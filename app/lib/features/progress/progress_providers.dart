/// The weekly view, as maths first and Riverpod second.
///
/// Everything a Sunday review needs is a fold over rows that already exist:
/// meals for the week, readings for the quarter, observations for a month.
/// The aggregation lives in plain classes here so it can be checked by hand
/// (see test/progress/progress_maths_test.dart); the providers underneath
/// only wire those classes to SQLite streams. Nothing here waits on the
/// network.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bia/body_composition.dart';
import '../../core/data/providers.dart';
import '../../core/data/repositories/observation_repository.dart';
import '../../core/nutrition/portion.dart';

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

/// Midnight on the Monday of the week containing [day]. Weeks run Monday to
/// Sunday because that is when people look back, and because the energy
/// chart's seven bars want a fixed order.
DateTime weekStartOf(DateTime day) {
  final midnight = DateTime(day.year, day.month, day.day);
  return midnight.subtract(Duration(days: midnight.weekday - 1));
}

/// Local midnight of [t], for grouping by calendar day.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

// ---------------------------------------------------------------------------
// Energy and macros
// ---------------------------------------------------------------------------

/// One calendar day's intake, folded from its meals.
class DayIntake {
  const DayIntake({required this.day, required this.meals});

  final DateTime day;
  final List<LoggedMeal> meals;

  List<LoggedComponent> get components =>
      [for (final m in meals) ...m.components];

  MealTotals get totals => MealTotals.from(components);
  double get kcal => totals.kcal;
  bool get isLogged => meals.isNotEmpty;

  /// Within ±[tolerance] of [targetKcal]. A day with nothing logged is not
  /// "within target": it is unknown, and counting it would flatter the week.
  bool isWithin(int targetKcal, {double tolerance = 0.10}) {
    if (!isLogged || targetKcal <= 0) return false;
    return (kcal - targetKcal).abs() <= targetKcal * tolerance;
  }
}

/// The week Monday to Sunday: seven days, always seven, so the chart has a
/// bar slot for each even when nothing was logged.
class WeeklySummary {
  const WeeklySummary({required this.weekStart, required this.days});

  factory WeeklySummary.from(List<LoggedMeal> meals, DateTime weekStart) {
    final byDay = <DateTime, List<LoggedMeal>>{};
    for (final m in meals) {
      byDay.putIfAbsent(dayOf(m.eatenAt), () => []).add(m);
    }
    return WeeklySummary(
      weekStart: weekStart,
      days: [
        for (var i = 0; i < 7; i++)
          DayIntake(
            day: weekStart.add(Duration(days: i)),
            meals: byDay[weekStart.add(Duration(days: i))] ?? const [],
          ),
      ],
    );
  }

  final DateTime weekStart;
  final List<DayIntake> days;

  List<DayIntake> get loggedDays => days.where((d) => d.isLogged).toList();
  int get loggedDayCount => loggedDays.length;
  bool get isEmpty => loggedDayCount == 0;

  /// The whole week as one meal: the weighed fraction and the quadrature
  /// error come out exactly as MealTotals defines them, with no re-derivation.
  MealTotals get totals =>
      MealTotals.from([for (final d in days) ...d.components]);

  /// Mean intake over the days that were logged. Dividing by seven would
  /// present a missed day as a fast, so the divisor is stated in the copy.
  double? get averageKcal {
    final logged = loggedDays;
    if (logged.isEmpty) return null;
    var sum = 0.0;
    for (final d in logged) {
      sum += d.kcal;
    }
    return sum / logged.length;
  }

  /// Mean grams of one macro over logged days; null when no day carried it.
  double? averageMacro(double? Function(MealTotals) pick) {
    var sum = 0.0;
    var n = 0;
    for (final d in loggedDays) {
      final v = pick(d.totals);
      if (v == null) continue;
      sum += v;
      n++;
    }
    return n == 0 ? null : sum / n;
  }

  double? get averageProteinG => averageMacro((t) => t.nutrients.proteinG);
  double? get averageCarbG => averageMacro((t) => t.nutrients.carbG);
  double? get averageFatG => averageMacro((t) => t.nutrients.fatG);

  int daysWithin(int targetKcal, {double tolerance = 0.10}) =>
      days.where((d) => d.isWithin(targetKcal, tolerance: tolerance)).length;

  /// Share of the week's energy that was actually weighed.
  double get weighedFraction => totals.weighedFraction;
}

// ---------------------------------------------------------------------------
// Consistency
// ---------------------------------------------------------------------------

/// Twelve weeks of days, one square each, plus the streak.
class ConsistencySummary {
  const ConsistencySummary({
    required this.gridStart,
    required this.kcalByDay,
    required this.today,
    this.weeks = 12,
  });

  /// [meals] may cover any range; only days from [gridStart] to [today] count.
  factory ConsistencySummary.from(
    List<LoggedMeal> meals, {
    required DateTime today,
    int weeks = 12,
  }) {
    // The grid ends on the Sunday of this week so columns are whole weeks.
    final thisWeek = weekStartOf(today);
    final gridStart = thisWeek.subtract(Duration(days: 7 * (weeks - 1)));
    final byDay = <DateTime, double>{};
    for (final m in meals) {
      final d = dayOf(m.eatenAt);
      if (d.isBefore(gridStart)) continue;
      byDay[d] = (byDay[d] ?? 0) + m.totals.kcal;
    }
    return ConsistencySummary(
      gridStart: gridStart,
      kcalByDay: byDay,
      today: dayOf(today),
      weeks: weeks,
    );
  }

  final DateTime gridStart;

  /// Energy logged on each day that had at least one meal. A day is present
  /// as soon as anything was logged, even at zero kcal, so a logged glass of
  /// water still keeps a streak alive.
  final Map<DateTime, double> kcalByDay;
  final DateTime today;
  final int weeks;

  /// Rows are Monday..Sunday, columns are weeks oldest first.
  DateTime dayAt({required int week, required int weekday}) =>
      gridStart.add(Duration(days: week * 7 + weekday));

  double kcalOn(DateTime day) => kcalByDay[dayOf(day)] ?? 0;

  bool isLogged(DateTime day) => kcalByDay.containsKey(dayOf(day));

  /// Consecutive logged days ending today, or ending yesterday when today has
  /// not been logged yet — a streak should not read as broken at breakfast.
  int get currentStreak {
    var day = isLogged(today) ? today : today.subtract(const Duration(days: 1));
    var n = 0;
    while (isLogged(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Shade for a square, 0 (nothing) to 3 (a full day). Scaled against
  /// [targetKcal] when there is one, so a light square is a light day rather
  /// than a day that happened to be smaller than the week's biggest.
  int level(DateTime day, {int? targetKcal}) {
    if (!isLogged(day)) return 0;
    final kcal = kcalOn(day);
    if (kcal <= 0) return 1;
    final reference = targetKcal != null && targetKcal > 0
        ? targetKcal.toDouble()
        : kcalByDay.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (reference <= 0) return 3;
    final f = kcal / reference;
    if (f < 0.5) return 1;
    if (f < 0.9) return 2;
    return 3;
  }
}

// ---------------------------------------------------------------------------
// Wearables
// ---------------------------------------------------------------------------

/// One wearable kind, this week against the month behind it.
class WearableComparison {
  const WearableComparison({
    required this.kind,
    required this.sevenDay,
    required this.thirtyDay,
    required this.sourceName,
    required this.sampleCount,
  });

  /// Means over the trailing windows. Days with no observation are simply
  /// absent — a night the watch was charging is not a night of zero sleep.
  static WearableComparison? from(
    String kind,
    List<ObservationPoint> series, {
    required DateTime asOf,
    required String sourceName,
  }) {
    final week = _mean(series, asOf.subtract(const Duration(days: 7)), asOf);
    final month = _mean(series, asOf.subtract(const Duration(days: 30)), asOf);
    if (week == null && month == null) return null;
    return WearableComparison(
      kind: kind,
      sevenDay: week,
      thirtyDay: month,
      sourceName: sourceName,
      sampleCount: series.length,
    );
  }

  static double? _mean(
    List<ObservationPoint> series,
    DateTime from,
    DateTime to,
  ) {
    var sum = 0.0;
    var n = 0;
    for (final p in series) {
      if (p.at.isAfter(from) && !p.at.isAfter(to)) {
        sum += p.value;
        n++;
      }
    }
    return n == 0 ? null : sum / n;
  }

  final String kind;
  final double? sevenDay;
  final double? thirtyDay;
  final String sourceName;
  final int sampleCount;

  /// Week minus month, in the kind's unit. Null until both exist.
  double? get delta =>
      sevenDay == null || thirtyDay == null ? null : sevenDay! - thirtyDay!;
}

/// The kinds the card shows, in order, with their labels.
const wearableKinds = <(String, String)>[
  ('sleep_minutes', 'Sleep'),
  ('hrv_sdnn_ms', 'HRV (SDNN)'),
  ('hrv_rmssd_ms', 'HRV (RMSSD)'),
  ('resting_hr_bpm', 'Resting HR'),
  ('steps', 'Steps'),
];

/// Human names for observation sources. The demo scale is called what it is:
/// a reading from it must never read as a measurement.
String sourceDisplayName(String? source) => switch (source) {
      'apple_health' => 'Apple Health',
      'health_connect' => 'Health Connect',
      'mananu_body_scale' => 'your scale',
      'mananu_kitchen_scale' => 'your kitchen scale',
      'simulated_scale' => 'the demo scale',
      null => 'your scale',
      _ => source.replaceAll('_', ' '),
    };

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

/// Direction words for a weekly rate. Under 50 g a week is noise on a
/// bathroom scale, so it is called steady rather than given a direction.
String describeWeeklyRate(double kgPerWeek) {
  if (kgPerWeek.abs() < 0.05) return 'Holding steady over three weeks';
  final word = kgPerWeek < 0 ? 'down' : 'up';
  return '${kgPerWeek.abs().toStringAsFixed(2)} kg per week $word '
      'over three weeks';
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Monday of the current week; rolls with [todayProvider].
final progressWeekStartProvider =
    Provider<DateTime>((ref) => weekStartOf(ref.watch(todayProvider)));

/// Twelve weeks of meals, oldest first. One stream feeds the week, the grid
/// and the streak, so they can never disagree.
final recentMealsProvider = StreamProvider<List<LoggedMeal>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final weekStart = ref.watch(progressWeekStartProvider);
  final start = weekStart.subtract(const Duration(days: 7 * 11));
  final end = weekStart.add(const Duration(days: 7));
  yield* s.meals.watchMealsBetween(start, end);
});

final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final meals = ref.watch(recentMealsProvider).valueOrNull ?? const [];
  final weekStart = ref.watch(progressWeekStartProvider);
  final end = weekStart.add(const Duration(days: 7));
  return WeeklySummary.from(
    [
      for (final m in meals)
        if (!m.eatenAt.isBefore(weekStart) && m.eatenAt.isBefore(end)) m,
    ],
    weekStart,
  );
});

final consistencyProvider = Provider<ConsistencySummary>((ref) {
  final meals = ref.watch(recentMealsProvider).valueOrNull ?? const [];
  return ConsistencySummary.from(meals, today: ref.watch(todayProvider));
});

/// Which window the weight chart shows, in days.
final progressWeightRangeProvider = StateProvider<int>((ref) => 30);

/// A goal weight, if the profile ever carries one. The field does not exist
/// on [UserProfile] today; this reads it dynamically so the screen draws the
/// goal line the day the field lands and compiles either way until then.
final targetWeightKgProvider = Provider<double?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return null;
  try {
    final v = (profile as dynamic).targetWeightKg;
    return v is num ? v.toDouble() : null;
  } on NoSuchMethodError {
    return null;
  }
});

/// The rate the Body screen quotes, so the two tabs never disagree.
final progressWeeklyRateProvider =
    Provider<double?>((ref) => ref.watch(weightTrendRateProvider));

/// Where the weight readings came from, for the card's provenance line.
final observationSourceProvider =
    StreamProvider.family<String?, String>((ref, kind) async* {
  final s = await ref.watch(appServicesProvider.future);
  final q = s.db.select(s.db.observations)
    ..where((o) => o.kind.equals(kind) & o.deletedAt.isNull())
    ..orderBy([(o) => OrderingTerm.desc(o.takenAt)])
    ..limit(1);
  yield* q.watch().map((rows) => rows.isEmpty ? null : rows.first.source);
});

/// Thirty days of one wearable kind.
final wearableSeriesProvider =
    StreamProvider.family<List<ObservationPoint>, String>((ref, kind) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  yield* s.observations.watchSeries(
    kind,
    since: today.subtract(const Duration(days: 31)),
  );
});

/// Every wearable kind with data, this week against the month.
final wearableComparisonsProvider = Provider<List<WearableComparison>>((ref) {
  final asOf = DateTime.now();
  final out = <WearableComparison>[];
  for (final (kind, _) in wearableKinds) {
    final series = ref.watch(wearableSeriesProvider(kind)).valueOrNull;
    if (series == null || series.isEmpty) continue;
    final source = ref.watch(observationSourceProvider(kind)).valueOrNull;
    final c = WearableComparison.from(
      kind,
      series,
      asOf: asOf,
      sourceName: sourceDisplayName(source),
    );
    if (c != null) out.add(c);
  }
  return out;
});

/// Rolling median for the chart line, one point per reading. Shared with the
/// Body screen's smoother so both tabs draw the same line.
List<({DateTime at, double value})> rollingMedianSeries(
  List<({DateTime at, double value})> window,
) {
  const smoother = TrendSmoother();
  return [
    for (final p in window)
      (at: p.at, value: smoother.rollingMedian(window, asOf: p.at) ?? p.value),
  ];
}
