import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/bia/body_composition.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/features/body/observation_detail_screen.dart';
import 'package:mananu/theme/instruments.dart';
import 'package:mananu/theme/tokens.dart';

/// One screen for every kind. These open it on a weight, a wearable value
/// and a seeded lab result, and check that the same widget serves all three
/// without a kind-specific branch showing through — and that the copy never
/// crosses the line from fact into advice.
void main() {
  late AppServices services;

  setUp(() => services = AppServices.inMemory());
  tearDown(() => services.db.close());

  Widget app(Widget home, {Brightness brightness = Brightness.light}) =>
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWith((ref) async => services),
        ],
        child: MaterialApp(
          theme: MananuTheme.light(),
          darkTheme: MananuTheme.dark(),
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: home,
        ),
      );

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  /// The same twenty weights as the stats test, one a day ending an hour
  /// ago, so seven of them fall in the trailing week whatever the clock
  /// says. Newest first here: 78.4 is today's.
  const weights = <double>[
    78.4, 76.8, 79.6, 77.1, 80.2, 78.0, 76.0, 79.1, 77.6, 78.9, //
    76.5, 79.8, 78.2, 77.4, 79.3, 76.3, 78.7, 77.9, 77.0, 78.5,
  ];

  Future<List<String>> seedWeights({int count = 20}) async {
    final now = DateTime.now();
    final ids = <String>[];
    for (var d = 0; d < count; d++) {
      ids.add(
        await services.observations.record(
          kind: 'weight_kg',
          value: weights[d],
          unit: 'kg',
          source: 'simulated_scale',
          takenAt: now.subtract(Duration(days: d, hours: 1)),
          confidence: 'measured',
        ),
      );
    }
    return ids;
  }

  /// The reading rows only: a Material snackbar is a Dismissible too.
  Finder dismissibles() => find.byWidgetPredicate(
        (w) =>
            w is Dismissible &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('obs-row-'),
      );

  LineChartData chartData(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  /// Every word the screen must never use of a reading. A reference range
  /// is context, not a verdict (CLAUDE.md rule 8).
  void expectNoAdvice(WidgetTester tester) {
    const banned = ['deficient', 'should', 'buy', 'improves', 'causes'];
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      final s = (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase();
      for (final word in banned) {
        expect(s.contains(word), isFalse, reason: '"$word" in "$s"');
      }
      expect(s.contains('!'), isFalse, reason: 'exclamation in "$s"');
    }
  }

  group('weight_kg', () {
    testWidgets('headline is the 7-day median with the raw latest beneath',
        (tester) async {
      await phone(tester);
      await seedWeights();
      await tester
          .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
      await settle(tester);

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('7-DAY MEDIAN'), findsOneWidget);
      // The seven most recent: 78.4 76.8 79.6 77.1 80.2 78.0 76.0, sorted
      // 76.0 76.8 77.1 78.0 78.4 79.6 80.2 → median 78.0.
      expect(find.text('78.0'), findsOneWidget);
      expect(find.text('kg'), findsWidgets);
      expect(find.text('derived from 7 readings'), findsOneWidget);
      expect(find.textContaining('Latest 78.4 kg'), findsOneWidget);
      expect(find.byType(SourceBadge), findsWidgets);
      expect(find.byType(RangeMarker), findsOneWidget);
      // Twenty readings in the thirty-day window: p10 76.48, p90 79.62, and
      // 78.4 sits inside.
      expect(find.text('within your usual range'), findsOneWidget);
      expect(find.textContaining('Your usual range'), findsWidgets);
      expect(find.textContaining('76.5–79.6 kg'), findsOneWidget);
      expectNoAdvice(tester);
      await shutDown(tester);
    });

    testWidgets('every reading is a row and a dot (redesign guard)',
        (tester) async {
      await phone(tester);
      await seedWeights();
      await tester
          .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
      await settle(tester);

      // The list is inside the same ListView as the chart; the rows exist
      // even when scrolled out of view? No — ListView is lazy, so scroll to
      // make sure every row is built before counting.
      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, -2000));
      await settle(tester);
      expect(dismissibles(), findsNWidgets(weights.length));
      await tester.drag(list, const Offset(0, 2000));
      await settle(tester);

      final data = chartData(tester);
      expect(data.lineBarsData.first.spots, hasLength(weights.length));
      // No bioimpedance error band for a measured weight: just dots and the
      // median.
      expect(data.lineBarsData, hasLength(2));
      expect(data.lineBarsData[1].barWidth, 2.5);
      expect(data.lineBarsData[1].color, MananuColors.brass);
      await shutDown(tester);
    });

    testWidgets('the range control narrows the window and the baseline',
        (tester) async {
      await phone(tester);
      await seedWeights();
      await tester
          .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
      await settle(tester);

      await tester.tap(find.text('7d'));
      await settle(tester);
      expect(find.text('WEIGHT · 7 DAYS'), findsOneWidget);
      expect(chartData(tester).lineBarsData.first.spots, hasLength(7));
      // Seven readings is short of a usual range, and the screen says so.
      expect(find.byType(CalibrationProgress), findsOneWidget);
      expect(
        find.textContaining('Collecting your baseline · 7 of 14'),
        findsOneWidget,
      );
      expect(find.text('collecting your baseline'), findsOneWidget);
      expect(find.text('7 IN VIEW'), findsOneWidget);
      await shutDown(tester);
    });

    testWidgets('tapping a dot shows its date, value and source',
        (tester) async {
      await phone(tester);
      await seedWeights();
      await tester
          .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
      await settle(tester);

      // The last spot is today's; tap where it is drawn.
      final chart = find.byType(LineChart);
      final box = tester.getRect(chart);
      // Right edge minus the axis labels' reserved width, roughly.
      await tester.tapAt(Offset(box.right - 60, box.center.dy));
      await settle(tester);
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      expect(find.byTooltip('Close'), findsNothing);
      await shutDown(tester);
    });

    testWidgets('swipe removes a reading, tombstones it, and Undo restores',
        (tester) async {
      await phone(tester);
      final ids = await seedWeights(count: 3);
      await tester
          .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
      await settle(tester);
      expect(dismissibles(), findsNWidgets(3));

      final newest = find.byKey(ValueKey('obs-row-${ids.first}'));
      await tester.dragUntilVisible(
        newest,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await settle(tester);
      await tester.drag(newest, const Offset(-600, 0));
      await settle(tester);
      expect(dismissibles(), findsNWidgets(2));
      expect(find.textContaining('Removed 78.4 kg'), findsOneWidget);

      final live = await (services.db.select(services.db.observations)
            ..where((o) => o.deletedAt.isNull()))
          .get();
      expect(live, hasLength(2));
      final gone = await (services.db.select(services.db.observations)
            ..where((o) => o.id.equals(ids.first)))
          .getSingle();
      expect(gone.deletedAt, isNotNull);
      expect(gone.syncedAt, isNull);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(dismissibles(), findsNWidgets(3));
      final back = await (services.db.select(services.db.observations)
            ..where((o) => o.id.equals(ids.first)))
          .getSingle();
      expect(back.deletedAt, isNull);
      await shutDown(tester);
    });

    testWidgets('renders in the dark theme', (tester) async {
      await phone(tester);
      await seedWeights();
      await tester.pumpWidget(
        app(
          const ObservationDetailScreen(kind: 'weight_kg'),
          brightness: Brightness.dark,
        ),
      );
      await settle(tester);
      expect(find.text('7-DAY MEDIAN'), findsOneWidget);
      await shutDown(tester);
    });
  });

  group('hrv_sdnn_ms', () {
    testWidgets('a wearable value: integers, the device named, no baseline yet',
        (tester) async {
      await phone(tester);
      final now = DateTime.now();
      const values = [44.0, 47.0, 41.0, 52.0, 45.0];
      for (var d = 0; d < values.length; d++) {
        await services.observations.record(
          kind: 'hrv_sdnn_ms',
          value: values[d],
          unit: 'ms',
          source: 'apple_health',
          takenAt: now.subtract(Duration(days: d, hours: 1)),
          method: 'imported',
          raw: {'sourceName': 'Oura', 'samples': 1},
        );
      }
      await tester.pumpWidget(
        app(const ObservationDetailScreen(kind: 'hrv_sdnn_ms')),
      );
      await settle(tester);

      expect(find.text('HRV (SDNN)'), findsOneWidget);
      // Sorted 41 44 45 47 52 → 45, set in the display size (an axis label
      // may say 45 too, in caption size).
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data == '45' && w.style?.fontSize == 40,
        ),
        findsOneWidget,
      );
      expect(find.text('ms'), findsWidgets);
      expect(find.text('derived from 5 readings'), findsOneWidget);
      expect(find.text('Oura via Apple Health'), findsWidgets);
      expect(find.text('collecting your baseline'), findsOneWidget);
      expect(
        find.textContaining('Collecting your baseline · 5 of 14'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mananu does not measure this itself'),
        findsOneWidget,
      );
      expectNoAdvice(tester);
      await shutDown(tester);
    });
  });

  group('ferritin_ug_l', () {
    Future<void> seedFerritin() async {
      final now = DateTime.now();
      for (final (daysAgo, value) in [(180, 62.0), (90, 70.0), (0, 85.0)]) {
        await services.observations.record(
          kind: 'ferritin_ug_l',
          value: value,
          unit: 'ug/L',
          source: 'lab',
          takenAt: now.subtract(Duration(days: daysAgo, hours: 2)),
          referenceLow: 30,
          referenceHigh: 400,
          referenceSource: 'NHS',
        );
      }
    }

    testWidgets('a lab result shows its reference range and who published it',
        (tester) async {
      await phone(tester);
      await seedFerritin();
      await tester.pumpWidget(
        app(const ObservationDetailScreen(kind: 'ferritin_ug_l')),
      );
      await settle(tester);

      expect(find.text('Ferritin'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('µg/L'), findsWidgets);
      expect(find.textContaining('NHS'), findsWidgets);
      expect(find.textContaining('30–400 µg/L'), findsWidgets);
      expect(
        find.textContaining('Mananu does not interpret it'),
        findsOneWidget,
      );
      // Three results is not a baseline, and the screen says so rather than
      // inventing one.
      expect(find.text('collecting your baseline'), findsOneWidget);
      expectNoAdvice(tester);

      // Widen to everything: the chart draws all three, and the reference
      // range is on it as dashed lines.
      await tester.tap(find.text('All'));
      await settle(tester);
      expect(find.text('FERRITIN · ALL TIME'), findsOneWidget);
      final data = chartData(tester);
      expect(data.lineBarsData.first.spots, hasLength(3));
      expect(data.extraLinesData.horizontalLines.map((l) => l.y), [30, 400]);
      expect(data.rangeAnnotations.horizontalRangeAnnotations, hasLength(1));
      expect(data.minY, 0);
      expect(data.maxY, 400);
      expect(dismissibles(), findsNWidgets(3));
      await shutDown(tester);
    });
  });

  group('body_fat_pct', () {
    testWidgets('a bioimpedance kind names its equation and error',
        (tester) async {
      await phone(tester);
      final now = DateTime.now();
      await services.profiles.save(
        heightCm: 178,
        dateOfBirth: UserProfile.dateOfBirthForAge(34, today: now),
        sex: Sex.male,
        activity: ActivityLevel.lowActive,
      );
      const engine = BodyCompositionEngine();
      for (var d = 2; d >= 0; d--) {
        final input = BiaInput(
          heightCm: 178,
          weightKg: 78.4 + d * 0.2,
          ageYears: 34,
          sex: Sex.male,
          resistanceOhm: 500,
        );
        final at = now.subtract(Duration(days: d, hours: 1));
        await services.body.record(
          result: engine.evaluate(input: input, takenAt: at),
          input: input,
          source: 'simulated_scale',
        );
      }
      await tester.pumpWidget(
        app(const ObservationDetailScreen(kind: 'body_fat_pct')),
      );
      await settle(tester);

      expect(find.text('Body fat'), findsOneWidget);
      expect(find.text('%'), findsWidgets);
      expect(find.textContaining('Sun et al. 2003'), findsWidgets);
      // Sun 2003 for a man: SEE 3.9 kg, over 78.4 kg = 4.97 → ±5.0 pts.
      expect(find.textContaining('±5.0 pts'), findsWidgets);
      final data = chartData(tester);
      expect(data.lineBarsData.first.spots, hasLength(3));
      // Dots, the median, and the two edges of the error band.
      expect(data.lineBarsData, hasLength(4));
      expect(data.betweenBarsData, hasLength(1));
      expect(
        data.betweenBarsData.single.color,
        MananuColors.brass.withValues(alpha: 0.12),
      );
      expectNoAdvice(tester);
      await shutDown(tester);
    });
  });

  testWidgets('with nothing recorded the screen says so', (tester) async {
    await phone(tester);
    await tester
        .pumpWidget(app(const ObservationDetailScreen(kind: 'weight_kg')));
    await settle(tester);
    expect(find.text('Nothing recorded yet'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    await shutDown(tester);
  });

  group('ObservationRepository', () {
    test('delete tombstones for sync and restore undoes it', () async {
      final id = await services.observations.record(
        kind: 'weight_kg',
        value: 78.4,
        unit: 'kg',
        source: 'simulated_scale',
        takenAt: DateTime(2026, 9, 8, 7, 12),
      );
      await services.observations.delete(id);
      expect(
        await services.observations.watchSeries('weight_kg').first,
        isEmpty,
      );
      var row = await (services.db.select(services.db.observations)
            ..where((o) => o.id.equals(id)))
          .getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.syncedAt, isNull);
      expect(row.updatedAt, row.deletedAt);

      await services.observations.restore(id);
      expect(
        await services.observations.watchSeries('weight_kg').first,
        hasLength(1),
      );
      row = await (services.db.select(services.db.observations)
            ..where((o) => o.id.equals(id)))
          .getSingle();
      expect(row.deletedAt, isNull);
      expect(row.syncedAt, isNull);
    });
  });

  group('DataExporter.exportKind', () {
    test('is RFC 4180 and carries only that kind, with its reference range',
        () async {
      await seedWeights(count: 3);
      final now = DateTime.now();
      for (final (daysAgo, value) in [(90, 70.0), (0, 85.0)]) {
        await services.observations.record(
          kind: 'ferritin_ug_l',
          value: value,
          unit: 'ug/L',
          source: 'lab, partner',
          takenAt: now.subtract(Duration(days: daysAgo)),
          referenceLow: 30,
          referenceHigh: 400,
          referenceSource: 'NHS',
        );
      }
      final csv = await DataExporter(services.db).exportKind('ferritin_ug_l');

      // CRLF line ends, a trailing one included, and never a bare LF.
      expect(csv, endsWith('\r\n'));
      expect(csv.replaceAll('\r\n', '').contains('\n'), isFalse);
      final lines = csv.split('\r\n')..removeLast();
      expect(
        lines.first,
        'taken_at,kind,value,unit,source,method,confidence,'
        'reference_low,reference_high,reference_source,id',
      );
      expect(lines, hasLength(3));
      for (final line in lines.skip(1)) {
        expect(line, contains(',ferritin_ug_l,'));
        expect(line, isNot(contains('weight_kg')));
        // The source had a comma in it, so it is quoted; the range and its
        // publisher ride along.
        expect(line, contains('"lab, partner"'));
        expect(line, contains(',30.0,400.0,NHS,'));
      }
      // Oldest first: the 90-day-old result before today's.
      expect(lines[1], contains(',70.0,'));
      expect(lines[2], contains(',85.0,'));

      // The other kind is untouched and unmixed.
      final weight = await DataExporter(services.db).exportKind('weight_kg');
      expect(weight.split('\r\n')..removeLast(), hasLength(4));
      expect(weight, isNot(contains('ferritin')));
    });
  });
}
