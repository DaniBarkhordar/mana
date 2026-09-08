import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/app.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/core/scale/stored_readings_sync.dart';
import 'package:mananu/features/progress/progress_screen.dart';

/// Boots the whole app on an in-memory database with the design persona —
/// a week of meals, a month of readings, a fortnight of sleep — and opens the
/// Progress tab.
Finder _tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

const _rice = FoodItem(
  id: 'cofid:11-020',
  name: 'Basmati rice, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.cofid,
);
const _chicken = FoodItem(
  id: 'cofid:13-001',
  name: 'Chicken breast, grilled',
  per100g: NutrientsPer100g(kcal: 165, proteinG: 31, fatG: 3.6, carbG: 0),
  source: NutritionSource.cofid,
);
const _apple = FoodItem(
  id: 'est:apple',
  name: 'Apple, medium',
  per100g: NutrientsPer100g(kcal: 52, carbG: 14, fatG: 0.2, proteinG: 0.3),
  source: NutritionSource.estimated,
);

void main() {
  late AppServices services;

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: const MananuApp(),
      );

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> seedProfile() async {
    final now = DateTime.now();
    await services.profiles.save(
      heightCm: 178,
      dateOfBirth: UserProfile.dateOfBirthForAge(34, today: now),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
    await services.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: true,
        grantedAt: now,
      ),
    );
  }

  Future<void> seedPersona() async {
    await seedProfile();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Seven days of meals ending today, mostly weighed.
    for (var d = 6; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      final lunch = WeighSession()
        ..addTared(food: _chicken, grams: 160)
        ..addTared(food: _rice, grams: 75);
      await services.meals.logMeal(
        components: lunch.components,
        eatenAt: day.add(const Duration(hours: 12, minutes: 50)),
        slot: MealSlot.lunch,
      );
      final snack = WeighSession()
        ..addUnweighed(
          food: _apple,
          grams: 180,
          method: PortionMethod.householdMeasure,
        );
      await services.meals.logMeal(
        components: snack.components,
        eatenAt: day.add(const Duration(hours: 16)),
        slot: MealSlot.snack,
      );
    }

    // Thirty mornings on the scale.
    const engine = BodyCompositionEngine();
    for (var d = 29; d >= 0; d--) {
      final kg = 80.0 - (29 - d) * 0.055 + (d.isEven ? 0.3 : -0.2);
      final input = BiaInput(
        heightCm: 178,
        weightKg: double.parse(kg.toStringAsFixed(1)),
        ageYears: 34,
        sex: Sex.male,
        resistanceOhm: 500,
      );
      final at = today
          .add(const Duration(hours: 7, minutes: 12))
          .subtract(Duration(days: d));
      await services.body.record(
        result: engine.evaluate(input: input, takenAt: at),
        input: input,
        source: 'simulated_scale',
      );
    }

    // A fortnight of sleep from a wearable.
    for (var d = 13; d >= 0; d--) {
      await services.observations.record(
        kind: 'sleep_minutes',
        value: 420 + (d % 3) * 20,
        unit: 'min',
        source: 'apple_health',
        takenAt:
            today.add(const Duration(hours: 12)).subtract(Duration(days: d)),
        method: 'imported',
      );
    }
  }

  testWidgets('the Progress tab is there and renders the seeded week',
      (tester) async {
    await seedPersona();
    await pumpApp(tester);
    await settle(tester);

    expect(_tab('Progress'), findsOneWidget);
    await tester.tap(_tab('Progress'));
    await settle(tester);

    expect(find.byType(ProgressScreen), findsOneWidget);
    // The header, over and above the tab label.
    expect(find.text('Progress'), findsNWidgets(2));
    expect(find.text('THIS WEEK'), findsOneWidget);

    // Weight card, defaulting to thirty days, from the demo scale.
    expect(find.text('WEIGHT · 30 DAYS'), findsOneWidget);
    expect(find.textContaining('From the demo scale'), findsOneWidget);
    expect(find.textContaining('kg per week'), findsOneWidget);

    // Energy: the average and the weighed share carry provenance.
    expect(find.text('kcal a day'), findsOneWidget);
    expect(find.textContaining('% weighed'), findsOneWidget);
    expect(find.textContaining('Average over'), findsOneWidget);

    // Consistency: at least today is logged.
    expect(find.text('days logged this week'), findsOneWidget);
    expect(find.text('current streak'), findsOneWidget);
    expect(
      find.textContaining('Twelve weeks, one square a day'),
      findsOneWidget,
    );
    await shutDown(tester);
  });

  testWidgets('the range control switches the chart to ninety days',
      (tester) async {
    await seedPersona();
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(_tab('Progress'));
    await settle(tester);

    // The weekly review sits above the chart, so bring the control up.
    await tester.ensureVisible(find.text('90d'));
    await settle(tester);
    await tester.tap(find.text('90d'));
    await settle(tester);
    expect(find.text('WEIGHT · 90 DAYS'), findsOneWidget);
    expect(find.text('WEIGHT · 30 DAYS'), findsNothing);
    await shutDown(tester);
  });

  testWidgets('wearables appear with their source when observations exist',
      (tester) async {
    await seedPersona();
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(_tab('Progress'));
    await settle(tester);

    final list = find.descendant(
      of: find.byType(ProgressScreen),
      matching: find.byType(ListView),
    );
    await tester.dragUntilVisible(
      find.text('From Apple Health'),
      list,
      const Offset(0, -300),
    );
    expect(find.text('From Apple Health'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('7-DAY AVERAGE · 30-DAY BASELINE'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('the weekly review leads the tab and opens the evening tags',
      (tester) async {
    await seedPersona();
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(_tab('Progress'));
    await settle(tester);

    // The review sits above the weight card, labelled with its ISO week.
    expect(find.text('WEEKLY REVIEW'), findsOneWidget);
    expect(find.textContaining('WEEK '), findsOneWidget);
    final review = tester.getTopLeft(find.text('WEEKLY REVIEW'));
    final weight = tester.getTopLeft(find.text('WEIGHT · 30 DAYS'));
    expect(review.dy, lessThan(weight.dy));

    // Seven days of meals ending today: the weighed share, the streak, and
    // the demo scale's mornings, all as plain sentences.
    expect(
      find.textContaining('of your calories this week'),
      findsOneWidget,
    );
    expect(find.textContaining('before 10:00'), findsOneWidget);
    expect(find.textContaining('Weight median'), findsOneWidget);
    expect(find.textContaining('Sleep median'), findsOneWidget);
    expect(find.textContaining('derived from'), findsOneWidget);

    // The tag sheet opens from the card and writes through the repository.
    await tester.ensureVisible(find.text('Evening tags'));
    await settle(tester);
    await tester.tap(find.text('Evening tags'));
    await settle(tester);
    expect(
      find.text(
        'These stay on your phone and only ever compare your own days.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('A drink this evening'));
    await settle(tester);
    final tags = await tester.runAsync(
      () => (services.db.select(services.db.observations)
            ..where((o) => o.kind.equals('tag_alcohol')))
          .get(),
    );
    expect(tags, hasLength(1));
    expect(tags!.single.source, 'diary');
    expect(tags.single.value, 1);
    await shutDown(tester);
  });

  testWidgets('with nothing logged the tab shows one friendly card',
      (tester) async {
    await seedProfile();
    // The demo scale hands over three remembered mornings on connect, which
    // would fill the page; "nothing logged" means that catch-up did not run.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          storedReadingsSyncProvider.overrideWith((ref) {}),
        ],
        child: const MananuApp(),
      ),
    );
    await settle(tester);
    await tester.tap(_tab('Progress'));
    await settle(tester);

    expect(find.text('Your first week starts now'), findsOneWidget);
    expect(find.text('WEIGHT · 30 DAYS'), findsNothing);
    await shutDown(tester);
  });
}
