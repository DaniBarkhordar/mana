import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/app.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/body/reading_reveal.dart';
import 'package:mananu/theme/tokens.dart';

/// Boots the whole app on an in-memory database, the way app_smoke_test
/// does, and exercises the Body tab: the reading moment after a simulated
/// step-on, the baseline card over seeded wearable data, and the charts'
/// spoken summaries.
Finder _tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

void main() {
  late AppServices services;

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
          // No demo backlog: these tests reason about the readings they seed.
          bodyScaleDriverProvider.overrideWithValue(
            SimulatedScaleDriver(kind: ScaleKind.body, demoBacklog: false),
          ),
        ],
        child: const MananuApp(),
      );

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> seedProfile({bool consent = true}) async {
    final now = DateTime.now();
    await services.profiles.save(
      heightCm: 178,
      dateOfBirth: UserProfile.dateOfBirthForAge(34, today: now),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
    await services.profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: consent,
        grantedAt: now,
      ),
    );
  }

  /// Ten mornings of readings at 500 Ω, so both charts have a line to draw.
  Future<void> seedReadings() async {
    final now = DateTime.now();
    const engine = BodyCompositionEngine();
    const noise = [0.3, -0.2, 0.4, -0.1, 0.5, -0.3, 0.1, -0.4, 0.2, 0.0];
    for (var d = 9; d >= 0; d--) {
      final input = BiaInput(
        heightCm: 178,
        weightKg: 80.0 - (9 - d) * 0.1 + noise[d],
        ageYears: 34,
        sex: Sex.male,
        resistanceOhm: 500 + (d % 5) * 4,
      );
      final at = DateTime(now.year, now.month, now.day, 7, 12)
          .subtract(Duration(days: d));
      await services.body.record(
        result: engine.evaluate(input: input, takenAt: at),
        input: input,
        source: 'simulated_scale',
      );
    }
  }

  Finder reveal() => find.textContaining('NEW READING');

  testWidgets('the reading reveal appears once for one stable sample',
      (tester) async {
    await pumpApp(tester);
    await seedProfile();
    await settle(tester);
    // Let the simulated scales connect.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_tab('Body'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(reveal(), findsNothing);

    await tester.tap(find.text('Simulate stepping on'));
    // Seven settling samples at 200 ms, then the one stable sample.
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    expect(reveal(), findsOneWidget);
    expect(
      find.text('Your first reading. The trend starts here.'),
      findsOneWidget,
    );
    // The weight has its moment first; the composition follows it in.
    await tester.pump(const Duration(seconds: 1));
    // The weight is weighed; the body fat, once the engine has run, is an
    // estimate with its ± and its equation.
    expect(find.text('BODY FAT'), findsOneWidget);
    expect(find.textContaining('± '), findsWidgets);
    expect(find.textContaining('Predicted with'), findsOneWidget);
    final badges = tester
        .widgetList<ProvenanceBadge>(find.byType(ProvenanceBadge))
        .map((b) => b.weighed)
        .toList();
    expect(badges, containsAll([true, false]));

    // The screen underneath rebuilds as the reading lands and the settled
    // sample is re-delivered to every rebuild's listener; still one sheet.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(reveal(), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(reveal(), findsNothing);

    // A second step-on is a second measurement, and gets its own moment.
    await tester.tap(find.byTooltip('Simulate stepping on (demo)'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(reveal(), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('the reveal compares the reading with the 7-day median',
      (tester) async {
    await seedProfile();
    await seedReadings();
    await pumpApp(tester);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_tab('Body'));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MananuApp)),
    );
    final driver =
        container.read(bodyScaleDriverProvider) as SimulatedScaleDriver;
    // The seven seeded mornings inside the window are 79.4, 79.0, 79.7,
    // 79.3, 80.0, 79.3 and 79.8 kg; sorted, the middle one is 79.4. A
    // reading of 78.4 is a kilogram under it — the edge of normal.
    driver.simulateReading(kg: 78.4).ignore();
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    expect(reveal(), findsOneWidget);
    expect(
      find.text('1.0 kg below your median — normal day-to-day movement.'),
      findsOneWidget,
    );
    await shutDown(tester);
  });

  testWidgets('no reveal while another tab is on screen', (tester) async {
    await pumpApp(tester);
    await seedProfile();
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Today'), findsWidgets);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MananuApp)),
    );
    final driver =
        container.read(bodyScaleDriverProvider) as SimulatedScaleDriver;
    // Not awaited: the demo settles over 1.4 s of pumped time.
    driver.simulateReading(kg: 78.4).ignore();
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(reveal(), findsNothing);

    // The reading was still stored; Body shows it without a sheet.
    await tester.tap(_tab('Body'));
    await settle(tester);
    expect(reveal(), findsNothing);
    expect(find.text('BODY FAT · 7-DAY MEDIAN'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('without consent the reveal is weight only', (tester) async {
    await pumpApp(tester);
    await seedProfile(consent: false);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_tab('Body'));
    await tester.pump(const Duration(milliseconds: 300));
    // The demo scale catches up on its stored backlog when it connects, so
    // the tab may already hold readings; the demo control is then the
    // app-bar icon rather than the empty state's button.
    final emptyStateButton = find.text('Simulate stepping on');
    await tester.tap(
      emptyStateButton.evaluate().isEmpty
          ? find.byTooltip('Simulate stepping on (demo)')
          : emptyStateButton,
    );
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(reveal(), findsOneWidget);
    expect(find.text('BODY FAT'), findsNothing);
    expect(find.textContaining('Weight only this time'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('the baseline card says last night against your usual',
      (tester) async {
    await seedProfile();
    await seedReadings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // A fortnight of sleep from an Oura ring through Apple Health. Latest
    // night 400 min; the thirteen before it are 415, 430, 445, 400, ... whose
    // sorted middle (7th of 13) is 415. So: 15 min below a usual of 6h 55.
    for (var d = 13; d >= 0; d--) {
      await services.observations.record(
        kind: 'sleep_minutes',
        value: 400 + (d % 4) * 15,
        unit: 'min',
        source: 'apple_health',
        takenAt:
            today.add(const Duration(hours: 8)).subtract(Duration(days: d)),
        method: 'imported',
        raw: {'sourceName': 'Oura'},
      );
    }
    // Three days of steps: shown, but too few for a baseline yet.
    for (var d = 2; d >= 0; d--) {
      await services.observations.record(
        kind: 'steps',
        value: 7000 + d * 100,
        unit: 'count',
        source: 'apple_health',
        takenAt:
            today.add(const Duration(hours: 8)).subtract(Duration(days: d)),
        method: 'imported',
      );
    }

    await pumpApp(tester);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_tab('Body'));
    await settle(tester);

    final list = find.byType(ListView).last;
    await tester.dragUntilVisible(
      find.text('Sleep'),
      list,
      const Offset(0, -200),
    );
    await tester.pump();
    expect(find.text('6h 40'), findsOneWidget);
    expect(find.text('Oura via Apple Health'), findsOneWidget);
    expect(find.text('−15 min below your usual 6h 55'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    // No score anywhere: the card only ever states the comparison.
    expect(find.textContaining('score'), findsNothing);
    expect(find.textContaining('readiness'), findsNothing);

    expect(find.text('7,000'), findsOneWidget);
    expect(
      find.text('collecting your baseline · 2 of 5 days'),
      findsOneWidget,
    );
    expect(find.text('Apple Health'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('charts carry a spoken summary of their numbers', (tester) async {
    await seedProfile();
    await seedReadings();
    await pumpApp(tester);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_tab('Body'));
    await settle(tester);

    expect(find.text('WEIGHT · 30 DAYS'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Weight over the last 30 days: 10 ')),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.text('BODY FAT · 30 DAYS'),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Body fat over the last 30 days: 10 readings, from '),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'The line is the 7-day median. The dots are each reading — '
        'that spread is normal.',
      ),
      findsNWidgets(2),
    );
    await shutDown(tester);
  });

  group('describeAgainstMedian', () {
    test('calls a first reading a start', () {
      expect(
        describeAgainstMedian(78.4, null),
        'Your first reading. The trend starts here.',
      );
    });

    test('within a kilogram is normal day-to-day movement', () {
      // 78.7 − 78.4 = 0.3 above.
      expect(
        describeAgainstMedian(78.7, 78.4),
        '0.3 kg above your median — normal day-to-day movement.',
      );
      // 77.4 − 78.4 = −1.0: exactly a kilogram is still within the band.
      expect(
        describeAgainstMedian(77.4, 78.4),
        '1.0 kg below your median — normal day-to-day movement.',
      );
    });

    test('beyond a kilogram defers to the median', () {
      expect(
        describeAgainstMedian(80.0, 78.4),
        '1.6 kg above your median — more than a day usually moves. '
        'The median will tell.',
      );
    });

    test('under fifty grams is level', () {
      expect(
        describeAgainstMedian(78.44, 78.4),
        'Level with your 7-day median.',
      );
    });
  });
}
