/// Published bioelectrical-impedance prediction equations.
///
/// Every equation here is a transcription of a citable paper. Coefficients are
/// NOT tuned, adjusted or invented. Where a paper states a validity range, it is
/// encoded in [EquationBounds] and enforced by the caller, not silently ignored.
///
/// Conventions used throughout (these match the source papers — do not change
/// them without re-checking every equation):
///   height  : centimetres
///   weight  : kilograms
///   age     : years
///   R (resistance) and Xc (reactance) : ohms, measured at 50 kHz
///   sex     : male = 1, female = 0
///
/// The single recurring term is the *resistance index*, height^2 / R.
library;

import 'dart:math' as math;

/// Biological sex as required by the regression equations.
///
/// This is a measurement input, not an identity field. The equations were fitted
/// on binary-coded populations; there is no published coefficient for anything
/// else. Where a user does not supply this, the caller must fall back to a
/// non-impedance estimate rather than guessing a value.
enum Sex {
  male(1),
  female(0);

  const Sex(this.code);

  /// The 0/1 coding used by every equation in this file.
  final int code;
}

/// Which published equation produced a value, so it can be surfaced to the user
/// and logged alongside the stored measurement.
enum BiaEquation {
  sun2003('Sun et al. 2003 (NHANES III)'),
  kyle2001('Kyle et al. 2001 (Geneva)'),
  deurenberg1991Bia('Deurenberg et al. 1991 (BIA)'),
  deurenberg1991Bmi('Deurenberg et al. 1991 (BMI, no impedance)'),
  janssen2000('Janssen et al. 2000'),
  cunningham1980('Cunningham 1980'),
  mifflinStJeor1990('Mifflin-St Jeor 1990');

  const BiaEquation(this.citation);

  final String citation;
}

/// The validity envelope a paper reported for its own equation.
///
/// Applying a regression outside the population it was fitted on is the most
/// common way consumer scales produce nonsense, so this is enforced rather than
/// documented.
class EquationBounds {
  const EquationBounds({
    required this.minAge,
    required this.maxAge,
    this.minBmi,
    this.maxBmi,
  });

  final int minAge;
  final int maxAge;
  final double? minBmi;
  final double? maxBmi;

  bool covers({required int age, required double bmi}) {
    if (age < minAge || age > maxAge) return false;
    if (minBmi != null && bmi < minBmi!) return false;
    if (maxBmi != null && bmi > maxBmi!) return false;
    return true;
  }
}

/// Inputs shared by every equation.
class BiaInput {
  const BiaInput({
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
    this.resistanceOhm,
    this.reactanceOhm,
  });

  final double heightCm;
  final double weightKg;
  final int ageYears;
  final Sex sex;

  /// Whole-body resistance at 50 kHz, in ohms. Null when the scale reported no
  /// usable impedance (bare feet not detected, socks, dry skin, or the user
  /// disabled impedance measurement).
  final double? resistanceOhm;

  /// Reactance at 50 kHz, in ohms. Only phase-sensitive 8-electrode hardware
  /// reports this. Required by Kyle 2001 and by nothing else here.
  final double? reactanceOhm;

  double get bmi {
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  /// height^2 / R — the term every impedance equation is built on.
  double get resistanceIndex {
    final r = resistanceOhm;
    if (r == null || r <= 0) {
      throw StateError('resistanceIndex requires a positive resistance');
    }
    return (heightCm * heightCm) / r;
  }

  bool get hasImpedance => resistanceOhm != null && resistanceOhm! > 0;
  bool get hasReactance => reactanceOhm != null && reactanceOhm! > 0;
}

/// A predicted value plus the provenance and uncertainty needed to display it
/// honestly.
class Prediction {
  const Prediction({
    required this.value,
    required this.equation,
    required this.standardError,
    required this.inBounds,
  });

  final double value;

  final BiaEquation equation;

  /// Standard error of the estimate reported by the source paper, in the same
  /// unit as [value]. This is the number that drives the uncertainty band in the
  /// UI; it is a property of the published equation, not of this measurement.
  final double standardError;

  /// False when the subject falls outside the population the equation was fitted
  /// on. The value is still returned so it can be logged, but it must not be
  /// shown to the user as a result.
  final bool inBounds;

  Prediction copyWith({double? value}) => Prediction(
        value: value ?? this.value,
        equation: equation,
        standardError: standardError,
        inBounds: inBounds,
      );
}

// ---------------------------------------------------------------------------
// Fat-free mass
// ---------------------------------------------------------------------------

/// Sun et al. 2003, Am J Clin Nutr 77:331-340. NHANES III, n = 1830, ages 12-94,
/// multi-ethnic, four-compartment reference model, 50 kHz.
///
/// This is the default. It needs only resistance, height, weight and sex —
/// exactly what a foot-to-foot scale can supply — and it has the widest
/// validated age range of the three.
///
/// RMSE: 3.9 kg (men), 2.9 kg (women).
const sun2003Bounds = EquationBounds(minAge: 12, maxAge: 94);

Prediction ffmSun2003(BiaInput i) {
  final ri = i.resistanceIndex;
  final r = i.resistanceOhm!;
  final value = i.sex == Sex.male
      ? -10.68 + 0.65 * ri + 0.26 * i.weightKg + 0.02 * r
      : -9.53 + 0.69 * ri + 0.17 * i.weightKg + 0.02 * r;
  return Prediction(
    value: value,
    equation: BiaEquation.sun2003,
    standardError: i.sex == Sex.male ? 3.9 : 2.9,
    inBounds: sun2003Bounds.covers(age: i.ageYears, bmi: i.bmi),
  );
}

/// Kyle et al. 2001, Nutrition 17:248-253. n = 343, ages 20-94, DXA reference.
///
/// The most accurate of the three (SEE 1.72 kg) but it requires reactance, which
/// only phase-sensitive 8-electrode hardware reports, and it degrades badly above
/// BMI ~34 because that is where its sample stopped.
const kyle2001Bounds =
    EquationBounds(minAge: 20, maxAge: 94, minBmi: 17.0, maxBmi: 33.8);

Prediction ffmKyle2001(BiaInput i) {
  if (!i.hasReactance) {
    throw StateError('Kyle 2001 requires reactance (Xc); use Sun 2003 instead');
  }
  final value = -4.104 +
      0.518 * i.resistanceIndex +
      0.231 * i.weightKg +
      0.130 * i.reactanceOhm! +
      4.229 * i.sex.code;
  return Prediction(
    value: value,
    equation: BiaEquation.kyle2001,
    standardError: 1.72,
    inBounds: kyle2001Bounds.covers(age: i.ageYears, bmi: i.bmi),
  );
}

/// Deurenberg et al. 1991, Int J Obes 15:17-25. n = 661, ages 7-83,
/// densitometry reference. SEE 2.63 kg.
///
/// Kept as an ensemble member and as the only equation here that spans
/// childhood.
const deurenberg1991BiaBounds = EquationBounds(minAge: 7, maxAge: 83);

Prediction ffmDeurenberg1991(BiaInput i) {
  final value = -12.44 +
      0.34 * i.resistanceIndex +
      0.1534 * i.heightCm +
      0.273 * i.weightKg -
      0.127 * i.ageYears +
      4.56 * i.sex.code;
  return Prediction(
    value: value,
    equation: BiaEquation.deurenberg1991Bia,
    standardError: 2.63,
    inBounds: deurenberg1991BiaBounds.covers(age: i.ageYears, bmi: i.bmi),
  );
}

// ---------------------------------------------------------------------------
// Body fat
// ---------------------------------------------------------------------------

/// Body fat percentage derived from fat-free mass.
double bodyFatPercentFromFfm({
  required double weightKg,
  required double ffmKg,
}) {
  if (weightKg <= 0) return 0;
  return ((weightKg - ffmKg) / weightKg) * 100.0;
}

/// Deurenberg et al. 1991, Br J Nutr 65:105-114 — body fat from BMI alone.
///
/// The fallback when there is no usable impedance at all. It is a population
/// regression on age, sex and BMI: it knows nothing about this particular body,
/// and it slightly overestimates fat in obese subjects (the paper says so).
///
/// The child form (age <= 15) explains only 38% of variance and must never be
/// surfaced to an individual — see [bodyFatPercentFromBmi]'s [inBounds] flag,
/// which is false for anyone under 16 for exactly this reason.
Prediction bodyFatPercentFromBmi(BiaInput i) {
  final bmi = i.bmi;
  final adult = i.ageYears > 15;
  final value = adult
      ? 1.20 * bmi + 0.23 * i.ageYears - 10.8 * i.sex.code - 5.4
      : 1.51 * bmi - 0.70 * i.ageYears - 3.6 * i.sex.code + 1.4;
  return Prediction(
    value: value,
    equation: BiaEquation.deurenberg1991Bmi,
    standardError: adult ? 4.1 : 4.4,
    // The child equation is population-level only (R^2 = 0.38). Never display.
    inBounds: adult,
  );
}

// ---------------------------------------------------------------------------
// Total body water
// ---------------------------------------------------------------------------

/// Sun et al. 2003 total body water, litres. Same cohort as [ffmSun2003].
/// MSE 3.8 L (men), 2.6 L (women).
double tbwSun2003(BiaInput i) {
  final ri = i.resistanceIndex;
  return i.sex == Sex.male
      ? 1.20 + 0.45 * ri + 0.18 * i.weightKg
      : 3.75 + 0.45 * ri + 0.11 * i.weightKg;
}

/// The standard hydration assumption: fat-free mass is 73.2% water.
/// Used only when there is no impedance to run [tbwSun2003] on.
double tbwFromFfm(double ffmKg) => 0.732 * ffmKg;

// ---------------------------------------------------------------------------
// Skeletal muscle
// ---------------------------------------------------------------------------

/// Janssen et al. 2000, J Appl Physiol 89:465-471. Whole-body skeletal muscle
/// mass in kg, validated against MRI. SEE 2.7 kg (9%).
///
/// This is the only defensible "muscle" number obtainable from a scale. It is
/// NOT the same quantity as the "muscle mass" consumer scales print, which is
/// almost always fat-free mass minus a bone constant — a larger number
/// describing lean soft tissue, not muscle.
Prediction skeletalMuscleJanssen2000(BiaInput i) {
  final value = 0.401 * i.resistanceIndex +
      3.825 * i.sex.code -
      0.071 * i.ageYears +
      5.102;
  return Prediction(
    value: value,
    equation: BiaEquation.janssen2000,
    standardError: 2.7,
    inBounds: i.ageYears >= 18 && i.ageYears <= 86,
  );
}

// ---------------------------------------------------------------------------
// Energy expenditure
// ---------------------------------------------------------------------------

/// Mifflin-St Jeor 1990, Am J Clin Nutr 51:241-247. Resting energy expenditure
/// in kcal/day from anthropometry alone. n = 498, ages 19-78, R^2 = 0.71.
///
/// This is the original published combined form. The commonly quoted split form
/// (10*W + 6.25*H - 5*A + 5 / -161) is a rounding of it and differs by a few
/// kcal; we use the published one.
Prediction bmrMifflinStJeor(BiaInput i) {
  final value = 9.99 * i.weightKg +
      6.25 * i.heightCm -
      4.92 * i.ageYears +
      166 * i.sex.code -
      161;
  return Prediction(
    value: value,
    equation: BiaEquation.mifflinStJeor1990,
    // The paper reports ~10% individual variation; no single SEE is published
    // in kcal, so this is the conventional read of its reported dispersion.
    standardError: value * 0.10,
    inBounds: i.ageYears >= 19 && i.ageYears <= 78,
  );
}

/// Cunningham 1980, resting metabolic rate from fat-free mass.
///
/// Preferred over Katch-McArdle (370 + 21.6 * LBM), which appears only in a
/// textbook and has no primary validation paper. Use this whenever a usable FFM
/// is available, because an FFM-based estimate outperforms an anthropometric one
/// in lean and in very muscular subjects.
Prediction rmrCunningham1980(double ffmKg) => Prediction(
      value: 500 + 22 * ffmKg,
      equation: BiaEquation.cunningham1980,
      standardError: 0.10 * (500 + 22 * ffmKg),
      inBounds: ffmKg > 20 && ffmKg < 120,
    );

/// Physical activity level bands from the NASEM 2023 Dietary Reference Intakes
/// for Energy, chapter 7 — derived from doubly-labelled-water studies.
///
/// Deliberately used in preference to the conventional 1.2/1.375/1.55/1.725/1.9
/// fitness multipliers, which have no primary source. Values are band midpoints.
enum ActivityLevel {
  inactive('Inactive', 1.35, 'Desk work, little deliberate activity'),
  lowActive('Low active', 1.65, 'Light activity most days'),
  active('Active', 1.85, 'Daily training or a physical job'),
  veryActive('Very active', 2.20, 'Hard training most days');

  const ActivityLevel(this.label, this.pal, this.description);

  final String label;

  /// Physical activity level: TDEE = RMR * pal.
  final double pal;
  final String description;
}

double tdee({required double restingKcal, required ActivityLevel activity}) =>
    restingKcal * activity.pal;

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Clamp a predicted value into a physiologically possible range.
///
/// Regressions are linear and will happily return a negative fat mass for an
/// extremely lean subject or an impossible one for a bad impedance reading. We
/// clamp rather than reject so the trend survives a single odd sample, and the
/// caller marks the reading low-confidence.
double clampPhysiological(double value, double min, double max) =>
    math.min(math.max(value, min), max);
