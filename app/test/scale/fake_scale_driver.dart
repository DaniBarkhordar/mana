import 'dart:async';

import 'package:mananu/core/scale/scale_driver.dart';

/// A scripted [ScaleDriver] above the vendor boundary: advertises whatever
/// it is given, connects instantly, remembers a backlog of stored readings,
/// and records every call so a test can assert on order. Not the simulated
/// driver — that one is the demo scale and skips the permission step.
class FakeScaleDriver implements ScaleDriver {
  FakeScaleDriver({
    this.kind = ScaleKind.body,
    this.devices = const [],
    List<StoredReading> stored = const [],
    this.exclusive = false,
  }) : stored = List.of(stored);

  final ScaleKind kind;
  final List<DiscoveredScale> devices;

  /// What the scale "remembers". Handed back on every fetch until cleared.
  List<StoredReading> stored;

  @override
  final bool exclusive;

  /// Every call, in order: `scan 60`, `connect X`, `fetchStored`, `clear`.
  final calls = <String>[];

  /// Runs inside [clearStoredReadings], so a test can check what the
  /// database held at the moment the scale was told to forget.
  Future<void> Function()? onClear;

  final _state = StreamController<ScaleConnectionState>.broadcast();
  final _samples = StreamController<WeightSample>.broadcast();

  @override
  String get driverName => 'fake';

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
    calls.add('scan ${timeout.inSeconds}');
    _state.add(ScaleConnectionState.scanning);
    for (final d in devices) {
      yield d;
    }
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<void> connect(DiscoveredScale scale) async {
    calls.add('connect ${scale.id}');
    _state.add(ScaleConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    calls.add('disconnect');
    _state.add(ScaleConnectionState.disconnected);
  }

  @override
  Future<void> tare() async => calls.add('tare');

  @override
  Future<List<StoredReading>> fetchStoredReadings() async {
    calls.add('fetchStored');
    return List.of(stored);
  }

  @override
  Future<void> clearStoredReadings() async {
    calls.add('clear');
    await onClear?.call();
    stored = const [];
  }

  @override
  Future<void> dispose() async {
    await _state.close();
    await _samples.close();
  }
}
