import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/app.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/core/scale/scale_driver.dart';
import 'package:mananu/features/settings/settings_screen.dart';

/// Boots the whole app on an in-memory database with no backend configured —
/// exactly the aeroplane-mode case — and walks the main flow: onboarding,
/// a logged meal on Today, a body reading on Body.
/// A tab by its label, as opposed to a screen header with the same word.
Finder _tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

void main() {
  late AppServices services;

  Widget app() => ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: const MananuApp(),
      );

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  /// A phone, not the 800×600 default: lists only build what fits, and the
  /// onboarding controls sit below that fold.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
  }

  /// The database opens and the first stream values arrive over a few frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Disposes the app and lets the simulator's pending delays run out.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> completeOnboarding(WidgetTester tester) async {
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
        granted: true,
        grantedAt: now,
      ),
    );
    await settle(tester);
  }

  testWidgets('starts on onboarding when there is no profile', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    expect(find.text("Weigh it.\nDon't guess it."), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('onboarding writes a profile, and the app moves on to Today',
      (tester) async {
    await pumpApp(tester);
    await settle(tester);

    // Welcome → about you.
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Sex is required before the page can advance.
    expect(find.text('About you'), findsOneWidget);
    await tester.tap(find.text('Male'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Goal: nothing chosen yet, so Continue is held until a card is tapped.
    expect(find.text('What are you here for?'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Lose weight'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Target and pace: the defaults are five kilos down at half a kilo a
    // week, with the date that implies.
    expect(find.text('TARGET WEIGHT'), findsOneWidget);
    expect(find.text('0.5 kg a week — steady'), findsOneWidget);
    expect(find.text('About 10 weeks'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Activity page.
    expect(find.text('How active are you?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Consent page: the box sits below the fold on a phone, so scroll to it.
    expect(find.text('Your body data'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settle(tester);
    // Summary: 175 cm, 35, male, 75 kg, low active, 0.5 kg a week.
    //   Mifflin-St Jeor 9.99(75) + 6.25(175) - 4.92(35) + 166 - 161
    //     = 749.25 + 1093.75 - 172.2 + 5 = 1675.8
    //   × 1.65 = 2765.07; less 550 = 2215.07 → 2,215.
    // The number rolls to its value over half a second; let it land.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Your starting point'), findsOneWidget);
    expect(find.text('2,215'), findsOneWidget);
    expect(find.textContaining('Mifflin-St Jeor 1990'), findsOneWidget);
    // The note sits under the gauge card, below the fold on a phone.
    await tester.dragUntilVisible(
      find.textContaining('This will move as your weight does'),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    await tester.pump();
    expect(
      find.textContaining('This will move as your weight does'),
      findsOneWidget,
    );
    await tester.tap(find.text('Start'));
    await settle(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Nothing logged yet today'), findsOneWidget);

    final profile = await services.profiles.currentProfile();
    expect(profile, isNotNull);
    expect(profile!.sex, Sex.male);
    expect(profile.goal, GoalKind.lose);
    expect(profile.targetWeightKg, 70);
    expect(profile.paceKgPerWeek, 0.5);
    expect(profile.macroSplit, MacroSplit.balanced);
    // The typed-in weight went in as an observation, labelled as such.
    final weights = await services.db.select(services.db.observations).get();
    expect(weights.single.kind, 'weight_kg');
    expect(weights.single.value, 75);
    expect(weights.single.source, selfReportedSource);
    // And Today's target is the one the summary showed.
    expect(find.text('left of 2,215'), findsOneWidget);
    final consent = await tester.runAsync(
      () => services.profiles
          .watchLatestConsent(ConsentRecord.bodyComposition)
          .first,
    );
    expect(consent!.granted, isTrue);
    await shutDown(tester);
  });

  testWidgets('a meal logged in SQLite shows on Today, marked unsynced',
      (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);
    expect(find.text('Nothing logged yet today'), findsOneWidget);

    const rice = FoodItem(
      id: 'cofid:11-020',
      name: 'Basmati rice, dry',
      per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1),
      source: NutritionSource.cofid,
    );
    final session = WeighSession()..addTared(food: rice, grams: 75);
    await services.meals.logMeal(
      components: session.components,
      eatenAt: DateTime.now(),
      slot: MealSlot.lunch,
    );
    await settle(tester);

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('267 kcal'), findsOneWidget);
    // No backend in this build: the meal is on the phone only.
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.text('Nothing logged yet today'), findsNothing);
    await shutDown(tester);
  });

  testWidgets('a simulated body reading is stored and shown on Body',
      (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);
    // Let the simulated scales connect. On connect the demo scale hands over
    // the three mornings it "remembered", and the shell says so.
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.text('Caught up: 3 readings from your scale'), findsOneWidget);

    await tester.tap(_tab('Body'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No readings yet'), findsNothing);
    final caughtUp =
        (await tester.runAsync(() => services.body.watchHistory().first))!;
    expect(caughtUp, hasLength(3));
    expect(caughtUp.last.takenAt.isBefore(DateTime.now()), isTrue);

    // With readings on the page the demo control moves to the header.
    await tester.tap(find.byTooltip('Simulate stepping on (demo)'));
    // Seven settling samples at 200 ms, then the stable one.
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    expect(find.text('No readings yet'), findsNothing);
    expect(find.text('BODY FAT · 7-DAY MEDIAN'), findsOneWidget);

    final history =
        (await tester.runAsync(() => services.body.watchHistory().first))!;
    expect(history, hasLength(4));
    // The demo reading wanders a few hundred grams around the base weight.
    expect(history.last.weightKg, closeTo(78.4, 0.31));
    expect(history.last.metric('bodyFatPercent'), isNotNull);
    final kinds = (await services.db.select(services.db.observations).get())
        .map((o) => o.kind)
        .toSet();
    expect(kinds, {'weight_kg', 'impedance_ohm', 'body_fat_pct'});
    final source =
        (await services.db.select(services.db.observations).get()).first.source;
    expect(source, 'simulated_scale');
    await shutDown(tester);
  });

  testWidgets('without consent a reading is stored weight-only',
      (tester) async {
    await pumpApp(tester);
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
        granted: false,
        grantedAt: now,
      ),
    );
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    await tester.tap(_tab('Body'));
    await tester.pump(const Duration(milliseconds: 300));
    // The demo scale's remembered mornings are already on the page, stored
    // under the same rule; the live reading joins them.
    await tester.tap(find.byTooltip('Simulate stepping on (demo)'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    final history =
        (await tester.runAsync(() => services.body.watchHistory().first))!;
    expect(history, hasLength(4));
    for (final reading in history) {
      expect(reading.impedanceOhm, isNull);
      expect(reading.metric('fatFreeMass'), isNull);
    }
    expect(find.text('Weight only for this reading'), findsOneWidget);
    await shutDown(tester);
  });

  testWidgets('Settings says plainly that this build has no backup',
      (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);
    await tester.tap(_tab('Settings'));
    await tester.pump(const Duration(milliseconds: 300));
    // The Backup tile sits below the fold on a phone.
    await tester.dragUntilVisible(
      find.text('Saved on this phone. This build has no cloud backup.'),
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -200),
    );
    expect(
      find.text('Saved on this phone. This build has no cloud backup.'),
      findsOneWidget,
    );
    await shutDown(tester);
  });

  test('the kitchen demo control ramps to the load and settles', () async {
    final driver = SimulatedScaleDriver(kind: ScaleKind.kitchen);
    final found = await driver.scan().first;
    await driver.connect(found);
    final samples = <WeightSample>[];
    final sub = driver.samples.listen(samples.add);
    await driver.setLoadGrams(160);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await sub.cancel();
    await driver.dispose();
    expect(samples.any((s) => !s.isStable), isTrue);
    expect(samples.last.isStable, isTrue);
    expect(samples.last.grams, closeTo(160, 1e-9));
  });
}
