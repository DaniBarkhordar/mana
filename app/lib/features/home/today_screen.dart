/// Today — the screen people open five times a day.
///
/// Two numbers lead it, and the second is the one nobody else shows: how much
/// of today's intake was actually weighed. It doubles as an honesty statement
/// and as the behavioural loop — people want to raise a percentage, and the only
/// way to raise this one is to use the scale.
///
/// Under the hero is the second glance: a streak in the header, a card of one
/// to three true sentences about the week (see insights.dart), and meal rows
/// that open in place to show what was in them and offer to log it again.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../core/nutrition/models.dart';
import '../../core/nutrition/portion.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';
import 'insights.dart';
import 'log_again.dart';
import 'streak.dart';
import 'today_providers.dart';

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
    final streak = ref.watch(todayStreakProvider);
    final insights = ref.watch(todayInsightsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
          children: [
            MananuHeader(
              title: 'Today',
              label: DateFormat('EEEE d MMMM').format(today),
              // The header drops its mark when it is given actions, so the
              // mark is passed back in after the chip to keep the corner
              // the same on every tab.
              actions: [
                if (streak >= streakChipMinimumDays) ...[
                  _StreakChip(days: streak),
                  const SizedBox(width: MananuSpacing.md),
                ],
                const Padding(
                  padding: EdgeInsets.only(right: MananuSpacing.sm),
                  child: MananuMark(height: 18),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MananuSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: MananuSpacing.sm),
                  _EnergyHero(totals: totals, target: target),
                  if (insights.isNotEmpty) ...[
                    const SizedBox(height: MananuSpacing.xl),
                    MananuSection(
                      title: 'Insights',
                      child: _InsightsCard(insights: insights),
                    ),
                  ],
                  const SizedBox(height: MananuSpacing.xl),
                  MananuSection(
                    title: 'Meals',
                    child: meals.isEmpty
                        ? const _FirstRunCard()
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (var i = 0; i < meals.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  // Keyed by meal so an open row stays open
                                  // for the same meal when the day re-sorts
                                  // around a new one.
                                  _MealRow(
                                    key: ValueKey('row-${meals[i].id}'),
                                    meal: meals[i],
                                    onDelete: () => _delete(ref, meals[i]),
                                    onLogAgain: () => _logAgain(ref, meals[i]),
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

  /// Writes the same components as a new meal now, in the slot the hour
  /// implies. See log_again.dart for what happens to their provenance.
  Future<void> _logAgain(WidgetRef ref, LoggedMeal meal) async {
    final services = await ref.read(appServicesProvider.future);
    final now = DateTime.now();
    await services.meals.logMeal(
      components: componentsForLogAgain(meal.components),
      eatenAt: now,
      slot: MealSlot.forHour(now.hour),
    );
  }
}

/// "12-day streak", small, in brass. Brass because it is the one accent the
/// app has and a streak is the one thing here worth a flourish; the
/// measured and estimated colours are never used for it.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    // Primary is brass in light and the brighter brass in dark, so the chip
    // keeps its contrast on the dark ground without a second constant.
    final brass = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: streakLabel(days),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: MananuColors.soft(context, MananuColors.brass),
            borderRadius: const BorderRadius.all(Radius.circular(999)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 14,
                color: brass,
              ),
              const SizedBox(width: 4),
              Text(
                streakLabel(days),
                style: MananuType.label.copyWith(
                  color: brass,
                  letterSpacing: 0.3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One to three sentences, each with the evidence under it. No verdicts, no
/// advice: see insights.dart for what the sentences may and may not say.
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<TodayInsight> insights;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MananuSpacing.lg,
          vertical: MananuSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < insights.length; i++) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MananuSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A brass tick mark in the margin, the way a ruler is
                    // graduated: it says "a reading", not "a warning".
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 10,
                        height: 2,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: MananuSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insights[i].text,
                            style: MananuType.body.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insights[i].provenance,
                            style: MananuType.caption.copyWith(
                              fontSize: 12,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
                        weighed: totals.weighedFraction >= weighedDayThreshold,
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

/// One meal. Collapsed, it is a line on the day's timeline; tapped, it opens
/// in place to list what was in it, split its energy by macro, and offer to
/// log the same again. Swiping left still deletes.
class _MealRow extends StatefulWidget {
  const _MealRow({
    super.key,
    required this.meal,
    required this.onDelete,
    required this.onLogAgain,
  });

  final LoggedMeal meal;
  final VoidCallback onDelete;
  final VoidCallback onLogAgain;

  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meal = widget.meal;
    final totals = meal.totals;
    final names = meal.components.map((c) => c.food.name).join(', ');
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MananuSpacing.xl),
        color: MananuColors.danger.withValues(alpha: 0.12),
        child: const Icon(Icons.delete_outline, color: MananuColors.danger),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
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
                            Flexible(
                              child: Text(
                                meal.slot.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MananuType.bodyStrong,
                              ),
                            ),
                            if (!meal.isSynced) ...[
                              const SizedBox(width: 6),
                              // Quietly: safe on this phone, not yet backed
                              // up.
                              Tooltip(
                                message:
                                    'Saved on this phone, not yet backed up',
                                child: Icon(
                                  Icons.cloud_off_outlined,
                                  size: 14,
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          names,
                          maxLines: _expanded ? 1 : 2,
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
                      Text(
                        '${totals.kcal.round()} kcal',
                        style: MananuType.number,
                      ),
                      const SizedBox(height: 4),
                      ProvenanceBadge(
                        weighed: totals.weighedFraction >= weighedDayThreshold,
                        label: totals.confidenceLabel,
                        dense: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _MealDetail(meal: meal, onLogAgain: widget.onLogAgain)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// The open meal: each component with its grams, how the grams were
/// established, and its energy; the meal's energy split by macro; and the
/// "Log again" action.
class _MealDetail extends StatelessWidget {
  const _MealDetail({required this.meal, required this.onLogAgain});

  final LoggedMeal meal;
  final VoidCallback onLogAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      // Indented to the text column, under the time column.
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.lg + 44,
        0,
        MananuSpacing.lg,
        MananuSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in meal.components) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.isCookingFat
                          ? '${c.food.name} · cooking fat'
                          : c.food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MananuType.caption.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: MananuSpacing.sm),
                  Text(
                    '${c.grams.round()} g',
                    style: MananuType.number.copyWith(
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: MananuSpacing.sm),
                  ProvenanceBadge(
                    weighed: c.method == PortionMethod.weighed,
                    label: c.method.label,
                    dense: true,
                  ),
                  const SizedBox(width: MananuSpacing.sm),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${c.nutrients.kcal.round()} kcal',
                      textAlign: TextAlign.right,
                      style: MananuType.number.copyWith(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: MananuSpacing.sm),
          _MacroKcalStrip(nutrients: meal.totals.nutrients),
          const SizedBox(height: MananuSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLogAgain,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MananuSpacing.sm,
                  ),
                  minimumSize: const Size(0, 36),
                  textStyle: MananuType.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Log again'),
              ),
              const SizedBox(width: MananuSpacing.sm),
              Expanded(
                child: Text(
                  'Same foods and grams, logged now as entered rather than '
                  'weighed. Swipe left to delete.',
                  style: MananuType.caption.copyWith(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The meal's energy split three ways, as a thin segmented bar in the macro
/// colours and a legend with the kilocalories. Protein and carbohydrate at
/// 4 kcal/g and fat at 9 — the Atwater general factors, the same ones
/// [NutrientsPer100g.atwaterKcal] uses to cross-check a database row.
class _MacroKcalStrip extends StatelessWidget {
  const _MacroKcalStrip({required this.nutrients});

  final NutrientsPer100g nutrients;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final parts = <({String label, double kcal, Color colour})>[
      (
        label: 'Protein',
        kcal: (nutrients.proteinG ?? 0) * 4,
        colour: MananuColors.protein,
      ),
      (
        label: 'Carbs',
        kcal: (nutrients.carbG ?? 0) * 4,
        colour: MananuColors.carbs,
      ),
      (label: 'Fat', kcal: (nutrients.fatG ?? 0) * 9, colour: MananuColors.fat),
    ];
    final total = parts.fold<double>(0, (a, p) => a + p.kcal);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                for (final p in parts)
                  if (p.kcal > 0)
                    Expanded(
                      // Flex is integer; a kilocalorie of resolution is far
                      // finer than the bar can draw.
                      flex: p.kcal.round().clamp(1, 1 << 20),
                      child: ColoredBox(color: p.colour),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MananuSpacing.xs),
        // A Wrap, not a Row: under the time column the strip has about
        // 280 px, and three labels with four-figure meals do not always fit
        // on one line.
        Wrap(
          spacing: MananuSpacing.md,
          runSpacing: 2,
          children: [
            for (final p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.colour,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.label} ${p.kcal.round()} kcal',
                    style: MananuType.caption.copyWith(
                      fontSize: 11,
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
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

/// The first-run card: what to do, where the button is, and the route for
/// someone whose scale has not arrived yet. The small caption keeps the
/// plain statement of state; the heading is the instruction.
class _FirstRunCard extends StatelessWidget {
  const _FirstRunCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
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
              'Nothing logged yet today',
              style: MananuType.caption.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.xs),
            Text(
              'Put the bowl on the scale',
              textAlign: TextAlign.center,
              style: MananuType.heading.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Then tap Weigh food, bottom right, and add the first '
              'ingredient. Each one is weighed on its own, so nothing is '
              'guessed.',
              textAlign: TextAlign.center,
              style: MananuType.body.copyWith(color: muted),
            ),
            const SizedBox(height: MananuSpacing.lg),
            const Divider(),
            const SizedBox(height: MananuSpacing.md),
            Text(
              'No scale yet? You can still log by searching and entering '
              'grams.',
              textAlign: TextAlign.center,
              style: MananuType.caption.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
