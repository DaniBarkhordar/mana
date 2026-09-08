import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/app.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/core/scale/stored_readings_sync.dart';

/// Boots the whole app on an in-memory database and exercises Today's
/// second glance: the streak chip, the first-run card, and a meal row that
/// opens in place and logs itself again.
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

void main() {
  late AppServices services;

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          // The demo scale hands over remembered mornings on connect; this
          // test is about meals, so that catch-up is kept out of the way.
          storedReadingsSyncProvider.overrideWith((ref) {}),
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

  /// Lunch today and the two days before: chicken 160 g and rice 75 g,
  /// both weighed. 264 + 267 = 531 kcal a meal. Returns today's meal id.
  Future<String> seedThreeDays() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var id = '';
    for (var d = 2; d >= 0; d--) {
      final session = WeighSession()
        ..addTared(food: _chicken, grams: 160)
        ..addTared(food: _rice, grams: 75);
      id = await services.meals.logMeal(
        components: session.components,
        eatenAt: DateTime(today.year, today.month, today.day - d, 12, 50),
        slot: MealSlot.lunch,
      );
    }
    return id;
  }

  testWidgets('with nothing logged the first-run card points at the button',
      (tester) async {
    await seedProfile();
    await pumpApp(tester);
    await settle(tester);

    expect(find.text('Nothing logged yet today'), findsOneWidget);
    expect(find.text('Put the bowl on the scale'), findsOneWidget);
    expect(find.textContaining('tap Weigh food'), findsOneWidget);
    expect(
      find.text(
        'No scale yet? You can still log by searching and entering grams.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('-day streak'), findsNothing);
    await shutDown(tester);
  });

  testWidgets('three logged days show a streak chip in the header',
      (tester) async {
    await seedProfile();
    await seedThreeDays();
    await pumpApp(tester);
    await settle(tester);

    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('a tapped meal row opens in place and Log again logs it again',
      (tester) async {
    await seedProfile();
    final original = await seedThreeDays();
    await pumpApp(tester);
    await settle(tester);

    // Collapsed: the row, its total, no components and no action.
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('531 kcal'), findsOneWidget);
    expect(find.text('Log again'), findsNothing);
    expect(find.text('Chicken breast, grilled'), findsNothing);

    await tester.ensureVisible(find.text('Lunch'));
    await settle(tester);
    await tester.tap(find.text('Lunch'));
    await settle(tester);

    // Open: each component with its grams, how they were established, and
    // its energy; the energy split by macro; the action.
    expect(find.text('Chicken breast, grilled'), findsOneWidget);
    expect(find.text('Basmati rice, dry'), findsOneWidget);
    expect(find.text('160 g'), findsOneWidget);
    expect(find.text('75 g'), findsOneWidget);
    expect(find.text('264 kcal'), findsOneWidget);
    expect(find.text('267 kcal'), findsOneWidget);
    // Two components weighed, plus the row's own badge.
    expect(find.text('Weighed'), findsNWidgets(3));
    // Protein (49.6 + 6.075) × 4 = 222.7; carbs 58.5 × 4 = 234;
    // fat (5.76 + 0.75) × 9 = 58.59.
    expect(find.text('Protein 223 kcal'), findsOneWidget);
    expect(find.text('Carbs 234 kcal'), findsOneWidget);
    expect(find.text('Fat 59 kcal'), findsOneWidget);
    expect(find.text('Log again'), findsOneWidget);

    await tester.ensureVisible(find.text('Log again'));
    await settle(tester);
    await tester.tap(find.text('Log again'));
    await settle(tester);

    // A second meal today, the same foods and grams, no longer weighed.
    final now = DateTime.now();
    final meals = await tester.runAsync(
      () => services.meals
          .watchMealsForDay(DateTime(now.year, now.month, now.day))
          .first,
    );
    expect(meals, hasLength(2));
    // By id, not position: the day is ordered by time eaten, and a run
    // before 12:50 sorts the new meal ahead of the seeded lunch.
    final again = meals!.singleWhere((m) => m.id != original);
    expect(again.components.map((c) => c.food.name), [
      'Chicken breast, grilled',
      'Basmati rice, dry',
    ]);
    expect(again.components.map((c) => c.grams), [160, 75]);
    expect(
      again.components.map((c) => c.method),
      everyElement(PortionMethod.manualGrams),
    );
    expect(again.totals.confidenceLabel, 'Estimated');
    // And it is on the screen: two rows now carry the meal's total.
    expect(find.text('531 kcal'), findsNWidgets(2));

    // The original row is still the open one, whichever way the two now
    // sort; tapping anywhere in it, its detail included, closes it.
    expect(find.text('Log again'), findsOneWidget);
    await tester.ensureVisible(find.text('Chicken breast, grilled'));
    await settle(tester);
    await tester.tap(find.text('Chicken breast, grilled'));
    await settle(tester);
    expect(find.text('Log again'), findsNothing);
    expect(find.text('Chicken breast, grilled'), findsNothing);
    await shutDown(tester);
  });
}
