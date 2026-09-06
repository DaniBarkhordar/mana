# Build and launch runbook

## Stack, and why

| Layer | Choice | Reason |
|---|---|---|
| App | **Flutter** | The factory maintains an **official Flutter plugin** (`LefuHengqi/pp_bluetooth_kit_flutter`). There is no React Native binding. This reverses my earlier advice: choosing Flutter means the riskiest part of the project — bridging a closed vendor SDK natively, twice, and maintaining it — is work the vendor already does. |
| Backend | **Supabase**, London or Frankfurt | Your data is relational (user → measurements over time → components → foods) and Postgres handles that where a document store fights you. Row Level Security gives per-user isolation of health data. Edge Functions keep the AI key server-side. ~$25/month until you are real. |
| Local store | **Drift (SQLite)** | Local-first. A food diary that needs signal is a food diary people abandon on day three. Built: `app/lib/core/data/`. |
| Vision | **A Flash-Lite class model via an Edge Function** | See below — this is the cost decision. |
| Subscriptions | **RevenueCat** | StoreKit and Play Billing are miserable to implement twice. Free until you are past roughly $2.5k/month. |
| Nutrition data | **CoFID + USDA offline, Open Food Facts online** | The only two datasets whose licences permit shipping inside the app binary. See §5. |

## 1. Keeping the AI cheap

Four decisions, in order of impact:

1. **Never ask the model for portion size.** This is the whole point of owning a scale. Every competitor spends most of its accuracy budget — and most of its output tokens — guessing grams from pixels. Asking only "what is this" means a smaller model, fewer output tokens, and a better answer.
2. **Downscale to 512 px on the device before upload.** A food photo at that size is roughly 1–2k image tokens. On a Flash-Lite tier model that is **well under $0.001 per identification** — around 100× cheaper than a specialist food-recognition API, which bills 20–30k tokens per photo.
3. **Cache by image hash.** People photograph the same breakfast for weeks. The cache holds no user identifier, so it is shared across all users, which makes it far more effective than a per-user cache.
4. **Send context, not a bigger model.** A published benchmark found that supplying time of day, locale and the user's recent foods cut calorie error by about 76 kcal on average — more than a model upgrade would. The Edge Function does this.

Practical effect: at 30 free scans per user per month, a thousand active users costs single-digit dollars in inference. Metering exists to stop a runaway client loop, not because the calls are expensive.

**And when the quota runs out, weighing still works.** The scale is the product; the camera is an accelerant. Metering the camera must never block core logging — the Edge Function returns `canStillWeigh: true` rather than an error.

## 2. First run

```bash
# Flutter 3.22+ with Dart 3.4+
cd app
flutter pub get
flutter test                 # BIA equations, frame parsers, portion maths

# No hardware or vendor licence needed — the app runs on SimulatedScaleDriver
flutter run
```

`scripts/verify_core.py` re-implements the same equations and byte parsers independently and asserts the same expected values. It needs no toolchain:

```bash
python3 scripts/verify_core.py
```

## 3. Supabase

```bash
supabase init
supabase link --project-ref <ref>          # create the project in London (eu-west-2)
supabase db push                            # applies migrations/0001, 0002, 0003

supabase secrets set ANTHROPIC_API_KEY=...  # the default provider
supabase functions deploy identify-food
```

The function serves whichever key is present, Anthropic first. Everything else is optional:

| Secret | Default | Meaning |
|---|---|---|
| `VISION_PROVIDER` | `anthropic` if its key is set, else `gemini` | Force one provider |
| `VISION_MODEL` | `claude-opus-5` / `gemini-2.5-flash-lite` | Model for every request |
| `VISION_MODEL_FREE` | same as `VISION_MODEL` | A cheaper model for the free tier only; tier comes from `public.entitlements`, never from the app |

Build the app with a matching `--dart-define=VISION_PROVIDER="Anthropic (Claude)"` (the default) or `"Google (Gemini)"` — that string is what the consent sheet shows, and it has to be true.

**What a scan costs.** The photo is 512 px on its longest edge before upload, which on Claude is a few hundred image tokens; the system prompt is about 600 tokens and the answer about 250. Per identification, at the list prices in `shared` API pricing (June 2026), before the cache:

| Model | Per scan | 30 free scans a day, all month | Typical (3 a day) |
|---|---|---|---|
| `claude-opus-5` ($5 / $25 per MTok) | ≈ $0.011 | ≈ $10 | ≈ $1.00 |
| `claude-haiku-4-5` ($1 / $5 per MTok) | ≈ $0.002 | ≈ $2 | ≈ $0.20 |
| `gemini-2.5-flash-lite` | ≈ $0.0005 | ≈ $0.45 | ≈ $0.05 |

The cache (same bytes, same hint, same model) makes repeat plates free, and empty answers are never charged against the quota. Plus at £4.99 a month covers Opus on every realistic pattern; the free tier's worst case is the number to watch. The lever is `VISION_MODEL_FREE=claude-haiku-4-5`: Plus keeps the strongest model, the free tier runs the economical one, and the app's consent text stays truthful because both are Anthropic. Pure logic (prompt, schema, metering, cache key) is under test:

```bash
cd supabase/functions/identify-food
deno task check && deno task test
```

Then, in the dashboard, Authentication → Providers → **enable anonymous sign-ins**. A fresh install gets an anonymous user on first contact so the diary is backed up from day one; Phase 4 links that user to Apple, Google or an email address.

Build the app with the project's URL and publishable key (a legacy anon key works in the same slot; never a service-role key):

```bash
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Without them the app runs local-only and Settings → Backup says so.

Region matters legally, not just for latency — see `04-compliance-uk.md` §4.

**Verify RLS before you ship anything.** Sign in as two users and confirm each sees only their own rows:

```sql
-- as user A, should return 0
select count(*) from body_measurements where user_id <> auth.uid();
```

## 4. Wiring the real scale

The vendor driver is written against the vendored plugin (`vendor/pp_bluetooth_kit_flutter`, a path dependency) and tested against a fake channel. What it needs from you is the licence:

1. Register on the Lefu Open Platform, add your device models, and download the config (docs/10-sdk.md). Save it as `app/assets/lefu.config` — it is git-ignored, never commit it.
2. Build with the credentials:

   ```bash
   flutter run --dart-define=LEFU_APP_KEY=... --dart-define=LEFU_APP_SECRET=...
   ```

   Without both defines and the file, the app runs on the simulated scale and Settings says "Demo scale".
3. In the app: Settings → Your scales → Body scale → choose the unit from the list (wake it first). Same for the kitchen scale. Pairing is per phone, on purpose: on iOS the identifier is a per-install Bluetooth UUID.

How it behaves, and what to check on the desk the first time:

- **One connection at a time.** The vendor SDK holds a single link. The body scale is connected by default; opening Weigh food hands the radio to the kitchen scale and closing it hands it back (`ScaleConnectionCoordinator` in `core/scale/pairing.dart`). Broadcast-only families (Banana, Jambul, Hamburger, Grapes) do not connect at all.
- **Units.** `PPBodyBaseModel.weight` is kg × 100 on a body scale and tenths of a gram on a kitchen scale, per the vendor's own demos. The raw integer and the device's accuracy class ride along in the measurement map — the first time a unit is on the desk, compare the readout with a known mass and, if it is off by ten, read `accuracy` in the map and adjust `LefuSdkGateway.measurementToMap`.
- **Stability** is the SDK's `completed` state. One stored reading per measurement is the acceptance check; `MeasurementAggregator` is the belt-and-braces guard.
- **Impedance** is the SDK's scalar `impedance`. The 200–1200 Ω plausibility gate in `BodyCompositionEngine` will refuse a wrong scale factor loudly. The `EnCode` segmental values are stored raw and never displayed (factory question 5).
- **Android** needs the vendor's Maven repository, which the plugin's own `build.gradle` declares (`raw.githubusercontent.com/LefuHengqi/PPBaseKit-Android`). The first `flutter build apk` will fetch `com.lefu.*`.
- **Demo scale** stays in every build: Settings → Your scales → Demo scale. That is App Review's route through the flow (CLAUDE.md rule 9), and readings from it are labelled `simulated_scale`.

The vendored plugin carries two one-line Mananu changes, both marked in the source: the app secret is no longer written to the log on initialisation, and a nullable return in `pp_peripheral_dorre.dart` that did not compile as shipped.

If the licence is slow to arrive, `lib/core/scale/frames.dart` already parses the Lefu FFB0/AC02 protocol, Qingniu, Xiaomi MIBFS and the Bluetooth SIG standard service from published reverse-engineering — enough to read weight over `flutter_blue_plus` without any vendor licence at all. Impedance still needs their frame map (question 6 in `01-factory.md`).

## 5. The food database

```bash
pip install openpyxl
python3 scripts/build_food_db.py --cofid data/cofid_2021.xlsx \
    --usda data/usda_sr_legacy data/usda_foundation data/usda_fndds
python3 scripts/build_food_db.py --verify          # "chicken breast" in < 100 ms
python3 scripts/test_build_food_db.py              # loader tests on fixtures
```

Inputs go under `data/` (git-ignored): the CoFID 2021 workbook from gov.uk and the USDA FoodData Central "CSV" zips, unpacked. The output, `app/assets/food/core.sqlite`, is committed and ships in the binary; the app copies it out of the bundle on first run and re-copies when it changes. A build with no file still runs — search covers the user's own foods and a starter list, and the sheet says so.

The licence boundary is enforced in the schema, not just in a comment, because the export job must not be able to get it wrong:

- **Offline core, shipped in the binary:** UK CoFID (Open Government Licence v3.0) + USDA FoodData Central (public domain). These are the only two of the candidate sources whose licences permit redistribution inside an app.
- **Open Food Facts (ODbL):** barcode and UK/EU branded lookups, cached per user. If you ever embed a filtered OFF extract in the binary you are distributing a derivative database and must publish that extract under ODbL — cheap to comply with, but do it deliberately. **Do not ship OFF images**; they are CC-BY-SA, a different licence.
- **Never** let a queried commercial API's data land in the embedded store. Those licences grant access, not redistribution.

CoFID is the right spine for a UK product: "chips", "baked beans", "roast chicken, dark meat" as analytically measured in the UK, not US proxies. Etekcity's competing scale has a US-only barcode database and its reviewer could not find UK supermarket eggs — that is the gap.

**Free barcode scanning is a live differentiator right now.** MyFitnessPal and Lose It! both moved barcode behind their paywalls in 2026 and took the backlash. Open Food Facts costs you nothing.

## 6. Builds

```bash
npm i -g eas-cli    # or use flutter build directly
flutter build ipa --release
flutter build appbundle --release
```

**Start the D-U-N-S number today.** An Apple organisation account requires it, it is free, and it takes up to two weeks. It is the classic blocker that catches everyone, and healthcare apps *must* be submitted by a legal entity rather than an individual (guideline 5.1.1(ix)). Register Google Play as an organisation too, or you face a 14-day closed test before you can release.

## 6a. Looking at the screens without a device

The screenshot tests render the real screens at phone size with a seeded
persona (178 cm, 34, male, a month of readings, three meals). They run as
ordinary tests everywhere; with two environment variables they also write
PNGs and use a real typeface (the test font draws every glyph as a box):

```bash
cd app
MANANU_SHOTS_DIR=/tmp/shots \
MANANU_FONT_PATH=/path/Sans-Regular.ttf:/path/Sans-Bold.ttf \
  flutter test test/screenshots --tags screenshots
```

Text set in an explicit style (the weight readout, app-bar titles, button
labels) still renders as boxes there; that is the harness, not the app.

The design canvas is generated from the same tokens: `python3
design/build_canvas.py` rewrites `design/canvas/`, and `design/README.md` says
how it is published.

## 7. Pricing

Hardware sold outright; no subscription required for core function.

| SKU | Price | Reference |
|---|---|---|
| Kitchen scale | **£69–79** | Etekcity smart nutrition scale is £47 but only 1 g resolution and no AI; Scanfit's is ~£90 |
| Body scale | **£99–119** | Renpho £30 (4-electrode, no nutrition side); Withings Body Scan £350; Scanfit ~£170 |
| **Bundle** | **£149–169** | Scanfit's equivalent bundle is ~£260. Make this the hero SKU — it is the only place your differentiation exists |

**Free forever:** unlimited weighing, unlimited barcode, manual logging, macro targets, body-composition trends, Health sync.
**Plus, £4.99/month or £39.99/year:** unlimited photo recognition beyond 30 scans a month, recipes, personal calibration, export.

That undercuts MacroFactor (~$72/yr), MyFitnessPal ($80/yr) and Cal AI (~£50/yr) while giving away what two of them charge for.

**Do not build a coaching tier.** Scanfit sells one at $599.99/year while marketing itself as "no subscription" — that is precisely what will get them written about, and a one-person company cannot deliver human coaching at scale without inheriting the claim risk that comes with it.

Bundle 12 months of Plus with the hardware, then **lapse to free**. Do not auto-renew at full price: under the incoming DMCCA subscription regime that pattern needs reminders and a fresh cooling-off period, and lapsing is cleaner to operate and a better story.

## 8. Order of work

**This week**
- Reply to Sophia; ask for UK/Ireland exclusivity (`01-factory.md` §1)
- Email `yanfabu-5@lefu.cc` with the engineering questions
- Register the Tier 1 domains (`02-name-and-domains.md`)
- Start the D-U-N-S application
- Instruct a trademark attorney: UK + EU clearance on MANANU, Classes 5, 9, 10, 35

**Next two weeks**
- Place the order on neutral packaging
- Stand up Supabase in London, deploy the Edge Function
- Build the offline food database
- Write the privacy policy and the DPIA

**On credentials arriving**
- Implement `PpBluetoothKitChannel`, swap the driver, test on real hardware
- TestFlight and Play internal testing

**Before first sale**
- Technical file and Declaration of Conformity in your name
- PSTI statement of compliance
- WEEE and battery registration
- Methods page published (`03-accuracy-claims.md`)
