import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/insights/associations.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

/// The two-arm comparison against arms worked out by hand, the eight-day
/// floor, the deterministic bootstrap, and the day-level behaviours.
void main() {
  // Late-meal nights, nine of them: 58 60 59 61 60 62 58 60 59 sorts to
  // 58 58 59 59 60 60 60 61 62, so the median is the fifth, 60.
  const lateNights = <double>[58, 60, 59, 61, 60, 62, 58, 60, 59];

  // Thirty-one other nights: the pattern 55 56 54 57 56 six times and one
  // more 55. That is six 54s, seven 55s, twelve 56s and six 57s; sorted,
  // positions 14 to 25 are 56, and the sixteenth value is the median: 56.
  final otherNights = <double>[
    for (var i = 0; i < 6; i++) ...[55, 56, 54, 57, 56],
    55,
  ];

  List<({bool flag, double outcome})> arms(
    List<double> flagged,
    List<double> other,
  ) =>
      [
        for (final v in flagged) (flag: true, outcome: v),
        for (final v in other) (flag: false, outcome: v),
      ];

  group('ArmDifference', () {
    test('median difference and n per arm, by hand', () {
      expect(otherNights.length, 31);
      final d = ArmDifference.compute(arms(lateNights, otherNights))!;
      expect(d.difference, 4);
      expect(d.nFlagged, 9);
      expect(d.nOther, 31);
      // The point estimate sits inside its own interval.
      expect(d.intervalLow, lessThanOrEqualTo(4));
      expect(d.intervalHigh, greaterThanOrEqualTo(4));
      // The arms span 58–62 and 54–57, so no resample can produce a
      // difference outside 1 (58 − 57) to 8 (62 − 54).
      expect(d.intervalLow, greaterThanOrEqualTo(1));
      expect(d.intervalHigh, lessThanOrEqualTo(8));
    });

    test('an arm of seven returns null', () {
      expect(
        ArmDifference.compute(arms(lateNights.sublist(0, 7), otherNights)),
        isNull,
      );
      expect(
        ArmDifference.compute(arms(lateNights, otherNights.sublist(0, 7))),
        isNull,
      );
      // Eight is enough.
      expect(
        ArmDifference.compute(arms(lateNights.sublist(0, 8), otherNights)),
        isNotNull,
      );
    });

    test('the bootstrap is seeded, so the interval is the same every time', () {
      final a = ArmDifference.compute(arms(lateNights, otherNights))!;
      final b = ArmDifference.compute(arms(lateNights, otherNights))!;
      expect(a.intervalLow, b.intervalLow);
      expect(a.intervalHigh, b.intervalHigh);
      final c = ArmDifference.compute(arms(lateNights, otherNights), seed: 1)!;
      expect(c.difference, a.difference);
    });

    test('arms with no spread give an interval of exactly the difference', () {
      // Every resample of a constant arm is the same constant, so all 1000
      // draws are 60 − 56 = 4 and both percentiles are 4.
      final d = ArmDifference.compute(
        arms(List.filled(8, 60), List.filled(8, 56)),
      )!;
      expect(d.difference, 4);
      expect(d.intervalLow, 4);
      expect(d.intervalHigh, 4);
    });
  });

  group('sentence', () {
    const restingHr = Outcome.restingHr;

    AssociationReport report(List<double> flagged, List<double> other) {
      final days = arms(flagged, other);
      return AssociationReport(
        behaviour: Behaviour.lateMeal,
        outcome: restingHr,
        nFlagged: flagged.length,
        nOther: other.length,
        stats: ArmDifference.compute(days),
      );
    }

    test('the exact pattern', () {
      expect(
        report(lateNights, otherNights).sentence,
        'In your data, nights after a late meal had resting HR 4 bpm above '
        'your median (n = 9 vs 31)',
      );
    });

    test('below reads as below', () {
      // Flagged arm all 50 against the 56 median: six below.
      expect(
        report(List.filled(8, 50), otherNights).sentence,
        'In your data, nights after a late meal had resting HR 6 bpm below '
        'your median (n = 8 vs 31)',
      );
    });

    test('a difference that rounds to nothing is level, not zero above', () {
      // Flagged arm all 56 against the 56 median.
      expect(
        report(List.filled(8, 56), otherNights).sentence,
        'In your data, nights after a late meal had resting HR level with '
        'your median (n = 8 vs 31)',
      );
      expect(Outcome.restingHr.describe(0.4), 'level with');
      expect(Outcome.restingHr.describe(-0.6), '1 bpm below');
    });

    test('a short arm renders nothing and says how far along it is', () {
      final r = report(lateNights.sublist(0, 5), otherNights);
      expect(r.sentence, isNull);
      expect(r.hasEnough, isFalse);
      expect(
        r.calibration,
        (count: 5, needed: 8, label: 'late-meal days'),
      );
      // When it is the other arm that is short, that is the one to fill.
      final o = report(lateNights, otherNights.sublist(0, 3));
      expect(o.calibration, (count: 3, needed: 8, label: 'other days'));
    });

    test('never causal, never a verdict', () {
      const banned = ['causes', 'improves', 'deficient', 'should', 'buy'];
      final s = report(lateNights, otherNights).sentence!.toLowerCase();
      for (final word in banned) {
        expect(s, isNot(contains(word)));
      }
      expect(s, isNot(contains('%')));
    });
  });

  group('behaviours over a day', () {
    const rice = FoodItem(
      id: 'cofid:rice',
      name: 'Rice',
      per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1),
      source: NutritionSource.cofid,
    );
    const oil = FoodItem(
      id: 'cofid:oil',
      name: 'Olive oil',
      per100g: NutrientsPer100g(kcal: 884, fatG: 100),
      source: NutritionSource.cofid,
    );
    LoggedMeal at(
      int hour,
      int minute, {
      FoodItem food = rice,
      double grams = 100,
      PortionMethod method = PortionMethod.weighed,
      DateTime? day,
    }) =>
        LoggedMeal(
          id: '${day?.day}:$hour:$minute',
          eatenAt: (day ?? DateTime(2026, 9, 8)).add(
            Duration(hours: hour, minutes: minute),
          ),
          slot: MealSlot.dinner,
          components: [
            LoggedComponent(food: food, grams: grams, method: method),
          ],
        );

    test('a late meal is one at or after 21:00', () {
      expect(Behaviour.lastMealAfterNine([at(12, 0), at(21, 0)]), isTrue);
      expect(Behaviour.lastMealAfterNine([at(21, 30), at(12, 0)]), isTrue);
      expect(Behaviour.lastMealAfterNine([at(12, 0), at(20, 59)]), isFalse);
      expect(Behaviour.lastMealAfterNine(const []), isFalse);
    });

    test('a high-fat day is more than 40% of energy from fat', () {
      // 100 g rice (356 kcal, 1 g fat = 9 kcal) plus 20 g oil (176.8 kcal,
      // 20 g fat = 180 kcal): 189 / 532.8 = 35.5%, not high-fat.
      expect(
        Behaviour.highFat([at(12, 0), at(19, 0, food: oil, grams: 20)]),
        isFalse,
      );
      // With 30 g oil: fat 31 g = 279 kcal of 621.2 kcal = 44.9%.
      expect(
        Behaviour.highFat([at(12, 0), at(19, 0, food: oil, grams: 30)]),
        isTrue,
      );
      expect(Behaviour.highFat(const []), isFalse);
    });

    test('a mostly weighed day has half its energy off the scale', () {
      // 356 weighed against 356 estimated: exactly half, which counts.
      expect(
        Behaviour.halfWeighed([
          at(12, 0),
          at(19, 0, method: PortionMethod.photoEstimate),
        ]),
        isTrue,
      );
      // 356 weighed against 712 estimated: a third.
      expect(
        Behaviour.halfWeighed([
          at(12, 0),
          at(19, 0, grams: 200, method: PortionMethod.photoEstimate),
        ]),
        isFalse,
      );
    });

    test('tags are their own behaviours and never read the diary', () {
      expect(Behaviour.alcohol.isTag, isTrue);
      expect(Behaviour.alcohol.tagKind, 'tag_alcohol');
      expect(Behaviour.tags.map((t) => t.tagKind), [
        'tag_alcohol',
        'tag_caffeine_late',
        'tag_illness',
        'tag_travel',
      ]);
      expect(Behaviour.alcohol.test([at(21, 30)]), isFalse);
    });

    test('a day pairs with the morning after it, or drops out', () {
      final mealsByDay = <DateTime, List<LoggedMeal>>{
        DateTime(2026, 9, 1): [at(21, 30)],
        DateTime(2026, 9, 2): [at(12, 0)],
        // No observation on the 4th: this day is not counted.
        DateTime(2026, 9, 3): [at(21, 30)],
      };
      final r = AssociationReport.pair(
        behaviour: Behaviour.lateMeal,
        outcome: Outcome.restingHr,
        mealsByDay: mealsByDay,
        tagDays: const {},
        outcomeByDay: {
          DateTime(2026, 9, 2): 60,
          DateTime(2026, 9, 3): 55,
        },
      );
      expect(r.nFlagged, 1);
      expect(r.nOther, 1);
      expect(r.stats, isNull);

      // A tag behaviour flags by day, on the same meals.
      final t = AssociationReport.pair(
        behaviour: Behaviour.alcohol,
        outcome: Outcome.restingHr,
        mealsByDay: mealsByDay,
        tagDays: {DateTime(2026, 9, 2)},
        outcomeByDay: {
          DateTime(2026, 9, 2): 60,
          DateTime(2026, 9, 3): 55,
        },
      );
      expect(t.nFlagged, 1);
      expect(t.nOther, 1);
    });

    test('all() keeps one HRV outcome and drops behaviours never seen', () {
      final meals = [
        for (var d = 1; d <= 20; d++) at(12, 0, day: DateTime(2026, 8, d)),
      ];
      final reports = AssociationReport.all(
        meals: meals,
        tagDaysByKind: const {},
        outcomesByKind: {
          'hrv_sdnn_ms': {
            for (var d = 2; d <= 21; d++) DateTime(2026, 8, d): 45.0,
          },
          'hrv_rmssd_ms': {
            for (var d = 2; d <= 21; d++) DateTime(2026, 8, d): 30.0,
          },
        },
      );
      // No late meal, no high-fat day, no tag: only the weighed-day
      // behaviour has any flagged day, and only one HRV line for it.
      expect(reports.map((r) => r.behaviour.id), ['half_weighed']);
      expect(reports.single.outcome.kind, 'hrv_sdnn_ms');
      // Every day was weighed, so the other arm is empty and nothing is
      // said.
      expect(reports.single.nFlagged, 20);
      expect(reports.single.nOther, 0);
      expect(reports.single.sentence, isNull);
    });
  });
}
