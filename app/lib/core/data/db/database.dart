/// The local database. Everything the app shows is read from here; the network
/// only ever fills it in the background.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'database.g.dart';

/// Describes one synced table to the sync engine, which otherwise works on
/// plain maps and never needs per-table code.
class SyncTableSpec {
  const SyncTableSpec({
    required this.name,
    required this.userColumn,
    this.hasTombstone = true,
    this.insertOnly = false,
    this.jsonColumns = const {},
    this.timestampColumns = const {},
    this.cursorColumn = 'updated_at',
  });

  final String name;

  /// The column pulls page on and last-write-wins compares. `granted_at` for
  /// the insert-only consents table, which has no updated_at.
  final String cursorColumn;

  /// Which column carries the owning user id (`id` on profiles).
  final String userColumn;

  /// False for tables the server has no `deleted_at` on.
  final bool hasTombstone;

  /// Consents: the server allows insert and select only.
  final bool insertOnly;

  /// Stored as JSON text locally, as jsonb remotely.
  final Set<String> jsonColumns;

  /// Normalised to UTC ISO-8601 in both directions.
  final Set<String> timestampColumns;
}

const _syncTimestamps = {'created_at', 'updated_at', 'deleted_at'};

/// Push order matters: parents before children so a foreign key on the server
/// never sees a child first.
const syncTables = <SyncTableSpec>[
  SyncTableSpec(
    name: 'profiles',
    userColumn: 'id',
    hasTombstone: false,
    timestampColumns: {'created_at', 'updated_at'},
  ),
  SyncTableSpec(
    name: 'foods',
    userColumn: 'user_id',
    jsonColumns: {'household_measures'},
    timestampColumns: _syncTimestamps,
  ),
  SyncTableSpec(
    name: 'recipes',
    userColumn: 'user_id',
    jsonColumns: {'ingredients'},
    timestampColumns: _syncTimestamps,
  ),
  SyncTableSpec(
    name: 'meals',
    userColumn: 'user_id',
    timestampColumns: {..._syncTimestamps, 'eaten_at'},
  ),
  SyncTableSpec(
    name: 'meal_components',
    userColumn: 'user_id',
    timestampColumns: _syncTimestamps,
  ),
  SyncTableSpec(
    name: 'body_measurements',
    userColumn: 'user_id',
    jsonColumns: {'segmental_raw', 'context', 'notes'},
    timestampColumns: {..._syncTimestamps, 'taken_at'},
  ),
  SyncTableSpec(
    name: 'observations',
    userColumn: 'user_id',
    jsonColumns: {'raw'},
    timestampColumns: {..._syncTimestamps, 'taken_at'},
  ),
  SyncTableSpec(
    name: 'daily_targets',
    userColumn: 'user_id',
    timestampColumns: _syncTimestamps,
  ),
  SyncTableSpec(
    name: 'consents',
    userColumn: 'user_id',
    hasTombstone: false,
    insertOnly: true,
    timestampColumns: {'granted_at'},
    cursorColumn: 'granted_at',
  ),
];

@DriftDatabase(
  tables: [
    Profiles,
    Consents,
    Observations,
    BodyMeasurements,
    Meals,
    MealComponents,
    Foods,
    Recipes,
    DailyTargets,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory, for tests and for the widget preview.
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// The on-device file. Documents, not caches: this is the user's diary and
  /// must not be evicted.
  ///
  /// It holds health data, so it must stay out of cloud backups (CLAUDE.md,
  /// "Don't"). Android: `allowBackup="false"` in the manifest, set. iOS: the
  /// file needs `NSURLIsExcludedFromBackupKey`, which takes a few lines of
  /// native code — open item for the iOS build, tracked in HANDOFF.md Phase 4.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mananu.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  static const _uuid = Uuid();

  static String newId() => _uuid.v4();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  TableInfo<Table, dynamic> tableNamed(String name) =>
      allTables.firstWhere((t) => t.actualTableName == name);

  // ---------------------------------------------------------------- state

  Future<String?> stateValue(String key) async {
    final row = await (select(syncState)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setStateValue(String key, String value) =>
      into(syncState).insertOnConflictUpdate(
        SyncStateCompanion(key: Value(key), value: Value(value)),
      );

  static const localUserKey = 'local_user_id';

  /// The id every local row is owned by. A random placeholder until sign-in
  /// (anonymous or otherwise) hands us a real uid, at which point
  /// [adoptUser] re-keys everything in one pass.
  Future<String> localUserId() async {
    final existing = await stateValue(localUserKey);
    if (existing != null) return existing;
    final id = newId();
    await setStateValue(localUserKey, id);
    return id;
  }

  /// Re-keys every row from the placeholder id to [uid]. Idempotent.
  Future<void> adoptUser(String uid) async {
    final current = await localUserId();
    if (current == uid) return;
    await transaction(() async {
      for (final spec in syncTables) {
        await customUpdate(
          'UPDATE ${spec.name} SET ${spec.userColumn} = ? '
          'WHERE ${spec.userColumn} = ?',
          variables: [Variable.withString(uid), Variable.withString(current)],
          updates: {tableNamed(spec.name)},
        );
      }
      await setStateValue(localUserKey, uid);
    });
  }
}
