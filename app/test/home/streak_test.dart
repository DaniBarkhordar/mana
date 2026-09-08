import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/features/home/streak.dart';

/// The streak on dates alone: gaps, today not yet logged, month ends, and
/// timestamps that only differ by the hour.
void main() {
  final today = DateTime(2026, 9, 8);
  DateTime daysAgo(int n) => DateTime(2026, 9, 8 - n);

  test('nothing logged is no streak', () {
    expect(loggingStreak(const [], today), 0);
  });

  test('a meal today alone is a streak of one', () {
    expect(loggingStreak([today], today), 1);
  });

  test('three consecutive days ending today count three', () {
    expect(loggingStreak([today, daysAgo(1), daysAgo(2)], today), 3);
  });

  test('today not yet logged: the streak ends yesterday and is not broken', () {
    expect(loggingStreak([daysAgo(1), daysAgo(2), daysAgo(3)], today), 3);
  });

  test('a one-day gap ends the count', () {
    // 8th, 7th, (6th missing), 5th, 4th: the streak is two.
    expect(
      loggingStreak([today, daysAgo(1), daysAgo(3), daysAgo(4)], today),
      2,
    );
  });

  test('neither today nor yesterday logged is zero, whatever came before', () {
    expect(loggingStreak([daysAgo(2), daysAgo(3), daysAgo(4)], today), 0);
  });

  test('timestamps reduce to their calendar day, and duplicates do not count',
      () {
    final days = [
      DateTime(2026, 9, 8, 7, 40),
      DateTime(2026, 9, 8, 12, 55),
      DateTime(2026, 9, 8, 19, 10),
      DateTime(2026, 9, 7, 23, 59),
    ];
    expect(loggingStreak(days, DateTime(2026, 9, 8, 13, 30)), 2);
  });

  test('runs back across a month boundary', () {
    expect(
      loggingStreak(
        [DateTime(2026, 9, 1), DateTime(2026, 8, 31), DateTime(2026, 8, 30)],
        DateTime(2026, 9, 1),
      ),
      3,
    );
  });

  test('runs back across the spring clock change by calendar days', () {
    // UK clocks go forward on 29 March 2026. Subtracting 24 hours from
    // midnight on the 29th lands on the 27th at 23:00 in that zone, which
    // would skip the 28th; dayBefore uses calendar arithmetic instead.
    final march29 = DateTime(2026, 3, 29);
    expect(dayBefore(march29), DateTime(2026, 3, 28));
    expect(
      loggingStreak(
        [march29, DateTime(2026, 3, 28), DateTime(2026, 3, 27)],
        march29,
      ),
      3,
    );
  });

  test('the chip label and its threshold', () {
    expect(streakLabel(12), '12-day streak');
    expect(streakLabel(2), '2-day streak');
    expect(streakChipMinimumDays, 2);
  });
}
