import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/food/cooking_fat_sheet.dart';
import 'package:mananu/features/food/food_search_sheet.dart';
import 'package:mananu/features/food/weigh_food_screen.dart';
import 'package:mananu/theme/tokens.dart';

/// The starter list's olive oil: 884 kcal / 100 g, so 1 g is 8.84 kcal.
/// Every expected figure below is computed by hand from that row (or from
/// butter's), never from a per-gram constant of the app's own.
const _rice = FoodItem(
  id: 'starter:basmati-rice-dry',
  name: 'Basmati rice, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.estimated,
);

const _demoScale = DiscoveredScale(
  id: 'sim-0001',
  name: 'Kitchen scale (demo)',
  kind: ScaleKind.kitchen,
);

void main() {
  late AppServices services;
  late SimulatedScaleDriver driver;

  setUp(() {
    services = AppServices.inMemory();
    driver = SimulatedScaleDriver(kind: ScaleKind.kitchen);
  });

  tearDown(() async {
    await services.db.close();
  });

  Widget host() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          foodCatalogProvider.overrideWith((ref) async => null),
          kitchenScaleDriverProvider.overrideWithValue(driver),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: const WeighFoodScreen(),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Tear the tree down, stop the demo scale's timer, then let Drift's
  /// stream-closing timers fire so the binding finds nothing pending.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await driver.dispose();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// The demo scale connects after a short delay and then streams.
  Future<void> connect(WidgetTester tester) async {
    unawaited(driver.connect(_demoScale));
    await settle(tester);
  }

  /// Put [grams] on the demo scale and wait for the reading to settle.
  Future<void> load(WidgetTester tester, double grams) async {
    unawaited(driver.setLoadGrams(grams));
    await settle(tester);
  }

  WeighSessionNotifier session(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(WeighFoodScreen)),
      ).read(weighSessionProvider.notifier);

  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(CookingFatSheet), matching: f);

  testWidgets(
      'tare, add oil, capture, cook, put the pan back, capture, two '
      'portions: a weighed cooking-fat component the weighed share counts',
      (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    await connect(tester);
    // Something estimated already in the meal, so the weighed share is a
    // real fraction rather than 100% by default.
    session(tester).addUnweighed(
      food: _rice,
      grams: 100,
      method: PortionMethod.manualGrams,
    );
    await settle(tester);

    await tester.tap(find.text('Cooking oil'));
    await settle(tester);

    // Step 1.
    expect(find.text('Pan on the scale, then tap Tare'), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(inSheet(find.text('Olive oil')), findsOneWidget);
    await tester.tap(inSheet(find.text('Tare')));
    await settle(tester);

    // Step 2: nothing to capture until the oil is in and the reading has
    // settled.
    expect(find.text('Add the oil'), findsOneWidget);
    expect(find.text('Waiting for the scale'), findsOneWidget);
    await load(tester, 15);
    expect(find.text('Capture 15.0 g'), findsOneWidget);
    await tester.tap(find.text('Capture 15.0 g'));
    await settle(tester);

    // Step 3, with the first reading parked in the session.
    expect(find.text('Cook, then put the pan back'), findsOneWidget);
    final pending = session(tester).pendingFat!;
    expect(pending.gramsAdded, closeTo(15, 1e-9));
    expect(pending.fat.id, 'starter:olive-oil');

    // The pan comes off to cook, then goes back with 3 g still in it.
    await load(tester, 0);
    expect(find.text('Capture 0.0 g left'), findsOneWidget);
    await load(tester, 3);
    await tester.tap(find.text('Capture 3.0 g left'));
    await settle(tester);
    expect(
      find.text('3.0 g left in the pan · 12.0 g into the food'),
      findsOneWidget,
    );

    // 12 g across two portions: 6.0 g each, 6 × 8.84 = 53.04 kcal.
    await tester.tap(find.byTooltip('More portions'));
    await settle(tester);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('6.0 g olive oil per portion, 53 kcal'), findsOneWidget);
    // A fact about this meal, never a comparison with other apps.
    expect(find.textContaining('apps'), findsNothing);

    await tester.tap(find.text('Add to meal'));
    await settle(tester);

    final components = session(tester).state;
    expect(components, hasLength(2));
    final fat = components.last;
    expect(fat.isCookingFat, isTrue);
    expect(fat.grams, closeTo(6.0, 1e-9));
    expect(fat.method, PortionMethod.weighed);
    expect(fat.nutrients.kcal, closeTo(53.04, 1e-6));
    expect(session(tester).pendingFat, isNull);

    // The weighed share counts it: 53.04 of (356 + 53.04) kcal.
    final totals = session(tester).totals();
    expect(totals.weighedFraction, closeTo(53.04 / 409.04, 1e-6));

    // The row wears the Weighed badge.
    final badges = tester
        .widgetList<ProvenanceBadge>(
          find.descendant(
            of: find.byType(ListTile),
            matching: find.byType(ProvenanceBadge),
          ),
        )
        .toList();
    expect(badges.map((b) => b.weighed), [false, true]);

    // Remembered for next time.
    final last = await tester.runAsync(
      () => services.db.stateValue(lastCookingFatKey),
    );
    expect(last, 'starter:olive-oil');
    await shutDown(tester);
  });

  testWidgets(
      'leaving the sheet after the oil is captured shows a chip that '
      'reopens it at step 3', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    await connect(tester);

    await tester.tap(find.text('Cooking oil'));
    await settle(tester);
    await tester.tap(inSheet(find.text('Tare')));
    await settle(tester);
    await load(tester, 15);
    await tester.tap(find.text('Capture 15.0 g'));
    await settle(tester);
    expect(find.text('STEP 3 OF 3'), findsOneWidget);

    // Off to cook: tap the barrier above the sheet.
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);
    expect(find.byType(CookingFatSheet), findsNothing);
    expect(
      find.text('Pan: 15 g olive oil captured · weigh what is left'),
      findsOneWidget,
    );
    expect(session(tester).pendingFat, isNotNull);

    // Back for the second reading, straight to step 3.
    await tester
        .tap(find.text('Pan: 15 g olive oil captured · weigh what is left'));
    await settle(tester);
    expect(find.byType(CookingFatSheet), findsOneWidget);
    expect(find.text('Cook, then put the pan back'), findsOneWidget);
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Pan on the scale, then tap Tare'), findsNothing);
    await shutDown(tester);
  });

  testWidgets(
      'with no scale connected the sheet opens on the typed path and the '
      'result is an estimate', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('Cooking oil'));
    await settle(tester);

    expect(
      find.text(
        'No kitchen scale connected, so the two pan readings are typed and '
        'the fat is logged as an estimate.',
      ),
      findsOneWidget,
    );
    expect(find.text('Tare'), findsNothing);
    expect(find.text('Use the scale instead'), findsNothing);

    final fields = find.descendant(
      of: find.byType(CookingFatSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '15');
    await tester.enterText(fields.at(1), '3');
    await settle(tester);
    await tester.tap(find.byTooltip('More portions'));
    await settle(tester);
    expect(find.text('6.0 g olive oil per portion, 53 kcal'), findsOneWidget);
    expect(find.text('Entered by hand'), findsOneWidget);

    await tester.tap(find.text('Add to meal'));
    await settle(tester);

    final c = session(tester).state.single;
    expect(c.isCookingFat, isTrue);
    expect(c.grams, closeTo(6.0, 1e-9));
    // The same method the no-scale grams entry uses: never weighed.
    expect(c.method, PortionMethod.manualGrams);
    final badge = tester.widget<ProvenanceBadge>(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(ProvenanceBadge),
      ),
    );
    expect(badge.weighed, isFalse);
    expect(session(tester).totals().weighedFraction, 0);
    expect(find.textContaining('Estimated ·'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets(
      'choosing butter uses butter\'s own per-100 g figures and becomes '
      'the default next time', (tester) async {
    await phone(tester);
    // Butter as the user entered it from the pack: 717 kcal / 100 g (the
    // figure on a UK block of salted butter), so 10 g is 71.7 kcal.
    await tester.runAsync(
      () => services.userFoods.save(
        const FoodItem(
          id: 'user:butter',
          name: 'Butter',
          per100g: NutrientsPer100g(kcal: 717, fatG: 81, saturatesG: 52),
          source: NutritionSource.userLabel,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('Cooking oil'));
    await settle(tester);
    expect(inSheet(find.text('Olive oil')), findsOneWidget);
    await tester.tap(find.text('Change'));
    await settle(tester);
    // The search box, not the sheet's own grams fields underneath it.
    await tester.enterText(
      find.descendant(
        of: find.byType(FoodSearchSheet),
        matching: find.byType(TextField),
      ),
      'butter',
    );
    await settle(tester);
    await tester.tap(find.text('Butter'));
    await settle(tester);
    expect(inSheet(find.text('Butter')), findsOneWidget);
    expect(inSheet(find.textContaining('717 kcal / 100 g')), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(CookingFatSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '20');
    await tester.enterText(fields.at(1), '0');
    await settle(tester);
    await tester.tap(find.byTooltip('More portions'));
    await settle(tester);
    expect(find.text('10.0 g butter per portion, 72 kcal'), findsOneWidget);
    await tester.tap(find.text('Add to meal'));
    await settle(tester);

    final c = session(tester).state.single;
    expect(c.food.id, 'user:butter');
    expect(c.grams, closeTo(10, 1e-9));
    expect(c.nutrients.kcal, closeTo(71.7, 1e-6));

    // Next time the sheet opens on butter.
    await tester.tap(find.text('Cooking oil'));
    await settle(tester);
    expect(inSheet(find.text('Butter')), findsOneWidget);
    expect(inSheet(find.text('Olive oil')), findsNothing);
    await shutDown(tester);
  });
}
