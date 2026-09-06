import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/data/repositories/body_repository.dart';
import 'package:mananu/core/data/repositories/meal_repository.dart';
import 'package:mananu/core/data/repositories/observation_repository.dart';
import 'package:mananu/core/data/repositories/profile_repository.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

/// Every repository reads and writes SQLite only. These run against an
/// in-memory database, so what they prove is exactly what the phone does in
/// aeroplane mode.
void main() {
  late AppDatabase db;
  late ProfileRepository profiles;
  late MealRepository meals;
  late ObservationRepository observations;
  late BodyRepository body;

  setUp(() {
    db = AppDatabase.memory();
    profiles = ProfileRepository(db);
    meals = MealRepository(db);
    observations = ObservationRepository(db);
    body = BodyRepository(db, observations);
  });

  tearDown(() => db.close());

  const riceDry = FoodItem(
    id: 'cofid:11-020',
    name: 'Basmati rice, dry',
    per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
    source: NutritionSource.cofid,
  );
  const chicken = FoodItem(
    id: 'cofid:13-001',
    name: 'Chicken breast, grilled',
    per100g: NutrientsPer100g(kcal: 165, proteinG: 31, fatG: 3.6, carbG: 0),
    source: NutritionSource.cofid,
  );
  const guessedSalad = FoodItem(
    id: 'est:1',
    name: 'Side salad',
    per100g: NutrientsPer100g(kcal: 90, proteinG: 2, carbG: 5, fatG: 7),
    source: NutritionSource.estimated,
  );

  group('ProfileRepository', () {
    test('is empty until onboarding saves one', () async {
      expect(await profiles.watchProfile().first, isNull);
    });

    test('saves, reads back, and derives age from the date of birth', () async {
      final dob =
          UserProfile.dateOfBirthForAge(34, today: DateTime(2026, 9, 6));
      await profiles.save(
        heightCm: 178,
        dateOfBirth: dob,
        sex: Sex.male,
        activity: ActivityLevel.active,
      );
      final p = (await profiles.watchProfile().first)!;
      expect(p.heightCm, 178);
      expect(p.sex, Sex.male);
      expect(p.activity, ActivityLevel.active);
      expect(p.ageOn(DateTime(2026, 9, 6)), 34);
      // Mid-year birthday: still 34 in June next year, 35 after it.
      expect(p.ageOn(DateTime(2027, 6, 30)), 34);
      expect(p.ageOn(DateTime(2027, 7, 1)), 35);
    });

    test('a second save updates in place and marks the row for sync', () async {
      await profiles.save(
        heightCm: 178,
        dateOfBirth: DateTime(1992, 7, 1),
        sex: Sex.male,
        activity: ActivityLevel.lowActive,
      );
      await db.customUpdate(
        "UPDATE profiles SET synced_at = '2026-01-01T00:00:00.000Z'",
      );
      await profiles.save(
        heightCm: 179,
        dateOfBirth: DateTime(1992, 7, 1),
        sex: Sex.male,
        activity: ActivityLevel.lowActive,
      );
      final rows = await db.select(db.profiles).get();
      expect(rows, hasLength(1));
      expect(rows.single.heightCm, 179);
      expect(rows.single.syncedAt, isNull);
    });

    test('consent is append-only and the latest decision wins', () async {
      await profiles.recordConsent(
        ConsentRecord(
          purpose: ConsentRecord.bodyComposition,
          policyVersion: '1',
          granted: true,
          grantedAt: DateTime(2026, 9, 1),
        ),
      );
      await profiles.recordConsent(
        ConsentRecord(
          purpose: ConsentRecord.bodyComposition,
          policyVersion: '1',
          granted: false,
          grantedAt: DateTime(2026, 9, 5),
        ),
      );
      final latest = await profiles
          .watchLatestConsent(ConsentRecord.bodyComposition)
          .first;
      expect(latest!.granted, isFalse);
      expect(await db.select(db.consents).get(), hasLength(2));
    });
  });

  group('MealRepository', () {
    test('a logged meal comes back the same, and marked unsynced', () async {
      final session = WeighSession()
        ..addTared(food: riceDry, grams: 75)
        ..addTared(food: chicken, grams: 160);
      final eatenAt = DateTime(2026, 9, 6, 12, 30);
      await meals.logMeal(
        components: session.components,
        eatenAt: eatenAt,
        slot: MealSlot.lunch,
      );

      final today = await meals.watchMealsForDay(DateTime(2026, 9, 6)).first;
      expect(today, hasLength(1));
      final meal = today.single;
      expect(meal.slot, MealSlot.lunch);
      expect(meal.isSynced, isFalse);
      expect(meal.eatenAt, eatenAt);
      expect(meal.components, hasLength(2));
      expect(meal.components[0].food.name, 'Basmati rice, dry');
      expect(meal.components[0].grams, 75);
      expect(meal.components[0].method, PortionMethod.weighed);
      // Per-100 g figures survive the round trip through stored totals.
      expect(meal.components[0].food.per100g.kcal, closeTo(356, 1e-6));
      expect(meal.components[1].food.per100g.proteinG, closeTo(31, 1e-6));
      // 356*0.75 + 165*1.6 = 267 + 264
      expect(meal.totals.kcal, closeTo(531, 0.01));
      expect(meal.totals.confidenceLabel, 'Weighed');
    });

    test('the identification error term survives storage', () async {
      final session = WeighSession()
        ..addUnweighed(
          food: guessedSalad,
          grams: 300,
          method: PortionMethod.photoEstimate,
        );
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 19),
        slot: MealSlot.dinner,
      );
      final meal =
          (await meals.watchMealsForDay(DateTime(2026, 9, 6)).first).single;
      expect(meal.components.single.food.source, NutritionSource.estimated);
      expect(meal.components.single.method, PortionMethod.photoEstimate);
      expect(meal.totals.confidenceLabel, 'Estimated');
      expect(meal.totals.relativeError, greaterThan(0.25));
    });

    test('cooking fat keeps its flag', () async {
      const oil = FoodItem(
        id: 'cofid:17-100',
        name: 'Olive oil',
        per100g: NutrientsPer100g(kcal: 884, fatG: 100),
        source: NutritionSource.cofid,
      );
      final session = WeighSession()
        ..addCookingFat(
          const CookingFatCapture(
            fat: oil,
            gramsAdded: 20,
            gramsRemaining: 6,
            portions: 2,
          ),
        );
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 19),
        slot: MealSlot.dinner,
      );
      final meal =
          (await meals.watchMealsForDay(DateTime(2026, 9, 6)).first).single;
      expect(meal.components.single.isCookingFat, isTrue);
      expect(meal.components.single.grams, closeTo(7, 1e-9));
    });

    test('days are local calendar days', () async {
      final session = WeighSession()..addTared(food: riceDry, grams: 50);
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 23, 45),
        slot: MealSlot.snack,
      );
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 7, 0, 10),
        slot: MealSlot.snack,
      );
      expect(
        await meals.watchMealsForDay(DateTime(2026, 9, 6)).first,
        hasLength(1),
      );
      expect(
        await meals.watchMealsForDay(DateTime(2026, 9, 7)).first,
        hasLength(1),
      );
    });

    test('deleting tombstones rather than removes, so it can sync', () async {
      final session = WeighSession()..addTared(food: riceDry, grams: 50);
      final id = await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 8),
        slot: MealSlot.breakfast,
      );
      await meals.deleteMeal(id);
      expect(await meals.watchMealsForDay(DateTime(2026, 9, 6)).first, isEmpty);
      final row = await db.select(db.meals).get();
      expect(row.single.deletedAt, isNotNull);
      expect(row.single.syncedAt, isNull);
    });

    test('the stream re-emits when a meal is added', () async {
      final session = WeighSession()..addTared(food: riceDry, grams: 50);
      final stream = meals.watchMealsForDay(DateTime(2026, 9, 6));
      final lengths = <int>[];
      final sub = stream.listen((m) => lengths.add(m.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 8),
        slot: MealSlot.breakfast,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(lengths, [0, 1]);
    });
  });

  group('BodyRepository', () {
    const input = BiaInput(
      heightCm: 178,
      weightKg: 80,
      ageYears: 34,
      sex: Sex.male,
      resistanceOhm: 500,
    );
    const engine = BodyCompositionEngine();

    test('stores a reading and reads it back identically', () async {
      final takenAt = DateTime(2026, 9, 6, 7, 15);
      final result = engine.evaluate(input: input, takenAt: takenAt);
      await body.record(result: result, input: input, source: 'test');

      final history = await body.watchHistory().first;
      expect(history, hasLength(1));
      final back = history.single;
      expect(back.takenAt, takenAt);
      expect(back.weightKg, 80);
      expect(back.confidence, ReadingConfidence.good);
      expect(
        back.metric('fatFreeMass')!.value,
        closeTo(result.metric('fatFreeMass')!.value, 1e-9),
      );
      expect(back.metric('fatFreeMass')!.equation, BiaEquation.sun2003);
      expect(back.metric('bodyFatPercent')!.uncertainty, isNotNull);
      expect(back.metric('boneMass')!.derived, Derived.notMeasured);
    });

    test('snapshots height, age and sex on the row', () async {
      final result = engine.evaluate(input: input, takenAt: DateTime(2026));
      await body.record(result: result, input: input, source: 'test');
      final row = (await db.select(db.bodyMeasurements).get()).single;
      expect(row.heightCmAtTime, 178);
      expect(row.ageYearsAtTime, 34);
      expect(row.sexAtTime, 'male');
      expect(row.equation, 'sun2003');
      expect(row.impedanceOhm, 500);
    });

    test('writes observations for weight, impedance and body fat', () async {
      final result = engine.evaluate(input: input, takenAt: DateTime(2026));
      await body.record(result: result, input: input, source: 'test');
      final rows = await db.select(db.observations).get();
      final kinds = rows.map((r) => r.kind).toSet();
      expect(kinds, {'weight_kg', 'impedance_ohm', 'body_fat_pct'});
      final fat = rows.singleWhere((r) => r.kind == 'body_fat_pct');
      expect(fat.method, 'sun2003');
      expect(fat.unit, '%');
      expect(fat.source, 'test');
    });

    test('a weight-only reading writes no body fat observation', () async {
      const noImpedance = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
      );
      final result =
          engine.evaluate(input: noImpedance, takenAt: DateTime(2026));
      await body.record(result: result, input: noImpedance, source: 'test');
      final kinds =
          (await db.select(db.observations).get()).map((r) => r.kind).toSet();
      expect(kinds, {'weight_kg'});
      final back = (await body.watchHistory().first).single;
      expect(back.confidence, ReadingConfidence.weightOnly);
    });

    test('a reading stored under a different equation is shown as stored',
        () async {
      final result = engine.evaluate(input: input, takenAt: DateTime(2026));
      await body.record(result: result, input: input, source: 'test');
      // Pretend history was written by an earlier engine.
      await db.customUpdate(
        "UPDATE body_measurements SET equation = 'deurenberg1991Bia', "
        'fat_free_mass_kg = 58.5',
      );
      final back = (await body.watchHistory().first).single;
      expect(back.metric('fatFreeMass')!.value, 58.5);
      expect(
        back.metric('fatFreeMass')!.equation,
        BiaEquation.deurenberg1991Bia,
      );
      expect(back.notes.last, contains('Shown as it was'));
    });

    test('history is oldest first', () async {
      for (final day in [3, 1, 2]) {
        final r =
            engine.evaluate(input: input, takenAt: DateTime(2026, 9, day));
        await body.record(result: r, input: input, source: 'test');
      }
      final history = await body.watchHistory().first;
      expect(history.map((r) => r.takenAt.day), [1, 2, 3]);
    });
  });

  group('ObservationRepository', () {
    test('series come back oldest first for the smoother', () async {
      for (final day in [5, 3, 4]) {
        await observations.record(
          kind: 'weight_kg',
          value: 80.0 + day,
          unit: 'kg',
          source: 'test',
          takenAt: DateTime(2026, 9, day),
        );
      }
      final series = await observations.watchSeries('weight_kg').first;
      expect(series.map((p) => p.value), [83.0, 84.0, 85.0]);
      expect(await observations.sources(), ['test']);
    });
  });

  group('AppDatabase', () {
    test('adoptUser re-keys every row from the placeholder id', () async {
      final placeholder = await db.localUserId();
      await profiles.save(
        heightCm: 178,
        dateOfBirth: DateTime(1992),
        sex: Sex.male,
        activity: ActivityLevel.lowActive,
      );
      final session = WeighSession()..addTared(food: riceDry, grams: 50);
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 6, 8),
        slot: MealSlot.breakfast,
      );
      await db.adoptUser('real-uid');

      expect(await db.localUserId(), 'real-uid');
      expect((await db.select(db.profiles).get()).single.id, 'real-uid');
      expect((await db.select(db.meals).get()).single.userId, 'real-uid');
      expect(
        (await db.select(db.mealComponents).get()).single.userId,
        'real-uid',
      );
      expect(placeholder, isNot('real-uid'));
      // Idempotent.
      await db.adoptUser('real-uid');
      expect((await db.select(db.meals).get()).single.userId, 'real-uid');
    });
  });
}
