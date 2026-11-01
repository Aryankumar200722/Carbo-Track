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
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    const body = await req.json();
    const staffCode = String(body.staffCode || "").trim().toUpperCase();
    const pin = String(body.pin || "");
    if (!/^[A-Z0-9_-]{4,24}$/.test(staffCode) || !/^\d{8,12}$/.test(pin)) {
      return json({ error: "Enter your staff ID and 8–12 digit PIN." }, 400);
    }

    const { data: account, error } = await service.from("staff_accounts")
      .select("id,internal_email,is_active,failed_attempts,locked_until")
      .ilike("staff_code", staffCode)
      .maybeSingle();

    // Use a generic error so account IDs cannot be enumerated.
    if (error || !account || !account.is_active) return json({ error: "Invalid staff ID or PIN." }, 401);
    if (account.locked_until && new Date(account.locked_until).getTime() > Date.now()) {
      return json({ error: "Too many attempts. Try again after the temporary lockout." }, 429);
    }

    const response = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: anonKey },
      body: JSON.stringify({ email: account.internal_email, password: pin }),
    });
    const session = await response.json();

    if (!response.ok || !session.access_token || !session.refresh_token) {
      const attempts = Number(account.failed_attempts || 0) + 1;
      const lockedUntil = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000).toISOString() : null;
      await service.from("staff_accounts").update({
        failed_attempts: attempts >= 5 ? 0 : attempts,
        locked_until: lockedUntil,
      }).eq("id", account.id);
      return json({ error: attempts >= 5 ? "Too many incorrect PIN attempts. Login is locked for 15 minutes." : "Invalid staff ID or PIN." }, 401);
    }

    await service.from("staff_accounts").update({ failed_attempts: 0, locked_until: null }).eq("id", account.id);
    return json({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      token_type: session.token_type,
      user: session.user,
    });
  } catch (_error) {
    return json({ error: "Unable to sign in right now. Please try again." }, 500);
  }
});
