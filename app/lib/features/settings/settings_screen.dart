import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import '../food/recipes_screen.dart';
import 'account_screen.dart';
import 'paywall_screen.dart';
import 'scale_pairing_sheet.dart';
import 'sources_screen.dart';

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
              title: 'Cooking',
              child: Card(
                child: _NavTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Recipes',
                  subtitle: 'Weigh a dish once, log a portion by weight '
                      'forever.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecipesScreen(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
            MananuSection(
              title: 'Wearables',
              child: Card(
                child: _NavTile(
                  icon: Icons.favorite_outline,
                  title: 'Connected sources',
                  subtitle: (ref.watch(healthConnectedProvider).valueOrNull ??
                          false)
                      ? 'Health connected. Sleep, heart and steps arrive on '
                          'the same timeline as your readings.'
                      : 'Bring in sleep, heart rate, HRV and steps from the '
                          'devices you already wear.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SourcesScreen(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
            MananuSection(
              title: 'Your data',
              child: Card(
                child: Column(
                  children: [
                    const _AccountTile(),
                    const Divider(height: 1),
                    const _PlusTile(),
                    const Divider(height: 1),
                    const _BackupTile(),
                    const Divider(height: 1),
                    const _BodyConsentTile(),
                    const Divider(height: 1),
                    const _PhotoConsentTile(),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.download_outlined,
                      title: 'Export everything',
                      subtitle: 'Every measurement and meal, as CSV',
                      onTap: () => _export(context, ref),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete my account',
                      subtitle: 'Erased, not hidden. This cannot be undone.',
                      danger: true,
                      onTap: () => _confirmDelete(context, ref),
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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final exporter = await ref.read(dataExporterProvider.future);
      await exporter.shareAll();
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not prepare the export.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Every measurement, meal and photo will be permanently erased from '
          'this phone and from our servers. Export your data first if you '
          'want to keep it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: MananuColors.danger,
            ),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final actions = await ref.read(accountActionsProvider.future);
      await actions.deleteAccount();
      // The profile is gone, so the root falls back to onboarding on its own.
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach the server to delete your account. Nothing was '
            'removed; try again when you are online.',
          ),
        ),
      );
    }
  }
}

/// Who this phone is signed in as, and the way to the Account screen.
class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(accountStatusProvider).valueOrNull ?? AccountStatus.none;
    final hasBackend =
        ref.watch(appServicesProvider).valueOrNull?.supabase != null;
    final subtitle = !hasBackend
        ? 'This build has no account. Everything stays on this phone.'
        : status.isSignedIn
            ? status.label
            : 'Temporary account. Sign in to keep your diary if you lose '
                'this phone.';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      leading: Icon(
        status.isSignedIn ? Icons.person_outline : Icons.person_off_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Account', style: MananuType.bodyStrong),
      subtitle: Text(subtitle, style: MananuType.caption),
      trailing: hasBackend && !status.isSignedIn
          ? Text(
              'Sign in',
              style: MananuType.caption.copyWith(
                color: MananuColors.brass,
                fontWeight: FontWeight.w600,
              ),
            )
          : Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
      ),
    );
  }
}

/// Plus: what it is, whether it is on, and the way to the paywall.
class _PlusTile extends ConsumerWidget {
  const _PlusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(plusStatusProvider).valueOrNull ?? PlusStatus.free;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      leading: Icon(
        plus.isPlus ? Icons.star : Icons.star_outline,
        color: plus.isPlus
            ? MananuColors.brass
            : Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Mananu Plus', style: MananuType.bodyStrong),
      subtitle: Text(
        plus.isPlus
            ? 'Active. Unlimited photo scans, recipes and calibration.'
            : 'Thirty photo scans a month are free. Plus removes the limit '
                'and adds recipes and calibration.',
        style: MananuType.caption,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: () => PaywallScreen.show(context),
    );
  }
}

/// Withdrawing must be as easy as granting (UK GDPR Art 7(3)). Withdrawal
/// asks one more question — keep or delete what was already computed — and
/// each answer is a new consent row.
class _BodyConsentTile extends ConsumerWidget {
  const _BodyConsentTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(bodyCompositionConsentProvider).valueOrNull;
    final granted = consent?.granted ?? false;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      secondary: Icon(
        Icons.verified_user_outlined,
        color: Theme.of(context).colorScheme.onSurface,
        size: 21,
      ),
      title: const Text('Body composition', style: MananuType.bodyStrong),
      subtitle: Text(
        granted
            ? 'Body fat, muscle and water are worked out from your scale\'s '
                'impedance. Switch off at any time; weight keeps working.'
            : 'Off. Readings are stored as weight only.',
        style: MananuType.caption,
      ),
      value: granted,
      onChanged: (v) => v ? _grant(ref) : _withdraw(context, ref),
    );
  }

  Future<void> _grant(WidgetRef ref) async {
    final services = await ref.read(appServicesProvider.future);
    await services.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: true,
        grantedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop working out body composition?'),
        content: const Text(
          'New readings will be stored as weight only. You can also remove '
          'the body fat, muscle and water figures already stored; the weights '
          'stay either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('Stop, keep history'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: MananuColors.danger),
            child: const Text('Stop and delete'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    final actions = await ref.read(accountActionsProvider.future);
    await actions.withdrawBodyComposition(deleteExisting: choice == 'delete');
  }
}

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
