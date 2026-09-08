/// Personal baselines for wearable observations.
///
/// The question a person actually has about last night's HRV is not "is 42 ms
/// good" — there is no published answer for one individual — but "is it
/// usual for me". So the comparison is against the person's own recent
/// history and nothing else: the median of the previous [windowDays],
/// excluding the latest point itself, so a value is never compared with a
/// baseline it has already moved.
///
/// Median rather than mean for the same reason the body-fat trend uses one:
/// a single bad night, or a night the watch was worn loose, must not drag
/// the line. And no baseline at all until [minPoints] exist — a "usual"
/// worked out from three nights is noise dressed as a finding.
///
/// Pure maths, no Flutter, so every number here is checked by hand in
/// test/health/baselines_test.dart.
library;

/// One point on a trend line, oldest first in any series passed here.
typedef BaselinePoint = ({DateTime at, double value});

/// Median of [values]; null for an empty list. Even counts average the two
/// middle values.
double? median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) return null;
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

/// The latest observation of one kind against the person's own baseline.
class PersonalBaseline {
  const PersonalBaseline({
    required this.latest,
    required this.baseline,
    required this.baselineCount,
    required this.minPoints,
    required this.windowDays,
  });

  /// The most recent point: last night's sleep, yesterday's steps.
  final BaselinePoint latest;

  /// Median of the points in the [windowDays] before [latest], not counting
  /// [latest]. Null until [baselineCount] reaches [minPoints].
  final double? baseline;

  /// How many earlier points fell inside the window.
  final int baselineCount;

  /// How many are needed before [baseline] is reported.
  final int minPoints;

  final int windowDays;

  /// Latest minus baseline, in the kind's own unit. Positive means above
  /// the usual. Null while there is no baseline.
  double? get delta => baseline == null ? null : latest.value - baseline!;

  bool get hasBaseline => baseline != null;
}

/// Works out the [PersonalBaseline] for a [series] of one kind, oldest first.
///
/// Returns null when the series is empty or when the latest point is older
/// than [recency] as of [asOf]: a reading from a fortnight ago is not "last
/// night", and showing it as such would be a small lie.
///
/// The baseline window runs back [windowDays] from the latest point's own
/// timestamp, not from [asOf], so a gap in wearing the device shortens the
/// window rather than silently comparing against stale nights.
PersonalBaseline? baselineFor(
  List<BaselinePoint> series, {
  required DateTime asOf,
  int windowDays = 30,
  int minPoints = 5,
  Duration recency = const Duration(days: 7),
}) {
  if (series.isEmpty) return null;
  final sorted = series.toList()..sort((a, b) => a.at.compareTo(b.at));
  final latest = sorted.last;
  if (asOf.difference(latest.at) > recency) return null;

  final cutoff = latest.at.subtract(Duration(days: windowDays));
  final earlier = <double>[];
  // Everything strictly before the latest point: the point is compared with
  // its own history, never with a median it is already part of.
  for (var i = 0; i < sorted.length - 1; i++) {
    final p = sorted[i];
    if (p.at.isAfter(cutoff)) earlier.add(p.value);
  }

  return PersonalBaseline(
    latest: latest,
    baseline: earlier.length < minPoints ? null : median(earlier),
    baselineCount: earlier.length,
    minPoints: minPoints,
    windowDays: windowDays,
  );
}

/// Whether a difference is worth a direction word at all. Below this
/// fraction of the baseline the value is "about your usual": a step count
/// 40 higher than a 7,000-step median is not "above".
const double baselineLevelFraction = 0.02;

/// Which way a value sits against its baseline, in plain words, without a
/// score or a verdict. The words are the comparison and nothing more
/// (CLAUDE.md rules 3 and 5): "12 ms below your usual" is a fact about the
/// person's own history; "your recovery is 62" is a claim nobody can check.
enum BaselineDirection {
  above('above your usual'),
  below('below your usual'),
  level('about your usual');

  const BaselineDirection(this.words);

  final String words;
}

/// The direction of [delta] against [baseline], treating anything within
/// [baselineLevelFraction] of the baseline as level.
BaselineDirection directionOf(double delta, double baseline) {
  final threshold = baseline.abs() * baselineLevelFraction;
  if (delta.abs() <= threshold) return BaselineDirection.level;
  return delta > 0 ? BaselineDirection.above : BaselineDirection.below;
}
