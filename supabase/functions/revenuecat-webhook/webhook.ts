// ============================================================================
// revenuecat-webhook — the pure part.
//
// RevenueCat tells us what the stores decided; we mirror it into
// public.entitlements so the vision function can meter by tier. The app never
// decides its own tier, and this function never trusts the app: the only
// input is RevenueCat's signed call, checked against a shared secret.
// ============================================================================

export type Tier = "free" | "plus";

/** The entitlement identifier configured in RevenueCat and in the app. */
export const ENTITLEMENT_ID = "plus";

/** The subset of a RevenueCat webhook event this function reads. */
export interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  /** Aliases RevenueCat merged into this customer; may carry the real uid. */
  aliases?: string[];
  /** Also present as `original_app_user_id`. */
  original_app_user_id?: string;
  entitlement_ids?: string[] | null;
  /** Epoch milliseconds. */
  expiration_at_ms?: number | null;
  product_id?: string;
  store?: string;
  environment?: "SANDBOX" | "PRODUCTION";
}

export interface EntitlementRow {
  user_id: string;
  tier: Tier;
  expires_at: string | null;
  source: string;
  updated_at: string;
}

/**
 * Event types after which the person has Plus. CANCELLATION is *not* one of
 * them to remove: a cancelled subscription runs to its expiry, and EXPIRATION
 * arrives then. BILLING_ISSUE likewise: the store retries; EXPIRATION is the
 * word.
 */
const GRANTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
  "PRODUCT_CHANGE",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);
const REVOKES = new Set(["EXPIRATION", "SUBSCRIPTION_PAUSED"]);
const IGNORED = new Set(["TEST", "TRANSFER", "SUBSCRIBER_ALIAS"]);

/** Supabase user ids are UUIDs; anything else is an anonymous RevenueCat id. */
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The Supabase uid this event is about, or null when RevenueCat only knows an
 *  anonymous id (a purchase before the app identified the user — the app's
 *  next logIn merges them and RevenueCat sends a TRANSFER/alias event). */
export function userIdOf(event: RevenueCatEvent): string | null {
  const candidates = [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
  ];
  return candidates.find((c) => typeof c === "string" && UUID.test(c)) ?? null;
}

/**
 * What to write, or null when the event changes nothing. Pure, so it can be
 * tested against RevenueCat's documented event shapes.
 */
export function rowFor(
  event: RevenueCatEvent,
  now: Date = new Date(),
): EntitlementRow | null {
  if (IGNORED.has(event.type)) return null;
  const userId = userIdOf(event);
  if (!userId) return null;

  const carriesPlus = (event.entitlement_ids ?? []).includes(ENTITLEMENT_ID);
  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms)
    : null;
  const stillValid = expiresAt === null || expiresAt.getTime() > now.getTime();

  let tier: Tier;
  if (REVOKES.has(event.type)) {
    tier = "free";
  } else if (GRANTS.has(event.type) && carriesPlus && stillValid) {
    tier = "plus";
  } else if (event.type === "CANCELLATION" || event.type === "BILLING_ISSUE") {
    // Runs to expiry. Keep Plus while the store says it is paid for.
    tier = carriesPlus && stillValid ? "plus" : "free";
  } else {
    return null;
  }

  return {
    user_id: userId,
    tier,
    expires_at: tier === "plus" ? expiresAt?.toISOString() ?? null : null,
    source: `revenuecat:${(event.store ?? "unknown").toLowerCase()}`,
    updated_at: now.toISOString(),
  };
}

/** Constant-time comparison for the shared secret. */
export function secretMatches(header: string | null, secret: string): boolean {
  if (!header || !secret) return false;
  const given = header.startsWith("Bearer ") ? header.slice(7) : header;
  if (given.length !== secret.length) return false;
  let diff = 0;
  for (let i = 0; i < secret.length; i++) {
    diff |= given.charCodeAt(i) ^ secret.charCodeAt(i);
  }
  return diff === 0;
}
