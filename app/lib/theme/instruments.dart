/// The small drawn pieces the screens share: the brand mark, an arc gauge, a
/// sparkline, an animated number, and the provenance vocabulary. All colour
/// comes from the tokens.
///
/// The provenance grammar, so screens do not each invent one:
///
/// * [ProvenanceBadge] (weighed / estimated) is for scale quantities only —
///   a portion, a cooking fat, a body reading. Those are the two colours with
///   product meaning and they mean exactly that.
/// * A value that came from a wearable is neither weighed nor guessed by us;
///   it wears a [SourceBadge] naming the device and the store it came
///   through.
/// * A statistic we worked out from several observations — a 7-day median, a
///   28-night baseline — wears a [DerivedNote] saying what it was derived
///   from, and where it sits against the baseline is said in words by a
///   [RangeMarker]. Until the baseline exists, [CalibrationProgress] says how
///   far along it is.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data/models.dart' show sourceLabel;
import 'tokens.dart';

/// The three-stroke mark: the three syllables, and a balance at rest. The
/// middle stroke is brass — the measured one. Proportions from
/// `brand/mananu-wordmark.svg`.
class MananuMark extends StatelessWidget {
  const MananuMark({super.key, this.height = 20, this.color});

  final double height;

  /// The outer strokes. Defaults to the surface's foreground.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final stroke = height * 0.225;
    final gap = height * 0.1625;
    final width = height * 1.05;
    Widget bar(Color c) => Container(
          width: width,
          height: stroke,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(stroke / 2),
          ),
        );
    return Semantics(
      label: 'Mananu',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bar(ink),
          SizedBox(height: gap),
          bar(MananuColors.brass),
          SizedBox(height: gap),
          bar(ink),
        ],
      ),
    );
  }
}

/// A 270° arc: quiet track, brass progress, warning colour past 100%.
///
/// With [measuredFraction] set, the progress is split into what was weighed
/// and what was estimated, so a day's energy ring shows at a glance how much
/// of it the scale can vouch for. Without it the arc paints exactly as it
/// always has.
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.progress,
    required this.child,
    this.size = 148,
    this.strokeWidth = 10,
    this.measuredFraction,
  });

  /// 0 to 1; beyond 1 the arc fills and turns to the warning colour.
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;

  /// The share of [progress] that was measured rather than estimated, 0 to 1.
  /// When set, the first that fraction of the filled sweep is drawn in
  /// [MananuColors.measured] and the rest in [MananuColors.estimated]. Past
  /// 100% the whole sweep is the warning colour regardless, as before: a day
  /// over its energy target is over it whichever way it was counted.
  final double? measuredFraction;

  /// The two sweeps as fractions of the full 270° arc: the measured part
  /// first, the estimated part after it. Exposed so a test can check the
  /// split arithmetic without inspecting pixels.
  @visibleForTesting
  static ({double measured, double estimated}) sweepFractions(
    double progress,
    double measuredFraction,
  ) {
    final p = progress.clamp(0.0, 1.0);
    final m = measuredFraction.clamp(0.0, 1.0);
    return (measured: p * m, estimated: p * (1 - m));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        size: Size.square(size),
        painter: _ArcPainter(
          progress: value,
          track: scheme.surfaceContainerHighest,
          fill: value > 1 ? MananuColors.warning : scheme.primary,
          strokeWidth: strokeWidth,
          measuredFraction: value > 1 ? null : measuredFraction,
        ),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.strokeWidth,
    this.measuredFraction,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double strokeWidth;
  final double? measuredFraction;

  static const _start = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, paint..color = track);
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final split = measuredFraction;
    if (split == null) {
      canvas.drawArc(rect, _start, _sweep * p, false, paint..color = fill);
      return;
    }
    final parts = ArcGauge.sweepFractions(p, split);
    // The estimated sweep is drawn for the whole progress and the measured
    // sweep over the start of it, so the round cap at the join belongs to the
    // measured segment and the two never show a seam.
    if (parts.estimated > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * p,
        false,
        paint..color = MananuColors.estimated,
      );
    }
    if (parts.measured > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * parts.measured,
        false,
        paint..color = MananuColors.measured,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.measuredFraction != measuredFraction;
}

/// A small trend line with a dot on the last point. No axes: it is a hint of
/// direction, not a chart. The Body screen has the chart.
///
/// An optional [band] — the user's usual range, in the same units as
/// [values] — is washed in behind the line so a point can be seen to sit
/// inside or outside it without a second colour.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 96,
    this.height = 32,
    this.band,
  });

  final List<double> values;
  final double width;
  final double height;

  /// Lower and upper edge of the band, in value units. The vertical scale
  /// stretches to include it, so the band is always fully in the picture.
  final ({double lo, double hi})? band;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
        values: values,
        color: MananuColors.brass,
        dot: scheme.surface,
        band: band,
        bandColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.dot,
    this.band,
    this.bandColor,
  });

  final List<double> values;
  final Color color;
  final Color dot;
  final ({double lo, double hi})? band;
  final Color? bandColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    final b = band;
    if (b != null) {
      lo = math.min(lo, math.min(b.lo, b.hi));
      hi = math.max(hi, math.max(b.lo, b.hi));
    }
    if (hi - lo < 0.5) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.25;
      hi = mid + 0.25;
    }
    const pad = 4.0;
    final bandFill = bandColor;
    if (b != null && bandFill != null) {
      final inner = size.height - 2 * pad;
      final top = pad + inner * (hi - math.max(b.lo, b.hi)) / (hi - lo);
      final bottom = pad + inner * (hi - math.min(b.lo, b.hi)) / (hi - lo);
      canvas.drawRect(
        Rect.fromLTRB(0, top, size.width, bottom),
        Paint()..color = bandFill,
      );
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = pad + (size.width - 2 * pad) * i / (values.length - 1);
      final y = pad + (size.height - 2 * pad) * (hi - values[i]) / (hi - lo);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final last = Offset(
      size.width - pad,
      pad + (size.height - 2 * pad) * (hi - values.last) / (hi - lo),
    );
    canvas.drawCircle(last, 4, Paint()..color = dot);
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.band != band ||
      old.bandColor != bandColor;
}

/// A number that rolls to its new value rather than jumping. Tabular figures
/// keep the width steady while it moves.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber(
    this.value, {
    super.key,
    required this.style,
    this.decimals = 0,
    this.format,
  });

  final double value;
  final TextStyle style;
  final int decimals;

  /// Overrides the default fixed-decimal rendering, e.g. to add thousands
  /// separators.
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        format?.call(v) ?? v.toStringAsFixed(decimals),
        style: style,
      ),
    );
  }
}

/// 1,234 — the app's one number format for energy figures.
String thousands(num n) {
  final s = n.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

/// The screen header the tabs share: a small label (usually the date) above
/// the title, the mark at the right.
class MananuHeader extends StatelessWidget {
  const MananuHeader({
    super.key,
    required this.title,
    this.label,
    this.actions = const [],
  });

  final String title;
  final String? label;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.lg,
        MananuSpacing.md,
        MananuSpacing.sm,
        MananuSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!.toUpperCase(),
                    style: MananuType.label.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (label != null) const SizedBox(height: 2),
                Text(
                  title,
                  style: MananuType.display.copyWith(
                    fontSize: 30,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
          if (actions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(right: MananuSpacing.sm),
              child: MananuMark(height: 18),
            ),
        ],
      ),
    );
  }
}

/// Names where a value came from: "Oura via Apple Health", "Apple Health",
/// "Mananu body scale", "Demo scale", "Diary".
///
/// A wearable value is not weighed and not guessed by us, so neither
/// provenance colour applies; what the user needs is which device said it and
/// which store it came through. [source] is the observation's source id and
/// [sourceName] the device the store attributed it to, when it named one.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.source, {super.key, this.sourceName});

  final String source;
  final String? sourceName;

  /// "Oura via Apple Health"; just "Apple Health" when the store did not name
  /// a device, or named itself.
  String get text {
    final store = sourceLabel(source);
    final device = sourceName?.trim();
    if (device == null || device.isEmpty || device == store) return store;
    return '$device via $store';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: MananuSpacing.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MananuType.caption.copyWith(color: fg, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a value sits against the user's own baseline.
enum RangeState {
  within('within your usual range'),
  above('above your usual range'),
  below('below your usual range'),

  /// Not enough observations yet to say what usual is.
  calibrating('collecting your baseline');

  const RangeState(this.words);

  /// The phrase the [RangeMarker] shows.
  final String words;
}

/// Says, in words, whether a value is inside the user's usual range.
///
/// An outlined pill and nothing more. A wearable's HRV being below its usual
/// range is information, not a verdict: colouring it red would turn a
/// comparison with the user's own history into something that looks like a
/// diagnosis, and the warning and danger colours are kept for things that
/// have gone wrong. The range is the user's own baseline, never a population
/// reference, and the pill only ever states the comparison.
class RangeMarker extends StatelessWidget {
  const RangeMarker(this.state, {super.key});

  final RangeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: state.words,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(999)),
          ),
          child: Text(
            state.words,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// How far along a baseline is: "Collecting your baseline · 6 of 14 nights
/// from Oura", with a thin brass track underneath.
///
/// A "usual range" worked out from three nights is noise dressed as a
/// finding, so a range is not shown until [needed] observations exist. This
/// is what the screen shows in the meantime, so the empty space explains
/// itself. [label] is the plural noun and the source: "nights from Oura".
class CalibrationProgress extends StatelessWidget {
  const CalibrationProgress(
    this.count,
    this.needed, {
    super.key,
    this.label,
  });

  final int count;
  final int needed;
  final String? label;

  /// [count] clamped to [needed]: a baseline that is done is 14 of 14, not
  /// 19 of 14.
  int get shown => count.clamp(0, math.max(0, needed));

  /// The full caption: "Collecting your baseline · 6 of 14 nights from Oura".
  String get caption {
    final tail = label == null ? '' : ' $label';
    return 'Collecting your baseline · $shown of $needed$tail';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = needed <= 0 ? 0.0 : shown / needed;
    return Semantics(
      label: caption,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              style: MananuType.caption.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: MananuSpacing.sm),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(1.5)),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: scheme.surfaceContainerHighest),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: const ColoredBox(color: MananuColors.brass),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "derived from 14 nights" — the caption under a statistic that is neither
/// measured nor estimated but worked out from several observations.
///
/// A 7-day median is not a reading; nothing measured it. Saying what it was
/// derived from is the honest label, and it keeps the weighed / estimated
/// badges for the quantities they mean. [unit] is the plural noun: "nights",
/// "readings", "days".
class DerivedNote extends StatelessWidget {
  const DerivedNote(this.n, this.unit, {super.key});

  final int n;
  final String unit;

  String get text => 'derived from $n $unit';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: MananuType.caption.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
