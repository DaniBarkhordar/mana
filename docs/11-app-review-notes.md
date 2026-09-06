# App Review notes

Paste the "Notes" block into App Store Connect → App Review Information, and the equivalent into the Play Console's "App access" instructions. Both reviewers will need the same three things: a way through the scale flow without hardware, a way through sign-in, and the reason the app asks for health data.

## Notes

> Mananu is a companion app for a Bluetooth body scale and kitchen scale. You do not need the hardware to review it.
>
> **Demo scale.** On first launch the app runs on a simulated scale. Settings → Your scales → "Demo scale" is on. Tap "Weigh food" and use the +75 g / +160 g buttons under the readout to simulate putting food on the scale; on the Body tab, tap "Simulate stepping on". Readings from the demo scale are labelled "simulated" and never presented as measurements.
>
> **Sign-in** is optional. The diary is backed up under a temporary account from the first launch; Settings → Account offers Sign in with Apple, Google, or an emailed code. A review account is not needed, but one is provided below if you prefer to test email sign-in.
>
> **Health.** Settings → Wearables → Connected sources → Connect asks to *read* sleep, resting heart rate, heart rate variability, steps and workouts, and — only if the reviewer switches it on — to *write* measured weight. Body composition figures are calculated from impedance using published equations and are never written to Health.
>
> **Photo recognition** sends a downscaled photo to our AI provider (named in the consent sheet) to identify *what* the food is. The amount is always read from the scale; the app never estimates portion size from a photo. The free allowance is thirty scans a month; Mananu Plus (auto-renewing, £4.99/month or £39.99/year) removes the limit and adds recipes and personal calibration. Weighing, barcode scanning, manual logging and body trends are free without limit.
>
> **Deletion.** Settings → Delete my account erases everything server-side (`delete_my_account()` cascades from the auth user) and on the phone.
>
> Review account: (email) — the six-digit code arrives at that inbox; the reviewer inbox forwarder is set up per docs/05-runbook.md §3a.

## What each permission string says, and why

| Permission | String | Why the reviewer will accept it |
|---|---|---|
| Bluetooth | connects to your body scale and kitchen scale | The whole product |
| Camera | works out what a food is and scans barcodes; the amount always comes from the scale | Distinguishes us from photo-estimation apps |
| HealthKit read | sleep, resting heart rate, HRV, steps, workouts on the same timeline as scale readings, device named | Data minimisation is visible: five types, all shown in the app |
| HealthKit write | measured weight only, and only if chosen | Apple 5.1.2(ii) — no modelled values written |

## Guidelines this app is designed around

- **1.4.1 / 5.1.1(ix)** — medical claims: none. Settings → About: "not a medical device". No visceral fat, no metabolic age (`CLAUDE.md` rule 3). Every derived number shows its equation and published error.
- **4.8** — Sign in with Apple is offered wherever Google is.
- **5.1.1(v)** — in-app account deletion, real deletion.
- **5.1.2(ii)** — nothing modelled written to HealthKit.
- **5.1.3(i)** — no health data to analytics or ad SDKs. There are no such SDKs in the build.
- **3.1.1 / 3.1.2** — subscriptions through StoreKit via RevenueCat; the paywall states the price, period, renewal terms and where to cancel.
- **Hardware companion apps without hardware** — the demo scale is the route through every flow, and it is on by default in a build without vendor credentials.

## Play Console

- **Health apps declaration:** list the seven `android.permission.health.*` permissions from the manifest and the sentence for each from docs/12-privacy-policy.md §"Wearables".
- **Data safety:** Health and fitness (collected, linked, not shared for advertising), Photos (collected, not stored beyond the request), Email (optional, account), Purchase history. Encryption in transit: yes. Deletion: in-app.
- **Ads:** none. **Tracking:** none.
