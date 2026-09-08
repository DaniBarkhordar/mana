import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/insights/weekly_review.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

/// The weekly review against a week worked out by hand. Every figure the
/// sentences print is derived below in a comment, from the per-100 g values
/// and the readings as listed, so a wrong fold shows up as a wrong sentence.
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

  // 75 g rice, weighed: 267 kcal.
  const rice75 = LoggedComponent(
    food: rice,
    grams: 75,
    method: PortionMethod.weighed,
  );
  // 160 g chicken, weighed: 264 kcal.
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

  LoggedMeal meal(String id, DateTime at, List<LoggedComponent> parts) =>
      LoggedMeal(id: id, eatenAt: at, slot: MealSlot.lunch, components: parts);

  // Tuesday 8 September 2026, mid-afternoon. The ISO week runs from Monday
  // the 7th; its Thursday is the 10th, the 253rd day of a year that began
  // on a Thursday, so 252 ~/ 7 + 1 = week 37.
  final now = DateTime(2026, 9, 8, 14);
  final monday = DateTime(2026, 9, 7);

  final meals = [
    // Older days for the streak: the 3rd is logged, the 4th is not, so the
    // streak ending today is 8, 7, 6, 5 — four days.
    meal('d3', DateTime(2026, 9, 3, 13), [rice75]),
    meal('d5', DateTime(2026, 9, 5, 13), [rice75, chicken160]),
    meal('d6', DateTime(2026, 9, 6, 19), [apple180]),
    // This week. Energy: 267 + 264 + 53.04 + 93.6 + 264 = 941.64 kcal, of
    // which everything but the apple was weighed: 848.04 / 941.64 = 0.9006.
    meal('mon-lunch', DateTime(2026, 9, 7, 12, 30), [rice75, chicken160, oil6]),
    meal('mon-snack', DateTime(2026, 9, 7, 19), [apple180]),
    meal('tue', DateTime(2026, 9, 8, 8), [chicken160]),
  ];

  BodyCompositionResult reading(
    DateTime at,
    double kg,
    double fatPct, {
    double? uncertainty,
  }) =>
      BodyCompositionResult(
        takenAt: at,
        weightKg: kg,
        confidence: ReadingConfidence.good,
        metrics: [
          Metric(
            key: 'bodyFatPercent',
            label: 'Body fat',
            value: fatPct,
            unit: '%',
            derived: Derived.predicted,
            uncertainty: uncertainty,
          ),
        ],
        notes: const [],
      );

  List<BodyCompositionResult> readings({
    double? uncertainty,
    double previousShift = 0,
  }) =>
      [
        // Previous week, Monday 31 August to Sunday 6 September. Weights
        // 78.9, 78.5, 78.7, 79.1 sort to 78.5 78.7 78.9 79.1: median 78.8.
        // Body fat 18.6, 18.5, 18.8, 19.0: median (18.6 + 18.8) / 2 = 18.7.
        reading(
          DateTime(2026, 8, 31, 7),
          78.9 + previousShift,
          18.6,
          uncertainty: uncertainty,
        ),
        reading(
          DateTime(2026, 9, 2, 7),
          78.5 + previousShift,
          18.5,
          uncertainty: uncertainty,
        ),
        reading(
          DateTime(2026, 9, 4, 7),
          78.7 + previousShift,
          18.8,
          uncertainty: uncertainty,
        ),
        reading(
          DateTime(2026, 9, 6, 7),
          79.1 + previousShift,
          19.0,
          uncertainty: uncertainty,
        ),
        // This week: 78.4, 78.0, 78.6 sort to 78.0 78.4 78.6, median 78.4;
        // body fat 18.4, 18.0, 18.9, median 18.4. Two of the three were
        // taken before 10:00.
        reading(DateTime(2026, 9, 7, 7), 78.4, 18.4, uncertainty: uncertainty),
        reading(
          DateTime(2026, 9, 8, 7, 30),
          78.0,
          18.0,
          uncertainty: uncertainty,
        ),
        reading(DateTime(2026, 9, 8, 11), 78.6, 18.9, uncertainty: uncertainty),
      ];

  ObservationSample obs(
    String kind,
    DateTime at,
    double value, {
    String? device,
  }) =>
      ObservationSample(
        kind: kind,
        value: value,
        unit: '',
        source: 'apple_health',
        takenAt: at,
        deviceName: device,
      );

  final observations = [
    // Older than the three-week baseline (which starts 17 August): ignored.
    obs('sleep_minutes', DateTime(2026, 8, 10, 8), 300, device: 'Oura'),
    // Baseline sleep 400, 410, 405: median 405. This week 430, 420: 425,
    // which is 7 h 05 m, 20 minutes more.
    obs('sleep_minutes', DateTime(2026, 8, 20, 8), 400, device: 'Oura'),
    obs('sleep_minutes', DateTime(2026, 8, 27, 8), 410, device: 'Oura'),
    obs('sleep_minutes', DateTime(2026, 9, 3, 8), 405, device: 'Oura'),
    obs('sleep_minutes', DateTime(2026, 9, 7, 8), 430, device: 'Oura'),
    obs('sleep_minutes', DateTime(2026, 9, 8, 8), 420, device: 'Oura'),
    // Resting HR, no device named: baseline 57, 58, 59 → 58; this week
    // 54, 56 → 55; three below.
    obs('resting_hr_bpm', DateTime(2026, 8, 20, 8), 57),
    obs('resting_hr_bpm', DateTime(2026, 8, 27, 8), 58),
    obs('resting_hr_bpm', DateTime(2026, 9, 3, 8), 59),
    obs('resting_hr_bpm', DateTime(2026, 9, 7, 8), 54),
    obs('resting_hr_bpm', DateTime(2026, 9, 8, 8), 56),
    // HRV: baseline 47, 45, 49 → 47; this week 47 → level.
    obs('hrv_sdnn_ms', DateTime(2026, 8, 20, 8), 47, device: 'Oura'),
    obs('hrv_sdnn_ms', DateTime(2026, 8, 27, 8), 45, device: 'Oura'),
    obs('hrv_sdnn_ms', DateTime(2026, 9, 3, 8), 49, device: 'Oura'),
    obs('hrv_sdnn_ms', DateTime(2026, 9, 7, 8), 47, device: 'Oura'),
  ];

  WeeklyReview review({
    double? uncertainty,
    double previousShift = 0,
  }) =>
      WeeklyReview.compute(
        meals: meals,
        bodyReadings: readings(
          uncertainty: uncertainty,
          previousShift: previousShift,
        ),
        observations: observations,
        now: now,
      );

  group('calendar', () {
    test('ISO week numbers', () {
      expect(isoWeekNumber(DateTime(2026, 9, 8)), 37);
      // 1 January 2026 is a Thursday, so it is in week 1 of 2026.
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      // 4 January 2027 is the Monday of 2027's week 1; 3 January (Sunday)
      // is still in 2026's last week, week 53.
      expect(isoWeekNumber(DateTime(2027, 1, 3)), 53);
      expect(isoWeekNumber(DateTime(2027, 1, 4)), 1);
      expect(isoWeekStart(DateTime(2026, 9, 8, 14)), DateTime(2026, 9, 7));
    });

    test('median of an odd and an even list', () {
      expect(median([3, 1, 2]), 2);
      expect(median([4, 1, 3, 2]), 2.5);
      expect(median(const []), isNull);
    });
  });

  group('figures', () {
    test('weighed share, cooking fat and readings', () {
      final r = review();
      expect(r.weekNumber, 37);
      expect(r.weekStart, DateTime(2026, 9, 7));
      expect(r.weekKcal, closeTo(941.64, 1e-9));
      expect(r.weighedShare, closeTo(848.04 / 941.64, 1e-9));
      expect(r.cookingFatG, 6);
      expect(r.cookingFatKcal, closeTo(53.04, 1e-9));
      expect(r.readingCount, 3);
      expect(r.readingsBeforeTen, 2);
      expect(r.daysLogged, 2);
      expect(r.streakDays, 4);
    });

    test('weight medians and a delta beyond the noise floor', () {
      final w = review().weight;
      expect(w.thisWeek, closeTo(78.4, 1e-9));
      expect(w.previousWeek, closeTo(78.8, 1e-9));
      expect(w.delta, closeTo(-0.4, 1e-9));
      expect(w.noiseFloor, 0.3);
      expect(w.beyondNoise, isTrue);
    });

    test('body fat uses the equation standard error as the floor', () {
      // Sun 2003 for a man: 3.9 kg on 78 kg is about 5 percentage points.
      final f = review(uncertainty: 4.9).bodyFat!;
      expect(f.thisWeek, closeTo(18.4, 1e-9));
      expect(f.previousWeek, closeTo(18.7, 1e-9));
      expect(f.delta, closeTo(-0.3, 1e-9));
      expect(f.noiseFloor, 4.9);
      expect(f.beyondNoise, isFalse);
      // Without one, the cited one-point fallback.
      expect(review().bodyFat!.noiseFloor, WeeklyReview.bodyFatNoisePct);
      expect(review().bodyFat!.beyondNoise, isFalse);
      // With a floor below the delta, the change is reported.
      expect(review(uncertainty: 0.2).bodyFat!.beyondNoise, isTrue);
    });

    test('wearables against the previous three weeks, with the source', () {
      final w = review().wearables;
      expect(w.map((x) => x.kind), [
        'sleep_minutes',
        'resting_hr_bpm',
        'hrv_sdnn_ms',
      ]);
      expect(w[0].thisWeek, 425);
      expect(w[0].baseline, 405);
      expect(w[0].thisWeekCount, 2);
      expect(w[0].baselineCount, 3);
      expect(w[0].sourceText, 'Oura via Apple Health');
      expect(w[1].thisWeek, 55);
      expect(w[1].baseline, 58);
      expect(w[1].sourceText, 'Apple Health');
      expect(w[2].delta, 0);
    });
  });

  group('sentences', () {
    test('the review in order, word for word', () {
      expect(review().sentences, [
        'You weighed 90% of your calories this week',
        'Cooking fat: 6 g captured, 53 kcal',
        '3 readings, 2 before 10:00',
        'Weight median 78.4 kg, 0.4 kg below last week',
        "Body fat median 18.4%, no change beyond the scale's noise",
        'Sleep median 7 h 05 m from Oura via Apple Health, 20 minutes more '
            'than your previous three weeks',
        'Resting HR median 55 bpm from Apple Health, 3 bpm below your '
            'previous three weeks',
        'HRV median 47 ms from Oura via Apple Health, level with your '
            'previous three weeks',
        'Meals logged 4 days running',
      ]);
    });

    test('a weight delta inside the repeatability reads as no change', () {
      // Previous week 0.2 kg heavier than this one: 78.6 against 78.4.
      final r = review(previousShift: -0.2);
      expect(r.weight.delta, closeTo(-0.2, 1e-9));
      expect(
        r.sentences,
        contains("Weight median 78.4 kg, no change beyond the scale's noise"),
      );
      // And a floor that exactly equals the delta is still no change: the
      // previous week 0.1 kg lighter has median 78.7, so the delta is 0.3.
      final edge = review(previousShift: -0.1);
      expect(edge.weight.delta, closeTo(-0.3, 1e-9));
      expect(edge.weight.beyondNoise, isFalse);
    });

    test('a week with no earlier week says so rather than inventing one', () {
      final r = WeeklyReview.compute(
        meals: meals,
        bodyReadings:
            readings().where((x) => !x.takenAt.isBefore(monday)).toList(),
        observations:
            observations.where((o) => !o.takenAt.isBefore(monday)).toList(),
        now: now,
      );
      expect(
        r.sentences,
        contains('Weight median 78.4 kg, nothing to compare with last week '
            'yet'),
      );
      expect(
        r.sentences,
        contains('Sleep median 7 h 05 m from Oura via Apple Health, no '
            'earlier weeks to compare with yet'),
      );
    });

    test('an empty week has no sentences and derives from nothing', () {
      final r = WeeklyReview.compute(
        meals: const [],
        bodyReadings: const [],
        observations: const [],
        now: now,
      );
      expect(r.sentences, isEmpty);
      expect(r.derivedFrom, (n: 0, unit: 'days'));
      expect(review().derivedFrom, (n: 3, unit: 'readings'));
    });

    test('never causal, never a verdict, never an accuracy claim', () {
      const banned = ['causes', 'improves', 'deficient', 'should', 'buy'];
      final variants = [
        review(),
        review(uncertainty: 0.2),
        review(previousShift: -0.2),
        review(previousShift: 2),
        WeeklyReview.compute(
          meals: meals,
          bodyReadings: const [],
          observations: const [],
          now: now,
        ),
      ];
      for (final r in variants) {
        for (final s in r.sentences) {
          final lower = s.toLowerCase();
          for (final word in banned) {
            expect(lower, isNot(contains(word)), reason: s);
          }
          // A percent sign anywhere near "accura…" is a headline accuracy
          // claim, which the product never makes.
          expect(
            RegExp(r'%.{0,12}accura|accura.{0,12}%').hasMatch(lower),
            isFalse,
            reason: s,
          );
          expect(s, isNot(contains('!')));
        }
      }
    });
  });
}
