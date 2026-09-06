import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/providers.dart';
import 'features/body/body_screen.dart';
import 'features/food/weigh_food_screen.dart';
import 'features/home/today_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'theme/tokens.dart';

class MananuApp extends StatelessWidget {
  const MananuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mananu',
      debugShowCheckedModeBanner: false,
      theme: MananuTheme.light(),
      darkTheme: MananuTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MananuRoot(),
    );
  }
}

/// Opens the local database, then gates on a profile: every BIA equation needs
/// height, age and sex, and the consent step has to happen before any body
/// data is processed. Both come from SQLite, so this works in aeroplane mode.
class MananuRoot extends ConsumerWidget {
  const MananuRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider);
    if (services.hasError) {
      return _StartupError(error: services.error!);
    }
    if (!services.hasValue) return const _Splash();

    final profile = ref.watch(userProfileProvider);
    if (!profile.hasValue) return const _Splash();
    if (profile.value == null) {
      return OnboardingScreen(onComplete: () {});
    }
    return const MananuShell();
  }
}

class MananuShell extends ConsumerStatefulWidget {
  const MananuShell({super.key});

  @override
  ConsumerState<MananuShell> createState() => _MananuShellState();
}

class _MananuShellState extends ConsumerState<MananuShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    TodayScreen(),
    BodyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Kept alive for the life of the shell: the scale connections, and the
    // listener that stores each settled body reading.
    ref.watch(scaleSessionProvider);
    ref.watch(bodyReadingRecorderProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),

      // One primary action, always in reach: put something on the scale.
      // The camera lives inside that flow rather than competing with it,
      // because weighing is the product and the photo is an accelerant.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WeighFoodScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Weigh food'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Body',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// The three-stroke mark, while the database opens. Sub-second on any phone;
/// never a spinner.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final colour in [ink, MananuColors.brass, ink])
              Container(
                width: 42,
                height: 9,
                margin: const EdgeInsets.symmetric(vertical: 3.25),
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(4.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mananu could not open its database',
                style: MananuType.heading,
              ),
              const SizedBox(height: MananuSpacing.sm),
              Text(
                'Nothing has been lost. Close the app fully and open it '
                'again; if this keeps happening, get in touch and quote:\n\n'
                '$error',
                textAlign: TextAlign.center,
                style: MananuType.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
