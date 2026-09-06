# Hand-off — build plan

For a fresh Claude Code session. Read `CLAUDE.md` first; it holds the standing rules. This file is the work.

**How to start:** open this folder in Claude Code and say —
> Read CLAUDE.md and HANDOFF.md. Run `flutter test` and `python3 scripts/verify_core.py` and confirm both pass. Then start Phase 1 and work phase by phase, stopping at each acceptance check for me to review.

Everything needed to finish the app is in this repo or in this document. Nothing depends on the conversation that produced it.

---

## Where things stand

| Built and tested | Not built |
|---|---|
| BIA engine — Sun 2003, Kyle 2001, Deurenberg 1991, Janssen 2000, Cunningham 1980, Mifflin-St Jeor, each with its published standard error and validity bounds | Real vendor driver (`PpBluetoothKitChannel` is a documented stub) |
| Frame parsers for four BLE protocols, tested against captured ground-truth frames | The `core.sqlite` data file itself — the pipeline is built and tested; run it where gov.uk and usda.gov are reachable (Phase 2) |
| Portion engine — running tare, yield factors, cooking-fat capture, personal calibration | |
| **Offline food search, barcode lookup, "from the pack" foods — Phase 2, code done.** FTS5 catalogue with exact/prefix ranking, user foods first, Open Food Facts cached per user | |
| **Photo identification, end to end.** Consent → camera → 512 px → `identify-food` → catalogue match → weigh. Never asks for grams. Tested with a fake identifier; needs the function deployed for real replies | |
| Supabase schema: RLS, consent records, cascade deletion, vision cache and metering, `observations` | Recipes UI (the model exists, no screen; a design is on the canvas) |
| **Local persistence (Drift) and background sync — Phase 1, done.** Every screen reads SQLite; meals, readings, profile and consent survive a restart; unsynced rows push when a session exists, last-write-wins on `updated_at` | RevenueCat / paywall |
| Vision Edge Function — cached, metered, context-enriched | Health Connect / HealthKit sync |
| Today, Body (with a 30-day trend chart), Weigh food, Onboarding, Settings screens | Sign-in beyond the anonymous session (Phase 4) |
| Design system in `theme/tokens.dart`, and the screens on a Claude Design canvas (`design/`) | |
| 40-check independent verification of the maths and byte parsing; repository and sync tests on an in-memory database | |

## Start here

```bash
cd app
flutter pub get
flutter test          # must be green before you change anything
flutter run           # runs on SimulatedScaleDriver — no hardware needed

python3 ../scripts/verify_core.py   # 40 checks, no toolchain required
```

If `flutter test` is red on a clean checkout, fix that before starting a phase.

---

## Phase 1 — Persistence and sync

**Done.** What was built, and where:

- `app/lib/core/data/db/` — Drift schema mirroring `supabase/migrations/` column for column, plus `observations`. Every synced row has a client-generated uuid, `updated_at`, and a local `synced_at` that records the *version* pushed, not a time, so clock skew between phone and server cannot make a row look dirty. Deletions are tombstones (`deleted_at`) so they sync.
- `app/lib/core/data/repositories/` — `ProfileRepository`, `MealRepository`, `BodyRepository`, `ObservationRepository`. SQLite only; the UI never awaits the network. A body reading stores the raw inputs (height, age, sex snapshotted), the derived figures with their equation, and one observation row each for weight, impedance and body fat.
- `app/lib/core/data/sync/` — `SyncEngine` pulls then pushes (that order is what makes last-write-wins safe), driven by `syncTables` in `database.dart`; `SyncScheduler` runs it after every local write, on resume, and every minute. `SupabaseSyncRemote` signs in anonymously on first contact so the diary is backed up from day one; Phase 4 links that user to Apple/Google/email without re-keying a row. Enable **anonymous sign-ins** in the Supabase dashboard (Authentication → Providers).
- `supabase/migrations/0003_observations_and_sync.sql` — the `observations` table, and `updated_at`/`deleted_at` on every synced table.
- Build with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`. Without them the app is local-only and Settings says so.
- Tests: `app/test/data/`. Run `flutter test`.

**Acceptance (for the founder to check on a device):** log a meal in aeroplane mode, force-quit, reopen — the meal is there with the small cloud-off mark. Reconnect, and it lands in Supabase within a minute; the mark clears and Settings → Backup reads "Everything is backed up."

The original plan follows, kept for the reasoning.

**Do this first, because it shapes everything after:** add an `observations` table (Drift and Postgres) —

```sql
create table observations (
  id uuid primary key, user_id uuid not null, taken_at timestamptz not null,
  kind text not null,          -- 'weight_kg','impedance_ohm','body_fat_pct','resting_hr_bpm',
                               -- 'hrv_rmssd_ms','sleep_min','steps','vitamin_d_25oh_nmol_l', ...
  value numeric not null, unit text not null,
  source text not null,        -- 'mananu_body_scale','mananu_kitchen_scale','apple_health',
                               -- 'health_connect','oura','whoop','garmin','partner_lab:<name>'
  device_id uuid, method text, confidence text,
  reference_low numeric, reference_high numeric, reference_source text,
  raw jsonb, created_at timestamptz default now()
);
create index on observations (user_id, kind, taken_at desc);
```

This is a cut-down FHIR `Observation`. Raw scale readings go in here; `body_measurements` keeps the *derived* composition figures and their provenance. When wearables and lab results arrive in later phases they are new `source` values, not new tables, and the trend chart that works for body fat works for ferritin unchanged.

**Then:**

1. Add Drift tables mirroring `supabase/migrations/0001_init.sql` — `observations`, `body_measurements`, `meals`, `meal_components`, `foods`, `recipes`, `daily_targets`. Keep column names identical to the Postgres schema; it makes the sync layer boring, which is what you want.
2. Every row gets `synced_at` (nullable) and a client-generated `uuid` primary key, so a row created offline keeps its identity when it reaches the server.
3. Write repositories that read and write Drift only. The UI must never await the network.
4. A background sync that pushes unsynced rows and pulls anything newer. Last-write-wins on `updated_at` is fine — this is a single-user diary, not a collaborative document.
5. Replace the `StateProvider`s in `core/data/providers.dart` with `StreamProvider`s over Drift queries.

**Acceptance:** log a meal in aeroplane mode, force-quit, reopen — the meal is there and marked unsynced. Reconnect, and it lands in Supabase within a minute.

**Watch for:** snapshot the user's height, age and sex onto each measurement row (`height_cm_at_time`, `age_years_at_time`, `sex_at_time`) as the schema already provides. Without that, a birthday silently rewrites the user's history the next time anything recomputes.

---

## Phase 2 — The offline food database

**Built; the data file is the one step left, and it needs a machine that can reach gov.uk and usda.gov** (the build session's egress policy blocks both, and openfoodfacts.org).

What exists:

- `scripts/build_food_db.py` — real loaders. CoFID: reads the Proximates and Inorganics sheets by header name, `Tr` and `N` become NULL, salt is sodium × 2.5, drinks are flagged `per_100ml`. USDA: joins `food.csv` to `food_nutrient.csv` (via `nutrient.csv` ids), skips branded rows. FTS5 index plus `name_norm`/`name_len` for ranking; attribution and provenance in `meta`. `--verify` times the acceptance query. Tests: `python3 scripts/test_build_food_db.py` (fixtures in the published layouts).
- `app/lib/core/food/` — `FoodCatalog` opens the asset read-only (copied out of the bundle once, re-copied when it changes), searches with exact > prefix > mid-word ranking, UK rows first; `FoodSearch` merges the user's own foods (first) with the catalogue, or a starter list when the build has none; `OpenFoodFactsClient` with the required User-Agent, 15 requests a minute, and a pure parser.
- `UserFoodRepository` — "from the pack" foods and barcode hits, synced like everything else. Recent foods come from meal components, so the empty search shows what the person actually eats.
- Weigh food → Search: live results, barcode button (`mobile_scanner`, EAN/UPC only), "Add from the pack" form. A scan checks the user's cache, then Open Food Facts, then falls back to the form with the barcode attached so the next scan is instant.

**To finish, on your machine:**

```bash
# 1. Download (both are free; the CoFID link is the 2021 xlsx, the USDA links
#    are the "CSV" zips — Foundation, SR Legacy, FNDDS). Keep them in data/.
# 2. Build and check:
pip install openpyxl
python3 scripts/build_food_db.py --cofid data/cofid_2021.xlsx \
    --usda data/usda_sr_legacy data/usda_foundation data/usda_fndds
python3 scripts/build_food_db.py --verify     # expects "chicken breast" < 100 ms, PASS
git add app/assets/food/core.sqlite && git commit -m "Ship the offline food database"
```

If a CoFID column is not found, the script says which; the loader matches headers by prefix and the 2021 workbook's are listed in `PROXIMATES`.

**Acceptance (unchanged):** aeroplane mode, search "chicken breast", get a UK CoFID row with per-100 g figures in under 100 ms. The in-app ranking test runs the same query over 4,000 rows in a few milliseconds.

The original plan follows.

**Do:**

1. `load_cofid()` — parse the CoFID 2021 workbook. Per 100 g of edible portion. Two things to get right: `Tr` means trace and `N` means "present but no reliable value" — **store NULL, not 0**, because coercing them is how a food log quietly under-reports. And alcoholic drinks are per 100 ml, not per 100 g.
2. `load_usda()` — join `food.csv` to `food_nutrient.csv` on `fdc_id` and pivot the nutrient IDs you need (208 energy kcal, 203 protein, 205 carbohydrate, 204 fat, 291 fibre, 269 sugars, 606 saturates, 307 sodium).
3. Ship the result at `app/assets/food/core.sqlite`, opened read-only alongside the writable Drift database.
4. Search: FTS5 over name and brand, ranked so exact and prefix matches beat mid-word ones. A user typing "chick" wants chicken breast, not chickpea flour.

**Acceptance:** aeroplane mode, search "chicken breast", get a UK CoFID row with per-100 g figures in under 100 ms.

**Then barcode:** `mobile_scanner` for the scan, Open Food Facts `/api/v2/product/{barcode}.json` for the lookup, cache the result into the user's own foods. Open Food Facts requires a custom User-Agent and rate-limits to about 15 requests a minute. **Keep barcode free** — MyFitnessPal and Lose It! both paywalled theirs in 2026 and took the backlash; ours costs nothing.

---

## Phase 3 — The vendor driver

**No longer blocked.** The vendor's SDK source is vendored under `vendor/` and documented from that source in `docs/10-sdk.md`. Two things changed on reading it: credentials are **self-service** on the Lefu Open Platform (register, add the device models, download `lefu.config`), and the vendor's demos ship working demo credentials that are fine for testing against a unit on the desk. You can start this phase the day a scale arrives. Production still needs the founder's own AppKey/AppSecret/config — never ship the demo keys.

What is needed, and who to ask — the full list with wording is in `docs/01-factory.md`, and the engineering questions go to `yanfabu-5@lefu.cc`, not to the sales contact:

- `appKey`, `appSecret`, `lefu.config`
- Which `PPDevicePeripheralType` family and protocol generation (2.x / 3.x / 4.x / Torre) the model is
- The Android SDK artifacts — `com.lefu.*` is **not** on Maven Central or the Aliyun mirror, it is handed out through their open platform
- The impedance encoding: the SDK emits a scalar `impedance` plus ten `z100Khz*EnCode` / `z20Khz*EnCode` segmental values. `EnCode` means encoded, not ohms. Without the decode, segmental analysis cannot ship
- Written confirmation on whether `lefu.config` expires, whether `initSdk` touches the network, and which hostnames the SDK contacts

**When they arrive:**

1. Uncomment `pp_bluetooth_kit_flutter` in `pubspec.yaml`. Prefer a path dependency on `../vendor/pp_bluetooth_kit_flutter` so the build is reproducible; the git ref is the fallback.
2. Put `lefu.config` in `assets/`, add it to the asset manifest, and **add it to `.gitignore`** — it is a licence artefact, not source.
3. Implement `PpBluetoothKitChannel` in `core/scale/lefu_driver.dart`. The 51 method-channel calls are documented; you need `initSDK`, `startScan`, `stopScan`, `connectDevice`, `disconnect`, the measurement stream, `toZero`, `impedanceSwitchControl` and `fetchDeviceInfo`.
4. Flip two lines in `core/data/providers.dart` to return `LefuScaleDriver`.

`LefuScaleDriver.parseMeasurement` is already written and pure, so you can unit-test it against a captured payload dictionary before any hardware exists. Read `docs/10-sdk.md` first — it has the real method names, the `weight` unit trap (kg×100 for body, tenths of a gram for kitchen), and the `completed` state that is the stability signal.

**Fallback if credentials are slow:** `core/scale/frames.dart` already parses the Lefu FFB0/AC02 protocol from published reverse-engineering. Over `flutter_blue_plus` you can read weight today with no vendor licence at all — service `0xFFB0`, notify `0xFFB2`, write `0xFFB1`, and `LefuFfb0Parser.handshake()` returns the five command frames in order. Impedance still needs their frame map.

**Acceptance:** a real scale connects, live weight streams to the readout, one stable reading is logged per measurement (not five), and impedance reaches `BodyCompositionEngine`.

---

## Phase 4 — Accounts, consent, entitlements

1. Supabase auth: **Sign in with Apple** (required by guideline 4.8 if you offer any third-party login), Google, and email OTP.
2. Wire the onboarding consent step to `public.consents`. One row per grant **or withdrawal**, never an update — the history is the evidence.
3. Settings: withdrawing consent must be as easy as giving it. On withdrawal, stop computing composition and offer to delete existing measurements. Weight and food logging keep working.
4. In-app account deletion calling `public.delete_my_account()`. Mandatory under Apple 5.1.1(v), and Article 17 is not satisfied by a soft-delete flag.
5. CSV export of everything.
6. RevenueCat: free tier and Plus. Mirror entitlements into `public.entitlements` from the webhook — **the app never decides its own tier**.
7. ~~A separate, explicit consent before the first photo scan, naming the AI provider.~~ **Done.** `PhotoIdentifySheet` asks before the first scan and names the provider (`--dart-define=VISION_PROVIDER=...`, default "Google (Gemini)" to match the function's default model); Settings → Photo recognition switches it, each flip a new consent row. The scan itself is live end to end once the Edge Function is deployed (runbook §3): 512 px on device, context sent, candidates matched to the catalogue, grams from the scale. In a build with no backend the sheet says so and search still works.
8. Keep the local database out of iCloud. Android is done (`allowBackup="false"` and data-extraction rules in the manifest). iOS needs `NSURLIsExcludedFromBackupKey` set on `mananu.sqlite` from native code — a few lines in `AppDelegate.swift` behind a method channel, or a tiny plugin. See `AppDatabase.open()`.
9. Link the anonymous user created by sync to the real sign-in (`linkIdentity` / `updateUser`), rather than creating a second user, so nothing is re-keyed.

**Acceptance:** two accounts on one device see strictly separate data. Deleting an account leaves no rows anywhere, verified in SQL.

---

## Phase 5 — Wearable data in, from day one

The roadmap includes a WHOOP-style band. **Do not build one for launch** — the scale factory does not make wearables, white-label bands are poor, and a poor band next to a good scale drags the brand. Instead, ingest the data users already have:

1. **HealthKit** (iOS) and **Health Connect** (Android): sleep, resting heart rate, HRV, steps, workouts, and write back weight and body fat as *measured* values only. Build on Health Connect, not Google Fit — Fit is supported only to end of 2026. Health Connect needs its own declaration and a privacy policy that matches the one shown at the Health Connect link.
2. **Direct integrations**, in order of UK user base: Garmin, Oura, WHOOP, Fitbit, Polar, Withings. Each is an OAuth flow and a mapping into `observations`. Oura and WHOOP have clean REST APIs; Garmin requires a developer programme application — start it early.
3. Every imported value lands as an observation with `source` set, so the user can always see which device said what.

**Acceptance:** a user with an Oura ring connects it, and last night's HRV appears in Mananu next to this morning's body fat, on the same timeline, with the source labelled.

**Guardrails:** Apple 5.1.3(i) — health data never reaches an analytics or ad SDK. Google April 2026 policy — never use health data for employment or insurance eligibility. Neither is a temptation; both must be in the privacy policy.

## Phase 6 — Finishing the loop

- **Recipes screen.** The model in `core/nutrition/portion.dart` is complete and tested; it needs a UI. This is the highest-retention feature in the product: weigh the ingredients once, then log a portion by weight forever. Make sure the user weighs the *finished dish* for `yieldGrams` — water boils off and fat renders out, and using the ingredient sum understates concentration on every portion, forever.
- **Personal calibration.** `PersonalCalibration.fit` is written. Feed it the `(estimated_grams, weighed_grams)` pairs the schema already indexes for. Surface it as "we've learned your usual portion" once there are five samples for a food.
- **Charts.** `fl_chart` is in `pubspec.yaml`. Body screen wants the rolling median as a line with raw readings as faint dots behind it — the trend is the signal, the dots show the noise honestly.
- **Widgets and a watch complication** — later, but the daily weigh-in is a good widget.

---

## Constants, so nothing is lost

Everything below is already implemented and tested. Reproduced here so this document stands alone if the source is ever refactored.

### BIA equations

`Ht` cm, `Wt` kg, `Age` years, `R` and `Xc` ohms at 50 kHz, `sex` male = 1 / female = 0. `RI = Ht²/R`.

```
Sun 2003 FFM (default — needs only R)         valid age 12–94
  male:    -10.68 + 0.65·RI + 0.26·Wt + 0.02·R      RMSE 3.9 kg
  female:   -9.53 + 0.69·RI + 0.17·Wt + 0.02·R      RMSE 2.9 kg

Kyle 2001 FFM (needs reactance)               valid age 20–94, BMI 17.0–33.8
  -4.104 + 0.518·RI + 0.231·Wt + 0.130·Xc + 4.229·sex        SEE 1.72 kg

Deurenberg 1991 FFM (BIA)                     valid age 7–83
  -12.44 + 0.34·RI + 0.1534·Ht + 0.273·Wt - 0.127·Age + 4.56·sex   SEE 2.63 kg

Deurenberg 1991 body fat % from BMI (no impedance)
  adult (>15):  1.20·BMI + 0.23·Age - 10.8·sex - 5.4          SEE 4.1 %
  child (<=15): 1.51·BMI - 0.70·Age -  3.6·sex + 1.4          R² only 0.38 — never display

Sun 2003 total body water (litres)
  male:   1.20 + 0.45·RI + 0.18·Wt
  female: 3.75 + 0.45·RI + 0.11·Wt
  fallback with no impedance: TBW ≈ 0.732 × FFM

Janssen 2000 skeletal muscle mass (vs MRI)    SEE 2.7 kg
  0.401·RI + 3.825·sex - 0.071·Age + 5.102

Mifflin-St Jeor RMR (published combined form)
  9.99·Wt + 6.25·Ht - 4.92·Age + 166·sex - 161

Cunningham 1980 RMR from fat-free mass
  500 + 22·FFM
  (Preferred over Katch-McArdle, which is textbook-only with no primary paper.)

Activity, from the NASEM 2023 DRI bands — band midpoints, not fitness-app lore:
  inactive 1.35 · low active 1.65 · active 1.85 · very active 2.20
```

Plausible adult resistance is **200–1200 Ω**. Outside that the electrodes did not make contact: fall back to weight-only and say why.

Worked check for 178 cm, 80 kg, 34 y, male, R = 500: RI = 63.368, Sun FFM = 61.3092, Janssen SMM = 31.9236, Mifflin RMR = 1749.42.

### BLE — Lefu FFB0 "AC02"

Service `0xFFB0`; `FFB1` write-without-response, `FFB2` notify, `FFB3` indicate. Advertised manufacturer ID `0x02AC`.

```
Frame, fixed 8 bytes:   AC 02 | D0 D1 D2 D3 | STATUS | CKSUM
CKSUM = (D0 + D1 + D2 + D3 + STATUS) & 0xFF
Weight frame:           AC 02 [wt_hi] [wt_lo] 00 00 [STATUS] [CKSUM]
                        weight_kg = uint16_BE / 10
STATUS 0xCE = measuring · 0xCA = stable

Ground truth:  ac 02 03 49 00 00 ca 16  ->  0x0349 = 841 -> 84.1 kg, stable

Handshake — enable notify on FFB2 (CCCD 0x0019 <- 0100), then write to FFB1:
  ac02 fa01 0000 cc c7
  ac02 fb02 1fa5 cc 8d
  ac02 fde2 0101 cc ad
  ac02 fc01 0000 cc c9
  ac02 fe06 0000 cc d0
```

Body composition arrives separately in a 40-byte type-`0xFF` result frame split across two notifications. **The impedance offsets inside it are not publicly decoded** — that is factory question 6.

Also implemented: Qingniu/QN (opcode `0x10`, weight `[3:5]` BE, stable `[5]`, R1 `[6:8]`, R2 `[8:10]`, negotiated divisor), Xiaomi MIBFS (13-byte advertisement under service data `0x181B`, impedance `[9:11]` LE ohms, weight `[11:13]` LE ÷ 200, flags bit1 impedance / bit5 stabilised / bit7 removed), and the Bluetooth SIG Weight Measurement characteristic (`0x2A9D` under `0x181D`, SI resolution 0.005 kg).

### Vision endpoint

Model: a Flash-Lite class model. Image downscaled to 512 px on device before upload. Cached by SHA-256 of the image bytes plus hint, shared across users because the cache holds no personal data. Free tier 30 scans/day, Plus 400.

The prompt asks for identification only — name, 2–4 database search queries, cooked or raw, rough mass share, and any likely absorbed cooking fat. **It explicitly forbids the model from estimating grams, calories or macros.** Context sent alongside: local time, locale, measured grams if known, the user's recent foods. That context is worth more than a bigger model — a published benchmark found it cut calorie error by about 76 kcal on average.

UK naming in the prompt: courgette not zucchini, aubergine not eggplant, mince not ground beef, rocket not arugula, coriander not cilantro.

### Yield factors (cooked mass ÷ raw mass)

```
pasta dry 2.2 · white rice 3.0 · brown rice 2.7 · lentils 2.4 · oats 3.0
chicken breast 0.73 · beef mince 0.72 · salmon 0.79 · potato 0.95
```

Logging 225 g of cooked rice against a dry database row overstates it by 534 kcal. That is what this table prevents.

### Error model

Per component, combined in quadrature — not summed, because the terms are independent:

```
quantity error:  weighed 1% · manual grams 10% · household measure 20% · photo estimate 25%
identity error:  reference dataset 5% · model guess 18%
```

The day's "% weighed" is **by calories, not by item count**. One small weighed item and one large guess must not read as 50%.

---

## Definition of done

- `flutter test` green; `python3 scripts/verify_core.py` reports 40/40
- `flutter analyze` clean
- Works fully offline: log a meal, take a body reading, see the trend, all in aeroplane mode
- Two accounts on one device see strictly separate data; deletion removes every row
- A review account can complete the whole flow on `SimulatedScaleDriver` with no hardware
- No accuracy percentage anywhere in the UI or store listing
- No `visceralFatRating`, no `metabolicAge`, no call to `uniquehealth.lefuenergy.com`

## In parallel — not code, but on the critical path

Someone has to do these; they gate the launch more than the app does.

1. **D-U-N-S number.** Free, up to two weeks, and an Apple organisation account cannot exist without it. Health apps must be submitted by a legal entity, not an individual (guideline 5.1.1(ix)).
2. **Ask the factory for UK and Ireland exclusivity** before confirming the order. Scanfit holds Denmark, Norway, Sweden, Holland, Finland and the US; the UK and the large EU markets are unclaimed. Without a clause you will be competing against three other importers of the same unit within a year. See `docs/01-factory.md` §1.
3. **Trademark attorney** — UK and EU clearance, Classes 9, 5, 10, 35. The EU register could not be checked reliably from here and is genuinely unverified.
4. **Privacy policy and DPIA.** Body composition is Article 9 special-category data; a DPIA is effectively mandatory.
5. **Technical file, Declaration of Conformity, PSTI statement, WEEE and battery registration.** Putting your brand on their product makes you the manufacturer in law. `docs/04-compliance-uk.md` has the full list.
