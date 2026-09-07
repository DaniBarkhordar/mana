/// Driver for Shenzhen Unique Scales (Lefu) hardware via the vendor's official
/// Flutter plugin, `pp_bluetooth_kit_flutter`, vendored at
/// `vendor/pp_bluetooth_kit_flutter` and documented from its source in
/// `docs/10-sdk.md`.
///
/// WHY FLUTTER AND NOT REACT NATIVE
/// The vendor maintains an official Flutter plugin alongside their iOS and
/// Android SDKs. There is no React Native binding. Choosing Flutter means the
/// riskiest, most tedious part of this project — bridging a closed vendor SDK
/// into a cross-platform app, twice, and maintaining it — is work the vendor
/// already did and keeps doing.
///
/// WHAT THE VENDOR SDK GIVES US
///   * device discovery and connection across their device families
///   * whole-body impedance AND five-segment impedance at 20 kHz and 100 kHz
///   * the kitchen scale on the same SDK and the same credentials
///
/// WHAT WE DELIBERATELY DO NOT USE
///   * `uniquehealth.lefuenergy.com` — the vendor's cloud body-composition API.
///     It takes age, sex, height, weight, heart rate and impedance, which is
///     Article 9 special-category health data, and sends it to a server in the
///     PRC. There is no adequacy decision, no SCCs and no processor agreement.
///     All composition maths runs locally on our own published equations in
///     core/bia, which we can explain, test and defend.
///   * the vendor's body-fat output as the displayed number, because we cannot
///     see the algorithm, cite it, or state its error.
///
/// The impedance is what we want from them. The interpretation is ours.
///
/// SHAPE OF THE VENDOR API, AND WHAT IT FORCES
/// The plugin is a set of static methods over one method channel: one scan
/// callback, one connection at a time (`currentDevice` on the native side),
/// one body-measurement listener and one kitchen listener. Registering a
/// listener twice replaces the first. So there is one process-wide
/// [LefuSdkGateway] that owns those registrations and fans out, and one
/// [PpBluetoothKitChannel] per scale kind on top of it. Because only one scale
/// can be connected at once, `ScaleConnectionCoordinator` (pairing.dart) hands
/// the radio to whichever scale the user is looking at.
library;

import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_banana.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_borre.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_dorre.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_egg.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_fish.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_forre.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_grapes.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_hamburger.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_ice.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_jambul.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_torre.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';

import 'frames.dart';
import 'scale_driver.dart';

/// Credentials issued by the vendor's open platform.
///
/// All three are required before the SDK will initialise, and `configAsset` is
/// an opaque encrypted blob we cannot audit. That is a real supply-chain
/// dependency: see docs/01-factory.md question 3, which asks the factory in
/// writing whether it expires and whether initialisation touches the network.
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
  apple('apple', ScaleKind.body, transport: LefuTransport.gatt),
  coconut('coconut', ScaleKind.body, transport: LefuTransport.gatt),
  torre('torre', ScaleKind.body, transport: LefuTransport.gatt),
  ice('ice', ScaleKind.body, transport: LefuTransport.gatt),
  banana('banana', ScaleKind.body, transport: LefuTransport.broadcast),
  jambul('jambul', ScaleKind.body, transport: LefuTransport.broadcast),
  borre('borre', ScaleKind.body, transport: LefuTransport.gatt),
  dorre('dorre', ScaleKind.body, transport: LefuTransport.gatt),
  forre('forre', ScaleKind.body, transport: LefuTransport.gatt),
  durian('durian', ScaleKind.body, transport: LefuTransport.gatt),
  kiwifruit('kiwifruit', ScaleKind.body, transport: LefuTransport.gatt),
  fish('fish', ScaleKind.kitchen, transport: LefuTransport.gatt),
  egg('egg', ScaleKind.kitchen, transport: LefuTransport.gatt),
  hamburger('hamburger', ScaleKind.kitchen, transport: LefuTransport.broadcast),
  grapes('grapes', ScaleKind.kitchen, transport: LefuTransport.broadcast);

  const LefuDeviceFamily(this.sdkName, this.kind, {required this.transport});

  final String sdkName;
  final ScaleKind kind;
  final LefuTransport transport;

  /// Accepts the enum name (`ice`) or the vendor's older prefixed spelling
  /// (`PeripheralIce`), case-insensitively.
  static LefuDeviceFamily? fromSdkName(String? name) {
    if (name == null) return null;
    var n = name.toLowerCase();
    if (n.startsWith('peripheral')) n = n.substring('peripheral'.length);
    for (final f in LefuDeviceFamily.values) {
      if (f.sdkName == n) return f;
    }
    return null;
  }

  static LefuDeviceFamily? fromPeripheralType(PPDevicePeripheralType? type) =>
      type == null ? null : fromSdkName(type.name);

  PPDevicePeripheralType get peripheralType =>
      PPDevicePeripheralType.values.firstWhere((t) => t.name == sdkName);
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
/// factory before segmental analysis ships — see docs/01-factory.md
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
  /// confirm the SDK's scalar matches before trusting it in an equation. The
  /// plausibility gate in `BodyCompositionEngine` (200–1200 Ω) catches a wrong
  /// scale factor loudly rather than silently.
  final double? impedance;

  final int? heartRate;
  final bool isOverload;

  final SegmentalImpedance? z100Khz;
  final SegmentalImpedance? z20Khz;

  bool get hasSegmental =>
      (z100Khz?.isComplete ?? false) && (z20Khz?.isComplete ?? false);
}

/// Thin abstraction over the vendor plugin.
///
/// Kept as an interface so every screen can be built and tested without a
/// licence or hardware: tests use a fake, the app uses
/// [PpBluetoothKitChannel]. Everything crosses this boundary as plain maps so
/// the mapping is auditable and testable on its own.
abstract class LefuSdkChannel {
  Future<bool> initSdk(LefuCredentials credentials);

  /// Devices of this channel's kind, as they are discovered. Scanning stops
  /// when the last listener cancels.
  Stream<Map<String, dynamic>> startScan();
  Future<void> stopScan();

  /// Completes once the SDK reports the link is up.
  Future<void> connectDevice(String deviceId);
  Future<void> disconnect();

  /// `connected` / `disconnected` / `error`, as the SDK reports them — a scale
  /// switching itself off after a reading arrives here.
  Stream<String> connectionStates();

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
  StreamSubscription<String>? _linkSub;
  bool _initialised = false;
  bool _connected = false;

  /// The SDK reports every frame while someone stands on the scale and then
  /// `completed` once. Sample rate is a few hertz, so the UI animates.
  @override
  String get driverName => 'lefu/pp_bluetooth_kit';

  /// One radio, one connection: the vendor SDK cannot hold the body scale and
  /// the kitchen scale at the same time.
  @override
  bool get exclusive => true;

  @override
  Stream<ScaleConnectionState> get connectionState => _state.stream;

  @override
  Stream<WeightSample> get samples => _samples.stream;

  bool get isConnected => _connected;

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

    try {
      await for (final raw in stream) {
        final scale = discoveredFromMap(raw, kind);
        if (scale == null) continue;
        yield scale;
      }
    } finally {
      if (!_connected) _state.add(ScaleConnectionState.disconnected);
    }
  }

  /// Pure: turns the channel's device map into a [DiscoveredScale], or null
  /// when the device is not of [kind].
  static DiscoveredScale? discoveredFromMap(
    Map<String, dynamic> raw,
    ScaleKind kind,
  ) {
    final family = LefuDeviceFamily.fromSdkName(raw['deviceType'] as String?);
    final declared = raw['kind'] as String?;
    final deviceKind = declared == 'kitchen'
        ? ScaleKind.kitchen
        : declared == 'body'
            ? ScaleKind.body
            : family?.kind;
    if (deviceKind != null && deviceKind != kind) return null;
    final id = (raw['deviceMac'] ?? raw['deviceId'] ?? '').toString();
    if (id.isEmpty) return null;
    return DiscoveredScale(
      id: id,
      name: (raw['deviceName'] ?? 'Scale').toString(),
      kind: deviceKind ?? kind,
      rssi: (raw['rssi'] as num?)?.toInt(),
      protocolHint: family?.sdkName,
      modelCode: raw['modelCode'] as String?,
    );
  }

  @override
  Future<void> stopScan() => _channel.stopScan();

  @override
  Future<void> connect(DiscoveredScale scale) async {
    _state.add(ScaleConnectionState.connecting);
    await _linkSub?.cancel();
    _linkSub = _channel.connectionStates().listen(_onLink);
    try {
      await _channel.connectDevice(scale.id);
    } on Object {
      _connected = false;
      _state.add(ScaleConnectionState.disconnected);
      rethrow;
    }

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
    _connected = true;
    _state.add(ScaleConnectionState.connected);
  }

  void _onLink(String state) {
    if (state == 'connected') {
      if (!_connected) {
        _connected = true;
        _state.add(ScaleConnectionState.connected);
      }
    } else {
      // The scale powered down, went out of range, or the OS dropped the
      // link. Either way the readout should say so; the coordinator decides
      // whether to reconnect.
      if (_connected) {
        _connected = false;
        _state.add(ScaleConnectionState.disconnected);
      }
    }
  }

  void _onMeasurement(Map<String, dynamic> raw) {
    final m = parseMeasurement(raw);
    if (m == null) return;
    if (m.isOverload) return;

    final sample = kind == ScaleKind.body
        ? _aggregator.accept(_frameFor(m), now: m.measuredAt)
        : WeightSample(
            kg: m.weightKg,
            // A kitchen scale streams continuously and reports no settled
            // state through this SDK; the weigh flow's own tare logic decides
            // when the value has stopped moving.
            isStable: true,
            at: m.measuredAt,
          );
    if (sample == null) return;

    _samples.add(
      WeightSample(
        kg: sample.kg,
        isStable: sample.isStable,
        at: sample.at,
        impedanceOhm: sample.impedanceOhm,
        segmental: m.z100Khz,
      ),
    );
  }

  /// A body-scale measurement as the shared aggregator sees it.
  ///
  /// The SDK reports `PPMeasurementDataState.completed` when a reading is
  /// final (vendor source: "in this state, read the impedance and calculate
  /// body data"); [PpBluetoothKitChannel] maps that onto `isCompleted`. A
  /// frame carrying an impedance is treated as settled too, for families that
  /// never send `completed`. Either way the aggregator publishes one stable
  /// sample per time someone stands on the scale and resets when they step
  /// off, so a reading is never recorded three times because three frames
  /// each carried the same impedance.
  ScaleFrame _frameFor(LefuMeasurement m) {
    final settled =
        m.isCompleted || (m.impedance != null && m.impedance! > 0);
    return ScaleFrame(
      weightKg: m.weightKg,
      stability: settled ? WeightStability.stable : WeightStability.live,
      impedanceOhm: m.impedance,
      protocol: driverName,
    );
  }

  /// Maps the vendor's measurement dictionary onto [LefuMeasurement].
  ///
  /// Public and pure so it can be unit-tested against captured payloads without
  /// hardware or a licence.
  static LefuMeasurement? parseMeasurement(Map<String, dynamic> raw) {
    final weight = _num(raw['weight']) ?? _num(raw['lfWeightKg']);
    if (weight == null) return null;

    final ms = _num(raw['measureTime']);
    final at = ms == null || ms <= 0
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

    final impedance = _num(raw['impedance']);
    return LefuMeasurement(
      weightKg: weight,
      measuredAt: at,
      isCompleted: raw['state'] == 'completed' || raw['isCompleted'] == true,
      // Zero is the SDK's "not measured", not a reading.
      impedance: impedance == null || impedance <= 0 ? null : impedance,
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
    await _linkSub?.cancel();
    _linkSub = null;
    try {
      await _channel.disconnect();
    } finally {
      _connected = false;
      _state.add(ScaleConnectionState.disconnected);
    }
  }

  @override
  Future<void> tare() => _channel.toZero();

  @override
  Future<void> dispose() async {
    await _measurementSub?.cancel();
    await _linkSub?.cancel();
    await _state.close();
    await _samples.close();
  }
}

// ---------------------------------------------------------------------------
// The real thing
// ---------------------------------------------------------------------------

/// A device as the gateway hands it out: the vendor model plus the family we
/// resolved for it.
class LefuDevice {
  const LefuDevice(this.model, this.family);

  final PPDeviceModel model;
  final LefuDeviceFamily? family;

  String get id => model.deviceMac ?? '';

  /// The kind the SDK itself declares (CA = kitchen), falling back to the
  /// family table when the device type is unknown.
  ScaleKind? get kind {
    switch (model.deviceType) {
      case PPDeviceType.ca:
        return ScaleKind.kitchen;
      case PPDeviceType.cf:
      case PPDeviceType.ce:
        return ScaleKind.body;
      case PPDeviceType.cb:
      case PPDeviceType.unknown:
      case null:
        return family?.kind;
    }
  }
}

/// Process-wide owner of the vendor SDK's single-registration callbacks.
///
/// The plugin exposes one scan callback, one connection, one body-measurement
/// listener and one kitchen listener; registering any of them twice replaces
/// the first. This class registers each exactly once and fans out over
/// broadcast streams, so the body and kitchen channels can both exist without
/// stepping on each other.
class LefuSdkGateway {
  LefuSdkGateway._();

  static final LefuSdkGateway instance = LefuSdkGateway._();

  bool _initialised = false;
  String? _configLoadedFrom;

  final _devices = StreamController<LefuDevice>.broadcast();
  final _link = StreamController<String>.broadcast();
  final _body = StreamController<Map<String, dynamic>>.broadcast();
  final _kitchen = StreamController<Map<String, dynamic>>.broadcast();
  bool _bodyListenerRegistered = false;
  bool _kitchenListenerRegistered = false;
  int _scanListeners = 0;
  bool _scanning = false;

  /// Devices seen this session, so a connect-by-id has the vendor model the
  /// SDK insists on.
  final Map<String, LefuDevice> seen = {};

  LefuDevice? connected;

  Future<bool> initialise(LefuCredentials credentials) async {
    if (_initialised && _configLoadedFrom == credentials.configAsset) {
      return true;
    }
    if (credentials.appKey.isEmpty || credentials.appSecret.isEmpty) {
      return false;
    }
    final String config;
    try {
      config = await rootBundle.loadString(credentials.configAsset);
    } on Object {
      // No licence file in the bundle: the build was made without one.
      return false;
    }
    if (config.trim().isEmpty) return false;
    try {
      PPBluetoothKitManager.initSDK(
        credentials.appKey,
        credentials.appSecret,
        config,
      );
    } on Object {
      return false;
    }
    _initialised = true;
    _configLoadedFrom = credentials.configAsset;
    return true;
  }

  /// Discovered devices of every kind. Scanning runs while anyone listens.
  Stream<LefuDevice> scan() {
    late StreamController<LefuDevice> out;
    StreamSubscription<LefuDevice>? sub;
    out = StreamController<LefuDevice>(
      onListen: () async {
        sub = _devices.stream.listen(out.add);
        _scanListeners += 1;
        if (!_scanning) {
          _scanning = true;
          await PPBluetoothKitManager.startScan(_onDevice);
        }
      },
      onCancel: () async {
        await sub?.cancel();
        _scanListeners -= 1;
        if (_scanListeners <= 0) {
          _scanListeners = 0;
          await stopScan();
        }
      },
    );
    return out.stream;
  }

  void _onDevice(PPDeviceModel model) {
    final family = LefuDeviceFamily.fromPeripheralType(
      model.getDevicePeripheralType(),
    );
    final device = LefuDevice(model, family);
    if (device.id.isEmpty) return;
    seen[device.id] = device;
    _devices.add(device);
  }

  Future<void> stopScan() async {
    if (!_scanning) return;
    _scanning = false;
    try {
      await PPBluetoothKitManager.stopScan();
    } on Object {
      // Stopping a scan that already stopped is not an error worth surfacing.
    }
  }

  Stream<String> get connectionStates => _link.stream;

  /// Connects, or for broadcast-only families starts receiving their
  /// advertisements. Completes when the SDK reports the link up.
  Future<void> connect(LefuDevice device) async {
    if (device.family?.transport == LefuTransport.broadcast) {
      final ok = await _receiveBroadcast(device, on: true);
      if (!ok) throw StateError('scale did not start broadcasting');
      connected = device;
      _link.add('connected');
      return;
    }

    final done = Completer<void>();
    PPBluetoothKitManager.connectDevice(
      device.model,
      callBack: (state) {
        switch (state) {
          case PPDeviceConnectionState.connected:
            connected = device;
            if (!done.isCompleted) done.complete();
            _link.add('connected');
          case PPDeviceConnectionState.disconnected:
            if (connected?.id == device.id) connected = null;
            if (!done.isCompleted) {
              done.completeError(StateError('scale disconnected'));
            }
            _link.add('disconnected');
          case PPDeviceConnectionState.error:
          case PPDeviceConnectionState.undefine:
            if (!done.isCompleted) {
              done.completeError(StateError('scale connection failed'));
            }
            _link.add('error');
        }
      },
    );
    await done.future.timeout(const Duration(seconds: 20));
  }

  Future<bool> _receiveBroadcast(LefuDevice device, {required bool on}) async {
    switch (device.family) {
      case LefuDeviceFamily.banana:
        return on
            ? PPPeripheralBanana.receiveDeviceData(device.model)
            : PPPeripheralBanana.unReceiveDeviceData(device.model);
      case LefuDeviceFamily.jambul:
        return on
            ? PPPeripheralJambul.receiveDeviceData(device.model)
            : PPPeripheralJambul.unReceiveDeviceData(device.model);
      case LefuDeviceFamily.hamburger:
        return on
            ? PPPeripheralHamburger.receiveDeviceData(device.model)
            : PPPeripheralHamburger.unReceiveDeviceData(device.model);
      case LefuDeviceFamily.grapes:
        return on
            ? PPPeripheralGrapes.receiveDeviceData(device.model)
            : PPPeripheralGrapes.unReceiveDeviceData(device.model);
      default:
        return false;
    }
  }

  Future<void> disconnect() async {
    final current = connected;
    connected = null;
    if (current?.family?.transport == LefuTransport.broadcast) {
      await _receiveBroadcast(current!, on: false);
    } else {
      PPBluetoothKitManager.disconnect();
    }
    _link.add('disconnected');
  }

  Stream<Map<String, dynamic>> bodyMeasurements() {
    if (!_bodyListenerRegistered) {
      _bodyListenerRegistered = true;
      PPBluetoothKitManager.addMeasurementListener(
        callBack: (state, model, device) => _body.add(
          measurementToMap(state, model, device, ScaleKind.body),
        ),
      );
    }
    return _body.stream;
  }

  Stream<Map<String, dynamic>> kitchenMeasurements() {
    if (!_kitchenListenerRegistered) {
      _kitchenListenerRegistered = true;
      PPBluetoothKitManager.addKitchenMeasurementListener(
        callBack: (state, model, device) => _kitchen.add(
          measurementToMap(state, model, device, ScaleKind.kitchen),
        ),
      );
    }
    return _kitchen.stream;
  }

  Future<bool> tare() async {
    switch (connected?.family) {
      case LefuDeviceFamily.fish:
        return PPPeripheralFish.toZero();
      case LefuDeviceFamily.egg:
        return PPPeripheralEgg.toZero();
      default:
        return false;
    }
  }

  Future<bool> impedanceSwitch({required bool on}) async {
    switch (connected?.family) {
      case LefuDeviceFamily.ice:
        return PPPeripheralIce.impedanceSwitchControl(on);
      case LefuDeviceFamily.torre:
        return PPPeripheralTorre.impedanceSwitchControl(on);
      case LefuDeviceFamily.borre:
        return PPPeripheralBorre.impedanceSwitchControl(on);
      case LefuDeviceFamily.dorre:
        return PPPeripheralDorre.impedanceSwitchControl(on);
      case LefuDeviceFamily.forre:
        return PPPeripheralForre.impedanceSwitchControl(on);
      default:
        // Other families measure impedance unconditionally.
        return true;
    }
  }

  /// Pure: the vendor's measurement callback as a plain map, weight in kg.
  ///
  /// `PPBodyBaseModel.weight` is an int whose unit depends on the device:
  /// kg × 100 for a body scale (the model's own `getPpWeightKg`), tenths of a
  /// gram for a kitchen scale (the vendor's own kitchen demo divides by 10).
  /// The raw integer and the device's accuracy class travel with the map so a
  /// unit on the desk can be checked against them (docs/10-sdk.md).
  static Map<String, dynamic> measurementToMap(
    PPMeasurementDataState state,
    PPBodyBaseModel model,
    PPDeviceModel device,
    ScaleKind kind,
  ) {
    final sign = model.isPlus ? 1 : -1;
    final kg = kind == ScaleKind.kitchen
        ? sign * model.weight / 10.0 / 1000.0
        : sign * model.getPpWeightKg();
    return {
      'kind': kind.name,
      'weight': kg,
      'rawWeight': model.weight,
      'accuracy': device.deviceAccuracyType?.name,
      'unit': model.unit?.name,
      'measureTime': model.measureTime,
      'state': state.name,
      'isCompleted': state == PPMeasurementDataState.completed,
      'impedance': model.impedance,
      'impedance100EnCode': model.impedance100EnCode,
      'heartRate': model.heartRate,
      'isHeartRating': model.isHeartRating,
      'isOverload': model.isOverload,
      'z100KhzLeftArmEnCode': model.z100KhzLeftArmEnCode,
      'z100KhzRightArmEnCode': model.z100KhzRightArmEnCode,
      'z100KhzLeftLegEnCode': model.z100KhzLeftLegEnCode,
      'z100KhzRightLegEnCode': model.z100KhzRightLegEnCode,
      'z100KhzTrunkEnCode': model.z100KhzTrunkEnCode,
      'z20KhzLeftArmEnCode': model.z20KhzLeftArmEnCode,
      'z20KhzRightArmEnCode': model.z20KhzRightArmEnCode,
      'z20KhzLeftLegEnCode': model.z20KhzLeftLegEnCode,
      'z20KhzRightLegEnCode': model.z20KhzRightLegEnCode,
      'z20KhzTrunkEnCode': model.z20KhzTrunkEnCode,
      'deviceMac': device.deviceMac,
    };
  }

  /// Pure: a discovered device as a plain map for the channel boundary.
  static Map<String, dynamic> deviceToMap(LefuDevice device) => {
        'deviceMac': device.model.deviceMac,
        'deviceName': device.model.customDeviceName?.isNotEmpty == true
            ? device.model.customDeviceName
            : device.model.deviceName,
        'rssi': device.model.rssi,
        'deviceType': device.family?.sdkName,
        'kind': device.kind?.name,
        'modelCode': device.model.productModel,
        'firmware': device.model.firmwareVersion,
        'calculateType': device.model.deviceCalculateType?.name,
        'accuracy': device.model.deviceAccuracyType?.name,
        'protocol': device.model.deviceProtocolType?.name,
        'power': device.model.devicePower,
      };
}

/// Real implementation against the vendor plugin, one per scale kind.
///
/// Key facts from the vendor source that this class respects:
///   * `PPBodyBaseModel.weight` is an int: kg × 100 for body scales, tenths of
///     a gram for kitchen scales. Converted in [LefuSdkGateway.measurementToMap].
///   * `PPMeasurementDataState.completed` is the stability signal, mapped to
///     `isCompleted`.
///   * ONE measurement listener per kind; the gateway registers it once.
///   * Kitchen tare is per family: `PPPeripheralFish.toZero()` /
///     `PPPeripheralEgg.toZero()`.
///   * One connection at a time on the native side.
class PpBluetoothKitChannel implements LefuSdkChannel {
  PpBluetoothKitChannel(this.kind, {LefuSdkGateway? gateway})
      : _gateway = gateway ?? LefuSdkGateway.instance;

  final ScaleKind kind;
  final LefuSdkGateway _gateway;

  @override
  Future<bool> initSdk(LefuCredentials credentials) =>
      _gateway.initialise(credentials);

  @override
  Stream<Map<String, dynamic>> startScan() => _gateway
      .scan()
      .where((d) => d.kind == null || d.kind == kind)
      .map(LefuSdkGateway.deviceToMap);

  @override
  Future<void> stopScan() => _gateway.stopScan();

  @override
  Future<void> connectDevice(String deviceId) async {
    final device = _gateway.seen[deviceId];
    if (device == null) {
      throw StateError('scale $deviceId has not been seen in this scan');
    }
    if (_gateway.connected != null && _gateway.connected!.id != deviceId) {
      await _gateway.disconnect();
    }
    await _gateway.connect(device);
  }

  @override
  Future<void> disconnect() => _gateway.disconnect();

  @override
  Stream<String> connectionStates() => _gateway.connectionStates;

  @override
  Stream<Map<String, dynamic>> measurements() => kind == ScaleKind.kitchen
      ? _gateway.kitchenMeasurements()
      : _gateway.bodyMeasurements();

  @override
  Future<void> toZero() => _gateway.tare();

  @override
  Future<void> impedanceSwitchControl({required bool on}) =>
      _gateway.impedanceSwitch(on: on);

  @override
  Future<Map<String, dynamic>> fetchDeviceInfo() async {
    final current = _gateway.connected;
    return current == null ? const {} : LefuSdkGateway.deviceToMap(current);
  }
}
