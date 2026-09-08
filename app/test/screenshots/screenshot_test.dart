@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/app.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/food/food_catalog.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/food/recipes_screen.dart';
import 'package:mananu/features/food/weigh_food_screen.dart';
import 'package:mananu/features/progress/progress_screen.dart';
import 'package:mananu/features/settings/account_screen.dart';
import 'package:mananu/features/settings/paywall_screen.dart';
import 'package:mananu/features/settings/scale_pairing_sheet.dart';
import 'package:mananu/features/settings/sources_screen.dart';
import 'package:mananu/theme/instruments.dart';
import 'package:mananu/theme/tokens.dart';

/// Renders the real screens at phone size and writes PNGs, so the design can
/// be looked at without a device. Runs as an ordinary test everywhere (it
/// exercises every screen with data); it only writes files when
/// MANANU_SHOTS_DIR is set. The app's bundled typeface (Instrument Sans,
/// declared in pubspec.yaml) is loaded by flutter_test on its own; icons are
/// not, so they render as boxes. MANANU_FONT_PATH (colon-separated TTFs)
/// remains as an override to preview another face.
///
///   MANANU_SHOTS_DIR=/tmp/shots \
///   MANANU_FONT_PATH=/fonts/Sans-Regular.ttf:/fonts/Sans-Bold.ttf \
///     flutter test test/screenshots --tags screenshots
void main() {
  final shotsDir = Platform.environment['MANANU_SHOTS_DIR'];
  final fontPath = Platform.environment['MANANU_FONT_PATH'];
  late AppServices services;
  late FoodCatalog catalog;

  setUpAll(() async {
    // flutter_test does not load pubspec fonts, so the bundled face is loaded
    // here under its real family name and every MananuType style picks it up.
    final files = (fontPath ??
            'assets/fonts/InstrumentSans-Regular.ttf:'
                'assets/fonts/InstrumentSans-Bold.ttf')
        .split(':')
        .map(File.new)
        .where((f) => f.path.isNotEmpty && f.existsSync())
        .toList();
    if (files.isEmpty) return;
    final loader = FontLoader(MananuType.family);
    for (final f in files) {
      final bytes = f.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });

  setUp(() async {
    services = AppServices.inMemory();
    catalog = FoodCatalog.inMemory();
    await _seed(services);
  });

  tearDown(() async {
    catalog.close();
    await services.db.close();
  });

  ThemeData themed(ThemeData base) => base;

  Widget app({
    required Widget home,
    Brightness brightness = Brightness.light,
  }) =>
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          foodCatalogProvider.overrideWith((ref) async => catalog),
        ],
        // The boundary sits above the Navigator so sheets and dialogs are in
        // the picture too.
        child: RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themed(MananuTheme.light()),
            darkTheme: themed(MananuTheme.dark()),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: home,
          ),
        ),
      );

  Future<void> shoot(WidgetTester tester, String name) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    if (shotsDir == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(shotsDir).createSync(recursive: true);
      File('$shotsDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('today', (tester) async {
    await phone(tester);
    await tester
        .pumpWidget(app(home: const RepaintBoundary(child: MananuRoot())));
    await shoot(tester, 'today');
    await shutDown(tester);
  });

  testWidgets('today dark', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(
        home: const RepaintBoundary(child: MananuRoot()),
        brightness: Brightness.dark,
      ),
    );
    await shoot(tester, 'today-dark');
    await shutDown(tester);
  });

  testWidgets('body', (tester) async {
    await phone(tester);
    await tester
        .pumpWidget(app(home: const RepaintBoundary(child: MananuRoot())));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Body'),
      ),
    );
    await shoot(tester, 'body');
    await shutDown(tester);
  });

  testWidgets('settings', (tester) async {
    await phone(tester);
    await tester
        .pumpWidget(app(home: const RepaintBoundary(child: MananuRoot())));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await shoot(tester, 'settings');
    await shutDown(tester);
  });

  testWidgets('progress', (tester) async {
    await phone(tester);
    await tester.runAsync(() => _seedWeek(services));
    await tester
        .pumpWidget(app(home: const RepaintBoundary(child: MananuRoot())));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await shoot(tester, 'progress');
    await shutDown(tester);
  });

  // The weekly review at the top of Progress, the evening-tags sheet, and
  // the "in your data" card at the bottom, each in both themes.
  for (final brightness in Brightness.values) {
    final dark = brightness == Brightness.dark;
    String named(String base) => dark ? '$base-dark' : base;

    Future<void> openProgress(WidgetTester tester) async {
      await phone(tester);
      await tester.runAsync(() => _seedWeek(services));
      await tester.pumpWidget(
        app(
          home: const RepaintBoundary(child: MananuRoot()),
          brightness: brightness,
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Progress'),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('weekly review ${brightness.name}', (tester) async {
      await openProgress(tester);
      expect(find.text('WEEKLY REVIEW'), findsOneWidget);
      await shoot(tester, named('weekly-review'));
      await shutDown(tester);
    });

    testWidgets('evening tags ${brightness.name}', (tester) async {
      await openProgress(tester);
      await tester.ensureVisible(find.text('Evening tags'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Evening tags'));
      await tester.pump(const Duration(milliseconds: 400));
      await shoot(tester, named('evening-tags'));
      await shutDown(tester);
    });

    testWidgets('in your data ${brightness.name}', (tester) async {
      await openProgress(tester);
      final list = find.descendant(
        of: find.byType(ProgressScreen),
        matching: find.byType(ListView),
      );
      await tester.dragUntilVisible(
        find.text('IN YOUR DATA'),
        list,
        const Offset(0, -400),
      );
      await tester.drag(list, const Offset(0, -600));
      await shoot(tester, named('in-your-data'));
      await shutDown(tester);
    });
  }

  testWidgets('weigh food', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(home: const RepaintBoundary(child: WeighFoodScreen())),
    );
    // Let the demo scale connect, then put something on it and capture an
    // ingredient so the list and summary bar are populated.
    await tester.pump(const Duration(seconds: 1));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeighFoodScreen)),
    );
    container.read(weighSessionProvider.notifier).addTared(
          food: _rice,
          grams: 75,
        );
    await tester.pump(const Duration(milliseconds: 300));
    await shoot(tester, 'weigh-food');
    await shutDown(tester);
  });

  testWidgets('account', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(home: const RepaintBoundary(child: AccountScreen())),
    );
    await shoot(tester, 'account');
    await shutDown(tester);
  });

  testWidgets('paywall', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(home: const RepaintBoundary(child: PaywallScreen())),
    );
    await shoot(tester, 'paywall');
    await shutDown(tester);
  });

  testWidgets('sources', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(home: const RepaintBoundary(child: SourcesScreen())),
    );
    await shoot(tester, 'sources');
    await shutDown(tester);
  });

  testWidgets('recipes', (tester) async {
    await phone(tester);
    await tester.runAsync(
      () => services.recipes.save(
        name: 'Chicken tikka',
        components: (WeighSession()
              ..addTared(food: _chicken, grams: 500)
              ..addTared(food: _yogurt, grams: 150)
              ..addTared(food: _oil, grams: 15))
            .components,
        yieldGrams: 560,
      ),
    );
    await tester.pumpWidget(
      app(home: const RepaintBoundary(child: RecipesScreen())),
    );
    await shoot(tester, 'recipes');
    await shutDown(tester);
  });

  testWidgets('pairing sheet', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      app(
        home: RepaintBoundary(
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      ScalePairingSheet.show(context, ScaleKind.body),
                  child: const Text('Pair'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Pair'));
    // The demo scale advertises after a short delay.
    await tester.pump(const Duration(milliseconds: 600));
    await shoot(tester, 'pairing');
    await shutDown(tester);
  });

  // The shared provenance instruments side by side, so a change to one of
  // them can be looked at in both themes without opening every screen.
  for (final brightness in Brightness.values) {
    testWidgets('instruments ${brightness.name}', (tester) async {
      await phone(tester);
      await tester.pumpWidget(
        app(
          home: const RepaintBoundary(child: _InstrumentsGallery()),
          brightness: brightness,
        ),
      );
      await shoot(
        tester,
        brightness == Brightness.dark ? 'instruments-dark' : 'instruments',
      );
      await shutDown(tester);
    });
  }

  testWidgets('onboarding', (tester) async {
    await phone(tester);
    final fresh = AppServices.inMemory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => fresh),
          foodCatalogProvider.overrideWith((ref) async => catalog),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themed(MananuTheme.light()),
          home: const RepaintBoundary(child: MananuRoot()),
        ),
      ),
    );
    await shoot(tester, 'onboarding');
    await shutDown(tester);
    await fresh.db.close();
  });
}

/// Every shared instrument in one column: the split arc, a banded sparkline,
/// the source badge grammar, the four range states, a baseline in progress
/// and a derived-from note.
class _InstrumentsGallery extends StatelessWidget {
  const _InstrumentsGallery();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.lg),
        children: [
          const MananuHeader(label: 'Design system', title: 'Instruments'),
          const MananuSection(
            title: 'Arc, measured and estimated',
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(MananuSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ArcGauge(
                      progress: 0.8,
                      measuredFraction: 0.6,
                      child: Text('1,640', style: MananuType.number),
                    ),
                    ArcGauge(
                      progress: 0.8,
                      child: Text('1,640', style: MananuType.number),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          const MananuSection(
            title: 'Sparkline with a band',
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(MananuSpacing.lg),
                child: Row(
                  children: [
                    Text('HRV', style: MananuType.bodyStrong),
                    Spacer(),
                    Sparkline(
                      values: [42, 44, 41, 47, 45, 39, 43],
                      band: (lo: 40, hi: 46),
                      width: 140,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          const MananuSection(
            title: 'Source badges',
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(MananuSpacing.lg),
                child: Wrap(
                  spacing: MananuSpacing.sm,
                  runSpacing: MananuSpacing.sm,
                  children: [
                    SourceBadge('apple_health', sourceName: 'Oura'),
                    SourceBadge('apple_health'),
                    SourceBadge('health_connect', sourceName: 'Garmin'),
                    SourceBadge('mananu_body_scale'),
                    SourceBadge('simulated_scale'),
                    SourceBadge('diary'),
                    ProvenanceBadge(weighed: true),
                    ProvenanceBadge(weighed: false),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Range markers',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(MananuSpacing.lg),
                child: Wrap(
                  spacing: MananuSpacing.sm,
                  runSpacing: MananuSpacing.sm,
                  children: [
                    for (final state in RangeState.values) RangeMarker(state),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Baseline and derived',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(MananuSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CalibrationProgress(
                      6,
                      14,
                      label: 'nights from Oura',
                    ),
                    const SizedBox(height: MananuSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('47', style: MananuType.display),
                        const SizedBox(width: MananuSpacing.xs),
                        Text(
                          'ms',
                          style: MananuType.title.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const DerivedNote(14, 'nights'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _rice = FoodItem(
  id: 'cofid:11-020',
  name: 'Basmati rice, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.cofid,
);
const _chicken = FoodItem(
  id: 'cofid:13-001',
  name: 'Chicken breast, grilled',
  per100g: NutrientsPer100g(kcal: 165, proteinG: 31, fatG: 3.6, carbG: 0),
  source: NutritionSource.cofid,
  state: FoodState.cooked,
);
const _oats = FoodItem(
  id: 'cofid:oats',
  name: 'Porridge oats',
  per100g: NutrientsPer100g(kcal: 379, proteinG: 11, carbG: 60, fatG: 8),
  source: NutritionSource.cofid,
);
const _yogurt = FoodItem(
  id: 'cofid:yog',
  name: 'Greek yogurt',
  per100g: NutrientsPer100g(kcal: 133, proteinG: 5.7, carbG: 4.8, fatG: 10.2),
  source: NutritionSource.cofid,
);
const _apple = FoodItem(
  id: 'est:apple',
  name: 'Apple, medium',
  per100g: NutrientsPer100g(kcal: 52, carbG: 14, fatG: 0.2, proteinG: 0.3),
  source: NutritionSource.estimated,
);
const _oil = FoodItem(
  id: 'cofid:oil',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100, saturatesG: 14),
  source: NutritionSource.cofid,
);

/// A believable day and a month of readings: 178 cm, 34, male, 500 Ω, weight
/// drifting down from 80 to 78.4 kg — the persona the design canvas uses.
Future<void> _seed(AppServices s) async {
  final now = DateTime.now();
  await s.profiles.save(
    heightCm: 178,
    dateOfBirth: UserProfile.dateOfBirthForAge(34, today: now),
    sex: Sex.male,
    activity: ActivityLevel.lowActive,
  );
  await s.profiles.recordConsent(
    ConsentRecord(
      purpose: ConsentRecord.bodyComposition,
      policyVersion: ConsentRecord.currentPolicyVersion,
      granted: true,
      grantedAt: now,
    ),
  );

  final breakfast = WeighSession()
    ..addTared(food: _oats, grams: 60)
    ..addTared(food: _yogurt, grams: 150);
  await s.meals.logMeal(
    components: breakfast.components,
    eatenAt: DateTime(now.year, now.month, now.day, 7, 40),
    slot: MealSlot.breakfast,
  );
  final lunch = WeighSession()
    ..addTared(food: _chicken, grams: 160)
    ..addTared(food: _rice, grams: 75)
    ..addCookingFat(
      const CookingFatCapture(
        fat: _oil,
        gramsAdded: 15,
        gramsRemaining: 3,
        portions: 2,
      ),
    );
  await s.meals.logMeal(
    components: lunch.components,
    eatenAt: DateTime(now.year, now.month, now.day, 12, 55),
    slot: MealSlot.lunch,
  );
  final snack = WeighSession()
    ..addUnweighed(
      food: _apple,
      grams: 180,
      method: PortionMethod.householdMeasure,
    );
  await s.meals.logMeal(
    components: snack.components,
    eatenAt: DateTime(now.year, now.month, now.day, 16, 10),
    slot: MealSlot.snack,
  );

  const engine = BodyCompositionEngine();
  const noise = [0.3, -0.2, 0.4, -0.1, 0.5, -0.3, 0.1, -0.4, 0.2, 0.0];
  for (var d = 29; d >= 0; d--) {
    final kg = 80.0 - (29 - d) * 0.055 + noise[d % noise.length];
    final input = BiaInput(
      heightCm: 178,
      weightKg: double.parse(kg.toStringAsFixed(1)),
      ageYears: 34,
      sex: Sex.male,
      resistanceOhm: 500 + (d % 5) * 4,
    );
    final at = DateTime(now.year, now.month, now.day, 7, 12)
        .subtract(Duration(days: d));
    await s.body.record(
      result: engine.evaluate(input: input, takenAt: at),
      input: input,
      source: 'simulated_scale',
    );
  }
}

/// The six days before today, so the week's bars, averages and streak are
/// populated; three weeks before that so the weekly review has a previous
/// week to set against and the "in your data" card has two arms of eight;
/// and four weeks of sleep, resting HR, HRV and steps so the wearables card
/// and the review's baselines render. Today itself comes from [_seed].
///
/// Every odd day from a week back is a late-dinner day (21:30), and the
/// morning after one reads a few bpm higher, so the association card has a
/// sentence to show rather than only a baseline in progress.
Future<void> _seedWeek(AppServices s) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  bool lateDay(int d) => d >= 7 && d.isOdd;
  for (var d = 27; d >= 7; d--) {
    final day = today.subtract(Duration(days: d));
    final lunch = WeighSession()
      ..addTared(food: _chicken, grams: 140 + (d % 4) * 10)
      ..addTared(food: _rice, grams: 70 + (d % 3) * 5);
    await s.meals.logMeal(
      components: lunch.components,
      eatenAt: day.add(const Duration(hours: 13)),
      slot: MealSlot.lunch,
    );
    final dinner = WeighSession()
      ..addTared(food: _chicken, grams: 170)
      ..addTared(food: _rice, grams: 75)
      ..addCookingFat(
        const CookingFatCapture(
          fat: _oil,
          gramsAdded: 12,
          gramsRemaining: 2,
          portions: 2,
        ),
      );
    await s.meals.logMeal(
      components: dinner.components,
      eatenAt: day.add(
        lateDay(d)
            ? const Duration(hours: 21, minutes: 30)
            : const Duration(hours: 19, minutes: 15),
      ),
      slot: MealSlot.dinner,
    );
  }
  for (var d = 6; d >= 1; d--) {
    final day = today.subtract(Duration(days: d));
    final breakfast = WeighSession()
      ..addTared(food: _oats, grams: 55 + d * 3)
      ..addTared(food: _yogurt, grams: 150);
    await s.meals.logMeal(
      components: breakfast.components,
      eatenAt: day.add(const Duration(hours: 7, minutes: 40)),
      slot: MealSlot.breakfast,
    );
    final lunch = WeighSession()
      ..addTared(food: _chicken, grams: 150 + d * 5)
      ..addTared(food: _rice, grams: 70 + d * 2);
    await s.meals.logMeal(
      components: lunch.components,
      eatenAt: day.add(const Duration(hours: 12, minutes: 55)),
      slot: MealSlot.lunch,
    );
    // A weekend meal out, estimated: the weighed share is honest, not 100%.
    if (d == 2 || d == 5) {
      final dinner = WeighSession()
        ..addUnweighed(
          food: _apple,
          grams: 420,
          method: PortionMethod.photoEstimate,
        );
      await s.meals.logMeal(
        components: dinner.components,
        eatenAt: day.add(const Duration(hours: 19, minutes: 30)),
        slot: MealSlot.dinner,
      );
    } else {
      final dinner = WeighSession()
        ..addTared(food: _chicken, grams: 180)
        ..addTared(food: _rice, grams: 80)
        ..addCookingFat(
          const CookingFatCapture(
            fat: _oil,
            gramsAdded: 12,
            gramsRemaining: 2,
            portions: 2,
          ),
        );
      await s.meals.logMeal(
        components: dinner.components,
        eatenAt: day.add(const Duration(hours: 19, minutes: 15)),
        slot: MealSlot.dinner,
      );
    }
  }
  for (var d = 27; d >= 0; d--) {
    final at = today.add(const Duration(hours: 12)).subtract(Duration(days: d));
    await s.observations.record(
      kind: 'sleep_minutes',
      value: 410 + (d % 4) * 15,
      unit: 'min',
      source: 'apple_health',
      takenAt: at,
      method: 'imported',
      raw: const {'sourceName': 'Oura'},
    );
    // The morning after a late dinner (day d + 1) reads three higher.
    await s.observations.record(
      kind: 'resting_hr_bpm',
      value: 54 + (d % 3) + (lateDay(d + 1) ? 3 : 0),
      unit: 'bpm',
      source: 'apple_health',
      takenAt: at,
      method: 'imported',
      raw: const {'sourceName': 'Oura'},
    );
    await s.observations.record(
      kind: 'hrv_sdnn_ms',
      value: 44 + (d % 5) * 2,
      unit: 'ms',
      source: 'apple_health',
      takenAt: at,
      method: 'imported',
      raw: const {'sourceName': 'Oura'},
    );
    await s.observations.record(
      kind: 'steps',
      value: 7200 + (d % 5) * 900,
      unit: 'count',
      source: 'apple_health',
      takenAt: at,
      method: 'imported',
    );
  }
}
