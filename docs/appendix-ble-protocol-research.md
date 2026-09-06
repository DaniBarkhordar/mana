I have comprehensive coverage across all six areas. Here are the findings.

---

# BLE Scale Protocols — Technical Research Notes

**Confidence key:** `[DOC]` = read from source code or an official/spec document · `[COMM]` = community reverse-engineering, single-source · `[INF]` = my inference, unverified.

---

## 0. Two corrections before you start

1. **Yolanda ≠ Transtek.** "Yolanda" is the brand of **Shenzhen Yolanda Technology Co., Ltd.**, and its SDK is the **Qingniu `QNBleSdk`** — the official docs live at `yolandaqingniu.github.io`, a single combined Yolanda/Qingniu site. **Guangdong Transtek Medical Electronics** (Zhongshan) is a *different, unrelated* ODM that makes scales/BP monitors for Medisana, iHealth etc. `[DOC]` So "Yolanda (Guangdong Transtek)" is two vendors merged. If your factory says "Yolanda protocol", they mean QN.
2. **openScale was rewritten.** The Java `BluetoothXxx.java` driver classes referenced in most blog posts and older PRs are **gone from `master`**. The current tree is Kotlin `ScaleDeviceHandler` subclasses. Any tutorial pointing at `BluetoothCommunication.java` / `BluetoothFactory.java` is stale (those paths now 404). `[DOC]`

---

## 1. openScale — vendors and driver architecture

Repo: https://github.com/oliexdev/openScale (GPLv3 — read it for protocol facts, don't copy code into a closed-source app)

### 1.1 Current layout

```
android_app/app/src/main/java/com/health/openscale/core/bluetooth/
  ScaleCommunicator.kt
  ScaleFactory.kt                  <- handler registry + resolution
  data/ScaleMeasurement.kt, ScaleUser.kt
  libs/                            <- pure math, no BLE
  scales/                          <- 53 files: handlers + transport adapters
```

`libs/` (body-composition maths, separated from transport — copy this idea): `MiScaleLib.kt`, `StandardImpedanceLib.kt`, `TrisaBodyAnalyzeLib.kt`, `YunmaiLib.kt`, `OneByoneLib.kt`, `OneByoneNewLib.kt`, `EufyP2Lib.kt`, `EtekcityLib.kt`, `SoehnleLib.kt`, `XiaomiS800Lib.kt`, `S400Aggregator.kt`, `S400BodyComposition.kt`, `S400Decryptor.kt`. `[DOC]`

### 1.2 The `ScaleDeviceHandler` contract `[DOC]`

```kotlin
abstract fun supportFor(device: ScannedDeviceInfo): DeviceSupport?   // null = not mine

open fun onAdvertisement(result: ScanResult, user: ScaleUser): BroadcastAction
protected open fun onConnected(user: ScaleUser)
protected open fun onNotification(characteristic: UUID, data: ByteArray, user: ScaleUser)
protected open fun onDisconnected()
open suspend fun onUserInteractionFeedback(type: UserInteractionType, appUserId: Int, data: Any)
@Composable open fun DeviceConfigurationUi()

data class DeviceSupport(
    val displayName: String,
    val capabilities: Set<DeviceCapability>,   // what the hardware can do
    val implemented: Set<DeviceCapability>,    // what this handler actually does
    val tuningProfile: TuningProfile = TuningProfile.Balanced,
    val linkMode: LinkMode = LinkMode.CONNECT_GATT
)

enum class LinkMode { CONNECT_GATT, BROADCAST_ONLY, CLASSIC_SPP }
enum class BroadcastAction { IGNORED, CONSUMED_KEEP_SCANNING, CONSUMED_STOP }
enum class DeviceCapability { BODY_COMPOSITION, TIME_SYNC, USER_SYNC,
                              HISTORY_READ, LIVE_WEIGHT_STREAM, UNIT_CONFIG, BATTERY_LEVEL }
```

Helpers given to handlers: `setNotifyOn(svc, chr)`, `writeTo(svc, chr, payload, withResponse)`, `readFrom(svc, chr)`, `publish(measurement)`, `requestDisconnect()`, `hasCharacteristic(svc, chr)`, `settingsGet/PutInt|String`, `userInfo/userWarn/userError`, `requestUserInteraction(...)`.

`LinkMode` selects the transport adapter: `CONNECT_GATT → GattScaleAdapter`, `BROADCAST_ONLY → BroadcastScaleAdapter`, `CLASSIC_SPP → SppScaleAdapter`. **This three-way split is the single most important design lesson** — advertisement-only scales and GATT scales need genuinely different plumbing (scan lifetime, dedup, stop conditions), but the same parser output type.

`BroadcastScaleAdapter` additionally does: RSSI floor filter, content-hash packet dedup over a time window, a stabilisation delay to avoid forwarding bursts, and retry/backoff. `[DOC]`

### 1.3 Handler resolution `[DOC]`

`ScaleFactory.createHandlers()` returns an **ordered** list; `createCommunicator` returns the **first** handler whose `supportFor()` is non-null. Ordering is load-bearing — from the source comment: *"TaylorBIAHandler, FitTrackDaraHandler, RelaxmedicHandler, RobiS9Handler and DrTrustSSW532Handler must stay ahead of MGBHandler"* because `MGBHandler` claims anything exposing service `0xFFB0`. Exact-name matches are placed ahead of the generic LeFu/`0xFFF0` handlers.

### 1.4 Full handler list (53 files) `[DOC]`

`AAAxHandler`, `ActiveEraBF06Handler`, `BeurerBF450Handler`, `BeurerSanitasHandler`, `BodyConnectHandler`, **`BroadcastScaleAdapter`**, `CultSmartScaleProHandler`, `CustomOpenScaleHandler`, `DebugGattHandler`, `DigooDGSO38HHandler`, `DrTrustSSW532Handler`, `ESCS20MHandler`, `EbelterBodyFatB2Handler`, **`EtekcityESF551Handler`**, `EufyC20Handler`, `EufyP2Handler`, `ExcelvanCF36xHandler`, `ExingtechY1Handler`, **`GattScaleAdapter`**, `HesleyHandler`, `HoffenBbs8107Handler`, `HuaweiAhCh100Handler`, `HuaweiCH100SHandler`, `IHealthHS3Handler`, `InlifeHandler`, **`MGBHandler`**, `MedisanaBs44xHandler`, **`MiScaleHandler`**, `MiScaleS400Handler`, **`ModernScaleAdapter`**, **`OkOkHandler`**, `OneByoneHandler`, `OneByoneNewHandler`, **`QNHandler`**, **`QNHandlerBroadcast`**, `RealmeSmartScaleHandler`, `RenphoES26BBHandler`, `RenphoHandler`, `RobiS9Handler`, `RunstarR5Handler`, `RyFitHandler`, `SanitasSbf72Handler`, `ScaleDeviceHandler`, `SenssunHandler`, **`SinocareHandler`**, `SoehnleHandler`, **`SppScaleAdapter`**, `StandardBeurerSanitasHandler`, **`StandardWeightProfileHandler`**, `TaylorBIAHandler`, `TrisaBodyAnalyzeHandler`, `XiaomiS800Handler`, `YunmaiHandler`.

**Protocol families that actually matter for a white-label Chinese scale (in likelihood order):** QN/Qingniu (`QNHandler`), OKOK/Chipsea broadcast (`OkOkHandler`), Lefu-Fitdays/MGB `0xFFB0` (`MGBHandler`), Bluetooth SIG standard (`StandardWeightProfileHandler`), Xiaomi MIBFS advertisement (`MiScaleHandler`), Senssun `0xFFF0` (`SenssunHandler`).

### 1.5 `StandardImpedanceLib` — the maths, and its provenance `[DOC]`

Inputs: impedance (Ω), weight (kg), height (m), age, sex. Outputs: body fat %, TBW (kg + %), skeletal muscle mass, bone mass, BMR, BMI. Core reused term is **`h²/R`**.

- FFM & TBW: **Sun SS et al., 2003** regressions
- BMR: **Katch–McArdle** → `FFM × 21.6 + 370`
- SMM: **Janssen et al.** — linear in `h²/R`, age, and a sex term (`3.825` male, `0` female)
- Bone mass: `5.7% (M) / 5.0% (F) × FFM`

Calibrated around **500 ± 100 Ω** for typical adults. This matters for you: **if the factory's impedance is on a different scale (e.g. per-segment, or already normalised), these formulas will produce nonsense.** See factory question A6.

---

## 2. Chinese OEM stacks — byte-level

### 2.1 Qingniu / QN / Yolanda (`QN-Scale`) `[DOC]` — most likely your factory's stack

Official SDK docs: https://yolandaqingniu.github.io/en/flow/ble_scale_custom_connect.html

**Transport: GATT notify.** (A separate broadcast variant exists — §2.7.)

Two UUID sets; a device implements one:

| Set | Service | Notify | Write | Extra |
|---|---|---|---|---|
| Type 1 | `0xFFE0` | `0xFFE1` weight/time/resistance | `0xFFE3` config/unit, `0xFFE4` time | `0xFFE2` indicate (misc/ack), `0x2A19` battery |
| Type 2 | `0xFFF0` | `0xFFF1` | `0xFFF2` (shared: unit + time) | `0x2A19` battery |

Fingerprints: advertised name `QN-Scale` / `QN-Scale1` (also `renpho-scale`, `seb-scale`); **vendor service `0xAE00` is a QN-only tell** and is the reliable one — names are re-branded freely.

**Live weight frame, opcode `0x10` (original layout):**

| Offset | Field | Notes |
|---|---|---|
| `[0]` | `0x10` opcode | |
| `[3:5]` | weight, **uint16 big-endian** | |
| `[5]` | **stable flag** — `0x00` live, `0x01` final | |
| `[6:8]` | R1 (primary impedance), uint16 BE | |
| `[8:10]` | R2 (secondary impedance), uint16 BE | |

**ES-30M variant:** `[4]` stable (`0x01`/`0x02` = stable), `[5:7]` weight BE, `[7:9]` R1, `[9:11]` R2.

**Stored/history frame, opcode `0x23`:** `[6:10]` device timestamp **LE** (QN epoch seconds), `[10:12]` weight BE, `[13:15]` R1 **LE**, `[15:17]` R2 **LE**. *(Note the endianness flips between live and stored frames — a classic footgun.)*

**Weight divisor is negotiated, not fixed.** Read frame `0x12`, `byte[10]`: `== 1` → divide by **100**; otherwise divide by **10**. openScale adds a sanity fallback: if the result is `≤ 5 kg` or `≥ 250 kg`, divide by 10 again.

**Checksum:** running 8-bit sum — `sum = (sum + byte) & 0xFF` over a start..end range (inclusive), appended as last byte.

**Commands written to `0xFFE3` / `0xFFF2`:**

| Op | Bytes |
|---|---|
| Unit config | `[0x13, 0x09, protocolType, unit, 0x10, 0x00, 0x00, 0x00, 0x00, cksum]` — `unit`: `0x01` = kg, `0x02` = lb/st |
| Time sync | `[0x20, 0x08, protocolType, t0, t1, t2, t3 (LE), 0x00, cksum]` |
| History query | `[0x22, 0x06, protocolType, 0x00, 0x03, cksum]` |

Community-confirmed minimal working sequence (ESPHome/OpenMQTTGateway thread): write `13 09 15 01 10 00 00 00 42` to `FFE3`, then `weight = ((x[3]&0xFF)<<8 | (x[4]&0xFF)) / 100.0`. Also a practical warning from that thread: **use 16-bit UUID short forms (`"ffe0"`) rather than the 128-bit expansion** on some stacks. `[COMM]`

**Impedance→ohms:** openScale applies `impedance = (R1 < 410.0) ? 3.0 : 0.3 * (R1 - 400.0)`. `[DOC]` — but treat this as an **openScale-specific normalisation for their formula library, not a vendor-documented ohm conversion** `[INF]`. Ask the factory directly (question A6).

Note the SDK also exposes `QNBleKitchenDevice`, `QNBleRulerDevice`, `QNBleBroadcastDevice`, `QNUserScaleConfig`, eight-electrode flows — same vendor, different device classes.

### 2.2 Xiaomi / Mi Body Composition Scale (MIBFS) `[DOC]` — **advertisement only, no connection needed**

Source: ESPHome `xiaomi_miscale` — https://api-docs.esphome.io/xiaomi__miscale_8cpp_source · https://github.com/oliexdev/openScale/wiki/Xiaomi-Bluetooth-Mi-Scale

Version discriminated by **service-data UUID + length**:

**V1 — service data `0x181D`, 10 bytes:**

| Offset | Field |
|---|---|
| `[0]` | unit/status: `0x22`/`0xA2` kg · `0x12`/`0xB2` jin · `0x03`/`0xB3` lb |
| `[1:3]` | weight uint16 **LE** |
| `[3:5]` year LE, `[5]` month, `[6]` day, `[7]` hour, `[8]` min, `[9]` sec |

kg = `raw × 0.01 / 2` (i.e. **/200**) · jin = `raw × 0.01 × 0.6` · lb = `raw × 0.01 × 0.453592`

**V2 (MIBFS) — service data `0x181B`, 13 bytes:**

| Offset | Field |
|---|---|
| `[0]` | unit: `0x02` kg, `0x03` lb |
| `[1]` | **flags**: bit1 = impedance present, **bit5 = stabilised**, **bit7 = load removed** |
| `[2:4]` | year LE |
| `[4]`,`[5]`,`[6]`,`[7]`,`[8]` | month, day, hour, minute, second |
| `[9:11]` | **impedance uint16 LE, ohms** |
| `[11:13]` | **weight uint16 LE** |

Accept only when `bit5 set && bit7 clear`. Reject impedance `== 0` or `≥ 3000`. Same kg/lb multipliers as V1.

Note Xiaomi **re-uses the SIG service UUIDs `0x181D`/`0x181B` as advertisement service-data IDs with an entirely non-SIG payload.** Do not let a UUID sniff route you into the SIG parser.

Xiaomi also exposes GATT: `0x181D` with Weight Measurement, a custom history char, and custom service `00001530-0000-3512-2118-0009af100700`; init by writing `01 96 8A BD 62` after enabling history notifications; set clock via `0x2A2B` (10 bytes). The S400 moved to **encrypted MiBeacon on `0xFE95` requiring a per-device bind key** — do not plan on supporting that.

### 2.3 Chipsea — two completely different stacks

**(a) Broadcast / "OKOK" protocol** (`OkOkHandler`) `[DOC]` — **advertisement only, non-connectable**

Names: `OKOK`, `Nameless`, `ADV`, `Chipsea-BLE`, `Yoda0`, `Yoda1` (prefix, case-insensitive). All multi-byte fields **big-endian**.

| Variant | Mfr ID | Len | Weight | Impedance | Checksum | Stable |
|---|---|---|---|---|---|---|
| V20 | `0x20CA` | 19 | MSB `[8]`, LSB `[9]`; ÷10 or ÷100 per `[6]` bit2 | MSB `[10]`, LSB `[11]`, ÷10 | `[12]` = XOR over `0x20` prefix + `[0..11]` | `[6]` bit0 |
| V11 | `0x11CA` | 23 | MSB `[3]`, LSB `[4]` | — | `[16]` = XOR with `0xCA ^ 0x11` prefix | body-props byte `[9]`: bits1–2 resolution, bits3–4 unit |
| VF0 | `0xF0FF` | — | MSB `[3]`, LSB `[2]`; ÷10 | — | — | — |
| C0 | any, low byte `0xC0` | — | MSB `[0]`, LSB `[1]` | — | — | `[6]` bit0; bits1–2 resolution, bits3–4 unit |

Unit codes: `0` = kg, `1` = jin, `2` = lb, `3` = st:lb.

Independent Gadgetbridge capture of a `Yoda0` device, 13 bytes of manufacturer data `[COMM]` (https://codeberg.org/Freeyourgadget/Gadgetbridge/issues/5271):

```
05 69 | 13 88 | 00 00 | 25 | 00 00 00 00 00 00
 ^weight ^"impedance"      ^unit+lock
```
`[0:2]` weight BE ÷100 kg · `[2:4]` nominally impedance but **hard-coded `0x1388` = 5000 on this unit — a real trap: a plausible-looking constant, not a measurement** · `[6]` unit+lock: `0x24` kg unlocked / `0x25` kg locked / `0x30`,`0x31` lb / `0x38`,`0x39` st:lb. st:lb decode: `st = raw / 256`, `lb = (raw % 256) / 10`.

**(b) GATT protocol, Chipsea CST34M97** (e.g. Lenovo HS11) `[COMM]` — https://gist.github.com/bendtherules/4f90fb0eba6f2ffd4847d8ab448c0eb1

Service `0xFFF0` · write `0xFFF1` · **notify `0xFFF4`** (note: *not* `0xFFF2`). 10-byte history records:

| Offset | Field |
|---|---|
| `[0]` hi nibble | year − 2017 |
| `[0]` lo nibble | month − 1 (0-based) |
| `[1]` `[2]` `[3]` `[4]` | day, hour, min, sec |
| `[5]` hi nibble | scale type (`0xF` on this model) |
| `[5]` lo nibble + `[6]` | **weight** = `((b5 & 0x0F) << 8 \| b6) × 0.1` kg |
| `[7:10]` | **impedance**, 24-bit LE = `b7 \| b8<<8 \| b9<<16` |

Commands: `F2 00` read stored measurements, `F2 01` delete. `F2 00` also terminates the record stream. No checksum documented.

### 2.4 ICOMON / MGB / SWAN — service `0xFFB0` `[DOC]`

`MGBHandler` matches names `SWAN`, `Icomon`, `YG` (also `Dr Trust Smart 505`). Service `0xFFB0`, `0xFFB1` write config, `0xFFB2` notify.

| | Live streaming frame (8 B) | Composite frame (20 B) |
|---|---|---|
| Weight | `[2:4]` uint16 **BE × 0.01 kg** | `[12:14]` uint16 BE **× 0.1** |
| Impedance | `[4:6]` uint16 BE **ohms**, only when header is `0xFD01`; valid 1–1499; **`[6]` must equal `0xCB`** | |
| Checksum | `[7]` = `sum([2..6]) & 0xFF` | |
| Stable | live `0xCE` → final **`0xCA`** | |

Config frame format: `[0xAC, 0x02, b2, b3, b4, b5, 0xCC, cksum]`. Opcodes `0xF7`/`0xFA` init, `0xFB` sex/age/height, `0xFD` date, `0xFC` time, `0xFE` units.

### 2.5 Lefu / Fitdays — the `0xFFB0` "AC02" dialect `[COMM]`

https://github.com/KristianP26/ble-scale-sync/issues/254 — **Fitdays is one of the most common white-label Chinese scale apps, so check this one early.**

Service `0xFFB0` · `0xFFB1` **write-without-response** (handle `0x001C`) · `0xFFB2` notify (handle `0x0018`) · `0xFFB3` indicate (unused).

Fixed 8-byte frames: `AC 02 | D0 D1 D2 D3 | STATUS | CKSUM`
- Weight stream: `AC 02 [weight_u16_BE] 00 00 [STATUS] [CKSUM]`, **kg = u16 / 10**
- `STATUS`: `0xCE` measuring/unstable → **`0xCA` stable/final**
- `CKSUM = (D0 + D1 + D2 + D3 + STATUS) & 0xFF`

Init after writing CCCD `0100` on `FFB2`:
```
ac02 fa01 0000 cc c7
ac02 fb02 1fa5 cc 8d
ac02 fde2 0101 cc ad
ac02 fc01 0000 cc c9
ac02 fe06 0000 cc d0
```
40-byte type-`FF` result frames carry impedance but were found unreliable; that adapter treats the device as weight-only.

### 2.6 Sinocare (body scale) `[DOC]` — **advertisement only**

Name matches `"Weight Scale"` (case-insensitive), **manufacturer ID `0xFF64`**, payload > 16 bytes.

- Weight: **LSB `[9]`, MSB `[10]`**, ÷ **100** (centikilograms)
- **Checksum: `XOR` of bytes `[6..15]` inclusive must equal `data[16]`**
- No stable flag in the payload — openScale uses a heuristic: **9 consecutive identical raw weights** (`WEIGHT_TRIGGER_THRESHOLD = 9`), then publish and stop scanning
- Negative/zero weights discarded. **No impedance implemented** — capabilities set is empty.

### 2.7 Broadcast-only Fitindex / Renpho `[DOC]`

This is `QNHandlerBroadcast` — the QN family in non-connectable mode:

| Field | Value |
|---|---|
| Manufacturer company ID | `0xFFFF` |
| **Magic header** | `0xAA 0xBB` at `[0:2]` — *the only reliable fingerprint*; names are unreliable |
| MAC | `[2:8]`, 6 bytes BE |
| **Stable flag** | `[15]`, **bit 5** (mask `0x20`) |
| **Weight** | `[17:19]` uint16 **LE**, ÷ **100** kg |
| Range check | 0.5–300 kg |
| Min length | 19 bytes |
| Advertising | `ADV_NONCONN_IND` |
| Impedance | **none** — broadcast mode cannot carry BIA |

**Renpho GATT variants are different again:**
- `ES-CS20M` / `ES-30M` → QN protocol (§2.1)
- `ES-WBE28` (`RenphoHandler`) `[DOC]` → SIG services `0x181B`/`0x181C`/`0x181D`/`0x1805` **plus** vendor chars `0xFFE1` notify, `0xFFE2` write, `0xFFF1`. Vendor frame `byte[0] == 0x2E`, `raw = (b[2]<<8) | b[1]`, **`kg = raw / 20.0`**. ⚠️ Flagging this: that divisor is *not* the SIG `×0.005` (÷200) — it's a vendor deviation on a nominally standard characteristic, and worth re-verifying against a real device before trusting. Magic writes: `MAGIC0 = 10 01 00 11`, `MAGIC1 = 03 00 01 04`, UCP `02 AA 0F 27`. Body composition `0x2A9C` parsing is marked TODO in the source (vendor-specific payload) and impedance is not implemented.

### 2.8 Senssun `0xFFF0` `[DOC]` — useful because many no-name scales copy it

Model A: svc `0xFFF0`, notify `0xFFF1`, write `0xFFF2`. Model B: svc `0xFFB0`, notify+write `0xFFB2`. Name `SENSSUN FAT`.

Notifications are prefixed with a `0xFF` padding byte, then a typed frame:

| Type | Payload |
|---|---|
| `0xA5` weight | `[1:3]` uint16 **BE ÷ 10** kg; **`[5]`: `0xAA` = stable, `0xA0` = live** |
| `0xB0` | `[1:3]` fat, `[3:5]` water, ÷10 |
| `0xC0` | `[1:3]` muscle, `[4],[3]` **bone (byte-reversed)**, ÷10 |
| `0xD0` | kcal |
| `0xBE` | error |

Checksum: `sum([1] .. [size−3])` stored at `[size−2]`. Publish when the received-group bitmask reaches `0x0F`. Sync commands: date `A5 30`, time `A5 31`, user `A5 10`.

### 2.9 Welland — **no public protocol** `[INF]`

Welland (HK) is an ODM (FG2211LB, FG2016LB-B, FG2015ULB etc.). I found **no** open-source driver, ESPHome component, or reverse-engineering write-up naming Welland. Their retail units ship with third-party apps. **Inference only:** given the FG-series form factor and app ecosystem, a Welland unit is most likely running either the Lefu/Fitdays `0xFFB0 AC02` stack (§2.5) or the OKOK/Chipsea broadcast stack (§2.3a). **Do not plan around this — sniff the device.**

### 2.10 Quick identification cheat-sheet

Run this before writing any parser:

| You observe | Family |
|---|---|
| Service `0xAE00` present | QN/Qingniu — §2.1 |
| Name `QN-Scale*`, svc `0xFFE0` or `0xFFF0` | QN — §2.1 |
| Mfr data starts `AA BB`, company `0xFFFF`, non-connectable | QN broadcast — §2.7 |
| Service data on `0x181B` (13 B) or `0x181D` (10 B) in the **advertisement** | Xiaomi MIBFS — §2.2 |
| Mfr ID `0x20CA` / `0x11CA` / name `Chipsea-BLE`,`Yoda*`,`OKOK` | Chipsea broadcast — §2.3a |
| Mfr ID `0xFF64`, name `Weight Scale` | Sinocare — §2.6 |
| Service `0xFFB0`, 8-byte frames starting `AC 02` | Lefu/Fitdays — §2.5 |
| Service `0xFFB0`, live `0xCE`/final `0xCA` | MGB/ICOMON — §2.4 |
| Service `0xFFF0`, notify `0xFFF4` | Chipsea CST34M97 GATT — §2.3b |
| Real GATT services `0x181D` **and** `0x181B` with `0x2A9E`/`0x2A9B` feature chars | SIG standard — §3 ✅ best case |

---

## 3. Bluetooth SIG standard services — the well-behaved case

Sources: https://www.bluetooth.com/specifications/specs/weight-scale-service-1-0/ · GATT XML from https://github.com/sputnikdev/bluetooth-gatt-parser · openScale `StandardWeightProfileHandler.kt`. `[DOC]`

### 3.1 Weight Scale Service `0x181D`

**Weight Measurement `0x2A9D` — property is INDICATE (not notify).** Write `0x0002` to the CCCD, not `0x0001`. Fields are LSO→MSO, packed, present only if flagged:

| Offset | Field | Format | Conversion |
|---|---|---|---|
| `0` | **Flags** | uint8 | bit0 unit (0 = SI kg, 1 = Imperial lb) · bit1 timestamp present · bit2 user ID present · bit3 BMI+height present · bits4–7 reserved |
| `1:3` | Weight | uint16 **LE** | **SI: × 0.005 kg** (÷200) · **Imperial: × 0.01 lb** |
| +7 | Time Stamp *(if bit1)* | `date_time` | year uint16 LE, month u8, day u8, hour u8, min u8, sec u8 |
| +1 | User ID *(if bit2)* | uint8 | `0xFF` = unknown user |
| +2 | BMI *(if bit3)* | uint16 LE | × 0.1 |
| +2 | Height *(if bit3)* | uint16 LE | SI × 0.001 m · Imperial × 0.1 in |

Also in the service: **Weight Scale Feature `0x2A9E`** (read) — advertises supported fields and the device's weight/height resolution. Read it at connect time to learn the real resolution rather than assuming. *(I did not verify its exact bit layout in this pass — `[INF]` on the specific bit indices.)*

### 3.2 Body Composition Service `0x181B`

**Body Composition Measurement `0x2A9C` — also INDICATE.**

**Flags: uint16 LE at bytes `[0:2]`**

| Bit | Meaning |
|---|---|
| 0 | Measurement units — 0 = SI (kg/m), 1 = Imperial (lb/in) |
| 1 | Time Stamp present |
| 2 | User ID present |
| 3 | Basal Metabolism present |
| 4 | Muscle Percentage present |
| 5 | Muscle Mass present |
| 6 | Fat Free Mass present |
| 7 | Soft Lean Mass present |
| 8 | Body Water Mass present |
| **9** | **Impedance present** |
| 10 | Weight present |
| 11 | Height present |
| 12 | **Multiple Packet Measurement** (measurement split across indications) |
| 13–15 | Reserved |

**Bytes `[2:4]`: Body Fat Percentage, uint16 LE × 0.1 %** — **mandatory, always present regardless of flags.**

Then, in exactly this order, each present only if its flag bit is set:

| Field | Format | Conversion |
|---|---|---|
| Time Stamp | date_time (7 B) | — |
| User ID | uint8 | `0xFF` = unknown |
| Basal Metabolism | uint16 LE | unit joule, exponent 3 → **value = raw kJ** |
| Muscle Percentage | uint16 LE | × 0.1 % |
| Muscle Mass | uint16 LE | SI × 0.005 kg · Imp × 0.01 lb |
| Fat Free Mass | uint16 LE | SI × 0.005 kg · Imp × 0.01 lb |
| Soft Lean Mass | uint16 LE | SI × 0.005 kg · Imp × 0.01 lb |
| Body Water Mass | uint16 LE | SI × 0.005 kg · Imp × 0.01 lb |
| **Impedance** | **uint16 LE** | **× 0.1 ohm** |
| Weight | uint16 LE | SI × 0.005 kg · Imp × 0.01 lb |
| Height | uint16 LE | SI × 0.001 m · Imp × 0.1 in |

**So yes — impedance is a first-class SIG field: flags bit 9, uint16 LE, 0.1 Ω resolution.** If your factory's scale sets bit 9, you get raw impedance for free and can run your own body-composition maths. This is the single best outcome; make it factory question A2.

Companion: **Body Composition Feature `0x2A9B`** (read) — declares which fields the device supports.

### 3.3 User Data Service `0x181C` — the part that bites

Multi-user SIG scales require a UDS handshake before they'll emit measurements. From `StandardWeightProfileHandler.kt` `[DOC]`:

**User Control Point `0x2A9F` opcodes:** `0x01` register new user · `0x02` consent · `0x04` list all users · `0x20` response opcode. Response result codes: `0x01` success · `0x04` operation failed · `0x05` user not authorised.

Flow: on connect, auto-consent from a persisted `{deviceUserIndex → consentCode}` map; if absent, list users; registering a new user generates a **random 16-bit consent code** which must be stored — **lose it and that user slot is unrecoverable without a factory reset.**

UDS characteristics used: `0x2A8C` gender, `0x2A8E` height (cm, LE), `0x2A85` date of birth (year LE), `0x2A80` age, `0x2AFF` athlete flag *(non-standard/vendor — `[INF]`)*, plus `0x2A99` DB change increment and `0x1805`/`0x2A2B` current time.

---

## 4. Kitchen / nutrition scales

### 4.1 Etekcity ESN00 / ESN90 Smart Nutrition Scale `[COMM]` — **the best-documented BLE kitchen scale**

Repo: https://github.com/hertzg/metekcity · write-up: https://dev.to/hertzg/hacking-ble-kitchen-scale-55io · samples: https://gist.github.com/hertzg/33f759c3dc49a3e9398df541ff5fabaf

| Service | Characteristic | Props | Role |
|---|---|---|---|
| `0x1910` | `0x2C10` | READ | |
| `0x1910` | `0x2C11` | WRITE / WRITE_NO_RSP | **commands, phone→scale** |
| `0x1910` | `0x2C12` | NOTIFY / INDICATE | **data, scale→phone** |
| `0x180A` | `0x2A23`, `0x2A50` | READ | device info |

**Frame:** `FE EF C0 A2 | TYPE | LEN | PAYLOAD… | CKSUM`

- bytes `[0:4]` = constant prelude **`FE EF C0 A2`**
- byte `[4]` = type · byte `[5]` = payload length · payload from `[6]` · last byte = checksum

**Measurement packet, type `0xD0`, len `0x05`:**

| Payload offset | Field | Values |
|---|---|---|
| `p[0]` | sign | `0x00` positive, `0x01` negative |
| `p[1:3]` | **weight, uint16 BIG-ENDIAN** | **value = grams × 10** → 0.1 g resolution |
| `p[3]` | unit | `0x00` g · `0x01` lb:oz · `0x02` ml · `0x03` fl oz · `0x04` ml (milk) · `0x05` fl oz (milk) · `0x06` oz |
| `p[4]` | **stable** | `0x00` measuring, `0x01` settled |

Worked examples from the capture:
```
fe ef c0 a2 d0 05 00 11 94 00 01 7b   -> +, 0x1194=4500 -> 450.0 g, unit=g, stable
fe ef c0 a2 d0 05 00 06 36 01 01 13   -> +, 0x0636=1590 -> 15.90, unit=lb:oz, stable
fe ef c0 a2 e0 01 00 e1               -> type 0xE0 = error response
```

**Commands (write to `0x2C11`):** `0xC0` SET_UNIT (1 byte, unit code) · **`0xC1` SET_TARE (1 byte bool `shouldReset`)** · `0xC4` SET_AUTO_OFF (1 byte timeout). Types `0xD2`/`0xD3` are tare-related responses.

A separate gist reports the **Sinocare CK-793 kitchen scale shares this chipset/protocol** — https://gist.github.com/scoates/840f2d30e25d6b5e6daa2c3251f5af39 `[COMM]`. So this `FE EF C0 A2` family is worth probing on any unknown Chinese kitchen scale.

⚠️ **Do not confuse with the Etekcity ESF-551 *body* scale**, which is a different protocol entirely (§4.4).

### 4.2 Acaia (Lunar / Pearl / Pyxis / Umbra) `[COMM]` — reference for live-gram streaming

Sources: https://github.com/lucapinello/pyacaia · https://github.com/zweckj/aioacaia · https://github.com/tatemazer/AcaiaArduinoBLE

**UUIDs:**
- Legacy: single char `00002a80-0000-1000-8000-00805f9b34fb` for both command and weight. ⚠️ `0x2A80` is the **SIG "Age" characteristic** — Acaia squatted on it. Never route by short UUID alone.
- Pyxis / Lunar 2021+: **ISSC/Microchip transparent-UART service** — write `49535343-8841-43f4-a8d4-ecbe34729bb3`, notify `49535343-1e4d-4bd9-ba61-23c647249616`

**Frame:** `EF DD | msgType | payload… | cksum1 | cksum2`
- header magic `0xEF 0xDD`
- **checksum: `cksum1 = Σ(payload bytes at even index) & 0xFF`, `cksum2 = Σ(odd index) & 0xFF`**

**Commands:**

| Purpose | msgType | Payload |
|---|---|---|
| Tare | `4` | `[0]` |
| **Heartbeat** | `0` | `[2, 0]` — **must be sent every ~3 s or the scale stops notifying** |
| Notification request | `12` | `[0,1,1,2,2,5,3,4]` with a length prefix |
| Identify | `11` | 15-byte payload (`0x2D` legacy, `0x30`–`0x39` Pyxis) |

**Weight decode:** payload `[0:2]` uint16 **LE**; `[4]` = unit divisor (`1`→÷10, `2`→÷100, `3`→÷1000, `4`→÷10000); `[5]` bit `0x02` set → negative.

The heartbeat requirement is the key transferable lesson: **several kitchen scales require a keepalive write or they silently stop streaming.** Budget for it.

### 4.3 Renpho / Chipsea-based kitchen scales `[INF]`

No public protocol documentation found for Renpho kitchen scales specifically. Chipsea-based kitchen scales overwhelmingly reuse the same `0xFFF0/0xFFF1/0xFFF2` or `0xFFB0/0xFFB1/0xFFB2` vendor-service pattern as the body scales, with grams as a uint16 (usually BE) and a unit + stable byte. **Inference — verify by sniffing.**

### 4.4 Etekcity ESF-551 body scale (for contrast) `[DOC]`

Name `Etekcity Smart Fitness Scale`. Service `0xFFF0`, notify `0xFFF1`, command `0xFFF2`. **Fixed 22-byte packets.**

| Offset | Field |
|---|---|
| `[0]`,`[1]`,`[3]` | frame sync `0xA5`, `0x02`, `0x10` |
| `[10:13]` | **weight, LE, ÷ 1000 → kg** (3-byte field) |
| `[13:15]` | **impedance, LE**, valid `0 < z < 1500` Ω |
| `[20]` | **stable flag, `== 0x01`** |

Unit-change command: 11-byte array, unit value at byte `[10]`, and byte `[5]` encodes `(43 − unitValue)`.

### 4.5 QN kitchen scales

`QNBleKitchenDevice` + `QNBleKitchenConfig` exist in `QNBleSdk` with a documented "Kitchen scale" flow, but **no byte-level protocol is published** — SDK-only. https://yolandaqingniu.github.io/en/ `[DOC]`

---

## 5. React Native BLE in 2026

### 5.1 Library comparison — current versions

| Package | Version | Expo config plugin | New Arch | Notes |
|---|---|---|---|---|
| **`react-native-ble-plx`** | **3.5.1** | ✅ **built in**, upstream | yes | dotintent. **Recommended default.** |
| `react-native-ble-manager` | **12.5.1** | ❌ not in package exports; community `@matthewwarnes/react-native-ble-manager-plugin` | ✅ `codegenConfig` `BleManagerSpec` (TurboModule) | innoveit |
| `react-native-ble-nitro` | 1.15.1 | ✅ ships `app.plugin.js` | Nitro Modules | peer: RN ≥ 0.76, `react-native-nitro-modules` ≥ 0.35. Newer, smaller ecosystem. |

**⚠️ `@config-plugins/react-native-ble-plx` is DEPRECATED.** Its README now reads: *"react-native-ble-plx now has upstream support for Expo Config Plugins. Use the latest version of react-native-ble-plx instead."* A lot of blog content still tells you to install it — don't. `[DOC]`

**There is no official `expo-bluetooth` module.** BLE always requires a **development build**; it will never run in Expo Go. `[DOC]`

**Expo SDK 56** (released 2026-05-21): React Native 0.85, React 19.2, **minimum iOS 16.4** (up from 15.1), Hermes v1 default, prebuilt XCFrameworks by default, config plugins now ship full TypeScript types. `[DOC]` https://expo.dev/changelog/sdk-56

### 5.2 Exact `app.json` config-plugin block (`react-native-ble-plx`) `[DOC]`

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-ble-plx",
        {
          "isBackgroundEnabled": true,
          "modes": ["central"],
          "bluetoothAlwaysPermission": "Allow $(PRODUCT_NAME) to connect to your scale",
          "neverForLocation": true
        }
      ]
    ]
  }
}
```

| Option | Type | Default | Effect |
|---|---|---|---|
| `isBackgroundEnabled` | boolean | `false` | Android background BLE support (adds the foreground-service scaffolding) |
| `neverForLocation` | boolean | `false` | adds `android:usesPermissionFlags="neverForLocation"` to `BLUETOOTH_SCAN` (API 31+) |
| `modes` | string[] | — | iOS `UIBackgroundModes`: `"central"`, `"peripheral"` |
| `bluetoothAlwaysPermission` | string \| false | — | iOS `NSBluetoothAlwaysUsageDescription` |

### 5.3 Android permissions — exact manifest `[DOC]`

For a scale app that does **not** derive location (https://developer.android.com/develop/connectivity/bluetooth/bt-permissions):

```xml
<uses-permission android:name="android.permission.BLUETOOTH"       android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
                 android:maxSdkVersion="30" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

- Runtime (must be requested at runtime, API 31+): `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`, `ACCESS_FINE_LOCATION`
- Install-time: `BLUETOOTH`, `BLUETOOTH_ADMIN` (API ≤ 30 only)
- `BLUETOOTH_ADVERTISE` — **omit it**; you're a central, and asking for it invites Play Store data-safety questions.

> **⚠️ `neverForLocation` risk for broadcast-only scales.** Android's own docs state that including `neverForLocation` **"filters some BLE beacons from scan results."** Your Sinocare / Chipsea-broadcast / QN-broadcast / Xiaomi scales deliver everything in the advertisement, so there is a real chance of losing packets on some OEM builds. **Test broadcast parsing on a Samsung and a Xiaomi device with the flag on before shipping it.** If it breaks, drop `neverForLocation`, keep `ACCESS_FINE_LOCATION` without `maxSdkVersion`, and request it at runtime. `[DOC]` + `[INF]` on the practical severity.

### 5.4 iOS Info.plist and background `[DOC]`

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app connects to your scale to record weight and body composition.</string>

<!-- only if you must support iOS < 13; SDK 56 min is 16.4, so normally omit -->
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app connects to your scale.</string>

<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

State restoration (https://github.com/dotintent/react-native-ble-plx/wiki/Background-mode-(iOS)):

```js
const manager = new BleManager({
  restoreStateIdentifier: 'ScaleBleRestore',
  restoreStateFunction: (restoredState) => {
    if (restoredState == null) { /* cold start */ }
    else { /* restoredState.connectedPeripherals */ }
  },
});
```

**Core Bluetooth background constraints — these directly shape your architecture** (https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html):

1. **You MUST pass a service-UUID filter to `startDeviceScan()` in the background.** Wildcard `null` scans return nothing. The peripheral must advertise that UUID.
2. `allowDuplicates` / `CBCentralManagerScanOptionAllowDuplicatesKey` is **ignored** in the background — repeated adverts coalesce into one discovery event.
3. Scan interval is throttled when all scanning apps are backgrounded.
4. `centralManager:willRestoreState:` fires **before** `centralManagerDidUpdateState:`.
5. Background task budget ≈ 15 min; on wake from suspension you get ≈ 35 s.

> **Consequence for broadcast-only scales:** a scale that advertises no service UUID (Chipsea/OKOK, Sinocare, QN-broadcast all put everything in *manufacturer* data) is **effectively undiscoverable in iOS background.** Design broadcast capture as a foreground, user-initiated "step on the scale now" flow. Only GATT scales that advertise a service UUID are viable background candidates. `[INF]` from the documented constraints.

---

## 6. Bridging a compiled vendor SDK (AAR / xcframework) into Expo

**Yes, this works.** Reference: https://docs.expo.dev/modules/third-party-library/ `[DOC]`

Requirements: **Continuous Native Generation (prebuild) or a bare project — Expo Go is out.** Build via EAS Build or local `expo prebuild && expo run:android|ios`.

### Practical steps

**1. Scaffold a local module** (stays in-repo, autolinked):
```bash
npx create-expo-module@latest --local qn-scale-sdk
```
Yields `modules/qn-scale-sdk/{android,ios,src,expo-module.config.json}`.

**2. Android — drop in the AAR:**
```
modules/qn-scale-sdk/android/libs/QNBleSdk.aar
```
```gradle
// modules/qn-scale-sdk/android/build.gradle
dependencies {
  implementation fileTree(dir: 'libs', include: ['*.aar', '*.jar'])
}
```
Expo autolinking registers the module's Gradle project; the AAR rides along. ⚠️ Known rough edges wrapping `.aar` in Expo Modules: https://github.com/expo/expo/issues/27985 — if the AAR has transitive Maven deps, declare them explicitly (an AAR carries no POM).

**3. iOS — vendored framework.** Keep Swift sources in a `src/` subdirectory so the framework's headers don't get globbed:
```
modules/qn-scale-sdk/ios/
  Frameworks/QNSDK.xcframework
  src/QnScaleSdkModule.swift
  QnScaleSdk.podspec
```
```ruby
s.vendored_frameworks = 'Frameworks/QNSDK.xcframework'
s.source_files        = 'src/**/*.{h,m,mm,swift}'   # NOT '**/*'
s.platforms           = { :ios => '16.4' }          # SDK 56 requirement
```

**4. Write the module surface** with the Expo Modules API (`Function`, `AsyncFunction`, `Events`) — expose `startScan / connect / onWeight / onBodyComposition` and nothing else, so the vendor SDK never leaks into your JS types.

**5. Config plugin** — only needed if the SDK demands manifest/plist entries beyond BLE (e.g. an API-key `<meta-data>`). Tutorial: https://docs.expo.dev/modules/config-plugin-and-native-module-tutorial/

**Non-obvious constraints, worth surfacing to the factory now:**
- **Ask for an `.xcframework`, not a `.framework`.** A fat `.framework` with a simulator slice **cannot be submitted to the App Store** and breaks Apple-Silicon simulator builds.
- Ask whether the SDK ships **arm64 simulator slices** — many Chinese SDKs are device-only, which blocks simulator development entirely.
- Ask for the **Android 14/15 `targetSdk` compatibility** status and whether the AAR bundles its own BLE permission declarations that will merge into your manifest (a common cause of surprise `ACCESS_FINE_LOCATION` requests).
- Ask whether the SDK **opens its own `CBCentralManager` / `BluetoothAdapter`.** If it does, it will **fight `react-native-ble-plx` for the radio.** This is the #1 integration failure mode for vendor scale SDKs and it argues strongly for shipping your own parsers as the primary path (§B).

---

# A) Questions to send the factory

Send as a numbered list and insist on written answers; ask for a **protocol PDF**, not just an SDK.

**Protocol & data**
1. Please provide the **BLE protocol specification document** (byte-level), not only the SDK. If an NDA is required, send it — we will sign.
2. Does the scale implement the **Bluetooth SIG Weight Scale Service (`0x181D`) and Body Composition Service (`0x181B`)**? If yes, which flag bits are set, and is **impedance exposed via `0x2A9C` flags bit 9**? *(If yes, we need almost nothing else.)*
3. Is measurement data delivered by **BLE advertisement (manufacturer/service data)** or by a **GATT notify/indicate characteristic** — or both? If both, which is authoritative?
4. List every **service UUID and characteristic UUID**, with properties (read/write/write-no-response/notify/indicate) and role.
5. For the measurement packet: **full byte-offset table**, including endianness of every multi-byte field, the **weight scale factor**, the **unit byte encoding** (kg/lb/jin/st:lb), and the **checksum algorithm** with a worked example.
6. **Impedance:** does the notification carry **raw impedance in ohms**, or a pre-scaled/vendor-encoded value? What is the unit and resolution? What is the valid range, and what value signals "no impedance measured"? Which byte offsets? *(We need raw ohms — a normalised value is unusable with published BIA regressions.)*
7. Which byte/bit is the **"stabilised vs live" flag**, and what are its exact values? Is there a separate "weight removed" / "load off" indicator?
8. Is there a **handshake or init sequence** required before the scale streams data (magic writes, time sync, user profile upload)? Give the exact byte sequences and the required order.
9. Does the scale require a **keepalive/heartbeat** write to keep notifying? Interval?
10. Is there **on-device history storage**? How is it read, and how is it acknowledged/cleared?
11. Are there **multiple protocol variants/versions** across firmware revisions or SKUs? How do we detect the version at runtime?

**Measurement & computation**
12. Is body composition computed **on the device, in your SDK on the phone, or in your cloud**? *(A cloud dependency is a product-level blocker — establish this immediately.)*
13. If the SDK computes it locally, which **published equations** are used (author/year), and can you provide the coefficients?
14. **How many electrodes** — 4 (foot-to-foot) or 8 (hand-to-foot)? How many **frequencies** (single vs multi-frequency)? What frequency/frequencies in kHz?
15. What is the **sample rate** of the live weight stream, and the typical **time-to-stable**?
16. Weight **capacity, graduation (resolution), and stated accuracy**; does resolution change above/below a threshold?
17. Does impedance vary meaningfully with **bare feet vs socks / dry vs damp skin**, and is there any on-device filtering or smoothing we should know about?

**Connectivity & lifecycle**
18. Exact **advertised device name** and any **name pattern/prefix**, plus the **MAC OUI prefix**. Can either be customised for us, and would that break your SDK?
19. Does the scale advertise a **service UUID in the advertisement packet**? *(Required for iOS background scanning — see §5.4. If not, ask them to add one.)*
20. **Pairing/bonding:** does it require BLE bonding, a PIN, or Just Works? Does it bond to one phone exclusively? How is bonding cleared?
21. Is the advertisement **connectable or non-connectable** (`ADV_IND` vs `ADV_NONCONN_IND`)? Advertising interval?
22. **Multi-user:** does the scale hold user slots on-device, and if so, how many, and what is the assignment/consent protocol?
23. Is any part of the payload **encrypted or obfuscated** (à la Xiaomi MiBeacon bind keys)?
24. **Sleep/wake behaviour:** what wakes the scale, how long does it advertise after a measurement, and when does it auto-power-off?
25. Battery reporting — standard `0x2A19`, or a vendor field?

**Firmware, SDK, compliance**
26. **Firmware update path:** is OTA/DFU supported? Which stack (Nordic DFU, Realtek, proprietary)? Can we drive it, or is it locked to your app?
27. Current firmware version, version-reporting mechanism, and your firmware **changelog/versioning policy**.
28. SDK deliverables: **Android `.aar`** (with transitive dependency list) and **iOS `.xcframework`** — confirm it is an *xcframework*, includes **arm64 simulator slices**, and states its **minimum iOS deployment target** and Android `minSdk`/`targetSdk`.
29. Does your SDK **open its own `CBCentralManager` / `BluetoothAdapter`**, or can it operate on a connection we own? *(Critical — see §6.)*
30. Does the SDK make **network calls**? To which endpoints, with what data? Is there an offline mode?
31. SDK **licence terms**, cost, and whether source or a protocol doc can be licensed instead.
32. **Certifications:** FCC ID, CE/UKCA, RoHS, REACH, BLE SIG **Declaration ID / QDID**, and — if you market any health claim — regulatory class in your target markets.
33. Chipset/module part number (e.g. Chipsea CST34M97, Realtek, Telink) — this alone often identifies the protocol family.
34. Can you supply **2–3 engineering samples plus raw HCI snoop logs** of a full session (connect → live → stable → disconnect) as a reference capture?

---

# B) Recommended abstraction

Mirror openScale's proven structure, which has survived 50+ protocols: **transport adapters are shared; parsers are pluggable and pure.**

## B.1 Layering

```
┌─────────────────────────────────────────────────────────┐
│ App / React hooks   useScale(), useLiveWeight()         │
├─────────────────────────────────────────────────────────┤
│ ScaleService — orchestration, session state, retries    │
├─────────────────────────────────────────────────────────┤
│ ScaleDriverRegistry — ordered, first-match-wins          │
├─────────────────────────────────────────────────────────┤
│ ScaleDriver implementations (one per protocol family)   │
│   QNDriver · ChipseaBroadcastDriver · LefuFFB0Driver    │
│   SigStandardDriver · MiScaleDriver · SinocareDriver    │
│   VendorSdkDriver  ← the factory SDK slots in HERE      │
├─────────────────────────────────────────────────────────┤
│ Transport adapters: GattTransport │ BroadcastTransport  │
├─────────────────────────────────────────────────────────┤
│ react-native-ble-plx  (or the vendor's native module)   │
└─────────────────────────────────────────────────────────┘
   BodyCompositionEngine — PURE, no BLE, swappable
```

**The load-bearing decision: keep body-composition maths in a separate pure module** (openScale's `libs/`). Transport, parsing, and physiology change independently. It also means you can A/B the factory's numbers against your own from the same raw impedance.

## B.2 Core types

```ts
export type LinkMode = 'gatt' | 'broadcast' | 'vendor-sdk';

export interface ScaleReading {
  weightKg: number;
  stable: boolean;                 // live stream vs final
  impedanceOhm?: number;           // RAW ohms only — never pre-scaled
  impedanceOhm2?: number;          // second electrode pair (8-electrode)
  unitOnDevice?: 'kg' | 'lb' | 'jin' | 'st';
  deviceTimestamp?: Date;
  batteryPct?: number;
  vendorComputed?: Partial<BodyComposition>;  // if the device/SDK sent its own
  raw: Uint8Array;                 // ALWAYS retain — see B.6
  source: { driverId: string; protocolVersion?: string };
}

export interface DeviceCandidate {
  id: string;                      // iOS UUID / Android MAC
  name: string | null;
  rssi: number;
  serviceUuids: string[];
  serviceData: Record<string, Uint8Array>;
  manufacturerData: Record<number, Uint8Array>;  // keyed by company ID
  isConnectable: boolean;
}

export interface DriverSupport {
  displayName: string;
  linkMode: LinkMode;
  capabilities: Set<Capability>;   // BODY_COMPOSITION | LIVE_WEIGHT | TIME_SYNC |
                                   // USER_SYNC | HISTORY | UNIT_CONFIG | BATTERY
  confidence: number;              // 0..1 — see B.4
}
```

## B.3 The driver interface

```ts
export interface ScaleDriver {
  readonly id: string;
  readonly priority: number;        // lower = evaluated earlier

  /** Pure, synchronous, no I/O. Return null if not mine. */
  supportFor(c: DeviceCandidate): DriverSupport | null;

  /** BROADCAST drivers */
  parseAdvertisement?(c: DeviceCandidate, ctx: UserContext): BroadcastResult;

  /** GATT drivers */
  onConnected?(io: GattIO, ctx: UserContext): Promise<void>;
  onNotification?(charUuid: string, data: Uint8Array, ctx: UserContext): ReadingEvent[];
  onDisconnected?(): void;

  /** Optional extras */
  setUnit?(io: GattIO, unit: 'kg' | 'lb'): Promise<void>;
  syncTime?(io: GattIO, when: Date): Promise<void>;
  readHistory?(io: GattIO): Promise<ScaleReading[]>;
  tare?(io: GattIO): Promise<void>;          // kitchen scales
}

export type BroadcastResult =
  | { action: 'ignored' }
  | { action: 'consumed-continue'; reading: ScaleReading }
  | { action: 'consumed-stop';     reading: ScaleReading };

export interface GattIO {
  notifyOn(service: string, char: string): Promise<void>;
  indicateOn(service: string, char: string): Promise<void>;   // SIG 0x2A9D/0x2A9C need this
  write(service: string, char: string, data: Uint8Array, withResponse?: boolean): Promise<void>;
  read(service: string, char: string): Promise<Uint8Array>;
  hasCharacteristic(service: string, char: string): boolean;
}
```

Copy openScale's `BroadcastAction` three-way return exactly — `ignored` / `consumed-continue` / `consumed-stop`. It is what lets one scan loop serve many broadcast protocols and know when to stop.

## B.4 Registry — improve on first-match-wins

openScale's ordering fragility (*"TaylorBIAHandler … must stay ahead of MGBHandler"*) is a maintenance tax. Use **confidence scoring** instead:

```ts
function resolve(c: DeviceCandidate): ScaleDriver | null {
  const hits = drivers
    .map(d => ({ d, s: d.supportFor(c) }))
    .filter(x => x.s !== null)
    .sort((a, b) => b.s!.confidence - a.s!.confidence || a.d.priority - b.d.priority);
  if (hits.length > 1) log.warn('ambiguous match', hits.map(h => h.d.id));
  return hits[0]?.d ?? null;
}
```

Confidence convention:
- `1.0` — unique magic bytes or vendor service (QN `0xAE00`; Chipsea mfr ID `0x20CA`; QN-broadcast `AA BB` header; Sinocare mfr `0xFF64`)
- `0.8` — exact device-name match
- `0.6` — vendor service UUID that several families share (`0xFFF0`, `0xFFB0`, `0xFFE0`)
- `0.4` — SIG standard services present (`SigStandardDriver`, the safety net — **always keep it registered last**)

Log every ambiguous match in dev builds; that log is how you discover the factory changed firmware.

## B.5 Parsers must be pure and independently testable

```ts
// parsers/qn.ts — zero BLE imports
export function parseQnWeightFrame(d: Uint8Array, divisor: 10 | 100): ScaleReading | null
```

Then table-driven tests against captured hex — the byte strings in §2 and §4 above are ready-made fixtures:

```ts
it('parses Chipsea Yoda0 advert', () => {
  const r = parseChipseaV20(hex('056913880000250000000000'));
  expect(r!.weightKg).toBeCloseTo(13.85);
});
```

**This is what makes the factory-SDK swap safe:** parsers have no BLE dependency, so they run in plain Jest on CI with no device.

## B.6 Always keep `raw`

Persist the raw bytes with every reading, at least in dev/beta. When the factory's firmware silently changes a divisor or an offset — and it will — a corpus of raw captures paired with the scale's own LCD reading is the difference between a one-hour fix and a re-reverse-engineering project.

## B.7 Slotting in the vendor SDK later

```ts
class VendorSdkDriver implements ScaleDriver {
  id = 'factory-qn-sdk';
  priority = 0;
  supportFor(c) {
    return NativeVendorSdk.canHandle(c.name, c.serviceUuids)
      ? { displayName: 'Factory Scale', linkMode: 'vendor-sdk' as const,
          capabilities: new Set([...]), confidence: 1.0 }
      : null;
  }
  // subscribes to the native module's event emitter, maps to ScaleReading
}
```

Because `linkMode: 'vendor-sdk'` bypasses `GattTransport` entirely, the vendor SDK owning the radio is contained to one driver. **But** — if the SDK grabs the global `CBCentralManager`/`BluetoothAdapter`, it will break your other drivers while active. Enforce **one active transport at a time** in `ScaleService`, and make that mutual exclusion explicit rather than emergent.

## B.8 Suggested build order

1. `SigStandardDriver` (§3) — pure spec, testable with **nRF Connect** as a mock peripheral, no hardware needed, and it may just work on day one.
2. `QNDriver` (§2.1) — highest prior probability for a white-label Chinese BIA scale.
3. `ChipseaBroadcastDriver` (§2.3a) + `LefuFFB0Driver` (§2.5) — cover most of the rest.
4. `MiScaleDriver` (§2.2) — trivial, advertisement-only, and gives you a second physical device to test the abstraction against, which is the real point.
5. Kitchen: `EtekcityEsn00Driver` (§4.1) as the reference `tare`/`setUnit` implementation.

**Day one, before any of that:** put `DebugGattHandler`'s equivalent in your app — a dev screen that dumps all services/characteristics, subscribes to everything, and logs raw hex with timestamps alongside the LCD reading. openScale ships exactly this, and it is how every protocol above was worked out.

---

## Sources

**openScale & reverse-engineering repos**
- [oliexdev/openScale](https://github.com/oliexdev/openScale) · [Supported scales wiki](https://github.com/oliexdev/openScale/wiki/Supported-scales-in-openScale) · [How to support a new scale](https://github.com/oliexdev/openScale/wiki/How-to-support-a-new-scale) · [Xiaomi Mi Scale wiki](https://github.com/oliexdev/openScale/wiki/Xiaomi-Bluetooth-Mi-Scale)
- Handler sources: [QNHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/QNHandler.kt) · [QNHandlerBroadcast.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/QNHandlerBroadcast.kt) · [StandardWeightProfileHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/StandardWeightProfileHandler.kt) · [SinocareHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/SinocareHandler.kt) · [OkOkHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/OkOkHandler.kt) · [MGBHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/MGBHandler.kt) · [SenssunHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/SenssunHandler.kt) · [EtekcityESF551Handler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/EtekcityESF551Handler.kt) · [RenphoHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/RenphoHandler.kt) · [ScaleDeviceHandler.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/ScaleDeviceHandler.kt) · [ScaleFactory.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/ScaleFactory.kt) · [BroadcastScaleAdapter.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/scales/BroadcastScaleAdapter.kt) · [StandardImpedanceLib.kt](https://raw.githubusercontent.com/oliexdev/openScale/master/android_app/app/src/main/java/com/health/openscale/core/bluetooth/libs/StandardImpedanceLib.kt)
- [KristianP26/ble-scale-sync](https://github.com/KristianP26/ble-scale-sync) · [Supported scales](https://blescalesync.dev/guide/supported-scales) · [Lefu/Fitdays FFB0 "AC02" decode, issue #254](https://github.com/KristianP26/ble-scale-sync/issues/254)
- [ESPHome `xiaomi_miscale.cpp`](https://api-docs.esphome.io/xiaomi__miscale_8cpp_source) · [ESPHome Miscale docs](https://esphome.io/components/sensor/xiaomi_miscale/) · [Theengs decoder XMTZC05HM](https://decoder.theengs.io/devices/XMTZC05HM.html)
- [Chipsea CST34M97 / Lenovo HS11 gist](https://gist.github.com/bendtherules/4f90fb0eba6f2ffd4847d8ab448c0eb1) · [Gadgetbridge issue #5271 — Chipsea "Yoda0"](https://codeberg.org/Freeyourgadget/Gadgetbridge/issues/5271)
- [OpenMQTTGateway — Integrate QN-Scale](https://community.openmqttgateway.com/t/integrate-qn-scale-with-bluetooth-ble-help-wanted/1586)

**Vendor / SIG specs**
- [Qingniu/Yolanda QNBleSdk docs](https://yolandaqingniu.github.io/en/) · [Common Bluetooth scale flow](https://yolandaqingniu.github.io/en/flow/ble_scale.html) · [Self-managed Bluetooth — UUID tables](https://yolandaqingniu.github.io/en/flow/ble_scale_custom_connect.html)
- [Bluetooth SIG Weight Scale Service 1.0](https://www.bluetooth.com/specifications/specs/weight-scale-service-1-0/) · [Weight Scale Profile 1.0](https://www.bluetooth.com/specifications/specs/weight-scale-profile-1-0/) · [weight_measurement.xml](https://github.com/sputnikdev/bluetooth-gatt-parser/blob/master/src/main/resources/gatt/characteristic/org.bluetooth.characteristic.weight_measurement.xml) · [body_composition_measurement.xml](https://github.com/sputnikdev/bluetooth-gatt-parser/blob/master/src/main/resources/gatt/characteristic/org.bluetooth.characteristic.body_composition_measurement.xml)
- [Transtek Medical (Wikipedia)](https://en.wikipedia.org/wiki/Transtek_Medical) · [Shenzhen Yolanda Technology](https://yolandascale.en.alibaba.com/company_profile.html)

**Kitchen scales**
- [hertzg/metekcity — ESN00 protocol](https://github.com/hertzg/metekcity) · [Hacking BLE Kitchen Scale](https://dev.to/hertzg/hacking-ble-kitchen-scale-55io) · [ESN00 packet samples gist](https://gist.github.com/hertzg/33f759c3dc49a3e9398df541ff5fabaf) · [Sinocare CK-793 / Etekcity gist](https://gist.github.com/scoates/840f2d30e25d6b5e6daa2c3251f5af39)
- [lucapinello/pyacaia](https://github.com/lucapinello/pyacaia) · [zweckj/aioacaia](https://github.com/zweckj/aioacaia) · [tatemazer/AcaiaArduinoBLE](https://github.com/tatemazer/AcaiaArduinoBLE)
- [etekcity-esf551-ble (PyPI)](https://pypi.org/project/etekcity-esf551-ble/)

**React Native / Expo**
- [react-native-ble-plx](https://github.com/dotintent/react-native-ble-plx) · [npm](https://www.npmjs.com/package/react-native-ble-plx) · [iOS background mode wiki](https://github.com/dotintent/react-native-ble-plx/wiki/Background-mode-(iOS)) · [deprecated @config-plugins/react-native-ble-plx](https://github.com/expo/config-plugins/blob/main/packages/react-native-ble-plx/README.md)
- [react-native-ble-manager](https://github.com/innoveit/react-native-ble-manager) · [@matthewwarnes/react-native-ble-manager-plugin](https://github.com/matthewwarnes/react-native-ble-manager-plugin) · [react-native-ble-nitro](https://github.com/zykeco/react-native-ble-nitro)
- [Expo: Wrap third-party native libraries](https://docs.expo.dev/modules/third-party-library/) · [Config plugin + native module tutorial](https://docs.expo.dev/modules/config-plugin-and-native-module-tutorial/) · [Expo Modules get started](https://docs.expo.dev/modules/get-started/) · [Expo SDK 56 changelog](https://expo.dev/changelog/sdk-56) · [expo/expo#27985 — AAR wrapping](https://github.com/expo/expo/issues/27985)
- [Android Bluetooth permissions](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions) · [Core Bluetooth background processing](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html)

---

**Two things I could not find publicly, flagged honestly:** (1) **Welland** has no open-source driver or protocol write-up anywhere I searched — §2.9 is inference only. (2) **QN kitchen scale** byte-level protocol is SDK-only; the flow docs exist but publish no packet layout. Both are covered by factory questions A1/A4/A5.agentId: afe40860e6ea372ec (use SendMessage with to: 'afe40860e6ea372ec', summary: '<5-10 word recap>' to continue this agent)
<usage>subagent_tokens: 155268
tool_uses: 103
duration_ms: 915093</usage>