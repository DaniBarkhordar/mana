/// Riverpod wiring for the insights: the weekly review, the "in your data"
/// associations and the evening tags they read.
///
/// Kept apart from `core/data/providers.dart` so the insight layer can grow
/// without touching the graph every screen depends on. Everything here is a
/// fold over SQLite streams; nothing awaits the network.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../insights/associations.dart';
import '../../insights/weekly_review.dart';
import '../providers.dart';

/// How far back the associations look. Eight days an arm takes weeks to
/// collect, so the window is a quarter rather than the review's month.
const insightWindowDays = 90;

/// Every observation of the last [insightWindowDays], oldest first, with the
/// device name the store credited it to. Read straight off the table because
/// the repository's series API drops the source, and the review has to name
/// where a number came from.
final insightObservationsProvider =
    StreamProvider<List<ObservationSample>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  final since = today.subtract(const Duration(days: insightWindowDays));
  final q = s.db.select(s.db.observations)
    ..where(
      (o) =>
          o.deletedAt.isNull() & o.takenAt.isBiggerOrEqualValue(since.toUtc()),
    )
    ..orderBy([(o) => OrderingTerm.asc(o.takenAt)]);
  yield* q.watch().map(
        (rows) => [
          for (final r in rows)
            ObservationSample(
              kind: r.kind,
              value: r.value,
              unit: r.unit,
              source: r.source,
              deviceName: _deviceName(r.raw),
              takenAt: r.takenAt.toLocal(),
            ),
        ],
      );
});

/// The health importer keeps the store's device attribution in the raw
/// payload under `sourceName`; the scale drivers keep nothing of the sort.
String? _deviceName(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['sourceName'] is String) {
      return decoded['sourceName'] as String;
    }
  } on FormatException {
    // Not JSON; no name.
  }
  return null;
}

/// Twelve weeks of meals, the same stream the Progress tab folds.
final _insightMealsProvider = StreamProvider<List<LoggedMeal>>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  final start = today.subtract(const Duration(days: insightWindowDays));
  final end = today.add(const Duration(days: 1));
  yield* s.meals.watchMealsBetween(start, end);
});

/// The review of the current ISO week. Null only while the streams are still
/// opening; an empty week produces a review with no sentences, and the card
/// decides what to say about that.
final weeklyReviewProvider = Provider<WeeklyReview?>((ref) {
  final meals = ref.watch(_insightMealsProvider).valueOrNull;
  final history = ref.watch(bodyHistoryProvider).valueOrNull;
  final observations = ref.watch(insightObservationsProvider).valueOrNull;
  if (meals == null || history == null || observations == null) return null;
  final now = DateTime.now();
  final since = now.subtract(const Duration(days: 28));
  return WeeklyReview.compute(
    meals: meals,
    bodyReadings: [
      for (final r in history)
        if (r.takenAt.isAfter(since)) r,
    ],
    observations: [
      for (final o in observations)
        if (o.takenAt.isAfter(since)) o,
    ],
    now: now,
  );
});

/// Which evening tags are set for [day]: the kinds whose latest `diary`
/// observation that day has value 1. Switching a tag off writes a 0 rather
/// than deleting, so the change syncs like any other row.
Set<String> tagsOn(Iterable<ObservationSample> observations, DateTime day) {
  final latest = <String, ObservationSample>{};
  for (final o in observations) {
    if (o.source != tagSource || !o.kind.startsWith('tag_')) continue;
    if (dayOf(o.takenAt) != dayOf(day)) continue;
    final seen = latest[o.kind];
    if (seen == null || o.takenAt.isAfter(seen.takenAt)) latest[o.kind] = o;
  }
  return {
    for (final e in latest.entries)
      if (e.value.value >= 1) e.key,
  };
}

/// Today's evening tags, for the sheet's toggles.
final todaysTagsProvider = Provider<Set<String>>((ref) {
  final observations =
      ref.watch(insightObservationsProvider).valueOrNull ?? const [];
  return tagsOn(observations, ref.watch(todayProvider));
});

/// Every behaviour against every next-morning outcome with data, with the
/// arm counts always and the statistic once both arms hold eight days.
final associationsProvider = Provider<List<AssociationReport>>((ref) {
  final meals = ref.watch(_insightMealsProvider).valueOrNull ?? const [];
  final observations =
      ref.watch(insightObservationsProvider).valueOrNull ?? const [];
  if (meals.isEmpty || observations.isEmpty) return const [];

  // Tag days: for each tag kind, the days whose latest tag observation is on.
  final tagDaysByKind = <String, Set<DateTime>>{};
  final tagDays = <DateTime>{};
  for (final o in observations) {
    if (o.source == tagSource && o.kind.startsWith('tag_')) {
      tagDays.add(dayOf(o.takenAt));
    }
  }
  for (final day in tagDays) {
    for (final kind in tagsOn(observations, day)) {
      tagDaysByKind.putIfAbsent(kind, () => {}).add(day);
    }
  }

  // Outcomes: one value per morning per kind. A store that reports twice in
  // a morning has its later value win, as it did for the review.
  final outcomesByKind = <String, Map<DateTime, double>>{};
  for (final o in observations) {
    if (Outcome.all.every((k) => k.kind != o.kind)) continue;
    outcomesByKind.putIfAbsent(o.kind, () => {})[dayOf(o.takenAt)] = o.value;
  }

  return AssociationReport.all(
    meals: meals,
    tagDaysByKind: tagDaysByKind,
    outcomesByKind: outcomesByKind,
  );
});
