import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/scale/pairing.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/settings/scale_pairing_sheet.dart';
import 'package:mananu/theme/tokens.dart';

import 'fake_scale_driver.dart';

/// The pairing sheet: over the simulated driver it goes straight to the
/// scan, finds the demo scale, and pairing it stores a record and connects;
/// over a real driver it explains the permission first and scans for a
/// minute.
void main() {
  late AppServices services;

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A phone, not the 800×600 default: the sheet is a fraction of the
  /// screen and only builds the rows that fit.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> open(
    WidgetTester tester,
    ScaleKind kind, {
    List<Override> overrides = const [],
  }) async {
    phone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          ...overrides,
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => ScalePairingSheet.show(context, kind),
                child: const Text('Pair'),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Pair'));
    await settle(tester);
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('finds the demo scale, pairs it and remembers it',
      (tester) async {
    await open(tester, ScaleKind.kitchen);

    expect(find.text('Pair your kitchen scale'), findsOneWidget);
    // No radio, nothing to ask: the demo scale skips the explainer.
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('Your phone will ask for'), findsNothing);
    expect(find.text('Switch the scale on'), findsOneWidget);
    // The simulated driver advertises one device after a short delay.
    final tile = find.byType(ListTile).first;
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    // The pairing record is a real database write and the demo scale takes
    // a moment to connect: let wall-clock time pass.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await settle(tester);

    // Sheet closed on success…
    expect(find.text('Pair your kitchen scale'), findsNothing);
    // …and the pairing is on disk.
    final store = await tester.runAsync(
      () => ProviderScope.containerOf(
        tester.element(find.byType(FilledButton)),
      ).read(scalePairingStoreProvider.future),
    );
    final paired = await tester.runAsync(() => store!.read(ScaleKind.kitchen));
    expect(paired, isNotNull);
    expect(paired!.kind, ScaleKind.kitchen);
    expect(paired.pairedAt, isNotNull);
    await shutDown(tester);
  });

  testWidgets('a real driver explains the permission before any scan',
      (tester) async {
    // The test host reads as Android; this is the iPhone wording.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final driver = FakeScaleDriver(
      devices: const [
        DiscoveredScale(
          id: 'far',
          name: 'Mananu Body',
          kind: ScaleKind.body,
          rssi: -82,
          modelCode: 'CF577',
        ),
        DiscoveredScale(
          id: 'near',
          name: 'Mananu Body',
          kind: ScaleKind.body,
          rssi: -48,
          modelCode: 'CF577',
        ),
      ],
    );
    await open(
      tester,
      ScaleKind.body,
      overrides: [bodyScaleDriverProvider.overrideWithValue(driver)],
    );

    expect(find.text('Pair your body scale'), findsOneWidget);
    expect(find.text('Your phone will ask for Bluetooth'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    // Nothing has touched the radio yet.
    expect(driver.calls, isEmpty);
    expect(find.text('Step on the scale, then step off'), findsNothing);

    await tester.tap(find.text('Continue'));
    await settle(tester);

    // The scan runs for a minute, and the wake instruction leads.
    expect(driver.calls.first, 'scan 60');
    expect(find.text('Step on the scale, then step off'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    // Strongest signal first, and labelled as such — once.
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('CF577 · Nearest'), findsOneWidget);
    expect(find.text('CF577 · Weak signal'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles.first.subtitle! as Text).data, 'CF577 · Nearest');

    await shutDown(tester);
    await driver.dispose();
    // The binding checks this is back to null before the test ends, so it
    // cannot wait for a tearDown.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on Android the explainer names both permission wordings',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final driver = FakeScaleDriver();
    await open(
      tester,
      ScaleKind.body,
      overrides: [bodyScaleDriverProvider.overrideWithValue(driver)],
    );
    expect(
      find.text('Your phone will ask for Nearby devices'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Android calls Bluetooth scanning a location permission. Mananu '
        'never reads or stores your location.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsNothing);
    await shutDown(tester);
    await driver.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('forget and re-pair clears the pairing and drops the link',
      (tester) async {
    final driver = FakeScaleDriver(
      devices: const [
        DiscoveredScale(id: 'B1', name: 'Mananu Body', kind: ScaleKind.body),
      ],
    );
    await ScalePairingStore(services.db).save(
      PairedScale.fromDiscovered(
        const DiscoveredScale(
          id: 'B1',
          name: 'Mananu Body',
          kind: ScaleKind.body,
        ),
      ),
    );
    await open(
      tester,
      ScaleKind.body,
      overrides: [bodyScaleDriverProvider.overrideWithValue(driver)],
    );

    expect(find.text('Forget Mananu Body and re-pair'), findsOneWidget);
    await tester.tap(find.text('Forget Mananu Body and re-pair'));
    await settle(tester);

    expect(driver.calls, contains('disconnect'));
    expect(
      await tester.runAsync(
        () => ScalePairingStore(services.db).read(ScaleKind.body),
      ),
      isNull,
    );
    expect(find.text('Forget Mananu Body and re-pair'), findsNothing);
    // Still on the explainer: the user has not agreed to a scan yet.
    expect(find.text('Continue'), findsOneWidget);
    expect(driver.calls, isNot(contains('scan 60')));

    await shutDown(tester);
    await driver.dispose();
  });
}
