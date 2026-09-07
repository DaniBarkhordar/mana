import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/features/progress/progress_providers.dart';

/// The weekly folds, checked against figures worked out by hand from the
/// per-100 g values below. Nothing here touches a database: these are the
/// sums the Progress tab prints, and a wrong sum on a Sunday review is the
/// kind of error nobody notices until it has shaped a month.
void main() {
  const rice = FoodItem(
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
  const apple = FoodItem(
    id: 'est:apple',
    name: 'Apple, medium',
    per100g: NutrientsPer100g(kcal: 52, carbG: 14, fatG: 0.2, proteinG: 0.3),
    source: NutritionSource.estimated,
  );

  // 75 g rice: 267 kcal, 6.075 g protein, 58.5 g carb, 0.75 g fat.
  const rice75 = LoggedComponent(
    food: rice,
    grams: 75,
    method: PortionMethod.weighed,
  );
  // 160 g chicken: 264 kcal, 49.6 g protein, 0 g carb, 5.76 g fat.
  const chicken160 = LoggedComponent(
    food: chicken,
    grams: 160,
    method: PortionMethod.weighed,
  );
  // 180 g apple, not weighed: 93.6 kcal, 0.54 g protein, 25.2 g carb,
  // 0.36 g fat.
  const apple180 = LoggedComponent(
    food: apple,
    grams: 180,
    method: PortionMethod.householdMeasure,
  );

  LoggedMeal meal(String id, DateTime at, List<LoggedComponent> parts) =>
      LoggedMeal(id: id, eatenAt: at, slot: MealSlot.lunch, components: parts);

  // 7 September 2026 is a Monday.
  final monday = DateTime(2026, 9, 7);
  final meals = [
    // Previous week's Sunday: must not count towards this week.
    meal('sun', DateTime(2026, 9, 6, 16), [apple180]),
    meal('mon', DateTime(2026, 9, 7, 12, 30), [rice75, chicken160]),
    meal('tue', DateTime(2026, 9, 8, 13), [rice75, apple180]),
    meal('wed', DateTime(2026, 9, 9, 19), [chicken160]),
  ];

  group('calendar', () {
    test('weekStartOf is the Monday at midnight', () {
      expect(weekStartOf(DateTime(2026, 9, 9, 15, 30)), monday);
      expect(weekStartOf(DateTime(2026, 9, 13, 23, 59)), monday);
      expect(weekStartOf(DateTime(2026, 9, 7, 8)), monday);
      expect(weekStartOf(DateTime(2026, 9, 14)), DateTime(2026, 9, 14));
    });
  });

  group('WeeklySummary', () {
    final week = WeeklySummary.from(meals, monday);

    test('always has seven days, Monday first', () {
      expect(week.days, hasLength(7));
      expect(week.days.first.day, monday);
      expect(week.days.last.day, DateTime(2026, 9, 13));
    });

    test('counts only the days in the week that had a meal', () {
      expect(week.loggedDayCount, 3);
      expect(week.isEmpty, isFalse);
      expect(week.days[3].isLogged, isFalse);
    });

    test('daily energy is the sum of the components', () {
      // Mon 267 + 264; Tue 267 + 93.6; Wed 264.
      expect(week.days[0].kcal, closeTo(531, 1e-9));
      expect(week.days[1].kcal, closeTo(360.6, 1e-9));
      expect(week.days[2].kcal, closeTo(264, 1e-9));
      expect(week.days[6].kcal, 0);
    });

    test('the average divides by logged days, not by seven', () {
      // (531 + 360.6 + 264) / 3 = 1155.6 / 3
      expect(week.averageKcal, closeTo(385.2, 1e-9));
    });

    test('the weighed fraction is by energy, across the week', () {
      // Weighed: 267 + 264 + 267 + 264 = 1062 of 1155.6.
      expect(week.weighedFraction, closeTo(1062 / 1155.6, 1e-9));
    });

    test('macro averages are over logged days and treat 0 as a value', () {
      // Protein: (6.075 + 49.6) + (6.075 + 0.54) + 49.6 = 111.89 / 3.
      expect(week.averageProteinG, closeTo(111.89 / 3, 1e-9));
      // Carbs: 58.5 + (58.5 + 25.2) + 0 = 142.2 / 3. Chicken's carb is a
      // real zero, not a gap, so Wednesday counts.
      expect(week.averageCarbG, closeTo(47.4, 1e-9));
      // Fat: (0.75 + 5.76) + (0.75 + 0.36) + 5.76 = 13.38 / 3.
      expect(week.averageFatG, closeTo(4.46, 1e-9));
    });

    test('days within target: ±10%, and an unlogged day never qualifies', () {
      // Tue 360.6 is within 36 of 360; Mon and Wed are not.
      expect(week.daysWithin(360), 1);
      // Nothing is within 30 of 300.
      expect(week.daysWithin(300), 0);
      // Mon 531 is within 53 of 530.
      expect(week.daysWithin(530), 1);
      // Wed is exactly on 264.
      expect(week.daysWithin(264), 1);
      // Widened, Tue and Wed both sit inside ±30% of 350 (245–455).
      expect(week.daysWithin(350, tolerance: 0.30), 2);
    });

    test('an empty week averages to nothing rather than zero', () {
      final empty = WeeklySummary.from(const [], monday);
      expect(empty.isEmpty, isTrue);
      expect(empty.averageKcal, isNull);
      expect(empty.averageProteinG, isNull);
      expect(empty.weighedFraction, 0);
      expect(empty.daysWithin(2000), 0);
    });
  });

  group('ConsistencySummary', () {
    test('the grid starts eleven weeks before this Monday', () {
      final c = ConsistencySummary.from(meals, today: DateTime(2026, 9, 9));
      // 7 September minus 77 days is 22 June, also a Monday.
      expect(c.gridStart, DateTime(2026, 6, 22));
      expect(c.dayAt(week: 11, weekday: 0), monday);
      expect(c.dayAt(week: 0, weekday: 6), DateTime(2026, 6, 28));
      expect(c.weeks, 12);
    });

    test('kcal per day includes last week, so the grid is not this week only',
        () {
      final c = ConsistencySummary.from(meals, today: DateTime(2026, 9, 9));
      expect(c.kcalOn(DateTime(2026, 9, 6)), closeTo(93.6, 1e-9));
      expect(c.kcalOn(DateTime(2026, 9, 7)), closeTo(531, 1e-9));
      expect(c.kcalOn(DateTime(2026, 9, 10)), 0);
      expect(c.isLogged(DateTime(2026, 9, 10)), isFalse);
    });

    test('the streak runs back from today, or from yesterday before breakfast',
        () {
      // Sun 6, Mon 7, Tue 8, Wed 9 all logged.
      expect(
        ConsistencySummary.from(meals, today: DateTime(2026, 9, 9))
            .currentStreak,
        4,
      );
      // Thursday morning, nothing logged yet: the four days still stand.
      expect(
        ConsistencySummary.from(meals, today: DateTime(2026, 9, 10))
            .currentStreak,
        4,
      );
      // Saturday: Friday was missed, so the streak is over.
      expect(
        ConsistencySummary.from(meals, today: DateTime(2026, 9, 12))
            .currentStreak,
        0,
      );
    });

    test('levels are relative to the target when there is one', () {
      final c = ConsistencySummary.from(meals, today: DateTime(2026, 9, 9));
      // 531/500 = 1.06 → full; 360.6/500 = 0.72 → mid; 264/500 = 0.53 → mid.
      expect(c.level(DateTime(2026, 9, 7), targetKcal: 500), 3);
      expect(c.level(DateTime(2026, 9, 8), targetKcal: 500), 2);
      expect(c.level(DateTime(2026, 9, 9), targetKcal: 500), 2);
      // 264/600 = 0.44 → light.
      expect(c.level(DateTime(2026, 9, 9), targetKcal: 600), 1);
      expect(c.level(DateTime(2026, 9, 10), targetKcal: 500), 0);
    });

    test('without a target, levels scale against the busiest day', () {
      final c = ConsistencySummary.from(meals, today: DateTime(2026, 9, 9));
      // Max is 531. 360.6/531 = 0.68 → mid; 264/531 = 0.497 → light.
      expect(c.level(DateTime(2026, 9, 7)), 3);
      expect(c.level(DateTime(2026, 9, 8)), 2);
      expect(c.level(DateTime(2026, 9, 9)), 1);
    });

    test('a logged day with no energy still counts as logged', () {
      const water = FoodItem(
        id: 'water',
        name: 'Water',
        per100g: NutrientsPer100g(kcal: 0),
        source: NutritionSource.cofid,
      );
      final c = ConsistencySummary.from(
        [
          meal('w', DateTime(2026, 9, 9, 9), const [
            LoggedComponent(
              food: water,
              grams: 250,
              method: PortionMethod.weighed,
            ),
          ]),
        ],
        today: DateTime(2026, 9, 9),
      );
      expect(c.isLogged(DateTime(2026, 9, 9)), isTrue);
      expect(c.currentStreak, 1);
      expect(c.level(DateTime(2026, 9, 9), targetKcal: 2000), 1);
    });
  });

  group('WearableComparison', () {
    final asOf = DateTime(2026, 9, 9, 12);
    ({DateTime at, double value}) p(int daysAgo, double v) =>
        (at: asOf.subtract(Duration(days: daysAgo)), value: v);

    test('week and month means, with a stale point left out', () {
      final c = WearableComparison.from(
        'sleep_minutes',
        [p(40, 999), p(20, 380), p(10, 400), p(3, 480), p(1, 420)],
        asOf: asOf,
        sourceName: 'Apple Health',
      )!;
      // Last 7 days: (420 + 480) / 2.
      expect(c.sevenDay, closeTo(450, 1e-9));
      // Last 30 days: (420 + 480 + 400 + 380) / 4 = 1680 / 4.
      expect(c.thirtyDay, closeTo(420, 1e-9));
      expect(c.delta, closeTo(30, 1e-9));
      expect(c.sourceName, 'Apple Health');
    });

    test('a week with no data has no seven-day figure but keeps the month', () {
      final c = WearableComparison.from(
        'steps',
        [p(20, 8000), p(12, 6000)],
        asOf: asOf,
        sourceName: 'Health Connect',
      )!;
      expect(c.sevenDay, isNull);
      expect(c.thirtyDay, closeTo(7000, 1e-9));
      expect(c.delta, isNull);
    });

    test('nothing in the month is nothing to show', () {
      expect(
        WearableComparison.from(
          'steps',
          [p(45, 8000)],
          asOf: asOf,
          sourceName: 'x',
        ),
        isNull,
      );
    });
  });

  group('copy', () {
    test('weekly rate words', () {
      expect(
        describeWeeklyRate(-0.35),
        '0.35 kg per week down over three weeks',
      );
      expect(describeWeeklyRate(0.5), '0.50 kg per week up over three weeks');
      expect(describeWeeklyRate(0.02), 'Holding steady over three weeks');
    });

    test('sources are named, and the demo scale is called what it is', () {
      expect(sourceDisplayName('apple_health'), 'Apple Health');
      expect(sourceDisplayName('health_connect'), 'Health Connect');
      expect(sourceDisplayName('mananu_body_scale'), 'your scale');
      expect(sourceDisplayName('simulated_scale'), 'the demo scale');
      expect(sourceDisplayName(null), 'your scale');
    });
  });
}
