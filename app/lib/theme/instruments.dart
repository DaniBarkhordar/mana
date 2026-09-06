/// The small drawn pieces the screens share: the brand mark, an arc gauge, a
/// sparkline, and an animated number. All colour comes from the tokens.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

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
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.progress,
    required this.child,
    this.size = 148,
    this.strokeWidth = 10,
  });

  /// 0 to 1; beyond 1 the arc fills and turns to the warning colour.
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;

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
  });

  final double progress;
  final Color track;
  final Color fill;
  final double strokeWidth;

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
    if (p > 0) {
      canvas.drawArc(rect, _start, _sweep * p, false, paint..color = fill);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}

/// A small trend line with a dot on the last point. No axes: it is a hint of
/// direction, not a chart. The Body screen has the chart.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 96,
    this.height = 32,
  });

  final List<double> values;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
        values: values,
        color: MananuColors.brass,
        dot: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.dot,
  });

  final List<double> values;
  final Color color;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 0.5) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.25;
      hi = mid + 0.25;
    }
    const pad = 4.0;
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
      old.values != values || old.color != color;
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
