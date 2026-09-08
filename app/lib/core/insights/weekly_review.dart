/// The weekly review: one week of a person's own data, folded into a handful
/// of sentences they can read in the time it takes the kettle to boil.
///
/// Pure Dart, no Flutter. Everything here is a fold over rows that already
/// exist — meals, scale readings, wearable observations — so it can be
/// checked by hand (see test/insights/weekly_review_test.dart) and the
/// provider underneath only wires it to SQLite streams.
///
/// Three things the sentences never do, and a test enforces: they never say a
/// behaviour *caused* a number, never name a health outcome, and never quote
/// an accuracy percentage. A weekly review is a mirror, not a verdict.
library;

import '../bia/body_composition.dart';
import '../data/models.dart';
import '../nutrition/portion.dart';

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

/// Local midnight of [t].
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Midnight on the Monday of the ISO week containing [day].
DateTime isoWeekStart(DateTime day) {
  final midnight = dayOf(day);
  return midnight.subtract(Duration(days: midnight.weekday - 1));
}

/// ISO 8601 week number: weeks start on Monday and week 1 is the week that
/// contains the year's first Thursday. Computed by finding the Thursday of
/// [day]'s week and counting from the first of that Thursday's year, which is
/// the standard construction (ISO 8601:2004 §2.2.10).
int isoWeekNumber(DateTime day) {
  final midnight = dayOf(day);
  final thursday = midnight.add(Duration(days: 4 - midnight.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  return 1 + thursday.difference(jan1).inDays ~/ 7;
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// One wearable observation as the review needs it: what, how much, from
/// which store, and which device the store credited it to, if it named one.
class ObservationSample {
  const ObservationSample({
    required this.kind,
    required this.value,
    required this.unit,
    required this.source,
    required this.takenAt,
    this.deviceName,
  });

  final String kind;
  final double value;
  final String unit;

  /// The observation's source id: `apple_health`, `health_connect`, `diary`.
  final String source;

  /// The device the store attributed the value to ("Oura"), when it did.
  final String? deviceName;
  final DateTime takenAt;

  /// "Oura via Apple Health"; just "Apple Health" when the store did not name
  /// a device, or named itself. The same rule the `SourceBadge` uses.
  String get sourceText {
    final store = sourceLabel(source);
    final device = deviceName?.trim();
    if (device == null || device.isEmpty || device == store) return store;
    return '$device via $store';
  }
}

// ---------------------------------------------------------------------------
// Statistics
// ---------------------------------------------------------------------------

/// Median of [values]; null when empty. The mean of the middle pair for an
/// even count, as everywhere else in the app.
double? median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return null;
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

/// A week's median of one quantity against the week before, with the
/// instrument's noise floor deciding whether the difference is worth a word.
class WeeklyDelta {
  const WeeklyDelta({
    required this.thisWeek,
    required this.previousWeek,
    required this.thisWeekCount,
    required this.previousWeekCount,
    required this.noiseFloor,
  });

  /// Median over this week's readings; null with none.
  final double? thisWeek;

  /// Median over the previous week's readings; null with none.
  final double? previousWeek;
  final int thisWeekCount;
  final int previousWeekCount;

  /// The smallest difference between two medians that means more than the
  /// instrument repeating itself. In the quantity's own unit.
  final double noiseFloor;

  /// This week minus last, or null when either week has no readings.
  double? get delta => thisWeek == null || previousWeek == null
      ? null
      : thisWeek! - previousWeek!;

  /// True only when the two medians differ by more than [noiseFloor]. A
  /// change inside the floor is reported as no change — not as a small one.
  /// The tolerance is there because 78.4 − 78.7 is −0.3000000000000007 in a
  /// double, and a sentence must not turn on the last bit of a subtraction.
  bool get beyondNoise => delta != null && delta!.abs() > noiseFloor + 1e-9;
}

/// This week's median of a wearable kind against the three weeks before it.
class WearableMedian {
  const WearableMedian({
    required this.kind,
    required this.thisWeek,
    required this.baseline,
    required this.thisWeekCount,
    required this.baselineCount,
    required this.sourceText,
  });

  final String kind;
  final double thisWeek;

  /// Median over the previous three weeks; null until they hold a value.
  final double? baseline;
  final int thisWeekCount;
  final int baselineCount;

  /// "Oura via Apple Health" — the most recent observation's source.
  final String sourceText;

  double? get delta => baseline == null ? null : thisWeek - baseline!;
}

// ---------------------------------------------------------------------------
// The review
// ---------------------------------------------------------------------------

/// The review for one ISO week, as plain figures plus the sentences that
/// state them.
class WeeklyReview {
  const WeeklyReview({
    required this.weekStart,
    required this.weekNumber,
    required this.weighedShare,
    required this.weekKcal,
    required this.cookingFatG,
    required this.cookingFatKcal,
    required this.readingCount,
    required this.readingsBeforeTen,
    required this.weight,
    required this.bodyFat,
    required this.wearables,
    required this.streakDays,
    required this.daysLogged,
    required this.sentences,
  });

  /// Monday of the week under review.
  final DateTime weekStart;
  final int weekNumber;

  /// Share of this week's energy that was weighed, 0 to 1; null when nothing
  /// was logged. Straight from [MealTotals.weighedFraction], so the Energy
  /// card and the review can never disagree.
  final double? weighedShare;
  final double weekKcal;

  /// Cooking fat captured by weighing the pan, this week.
  final double cookingFatG;
  final double cookingFatKcal;

  /// Scale readings this week, and how many were taken before 10:00 local —
  /// the morning, fasted readings the trend is built to prefer.
  final int readingCount;
  final int readingsBeforeTen;

  final WeeklyDelta weight;

  /// Null when no reading this week or last carried a body-fat figure.
  final WeeklyDelta? bodyFat;

  /// Sleep, resting HR and HRV, whichever have data this week.
  final List<WearableMedian> wearables;

  /// Consecutive days with a meal logged, ending today or yesterday.
  final int streakDays;

  /// Days this week with at least one meal.
  final int daysLogged;

  /// The review in the product's voice, one fact per line.
  final List<String> sentences;

  /// What the review is derived from, for the DerivedNote under it: the
  /// larger of days logged and readings taken, in the unit that applies.
  ({int n, String unit}) get derivedFrom => readingCount > daysLogged
      ? (n: readingCount, unit: 'readings')
      : (n: daysLogged, unit: 'days');

  /// Consumer body scales are sold with a 0.1 kg graduation and a stated
  /// repeatability of ±0.2–0.3 kg between successive weighings of the same
  /// load; the vendor's own specification sheets for the platform this app
  /// ships with quote the upper figure, and third-party repeatability tests
  /// of consumer scales under ISO/IEC 17025-accredited conditions land in the
  /// same band. Two weekly medians closer than that are the scale repeating
  /// itself, not the body changing.
  static const weightNoiseKg = 0.3;

  /// Fallback noise floor for body fat, in percentage points, used when the
  /// readings do not carry the equation's own standard error. Between-day
  /// repeatability of foot-to-foot BIA under a controlled protocol is under
  /// 1 kg of fat mass (the figure `TrendSmoother` is built on), which on an
  /// adult body is about one percentage point.
  static const bodyFatNoisePct = 1.0;

  /// The wearable kinds the review reports, in order, with their labels.
  static const wearableKinds = <(String, String)>[
    ('sleep_minutes', 'Sleep'),
    ('resting_hr_bpm', 'Resting HR'),
    ('hrv_sdnn_ms', 'HRV'),
    ('hrv_rmssd_ms', 'HRV'),
  ];

  /// Folds the week ending in [now]'s ISO week.
  ///
  /// [meals] may cover any range — the streak reads back through all of it —
  /// but must include this week and the previous one. [bodyReadings] and
  /// [observations] should cover the last 28 days: the week under review and
  /// the three before it, which is the baseline the wearable sentences
  /// compare against.
  static WeeklyReview compute({
    required List<LoggedMeal> meals,
    required List<BodyCompositionResult> bodyReadings,
    required List<ObservationSample> observations,
    required DateTime now,
  }) {
    final weekStart = isoWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final previousStart = weekStart.subtract(const Duration(days: 7));
    final baselineStart = weekStart.subtract(const Duration(days: 21));
    bool inThisWeek(DateTime t) =>
        !t.isBefore(weekStart) && t.isBefore(weekEnd);
    bool inPreviousWeek(DateTime t) =>
        !t.isBefore(previousStart) && t.isBefore(weekStart);
    bool inBaseline(DateTime t) =>
        !t.isBefore(baselineStart) && t.isBefore(weekStart);

    // Meals.
    final thisWeek = [
      for (final m in meals)
        if (inThisWeek(m.eatenAt)) m,
    ];
    final components = [for (final m in thisWeek) ...m.components];
    final totals = MealTotals.from(components);
    final weighedShare = totals.kcal <= 0 ? null : totals.weighedFraction;
    var fatG = 0.0;
    var fatKcal = 0.0;
    for (final c in components) {
      if (!c.isCookingFat) continue;
      fatG += c.grams;
      fatKcal += c.nutrients.kcal;
    }
    final loggedDays = {for (final m in meals) dayOf(m.eatenAt)};
    final daysLogged = loggedDays.where(inThisWeek).length;
    final streak = _streak(loggedDays, dayOf(now));

    // Scale readings.
    final weekReadings = [
      for (final r in bodyReadings)
        if (inThisWeek(r.takenAt)) r,
    ];
    final previousReadings = [
      for (final r in bodyReadings)
        if (inPreviousWeek(r.takenAt)) r,
    ];
    final beforeTen = weekReadings.where((r) => r.takenAt.hour < 10).length;

    final weight = WeeklyDelta(
      thisWeek: median(weekReadings.map((r) => r.weightKg)),
      previousWeek: median(previousReadings.map((r) => r.weightKg)),
      thisWeekCount: weekReadings.length,
      previousWeekCount: previousReadings.length,
      noiseFloor: weightNoiseKg,
    );

    WeeklyDelta? bodyFat;
    final fatThis = _bodyFatMetrics(weekReadings);
    final fatPrevious = _bodyFatMetrics(previousReadings);
    if (fatThis.isNotEmpty || fatPrevious.isNotEmpty) {
      // The noise floor is the equation's own published standard error,
      // carried on every metric the engine produces, when the readings have
      // it; the median over the fortnight so one weight-only reading cannot
      // move it. Otherwise the cited fallback.
      final errors = [
        for (final m in [...fatThis, ...fatPrevious])
          if (m.uncertainty != null) m.uncertainty!,
      ];
      bodyFat = WeeklyDelta(
        thisWeek: median(fatThis.map((m) => m.value)),
        previousWeek: median(fatPrevious.map((m) => m.value)),
        thisWeekCount: fatThis.length,
        previousWeekCount: fatPrevious.length,
        noiseFloor: median(errors) ?? bodyFatNoisePct,
      );
    }

    // Wearables: this week against the previous three, one entry per kind.
    // SDNN and RMSSD are both "HRV"; whichever has data this week is used,
    // SDNN first, so the review never prints two HRV lines.
    final wearables = <WearableMedian>[];
    var hrvDone = false;
    for (final (kind, _) in wearableKinds) {
      final isHrv = kind.startsWith('hrv_');
      if (isHrv && hrvDone) continue;
      final series = [
        for (final o in observations)
          if (o.kind == kind) o,
      ]..sort((a, b) => a.takenAt.compareTo(b.takenAt));
      final week = series.where((o) => inThisWeek(o.takenAt)).toList();
      if (week.isEmpty) continue;
      final baseline = series.where((o) => inBaseline(o.takenAt)).toList();
      wearables.add(
        WearableMedian(
          kind: kind,
          thisWeek: median(week.map((o) => o.value))!,
          baseline: median(baseline.map((o) => o.value)),
          thisWeekCount: week.length,
          baselineCount: baseline.length,
          sourceText: series.last.sourceText,
        ),
      );
      if (isHrv) hrvDone = true;
    }

    final review = WeeklyReview(
      weekStart: weekStart,
      weekNumber: isoWeekNumber(weekStart),
      weighedShare: weighedShare,
      weekKcal: totals.kcal,
      cookingFatG: fatG,
      cookingFatKcal: fatKcal,
      readingCount: weekReadings.length,
      readingsBeforeTen: beforeTen,
      weight: weight,
      bodyFat: bodyFat,
      wearables: wearables,
      streakDays: streak,
      daysLogged: daysLogged,
      sentences: const [],
    );
    return review._withSentences();
  }

  static List<Metric> _bodyFatMetrics(List<BodyCompositionResult> readings) {
    final out = <Metric>[];
    for (final r in readings) {
      final m = r.metric('bodyFatPercent');
      if (m != null && m.derived == Derived.predicted) out.add(m);
    }
    return out;
  }

  /// Consecutive logged days ending today, or yesterday when today has not
  /// been logged yet — a streak should not read as broken at breakfast.
  static int _streak(Set<DateTime> loggedDays, DateTime today) {
    var day = loggedDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var n = 0;
    while (loggedDays.contains(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  WeeklyReview _withSentences() => WeeklyReview(
        weekStart: weekStart,
        weekNumber: weekNumber,
        weighedShare: weighedShare,
        weekKcal: weekKcal,
        cookingFatG: cookingFatG,
        cookingFatKcal: cookingFatKcal,
        readingCount: readingCount,
        readingsBeforeTen: readingsBeforeTen,
        weight: weight,
        bodyFat: bodyFat,
        wearables: wearables,
        streakDays: streakDays,
        daysLogged: daysLogged,
        sentences: _sentences(),
      );

  /// The review, one plain sentence per fact. Nothing causal, nothing about
  /// health, no product and nobody else's numbers — only what this person's
  /// own week contained.
  List<String> _sentences() {
    final out = <String>[];
    final share = weighedShare;
    if (share != null) {
      out.add('You weighed ${(share * 100).round()}% of your calories this '
          'week');
    }
    if (cookingFatG > 0) {
      out.add('Cooking fat: ${cookingFatG.round()} g captured, '
          '${cookingFatKcal.round()} kcal');
    }
    if (readingCount > 0) {
      out.add('${_plural(readingCount, 'reading')}, $readingsBeforeTen '
          'before 10:00');
    }
    if (weight.thisWeek != null) {
      out.add(
        'Weight median ${weight.thisWeek!.toStringAsFixed(1)} kg, '
        '${_deltaPhrase(weight, (d) => '${d.toStringAsFixed(1)} kg')}',
      );
    }
    final fat = bodyFat;
    if (fat != null && fat.thisWeek != null) {
      out.add(
        'Body fat median ${fat.thisWeek!.toStringAsFixed(1)}%, '
        '${_deltaPhrase(fat, (d) => '${d.toStringAsFixed(1)} points')}',
      );
    }
    for (final w in wearables) {
      out.add(_wearableSentence(w));
    }
    if (streakDays > 0) {
      out.add(
        streakDays == 1
            ? 'A meal logged today'
            : 'Meals logged $streakDays days running',
      );
    }
    return out;
  }

  static String _deltaPhrase(WeeklyDelta d, String Function(double) fmt) {
    final delta = d.delta;
    if (delta == null) return 'nothing to compare with last week yet';
    if (!d.beyondNoise) return "no change beyond the scale's noise";
    return '${fmt(delta.abs())} ${delta < 0 ? 'below' : 'above'} last week';
  }

  static String _wearableSentence(WearableMedian w) {
    final label = wearableKinds.firstWhere((k) => k.$1 == w.kind).$2;
    final head = '$label median ${formatValue(w.kind, w.thisWeek)} from '
        '${w.sourceText}';
    final delta = w.delta;
    if (delta == null) return '$head, no earlier weeks to compare with yet';
    final rounded = delta.round();
    if (rounded == 0) return '$head, level with your previous three weeks';
    final more = delta > 0;
    final amount = switch (w.kind) {
      'sleep_minutes' => '${_plural(rounded.abs(), 'minute')} '
          '${more ? 'more' : 'less'} than',
      'resting_hr_bpm' => '${rounded.abs()} bpm ${more ? 'above' : 'below'}',
      _ => '${rounded.abs()} ms ${more ? 'above' : 'below'}',
    };
    return '$head, $amount your previous three weeks';
  }

  /// "7 h 05 m", "54 bpm", "47 ms".
  static String formatValue(String kind, double v) => switch (kind) {
        'sleep_minutes' => '${v ~/ 60} h '
            '${(v % 60).round().toString().padLeft(2, '0')} m',
        'resting_hr_bpm' => '${v.round()} bpm',
        _ => '${v.round()} ms',
      };

  static String _plural(int n, String noun) =>
      n == 1 ? '1 $noun' : '$n ${noun}s';
}
