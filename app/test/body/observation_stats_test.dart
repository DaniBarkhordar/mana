import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/features/body/observation_stats.dart';

/// The drill-down's maths, checked against figures worked out by hand. The
/// band in particular is a number the user can reproduce from an export, so
/// the quantile rule is pinned to the spreadsheet definition (PERCENTILE.INC,
/// R type 7).
void main() {
  // Twenty weights, deliberately out of order. Sorted:
  //   76.0 76.3 76.5 76.8 77.0 77.1 77.4 77.6 77.9 78.0
  //   78.2 78.4 78.5 78.7 78.9 79.1 79.3 79.6 79.8 80.2
  const fixture = <double>[
    78.4, 76.8, 79.6, 77.1, 80.2, 78.0, 76.0, 79.1, 77.6, 78.9, //
    76.5, 79.8, 78.2, 77.4, 79.3, 76.3, 78.7, 77.9, 77.0, 78.5,
  ];

  group('median', () {
    test('even count averages the middle pair', () {
      // Tenth and eleventh of twenty: (78.0 + 78.2) / 2.
      expect(median(fixture), closeTo(78.1, 1e-9));
    });

    test('odd count takes the middle value', () {
      expect(median([3, 1, 2]), 2);
    });

    test('single value is its own median', () {
      expect(median([42]), 42);
    });
  });

  group('quantile', () {
    test('p10 and p90 of the fixture, by linear interpolation', () {
      // h = (20 − 1) × 0.1 = 1.9: x[1] + 0.9 × (x[2] − x[1])
      //   = 76.3 + 0.9 × 0.2 = 76.48.
      expect(quantile(fixture, 0.10), closeTo(76.48, 1e-9));
      // h = 19 × 0.9 = 17.1: x[17] + 0.1 × (x[18] − x[17])
      //   = 79.6 + 0.1 × 0.2 = 79.62.
      expect(quantile(fixture, 0.90), closeTo(79.62, 1e-9));
    });

    test('the ends are the min and the max', () {
      expect(quantile(fixture, 0), 76.0);
      expect(quantile(fixture, 1), 80.2);
    });

    test('median agrees with the 0.5 quantile', () {
      expect(quantile(fixture, 0.5), closeTo(median(fixture), 1e-9));
    });
  });

  group('usualRange', () {
    test('needs fourteen readings', () {
      expect(usualRange(fixture.sublist(0, 13)), isNull);
      expect(usualRange(fixture.sublist(0, 14)), isNotNull);
    });

    test('is the middle 80% of the fixture', () {
      final band = usualRange(fixture)!;
      expect(band.lo, closeTo(76.48, 1e-9));
      expect(band.hi, closeTo(79.62, 1e-9));
    });

    test('positions a value against it in words, or says calibrating', () {
      final band = usualRange(fixture);
      expect(positionIn(76.0, band), UsualRangePosition.below);
      expect(positionIn(78.1, band), UsualRangePosition.within);
      expect(positionIn(80.2, band), UsualRangePosition.above);
      expect(positionIn(78.1, null), UsualRangePosition.calibrating);
    });
  });

  group('windows', () {
    ObservationRecord row(String id, DateTime at, double v) =>
        ObservationRecord(
          id: id,
          at: at,
          value: v,
          unit: 'kg',
          source: 'simulated_scale',
        );
    final now = DateTime(2026, 9, 8, 12);

    test('windowOf keeps the last N days, oldest first; zero is all', () {
      final rows = [
        row('a', now.subtract(const Duration(days: 1)), 80),
        row('b', now.subtract(const Duration(days: 40)), 81),
        row('c', now.subtract(const Duration(days: 10)), 82),
      ];
      expect(
        windowOf(rows, 30, asOf: now).map((r) => r.id),
        ['c', 'a'],
      );
      expect(
        windowOf(rows, 0, asOf: now).map((r) => r.id),
        ['b', 'c', 'a'],
      );
    });

    test('headlineWindow is the trailing seven days', () {
      final rows = [
        row('a', now.subtract(const Duration(days: 1)), 80),
        row('b', now.subtract(const Duration(days: 3)), 81),
        row('c', now.subtract(const Duration(days: 8)), 82),
        // The future is not a reading yet.
        row('d', now.add(const Duration(hours: 1)), 83),
      ];
      expect(
        headlineWindow(rows, asOf: now).map((r) => r.id),
        ['a', 'b'],
      );
    });

    test('rollingMedianSeries is a seven-day window, not seven points', () {
      // Day 1: 80 → 80. Day 2: {80, 82} → 81. Day 10: eight days on, so
      // neither earlier reading is in its window → 90 alone.
      final rows = [
        row('a', DateTime(2026, 9, 1, 7), 80),
        row('b', DateTime(2026, 9, 2, 7), 82),
        row('c', DateTime(2026, 9, 10, 7), 90),
      ];
      final line = rollingMedianSeries(rows);
      expect(line.map((p) => p.value), [80, 81, 90]);
    });
  });

  group('niceStep', () {
    test('matches the Body chart for kilogram-sized ranges', () {
      expect(niceStep(2.0), 0.5);
      expect(niceStep(3.1), 1.0);
      expect(niceStep(9.0), 2.0);
      expect(niceStep(20.0), 5.0);
    });

    test('scales up for lab counts and steps', () {
      // 370 → 100 gives 3.7 bands; 3,000 → 1,000 gives 3.
      expect(niceStep(370), 100);
      expect(niceStep(3000), 1000);
    });

    test('minutes step in quarter and whole hours', () {
      expect(niceStep(120, unit: 'min'), 30);
      expect(niceStep(400, unit: 'min'), 120);
    });
  });

  group('axisRange', () {
    test('weight never narrower than two kilograms, snapped to the step', () {
      // 78.0–78.4 widens about 78.2 to 77.2–79.2; step 0.5; floor/ceil to
      // 77.0–79.5.
      final a = axisRange([78.0, 78.4], minSpan: minSpanFor('kg'), unit: 'kg');
      expect(a.lo, 77.0);
      expect(a.hi, 79.5);
      expect(a.step, 0.5);
    });

    test('a reference range is always in the picture', () {
      // Values 62–85 with a 30–400 range: 370 wide, step 100, 0–400.
      final a = axisRange(
        [62, 70, 85],
        includes: [30, 400],
        minSpan: minSpanFor('ug/L'),
        unit: 'ug/L',
      );
      expect(a.lo, 0);
      expect(a.hi, 400);
      expect(a.step, 100);
    });

    test('identical readings still get a band to sit in', () {
      final a = axisRange([55, 55, 55], unit: 'bpm');
      expect(a.hi - a.lo, greaterThan(0));
    });
  });

  group('formatting', () {
    test('formatValue follows the unit', () {
      expect(formatValue(78.44, 'kg'), '78.4');
      expect(formatValue(21.37, '%'), '21.4');
      expect(formatValue(47.6, 'ms'), '48');
      expect(formatValue(54.4, 'bpm'), '54');
      expect(formatValue(8450, 'count'), '8,450');
      expect(formatValue(410, 'min'), '6h 50m');
      expect(formatValue(45, 'min'), '45m');
      expect(formatValue(62, 'ug/L'), '62');
      expect(formatValue(1712.4, 'kcal/day'), '1,712');
    });

    test('formatAxis is whole for whole steps', () {
      expect(formatAxis(77.5, 0.5, 'kg'), '77.5');
      expect(formatAxis(8000, 1000, 'count'), '8,000');
      expect(formatAxis(420, 30, 'min'), '7h 00m');
    });

    test('formatReference names the range and its unit', () {
      expect(
        formatReference((low: 30, high: 400, source: 'NHS'), 'ug/L'),
        '30–400 µg/L',
      );
      expect(
        formatReference((low: null, high: 5, source: 'NHS'), 'mmol/L'),
        'under 5.0 mmol/L',
      );
      expect(
        formatReference((low: 50, high: null, source: 'lab'), 'nmol/L'),
        'over 50.0 nmol/L',
      );
    });

    test('formatUncertainty speaks in points for a percentage', () {
      expect(formatUncertainty(3.9, 'kg'), '±3.9 kg');
      expect(formatUncertainty(4.9, '%'), '±4.9 pts');
      expect(formatUncertainty(171.2, 'kcal/day'), '±171 kcal');
    });

    test('kindLabel names known kinds and humanises the rest', () {
      expect(kindLabel('weight_kg'), 'Weight');
      expect(kindLabel('hrv_sdnn_ms'), 'HRV (SDNN)');
      expect(kindLabel('ferritin_ug_l'), 'Ferritin');
      expect(kindLabel('vitamin_d_nmol_l'), 'Vitamin d');
    });

    test('unitLabel prints the micro sign and hides counts', () {
      expect(unitLabel('ug/L'), 'µg/L');
      expect(unitLabel('count'), '');
      expect(unitLabel('kg'), 'kg');
    });
  });

  test('bioimpedance kinds map onto the engine metric keys', () {
    expect(isBiaKind('body_fat_pct'), isTrue);
    expect(isBiaKind('weight_kg'), isFalse);
    expect(isBiaKind('ferritin_ug_l'), isFalse);
    expect(biaMetricKeyForKind['body_fat_pct'], 'bodyFatPercent');
  });
}
