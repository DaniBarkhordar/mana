import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/health/health_importer.dart';

class FakeGateway implements HealthGateway {
  FakeGateway({this.samples = const [], this.grant = true});

  List<HealthSample> samples;
  final bool grant;
  final written = <(double, DateTime)>[];
  final calls = <String>[];

  @override
  String get sourceId => 'apple_health';

  @override
  String get displayName => 'Apple Health';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestAccess({required bool writeWeight}) async {
    calls.add('access write=$writeWeight');
    return grant;
  }

  @override
  Future<List<HealthSample>> read({
    required List<HealthKind> kinds,
    required DateTime from,
    required DateTime to,
  }) async =>
      samples.where((s) => kinds.contains(s.kind)).toList();

  @override
  Future<bool> writeWeight(double kg, DateTime at) async {
    written.add((kg, at));
    return true;
  }
}

HealthSample _s(
  HealthKind kind,
  double value,
  DateTime from, {
  DateTime? to,
  String source = 'Oura',
}) =>
    HealthSample(
      kind: kind,
      value: value,
      from: from,
      to: to ?? from,
      sourceName: source,
    );

void main() {
  final mon = DateTime(2026, 9, 7);
  final samples = [
    // Steps in chunks through Monday: summed.
    _s(HealthKind.steps, 3000, mon.add(const Duration(hours: 8))),
    _s(HealthKind.steps, 4500, mon.add(const Duration(hours: 13))),
    _s(HealthKind.steps, 1200, mon.add(const Duration(hours: 20))),
    // Sleep Sunday 23:30 → Monday 07:10: Monday's night, in minutes.
    _s(
      HealthKind.sleepAsleep,
      460,
      mon.subtract(const Duration(minutes: 30)),
      to: mon.add(const Duration(hours: 7, minutes: 10)),
    ),
    // Resting HR twice on Monday: the median.
    _s(HealthKind.restingHeartRate, 52, mon.add(const Duration(hours: 6))),
    _s(HealthKind.restingHeartRate, 58, mon.add(const Duration(hours: 22))),
    _s(
      HealthKind.hrvSdnn,
      61,
      mon.add(const Duration(hours: 5)),
      source: 'Apple Watch',
    ),
    // A workout: 45 minutes.
    _s(
      HealthKind.workout,
      45,
      mon.add(const Duration(hours: 18)),
      to: mon.add(const Duration(hours: 18, minutes: 45)),
    ),
  ];

  test('aggregate: sums, nights and medians, one value per kind per day', () {
    final daily = HealthImporter.aggregate(samples);
    final byKind = {for (final d in daily) d.kind: d};
    expect(byKind[HealthKind.steps]!.value, 8700);
    expect(byKind[HealthKind.steps]!.samples, 3);
    expect(byKind[HealthKind.sleepAsleep]!.value, 460);
    expect(byKind[HealthKind.sleepAsleep]!.at, DateTime(2026, 9, 7, 12));
    expect(byKind[HealthKind.restingHeartRate]!.value, 55);
    expect(byKind[HealthKind.hrvSdnn]!.sourceName, 'Apple Watch');
    expect(byKind[HealthKind.workout]!.value, 45);
    expect(daily.every((d) => d.at.hour == 12), isTrue);
  });

  test('connect imports once, and a second import adds nothing', () async {
    final s = AppServices.inMemory();
    addTearDown(s.db.close);
    final gateway = FakeGateway(samples: samples);
    final importer = HealthImporter(
      gateway: gateway,
      observations: s.observations,
      db: s.db,
    );
    expect(await importer.connect(), isTrue);
    expect(gateway.calls, ['access write=false']);
    expect(await importer.isConnected, isTrue);

    final rows = await s.db.select(s.db.observations).get();
    expect(rows, hasLength(5));
    expect(rows.every((r) => r.source == 'apple_health'), isTrue);
    expect(rows.every((r) => r.method == 'imported'), isTrue);
    final sleep = rows.singleWhere((r) => r.kind == 'sleep_minutes');
    expect(sleep.value, 460);
    expect(sleep.unit, 'min');
    expect(sleep.raw, contains('Oura'));

    expect(await importer.importSince(), 0);
    expect(await s.db.select(s.db.observations).get(), hasLength(5));
    expect(await s.observations.sources(), contains('apple_health'));
  });

  test('refused access connects nothing', () async {
    final s = AppServices.inMemory();
    addTearDown(s.db.close);
    final importer = HealthImporter(
      gateway: FakeGateway(grant: false),
      observations: s.observations,
      db: s.db,
    );
    expect(await importer.connect(), isFalse);
    expect(await importer.isConnected, isFalse);
  });

  test('weight goes back only when connected and switched on', () async {
    final s = AppServices.inMemory();
    addTearDown(s.db.close);
    final gateway = FakeGateway();
    final importer = HealthImporter(
      gateway: gateway,
      observations: s.observations,
      db: s.db,
    );
    await importer.shareWeight(78.7, mon);
    expect(gateway.written, isEmpty);

    await importer.connect(writeWeight: true);
    await importer.shareWeight(78.7, mon);
    expect(gateway.written, [(78.7, mon)]);

    await importer.setWriteWeight(false);
    await importer.shareWeight(78.5, mon);
    expect(gateway.written, hasLength(1));
  });
}
