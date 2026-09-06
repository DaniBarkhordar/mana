import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';

/// These tests are the reason the equations live in their own library.
///
/// Every expected value below is computed by hand from the published
/// coefficients, so a typo in a coefficient fails a test rather than silently
/// shipping a wrong body-fat percentage to every user.
void main() {
  const subject = BiaInput(
    heightCm: 178,
    weightKg: 80,
    ageYears: 34,
    sex: Sex.male,
    resistanceOhm: 500,
  );

  group('resistance index', () {
    test('is height squared over resistance', () {
      // 178^2 / 500 = 31684 / 500 = 63.368
      expect(subject.resistanceIndex, closeTo(63.368, 0.001));
    });

    test('throws rather than returning a nonsense value with no impedance', () {
      const noImpedance = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
      );
      expect(() => noImpedance.resistanceIndex, throwsStateError);
    });
  });

  group('Sun 2003 fat-free mass', () {
    test('male coefficients', () {
      // -10.68 + 0.65(63.368) + 0.26(80) + 0.02(500)
      //  = -10.68 + 41.1892 + 20.8 + 10 = 61.3092
      expect(ffmSun2003(subject).value, closeTo(61.3092, 0.001));
    });

    test('female coefficients differ', () {
      const female = BiaInput(
        heightCm: 165,
        weightKg: 65,
        ageYears: 30,
        sex: Sex.female,
        resistanceOhm: 600,
      );
      // ri = 165^2/600 = 27225/600 = 45.375
      // -9.53 + 0.69(45.375) + 0.17(65) + 0.02(600)
      //  = -9.53 + 31.30875 + 11.05 + 12 = 44.82875
      expect(ffmSun2003(female).value, closeTo(44.82875, 0.001));
    });

    test('reports the published standard error, not a made-up one', () {
      expect(ffmSun2003(subject).standardError, 3.9);
    });

    test('flags a 10-year-old as outside the validated age range', () {
      const child = BiaInput(
        heightCm: 140,
        weightKg: 32,
        ageYears: 10,
        sex: Sex.male,
        resistanceOhm: 700,
      );
      expect(ffmSun2003(child).inBounds, isFalse);
    });
  });

  group('Kyle 2001', () {
    test('refuses to run without reactance rather than inventing one', () {
      expect(() => ffmKyle2001(subject), throwsStateError);
    });

    test('male coefficients', () {
      const withXc = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
        resistanceOhm: 500,
        reactanceOhm: 55,
      );
      // -4.104 + 0.518(63.368) + 0.231(80) + 0.130(55) + 4.229
      //  = -4.104 + 32.824624 + 18.48 + 7.15 + 4.229 = 58.579624
      expect(ffmKyle2001(withXc).value, closeTo(58.5796, 0.001));
    });

    test('is out of bounds above its published BMI ceiling of 33.8', () {
      const obese = BiaInput(
        heightCm: 170,
        weightKg: 110, // BMI 38.1
        ageYears: 40,
        sex: Sex.male,
        resistanceOhm: 450,
        reactanceOhm: 50,
      );
      expect(ffmKyle2001(obese).inBounds, isFalse);
    });
  });

  group('Deurenberg 1991', () {
    test('BIA form', () {
      // -12.44 + 0.34(63.368) + 0.1534(178) + 0.273(80) - 0.127(34) + 4.56
      //  = -12.44 + 21.54512 + 27.3052 + 21.84 - 4.318 + 4.56 = 58.49232
      expect(ffmDeurenberg1991(subject).value, closeTo(58.4923, 0.001));
    });

    test('BMI form for an adult', () {
      // BMI = 80 / 1.78^2 = 80 / 3.1684 = 25.2493...
      // 1.20(25.2493) + 0.23(34) - 10.8(1) - 5.4
      //  = 30.29916 + 7.82 - 10.8 - 5.4 = 21.91916
      final p = bodyFatPercentFromBmi(subject);
      expect(p.value, closeTo(21.9192, 0.01));
      expect(p.inBounds, isTrue);
    });

    test('never marks the child equation as displayable', () {
      const child = BiaInput(
        heightCm: 150,
        weightKg: 42,
        ageYears: 12,
        sex: Sex.female,
      );
      final p = bodyFatPercentFromBmi(child);
      // The child equation explains only 38% of variance. It may be computed
      // for population work; it must never be shown to an individual.
      expect(p.inBounds, isFalse);
    });
  });

  group('body fat from fat-free mass', () {
    test('is the complement of fat-free mass over weight', () {
      expect(
        bodyFatPercentFromFfm(weightKg: 80, ffmKg: 60),
        closeTo(25.0, 1e-9),
      );
    });
  });

  group('total body water', () {
    test('Sun 2003 male', () {
      // 1.20 + 0.45(63.368) + 0.18(80) = 1.20 + 28.5156 + 14.4 = 44.1156
      expect(tbwSun2003(subject), closeTo(44.1156, 0.001));
    });

    test('the 73.2% fallback matches the standard hydration constant', () {
      expect(tbwFromFfm(60), closeTo(43.92, 1e-9));
    });
  });

  group('Janssen 2000 skeletal muscle', () {
    test('coefficients, with the age term negative', () {
      // 0.401(63.368) + 3.825(1) - 0.071(34) + 5.102
      //  = 25.410568 + 3.825 - 2.414 + 5.102 = 31.923568
      expect(
        skeletalMuscleJanssen2000(subject).value,
        closeTo(31.9236, 0.001),
      );
    });

    test('produces a lower figure than fat-free mass', () {
      // The distinction the whole industry blurs: skeletal muscle is not lean
      // soft tissue. If this ever inverts, the labelling is lying.
      expect(
        skeletalMuscleJanssen2000(subject).value,
        lessThan(ffmSun2003(subject).value),
      );
    });
  });

  group('energy', () {
    test('Mifflin-St Jeor, published combined form', () {
      // 9.99(80) + 6.25(178) - 4.92(34) + 166 - 161
      //  = 799.2 + 1112.5 - 167.28 + 5 = 1749.42
      expect(bmrMifflinStJeor(subject).value, closeTo(1749.42, 0.01));
    });

    test('Cunningham 1980 from fat-free mass', () {
      expect(rmrCunningham1980(60).value, closeTo(1820, 1e-9));
    });

    test('activity multipliers come from the DRI bands, not fitness lore', () {
      // The conventional 1.2/1.375/1.55/1.725/1.9 ladder has no primary source.
      expect(ActivityLevel.inactive.pal, 1.35);
      expect(ActivityLevel.veryActive.pal, 2.20);
      expect(
        tdee(restingKcal: 1800, activity: ActivityLevel.active),
        closeTo(3330, 1e-9),
      );
    });
  });

  group('BodyCompositionEngine', () {
    const engine = BodyCompositionEngine();
    final now = DateTime(2026, 8, 25, 7, 15);

    test('produces a full result for a good reading', () {
      final r = engine.evaluate(input: subject, takenAt: now);
      expect(r.confidence, ReadingConfidence.good);
      expect(r.metric('bodyFatPercent'), isNotNull);
      expect(r.metric('skeletalMuscleMass'), isNotNull);
      expect(r.metric('restingEnergy'), isNotNull);
    });

    test('never invents visceral fat or metabolic age', () {
      final r = engine.evaluate(input: subject, takenAt: now);
      // Neither has a published algorithm or any validation for a foot-to-foot
      // scale. Competitors print them anyway; we do not.
      expect(r.metric('visceralFat'), isNull);
      expect(r.metric('metabolicAge'), isNull);
    });

    test('labels bone mass as not measured', () {
      final r = engine.evaluate(input: subject, takenAt: now);
      final bone = r.metric('boneMass')!;
      expect(bone.derived, Derived.notMeasured);
      expect(bone.caveat, isNotNull);
    });

    test('falls back to weight-only when impedance is implausible', () {
      const badContact = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
        resistanceOhm: 45, // far below any real adult reading
      );
      final r = engine.evaluate(input: badContact, takenAt: now);
      expect(r.confidence, ReadingConfidence.weightOnly);
      expect(r.metric('fatFreeMass'), isNull);
      expect(r.notes.join(' '), contains('socks'));
    });

    test('weight-only still reports weight and BMI', () {
      const noImpedance = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
      );
      final r = engine.evaluate(input: noImpedance, takenAt: now);
      expect(r.metric('weight')!.value, 80);
      expect(r.metric('bmi'), isNotNull);
      expect(r.confidence, ReadingConfidence.weightOnly);
    });

    test('downgrades confidence and explains why when off-protocol', () {
      final r = engine.evaluate(
        input: subject,
        takenAt: now,
        context: const MeasurementContext(afterExercise: true),
      );
      expect(r.confidence, ReadingConfidence.fair);
      expect(r.notes.join(' ').toLowerCase(), contains('sweat'));
    });

    test('prefers Kyle when reactance is available and in bounds', () {
      const eightElectrode = BiaInput(
        heightCm: 178,
        weightKg: 80,
        ageYears: 34,
        sex: Sex.male,
        resistanceOhm: 500,
        reactanceOhm: 55,
      );
      final r = engine.evaluate(input: eightElectrode, takenAt: now);
      expect(r.metric('fatFreeMass')!.equation, BiaEquation.kyle2001);
    });

    test('falls back to Sun when Kyle is out of bounds', () {
      const obeseWithXc = BiaInput(
        heightCm: 170,
        weightKg: 110,
        ageYears: 40,
        sex: Sex.male,
        resistanceOhm: 450,
        reactanceOhm: 50,
      );
      final r = engine.evaluate(input: obeseWithXc, takenAt: now);
      expect(r.metric('fatFreeMass')!.equation, BiaEquation.sun2003);
      expect(r.notes.join(' '), contains('Sun'));
    });
  });

  group('TrendSmoother', () {
    const smoother = TrendSmoother();
    final asOf = DateTime(2026, 8, 25);

    test('median ignores a single bad-contact outlier', () {
      final series = [
        (at: asOf.subtract(const Duration(days: 5)), value: 22.0),
        (at: asOf.subtract(const Duration(days: 4)), value: 22.3),
        (at: asOf.subtract(const Duration(days: 3)), value: 41.0), // outlier
        (at: asOf.subtract(const Duration(days: 2)), value: 22.1),
        (at: asOf.subtract(const Duration(days: 1)), value: 22.4),
      ];
      final median = smoother.rollingMedian(series, asOf: asOf)!;
      // A mean would be dragged to 26. The median is not.
      expect(median, closeTo(22.3, 0.001));
    });

    test('returns null with nothing in the window', () {
      final old = [
        (at: asOf.subtract(const Duration(days: 60)), value: 22.0),
      ];
      expect(smoother.rollingMedian(old, asOf: asOf), isNull);
    });

    test('weekly rate fits a clean downward slope', () {
      final series = [
        (at: asOf.subtract(const Duration(days: 21)), value: 82.0),
        (at: asOf.subtract(const Duration(days: 14)), value: 81.5),
        (at: asOf.subtract(const Duration(days: 7)), value: 81.0),
        (at: asOf, value: 80.5),
      ];
      final rate =
          const TrendSmoother(windowDays: 30).weeklyRate(series, asOf: asOf)!;
      expect(rate, closeTo(-0.5, 0.01));
    });

    test('refuses to fit a slope from too few points', () {
      final series = [
        (at: asOf.subtract(const Duration(days: 2)), value: 82.0),
        (at: asOf, value: 81.0),
      ];
      expect(smoother.weeklyRate(series, asOf: asOf), isNull);
    });
  });
}
