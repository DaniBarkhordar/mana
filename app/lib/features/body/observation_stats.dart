/// The maths behind the observation drill-down, with no Flutter in it.
///
/// One screen serves every kind of observation — a weight, a night's HRV, a
/// ferritin result — so the statistics have to be kind-agnostic: a median,
/// a personal p10–p90 band, an axis range, a label. They live here rather
/// than in the widget so each can be checked by hand
/// (test/body/observation_stats_test.dart). Nothing here knows about the
/// database; it is given rows and returns numbers.
library;

import 'dart:math' as math;

/// One stored observation, as the drill-down needs it: enough to draw the
/// point, name its source, delete it, and show its reference range beside it.
///
/// A reference range travels with the row it belongs to (CLAUDE.md rule 8):
/// a lab result is never shown without the range the lab quoted, and never
/// with a range we invented.
class ObservationRecord {
  const ObservationRecord({
    required this.id,
    required this.at,
    required this.value,
    required this.unit,
    required this.source,
    this.sourceName,
    this.method,
    this.referenceLow,
    this.referenceHigh,
    this.referenceSource,
  });

  final String id;
  final DateTime at;
  final double value;
  final String unit;
  final String source;

  /// The device the store attributed the value to ("Oura", "Apple Watch"),
  /// when it named one. The health importer keeps it in the raw payload.
  final String? sourceName;

  /// The equation or import path that produced it (`sun2003`, `imported`).
  final String? method;
  final double? referenceLow;
  final double? referenceHigh;

  /// Who published the range: "NHS", the lab's name.
  final String? referenceSource;

  bool get hasReference => referenceLow != null || referenceHigh != null;
}

/// A reference range as one row carried it, with its publisher.
typedef ReferenceRange = ({double? low, double? high, String source});

/// Lower and upper edge of a band, in value units.
typedef Band = ({double lo, double hi});

// ---------------------------------------------------------------------------
// Order statistics
// ---------------------------------------------------------------------------

/// The plain median. Even counts average the middle pair, as
/// `TrendSmoother` does, so the headline and the chart line agree.
double median(List<double> values) {
  if (values.isEmpty) throw ArgumentError('median of nothing');
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

/// The [p]-th quantile (0–1) by linear interpolation between order
/// statistics: rank `h = (n − 1)·p`, then `x[⌊h⌋] + (h − ⌊h⌋)(x[⌊h⌋+1] −
/// x[⌊h⌋])`. This is R's default (type 7) and what spreadsheets call
/// PERCENTILE.INC, so a user can reproduce the band from an export.
double quantile(List<double> values, double p) {
  if (values.isEmpty) throw ArgumentError('quantile of nothing');
  if (p < 0 || p > 1) throw ArgumentError.value(p, 'p', 'must be 0–1');
  final sorted = [...values]..sort();
  if (sorted.length == 1) return sorted.first;
  final h = (sorted.length - 1) * p;
  final lo = h.floor();
  final hi = math.min(lo + 1, sorted.length - 1);
  return sorted[lo] + (h - lo) * (sorted[hi] - sorted[lo]);
}

/// How many readings a personal range needs before it is shown. A "usual
/// range" from three readings is noise dressed as a finding; fourteen is
/// two weeks of a nightly wearable, or two weeks on the scale.
const int usualRangeMinimum = 14;

/// The middle 80% of [values] — the 10th to the 90th percentile — or null
/// when there are fewer than [usualRangeMinimum] of them.
Band? usualRange(List<double> values) {
  if (values.length < usualRangeMinimum) return null;
  return (lo: quantile(values, 0.10), hi: quantile(values, 0.90));
}

/// Where [value] sits against [band]: below, within, above. Null band means
/// the baseline is still being collected.
UsualRangePosition positionIn(double value, Band? band) {
  if (band == null) return UsualRangePosition.calibrating;
  if (value < band.lo) return UsualRangePosition.below;
  if (value > band.hi) return UsualRangePosition.above;
  return UsualRangePosition.within;
}

enum UsualRangePosition { below, within, above, calibrating }

// ---------------------------------------------------------------------------
// Windows and the rolling median
// ---------------------------------------------------------------------------

/// How many days the rolling median looks back. Seven, as everywhere else in
/// the app: the Body and Progress charts draw the same line.
const int medianWindowDays = 7;

/// Rows taken within [days] of [asOf], oldest first. Zero or negative [days]
/// means every row.
List<ObservationRecord> windowOf(
  List<ObservationRecord> rows,
  int days, {
  required DateTime asOf,
}) {
  final sorted = [...rows]..sort((a, b) => a.at.compareTo(b.at));
  if (days <= 0) return sorted;
  final cutoff = asOf.subtract(Duration(days: days));
  return sorted.where((r) => r.at.isAfter(cutoff)).toList();
}

/// Rows in the trailing [medianWindowDays] up to [asOf]: what the headline
/// median is derived from.
List<ObservationRecord> headlineWindow(
  List<ObservationRecord> rows, {
  required DateTime asOf,
}) {
  final cutoff = asOf.subtract(const Duration(days: medianWindowDays));
  return rows
      .where((r) => r.at.isAfter(cutoff) && !r.at.isAfter(asOf))
      .toList();
}

/// The rolling median at each row: the median of every reading in the
/// [medianWindowDays] up to and including that row. A window of days rather
/// than a count of points, so a sparse series — a lab result twice a year —
/// is never smeared across years; each such point is its own median.
List<({DateTime at, double value})> rollingMedianSeries(
  List<ObservationRecord> window,
) {
  final sorted = [...window]..sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final r in sorted)
      (
        at: r.at,
        value: median([
          for (final o in headlineWindow(sorted, asOf: r.at)) o.value,
        ]),
      ),
  ];
}

// ---------------------------------------------------------------------------
// Axis
// ---------------------------------------------------------------------------

/// A round gridline step giving three to five bands over [range]: 1, 2 or
/// 5 times a power of ten. The Body chart's rule (0.5, 1, 2, 5, 10 for
/// kilograms) falls out of this for weight-sized ranges; steps and ferritin
/// need the larger multiples. Minutes step in quarter and whole hours so the
/// labels read as times.
double niceStep(double range, {String? unit}) {
  if (unit == 'min') {
    for (final step in const [15.0, 30.0, 60.0, 120.0, 180.0, 240.0]) {
      if (range / step <= 4.5) return step;
    }
    return 480;
  }
  if (range <= 0) return 1;
  var magnitude = math.pow(10, (math.log(range) / math.ln10).floor() - 1);
  for (var i = 0; i < 6; i++) {
    for (final m in const [1.0, 2.0, 5.0]) {
      final step = m * magnitude;
      if (range / step <= 4.5) return step;
    }
    magnitude *= 10;
  }
  return magnitude.toDouble();
}

/// The smallest vertical span a chart may show for a unit, so a flat week
/// does not look like a cliff: two kilograms for weight (the Body chart's
/// rule), two points for a percentage. Null means no floor beyond the data.
double? minSpanFor(String unit) => switch (unit) {
      'kg' => 2.0,
      '%' => 2.0,
      _ => null,
    };

/// The y axis for [values] plus anything that must be in the picture — a
/// band, a reference range — snapped to whole steps of [niceStep] so every
/// label sits on a gridline.
({double lo, double hi, double step}) axisRange(
  List<double> values, {
  Iterable<double> includes = const [],
  double? minSpan,
  String? unit,
}) {
  final all = [...values, ...includes];
  if (all.isEmpty) throw ArgumentError('axis of nothing');
  var lo = all.reduce(math.min);
  var hi = all.reduce(math.max);
  final floor = minSpan ??
      // No unit rule: a tenth of the value, or one whole unit, so a series
      // of identical readings still has a band to sit in.
      math.max(1.0, hi.abs() * 0.1);
  if (hi - lo < floor) {
    final mid = (hi + lo) / 2;
    lo = mid - floor / 2;
    hi = mid + floor / 2;
  }
  final step = niceStep(hi - lo, unit: unit);
  lo = (lo / step).floorToDouble() * step;
  hi = (hi / step).ceilToDouble() * step;
  if (hi - lo < step * 2) hi += step;
  return (lo: lo, hi: hi, step: step);
}

// ---------------------------------------------------------------------------
// Naming and formatting
// ---------------------------------------------------------------------------

/// The title a kind wears: `hrv_sdnn_ms` → "HRV (SDNN)", `ferritin_ug_l` →
/// "Ferritin". Kinds nobody has named yet are humanised from the id with the
/// unit suffix dropped, so a new lab analyte reads as words on day one.
String kindLabel(String kind) {
  const known = <String, String>{
    'weight_kg': 'Weight',
    'body_fat_pct': 'Body fat',
    'fat_free_mass_kg': 'Fat-free mass',
    'total_body_water_l': 'Body water',
    'skeletal_muscle_kg': 'Skeletal muscle',
    'resting_energy_kcal': 'Resting energy',
    'impedance_ohm': 'Impedance',
    'sleep_minutes': 'Sleep',
    'hrv_sdnn_ms': 'HRV (SDNN)',
    'hrv_rmssd_ms': 'HRV (RMSSD)',
    'resting_hr_bpm': 'Resting heart rate',
    'steps': 'Steps',
    'workout_minutes': 'Workouts',
  };
  final named = known[kind];
  if (named != null) return named;
  const unitSuffixes = {
    'kg', 'g', 'pct', 'ms', 'bpm', 'l', 'ml', 'dl', 'ug', 'mg', 'ng', 'mmol', //
    'umol', 'nmol', 'pmol', 'iu', 'min', 'minutes', 'kcal', 'ohm', 'cm', 'mm',
    'count', 'per',
  };
  final parts = kind.split('_').where((p) => p.isNotEmpty).toList();
  while (parts.length > 1 && unitSuffixes.contains(parts.last)) {
    parts.removeLast();
  }
  final words = parts.join(' ');
  if (words.isEmpty) return kind;
  return words[0].toUpperCase() + words.substring(1);
}

/// The unit as printed beside a number. `ug/L` becomes µg/L; a count has no
/// unit word; minutes are folded into the number itself by [formatValue].
String unitLabel(String unit) => switch (unit) {
      'ug/L' || 'ug/l' => 'µg/L',
      'count' => '',
      'min' => '',
      'kcal/day' => 'kcal',
      _ => unit,
    };

/// A value as the screen prints it. Body fat and weight to one decimal —
/// a foot-to-foot scale reporting more is claiming a precision it does not
/// have; milliseconds, beats, steps, ohms and lab counts as integers;
/// minutes as hours and minutes.
String formatValue(double value, String unit) => switch (unit) {
      'min' => _hoursMinutes(value),
      '%' || 'kg' || 'L' => value.toStringAsFixed(1),
      'ms' ||
      'bpm' ||
      'count' ||
      'ohm' ||
      'kcal/day' ||
      'ug/L' ||
      'ug/l' =>
        _thousands(value.round()),
      _ => value.abs() >= 100
          ? _thousands(value.round())
          : value.toStringAsFixed(1),
    };

/// A gridline label: integers when the step is whole, one decimal otherwise,
/// hours and minutes for minutes.
String formatAxis(double value, double step, String unit) {
  if (unit == 'min') return _hoursMinutes(value);
  if (step >= 1) return _thousands(value.round());
  return value.toStringAsFixed(1);
}

/// A reference range in words: "30–400 µg/L", "under 5 mmol/L", "over 30".
String formatReference(ReferenceRange range, String unit) {
  final u = unitLabel(unit);
  final suffix = u.isEmpty ? '' : ' $u';
  String f(double v) => formatValue(v, unit);
  final lo = range.low;
  final hi = range.high;
  if (lo != null && hi != null) return '${f(lo)}–${f(hi)}$suffix';
  if (hi != null) return 'under ${f(hi)}$suffix';
  if (lo != null) return 'over ${f(lo)}$suffix';
  return '';
}

String _hoursMinutes(double minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String _thousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

// ---------------------------------------------------------------------------
// Bioimpedance kinds
// ---------------------------------------------------------------------------

/// Observation kinds that are predictions from a published bioimpedance
/// equation, and the `Metric.key` the engine files each under. The screen
/// reads the equation and its standard error off the engine's own result
/// through this map; no error figure is ever typed into the screen.
const Map<String, String> biaMetricKeyForKind = {
  'body_fat_pct': 'bodyFatPercent',
  'fat_free_mass_kg': 'fatFreeMass',
  'total_body_water_l': 'totalBodyWater',
  'skeletal_muscle_kg': 'skeletalMuscleMass',
  'resting_energy_kcal': 'restingEnergy',
};

bool isBiaKind(String kind) => biaMetricKeyForKind.containsKey(kind);

/// "±3.9 kg" / "±4.9 pts" — a published standard error in words. Percentage
/// points rather than "%", so ±4.9 is not read as a relative error.
String formatUncertainty(double se, String unit) {
  final u = unit == '%' ? 'pts' : unitLabel(unit);
  final n = se >= 10 ? se.toStringAsFixed(0) : se.toStringAsFixed(1);
  return u.isEmpty ? '±$n' : '±$n $u';
}
