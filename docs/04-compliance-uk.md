# UK/EU compliance — what actually bites

Ordered by how likely it is to hurt you, not by how it appears on a regulator's website.

---

## 1. Own-branding makes you the manufacturer

If you place a product on the market under your own name or trademark, you take on the manufacturer's obligations. Not the importer's — the manufacturer's. Concretely:

- Hold the **technical file** for **10 years** (design, test reports, risk assessment, BOM)
- Issue the **Declaration of Conformity in MOTOPA/Mananu's name**
- Affix the conformity marking yourself
- Put **your name and a UK postal address** on the product
- Keep a register of complaints and non-conformities, and withdraw or recall when needed
- Supply instructions and safety information in English, and in each EU market's language

**Action:** get the full test reports naming *your* model into the supply contract before you pay. See `01-factory.md` §5.

**Good news:** you do **not** need a separate UKCA mark. The Product Safety and Metrology (Amendment) Regulations 2024, in force 1 October 2024, made CE recognition in Great Britain **indefinite** across the regulations you care about — Radio Equipment, EMC, RoHS and Non-automatic Weighing Instruments. CE-mark and sell in GB. Northern Ireland follows EU rules.

## 2. UK PSTI — cheap to comply with, expensive to ignore

The Product Security and Telecommunications Infrastructure regime has applied since **29 April 2024** to products that connect to the internet directly *or indirectly through another device*. A BLE scale that pairs with an app that syncs to your cloud is very likely in scope.

Three requirements:

1. **No universal default passwords** — unique per device or user-set
2. **A published vulnerability disclosure policy** — a `security@` address, a public page, and stated response times
3. **A declared minimum security update period** — state it and honour it

A **Statement of Compliance must accompany the product**. Penalties run to £10m or 4% of qualifying worldwide revenue.

Specify this to the factory *before tooling*. Note that Scanfit's Play Store data-safety declaration says their data is **not encrypted** — that is both a PSTI-adjacent problem and an Article 9 problem, and it is the kind of thing that ends up in a news story.

## 3. EU Cyber Resilience Act — the nearest hard deadline

Regulation (EU) 2024/2847. A BLE scale with a companion app is unambiguously a "product with digital elements."

- **11 September 2026** — vulnerability and incident reporting obligations begin. Actively exploited vulnerabilities or severe incidents: **early warning within 24 hours**, follow-up within 72 hours, final report within 14 days (vulnerabilities) or one month (incidents), via the ENISA Single Reporting Platform.
- **11 December 2027** — full application, including CE marking against the essential cybersecurity requirements.

Penalties to €15m or 2.5% of global turnover.

**If you sell into the EU, you need a 24-hour vulnerability reporting runbook standing up before 11 September 2026.** That is roughly two weeks away. Name an owner, register with ENISA, write the one-page process. UK-only launch defers this.

## 4. Body composition is special-category data

The ICO explicitly lists fitness tracker data as an example of health data under Article 9. Weight plus body fat plus BMI plus calorie intake, presented in a health app that generates trends, is squarely Article 9. There is an academic argument that weight alone is not — do not take it.

You need **an Article 6 basis and an Article 9 condition**. For a consumer app the realistic condition is **explicit consent, Article 9(2)(a)**. Explicit means a specific affirmative act: not pre-ticked, not bundled into the terms, not implied by use. The app implements this as its own onboarding step, unticked, with the product remaining fully usable if declined.

Also required:

- **A DPIA.** Health data at scale — effectively mandatory. Write it before launch, not after an incident.
- **Data residency in the UK/EU.** Supabase project in London or Frankfurt.
- **Real deletion.** In-app account deletion is mandatory under Apple 5.1.1(v), and Article 17 is not satisfied by a soft-delete flag. The schema cascades from `auth.users`, and `public.delete_my_account()` is exposed as an RPC.
- **A consent record.** `public.consents` stores one row per grant or withdrawal, never updated in place.

### The Lefu cloud is the trap

Their SDK offers two paths for body-composition maths: a local library (`PPCalculateKit`) and a cloud endpoint at `uniquehealth.lefuenergy.com`.

The cloud endpoint takes age, sex, height, weight, heart rate and impedance. That is Article 9 special-category data going to a server in the PRC, with no adequacy decision, no SCCs, no processor agreement, and no transfer risk assessment. Their own consumer app's privacy policy says data obtained in the PRC is stored in the PRC and does not mention GDPR anywhere.

**A privacy notice does not fix this.** The app is architected so it never happens: BLE → the app → local calculation → your EU backend. Ask the factory for a DPA anyway, and if they cannot supply one, treat the cloud API as permanently off-limits.

## 5. Are you a medical device?

**"Body fat 18%" is not a medical device claim. "Your body fat indicates your risk of type 2 diabetes" is.**

The line is a claim tied to a specific disease or to diagnosis, treatment, monitoring or prediction. Stay on the safe side of it:

- Ship the disclaimer: *not a medical device, not intended to diagnose, treat, cure or prevent any disease.*
- No visceral-fat-as-cardiovascular-risk framing. No "metabolic age" as health status.
- No BMI category rendered as a clinical state ("you are obese").
- Carry the pacemaker/ICD contraindication and the pregnancy note — the app does, in the protocol sheet.

Note the incentive: medical devices are *exempt* from PSTI. That is a reason not to drift into being one accidentally, and it also means that if you stay non-medical, PSTI definitely applies to you.

## 6. Weighing instruments — a non-issue, but guard it

The Non-automatic Weighing Instruments Regulations 2016 regulate six prescribed purposes. A consumer bathroom or kitchen scale is none of them. Government guidance is explicit that domestic and personal-use instruments are exempt and need only **manufacturer identification and maximum capacity marking**.

Two traps:

1. **Do not apply the "M" metrology mark or claim "approved", "verified" or "trade approved".** Marking a non-regulated instrument as approved is itself an offence.
2. **Never market for clinical or patient weighing.** "Great for clinics!" on the Shopify page drags you into prescribed purpose (4) — full conformity assessment, an Approved Body, Class III accuracy, the M mark, and almost certainly medical device status. One sentence does it.

## 7. Consumer law — DMCCA

In force since **6 April 2025**:

- **Drip pricing banned.** Total price, inclusive of VAT, in every invitation to purchase. Price the site in GBP with the total shown up front.
- **Fake and incentivised reviews banned.** Take reasonable steps to verify; remove reviews that conceal incentivisation.
- **The CMA can enforce directly** without a court order, with fines and consumer redress.

The subscription contracts regime — pre-contract information, renewal reminders, a 14-day cooling-off before auto-renewal, easy cancellation — was expected in spring 2026. **Confirm its commencement status before launch**, since it is now late August 2026.

Cal AI's most-cited complaint is "not upfront about pricing — they only told me after I'd entered all my info." That practice is exactly what this targets, which is why Mananu's onboarding shows the price on the first screen.

## 8. Producer responsibility — register before you sell

| Scheme | Trigger | Action |
|---|---|---|
| **WEEE** | You sell EEE under your own brand | Register with the Environment Agency. Under 5 t/year = small producer, register direct. Over = join a compliance scheme. **A 2 kg scale means 5 t ≈ 2,500 units/year** — you will cross this sooner than you expect. Crossed-out wheelie bin symbol on the product. |
| **Batteries** | Portable battery producer | Register regardless of volume. Over 1 t/year requires a compliance scheme. |
| **Packaging EPR** | UK-established AND >25 t packaging AND turnover ≥£1m | Probably not yet. Keep records for 7 years regardless. |
| **EU WEEE** | Per member state | Separate registration in **every** member state you ship to, usually via an authorised representative. The most tedious and most-often-skipped EU obligation. |

**EU Battery Regulation dates:** enhanced labelling — capacity, crossed-out bin, hazard warnings, durability, QR code — applies from **18 August 2026**, which has just passed. Check the artwork. And from **18 February 2027** portable batteries must be readily removable and replaceable by the end user, which is the argument for AAA or CR2032 cells rather than a sealed pack.

## 9. App store specifics

**Apple**

- **5.1.1(ix):** apps in healthcare must be submitted by a **legal entity**, not an individual developer. Register the Apple Developer account to the limited company. Getting this wrong means a rejection and a slow account migration. The D-U-N-S number this requires is free but can take up to two weeks — **start it today**.
- **1.4.1:** you must disclose data and methodology supporting health-measurement accuracy claims. Note the wording exempts you from the worst of it — the prohibition is on measuring "using only the sensors on the device", and yours comes from dedicated BIA hardware. Still, prepare a one-page accuracy and methodology note and attach it in App Review Notes. The app's Body screen already displays the equations and their standard errors, which is most of the work.
- **5.1.2(i):** explicit permission before sharing data with **third-party AI**, named, before first use. Directly on point for photo food logging. Build the consent screen.
- **5.1.1(v):** in-app account deletion is mandatory.
- **4.8:** ship Sign in with Apple if you offer any third-party login.
- **Age rating:** answer the medical/wellness questions honestly. Expect 12+/13+. Do not enter the Kids Category.

**Google Play**

- The **health apps declaration form** has been mandatory for every app since 31 August 2024. Declare Health & Fitness → nutrition and weight management.
- **Data Safety:** declare Health info and Fitness info. If the vision call ships a food photo to a third party, that is User content → Photos, **shared** — declare it. Declarations are cross-checked against actual network behaviour; an inaccurate one is an enforcement action, not an argument.
- Register as an **organisation**, not a personal account, or you face a 14-day closed test before release.
- Build on **Health Connect**, not Google Fit — the Fit APIs are supported only to the end of 2026.

**Both stores, the practical one:** App Review cannot test a Bluetooth scale they do not have. The single most common cause of avoidable rejection loops for hardware companion apps is not giving reviewers a way through the flow. The app ships a `SimulatedScaleDriver` for exactly this — put a review account behind it and say so in the notes.

---

## Before launch vs later

**Before you can sell:**
Technical file and DoC · CE marking · PSTI statement of compliance · WEEE and battery registration · UK address on the product · privacy policy and DPIA · explicit consent flow · in-app deletion · EU/UK data residency · company-registered developer accounts · D-U-N-S

**Before you ship to the EU:**
CRA vulnerability reporting runbook (11 Sept 2026) · per-member-state WEEE · EU authorised representative · battery labelling artwork

**Later:**
Packaging EPR (at £1m turnover and 25 t) · EU Battery removability (Feb 2027) · CRA full application (Dec 2027)
