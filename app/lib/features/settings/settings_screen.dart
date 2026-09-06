import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'scale_pairing_sheet.dart';

/// Settings.
///
/// Three items here are legal requirements rather than features:
/// withdrawing consent must be as easy as giving it (UK GDPR Art 7(3)); in-app
/// account deletion is mandatory under Apple guideline 5.1.1(v) and is the only
/// thing that satisfies Art 17; and data export is what makes the first two
/// something a user will actually use.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(bodyConnectionProvider).valueOrNull;
    final kitchen = ref.watch(kitchenConnectionProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            MananuSpacing.lg,
            0,
            MananuSpacing.lg,
            120,
          ),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 0),
              child: MananuHeader(title: 'Settings', label: 'mananu'),
            ),
            const SizedBox(height: MananuSpacing.sm),
            MananuSection(
              title: 'Your scales',
              child: Card(
                child: Column(
                  children: [
                    _DeviceTile(
                      kind: ScaleKind.body,
                      title: 'Body scale',
                      state: body,
                      subtitle: 'Bare feet, hard floor, same time each morning',
                    ),
                    const Divider(height: 1),
                    _DeviceTile(
                      kind: ScaleKind.kitchen,
                      title: 'Kitchen scale',
                      state: kitchen,
                      subtitle: 'Tare between ingredients, or let Mananu take '
                          'the difference',
                    ),
                    if (LefuConfig.isConfigured) ...[
                      const Divider(height: 1),
                      const _DemoScaleTile(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
            MananuSection(
              title: 'Your data',
              child: Card(
                child: Column(
                  children: [
                    const _BackupTile(),
                    const Divider(height: 1),
                    const _NavTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Body composition consent',
                      subtitle: 'Withdraw at any time. Weight and food logging '
                          'keep working without it.',
                    ),
                    const Divider(height: 1),
                    const _PhotoConsentTile(),
                    const Divider(height: 1),
                    const _NavTile(
                      icon: Icons.download_outlined,
                      title: 'Export everything',
                      subtitle: 'Every measurement and meal, as CSV',
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete my account',
                      subtitle: 'Erased, not hidden. This cannot be undone.',
                      danger: true,
                      onTap: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
            MananuSection(
              title: 'About',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(MananuSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mananu is not a medical device. It does not diagnose, '
                        'treat, cure or prevent any disease. Do not use the body '
                        'scale if you have a pacemaker or another implanted '
                        'electronic device.',
                        style: MananuType.caption.copyWith(
                          color: MananuColors.warning,
                        ),
                      ),
                      const SizedBox(height: MananuSpacing.md),
                      Text(
                        // The shipped catalogue carries its own attribution
                        // string, written by the build that made it.
                        ref
                                .watch(foodCatalogProvider)
                                .valueOrNull
                                ?.attribution ??
                            "Nutrition data: McCance and Widdowson's The "
                                'Composition of Foods Integrated Dataset, used '
                                'under the Open Government Licence v3.0; USDA '
                                'FoodData Central, public domain; barcode data '
                                'from Open Food Facts under the Open Database '
                                'Licence.',
                        style: MananuType.caption.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Every measurement, meal and photo will be permanently erased. '
          'Export your data first if you want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: MananuColors.danger,
            ),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
  }
}

/// Where the diary stands: on this phone only, or backed up. Honest about the
/// build too — a build with no backend configured says so rather than
/// pretending to sync.
class _BackupTile extends ConsumerWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider).valueOrNull;
    final report = ref.watch(syncReportProvider).valueOrNull;
    final pending = ref.watch(unsyncedMealCountProvider).valueOrNull ?? 0;
    final canSync = services?.canSync ?? false;

    final String subtitle;
    if (!canSync) {
      subtitle = 'Saved on this phone. This build has no cloud backup.';
    } else if (report == null) {
      subtitle = 'Saved on this phone. Backing up shortly.';
    } else {
      subtitle = switch (report.outcome) {
        SyncOutcome.synced => pending == 0
            ? 'Everything is backed up.'
            : '$pending ${pending == 1 ? 'meal' : 'meals'} waiting to back up.',
        SyncOutcome.noSession =>
          'Saved on this phone. Will back up when online.',
        SyncOutcome.failed =>
          'Could not reach the server. Safe on this phone; retrying.',
        SyncOutcome.busy => 'Backing up now.',
      };
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      leading: Icon(
        canSync && pending == 0 && report?.succeeded == true
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Backup', style: MananuType.bodyStrong),
      subtitle: Text(subtitle, style: MananuType.caption),
      trailing: canSync
          ? TextButton(
              onPressed: () => services?.sync?.syncNow(),
              child: const Text('Sync now'),
            )
          : null,
    );
  }
}

/// Withdrawing must be as easy as granting (UK GDPR Art 7(3)). Each flip is a
/// new consent row, never an edit.
class _PhotoConsentTile extends ConsumerWidget {
  const _PhotoConsentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(photoConsentProvider).valueOrNull;
    final granted = consent?.granted ?? false;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      secondary: Icon(
        Icons.auto_awesome_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Photo recognition', style: MananuType.bodyStrong),
      subtitle: Text(
        granted
            ? 'A photo goes to ${VisionConfig.providerName} only when you '
                'take one, to name the food. Nothing else is sent.'
            : 'Off. Search and barcodes still work; the scale always does.',
        style: MananuType.caption,
      ),
      value: granted,
      onChanged: (v) async {
        final services = await ref.read(appServicesProvider.future);
        await services.profiles.recordConsent(
          ConsentRecord(
            purpose: ConsentRecord.photoRecognition,
            policyVersion: ConsentRecord.currentPolicyVersion,
            granted: v,
            grantedAt: DateTime.now(),
          ),
        );
      },
    );
  }
}

/// One scale: its pairing, its link, and the way in to change either.
class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({
    required this.kind,
    required this.title,
    required this.state,
    required this.subtitle,
  });

  final ScaleKind kind;
  final String title;
  final ScaleConnectionState? state;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoScaleProvider).valueOrNull ?? true;
    final paired = ref.watch(pairedScaleProvider(kind)).valueOrNull;
    final connected = state == ScaleConnectionState.connected;
    final unauthorised = state == ScaleConnectionState.unauthorised;
    final busy = state == ScaleConnectionState.scanning ||
        state == ScaleConnectionState.connecting;

    final String detail;
    if (unauthorised) {
      detail = 'Could not start the scale software. Weight still works; get '
          'in touch and we will sort it.';
    } else if (demo) {
      detail = 'Demo scale — no hardware. $subtitle';
    } else if (paired == null) {
      detail = 'Not paired yet. Tap to choose your scale.';
    } else {
      detail = '${paired.name} · $subtitle';
    }

    final String status;
    if (connected) {
      status = 'Connected';
    } else if (busy) {
      status = 'Looking…';
    } else if (!demo && paired == null) {
      status = 'Pair';
    } else {
      status = 'Not connected';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      onTap: demo ? null : () => _open(context, ref, paired != null),
      leading: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: connected
              ? MananuColors.measured
              : unauthorised
                  ? MananuColors.danger
                  : MananuColors.mist,
        ),
      ),
      title: Text(title, style: MananuType.bodyStrong),
      subtitle: Text(detail, style: MananuType.caption),
      trailing: Text(
        status,
        style: MananuType.caption.copyWith(
          color: !demo && paired == null ? MananuColors.brass : null,
          fontWeight: !demo && paired == null ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, bool paired) async {
    if (!paired) {
      await ScalePairingSheet.show(context, kind);
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bluetooth_searching),
              title: const Text('Pair a different scale'),
              onTap: () => Navigator.pop(context, 'pair'),
            ),
            ListTile(
              leading: const Icon(
                Icons.link_off,
                color: MananuColors.danger,
              ),
              title: const Text(
                'Forget this scale',
                style: TextStyle(color: MananuColors.danger),
              ),
              onTap: () => Navigator.pop(context, 'forget'),
            ),
            const SizedBox(height: MananuSpacing.sm),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'pair') {
      await ScalePairingSheet.show(context, kind);
    } else if (choice == 'forget') {
      final coordinator = await ref.read(scaleCoordinatorProvider.future);
      await coordinator.forget(kind);
    }
  }
}

/// The review account's route through the flow, and a tester's. Only shown
/// on a build that carries real credentials; a build without them is already
/// on the demo scale.
class _DemoScaleTile extends ConsumerWidget {
  const _DemoScaleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoScaleProvider).valueOrNull ?? false;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      secondary: Icon(
        Icons.science_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Demo scale', style: MananuType.bodyStrong),
      subtitle: const Text(
        'A simulated scale for trying the app without hardware. Readings '
        'from it are labelled as simulated and never look like measurements.',
        style: MananuType.caption,
      ),
      value: demo,
      onChanged: (v) async {
        final services = await ref.read(appServicesProvider.future);
        await services.db.setStateValue(demoScaleKey, v ? 'true' : 'false');
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colour =
        danger ? MananuColors.danger : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      leading: Icon(icon, color: colour, size: 21),
      title: Text(title, style: MananuType.bodyStrong.copyWith(color: colour)),
      subtitle: Text(subtitle, style: MananuType.caption),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
