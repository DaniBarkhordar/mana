# Go-to-market: how to beat Scanfit with the same hardware

Scanfit will have essentially the same two devices from the same factory. So the hardware is not where this is won. It is won on five things they are weak at, in this order.

## Know what you are actually up against

From the teardown in August (`docs/appendix-*` and the launch brief):

- **Scanfit ApS**, Hørsholm, Denmark. Small. Storefronts in Danish (scanfit.dk) and English (myscanfit.com); no UK storefront, no GBP pricing, `/pages/shipping` and `/pages/faq` returned 404.
- **App: 2.8★ on Google Play, ~5,000 installs; 10 ratings on iOS.** Reviews: "no way to determine whether the app has received the data"; segmental analysis called "worthless". This is the weakness.
- **Hardware claims contradict each other.** The English site attacks "ITO-coated glass" and claims stainless electrodes conduct "60–70× better"; the Danish spec sheet for the same device lists "Elektroder i ITO-belagt film". One of those pages is wrong.
- **The "independent DEXA validation" is a supplier-commissioned n=50 study in Shenzhen** with no correlation coefficients and no derivation of the "98.5%" figure; their own per-metric number for fat mass is 88%.
- **"No subscription"** in every headline; a **$599.99/year coaching tier** in the App Store listing.
- **Supply-constrained.** Their own page: "We don't have automated production lines yet — we've already sold out 3 times in 2026. Order while stock lasts." Pre-orders on August batches.
- **Exclusivity:** Denmark, Norway, Sweden, Holland, Finland, United States. **Not the UK. Not Germany, France, Spain, Italy, Ireland.**

They are a small Nordic DTC operation with a good instinct (scale + camera) and a weak app, over-claiming on a white-label unit, unable to keep stock, with the largest European markets unclaimed.

## 1. Lock the supply

**Before anything else: UK and Ireland exclusivity from Shenzhen Unique Scales**, with right of first refusal on Germany, France, Spain and Italy. If they resist on a first order, exclusivity triggered by volume. On the proforma, not in WeChat. `01-factory.md` §1 has the wording.

Ask one more question explicitly: *does Scanfit's agreement permit them to sell into the UK?* If their exclusivity is for the listed countries only, the factory may still be free to supply a UK distributor — you — and may or may not be able to stop Scanfit shipping from Denmark. You want to know which.

This is the only move that Scanfit cannot copy. Everything below they could in principle do; this one is first-come.

## 2. Win on the app, because that is where they lose

Their 2.8★ is your opening. Ship what they do not have:

- **Weigh-first logging with running tare** — one exact food-and-grams pair per ingredient. They photograph, then weigh; you weigh, then photograph. It sounds like the same thing and it is not: yours produces ground truth on every meal.
- **Cooking-oil capture.** The one workflow that targets the published 250–345 kcal error directly. No competitor has it.
- **UK food data.** CoFID as the spine, Open Food Facts for UK barcodes. Etekcity's rival scale has a US-only barcode database and its reviewer couldn't find UK supermarket eggs.
- **Free barcode scanning.** MyFitnessPal and Lose It! both moved barcode behind their paywalls in 2026 and took the backlash. Yours costs nothing.
- **"Synced ✓" on every reading**, offline-first. Their worst review is a sync complaint.
- **Wearable data in from day one** — Oura, WHOOP, Garmin, Apple Health, Health Connect. Scanfit is a scale company. You are a platform that happens to start with scales.
- **Trend, not snapshot, for body composition** — with the uncertainty shown. Every competitor prints "18.4%" in 48-point type. Being the one that says "±3 points, watch the seven-day line" reads as the grown-up in the room.

## 3. Win on trust — and let them keep over-claiming

Do not publish an accuracy percentage. Publish a **methods page**: which equations, their published standard errors, your repeatability protocol, your sample, your raw data. Nobody in this category does it. It costs a weekend and it becomes both your ASA defence file and your best marketing asset.

Then let the contrast do the work. You never name them. You say: *"We weigh to 0.1 g. We show you the uncertainty. We publish our methods."* Every journalist who then looks at a "98.5% DEXA-level accuracy" claim backed by a supplier-commissioned PDF will draw the conclusion without your help.

The same applies to price: **"No subscription required, ever, for weighing, barcodes, logging and trends"** — and mean it, with no $599 tier hiding in the listing.

## 4. Win on stock and speed

They sell out. You hold UK stock and ship next day. That alone converts a meaningful share of buyers who found them first and hit "pre-order — August batch".

Timeline: order on neutral packaging now; UK stock by late Q4 2026; app in TestFlight when the credentials land; launch before anyone else buys this unit for the UK. A waitlist landing page on `getmananu.com` can go up this week and start collecting emails against a Christmas ship date.

## 5. Win on price and packaging

| SKU | Price | Versus |
|---|---|---|
| Kitchen scale | £69–79 | Etekcity £47 (1 g resolution, no AI); Scanfit ≈£90 |
| Body scale | £99–119 | Renpho £30 (4-electrode, no nutrition); Withings £350; Scanfit ≈£170 |
| **Bundle — the hero** | **£149–169** | Scanfit's equivalent ≈£260 |

Free tier forever; Plus at £4.99/month or £39.99/year for unlimited photo scans, recipes, calibration, export. Twelve months of Plus bundled with hardware, then **lapse to free** — never auto-renew at full price. 100-day trial and 2-year warranty, matching them (you owe 14 days statutorily anyway, so it is cheap). Total price with VAT shown up front — drip pricing has been illegal since April 2025.

## 6. Where to sell, in order

1. **Own Shopify store.** You already run one. Full margin, own the customer, the platform's home.
2. **Amazon UK** with Brand Registry and A+ content. It is where the Renpho buyer already is, and Renpho is the upgrade path you are selling against — same price bracket as a mid-range scale, with a nutrition side they do not have.
3. **The GLP-1 channel.** People on semaglutide and tirzepatide are told to track body composition and protect muscle with high protein — your product exactly, for a population that is spending. Routes: GLP-1 telehealth providers (partnership or affiliate), pharmacies, the large UK GLP-1 communities on Reddit and Facebook. Content that speaks to them directly: *"On a GLP-1? Your scale should tell you what you're losing."*
4. **Personal trainers and online coaches**, as an affiliate channel — they already tell clients to weigh food and are tired of MyFitnessPal.
5. **Retail later** — Argos and John Lewis carry Renpho and Withings; you need reviews and a UK service record first.

## 7. Content that sells the mechanism

Short video, native to TikTok and Reels, all built on one demo: **the same plate, a photo app's guess next to the scale's number.** Then the oil demo — weigh the pan before and after, show the calories every photo app misses. Repeatable, cheap to produce, and true.

The line: **Weigh it. Don't guess it.**

## 8. What not to do

- Don't fight Cal AI or MyFitnessPal on photo logging. Cal AI was acquired by MyFitnessPal in March 2026; MFP's CEO publicly positioned it as the "speed" product and MFP as "accuracy". The accuracy seat is open; take it with hardware, not a better model.
- Don't build a band. Ingest theirs (`07-vision-and-roadmap.md`).
- Don't add a coaching tier.
- Don't say "clinical", "DEXA", "medical-grade", "detects", or any percentage.
- Don't market to gyms or clinics for patient weighing — it turns the scale into a regulated weighing instrument.

## The sequence, this month

Week 1: exclusivity ask · domains · D-U-N-S · attorney instructed · waitlist page live.
Week 2: order on neutral packaging · Supabase in London · Claude Code starts Phase 1.
Week 3–4: brand assets and carton artwork · methods page drafted · Amazon Brand Registry application (needs the trademark application number).
On credentials: driver wired · TestFlight.
