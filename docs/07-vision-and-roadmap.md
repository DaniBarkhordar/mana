# The vision, staged — and what each stage costs

**The vision, as stated:** start like MyScanFit — a body scale and a nutrition scale in one app. Then a WHOOP-style wearable collecting the person's data continuously. Then at-home or in-person blood tests. Gather all of it, work out what the body is missing, and sell supplements and other products against that data.

That is ZOE's model, Withings' hardware breadth and WHOOP's data moat, combined. It is a good vision, and it is stageable — but each stage crosses a regulatory line the previous one did not, and the order below is the order in which the lines get expensive. The naming decision already reflects it: **Mananu is a platform name, not a scale name.**

---

## Stage 1 — Scales and the app (now)

Body scale, kitchen scale, one app. Camera identifies, scale quantifies. This is what the repo builds.

**Regulatory weight:** light. Wellness product, not a medical device, provided nothing claims to diagnose. UK GDPR Article 9 consent for body composition. PSTI, CE, WEEE. All covered in `04-compliance-uk.md`.

**What to build differently because of the vision:** the data model. See §"Build for stage 4 on day one" below.

## Stage 2 — Wearable data (launch, but not our hardware)

The vision says "maybe a band from the beginning." **Ingest wearable data from day one; do not ship a band at launch.** Here is why, plainly:

- **Shenzhen Unique Scales does not make wearables.** A band is a different factory, a different supply chain, and a different engineering problem — optical heart-rate sensing, motion algorithms, battery life, firmware updates, water resistance. WHOOP has ~500 engineers and took years to make theirs credible.
- **The white-label bands available today are poor**, and a poor band next to a good scale drags the brand down. Reviews will say "great scale, band is junk," and the band review is the one that gets quoted.
- **You get the data anyway.** Apple Health, Health Connect, Garmin, Oura, WHOOP, Fitbit, Polar and Withings all export sleep, HRV, resting heart rate, steps and workouts. A user who already owns a band — and the customer who buys a £150 scale bundle very often does — connects it in thirty seconds. The platform then holds body composition, nutrition **and** wearable data for that person, which is the thing WHOOP alone cannot do.

So stage 2 is an integrations layer, not a hardware SKU. It also happens to be what the app stores want: HealthKit and Health Connect are first-class, and Apple guideline 2.5.1 rewards apps that integrate with the Health app properly.

**Ship your own band at stage 2b**, once there are users and revenue, as a white-label unit chosen against a real spec — and price it as an accessory to the platform, not as a WHOOP competitor.

**Regulatory weight:** still light, with one new item — Health Connect requires its own declaration and a matching privacy policy, and Google's April 2026 update prohibits using health data for employment or insurance eligibility. Fine, because you would never.

## Stage 3 — Blood tests

This is the step change. **A blood test is a regulated in-vitro diagnostic, whatever the marketing says.**

- **In the UK**, the test kits are IVDs under the UK Medical Devices Regulations 2002 (as amended), and the lab that runs them must be accredited (UKAS to ISO 15189). If you *provide a diagnostic service* in England — including at-home kits with results interpretation — you are very likely in scope for **CQC registration**. Thriva, Medichecks and Randox all operate this way; none of them make the kits or run the labs themselves.
- **In the EU**, the IVD Regulation (EU) 2017/746 applies, and it is stricter than the UK regime.
- **Blood test results are health data of the most sensitive kind.** Article 9 still, but now the DPIA is non-negotiable and a Data Protection Officer becomes the sensible default.

**The workable model** — and the one every UK entrant uses — is to **white-label an accredited lab partner**, not to build testing. The user orders through Mananu, the kit ships from the partner, the partner's UKAS lab runs it, results land in your app via API. You own the customer and the data view; they own the regulated activity. That is a contract negotiation, not a product build, and it is roughly a six-month workstream that should start once stage 1 has revenue.

**Regulatory weight:** heavy. Budget for a regulatory consultant. Do not add the word "blood" to any marketing before the partner and the compliance position are in place.

## Stage 4 — "What is your body missing" → supplements

The commercial engine of the vision, and the part that needs the most care in how it is *said*.

- **The line that turns a wellness product into a medical device** is a claim tied to a specific disease or to diagnosis, treatment or prevention. "Your vitamin D is 32 nmol/L, which is below the NHS reference range" is a fact about a test result. "You are deficient and this product will fix it" is a medical claim about a specific condition. The first is permitted; the second makes the app software-as-a-medical-device under UK MDR and MDCG 2019-11.
- **The safe framing is the reference range and the product, not the diagnosis.** Show the result, show where it sits against the published range, let the user choose. Recommendation engines that go further need clinical oversight — a registered dietitian or pharmacist signing off the logic, and their name on it.
- **ZOE is the cautionary tale**, not the template. The ASA required them to change advertising in 2023 over implied clinical validation of weight-loss claims, and their evidence base has been publicly questioned by nutrition scientists. They are still a good business — but they spent real money and goodwill learning where the line is. Learn it from them, not from an ASA ruling of your own.
- **The conflict of interest is visible to everyone.** A company that tests you and then sells you the cure for what it found will be asked, by journalists and regulators, whether the test is honest. The answer has to be structural: publish the ranges you use, publish the recommendation logic, and never let a test result drive a purchase without the range being shown alongside it. Doing this well is also a marketing position — it is what the "methods page" in `03-accuracy-claims.md` becomes at scale.

**Supplements themselves:** food law, not medicine, in the UK — provided no medicinal claims. Novel Foods authorisation for anything unusual. Nutrition and health claims must be on the GB Nutrition and Health Claims Register; "supports immune function" is only permissible for the specific nutrients it is authorised for. Manufacture through a UK contract manufacturer with GMP; do not import finished supplements from the scale factory's neighbours without a UK responsible person.

---

## Build for stage 4 on day one

The single architectural decision that makes stages 2–4 cheap instead of expensive is **how measurements are stored**.

Do not build a `body_measurements` table, then a `wearable_samples` table, then a `blood_results` table, each with its own shape. Build **one observation model** and let every source feed it:

```
observation
  id, user_id, taken_at
  kind          -- 'weight', 'body_fat_pct', 'resting_hr', 'hrv_rmssd', 'sleep_duration',
                -- 'vitamin_d_25oh', 'ferritin', 'hba1c', ...
  value, unit
  source        -- 'mananu_body_scale', 'apple_health', 'oura', 'partner_lab:randox'
  device_id, method, confidence
  reference_low, reference_high, reference_source   -- for lab and clinical values
  raw jsonb     -- the source payload, never discarded
```

This is a simplified version of the FHIR `Observation` resource, which is what the NHS, every lab, and every wearable exporter already speak. Adopting the shape now means:

- a blood result and a scale reading are the same kind of row, and the trend chart that already works for body fat works for ferritin without new code
- a lab partner's API maps onto your schema in an afternoon
- "what is your body missing" is a query over one table, not a join across five
- exporting a user's data (Article 20 portability) is one endpoint

The existing `body_measurements` table stays for the derived composition figures and their provenance; the raw readings that feed it become observations. `HANDOFF.md` Phase 1 has been updated accordingly.

---

## Trademark classes — updated for the platform

The vision changes the filing list. Class 44 moves from optional to essential.

| Class | Covers | Stage |
|---|---|---|
| **9** | App, software, scales and wearables as measuring apparatus | 1 |
| **5** | Vitamins, dietary and nutritional supplements | 4 — file now, it is the crowded class and you cannot add it later cheaply |
| **10** | Medical and diagnostic apparatus — wearables with health sensors, test kits | 2b/3 |
| **42** | SaaS, data platform, health-data analysis software | 1 |
| **44** | Health, medical, nutrition and dietary advice services; medical testing services | 3/4 |
| **35** | Retail of the above | 1 |

Six classes. At UK IPO fees that is modest; the attorney's clearance opinion across six classes is the real cost and is worth it once, now, rather than class-by-class later.

---

## The honest summary

Stage 1 is a product. Stage 2 is an integration. Stage 3 is a regulated partnership. Stage 4 is a compliance posture as much as a feature. The vision is right and the name is right for it — build the data layer for stage 4 today, ship stage 1 this quarter, and do not say "blood" or "deficient" in public until the paperwork exists.
