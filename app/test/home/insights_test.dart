import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/features/home/insights.dart';

/// Every figure a sentence prints is worked out below in a comment from the
/// per-100 g values and the readings as listed, so a wrong fold shows up as a
/// wrong sentence.
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
  const oil = FoodItem(
    id: 'cofid:oil',
    name: 'Olive oil',
    per100g: NutrientsPer100g(kcal: 884, fatG: 100),
    source: NutritionSource.cofid,
  );

  // 75 g rice, weighed: 267 kcal, 6.075 g protein.
  const rice75 = LoggedComponent(
    food: rice,
    grams: 75,
    method: PortionMethod.weighed,
  );
  // 75 g rice as a household measure: the same figures, not weighed.
  const rice75Cup = LoggedComponent(
    food: rice,
    grams: 75,
    method: PortionMethod.householdMeasure,
  );
  // 160 g chicken, weighed: 264 kcal, 49.6 g protein.
  const chicken160 = LoggedComponent(
    food: chicken,
    grams: 160,
    method: PortionMethod.weighed,
  );
  // 180 g apple, a household measure: 93.6 kcal, not weighed.
  const apple180 = LoggedComponent(
    food: apple,
    grams: 180,
    method: PortionMethod.householdMeasure,
  );
  // 6 g of oil absorbed from the pan: 884 × 0.06 = 53.04 kcal, weighed.
  const oil6 = LoggedComponent(
    food: oil,
    grams: 6,
    method: PortionMethod.weighed,
    isCookingFat: true,
  );

  LoggedMeal meal(
    String id,
    DateTime at,
    List<LoggedComponent> parts, {
    MealSlot slot = MealSlot.lunch,
  }) =>
      LoggedMeal(id: id, eatenAt: at, slot: slot, components: parts);

  // Tuesday 8 September 2026, one o'clock: lunch is due.
  final now = DateTime(2026, 9, 8, 13);

  group('meal slot nudge', () {
    test('says lunch is unlogged at one, and that the scale is ready', () {
      final i = mealSlotInsight(now: now, meals: const [], scaleReady: true);
      expect(i!.text, 'No lunch logged yet; the scale is ready');
      expect(i.provenance, contains('kitchen scale is connected'));
    });

    test('does not claim the scale is ready when it is not', () {
      final i = mealSlotInsight(now: now, meals: const [], scaleReady: false);
      expect(i!.text, 'No lunch logged yet');
      expect(i.provenance, "Today's meals");
    });

    test('goes quiet once lunch is logged today', () {
      final meals = [
        meal('l', DateTime(2026, 9, 8, 12, 30), [rice75]),
      ];
      expect(mealSlotInsight(now: now, meals: meals, scaleReady: true), isNull);
    });

    test("yesterday's lunch does not count for today", () {
      final meals = [
        meal('l', DateTime(2026, 9, 7, 12, 30), [rice75]),
      ];
      expect(
        mealSlotInsight(now: now, meals: meals, scaleReady: false),
        isNotNull,
      );
    });

    test('the windows: breakfast, lunch, dinner, and the gaps between', () {
      expect(mealSlotDue(DateTime(2026, 9, 8, 6)), isNull);
      expect(mealSlotDue(DateTime(2026, 9, 8, 7)), MealSlot.breakfast);
      expect(mealSlotDue(DateTime(2026, 9, 8, 10, 59)), MealSlot.breakfast);
      expect(mealSlotDue(DateTime(2026, 9, 8, 11)), isNull);
      expect(mealSlotDue(DateTime(2026, 9, 8, 12)), MealSlot.lunch);
      expect(mealSlotDue(DateTime(2026, 9, 8, 14, 59)), MealSlot.lunch);
      expect(mealSlotDue(DateTime(2026, 9, 8, 16)), isNull);
      expect(mealSlotDue(DateTime(2026, 9, 8, 18)), MealSlot.dinner);
      expect(mealSlotDue(DateTime(2026, 9, 8, 20, 59)), MealSlot.dinner);
      expect(mealSlotDue(DateTime(2026, 9, 8, 21)), isNull);
      expect(mealSlotDue(DateTime(2026, 9, 8, 23)), isNull);
    });

    test('names breakfast and dinner in their windows', () {
      expect(
        mealSlotInsight(
          now: DateTime(2026, 9, 8, 8),
          meals: const [],
          scaleReady: false,
        )!
            .text,
        'No breakfast logged yet',
      );
      expect(
        mealSlotInsight(
          now: DateTime(2026, 9, 8, 19),
          meals: const [],
          scaleReady: false,
        )!
            .text,
        'No dinner logged yet',
      );
    });
  });

  group('protein against target', () {
    // Three full days, each rice + chicken: 6.075 + 49.6 = 55.675 g.
    final threeDays = [
      meal('a', DateTime(2026, 9, 5, 13), [rice75, chicken160]),
      meal('b', DateTime(2026, 9, 6, 13), [rice75, chicken160]),
      meal('c', DateTime(2026, 9, 7, 13), [rice75, chicken160]),
    ];

    test('reports the mean shortfall against the target, rounded', () {
      // 55.675 − 140 = −84.325 → 84 g under.
      final i = proteinInsight(now: now, meals: threeDays, targetG: 140);
      expect(i!.text, 'Protein is running 84 g under target this week');
      expect(
        i.provenance,
        'Average of the last 3 logged days against your 140 g target',
      );
    });

    test('and the surplus the other way', () {
      // 55.675 − 40 = 15.675 → 16 g over.
      final i = proteinInsight(now: now, meals: threeDays, targetG: 40);
      expect(i!.text, 'Protein is running 16 g over target this week');
    });

    test('a gap inside the noise floor is not a sentence', () {
      // 55.675 − 56 = −0.325 g: inside 10 g.
      expect(proteinInsight(now: now, meals: threeDays, targetG: 56), isNull);
      // Exactly 9.675 under: still inside.
      expect(
        proteinInsight(now: now, meals: threeDays, targetG: 65),
        isNull,
      );
    });

    test('needs three logged days and a target', () {
      expect(
        proteinInsight(now: now, meals: threeDays.sublist(0, 2), targetG: 140),
        isNull,
      );
      expect(proteinInsight(now: now, meals: threeDays, targetG: null), isNull);
      expect(proteinInsight(now: now, meals: threeDays, targetG: 0), isNull);
    });

    test('today is left out because it is still being eaten', () {
      // An apple at breakfast today (0.54 g) would drag the mean to
      // (3 × 55.675 + 0.54) / 4 = 41.9 g; excluded, it stays 55.675.
      final meals = [
        ...threeDays,
        meal('t', DateTime(2026, 9, 8, 8), [apple180]),
      ];
      final i = proteinInsight(now: now, meals: meals, targetG: 140);
      expect(i!.text, 'Protein is running 84 g under target this week');
      expect(i.provenance, contains('last 3 logged days'));
    });

    test('and so is anything older than six days back', () {
      // 1 September is seven days back: outside the window.
      final meals = [
        ...threeDays,
        meal('old', DateTime(2026, 9, 1, 13), [apple180]),
      ];
      expect(
        proteinInsight(now: now, meals: meals, targetG: 140)!.provenance,
        contains('last 3 logged days'),
      );
    });
  });

  group('weighed days', () {
    // The trailing week is 2 to 8 September. Per day, the weighed share of
    // energy: 2nd rice weighed 1.0; 3rd apple 0; 4th chicken + apple
    // 264 / 357.6 = 0.738; 5th nothing; 6th rice by the cup + chicken
    // 264 / 531 = 0.497; 7th rice weighed 1.0; 8th apple + rice
    // 267 / 360.6 = 0.740. Four days clear 0.6, six of seven are logged.
    final week = [
      meal('1', DateTime(2026, 9, 1, 13), [rice75]), // outside the window
      meal('2', DateTime(2026, 9, 2, 13), [rice75]),
      meal('3', DateTime(2026, 9, 3, 16), [apple180]),
      meal('4', DateTime(2026, 9, 4, 13), [chicken160, apple180]),
      meal('6', DateTime(2026, 9, 6, 13), [rice75Cup, chicken160]),
      meal('7', DateTime(2026, 9, 7, 13), [rice75]),
      meal('8', DateTime(2026, 9, 8, 12), [apple180, rice75]),
    ];

    test('counts the days that cleared the threshold, in words', () {
      final i = weighedDaysInsight(now: now, meals: week);
      expect(
        i!.text,
        'Four of the last seven days were weighed, not estimated',
      );
      expect(
        i.provenance,
        'Days where at least 60% of the energy logged came off the scale; '
        '6 of 7 days logged',
      );
    });

    test('needs four logged days in the window', () {
      // Three in the window plus the one outside it.
      expect(
        weighedDaysInsight(now: now, meals: week.sublist(0, 4)),
        isNull,
      );
    });

    test('singular for one day, and a plain sentence for none', () {
      final one = [
        meal('2', DateTime(2026, 9, 2, 13), [rice75]),
        meal('3', DateTime(2026, 9, 3, 16), [apple180]),
        meal('4', DateTime(2026, 9, 4, 13), [apple180]),
        meal('5', DateTime(2026, 9, 5, 13), [apple180]),
      ];
      expect(
        weighedDaysInsight(now: now, meals: one)!.text,
        'One of the last seven days was weighed, not estimated',
      );
      final none = [
        for (final m in one) meal(m.id, m.eatenAt, [apple180]),
      ];
      expect(
        weighedDaysInsight(now: now, meals: none)!.text,
        'Nothing in the last seven days was weighed',
      );
    });

    test('a full week of weighed days', () {
      final all = [
        for (var d = 2; d <= 8; d++)
          meal('$d', DateTime(2026, 9, d, 13), [rice75]),
      ];
      expect(
        weighedDaysInsight(now: now, meals: all)!.text,
        'Seven of the last seven days were weighed, not estimated',
      );
    });
  });

  group('weight median', () {
    ({DateTime at, double value}) r(int day, double kg, {int month = 9}) =>
        (at: DateTime(2026, month, day, 7), value: kg);

    test('this week against last, beyond the noise floor', () {
      // This week (2–8 Sept) 78.4, 78.2, 78.6 → median 78.4; the week before
      // (26 Aug–1 Sept) 78.9, 78.7, 79.1 → 78.9. Down 0.5 kg.
      final i = weightMedianInsight(
        now: now,
        weights: [
          r(26, 78.9, month: 8),
          r(28, 78.7, month: 8),
          r(1, 79.1),
          r(3, 78.4),
          r(5, 78.2),
          r(8, 78.6),
        ],
      );
      expect(i!.text, 'Your weight median moved 0.5 kg down in two weeks');
      expect(
        i.provenance,
        'Median of 3 readings this week against 3 the week before',
      );
    });

    test('and up', () {
      // 79.0, 79.2, 79.4 → 79.2 against 78.4, 78.5, 78.6 → 78.5: up 0.7.
      final i = weightMedianInsight(
        now: now,
        weights: [
          r(27, 78.4, month: 8),
          r(29, 78.5, month: 8),
          r(31, 78.6, month: 8),
          r(2, 79.0),
          r(4, 79.2),
          r(6, 79.4),
        ],
      );
      expect(i!.text, 'Your weight median moved 0.7 kg up in two weeks');
    });

    test('inside the noise floor it is holding, not a small move', () {
      // 78.4 against 78.6: 0.2 kg, under the 0.3 kg repeatability.
      final i = weightMedianInsight(
        now: now,
        weights: [
          r(27, 78.7, month: 8),
          r(29, 78.5, month: 8),
          r(31, 78.6, month: 8),
          r(2, 78.4),
          r(4, 78.5),
          r(6, 78.2),
        ],
      );
      expect(
        i!.text,
        'Your weight median is holding at 78.4 kg across two weeks',
      );
      expect(i.provenance, contains("under 0.3 kg is the scale's own noise"));
    });

    test('exactly the noise floor is still holding, despite the last bit', () {
      // 78.4 − 78.7 is −0.3000000000000007 in a double.
      final i = weightMedianInsight(
        now: now,
        weights: [
          r(27, 78.7, month: 8),
          r(29, 78.7, month: 8),
          r(31, 78.7, month: 8),
          r(2, 78.4),
          r(4, 78.4),
          r(6, 78.4),
        ],
      );
      expect(i!.text, startsWith('Your weight median is holding'));
    });

    test('needs three readings in each week', () {
      expect(
        weightMedianInsight(
          now: now,
          weights: [
            r(27, 78.7, month: 8),
            r(29, 78.5, month: 8),
            r(2, 78.4),
            r(4, 78.5),
            r(6, 78.2),
          ],
        ),
        isNull,
      );
    });

    test('readings older than a fortnight do not move the median', () {
      // A 90 kg reading on 25 August is outside both windows.
      final i = weightMedianInsight(
        now: now,
        weights: [
          r(25, 90.0, month: 8),
          r(26, 78.9, month: 8),
          r(28, 78.7, month: 8),
          r(1, 79.1),
          r(3, 78.4),
          r(5, 78.2),
          r(8, 78.6),
        ],
      );
      expect(i!.text, 'Your weight median moved 0.5 kg down in two weeks');
      expect(i.provenance, contains('against 3 the week before'));
    });
  });

  group('cooking fat', () {
    test('sums the pan across the week and counts its meals', () {
      // Two meals in the window with 6 g each: 12 g, 2 × 53.04 = 106.08 kcal.
      // The 1 September meal is outside the window.
      final meals = [
        meal('old', DateTime(2026, 9, 1, 13), [rice75, oil6]),
        meal('a', DateTime(2026, 9, 2, 13), [rice75, oil6]),
        meal('b', DateTime(2026, 9, 5, 13), [chicken160]),
        meal('c', DateTime(2026, 9, 8, 12), [chicken160, oil6]),
      ];
      final i = cookingFatInsight(now: now, meals: meals);
      expect(i!.text, 'You weighed 12 g of cooking fat this week: 106 kcal');
      expect(i.provenance, 'Pan weighed before and after, across 2 meals');
    });

    test('singular for one meal, nothing for none', () {
      final one = [
        meal('a', DateTime(2026, 9, 2, 13), [rice75, oil6]),
      ];
      expect(
        cookingFatInsight(now: now, meals: one)!.provenance,
        'Pan weighed before and after, across 1 meal',
      );
      final none = [
        meal('a', DateTime(2026, 9, 2, 13), [rice75]),
      ];
      expect(cookingFatInsight(now: now, meals: none), isNull);
    });
  });

  group('the card', () {
    test('nothing to say is an empty list, not a filler sentence', () {
      expect(
        todayInsights(
          TodayInsightInputs(now: DateTime(2026, 9, 8, 16), meals: const []),
        ),
        isEmpty,
      );
    });

    test('most immediate first, capped at three', () {
      // Lunch is due and unlogged; protein has three full days; six days
      // are logged; both weight weeks have readings; oil was weighed. Five
      // candidates, three shown, in order.
      final meals = [
        for (var d = 2; d <= 7; d++)
          meal('$d', DateTime(2026, 9, d, 13), [rice75, chicken160, oil6]),
      ];
      final weights = [
        for (var d = 26; d <= 31; d++)
          (at: DateTime(2026, 8, d, 7), value: 79.0),
        for (var d = 2; d <= 7; d++) (at: DateTime(2026, 9, d, 7), value: 78.0),
      ];
      final out = todayInsights(
        TodayInsightInputs(
          now: now,
          meals: meals,
          proteinTargetG: 140,
          weights: weights,
          kitchenScaleConnected: true,
        ),
      );
      expect(out, hasLength(maxTodayInsights));
      expect(out[0].text, 'No lunch logged yet; the scale is ready');
      expect(out[1].text, startsWith('Protein is running'));
      expect(
        out[2].text,
        'Six of the last seven days were weighed, not estimated',
      );
      for (final i in out) {
        expect(i.provenance, isNotEmpty);
      }
    });

    test('the sentences state facts and never advise or claim accuracy', () {
      final meals = [
        for (var d = 2; d <= 7; d++)
          meal('$d', DateTime(2026, 9, d, 13), [rice75, chicken160, oil6]),
      ];
      final weights = [
        for (var d = 26; d <= 31; d++)
          (at: DateTime(2026, 8, d, 7), value: 79.0),
        for (var d = 2; d <= 7; d++) (at: DateTime(2026, 9, d, 7), value: 78.0),
      ];
      final all = <TodayInsight?>[
        mealSlotInsight(now: now, meals: meals, scaleReady: true),
        mealSlotInsight(now: now, meals: meals, scaleReady: false),
        proteinInsight(now: now, meals: meals, targetG: 140),
        proteinInsight(now: now, meals: meals, targetG: 40),
        weighedDaysInsight(now: now, meals: meals),
        weightMedianInsight(now: now, weights: weights),
        cookingFatInsight(now: now, meals: meals),
      ];
      for (final i in all.whereType<TodayInsight>()) {
        final lower = '${i.text} ${i.provenance}'.toLowerCase();
        for (final banned in [
          'should',
          'must',
          'need to',
          'eat less',
          'eat more',
          'deficien',
          'accura',
          'healthy',
          'unhealthy',
        ]) {
          expect(lower, isNot(contains(banned)), reason: i.text);
        }
        // A percentage in the text would read as a claim; the only one
        // allowed is the threshold in a provenance line.
        expect(i.text, isNot(contains('%')));
        expect(i.text, isNot(endsWith('.')));
      }
    });
  });

  test('count words', () {
    expect(countWord(0), 'None');
    expect(countWord(1), 'One');
    expect(countWord(7), 'Seven');
    expect(countWord(8), '8');
  });
}
