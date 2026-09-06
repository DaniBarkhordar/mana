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

/// Onboarding gates the app until there is a measurement profile, because every
/// BIA equation needs height, age and sex, and the consent step has to happen
/// before any body data is processed.
class MananuRoot extends ConsumerWidget {
  const MananuRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) {
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
