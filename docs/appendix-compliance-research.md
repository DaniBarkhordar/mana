I've completed the research. Here's the report.

---

# UK Consumer Health App (Smart Scale + Food Logging) — Build & Launch Requirements, 2026

**Research date: 25 August 2026.** Figures are USD unless noted. Items marked ⚠️ are unverified or in flux and need a second look before you rely on them.

---

## 0. THE FIVE THINGS THAT WILL ACTUALLY BITE YOU

1. **Body composition data is Article 9 special-category data under UK GDPR.** You need a lawful basis *and* a separate Article 9 condition — realistically **explicit consent (Art 9(2)(a))**. A DPIA is effectively mandatory.
2. **"Body fat %" is safe. "Body fat % indicates your risk of type 2 diabetes" is a medical device.** The line is a claim tied to a *specific disease*, not the measurement itself.
3. **Apple guideline 1.4.1** requires you to *disclose data and methodology supporting accuracy claims for health measurements*. Prepare a written accuracy/methodology statement before you submit.
4. **Putting your brand on a factory's scale makes you the legal manufacturer** in GB and the EU. Full technical file, DoC in your name, UKCA/CE, PSTI statement of compliance, WEEE/battery registrations.
5. **The UK is not the EU for app-store purposes.** DMA link-out rights don't apply. The CMA's steering conduct requirement for Apple was still only at "consultation responses published" as of **14 Aug 2026**.

---

## 1. BACKEND — SUPABASE IN 2026

### 1.1 Pricing (verified from supabase.com/pricing)

| Plan | Price | Key inclusions |
|---|---|---|
| Free | $0 | 50k MAU, 500 MB DB, 5 GB egress, 1 GB storage, 500k Edge Fn invocations, 2M Realtime msgs. **Projects pause after 1 week inactive; max 2 active projects.** |
| **Pro** | **$25/mo** | 100k MAU (then $0.00325/MAU), 8 GB disk (then $0.125/GB), 250 GB egress ($0.09/GB over), 100 GB storage ($0.0213/GB over), 2M Edge Fn invocations ($2/M over), 5M Realtime ($2.50/M over), **$10/mo compute credits**, 7-day backups, email support |
| Team | $599/mo | Same quotas as Pro + **SOC 2 & ISO 27001**, 28-day log retention, 14-day backups, project-scoped roles, SLAs. **HIPAA is a paid add-on here.** |
| Enterprise | Custom | BYO cloud, uptime SLAs, 24/7 |

**Add-ons:** Compute Micro $10/mo (1 GB RAM, 2-core ARM) → 16XL $3,730/mo (256 GB, 64-core). **PITR $100/mo per 7-day retention window.** Custom domain $10/mo. Log drains $60/mo + $0.20/M events. Advanced MFA (Phone) $75/mo first project.

**Realistic year-1 cost:** Pro $25 + Small/Medium compute (~$15–60) + custom domain $10 ≈ **$50–100/mo**. Add PITR ($100/mo) once you hold real user health data — I'd treat that as non-optional for a health product.

### 1.2 EU/UK regions — both available ✅
https://supabase.com/docs/guides/platform/regions

- **London `eu-west-2`** ✅ — pick this for a UK-first product
- **Frankfurt `eu-central-1`** ✅
- Also: Ireland `eu-west-1`, Paris `eu-west-3`, Zurich `eu-central-2`, Stockholm `eu-north-1`

Two gotchas:
- Supabase warns that **"general" region groupings deploy to *an* available AWS region within that area** — always select the specific named region, not a broad group, if you're making a residency statement.
- **Region cannot be changed after project creation.** Migration = new project + `pg_dump`/restore + storage copy. Get this right on day one.

### 1.3 ⚠️ RECENT CHANGE: new API keys (this affects your client code)

https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys

- `anon` → **`sb_publishable_…`**; `service_role` → **`sb_secret_…`**
- **Legacy JWT-based `anon`/`service_role` keys are deprecated by end of 2026.**
- **Breaking detail:** new keys **must be sent in the `apikey` header, not `Authorization: Bearer`.**
- Public (unauthenticated) Realtime connections are now capped at **24 hours** unless upgraded with user auth.

Other 2026 platform changes worth knowing:
- **28 Apr 2026** — tables are **no longer auto-exposed** to the Data/GraphQL APIs by default; you opt in. (Good default for you.)
- **1 Jul 2026** — Postgres 14 EOL; `timescaledb`, `plv8`, `pgjwt` removed.
- **14 Jul 2026** — `realtime` schema locked against modification.
- **23 Jul 2026** — Management API `logs.all` endpoint removed (ClickHouse-backed `logs` endpoint, ClickHouse SQL only) — migration deadline 23 Sep 2026.

### 1.4 RLS patterns for per-user health data

https://supabase.com/docs/guides/database/postgres/row-level-security

Baseline every health table:

```sql
alter table public.measurements enable row level security;
revoke all on table public.measurements from anon, authenticated;
grant select, insert, update, delete on table public.measurements to authenticated;

create policy "own rows: select" on public.measurements
  for select to authenticated
  using ( (select auth.uid()) = user_id );

create policy "own rows: insert" on public.measurements
  for insert to authenticated
  with check ( (select auth.uid()) = user_id );

create policy "own rows: update" on public.measurements
  for update to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

create index on public.measurements (user_id);
```

Non-obvious rules from the docs:
- **Wrap `auth.uid()` in `(select …)`** — lets Postgres cache it per-statement instead of evaluating per row. Big perf difference on time-series measurement tables.
- **Index every column your policies filter on.** Otherwise seq scans.
- `auth.uid()` returns `null` for unauthenticated requests — scope policies `to authenticated`, don't rely on a null comparison failing.
- **"A wrong policy fails quietly"** — no error is raised for an over-permissive policy. Write pgTAP tests asserting user A cannot read user B's rows. Do this; it's the single highest-value test in the codebase.
- `security definer` helper functions: **always `set search_path = ''`** and schema-qualify everything, or you have a privilege-escalation hole.
- **The secret key bypasses RLS entirely.** Never ship it to a client. Note the docs' subtlety: if a request carries a user JWT, it runs under *that user's* RLS even if the client was initialised with a secret key.

### 1.5 Edge Functions — runtime, limits, keeping the LLM key server-side

https://supabase.com/docs/guides/functions/limits

| Limit | Value |
|---|---|
| Runtime | Supabase Edge Runtime, **Deno 2.1-compatible** (all regions) |
| Memory | **256 MB** |
| Wall clock | **150 s** free / **400 s** paid |
| **CPU time** | **2 s per request** ← the one that bites |
| Function size | 20 MB (CLI-bundled) / 5 MB (server-bundled) |
| Functions/project | 100 free / **1,000 Pro** / 2,000 Team |
| Secrets | 100 max, 256-char names, 48 KiB each |
| Blocked | Outbound ports **25 and 587**; no Web Worker APIs; no multithreaded native libs (sharp, libvips) |

**The 2 s CPU limit is not a problem for LLM calls** — waiting on `fetch` is I/O, not CPU. It *is* a problem if you try to resize/process food photos in the function. Do image resizing client-side, or use Storage image transformations.

**Keeping the LLM API key server-side — the pattern:**

```bash
supabase secrets set OPENAI_API_KEY=sk-...          # or ANTHROPIC_API_KEY
supabase functions deploy analyse-meal --no-verify-jwt=false
```

```ts
// supabase/functions/analyse-meal/index.ts
Deno.serve(async (req) => {
  const auth = req.headers.get('Authorization')          // user's JWT
  if (!auth) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,                   // NOT the secret key
    { global: { headers: { Authorization: auth } } }      // runs under user RLS
  )
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return new Response('Unauthorized', { status: 401 })

  const key = Deno.env.get('OPENAI_API_KEY')!             // never leaves the edge
  // ... rate-limit per user, call the model, write result under RLS
})
```

Rules: leave JWT verification **on** (default), derive `user_id` from the verified JWT (never trust a body param), and add a per-user rate limit in Postgres — otherwise one user can burn your entire LLM budget. Also useful: **Background Tasks + ephemeral storage + WebSockets** shipped for Edge Functions (https://supabase.com/blog/edge-functions-background-tasks-websockets) — background tasks let you return a response fast and keep working past the response.

### 1.6 Storage for food photos + signed URLs

https://supabase.com/docs/guides/storage/serving/downloads

- **Private bucket** + RLS policies on `storage.objects`. Path convention `{user_id}/{uuid}.jpg` and a policy matching `(storage.foldername(name))[1] = auth.uid()::text`.
- `supabase.storage.from('meals').createSignedUrl(path, 3600)` — expiry in seconds.
- **Signed URLs are signed with a dedicated internal key**, separate from your Auth JWT signing key — they survive JWT key rotation.
- ⚠️ **Signed URLs cannot be revoked before expiry** (you must contact support). So keep expiries short — 60–300 s for a food photo in a list view, not 7 days.
- Alternative to signing: authenticated GET against `…/storage/v1/object/authenticated/{bucket}/{path}` with the user's JWT.
- **File size limits:** Free **50 MB**; Pro/Team **up to 500 GB**. Set a *global file size limit* in Storage Settings — cap it at ~10 MB so a bad client can't upload video.

### 1.7 Auth

| Method | Notes |
|---|---|
| **Sign in with Apple** | Native flow via `expo-apple-authentication` + `signInWithIdToken` is the recommended path on iOS. ⚠️ **Apple requires you to regenerate the client secret from your `.p8` signing key every 6 months** — put a calendar reminder or you will get a 3am outage. Apple only returns full name on **first** sign-in, and never via the OAuth (web) flow. |
| **Google** | Standard OAuth / native ID token. Triggers Apple guideline **4.8** (see §4). |
| **Magic link / email OTP** | One-time use, 1 hr expiry, 60 s per-user cooldown. |

**⚠️ Critical production gotcha:** Supabase's **built-in email service is limited to 2 emails per hour**. That's a dev-only facility. You *must* configure custom SMTP (Resend / Postmark / SES) before any real user touches magic links or password resets. Project-wide OTP default is 30/hour (configurable). https://supabase.com/docs/guides/auth/rate-limits

Non-configurable IP limits: token refresh 1,800/hr, verify 360/hr, MFA challenge 15/hr, anonymous sign-in 30/hr.

**Recommended auth set for this app:** Sign in with Apple (native) + Google + email OTP. Email OTP alone satisfies Apple 4.8 as the "equivalent option" if you'd rather not ship SIWA — but SIWA is less friction than arguing with review.

### 1.8 Compliance posture
- **DPA** (https://supabase.com/legal/dpa) covers **both EU and UK GDPR**, uses **SCCs + UK Addendum B.1.0**. Explicit clause: *"Where Customer directs Supabase to Process Covered Data in a specific geographical region, Supabase shall ensure that such Covered Data is stored and primarily Processed in that region."* — that's the sentence your DPIA cites.
- **SOC 2 Type 2 + ISO 27001 require the Team plan ($599/mo)**. Pro does not carry the certification. If you need to hand a SOC 2 report to a partner, that's a real $7k/yr line item.
- Sub-processor list: https://supabase.com/legal/customer-resources/subprocessor-list — 30 days' notice of changes. **Subscribe to it**; you must keep your privacy policy in sync.

### 1.9 Honest verdict vs alternatives

**Stay on Supabase.** For this product it's the right call, for three specific reasons: Postgres RLS is the single best tool available for per-user health-data isolation and it's *auditable* (you can show a regulator the policy); London region is a first-class option; and the DPA already has the UK Addendum. Nothing else on your list beats it on all three.

Per alternative:

- **Firebase** — ⚠️ **Firebase Authentication has no EU data residency.** You can pin Firestore to `europe-west2` (London), but Auth identity data is processed in the US regardless. For an Article 9 product that's an awkward paragraph in your DPIA for no benefit. Also: security rules are weaker and harder to test than RLS. **Don't.**
- **AWS Amplify** — genuinely fine on residency (eu-west-2) and the most defensible for enterprise procurement later. But it's 3–5× the setup and ops effort of Supabase, and Gen 2 churn has been real. Only worth it if you already have AWS expertise on the team.
- **Convex** — excellent DX, best-in-class reactivity, and its function-level auth model is arguably cleaner than RLS for app code. Two problems for you: EU/UK region support is weaker and less mature than Supabase's ⚠️ (verify current self-host/region options directly), and you'd be handing a novel proprietary datastore to a regulator instead of "it's Postgres." Not worth the story cost here.
- **Neon + Hono** — the "adult" option. Neon has London, you get plain Postgres, and Hono on Cloudflare/Fly is fast and cheap. But you're now building auth, storage, signed URLs, realtime, and an admin UI yourself. That's 6–10 weeks you don't get back. Choose this only if you have a specific reason to avoid a BaaS.
- **PocketBase** — single Go binary, delightful for a prototype. **Not appropriate for special-category health data at consumer scale**: single-node SQLite, you own backup/PITR/HA/patching, and no DPA or certifications to point at. **No.**

**One caveat on the Supabase recommendation:** if you ever need SOC 2 evidence, budget the $599/mo Team plan, not $25. Factor that in now rather than discovering it during a partnership conversation.

---

## 2. MOBILE — EXPO

### 2.1 Current SDK
- **Expo SDK 57** — released **30 June 2026**, **React Native 0.86**, **React 19.2**. Expo describes it as "the easiest Expo SDK upgrade you've ever made" (no user-facing RN breaking changes). https://expo.dev/changelog/sdk-57
- SDK 56 (21 May 2026, RN 0.85) made **Hermes v1 the default** and shipped precompiled iOS packages (~16% faster clean builds). ⚠️ **Use ≥ 57.0.9** — earlier 57.x had a Hermes V1 memory regression affecting `react-native-reanimated` / `react-native-worklets`.
- Expo has moved to **"optional upgrades" between majors with ~1-year support windows per SDK**. Plan one SDK upgrade per year as real scheduled work.
- SDK 55 dropped the legacy architecture; **New Architecture is the default**. Audit any native dep for New Arch support before you commit to it.

### 2.2 ⚠️ Expo Go is effectively dead for you — and that's fine
https://expo.dev/changelog/expo-go-and-app-store-may-2026 — as of 4 May 2026 the SDK 55 Expo Go build was stuck in App Store review indefinitely. Expo now says Expo Go "is first and foremost an educational tool" and directs everyone to development builds. **You need a development build anyway because BLE is native code.** Use `eas go` to make a personalised Expo Go via TestFlight if you want it for spikes.

### 2.3 Exact commands

**Create the project**
```bash
npx create-expo-app@latest bodyscale-app --template default
cd bodyscale-app
npm install --global eas-cli
eas login && eas whoami
eas init                       # links to an EAS project
eas build:configure            # generates eas.json
```

**Add BLE (needs a config plugin + dev build)**
```bash
npx expo install react-native-ble-plx expo-dev-client
```
`react-native-ble-plx` now ships its **own** Expo config plugin — the old `@config-plugins/react-native-ble-plx` is deprecated and its README just points you upstream. In `app.json`:
```json
{
  "expo": {
    "plugins": [
      ["react-native-ble-plx", {
        "isBackgroundEnabled": true,
        "modes": ["central"],
        "bluetoothAlwaysPermission": "BodyScale uses Bluetooth to connect to your scale and read your measurements.",
        "neverForLocation": true
      }],
      "expo-dev-client"
    ]
  }
}
```
It adds **iOS**: `NSBluetoothAlwaysUsageDescription`, `UIBackgroundModes`. **Android**: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (API 31+), `BLUETOOTH`/`BLUETOOTH_ADMIN` (<31), `ACCESS_FINE_LOCATION`.

Set **`neverForLocation: true`** unless you genuinely derive location from BLE — it lets you drop the fine-location permission on Android 12+, which materially improves your Play Data Safety story and install conversion. ⚠️ The upstream README currently documents v3.2.0 / "tested against SDK 49" and looks stale for SDK 57 — verify plugin option names against the installed package version.

**Development build**
```bash
eas build --profile development --platform ios      # + --local for a local build
eas build --profile development --platform android
npx expo start --dev-client
```

**TestFlight**
```bash
eas build --profile production --platform ios
eas submit --platform ios --latest
# or in one shot:
eas build --profile production --platform ios --auto-submit
```

**Google Play**
```bash
eas build --profile production --platform android   # produces .aab
eas submit --platform android --latest
```

`eas.json` sketch:
```json
{
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview":     { "distribution": "internal", "ios": { "simulator": false } },
    "production":  { "autoIncrement": true, "channel": "production" }
  },
  "submit": {
    "production": {
      "ios": { "appleId": "you@co.uk", "ascAppId": "1234567890", "appleTeamId": "ABCDE12345" },
      "android": { "serviceAccountKeyPath": "./play-service-account.json", "track": "internal" }
    }
  }
}
```
Credentials: **App Store Connect API key** (.p8, preferred over Apple ID + 2FA) and a **Google Play service account JSON** with Release Manager rights. **EAS Submit uploads the binary only** — it does not manage store listing metadata, screenshots, or release notes.

Accounts: **Apple Developer Program $99/yr**, **Google Play $25 one-time**.

### 2.4 OTA updates (EAS Update) and the store rules

```bash
npx expo install expo-updates
eas update:configure
eas update --channel production --message "Fix macro rounding"
```

**Can ship OTA:** JS, styling, layout, copy/i18n, images and assets, behaviour changes within store guidelines.
**Cannot ship OTA:** native code, native deps, **permission changes**, Expo SDK upgrades — all need a new binary. `runtimeVersion` policies enforce this so an incompatible update can't reach a build.

**The store rules — the accurate version:**
- **Apple explicitly permits it.** The Developer Program License Agreement §3.3.2 carve-out allows downloading and running *interpreted code* (JavaScript) provided it doesn't change the app's primary purpose, doesn't create a store/marketplace, and doesn't circumvent signing. Guideline **2.5.2** bars downloading/installing *executable* code. React Native JS bundles are interpreted code — this is why CodePush and EAS Update are legal and widely used.
- **The real risk is behavioural, not technical:** using OTA to add features you didn't disclose at review, change the app's purpose, or flip on monetisation post-approval. That's a 2.3.1 ("hidden features") removal, not a 2.5.2 one.
- **Google Play** similarly permits JS-bundle updates but prohibits OTA that circumvents Play's update mechanism or alters the app's core purpose.
- **Practical policy:** OTA for bug fixes, copy, and layout only. Anything touching permissions, purchase flows, health claims, or the privacy-relevant data flow ships as a store binary. Write this down as an internal rule — it's the kind of thing that gets violated by a well-meaning engineer at 6pm.

### 2.5 EAS cost — the practical read
https://expo.dev/pricing

| Plan | Price | Build credit | Concurrency | Update MAU |
|---|---|---|---|---|
| Free | $0 | 15 Android + 15 iOS builds | 1 | 1,000 |
| **Starter** | **$19/mo** | $45/mo credit | 1 (+$50 each, max 5) | 3,000 |
| Production | $199/mo | $225/mo credit | 2 (+$50 each) | 50,000 |
| Enterprise | Custom | from $1,000 | 5 | 1M+ |

**Per-build:** Android medium **$1** / large **$2**; iOS medium **$2** / large **$4**.
**Update overage:** **$0.005/MAU** (first band, tapering to $0.00085 at 100M+); bandwidth **$0.10/GiB**; update storage $0.05/GiB. ~40 MiB edge bandwidth included per additional MAU.

**Honest cost picture:** at 5,000 MAU doing ~40 builds/month, **Starter at $19/mo covers you** — $45 of credit against roughly $40–60 of builds, plus ~$10 of MAU overage. You do not need the $199 Production plan until you're past ~50k MAU or the 1-concurrency queue genuinely hurts. Free tier's 15+15 builds burns out in the first week of a BLE project, so budget **$19–40/mo**. If cost matters more than convenience, `eas build --local` in CI is free apart from your runner.

---

## 3. PAYMENTS

### 3.1 RevenueCat (verified, revenuecat.com/pricing)
- **Free up to $2,500 monthly tracked revenue (MTR).** Above that, **1% of MTR**.
- **No feature gating** — Pro is the same product as free; the difference is purely the fee.
- "Growth Tools" alternative: use your own infra, pay 1% only on conversions from RevenueCat Paywalls and web-to-app Funnels.
- Enterprise: custom, volume discounts.

**Verdict: use it.** 1% on top of a 15% store cut to avoid building receipt validation, cross-platform entitlement reconciliation, subscriber state, grace periods, and billing-retry handling is a straightforwardly good trade at your stage. The web-vs-app entitlement unification (below) is where it really earns its keep.

### 3.2 Apple commission

**Standard (UK — this is your case):**
- 30% standard; **15% under the Small Business Program**; **15%** on auto-renewing subs after year 1 regardless of SBP.
- **SBP eligibility:** ≤ **$1M USD proceeds** in the prior calendar year *and* in the current year, aggregated across all Associated Developer Accounts. Enrol in App Store Connect after accepting the current Paid Apps agreement (Schedule 2). Rate takes effect **15 days after the end of the fiscal month in which enrolment is approved**. Exceed $1M mid-year → standard rate on future sales, ineligible for the rest of that year; you can re-qualify the year after proceeds fall back below $1M.
- https://developer.apple.com/app-store/small-business-program/

**➜ Enrol in SBP on day one. 15% vs 30% is the single largest lever on your unit economics and it takes ten minutes.**

**EU — ⚠️ major change effective 1 October 2026** (https://www.apple.com/newsroom/2026/08/apple-announces-changes-for-apps-in-the-european-union/):

| Route | Standard | Reduced (SBP / subs after yr 1 / Mini Apps) |
|---|---|---|
| App Store + Apple IAP | **26%** | **15%** |
| App Store + alternative payment processing | **20%** | **10%** |
| App Store + external purchase links | **15%** | **10%** |
| Alternative marketplace / web distribution | **5% Core Technology Commission** | — |

- The per-install **Core Technology Fee (€0.50 above 1M first annual installs) is replaced by the 5% Core Technology Commission**. The Initial Acquisition Fee and Store Services Fee are eliminated.
- **New:** you may now offer Apple IAP *alongside* alternative payment options in the EU (previously banned) — but you must keep the selected payment methods for **12 months**.
- Child safety: **no external purchase links for users under 13**; parental gate for alternative payments under 18; no external links in Kids Category apps.
- Note the older Alternative Business Terms (Tier 1 10% / Tier 2 17% + 3% payment processing) are being superseded — https://developer.apple.com/support/dma-and-apps-in-the-eu/ still describes the transitional structure. ⚠️ Re-read both pages in September before you model EU revenue.

**UK — no link-out rights today.** The DMA doesn't apply. The CMA designated Apple with **Strategic Market Status on 22 Oct 2025**; final commitments on app review/ranking/data/interop landed **1 April 2026**; the **Steering conduct requirement** consultation opened **30 June 2026** with responses published **14 August 2026** — **not yet in force, no decision date published**. https://www.gov.uk/cma-cases/apples-mobile-platform — **watch this monthly.**

**US:** in flux. The Dec 2025 appeals ruling let Apple charge *some* commission on external links but remanded rate-setting to the district court; the Supreme Court cleared the path in Aug 2026 for Apple to defend its rates below. ⚠️ Don't build a US link-out strategy on today's numbers.

### 3.3 Google Play — ⚠️ restructured 30 June 2026 (US/EEA/UK)
https://android-developers.googleblog.com/2026/06/play-expanded-billing.html · https://support.google.com/googleplay/android-developer/answer/16954621

Service fee and billing fee are now **unbundled**:

| | New installs | Existing installs |
|---|---|---|
| Standard, non-recurring | 20% | 25% |
| **Standard, auto-renewing subscriptions** | **10%** | **10%** |
| Apps Experience / Games Level Up participants | 15% / 10% | 20% / 10% |
| **First $1M annual earnings** | **10%** (all types) | **10%** |

**Plus a 5% billing fee** if you use Google Play's billing system in the US, UK or EEA. **0% billing fee** for alternative billing or external web purchases.

**➜ Your effective UK rate on subscriptions via Play billing: 10% + 5% = 15%.** Same as Apple SBP. Clean.

- **Billing choice program is available in the UK and EEA** (US added 30 June 2026) — this is the one Google programme the UK *does* get.
- **External offers programme is EEA-only — the UK is explicitly excluded.** Fees from 4 June 2026: initial acquisition fee **0%**; ongoing 10% subs / 20% other digital / €1.20 per app install. https://support.google.com/googleplay/android-developer/answer/14372887
- Apps Experience / Games Level Up reduced rates start **30 Sept 2026** ⚠️ — requirements weren't published as of this research. Check whether you qualify.

### 3.4 The sane setup for hardware-on-Shopify + app subscription

The relevant guidelines, verbatim:

- **3.1.3(e) Goods and Services Outside of the App:** *"If your app enables people to purchase physical goods or services that will be consumed outside of the app, you must use purchase methods other than in-app purchase."* → **The scale MUST NOT go through IAP.** Shopify is correct and required.
- **3.1.4 Hardware-Specific Content:** *"In limited circumstances, such as when features are dependent upon specific hardware to function, the app may unlock that functionality without using in-app purchase (e.g. an astronomy app that adds features when synced with a telescope). App features that work in combination with an approved physical product (such as a toy) on an* optional *basis may unlock functionality without using in-app purchase, provided that an in-app purchase option is available as well."*
- **3.1.3(b) Multiplatform Services:** you may let users access subscriptions acquired on your website, *"provided those items are also available as in-app purchases within the app."*
- **3.1.3 opening clause:** *"Apps in this section cannot, within the app, encourage users to use a purchasing method other than in-app purchase, except for apps on the United States storefront and as set forth in 3.1.1(a) and 3.1.3(a)."*
- **3.1.3(f) Free Stand-alone Apps:** a free companion to a paid web-based tool needs no IAP *"provided there is no purchasing inside the app, or calls to action for purchase outside of the app."*

**Recommended architecture:**

1. **Scale sold on Shopify. No IAP, ever.** (3.1.3(e))
2. **Core app functionality — pair scale, see weight/body fat/trends, log food — is free with the hardware.** Lean on **3.1.4**: features dependent on the hardware to function can unlock without IAP.
3. **If you bundle a subscription with hardware**, fulfil it as an account entitlement: Shopify order → webhook → your backend → RevenueCat **promotional/granted entitlement** on the user's account. The user signs in and it's there.
4. **Also offer the same subscription as an IAP in-app** — required by 3.1.3(b), and it's your standalone/renewal path anyway. RevenueCat unifies IAP + Play Billing + web (Stripe or **RevenueCat Web Billing**) into one entitlement check.
5. **Inside the app in UK/EU: never mention that the subscription is cheaper on your website, and never link out to buy it.** No buttons, no "manage on web," no pricing comparison. That is the fastest way to a 3.1.1 rejection. US storefront is currently exempt from the anti-steering prohibition ⚠️ but is in litigation.
6. **Off-app marketing is explicitly allowed:** *"Developers can send communications outside of the app to their user base about purchasing methods other than in-app purchase."* → Email, your Shopify site, and the box insert are your legitimate channels for the cheaper web price. Use them.

This is exactly the Whoop / Oura / Eight Sleep pattern and it survives review.

**Money model at a glance:** hardware via Shopify (Shopify Payments ~1.5–2% + 20p UK card), app subs at 15% effective on both stores, RevenueCat 1% above $2,500 MTR. Push renewals to web billing where you can — a web-billed sub costs ~3% total instead of 15%, and that difference compounds.

---

## 4. STORE POLICY — GUIDELINE NUMBERS AND WHAT ACTUALLY GETS REJECTED

### 4.1 Apple — the guidelines that apply to you
https://developer.apple.com/app-store/review/guidelines/

| # | What it says | Your action |
|---|---|---|
| **1.4.1** | *"Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements, and if the level of accuracy or methodology cannot be validated, we will reject your app. For example, apps that claim to take x-rays, measure blood pressure, body temperature, blood glucose levels, or blood oxygen levels using only the sensors on the device are not permitted."* Also: *"Apps should remind users to check with a doctor…"* | **The single most important one.** Note "**using only the sensors on the device**" — your measurement comes from dedicated BIA hardware, which puts you on the right side. But you must still document methodology. Prepare a **one-page accuracy & methodology note** (BIA, electrode configuration, the regression model / validation reference, stated error range) and attach it in App Review Notes. Add a doctor-consultation reminder in onboarding. |
| **1.4.2** | Drug dosage calculators must come from an approved entity | N/A — but **never** add "adjust your medication" or supplement-dosing features. |
| **2.5.1** | Public APIs only; *"HealthKit should be used for health and fitness purposes and integrate with the Health app."* | Use CoreBluetooth properly; if you touch HealthKit, actually integrate with the Health app. |
| **5.1.1(i)** | Privacy policy link in App Store Connect **and in-app**; must identify data collected, how, all uses; confirm third parties give equal protection; explain retention/deletion **and how to revoke consent** | Covered in §5. |
| **5.1.1(ii)** | Consent required for collection; *"Paid functionality must not be dependent on or require a user to grant access to this data."* | Don't gate the subscription on granting health permissions. |
| **5.1.1(iii)** | Data minimisation | Don't ask for contacts, precise location, or photo library scope you don't use. |
| **5.1.1(v)** | **In-app account deletion is mandatory** if you support account creation | Build a real delete flow (Edge Function: cascade-delete rows + storage objects + RevenueCat + auth user). Not "email us." |
| **5.1.1(ix)** | *"Apps that provide services in highly regulated fields (such as banking and financial services, **healthcare**…) or that require sensitive user information should be submitted by a **legal entity** that provides the services, and not by an individual developer."* | **Register the Apple Developer account to your Ltd company, not a person.** Getting this wrong means a rejection *and* a slow account-type migration. |
| **5.1.2(i)** | *"You must clearly disclose where personal data will be shared with third parties, **including with third-party AI**, and obtain explicit permission before doing so."* | **Directly on point for LLM food logging.** You need an explicit, specific in-app consent for sending meal photos/descriptions to your AI provider — named, before first use. |
| **5.1.2(ii)** | No repurposing data without further consent | Don't quietly start training on user meals. |
| **5.1.2(vi)** | HealthKit/Clinical Health Records/etc. data may not be used for marketing, advertising or use-based data mining, including by third parties | No health data to ad SDKs. Ever. |
| **5.1.3(i)** | *"Apps may not use or disclose to third parties data gathered in the health, fitness, and medical research context… for advertising, marketing, or other use-based data mining purposes other than improving health management, or for the purpose of health research, and then only with permission."* | Your analytics choice matters: prefer a first-party or EU-hosted analytics tool. Never send weight/body fat as event properties to an ad-adjacent SDK. |
| **5.1.3(ii)** | *"Apps must not write false or inaccurate data into HealthKit… and may not store personal health information in iCloud."* | If you write to HealthKit, write measured values only — never modelled estimates as if measured. **No PHI in iCloud** (including CloudKit-backed local caches). |
| **4.8** | If you use a third-party/social login (e.g. Google Sign-In) you must offer an equivalent that limits collection to name + email, allows the user to keep email private, and doesn't collect app interactions for ads | **Ship Sign in with Apple** (easiest), or email OTP as the equivalent. |
| **2.3.6 / 2.3.8** | Answer age-rating questions honestly; metadata must suit 4+ | See age ratings below. |
| **1.3 / 5.1.4(b)** | Kids Category rules | **Do not enter the Kids Category.** |

**Apple age ratings — ⚠️ already mandatory.** New tiers **4+ / 9+ / 13+ / 16+ / 18+**; the questionnaire added **"Medical or wellness topics"**, in-app controls, capabilities, and violent themes. **Deadline to answer was 31 January 2026** — unanswered apps hit submission interruptions. https://developer.apple.com/news/?id=ks775ehf — a calorie-counting + body-composition app should answer the medical/wellness questions honestly and expect **12+/13+ or higher**. See §5.7 for why you want a higher rating anyway.

**Also:** the July 2026 questionnaire update added **social-media capability questions** with required responses from **September 2026** — relevant if you add community/sharing features. https://developer.apple.com/news/

### 4.2 What gets rejected vs what's safe — claims

| ❌ Rejected / risky | ✅ Safe |
|---|---|
| "Clinically accurate body fat measurement" | "Estimates body fat using bioelectrical impedance analysis" |
| "Medical-grade" / "clinically validated" (without evidence) | "For general fitness and wellbeing" |
| "Detects obesity" / "screens for metabolic syndrome" | "Track your body composition trends over time" |
| "Reduces your diabetes risk" / "visceral fat rating shows your disease risk" | "Visceral fat rating — a relative index, not a diagnosis" |
| "Diagnoses" / "treats" / "prevents" anything | "Not a medical device. Not intended to diagnose, treat, cure or prevent any disease. Consult a healthcare professional." |
| Body fat % measured by the *phone's* sensors | Body fat % from a paired BIA accessory, with methodology disclosed |
| Prescriptive calorie deficits framed medically | Informational calorie/macro tracking with a wellbeing frame |

**Also avoid:** BMI categories labelled as clinical states ("you are obese"), any eating-disorder-adjacent framing, and target weights presented as medical advice.

### 4.3 Google Play

| Policy | Requirement |
|---|---|
| **Health Content and Services** (https://support.google.com/googleplay/android-developer/answer/16679511) | No *"misleading or harmful health functionality"*; no *"false or misleading health claims"*; must disclose external hardware requirements and device compatibility for sensor-based functions; must state the app **"is not a medical device and does not diagnose, treat, cure, or prevent any medical condition"** unless actually regulated. Privacy policy link in Play Console **and in-app**, on an **active, publicly accessible, non-geofenced, non-PDF URL**. |
| **Health apps declaration form** (https://support.google.com/googleplay/android-developer/answer/14738291) | **Mandatory for every app since 31 Aug 2024**, including apps with *no* health features (you certify that). You'd declare **Health & Fitness → nutrition and weight management**. Regulated medical devices in EEA/NI must additionally supply device trade name + eIFU link. |
| **Data safety** (answer/10787469) | Declare **Health info** and **Fitness info**. "Collected" = transmitted off device, *including via third-party SDKs*. "Shared" = transferred to a third party. Declare encryption in transit and a data-deletion request mechanism. *"You alone are responsible for making complete and accurate declarations."* |
| **User Data** (answer/10144311) | Prominent disclosure + affirmative consent for personal & sensitive data. |
| **Permissions & APIs** | BLE permissions minimised; `neverForLocation` if applicable. |
| **Health Connect** (https://developer.android.com/health-and-fitness/health-connect/publish) | Separate declaration; request minimum data types with per-type justification; **in-app privacy policy must match the one shown at the Health Connect link**; **no advertising use**. ⚠️ **Google Fit APIs are supported only until end of 2026** — build on Health Connect. |
| **April 2026 update** (answer/16926792) | Android 16 granular health permissions; new data types; **prohibited: using health data for employment or insurance eligibility, and unauthorised social sharing.** Contacts must use the Android Contact Picker; location scope tightened. |

**Practical Google note:** Data Safety declarations are cross-checked against your app's actual network behaviour. If your LLM call ships a food photo to a third party, that's **User content → Photos, shared** — declare it. An inaccurate declaration is an enforcement action, not a rejection you can argue.

### 4.4 Bluetooth accessory
No dedicated guideline number on either store beyond **2.5.1** (use APIs for their intended purpose). Practical requirements:
- Clear, specific `NSBluetoothAlwaysUsageDescription` — "to connect to your BodyScale and read measurements", not "for Bluetooth".
- **Provide reviewers a way to test.** Either ship a physical unit to App Review (slow, and they often won't) or — much better — **build a demo/simulation mode** behind a review account that exercises the full flow with synthetic data. Include credentials and instructions in App Review Notes. Missing this is the #1 cause of avoidable rejection loops for hardware companion apps.
- MFi is **not** required for BLE (only for classic Bluetooth / accessory protocol).
- If you don't use background BLE, don't declare the background mode — undeclared-but-unused background modes draw 2.5.4 rejections.

---

## 5. PRIVACY / LEGAL (UK & EU)

### 5.1 Is body composition data special-category data? **Yes — treat it as such.**

ICO definition of health data (Art 4(15) / Art 9(1)): *"personal data related to the physical or mental health of a natural person… which reveal information about his or her health status."* The ICO **explicitly lists fitness tracker data as an example**. https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-is-special-category-data/

Inferred health data also counts if you *"intend to make inferences"* about health status or *"treat someone differently"* based on them: *"If you carry out any form of profiling which infers things like… health status (condition or risks)… you will be processing special category data."*

**Applied to you:** weight + body fat % + BMI + visceral fat + calorie intake, presented in a health app that generates trends and recommendations, is squarely Article 9. There's an academic argument that weight alone isn't — **don't take it.** The cost of treating it as special category is a consent screen; the cost of getting it wrong is an ICO enforcement action.

**Biometric data:** only special category *"for the purpose of uniquely identifying a natural person."* Impedance measurements are **not** biometric data here. If you later add face-based food recognition or biometric app-unlock, revisit.

### 5.2 Lawful basis — concretely

You need **two** things: an Art 6 basis **and** an Art 9 condition.

- **Art 6: 6(1)(b) performance of a contract** for core service delivery (you can't provide the app without processing measurements). Use **6(1)(f) legitimate interests** for security/fraud/aggregate service improvement, with an LIA on file.
- **Art 9: 9(2)(a) explicit consent** — realistically your only option. The DPA 2018 Schedule 1 conditions are aimed at employment, health professionals, and public health; none fit a direct-to-consumer app.

**Explicit consent must be:** a clear affirmative *express statement*, **granular**, **separate from your T&Cs**, freely given, informed (name the recipients), and **as easy to withdraw as to give**.

**Separate consent toggles you need:**
1. Processing health/body-composition data to provide the service
2. **Sending food photos/descriptions to [named AI provider] for meal recognition** — name the vendor and the country
3. Optional: analytics/product improvement
4. Optional: marketing

⚠️ **The known tension:** consent must be "freely given," but you can't deliver the app without health data. The standard resolution is Art 6(1)(b) contract for the Art 6 leg + Art 9(2)(a) explicit consent for the Art 9 leg, with a clear explanation that declining means the service can't be provided. **This is the one area where I'd get a data protection solicitor to sign off** — it's contested and it's the foundation of your whole processing.

### 5.3 DPIA — mandatory. Do it before you write the schema.
https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/

You trip multiple triggers:
- **Art 35(3)(b)** — *"processing on a large scale of special categories of data."*
- ICO's list: **tracking behaviour**, **innovative technology** (LLM inference on user content), **processing that could jeopardise physical health or safety**, and **children/vulnerable individuals** if under-18s can access it.
- The European guidelines' nine criteria: **two or more = DPIA.** You hit at least four (special category, large scale, innovative tech, vulnerable data subjects).

**Your DPIA must cover:** the LLM processing of meal photos (including whether the vendor trains on inputs — get zero-retention/no-training contractual terms), international transfers, the eating-disorder risk of surfacing body-fat and calorie-deficit data to young users, and retention/deletion.

### 5.4 Data residency & international transfers
- **Not legally required** to keep UK data in the UK — but every transfer out needs a mechanism, and residency is the cheapest way to shrink the problem.
- **Pick Supabase London (`eu-west-2`).**
- Supabase's DPA already provides **SCCs + UK Addendum B.1.0**. Execute it and file it.
- **Map every onward transfer** — this is the part people forget: SMTP provider, push (APNs/FCM), analytics, crash reporting (Sentry), RevenueCat, Stripe/Shopify, **and your LLM vendor**. Each needs its own mechanism (UK Addendum/IDTA, or the **UK Extension to the EU–US Data Privacy Framework** if the US vendor is certified — check the DPF list per vendor, per entity).
- **Strong recommendation:** use an **EU/UK-region LLM endpoint** with zero-retention terms. It removes your single hardest transfer paragraph and it's a genuine marketing asset for a UK health brand.

### 5.5 ⚠️ Data (Use and Access) Act 2025 — already in force, changes your compliance docs
- **Commenced 5 February 2026:** "recognised legitimate interests"; a statutory list of purposes treated as compatible with the original purpose; SAR clarifications including **"stop the clock"** while you seek clarification; relaxed automated decision-making (⚠️ verify what remains restricted for special-category data — likely still tight, which matters if you automate anything meaningful from body-fat data); certain **cookies usable without consent**; **PECR maximum fines raised from £500,000 to £17.5m or 4% of global turnover**.
- **Commenced 19 June 2026:** a **new right to complain** to the controller — **you must provide a complaints route and acknowledge within 30 days.** Add this to your privacy policy and build the inbox.

### 5.6 Store privacy declarations

**Apple App Privacy** (https://developer.apple.com/app-store/app-privacy-details/) — declare per data type across **Used to Track You / Linked to You / Not Linked to You**:

| Data type | Likely declaration |
|---|---|
| **Health & Fitness → Health, Fitness** | Collected, **Linked to You**, App Functionality |
| **Identifiers → User ID** | Linked to You, App Functionality |
| **Contact Info → Email** | Linked to You, App Functionality |
| **User Content → Photos** (food photos) | Linked to You, App Functionality |
| **User Content → Other** (meal text) | Linked to You, App Functionality |
| **Purchases** | Linked to You, App Functionality |
| **Diagnostics → Crash/Performance** | Not Linked to You, Analytics |
| **Usage Data** | Not Linked (if you can keep it so), Analytics |

Rules: you must declare data collected by **third-party SDKs** too; on-device-only data needn't be declared; you can update answers **without an app update**. Ship a **privacy manifest** (`PrivacyInfo.xcprivacy`) — required-reason APIs and tracking domains.
**Do not tick "Used to Track You."** For a health app that's both a business mistake and a 5.1.3(i) violation waiting to happen.

**Google Play Data safety** — declare **Health info**, **Fitness info**, **Photos**, **Email address**, **User IDs**, **Purchase history**, **Crash logs**. Declare **encrypted in transit = yes** and **users can request deletion = yes** (you must actually honour it). Plus the **Health apps declaration form** and, if used, the **Health Connect declaration**.

### 5.7 Age gating — take this seriously, it's a genuine safety issue

- **UK age of consent for information society services is 13** (DPA 2018 s.9).
- The **ICO Children's Code** applies to services *"likely to be accessed by"* children — not just those aimed at them. Standards include **high privacy by default**, data minimisation, no detrimental profiling, and a DPIA.
- **A calorie-counting app that displays body fat percentage carries real eating-disorder risk for minors.** This is the part where the compliance answer and the right answer coincide.

**Do:**
1. **Set the App Store rating to 16+ or 18+** and Play's equivalent, and state a minimum age in your T&Cs.
2. **Neutral date-of-birth age gate at signup** (not "are you over 18? [Yes]"), enforced server-side, with the result stored.
3. **Do not market to under-18s.** No school/teen positioning, no youth influencers.
4. Add signposting to eating-disorder support (Beat, in the UK) and consider allowing users to hide body-fat/weight numbers and see trends only.
5. Document in the DPIA *why* the Children's Code either doesn't apply or is met anyway. ⚠️ Given the risk profile, get a legal read — an under-18 harm story is an existential PR event for a scale company.

### 5.8 Privacy policy — required contents checklist

Identity & contact details of the controller (your Ltd, company number, registered address) · **ICO registration number** · DPO or privacy contact · categories of personal data **including special-category health data** · purposes · **Art 6 basis AND Art 9 condition for each purpose** · **named recipients/processors** (Supabase, your LLM vendor, RevenueCat, Stripe/Shopify, SMTP, analytics, crash reporting, Apple/Google) · international transfers + safeguards (SCCs/UK Addendum/DPF) · **retention periods per data category** · all data subject rights (access, rectification, erasure, restriction, portability, object) · **right to withdraw consent at any time and how** · **right to complain to the controller (DUAA, from 19 June 2026) and to the ICO** · automated decision-making / profiling · children · cookies & SDK identifiers · security measures · how changes are notified.

**Must be:** linked in App Store Connect **and** Play Console, reachable **in-app**, at a live public non-geofenced HTML URL (Google explicitly rejects PDFs and geofenced pages), and identical to any policy shown at a Health Connect link.

**Also register with the ICO and pay the data protection fee.** ⚠️ Tiers were **£52 / £78 / £3,763** as of Feb 2025 — verify current amounts at https://ico.org.uk/for-organisations/data-protection-fee/. You're almost certainly Tier 1.

### 5.9 **Does displaying "body fat %" make it a medical device? — Practical read: NO, if you keep the claims clean.**

**UK (UK MDR 2002 as amended):**
MHRA's decision logic (flow chart v1.10f; **GB Flow Chart Accompanying Guidance v3.0, Nov 2025**):
- *"Monitoring of general fitness, general health and general wellbeing is **not** usually considered to be a medical purpose."*
- There *"needs to be a link to a **specific disease, injury or handicap**."*
- Software is **likely** a device if it *"is intended to influence the actual treatment — dose, size of implant, time or type of treatment"*, produces a diagnosis or prognosis, or *"provides future risk of disease."*
- **Crucially: the manufacturer's claims decide, not actual use — and a disclaimer cannot rescue a product that makes clinical claims.**
- Borderlines guidance: status turns on *"the stated intended purpose of the product and its mode of action"*; *"products for sport or leisure purposes are not considered to be medical devices"* absent medical claims.

**EU (MDR 2017/745 + MDCG 2019-11 Rev.1, published 17 June 2025):**
https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en
- Software must have **its own medical purpose** to be MDSW.
- Software limited to *"storage, archival, communication, simple search, lossless compression"* is **not** MDSW.
- *"Altering the representation of data for embellishment/cosmetic or compatibility purposes does not readily qualify the software as medical device software"*; **mean and unit conversion don't create new diagnostic information.**
- Rule 11: 11a (diagnosis/therapy decision support) → **Class IIa+**; 11b (monitoring physiological processes) → **IIa**, **IIb** for vital parameters where variation could cause immediate danger; 11c (everything else) → **Class I**.
- Body composition scales are **not** in **MDR Annex XVI** (products without a medical purpose that are regulated anyway) — confirmed by absence from that list.

**Where the line actually sits for your app:**

| ✅ Not a medical device | ❌ Becomes a medical device |
|---|---|
| Display body fat % computed by the scale | "Screens for obesity" / "detects sarcopenia" |
| Compute body fat % from raw impedance + height/age/sex, framed as fitness | "Assesses your cardiovascular / type 2 diabetes risk" |
| Show weight, BMI, trends, charts | "Monitors your condition" for any named disease |
| Informational calorie/macro tracking | Prescriptive nutrition therapy for a diagnosed condition |
| "For general fitness and wellbeing" | *Any* "risk of disease" output |
| Goal-setting the user chooses | Recommending medication or treatment changes |
| Intended for consumers | **Intended for clinicians to monitor patients** ← flips *both* the app and the scale |

**Practical rules:**
1. Write a formal **Intended Purpose statement** — MHRA, *Crafting an Intended Purpose in the Context of SaMD* (22 Mar 2023), https://www.gov.uk/government/publications/crafting-an-intended-purpose-in-the-context-of-software-as-a-medical-device-samd — covering structure/function, intended population, intended user, use environment. Keep it to general fitness and wellbeing.
2. **Enforce it across every surface** — App Store copy, Play copy, Shopify product page, box, packaging insert, ads, influencer briefs, support macros. MHRA looks at *promotional materials*. Your Shopify page is the most likely place someone writes "clinically accurate" and blows the whole position.
3. **Disclaimers don't save non-compliant claims** — but they do help establish intent when your claims are already clean. Include: *"BodyScale is not a medical device. It is intended for general fitness and wellbeing. It is not intended to diagnose, treat, cure or prevent any disease. Consult a healthcare professional before making health decisions."*
4. **Never** market for medical use or patient weighing — that also drags the scale into NAWI regulated use (see §6.6) and Class IIa.
5. **Bottom line:** a consumer BIA scale + app showing body fat %, framed as fitness, is not a medical device in the UK or EU. **You can lose this position with one marketing sentence.** Put claims review in the launch checklist and give one named person a veto.

⚠️ Note: UK medical device regulation is mid-reform — post-market surveillance rules (**SI 2024/1368**) took effect **16 June 2025** and draft amending regulations plus an MHRA call for evidence were live in **May 2026**. Only relevant if you ever become a device, but worth a watch item.

---

## 6. HARDWARE COMPLIANCE — BLUETOOTH SCALE, OWN BRAND, UK/EU

### 6.1 Own-branding changes everything ⚠️
gov.uk: if you place a product *"under your own name or trademark,"* **you assume the manufacturer's responsibilities** — including holding sufficient information about design and production, and affixing the conformity marking yourself.

**You are the manufacturer, not a reseller.** That means:
- Own the **technical file** (design, test reports, risk assessment, BOM) — **retain 10 years**
- Issue the **Declaration of Conformity in your company's name**
- Ensure conformity assessment was actually done **against your product configuration**
- Mark the product with **your name and a UK/EU postal address**
- Keep a register of complaints/non-conformities; withdraw or recall when needed
- Provide instructions and safety information **in English** (and each EU market's language)

**➜ The most important commercial step:** get the factory to transfer or licence the **full test reports and technical file** — RED/EMC/RF, LVD/safety, RoHS, battery — **naming your product model**. A generic "we're CE certified" PDF is not a technical file and will not survive a Trading Standards or market-surveillance request. Negotiate this into the supply contract **before** you place the order, and budget for a UK/EU lab to re-test or at least review if the reports are thin.

### 6.2 GB conformity marking — CE is fine, indefinitely ✅
Under **The Product Safety and Metrology etc. (Amendment) Regulations 2024**, in force **1 October 2024**, CE recognition in Great Britain was made **indefinite** across 19–21 regulations. The list **includes**:
- **Radio Equipment Regulations 2017 (SI 2017/1206)** ✅
- **Electromagnetic Compatibility Regulations 2016 (SI 2016/1091)** ✅
- **RoHS Regulations 2012 (SI 2012/3032)** ✅
- **Non-automatic Weighing Instruments Regulations 2016 (SI 2016/1152)** ✅

**➜ You can CE-mark and sell in GB without a separate UKCA mark.** This saves real money. (Northern Ireland follows EU rules — CE / UKNI as applicable.)

### 6.3 Radio (the main technical file)
- **GB:** Radio Equipment Regulations 2017. **EU:** RED 2014/53/EU.
- Essential requirements: **Art 3.1(a) safety** (LVD-equivalent), **3.1(b) EMC**, **3.2 efficient spectrum use**, plus **3.3(d)(e)(f) cybersecurity**.
- Self-declaration (Module A) is available **only if harmonised/designated standards are fully applied**; otherwise you need a Notified/Approved Body. For a BLE module in a plastic scale using standard EN 300 328 / EN 301 489 / EN 62368-1, self-declaration is normal.
- Cheapest credible route: use a **pre-certified BLE module** and inherit its RF test reports, then do product-level EMC + safety. Confirm the factory did this and get the module's certification.
- ⚠️ **RED cybersecurity (Delegated Regulation (EU) 2022/30) has been mandatory since 1 August 2025**, with harmonised standards **EN 18031-1/-2/-3**. Many far-east factories are still behind on this. **Ask for EN 18031 evidence explicitly** — this is currently the most common compliance gap in cheap BLE consumer hardware.

### 6.4 UK PSTI — likely in scope, and it's cheap to comply ⚠️
**PSTI Act 2022** + **Security Requirements Regulations 2023 (SI 2023/1007)**, in force **29 April 2024**.

Three baseline requirements:
1. **No universal default passwords**
2. **Published vulnerability disclosure policy** (a `security@yourdomain` contact + a public page + stated response times)
3. **Transparency on the minimum period for security updates** — declare it and honour it

Plus: a **Statement of Compliance must accompany the product**, and manufacturers/importers/distributors must act on compliance failures. Penalties up to **£10m or 4% of qualifying worldwide revenue**.

⚠️ **Scope:** covers products that connect to the internet *or* connect to the internet indirectly via another device. A BLE scale that pairs with a phone app which uploads to your cloud is **very likely** a "relevant connectable product." The gov.uk factsheet doesn't call out Bluetooth-only devices explicitly. **Get a specific legal read**, but the sensible default is: **comply.** The three requirements are cheap; the fine is not.

### 6.5 EU Cyber Resilience Act ⚠️ — the September 2026 date is imminent
Regulation (EU) 2024/2847. A BLE scale with a companion app is unambiguously a **"product with digital elements."**
- **11 September 2026** — **vulnerability and incident reporting obligations begin.** Actively exploited vulnerabilities / severe incidents: **early warning within 24 hours**, follow-up within 72 hours, final report within 14 days (vulnerabilities) or one month (incidents), via the **ENISA Single Reporting Platform**.
- **11 December 2027** — full application: essential cybersecurity requirements, secure-by-design, vulnerability handling, **minimum support period**, technical documentation, conformity assessment, **CE marking**.
- Penalties: up to **€15m or 2.5% global turnover** for essential-requirement and reporting breaches.

**➜ If you sell into the EU, stand up a 24-hour vulnerability reporting runbook before 11 Sept 2026.** Name an owner, register with ENISA, and rehearse it. This is the nearest hard deadline in this whole report.

### 6.6 Weighing instruments (NAWI) — **no approval needed. Guard it.**
**Non-automatic Weighing Instruments Regulations 2016 (SI 2016/1152)** regulate instruments used for six prescribed purposes: (1) commercial transactions; (2) tolls/tax/tariffs; (3) legal/regulatory or court use; (4) **determination of mass in medical practice for weighing patients for monitoring, diagnosis and treatment**; (5) pharmacy prescriptions and medical/pharmaceutical lab analysis; (6) price determination for direct sale and pre-packaging.

**A consumer bathroom scale is none of these.** gov.uk guidance is explicit: *"Non-regulated instruments (domestic kitchens, bathroom scales, goods inspection) need only manufacturer identification and maximum capacity marking — no conformity assessment required."* and *"Domestic/personal-use instruments are explicitly exempt."*
https://www.gov.uk/government/publications/non-automatic-weighing-instruments/non-automatic-weighing-instruments-regulations-2016-great-britain

**➜ Required markings: your name/identification + maximum capacity. That's it.**

**⚠️ Two traps:**
1. **Do not apply the "M" metrology mark or claim "approved"/"verified"/"trade approved"** — marking a non-regulated instrument as approved is itself an offence.
2. **Never market for clinical/patient weighing.** Purpose (4) drags you into full conformity assessment, an Approved Body, Class III accuracy, and the M mark — plus almost certainly Class IIa medical device status. One line on the Shopify page ("great for clinics!") does this.

### 6.7 RoHS
GB: RoHS Regulations 2012. EU: 2011/65/EU. Self-declaration, but you need **supply-chain declarations for every homogeneous material** (solder, cables, plastics, PCB, battery contacts). Get the factory's full RoHS pack — per-component certificates of analysis, not a one-page cover letter. Include in the technical file.

### 6.8 WEEE
- You're a **UK producer** because you sell EEE under your own brand and/or import it.
- **Small producer** = **< 5 tonnes** of EEE placed on the UK market per year → register directly with the Environment Agency (much cheaper than joining a Producer Compliance Scheme). **≥ 5 tonnes → you must join a PCS.**
- A ~2 kg scale means 5 tonnes ≈ 2,500 units/year — **you will cross this faster than you expect.** Model it now.
- Mark the product with the **crossed-out wheelie bin** symbol plus producer identification.
- **Register before you place product on the market.** Registration runs on a calendar-year cycle with an annual deadline — ⚠️ verify the current deadline and fees with the EA; historically registration is required by **31 March** for the compliance year.
- **EU:** separate WEEE registration **in every member state you ship to**, usually via an authorised representative. This is the single most tedious and most-often-skipped EU obligation.

### 6.9 Batteries
- **UK:** register as a portable battery producer. **> 1 tonne/year → must join a Battery Compliance Scheme.** Retailers/distributors supplying **> 32 kg/year** must offer in-store takeback. A coin-cell or AAA scale won't hit 1 tonne for a long time, but **register regardless**.
- **EU Battery Regulation (EU) 2023/1542** — dates that matter to you:
  - **18 Aug 2024** — CE marking on portable batteries
  - **18 Aug 2025** — chemistry labelling (Li-ion, NiMH, etc.)
  - **⚠️ 18 Aug 2026 — enhanced labelling: capacity, crossed-out wheeled bin, hazardous substance warnings, performance/durability for rechargeables, and a QR code.** This is **days away**. Check your artwork now.
  - **18 Feb 2027 — removability & replaceability: portable batteries must be "readily removable and replaceable by the end user."** Design decision: **use user-replaceable AAA/CR2032, not a sealed rechargeable.** Cheaper, avoids the 2027 problem, avoids shipping restrictions, and consumers prefer it in a scale.
  - EPR/producer registration applies per member state from the general application date.

### 6.10 Packaging EPR
- **UK:** obligated if UK-established **AND** > **25 tonnes** packaging supplied/imported **AND** turnover ≥ **£1m**.
  - 25–50 t + £1–2m turnover → **small producer** (register, report **annually**)
  - \> 50 t + £2m+ turnover → **large producer** (register, report **every 6 months**, buy PRNs/PERNs, pay PackUK disposal fees, annual compliance certificate)
  - < 25 t **or** < £1m turnover → **no obligation**
  - **Keep records for 7 years regardless.** For 2026 reporting: tonnage from 1 Jan–31 Dec 2025; turnover from accounts available before 7 April 2026.
  - https://www.gov.uk/guidance/packaging-waste-prepare-for-extended-producer-responsibility
  - **A startup shipping a few thousand scales will be well under 25 t.** Track it from unit one so you don't discover the crossing retrospectively.
- **EU:** packaging EPR registration **per member state**, plus ⚠️ **PPWR (EU) 2025/40 applies from 12 August 2026** — verify labelling/recyclability implications for your retail box.

### 6.11 EU market entry (if you ship beyond the UK)
- **GPSR (EU) 2023/988**, applicable since **13 Dec 2024**: you need an **EU-established "responsible person" (Art 16)** whose name and contact appear **on the product or packaging and in every online listing**. No responsible person = your Shopify listings are non-compliant and marketplaces will delist.
- As a UK-based own-brand manufacturer, appoint an **EU Authorised Representative / Responsible Person** — several service providers do this for a few hundred €/year. Get one before your first EU order.
- Separate per-state registrations: **WEEE, batteries, packaging**. Budget €1,500–4,000/yr for an EU compliance service to run these, or restrict launch to GB and add the EU deliberately in phase 2. **Honestly: UK-only at launch is the right call** unless EU demand is proven.

---

## 7. LAUNCH CHECKLIST

### ✅ MUST DO BEFORE LAUNCH

**Legal entity & registrations**
- [ ] Apple Developer account registered to the **Ltd company** (guideline 5.1.1(ix)) — not an individual
- [ ] Google Play developer account (business, D-U-N-S verified)
- [ ] **ICO registration + data protection fee paid** (~£52 Tier 1 ⚠️ verify)
- [ ] **WEEE producer registration** (EA — small producer if < 5 t/yr)
- [ ] **Battery producer registration**
- [ ] EU Authorised Representative / GPSR Responsible Person **(only if selling into the EU)**

**Privacy & data protection**
- [ ] **DPIA completed and signed off** — covering LLM processing, transfers, and under-18 risk
- [ ] Article 6 + Article 9 lawful basis analysis documented; **legal sign-off on the consent model**
- [ ] Privacy policy live at a public HTML URL, linked in both consoles **and in-app** (§5.8 checklist)
- [ ] **Granular explicit-consent flow** with a separate, named consent for third-party AI processing of meal photos (Apple 5.1.2(i))
- [ ] **Supabase DPA executed**; sub-processor notifications subscribed
- [ ] DPAs with **every** processor: LLM vendor (zero-retention/no-training terms), SMTP, analytics, Sentry, RevenueCat, Stripe/Shopify
- [ ] Transfer mechanisms mapped and documented per vendor (SCCs / UK Addendum / DPF)
- [ ] Records of Processing Activities (ROPA)
- [ ] **Complaints procedure + 30-day acknowledgement** (DUAA, live since 19 June 2026)
- [ ] Data retention schedule and automated deletion job
- [ ] **In-app account deletion that actually cascades** — DB rows, storage objects, RevenueCat, auth user (Apple 5.1.1(v))
- [ ] Age gate (neutral DOB, server-enforced) + 16+/18+ rating + minimum age in T&Cs

**Backend**
- [ ] Supabase project in **London `eu-west-2`** — irreversible, get it right
- [ ] **RLS enabled on every table**, with pgTAP tests proving cross-user isolation
- [ ] `(select auth.uid())` in all policies; index on every policy-filtered column
- [ ] Secret key confined to server; new `sb_publishable_…` key in the client, sent on the **`apikey` header**
- [ ] **Custom SMTP configured** (built-in is 2 emails/hour — this will break launch day)
- [ ] Private storage bucket + short-lived signed URLs (60–300 s); global file size cap set
- [ ] LLM API key in Edge Function secrets; JWT verification on; **per-user rate limiting**
- [ ] **PITR add-on enabled** ($100/mo) — you're holding health data
- [ ] Apple client-secret rotation reminder set (**every 6 months**)

**Mobile**
- [ ] Expo SDK **≥ 57.0.9**
- [ ] Development build with the BLE config plugin; `neverForLocation: true` if applicable
- [ ] Specific, human-readable Bluetooth permission strings
- [ ] `PrivacyInfo.xcprivacy` privacy manifest
- [ ] `eas.json` production profile + submit credentials (ASC API key, Play service account)
- [ ] **Reviewer demo/simulation mode** for the BLE flow + credentials in App Review Notes

**Store submissions**
- [ ] Apple **App Privacy** answers complete and accurate
- [ ] **Apple age-rating questionnaire** answered — including medical/wellness topics (was due 31 Jan 2026)
- [ ] Google Play **Data safety** complete
- [ ] Google Play **Health apps declaration form** submitted (mandatory for all apps)
- [ ] **Accuracy & methodology note for guideline 1.4.1** attached in App Review Notes
- [ ] Doctor-consultation reminder in onboarding
- [ ] **"Not a medical device" disclaimer** in-app, on the store listings, on the Shopify page, and on the box
- [ ] **Full claims review** across app copy, store listings, Shopify, packaging, ads, influencer briefs — one named owner with a veto

**Payments**
- [ ] **Apple Small Business Program enrolled** (15% not 30%)
- [ ] Google Play developer account configured; first-$1M 10% tier confirmed
- [ ] RevenueCat products + entitlements; IAP offered in-app (Apple 3.1.3(b))
- [ ] Shopify → webhook → RevenueCat promotional entitlement for bundled subs
- [ ] **Zero in-app references to cheaper web pricing** in UK/EU (Apple 3.1.3 anti-steering)
- [ ] Hardware sold **only** via Shopify, never IAP (Apple 3.1.3(e))

**Hardware**
- [ ] **Full technical file transferred from the factory, naming your model** — RED/EMC/RF, safety, RoHS, battery
- [ ] **EN 18031 cybersecurity evidence** (mandatory since 1 Aug 2025) — ask explicitly
- [ ] **Declaration of Conformity issued in your company's name**
- [ ] CE mark (valid in GB indefinitely) + your name and address on the product
- [ ] **Markings: manufacturer ID, maximum capacity, crossed-out wheelie bin** — and **no "M" mark, no "approved"**
- [ ] **PSTI: statement of compliance + published vulnerability disclosure policy + declared minimum security update period**
- [ ] Battery labelling checked against the **18 Aug 2026** enhanced-labelling requirements
- [ ] User instructions in English
- [ ] 10-year technical file retention process

### 📅 LATER (but diarise now)

| When | What |
|---|---|
| **⚠️ 11 Sep 2026** | **EU CRA vulnerability/incident reporting begins** — ENISA platform, 24h/72h/14d runbook (if selling in EU) |
| **30 Sep 2026** | Google Play Apps Experience / Games Level Up programmes — check eligibility for reduced rates |
| **1 Oct 2026** | Apple EU commission restructure takes effect — re-model EU economics; accept updated DPLA Attachment 14 |
| **End 2026** | **Supabase legacy `anon`/`service_role` keys deprecated** — complete migration |
| **End 2026** | **Google Fit APIs sunset** — must be on Health Connect |
| **Ongoing** | CMA steering conduct requirement for Apple/Google (UK link-out rights) — **check monthly** |
| **Jan–Mar 2027** | WEEE annual registration renewal; packaging EPR reporting if you cross thresholds |
| **18 Feb 2027** | EU Battery Regulation **user-replaceable battery** requirement (design around it now) |
| **Spring 2027** | **DMCCA subscription contracts regime** — pre-contract info, reminder notices, cooling-off, easy exit ("click to cancel"). ⚠️ Delayed from 2026 to **spring 2027**. Design your cancellation flow for it now — it's cheaper than retrofitting. |
| **11 Dec 2027** | **EU CRA full application** — essential requirements + CE marking for digital elements |
| When SOC 2 is asked for | Supabase Team plan ($599/mo) — Pro does not carry the certification |
| Growth | WEEE PCS membership once > 5 t/yr; packaging EPR once > 25 t **and** £1m turnover |

---

## 8. ⚠️ UNVERIFIED / NEEDS A SECOND LOOK

1. **ICO data protection fee amounts** — £52 / £78 / £3,763 were the Feb 2025 figures. Confirm current.
2. **PSTI scope for Bluetooth-only devices** — gov.uk's factsheet doesn't address BLE explicitly. My read is you're in scope (indirect internet connectivity via the phone). **Get a legal opinion**; comply either way.
3. **`react-native-ble-plx` Expo plugin options against SDK 57** — upstream README appears stale (documents v3.2.0 / "tested against SDK 49"). Verify option names against the installed version.
4. **Apple EU terms** — the newsroom announcement (Oct 2026 structure) and developer.apple.com/support/dma-and-apps-in-the-eu/ (transitional Tier 1/Tier 2 structure) describe different regimes. Re-read both in September.
5. **DUAA automated decision-making relaxation** — what remains restricted for special-category data wasn't fully resolved in my sources. Matters if you automate anything consequential from body-fat data.
6. **Google Apps Experience Program requirements** — not published as of research date.
7. **Convex EU/UK region maturity** — my read is "weaker than Supabase" but I didn't verify against current Convex docs. Only matters if you reconsider the backend.
8. **CE recognition for radio equipment in GB** — confirmed present in the SI 2024/1208 list via a UL Solutions summary, not read from the SI itself. High confidence, but read the SI before you rely on it commercially.
9. **MDCG 2019-11 Rev.1 detailed changes** — I confirmed publication (17 June 2025) but the substantive deltas from the original came from the pre-revision PDF plus secondary sources. Read the Rev.1 PDF directly if the medical-device boundary gets close.
10. **WEEE registration deadline and current fees** — historically 31 March for the compliance year; confirm with the Environment Agency.

---

**Sources:**

[Supabase Pricing](https://supabase.com/pricing) · [Supabase Regions](https://supabase.com/docs/guides/platform/regions) · [Supabase Edge Function Limits](https://supabase.com/docs/guides/functions/limits) · [Supabase Edge Functions](https://supabase.com/docs/guides/functions) · [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) · [Supabase New API Keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys) · [Supabase Signed URLs](https://supabase.com/docs/guides/storage/serving/downloads) · [Supabase Storage File Limits](https://supabase.com/docs/guides/storage/uploads/file-limits) · [Supabase Sign in with Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple) · [Supabase Passwordless Auth](https://supabase.com/docs/guides/auth/auth-email-passwordless) · [Supabase Auth Rate Limits](https://supabase.com/docs/guides/auth/rate-limits) · [Supabase DPA](https://supabase.com/legal/dpa) · [Supabase Changelog](https://supabase.com/changelog) · [Supabase Edge Functions: Background Tasks](https://supabase.com/blog/edge-functions-background-tasks-websockets)

[Expo SDK 57](https://expo.dev/changelog/sdk-57) · [Expo SDK 56](https://expo.dev/changelog/sdk-56) · [Expo Go and the App Store, May 2026](https://expo.dev/changelog/expo-go-and-app-store-may-2026) · [Expo Pricing](https://expo.dev/pricing) · [Expo Usage-Based Pricing](https://docs.expo.dev/billing/usage-based-pricing/) · [EAS Build Setup](https://docs.expo.dev/build/setup/) · [EAS Submit](https://docs.expo.dev/submit/introduction/) · [EAS Update](https://docs.expo.dev/eas-update/introduction/) · [react-native-ble-plx](https://github.com/dotintent/react-native-ble-plx/blob/master/README.md)

[RevenueCat Pricing](https://www.revenuecat.com/pricing/) · [Apple Small Business Program](https://developer.apple.com/app-store/small-business-program/) · [Apple: Changes for apps in the EU (Aug 2026)](https://www.apple.com/newsroom/2026/08/apple-announces-changes-for-apps-in-the-european-union/) · [Apple DMA Support](https://developer.apple.com/support/dma-and-apps-in-the-eu/) · [Apple Developer News](https://developer.apple.com/news/) · [Google Play: Expanded billing choice (Jun 2026)](https://android-developers.googleblog.com/2026/06/play-expanded-billing.html) · [Google Play Lower Service Fees](https://support.google.com/googleplay/android-developer/answer/16954621) · [Google Play External Offers Programme](https://support.google.com/googleplay/android-developer/answer/14372887) · [Google Play EEA Alternative Billing](https://support.google.com/googleplay/android-developer/answer/12348241)

[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) · [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) · [Apple Updated Age Ratings](https://developer.apple.com/news/?id=ks775ehf) · [Google Play Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511) · [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469) · [Google Play Health Apps Declaration](https://support.google.com/googleplay/android-developer/answer/14738291) · [Google Play Health App Categories](https://support.google.com/googleplay/android-developer/answer/13996367) · [Google Play April 2026 Policy Update](https://support.google.com/googleplay/android-developer/answer/16926792) · [Publish a Health App on Google Play](https://developer.android.com/health-and-fitness/health-connect/publish)

[ICO: What is Special Category Data](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-is-special-category-data/) · [ICO: When do we need a DPIA](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/) · [ICO Children's Code](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/) · [ICO Data Protection Fee](https://ico.org.uk/for-organisations/data-protection-fee/) · [DUAA 2025 commencement (Hill Dickinson)](https://www.hilldickinson.com/our-view/articles/data-use-and-access-act-changes-to-uk-data-protection-law-come-into-effect/)

[MHRA Software Flow Chart](https://assets.publishing.service.gov.uk/media/64a7d22d7a4c230013bba33c/Medical_device_stand-alone_software_including_apps__including_IVDMDs_.pdf) · [MHRA GB Flow Chart Accompanying Guidance v3.0](https://assets.publishing.service.gov.uk/media/68a87c553a052c9c504c8db0/GB_Flow_Chart_Accompanying_Guidance_v2.pdf) · [MHRA: Crafting an Intended Purpose (SaMD)](https://www.gov.uk/government/publications/crafting-an-intended-purpose-in-the-context-of-software-as-a-medical-device-samd/crafting-an-intended-purpose-in-the-context-of-software-as-a-medical-device-samd) · [MHRA Borderlines with Medical Devices](https://www.gov.uk/government/publications/borderlines-with-medical-devices/borderlines-with-medical-devices-and-other-products-in-great-britain) · [MDCG 2019-11](https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_en_0.pdf) · [MDCG 2019-11 Rev.1 (17 Jun 2025)](https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en) · [Medical Devices PMS Regulations SI 2024/1368](https://www.legislation.gov.uk/uksi/2024/1368/contents/made)

[NAWI Regulations 2016 Guidance](https://www.gov.uk/government/publications/non-automatic-weighing-instruments/non-automatic-weighing-instruments-regulations-2016-great-britain) · [NAWI Regulations 2016 (SI 2016/1152)](https://www.legislation.gov.uk/uksi/2016/1152/contents) · [Using the UKCA Marking](https://www.gov.uk/guidance/using-the-ukca-marking) · [UL: UK removes CE marking expiry dates](https://www.ul.com/news/consumer-products-uk-removes-expiry-dates-ce-marking-and-eu-conformity-certain-products) · [Radio Equipment Regulations 2017](https://www.legislation.gov.uk/uksi/2017/1206/contents/made) · [PSTI Product Security Factsheet](https://www.gov.uk/guidance/the-product-security-and-telecommunications-infrastructure-psti-bill-product-security-factsheet) · [PSTI Security Requirements Regulations 2023](https://www.legislation.gov.uk/ukdsi/2023/9780348249767) · [EU CRA 11 Sep 2026 deadline (Crowell)](https://www.crowell.com/en/insights/client-alerts/eu-cyber-resilience-act-countdown-11-september-2026-incidentvulnerability-reporting-deadline-is-less-than-100-days-away) · [RED Cybersecurity mandatory 1 Aug 2025 (SGS)](https://www.sgs.com/en-se/news/2025/06/red-cybersecurity-requirements-mandatory-on-1-august-2025) · [UK Packaging EPR](https://www.gov.uk/guidance/packaging-waste-prepare-for-extended-producer-responsibility) · [UK Batteries Regulations](https://www.gov.uk/guidance/regulations-batteries-and-waste-batteries) · [EU Battery Regulation dates](https://cecheck.com/battery-regulation/) · [CMA: Apple's mobile platform](https://www.gov.uk/cma-cases/apples-mobile-platform) · [DMCCA subscription regime delayed to spring 2027 (Taylor Wessing)](https://www.taylorwessing.com/en/insights-and-events/insights/2026/04/subscription-contracts)agentId: aa6b63a9726b6d7ac (use SendMessage with to: 'aa6b63a9726b6d7ac', summary: '<5-10 word recap>' to continue this agent)
<usage>subagent_tokens: 182190
tool_uses: 125
duration_ms: 1099887</usage>