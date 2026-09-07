import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/features/settings/goals_screen.dart';
import 'package:mananu/theme/tokens.dart';

/// The Goals screen edits the profile's goal fields in place and shows the
/// target the change produces, on an in-memory database with no reading yet
/// — so the weight comes from the self-reported observation.
void main() {
  late AppServices services;

  setUp(() async {
    services = AppServices.inMemory();
    // 178 cm, 34, male, low active: Mifflin-St Jeor 1749.42 × 1.65 = 2887.
    await services.profiles.save(
      heightCm: 178,
      dateOfBirth: UserProfile.dateOfBirthForAge(34),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
      goal: GoalKind.lose,
      targetWeightKg: 75,
      paceKgPerWeek: 0.5,
    );
    await services.observations.record(
      kind: 'weight_kg',
      value: 80,
      unit: 'kg',
      source: selfReportedSource,
      takenAt: DateTime.now(),
    );
  });

  tearDown(() => services.db.close());

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          home: const GoalsScreen(),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
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

  /// Disposes the screen and lets the database's pending stream timers run
  /// out, so nothing is left ticking when the test binding checks.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  /// The list only builds what fits on the phone; the controls sit below
  /// the target card.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pump();
  }

  testWidgets('shows the target for the saved goal, with its basis',
      (tester) async {
    await pumpScreen(tester);
    // 2887 - 550 = 2337, from the typed-in 80 kg.
    expect(find.text('2,337'), findsOneWidget);
    expect(find.text('kcal a day'), findsOneWidget);
    expect(find.textContaining('Mifflin-St Jeor 1990'), findsOneWidget);
    expect(find.textContaining('to lose 0.5 kg a week'), findsOneWidget);
    expect(find.textContaining('as typed in'), findsOneWidget);
    // Provenance on the number: it is modelled, not measured.
    expect(find.textContaining('Estimated'), findsOneWidget);
    await scrollTo(tester, find.text('0.5 kg a week — steady'));
    expect(find.text('0.5 kg a week — steady'), findsOneWidget);
    // 5 kg at 0.5 kg a week.
    expect(find.text('About 10 weeks'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('choosing a different goal saves it and moves the target',
      (tester) async {
    await pumpScreen(tester);
    await scrollTo(tester, find.text('Stay where I am'));
    await tester.tap(find.text('Stay where I am'));
    await settle(tester);
    // Back to the top: the number has moved to maintenance.
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await settle(tester);
    expect(find.text('2,887'), findsOneWidget);
    expect(find.text('2,337'), findsNothing);
    // The target and pace controls only exist for a loss or a gain.
    expect(find.text('TARGET WEIGHT'), findsNothing);

    final profile = (await services.profiles.currentProfile())!;
    expect(profile.goal, GoalKind.maintain);
    expect(profile.targetWeightKg, isNull);
    expect(profile.paceKgPerWeek, isNull);
    // The measurement inputs are untouched.
    expect(profile.heightCm, 178);
    expect(profile.activity, ActivityLevel.lowActive);
    await shutDown(tester);
  });

  testWidgets('changing the split saves it and the macros follow',
      (tester) async {
    await pumpScreen(tester);
    await scrollTo(tester, find.text('Lower carb'));
    await tester.tap(find.text('Lower carb'));
    await settle(tester);
    final profile = (await services.profiles.currentProfile())!;
    expect(profile.macroSplit, MacroSplit.lowCarb);
    expect(profile.goal, GoalKind.lose);
    expect(
      find.textContaining('A preference, not a recommendation'),
      findsOneWidget,
    );
    await shutDown(tester);
  });
}
