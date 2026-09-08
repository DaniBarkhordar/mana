import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/theme/instruments.dart';
import 'package:mananu/theme/tokens.dart';

/// The shared provenance vocabulary. The colour checks matter more than they
/// look: a range pill that picked up the warning colour would turn "below
/// your usual range" into something that reads as a diagnosis.
void main() {
  Widget themed(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: MananuTheme.light(),
        darkTheme: MananuTheme.dark(),
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(body: Center(child: child)),
      );

  group('ArcGauge', () {
    test('splits the sweep by measuredFraction', () {
      // 0.8 of the arc is filled; 60% of that was weighed:
      // measured 0.8 × 0.6 = 0.48, estimated 0.8 × 0.4 = 0.32.
      final parts = ArcGauge.sweepFractions(0.8, 0.6);
      expect(parts.measured, closeTo(0.48, 1e-9));
      expect(parts.estimated, closeTo(0.32, 1e-9));
    });

    test('clamps progress and the fraction to their ranges', () {
      // Over 100%: the sweep is the full arc, still split 70/30.
      final over = ArcGauge.sweepFractions(1.4, 0.7);
      expect(over.measured, closeTo(0.7, 1e-9));
      expect(over.estimated, closeTo(0.3, 1e-9));
      // Nothing weighed at all.
      final none = ArcGauge.sweepFractions(0.5, 0);
      expect(none.measured, 0);
      expect(none.estimated, closeTo(0.5, 1e-9));
      // A fraction outside 0–1 is treated as 1.
      final all = ArcGauge.sweepFractions(0.5, 1.5);
      expect(all.measured, closeTo(0.5, 1e-9));
      expect(all.estimated, 0);
    });

    testWidgets('builds with and without a split', (tester) async {
      await tester.pumpWidget(
        themed(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArcGauge(progress: 0.8, child: Text('a')),
              ArcGauge(
                progress: 0.8,
                measuredFraction: 0.6,
                child: Text('b'),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ArcGauge), findsNWidgets(2));
    });
  });

  group('Sparkline', () {
    testWidgets('accepts a band', (tester) async {
      await tester.pumpWidget(
        themed(
          const Sparkline(
            values: [42, 44, 41, 47, 45],
            band: (lo: 40, hi: 46),
          ),
        ),
      );
      expect(find.byType(Sparkline), findsOneWidget);
    });
  });

  group('sourceLabel', () {
    test('names every known source and tidies the rest', () {
      expect(sourceLabel('apple_health'), 'Apple Health');
      expect(sourceLabel('health_connect'), 'Health Connect');
      expect(sourceLabel('mananu_body_scale'), 'Mananu body scale');
      expect(sourceLabel('mananu_kitchen_scale'), 'Mananu kitchen scale');
      expect(sourceLabel('simulated_scale'), 'Demo scale');
      expect(sourceLabel('diary'), 'Diary');
      expect(sourceLabel('some_new_thing'), 'some new thing');
    });
  });

  group('SourceBadge', () {
    testWidgets('reads "<device> via <store>"', (tester) async {
      await tester.pumpWidget(
        themed(const SourceBadge('apple_health', sourceName: 'Oura')),
      );
      expect(find.text('Oura via Apple Health'), findsOneWidget);
    });

    testWidgets('reads the store alone when no device is named',
        (tester) async {
      await tester.pumpWidget(themed(const SourceBadge('apple_health')));
      expect(find.text('Apple Health'), findsOneWidget);
    });

    testWidgets('names the demo scale and the diary', (tester) async {
      await tester.pumpWidget(
        themed(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SourceBadge('simulated_scale'),
              SourceBadge('mananu_body_scale'),
              SourceBadge('diary'),
            ],
          ),
        ),
      );
      expect(find.text('Demo scale'), findsOneWidget);
      expect(find.text('Mananu body scale'), findsOneWidget);
      expect(find.text('Diary'), findsOneWidget);
    });

    test('does not say "Apple Health via Apple Health"', () {
      const badge = SourceBadge('apple_health', sourceName: 'Apple Health');
      expect(badge.text, 'Apple Health');
      expect(
        const SourceBadge('apple_health', sourceName: '  ').text,
        'Apple Health',
      );
    });
  });

  group('RangeMarker', () {
    // Not const: Color overrides ==, which a const set does not allow.
    final forbidden = <Color>{
      MananuColors.warning,
      MananuColors.danger,
      MananuColors.measured,
      MananuColors.estimated,
    };

    /// Every colour a Container decoration or a Text style in [root] paints.
    Set<Color> paintedColours(WidgetTester tester, Finder root) {
      final colours = <Color>{};
      for (final w in tester.widgetList(
        find.descendant(of: root, matching: find.byType(Container)),
      )) {
        final box = w as Container;
        final d = box.decoration;
        if (box.color != null) colours.add(box.color!);
        if (d is BoxDecoration) {
          if (d.color != null) colours.add(d.color!);
          final b = d.border;
          if (b is Border) {
            colours.addAll(
              [b.top, b.right, b.bottom, b.left].map((s) => s.color),
            );
          }
        }
      }
      for (final w in tester.widgetList(
        find.descendant(of: root, matching: find.byType(Text)),
      )) {
        final c = (w as Text).style?.color;
        if (c != null) colours.add(c);
      }
      return colours;
    }

    for (final brightness in Brightness.values) {
      for (final state in RangeState.values) {
        testWidgets(
            '$state in ${brightness.name} says its words and stays uncoloured',
            (tester) async {
          await tester.pumpWidget(
            themed(RangeMarker(state), brightness: brightness),
          );
          expect(find.text(state.words), findsOneWidget);
          expect(find.bySemanticsLabel(state.words), findsOneWidget);
          final colours = paintedColours(tester, find.byType(RangeMarker));
          expect(colours, isNotEmpty);
          for (final c in colours) {
            expect(forbidden.contains(c), isFalse, reason: '$state paints $c');
            // Nor a translucent version of one: same channels, any alpha.
            for (final f in forbidden) {
              expect(
                c.r == f.r && c.g == f.g && c.b == f.b,
                isFalse,
                reason: '$state paints a tint of $f',
              );
            }
          }
          // No fill: an outline is the whole decoration.
          final box = tester.widget<Container>(
            find.descendant(
              of: find.byType(RangeMarker),
              matching: find.byType(Container),
            ),
          );
          expect((box.decoration! as BoxDecoration).color, isNull);
        });
      }
    }

    test('the four states have the agreed wording', () {
      expect(RangeState.within.words, 'within your usual range');
      expect(RangeState.above.words, 'above your usual range');
      expect(RangeState.below.words, 'below your usual range');
      expect(RangeState.calibrating.words, 'collecting your baseline');
    });
  });

  group('CalibrationProgress', () {
    testWidgets('renders the exact caption', (tester) async {
      await tester.pumpWidget(
        themed(const CalibrationProgress(6, 14, label: 'nights from Oura')),
      );
      expect(
        find.text('Collecting your baseline · 6 of 14 nights from Oura'),
        findsOneWidget,
      );
    });

    test('clamps the count to what is needed', () {
      expect(const CalibrationProgress(19, 14).shown, 14);
      expect(const CalibrationProgress(-2, 14).shown, 0);
      expect(
        const CalibrationProgress(19, 14, label: 'nights').caption,
        'Collecting your baseline · 14 of 14 nights',
      );
      expect(
        const CalibrationProgress(3, 14).caption,
        'Collecting your baseline · 3 of 14',
      );
    });

    testWidgets('the fill is the brass share of the track', (tester) async {
      await tester.pumpWidget(
        themed(
          const SizedBox(
            width: 280,
            child: CalibrationProgress(7, 14, label: 'nights'),
          ),
        ),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, closeTo(0.5, 1e-9));
      expect((fill.child! as ColoredBox).color, MananuColors.brass);
    });
  });

  group('DerivedNote', () {
    testWidgets('says what the statistic came from', (tester) async {
      await tester.pumpWidget(themed(const DerivedNote(14, 'nights')));
      expect(find.text('derived from 14 nights'), findsOneWidget);
    });
  });

  group('MananuColors.soft', () {
    testWidgets('differs between light and dark', (tester) async {
      Color? light;
      Color? dark;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) {
              light = MananuColors.soft(context, MananuColors.brass);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) {
              dark = MananuColors.soft(context, MananuColors.brass);
              return const SizedBox();
            },
          ),
          brightness: Brightness.dark,
        ),
      );
      // MaterialApp animates between themes, so the first dark frame is still
      // mid-lerp from light; the builder runs again once it has settled.
      await tester.pumpAndSettle();
      expect(light, MananuColors.brassSoft);
      expect(dark, isNot(light));
      expect(dark!.a, closeTo(0.18, 1e-6));
      expect(dark!.r, MananuColors.brass.r);
    });

    testWidgets('maps each accent to its soft twin in light mode',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        themed(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        MananuColors.soft(ctx, MananuColors.measured),
        MananuColors.measuredSoft,
      );
      expect(
        MananuColors.soft(ctx, MananuColors.estimated),
        MananuColors.estimatedSoft,
      );
      final other = MananuColors.soft(ctx, MananuColors.protein);
      expect(other.a, closeTo(0.12, 1e-6));
      expect(other.r, MananuColors.protein.r);
    });
  });
}
