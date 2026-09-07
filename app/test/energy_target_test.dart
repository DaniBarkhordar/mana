import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/nutrition/energy_target.dart';

/// Every expected value here is worked by hand from the published figures:
/// Mifflin-St Jeor 1990 for the resting rate, the NASEM 2023 activity bands,
/// Wishnofsky's 7,700 kcal per kilogram, and the 1.6 g/kg protein floor.
void main() {
  // 178 cm, 80 kg, 34, male:
  //   9.99(80) + 6.25(178) - 4.92(34) + 166 - 161
  //   = 799.2 + 1112.5 - 167.28 + 5 = 1749.42 kcal
  const subject = BiaInput(
    heightCm: 178,
    weightKg: 80,
    ageYears: 34,
    sex: Sex.male,
  );
  final resting = bmrMifflinStJeor(subject);

  group('pace to energy', () {
    test('0.5 kg a week is 550 kcal a day', () {
      // 0.5 × 7700 / 7 = 550
      expect(dailyAdjustmentForPace(0.5), closeTo(550, 1e-9));
    });

    test('a kilo a week is 1,100 kcal a day', () {
      expect(dailyAdjustmentForPace(1.0), closeTo(1100, 1e-9));
    });
  });

  group('maintain', () {
    test('is resting times the activity band, with no adjustment', () {
      // 1749.42 × 1.65 (low active) = 2886.543 → 2887
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
      );
      expect(t.restingKcal, 1749);
      expect(t.maintenanceKcal, 2887);
      expect(t.kcal, 2887);
      expect(t.adjustmentKcal, 0);
      expect(t.restingFloorApplied, isFalse);
      expect(t.goal, GoalKind.maintain);
    });

    test('balanced macros come straight from the shares', () {
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
      );
      // Protein 25 % of 2887 / 4 = 180.4 → 180 (no floor for maintain).
      expect(t.proteinG, 180);
      // Remainder 2887 - 180.4375 × 4 = 2165.25. Carbs 45/(45+30) = 0.6 of
      // it: 1299.15 / 4 = 324.8 → 325. Fat 0.4: 866.1 / 9 = 96.2 → 96.
      expect(t.carbG, 325);
      expect(t.fatG, 96);
    });

    test('names the equation and the goal', () {
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
      );
      expect(t.basis, contains('Mifflin-St Jeor 1990'));
      expect(t.basis, contains('low active ×1.65'));
      expect(t.basis, contains('to maintain'));
    });
  });

  group('lose', () {
    test('takes the pace off maintenance', () {
      // 2886.543 - 550 = 2336.543 → 2337
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
        goal: GoalKind.lose,
        paceKgPerWeek: 0.5,
      );
      expect(t.kcal, 2337);
      expect(t.adjustmentKcal, -550);
      expect(t.restingFloorApplied, isFalse);
      expect(t.basis, contains('less 550 kcal a day to lose 0.5 kg a week'));
    });

    test('protein never drops below 1.6 g per kg', () {
      // Inactive, 1.0 kg a week: 2886.543 × 1.35/1.65... use the band
      // directly: 1749.42 × 1.35 = 2361.717; minus 1100 = 1261.717, which is
      // under the resting rate, so the target is held at 1749.42 → 1749.
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.inactive,
        weightKg: 80,
        goal: GoalKind.lose,
        paceKgPerWeek: 1.0,
      );
      expect(t.kcal, 1749);
      expect(t.restingFloorApplied, isTrue);
      // Protein by share: 25 % of 1749 / 4 = 109.3. Floor: 1.6 × 80 = 128.
      expect(t.proteinG, 128);
      // Remainder 1749 - 512 = 1237. Carbs 0.6 × 1237 / 4 = 185.55 → 186.
      // Fat 0.4 × 1237 / 9 = 54.98 → 55.
      expect(t.carbG, 186);
      expect(t.fatG, 55);
      expect(t.basis, contains('held at your resting rate'));
    });

    test('a pace outside the range is clamped, not honoured', () {
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.veryActive,
        weightKg: 80,
        goal: GoalKind.lose,
        paceKgPerWeek: 3.0,
      );
      // 1749.42 × 2.2 = 3848.724; minus 1100 (the 1.0 cap) = 2748.724 → 2749
      expect(t.kcal, 2749);
      expect(t.adjustmentKcal, -1100);
    });

    test('no pace given means the default half kilo', () {
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
        goal: GoalKind.lose,
      );
      expect(t.adjustmentKcal, -550);
    });
  });

  group('gain', () {
    test('adds the pace to maintenance', () {
      // 2886.543 + 275 (0.25 kg/wk) = 3161.543 → 3162
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
        goal: GoalKind.gain,
        paceKgPerWeek: 0.25,
      );
      expect(t.kcal, 3162);
      expect(t.adjustmentKcal, 275);
      expect(t.basis, contains('plus 275 kcal a day to gain 0.25 kg a week'));
    });
  });

  group('macro splits', () {
    test('high protein applies the floor even when maintaining', () {
      // Cunningham from 60 kg FFM: 500 + 22 × 60 = 1820. Inactive × 1.35 =
      // 2457. Share: 35 % × 2457 / 4 = 214.99. Floor 1.6 × 80 = 128, so the
      // share wins → 215.
      final t = computeEnergyTarget(
        resting: rmrCunningham1980(60),
        activity: ActivityLevel.inactive,
        weightKg: 80,
        split: MacroSplit.highProtein,
      );
      expect(t.kcal, 2457);
      expect(t.proteinG, 215);
      // Remainder 2457 - 859.95 = 1597.05. Carbs 35/(35+30) = 0.53846:
      // 859.95 / 4 = 214.99 → 215. Fat 0.46154: 737.1 / 9 = 81.9 → 82.
      expect(t.carbG, 215);
      expect(t.fatG, 82);
      expect(t.basis, contains('Cunningham 1980'));
      expect(t.basis, startsWith('From your fat-free mass'));
    });

    test('lower carb puts the remainder mostly into fat', () {
      final t = computeEnergyTarget(
        resting: resting,
        activity: ActivityLevel.lowActive,
        weightKg: 80,
        split: MacroSplit.lowCarb,
      );
      // 30 % × 2887 / 4 = 216.5 → 217 (216.525 rounds up).
      expect(t.proteinG, 217);
      // Remainder 2887 - 866.1 = 2020.9. Carbs 25/70: 721.75 / 4 = 180.4 →
      // 180. Fat 45/70: 1299.15 / 9 = 144.35 → 144.
      expect(t.carbG, 180);
      expect(t.fatG, 144);
    });
  });

  group('projected date', () {
    test('counts the weeks at the pace, rounded up to whole days', () {
      // 5 kg at 0.5 kg a week = 10 weeks = 70 days.
      final from = DateTime(2026, 9, 7);
      expect(
        projectedDate(
          currentKg: 80,
          targetKg: 75,
          paceKgPerWeek: 0.5,
          goal: GoalKind.lose,
          from: from,
        ),
        DateTime(2026, 11, 16),
      );
    });

    test('is null when the target is the wrong side of now', () {
      expect(
        projectedDate(
          currentKg: 80,
          targetKg: 85,
          paceKgPerWeek: 0.5,
          goal: GoalKind.lose,
        ),
        isNull,
      );
      expect(
        projectedDate(
          currentKg: 80,
          targetKg: 75,
          paceKgPerWeek: 0.5,
          goal: GoalKind.maintain,
        ),
        isNull,
      );
    });
  });

  group('labels', () {
    test('formats the pace without trailing zeros', () {
      expect(formatPace(0.25), '0.25');
      expect(formatPace(0.5), '0.5');
      expect(formatPace(1.0), '1');
    });

    test('describes the pace in a word', () {
      expect(describePace(0.25), 'gentle');
      expect(describePace(0.5), 'steady');
      expect(describePace(0.75), 'brisk');
      expect(describePace(1.0), 'fast');
    });
  });
}
