# The name: Mananu

*Rewritten 7 September 2026. The earlier version of this file was the Kelbrook clearance document with the name swapped, so its register hits, its Lancashire village and its expiring `.co.uk` were Kelbrook facts, not Mananu facts. Everything below was checked for the string "Mananu" itself. `docs/08-second-round-names.md` has the round that produced the name; `docs/06-full-list-screen.md` has the protocol.*

## Decision

**Mananu** is the brand. Decided 6 September 2026 after three screening rounds (about 130 names) and re-checked on 7 September. Lowercase wordmark `mananu`; three-stroke mark in `brand/`. Positioning line: **Weigh it. Don't guess it.**

The founder's preferred name, **Revolo**, was screened on 7 September and is not usable. Details below, so the question does not need reopening.

## Mananu — what was verified on 7 September 2026

| Check | Result |
|---|---|
| US register (Justia, USPTO.report, TrademarkElite, exact string) | **Nothing.** Nearest hit is MANANUKA, Serial 79232807, Ngati Apiaries Ltd, Class 30 honey, 2019 — a different word in a different class |
| UK register (Trademarkia UK mirror, control-tested) | **Nothing** on the exact string |
| Companies House | **No company** named Mananu |
| App Store and Google Play | **No app** named Mananu |
| Live brand in health, food, supplements, electronics or measurement | **None found** |
| getmananu.com, trymananu.com, joinmananu.com | Available at the 6 September check |
| mananu.health, mananu.app, mananu.io | Available at the 6 September check |
| mananu.co.uk | **Did not resolve in DNS on 7 September** — may simply be available; check RDAP and register it the same day |

Register the domains before anything else in this document is acted on: `getmananu.com` (primary until a `.co.uk` exists), `mananu.co.uk`, `mananu.health`, `mananu.app`, `mananu.io`, plus `trymananu.com` and `joinmananu.com` defensively. The app's privacy policy URL and the paywall's terms link already point at `getmananu.com` (`app/lib/core/legal.dart`).

## Residual risks, named honestly

1. **EUIPO is unverified.** No EU register route returned trustworthy data. Commission a professional EUIPO search before filing; do not read the table above as EU clearance.
2. **Pending UK applications are invisible** to the sources used. A mark filed in the last few months may not be indexed. The attorney's clearance opinion must cover pending marks.
3. **Reputation is zero.** Mananu means nothing to anyone, which is the point — every name that *means* weighing or health is taken (see the table below) — but it also means the positioning line does all the work.

## Revolo — why not

| Conflict | Detail |
|---|---|
| US registration, live | REVOLO, Serial 88894110, filed 29 April 2020, registered November 2020, Class 9: batteries, cameras, phone cases, digital door locks, earphones, **electric sensors**, protective goggles. That is the class the app and both scales sit in |
| App stores | A smart-lock companion app named **Revolo** is live on the App Store and Google Play. Apple's name-collision rule alone makes the app name unavailable |
| Companies House | **Revolo Biotherapeutics**, company 07828414, active — a UK biotech in exactly the health adjacency Classes 5, 42 and 44 would need |
| Domains | revolo.com and revolo.co.uk are registered to others |

Any one of these would draw an objection or an opposition. Together they make Revolo a certain rebrand later, at the point when the brand is worth the most to lose.

## The rest of the 7 September shortlist

Listed so nobody re-screens them.

| Name | Verdict | Why |
|---|---|---|
| Librile | Unknown | Latin for the beam of a balance. Nothing indexed anywhere, but the registers could not be queried directly and nobody will hear the root; neighbours are all book brands |
| Tulana | Risky | Sanskrit "weighing". TULA is a large US Class 5 supplement and skincare portfolio and Tulana would be argued as TULA plus a suffix; two UK companies carry the name |
| Talanto | Risky | One vowel from TALENTO, a crowded HR-software family; the `.com` and `.co.uk` are taken |
| Pondero | Risky | PONDER and PONDERA already occupy Class 9 software and Class 5 supplements in the US; a weight-loss app called Pondera exists |
| Svari | Blocked | Latvian for "scales" — a generic noun in an EU language, so an EUTM in Class 9 faces a descriptiveness objection; the `.com` is a UK IT company |
| Hakaru, Vekta, Vekt, Metria, Vaga, Vaaka, Mizan, Pondus, Mensura, Libella, Bilanx, Lanxa, Kaalu | Blocked | Every natural-language word for weigh, weight, measure or balance is already a weighing company, a fitness app or a Class 5 mark |

## Filing plan

File **UK first**, then EU within six months to claim priority.

| Class | Covers | Priority |
|---|---|---|
| **9** | The app, software, the scales as measuring apparatus | Essential |
| **5** | Vitamins, dietary and nutritional supplements | Essential — the crowded class, and the reason the search mattered |
| **10** | If the device is ever described in medical or diagnostic terms | Recommended |
| **35** | Retail of the above | Recommended |
| **44** | Health, nutrition and dietary advice | Only if the app ever gives personalised guidance |

Budget a UK attorney for a clearance opinion covering UK and EU registers including pending marks. On a three-class filing across 5, 9 and 10 for a brand that will carry a device and ingestibles, that is the one piece of trademark spending clearly worth it.

## The wordmark

`mananu` is set lowercase in Instrument Sans with slightly open tracking (`brand/mananu-wordmark.svg`). Six letters, three syllables, no consonant cluster, and it reads the same in every language the app will ship in. The three-stroke monogram (`brand/mananu-monogram.svg`) is the app icon and the scale silkscreen.

Positioning line: **"Weigh it. Don't guess it."** It states the product's actual mechanism, it is a factual claim the scale substantiates, and it draws the comparison with photo-only apps without naming one or making an accuracy claim. See `03-accuracy-claims.md`.

## If the name ever changes

Do not rename unless the founder says so. The rename recipe is in `CLAUDE.md`; run it from the repo root and then re-check `brand/`, the store listing (`docs/13-store-listing.md`), the privacy policy, and `app/lib/core/legal.dart`.
