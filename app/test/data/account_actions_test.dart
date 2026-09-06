import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

const _rice = FoodItem(
  id: 'cofid:rice',
  name: 'Rice, "basmati", boiled',
  per100g: NutrientsPer100g(kcal: 130, proteinG: 3, carbG: 28, fatG: 0.4),
  source: NutritionSource.cofid,
  state: FoodState.cooked,
);

void main() {
  late AppServices s;
  late AccountActions actions;

  setUp(() async {
    s = AppServices.inMemory();
    actions = AccountActions(db: s.db, profiles: s.profiles);
    await s.profiles.save(
      heightCm: 178,
      dateOfBirth: DateTime(1992, 3, 4),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
    await s.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: true,
        grantedAt: DateTime(2026, 9, 1),
      ),
    );
    const input = BiaInput(
      heightCm: 178,
      weightKg: 78.7,
      ageYears: 34,
      sex: Sex.male,
      resistanceOhm: 500,
    );
    await s.body.record(
      result: const BodyCompositionEngine()
          .evaluate(input: input, takenAt: DateTime(2026, 9, 5, 7, 12)),
      input: input,
      source: 'simulated_scale',
    );
    final session = WeighSession()..addTared(food: _rice, grams: 150);
    await s.meals.logMeal(
      components: session.components,
      eatenAt: DateTime(2026, 9, 5, 12, 30),
      slot: MealSlot.lunch,
    );
  });

  tearDown(() => s.db.close());

  test('withdrawing consent keeps the weight and removes the composition',
      () async {
    await actions.withdrawBodyComposition(deleteExisting: true);

    final consent =
        await s.profiles.latestConsent(ConsentRecord.bodyComposition);
    expect(consent!.granted, isFalse);
    // Two rows: the grant and the withdrawal. Never an edit.
    expect((await s.db.select(s.db.consents).get()).length, 2);

    final row = await s.db.select(s.db.bodyMeasurements).getSingle();
    expect(row.weightKg, 78.7);
    expect(row.impedanceOhm, isNull);
    expect(row.bodyFatPercent, isNull);
    expect(row.fatFreeMassKg, isNull);
    expect(row.confidence, 'weight_only');
    expect(row.syncedAt, isNull);

    final live = await (s.db.select(s.db.observations)
          ..where((o) => o.deletedAt.isNull()))
        .get();
    expect(live.map((o) => o.kind), ['weight_kg']);

    // The history still shows the weight, honestly labelled.
    final history = await s.body.watchHistory().first;
    expect(history.single.confidence, ReadingConfidence.weightOnly);
  });

  test('the export is one CSV per table with the rows in it', () async {
    final dir = Directory.systemTemp.createTempSync('mananu-export');
    addTearDown(() => dir.deleteSync(recursive: true));
    final files = await DataExporter(s.db).writeAll(dir);
    expect(
      files.map((f) => f.uri.pathSegments.last),
      [
        'body_measurements.csv',
        'observations.csv',
        'meals.csv',
        'meal_components.csv',
        'consents.csv',
      ],
    );
    final body = files[0].readAsLinesSync();
    expect(body.first, startsWith('taken_at,weight_kg,impedance_ohm'));
    expect(body, hasLength(2));
    expect(body[1], contains('78.7'));

    final components = files[3].readAsLinesSync();
    expect(components, hasLength(2));
    // The quoted food name survives the comma and the quotes inside it.
    expect(components[1], contains('"Rice, ""basmati"", boiled"'));
    expect(components[1], contains('150.0'));

    final consents = files[4].readAsLinesSync();
    expect(consents, hasLength(2));
    expect(consents[1], contains('body_composition'));
  });

  test('csvLine escapes exactly what RFC 4180 needs', () {
    expect(
      DataExporter.csvLine(['a', null, 1.5, 'x,y', 'he said "hi"']),
      'a,,1.5,"x,y","he said ""hi"""',
    );
    expect(
      DataExporter.csvLine([DateTime.utc(2026, 9, 5, 7, 12)]),
      '2026-09-05T07:12:00.000Z',
    );
  });

  test('wiping leaves nothing behind and a fresh local user id follows',
      () async {
    final before = await s.db.localUserId();
    await actions.wipeLocal();
    for (final table in s.db.allTables) {
      expect(await s.db.select(table).get(), isEmpty, reason: table.entityName);
    }
    expect(await s.db.localUserId(), isNot(before));
    expect(await s.profiles.currentProfile(), isNull);
  });

  test('deleting without a backend is a local wipe', () async {
    await actions.deleteAccount();
    expect(await s.db.select(s.db.meals).get(), isEmpty);
  });
}
