/// Body composition, presented the way the evidence says it should be.
///
/// The design constraint, stated plainly: published limits of agreement for
/// foot-to-foot bioimpedance against a four-compartment reference run to roughly
/// six kilograms of fat mass at the individual level, while between-day
/// repeatability under controlled conditions is well under one kilogram. Large
/// bias, small noise.
///
/// That has one honest consequence for the interface: lead with the trend, and
/// never show a single reading as though it were a fact. Every competitor in
/// this category prints "18.4%" in 48-point type. Mananu prints the seven-day
/// median, an uncertainty band, and today's raw figure underneath it.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/bia/body_composition.dart';
import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/tokens.dart';

class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestBodyMeasurementProvider);
    final trend = ref.watch(bodyFatTrendProvider);
    final rate = ref.watch(weightTrendRateProvider);
    final series = ref.watch(weightSeriesProvider);
    final driver = ref.watch(bodyScaleDriverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body'),
        actions: [
          if (driver is SimulatedScaleDriver && latest != null)
            IconButton(
              onPressed: () => driver.simulateReading(),
              icon: const Icon(Icons.monitor_weight_outlined),
              tooltip: 'Simulate stepping on (demo)',
            ),
          IconButton(
            onPressed: () => _showProtocol(context),
            icon: const Icon(Icons.info_outline),
            tooltip: 'How to get a comparable reading',
          ),
        ],
      ),
      body: latest == null
          ? _NoReadingsYet(driver: driver)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.lg,
                MananuSpacing.sm,
                MananuSpacing.lg,
                120,
              ),
              children: [
                _TrendHeadline(
                  medianBodyFat: trend,
                  latest: latest,
                  weeklyRateKg: rate,
                ),
                const SizedBox(height: MananuSpacing.xl),
                if (_WeightChartCard.hasEnough(series)) ...[
                  _WeightChartCard(series: series),
                  const SizedBox(height: MananuSpacing.xl),
                ],
                if (latest.notes.isNotEmpty) ...[
                  _NotesCard(
                    notes: latest.notes,
                    confidence: latest.confidence,
                  ),
                  const SizedBox(height: MananuSpacing.xl),
                ],
                MananuSection(
                  title: 'This reading',
                  child: Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < latest.metrics.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _MetricRow(metric: latest.metrics[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MananuSpacing.xl),
                const _MethodCard(),
              ],
            ),
    );
  }

  void _showProtocol(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ProtocolSheet(),
    );
  }
}

class _TrendHeadline extends StatelessWidget {
  const _TrendHeadline({
    required this.medianBodyFat,
    required this.latest,
    required this.weeklyRateKg,
  });

  final double? medianBodyFat;
  final BodyCompositionResult latest;
  final double? weeklyRateKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = latest.metric('bodyFatPercent');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BODY FAT · 7-DAY MEDIAN',
              style: MananuType.label
                  .copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: MananuSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  medianBodyFat == null
                      ? '—'
                      : medianBodyFat!.toStringAsFixed(1),
                  style: MananuType.display.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(width: 4),
                Text(
                  '%',
                  style: MananuType.title.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: MananuSpacing.md),
                if (today?.uncertainty != null)
                  // Takes what is left and shrinks rather than overflowing
                  // under large accessibility text.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MananuSpacing.md,
                            vertical: MananuSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: MananuSpacing.radiusSm,
                          ),
                          child: Text(
                            '± ${today!.uncertainty!.toStringAsFixed(1)} pts',
                            style: MananuType.caption.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MananuSpacing.md),
            Text(
              today == null
                  ? 'Step on the scale to start a trend.'
                  : "Today's reading was ${today.display}. "
                      'Single readings move with hydration; the median is the '
                      'one to watch.',
              style: MananuType.caption.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (weeklyRateKg != null) ...[
              const Divider(height: MananuSpacing.xxl),
              Row(
                children: [
                  Icon(
                    weeklyRateKg! < 0 ? Icons.trending_down : Icons.trending_up,
                    size: 18,
                    color: MananuColors.brass,
                  ),
                  const SizedBox(width: MananuSpacing.sm),
                  Expanded(
                    child: Text(
                      '${weeklyRateKg!.abs().toStringAsFixed(2)} kg per week '
                      '${weeklyRateKg! < 0 ? 'down' : 'up'} over three weeks',
                      style: MananuType.body.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Weight over the last thirty days: the rolling median as a line, each raw
/// reading as a faint dot behind it. The trend is the signal; the dots show
/// the noise honestly.
class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({required this.series});

  final List<({DateTime at, double value})> series;

  static const _days = 30;

  /// Two readings on one day make a dot, not a trend.
  static bool hasEnough(List<({DateTime at, double value})> series) {
    final window = _window(series);
    if (window.length < 3) return false;
    return window.last.at.difference(window.first.at).inHours >= 24;
  }

  static List<({DateTime at, double value})> _window(
    List<({DateTime at, double value})> series,
  ) {
    final cutoff = DateTime.now().subtract(const Duration(days: _days));
    return series.where((p) => p.at.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final window = _window(series);
    final t0 = window.first.at;
    double x(DateTime t) => t.difference(t0).inMinutes / (24 * 60);

    const smoother = TrendSmoother();
    final raw = [for (final p in window) FlSpot(x(p.at), p.value)];
    final median = [
      for (final p in window)
        FlSpot(x(p.at), smoother.rollingMedian(window, asOf: p.at) ?? p.value),
    ];

    var lo = window.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    var hi = window.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    // At least a two-kilogram band, so a flat week does not look like a cliff.
    if (hi - lo < 2) {
      final mid = (hi + lo) / 2;
      lo = mid - 1;
      hi = mid + 1;
    }
    lo = lo.floorToDouble() - 0.5;
    hi = hi.ceilToDouble() + 0.5;
    final yInterval = ((hi - lo) / 3).clamp(0.5, 20.0);
    final maxX = x(window.last.at);
    final muted = scheme.onSurface.withValues(alpha: 0.45);
    final dateFormat = DateFormat('d MMM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.xl,
          MananuSpacing.xl,
          MananuSpacing.xl,
          MananuSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEIGHT · $_days DAYS',
              style: MananuType.label.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.md),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX <= 0 ? 1 : maxX,
                  minY: lo,
                  maxY: hi,
                  clipData: const FlClipData.none(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outline, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            v.toStringAsFixed(1),
                            style: MananuType.caption.copyWith(
                              fontSize: 11,
                              color: muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: maxX <= 0 ? 1 : maxX,
                        getTitlesWidget: (v, meta) {
                          final isEnd = (v - maxX).abs() < 1e-6;
                          if (v != 0 && !isEnd) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dateFormat.format(
                                t0.add(
                                  Duration(minutes: (v * 24 * 60).round()),
                                ),
                              ),
                              style: MananuType.caption
                                  .copyWith(fontSize: 11, color: muted),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: raw,
                      barWidth: 0,
                      color: Colors.transparent,
                      dotData: FlDotData(
                        getDotPainter: (spot, pct, bar, i) =>
                            FlDotCirclePainter(
                          radius: 2.6,
                          color: MananuColors.mist.withValues(alpha: 0.45),
                          strokeWidth: 0,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: median,
                      barWidth: 2.5,
                      color: MananuColors.brass,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'The line is the 7-day median. The dots are each reading — '
              'that spread is normal.',
              style: MananuType.caption.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEstimate = metric.derived == Derived.notMeasured;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      title: Row(
        children: [
          Flexible(child: Text(metric.label, style: MananuType.bodyStrong)),
          if (isEstimate) ...[
            const SizedBox(width: MananuSpacing.sm),
            const ProvenanceBadge(
              weighed: false,
              label: 'Not measured',
              dense: true,
            ),
          ],
        ],
      ),
      subtitle: metric.caveat == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                metric.caveat!,
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(metric.display, style: MananuType.number.copyWith(fontSize: 17)),
          if (metric.uncertaintyDisplay != null)
            Text(
              metric.uncertaintyDisplay!,
              style: MananuType.caption.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.confidence});

  final List<String> notes;
  final ReadingConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: MananuColors.brass,
                ),
                const SizedBox(width: MananuSpacing.sm),
                Expanded(
                  child: Text(
                    confidence == ReadingConfidence.weightOnly
                        ? 'Weight only for this reading'
                        : 'About this reading',
                    style:
                        MananuType.bodyStrong.copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.sm),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: MananuSpacing.sm),
                child: Text(
                  n,
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Says which published equations produced the numbers.
///
/// Beyond being the right thing to do, this is a concrete asset: Apple's review
/// guideline on physical-harm risk expects health-measurement claims to be
/// supported by disclosed data and methodology. Shipping the citation in the app
/// is cheaper than arguing with a reviewer about it.
class _MethodCard extends StatelessWidget {
  const _MethodCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How these numbers are worked out',
              style: MananuType.heading,
            ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Your scale passes a small current through your body and measures '
              'the resistance. Water conducts; fat does not. Everything except '
              'your weight is calculated from that one measurement using '
              'published equations — Sun (2003) for fat-free mass and body '
              'water, Janssen (2000) for skeletal muscle, Cunningham (1980) for '
              'resting energy.\n\n'
              'Bioimpedance is good at showing change over weeks and poor at '
              'absolute figures for one person on one day. Mananu shows you the '
              'trend for that reason.',
              style: MananuType.body.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolSheet extends StatelessWidget {
  const _ProtocolSheet();

  static const _rules = <(IconData, String, String)>[
    (
      Icons.wb_twilight,
      'First thing in the morning',
      'Before eating or drinking, after the toilet.'
    ),
    (
      Icons.checkroom,
      'Bare, dry feet',
      'Socks and tights break the circuit. Damp feet skew it.'
    ),
    (
      Icons.fitness_center,
      'Not straight after training',
      'Sweat loss lowers body water, which makes body fat read high.'
    ),
    (
      Icons.wine_bar,
      'Not the morning after drinking',
      'Alcohol shifts body water for about a day.'
    ),
    (
      Icons.grid_on,
      'Hard floor, not carpet',
      'A soft surface changes the load on the sensors.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        MananuSpacing.sm,
        MananuSpacing.xl,
        MananuSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Getting comparable readings', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Bioimpedance measures body water, so anything that moves your '
            'water moves the result. Same conditions every time matters far '
            'more than any single number.',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          for (final (icon, title, detail) in _rules)
            Padding(
              padding: const EdgeInsets.only(bottom: MananuSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: MananuColors.brass),
                  const SizedBox(width: MananuSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: MananuType.bodyStrong),
                        Text(
                          detail,
                          style: MananuType.caption.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          const SizedBox(height: MananuSpacing.md),
          Text(
            'Do not use the body scale if you have a pacemaker or another '
            'implanted electronic device. If you are pregnant, speak to your '
            'midwife or doctor before using the body-composition features.',
            style: MananuType.caption.copyWith(color: MananuColors.warning),
          ),
        ],
      ),
    );
  }
}

class _NoReadingsYet extends StatelessWidget {
  const _NoReadingsYet({required this.driver});

  final ScaleDriver driver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final demo = driver;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 44,
              color: scheme.outline,
            ),
            const SizedBox(height: MananuSpacing.lg),
            const Text('No readings yet', style: MananuType.heading),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Step on your Mananu body scale with bare feet. The first reading '
              'takes about ten seconds.',
              textAlign: TextAlign.center,
              style: MananuType.body.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (demo is SimulatedScaleDriver) ...[
              const SizedBox(height: MananuSpacing.xl),
              // The review account's route through the flow. Labelled as a
              // demo so a reading from it can never pass as a measurement.
              OutlinedButton.icon(
                onPressed: () => demo.simulateReading(),
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Simulate stepping on'),
              ),
              const SizedBox(height: MananuSpacing.sm),
              Text(
                'Demo scale — no hardware connected',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
