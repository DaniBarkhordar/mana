// ============================================================================
// identify-food — Mananu's vision endpoint
//
// COST IS THE DESIGN CONSTRAINT. Four decisions keep it near zero:
//
//  1. We do not ask the model for portion size. Every other app in this category
//     spends most of its accuracy budget guessing grams from pixels, and gets it
//     wrong by a documented ±22%. We have a scale. The model's only job is "what
//     is this", which is the part it is actually good at, and asking for less
//     means fewer output tokens and a short, schema-bound answer. A typed
//     description goes through the same call with no image block at all.
//
//  2. The image is downscaled to 512px on the device before upload. At that
//     size a photo is a few hundred image tokens on Claude, so a scan is a
//     fraction of a penny on every model in the table in runbook §3.
//
//  3. Results are cached by image hash. Users photograph the same breakfast for
//     weeks; the second time is free.
//
//  4. Context beats model size. Time of day, locale and the user's recent foods
//     go with every request; that resolves more ambiguity than a bigger model
//     would.
//
// The API keys live here, never in the app bundle. Which provider serves is
// a deployment setting (VISION_PROVIDER / VISION_MODEL / VISION_MODEL_FREE),
// so the consent text in the app is built with a matching VISION_PROVIDER
// define.
// ============================================================================

import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { createClient } from "@supabase/supabase-js";

import {
  buildUserPrompt,
  cacheKey,
  type IdentifyRequest,
  type IdentifyResponse,
  type IdentifyResult,
  IdentifyResultSchema,
  modelFor,
  normalise,
  parseModelJson,
  providerFor,
  quotaFor,
  quotaReply,
  SYSTEM_PROMPT,
  tierOf,
  UNAVAILABLE,
  UNREADABLE,
  validateRequest,
  type VisionEnv,
} from "./identify.ts";

const env: VisionEnv = {
  ANTHROPIC_API_KEY: Deno.env.get("ANTHROPIC_API_KEY") ?? undefined,
  GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY") ?? undefined,
  VISION_PROVIDER: Deno.env.get("VISION_PROVIDER") ?? undefined,
  VISION_MODEL: Deno.env.get("VISION_MODEL") ?? undefined,
  VISION_MODEL_FREE: Deno.env.get("VISION_MODEL_FREE") ?? undefined,
};

const anthropic = env.ANTHROPIC_API_KEY
  ? new Anthropic({ apiKey: env.ANTHROPIC_API_KEY, maxRetries: 2, timeout: 25_000 })
  : null;

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/**
 * Claude, through the official SDK. Structured output binds the reply to the
 * schema, so there is no JSON repair step; effort is low because this is a
 * recognition task, not reasoning; and `fallbacks: "default"` re-runs a
 * policy decline on Anthropic's recommended substitute inside the same call
 * rather than returning an empty plate.
 */
async function callAnthropic(req: IdentifyRequest, model: string): Promise<IdentifyResult> {
  if (!anthropic) throw new Error("no anthropic key");
  const params = {
    model,
    max_tokens: 1024,
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    system: SYSTEM_PROMPT,
    output_config: {
      effort: "low",
      format: zodOutputFormat(IdentifyResultSchema),
    },
    messages: [{
      role: "user",
      // A described plate has no image block: the text alone carries it.
      content: [
        ...(req.imageBase64
          ? [{
            type: "image",
            source: { type: "base64", media_type: "image/jpeg", data: req.imageBase64 },
          }]
          : []),
        { type: "text", text: buildUserPrompt(req) },
      ],
    }],
  };
  // The SDK's typings trail the `fallbacks` parameter; the request shape is the
  // documented one (runbook §3 names the beta header).
  const response = await anthropic.beta.messages.create(
    params as unknown as Parameters<typeof anthropic.beta.messages.create>[0],
  ) as Anthropic.Beta.BetaMessage;

  if (response.stop_reason === "refusal") {
    // The whole fallback chain declined. Say so honestly; weighing goes on.
    return { candidates: [], note: "This photo could not be processed." };
  }
  const text = response.content
    .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")
    .map((b) => b.text)
    .join("");
  if (!text) return UNREADABLE;
  const parsed = IdentifyResultSchema.safeParse(JSON.parse(text));
  return parsed.success ? normalise(parsed.data) : parseModelJson(text);
}

/** Gemini, kept as the low-cost alternative. Raw REST; there is no official Deno SDK. */
async function callGemini(req: IdentifyRequest, model: string): Promise<IdentifyResult> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${env.GEMINI_API_KEY}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{
          text: SYSTEM_PROMPT +
            '\n\nReturn strict JSON only: {"candidates":[{"name":string,"queries":string[],"confidence":number,"massShare":number|null,"cooked":boolean,"likelyAddedFat":string|null}],"note":string|null}',
        }],
      },
      contents: [{
        role: "user",
        parts: [
          ...(req.imageBase64
            ? [{ inline_data: { mime_type: "image/jpeg", data: req.imageBase64 } }]
            : []),
          { text: buildUserPrompt(req) },
        ],
      }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      },
    }),
  });
  if (!res.ok) throw new Error(`vision upstream ${res.status}`);
  const json = await res.json();
  return parseModelJson(json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}");
}

// ---------------------------------------------------------------------------
// HTTP
// ---------------------------------------------------------------------------

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }

  const authHeader = request.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("unauthorised", { status: 401 });

  let raw: unknown;
  try {
    raw = await request.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }
  const body = validateRequest(raw);
  if (typeof body === "string") return new Response(body, { status: 400 });

  const provider = providerFor(env);
  if (!provider) {
    // Deployed without a key. The app shows "unavailable" and keeps weighing.
    return Response.json(UNAVAILABLE satisfies IdentifyResponse, { status: 200 });
  }

  // ---- tier ---------------------------------------------------------------
  // Read first: it decides both the model and the ceiling. The app never
  // tells us its tier; the entitlements table, fed by the billing webhook, does.
  const { data: entitlement } = await supabase
    .from("entitlements")
    .select("tier")
    .eq("user_id", user.id)
    .maybeSingle();
  const tier = tierOf(entitlement?.tier);
  const model = modelFor(env, provider, tier);

  // ---- cache --------------------------------------------------------------
  // Same photo (or the same words), same answer, no spend. Keyed on the
  // image, the description, the hint and the model only: time of day and
  // recent foods shift wording, not identity.
  const key = await cacheKey(body, model);
  const { data: cached } = await supabase
    .from("vision_cache")
    .select("result")
    .eq("cache_key", key)
    .maybeSingle();
  if (cached?.result) {
    await supabase.rpc("bump_cache_hit", { p_key: key });
    return Response.json({ ...normalise(cached.result), cached: true } satisfies IdentifyResponse);
  }

  // ---- quota --------------------------------------------------------------
  // Thirty a month free, a daily ceiling on Plus (identify.ts). Cache hits
  // never count, and neither do empty answers.
  const quota = quotaFor(tier);
  const { count } = await supabase
    .from("vision_usage")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", quota.since.toISOString());
  if ((count ?? 0) >= quota.limit) {
    return Response.json(quotaReply(quota), { status: 200 });
  }

  // ---- model --------------------------------------------------------------
  let result: IdentifyResult;
  try {
    result = provider === "anthropic"
      ? await callAnthropic(body, model)
      : await callGemini(body, model);
  } catch (err) {
    // Rate limit, outage, bad key: all the same to the user. Log the class,
    // never the image.
    console.error("vision failed", err instanceof Error ? err.message : String(err));
    return Response.json(UNAVAILABLE satisfies IdentifyResponse, { status: 200 });
  }

  // A reply with nothing in it is not worth caching: the next attempt at the
  // same plate should get a fresh look, and it never cost a scan either way.
  if (result.candidates.length > 0) {
    await supabase.from("vision_cache").insert({ cache_key: key, result });
    await supabase.from("vision_usage").insert({ user_id: user.id });
  }

  return Response.json({ ...result, cached: false } satisfies IdentifyResponse);
});
