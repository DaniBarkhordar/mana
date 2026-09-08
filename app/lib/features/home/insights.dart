/// The second glance on Today: one to three short, true sentences about this
/// person's own data, each with the provenance it rests on.
///
/// Pure Dart. Every sentence is a fold over rows that already exist — meals,
/// scale readings, the kitchen scale's connection state — so it can be checked
/// by hand (test/home/insights_test.dart); the provider under it only wires
/// the fold to streams.
///
/// What the sentences never do, and the tests enforce: they never advise
/// ("eat less", "you should"), never name a health outcome, never quote an
/// accuracy percentage, and never state a number without saying where it
/// came from. An insight here is a fact with its working shown, not a
/// verdict.
library;

import '../../core/data/models.dart';
import '../../core/insights/weekly_review.dart' show WeeklyReview, median;
import '../../core/nutrition/portion.dart';
import 'streak.dart';

/// One sentence and the evidence under it.
class TodayInsight {
  const TodayInsight({required this.text, required this.provenance});

  /// The fact, in the product's voice. No full stop; the card sets it.
  final String text;

  /// What the fact was worked out from: which days, how many readings,
  /// against which target. Shown in the caption line under the sentence.
  final String provenance;
}

/// Everything the sentences are folded from. Hand-built in tests.
class TodayInsightInputs {
  const TodayInsightInputs({
    required this.now,
    required this.meals,
    this.proteinTargetG,
    this.weights = const [],
    this.kitchenScaleConnected = false,
  });

  /// The local time the sentences are written for.
  final DateTime now;

  /// Meals over at least the last [insightMealDays] days, today included.
  final List<LoggedMeal> meals;

  /// Today's protein target in grams, from the energy target; null when
  /// there is no target yet.
  final int? proteinTargetG;

  /// Weight readings, oldest first, over at least the last fourteen days.
  final List<({DateTime at, double value})> weights;

  /// True when the kitchen scale is connected right now, so a nudge to log
  /// can say the scale is ready and be telling the truth.
  final bool kitchenScaleConnected;
}

/// How many days of meals the sentences look back over: this week and the
/// one before, so a median has something to be compared with.
const int insightMealDays = 14;

/// The card shows at most this many sentences. Three is a glance; more is a
/// report, and the Progress tab has the report.
const int maxTodayInsights = 3;

/// A day counts as weighed when at least this share of its energy came off
/// the scale — the same threshold the energy hero and the meal rows use for
/// their badge, so the sentence and the badges can never disagree.
const double weighedDayThreshold = 0.6;

/// Under this many grams a protein difference is not reported. Reference
/// data per 100 g carries spread of its own, and a household measure or two
/// across a week moves the average by about this much, so a smaller gap is
/// the log's noise rather than a pattern.
const double proteinNoiseG = 10;

/// The sentences for [inputs], most immediate first, at most
/// [maxTodayInsights] of them.
///
/// Order: the nudge for the meal that is due now (the one thing the reader
/// can act on this minute), then protein against target, then how many of
/// the week's days were weighed, then the weight median, then cooking fat.
List<TodayInsight> todayInsights(TodayInsightInputs inputs) {
  final out = <TodayInsight?>[
    mealSlotInsight(
      now: inputs.now,
      meals: inputs.meals,
      scaleReady: inputs.kitchenScaleConnected,
    ),
    proteinInsight(
      now: inputs.now,
      meals: inputs.meals,
      targetG: inputs.proteinTargetG,
    ),
    weighedDaysInsight(now: inputs.now, meals: inputs.meals),
    weightMedianInsight(now: inputs.now, weights: inputs.weights),
    cookingFatInsight(now: inputs.now, meals: inputs.meals),
  ].whereType<TodayInsight>().toList();
  return out.length > maxTodayInsights ? out.sublist(0, maxTodayInsights) : out;
}

/// The meal slot that is due at [now]'s hour, or null between mealtimes.
///
/// Breakfast 07:00–10:59, lunch 12:00–14:59, dinner 18:00–20:59. The windows
/// open at the usual start of each meal rather than the moment the previous
/// one ends, so the card is not nagging about lunch at 11:05.
MealSlot? mealSlotDue(DateTime now) => switch (now.hour) {
      >= 7 && < 11 => MealSlot.breakfast,
      >= 12 && < 15 => MealSlot.lunch,
      >= 18 && < 21 => MealSlot.dinner,
      _ => null,
    };

/// "No lunch logged yet; the scale is ready" — when a meal is due and today
/// has no meal in that slot. Null between mealtimes or once it is logged.
TodayInsight? mealSlotInsight({
  required DateTime now,
  required List<LoggedMeal> meals,
  required bool scaleReady,
}) {
  final slot = mealSlotDue(now);
  if (slot == null) return null;
  final today = dayOf(now);
  final logged = meals.any((m) => dayOf(m.eatenAt) == today && m.slot == slot);
  if (logged) return null;
  final name = slot.label.toLowerCase();
  return TodayInsight(
    text: scaleReady
        ? 'No $name logged yet; the scale is ready'
        : 'No $name logged yet',
    provenance: scaleReady
        ? "Today's meals, and the kitchen scale is connected"
        : "Today's meals",
  );
}

/// Protein per logged day over the six days before [today]. Today is left
/// out because it is still being eaten: a half-logged day would drag the
/// average down and report a shortfall that is only the time of day.
Map<DateTime, double> _proteinByFullDay(
  List<LoggedMeal> meals,
  DateTime today,
) {
  final start = DateTime(today.year, today.month, today.day - 6);
  final byDay = <DateTime, double>{};
  for (final m in meals) {
    final d = dayOf(m.eatenAt);
    if (d.isBefore(start) || !d.isBefore(today)) continue;
    final p = m.totals.nutrients.proteinG;
    if (p == null) continue;
    byDay[d] = (byDay[d] ?? 0) + p;
  }
  return byDay;
}

/// "Protein is running 20 g under target this week" — the mean over the
/// last week's fully logged days against the target. Null without a target,
/// with fewer than three logged days to average, or when the gap is inside
/// [proteinNoiseG].
TodayInsight? proteinInsight({
  required DateTime now,
  required List<LoggedMeal> meals,
  required int? targetG,
}) {
  if (targetG == null || targetG <= 0) return null;
  final byDay = _proteinByFullDay(meals, dayOf(now));
  if (byDay.length < 3) return null;
  var sum = 0.0;
  for (final v in byDay.values) {
    sum += v;
  }
  final mean = sum / byDay.length;
  final diff = mean - targetG;
  if (diff.abs() < proteinNoiseG) return null;
  return TodayInsight(
    text: 'Protein is running ${diff.abs().round()} g '
        '${diff < 0 ? 'under' : 'over'} target this week',
    provenance: 'Average of the last ${byDay.length} logged days against '
        'your $targetG g target',
  );
}

/// "Six of the last seven days were weighed, not estimated" — days in the
/// trailing week, today included, whose energy was at least
/// [weighedDayThreshold] weighed. Null with fewer than four logged days,
/// when the count would be a statement about absence rather than habit.
TodayInsight? weighedDaysInsight({
  required DateTime now,
  required List<LoggedMeal> meals,
}) {
  final today = dayOf(now);
  final start = DateTime(today.year, today.month, today.day - 6);
  final byDay = <DateTime, List<LoggedComponent>>{};
  for (final m in meals) {
    final d = dayOf(m.eatenAt);
    if (d.isBefore(start) || d.isAfter(today)) continue;
    byDay.putIfAbsent(d, () => []).addAll(m.components);
  }
  if (byDay.length < 4) return null;
  final weighed = byDay.values
      .where(
        (c) => MealTotals.from(c).weighedFraction >= weighedDayThreshold,
      )
      .length;
  final text = weighed == 0
      ? 'Nothing in the last seven days was weighed'
      : '${countWord(weighed)} of the last seven days '
          '${weighed == 1 ? 'was' : 'were'} weighed, not estimated';
  return TodayInsight(
    text: text,
    provenance: 'Days where at least '
        '${(weighedDayThreshold * 100).round()}% of the energy logged came '
        'off the scale; ${byDay.length} of 7 days logged',
  );
}

/// "Your weight median moved 0.4 kg down in two weeks" — the median of the
/// last seven days' readings against the median of the seven before. Null
/// until both weeks hold three readings; a median of one is a reading.
///
/// A difference inside [WeeklyReview.weightNoiseKg] is reported as holding,
/// not as a small move: two medians closer than the scale's repeatability
/// are the scale repeating itself.
TodayInsight? weightMedianInsight({
  required DateTime now,
  required List<({DateTime at, double value})> weights,
}) {
  final today = dayOf(now);
  final recentStart = DateTime(today.year, today.month, today.day - 6);
  final priorStart = DateTime(today.year, today.month, today.day - 13);
  final recent = <double>[];
  final prior = <double>[];
  for (final w in weights) {
    final d = dayOf(w.at);
    if (d.isAfter(today) || d.isBefore(priorStart)) continue;
    (d.isBefore(recentStart) ? prior : recent).add(w.value);
  }
  if (recent.length < 3 || prior.length < 3) return null;
  final a = median(recent)!;
  final b = median(prior)!;
  final delta = a - b;
  const noise = WeeklyReview.weightNoiseKg;
  // The tolerance is there because 78.4 − 78.7 is −0.3000000000000007 in a
  // double, and a sentence must not turn on the last bit of a subtraction.
  if (delta.abs() <= noise + 1e-9) {
    return TodayInsight(
      text: 'Your weight median is holding at ${a.toStringAsFixed(1)} kg '
          'across two weeks',
      provenance: 'Median of ${recent.length} readings this week against '
          "${prior.length} the week before; under ${noise.toStringAsFixed(1)} "
          "kg is the scale's own noise",
    );
  }
  return TodayInsight(
    text: 'Your weight median moved ${delta.abs().toStringAsFixed(1)} kg '
        '${delta < 0 ? 'down' : 'up'} in two weeks',
    provenance: 'Median of ${recent.length} readings this week against '
        '${prior.length} the week before',
  );
}

/// "You weighed 24 g of cooking fat this week: 212 kcal" — the pan weighed
/// before and after, summed over the trailing week. Null when none was.
TodayInsight? cookingFatInsight({
  required DateTime now,
  required List<LoggedMeal> meals,
}) {
  final today = dayOf(now);
  final start = DateTime(today.year, today.month, today.day - 6);
  var grams = 0.0;
  var kcal = 0.0;
  var mealCount = 0;
  for (final m in meals) {
    final d = dayOf(m.eatenAt);
    if (d.isBefore(start) || d.isAfter(today)) continue;
    var inMeal = false;
    for (final c in m.components) {
      if (!c.isCookingFat) continue;
      grams += c.grams;
      kcal += c.nutrients.kcal;
      inMeal = true;
    }
    if (inMeal) mealCount++;
  }
  if (grams <= 0) return null;
  return TodayInsight(
    text: 'You weighed ${grams.round()} g of cooking fat this week: '
        '${kcal.round()} kcal',
    provenance: 'Pan weighed before and after, across '
        '${mealCount == 1 ? '1 meal' : '$mealCount meals'}',
  );
}

/// "One" to "Seven" for a count of days; digits beyond that. A sentence
/// reads better with the small numbers spelt out, and seven is the most a
/// week can hold.
String countWord(int n) => switch (n) {
      0 => 'None',
      1 => 'One',
      2 => 'Two',
      3 => 'Three',
      4 => 'Four',
      5 => 'Five',
      6 => 'Six',
      7 => 'Seven',
      _ => '$n',
    };
