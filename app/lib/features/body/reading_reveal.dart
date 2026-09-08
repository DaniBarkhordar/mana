/// The reading moment.
///
/// Stepping on the scale is the one ritual the product owns, and the ten
/// seconds after it are when the number is looked at. So the settled weight
/// rolls in, then — with consent, and once the engine has run — body fat
/// with its published ± and its provenance badge, and one line saying how
/// today sits against the person's own 7-day median. No score, no verdict:
/// the comparison is the whole message (CLAUDE.md rules 4 and 5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/bia/body_composition.dart';
import '../../core/data/providers.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Within this band a difference from the median is called normal
/// day-to-day movement. Body water alone moves a kilogram between mornings;
/// published test-retest for a bathroom scale is well inside it.
const double normalDailyMovementKg = 1.0;

/// How far apart a sample's timestamp and its stored reading may be and
/// still be the same measurement. SQLite keeps whole seconds.
const Duration _sameReadingTolerance = Duration(seconds: 2);

/// The one line under the weight. Kept as a function so the wording is
/// testable without a scale: [priorMedianKg] is the 7-day median of the
/// readings before this one, null when this is the first.
String describeAgainstMedian(double kg, double? priorMedianKg) {
  if (priorMedianKg == null) {
    return 'Your first reading. The trend starts here.';
  }
  final delta = kg - priorMedianKg;
  if (delta.abs() < 0.05) return 'Level with your 7-day median.';
  final word = delta > 0 ? 'above' : 'below';
  final size = '${delta.abs().toStringAsFixed(1)} kg $word your median';
  if (delta.abs() <= normalDailyMovementKg) {
    return '$size — normal day-to-day movement.';
  }
  return '$size — more than a day usually moves. The median will tell.';
}

/// A bottom sheet for one settled body-scale sample.
class ReadingRevealSheet extends ConsumerStatefulWidget {
  const ReadingRevealSheet({super.key, required this.sample});

  final WeightSample sample;

  static Future<void> show(BuildContext context, WeightSample sample) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ReadingRevealSheet(sample: sample),
    );
  }

  @override
  ConsumerState<ReadingRevealSheet> createState() => _ReadingRevealSheetState();
}

class _ReadingRevealSheetState extends ConsumerState<ReadingRevealSheet> {
  /// False for the first frame so the weight rolls in rather than appearing.
  bool _landed = false;

  /// True once the weight has had its half-second; the composition follows.
  bool _showComposition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _landed = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showComposition = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final sample = widget.sample;
    final driver = ref.watch(bodyScaleDriverProvider);
    final source = observationSourceFor(driver, ScaleKind.body);

    // The stored reading for this sample, once the recorder has run the
    // engine. Matched on time, newest first: one measurement, one row.
    final history = ref.watch(bodyHistoryProvider).valueOrNull ?? const [];
    BodyCompositionResult? stored;
    for (final r in history.reversed) {
      if (r.takenAt.difference(sample.at).abs() <= _sameReadingTolerance) {
        stored = r;
        break;
      }
    }

    // The median of what came before, so today is compared with history it
    // is not yet part of.
    final series = ref.watch(weightSeriesProvider);
    final prior = [
      for (final p in series)
        if (p.at.difference(sample.at).abs() > _sameReadingTolerance) p,
    ];
    final priorMedian =
        const TrendSmoother().rollingMedian(prior, asOf: sample.at);

    // Real hardware settles from above, and so does the demo: the last few
    // hundred grams roll down onto the figure.
    final weightShown = _landed ? sample.kg : sample.kg + 0.8;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'NEW READING · ${DateFormat('HH:mm').format(sample.at)}',
                  style: MananuType.label.copyWith(color: muted),
                ),
              ),
              SourceBadge(source),
            ],
          ),
          const SizedBox(height: MananuSpacing.lg),
          Semantics(
            label: 'Weight ${sample.kg.toStringAsFixed(1)} kilograms, weighed',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Shrinks rather than overflowing under large
                  // accessibility text; the badge keeps its size.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedNumber(
                            weightShown,
                            decimals: 1,
                            style: MananuType.readout.copyWith(
                              fontSize: 64,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: MananuSpacing.sm),
                          Text(
                            'kg',
                            style: MananuType.title.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MananuSpacing.md),
                  const Padding(
                    padding: EdgeInsets.only(bottom: MananuSpacing.sm),
                    child: ProvenanceBadge(weighed: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.md),
          Text(
            describeAgainstMedian(sample.kg, priorMedian),
            style: MananuType.body.copyWith(color: scheme.onSurface),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showComposition && stored != null
                ? _Composition(result: stored)
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: MananuSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Body fat with its ± and where it came from; or, without an impedance,
/// a plain statement that this one was weight only.
class _Composition extends StatefulWidget {
  const _Composition({required this.result});

  final BodyCompositionResult result;

  @override
  State<_Composition> createState() => _CompositionState();
}

class _CompositionState extends State<_Composition> {
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _landed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final fat = widget.result.metric('bodyFatPercent');

    if (fat == null || fat.derived != Derived.predicted) {
      return Padding(
        padding: const EdgeInsets.only(top: MananuSpacing.lg),
        child: Text(
          'Weight only this time. Body fat needs an impedance reading and '
          'your consent to work it out.',
          style: MananuType.caption.copyWith(color: muted),
        ),
      );
    }

    final uncertainty = fat.uncertainty;
    final citation = fat.equation?.citation;
    return Padding(
      padding: const EdgeInsets.only(top: MananuSpacing.xl),
      child: Semantics(
        label: 'Body fat ${fat.value.toStringAsFixed(1)} per cent'
            '${uncertainty == null ? '' : ', plus or minus ${uncertainty.toStringAsFixed(1)} points'}'
            ', estimated',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BODY FAT',
                style: MananuType.label.copyWith(color: muted),
              ),
              const SizedBox(height: MananuSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedNumber(
                            _landed ? fat.value : 0,
                            decimals: 1,
                            style: MananuType.display
                                .copyWith(color: scheme.onSurface),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '%',
                            style: MananuType.title.copyWith(color: muted),
                          ),
                          if (uncertainty != null) ...[
                            const SizedBox(width: MananuSpacing.md),
                            Text(
                              '± ${uncertainty.toStringAsFixed(1)} pts',
                              style: MananuType.caption.copyWith(color: muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: MananuSpacing.md),
                  const ProvenanceBadge(weighed: false),
                ],
              ),
              const SizedBox(height: MananuSpacing.sm),
              Text(
                citation == null
                    ? 'Worked out from your impedance on this phone.'
                    : 'Predicted with $citation from your impedance. The ± '
                        'is that equation\'s published standard error. Watch '
                        'the 7-day median, not this figure.',
                style: MananuType.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
