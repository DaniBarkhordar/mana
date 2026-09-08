import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/core/scale/stored_readings_sync.dart';

import 'fake_scale_driver.dart';

/// The catch-up over an in-memory database: what the scale remembered
/// becomes body_measurements rows with the scale's own timestamps, once, and
/// under exactly the consent rule the live recorder applies.
void main() {
  late AppServices services;

  // A fixed "now" so the far-future and pre-pairing cases are exact.
  final now = DateTime(2026, 9, 8, 8, 0);
  final pairedAt = DateTime(2026, 9, 4, 18, 0);

  final yesterday = DateTime(2026, 9, 7, 7, 30);
  final twoDaysAgo = DateTime(2026, 9, 6, 7, 31);
  final threeDaysAgo = DateTime(2026, 9, 5, 7, 29);

  /// A day before the pairing: someone else's weigh-in, or the shop's.
  final beforePairing = DateTime(2026, 9, 3, 7, 30);

  /// A scale whose clock was never set.
  final farFuture = DateTime(2027, 1, 1, 7, 30);

  final backlog = [
    StoredReading(kg: 79.2, at: threeDaysAgo, impedanceOhm: 515),
    StoredReading(kg: 78.9, at: twoDaysAgo, impedanceOhm: 508),
    StoredReading(kg: 78.7, at: yesterday, impedanceOhm: 512),
    StoredReading(kg: 80.1, at: beforePairing, impedanceOhm: 520),
    StoredReading(kg: 78.5, at: farFuture, impedanceOhm: 511),
  ];

  setUp(() async {
    services = AppServices.inMemory();
    await services.profiles.save(
      heightCm: 178,
      dateOfBirth: UserProfile.dateOfBirthForAge(34, today: now),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
  });
  tearDown(() => services.db.close());

  Future<void> consent({required bool granted}) =>
      services.profiles.recordConsent(
        ConsentRecord(
          purpose: ConsentRecord.bodyComposition,
          policyVersion: ConsentRecord.currentPolicyVersion,
          granted: granted,
          grantedAt: now,
        ),
      );

  StoredReadingsSync syncOver(FakeScaleDriver driver) => StoredReadingsSync(
        driver: driver,
        body: services.body,
        profiles: services.profiles,
        source: 'mananu_body_scale',
        pairedAt: pairedAt,
        now: () => now,
      );

  Future<Set<String>> observationKinds() async =>
      (await services.db.select(services.db.observations).get())
          .map((o) => o.kind)
          .toSet();

  test('three rows carrying the scale\'s timestamps, stored once', () async {
    await consent(granted: true);
    final driver = FakeScaleDriver(stored: backlog);
    var rowsWhenCleared = -1;
    driver.onClear = () async {
      rowsWhenCleared =
          (await services.db.select(services.db.bodyMeasurements).get()).length;
    };

    expect(await syncOver(driver).run(), 3);

    final history = await services.body.watchHistory().first;
    expect(history, hasLength(3));
    // Oldest first, and the scale's stamps — not the time of the sync.
    expect(
      history.map((r) => r.takenAt),
      [threeDaysAgo, twoDaysAgo, yesterday],
    );
    expect(history.map((r) => r.weightKg), [79.2, 78.9, 78.7]);
    expect(history.map((r) => r.impedanceOhm), [515, 508, 512]);

    // The pre-pairing and far-future readings were rejected.
    expect(history.any((r) => r.takenAt == beforePairing), isFalse);
    expect(history.any((r) => r.takenAt == farFuture), isFalse);

    // The scale was told to forget only after all three were on disk.
    expect(driver.calls, ['fetchStored', 'clear']);
    expect(rowsWhenCleared, 3);

    // Same backlog again — a scale that ignored the clear, or a family that
    // has no clear — stores nothing new.
    driver.stored = List.of(backlog);
    expect(await syncOver(driver).run(), 0);
    expect(await services.body.watchHistory().first, hasLength(3));

    final source =
        (await services.db.select(services.db.observations).get()).first.source;
    expect(source, 'mananu_body_scale');
  });

  test('a reading already recorded live within a minute is not repeated',
      () async {
    await consent(granted: true);
    // The live recorder stamped it when it arrived, 40 s after the scale.
    const input = BiaInput(
      heightCm: 178,
      weightKg: 78.7,
      ageYears: 34,
      sex: Sex.male,
      resistanceOhm: 512,
    );
    await services.body.record(
      result: const BodyCompositionEngine().evaluate(
        input: input,
        takenAt: yesterday.add(const Duration(seconds: 40)),
      ),
      input: input,
      source: 'mananu_body_scale',
    );
    final driver = FakeScaleDriver(
      stored: [StoredReading(kg: 78.7, at: yesterday, impedanceOhm: 512)],
    );
    expect(await syncOver(driver).run(), 0);
    expect(await services.body.watchHistory().first, hasLength(1));
    // Nothing to defer: the scale may still forget it.
    expect(driver.calls, ['fetchStored', 'clear']);
  });

  test('now plus five minutes is the far edge of a believable clock', () async {
    await consent(granted: true);
    final driver = FakeScaleDriver(
      stored: [
        StoredReading(kg: 78.7, at: now.add(const Duration(minutes: 4))),
        StoredReading(kg: 78.8, at: now.add(const Duration(minutes: 6))),
      ],
    );
    expect(await syncOver(driver).run(), 1);
    final history = await services.body.watchHistory().first;
    expect(history.single.weightKg, 78.7);
  });

  test('with consent the composition is stored; without it, weight only',
      () async {
    await consent(granted: true);
    final driver = FakeScaleDriver(stored: backlog.take(3).toList());
    expect(await syncOver(driver).run(), 3);
    expect(
      await observationKinds(),
      {'weight_kg', 'impedance_ohm', 'body_fat_pct'},
    );
    final history = await services.body.watchHistory().first;
    expect(history.last.metric('bodyFatPercent'), isNotNull);
  });

  test('without consent only weight and impedance are stored', () async {
    await consent(granted: false);
    final driver = FakeScaleDriver(stored: backlog.take(3).toList());
    expect(await syncOver(driver).run(), 3);
    // Same rule as the live recorder: the impedance never reaches the
    // engine, so no body_fat_pct observation exists and the row has no
    // impedance to recompute from later.
    expect(await observationKinds(), {'weight_kg'});
    final history = await services.body.watchHistory().first;
    // No impedance, so no fat-free mass from bioimpedance; any body-fat
    // figure left is the anthropometric fallback, which the observation
    // store does not record as measured-and-predicted.
    expect(history.last.metric('fatFreeMass'), isNull);
    expect(history.last.impedanceOhm, isNull);
  });

  test('no pairing time means no lower bound', () async {
    await consent(granted: true);
    final driver = FakeScaleDriver(stored: backlog);
    final sync = StoredReadingsSync(
      driver: driver,
      body: services.body,
      profiles: services.profiles,
      source: 'simulated_scale',
      now: () => now,
    );
    // Four: the far-future one is still rejected.
    expect(await sync.run(), 4);
  });

  test('without a profile nothing is stored and the scale keeps its memory',
      () async {
    final fresh = AppServices.inMemory();
    addTearDown(fresh.db.close);
    final driver = FakeScaleDriver(stored: backlog.take(3).toList());
    final sync = StoredReadingsSync(
      driver: driver,
      body: fresh.body,
      profiles: fresh.profiles,
      source: 'mananu_body_scale',
      pairedAt: pairedAt,
      now: () => now,
    );
    expect(await sync.run(), 0);
    expect(driver.calls, ['fetchStored']);
    expect(driver.stored, hasLength(3));
  });

  test('the demo scale serves its backlog once per connect', () async {
    final demo = SimulatedScaleDriver();
    expect(await demo.fetchStoredReadings(), isEmpty);
    final found = await demo.scan().first;
    await demo.connect(found);
    final first = await demo.fetchStoredReadings();
    expect(first, hasLength(3));
    // Oldest first, a few hundred grams apart, impedance around 512.
    expect(first.first.at.isBefore(first.last.at), isTrue);
    expect(first.map((r) => r.kg), [79.2, 78.9, 78.7]);
    for (final r in first) {
      expect(r.impedanceOhm, closeTo(512, 5));
      expect(r.at.isBefore(DateTime.now()), isTrue);
    }
    expect(await demo.fetchStoredReadings(), isEmpty);
    await demo.disconnect();
    await demo.connect(found);
    expect(await demo.fetchStoredReadings(), hasLength(3));
    await demo.dispose();
  });

  test('the message handles one reading and several', () {
    expect(
      StoredReadingsCatchUp(count: 1, at: now).message,
      'Caught up: 1 reading from your scale',
    );
    expect(
      StoredReadingsCatchUp(count: 3, at: now).message,
      'Caught up: 3 readings from your scale',
    );
  });
}
