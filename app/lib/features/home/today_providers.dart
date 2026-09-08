/// Riverpod wiring for Today's second glance: the streak and the insights.
///
/// Kept apart from `core/data/providers.dart` so the Today screen can grow
/// without touching the graph every screen depends on. Everything here is a
/// fold over SQLite streams; nothing awaits the network.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import 'insights.dart';
import 'streak.dart';

/// How far back the streak reads. A streak longer than this shows as this
/// many days; the window is a year and a bit so the query stays a single
/// index scan rather than a walk over every meal ever logged.
const int streakWindowDays = 400;

/// Every local calendar day in the last [streakWindowDays] with at least one
/// live meal. Only the timestamp column is read: the streak needs days, not
/// components, and a year of meals is a lot of components.
final loggedDaysProvider = StreamProvider<Set<DateTime>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  final since = today.subtract(const Duration(days: streakWindowDays));
  final meals = s.db.meals;
  final q = s.db.selectOnly(meals)
    ..addColumns([meals.eatenAt])
    ..where(
      meals.deletedAt.isNull() &
          meals.eatenAt.isBiggerOrEqualValue(since.toUtc()),
    );
  yield* q.watch().map(
        (rows) => {
          for (final r in rows) dayOf(r.read(meals.eatenAt)!.toLocal()),
        },
      );
});

/// Consecutive logged days ending today or yesterday. Zero while the stream
/// is still opening, which hides the chip rather than flashing a wrong one.
final todayStreakProvider = Provider<int>((ref) {
  final days = ref.watch(loggedDaysProvider).valueOrNull ?? const {};
  return loggingStreak(days, ref.watch(todayProvider));
});

/// The current hour, refreshed on the hour so the "no lunch logged yet"
/// nudge appears at noon rather than when the next meal happens to land.
/// The same trick `todayProvider` uses at midnight.
final clockHourProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final thisHour = DateTime(now.year, now.month, now.day, now.hour);
  final untilNextHour = thisHour.add(const Duration(hours: 1)).difference(now) +
      const Duration(seconds: 1);
  final timer = Timer(untilNextHour, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return thisHour;
});

/// The last [insightMealDays] days of meals, today included, oldest first.
final insightMealsProvider = StreamProvider<List<LoggedMeal>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  final start = today.subtract(const Duration(days: insightMealDays - 1));
  final end = today.add(const Duration(days: 1));
  yield* s.meals.watchMealsBetween(start, end);
});

/// The sentences for the insights card. Empty while the meal stream is
/// still opening, and empty when there is nothing true to say — the card
/// hides itself either way.
final todayInsightsProvider = Provider<List<TodayInsight>>((ref) {
  final meals = ref.watch(insightMealsProvider).valueOrNull;
  if (meals == null) return const [];
  final hour = ref.watch(clockHourProvider);
  final target = ref.watch(dailyTargetProvider);
  final weights = ref.watch(weightSeriesProvider);
  final kitchen = ref.watch(kitchenConnectionProvider).valueOrNull;
  return todayInsights(
    TodayInsightInputs(
      // The hour from the clock provider so the nudge rolls over; the minute
      // does not matter to any sentence.
      now: hour,
      meals: meals,
      proteinTargetG: target?.proteinG,
      weights: weights,
      kitchenScaleConnected: kitchen == ScaleConnectionState.connected,
    ),
  );
});
