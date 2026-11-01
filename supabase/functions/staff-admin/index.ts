import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Sign in as the institution administrator." }, 401);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return json({ error: "Your session is invalid. Sign in again." }, 401);

  try {
    const body = await req.json();
    const orgId = String(body.organizationId || "");
    const displayName = String(body.displayName || "").trim();
    const staffCode = String(body.staffCode || "").trim().toUpperCase();
    const pin = String(body.pin || "");
    const department = String(body.department || "");

    const roleByDepartment: Record<string, string> = {
      energy: "energy_manager",
      fuel: "fuel_manager",
      transport: "transport_manager",
      waste: "waste_manager",
      procurement: "procurement_manager",
    };
    if (!orgId || !displayName || !/^[A-Z0-9_-]{4,24}$/.test(staffCode) ||
        !/^\d{8,12}$/.test(pin) || !roleByDepartment[department]) {
      return json({ error: "Enter a name, a 4–24 character staff ID, an 8–12 digit PIN and a valid department." }, 400);
    }

    const { data: membership, error: memberError } = await admin
      .from("organization_members")
      .select("role")
      .eq("organization_id", orgId)
      .eq("user_id", userData.user.id)
      .maybeSingle();
    if (memberError || membership?.role !== "admin") return json({ error: "Only the institution administrator can create staff accounts." }, 403);

    const { data: existing } = await admin.from("staff_accounts")
      .select("id").eq("organization_id", orgId).ilike("staff_code", staffCode).maybeSingle();
    if (existing) return json({ error: "That staff ID is already in use in this institution." }, 409);

    const internalEmail = `staff-${crypto.randomUUID()}@staff.carbotrack.invalid`;
    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: internalEmail,
      password: pin,
      email_confirm: true,
      user_metadata: { full_name: displayName, carbotrack_staff: true },
    });
    if (createError || !created.user) return json({ error: createError?.message || "Could not create the staff login." }, 400);

    const role = roleByDepartment[department];
    const { error: accountError } = await admin.from("staff_accounts").insert({
      organization_id: orgId,
      auth_user_id: created.user.id,
      staff_code: staffCode,
      display_name: displayName,
      department,
      role,
      internal_email: internalEmail,
      created_by: userData.user.id,
    });
    if (!accountError) {
      const { error: membershipError } = await admin.from("organization_members").insert({
        organization_id: orgId,
        user_id: created.user.id,
        role,
        department,
      });
      if (!membershipError) return json({ success: true, staffId: staffCode, name: displayName, department });
      await admin.from("staff_accounts").delete().eq("auth_user_id", created.user.id);
      await admin.auth.admin.deleteUser(created.user.id);
      return json({ error: membershipError.message }, 400);
    }

    await admin.auth.admin.deleteUser(created.user.id);
    return json({ error: accountError.message }, 400);
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Unexpected server error." }, 500);
  }
});
