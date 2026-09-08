/// The Body tab's own wiring: the baseline view of the wearable kinds, the
/// body-fat series for its chart, and the bookkeeping for the reading moment.
///
/// Reads SQLite through streams like everything else; the maths lives in
/// core/health/baselines.dart so it can be checked without a widget tree.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bia/body_composition.dart';
import '../../core/data/providers.dart';
import '../../core/health/baselines.dart';

/// The Body tab's position in the shell's navigation bar: the reading reveal
/// is only shown when this tab is the one on screen.
const int bodyTabIndex = 1;

/// The kinds the baseline card shows, in order, with their labels. The two
/// HRV kinds are alternatives: Apple Health exports SDNN, Health Connect
/// RMSSD, and a phone rarely has both.
const wearableBaselineKinds = <(String kind, String label)>[
  ('sleep_minutes', 'Sleep'),
  ('hrv_sdnn_ms', 'HRV'),
  ('hrv_rmssd_ms', 'HRV'),
  ('resting_hr_bpm', 'Resting HR'),
  ('steps', 'Steps'),
];

/// Minimum earlier points before a baseline is quoted.
const int baselineMinPoints = 5;

/// One wearable kind on the card: last night's figure, the person's usual,
/// and which device said so.
class WearableBaselineView {
  const WearableBaselineView({
    required this.kind,
    required this.label,
    required this.baseline,
    required this.source,
    this.sourceName,
  });

  final String kind;
  final String label;
  final PersonalBaseline baseline;

  /// The observation's source id: 'apple_health', 'health_connect'.
  final String source;

  /// The device the store attributed the value to ('Oura'), when it named
  /// one. From the row's raw payload.
  final String? sourceName;
}

/// Where the latest observation of [kind] came from. The device name rides
/// in the raw payload the importer keeps, so it is read from there.
final wearableProvenanceProvider =
    StreamProvider.family<({String source, String? sourceName})?, String>(
        (ref, kind) async* {
  final s = await ref.watch(appServicesProvider.future);
  final q = s.db.select(s.db.observations)
    ..where((o) => o.kind.equals(kind) & o.deletedAt.isNull())
    ..orderBy([(o) => OrderingTerm.desc(o.takenAt)])
    ..limit(1);
  yield* q.watch().map((rows) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    String? name;
    final raw = row.raw;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['sourceName'] is String) {
          name = decoded['sourceName'] as String;
        }
      } on FormatException {
        // A payload that is not JSON has no name to offer; the store's own
        // label is still shown.
      }
    }
    return (source: row.source, sourceName: name);
  });
});

/// Enough history for a 30-day baseline behind a point up to a week old.
final _wearableSeriesProvider =
    StreamProvider.family<List<BaselinePoint>, String>((ref, kind) async* {
  final s = await ref.watch(appServicesProvider.future);
  final today = ref.watch(todayProvider);
  yield* s.observations.watchSeries(
    kind,
    since: today.subtract(const Duration(days: 38)),
  );
});

/// Every wearable kind with a point in the last week, against its baseline.
/// Empty when the phone has no wearable data, so the card is not drawn.
final wearableBaselinesProvider = Provider<List<WearableBaselineView>>((ref) {
  final asOf = DateTime.now();
  final out = <WearableBaselineView>[];
  var hrvShown = false;
  for (final (kind, label) in wearableBaselineKinds) {
    final isHrv = kind.startsWith('hrv_');
    if (isHrv && hrvShown) continue;
    final series = ref.watch(_wearableSeriesProvider(kind)).valueOrNull;
    if (series == null || series.isEmpty) continue;
    final b = baselineFor(series, asOf: asOf, minPoints: baselineMinPoints);
    if (b == null) continue;
    final provenance = ref.watch(wearableProvenanceProvider(kind)).valueOrNull;
    out.add(
      WearableBaselineView(
        kind: kind,
        label: label,
        baseline: b,
        source: provenance?.source ?? 'apple_health',
        sourceName: provenance?.sourceName,
      ),
    );
    if (isHrv) hrvShown = true;
  }
  return out;
});

/// Body fat as a series for the chart: only readings where an equation
/// actually ran on a measured impedance. A weight-only reading has no
/// body-fat point, rather than a zero.
final bodyFatSeriesProvider = Provider<List<({DateTime at, double value})>>(
  (ref) {
    final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
    return [
      for (final r in history)
        if (r.metric('bodyFatPercent') case final m?
            when m.derived == Derived.predicted)
          (at: r.takenAt, value: m.value),
    ];
  },
);

/// The stable sample the reading reveal was last shown for. One measurement
/// produces exactly one stable sample, so its timestamp is the guard against
/// showing the moment twice.
final revealedReadingProvider = StateProvider<DateTime?>((ref) => null);
