import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/notifications/reminders_providers.dart';
import '../../theme/tokens.dart';

/// The Reminders card in Settings: one master switch, then a time for the
/// morning weigh-in and for each meal. Everything is off until the person
/// turns it on, and the notification permission is asked for at that moment
/// and no other (never at launch).
class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  static const masterSwitchKey = Key('reminders.master');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider).valueOrNull ??
        const ReminderSettings();
    return MananuSection(
      title: 'Reminders',
      child: Card(
        child: Column(
          children: [
            _MasterTile(settings: settings),
            const Divider(height: 1),
            _TimeTile(
              kind: ReminderKind.morning,
              icon: Icons.monitor_weight_outlined,
              settings: settings,
              // 07:00, 08:00, 13:00 and 19:00 are only where the picker
              // opens; nothing is set until the person chooses.
              suggested: const TimeOfDay(hour: 7, minute: 0),
            ),
            const Divider(height: 1),
            _TimeTile(
              kind: ReminderKind.breakfast,
              icon: Icons.wb_sunny_outlined,
              settings: settings,
              suggested: const TimeOfDay(hour: 8, minute: 0),
            ),
            const Divider(height: 1),
            _TimeTile(
              kind: ReminderKind.lunch,
              icon: Icons.lunch_dining_outlined,
              settings: settings,
              suggested: const TimeOfDay(hour: 13, minute: 0),
            ),
            const Divider(height: 1),
            _TimeTile(
              kind: ReminderKind.dinner,
              icon: Icons.dinner_dining_outlined,
              settings: settings,
              suggested: const TimeOfDay(hour: 19, minute: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterTile extends ConsumerWidget {
  const _MasterTile({required this.settings});

  final ReminderSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String subtitle;
    if (!settings.enabled) {
      subtitle = 'Off. Nothing is sent until you switch this on.';
    } else if (!settings.hasAnyTime) {
      subtitle = 'On. Choose a time below for each reminder you want.';
    } else {
      subtitle = 'One nudge at each time you set, and none for a meal you '
          'have already logged.';
    }
    return SwitchListTile(
      key: RemindersSection.masterSwitchKey,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      secondary: Icon(
        Icons.notifications_none_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Reminders', style: MananuType.bodyStrong),
      subtitle: Text(subtitle, style: MananuType.caption),
      value: settings.enabled,
      onChanged: (v) => v ? _turnOn(context, ref) : _turnOff(ref),
    );
  }

  Future<void> _turnOn(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final services = await ref.read(appServicesProvider.future);
    final reminders = await ref.read(reminderServiceProvider.future);
    // The one place the OS prompt is allowed to appear.
    final granted = await reminders.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are off for Mananu in your phone\'s settings. '
            'Allow them there, then try again.',
          ),
        ),
      );
      return;
    }
    await ReminderSettings.setEnabled(services.db, true);
  }

  Future<void> _turnOff(WidgetRef ref) async {
    final services = await ref.read(appServicesProvider.future);
    await ReminderSettings.setEnabled(services.db, false);
  }
}

/// A time for one reminder. Tapping opens the platform time picker; the
/// small cross beside a set time switches that one reminder off.
class _TimeTile extends ConsumerWidget {
  const _TimeTile({
    required this.kind,
    required this.icon,
    required this.settings,
    required this.suggested,
  });

  final ReminderKind kind;
  final IconData icon;
  final ReminderSettings settings;
  final TimeOfDay suggested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final time = settings.timeFor(kind);
    final active = settings.enabled && time != null;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: MananuSpacing.lg,
        right: MananuSpacing.sm,
        top: MananuSpacing.xs,
        bottom: MananuSpacing.xs,
      ),
      leading: Icon(icon, color: scheme.onSurface, size: 21),
      title: Text(kind.title, style: MananuType.bodyStrong),
      subtitle: Text(kind.body, style: MananuType.caption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time == null ? 'Off' : time.format(context),
            style: MananuType.number.copyWith(
              color: active ? scheme.primary : muted,
            ),
          ),
          if (time == null)
            const SizedBox(width: MananuSpacing.sm)
          else
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: muted,
              tooltip: 'Turn off',
              onPressed: () => _set(ref, null),
            ),
        ],
      ),
      onTap: () => _pick(context, ref, time ?? suggested),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initial,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: kind.title.toUpperCase(),
    );
    if (picked == null) return;
    await _set(ref, picked);
  }

  Future<void> _set(WidgetRef ref, TimeOfDay? time) async {
    final services = await ref.read(appServicesProvider.future);
    await ReminderSettings.setTime(services.db, kind, time);
  }
}
