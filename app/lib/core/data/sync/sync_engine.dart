/// Background sync: pull what is newer, push what is unsynced.
///
/// The engine moves rows as plain maps, driven by [syncTables] and the
/// column types Drift already knows, so adding a table means adding a spec,
/// not code. Conflict resolution is last-write-wins on `updated_at`, which is
/// right for a single-user diary: the same person on two phones, not two
/// people editing one document.
///
/// Order matters and is deliberate — pull first, then push. A row edited
/// offline on this phone but edited later on another is dropped here in the
/// pull, before it can overwrite the newer version on the server.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';
import 'sync_remote.dart';

class SyncReport {
  const SyncReport({
    required this.outcome,
    this.pushed = 0,
    this.pulled = 0,
    this.error,
  });

  const SyncReport.noSession() : this(outcome: SyncOutcome.noSession);
  const SyncReport.busy() : this(outcome: SyncOutcome.busy);

  final SyncOutcome outcome;
  final int pushed;
  final int pulled;
  final Object? error;

  bool get succeeded => outcome == SyncOutcome.synced;

  @override
  String toString() =>
      'SyncReport(${outcome.name}, pushed: $pushed, pulled: $pulled'
      '${error == null ? '' : ', error: $error'})';
}

enum SyncOutcome {
  synced,

  /// No session and none could be established. Everything stays local.
  noSession,

  /// A sync was already running.
  busy,

  /// Network or server error. Rows stay marked unsynced and are retried.
  failed,
}

class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncRemote remote,
    this.pageSize = 500,
  })  : _db = db,
        _remote = remote;

  final AppDatabase _db;
  final SyncRemote _remote;
  final int pageSize;

  bool _running = false;

  bool get isRunning => _running;

  /// True when any row on this device has not reached the server.
  Future<bool> hasPendingChanges() async {
    for (final spec in syncTables) {
      final row = await _db
          .customSelect(
            'SELECT COUNT(*) AS n FROM ${spec.name} WHERE ${_dirtyWhere(spec)}',
          )
          .getSingle();
      if (row.read<int>('n') > 0) return true;
    }
    return false;
  }

  Future<SyncReport> syncNow() async {
    if (_running) return const SyncReport.busy();
    _running = true;
    try {
      final uid = await _remote.ensureUserId();
      if (uid == null) return const SyncReport.noSession();
      await _db.adoptUser(uid);

      var pulled = 0;
      var pushed = 0;
      for (final spec in syncTables) {
        pulled += await _pull(spec, uid);
      }
      for (final spec in syncTables) {
        pushed += await _push(spec, uid);
      }
      return SyncReport(
        outcome: SyncOutcome.synced,
        pushed: pushed,
        pulled: pulled,
      );
    } on Object catch (e) {
      return SyncReport(outcome: SyncOutcome.failed, error: e);
    } finally {
      _running = false;
    }
  }

  // ---------------------------------------------------------------- pull

  String _cursorKey(SyncTableSpec spec) => 'last_pull:${spec.name}';

  Future<int> _pull(SyncTableSpec spec, String uid) async {
    final table = _db.tableNamed(spec.name);
    final sinceText = await _db.stateValue(_cursorKey(spec));
    final since = sinceText == null ? null : DateTime.parse(sinceText);
    var cursor = since;
    var applied = 0;

    while (true) {
      final rows = await _remote.pullSince(
        spec.name,
        userColumn: spec.userColumn,
        userId: uid,
        cursorColumn: spec.cursorColumn,
        since: cursor,
        limit: pageSize,
      );
      if (rows.isEmpty) break;
      for (final remote in rows) {
        if (await _applyRemote(spec, table, remote)) applied++;
        final t = _parseTimestamp(remote[spec.cursorColumn]);
        if (t != null && (cursor == null || t.isAfter(cursor))) cursor = t;
      }
      if (rows.length < pageSize) break;
    }

    if (cursor != null && cursor != since) {
      await _db.setStateValue(
        _cursorKey(spec),
        cursor.toUtc().toIso8601String(),
      );
    }
    return applied;
  }

  /// Writes a remote row locally unless this phone holds a newer, unsynced
  /// edit of it. Returns whether anything was written.
  Future<bool> _applyRemote(
    SyncTableSpec spec,
    TableInfo<Table, dynamic> table,
    Map<String, Object?> remote,
  ) async {
    final id = remote['id']?.toString();
    if (id == null) return false;

    final local = await _db.customSelect(
      'SELECT * FROM ${spec.name} WHERE id = ?',
      variables: [Variable.withString(id)],
    ).getSingleOrNull();

    if (local != null) {
      if (spec.insertOnly) return false;
      final localUpdated = _parseTimestamp(local.data['updated_at']);
      final localSynced = _parseTimestamp(local.data['synced_at']);
      final remoteUpdated = _parseTimestamp(remote[spec.cursorColumn]);
      final dirty = localSynced == null ||
          (localUpdated != null && !localUpdated.isAtSameMomentAs(localSynced));
      if (dirty &&
          localUpdated != null &&
          remoteUpdated != null &&
          !localUpdated.isBefore(remoteUpdated)) {
        return false; // Ours is newer; it goes up in the push.
      }
    }

    final row = _fromRemote(table, remote);
    // The version we now hold is, by definition, the synced one.
    row['synced_at'] = row[spec.cursorColumn];
    final columns = row.keys.toList();
    await _db.customInsert(
      'INSERT OR REPLACE INTO ${spec.name} (${columns.join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')})',
      variables: [for (final c in columns) Variable(row[c])],
      updates: {table},
    );
    return true;
  }

  // ---------------------------------------------------------------- push

  /// A row is dirty until `synced_at` equals the `updated_at` that was sent.
  /// Recording the synced *version* rather than a time keeps this immune to
  /// clock skew between the phone and the server.
  String _dirtyWhere(SyncTableSpec spec) => spec.insertOnly
      ? 'synced_at IS NULL'
      : '(synced_at IS NULL OR updated_at <> synced_at)';

  Future<int> _push(SyncTableSpec spec, String uid) async {
    final table = _db.tableNamed(spec.name);
    var total = 0;
    final sent = <Object?>{};
    while (true) {
      final rows = await _db.customSelect(
        'SELECT * FROM ${spec.name} WHERE ${spec.userColumn} = ? '
        'AND ${_dirtyWhere(spec)} ORDER BY ${spec.cursorColumn} LIMIT ?',
        variables: [Variable.withString(uid), Variable.withInt(pageSize)],
      ).get();
      if (rows.isEmpty) break;
      // A row that comes round again was not marked after its push; stop
      // rather than spin. It will be retried on the next sync.
      if (rows.any((r) => sent.contains(r.data['id']))) break;
      sent.addAll(rows.map((r) => r.data['id']));

      await _remote.upsert(
        spec.name,
        [for (final r in rows) _toRemote(table, r.data)],
        insertOnly: spec.insertOnly,
      );

      for (final r in rows) {
        // Only mark the version we sent. An edit made while the request was
        // in flight changes updated_at, so it stays dirty and goes next.
        final version = r.data[spec.cursorColumn];
        await _db.customUpdate(
          spec.insertOnly
              ? 'UPDATE ${spec.name} SET synced_at = ? WHERE id = ?'
              : 'UPDATE ${spec.name} SET synced_at = ? WHERE id = ? '
                  'AND updated_at = ?',
          variables: [
            Variable(version),
            Variable(r.data['id']),
            if (!spec.insertOnly) Variable(version),
          ],
          updates: {table},
          updateKind: UpdateKind.update,
        );
      }
      total += rows.length;
      if (rows.length < pageSize) break;
    }
    return total;
  }

  // ---------------------------------------------------------------- codecs

  /// A local row as the server expects it: JSON text decoded to objects,
  /// SQLite integers back to booleans, `synced_at` dropped.
  static Map<String, Object?> _toRemote(
    TableInfo<Table, dynamic> table,
    Map<String, Object?> local,
  ) {
    final spec = syncTables.firstWhere((s) => s.name == table.actualTableName);
    final out = <String, Object?>{};
    for (final entry in local.entries) {
      final name = entry.key;
      if (name == 'synced_at') continue;
      final column = table.columnsByName[name];
      if (column == null) continue;
      var value = entry.value;
      if (value != null) {
        if (column.type == DriftSqlType.bool) {
          value = value == 1 || value == true;
        } else if (spec.jsonColumns.contains(name) && value is String) {
          value = jsonDecode(value);
        }
      }
      out[name] = value;
    }
    return out;
  }

  /// A server row as SQLite stores it. Unknown columns (generated tsvectors,
  /// server-only fields) are dropped; timestamps are normalised to UTC ISO so
  /// text comparison in SQL works.
  static Map<String, Object?> _fromRemote(
    TableInfo<Table, dynamic> table,
    Map<String, Object?> remote,
  ) {
    final spec = syncTables.firstWhere((s) => s.name == table.actualTableName);
    final out = <String, Object?>{};
    for (final column in table.$columns) {
      final name = column.$name;
      if (name == 'synced_at' || !remote.containsKey(name)) continue;
      var value = remote[name];
      if (value != null) {
        switch (column.type) {
          case DriftSqlType.bool:
            value = (value == true || value == 1) ? 1 : 0;
          case DriftSqlType.dateTime:
            value = _parseTimestamp(value)?.toUtc().toIso8601String();
          case DriftSqlType.int:
            value = (value as num).toInt();
          case DriftSqlType.double:
            value = (value as num).toDouble();
          case DriftSqlType.string:
            if (spec.jsonColumns.contains(name) && value is! String) {
              value = jsonEncode(value);
            } else {
              value = value.toString();
            }
          default:
            break;
        }
      }
      out[name] = value;
    }
    return out;
  }

  static DateTime? _parseTimestamp(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
