/// "In your data": the associations with enough days behind them, one line
/// each, at the bottom of the Progress tab. Until one has, the card shows how
/// far the baseline has got rather than an empty box or a premature number.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers/insight_providers.dart';
import '../../core/insights/associations.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

class InYourDataCard extends ConsumerWidget {
  const InYourDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(associationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final ready = reports.where((r) => r.hasEnough).toList();

    return MananuSection(
      title: 'In your data',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ready.isEmpty)
                _Collecting(reports: reports)
              else ...[
                for (var i = 0; i < ready.length; i++) ...[
                  if (i > 0) const SizedBox(height: MananuSpacing.md),
                  _AssociationLine(ready[i]),
                ],
              ],
              const SizedBox(height: MananuSpacing.md),
              Text(
                ready.isEmpty
                    ? 'Comparisons between your own days appear here once '
                        'each side has eight of them.'
                    : 'Each line compares the mornings after those days with '
                        'the mornings after your others. A difference in '
                        'your data is not a reason for it.',
                style: MananuType.caption.copyWith(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sentence, the interval beneath it, and what it was derived from.
class _AssociationLine extends StatelessWidget {
  const _AssociationLine(this.report);

  final AssociationReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = report.stats!;
    final unit = report.outcome.unit;
    String signed(double v) => '${v < 0 ? '−' : '+'}${v.abs().round()} $unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.sentence!,
          style: MananuType.body.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: MananuSpacing.xs),
        Text(
          '80% of resamples fell between ${signed(s.intervalLow)} and '
          '${signed(s.intervalHigh)} · '
          '${DerivedNote(s.nFlagged + s.nOther, 'mornings').text}',
          style: MananuType.caption.copyWith(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// The baseline in progress for whichever behaviour is nearest to eight
/// days an arm — or, before any behaviour has been seen, the first one.
class _Collecting extends StatelessWidget {
  const _Collecting({required this.reports});

  final List<AssociationReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return CalibrationProgress(
        0,
        ArmDifference.minPerArm,
        label: Behaviour.lateMeal.noun,
      );
    }
    // The report whose short arm is furthest along.
    var best = reports.first;
    for (final r in reports) {
      if (r.calibration.count > best.calibration.count) best = r;
    }
    final c = best.calibration;
    return CalibrationProgress(c.count, c.needed, label: c.label);
  }
}
