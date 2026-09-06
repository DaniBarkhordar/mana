import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/data/repositories/body_repository.dart';
import 'package:mananu/core/data/repositories/meal_repository.dart';
import 'package:mananu/core/data/repositories/observation_repository.dart';
import 'package:mananu/core/data/repositories/profile_repository.dart';
import 'package:mananu/core/data/sync/sync_engine.dart';
import 'package:mananu/core/data/sync/sync_remote.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

/// A server in a map. Keeps whatever it is given, so the tests control every
/// timestamp; the real server stamps `updated_at` itself on update, which the
/// pull-then-push order in the engine is designed for either way.
class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({this.userId = 'uid-1'});

  String? userId;
  final tables = <String, Map<String, Map<String, Object?>>>{};
  final upserts = <(String, List<Map<String, Object?>>)>[];
  bool failNext = false;

  Map<String, Map<String, Object?>> table(String name) =>
      tables.putIfAbsent(name, () => {});

  @override
  Future<String?> ensureUserId() async => userId;

  @override
  Future<void> upsert(
    String table,
    List<Map<String, Object?>> rows, {
    bool insertOnly = false,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('network down');
    }
    upserts.add((table, rows));
    final t = this.table(table);
    for (final row in rows) {
      final id = row['id'] as String;
      if (insertOnly && t.containsKey(id)) continue;
      t[id] = Map.of(row);
    }
  }

  @override
  Future<List<Map<String, Object?>>> pullSince(
    String table, {
    required String userColumn,
    required String userId,
    required String cursorColumn,
    DateTime? since,
    int limit = 500,
  }) async {
    final rows = this
        .table(table)
        .values
        .where((r) => r[userColumn] == userId)
        .where((r) {
      if (since == null) return true;
      final t = DateTime.parse(r[cursorColumn] as String);
      return t.isAfter(since);
    }).toList()
      ..sort(
        (a, b) =>
            (a[cursorColumn] as String).compareTo(b[cursorColumn] as String),
      );
    return rows.take(limit).map(Map<String, Object?>.of).toList();
  }
}

void main() {
  late AppDatabase db;
  late FakeSyncRemote remote;
  late SyncEngine engine;
  late MealRepository meals;
  late ProfileRepository profiles;

  const riceDry = FoodItem(
    id: 'cofid:11-020',
    name: 'Basmati rice, dry',
    per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
    source: NutritionSource.cofid,
  );

  Future<String> logRice() {
    final session = WeighSession()..addTared(food: riceDry, grams: 75);
    return meals.logMeal(
      components: session.components,
      eatenAt: DateTime(2026, 9, 6, 8),
      slot: MealSlot.breakfast,
    );
  }

  setUp(() {
    db = AppDatabase.memory();
    remote = FakeSyncRemote();
    engine = SyncEngine(db: db, remote: remote, pageSize: 2);
    meals = MealRepository(db);
    profiles = ProfileRepository(db);
  });

  tearDown(() => db.close());

  test('with no session, nothing moves and everything stays pending', () async {
    remote.userId = null;
    await logRice();
    final report = await engine.syncNow();
    expect(report.outcome, SyncOutcome.noSession);
    expect(remote.upserts, isEmpty);
    expect(await engine.hasPendingChanges(), isTrue);
  });

  test('push sends unsynced rows, re-keyed to the real uid, and marks them',
      () async {
    await logRice();
    final report = await engine.syncNow();
    expect(report.outcome, SyncOutcome.synced);
    expect(report.pushed, 2); // one meal, one component
    expect(await engine.hasPendingChanges(), isFalse);

    final meal = remote.table('meals').values.single;
    expect(meal['user_id'], 'uid-1');
    expect(meal.containsKey('synced_at'), isFalse);
    expect(meal['slot'], 'breakfast');
    final component = remote.table('meal_components').values.single;
    expect(component['is_cooking_fat'], isFalse); // a bool, not 0
    expect(component['grams'], 75.0);

    final local =
        (await meals.watchMealsForDay(DateTime(2026, 9, 6)).first).single;
    expect(local.isSynced, isTrue);
  });

  test('a failed push leaves rows pending and reports the failure', () async {
    await logRice();
    remote.failNext = true;
    final report = await engine.syncNow();
    expect(report.outcome, SyncOutcome.failed);
    expect(await engine.hasPendingChanges(), isTrue);
    // The next attempt succeeds.
    expect((await engine.syncNow()).outcome, SyncOutcome.synced);
    expect(await engine.hasPendingChanges(), isFalse);
  });

  test('an edit made after the push is pending again', () async {
    final id = await logRice();
    await engine.syncNow();
    await meals.deleteMeal(id);
    expect(await engine.hasPendingChanges(), isTrue);
    final report = await engine.syncNow();
    expect(report.pushed, 2);
    expect(remote.table('meals')[id]!['deleted_at'], isNotNull);
  });

  test('pull writes rows from another device into SQLite', () async {
    await db.adoptUser('uid-1');
    remote.table('meals')['m-remote'] = {
      'id': 'm-remote',
      'user_id': 'uid-1',
      'eaten_at': '2026-08-30T12:00:00+00:00',
      'slot': 'lunch',
      'note': null,
      'photo_path': null,
      'created_at': '2026-08-30T12:01:00+00:00',
      'updated_at': '2026-08-30T12:01:00+00:00',
      'deleted_at': null,
      'server_only_column': 'ignored',
    };
    remote.table('meal_components')['c-remote'] = {
      'id': 'c-remote',
      'meal_id': 'm-remote',
      'user_id': 'uid-1',
      'food_id': null,
      'food_name': 'Chicken breast, grilled',
      'food_source': 'cofid',
      'grams': 160,
      'method': 'weighed',
      'kcal': 264,
      'protein_g': 49.6,
      'carb_g': 0,
      'fat_g': 5.76,
      'is_cooking_fat': false,
      'estimated_grams': null,
      'position': 0,
      'note': null,
      'created_at': '2026-08-30T12:01:00+00:00',
      'updated_at': '2026-08-30T12:01:00+00:00',
      'deleted_at': null,
    };

    final report = await engine.syncNow();
    expect(report.pulled, 2);
    final today = await meals.watchMealsForDay(DateTime(2026, 8, 30)).first;
    expect(today, hasLength(1));
    expect(today.single.isSynced, isTrue);
    expect(today.single.slot, MealSlot.lunch);
    expect(today.single.components.single.grams, 160.0);
    expect(
      today.single.components.single.food.per100g.kcal,
      closeTo(165, 1e-6),
    );
    // Pulled rows are not pushed back.
    expect(await engine.hasPendingChanges(), isFalse);
    expect(remote.upserts, isEmpty);
  });

  test('a newer local edit beats an older remote row', () async {
    final id = await logRice();
    await engine.syncNow();
    // Another device deleted it, a week before our edit below.
    final serverRow = Map<String, Object?>.of(remote.table('meals')[id]!);
    serverRow['deleted_at'] = '2026-08-30T09:00:00+00:00';
    serverRow['updated_at'] = '2026-08-30T09:00:00+00:00';
    remote.table('meals')[id] = serverRow;
    // Reset the cursor so the pull sees it.
    await db.setStateValue('last_pull:meals', '2026-01-01T00:00:00.000Z');

    // Our edit is "now", which is later than 30 August.
    await meals.deleteMeal(id);
    final local = (await db.select(db.meals).get()).single;
    expect(local.updatedAt.isAfter(DateTime.utc(2026, 8, 30, 9)), isTrue);

    await engine.syncNow();
    final pushedMeal = remote.table('meals')[id]!;
    expect(pushedMeal['updated_at'], local.updatedAt.toIso8601String());
  });

  test('an older local edit loses to a newer remote row', () async {
    final id = await logRice();
    await engine.syncNow();
    // Make our local copy dirty but old.
    await db.customUpdate(
      "UPDATE meals SET note = 'mine', "
      "updated_at = '2026-01-01T00:00:00.000Z', synced_at = NULL",
    );
    final serverRow = Map<String, Object?>.of(remote.table('meals')[id]!);
    serverRow['note'] = 'theirs';
    serverRow['updated_at'] = '2026-06-01T00:00:00+00:00';
    remote.table('meals')[id] = serverRow;
    await db.setStateValue('last_pull:meals', '2026-01-01T00:00:00.000Z');

    await engine.syncNow();
    final local = (await db.select(db.meals).get()).single;
    expect(local.note, 'theirs');
    expect(remote.table('meals')[id]!['note'], 'theirs');
  });

  test('the pull cursor advances so rows are not re-fetched', () async {
    await db.adoptUser('uid-1');
    remote.table('meals')['m1'] = {
      'id': 'm1',
      'user_id': 'uid-1',
      'eaten_at': '2026-08-30T12:00:00+00:00',
      'slot': 'lunch',
      'created_at': '2026-08-30T12:01:00+00:00',
      'updated_at': '2026-08-30T12:01:00+00:00',
    };
    expect((await engine.syncNow()).pulled, 1);
    expect((await engine.syncNow()).pulled, 0);
    expect(
      await db.stateValue('last_pull:meals'),
      '2026-08-30T12:01:00.000Z',
    );
  });

  test('paging pulls everything, not just the first page', () async {
    await db.adoptUser('uid-1');
    for (var i = 0; i < 5; i++) {
      remote.table('meals')['m$i'] = {
        'id': 'm$i',
        'user_id': 'uid-1',
        'eaten_at': '2026-08-30T1$i:00:00+00:00',
        'slot': 'snack',
        'created_at': '2026-08-30T1$i:00:00+00:00',
        'updated_at': '2026-08-30T1$i:00:00+00:00',
      };
    }
    expect((await engine.syncNow()).pulled, 5);
    expect(await db.select(db.meals).get(), hasLength(5));
  });

  test('consents push as insert-only and never re-push', () async {
    await profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: '1',
        granted: true,
        grantedAt: DateTime(2026, 9, 6),
      ),
    );
    var report = await engine.syncNow();
    expect(report.pushed, 1);
    expect(remote.table('consents').values.single['granted'], isTrue);
    report = await engine.syncNow();
    expect(report.pushed, 0);
  });

  test('JSON columns cross as objects and land back as text', () async {
    const input = BiaInput(
      heightCm: 178,
      weightKg: 80,
      ageYears: 34,
      sex: Sex.male,
      resistanceOhm: 500,
    );
    final observations = ObservationRepository(db);
    final body = BodyRepository(db, observations);
    final result = const BodyCompositionEngine().evaluate(
      input: input,
      takenAt: DateTime(2026, 9, 6, 7),
      context: const MeasurementContext(afterExercise: true),
    );
    await body.record(
      result: result,
      input: input,
      source: 'test',
      raw: {'kg': 80.0},
    );
    await engine.syncNow();

    final remoteRow = remote.table('body_measurements').values.single;
    expect(remoteRow['context'], isA<Map<String, Object?>>());
    expect((remoteRow['context'] as Map)['after_exercise'], isTrue);
    expect(remoteRow['notes'], isA<List<Object?>>());
    final remoteObs = remote.table('observations').values.firstWhere(
          (r) => r['kind'] == 'weight_kg',
        );
    expect(remoteObs['raw'], {'kg': 80.0});

    // Round trip: wipe local, pull, and the reading reconstructs.
    await db.customUpdate('DELETE FROM body_measurements');
    await db.setStateValue(
      'last_pull:body_measurements',
      '2026-01-01T00:00:00.000Z',
    );
    await engine.syncNow();
    final back = (await body.watchHistory().first).single;
    expect(back.confidence, ReadingConfidence.fair);
    expect(back.notes.join(' ').toLowerCase(), contains('sweat'));
  });

  test('sync is not re-entrant', () async {
    await logRice();
    final first = engine.syncNow();
    final second = await engine.syncNow();
    expect(second.outcome, SyncOutcome.busy);
    expect((await first).outcome, SyncOutcome.synced);
  });
}
