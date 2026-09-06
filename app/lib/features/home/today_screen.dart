/// Today — the screen people open five times a day.
///
/// Two numbers lead it, and the second is the one nobody else shows: how much
/// of today's intake was actually weighed. It doubles as an honesty statement
/// and as the behavioural loop — people want to raise a percentage, and the only
/// way to raise this one is to use the scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/nutrition/portion.dart';
import '../../theme/tokens.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysTotalsProvider);
    final target = ref.watch(dailyTargetProvider);
    final meals = ref.watch(todaysMealsProvider);
    final trend = ref.watch(bodyFatTrendProvider);
    final latest = ref.watch(latestBodyMeasurementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          120,
        ),
        children: [
          _EnergyCard(totals: totals, target: target),
          const SizedBox(height: MananuSpacing.lg),
          _MacroCard(totals: totals, target: target),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Meals',
            child: meals.isEmpty
                ? const _NoMealsCard()
                : Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < meals.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _MealRow(meal: meals[i]),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          if (latest != null)
            MananuSection(
              title: 'Body',
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(MananuSpacing.lg),
                  title: Text(
                    '${latest.weightKg.toStringAsFixed(1)} kg',
                    style: MananuType.title,
                  ),
                  subtitle: Text(
                    trend == null
                        ? 'Latest reading'
                        : 'Body fat trending at '
                            '${trend.toStringAsFixed(1)}%',
                    style: MananuType.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.totals, required this.target});

  final MealTotals totals;
  final DailyTarget? target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eaten = totals.kcal.round();
    final goal = target?.kcal;
    final remaining = goal == null ? null : goal - eaten;
    final progress =
        goal == null || goal == 0 ? 0.0 : (eaten / goal).clamp(0.0, 1.2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$eaten',
                  style: MananuType.display.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(width: MananuSpacing.xs),
                Text(
                  'kcal',
                  style: MananuType.body.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (remaining != null)
                  Text(
                    remaining >= 0
                        ? '$remaining left'
                        : '${remaining.abs()} over',
                    style: MananuType.bodyStrong.copyWith(
                      color: remaining >= 0
                          ? scheme.onSurface.withValues(alpha: 0.7)
                          : MananuColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MananuSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  progress > 1.0 ? MananuColors.warning : MananuColors.brass,
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.lg),

            // The number no competitor shows. It is simultaneously the honesty
            // statement, the retention loop, and the reason to keep the scale on
            // the counter.
            _WeighedMeter(fraction: totals.weighedFraction),

            if (target != null) ...[
              const SizedBox(height: MananuSpacing.md),
              Text(
                target!.basis,
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

class _WeighedMeter extends StatelessWidget {
  const _WeighedMeter({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (fraction * 100).round();
    return Row(
      children: [
        ProvenanceBadge(weighed: fraction >= 0.6, label: '$pct% weighed'),
        const SizedBox(width: MananuSpacing.md),
        Expanded(
          child: Text(
            fraction >= 0.9
                ? "Today's numbers are about as accurate as food logging gets."
                : fraction >= 0.5
                    ? 'Weighing the rest would tighten this up.'
                    : 'Weighed portions are far more accurate than estimates.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.totals, required this.target});

  final MealTotals totals;
  final DailyTarget? target;

  @override
  Widget build(BuildContext context) {
    final n = totals.nutrients;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.lg),
        child: Row(
          children: [
            _Macro(
              label: 'Protein',
              grams: n.proteinG,
              target: target?.proteinG,
              colour: MananuColors.protein,
            ),
            _Macro(
              label: 'Carbs',
              grams: n.carbG,
              target: target?.carbG,
              colour: MananuColors.carbs,
            ),
            _Macro(
              label: 'Fat',
              grams: n.fatG,
              target: target?.fatG,
              colour: MananuColors.fat,
            ),
          ],
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
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
        children: [
          Text(
            label.toUpperCase(),
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            '${value.round()} g',
            style: MananuType.number.copyWith(
              fontSize: 17,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: MananuSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colour),
              ),
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(
              'of $target g',
              style: MananuType.caption.copyWith(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final LoggedMeal meal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = meal.totals;
    final names = meal.components.map((c) => c.food.name).join(', ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.sm,
      ),
      title: Text(
        meal.slot[0].toUpperCase() + meal.slot.substring(1),
        style: MananuType.bodyStrong,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          names,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MananuType.caption.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${totals.kcal.round()} kcal', style: MananuType.number),
          const SizedBox(height: 2),
          ProvenanceBadge(
            weighed: totals.weighedFraction >= 0.6,
            label: totals.confidenceLabel,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _NoMealsCard extends StatelessWidget {
  const _NoMealsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xl),
        child: Column(
          children: [
            const Text('Nothing logged yet today', style: MananuType.heading),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Put your first ingredient on the scale and tap the button below.',
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
