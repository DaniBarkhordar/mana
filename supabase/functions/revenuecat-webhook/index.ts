// ============================================================================
// revenuecat-webhook — mirrors store entitlements into public.entitlements.
//
// RevenueCat → Project settings → Integrations → Webhooks: URL of this
// function, and an Authorization header value that matches the
// REVENUECAT_WEBHOOK_SECRET secret set on the project. The function writes
// with the service role because the caller is RevenueCat, not a user; every
// other path to this table is read-only under RLS.
// ============================================================================

import { createClient } from "@supabase/supabase-js";

import { type RevenueCatEvent, rowFor, secretMatches } from "./webhook.ts";

const SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }
  if (!secretMatches(request.headers.get("Authorization"), SECRET)) {
    return new Response("unauthorised", { status: 401 });
  }

  let body: { event?: RevenueCatEvent };
  try {
    body = await request.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }
  const event = body.event;
  if (!event || typeof event.type !== "string") {
    return new Response("no event", { status: 400 });
  }

  const row = rowFor(event);
  if (!row) return Response.json({ ok: true, applied: false });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supabase.from("entitlements").upsert(row, {
    onConflict: "user_id",
  });
  if (error) {
    console.error("entitlement upsert failed", error.message);
    // 5xx makes RevenueCat retry, which is what we want.
    return new Response("storage error", { status: 500 });
  }
  return Response.json({ ok: true, applied: true, tier: row.tier });
});
