import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/legal.dart';
import 'package:mananu/features/settings/data_residency_screen.dart';
import 'package:mananu/features/settings/sources_screen.dart';
import 'package:mananu/theme/tokens.dart';

/// 'Where your data lives' is the in-app half of the privacy policy: static
/// facts, each next to the control that proves it. It has to render with no
/// backend at all, every arrow has to go somewhere, and the copy has to stay
/// on the right side of the medical-device line.
void main() {
  late AppServices services;

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: const DataResidencyScreen(),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await settle(tester);
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  /// Every string on the screen, including what sits below the fold: the
  /// ListView is scrolled to the end so the lazy list builds it all.
  Future<List<String>> allCopy(WidgetTester tester) async {
    final seen = <String>{};
    void collect() {
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final s = w.data ?? w.textSpan?.toPlainText();
        if (s != null) seen.add(s);
      }
    }

    collect();
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      collect();
    }
    return seen.toList();
  }

  testWidgets('renders offline, local-only, with the legal links',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('Where your data lives'), findsWidgets);
    // No sync engine in an in-memory app, so the screen says so rather than
    // claiming a London copy that does not exist.
    expect(find.textContaining('local-only'), findsOneWidget);
    expect(find.textContaining('London'), findsNothing);
    // The provider is named, and only identification is claimed for it.
    expect(find.textContaining(VisionConfig.providerName), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Mananu is not a medical device.'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.byType(LegalLinks), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('every arrow goes somewhere', (tester) async {
    await pumpScreen(tester);
    var arrows = 0;
    for (var i = 0; i < 12; i++) {
      for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) {
        final trailing = tile.trailing;
        if (trailing is Icon && trailing.icon == Icons.chevron_right) {
          arrows++;
          expect(tile.onTap, isNotNull, reason: 'arrow tile without onTap');
        }
      }
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    // Backup, Body composition, Account, Connected sources, Photo
    // recognition, Export everything, Delete my account — each seen at
    // least once as the list scrolls.
    expect(arrows, greaterThanOrEqualTo(7));
    await shutDown(tester);
  });

  testWidgets('the copy makes no claim it cannot keep', (tester) async {
    await pumpScreen(tester);
    final copy = await allCopy(tester);
    expect(copy, isNotEmpty);
    for (final banned in const ['accura', 'diagnos', 'cure', 'guarantee']) {
      for (final s in copy) {
        expect(
          s.toLowerCase().contains(banned),
          isFalse,
          reason: '"$banned" in: $s',
        );
      }
    }
    await shutDown(tester);
  });

  testWidgets('the Connected sources link pushes a screen', (tester) async {
    await pumpScreen(tester);
    // The first card is one list child, so the tile exists before it is on
    // screen; scroll it into view rather than until it is merely built.
    await tester.ensureVisible(find.text('Connected sources'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Connected sources'));
    await settle(tester);
    // The route underneath stays mounted; what matters is the one on top.
    expect(find.byType(SourcesScreen), findsOneWidget);
    await shutDown(tester);
  });
}
