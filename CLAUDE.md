# Project context for Claude Code

Read this before touching anything. It is the standing context for the repo; `HANDOFF.md` is the build plan.

## What this is

**Mananu** is a personal health-data platform. It launches as a Bluetooth body-composition scale, an AI kitchen/nutrition scale, and the Flutter app that ties them together — UK-first, direct to consumer. The stated roadmap is: wearable data (ingested from Apple Health, Health Connect, Oura, WHOOP, Garmin from day one; our own band later), then at-home blood tests through an accredited lab partner, then data-driven supplements. `docs/07-vision-and-roadmap.md` has the stages and what each one costs in regulation.

The consequence for the code: **build the data layer for stage 4 today.** Every measurement — a scale reading, a night's HRV, a ferritin result — is an *observation* with a kind, a value, a unit, a source and a reference range. One model, many sources. Do not create a new table per device type.

Hardware is white-label from **Shenzhen Unique Scales Co., Ltd** (Chinese name 深圳市乐福衡器有限公司, trades as Lefu). They are a real ODM — VeSync/Etekcity and Ozeri are clients, and Xiaomi ships a scale whose internal model ID is `lefu.scales.cf822`.

## The one idea the whole product rests on

Photo calorie apps have to guess how much is on the plate, and that guess is where the error lives. We own a scale, so we don't guess.

A controlled-feeding study presented at NUTRITION 2026 measured the leading apps against 102 standardised meals weighed to 0.1 g: all underestimated, by **250–345 kcal per meal**, with fat under-reported by roughly 30 g. Split that error three ways:

| Source | Who fixes it |
|---|---|
| **Identification** — what is it | The camera is good at this |
| **Quantity** — how much | The scale solves it completely |
| **Cooking fat and preparation** | Nobody, currently — and it is the largest share |

So the camera is used **only** for identification. Quantity always comes from hardware. And the app attacks the third bucket with a workflow no photo app can copy: weigh the pan, weigh the oil, weigh what's left.

If a change would make the app estimate a quantity that could have been measured, it is the wrong change.

## Hard rules

These are product and legal commitments, not preferences. Do not relax them without asking.

1. **Never ask a vision model for grams, calories or macros.** Identification only. This is the cost control and the accuracy claim at the same time.
2. **Never call `uniquehealth.lefuenergy.com` with user data.** That is the vendor's cloud body-composition endpoint; it takes age, sex, height, weight and impedance to a server in the PRC. Article 9 special-category data, no adequacy decision, no SCCs. All composition maths runs on device.
3. **No `visceralFatRating`. No `metabolicAge`.** Neither has a published algorithm or any validation for a foot-to-foot scale. Competitors print them; we do not. If a stakeholder insists, they go behind an explicit "unvalidated estimate" label — never into `BodyCompositionEngine`.
4. **Every displayed number carries its provenance.** Weighed vs estimated, and for body metrics the equation that produced it plus that equation's published standard error. `ProvenanceBadge` exists for this.
5. **Never publish a single headline accuracy percentage.** Accuracy depends entirely on the meal. Cal AI published 90%, then quietly moved to 80%. See `docs/03-accuracy-claims.md` for what may and may not be claimed.
6. **Equation coefficients are transcriptions of published papers.** Do not tune, round or "improve" them. If a number changes, a test fails — that is the design.
7. **Store every measurement as an observation.** `kind / value / unit / source / taken_at / reference range / raw payload`. Scale, wearable and lab data are the same shape. A new source is a new adapter, never a new table. See `docs/07-vision-and-roadmap.md` §"Build for stage 4 on day one".
8. **Never let a test result drive a purchase without its reference range shown beside it.** "Your vitamin D is 32 nmol/L, below the NHS range" is a fact. "You are deficient, buy this" is a medical claim that makes the app a medical device. The platform's credibility rests on this line.
9. **Keep `SimulatedScaleDriver` working and in the release build.** App Review cannot test a Bluetooth scale they do not have; not giving them a route through the flow is the most common cause of rejection loops for hardware companion apps.

## Architecture

```
app/lib/core/bia/          Published BIA equations + the honesty layer over them
app/lib/core/nutrition/    Per-100g model, running-tare weighing, yield factors
app/lib/core/scale/        Driver interface, byte parsers, vendor adapter
app/lib/core/data/         Riverpod wiring, Drift schema, repositories, sync
design/                    The screens on a Claude Design canvas; generated from tokens.dart
app/lib/features/          Screens
app/lib/theme/tokens.dart  Design system — read before writing any UI
supabase/migrations/       Schema, RLS, consent, real deletion
supabase/functions/        Vision endpoint
scripts/verify_core.py     Independent check of the maths and byte parsing
docs/                      Factory, name, claims, compliance, runbook
```

`ScaleDriver` is the boundary. Nothing above it knows the vendor's name, the `PP` class prefix, or that a licence blob exists. That matters commercially: the SDK needs an appKey, an appSecret and an encrypted `lefu.config` to initialise, so if the licence lapses or the hardware is second-sourced, the replacement slots in behind the interface and nothing else moves.

## Conventions

- **Dart:** `flutter_lints` plus the extra rules in `analysis_options.yaml`. Trailing commas, `const` where possible, explicit return types.
- **State:** Riverpod. The app is mostly streams — a live weight, a day's log — and `StreamProvider` maps onto that.
- **Comments explain *why*.** The equations and byte offsets are meaningless without their source; every one names the paper or the capture it came from. Do not strip these.
- **Tests:** anything numeric gets a test with the expected value computed by hand from the published coefficients. Repositories and sync are tested on an in-memory database. `flutter test` must pass before any commit.
- **Schema changes:** edit `app/lib/core/data/db/tables.dart` and the matching `supabase/migrations/` file together, then `dart run build_runner build --delete-conflicting-outputs`. Column names are identical on both sides; keep them so.
- **UI:** all colour and type from `theme/tokens.dart`. `MananuColors.measured` and `.estimated` are reserved for provenance and used for nothing else.
- **Local-first.** Every log works offline and syncs later. A food diary that needs signal is a food diary people abandon on day three.

## The brand name is Mananu

Decided 6 September 2026 after three screening rounds (~130 names). Mananu was the only clean candidate with no known conflict of any kind — no phonetic twin, no namesake company in an adjacent field, no famous-name owner, no circling registrations. Registers checked: US (Justia/TSDR), UK (Trademarkia mirror, control-tested), Companies House, RDAP for domains. EUIPO is unverified and is with the attorney. Details in `docs/02-name-and-domains.md` and `docs/08-second-round-names.md`.

Lowercase wordmark `mananu`; three-stroke mark in `brand/`. Positioning line: **Weigh it. Don't guess it.**

Do not rename unless the founder says so. If that ever happens, from the repo root:

```bash
NEW=Newname; NEWL=$(echo $NEW | tr 'A-Z' 'a-z')
find . -type f \( -name '*.dart' -o -name '*.yaml' -o -name '*.sql' -o -name '*.ts' -o -name '*.md' \) -print0 \
  | xargs -0 sed -i -e "s/Mananu/$NEW/g" -e "s/mananu/$NEWL/g"
```

## Don't

- Add analytics or crash SDKs that receive weight, body fat or meal data. Apple 5.1.3(i) prohibits health data going to ad-adjacent SDKs, and it is the kind of thing that ends up in a news story.
- Write modelled estimates into HealthKit as though they were measured (Apple 5.1.2(ii)).
- Put personal health information in iCloud, including CloudKit-backed local caches.
- Ship Open Food Facts *images* — the data is ODbL, the images are CC-BY-SA, and mixing them creates a share-alike obligation on your image pipeline.
- Let a queried commercial nutrition API's rows land in the embedded offline database. Those licences grant access, not redistribution.
