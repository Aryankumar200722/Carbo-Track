-- CarboTrack individual staff-ID authentication and strict department isolation.
-- Run after institutional-schema.sql and departmental-access.sql.

create extension if not exists pgcrypto;

alter table public.organization_members
  add column if not exists department text;

alter table public.activity_records
  add column if not exists department text;

-- Ensure the supported role set is present.
alter table public.organization_members
  drop constraint if exists organization_members_role_check;
alter table public.organization_members
  add constraint organization_members_role_check
  check (role in (
    'admin','data_manager','viewer',
    'energy_manager','fuel_manager','transport_manager',
    'waste_manager','procurement_manager'
  ));

-- Staff IDs are globally unique. PINs are NOT stored here:
-- Supabase Auth stores the password hash.
create table if not exists public.staff_accounts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  staff_code text not null,
  display_name text not null,
  department text not null check (department in ('energy','fuel','transport','waste','procurement')),
  role text not null check (role in ('energy_manager','fuel_manager','transport_manager','waste_manager','procurement_manager')),
  internal_email text not null unique,
  is_active boolean not null default true,
  failed_attempts integer not null default 0,
  locked_until timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (organization_id, staff_code)
);

create index if not exists staff_accounts_org_idx on public.staff_accounts(organization_id);
-- Staff IDs are globally unique because the login screen asks for ID without an institution selector.
create unique index if not exists staff_accounts_staff_code_global_ci_idx
  on public.staff_accounts(lower(staff_code));
create unique index if not exists staff_accounts_code_ci_idx
  on public.staff_accounts(organization_id, lower(staff_code));

alter table public.staff_accounts enable row level security;
drop policy if exists staff_accounts_admin_read on public.staff_accounts;
create policy staff_accounts_admin_read
on public.staff_accounts for select to authenticated
using (public.carbotrack_is_admin(organization_id));
revoke all on public.staff_accounts from anon, authenticated;
grant select on public.staff_accounts to authenticated;

-- Members can see only their own membership row; administrators can manage the roster.
drop policy if exists member_read_roster on public.organization_members;
drop policy if exists member_read_self_or_admin on public.organization_members;
create policy member_read_self_or_admin
on public.organization_members for select to authenticated
using (user_id = auth.uid() or public.carbotrack_is_admin(organization_id));

-- Department-role mapping is enforced in PostgreSQL, not only in the UI.
create or replace function public.carbotrack_can_submit(org_id uuid, dept text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = org_id
      and m.user_id = auth.uid()
      and (
        m.role = 'admin'
        or (m.role = 'energy_manager' and dept = 'energy')
        or (m.role = 'fuel_manager' and dept = 'fuel')
        or (m.role = 'transport_manager' and dept = 'transport')
        or (m.role = 'waste_manager' and dept = 'waste')
        or (m.role = 'procurement_manager' and dept = 'procurement')
      )
  );
$$;

create or replace function public.carbotrack_can_view_record(org_id uuid, dept text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = org_id
      and m.user_id = auth.uid()
      and (
        m.role = 'admin'
        or (m.role = 'energy_manager' and dept = 'energy')
        or (m.role = 'fuel_manager' and dept = 'fuel')
        or (m.role = 'transport_manager' and dept = 'transport')
        or (m.role = 'waste_manager' and dept = 'waste')
        or (m.role = 'procurement_manager' and dept = 'procurement')
      )
  );
$$;

create or replace function public.carbotrack_factor_matches_department(p_factor_id uuid, p_department text)
returns boolean
language sql stable security definer set search_path = public
as $function$
  select exists (
    select 1 from public.emission_factors f
    where f.id = p_factor_id and f.active = true
      and (
        (p_department = 'energy' and f.category = 'Purchased electricity')
        or (p_department = 'fuel' and f.category in ('Stationary/mobile fuel','Stationary fuel'))
        or (p_department = 'transport' and f.category in ('Owned vehicle fuel','Stationary/mobile fuel'))
        or (p_department = 'waste' and f.category = 'Waste')
        or (p_department = 'procurement' and f.category = 'Purchased goods')
      )
  );
$function$;

-- Replace broad member-wide read access with department-scoped access.
drop policy if exists activity_read_members on public.activity_records;
drop policy if exists activity_read_department on public.activity_records;
create policy activity_read_department
on public.activity_records for select to authenticated
using (public.carbotrack_can_view_record(organization_id, department));

drop policy if exists activity_insert_managers on public.activity_records;
drop policy if exists activity_insert_department on public.activity_records;
create policy activity_insert_department
on public.activity_records for insert to authenticated
with check (
  public.carbotrack_can_submit(organization_id, department)
  and public.carbotrack_factor_matches_department(factor_id, department)
  and entered_by = auth.uid()
);

drop policy if exists activity_update_managers on public.activity_records;
drop policy if exists activity_update_department on public.activity_records;
create policy activity_update_department
on public.activity_records for update to authenticated
using (
  public.carbotrack_is_admin(organization_id)
  or (
    public.carbotrack_can_submit(organization_id, department)
    and public.carbotrack_factor_matches_department(factor_id, department)
    and entered_by = auth.uid()
  )
)
with check (
  public.carbotrack_is_admin(organization_id)
  or (
    public.carbotrack_can_submit(organization_id, department)
    and public.carbotrack_factor_matches_department(factor_id, department)
    and entered_by = auth.uid()
  )
);

drop policy if exists activity_delete_admin on public.activity_records;
create policy activity_delete_admin
on public.activity_records for delete to authenticated
using (public.carbotrack_is_admin(organization_id));

-- Only admins can view the staff roster through this RPC.
drop function if exists public.carbotrack_list_members();
create function public.carbotrack_list_members()
returns table (
  member_id uuid,
  display_name text,
  staff_code text,
  role text,
  department text,
  joined_at timestamptz,
  is_active boolean
)
language plpgsql stable security definer set search_path = public
as $$
declare
  org_id uuid;
begin
  select m.organization_id into org_id
  from public.organization_members m
  where m.user_id = auth.uid() and m.role = 'admin'
  limit 1;

  if org_id is null then
    raise exception 'Only the institution administrator can view the staff roster';
  end if;

  return query
  select m.user_id,
         coalesce(sa.display_name, u.raw_user_meta_data->>'full_name', 'Institution administrator'),
         sa.staff_code,
         m.role,
         m.department,
         m.created_at,
         coalesce(sa.is_active, true)
  from public.organization_members m
  join auth.users u on u.id = m.user_id
  left join public.staff_accounts sa
    on sa.auth_user_id = m.user_id and sa.organization_id = m.organization_id
  where m.organization_id = org_id
  order by m.created_at;
end;
$$;

grant execute on function public.carbotrack_list_members() to authenticated;

-- No public/anonymous access to staff account metadata.
revoke all on public.staff_accounts from anon;
