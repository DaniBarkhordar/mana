/// Progress — the screen people open on a Sunday.
///
/// Today answers "how is today going"; Body answers "what is my trend". This
/// tab answers the question in between: did the week add up? Weight against
/// the goal, energy against the target, the macros, whether the diary was
/// kept, and what the wearable saw — every figure with the same provenance
/// discipline as the rest of the app. A weekly average of estimated meals is
/// still an estimate, and the card says so.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'in_your_data_card.dart';
import 'progress_providers.dart';
import 'weekly_review_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weeklySummaryProvider);
    final consistency = ref.watch(consistencyProvider);
    final target = ref.watch(dailyTargetProvider);
    final series = ref.watch(weightSeriesProvider);
    final wearables = ref.watch(wearableComparisonsProvider);
    final weekStart = ref.watch(progressWeekStartProvider);

    final nothingAtAll = week.isEmpty &&
        consistency.kcalByDay.isEmpty &&
        series.isEmpty &&
        wearables.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
          children: [
            const MananuHeader(label: 'This week', title: 'Progress'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.lg),
              child: nothingAtAll
                  ? const Padding(
                      padding: EdgeInsets.only(top: MananuSpacing.sm),
                      child: _EmptyCard(
                        title: 'Your first week starts now',
                        message: 'Weigh a meal or step on the scale and this '
                            'page fills in as the week goes on.',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: MananuSpacing.sm),
                        const WeeklyReviewCard(),
                        const SizedBox(height: MananuSpacing.xl),
                        MananuSection(
                          title: 'Weight',
                          child: _WeightCard(series: series),
                        ),
                        const SizedBox(height: MananuSpacing.xl),
                        MananuSection(
                          title: 'Energy',
                          trailing: Text(
                            _weekLabel(weekStart),
                            style: MananuType.label.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: _EnergyCard(week: week, target: target),
                        ),
                        const SizedBox(height: MananuSpacing.xl),
                        MananuSection(
                          title: 'Macros',
                          child: _MacrosCard(week: week, target: target),
                        ),
                        const SizedBox(height: MananuSpacing.xl),
                        MananuSection(
                          title: 'Consistency',
                          child: _ConsistencyCard(
                            week: week,
                            consistency: consistency,
                            targetKcal: target?.kcal,
                          ),
                        ),
                        if (wearables.isNotEmpty) ...[
                          const SizedBox(height: MananuSpacing.xl),
                          MananuSection(
                            title: 'Wearables',
                            child: _WearablesCard(comparisons: wearables),
                          ),
                        ],
                        const SizedBox(height: MananuSpacing.xl),
                        const InYourDataCard(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final f = DateFormat('d MMM');
    return '${f.format(weekStart)} – ${f.format(end)}'.toUpperCase();
  }
}

/// A round gridline step giving three to five bands over [range] kg:
/// 0.5, 1, 2, 5 or 10. Same rule as the Body screen's chart.
double _niceStep(double range) {
  for (final step in const [0.5, 1.0, 2.0, 5.0]) {
    if (range / step <= 4.5) return step;
  }
  return 10;
}

// ---------------------------------------------------------------------------
// Weight
// ---------------------------------------------------------------------------

/// Thirty or ninety days of weight: the 7-day median as a line, each raw
/// reading as a faint dot, a dashed goal line when the profile has a target,
/// and the three-week rate underneath. Drawn to match the Body screen's chart
/// exactly so the two tabs read as one instrument.
class _WeightCard extends ConsumerWidget {
  const _WeightCard({required this.series});

  final List<({DateTime at, double value})> series;

  static List<({DateTime at, double value})> _window(
    List<({DateTime at, double value})> series,
    int days,
  ) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return series.where((p) => p.at.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final days = ref.watch(progressWeightRangeProvider);
    final rate = ref.watch(progressWeeklyRateProvider);
    final goal = ref.watch(targetWeightKgProvider);
    final source =
        ref.watch(observationSourceProvider('weight_kg')).valueOrNull;
    final muted = scheme.onSurface.withValues(alpha: 0.45);
    final window = _window(series, days);
    final enough = window.length >= 3 &&
        window.last.at.difference(window.first.at).inHours >= 24;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.xl,
          MananuSpacing.lg,
          MananuSpacing.xl,
          MananuSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'WEIGHT · $days DAYS',
                    style: MananuType.label.copyWith(color: muted),
                  ),
                ),
                _RangeControl(
                  days: days,
                  onChanged: (d) =>
                      ref.read(progressWeightRangeProvider.notifier).state = d,
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.md),
            if (!enough)
              _InlineEmpty(
                message: series.isEmpty
                    ? 'Step on the scale a few mornings and a trend appears '
                        'here.'
                    : 'A trend needs readings on three separate days. Keep '
                        'going.',
              )
            else
              _WeightChart(window: window, goalKg: goal),
            const SizedBox(height: MananuSpacing.md),
            if (rate != null) ...[
              Row(
                children: [
                  Icon(
                    rate.abs() < 0.05
                        ? Icons.trending_flat
                        : rate < 0
                            ? Icons.trending_down
                            : Icons.trending_up,
                    size: 18,
                    color: MananuColors.brass,
                  ),
                  const SizedBox(width: MananuSpacing.sm),
                  Expanded(
                    child: Text(
                      describeWeeklyRate(rate),
                      style: MananuType.body.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MananuSpacing.sm),
            ],
            if (goal != null && series.isNotEmpty) ...[
              Text(
                '${(series.last.value - goal).abs().toStringAsFixed(1)} kg '
                '${series.last.value >= goal ? 'above' : 'below'} your goal of '
                '${goal.toStringAsFixed(1)} kg',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: MananuSpacing.xs),
            ],
            Row(
              children: [
                const ProvenanceBadge(
                  weighed: true,
                  label: 'Measured',
                  dense: true,
                ),
                const SizedBox(width: MananuSpacing.sm),
                Expanded(
                  child: Text(
                    'From ${sourceDisplayName(source)}. The line is the 7-day '
                    'median; the dots are each reading.',
                    style: MananuType.caption.copyWith(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 30 / 90 days. Styled by hand because Material's segmented button picks
/// up the theme's secondary colour for its selected face, and that colour is
/// [MananuColors.measured], which is reserved for provenance.
class _RangeControl extends StatelessWidget {
  const _RangeControl({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFace =
        isDark ? MananuColors.surfaceRaisedDark : MananuColors.brassSoft;
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 30, label: Text('30d')),
        ButtonSegment(value: 90, label: Text('90d')),
      ],
      selected: {days},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedFace
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurface.withValues(alpha: 0.55),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: MananuSpacing.md),
        ),
      ),
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.window, required this.goalKg});

  final List<({DateTime at, double value})> window;
  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t0 = window.first.at;
    double x(DateTime t) => t.difference(t0).inMinutes / (24 * 60);

    final raw = [for (final p in window) FlSpot(x(p.at), p.value)];
    final median = [
      for (final p in rollingMedianSeries(window)) FlSpot(x(p.at), p.value),
    ];

    var lo = window.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    var hi = window.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    // The goal has to be on the chart to mean anything.
    if (goalKg != null) {
      if (goalKg! < lo) lo = goalKg!;
      if (goalKg! > hi) hi = goalKg!;
    }
    // At least a two-kilogram band, so a flat month does not look like a
    // cliff.
    if (hi - lo < 2) {
      final mid = (hi + lo) / 2;
      lo = mid - 1;
      hi = mid + 1;
    }
    // Snap the band to whole steps of a round interval so every axis label
    // sits on a gridline.
    final yInterval = _niceStep(hi - lo);
    lo = (lo / yInterval).floorToDouble() * yInterval;
    hi = (hi / yInterval).ceilToDouble() * yInterval;
    if (hi - lo < yInterval * 2) hi += yInterval;
    final maxX = x(window.last.at);
    final muted = scheme.onSurface.withValues(alpha: 0.45);
    final dateFormat = DateFormat('d MMM');

    return SizedBox(
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
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goalKg != null)
                HorizontalLine(
                  y: goalKg!,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  strokeWidth: 1.5,
                  dashArray: const [6, 4],
                ),
            ],
          ),
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
                      fontFeatures: const [FontFeature.tabularFigures()],
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
                        t0.add(Duration(minutes: (v * 24 * 60).round())),
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
                getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Energy
// ---------------------------------------------------------------------------

/// Seven bars against a faint band at ±10% of the target, then the average,
/// how many days landed in the band, and how much of the week was weighed.
class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.week, required this.target});

  final WeeklySummary week;
  final EnergyTarget? target;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    if (week.isEmpty) {
      return const _EmptyCard(
        title: 'Nothing logged this week yet',
        message: 'Every weighed meal adds a bar here.',
      );
    }

    final goal = target?.kcal;
    final average = week.averageKcal!;
    final within = goal == null ? null : week.daysWithin(goal);
    final weighed = week.weighedFraction;
    final today = dayOf(DateTime.now());

    var maxY = week.days.map((d) => d.kcal).reduce((a, b) => a > b ? a : b);
    if (goal != null && goal * 1.1 > maxY) maxY = goal * 1.1;
    // Headroom so the tallest bar does not touch the card's top edge.
    maxY = maxY * 1.15;
    if (maxY <= 0) maxY = 100;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedNumber(
                  average,
                  format: thousands,
                  style: MananuType.display.copyWith(
                    fontSize: 34,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'kcal a day',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              ],
            ),
            Text(
              goal == null
                  ? 'Average over ${_days(week.loggedDayCount)} logged'
                  : 'Average over ${_days(week.loggedDayCount)} logged · '
                      'target ${thousands(goal)}',
              style: MananuType.caption.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.lg),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      if (goal != null)
                        HorizontalRangeAnnotation(
                          y1: goal * 0.9,
                          y2: goal * 1.1,
                          color: MananuColors.brass.withValues(alpha: 0.12),
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _dayLetters[v.toInt()],
                            style: MananuType.caption.copyWith(
                              fontSize: 11,
                              fontWeight: week.days[v.toInt()].day == today
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < 7; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: week.days[i].kcal,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            color: week.days[i].day.isAfter(today)
                                ? Colors.transparent
                                : week.days[i].isLogged
                                    ? MananuColors.brass
                                    : scheme.surfaceContainerHighest,
                            // An unlogged past day shows a stub so the gap
                            // reads as a gap and not as an empty axis.
                            fromY: 0,
                            backDrawRodData: BackgroundBarChartRodData(
                              show: !week.days[i].isLogged &&
                                  !week.days[i].day.isAfter(today),
                              toY: maxY * 0.02,
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.md),
            if (within != null)
              Text(
                '${_days(within)} within 10% of target'
                '${week.loggedDayCount < 7 ? ', of the ${week.loggedDayCount} logged' : ''}.',
                style: MananuType.body.copyWith(color: scheme.onSurface),
              ),
            const SizedBox(height: MananuSpacing.md),
            Row(
              children: [
                ProvenanceBadge(
                  weighed: weighed >= 0.6,
                  label: '${(weighed * 100).round()}% weighed',
                ),
                const SizedBox(width: MananuSpacing.sm),
                Expanded(
                  child: Text(
                    weighed >= 0.9
                        ? 'Nearly all of this week went over the scale.'
                        : weighed >= 0.5
                            ? 'The rest was estimated. Weighing it would '
                                'tighten these figures.'
                            : 'Most of this week was estimated, so the '
                                'average is too.',
                    style: MananuType.caption.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            if (target != null) ...[
              const SizedBox(height: MananuSpacing.sm),
              Text(
                target!.basis,
                style: MananuType.caption.copyWith(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _days(int n) => n == 1 ? '1 day' : '$n days';
}

// ---------------------------------------------------------------------------
// Macros
// ---------------------------------------------------------------------------

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.week, required this.target});

  final WeeklySummary week;
  final EnergyTarget? target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (week.isEmpty) {
      return const _EmptyCard(
        title: 'No macros to average yet',
        message: 'Protein, carbs and fat for the week show up with the first '
            'meal.',
      );
    }
    final weighed = week.weighedFraction;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MacroBar(
                  label: 'Protein',
                  grams: week.averageProteinG,
                  target: target?.proteinG,
                  colour: MananuColors.protein,
                ),
                _MacroBar(
                  label: 'Carbs',
                  grams: week.averageCarbG,
                  target: target?.carbG,
                  colour: MananuColors.carbs,
                ),
                _MacroBar(
                  label: 'Fat',
                  grams: week.averageFatG,
                  target: target?.fatG,
                  colour: MananuColors.fat,
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.md),
            Row(
              children: [
                ProvenanceBadge(
                  weighed: weighed >= 0.6,
                  label: weighed >= 0.95
                      ? 'Weighed'
                      : weighed >= 0.6
                          ? 'Mostly weighed'
                          : 'Estimated',
                  dense: true,
                ),
                const SizedBox(width: MananuSpacing.sm),
                Expanded(
                  child: Text(
                    'Daily averages over the '
                    '${week.loggedDayCount == 1 ? 'day' : '${week.loggedDayCount} days'} '
                    'you logged.',
                    style: MananuType.caption.copyWith(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The slim bar Today uses, one per macro.
class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.grams,
    required this.target,
    required this.colour,
  });

  final String label;
  final double? grams;
  final int? target;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = grams ?? 0;
    final progress =
        target == null || target == 0 ? 0.0 : (value / target!).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedNumber(
                value,
                style: MananuType.number.copyWith(
                  fontSize: 17,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                ' g',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: MananuSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: MananuSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colour),
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xs),
          Text(
            target == null ? label : '$label · of $target g',
            style: MananuType.caption.copyWith(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Consistency
// ---------------------------------------------------------------------------

/// Days logged this week, the streak, and twelve weeks of squares — one per
/// day, brass by how much was logged, grey for nothing. The habit is the
/// product; this is the habit made visible.
class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({
    required this.week,
    required this.consistency,
    required this.targetKcal,
  });

  final WeeklySummary week;
  final ConsistencySummary consistency;
  final int? targetKcal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final streak = consistency.currentStreak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '${week.loggedDayCount} of 7',
                    label: 'days logged this week',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: streak == 1 ? '1 day' : '$streak days',
                    label: streak == 0 ? 'no streak yet' : 'current streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.lg),
            _DayGrid(consistency: consistency, targetKcal: targetKcal),
            const SizedBox(height: MananuSpacing.md),
            Text(
              consistency.kcalByDay.isEmpty
                  ? 'Twelve weeks, one square a day. The first one is yours.'
                  : 'Twelve weeks, one square a day. Darker is closer to a '
                      'full day; grey is nothing logged.',
              style: MananuType.caption.copyWith(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: MananuType.display.copyWith(
            fontSize: 24,
            color: scheme.onSurface,
          ),
        ),
        Text(
          label,
          style: MananuType.caption.copyWith(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.consistency, required this.targetKcal});

  final ConsistencySummary consistency;
  final int? targetKcal;

  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = consistency.today;
    return LayoutBuilder(
      builder: (context, constraints) {
        final weeks = consistency.weeks;
        final cell = (constraints.maxWidth - _gap * (weeks - 1)) / weeks;
        return Column(
          children: [
            for (var weekday = 0; weekday < 7; weekday++)
              Padding(
                padding: EdgeInsets.only(bottom: weekday == 6 ? 0 : _gap),
                child: Row(
                  children: [
                    for (var w = 0; w < weeks; w++) ...[
                      if (w > 0) const SizedBox(width: _gap),
                      _square(
                        scheme,
                        consistency.dayAt(week: w, weekday: weekday),
                        today,
                        cell,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _square(
    ColorScheme scheme,
    DateTime day,
    DateTime today,
    double size,
  ) {
    final future = day.isAfter(today);
    final level = future ? 0 : consistency.level(day, targetKcal: targetKcal);
    final colour = switch (level) {
      0 =>
        future ? Colors.transparent : scheme.onSurface.withValues(alpha: 0.06),
      1 => MananuColors.brass.withValues(alpha: 0.35),
      2 => MananuColors.brass.withValues(alpha: 0.65),
      _ => MananuColors.brass,
    };
    return Semantics(
      label: '${DateFormat('EEE d MMM').format(day)}: '
          '${level == 0 ? 'nothing logged' : '${thousands(consistency.kcalOn(day))} kcal'}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(2.5),
          border: day == today
              ? Border.all(color: scheme.onSurface.withValues(alpha: 0.5))
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wearables
// ---------------------------------------------------------------------------

/// This week against the month for every wearable kind with data, each row
/// naming the device that said so. Rendered only when there is something to
/// show; a phone with no wearable never sees an empty card.
class _WearablesCard extends StatelessWidget {
  const _WearablesCard({required this.comparisons});

  final List<WearableComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '7-DAY AVERAGE · 30-DAY BASELINE',
                    style: MananuType.label.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.md),
            for (var i = 0; i < comparisons.length; i++) ...[
              if (i > 0) const Divider(height: MananuSpacing.xl),
              _WearableRow(comparison: comparisons[i]),
            ],
            const SizedBox(height: MananuSpacing.md),
            Text(
              'Averages of what your wearable reported. Mananu does not '
              'measure these itself.',
              style: MananuType.caption.copyWith(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _WearableRow extends StatelessWidget {
  const _WearableRow({required this.comparison});

  final WearableComparison comparison;

  static const _icons = <String, IconData>{
    'sleep_minutes': Icons.bedtime_outlined,
    'hrv_sdnn_ms': Icons.monitor_heart_outlined,
    'hrv_rmssd_ms': Icons.monitor_heart_outlined,
    'resting_hr_bpm': Icons.favorite_outline,
    'steps': Icons.directions_walk,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final c = comparison;
    final label = wearableKinds
        .firstWhere((k) => k.$1 == c.kind, orElse: () => (c.kind, c.kind))
        .$2;
    final delta = c.delta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _icons[c.kind] ?? Icons.sensors,
          size: 20,
          color: MananuColors.brass,
        ),
        const SizedBox(width: MananuSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: MananuType.bodyStrong),
              Text(
                'From ${c.sourceName}',
                style: MananuType.caption.copyWith(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
        // Bounded so a long caption ("down 1,234 on 9,876") wraps rather
        // than pushing the row past the card; the left column takes the rest.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 168),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                c.sevenDay == null ? '—' : format(c.kind, c.sevenDay!),
                style: MananuType.display.copyWith(
                  fontSize: 22,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                c.thirtyDay == null
                    ? 'no 30-day baseline yet'
                    : delta == null
                        ? 'baseline ${format(c.kind, c.thirtyDay!)}'
                        : '${_deltaWord(delta)} ${_formatDelta(c.kind, delta.abs())} '
                            'on ${format(c.kind, c.thirtyDay!)}',
                textAlign: TextAlign.end,
                style: MananuType.caption.copyWith(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _deltaWord(double d) => d.abs() < 1e-9
      ? 'level with'
      : d > 0
          ? 'up'
          : 'down';

  /// A difference is small, so sleep reads in minutes rather than "0h 02".
  static String _formatDelta(String kind, double v) =>
      kind == 'sleep_minutes' ? '${v.round()} min' : format(kind, v);

  /// The same formats the Body screen uses for these kinds.
  static String format(String kind, double v) => switch (kind) {
        'sleep_minutes' =>
          '${(v ~/ 60)}h ${(v % 60).round().toString().padLeft(2, '0')}',
        'hrv_sdnn_ms' || 'hrv_rmssd_ms' => '${v.round()} ms',
        'resting_hr_bpm' => '${v.round()} bpm',
        'steps' => thousands(v),
        _ => v.toStringAsFixed(0),
      };
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

/// A card with the mark and one sentence. Designed, not blank.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          children: [
            MananuMark(
              height: 22,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: MananuSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MananuType.heading,
            ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MananuType.body.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The in-card version, for a card that has a header worth keeping.
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MananuMark(
              height: 18,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: MananuSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
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
