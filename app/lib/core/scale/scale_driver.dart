/// The boundary between the app and whatever hardware is on the floor.
///
/// Nothing above this layer knows that the scale is made by Shenzhen Unique
/// Scales, that the SDK class prefix is `PP`, or that a licence blob exists.
/// That matters commercially as well as technically: the vendor SDK needs an
/// appKey, an appSecret and an encrypted `lefu.config` to initialise, so if that
/// licence ever lapses, changes terms, or the hardware is second-sourced, the
/// replacement slots in here and the rest of the app does not move.
library;

import 'dart:async';
import 'dart:math' as math;

import 'frames.dart';

/// What kind of device this is. The same SDK and the same app handle both.
enum ScaleKind {
  /// Bathroom scale with bioimpedance.
  body,

  /// Kitchen scale. Streams grams and nothing else.
  kitchen,
}

/// A scale the app has seen advertising.
class DiscoveredScale {
  const DiscoveredScale({
    required this.id,
    required this.name,
    required this.kind,
    this.rssi,
    this.protocolHint,
    this.modelCode,
  });

  /// Stable identifier. MAC on Android; on iOS a per-app CoreBluetooth UUID that
  /// is stable for this install only, which is why the pairing record is keyed
  /// on this plus the model rather than on a MAC.
  final String id;
  final String name;
  final ScaleKind kind;
  final int? rssi;

  /// Which frame parser is expected to handle it, when the advertisement gave
  /// that away.
  final String? protocolHint;

  /// Factory model code where known. Lefu's own taxonomy: CF### body scales,
  /// CK### kitchen scales, CW### weight-only.
  final String? modelCode;
}

/// Connection state, mapped to something the UI can render without knowing about
/// GATT.
enum ScaleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,

  /// Connected but refusing to measure — most often because the SDK licence
  /// failed to initialise.
  unauthorised,
}

/// A live weight sample. Emitted continuously while someone is on the scale, so
/// the UI can animate, and marked stable exactly once per measurement.
class WeightSample {
  const WeightSample({
    required this.kg,
    required this.isStable,
    required this.at,
    this.impedanceOhm,
    this.reactanceOhm,
    this.segmental,
  });

  final double kg;
  final bool isStable;
  final DateTime at;
  final double? impedanceOhm;
  final double? reactanceOhm;

  /// Per-segment impedance from 8-electrode hardware, when present.
  final SegmentalImpedance? segmental;

  double get grams => kg * 1000.0;
}

/// Five-segment impedance at two frequencies.
///
/// The vendor SDK exposes exactly this shape — left arm, right arm, left leg,
/// right leg and trunk at both 20 kHz and 100 kHz. It is the raw material for
/// segmental analysis, and it is the reason to insist on raw values rather than
/// accept the vendor's pre-computed body-fat number.
class SegmentalImpedance {
  const SegmentalImpedance({
    required this.frequencyKhz,
    this.leftArm,
    this.rightArm,
    this.leftLeg,
    this.rightLeg,
    this.trunk,
  });

  final int frequencyKhz;
  final double? leftArm;
  final double? rightArm;
  final double? leftLeg;
  final double? rightLeg;
  final double? trunk;

  bool get isComplete =>
      leftArm != null &&
      rightArm != null &&
      leftLeg != null &&
      rightLeg != null &&
      trunk != null;
}

/// Everything a scale implementation must provide.
abstract class ScaleDriver {
  /// Human-readable name for logs and the support inbox.
  String get driverName;

  Stream<ScaleConnectionState> get connectionState;

  /// Live samples. Multiple listeners are expected (a UI and a logger), so
  /// implementations must broadcast.
  Stream<WeightSample> get samples;

  /// True once any credential or permission setup has completed.
  Future<bool> initialise();

  Stream<DiscoveredScale> scan({
    Duration timeout = const Duration(seconds: 30),
  });

  Future<void> stopScan();

  Future<void> connect(DiscoveredScale scale);

  Future<void> disconnect();

  /// Zero the kitchen scale. No-op on a body scale.
  Future<void> tare();

  Future<void> dispose();
}

/// Turns a stream of raw frames into a stream of samples, and decides when a
/// measurement is finished.
///
/// Shared by every driver so that "what counts as a settled reading" is defined
/// once. Some protocols announce stability in a status byte; some do not, so
/// this also detects settling by watching the value stop moving.
class MeasurementAggregator {
  MeasurementAggregator({
    this.stabilityWindow = const Duration(milliseconds: 1200),
    this.stabilityToleranceKg = 0.05,
  });

  /// How long the value must hold still to count as settled, for protocols with
  /// no stability flag.
  final Duration stabilityWindow;

  /// How far it may wander within that window.
  final double stabilityToleranceKg;

  /// The current run of samples that all sit within [stabilityToleranceKg] of
  /// each other. Tracked as a start time plus running min/max rather than a
  /// list, so the span the value has held still for is known exactly: a
  /// time-boxed list would have to evict the very sample that proves the
  /// window has elapsed.
  DateTime? _runStart;
  int _runCount = 0;
  double _runMin = double.infinity;
  double _runMax = double.negativeInfinity;
  bool _emittedStable = false;

  /// Fewer samples than this cannot show that a value is holding still, however
  /// far apart in time they are.
  static const int _minSamplesForSettle = 4;

  /// Feed a decoded frame; returns the sample to publish, or null to ignore.
  WeightSample? accept(ScaleFrame frame, {DateTime? now}) {
    final at = now ?? DateTime.now();

    if (frame.stability == WeightStability.removed) {
      reset();
      return null;
    }

    // Below this the platform is empty or someone is stepping on.
    if (frame.weightKg < 2.0) {
      reset();
      return null;
    }

    _extendRun(frame.weightKg, at);

    final protocolSaysStable = frame.isStable;
    final settled = protocolSaysStable || _hasSettled(at);

    if (settled && _emittedStable) return null;
    if (settled) _emittedStable = true;

    return WeightSample(
      kg: frame.weightKg,
      isStable: settled,
      at: at,
      impedanceOhm: frame.impedanceOhm,
    );
  }

  /// Extends the current still-run with [kg], or starts a new one at [at] when
  /// the value has moved by more than the tolerance.
  void _extendRun(double kg, DateTime at) {
    final min = math.min(_runMin, kg);
    final max = math.max(_runMax, kg);
    if (_runStart == null || (max - min) > stabilityToleranceKg) {
      _runStart = at;
      _runCount = 1;
      _runMin = kg;
      _runMax = kg;
      return;
    }
    _runMin = min;
    _runMax = max;
    _runCount++;
  }

  bool _hasSettled(DateTime now) {
    final start = _runStart;
    if (start == null || _runCount < _minSamplesForSettle) return false;
    return now.difference(start) >= stabilityWindow;
  }

  void reset() {
    _runStart = null;
    _runCount = 0;
    _runMin = double.infinity;
    _runMax = double.negativeInfinity;
    _emittedStable = false;
  }
}

/// An in-memory driver used by tests, by the simulator build, and by the demo
/// mode a salesperson can run without hardware.
///
/// It also means the whole app — screens, storage, sync, charts — can be built
/// and reviewed before a single physical unit arrives from Shenzhen.
class SimulatedScaleDriver implements ScaleDriver {
  SimulatedScaleDriver({this.kind = ScaleKind.body});

  final ScaleKind kind;

  final _state = StreamController<ScaleConnectionState>.broadcast();
  final _samples = StreamController<WeightSample>.broadcast();
  Timer? _timer;

  @override
  String get driverName => 'simulated';

  @override
  Stream<ScaleConnectionState> get connectionState => _state.stream;

  @override
  Stream<WeightSample> get samples => _samples.stream;

  @override
  Future<bool> initialise() async => true;

  @override
  Stream<DiscoveredScale> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    _state.add(ScaleConnectionState.scanning);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    yield DiscoveredScale(
      id: 'sim-0001',
      name:
          kind == ScaleKind.body ? 'Body scale (demo)' : 'Kitchen scale (demo)',
      kind: kind,
      rssi: -52,
      protocolHint: 'simulated',
      modelCode: kind == ScaleKind.body ? 'CF577' : 'CK869',
    );
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(DiscoveredScale scale) async {
    _state.add(ScaleConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _state.add(ScaleConnectionState.connected);
    _startStreaming();
  }

  void _startStreaming() {
    final target = kind == ScaleKind.body ? 78.4 : 0.0;
    var t = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      t++;
      if (kind == ScaleKind.body) {
        // Converge on the target, then lock.
        final settling = t < 8;
        final wobble = settling ? (8 - t) * 0.4 : 0.0;
        _samples.add(
          WeightSample(
            kg: target + wobble,
            isStable: !settling,
            at: DateTime.now(),
            impedanceOhm: settling ? null : 512.0,
          ),
        );
        if (!settling) timer.cancel();
      } else {
        _samples.add(
          WeightSample(
            kg: 0,
            isStable: true,
            at: DateTime.now(),
          ),
        );
      }
    });
  }

  /// Test and demo hook: push an arbitrary reading.
  void emit(double kg, {bool stable = true, double? impedanceOhm}) {
    _samples.add(
      WeightSample(
        kg: kg,
        isStable: stable,
        at: DateTime.now(),
        impedanceOhm: impedanceOhm,
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _state.add(ScaleConnectionState.disconnected);
  }

  @override
  Future<void> tare() async {
    _samples.add(WeightSample(kg: 0, isStable: true, at: DateTime.now()));
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _state.close();
    await _samples.close();
  }
}
