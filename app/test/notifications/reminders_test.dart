import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/data/repositories/meal_repository.dart';
import 'package:mananu/core/notifications/reminders.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

/// Records what the service asks of the plugin, so the tests can say exactly
/// which instants would reach the phone.
class FakeScheduler implements NotificationScheduler {
  FakeScheduler({this.grant = true});

  final bool grant;
  int permissionRequests = 0;
  int cancelAllCalls = 0;
  final cancelled = <int>[];
  final scheduled = <({int id, String title, String body, DateTime at})>[];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    scheduled.add((id: id, title: title, body: body, at: at));
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls++;
}

const _rice = FoodItem(
  id: 'cofid:11-020',
  name: 'Basmati rice, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.cofid,
);

void main() {
  const planner = ReminderPlanner();
  // A Tuesday, half past six in the morning: nothing has happened yet today.
  final earlyTuesday = DateTime(2026, 9, 8, 6, 30);

  group('ReminderPlanner', () {
    test('a null time plans nothing', () {
      expect(
        planner.plan(
          kind: ReminderKind.morning,
          time: null,
          now: earlyTuesday,
          loggedToday: const {},
        ),
        isEmpty,
      );
    });

    test('plans one a day for seven days, ids in the kind\'s block', () {
      final plan = planner.plan(
        kind: ReminderKind.morning,
        time: const TimeOfDay(hour: 7, minute: 0),
        now: earlyTuesday,
        loggedToday: const {},
      );
      // Morning is kind 0, so ids 0..6; 07:00 today is still ahead of 06:30.
      expect(plan.map((p) => p.id), [0, 1, 2, 3, 4, 5, 6]);
      expect(
        plan.map((p) => p.at),
        [for (var d = 8; d <= 14; d++) DateTime(2026, 9, d, 7, 0)],
      );
    });

    test('a time already gone today starts from tomorrow', () {
      final plan = planner.plan(
        kind: ReminderKind.breakfast,
        time: const TimeOfDay(hour: 8, minute: 0),
        now: DateTime(2026, 9, 8, 9, 30),
        loggedToday: const {},
      );
      // Breakfast is kind 1: ids 101..106, six of them, 9 to 14 September.
      expect(plan.map((p) => p.id), [101, 102, 103, 104, 105, 106]);
      expect(plan.first.at, DateTime(2026, 9, 9, 8, 0));
      expect(plan.last.at, DateTime(2026, 9, 14, 8, 0));
    });

    test('exactly now counts as gone', () {
      final plan = planner.plan(
        kind: ReminderKind.lunch,
        time: const TimeOfDay(hour: 6, minute: 30),
        now: earlyTuesday,
        loggedToday: const {},
      );
      expect(plan.first.id, 201);
      expect(plan.length, 6);
    });

    test('a meal already logged in the slot skips today only', () {
      final plan = planner.plan(
        kind: ReminderKind.lunch,
        time: const TimeOfDay(hour: 13, minute: 0),
        now: earlyTuesday,
        loggedToday: const {MealSlot.lunch},
      );
      expect(plan.map((p) => p.id), [201, 202, 203, 204, 205, 206]);
      expect(plan.first.at, DateTime(2026, 9, 9, 13, 0));
    });

    test('a meal in another slot does not skip anything', () {
      final plan = planner.plan(
        kind: ReminderKind.dinner,
        time: const TimeOfDay(hour: 19, minute: 0),
        now: earlyTuesday,
        loggedToday: const {MealSlot.lunch, MealSlot.snack},
      );
      expect(plan.length, 7);
      expect(plan.first.id, 300);
    });

    test('the morning weigh-in is never skipped for a meal', () {
      final plan = planner.plan(
        kind: ReminderKind.morning,
        time: const TimeOfDay(hour: 7, minute: 0),
        now: earlyTuesday,
        loggedToday: MealSlot.values.toSet(),
      );
      expect(plan.length, 7);
    });

    test('crosses a month end by the calendar', () {
      final plan = planner.plan(
        kind: ReminderKind.morning,
        time: const TimeOfDay(hour: 7, minute: 0),
        now: DateTime(2026, 9, 28, 6, 0),
        loggedToday: const {},
      );
      expect(plan.last.at, DateTime(2026, 10, 4, 7, 0));
    });

    test('ids for cancelling cover the whole block', () {
      expect(planner.idsFor(ReminderKind.dinner), [
        300,
        301,
        302,
        303,
        304,
        305,
        306,
      ]);
    });
  });

  group('ReminderSettings', () {
    test('round-trips a time as HH:mm', () {
      const t = TimeOfDay(hour: 7, minute: 5);
      expect(ReminderSettings.encodeTime(t), '07:05');
      expect(ReminderSettings.decodeTime('07:05'), t);
      expect(
        ReminderSettings.decodeTime('19:30'),
        const TimeOfDay(hour: 19, minute: 30),
      );
    });

    test('anything unreadable is off', () {
      expect(ReminderSettings.decodeTime(null), isNull);
      expect(ReminderSettings.decodeTime(''), isNull);
      expect(ReminderSettings.decodeTime('7'), isNull);
      expect(ReminderSettings.decodeTime('25:00'), isNull);
      expect(ReminderSettings.decodeTime('12:60'), isNull);
    });

    test('is off by default, and persists through the key-value table',
        () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      final initial = await ReminderSettings.load(db);
      expect(initial.enabled, isFalse);
      expect(initial.hasAnyTime, isFalse);

      await ReminderSettings.setEnabled(db, true);
      await ReminderSettings.setTime(
        db,
        ReminderKind.lunch,
        const TimeOfDay(hour: 13, minute: 0),
      );
      final loaded = await ReminderSettings.load(db);
      expect(loaded.enabled, isTrue);
      expect(loaded.lunch, const TimeOfDay(hour: 13, minute: 0));
      expect(loaded.morning, isNull);
      expect(await db.stateValue(ReminderSettings.lunchKey), '13:00');

      await ReminderSettings.setTime(db, ReminderKind.lunch, null);
      expect((await ReminderSettings.load(db)).lunch, isNull);
    });

    test('the watch emits the whole picture, then follows changes', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await ReminderSettings.setTime(
        db,
        ReminderKind.morning,
        const TimeOfDay(hour: 7, minute: 0),
      );

      final seen = <ReminderSettings>[];
      final sub = ReminderSettings.watch(db).listen(seen.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen, hasLength(1));
      expect(seen.first.enabled, isFalse);
      expect(seen.first.morning, const TimeOfDay(hour: 7, minute: 0));

      await ReminderSettings.setEnabled(db, true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen.last.enabled, isTrue);
      expect(seen.last.morning, const TimeOfDay(hour: 7, minute: 0));
    });
  });

  group('LocalReminderService', () {
    late AppDatabase db;
    late MealRepository meals;
    late FakeScheduler fake;
    late LocalReminderService service;

    setUp(() {
      db = AppDatabase.memory();
      meals = MealRepository(db);
      fake = FakeScheduler();
      service = LocalReminderService(
        scheduler: fake,
        meals: meals,
        clock: () => earlyTuesday,
      );
    });

    tearDown(() => db.close());

    Future<void> logLunchToday() async {
      final session = WeighSession()..addTared(food: _rice, grams: 75);
      await meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 8, 12, 50),
        slot: MealSlot.lunch,
      );
    }

    test('the morning weigh-in carries its copy', () async {
      await service.scheduleMorningWeighIn(const TimeOfDay(hour: 7, minute: 0));
      expect(fake.cancelled, planner.idsFor(ReminderKind.morning));
      expect(fake.scheduled.length, 7);
      expect(fake.scheduled.first.title, 'Morning weigh-in');
      expect(
        fake.scheduled.first.body,
        'Step on the scale before breakfast — same time, bare feet.',
      );
      expect(fake.scheduled.first.at, DateTime(2026, 9, 8, 7, 0));
    });

    test('a logged lunch skips today\'s lunch reminder and nothing else',
        () async {
      await logLunchToday();
      await service.scheduleMealReminders(
        breakfast: const TimeOfDay(hour: 8, minute: 0),
        lunch: const TimeOfDay(hour: 13, minute: 0),
        dinner: const TimeOfDay(hour: 19, minute: 0),
      );
      final ids = fake.scheduled.map((s) => s.id).toList();
      expect(
        ids.where((id) => id ~/ 100 == 1),
        [100, 101, 102, 103, 104, 105, 106],
      );
      expect(ids.where((id) => id ~/ 100 == 2), [201, 202, 203, 204, 205, 206]);
      expect(
        ids.where((id) => id ~/ 100 == 3),
        [300, 301, 302, 303, 304, 305, 306],
      );
      expect(
        fake.scheduled.every(
          (s) =>
              s.body ==
              'Weigh it as you plate it. Thirty seconds now saves guessing '
                  'later.',
        ),
        isTrue,
      );
      // Every id in the three blocks was cleared before scheduling.
      expect(fake.cancelled.toSet(), {
        ...planner.idsFor(ReminderKind.breakfast),
        ...planner.idsFor(ReminderKind.lunch),
        ...planner.idsFor(ReminderKind.dinner),
      });
    });

    test('a deleted meal brings the reminder back', () async {
      await logLunchToday();
      final id = (await meals.watchMealsForDay(earlyTuesday).first).single.id;
      await meals.deleteMeal(id);
      await service.scheduleMealReminders(
        lunch: const TimeOfDay(hour: 13, minute: 0),
      );
      expect(
        fake.scheduled.map((s) => s.id).where((id) => id ~/ 100 == 2).first,
        200,
      );
    });

    test('a slot with no time is cleared, not scheduled', () async {
      await service.scheduleMealReminders(
        lunch: const TimeOfDay(hour: 13, minute: 0),
      );
      final ids = fake.scheduled.map((s) => s.id);
      expect(ids.any((id) => id ~/ 100 == 1), isFalse);
      expect(ids.any((id) => id ~/ 100 == 3), isFalse);
      expect(fake.cancelled, containsAll(planner.idsFor(ReminderKind.dinner)));
    });

    test('apply with the master switch off cancels everything', () async {
      await service.apply(
        const ReminderSettings(morning: TimeOfDay(hour: 7, minute: 0)),
      );
      expect(fake.cancelAllCalls, 1);
      expect(fake.scheduled, isEmpty);
    });

    test('apply with the master switch on schedules what is set', () async {
      await service.apply(
        const ReminderSettings(
          enabled: true,
          morning: TimeOfDay(hour: 7, minute: 0),
          dinner: TimeOfDay(hour: 19, minute: 0),
        ),
      );
      expect(fake.cancelAllCalls, 0);
      final blocks = fake.scheduled.map((s) => s.id ~/ 100).toSet();
      expect(blocks, {0, 3});
      // At most one per kind per day.
      final perDay = <String, int>{};
      for (final s in fake.scheduled) {
        final key = '${s.id ~/ 100}:${s.at.day}';
        perDay[key] = (perDay[key] ?? 0) + 1;
      }
      expect(perDay.values.every((n) => n == 1), isTrue);
    });

    test('permission goes straight through to the plugin', () async {
      expect(await service.requestPermission(), isTrue);
      expect(fake.permissionRequests, 1);
      final denied = LocalReminderService(
        scheduler: FakeScheduler(grant: false),
        meals: meals,
      );
      expect(await denied.requestPermission(), isFalse);
    });
  });
}
