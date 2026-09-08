/// The weekly review card: the week's facts as a quiet list at the top of
/// the Progress tab, the ISO week it covers, what the figures were derived
/// from, and a way into the evening tags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers/insight_providers.dart';
import '../../core/insights/weekly_review.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'evening_tags_sheet.dart';

class WeeklyReviewCard extends ConsumerWidget {
  const WeeklyReviewCard({super.key});

  /// "WEEK 37 · 7 – 13 SEP".
  static String weekLabel(WeeklyReview review) {
    final f = DateFormat('d MMM');
    final end = review.weekStart.add(const Duration(days: 6));
    return 'Week ${review.weekNumber} · ${f.format(review.weekStart)} – '
            '${f.format(end)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(weeklyReviewProvider);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return MananuSection(
      title: 'Weekly review',
      trailing: review == null
          ? null
          : Text(
              weekLabel(review),
              style: MananuType.label.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.xl),
          child: review == null || review.sentences.isEmpty
              ? Text(
                  'Nothing to review yet. A weighed meal or a morning on the '
                  'scale is where it starts.',
                  style: MananuType.body.copyWith(color: muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in review.sentences) _Line(s),
                    const SizedBox(height: MananuSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: DerivedNote(
                            review.derivedFrom.n,
                            review.derivedFrom.unit,
                          ),
                        ),
                        const _TagsButton(),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// One sentence with a brass tick mark in the margin: a list, not a chart.
class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Container(
              width: 10,
              height: 2,
              decoration: const BoxDecoration(
                color: MananuColors.brass,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
          ),
          const SizedBox(width: MananuSpacing.md),
          Expanded(
            child: Text(
              text,
              style: MananuType.body.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small outlined button — the theme's full-height outline would make the
/// tags look like the point of the card.
class _TagsButton extends StatelessWidget {
  const _TagsButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => EveningTagsSheet.show(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.md),
        visualDensity: VisualDensity.compact,
        foregroundColor: scheme.onSurface.withValues(alpha: 0.8),
        textStyle: MananuType.caption.copyWith(fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(
          borderRadius: MananuSpacing.radiusSm,
        ),
      ),
      icon: const Icon(Icons.nightlight_outlined, size: 14),
      label: const Text('Evening tags'),
    );
  }
}
