/// The controls for choosing a goal, shared by onboarding and the Goals
/// screen so the two never drift apart in wording or behaviour.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Three large cards, one per [GoalKind]. Null [selected] means none chosen
/// yet, which onboarding uses to hold the Continue button.
class GoalCards extends StatelessWidget {
  const GoalCards({super.key, required this.selected, required this.onChanged});

  final GoalKind? selected;
  final ValueChanged<GoalKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final goal in GoalKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: MananuSpacing.md),
            child: SelectableCard(
              selected: selected == goal,
              onTap: () => onChanged(goal),
              child: Row(
                children: [
                  _GoalGlyph(goal: goal, selected: selected == goal),
                  const SizedBox(width: MananuSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.label, style: MananuType.heading),
                        const SizedBox(height: 2),
                        Text(
                          goal.description,
                          style: MananuType.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A direction glyph: the balance mark tilted for lose and gain, level for
/// maintain. Brass when chosen.
class _GoalGlyph extends StatelessWidget {
  const _GoalGlyph({required this.goal, required this.selected});

  final GoalKind goal;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (goal) {
      GoalKind.lose => Icons.south_east,
      GoalKind.maintain => Icons.east,
      GoalKind.gain => Icons.north_east,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? MananuColors.brass : scheme.surfaceContainerHighest,
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? Colors.white : scheme.onSurface,
      ),
    );
  }
}

/// A tappable card with the brass selected state every chooser in the app
/// uses.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(MananuSpacing.lg),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: MananuSpacing.radiusMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: MananuSpacing.radiusMd,
          color: selected
              ? (isDark
                  ? MananuColors.brass.withValues(alpha: 0.16)
                  : MananuColors.brassSoft)
              : scheme.surface,
          border: Border.all(
            color: selected ? MananuColors.brass : scheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Target weight as a large display number over a slider, bounded so a
/// loss target is always below the current weight and a gain target above.
class TargetWeightControl extends StatelessWidget {
  const TargetWeightControl({
    super.key,
    required this.goal,
    required this.currentKg,
    required this.targetKg,
    required this.onChanged,
    this.onChangeEnd,
  });

  final GoalKind goal;
  final double currentKg;
  final double targetKg;
  final ValueChanged<double> onChanged;

  /// Fired when the drag ends: where a caller persists the value.
  final ValueChanged<double>? onChangeEnd;

  /// The slider's range for a goal, half-kilo steps. Forty kilos either way
  /// is further than any pace in the app reaches inside a year.
  static ({double min, double max}) rangeFor(GoalKind goal, double currentKg) {
    return switch (goal) {
      GoalKind.lose => (
          min: (currentKg - 40).clamp(35.0, currentKg - 0.5),
          max: currentKg - 0.5,
        ),
      GoalKind.gain => (
          min: currentKg + 0.5,
          max: (currentKg + 40).clamp(currentKg + 0.5, 250.0),
        ),
      GoalKind.maintain => (min: currentKg, max: currentKg),
    };
  }

  /// A sensible first target when none is chosen: five kilos in the goal's
  /// direction, or the current weight for maintenance.
  static double defaultFor(GoalKind goal, double currentKg) {
    final r = rangeFor(goal, currentKg);
    return switch (goal) {
      GoalKind.lose => (currentKg - 5).clamp(r.min, r.max),
      GoalKind.gain => (currentKg + 5).clamp(r.min, r.max),
      GoalKind.maintain => currentKg,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = rangeFor(goal, currentKg);
    final value = targetKg.clamp(r.min, r.max);
    final delta = (value - currentKg).abs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedNumber(
              value,
              decimals: 1,
              style: MananuType.display.copyWith(
                fontSize: 56,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: MananuSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'kg',
                style: MananuType.title.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        Text(
          '${delta.toStringAsFixed(1)} kg '
          '${goal == GoalKind.lose ? 'down' : 'up'} from '
          '${currentKg.toStringAsFixed(1)} kg now',
          style: MananuType.caption.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: MananuSpacing.sm),
        Slider(
          value: value,
          min: r.min,
          max: r.max,
          divisions: ((r.max - r.min) * 2).round().clamp(1, 1000),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

/// Pace in kg a week, in quarter-kilo steps, with the word for it and the
/// date it reaches the target.
class PaceControl extends StatelessWidget {
  const PaceControl({
    super.key,
    required this.goal,
    required this.paceKgPerWeek,
    required this.currentKg,
    required this.targetKg,
    required this.onChanged,
    this.onChangeEnd,
    this.dailyKcal,
  });

  final GoalKind goal;
  final double paceKgPerWeek;
  final double currentKg;
  final double? targetKg;
  final ValueChanged<double> onChanged;

  /// Fired when the drag ends: where a caller persists the value.
  final ValueChanged<double>? onChangeEnd;

  /// The deficit or surplus this pace implies, shown when known.
  final int? dailyKcal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final date = projectedDate(
      currentKg: currentKg,
      targetKg: targetKg,
      paceKgPerWeek: paceKgPerWeek,
      goal: goal,
    );
    final weeks = targetKg == null
        ? null
        : ((targetKg! - currentKg).abs() / paceKgPerWeek).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatPace(paceKgPerWeek)} kg a week — '
          '${describePace(paceKgPerWeek)}',
          style: MananuType.heading,
        ),
        const SizedBox(height: 2),
        Text(
          dailyKcal == null
              ? '${dailyAdjustmentForPace(paceKgPerWeek).round()} kcal a day '
                  '${goal == GoalKind.gain ? 'over' : 'under'} what you burn'
              : '$dailyKcal kcal a day '
                  '${goal == GoalKind.gain ? 'over' : 'under'} what you burn',
          style: MananuType.caption.copyWith(color: muted),
        ),
        const SizedBox(height: MananuSpacing.sm),
        Slider(
          value: paceKgPerWeek,
          min: minPaceKgPerWeek,
          max: maxPaceKgPerWeek,
          divisions: ((maxPaceKgPerWeek - minPaceKgPerWeek) / 0.25).round(),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        if (date != null && weeks != null)
          Container(
            padding: const EdgeInsets.all(MananuSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: MananuSpacing.radiusMd,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: MananuColors.brass,
                ),
                const SizedBox(width: MananuSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About $weeks ${weeks == 1 ? 'week' : 'weeks'}',
                        style: MananuType.bodyStrong,
                      ),
                      Text(
                        'Around ${DateFormat('d MMMM yyyy').format(date)}, '
                        'if the pace holds. It usually does not hold exactly, '
                        'and the target moves with each reading.',
                        style: MananuType.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The three macro splits as a row of chips.
class MacroSplitControl extends StatelessWidget {
  const MacroSplitControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MacroSplit selected;
  final ValueChanged<MacroSplit> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final split in MacroSplit.values) ...[
              Expanded(
                child: SelectableCard(
                  selected: selected == split,
                  onTap: () => onChanged(split),
                  padding: const EdgeInsets.symmetric(
                    vertical: MananuSpacing.md,
                    horizontal: MananuSpacing.sm,
                  ),
                  child: Text(
                    split.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MananuType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (split != MacroSplit.values.last)
                const SizedBox(width: MananuSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: MananuSpacing.sm),
        Text(
          '${selected.description} per cent of energy. '
          '${selected == MacroSplit.balanced ? 'Inside the reference ranges.' : 'A preference, not a recommendation.'}',
          style: MananuType.caption.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// The computed target, as onboarding's summary and the Goals screen show
/// it: the arc, the number, its provenance, the macros and the basis.
class TargetSummary extends StatelessWidget {
  const TargetSummary({super.key, required this.target, this.compact = false});

  final EnergyTarget target;

  /// Smaller arc for the Goals screen, where it sits above the controls.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    final maintenance = target.maintenanceKcal;
    final progress =
        maintenance == 0 ? 1.0 : (target.kcal / maintenance).clamp(0.0, 1.0);
    final adjustment = target.adjustmentKcal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ArcGauge(
            progress: progress,
            size: compact ? 168 : 208,
            strokeWidth: compact ? 10 : 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedNumber(
                  target.kcal.toDouble(),
                  format: thousands,
                  style: MananuType.display.copyWith(
                    fontSize: compact ? 40 : 48,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'kcal a day',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MananuSpacing.md),
        Center(
          child: ProvenanceBadge(
            weighed: false,
            label: 'Estimated · ${target.restingKcal} resting',
          ),
        ),
        const SizedBox(height: MananuSpacing.sm),
        Center(
          child: Text(
            adjustment == 0
                ? 'Matches what you burn, ${thousands(maintenance)} kcal'
                : '${thousands(adjustment.abs())} kcal a day '
                    '${adjustment < 0 ? 'under' : 'over'} what you burn, '
                    '${thousands(maintenance)} kcal',
            textAlign: TextAlign.center,
            style: MananuType.caption.copyWith(color: muted),
          ),
        ),
        const SizedBox(height: MananuSpacing.xl),
        Row(
          children: [
            _MacroCell(
              label: 'Protein',
              grams: target.proteinG,
              colour: MananuColors.protein,
            ),
            _MacroCell(
              label: 'Carbs',
              grams: target.carbG,
              colour: MananuColors.carbs,
            ),
            _MacroCell(
              label: 'Fat',
              grams: target.fatG,
              colour: MananuColors.fat,
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.lg),
        Text(
          target.basis,
          style: MananuType.caption.copyWith(color: muted),
        ),
        if (target.restingFloorApplied) ...[
          const SizedBox(height: MananuSpacing.md),
          Container(
            padding: const EdgeInsets.all(MananuSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: MananuSpacing.radiusSm,
            ),
            child: Text(
              'Held at your resting rate, ${thousands(target.restingKcal)} '
              'kcal. Mananu never sets a target below what your body uses '
              'lying still, so this will be slower than the pace you chose.',
              style: MananuType.caption.copyWith(color: MananuColors.warning),
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.grams,
    required this.colour,
  });

  final String label;
  final int? grams;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            grams == null ? '—' : '$grams g',
            style: MananuType.number.copyWith(
              fontSize: 17,
              color: scheme.onSurface,
            ),
          ),
          Text(
            label,
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
