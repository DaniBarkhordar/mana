# Privacy policy — draft for counsel

*Draft, 6 September 2026. Written to match what the code does; every sentence here is checkable against the repository. Counsel should confirm the controller details, the lawful bases and the retention periods before publication at getmananu.com/privacy. Health Connect requires this policy to be reachable from the app's permissions rationale screen and from the Play listing.*

## Who we are

Mananu Ltd (to be confirmed), the controller for the personal data described here. Contact: privacy@getmananu.com.

## What Mananu does with your data, in one paragraph

Mananu weighs food and measures your body with scales you own. The app stores what you weigh and what the scale measures on your phone first, and backs it up to your account on servers in the United Kingdom. Nothing about your body or your food is sold, shared with advertisers, or used to decide anything about you. You can export everything and delete everything, from inside the app, at any time.

## The data, where it goes, and why

| Data | Where it comes from | Why we process it | Lawful basis (UK GDPR) | Where it is stored |
|---|---|---|---|---|
| Weight, and the electrical impedance your body scale measures | Your scale, over Bluetooth | To show your weight and, with your consent, to calculate body composition using published equations on your phone | Consent (Article 9(2)(a)) for body composition; contract for weight | Your phone; your account (UK region) |
| Body composition figures (body fat, fat-free mass, water, muscle, resting energy) | Calculated on your phone | To show trends | Consent (Article 9(2)(a)); withdrawable in Settings; withdrawal can delete what was calculated | Same |
| Height, date of birth, sex | You, at setup | Inputs to the published equations; they cannot run without them | Consent, as above | Same |
| Meals, foods, recipes, grams weighed | Your kitchen scale and what you choose | The food diary | Contract | Same |
| Meal photos | Your camera, only when you choose to take one | Sent once, downscaled, to our AI provider to identify **what** the food is. The provider is named in the app before the first photo. The photo is not kept by us; the answer is cached by a hash of the image so the same photo is never sent twice | Consent, separate from body composition, withdrawable in Settings | Transient; the provider's processing terms apply |
| Sleep, resting heart rate, heart-rate variability, steps, workouts | Apple Health or Health Connect, only if you connect them | To show wearable data next to your scale readings, with the device named | Consent (Article 9(2)(a)), withdrawable by disconnecting | Your phone; your account |
| Measured weight written to Health | Your scale, only if you switch this on | So other apps you use see your weight | Consent | Apple Health / Health Connect on your phone |
| Email address, or an Apple / Google identifier | Sign-in, optional | To let you sign back in on another phone | Contract | Your account |
| Subscription status | The App Store or Google Play, via RevenueCat | To know whether Plus is active | Contract | RevenueCat; a tier flag in your account |

**Never:** analytics or crash-reporting services that receive health data; advertising; selling data; profiling; using health data for insurance, employment or credit decisions. There are no such services in the app at all.

## Where your data lives

Your phone holds the primary copy in a database that is excluded from iCloud and Google device backups. Your account holds a synchronised copy on Supabase infrastructure in the United Kingdom (London). Row-level security means only your session can read your rows. The AI provider for photo identification processes images transiently; the current provider is shown in the app under Settings → Photo recognition. *(Counsel: international transfer analysis for the AI provider — the image is not linked to an identity, but confirm the appropriate safeguard.)*

## How long

Until you delete it. Deleting your account (Settings → Delete my account) removes every row from our servers immediately and clears the phone; there is no soft-delete. Consent records (what you agreed to and when) are kept with the account and go with it.

## Your rights

Access and portability: Settings → Export everything gives you every measurement and meal as CSV. Rectification: edit or delete any meal or reading in the app. Erasure: Settings → Delete my account. Withdrawing consent: Settings → Body composition, Settings → Photo recognition, Settings → Connected sources. Complaints: the Information Commissioner's Office, ico.org.uk.

## Children

Mananu is for adults. The body-composition equations are validated for ages 18 and over; the app will not calculate composition for a younger profile.

## Changes

The consent text in the app carries a policy version. When this policy changes in a way that affects how we use your data, the app will ask again.

## Wearables (wording for the Play Console Health Connect declaration)

- `READ_STEPS` — daily step count, shown on the Body screen.
- `READ_SLEEP` — sleep duration per night, shown on the Body screen.
- `READ_RESTING_HEART_RATE` — daily resting heart rate, shown on the Body screen.
- `READ_HEART_RATE_VARIABILITY` — daily HRV, shown on the Body screen.
- `READ_EXERCISE` — workout minutes, shown on the Body screen.
- `READ_WEIGHT` — to avoid duplicating a weight already written by Mananu.
- `WRITE_WEIGHT` — measured weight from the scale, only when the user switches "Share weight with Health" on.
