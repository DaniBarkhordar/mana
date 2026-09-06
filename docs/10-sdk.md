# The Shenzhen Unique Scales (Lefu) SDK — what is actually in it

The vendor's SDK source is vendored under `vendor/` — six repositories cloned from `github.com/LefuHengqi` on 6 September 2026. Everything below was read from that code, not from documentation.

| Repo | What it is | Use |
|---|---|---|
| `pp_bluetooth_kit_flutter` | **The official Flutter plugin.** Dart API over a method channel; bundles the iOS `PPBaseKit` and `PPBluetoothKit` xcframeworks under `ios/Frameworks/` | This is what the app depends on |
| `pp_bluetooth_kit_demo` | Flutter demo app, one screen per device family | Copy the patterns, especially `lib/Device/device_fish.dart` (kitchen) and the body-scale screens |
| `BluetoothKit-AndroidDemo` | Native Android demo (Kotlin) | Reference for Android gradle setup and permissions |
| `BluetoothKit-iOSDemo` | Native iOS demo with the pods checked in | Reference only |
| `PPBluetoothKit`, `PPCalculateKit` | iOS pods — closed xcframeworks with podspecs | Reference only; the Flutter plugin already bundles what it needs |

## Credentials are self-service — do not wait for the sales rep

The plugin README, §1.1–1.4, is explicit: **register on the Lefu Open Platform, fill in company details, and the AppKey and AppSecret are issued to your account.** Then configure the device model(s) you are buying on the platform and download the config file, renamed to `lefu.config`.

- Register: `https://uniquehealth.lefuenergy.com/unique-open-web/#/login`
- Device configuration guide: `https://xinzhiyun.feishu.cn/docx/Gw38d5JskoShyFxKnwIcvIaznhb` (Feishu; opens in a browser, blocked to bots)
- Download config: `https://uniquehealth.lefuenergy.com/unique-open-web/#/usermsg`

What you still need from Sophia is the **model code** of each device (their `CF###` / `CK###` codes), so you can add them on the platform. That is one WeChat message, not a negotiation.

**For development today**, the demos ship working credentials and config files. They are the vendor's own demo keys, published in a public repository, and the demo code says in Chinese to replace them with your own before shipping — so: fine for a developer testing against a unit on the desk, never in a build that leaves the desk.

```
vendor/BluetoothKit-AndroidDemo/app/src/main/java/com/lefu/ppblutoothkit/PPApplication.kt   (appKey / appSecret)
vendor/pp_bluetooth_kit_demo/config/lefu.config                                            (demo config, ~200 KB base64)
```

The demo config whitelists whichever devices the vendor configured for their demo account. If your unit does not appear in a scan with the demo config, that is why — it is not a bug.

## The Android artifacts are resolvable after all

Earlier research said `com.lefu.*` was not on Maven Central or the Aliyun mirror. Correct — the vendor hosts its own Maven repository on GitHub:

```gradle
maven { url "https://raw.githubusercontent.com/LefuHengqi/PPBaseKit-Android/main" }
```

The Flutter plugin's `android/build.gradle` already declares it and depends on `com.lefu.ppbasekit:ppbasekit:4.6.13`, `com.lefu:bluetoothkit:1.5.5`, `com.lefu.ppbluetoothkit:ppbluetoothkit:4.6.13`. The native demo is on `4.6.21`. Nothing to hand-drop.

## The Dart API, as it really is

```dart
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';

// Once, at startup. Synchronous.
final config = await rootBundle.loadString('config/lefu.config');
PPBluetoothKitManager.initSDK(appKey, appSecret, config);

// Discovery
await PPBluetoothKitManager.startScan((PPDeviceModel device) { ... });
await PPBluetoothKitManager.stopScan();
PPBluetoothKitManager.addScanStateListener(callBack: (bool scanning) { ... });
PPBluetoothKitManager.addBlePermissionListener(...);

// Connection
PPBluetoothKitManager.connectDevice(device,
    callBack: (PPDeviceConnectionState state) { ... });   // fires on connect AND disconnect
PPBluetoothKitManager.disconnect();
final current = await PPBluetoothKitManager.fetchConnectedDevice();

// Measurements — register ONE listener globally; a second registration replaces the first
PPBluetoothKitManager.addMeasurementListener(
    callBack: (PPMeasurementDataState state, PPBodyBaseModel m, PPDeviceModel d) { ... });
PPBluetoothKitManager.addKitchenMeasurementListener(
    callBack: (PPMeasurementDataState state, PPBodyBaseModel m, PPDeviceModel d) { ... });

// Kitchen tare — per device family
await PPPeripheralFish.toZero();   // or PPPeripheralEgg.toZero()
```

### Stability is a state, not a heuristic

`PPMeasurementDataState` has four values: `processData`, `measuringBodyFat`, `measuringHeartRate`, **`completed`** — and the source comment on `completed` says "in this state, read the impedance and calculate body data". That is the stability signal. Earlier notes said the bridge exposed no stable flag and the driver watched the value settle; that was wrong. Use `state == completed`. Keep `MeasurementAggregator` as a belt-and-braces guard, not as the primary signal.

### Units — they differ by device kind

`PPBodyBaseModel.weight` is an `int`.

- **Body scale:** kilograms × 100. `weight / 100.0` = kg. The model has `getPpWeightKg()` for exactly this.
- **Kitchen scale:** the vendor's own demo (`device_fish.dart`) does `weight / 10.0` and displays that — i.e. **tenths of a gram**. Check `device.deviceAccuracyType` (`point01`, `point005`, `pointG`, `point01G`, `point001`) before trusting the divisor on a new model, and write a test the first time a real unit is on the desk.

### Impedance

- `impedance` (`int`) — commented "4-electrode algorithm impedance". This is the plain scalar. Confirm it is ohms with the factory before it feeds an equation; the plausibility gate in `BodyCompositionEngine` (200–1200 Ω) will catch a wrong scale factor loudly rather than silently.
- `impedance100EnCode` and the ten `z20Khz*EnCode` / `z100Khz*EnCode` fields — commented "encrypted values" (加密值 / 密文). Not ohms. Store raw in `segmental_raw`; do not display until the decode is confirmed. This is factory question 5 and it stands.

### Device model — useful fields

`PPDeviceModel` carries `deviceMac`, `deviceName`, `devicePower` (−1 = unsupported), `rssi`, `firmwareVersion`, `productModel`, `deviceType`, `deviceProtocolType`, **`deviceCalculateType`** (which vendor algorithm family: `alternate` = 4-electrode AC, `alternate8*` = 8-electrode, `inScale` = computed on the scale, `needNot` = weight-only), **`deviceAccuracyType`**, `devicePowerType`, `standardType` (0 Asia, 1 WHO), `mtu`.

`deviceCalculateType` answers factory question 1 from the device itself once one is on the desk.

## Vendor cloud — still off-limits

Nothing in the Flutter bridge calls the network. The native Android demo does (`okhttp/NetUtil.java`, `GET_SCALE_CONFIG + appKey`) — to fetch device configuration for the demo, with a comment saying production apps should use the bundled `lefu.config` instead. The `PPCalculateKit` library is what computes composition on device; the cloud body-data endpoint at `uniquehealth.lefuenergy.com/openapi-bodydata/...` is separate, and the rule in `CLAUDE.md` stands: never call it with user data.

## What this changes in the plan

- **Phase 3 is no longer blocked.** A developer with a scale on the desk can integrate against the demo credentials today; production credentials come from self-service registration plus the model codes.
- `PpBluetoothKitChannel` in `lib/core/scale/lefu_driver.dart` is implemented over a process-wide `LefuSdkGateway` that owns the SDK's single-registration callbacks (one scan, one connection, one listener per kind). The vendored copy carries two marked one-line changes: the secret is not logged on init, and `pp_peripheral_dorre.dart` returns a non-null bool (it did not compile as shipped).
- Ask Sophia for **model codes**, and separately ask her to have the factory confirm the impedance units and the `EnCode` decode. The exclusivity conversation is unchanged.
