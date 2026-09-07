# Mananu

**Weigh it. Don't guess it.**

A body-composition scale, an AI kitchen scale, and the app that ties them together — built on the premise that portion size should be *measured*, not estimated from a photograph.

## Why this exists

Photo calorie apps have to guess how much is on the plate. A controlled-feeding study presented at NUTRITION 2026 found the leading apps underestimate meals by **250–345 kcal on average**, with fat under-reported by about **30 g per meal**. Two things cause that: nobody can judge grams from a picture, and no camera can see the oil that went into the pan.

Mananu fixes both. The scale supplies exact grams. The camera is used only for what it is good at — working out what the food is. And the app can capture cooking fat by weighing the pan before and after, which is the single largest correctable error in the category and something no photo-only app can ever do.

## Layout

```
app/                      Flutter app
  lib/core/bia/           Published BIA equations + the honesty layer
  lib/core/nutrition/     Per-100g model, running-tare weighing, yield factors, recipes
  lib/core/scale/         Driver abstraction, byte parsers, the vendor driver, pairing
  lib/core/data/          Drift schema, repositories, sync, Riverpod wiring
  lib/core/auth/          Sign-in that links the anonymous user
  lib/core/billing/       Plus, through RevenueCat
  lib/core/health/        Apple Health / Health Connect into observations
  lib/features/           Screens
  lib/theme/              Tokens and instruments — every colour, type size and drawn piece
  test/                   Unit, repository and widget tests; a screenshot harness
supabase/
  migrations/             Schema with RLS, consent records, real deletion
  functions/identify-food AI identification, cached and metered by tier
  functions/revenuecat-webhook  Store entitlements into public.entitlements
vendor/                   The scale vendor's SDKs and demos, as shipped
design/                   The screens on a Claude Design canvas, generated from the tokens
scripts/
  verify_core.py          Independent check of the maths and the byte parsing
  build_food_db.py        CoFID + USDA -> offline SQLite
docs/                     Factory, name, claims, compliance, runbook, review notes, privacy policy
```

## Three design decisions worth knowing about

**1. Every displayed number carries its provenance.**
`ProvenanceBadge` distinguishes weighed from estimated everywhere a quantity appears, and every body metric shows the equation that produced it plus that equation's published standard error. The app never prints a body-fat percentage to two decimal places, because a foot-to-foot scale does not have that precision.

**2. Metrics with no scientific basis are not computed.**
There is no `visceralFatRating` and no `metabolicAge` in this codebase. Visceral fat from a foot-to-foot scale has no published algorithm and no validation; metabolic age is a restatement of BMR against a population table. Bone mass *is* computed, and labelled `Derived.notMeasured`, because bone mineral is effectively invisible to a 50 kHz current.

**3. The vendor SDK is behind an interface.**
The scale is made by Shenzhen Unique Scales (Lefu). Their SDK is a closed binary requiring an appKey, an appSecret and an encrypted licence blob. `ScaleDriver` means the app can be built, tested and reviewed with `SimulatedScaleDriver` before any of that arrives, that a lapsed licence does not brick the product, and that a second-source scale is a new adapter rather than a rewrite.

## Running it

```bash
cd app && flutter pub get && flutter test && flutter run
python3 ../scripts/verify_core.py
```

No hardware and no vendor credentials required.

## Status

| Done | Waiting on the factory |
|---|---|
| BIA engine, tested against published coefficients | Model code and electrode configuration |
| Frame parsers for four protocols, tested against captured frames | The 40-byte result frame map (for impedance over raw BLE) |
| Portion engine: running tare, yield factors, cooking fat, calibration | Impedance encoding for the segmental values |
| Supabase schema, RLS, consent, deletion | appKey / appSecret / lefu.config |
| Vision endpoint with caching and metering | |
| Today, Body, Weigh, Onboarding, Settings screens | |

Wiring the real driver is about a day's work once the credentials land. See `docs/05-runbook.md` §4.
