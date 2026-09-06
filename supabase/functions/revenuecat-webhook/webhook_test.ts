import { rowFor, secretMatches, userIdOf } from "./webhook.ts";

function assert(condition: unknown, message = "assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}
function assertEquals(actual: unknown, expected: unknown): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`expected ${e}, got ${a}`);
}

const uid = "8d5b1a2e-3c4f-4a6b-9c8d-1e2f3a4b5c6d";
const now = new Date("2026-09-06T09:00:00Z");
const later = Date.UTC(2026, 9, 6); // 6 Oct 2026

Deno.test("a purchase with the plus entitlement grants plus until expiry", () => {
  const row = rowFor({
    type: "INITIAL_PURCHASE",
    app_user_id: uid,
    entitlement_ids: ["plus"],
    expiration_at_ms: later,
    store: "APP_STORE",
  }, now)!;
  assertEquals(row.user_id, uid);
  assertEquals(row.tier, "plus");
  assertEquals(row.expires_at, new Date(later).toISOString());
  assertEquals(row.source, "revenuecat:app_store");
});

Deno.test("expiration and pause revoke; cancellation runs to expiry", () => {
  assertEquals(
    rowFor({ type: "EXPIRATION", app_user_id: uid, entitlement_ids: ["plus"] }, now)!.tier,
    "free",
  );
  assertEquals(
    rowFor({ type: "SUBSCRIPTION_PAUSED", app_user_id: uid }, now)!.tier,
    "free",
  );
  const cancelled = rowFor({
    type: "CANCELLATION",
    app_user_id: uid,
    entitlement_ids: ["plus"],
    expiration_at_ms: later,
  }, now)!;
  assertEquals(cancelled.tier, "plus");
  const lapsed = rowFor({
    type: "CANCELLATION",
    app_user_id: uid,
    entitlement_ids: ["plus"],
    expiration_at_ms: Date.UTC(2026, 7, 1),
  }, now)!;
  assertEquals(lapsed.tier, "free");
  assertEquals(lapsed.expires_at, null);
});

Deno.test("a different entitlement, an already-expired grant, or an anonymous id changes nothing useful", () => {
  assertEquals(
    rowFor({ type: "RENEWAL", app_user_id: uid, entitlement_ids: ["other"] }, now),
    null,
  );
  assertEquals(
    rowFor({
      type: "RENEWAL",
      app_user_id: uid,
      entitlement_ids: ["plus"],
      expiration_at_ms: Date.UTC(2026, 0, 1),
    }, now),
    null,
  );
  assertEquals(rowFor({ type: "TEST", app_user_id: uid }, now), null);
  assertEquals(
    rowFor({ type: "RENEWAL", app_user_id: "$RCAnonymousID:abc", entitlement_ids: ["plus"] }, now),
    null,
  );
});

Deno.test("the uid is found among aliases", () => {
  assertEquals(
    userIdOf({ type: "RENEWAL", app_user_id: "$RCAnonymousID:abc", aliases: ["x", uid] }),
    uid,
  );
  assertEquals(userIdOf({ type: "RENEWAL", app_user_id: "nope" }), null);
});

Deno.test("the shared secret is checked, with or without Bearer", () => {
  assert(secretMatches("Bearer s3cret", "s3cret"));
  assert(secretMatches("s3cret", "s3cret"));
  assert(!secretMatches("Bearer wrong!", "s3cret"));
  assert(!secretMatches(null, "s3cret"));
  assert(!secretMatches("Bearer ", ""));
});
