import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/health/baselines.dart';

/// Every expected value here is worked out by hand from the definition:
/// sort, take the middle, and never count the latest point.
void main() {
  final today = DateTime(2026, 9, 8, 12);

  /// One value a day, oldest first, ending on [today].
  List<BaselinePoint> nightly(List<double> values) => [
        for (var i = 0; i < values.length; i++)
          (
            at: today.subtract(Duration(days: values.length - 1 - i)),
            value: values[i],
          ),
      ];

  group('median', () {
    test('is null for nothing', () {
      expect(median(const []), isNull);
    });

    test('is the middle of an odd count', () {
      // Sorted: 40, 42, 45, 48, 60 → middle is 45. The 60 is an outlier that
      // a mean (47) would have let through.
      expect(median([48, 42, 60, 40, 45]), 45);
    });

    test('averages the two middle values of an even count', () {
      // Sorted: 40, 42, 45, 48 → (42 + 45) / 2 = 43.5.
      expect(median([48, 42, 40, 45]), 43.5);
    });
  });

  group('baselineFor', () {
    test('is the median of the earlier points, not counting the latest', () {
      // Six nights of HRV. The latest is 30; the five before it sort to
      // 40, 42, 45, 48, 50 → median 45. Including the 30 would give the
      // even-count median (42 + 45) / 2 = 43.5 instead.
      final b = baselineFor(nightly([48, 42, 50, 40, 45, 30]), asOf: today)!;
      expect(b.latest.value, 30);
      expect(b.baselineCount, 5);
      expect(b.baseline, 45);
      // 30 - 45 = -15: fifteen below the usual.
      expect(b.delta, -15);
    });

    test('has no baseline until five earlier points exist', () {
      // Four earlier nights plus the latest: the latest is shown, the
      // baseline is withheld.
      final b = baselineFor(nightly([48, 42, 50, 40, 45]), asOf: today)!;
      expect(b.latest.value, 45);
      expect(b.baselineCount, 4);
      expect(b.baseline, isNull);
      expect(b.delta, isNull);
      expect(b.hasBaseline, isFalse);
      // The fifth earlier night tips it over.
      final c = baselineFor(nightly([44, 48, 42, 50, 40, 45]), asOf: today)!;
      expect(c.baselineCount, 5);
      // Sorted earlier: 40, 42, 44, 48, 50 → 44.
      expect(c.baseline, 44);
    });

    test('only counts points inside the window before the latest', () {
      // Ten nights, window of seven days: the latest is day 0, so only days
      // 1..6 are inside (the cutoff at day 7 is exclusive). Those six values
      // are 61, 62, 63, 64, 65, 66 → (63 + 64) / 2 = 63.5. Days 7, 8, 9
      // (values 90, 90, 90) are out and would have dragged the median up.
      final series = nightly([90, 90, 90, 66, 65, 64, 63, 62, 61, 60]);
      final b = baselineFor(series, asOf: today, windowDays: 7)!;
      expect(b.baselineCount, 6);
      expect(b.baseline, 63.5);
      expect(b.delta, -3.5);
    });

    test('is null for an empty series', () {
      expect(baselineFor(const [], asOf: today), isNull);
    });

    test('is null when the latest point is older than a week', () {
      // Eight days old is not last night.
      final stale = [
        for (var i = 0; i < 6; i++)
          (at: today.subtract(Duration(days: 8 + i)), value: 50.0),
      ];
      expect(baselineFor(stale, asOf: today), isNull);
      // Exactly seven days old still counts.
      final weekOld = [
        for (var i = 0; i < 6; i++)
          (at: today.subtract(Duration(days: 7 + i)), value: 50.0),
      ];
      expect(baselineFor(weekOld, asOf: today), isNotNull);
    });

    test('sorts an unordered series before picking the latest', () {
      final shuffled = nightly([48, 42, 50, 40, 45, 30]).reversed.toList();
      final b = baselineFor(shuffled, asOf: today)!;
      expect(b.latest.value, 30);
      expect(b.baseline, 45);
    });
  });

  group('directionOf', () {
    test('calls anything within two per cent level', () {
      // 2% of a 7,000-step baseline is 140 steps.
      expect(directionOf(140, 7000), BaselineDirection.level);
      expect(directionOf(-140, 7000), BaselineDirection.level);
      expect(directionOf(141, 7000), BaselineDirection.above);
      expect(directionOf(-141, 7000), BaselineDirection.below);
    });

    test('uses plain words and never a score', () {
      expect(BaselineDirection.below.words, 'below your usual');
      expect(BaselineDirection.above.words, 'above your usual');
      expect(BaselineDirection.level.words, 'about your usual');
    });
  });
}
