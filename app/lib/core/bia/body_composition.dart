/// Turns one raw scale reading into a body-composition result that can be shown
/// to a user without lying to them.
///
/// Three rules are enforced here rather than left to the UI:
///
///  1. Every displayed number carries the equation that produced it and an
///     uncertainty band from that equation's published standard error.
///  2. Metrics with no scientific basis are not computed. Specifically there is
///     no `visceralFatRating` and no `metabolicAge` in this file. Visceral fat
///     from a foot-to-foot scale has no published algorithm and no validation;
///     metabolic age is a restatement of BMR against a population table. If the
///     product later needs them for parity with competitors, they belong behind
///     an explicit "unvalidated estimate" label, not in this engine.
///  3. Bone mass is computed but flagged [Derived.notMeasured], because bone
///     mineral is effectively invisible to a 50 kHz current — the value is a
///     fixed fraction of fat-free mass and will drift with weight, which users
///     misread as bone change.
library;

import 'equations.dart';

/// How much trust a single reading has earned.
enum ReadingConfidence {
  /// Impedance present, subject inside the equation's validated population,
  /// and the measurement protocol was followed.
  good,

  /// Usable, but something reduces trust: off-protocol timing, an impedance
  /// value near the edge of the plausible range, or a first reading with no
  /// history to compare against.
  fair,

  /// Weight is trustworthy; composition is not. Shown as weight-only.
  weightOnly,
}

/// Whether a field is a prediction from a published equation, or a fixed
/// fraction of another prediction dressed up as a measurement.
enum Derived {
  /// Output of a citable regression on measured impedance.
  predicted,

  /// A constant times another prediction. Carries no independent information.
  notMeasured,
}

class Metric {
  const Metric({
    required this.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.derived,
    this.equation,
    this.uncertainty,
    this.caveat,
  });

  final String key;
  final String label;
  final double value;
  final String unit;
  final Derived derived;
  final BiaEquation? equation;

  /// Plus-or-minus band in [unit]. Null when no published error exists.
  final double? uncertainty;

  /// One sentence the UI must show alongside the value when it is not a plain
  /// measurement.
  final String? caveat;

  /// Formatted for display. Deliberately low precision: a foot-to-foot scale
  /// reporting body fat to two decimal places is claiming a precision it does
  /// not have.
  String get display {
    final decimals = unit == '%' ? 1 : (value >= 100 ? 0 : 1);
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  String? get uncertaintyDisplay {
    final u = uncertainty;
    if (u == null) return null;
    return '±${u.toStringAsFixed(u >= 10 ? 0 : 1)} $unit';
  }
}

class BodyCompositionResult {
  const BodyCompositionResult({
    required this.takenAt,
    required this.weightKg,
    required this.confidence,
    required this.metrics,
    required this.notes,
    this.impedanceOhm,
    this.context = const MeasurementContext(),
  });

  final DateTime takenAt;
  final double weightKg;
  final double? impedanceOhm;
  final ReadingConfidence confidence;
  final List<Metric> metrics;

  /// Human-readable reasons the confidence is what it is. Shown verbatim.
  final List<String> notes;

  /// The conditions this was evaluated under. Carried with the result so
  /// storage cannot be handed a result and a context that disagree.
  final MeasurementContext context;

  Metric? metric(String key) {
    for (final m in metrics) {
      if (m.key == key) return m;
    }
    return null;
  }
}

/// Conditions the user reported (or the app inferred) at the time of the
/// reading. BIA measures water and infers everything else from it, so these
/// materially change what the number means.
///
/// Absence of information is not evidence of a bad reading. A field the user
/// was never asked about must not downgrade confidence, which is why
/// [morningFasted] is tri-state: null means "not reported", and only an
/// explicit `false` counts against the reading.
class MeasurementContext {
  const MeasurementContext({
    this.morningFasted,
    this.afterExercise = false,
    this.afterAlcohol = false,
    this.hoursSinceLastMeal,
  });

  /// True if the user confirmed a fasted morning reading, false if they said it
  /// was not, null if nobody asked.
  final bool? morningFasted;
  final bool afterExercise;
  final bool afterAlcohol;
  final double? hoursSinceLastMeal;

  bool get offProtocol =>
      afterExercise || afterAlcohol || morningFasted == false;
}

/// Plausible whole-body resistance for an adult at 50 kHz. Outside this, the
/// electrodes almost certainly did not make proper contact.
const double _minPlausibleOhm = 200;
const double _maxPlausibleOhm = 1200;

class BodyCompositionEngine {
  const BodyCompositionEngine();

  BodyCompositionResult evaluate({
    required BiaInput input,
    required DateTime takenAt,
    MeasurementContext context = const MeasurementContext(),
  }) {
    final notes = <String>[];
    final metrics = <Metric>[
      Metric(
        key: 'weight',
        label: 'Weight',
        value: input.weightKg,
        unit: 'kg',
        derived: Derived.predicted,
        uncertainty: 0.1,
      ),
      Metric(
        key: 'bmi',
        label: 'BMI',
        value: input.bmi,
        unit: '',
        derived: Derived.predicted,
      ),
    ];

    final r = input.resistanceOhm;
    final impedanceUsable =
        r != null && r >= _minPlausibleOhm && r <= _maxPlausibleOhm;

    if (r != null && !impedanceUsable) {
      notes.add(
        'The scale reported an impedance of ${r.toStringAsFixed(0)} Ω, which is '
        'outside the range a normal adult measurement produces. This usually '
        'means socks, tights, very dry skin, or feet not covering all four '
        'contacts. Weight is still accurate.',
      );
    }

    if (!impedanceUsable) {
      // No usable impedance. Fall back to the BMI-only fat estimate, which is a
      // population regression and is labelled as such.
      final bmiFat = bodyFatPercentFromBmi(input);
      if (bmiFat.inBounds) {
        metrics.add(
          Metric(
            key: 'bodyFatPercent',
            label: 'Body fat (estimated)',
            value: clampPhysiological(bmiFat.value, 3, 70),
            unit: '%',
            derived: Derived.notMeasured,
            equation: bmiFat.equation,
            uncertainty: bmiFat.standardError,
            caveat: 'Estimated from height, weight, age and sex only — no body '
                'measurement was taken. Two people with the same BMI get the same '
                'number.',
          ),
        );
      }
      if (r == null) {
        notes.add(
          'No impedance was recorded, so only weight and BMI are shown.',
        );
      }
      return BodyCompositionResult(
        takenAt: takenAt,
        weightKg: input.weightKg,
        impedanceOhm: r,
        confidence: ReadingConfidence.weightOnly,
        metrics: metrics,
        notes: notes,
        context: context,
      );
    }

    // --- Fat-free mass: prefer Kyle when reactance exists, else Sun. ---------
    final Prediction ffm;
    if (input.hasReactance) {
      final kyle = ffmKyle2001(input);
      if (kyle.inBounds) {
        ffm = kyle;
      } else {
        ffm = ffmSun2003(input);
        notes.add(
          'Using the Sun (2003) equation: this reading falls outside the '
          'population the more precise Kyle (2001) equation was validated on '
          '(BMI 17–34, age 20–94).',
        );
      }
    } else {
      ffm = ffmSun2003(input);
    }

    if (!ffm.inBounds) {
      notes.add(
        'You are outside the age or size range this equation was validated on, '
        'so treat the composition numbers as a trend indicator only.',
      );
    }

    final ffmKg = clampPhysiological(ffm.value, 15, 120);

    metrics.add(
      Metric(
        key: 'fatFreeMass',
        label: 'Fat-free mass',
        value: ffmKg,
        unit: 'kg',
        derived: Derived.predicted,
        equation: ffm.equation,
        uncertainty: ffm.standardError,
      ),
    );

    final fatPercent = clampPhysiological(
      bodyFatPercentFromFfm(weightKg: input.weightKg, ffmKg: ffmKg),
      3,
      70,
    );

    // Convert the FFM standard error into a body-fat percentage band. An error
    // of X kg in fat-free mass is an error of X kg in fat mass, because the two
    // sum to a weight we measured directly.
    final fatPercentBand = (ffm.standardError / input.weightKg) * 100.0;

    metrics.add(
      Metric(
        key: 'bodyFatPercent',
        label: 'Body fat',
        value: fatPercent,
        unit: '%',
        derived: Derived.predicted,
        equation: ffm.equation,
        uncertainty: fatPercentBand,
        caveat:
            'Bioimpedance is reliable for tracking change over weeks, not for '
            'a single absolute figure.',
      ),
    );

    metrics.add(
      Metric(
        key: 'fatMass',
        label: 'Fat mass',
        value: clampPhysiological(input.weightKg - ffmKg, 0, 200),
        unit: 'kg',
        derived: Derived.predicted,
        equation: ffm.equation,
        uncertainty: ffm.standardError,
      ),
    );

    // --- Total body water ---------------------------------------------------
    final tbw = tbwSun2003(input);
    metrics.add(
      Metric(
        key: 'totalBodyWater',
        label: 'Body water',
        value: clampPhysiological(tbw, 10, 80),
        unit: 'L',
        derived: Derived.predicted,
        equation: BiaEquation.sun2003,
        uncertainty: input.sex == Sex.male ? 3.8 : 2.6,
        caveat: 'Body water and fat-free mass are two views of the same '
            'measurement, so they always move together.',
      ),
    );

    // --- Skeletal muscle ----------------------------------------------------
    final smm = skeletalMuscleJanssen2000(input);
    metrics.add(
      Metric(
        key: 'skeletalMuscleMass',
        label: 'Skeletal muscle',
        value: clampPhysiological(smm.value, 10, 70),
        unit: 'kg',
        derived: Derived.predicted,
        equation: smm.equation,
        uncertainty: smm.standardError,
        caveat:
            'Validated against MRI. This is skeletal muscle only — lower than '
            'the "muscle mass" most scales report, which includes organs and '
            'connective tissue.',
      ),
    );

    // --- Bone: computed for completeness, labelled as not measured ----------
    final boneFraction = input.sex == Sex.male ? 0.057 : 0.050;
    metrics.add(
      Metric(
        key: 'boneMass',
        label: 'Bone mass',
        value: ffmKg * boneFraction,
        unit: 'kg',
        derived: Derived.notMeasured,
        caveat:
            'Bone does not conduct the measurement current, so this is a fixed '
            'proportion of your fat-free mass rather than a reading. It will move '
            'when your weight moves; that is not bone change.',
      ),
    );

    // --- Energy -------------------------------------------------------------
    final rmr = rmrCunningham1980(ffmKg);
    metrics.add(
      Metric(
        key: 'restingEnergy',
        label: 'Resting energy',
        value: rmr.value,
        unit: 'kcal/day',
        derived: Derived.predicted,
        equation: rmr.equation,
        uncertainty: rmr.standardError,
      ),
    );

    // --- Confidence ---------------------------------------------------------
    var confidence = ReadingConfidence.good;
    if (context.offProtocol) {
      confidence = ReadingConfidence.fair;
      if (context.afterExercise) {
        notes.add(
          'Taken after exercise. Sweat loss lowers body water, which makes body '
          'fat read higher than it is.',
        );
      }
      if (context.afterAlcohol) {
        notes.add(
          'Taken within a day of alcohol, which shifts body water and therefore '
          'the composition numbers.',
        );
      }
      if (context.morningFasted == false) {
        notes.add(
          'For comparable readings, weigh first thing in the morning, after the '
          'toilet and before eating or drinking.',
        );
      }
    }
    if (!ffm.inBounds) confidence = ReadingConfidence.fair;

    return BodyCompositionResult(
      takenAt: takenAt,
      weightKg: input.weightKg,
      impedanceOhm: r,
      confidence: confidence,
      metrics: metrics,
      notes: notes,
      context: context,
    );
  }
}

/// Smoothing over a series of readings.
///
/// Published limits of agreement for foot-to-foot BIA against a reference method
/// run to roughly ±6 kg of fat mass at the individual level, while between-day
/// repeatability under controlled conditions is well under 1 kg. In other words
/// the noise is small and the bias is large — which is exactly the situation
/// where a trend is informative and a single reading is not.
///
/// The app therefore leads with a rolling median and shows today's raw value
/// underneath it.
class TrendSmoother {
  const TrendSmoother({this.windowDays = 7});

  final int windowDays;

  /// Rolling median of [values] whose timestamps fall within [windowDays] of
  /// [asOf]. Median rather than mean so one bad-contact reading cannot drag the
  /// line.
  double? rollingMedian(
    List<({DateTime at, double value})> series, {
    required DateTime asOf,
  }) {
    final cutoff = asOf.subtract(Duration(days: windowDays));
    final window = series
        .where((e) => e.at.isAfter(cutoff) && !e.at.isAfter(asOf))
        .map((e) => e.value)
        .toList()
      ..sort();
    if (window.isEmpty) return null;
    final mid = window.length ~/ 2;
    if (window.length.isOdd) return window[mid];
    return (window[mid - 1] + window[mid]) / 2.0;
  }

  /// Change per week, fitted by least squares over the window. Returns null when
  /// there are too few points for the slope to mean anything.
  double? weeklyRate(
    List<({DateTime at, double value})> series, {
    required DateTime asOf,
    int minPoints = 4,
  }) {
    final cutoff = asOf.subtract(Duration(days: windowDays));
    final window = series
        .where((e) => e.at.isAfter(cutoff) && !e.at.isAfter(asOf))
        .toList();
    if (window.length < minPoints) return null;

    final t0 = window.first.at.millisecondsSinceEpoch.toDouble();
    const msPerWeek = 7 * 24 * 60 * 60 * 1000.0;

    var sumX = 0.0, sumY = 0.0, sumXy = 0.0, sumXx = 0.0;
    for (final p in window) {
      final x = (p.at.millisecondsSinceEpoch.toDouble() - t0) / msPerWeek;
      final y = p.value;
      sumX += x;
      sumY += y;
      sumXy += x * y;
      sumXx += x * x;
    }
    final n = window.length.toDouble();
    final denom = n * sumXx - sumX * sumX;
    if (denom.abs() < 1e-9) return null;
    return (n * sumXy - sumX * sumY) / denom;
  }
}
