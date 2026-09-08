import 'dart:async';

import 'package:mananu/core/scale/lefu_driver.dart';
import 'package:mananu/core/scale/scale_driver.dart';

/// Stands in for the vendor plugin: scripted devices, scripted frames, a
/// scripted memory of stored readings, and a record of every call, so the
/// driver can be exercised without a licence.
class FakeChannel implements LefuSdkChannel {
  FakeChannel({
    this.initOk = true,
    this.devices = const [],
    this.storedReadings = const [],
  });

  final bool initOk;
  final List<Map<String, dynamic>> devices;

  /// What the scale "remembers". Handed back on every fetch until cleared.
  List<Map<String, dynamic>> storedReadings;

  final calls = <String>[];
  final frames = StreamController<Map<String, dynamic>>.broadcast();
  final link = StreamController<String>.broadcast();

  @override
  Future<bool> initSdk(LefuCredentials credentials) async {
    calls.add('init ${credentials.redacted}');
    return initOk;
  }

  @override
  Stream<Map<String, dynamic>> startScan() async* {
    calls.add('scan');
    for (final d in devices) {
      yield d;
    }
  }

  @override
  Future<void> stopScan() async => calls.add('stopScan');

  @override
  Future<void> connectDevice(String deviceId) async =>
      calls.add('connect $deviceId');

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  Stream<String> connectionStates() => link.stream;

  @override
  Stream<Map<String, dynamic>> measurements() => frames.stream;

  @override
  Future<void> toZero() async => calls.add('toZero');

  @override
  Future<void> impedanceSwitchControl({required bool on}) async =>
      calls.add('impedance $on');

  @override
  Future<Map<String, dynamic>> fetchDeviceInfo() async => const {};

  @override
  Future<List<Map<String, dynamic>>> fetchStoredReadings(
    ScaleKind kind,
  ) async {
    calls.add('fetchHistory ${kind.name}');
    return List.of(storedReadings);
  }

  @override
  Future<void> clearStoredReadings(ScaleKind kind) async {
    calls.add('clearHistory ${kind.name}');
    storedReadings = const [];
  }
}
