# The factory: what to ask, and what to lock down

**Who they actually are.** Sophia Bonnie Zhang works for **Shenzhen Unique Scales Co., Ltd** — Chinese legal name 深圳市乐福衡器有限公司, trading in English as Lefu. Founded 2002, ~35,000 m² across 21 lines, roughly 1,200 staff, ISO 9001 and ISO 13485. Their SDK is the link you sent (`uniquehealth.lefuenergy.com`), their GitHub org is `LefuHengqi`, and their OEM client list includes **VeSync** — the parent of Etekcity, Levoit and Cosori — and **Ozeri**. Xiaomi ships a scale whose internal model ID is literally `lefu.scales.cf822`.

They are a real, large, competent manufacturer. That is good news for your product and it means you should negotiate like a brand owner, not a small buyer.

---

## 1. The thing worth more than the discount

Sophia's message says Scanfit holds **exclusive distribution in Denmark, Norway, Sweden, Holland, Finland and the United States**.

Read that list again for what is *not* on it. **The United Kingdom is not on it. Neither is Germany, France, Spain, Italy, Ireland or Poland.** The largest markets in Europe are unclaimed on this product, and Scanfit — a small Danish operation, 2.8★ on Google Play with about 5,000 installs — took the Nordics and the US and left them.

**Your first ask is not the $200. It is exclusivity for the UK and Ireland**, with a right of first refusal on Germany, France, Spain and Italy. If you order without asking, you will be competing on Amazon UK against three other people buying the same white-label unit from the same factory within a year, and the only thing that stops that is a clause in your agreement.

What to ask for, in order of what you are likely to get:

1. **Exclusive UK + Ireland distribution** for both models, for a defined term (start at 24 months) against an agreed minimum annual volume.
2. **Right of first refusal** on Germany, France, Spain, Italy for 12 months.
3. If they resist exclusivity on a first order — normal — ask for **exclusivity triggered by volume**: non-exclusive now, converting to exclusive UK/IE once you pass an agreed unit count. This costs them nothing and gives you a path.
4. Failing all of that, a **most-favoured-customer clause** on price, and written notice before they appoint a UK distributor.

Get whichever you get **in writing on the proforma invoice**, not in a chat message.

## 2. The coupon

The two $100 coupons were offered on 10 August, conditional on confirming "this week". That window closed around 17 August. Coupons like this are a standing sales tool, not a one-off — ask for them to be reinstated when you confirm. Do not let a $200 discount set your timetable on a decision this size, and do not let it be the reason you skip the exclusivity conversation.

## 3. Solution A vs Solution B

From the photos: **Solution A** is the black glass unit with a large segment LCD showing many metrics at once and four visible electrode pads. **Solution B** is the white unit with a small colour display in a central black strip. Both come paired with the same dark kitchen scale.

You cannot choose between them from photographs. Ask:

- The **model codes** for each. Their taxonomy: `CF###` = body-fat scales, `CK###` = kitchen scales, `CW###` = weight only. The code tells you which internal platform it is.
- **How many electrodes, and is it foot-to-foot or hand-to-foot?** Beware the marketing arithmetic: "8 electrodes" usually means four pads carrying two electrodes each, still measuring foot-to-foot. A genuine 8-electrode device has handles you hold. Foot-to-foot only measures the legs properly and infers the rest; it is materially less accurate, and Scanfit's own two websites contradict each other on exactly this point.
- **Which frequencies?** Their SDK exposes 20 kHz and 100 kHz, which is a genuine multi-frequency capability worth having and worth advertising.
- Display type, capacity, resolution, battery (see §6 on why you want replaceable cells), and whether the platform is real glass.

For the kitchen scale: **0.1 g resolution up to at least 1 kg** is the number to insist on. Etekcity's competing smart nutrition scale is only 1 g, and 0.1 g is a real, demonstrable advantage for exactly the ingredient-weighing workflow the app is built around.

## 4. Engineering questions — send these to `yanfabu-5@lefu.cc`, not to sales

Sophia is commercial. These need their developer support, and asking them well signals you are a serious brand rather than a first-time importer.

1. **Which `PPDevicePeripheralType` family and protocol generation (2.x / 3.x / 4.x / Torre) is my model?** Give them the `CF###` code. Their SDK has thirteen device families and four protocol generations; everything downstream depends on which one you have.

2. **Send the Android SDK artifacts.** The README advertises `com.lefu.ppbasekit:ppbasekit:4.1.5` and siblings, but `com.lefu` is not on Maven Central or the Aliyun mirror — I checked. It is distributed as files handed out through the open platform. Ask for the repository URL or the AAR set, and for the iOS pods (`PPBluetoothKit` 1.2.43 is on the public CocoaPods trunk) and the Flutter plugin ref.

3. **Confirm the model codes so the devices can be added on the Open Platform.** The AppKey, AppSecret and `lefu.config` are self-service once you register at `uniquehealth.lefuenergy.com` with company details and add your device models — see `10-sdk.md`. What you cannot do without the factory is know which `CF###`/`CK###` codes to add. Then, in writing:
   - Does `lefu.config` **expire**?
   - Is there an **online activation or licence check** at `initSdk`, and does the SDK function with no network at all?
   - **Which hostnames does the SDK contact?**

   This matters more than it sounds. `lefu.config` is an encrypted blob you cannot audit, and without it the SDK will not initialise. If it lapses, your product stops working. Get the answer in an email you can point at later.

4. **Confirm `PPCalculateKit` runs fully offline**, and that its local 4-electrode and 8-electrode algorithms give the same result as their cloud endpoint. Ask for the algorithm version string they are licensing you (theirs reports as e.g. `BH_V5.0.a`).

5. **Impedance units and encoding.** Their SDK emits a scalar `impedance` plus ten segmental values named `z100KhzLeftArmEnCode`, `z20KhzTrunkEnCode` and so on. The `EnCode` suffix means those are encoded, not plain ohms. Ask for: the unit of the scalar (their cloud API documents it in Ω), the decode for the `EnCode` variants, and a raw-ohms accessor. **Without this you cannot ship segmental analysis**, and segmental is one of your selling points over a £30 Renpho.

6. **The frame specification for your family** — service and characteristic UUIDs, advertisement layout, the field map of the 40-byte result frame, and the semantics of the stabilised flag. Their own README references a "self-hosted server integration" option, so they do share protocol documents with customers who are not using their cloud. Ask for that document by name.

7. **A GDPR data processing agreement**, or explicit written confirmation that no SDK component transmits personal data to infrastructure in China. Their own Unique Health app's privacy policy says data obtained in the PRC is stored in the PRC and mentions GDPR nowhere. See `04-compliance-uk.md` — this is the one that can genuinely bite you.

8. **Compliance pack.** Full test reports naming *your* model, not a generic certificate: RED/EMC/RF, safety, RoHS per-component declarations, battery. Plus **EN 18031 evidence** for RED cybersecurity, which has been mandatory since August 2025 and is the most common gap in cheap BLE hardware. And their ISO 13485 scope, plus whatever validation sits behind any accuracy claim they make.

9. **Which CF models buffer readings, how many, and does the clock persist across battery changes?** The SDK's `fetchHistoryData` exists on the Apple, Coconut, Ice and Torre-generation families, but the plugin source does not say which `CF###` codes keep readings on board, how deep the buffer is, or what happens to `measureTime` when the batteries come out. The app stores what the scale remembered under the scale's own timestamp and rejects anything before pairing or later than now (`app/lib/core/scale/stored_readings_sync.dart`); a clock that resets to 2000 on every battery change would make every buffered reading unusable, and we need to know that before the packaging says "records while your phone is away".

## 5. What you must own, or you do not have a brand

Putting your name on their product makes you the **manufacturer** in UK and EU law, not a reseller. That is not a formality — it means you hold the technical file for ten years, you issue the Declaration of Conformity in your company's name, and your name and a UK address go on the product.

So the supply contract needs, before you pay:

- **Transfer or licence of the full technical file and test reports, naming your model number.** A one-page "we are CE certified" PDF is not a technical file and will not survive a Trading Standards request.
- Confirmation of which **pre-certified BLE module** is inside, and its certification — this is how you inherit the RF test reports cheaply.
- Agreement that **artwork, packaging and the app are yours**, and that they will not supply your specific cosmetic configuration to another buyer.

## 6. Two things to specify before they tool up

**Use replaceable AAA or CR2032 cells, not a sealed rechargeable.** From 18 February 2027 the EU Battery Regulation requires portable batteries to be readily removable and replaceable by the end user. A sealed pack also complicates air freight and annoys customers. Scanfit's unit uses an 800 mAh lithium cell — do not copy that.

**No universal default password, a published security contact, and a stated minimum security-update period.** The UK PSTI regime has applied since April 2024 to products that connect to the internet directly or indirectly, and a BLE scale that pairs with an app that syncs to your cloud is very likely in scope. A Statement of Compliance has to accompany the product. The requirements are cheap; the penalty ceiling is £10m or 4% of worldwide revenue. Specify it now, because retrofitting firmware after tooling is expensive.

## 7. You do not need the final name to order

Most factories will run a first batch on neutral packaging and hold the printed carton and silkscreen artwork until you send it. Ask. That decouples the naming and trademark work from the production slot, which is exactly what you want given you have already lost time to it.

---

## The order of operations

1. Reply to Sophia. Re-open the conversation, ask for UK/Ireland exclusivity, ask for the model codes and the electrode configuration, ask whether the coupons can be reinstated.
2. Email `yanfabu-5@lefu.cc` with the nine engineering questions.
3. When they answer 1, 5 and 6, the app's hardware layer can be finished — it is roughly a day's work, because everything above that layer is already built and tested.
4. Place the order on neutral packaging while the trademark filing runs.
