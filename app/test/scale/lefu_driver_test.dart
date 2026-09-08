import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/scale/lefu_driver.dart';
import 'package:mananu/core/scale/pairing.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';

import 'fake_channel.dart';

const _creds = LefuCredentials(
  appKey: 'lefu-test-key',
  appSecret: 'secret',
  configAsset: 'assets/lefu.config',
);

PPDeviceModel _device({
  String mac = 'AA:BB',
  PPDeviceType type = PPDeviceType.cf,
  PPDeviceAccuracyType accuracy = PPDeviceAccuracyType.point01,
}) {
  final d = PPDeviceModel('Mananu Body', mac);
  d.deviceType = type;
  d.deviceAccuracyType = accuracy;
  d.productModel = 'CF577';
  d.peripheralType = PPDevicePeripheralType.ice.value;
  return d;
}

void main() {
  group('measurementToMap', () {
    test('body weight is kg × 100 and completed is the stability flag', () {
      final m = PPBodyBaseModel()
        ..weight = 7870
        ..impedance = 512
        ..measureTime = 1757142720000
        ..z100KhzLeftArmEnCode = 1234;
      final map = LefuSdkGateway.measurementToMap(
        PPMeasurementDataState.completed,
        m,
        _device(),
        ScaleKind.body,
      );
      expect(map['weight'], closeTo(78.7, 1e-9));
      expect(map['rawWeight'], 7870);
      expect(map['isCompleted'], isTrue);
      expect(map['impedance'], 512);

      final parsed = LefuScaleDriver.parseMeasurement(map)!;
      expect(parsed.weightKg, closeTo(78.7, 1e-9));
      expect(parsed.isCompleted, isTrue);
      expect(parsed.impedance, 512);
      expect(parsed.z100Khz!.leftArm, 1234);
      expect(parsed.measuredAt.millisecondsSinceEpoch, 1757142720000);
    });

    test('kitchen weight is tenths of a gram, signed', () {
      final m = PPBodyBaseModel()..weight = 2350;
      final map = LefuSdkGateway.measurementToMap(
        PPMeasurementDataState.processData,
        m,
        _device(type: PPDeviceType.ca, accuracy: PPDeviceAccuracyType.pointG),
        ScaleKind.kitchen,
      );
      expect(map['weight'], closeTo(0.235, 1e-9));
      expect(map['isCompleted'], isFalse);
      expect(map['accuracy'], 'pointG');

      m.isPlus = false;
      final neg = LefuSdkGateway.measurementToMap(
        PPMeasurementDataState.processData,
        m,
        _device(type: PPDeviceType.ca),
        ScaleKind.kitchen,
      );
      expect(neg['weight'], closeTo(-0.235, 1e-9));
    });

    test('an impedance of zero is "not measured", not a reading', () {
      final map = LefuSdkGateway.measurementToMap(
        PPMeasurementDataState.processData,
        PPBodyBaseModel()..weight = 8000,
        _device(),
        ScaleKind.body,
      );
      expect(LefuScaleDriver.parseMeasurement(map)!.impedance, isNull);
    });

    test('a stored reading is complete and keeps the scale\'s own stamp', () {
      final m = PPBodyBaseModel()
        ..weight = 7910
        ..impedance = 520
        ..measureTime = 1757056320000;
      final map = LefuSdkGateway.historyToMap(m, _device(), ScaleKind.body);
      expect(map['isCompleted'], isTrue);
      expect(map['measuredAt'], 1757056320000);
      expect(map['weight'], closeTo(79.1, 1e-9));
      final parsed = LefuScaleDriver.parseMeasurement(map)!;
      expect(parsed.measuredAt.millisecondsSinceEpoch, 1757056320000);
      expect(LefuScaleDriver.hasTimestamp(map), isTrue);

      // A scale that never had its clock set stamps zero: no date, not now.
      final undated = LefuSdkGateway.historyToMap(
        PPBodyBaseModel()..weight = 7910,
        _device(),
        ScaleKind.body,
      );
      expect(undated['measuredAt'], isNull);
      expect(LefuScaleDriver.hasTimestamp(undated), isFalse);
    });
  });

  group('deviceToMap and discovery', () {
    test('the SDK device type decides the kind; the family gives the hint', () {
      final kitchen = LefuDevice(
        _device(mac: '11:22', type: PPDeviceType.ca)
          ..peripheralType = PPDevicePeripheralType.fish.value,
        LefuDeviceFamily.fish,
      );
      final map = LefuSdkGateway.deviceToMap(kitchen);
      expect(map['kind'], 'kitchen');
      expect(map['deviceType'], 'fish');
      expect(map['modelCode'], 'CF577');

      expect(LefuScaleDriver.discoveredFromMap(map, ScaleKind.body), isNull);
      final found = LefuScaleDriver.discoveredFromMap(map, ScaleKind.kitchen)!;
      expect(found.id, '11:22');
      expect(found.protocolHint, 'fish');
    });

    test('family names resolve from either spelling', () {
      expect(
        LefuDeviceFamily.fromSdkName('PeripheralIce'),
        LefuDeviceFamily.ice,
      );
      expect(LefuDeviceFamily.fromSdkName('torre'), LefuDeviceFamily.torre);
      expect(LefuDeviceFamily.fromSdkName('nope'), isNull);
      expect(
        LefuDeviceFamily.fromPeripheralType(PPDevicePeripheralType.egg)!.kind,
        ScaleKind.kitchen,
      );
      expect(LefuDeviceFamily.ice.peripheralType, PPDevicePeripheralType.ice);
    });
  });

  group('LefuScaleDriver', () {
    test('scan filters to its kind and connect turns impedance on', () async {
      final channel = FakeChannel(
        devices: [
          {'deviceMac': 'AA', 'deviceName': 'Body', 'kind': 'body'},
          {'deviceMac': 'BB', 'deviceName': 'Kitchen', 'kind': 'kitchen'},
          {
            'deviceMac': 'CC',
            'deviceName': 'Old',
            'deviceType': 'PeripheralApple',
          },
        ],
      );
      final driver = LefuScaleDriver(channel: channel, credentials: _creds);
      final states = <ScaleConnectionState>[];
      driver.connectionState.listen(states.add);

      final found = await driver.scan().toList();
      expect(found.map((s) => s.id), ['AA', 'CC']);

      await driver.connect(found.first);
      expect(channel.calls, contains('connect AA'));
      expect(channel.calls, contains('impedance true'));
      expect(driver.isConnected, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(states, contains(ScaleConnectionState.connected));
      await driver.dispose();
    });

    test('a completed frame is one stable sample; frames before it are not',
        () async {
      final channel = FakeChannel();
      final driver = LefuScaleDriver(channel: channel, credentials: _creds);
      final samples = <WeightSample>[];
      driver.samples.listen(samples.add);
      await driver.connect(
        const DiscoveredScale(id: 'AA', name: 'Body', kind: ScaleKind.body),
      );

      channel.frames.add({'weight': 78.4, 'state': 'processData'});
      channel.frames.add({'weight': 78.6, 'state': 'processData'});
      channel.frames.add({
        'weight': 78.7,
        'state': 'completed',
        'impedance': 505,
      });
      channel.frames.add({'weight': 78.7, 'isOverload': true});
      await Future<void>.delayed(Duration.zero);

      expect(samples, hasLength(3));
      expect(samples.map((s) => s.isStable), [false, false, true]);
      expect(samples.last.impedanceOhm, 505);
      await driver.dispose();
    });

    test('the SDK dropping the link is reported', () async {
      final channel = FakeChannel();
      final driver = LefuScaleDriver(channel: channel, credentials: _creds);
      final states = <ScaleConnectionState>[];
      driver.connectionState.listen(states.add);
      await driver.connect(
        const DiscoveredScale(id: 'AA', name: 'Body', kind: ScaleKind.body),
      );
      channel.link.add('disconnected');
      await Future<void>.delayed(Duration.zero);
      expect(states.last, ScaleConnectionState.disconnected);
      expect(driver.isConnected, isFalse);
      await driver.dispose();
    });

    test('a failed licence reports unauthorised and never scans', () async {
      final channel = FakeChannel(initOk: false);
      final driver = LefuScaleDriver(channel: channel, credentials: _creds);
      final states = <ScaleConnectionState>[];
      driver.connectionState.listen(states.add);
      expect(await driver.scan().toList(), isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(states, [ScaleConnectionState.unauthorised]);
      expect(channel.calls, isNot(contains('scan')));
      await driver.dispose();
    });

    test('stored readings honour their timestamps and clear waits for us',
        () async {
      final channel = FakeChannel(
        storedReadings: [
          // Out of order on purpose: the driver sorts oldest first.
          {'weight': 78.9, 'impedance': 510, 'measuredAt': 1757056320000},
          {'weight': 79.3, 'impedance': 518, 'measuredAt': 1756883520000},
          // Seconds rather than milliseconds, as Android can send.
          {'weight': 79.1, 'impedance': 0, 'measureTime': 1756969920},
          // Undated: dropped, never stamped with now.
          {'weight': 80.0, 'impedance': 512, 'measureTime': 0},
          // Overloaded: not a reading.
          {'weight': 79.0, 'isOverload': true, 'measuredAt': 1757000000000},
        ],
      );
      final driver = LefuScaleDriver(channel: channel, credentials: _creds);
      await driver.connect(
        const DiscoveredScale(id: 'AA', name: 'Body', kind: ScaleKind.body),
      );

      final stored = await driver.fetchStoredReadings();
      expect(stored, hasLength(3));
      expect(
        stored.map((r) => r.at.millisecondsSinceEpoch),
        [1756883520000, 1756969920000, 1757056320000],
      );
      expect(stored.map((r) => r.kg), [79.3, 79.1, 78.9]);
      // Zero impedance is "not measured" for a stored reading too.
      expect(stored.map((r) => r.impedanceOhm), [518, null, 510]);

      // Fetching never clears: that is the sync's decision, after storing.
      expect(channel.calls, contains('fetchHistory body'));
      expect(channel.calls, isNot(contains('clearHistory body')));
      await driver.clearStoredReadings();
      expect(
        channel.calls.indexOf('clearHistory body'),
        greaterThan(channel.calls.indexOf('fetchHistory body')),
      );
      expect(await driver.fetchStoredReadings(), isEmpty);
      await driver.dispose();
    });

    test('a kitchen scale has no memory to fetch', () async {
      final channel = FakeChannel(
        storedReadings: [
          {'weight': 0.235, 'measuredAt': 1757056320000},
        ],
      );
      final driver = LefuScaleDriver(
        channel: channel,
        credentials: _creds,
        kind: ScaleKind.kitchen,
      );
      expect(await driver.fetchStoredReadings(), isEmpty);
      expect(channel.calls, isNot(contains('fetchHistory kitchen')));
      await driver.dispose();
    });

    test('tare reaches the scale', () async {
      final channel = FakeChannel();
      final driver = LefuScaleDriver(
        channel: channel,
        credentials: _creds,
        kind: ScaleKind.kitchen,
      );
      await driver.tare();
      expect(channel.calls, ['toZero']);
      await driver.dispose();
    });
  });

  group('pairing', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.memory());
    tearDown(() => db.close());

    test('a pairing round-trips and can be forgotten', () async {
      final store = ScalePairingStore(db);
      expect(await store.read(ScaleKind.body), isNull);
      await store.save(
        PairedScale.fromDiscovered(
          const DiscoveredScale(
            id: 'AA:BB',
            name: 'Mananu Body',
            kind: ScaleKind.body,
            modelCode: 'CF577',
            protocolHint: 'ice',
          ),
        ),
      );
      final back = (await store.read(ScaleKind.body))!;
      expect(back.id, 'AA:BB');
      expect(back.modelCode, 'CF577');
      expect(back.toDiscovered().protocolHint, 'ice');
      expect(await store.read(ScaleKind.kitchen), isNull);
      await store.forget(ScaleKind.body);
      expect(await store.read(ScaleKind.body), isNull);
    });

    test('the coordinator gives the radio to the focused scale', () async {
      final store = ScalePairingStore(db);
      final bodyChannel = FakeChannel(
        devices: [
          {'deviceMac': 'B1', 'deviceName': 'Body', 'kind': 'body'},
        ],
      );
      final kitchenChannel = FakeChannel(
        devices: [
          {'deviceMac': 'K1', 'deviceName': 'Kitchen', 'kind': 'kitchen'},
        ],
      );
      final body = LefuScaleDriver(channel: bodyChannel, credentials: _creds);
      final kitchen = LefuScaleDriver(
        channel: kitchenChannel,
        credentials: _creds,
        kind: ScaleKind.kitchen,
      );
      final coordinator = ScaleConnectionCoordinator(
        body: body,
        kitchen: kitchen,
        pairing: store,
        scanTimeout: const Duration(milliseconds: 200),
      );

      // Nothing paired: start connects nothing.
      await coordinator.start();
      expect(bodyChannel.calls, isNot(contains('connect B1')));

      await coordinator.pair(
        const DiscoveredScale(
          id: 'K1',
          name: 'Kitchen',
          kind: ScaleKind.kitchen,
        ),
      );
      expect(kitchenChannel.calls, contains('connect K1'));
      expect(coordinator.focus, ScaleKind.kitchen);

      await store.save(
        PairedScale.fromDiscovered(
          const DiscoveredScale(id: 'B1', name: 'Body', kind: ScaleKind.body),
        ),
      );
      await coordinator.focusOn(ScaleKind.body);
      expect(kitchenChannel.calls, contains('disconnect'));
      expect(bodyChannel.calls, contains('connect B1'));

      await coordinator.focusOn(ScaleKind.kitchen);
      expect(bodyChannel.calls.last, 'disconnect');
      expect(
        kitchenChannel.calls.where((c) => c == 'connect K1'),
        hasLength(2),
      );
      await body.dispose();
      await kitchen.dispose();
    });
  });
}
