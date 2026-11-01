-- CarboTrack Supabase schema. Run in the Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Campus member',
 institution text,
 city text,
 course text,
 leaderboard_opt_in boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.carbon_results (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 total_kg numeric(12,2) not null check(total_kg >= 0),
 transport_kg numeric(12,2) not null default 0,
 energy_kg numeric(12,2) not null default 0,
 food_kg numeric(12,2) not null default 0,
 water_kg numeric(12,2) not null default 0,
 waste_kg numeric(12,2) not null default 0,
 shopping_kg numeric(12,2) not null default 0,
 factor_version text not null default 'illustrative-v1',
 created_at timestamptz not null default now()
);
create table if not exists public.challenge_progress (
 user_id uuid not null references auth.users(id) on delete cascade,
 challenge_key text not null default 'green-week-7',
 completed_days integer[] not null default '{}',
 started_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 primary key(user_id, challenge_key),
 constraint valid_days check(completed_days <@ array[0,1,2,3,4,5,6])
);
create index if not exists carbon_results_user_created on public.carbon_results(user_id,created_at desc);
alter table public.profiles enable row level security;
alter table public.carbon_results enable row level security;
alter table public.challenge_progress enable row level security;
drop policy if exists "Profiles visible to owner" on public.profiles;
create policy "Profiles visible to owner" on public.profiles for select using(auth.uid()=id);
drop policy if exists "Profiles insert by owner" on public.profiles;
create policy "Profiles insert by owner" on public.profiles for insert with check(auth.uid()=id);
drop policy if exists "Profiles update by owner" on public.profiles;
create policy "Profiles update by owner" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
drop policy if exists "Results readable by owner" on public.carbon_results;
create policy "Results readable by owner" on public.carbon_results for select using(auth.uid()=user_id);
drop policy if exists "Results insert by owner" on public.carbon_results;
create policy "Results insert by owner" on public.carbon_results for insert with check(auth.uid()=user_id);
drop policy if exists "Results delete by owner" on public.carbon_results;
create policy "Results delete by owner" on public.carbon_results for delete using(auth.uid()=user_id);
drop policy if exists "Challenge owner access" on public.challenge_progress;
create policy "Challenge owner access" on public.challenge_progress for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
-- Public leaderboard view exposes only opt-in display names and aggregate latest totals.
create or replace view public.public_leaderboard as
select p.display_name,p.institution,r.total_kg,r.created_at
from public.profiles p
join lateral (select total_kg,created_at from public.carbon_results cr where cr.user_id=p.id order by created_at desc limit 1) r on true
where p.leaderboard_opt_in=true;
-- Add a profile row automatically when a new auth user is created.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Campus member'));
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Public can read only the opt-in projection exposed by this view.
grant select on public.public_leaderboard to anon, authenticated;
