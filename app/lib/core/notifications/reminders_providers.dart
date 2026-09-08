/// Riverpod wiring for reminders.
///
/// Kept apart from `core/data/providers.dart` so the notification plugin is
/// only a dependency of the two things that need it: this file and Settings.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'reminders.dart';

export 'reminders.dart' show ReminderKind, ReminderService, ReminderSettings;

/// The plugin boundary. Tests override it with a fake that records calls.
final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => LocalNotificationScheduler(),
);

final reminderServiceProvider = FutureProvider<ReminderService>((ref) async {
  final s = await ref.watch(appServicesProvider.future);
  return LocalReminderService(
    scheduler: ref.watch(notificationSchedulerProvider),
    meals: s.meals,
  );
});

/// What the person has chosen, straight from the key-value table.
final reminderSettingsProvider = StreamProvider<ReminderSettings>((ref) async* {
  final s = await ref.watch(appServicesProvider.future);
  yield* ReminderSettings.watch(s.db);
});

/// Keeps the schedule true to the settings and to today's log. Kept alive by
/// the shell. Re-applies whenever the settings change, whenever today's meals
/// change (so a logged breakfast cancels its reminder), and at midnight (so
/// the seven-day horizon rolls forward and yesterday's skips are forgotten).
///
/// With the master switch off the only call is a cancel, which clears
/// anything left from before the switch went off. Nothing here ever asks for
/// permission: that happens in Settings, on the switch, and nowhere else.
final remindersProvider = Provider<void>((ref) {
  final settings = ref.watch(reminderSettingsProvider).valueOrNull;
  if (settings == null) return;
  if (settings.enabled) {
    // Only the days matter for the skip rule; watching the meals keeps this
    // in step with the log without a second query.
    ref.watch(todaysMealsProvider);
    ref.watch(todayProvider);
  }
  unawaited(() async {
    try {
      final service = await ref.read(reminderServiceProvider.future);
      await service.apply(settings);
    } on Object {
      // Notifications unavailable right now; the next change tries again.
    }
  }());
});
