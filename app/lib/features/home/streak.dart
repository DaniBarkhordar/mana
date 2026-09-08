/// The logging streak: consecutive calendar days with at least one meal,
/// ending today or yesterday.
///
/// Pure Dart on dates alone, so it can be checked by hand
/// (test/home/streak_test.dart). The provider under it only supplies the set
/// of logged days; nothing here knows about SQLite or the clock.
library;

/// Local midnight of [t], for grouping by calendar day.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// The day before [day], by calendar arithmetic rather than by subtracting
/// 24 hours: on the morning the clocks go forward, midnight minus a day of
/// hours lands at 23:00 two days back, and the streak would skip a day.
DateTime dayBefore(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// The chip is hidden under this many days. A one-day streak is a meal, not
/// a streak, and the word would only draw attention to the gap before it.
const int streakChipMinimumDays = 2;

/// Consecutive logged days ending on [today], or ending yesterday when today
/// has not been logged yet — a streak should not read as broken at breakfast.
///
/// [loggedDays] may hold any timestamps; each is reduced to its local
/// calendar day. A gap of even one day ends the count: the streak is a
/// statement about consecutive days, and a day with nothing logged is
/// unknown, not zero.
int loggingStreak(Iterable<DateTime> loggedDays, DateTime today) {
  final days = {for (final d in loggedDays) dayOf(d)};
  final start = dayOf(today);
  var day = days.contains(start) ? start : dayBefore(start);
  var n = 0;
  while (days.contains(day)) {
    n++;
    day = dayBefore(day);
  }
  return n;
}

/// "12-day streak" — the chip's label.
String streakLabel(int days) => '$days-day streak';
