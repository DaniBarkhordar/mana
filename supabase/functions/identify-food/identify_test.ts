// Three assertions, kept local so the tests need nothing from a registry.
function assert(condition: unknown, message = "assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}
function assertEquals(actual: unknown, expected: unknown): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`expected ${e}, got ${a}`);
}
function assertStringIncludes(haystack: string, needle: string): void {
  if (!haystack.includes(needle)) throw new Error(`expected to find "${needle}"`);
}

import {
  buildUserPrompt,
  cacheKey,
  DAILY_LIMIT,
  modelFor,
  normalise,
  parseModelJson,
  providerFor,
  quotaReply,
  SYSTEM_PROMPT,
  tierOf,
  validateRequest,
} from "./identify.ts";

Deno.test("the prompt never asks for a quantity, and forbids it", () => {
  assertStringIncludes(SYSTEM_PROMPT, "NEVER estimate portion size");
  assert(!/how (much|many grams)/i.test(SYSTEM_PROMPT));
  const user = buildUserPrompt({
    imageBase64: "x",
    localTime: "07:40",
    locale: "en-GB",
    recentFoods: ["Porridge oats", "  ", "Greek yogurt"],
    hint: "leftovers",
    measuredGrams: 235.4,
  });
  assertStringIncludes(user, "Local time: 07:40");
  assertStringIncludes(user, "Porridge oats, Greek yogurt");
  assertStringIncludes(user, "235 g");
  assertStringIncludes(user, "User note: leftovers");
  assert(!/calorie/i.test(user));
});

Deno.test("UK naming is in the prompt", () => {
  for (const word of ["courgette", "aubergine", "mince", "rocket", "coriander"]) {
    assertStringIncludes(SYSTEM_PROMPT, word);
  }
});

Deno.test("parseModelJson tolerates fences, drops junk, sorts by share", () => {
  const r = parseModelJson(`\`\`\`json
  {"candidates":[
    {"name":"Coriander","queries":["coriander leaves"],"confidence":0.6,"massShare":0.02,"cooked":false},
    {"name":"","queries":[]},
    "nonsense",
    {"name":"Basmati rice","queries":["rice basmati boiled","rice"],"confidence":2,"massShare":0.5,"cooked":true},
    {"name":"Chicken tikka","confidence":0.8,"massShare":0.35,"cooked":"yes","likelyAddedFat":"ghee"}
  ],"note":null}
  \`\`\``);
  assertEquals(r.candidates.map((c) => c.name), ["Basmati rice", "Chicken tikka", "Coriander"]);
  assertEquals(r.candidates[0].confidence, 1);
  // No queries given: the name is the query.
  assertEquals(r.candidates[1].queries, ["Chicken tikka"]);
  assertEquals(r.candidates[1].cooked, false);
  assertEquals(r.candidates[1].likelyAddedFat, "ghee");
  assertEquals(r.note, null);
});

Deno.test("unreadable text is an honest empty result", () => {
  const r = parseModelJson("I think that is a sandwich");
  assertEquals(r.candidates, []);
  assert(r.note);
  assertEquals(normalise(null).candidates, []);
});

Deno.test("metering: tiers, limits and model choice", () => {
  assertEquals(tierOf("plus"), "plus");
  assertEquals(tierOf(undefined), "free");
  assertEquals(DAILY_LIMIT.free, 30);
  assertEquals(DAILY_LIMIT.plus, 400);
  assertEquals(quotaReply().canStillWeigh, true);

  const env = { ANTHROPIC_API_KEY: "k" };
  assertEquals(providerFor(env), "anthropic");
  assertEquals(providerFor({ GEMINI_API_KEY: "g" }), "gemini");
  assertEquals(providerFor({ GEMINI_API_KEY: "g", VISION_PROVIDER: "anthropic" }), null);
  assertEquals(providerFor({}), null);

  assertEquals(modelFor(env, "anthropic", "plus"), "claude-opus-5");
  assertEquals(modelFor(env, "anthropic", "free"), "claude-opus-5");
  const split = { ...env, VISION_MODEL: "claude-opus-5", VISION_MODEL_FREE: "claude-haiku-4-5" };
  assertEquals(modelFor(split, "anthropic", "free"), "claude-haiku-4-5");
  assertEquals(modelFor(split, "anthropic", "plus"), "claude-opus-5");
  assertEquals(modelFor({ GEMINI_API_KEY: "g" }, "gemini", "free"), "gemini-2.5-flash-lite");
});

Deno.test("request validation", () => {
  assertEquals(validateRequest(null), "bad request");
  assertEquals(validateRequest({}), "no image");
  assertEquals(validateRequest({ imageBase64: "%%%" }), "image is not base64");
  assertEquals(validateRequest({ imageBase64: "a".repeat(1_000_000) }), "image too large");
  const ok = validateRequest({ imageBase64: "/9j/4AAQ\n", localTime: "07:40", recentFoods: ["a", 1] });
  assert(typeof ok !== "string");
  assertEquals(ok.imageBase64, "/9j/4AAQ");
  assertEquals(ok.recentFoods, ["a"]);
});

Deno.test("the cache key changes with the model and the hint, not the time", async () => {
  const req = { imageBase64: "abc", hint: "h", localTime: "07:40" };
  const a = await cacheKey(req, "m1");
  assertEquals(a, await cacheKey({ ...req, localTime: "19:00" }, "m1"));
  assert(a !== await cacheKey(req, "m2"));
  assert(a !== await cacheKey({ ...req, hint: "other" }, "m1"));
});
