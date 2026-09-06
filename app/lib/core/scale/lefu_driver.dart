/// Driver for Shenzhen Unique Scales (Lefu) hardware via the vendor's official
/// Flutter plugin, `pp_bluetooth_kit_flutter`.
///
/// WHY FLUTTER AND NOT REACT NATIVE
/// The vendor maintains an official Flutter plugin (github.com/LefuHengqi/
/// pp_bluetooth_kit_flutter) alongside their iOS and Android SDKs. There is no
/// React Native binding. Choosing Flutter means the riskiest, most tedious part
/// of this project — bridging a closed vendor SDK into a cross-platform app,
/// twice, and maintaining it — is work the vendor already did and keeps doing.
///
/// WHAT THE VENDOR SDK GIVES US
///   * device discovery and connection across their 13 device families
///   * whole-body impedance AND five-segment impedance at 20 kHz and 100 kHz
///   * on-device body-composition maths in `PPCalculateKit`
///   * the kitchen scale on the same SDK and the same credentials
///
/// WHAT WE DELIBERATELY DO NOT USE
///   * `uniquehealth.lefuenergy.com` — the vendor's cloud body-composition API.
///     It takes age, sex, height, weight, heart rate and impedance, which is
///     Article 9 special-category health data, and sends it to a server in the
///     PRC. There is no adequacy decision, no SCCs and no processor agreement.
///     A privacy notice does not fix that. All composition maths runs locally:
///     either the vendor's on-device library or, preferably, our own published
///     equations in core/bia, which we can explain, test and defend.
///   * the vendor's body-fat output as the displayed number, because we cannot
///     see the algorithm, cite it, or state its error.
///
/// The impedance is what we want from them. The interpretation is ours.
library;

import 'dart:async';

import 'scale_driver.dart';

/// Credentials issued by the vendor's open platform.
///
/// All three are required before the SDK will initialise, and `configAsset` is
/// an opaque encrypted blob we cannot audit. That is a real supply-chain
/// dependency: see docs/01-factory-questions.md question 3, which asks the
/// factory in writing whether it expires and whether initialisation touches the
/// network.
class LefuCredentials {
  const LefuCredentials({
    required this.appKey,
    required this.appSecret,
    required this.configAsset,
  });

  final String appKey;
  final String appSecret;

  /// Asset path of the vendor's `lefu.config` licence file.
  final String configAsset;

  /// Never log or transmit the secret. Present so a support build can confirm
  /// which key is loaded without exposing it.
  String get redacted => '${appKey.substring(0, appKey.length.clamp(0, 8))}…';
}

/// Maps the vendor's fruit-codenamed device families onto something meaningful.
///
/// Taken from `PPDevicePeripheralType`. The families matter because they select
/// the transport: some connect over GATT, some only broadcast, and the kitchen
/// scales use a different callback entirely.
enum LefuDeviceFamily {
  apple('PeripheralApple', ScaleKind.body, transport: LefuTransport.gatt),
  coconut('Coconut', ScaleKind.body, transport: LefuTransport.gatt),
  torre('Torre', ScaleKind.body, transport: LefuTransport.gatt),
  ice('Ice', ScaleKind.body, transport: LefuTransport.gatt),
  banana('Banana', ScaleKind.body, transport: LefuTransport.broadcast),
  jambul('Jambul', ScaleKind.body, transport: LefuTransport.broadcast),
  borre('Borre', ScaleKind.body, transport: LefuTransport.gatt),
  forre('Forre', ScaleKind.body, transport: LefuTransport.gatt),
  durian('Durian', ScaleKind.body, transport: LefuTransport.gatt),
  fish('Fish', ScaleKind.kitchen, transport: LefuTransport.gatt),
  egg('Egg', ScaleKind.kitchen, transport: LefuTransport.gatt),
  hamburger('Hamburger', ScaleKind.kitchen, transport: LefuTransport.broadcast),
  grapes('Grapes', ScaleKind.kitchen, transport: LefuTransport.broadcast);

  const LefuDeviceFamily(this.sdkName, this.kind, {required this.transport});

  final String sdkName;
  final ScaleKind kind;
  final LefuTransport transport;

  static LefuDeviceFamily? fromSdkName(String? name) {
    if (name == null) return null;
    for (final f in LefuDeviceFamily.values) {
      if (f.sdkName.toLowerCase() == name.toLowerCase()) return f;
    }
    return null;
  }
}

enum LefuTransport {
  /// Connect, then subscribe to notifications.
  gatt,

  /// Parse advertisements; never connects.
  broadcast,
}

/// One measurement as the vendor SDK reports it, before we interpret anything.
///
/// Field names mirror the SDK's own keys so the mapping is auditable. The
/// `EnCode` suffix on the segmental values is the vendor's: those arrive
/// encoded rather than as plain ohms, and the decode must be confirmed with the
/// factory before segmental analysis ships — see docs/01-factory-questions.md
/// question 5. Until then, segmental values are stored raw and not displayed.
class LefuMeasurement {
  const LefuMeasurement({
    required this.weightKg,
    required this.measuredAt,
    this.impedance,
    this.heartRate,
    this.isOverload = false,
    this.isCompleted = false,
    this.z100Khz,
    this.z20Khz,
  });

  /// True when the SDK reported `PPMeasurementDataState.completed`.
  final bool isCompleted;

  final double weightKg;
  final DateTime measuredAt;

  /// Whole-body impedance. The vendor's cloud API documents this field in ohms;
  /// confirm the SDK's scalar matches before trusting it in an equation.
  final double? impedance;

  final int? heartRate;
  final bool isOverload;

  final SegmentalImpedance? z100Khz;
  final SegmentalImpedance? z20Khz;

  bool get hasSegmental =>
      (z100Khz?.isComplete ?? false) && (z20Khz?.isComplete ?? false);
}

/// Thin abstraction over the vendor plugin's method channel.
///
/// Kept as an interface so the app compiles and every screen can be built and
/// tested before the credentials arrive from Shenzhen. Swap in
/// [PpBluetoothKitChannel] once the appKey lands; nothing else changes.
abstract class LefuSdkChannel {
  Future<bool> initSdk(LefuCredentials credentials);
  Stream<Map<String, dynamic>> startScan();
  Future<void> stopScan();
  Future<void> connectDevice(String deviceId);
  Future<void> disconnect();
  Stream<Map<String, dynamic>> measurements();
  Future<void> toZero();
  Future<void> impedanceSwitchControl({required bool on});
  Future<Map<String, dynamic>> fetchDeviceInfo();
}

/// Driver proper.
class LefuScaleDriver implements ScaleDriver {
  LefuScaleDriver({
    required LefuSdkChannel channel,
    required LefuCredentials credentials,
    this.kind = ScaleKind.body,
  })  : _channel = channel,
        _credentials = credentials;

  final LefuSdkChannel _channel;
  final LefuCredentials _credentials;
  final ScaleKind kind;

  final _state = StreamController<ScaleConnectionState>.broadcast();
  final _samples = StreamController<WeightSample>.broadcast();
  final _aggregator = MeasurementAggregator();

  StreamSubscription<Map<String, dynamic>>? _measurementSub;
  bool _initialised = false;

  @override
  String get driverName => 'lefu/pp_bluetooth_kit';

  @override
  Stream<ScaleConnectionState> get connectionState => _state.stream;

  @override
  Stream<WeightSample> get samples => _samples.stream;

  @override
  Future<bool> initialise() async {
    if (_initialised) return true;
    try {
      _initialised = await _channel.initSdk(_credentials);
    } on Object {
      _initialised = false;
    }
    if (!_initialised) {
      // Almost always a bad or expired licence blob rather than a bug. The UI
      // must degrade to weight-only rather than showing a stack trace, and
      // support needs to be able to tell the two apart.
      _state.add(ScaleConnectionState.unauthorised);
    }
    return _initialised;
  }

  @override
  Stream<DiscoveredScale> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    if (!await initialise()) return;
    _state.add(ScaleConnectionState.scanning);

    final stream = _channel.startScan().timeout(
          timeout,
          onTimeout: (sink) => sink.close(),
        );

    await for (final raw in stream) {
      final family = LefuDeviceFamily.fromSdkName(raw['deviceType'] as String?);
      if (family != null && family.kind != kind) continue;
      yield DiscoveredScale(
        id: (raw['deviceMac'] ?? raw['deviceId'] ?? '').toString(),
        name: (raw['deviceName'] ?? 'Scale').toString(),
        kind: family?.kind ?? kind,
        rssi: raw['rssi'] as int?,
        protocolHint: family?.sdkName,
        modelCode: raw['modelCode'] as String?,
      );
    }
  }

  @override
  Future<void> stopScan() => _channel.stopScan();

  @override
  Future<void> connect(DiscoveredScale scale) async {
    _state.add(ScaleConnectionState.connecting);
    await _channel.connectDevice(scale.id);

    // Impedance is switchable per device and there is no guarantee of its
    // default, so it is turned on explicitly on every connect.
    if (kind == ScaleKind.body) {
      try {
        await _channel.impedanceSwitchControl(on: true);
      } on Object {
        // Older families do not implement the switch; impedance still arrives.
      }
    }

    await _measurementSub?.cancel();
    _measurementSub = _channel.measurements().listen(_onMeasurement);
    _aggregator.reset();
    _state.add(ScaleConnectionState.connected);
  }

  void _onMeasurement(Map<String, dynamic> raw) {
    final m = parseMeasurement(raw);
    if (m == null) return;
    if (m.isOverload) return;

    _samples.add(
      WeightSample(
        kg: m.weightKg,
        // The vendor bridge does not expose a stability flag, so settling is
        // detected by watching the value hold still. See MeasurementAggregator.
        isStable: _looksStable(m),
        at: m.measuredAt,
        impedanceOhm: m.impedance,
        segmental: m.z100Khz,
      ),
    );
  }

  bool _looksStable(LefuMeasurement m) {
    // The SDK reports PPMeasurementDataState.completed when a reading is final
    // (vendor source: "in this state, read the impedance and calculate body
    // data"). PpBluetoothKitChannel maps that onto `isCompleted`. The
    // impedance check remains as a fallback for families that never send it.
    if (m.isCompleted) return true;
    if (kind == ScaleKind.body && m.impedance != null && m.impedance! > 0) {
      return true;
    }
    return false;
  }

  /// Maps the vendor's measurement dictionary onto [LefuMeasurement].
  ///
  /// Public and pure so it can be unit-tested against captured payloads without
  /// hardware or a licence.
  static LefuMeasurement? parseMeasurement(Map<String, dynamic> raw) {
    final weight = _num(raw['weight']) ?? _num(raw['lfWeightKg']);
    if (weight == null) return null;

    final ms = _num(raw['measureTime']);
    final at = ms == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(
            ms > 1e11 ? ms.toInt() : (ms * 1000).toInt(),
          );

    SegmentalImpedance? seg(int khz, String prefix) {
      final la = _num(raw['${prefix}LeftArmEnCode']);
      final ra = _num(raw['${prefix}RightArmEnCode']);
      final ll = _num(raw['${prefix}LeftLegEnCode']);
      final rl = _num(raw['${prefix}RightLegEnCode']);
      final tr = _num(raw['${prefix}TrunkEnCode']);
      if (la == null && ra == null && ll == null && rl == null && tr == null) {
        return null;
      }
      return SegmentalImpedance(
        frequencyKhz: khz,
        leftArm: la,
        rightArm: ra,
        leftLeg: ll,
        rightLeg: rl,
        trunk: tr,
      );
    }

    return LefuMeasurement(
      weightKg: weight,
      measuredAt: at,
      isCompleted: raw['state'] == 'completed' || raw['isCompleted'] == true,
      impedance: _num(raw['impedance']),
      heartRate: (raw['isHeartRating'] == true)
          ? _num(raw['heartRate'])?.toInt()
          : null,
      isOverload: raw['isOverload'] == true,
      z100Khz: seg(100, 'z100Khz'),
      z20Khz: seg(20, 'z20Khz'),
    );
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Future<void> disconnect() async {
    await _measurementSub?.cancel();
    _measurementSub = null;
    await _channel.disconnect();
    _state.add(ScaleConnectionState.disconnected);
  }

  @override
  Future<void> tare() => _channel.toZero();

  @override
  Future<void> dispose() async {
    await _measurementSub?.cancel();
    await _state.close();
    await _samples.close();
  }
}

/// Real implementation against the vendor plugin.
///
/// The plugin source is vendored at `vendor/pp_bluetooth_kit_flutter`; the API
/// is documented from that source in `docs/10-sdk.md`. Demo credentials for
/// desk testing are in the vendored demos; production credentials are
/// self-service on the Lefu Open Platform (see the same doc). This class is
/// roughly a day's work with a unit on the desk.
///
/// Key facts from the vendor source that this class must respect:
///   * `PPBodyBaseModel.weight` is an int: kg × 100 for body scales, tenths of
///     a gram for kitchen scales (the vendor's own kitchen demo divides by 10).
///     Check `device.deviceAccuracyType` before trusting a divisor.
///   * `PPMeasurementDataState.completed` is the stability signal. Map it to
///     `isCompleted` on the measurement map this channel emits.
///   * Register ONE measurement listener; a second registration replaces it.
///   * Kitchen tare is per family: `PPPeripheralFish.toZero()` / `PPPeripheralEgg.toZero()`.
///
/// Wiring, for whoever picks it up:
///
/// ```yaml
/// # pubspec.yaml
/// dependencies:
///   pp_bluetooth_kit_flutter:
///     git:
///       url: https://github.com/LefuHengqi/pp_bluetooth_kit_flutter.git
///       ref: 0.1.1
/// ```
///
/// ```dart
/// final config = await rootBundle.loadString('assets/lefu.config');
/// await PPBluetoothKitManager.initSDK(appKey, appSecret, config);
/// ```
class PpBluetoothKitChannel implements LefuSdkChannel {
  @override
  Future<bool> initSdk(LefuCredentials credentials) {
    throw UnimplementedError(
      'Waiting on appKey, appSecret and lefu.config from Shenzhen Unique '
      'Scales. Use SimulatedScaleDriver until then.',
    );
  }

  @override
  Stream<Map<String, dynamic>> startScan() => throw UnimplementedError();

  @override
  Future<void> stopScan() => throw UnimplementedError();

  @override
  Future<void> connectDevice(String deviceId) => throw UnimplementedError();

  @override
  Future<void> disconnect() => throw UnimplementedError();

  @override
  Stream<Map<String, dynamic>> measurements() => throw UnimplementedError();

  @override
  Future<void> toZero() => throw UnimplementedError();

  @override
  Future<void> impedanceSwitchControl({required bool on}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchDeviceInfo() => throw UnimplementedError();
}
