import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/food/food_identifier.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/food/weigh_food_screen.dart';
import 'package:mananu/theme/tokens.dart';

/// Records what it was asked, and answers with nothing: these tests are
/// about the request, not the plate.
class _RecordingIdentifier implements FoodIdentifier {
  IdentifyRequest? lastRequest;

  @override
  Future<IdentifyResult> identify(IdentifyRequest request) async {
    lastRequest = request;
    return const IdentifyResult(candidates: []);
  }
}

const _oil = FoodItem(
  id: 'cofid:olive-oil',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100),
  source: NutritionSource.cofid,
);

void main() {
  test('WeighSession.replaceAt keeps the order and the running tare', () {
    final s = WeighSession();
    s.addFromRunningTotal(food: _oil, totalOnScaleGrams: 20);
    s.addFromRunningTotal(food: _oil, totalOnScaleGrams: 50);
    s.replaceAt(
      0,
      const LoggedComponent(
        food: _oil,
        grams: 25,
        method: PortionMethod.manualGrams,
      ),
    );
    expect(s.components.map((c) => c.grams), [25, 30]);
    expect(s.components.first.method, PortionMethod.manualGrams);
    // The scale still read 50 g; the edit is the user's number, not the
    // platform's.
    expect(s.platformGrams, 50);
    // Out of range is ignored, not thrown.
    s.replaceAt(
      5,
      const LoggedComponent(
        food: _oil,
        grams: 1,
        method: PortionMethod.manualGrams,
      ),
    );
    expect(s.components, hasLength(2));
  });

  late AppServices services;
  late _RecordingIdentifier identifier;

  setUp(() {
    services = AppServices.inMemory();
    identifier = _RecordingIdentifier();
  });

  tearDown(() async {
    await services.db.close();
  });

  /// The screen with no kitchen scale: the connection stream says
  /// disconnected and the live weight never arrives. No catalogue either, so
  /// search falls back to the starter list.
  Widget host({
    ScaleConnectionState state = ScaleConnectionState.disconnected,
  }) =>
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          foodCatalogProvider.overrideWith((ref) async => null),
          foodIdentifierProvider.overrideWithValue(identifier),
          kitchenConnectionProvider.overrideWith((ref) => Stream.value(state)),
          liveGramsProvider
              .overrideWith((ref) => const Stream<WeightSample>.empty()),
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

  /// Tear the tree down, then let Drift's stream-closing timers fire so
  /// the binding finds nothing pending.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Search for olive oil in the starter list and make it the pending food.
  Future<void> pickOliveOil(WidgetTester tester) async {
    await tester.tap(find.text('Search'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'olive');
    await settle(tester);
    await tester.tap(find.text('Olive oil').first);
    await settle(tester);
  }

  testWidgets(
      'the action bar holds Search, Photo, Describe and Cooking oil '
      'in one row at 390 px', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    for (final label in ['Search', 'Photo', 'Describe', 'Cooking oil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    // All four sit on the same line.
    final ys = [
      for (final label in ['Search', 'Photo', 'Describe', 'Cooking oil'])
        tester.getCenter(find.text(label)).dy,
    ];
    expect(ys.toSet().length, 1);
    await shutDown(tester);
  });

  testWidgets(
      'with no scale, a pending food is entered in grams and the '
      'tile says Estimated', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    await pickOliveOil(tester);

    // No capture button: the scale is not there to capture with.
    expect(find.text('Enter grams'), findsOneWidget);
    expect(find.textContaining('Capture'), findsNothing);
    expect(find.textContaining('No scale connected'), findsOneWidget);

    await tester.tap(find.text('Enter grams'));
    await settle(tester);

    // Oil offers spoon measures, at oil's density, and never a cup.
    expect(find.text('Tablespoon · 14 g'), findsOneWidget);
    expect(find.text('Teaspoon · 5 g'), findsOneWidget);
    expect(find.textContaining('Cup'), findsNothing);
    expect(find.text('Enter an amount'), findsOneWidget);

    await tester.tap(find.text('Tablespoon · 14 g'));
    await settle(tester);
    expect(find.text('Add 14 g'), findsOneWidget);
    await tester.tap(find.text('Add 14 g'));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeighFoodScreen)),
    );
    final components = container.read(weighSessionProvider);
    expect(components, hasLength(1));
    expect(components.single.grams, 14);
    expect(components.single.method, PortionMethod.householdMeasure);
    expect(components.single.note, 'One tablespoon');
    // 14 g of oil at 884 kcal / 100 g.
    expect(components.single.nutrients.kcal, closeTo(123.76, 1e-6));

    // The tile carries the badge, and the summary says nothing was weighed.
    final badge = tester.widget<ProvenanceBadge>(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(ProvenanceBadge),
      ),
    );
    expect(badge.weighed, isFalse);
    expect(find.text('14 g'), findsOneWidget);
    expect(
      find.textContaining('0% of these calories were weighed'),
      findsOneWidget,
    );
    expect(find.textContaining('Estimated ·'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('a typed number is logged as entered by hand', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    await pickOliveOil(tester);
    await tester.tap(find.text('Enter grams'));
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, '22.5');
    await settle(tester);
    await tester.tap(find.text('Add 22.5 g'));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeighFoodScreen)),
    );
    final c = container.read(weighSessionProvider).single;
    expect(c.grams, 22.5);
    expect(c.method, PortionMethod.manualGrams);
    expect(c.note, isNull);
    await shutDown(tester);
  });

  testWidgets('long press on a captured row edits the grams or removes it',
      (tester) async {
    await phone(tester);
    await tester.pumpWidget(host(state: ScaleConnectionState.connected));
    await settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeighFoodScreen)),
    );
    // A weighed row, as the scale would have produced it.
    container
        .read(weighSessionProvider.notifier)
        .addTared(food: _oil, grams: 30);
    await settle(tester);
    expect(find.text('30 g'), findsOneWidget);

    await tester.longPress(find.text('Olive oil'));
    await settle(tester);
    expect(find.text('Edit grams'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    await tester.tap(find.text('Edit grams'));
    await settle(tester);

    // Pre-filled with the current figure; the button says Save.
    expect(find.text('Save 30 g'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '45');
    await settle(tester);
    await tester.tap(find.text('Save 45 g'));
    await settle(tester);

    final edited = container.read(weighSessionProvider).single;
    expect(edited.grams, 45);
    // A corrected weighing is no longer a weighing.
    expect(edited.method, PortionMethod.manualGrams);
    expect(edited.food.id, _oil.id);
    expect(find.text('45 g'), findsOneWidget);

    await tester.longPress(find.text('Olive oil'));
    await settle(tester);
    await tester.tap(find.text('Remove'));
    await settle(tester);
    expect(container.read(weighSessionProvider), isEmpty);
    expect(find.text('Put the bowl on, then tare'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('with the scale connected the pending food waits for a capture',
      (tester) async {
    await phone(tester);
    await tester.pumpWidget(host(state: ScaleConnectionState.connected));
    await settle(tester);
    await pickOliveOil(tester);
    expect(find.text('Enter grams'), findsNothing);
    expect(find.text('Waiting for the scale'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets(
      'Describe sends the words and no image, and no photo consent '
      'is asked for', (tester) async {
    await phone(tester);
    await tester.pumpWidget(host());
    await settle(tester);
    await tester.tap(find.text('Describe'));
    await settle(tester);

    expect(find.text('Describe it'), findsOneWidget);
    expect(find.textContaining(VisionConfig.providerName), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'Chicken tikka with rice and a naan',
    );
    await settle(tester);
    await tester.tap(find.text('Identify'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await settle(tester);

    final req = identifier.lastRequest!;
    expect(req.description, 'Chicken tikka with rice and a naan');
    expect(req.imageBase64, isNull);
    expect(req.toJson().keys, isNot(contains('imageBase64')));
    expect(find.text('Photos and the AI provider'), findsNothing);
    expect(find.text('Nothing recognised'), findsOneWidget);
    await shutDown(tester);
  });
}
