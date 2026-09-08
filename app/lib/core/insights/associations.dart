/// "In your data": does a day that went one way tend to be followed by a
/// morning that reads differently?
///
/// Pure Dart, no Flutter. Each behaviour is a yes/no over one day's diary —
/// a late meal, a high-fat day, a day mostly weighed, or an evening tag the
/// user set — and each outcome is the next morning's wearable value. The days
/// split into two arms, and the report is the difference between the arms'
/// medians with a bootstrap interval around it.
///
/// What this is not: a finding. Two arms of a person's own days differ for a
/// hundred reasons, and nothing here separates them. The sentence says "in
/// your data" and states a difference with its n; it never says one thing
/// caused another, and below eight days an arm it says nothing at all,
/// because a median of five nights is noise wearing a number.
library;

import 'dart:math' as math;

import '../data/models.dart';
import '../nutrition/portion.dart';
import 'weekly_review.dart' show dayOf, median;

// ---------------------------------------------------------------------------
// Behaviours
// ---------------------------------------------------------------------------

/// One yes/no over a day, derivable from the diary or from an evening tag.
class Behaviour {
  const Behaviour._({
    required this.id,
    required this.phrase,
    required this.noun,
    required this.test,
    this.tagKind,
  });

  /// A behaviour worked out from the day's meals.
  const Behaviour.fromDiary({
    required String id,
    required String phrase,
    required String noun,
    required bool Function(List<LoggedMeal> meals) test,
  }) : this._(id: id, phrase: phrase, noun: noun, test: test);

  /// A behaviour the user tagged in the evening, stored as an observation of
  /// [tagKind] with source `diary`, value 1 (or 0 when switched back off).
  const Behaviour.fromTag({
    required String id,
    required String phrase,
    required String noun,
    required String tagKind,
  }) : this._(
          id: id,
          phrase: phrase,
          noun: noun,
          test: _never,
          tagKind: tagKind,
        );

  static bool _never(List<LoggedMeal> _) => false;

  final String id;

  /// "a late meal" — completes "nights after …".
  final String phrase;

  /// "late-meal days" — for the calibration caption.
  final String noun;

  /// The diary test; ignored for tag behaviours.
  final bool Function(List<LoggedMeal> meals) test;
  final String? tagKind;

  bool get isTag => tagKind != null;

  /// The last meal of the day was eaten at or after 21:00.
  static bool lastMealAfterNine(List<LoggedMeal> meals) {
    if (meals.isEmpty) return false;
    var last = meals.first.eatenAt;
    for (final m in meals) {
      if (m.eatenAt.isAfter(last)) last = m.eatenAt;
    }
    return last.hour >= 21;
  }

  /// More than 40% of the day's energy came from fat, at 9 kcal per gram
  /// (Atwater). Days with no fat figure at all are not high-fat days.
  static bool highFat(List<LoggedMeal> meals) {
    final totals = MealTotals.from([for (final m in meals) ...m.components]);
    final fatG = totals.nutrients.fatG;
    if (fatG == null || totals.kcal <= 0) return false;
    return fatG * 9 / totals.kcal > 0.40;
  }

  /// At least half the day's energy was weighed.
  static bool halfWeighed(List<LoggedMeal> meals) {
    final totals = MealTotals.from([for (final m in meals) ...m.components]);
    return totals.kcal > 0 && totals.weighedFraction >= 0.5;
  }

  static const lateMeal = Behaviour.fromDiary(
    id: 'late_meal',
    phrase: 'a late meal',
    noun: 'late-meal days',
    test: lastMealAfterNine,
  );
  static const highFatDay = Behaviour.fromDiary(
    id: 'high_fat',
    phrase: 'a high-fat day',
    noun: 'high-fat days',
    test: highFat,
  );
  static const weighedDay = Behaviour.fromDiary(
    id: 'half_weighed',
    phrase: 'a mostly weighed day',
    noun: 'mostly weighed days',
    test: halfWeighed,
  );
  static const alcohol = Behaviour.fromTag(
    id: 'tag_alcohol',
    phrase: 'a drink',
    noun: 'tagged evenings',
    tagKind: 'tag_alcohol',
  );
  static const lateCaffeine = Behaviour.fromTag(
    id: 'tag_caffeine_late',
    phrase: 'late caffeine',
    noun: 'tagged evenings',
    tagKind: 'tag_caffeine_late',
  );
  static const illness = Behaviour.fromTag(
    id: 'tag_illness',
    phrase: 'a day feeling unwell',
    noun: 'tagged days',
    tagKind: 'tag_illness',
  );
  static const travel = Behaviour.fromTag(
    id: 'tag_travel',
    phrase: 'a day travelling',
    noun: 'tagged days',
    tagKind: 'tag_travel',
  );

  /// Every behaviour, diary ones first.
  static const all = [
    lateMeal,
    highFatDay,
    weighedDay,
    alcohol,
    lateCaffeine,
    illness,
    travel,
  ];

  /// The four evening tags, in the order the sheet shows them.
  static const tags = [alcohol, lateCaffeine, illness, travel];
}

/// The evening-tag observation shape, so the sheet and the reader agree.
const tagSource = 'diary';
const tagUnit = 'flag';

// ---------------------------------------------------------------------------
// Outcomes
// ---------------------------------------------------------------------------

/// A next-morning quantity and how its difference reads in a sentence.
class Outcome {
  const Outcome({required this.kind, required this.label, required this.unit});

  final String kind;

  /// "resting HR" — mid-sentence, so lower case except for initials.
  final String label;
  final String unit;

  /// "4 bpm above", "20 min below" — or "level with" when the difference
  /// rounds to nothing, because "0 ms above" is a difference dressed up.
  String describe(double difference) {
    final n = difference.abs().round();
    if (n == 0) return 'level with';
    final direction = difference < 0 ? 'below' : 'above';
    return '$n $unit $direction';
  }

  static const restingHr =
      Outcome(kind: 'resting_hr_bpm', label: 'resting HR', unit: 'bpm');
  static const hrvSdnn = Outcome(kind: 'hrv_sdnn_ms', label: 'HRV', unit: 'ms');
  static const hrvRmssd =
      Outcome(kind: 'hrv_rmssd_ms', label: 'HRV', unit: 'ms');
  static const sleep =
      Outcome(kind: 'sleep_minutes', label: 'sleep', unit: 'min');

  static const all = [restingHr, hrvSdnn, hrvRmssd, sleep];
}

// ---------------------------------------------------------------------------
// The statistic
// ---------------------------------------------------------------------------

/// The difference between two arms' medians, with an 80% bootstrap interval.
class ArmDifference {
  const ArmDifference({
    required this.difference,
    required this.intervalLow,
    required this.intervalHigh,
    required this.nFlagged,
    required this.nOther,
  });

  /// Median of the flagged arm minus median of the other arm.
  final double difference;

  /// 10th and 90th percentiles of the same statistic over the resamples.
  final double intervalLow;
  final double intervalHigh;
  final int nFlagged;
  final int nOther;

  /// Fewest days an arm may hold before anything is said. Eight is where a
  /// median stops being one or two nights in disguise.
  static const minPerArm = 8;

  /// Splits [days] by flag and compares the arms. Null when either arm has
  /// fewer than [minPerArm] days.
  ///
  /// The interval is a percentile bootstrap: [resamples] draws with
  /// replacement from each arm, the median difference of each, and the 10th
  /// and 90th percentiles of those (Efron & Tibshirani 1993, ch. 13). The
  /// random source is seeded so the same days always give the same interval
  /// — the number on screen must not wander between two opens of the tab.
  static ArmDifference? compute(
    List<({bool flag, double outcome})> days, {
    int minPerArm = minPerArm,
    int resamples = 1000,
    int seed = 20260908,
  }) {
    final flagged = [
      for (final d in days)
        if (d.flag) d.outcome,
    ];
    final other = [
      for (final d in days)
        if (!d.flag) d.outcome,
    ];
    if (flagged.length < minPerArm || other.length < minPerArm) return null;

    final difference = median(flagged)! - median(other)!;
    final random = math.Random(seed);
    final draws = List<double>.generate(resamples, (_) {
      final a = _resample(flagged, random);
      final b = _resample(other, random);
      return median(a)! - median(b)!;
    })
      ..sort();
    return ArmDifference(
      difference: difference,
      intervalLow: _percentile(draws, 0.10),
      intervalHigh: _percentile(draws, 0.90),
      nFlagged: flagged.length,
      nOther: other.length,
    );
  }

  static List<double> _resample(List<double> arm, math.Random random) =>
      List<double>.generate(arm.length, (_) => arm[random.nextInt(arm.length)]);

  /// Nearest-rank percentile of a sorted list, which for 1000 draws is the
  /// 100th and 900th values.
  static double _percentile(List<double> sorted, double p) {
    final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
    return sorted[rank - 1];
  }
}

// ---------------------------------------------------------------------------
// Pairing days with mornings
// ---------------------------------------------------------------------------

/// One behaviour against one outcome: the arm counts, always, and the
/// statistic once both arms are big enough.
class AssociationReport {
  const AssociationReport({
    required this.behaviour,
    required this.outcome,
    required this.nFlagged,
    required this.nOther,
    required this.stats,
  });

  final Behaviour behaviour;
  final Outcome outcome;
  final int nFlagged;
  final int nOther;

  /// Null until each arm has [ArmDifference.minPerArm] days.
  final ArmDifference? stats;

  bool get hasEnough => stats != null;

  /// 'In your data, nights after a late meal had resting HR 4 bpm above your
  /// median (n = 9 vs 31)'. Null when an arm is short — nothing is said.
  String? get sentence {
    final s = stats;
    if (s == null) return null;
    return 'In your data, nights after ${behaviour.phrase} had '
        '${outcome.label} ${outcome.describe(s.difference)} your median '
        '(n = ${s.nFlagged} vs ${s.nOther})';
  }

  /// "Collecting your baseline · 5 of 8 late-meal days" — the pieces for the
  /// `CalibrationProgress` instrument while an arm is short. The shorter
  /// arm is the one to fill.
  ({int count, int needed, String label}) get calibration {
    final short = nFlagged < ArmDifference.minPerArm;
    return (
      count: short ? nFlagged : nOther,
      needed: ArmDifference.minPerArm,
      label: short ? behaviour.noun : 'other days',
    );
  }

  /// Pairs each day that has a diary entry with the morning after it.
  ///
  /// Only days with a meal logged are counted, for tags as well as diary
  /// behaviours: a day with no diary is a day the user was not keeping one,
  /// and reading its missing tag as "no drink" would put absent evenings in
  /// the comparison arm. [mealsByDay] and [tagDays] are keyed on local
  /// midnight; [outcomeByDay] on the local midnight of the morning the
  /// observation was taken.
  static AssociationReport pair({
    required Behaviour behaviour,
    required Outcome outcome,
    required Map<DateTime, List<LoggedMeal>> mealsByDay,
    required Set<DateTime> tagDays,
    required Map<DateTime, double> outcomeByDay,
  }) {
    final days = <({bool flag, double outcome})>[];
    for (final entry in mealsByDay.entries) {
      final day = dayOf(entry.key);
      final morning = outcomeByDay[day.add(const Duration(days: 1))];
      if (morning == null) continue;
      final flag =
          behaviour.isTag ? tagDays.contains(day) : behaviour.test(entry.value);
      days.add((flag: flag, outcome: morning));
    }
    final flagged = days.where((d) => d.flag).length;
    return AssociationReport(
      behaviour: behaviour,
      outcome: outcome,
      nFlagged: flagged,
      nOther: days.length - flagged,
      stats: ArmDifference.compute(days),
    );
  }

  /// Every behaviour against every outcome that has data, in a stable order.
  /// Behaviours with no flagged day at all are left out: there is nothing
  /// to collect a baseline for until the first one happens.
  static List<AssociationReport> all({
    required List<LoggedMeal> meals,
    required Map<String, Set<DateTime>> tagDaysByKind,
    required Map<String, Map<DateTime, double>> outcomesByKind,
  }) {
    final mealsByDay = <DateTime, List<LoggedMeal>>{};
    for (final m in meals) {
      mealsByDay.putIfAbsent(dayOf(m.eatenAt), () => []).add(m);
    }
    final out = <AssociationReport>[];
    for (final behaviour in Behaviour.all) {
      var hrvDone = false;
      for (final outcome in Outcome.all) {
        final byDay = outcomesByKind[outcome.kind];
        if (byDay == null || byDay.isEmpty) continue;
        final isHrv = outcome.kind.startsWith('hrv_');
        if (isHrv && hrvDone) continue;
        final report = pair(
          behaviour: behaviour,
          outcome: outcome,
          mealsByDay: mealsByDay,
          tagDays: tagDaysByKind[behaviour.tagKind] ?? const {},
          outcomeByDay: byDay,
        );
        if (report.nFlagged == 0) continue;
        out.add(report);
        if (isHrv) hrvDone = true;
      }
    }
    return out;
  }
}
