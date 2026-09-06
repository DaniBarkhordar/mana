/// The general store: one row per measurement from any source.
///
/// A scale reading, a night's HRV and a ferritin result all land here with a
/// kind, a value, a unit and a source. The trend that works for body fat works
/// for ferritin unchanged. New sources are new [source] values, never new
/// tables (CLAUDE.md rule 7).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';

/// One point on a trend line.
typedef ObservationPoint = ({DateTime at, double value});

class ObservationRepository {
  ObservationRepository(this._db);

  final AppDatabase _db;

  Future<String> record({
    required String kind,
    required double value,
    required String unit,
    required String source,
    required DateTime takenAt,
    String? method,
    String? confidence,
    String? deviceId,
    double? referenceLow,
    double? referenceHigh,
    String? referenceSource,
    Map<String, Object?>? raw,
  }) async {
    final userId = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final id = AppDatabase.newId();
    await _db.into(_db.observations).insert(
          ObservationsCompanion.insert(
            id: id,
            userId: userId,
            takenAt: takenAt.toUtc(),
            kind: kind,
            value: value,
            unit: unit,
            source: source,
            deviceId: Value(deviceId),
            method: Value(method),
            confidence: Value(confidence),
            referenceLow: Value(referenceLow),
            referenceHigh: Value(referenceHigh),
            referenceSource: Value(referenceSource),
            raw: Value(raw == null ? null : jsonEncode(raw)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// A series for one kind, oldest first, for the trend smoother.
  Stream<List<ObservationPoint>> watchSeries(
    String kind, {
    DateTime? since,
    int limit = 1000,
  }) {
    final q = _db.select(_db.observations)
      ..where((o) => o.kind.equals(kind) & o.deletedAt.isNull())
      ..orderBy([(o) => OrderingTerm.desc(o.takenAt)])
      ..limit(limit);
    if (since != null) {
      q.where((o) => o.takenAt.isBiggerOrEqualValue(since.toUtc()));
    }
    return q.watch().map(
          (rows) => [
            for (final r in rows.reversed)
              (at: r.takenAt.toLocal(), value: r.value),
          ],
        );
  }

  /// The distinct sources that have ever reported, for the Settings screen's
  /// "which device said what".
  Future<List<String>> sources() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT source FROM observations WHERE deleted_at IS NULL '
      'ORDER BY source',
      readsFrom: {_db.observations},
    ).get();
    return [for (final r in rows) r.read<String>('source')];
  }
}
