// ============================================================================
// identify-food — Mananu's vision endpoint
//
// COST IS THE DESIGN CONSTRAINT. Four decisions keep it near zero:
//
//  1. We do not ask the model for portion size. Every other app in this category
//     spends most of its accuracy budget guessing grams from pixels, and gets it
//     wrong by a documented ±22%. We have a scale. The model's only job is "what
//     is this", which is the part it is actually good at, and asking for less
//     means fewer output tokens and a smaller, cheaper model.
//
//  2. The image is downscaled to 512px on the device before upload. A food photo
//     at that size is roughly 1-2k image tokens. On a Flash-Lite class model
//     that is well under $0.001 per identification — around 100x cheaper than a
//     specialist food-recognition API, which bills 20-30k tokens per photo.
//
//  3. Results are cached by image hash. Users photograph the same breakfast for
//     weeks; the second time is free.
//
//  4. Context beats model size. A published benchmark found that supplying time
//     of day, locale and the user's recent foods cut calorie error by ~76 kcal
//     on average — more than upgrading the model would. We send that context and
//     stay on the cheap tier.
//
// The API key lives here, never in the app bundle.
// ============================================================================

import { createClient } from "jsr:@supabase/supabase-js@2";

const MODEL = Deno.env.get("VISION_MODEL") ?? "gemini-2.5-flash-lite";
const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY");
const ANTHROPIC_KEY = Deno.env.get("ANTHROPIC_API_KEY");

/** Hard ceiling per user per day. Protects against a runaway client loop. */
const DAILY_LIMIT_FREE = 30;
const DAILY_LIMIT_PLUS = 400;

interface IdentifyRequest {
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

interface FoodCandidate {
  name: string;
  /** Suggested search terms against the offline CoFID/USDA index. */
  queries: string[];
  confidence: number;
  /** For a multi-component plate, the share of total mass this component looks
   *  to be. The user confirms each one on the scale; this only orders the UI. */
  massShare?: number;
  cooked: boolean;
  /** Fat that would have been added in cooking and is invisible in the photo.
   *  Prompting for this explicitly is what closes the largest published error
   *  in the category. */
  likelyAddedFat?: string;
}

const SYSTEM_PROMPT = `You identify food in photographs for a UK nutrition app.

The user has a kitchen scale. The exact weight is measured by hardware and is
supplied to you or captured separately. NEVER estimate portion size, grams,
calories or macros. You will be wrong and the scale will not be.

Your only job is identification. Return, for each distinct food component:
- a short specific name a UK shopper would recognise
- 2-4 search queries for a food-composition database, most specific first
- whether it is cooked or raw
- roughly what share of the total mass it looks like (for ordering only)
- any cooking fat likely absorbed but not visible (oil, butter, ghee)

Rules:
- Prefer UK naming: "courgette" not "zucchini", "aubergine" not "eggplant",
  "mince" not "ground beef", "rocket" not "arugula", "coriander" not "cilantro".
- Split composite plates into components. "Chicken curry with rice" is at least
  three: chicken, sauce, rice.
- If the photo is unclear, say so with low confidence rather than guessing.
- If there is no food in the image, return an empty array.
- Never diagnose, never give medical or dietary advice, never mention allergens
  as safe or unsafe.

Return strict JSON only: {"candidates":[...],"note":string|null}`;

function buildUserPrompt(req: IdentifyRequest): string {
  const bits: string[] = [];
  if (req.localTime) bits.push(`Local time: ${req.localTime}`);
  if (req.locale) bits.push(`Locale: ${req.locale}`);
  if (req.measuredGrams) {
    bits.push(`Total measured mass on the scale: ${Math.round(req.measuredGrams)} g`);
  }
  if (req.recentFoods?.length) {
    bits.push(`This user's recent foods: ${req.recentFoods.slice(0, 25).join(", ")}`);
  }
  if (req.hint) bits.push(`User note: ${req.hint}`);
  bits.push("Identify the food components in this photograph.");
  return bits.join("\n");
}

async function sha256(input: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Strip markdown fencing some models add around JSON. */
function parseModelJson(text: string): { candidates: FoodCandidate[]; note: string | null } {
  const cleaned = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/```$/, "");
  try {
    const parsed = JSON.parse(cleaned);
    return {
      candidates: Array.isArray(parsed.candidates) ? parsed.candidates : [],
      note: typeof parsed.note === "string" ? parsed.note : null,
    };
  } catch {
    return { candidates: [], note: "Could not read the photo clearly." };
  }
}

async function callGemini(req: IdentifyRequest): Promise<string> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_KEY}`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
      contents: [{
        role: "user",
        parts: [
          { inline_data: { mime_type: "image/jpeg", data: req.imageBase64 } },
          { text: buildUserPrompt(req) },
        ],
      }],
      generationConfig: {
        temperature: 0.1,
        // Identification is short. Capping output is a direct cost control.
        maxOutputTokens: 700,
        responseMimeType: "application/json",
      },
    }),
  });
  if (!res.ok) throw new Error(`vision upstream ${res.status}`);
  const json = await res.json();
  return json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
}

async function callAnthropic(req: IdentifyRequest): Promise<string> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": ANTHROPIC_KEY!,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 700,
      temperature: 0.1,
      system: SYSTEM_PROMPT,
      messages: [{
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: "image/jpeg", data: req.imageBase64 },
          },
          { type: "text", text: buildUserPrompt(req) },
        ],
      }],
    }),
  });
  if (!res.ok) throw new Error(`vision upstream ${res.status}`);
  const json = await res.json();
  return json?.content?.[0]?.text ?? "{}";
}

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

  let body: IdentifyRequest;
  try {
    body = await request.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }
  if (!body.imageBase64) return new Response("no image", { status: 400 });

  // ---- cache -------------------------------------------------------------
  // Same photo, same answer, no spend. Keyed on the image and the hint only:
  // time of day and recent foods shift wording, not identity.
  const key = await sha256(body.imageBase64 + (body.hint ?? ""));
  const { data: cached } = await supabase
    .from("vision_cache")
    .select("result")
    .eq("cache_key", key)
    .maybeSingle();

  if (cached?.result) {
    return Response.json({ ...cached.result, cached: true });
  }

  // ---- quota -------------------------------------------------------------
  const since = new Date();
  since.setUTCHours(0, 0, 0, 0);
  const { count } = await supabase
    .from("vision_usage")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", since.toISOString());

  const { data: entitlement } = await supabase
    .from("entitlements")
    .select("tier")
    .eq("user_id", user.id)
    .maybeSingle();

  const limit = entitlement?.tier === "plus" ? DAILY_LIMIT_PLUS : DAILY_LIMIT_FREE;
  if ((count ?? 0) >= limit) {
    return Response.json({
      candidates: [],
      note: "You've used today's photo scans.",
      quotaExceeded: true,
      // Weighing still works, always. The scale is the product; the camera is
      // a convenience, and metering it must never block core logging.
      canStillWeigh: true,
    }, { status: 200 });
  }

  // ---- model -------------------------------------------------------------
  let raw: string;
  try {
    raw = GEMINI_KEY ? await callGemini(body) : await callAnthropic(body);
  } catch (err) {
    console.error("vision failed", err);
    return Response.json({
      candidates: [],
      note: "Photo recognition is unavailable. You can still search or weigh.",
      degraded: true,
    }, { status: 200 });
  }

  const result = parseModelJson(raw);

  await supabase.from("vision_cache").insert({ cache_key: key, result });
  await supabase.from("vision_usage").insert({ user_id: user.id });

  return Response.json({ ...result, cached: false });
});
