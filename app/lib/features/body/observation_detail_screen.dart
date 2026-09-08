/// One drill-down for every kind of observation.
///
/// A weight, a night's HRV and a ferritin result are the same shape in the
/// store — kind, value, unit, source, reference range (CLAUDE.md rule 7) —
/// so they get the same screen: the 7-day median as the headline, every raw
/// reading as a dot, the user's own usual range as a band once there are
/// enough readings to draw one, and, when a row carries a reference range,
/// that range beside the result with its publisher named (rule 8).
///
/// Nothing here branches on the kind beyond number formatting and the
/// lookup of a bioimpedance equation's published error. A stage-3 lab
/// result lands on this screen unchanged.
library;

import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/bia/body_composition.dart';
import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'observation_stats.dart';

/// The rows of one kind, newest first, optionally from one source. A single
/// stream feeds the headline, the chart and the list so they can never
/// disagree; the range control filters it in memory.
final observationRecordsProvider = StreamProvider.family<
    List<ObservationRecord>,
    ({String kind, String? source})>((ref, key) async* {
  final s = await ref.watch(appServicesProvider.future);
  final q = s.db.select(s.db.observations)
    ..where((o) => o.kind.equals(key.kind) & o.deletedAt.isNull())
    ..orderBy([(o) => OrderingTerm.desc(o.takenAt)])
    ..limit(2000);
  final source = key.source;
  if (source != null) q.where((o) => o.source.equals(source));
  yield* q.watch().map(
        (rows) => [
          for (final r in rows)
            ObservationRecord(
              id: r.id,
              at: r.takenAt.toLocal(),
              value: r.value,
              unit: r.unit,
              source: r.source,
              sourceName: _sourceNameOf(r.raw),
              method: r.method,
              referenceLow: r.referenceLow,
              referenceHigh: r.referenceHigh,
              referenceSource: r.referenceSource,
            ),
        ],
      );
});

String? _sourceNameOf(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final name = decoded['sourceName'];
      if (name is String && name.trim().isNotEmpty) return name;
    }
  } on FormatException {
    // Not JSON. The payload is kept raw on purpose; nothing to name.
  }
  return null;
}

/// The engine's own metadata for a bioimpedance kind — the equation and its
/// published standard error — read off the most recent reading that
/// predicted it. Null for any other kind, or before a prediction exists.
/// The number is never typed into this screen: it comes from the bia layer.
final biaMetricForKindProvider = Provider.family<Metric?, String>((ref, kind) {
  final key = biaMetricKeyForKind[kind];
  if (key == null) return null;
  final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
  for (final result in history.reversed) {
    final m = result.metric(key);
    if (m != null && m.derived == Derived.predicted && m.uncertainty != null) {
      return m;
    }
  }
  return null;
});

class ObservationDetailScreen extends ConsumerStatefulWidget {
  const ObservationDetailScreen({super.key, required this.kind, this.source});

  final String kind;

  /// Restrict to one source, e.g. only what Apple Health said.
  final String? source;

  /// The range chips, in days; zero is everything.
  static const ranges = <(int, String)>[
    (7, '7d'),
    (30, '30d'),
    (90, '90d'),
    (365, '1y'),
    (0, 'All'),
  ];

  @override
  ConsumerState<ObservationDetailScreen> createState() =>
      _ObservationDetailScreenState();
}

class _ObservationDetailScreenState
    extends ConsumerState<ObservationDetailScreen> {
  int _days = 30;
  String? _selectedId;

  /// Rows swiped away but not yet gone from the stream. A Dismissible must
  /// leave the tree in the same frame it is dismissed, and the database
  /// answers a frame later.
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(
      observationRecordsProvider((kind: widget.kind, source: widget.source)),
    );
    final label = kindLabel(widget.kind);
    return Scaffold(
      appBar: AppBar(),
      body: rowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MananuSpacing.xl),
            child: Text('Could not read these readings: $e'),
          ),
        ),
        data: (all) {
          final rows = [
            for (final r in all)
              if (!_hidden.contains(r.id)) r,
          ];
          final now = DateTime.now();
          if (rows.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              children: [
                MananuHeader(title: label),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MananuSpacing.lg,
                  ),
                  child: _EmptyCard(
                    title: 'Nothing recorded yet',
                    message: 'Readings of ${label.toLowerCase()} appear here '
                        'as soon as a source reports one.',
                  ),
                ),
              ],
            );
          }

          final latest = rows.first;
          final unit = latest.unit;
          final window = windowOf(rows, _days, asOf: now);
          final windowValues = [for (final r in window) r.value];
          final headline = headlineWindow(rows, asOf: now);
          final median7 = headline.isEmpty
              ? null
              : median([for (final r in headline) r.value]);
          final band = usualRange(windowValues);
          final bia = ref.watch(biaMetricForKindProvider(widget.kind));
          final withReference = rows.where((r) => r.hasReference).firstOrNull;
          final ReferenceRange? reference = withReference == null
              ? null
              : (
                  low: withReference.referenceLow,
                  high: withReference.referenceHigh,
                  source: withReference.referenceSource ?? 'the source',
                );
          final selected = window.where((r) => r.id == _selectedId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            children: [
              MananuHeader(
                title: label,
                label: 'Last reading '
                    '${DateFormat('EEE d MMM, HH:mm').format(latest.at)}',
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: MananuSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: MananuSpacing.sm),
                    _HeadlineCard(
                      label: label,
                      unit: unit,
                      median7: median7,
                      derivedFrom: headline.length,
                      latest: latest,
                      position: positionIn(latest.value, band),
                    ),
                    const SizedBox(height: MananuSpacing.xl),
                    MananuSection(
                      title: 'Trend',
                      child: _TrendCard(
                        label: label,
                        unit: unit,
                        days: _days,
                        onDaysChanged: (d) => setState(() {
                          _days = d;
                          _selectedId = null;
                        }),
                        window: window,
                        band: band,
                        bia: bia,
                        reference: reference,
                        selected: selected,
                        onSelect: (id) => setState(() => _selectedId = id),
                      ),
                    ),
                    const SizedBox(height: MananuSpacing.xl),
                    MananuSection(
                      title: 'How this is worked out',
                      child: _MethodCard(
                        label: label,
                        unit: unit,
                        derivedFrom: headline.length,
                        windowCount: window.length,
                        bia: bia,
                        reference: reference,
                        source: latest.source,
                      ),
                    ),
                    const SizedBox(height: MananuSpacing.xl),
                    MananuSection(
                      title: 'Readings',
                      trailing: Text(
                        '${window.length} in view'.toUpperCase(),
                        style: MananuType.label.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: _ReadingsCard(
                        label: label,
                        window: window,
                        onDelete: _delete,
                      ),
                    ),
                    const SizedBox(height: MananuSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: _export,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Export this kind'),
                    ),
                    const SizedBox(height: MananuSpacing.sm),
                    Text(
                      'A CSV of every ${label.toLowerCase()} reading, with '
                      'its source and any reference range.',
                      textAlign: TextAlign.center,
                      style: MananuType.caption.copyWith(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(ObservationRecord r) async {
    setState(() {
      _hidden.add(r.id);
      if (_selectedId == r.id) _selectedId = null;
    });
    final s = await ref.read(appServicesProvider.future);
    await s.observations.delete(r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Removed ${formatValue(r.value, r.unit)} ${unitLabel(r.unit)} '
                    'from ${DateFormat('d MMM').format(r.at)}'
                .trim(),
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await s.observations.restore(r.id);
              if (mounted) setState(() => _hidden.remove(r.id));
            },
          ),
        ),
      );
  }

  /// One kind as RFC 4180 CSV, handed to the share sheet. The person's
  /// choice where it goes — Files, mail, AirDrop — never ours.
  Future<void> _export() async {
    final exporter = await ref.read(dataExporterProvider.future);
    final csv = await exporter.exportKind(widget.kind);
    final name = '${widget.kind}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(csv),
            mimeType: 'text/csv',
            name: name,
          ),
        ],
        fileNameOverrides: [name],
        subject: 'Mananu · ${kindLabel(widget.kind)}',
        text: 'Every ${kindLabel(widget.kind).toLowerCase()} reading, as CSV.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Headline
// ---------------------------------------------------------------------------

/// The 7-day median, large, with what it was derived from and where the
/// latest reading sits against the usual range — in words, never a colour.
/// The raw latest sits underneath with the device that said so.
class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.label,
    required this.unit,
    required this.median7,
    required this.derivedFrom,
    required this.latest,
    required this.position,
  });

  final String label;
  final String unit;
  final double? median7;
  final int derivedFrom;
  final ObservationRecord latest;
  final UsualRangePosition position;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final headlineValue = median7 ?? latest.value;
    final unitWord = unitLabel(unit);
    final state = switch (position) {
      UsualRangePosition.within => RangeState.within,
      UsualRangePosition.above => RangeState.above,
      UsualRangePosition.below => RangeState.below,
      UsualRangePosition.calibrating => RangeState.calibrating,
    };
    final latestValue =
        'Latest ${formatValue(latest.value, unit)} $unitWord'.trimRight();
    final latestLine =
        '$latestValue · ${DateFormat('EEE d MMM, HH:mm').format(latest.at)}';

    return Semantics(
      container: true,
      label: median7 == null
          ? '$label, latest reading ${formatValue(latest.value, unit)} '
              '$unitWord, ${state.words}'
          : '$label, 7-day median ${formatValue(median7!, unit)} $unitWord, '
              'derived from $derivedFrom readings, ${state.words}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                median7 == null ? 'LATEST READING' : '7-DAY MEDIAN',
                style: MananuType.label
                    .copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: MananuSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatValue(headlineValue, unit),
                    style: MananuType.display.copyWith(color: scheme.onSurface),
                  ),
                  if (unitWord.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unitWord,
                      style: MananuType.title.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
              if (median7 != null)
                DerivedNote(
                  derivedFrom,
                  derivedFrom == 1 ? 'reading' : 'readings',
                )
              else
                Text(
                  'No readings in the last 7 days to take a median of.',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              const SizedBox(height: MananuSpacing.md),
              Align(alignment: Alignment.centerLeft, child: RangeMarker(state)),
              const SizedBox(height: MananuSpacing.md),
              Wrap(
                spacing: MananuSpacing.sm,
                runSpacing: MananuSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    latestLine,
                    style: MananuType.caption.copyWith(color: muted),
                  ),
                  SourceBadge(latest.source, sourceName: latest.sourceName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend
// ---------------------------------------------------------------------------

/// The chart: the 7-day median as a brass line, every raw reading as a
/// tappable dot, the usual range washed in behind, an equation's error band
/// in brass for bioimpedance kinds, and a reference range with its
/// publisher named when the rows carry one.
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.unit,
    required this.days,
    required this.onDaysChanged,
    required this.window,
    required this.band,
    required this.bia,
    required this.reference,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final String unit;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final List<ObservationRecord> window;
  final Band? band;
  final Metric? bia;
  final ReferenceRange? reference;
  final ObservationRecord? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final enough = window.length >= 2 &&
        window.last.at.difference(window.first.at).inHours >= 24;
    final rangeWord = days == 0 ? 'all time' : '$days days';

    return Semantics(
      container: true,
      label: '$label trend over $rangeWord, ${window.length} readings',
      child: Card(
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
              Text(
                '${label.toUpperCase()} · ${rangeWord.toUpperCase()}',
                style: MananuType.label.copyWith(color: muted),
              ),
              const SizedBox(height: MananuSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: _RangeControl(days: days, onChanged: onDaysChanged),
              ),
              const SizedBox(height: MananuSpacing.md),
              if (!enough)
                _InlineEmpty(
                  message: window.isEmpty
                      ? 'No readings in this window. Try a longer one.'
                      : 'Readings on two different days make a line.',
                )
              else
                _ObservationChart(
                  window: window,
                  unit: unit,
                  band: band,
                  bia: bia,
                  reference: reference,
                  selectedId: selected?.id,
                  onSelect: onSelect,
                ),
              if (selected != null) ...[
                const SizedBox(height: MananuSpacing.sm),
                _PointPopover(
                  record: selected!,
                  onClose: () => onSelect(null),
                ),
              ],
              const SizedBox(height: MananuSpacing.md),
              if (band == null)
                CalibrationProgress(
                  window.length,
                  usualRangeMinimum,
                  label: 'readings for a usual range',
                )
              else
                _Legend(
                  swatch: scheme.surfaceContainerHighest,
                  text: 'Your usual range: the middle 80% of these '
                          '${window.length} readings, '
                          '${formatValue(band!.lo, unit)}–'
                          '${formatValue(band!.hi, unit)} ${unitLabel(unit)}'
                      .trimRight(),
                ),
              if (bia?.uncertainty != null) ...[
                const SizedBox(height: MananuSpacing.sm),
                _Legend(
                  swatch: MananuColors.brass.withValues(alpha: 0.12),
                  text: 'Equation error: '
                      '${formatUncertainty(bia!.uncertainty!, unit)} either '
                      'side of the median, from '
                      '${bia!.equation?.citation ?? 'the published equation'}.',
                ),
              ],
              if (reference != null) ...[
                const SizedBox(height: MananuSpacing.sm),
                Wrap(
                  spacing: MananuSpacing.sm,
                  runSpacing: MananuSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Legend(
                      swatch: scheme.onSurface.withValues(alpha: 0.06),
                      text: 'Reference range '
                          '${formatReference(reference!, unit)}',
                    ),
                    _SourcePill(reference!.source),
                  ],
                ),
              ],
              const SizedBox(height: MananuSpacing.sm),
              Text(
                'The line is the 7-day median. Each dot is one reading — '
                'tap one to see it.',
                style: MananuType.caption.copyWith(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chart proper. `lineBarsData[0]` is always the raw readings, one spot
/// per row in the window, so a test can count them.
class _ObservationChart extends StatelessWidget {
  const _ObservationChart({
    required this.window,
    required this.unit,
    required this.band,
    required this.bia,
    required this.reference,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ObservationRecord> window;
  final String unit;
  final Band? band;
  final Metric? bia;
  final ReferenceRange? reference;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t0 = window.first.at;
    double x(DateTime t) => t.difference(t0).inMinutes / (24 * 60);

    final raw = [for (final r in window) FlSpot(x(r.at), r.value)];
    final medianLine = rollingMedianSeries(window);
    final medianSpots = [
      for (final p in medianLine) FlSpot(x(p.at), p.value),
    ];
    final se = bia?.uncertainty;
    final upper = se == null
        ? const <FlSpot>[]
        : [for (final p in medianLine) FlSpot(x(p.at), p.value + se)];
    final lower = se == null
        ? const <FlSpot>[]
        : [for (final p in medianLine) FlSpot(x(p.at), p.value - se)];

    final axis = axisRange(
      [for (final r in window) r.value],
      includes: [
        if (band != null) ...[band!.lo, band!.hi],
        if (reference?.low != null) reference!.low!,
        if (reference?.high != null) reference!.high!,
        for (final s in upper) s.y,
        for (final s in lower) s.y,
      ],
      minSpan: minSpanFor(unit),
      unit: unit,
    );
    final maxX = x(window.last.at);
    final muted = scheme.onSurface.withValues(alpha: 0.45);
    final dateFormat = DateFormat('d MMM');
    final refLow = reference?.low;
    final refHigh = reference?.high;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX <= 0 ? 1 : maxX,
          minY: axis.lo,
          maxY: axis.hi,
          clipData: const FlClipData.none(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: axis.step,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outline, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              if (band != null)
                HorizontalRangeAnnotation(
                  y1: band!.lo,
                  y2: band!.hi,
                  color: scheme.surfaceContainerHighest,
                ),
              if (refLow != null && refHigh != null)
                HorizontalRangeAnnotation(
                  y1: refLow,
                  y2: refHigh,
                  color: scheme.onSurface.withValues(alpha: 0.06),
                ),
            ],
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              for (final y in [refLow, refHigh])
                if (y != null)
                  HorizontalLine(
                    y: y,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    strokeWidth: 1.5,
                    dashArray: const [6, 4],
                  ),
            ],
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: false,
            touchSpotThreshold: 24,
            touchCallback: (event, response) {
              if (event is! FlTapUpEvent) return;
              final hit = response?.lineBarSpots
                  ?.where((s) => s.barIndex == 0)
                  .firstOrNull;
              onSelect(hit == null ? null : window[hit.spotIndex].id);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: unit == 'min' ? 52 : 44,
                interval: axis.step,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    formatAxis(v, axis.step, unit),
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
          betweenBarsData: [
            if (se != null)
              BetweenBarsData(
                fromIndex: 2,
                toIndex: 3,
                color: MananuColors.brass.withValues(alpha: 0.12),
              ),
          ],
          lineBarsData: [
            // 0: every raw reading. The selected one wears a brass ring.
            LineChartBarData(
              spots: raw,
              barWidth: 0,
              color: Colors.transparent,
              dotData: FlDotData(
                getDotPainter: (spot, pct, bar, i) => window[i].id == selectedId
                    ? FlDotCirclePainter(
                        radius: 4.5,
                        color: scheme.surface,
                        strokeWidth: 2,
                        strokeColor: MananuColors.brass,
                      )
                    : FlDotCirclePainter(
                        radius: 2.6,
                        color: MananuColors.mist.withValues(alpha: 0.45),
                        strokeWidth: 0,
                      ),
              ),
            ),
            // 1: the 7-day median.
            LineChartBarData(
              spots: medianSpots,
              barWidth: 2.5,
              color: MananuColors.brass,
              dotData: const FlDotData(show: false),
            ),
            // 2 and 3: the equation's error either side of the median,
            // invisible lines whose gap is filled above.
            if (se != null) ...[
              LineChartBarData(
                spots: upper,
                barWidth: 0,
                color: Colors.transparent,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: lower,
                barWidth: 0,
                color: Colors.transparent,
                dotData: const FlDotData(show: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The tapped reading: date, value, and the device that said so.
class _PointPopover extends StatelessWidget {
  const _PointPopover({required this.record, required this.onClose});

  final ObservationRecord record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value =
        '${formatValue(record.value, record.unit)} ${unitLabel(record.unit)}'
            .trimRight();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.md,
        MananuSpacing.sm,
        MananuSpacing.xs,
        MananuSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: MananuSpacing.radiusSm,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: MananuSpacing.sm,
              runSpacing: MananuSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: MananuType.number.copyWith(color: scheme.onSurface),
                ),
                Text(
                  DateFormat('EEE d MMM, HH:mm').format(record.at),
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SourceBadge(record.source, sourceName: record.sourceName),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// A swatch and a sentence: what a band on the chart is.
class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.text});

  final Color swatch;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: scheme.outline),
            ),
          ),
        ),
        const SizedBox(width: MananuSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }
}

/// Who published a reference range, as an outlined pill beside it. Never a
/// colour: the range is context, not a verdict.
class _SourcePill extends StatelessWidget {
  const _SourcePill(this.source);

  final String source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        source,
        style: MananuType.label.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// 7d / 30d / 90d / 1y / All. Styled by hand, as the Progress tab's is,
/// because Material's segmented button paints its selected face in the
/// theme's secondary colour — [MananuColors.measured], which is reserved for
/// provenance.
class _RangeControl extends StatelessWidget {
  const _RangeControl({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFace = MananuColors.soft(context, MananuColors.brass);
    return SegmentedButton<int>(
      segments: [
        for (final (d, text) in ObservationDetailScreen.ranges)
          ButtonSegment(value: d, label: Text(text)),
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
          EdgeInsets.symmetric(horizontal: MananuSpacing.sm),
        ),
      ),
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ---------------------------------------------------------------------------
// Method
// ---------------------------------------------------------------------------

/// Says, in words, where every number on the screen came from: the equation
/// and its published error for a bioimpedance kind, the median rule for
/// everything else, the usual-range rule, and who published a reference
/// range. Every derived statistic says what it is derived from.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.label,
    required this.unit,
    required this.derivedFrom,
    required this.windowCount,
    required this.bia,
    required this.reference,
    required this.source,
  });

  final String label;
  final String unit;
  final int derivedFrom;
  final int windowCount;
  final Metric? bia;
  final ReferenceRange? reference;
  final String source;

  static const _stores = {'apple_health', 'health_connect'};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paragraphs = <String>[];
    final se = bia?.uncertainty;
    final equation = bia?.equation;
    if (se != null && equation != null) {
      paragraphs.add(
        'Predicted with ${equation.citation}. That equation\'s published '
        'standard error is ${formatUncertainty(se, unit)}, so the brass band '
        'on the chart runs that far either side of the median. The band is a '
        'property of the equation, not of any one reading.',
      );
    }
    paragraphs.add(
      derivedFrom == 0
          ? 'The headline is normally the median of your readings from the '
              'last 7 days. There are none in that window at the moment, so '
              'the latest reading is shown instead.'
          : 'The headline is the median of your readings from the last 7 '
              'days — $derivedFrom ${derivedFrom == 1 ? 'reading' : 'readings'} '
              'at the moment. A median rather than an average, so one odd '
              'reading cannot drag it.',
    );
    paragraphs.add(
      windowCount >= usualRangeMinimum
          ? 'Your usual range is the middle 80% of your last $windowCount '
              'readings: from the 10th to the 90th percentile of the readings '
              'in the window you have chosen. It is your own baseline, not a '
              'population figure.'
          : 'Your usual range will be the middle 80% of the readings in the '
              'window you have chosen — the 10th to the 90th percentile. It '
              'appears once there are $usualRangeMinimum of them; there are '
              '$windowCount so far.',
    );
    if (reference != null) {
      paragraphs.add(
        'The reference range ${formatReference(reference!, unit)} is '
        'published by ${reference!.source}. It is shown beside the result '
        'for context. Mananu does not interpret it; that is a conversation '
        'for you and your clinician.',
      );
    }
    if (_stores.contains(source)) {
      paragraphs.add(
        'These readings are what ${sourceLabel(source)} reported. Mananu '
        'does not measure this itself.',
      );
    }

    return Semantics(
      container: true,
      label: 'How $label is worked out',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < paragraphs.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == paragraphs.length - 1 ? 0 : MananuSpacing.md,
                  ),
                  child: Text(
                    paragraphs[i],
                    style: MananuType.body.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Readings
// ---------------------------------------------------------------------------

/// Every reading in the window, newest first: value, source, date. Swipe
/// left to remove; the snackbar's Undo puts it back.
class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({
    required this.label,
    required this.window,
    required this.onDelete,
  });

  final String label;
  final List<ObservationRecord> window;
  final ValueChanged<ObservationRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final newestFirst = window.reversed.toList();
    return Semantics(
      container: true,
      label: '${window.length} $label readings, newest first',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: newestFirst.isEmpty
            ? const _InlineEmpty(message: 'No readings in this window.')
            : Column(
                children: [
                  for (var i = 0; i < newestFirst.length; i++) ...[
                    if (i > 0) const Divider(),
                    _ReadingRow(
                      record: newestFirst[i],
                      onDelete: () => onDelete(newestFirst[i]),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.record, required this.onDelete});

  final ObservationRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value =
        '${formatValue(record.value, record.unit)} ${unitLabel(record.unit)}'
            .trimRight();
    return Dismissible(
      key: ValueKey('obs-row-${record.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      // The quiet surface, not a red one: removing a reading is housekeeping,
      // and the warning colours are kept for things that have gone wrong.
      background: Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MananuSpacing.xl),
        child: Icon(
          Icons.delete_outline,
          color: scheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      child: Semantics(
        label: '$value, ${DateFormat('EEE d MMM, HH:mm').format(record.at)}, '
            'from ${sourceLabel(record.source)}. Swipe left to remove.',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MananuSpacing.lg,
            vertical: MananuSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style:
                          MananuType.number.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE d MMM, HH:mm').format(record.at),
                      style: MananuType.caption.copyWith(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MananuSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: SourceBadge(
                  record.source,
                  sourceName: record.sourceName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MananuType.heading.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: MananuSpacing.sm),
              Text(
                message,
                style: MananuType.body.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.lg,
      ),
      child: Text(
        message,
        style: MananuType.body.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
