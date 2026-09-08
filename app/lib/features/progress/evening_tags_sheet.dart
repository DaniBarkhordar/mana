/// Evening tags: four switches for today — a drink, late caffeine, feeling
/// unwell, travelling — that the "in your data" card can later set against
/// the next morning's wearable numbers.
///
/// Each tag is an observation like any other (kind `tag_*`, source `diary`,
/// value 1 or 0, unit `flag`), written through the observation repository the
/// moment the switch moves. There is no save button: a tag set at 22:00 is
/// half-asleep data entry and should cost one tap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/data/providers/insight_providers.dart';
import '../../core/insights/associations.dart';
import '../../theme/tokens.dart';

class EveningTagsSheet extends ConsumerWidget {
  const EveningTagsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const EveningTagsSheet(),
      );

  /// The label each switch wears.
  static const labels = <String, String>{
    'tag_alcohol': 'A drink this evening',
    'tag_caffeine_late': 'Caffeine after 15:00',
    'tag_illness': 'Feeling unwell',
    'tag_travel': 'Travelling today',
  };

  /// Writes the tag as an observation, on or off. Exposed so a test can call
  /// what the switch calls.
  static Future<void> setTag(
    AppServices services,
    String kind, {
    required bool on,
    DateTime? at,
  }) =>
      services.observations.record(
        kind: kind,
        value: on ? 1 : 0,
        unit: tagUnit,
        source: tagSource,
        takenAt: at ?? DateTime.now(),
        method: 'self_reported',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final set = ref.watch(todaysTagsProvider);
    final services = ref.watch(appServicesProvider).valueOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.xl,
          0,
          MananuSpacing.xl,
          MananuSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evening tags', style: MananuType.title),
            const SizedBox(height: MananuSpacing.xs),
            Text(
              'These stay on your phone and only ever compare your own days.',
              style: MananuType.caption.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.md),
            for (final tag in Behaviour.tags)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  labels[tag.tagKind] ?? tag.phrase,
                  style: MananuType.body,
                ),
                value: set.contains(tag.tagKind),
                activeTrackColor: MananuColors.brass,
                onChanged: services == null
                    ? null
                    : (on) => setTag(services, tag.tagKind!, on: on),
              ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Once a tag has eight evenings behind it, the Progress tab '
              'shows how the mornings after compared with your other days.',
              style: MananuType.caption.copyWith(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
