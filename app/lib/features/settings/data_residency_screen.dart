import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/legal.dart';
import '../../theme/tokens.dart';
import 'account_screen.dart';
import 'sources_screen.dart';

/// Where your data lives.
///
/// The privacy policy (docs/12-privacy-policy.md) is written so that every
/// sentence is checkable against the code. This screen is the in-app half of
/// that: the same facts, in the same order, each next to the control that
/// proves it. Health Connect requires the policy to be reachable from the
/// app, and App Review reads the About card for it, so this is linked from
/// both Settings and the consent page.
///
/// Nothing here is a promise about the future or a claim about health. It
/// is a description of what the build does, and the tests check the copy
/// stays that way.
class DataResidencyScreen extends ConsumerWidget {
  const DataResidencyScreen({super.key});

  /// The Settings tab's position in the shell's [NavigationBar].
  static const _settingsTab = 3;

  /// Most of the controls this screen points at sit on Settings, which is a
  /// tab rather than a route: go back to the shell and select it. Opened
  /// from onboarding there is no shell yet, so this just goes back.
  void _openSettings(BuildContext context, WidgetRef ref) {
    ref.read(shellIndexProvider.notifier).state = _settingsTab;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    // The Backup tile on Settings makes the same distinction: a build with
    // no sync engine keeps everything on the phone, and says so.
    final canSync =
        ref.watch(appServicesProvider).valueOrNull?.canSync ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Where your data lives')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          MananuSpacing.huge,
        ),
        children: [
          Text(
            'What the app does with what you weigh and measure, as plain '
            'facts. Each one sits next to the setting that shows it.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Where your data lives',
            child: Card(
              child: Column(
                children: [
                  const _Fact(
                    heading: 'On this phone first',
                    body: 'Every weight, reading and meal is saved on this '
                        'phone before anything else, in a database that is '
                        'kept out of iCloud and Google device backups.',
                  ),
                  const Divider(height: 1),
                  _Fact(
                    heading: 'In your account, in the UK',
                    body: canSync
                        ? 'A copy is kept in your account on servers in '
                            'London (Supabase), so you can sign back in on '
                            'another phone. Only your session can read your '
                            'rows.'
                        : 'This build has no backup configured, so it is '
                            'local-only. Everything stays on this phone.',
                  ),
                  _Link(
                    label: 'Backup',
                    onTap: () => _openSettings(context, ref),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Body composition is worked out on the phone',
                    body: 'Body fat, water, muscle and resting energy are '
                        'calculated here from the impedance your scale '
                        'measures, using published equations: Sun (2003) for '
                        'fat-free mass and body water, Janssen (2000) for '
                        'skeletal muscle, Cunningham (1980) for resting '
                        'energy. Each figure on Body names the equation that '
                        'produced it.',
                  ),
                  const _Fact(
                    heading: 'The scale maker\'s cloud is never called',
                    body: 'The company that makes the scale runs its own '
                        'online service for body composition. Mananu does '
                        'not use it. The scale sends weight and impedance to '
                        'this phone over Bluetooth, and that is where they '
                        'stay.',
                  ),
                  _Link(
                    label: 'Body composition',
                    onTap: () => _openSettings(context, ref),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Sign-in',
                    body: 'Apple, Google or a code sent to your email. '
                        'Nothing else is asked for, and signing in is '
                        'optional.',
                  ),
                  _Link(
                    label: 'Account',
                    onTap: () => _push(context, const AccountScreen()),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'No analytics or advertising services',
                    body: 'There are none in the build. No analytics, '
                        'crash-reporting or advertising service receives '
                        'anything from the app.',
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Health is read-only, with one exception',
                    body: 'When you connect Apple Health or Health Connect, '
                        'Mananu reads sleep, heart rate, HRV, steps and '
                        'workouts. It writes one thing, measured weight, '
                        'and only while that switch is on.',
                  ),
                  _Link(
                    label: 'Connected sources',
                    onTap: () => _push(context, const SourcesScreen()),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Photo recognition',
                    body: 'When you take a photo of a meal, a downscaled copy '
                        'goes to ${VisionConfig.providerName} to identify '
                        'what the food is, and nothing else. The answer is '
                        'cached by a hash of the image, so the same photo is '
                        'never sent twice. How much is on the plate comes '
                        'from the scale.',
                  ),
                  _Link(
                    label: 'Photo recognition',
                    onTap: () => _openSettings(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          const MananuSection(
            title: 'How long',
            child: Card(
              child: _Fact(
                heading: 'Until you delete it',
                body: 'Deleting your account removes every row from the '
                    'server at once and clears this phone. Nothing is hidden '
                    'or kept back. The record of what you agreed to goes '
                    'with it.',
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Your rights',
            child: Card(
              child: Column(
                children: [
                  const _Fact(
                    heading: 'Take a copy',
                    body: 'Every measurement and meal, as CSV, from inside '
                        'the app.',
                  ),
                  _Link(
                    label: 'Export everything',
                    onTap: () => _openSettings(context, ref),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Erase it',
                    body: 'Delete your account from inside the app. It is '
                        'erased, not hidden.',
                  ),
                  _Link(
                    label: 'Delete my account',
                    onTap: () => _openSettings(context, ref),
                  ),
                  const Divider(height: 1),
                  const _Fact(
                    heading: 'Change your mind',
                    body: 'Body composition and photo recognition each have '
                        'a switch in Settings. Withdrawing is as easy as '
                        'agreeing. Complaints go to the Information '
                        'Commissioner\'s Office, ico.org.uk.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          const LegalLinks(),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Mananu is not a medical device.',
            style: MananuType.caption.copyWith(color: MananuColors.warning),
          ),
        ],
      ),
    );
  }
}

/// One fact: a short heading and a sentence or two.
class _Fact extends StatelessWidget {
  const _Fact({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.lg,
        MananuSpacing.lg,
        MananuSpacing.lg,
        MananuSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: MananuType.bodyStrong),
          const SizedBox(height: MananuSpacing.xs),
          Text(
            body,
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// The way to the setting that proves the fact above it.
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
      ),
      title: Text(
        label,
        style: MananuType.caption.copyWith(
          color: MananuColors.brass,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: scheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}
