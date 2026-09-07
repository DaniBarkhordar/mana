// ============================================================================
// identify-food — the pure part.
//
// Everything in this module runs without a network, a database or a key, so
// `deno test` can hold the prompt, the schema and the metering rules to
// account. index.ts is the thin HTTP wrapper around it.
// ============================================================================

import { z } from "zod";

/** What the app sends. Mirrors `IdentifyRequest.toJson` in the Flutter app. */
export interface IdentifyRequest {
  /** base64 JPEG, already downscaled to <=512px on the longest edge. */
  imageBase64: string;
  /** Device-local time, so "07:40" can bias towards breakfast foods. */
  localTime?: string;
  /** BCP-47, e.g. "en-GB". Drives cuisine priors and UK product names. */
  locale?: string;
  /** Names the user logged in the last fortnight — their actual diet. */
  recentFoods?: string[];
  /** Anything the user typed before taking the photo. */
  hint?: string;
  /** Measured grams, when the scale already has a number. Sent for context
   *  only: it lets the model reason about how many components are plausible. */
  measuredGrams?: number;
}

/** One recognised component. The shape the app's `FoodCandidate.fromJson` reads. */
export const FoodCandidateSchema = z.object({
  /** A short specific name a UK shopper would recognise. */
  name: z.string().min(1).max(80),
  /** Search terms against the offline CoFID/USDA index, most specific first. */
  queries: z.array(z.string().min(1).max(80)).min(1).max(4),
  confidence: z.number().min(0).max(1),
  /** Share of the plate's mass this looks like. Orders the UI, nothing more. */
  massShare: z.number().min(0).max(1).nullable(),
  cooked: z.boolean(),
  /** Fat that would have been added in cooking and is invisible in the photo.
   *  Asking for this explicitly is what closes the largest published error in
   *  the category. */
  likelyAddedFat: z.string().max(120).nullable(),
});

export const IdentifyResultSchema = z.object({
  candidates: z.array(FoodCandidateSchema).max(8),
  /** Something the user should know: "photo is blurry", "no food visible". */
  note: z.string().max(200).nullable(),
});

export type FoodCandidate = z.infer<typeof FoodCandidateSchema>;
export type IdentifyResult = z.infer<typeof IdentifyResultSchema>;

/** The reply the app gets, whichever path produced it. */
export interface IdentifyResponse extends IdentifyResult {
  cached: boolean;
  degraded?: boolean;
  quotaExceeded?: boolean;
  canStillWeigh?: boolean;
}

// ---------------------------------------------------------------------------
// Prompt
// ---------------------------------------------------------------------------

/**
 * Identification only. The scale measures quantity; the model must never try.
 * That is the cost control and the accuracy claim at the same time
 * (CLAUDE.md hard rule 1).
 */
export const SYSTEM_PROMPT = `You identify food in photographs for Mananu, a UK nutrition app built around a kitchen scale.

The exact weight of the food is measured by hardware. NEVER estimate portion size, grams, calories or macros — the scale has the number and you do not.

Your only job is identification. For each distinct food component in the photo give:
- a short specific name a UK shopper would recognise
- 2 to 4 search queries for a food-composition database (CoFID / USDA), most specific first, plain words, no punctuation
- whether it is cooked or raw
- roughly what share of the plate's mass it looks like, as a fraction of 1 (for ordering only)
- any cooking fat likely absorbed but not visible (oil, butter, ghee), or null

Rules:
- Prefer UK naming: courgette not zucchini, aubergine not eggplant, mince not ground beef, rocket not arugula, coriander not cilantro, prawns not shrimp, chips not fries.
- Split composite plates into components. "Chicken curry with rice" is at least three: chicken, sauce, rice.
- Use the context you are given (time of day, the user's recent foods, anything they typed) to resolve ambiguity, and say so in a query when it helps.
- If the photo is unclear, say so with low confidence rather than guessing.
- If there is no food in the image, return an empty list and a short note.
- Never diagnose, never give medical or dietary advice, never call an allergen safe or unsafe.`;

export function buildUserPrompt(req: IdentifyRequest): string {
  const bits: string[] = [];
  if (req.localTime) bits.push(`Local time: ${req.localTime}`);
  if (req.locale) bits.push(`Locale: ${req.locale}`);
  if (req.measuredGrams && req.measuredGrams > 0) {
    bits.push(
      `Total measured mass on the scale: ${Math.round(req.measuredGrams)} g (context for how many components are plausible; do not restate it)`,
    );
  }
  if (req.recentFoods?.length) {
    const recent = req.recentFoods
      .filter((f) => typeof f === "string" && f.trim().length > 0)
      .slice(0, 25)
      .map((f) => f.trim().slice(0, 60));
    if (recent.length) bits.push(`This user's recent foods: ${recent.join(", ")}`);
  }
  if (req.hint?.trim()) bits.push(`User note: ${req.hint.trim().slice(0, 200)}`);
  bits.push("Identify the food components in this photograph.");
  return bits.join("\n");
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/** Empty-but-honest result, used whenever the model could not be read. */
export const UNREADABLE: IdentifyResult = {
  candidates: [],
  note: "Could not read the photo clearly.",
};

/**
 * Turns model text into a validated result. Tolerates the markdown fencing
 * some providers add and the fields a looser model leaves out; drops any
 * candidate that does not survive the schema rather than the whole reply.
 * Sorted largest share first, then most confident.
 */
export function parseModelJson(text: string): IdentifyResult {
  const cleaned = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "");
  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    return UNREADABLE;
  }
  return normalise(parsed);
}

export function normalise(parsed: unknown): IdentifyResult {
  if (!parsed || typeof parsed !== "object") return UNREADABLE;
  const obj = parsed as Record<string, unknown>;
  const raw = Array.isArray(obj.candidates) ? obj.candidates : [];
  const candidates: FoodCandidate[] = [];
  for (const c of raw) {
    if (!c || typeof c !== "object") continue;
    const r = c as Record<string, unknown>;
    const name = typeof r.name === "string" ? r.name.trim() : "";
    if (!name) continue;
    const queries = Array.isArray(r.queries)
      ? r.queries.filter((q): q is string => typeof q === "string" && q.trim().length > 0)
        .map((q) => q.trim().slice(0, 80)).slice(0, 4)
      : [];
    const attempt = FoodCandidateSchema.safeParse({
      name: name.slice(0, 80),
      queries: queries.length ? queries : [name.slice(0, 80)],
      confidence: clamp01(r.confidence, 0.5),
      massShare: r.massShare == null ? null : clamp01(r.massShare, 0),
      cooked: r.cooked === true,
      likelyAddedFat: typeof r.likelyAddedFat === "string" && r.likelyAddedFat.trim()
        ? r.likelyAddedFat.trim().slice(0, 120)
        : null,
    });
    if (attempt.success) candidates.push(attempt.data);
  }
  candidates.sort((a, b) =>
    (b.massShare ?? 0) - (a.massShare ?? 0) || b.confidence - a.confidence
  );
  const note = typeof obj.note === "string" && obj.note.trim()
    ? obj.note.trim().slice(0, 200)
    : null;
  return { candidates: candidates.slice(0, 8), note };
}

function clamp01(v: unknown, fallback: number): number {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(1, Math.max(0, n));
}

// ---------------------------------------------------------------------------
// Metering and model selection
// ---------------------------------------------------------------------------

export type Tier = "free" | "plus";

/**
 * The allowance, as sold (runbook §7): thirty scans a month free, unlimited
 * on Plus. "Unlimited" still has a per-day ceiling that no person reaches,
 * so a runaway client loop cannot run up a bill.
 */
export const FREE_MONTHLY_LIMIT = 30;
export const PLUS_DAILY_CEILING = 400;

export interface Quota {
  limit: number;
  /** Start of the window, UTC. */
  since: Date;
  /** What to tell the person when it is spent. */
  note: string;
}

export function quotaFor(tier: Tier, now: Date = new Date()): Quota {
  if (tier === "plus") {
    const since = new Date(now);
    since.setUTCHours(0, 0, 0, 0);
    return {
      limit: PLUS_DAILY_CEILING,
      since,
      note: "That is a lot of photos for one day. Weighing still works; scans come back tomorrow.",
    };
  }
  const since = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  return {
    limit: FREE_MONTHLY_LIMIT,
    since,
    note: "You've used this month's 30 free photo scans. Plus has no limit — and the scale always works.",
  };
}

export function tierOf(value: unknown): Tier {
  return value === "plus" ? "plus" : "free";
}

export type Provider = "anthropic" | "gemini";

export interface VisionEnv {
  ANTHROPIC_API_KEY?: string;
  GEMINI_API_KEY?: string;
  VISION_PROVIDER?: string;
  VISION_MODEL?: string;
  VISION_MODEL_FREE?: string;
}

/**
 * Defaults chosen for cost-effectiveness, as the founder asked: a strong
 * vision model that is not the most expensive. Claude Sonnet 5 identifies a
 * plate as well as this task needs at roughly a third of a penny per scan;
 * `claude-opus-5` is a VISION_MODEL away when quality on hard plates is worth
 * three times that (runbook §3 has the table).
 */
export const DEFAULT_MODEL: Record<Provider, string> = {
  anthropic: "claude-sonnet-5",
  gemini: "gemini-2.5-flash-lite",
};

/**
 * Which provider serves this deployment. Explicit VISION_PROVIDER wins; else
 * whichever key is present, Anthropic first. Null when there is no key at
 * all, in which case the function answers "unavailable" and the app keeps
 * weighing.
 */
export function providerFor(env: VisionEnv): Provider | null {
  const explicit = env.VISION_PROVIDER?.toLowerCase();
  if (explicit === "anthropic" || explicit === "gemini") {
    const key = explicit === "anthropic" ? env.ANTHROPIC_API_KEY : env.GEMINI_API_KEY;
    return key ? explicit : null;
  }
  if (env.ANTHROPIC_API_KEY) return "anthropic";
  if (env.GEMINI_API_KEY) return "gemini";
  return null;
}

/**
 * The model for this request. VISION_MODEL for everyone; VISION_MODEL_FREE
 * lets the free tier run on a cheaper model than Plus (runbook §3 has the
 * per-scan cost table). Tier is decided by the entitlements table, never by
 * the app.
 */
export function modelFor(env: VisionEnv, provider: Provider, tier: Tier): string {
  const paid = env.VISION_MODEL?.trim() || DEFAULT_MODEL[provider];
  if (tier === "free" && env.VISION_MODEL_FREE?.trim()) {
    return env.VISION_MODEL_FREE.trim();
  }
  return paid;
}

/** Cache key: the same bytes, the same hint, the same model — the same answer. */
export async function cacheKey(req: IdentifyRequest, model: string): Promise<string> {
  return await sha256(`${model}|${req.hint ?? ""}|${req.imageBase64}`);
}

export async function sha256(input: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** A 512 px JPEG is well under 200 KB; anything much bigger is not from our app. */
export const MAX_IMAGE_BASE64 = 900_000;

export function validateRequest(body: unknown): IdentifyRequest | string {
  if (!body || typeof body !== "object") return "bad request";
  const b = body as Record<string, unknown>;
  if (typeof b.imageBase64 !== "string" || b.imageBase64.length === 0) return "no image";
  if (b.imageBase64.length > MAX_IMAGE_BASE64) return "image too large";
  if (!/^[A-Za-z0-9+/=\s]+$/.test(b.imageBase64.slice(0, 4096))) return "image is not base64";
  return {
    imageBase64: b.imageBase64.replace(/\s+/g, ""),
    localTime: typeof b.localTime === "string" ? b.localTime.slice(0, 8) : undefined,
    locale: typeof b.locale === "string" ? b.locale.slice(0, 16) : undefined,
    recentFoods: Array.isArray(b.recentFoods)
      ? b.recentFoods.filter((f): f is string => typeof f === "string")
      : undefined,
    hint: typeof b.hint === "string" ? b.hint : undefined,
    measuredGrams: typeof b.measuredGrams === "number" ? b.measuredGrams : undefined,
  };
}

export const UNAVAILABLE: IdentifyResponse = {
  candidates: [],
  note: "Photo recognition is unavailable. You can still search or weigh.",
  cached: false,
  degraded: true,
};

export function quotaReply(quota: Quota): IdentifyResponse {
  return {
    candidates: [],
    note: quota.note,
    cached: false,
    quotaExceeded: true,
    // Weighing still works, always. The scale is the product; the camera is
    // a convenience, and metering it must never block core logging.
    canStillWeigh: true,
  };
}
