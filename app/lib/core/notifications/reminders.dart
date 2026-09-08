/// Gentle reminders that respect the person.
///
/// Two things are worth a nudge: stepping on the scale in the morning, and
/// weighing food as it goes on the plate. Neither is worth nagging about, so
/// the rules are fixed here rather than left to a settings screen:
///
/// * everything is off until the person switches it on;
/// * at most one reminder per meal slot and one for the morning, per day;
/// * a meal reminder is skipped when a meal in that slot is already logged
///   today — a reminder to do something already done is the definition of
///   a nag;
/// * scheduling is inexact, so Android never asks for the exact-alarm
///   permission and a reminder arriving a few minutes late is by design.
///
/// The plugin sits behind [NotificationScheduler] so the planning and the
/// skip rule are tested against a fake, and [ReminderService] is itself an
/// interface so the settings screen can be tested without either.
///
/// Reminders are scheduled as individual one-shot notifications for the next
/// [ReminderPlanner.horizonDays] days rather than as a repeating rule. That is
/// what lets today's be skipped when the meal is logged, and it means an app
/// nobody opens for a week goes quiet on its own instead of reminding forever.
/// Every instant is handed over in UTC, so no time-zone lookup is needed and a
/// clock change between now and then cannot shift the local time.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/db/database.dart';
import '../data/models.dart';
import '../data/repositories/meal_repository.dart';

/// The four reminders the app can send, with the copy for each.
enum ReminderKind {
  morning(
    title: 'Morning weigh-in',
    body: 'Step on the scale before breakfast — same time, bare feet.',
    slot: null,
  ),
  breakfast(
    title: 'Breakfast',
    body: 'Weigh it as you plate it. Thirty seconds now saves guessing later.',
    slot: MealSlot.breakfast,
  ),
  lunch(
    title: 'Lunch',
    body: 'Weigh it as you plate it. Thirty seconds now saves guessing later.',
    slot: MealSlot.lunch,
  ),
  dinner(
    title: 'Dinner',
    body: 'Weigh it as you plate it. Thirty seconds now saves guessing later.',
    slot: MealSlot.dinner,
  );

  const ReminderKind({
    required this.title,
    required this.body,
    required this.slot,
  });

  final String title;
  final String body;

  /// The meal slot this reminder is for; null for the morning weigh-in.
  final MealSlot? slot;

  /// Notification ids are `kind * 100 + day offset`, so each kind owns a
  /// block of ids and can be cancelled without touching the others.
  int idFor(int dayOffset) => index * 100 + dayOffset;
}

/// What the person has chosen, as stored in the local key-value table.
///
/// A null time means that reminder is off. [enabled] is the master switch:
/// with it off nothing is scheduled whatever the times say, so switching it
/// back on restores the times the person had set.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.morning,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  /// `'true'` / `'false'`. Absent means off.
  static const enabledKey = 'reminders_enabled';

  /// Each a `HH:mm` string in local time, or absent for off.
  static const morningKey = 'reminders_morning_time';
  static const breakfastKey = 'reminders_breakfast_time';
  static const lunchKey = 'reminders_lunch_time';
  static const dinnerKey = 'reminders_dinner_time';

  static const keys = [
    enabledKey,
    morningKey,
    breakfastKey,
    lunchKey,
    dinnerKey,
  ];

  final bool enabled;
  final TimeOfDay? morning;
  final TimeOfDay? breakfast;
  final TimeOfDay? lunch;
  final TimeOfDay? dinner;

  TimeOfDay? timeFor(ReminderKind kind) => switch (kind) {
        ReminderKind.morning => morning,
        ReminderKind.breakfast => breakfast,
        ReminderKind.lunch => lunch,
        ReminderKind.dinner => dinner,
      };

  static String keyFor(ReminderKind kind) => switch (kind) {
        ReminderKind.morning => morningKey,
        ReminderKind.breakfast => breakfastKey,
        ReminderKind.lunch => lunchKey,
        ReminderKind.dinner => dinnerKey,
      };

  /// True when the master switch is on but no time has been chosen, so the
  /// screen can say so rather than leave the person waiting for nothing.
  bool get hasAnyTime =>
      morning != null || breakfast != null || lunch != null || dinner != null;

  static ReminderSettings fromValues(Map<String, String?> values) =>
      ReminderSettings(
        enabled: values[enabledKey] == 'true',
        morning: decodeTime(values[morningKey]),
        breakfast: decodeTime(values[breakfastKey]),
        lunch: decodeTime(values[lunchKey]),
        dinner: decodeTime(values[dinnerKey]),
      );

  static Future<ReminderSettings> load(AppDatabase db) async {
    final values = <String, String?>{};
    for (final key in keys) {
      values[key] = await db.stateValue(key);
    }
    return fromValues(values);
  }

  /// Re-emits whenever any of the five keys changes.
  static Stream<ReminderSettings> watch(AppDatabase db) {
    late StreamController<ReminderSettings> controller;
    final subs = <StreamSubscription<String?>>[];
    final values = <String, String?>{};
    var seen = 0;
    controller = StreamController<ReminderSettings>(
      onListen: () {
        for (final key in keys) {
          var first = true;
          subs.add(
            db.watchStateValue(key).listen((v) {
              values[key] = v;
              if (first) {
                first = false;
                seen++;
              }
              // Wait for every key's first value so the initial emission is
              // the whole picture, not a switch with no times yet.
              if (seen == keys.length) controller.add(fromValues(values));
            }),
          );
        }
      },
      // Not awaited: a widget test's fake clock would otherwise hold the
      // database open forever, and nothing needs to know when it is done.
      onCancel: () {
        for (final s in subs) {
          unawaited(s.cancel());
        }
        subs.clear();
      },
    );
    return controller.stream;
  }

  static Future<void> setEnabled(AppDatabase db, bool enabled) =>
      db.setStateValue(enabledKey, enabled ? 'true' : 'false');

  /// Stores a time, or the empty string for off. The key-value table has no
  /// delete, and an empty string decodes to null, which is the same thing.
  static Future<void> setTime(
    AppDatabase db,
    ReminderKind kind,
    TimeOfDay? time,
  ) =>
      db.setStateValue(keyFor(kind), time == null ? '' : encodeTime(time));

  static String encodeTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? decodeTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

/// One notification the planner wants delivered.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.at,
  });

  final int id;
  final ReminderKind kind;

  /// Local time.
  final DateTime at;

  @override
  String toString() => 'PlannedReminder($id ${kind.name} $at)';
}

/// Pure planning: which instants to schedule for a kind, given the clock and
/// what has already been logged today. No I/O, so the rules are tested by
/// hand-computed expected values.
class ReminderPlanner {
  const ReminderPlanner({this.horizonDays = 7});

  /// How many days ahead to schedule. Beyond this the app has to be opened
  /// again for reminders to continue; that is deliberate.
  final int horizonDays;

  List<PlannedReminder> plan({
    required ReminderKind kind,
    required TimeOfDay? time,
    required DateTime now,
    required Set<MealSlot> loggedToday,
  }) {
    if (time == null) return const [];
    final today = DateTime(now.year, now.month, now.day);
    final out = <PlannedReminder>[];
    for (var offset = 0; offset < horizonDays; offset++) {
      // Calendar arithmetic, not Duration: adding 24 h across a clock change
      // would land an hour off.
      final day = DateTime(today.year, today.month, today.day + offset);
      final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      // Already gone today, so the next one is tomorrow's.
      if (!at.isAfter(now)) continue;
      // The one rule that stops this being a nag: a meal already logged in
      // this slot today needs no reminder today.
      final slot = kind.slot;
      if (offset == 0 && slot != null && loggedToday.contains(slot)) continue;
      out.add(PlannedReminder(id: kind.idFor(offset), kind: kind, at: at));
    }
    return out;
  }

  /// Every id a kind can occupy, for cancelling.
  List<int> idsFor(ReminderKind kind) =>
      [for (var d = 0; d < horizonDays; d++) kind.idFor(d)];
}

/// The platform notification plugin, reduced to what reminders need.
abstract class NotificationScheduler {
  /// Asks the OS for permission to notify. Only ever called when the person
  /// turns the master switch on, never at launch.
  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();
}

/// The public face. Implemented over the database and a scheduler; faked in
/// widget tests.
abstract class ReminderService {
  Future<bool> requestPermission();

  Future<void> scheduleMorningWeighIn(TimeOfDay time);

  /// A null time leaves that slot off. Slots with a meal already logged
  /// today are not reminded today.
  Future<void> scheduleMealReminders({
    TimeOfDay? breakfast,
    TimeOfDay? lunch,
    TimeOfDay? dinner,
  });

  Future<void> cancelAll();

  /// Applies a whole [ReminderSettings]: everything off when the master
  /// switch is off, otherwise the morning and the meals as set.
  Future<void> apply(ReminderSettings settings);
}

class LocalReminderService implements ReminderService {
  LocalReminderService({
    required NotificationScheduler scheduler,
    required MealRepository meals,
    ReminderPlanner planner = const ReminderPlanner(),
    DateTime Function() clock = DateTime.now,
  })  : _scheduler = scheduler,
        _meals = meals,
        _planner = planner,
        _clock = clock;

  final NotificationScheduler _scheduler;
  final MealRepository _meals;
  final ReminderPlanner _planner;
  final DateTime Function() _clock;

  @override
  Future<bool> requestPermission() => _scheduler.requestPermission();

  @override
  Future<void> scheduleMorningWeighIn(TimeOfDay time) =>
      _reschedule(ReminderKind.morning, time, const {});

  @override
  Future<void> scheduleMealReminders({
    TimeOfDay? breakfast,
    TimeOfDay? lunch,
    TimeOfDay? dinner,
  }) async {
    final logged = await _loggedToday();
    await _reschedule(ReminderKind.breakfast, breakfast, logged);
    await _reschedule(ReminderKind.lunch, lunch, logged);
    await _reschedule(ReminderKind.dinner, dinner, logged);
  }

  @override
  Future<void> cancelAll() => _scheduler.cancelAll();

  @override
  Future<void> apply(ReminderSettings settings) async {
    if (!settings.enabled) {
      await cancelAll();
      return;
    }
    if (settings.morning != null) {
      await scheduleMorningWeighIn(settings.morning!);
    } else {
      await _reschedule(ReminderKind.morning, null, const {});
    }
    await scheduleMealReminders(
      breakfast: settings.breakfast,
      lunch: settings.lunch,
      dinner: settings.dinner,
    );
  }

  /// Which slots already have a meal today. Read at schedule time from the
  /// same query the Today screen uses, so the two never disagree.
  Future<Set<MealSlot>> _loggedToday() async {
    final meals = await _meals.watchMealsForDay(_clock()).first;
    return {for (final m in meals) m.slot};
  }

  /// Clears the kind's whole block of ids, then schedules what the planner
  /// wants. Cancel-then-schedule rather than diffing: the plugin's pending
  /// list is not worth a round trip for at most seven entries.
  Future<void> _reschedule(
    ReminderKind kind,
    TimeOfDay? time,
    Set<MealSlot> loggedToday,
  ) async {
    for (final id in _planner.idsFor(kind)) {
      await _scheduler.cancel(id);
    }
    final planned = _planner.plan(
      kind: kind,
      time: time,
      now: _clock(),
      loggedToday: loggedToday,
    );
    for (final p in planned) {
      await _scheduler.schedule(
        id: p.id,
        title: kind.title,
        body: kind.body,
        at: p.at,
      );
    }
  }
}

/// `flutter_local_notifications`, initialised lazily so an app in which
/// reminders are off never touches the plugin, and quiet when the platform
/// side is missing (tests, a desktop preview).
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _initialised;

  /// One channel for all four reminders: the person switched them on
  /// together and Android's channel settings should treat them as one thing.
  static const _channelId = 'reminders';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Reminders',
      channelDescription: 'The morning weigh-in and meal reminders you set',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      // The monochrome launcher glyph reads correctly in the status bar; the
      // full-colour icon would be flattened to a white square.
      icon: '@drawable/ic_launcher_monochrome',
    ),
    // Presentation is left to iOS's defaults; the permission for alert and
    // sound is requested separately, and only on the master switch.
    iOS: DarwinNotificationDetails(),
  );

  Future<bool> _ensureInitialised() => _initialised ??= _initialise();

  Future<bool> _initialise() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            '@drawable/ic_launcher_monochrome',
          ),
          // No permission prompts at initialisation. iOS asks exactly once,
          // and that moment is the person turning the switch on.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return ok ?? false;
    } on Object {
      // No platform side at all (tests, a desktop preview): the platform
      // interface has no instance and says so with an error, not an
      // exception. Either way, reminders are simply unavailable.
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _ensureInitialised()) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        // Below Android 13 there is no runtime permission; the plugin
        // reports null and notifications simply work.
        return await android?.requestNotificationsPermission() ?? true;
      }
      if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        // No badge: an unread count on the icon is a nag by another name.
        return await ios?.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!await _ensureInitialised()) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        // An instant, expressed in UTC. The plugin sends the zone name and a
        // wall-clock string, and `Etc/UTC` is known to both platforms.
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: _details,
        // Inexact: a reminder a few minutes late is fine, and the exact-alarm
        // permission is one prompt the person never has to see.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on MissingPluginException {
      // No platform side; nothing to schedule.
    } on PlatformException {
      // Notifications are blocked for the app. Settings says so.
    } on ArgumentError {
      // The instant passed between planning and scheduling.
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!await _ensureInitialised()) return;
    try {
      await _plugin.cancel(id: id);
    } on MissingPluginException {
      // Nothing to cancel.
    } on PlatformException {
      // Nothing to cancel.
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _ensureInitialised()) return;
    try {
      await _plugin.cancelAll();
    } on MissingPluginException {
      // Nothing to cancel.
    } on PlatformException {
      // Nothing to cancel.
    }
  }
}
