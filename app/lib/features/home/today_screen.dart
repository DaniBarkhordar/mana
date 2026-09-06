/// Today — the screen people open five times a day.
///
/// Two numbers lead it, and the second is the one nobody else shows: how much
/// of today's intake was actually weighed. It doubles as an honesty statement
/// and as the behavioural loop — people want to raise a percentage, and the only
/// way to raise this one is to use the scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/nutrition/portion.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysTotalsProvider);
    final target = ref.watch(dailyTargetProvider);
    final meals = ref.watch(todaysMealsProvider).valueOrNull ?? const [];
    final trend = ref.watch(bodyFatTrendProvider);
    final latest = ref.watch(latestBodyMeasurementProvider);
    final weights = ref.watch(weightSeriesProvider);
    final today = ref.watch(todayProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
          children: [
            MananuHeader(
              title: 'Today',
              label: DateFormat('EEEE d MMMM').format(today),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: MananuSpacing.sm),
                  _EnergyHero(totals: totals, target: target),
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
                                  _MealRow(
                                    meal: meals[i],
                                    onDelete: () => _delete(ref, meals[i]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: MananuSpacing.xl),
                  if (latest != null)
                    MananuSection(
                      title: 'Body',
                      child: _BodyCard(
                        weightKg: latest.weightKg,
                        trend: trend,
                        weights: [
                          for (final p in weights.length > 14
                              ? weights.sublist(weights.length - 14)
                              : weights)
                            p.value,
                        ],
                        onTap: () =>
                            ref.read(shellIndexProvider.notifier).state = 1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tombstones the meal locally; the deletion syncs like any other change.
  Future<void> _delete(WidgetRef ref, LoggedMeal meal) async {
    final services = await ref.read(appServicesProvider.future);
    await services.meals.deleteMeal(meal.id);
  }
}

/// The day at a glance: the arc is energy against target, the pill is how much
/// of it was weighed, the row underneath is the macros. One card, because they
/// are one question — how is today going?
class _EnergyHero extends StatelessWidget {
  const _EnergyHero({required this.totals, required this.target});

  final MealTotals totals;
  final EnergyTarget? target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eaten = totals.kcal;
    final goal = target?.kcal;
    final remaining = goal == null ? null : goal - eaten.round();
    final progress = goal == null || goal == 0 ? 0.0 : eaten / goal;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.xl,
          MananuSpacing.xl,
          MananuSpacing.xl,
          MananuSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ArcGauge(
                  progress: progress,
                  size: 132,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedNumber(
                        eaten,
                        format: thousands,
                        style: MananuType.display.copyWith(
                          fontSize: 34,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: MananuType.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MananuSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (remaining != null) ...[
                        AnimatedNumber(
                          remaining.abs().toDouble(),
                          format: thousands,
                          style: MananuType.display.copyWith(
                            fontSize: 28,
                            color: remaining >= 0
                                ? scheme.onSurface
                                : MananuColors.warning,
                          ),
                        ),
                        Text(
                          remaining >= 0
                              ? 'left of ${thousands(goal!)}'
                              : 'over ${thousands(goal!)}',
                          style: MananuType.caption.copyWith(color: muted),
                        ),
                        const SizedBox(height: MananuSpacing.md),
                      ],
                      // The number no competitor shows. It is simultaneously
                      // the honesty statement, the retention loop, and the
                      // reason to keep the scale on the counter.
                      ProvenanceBadge(
                        weighed: totals.weighedFraction >= 0.6,
                        label: '${(totals.weighedFraction * 100).round()}% '
                            'weighed',
                      ),
                      const SizedBox(height: MananuSpacing.xs),
                      Text(
                        totals.componentCount == 0
                            ? 'Weigh it. Don\'t guess it.'
                            : totals.weighedFraction >= 0.9
                                ? 'About as accurate as logging gets.'
                                : totals.weighedFraction >= 0.5
                                    ? 'Weighing the rest would tighten this.'
                                    : 'Weighed beats estimated every time.',
                        style: MananuType.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MananuSpacing.lg),
            const Divider(),
            const SizedBox(height: MananuSpacing.md),
            Row(
              children: [
                _Macro(
                  label: 'Protein',
                  grams: totals.nutrients.proteinG,
                  target: target?.proteinG,
                  colour: MananuColors.protein,
                ),
                _Macro(
                  label: 'Carbs',
                  grams: totals.nutrients.carbG,
                  target: target?.carbG,
                  colour: MananuColors.carbs,
                ),
                _Macro(
                  label: 'Fat',
                  grams: totals.nutrients.fatG,
                  target: target?.fatG,
                  colour: MananuColors.fat,
                ),
              ],
            ),
            if (target != null) ...[
              const SizedBox(height: MananuSpacing.md),
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

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal, required this.onDelete});

  final LoggedMeal meal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = meal.totals;
    final names = meal.components.map((c) => c.food.name).join(', ');
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MananuSpacing.xl),
        color: MananuColors.danger.withValues(alpha: 0.12),
        child: const Icon(Icons.delete_outline, color: MananuColors.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MananuSpacing.lg,
          vertical: MananuSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The time column reads like a timeline down the card.
            SizedBox(
              width: 44,
              child: Text(
                DateFormat('HH:mm').format(meal.eatenAt),
                style: MananuType.number.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(meal.slot.label, style: MananuType.bodyStrong),
                      if (!meal.isSynced) ...[
                        const SizedBox(width: 6),
                        // Quietly: safe on this phone, not yet backed up.
                        Tooltip(
                          message: 'Saved on this phone, not yet backed up',
                          child: Icon(
                            Icons.cloud_off_outlined,
                            size: 14,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    names,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MananuType.caption.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MananuSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${totals.kcal.round()} kcal', style: MananuType.number),
                const SizedBox(height: 4),
                ProvenanceBadge(
                  weighed: totals.weighedFraction >= 0.6,
                  label: totals.confidenceLabel,
                  dense: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.weightKg,
    required this.trend,
    required this.weights,
    required this.onTap,
  });

  final double weightKg;
  final double? trend;
  final List<double> weights;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: MananuSpacing.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(MananuSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weightKg.toStringAsFixed(1)} kg',
                      style: MananuType.title.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trend == null
                          ? 'Latest reading'
                          : 'Body fat trending at ${trend!.toStringAsFixed(1)}%',
                      style: MananuType.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (weights.length >= 2) ...[
                Sparkline(values: weights),
                const SizedBox(width: MananuSpacing.sm),
              ],
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
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
            MananuMark(
              height: 22,
              color: scheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: MananuSpacing.lg),
            const Text('Nothing logged yet today', style: MananuType.heading),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Put your first ingredient on the scale and tap Weigh food.',
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
