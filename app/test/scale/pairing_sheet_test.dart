import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/settings/scale_pairing_sheet.dart';
import 'package:mananu/theme/tokens.dart';

/// The pairing sheet over the simulated driver: it finds the demo scale,
/// pairing it stores a record and connects.
void main() {
  late AppServices services;

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('finds the demo scale, pairs it and remembers it',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    ScalePairingSheet.show(context, ScaleKind.kitchen),
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

    expect(find.text('Pair your kitchen scale'), findsOneWidget);
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
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
