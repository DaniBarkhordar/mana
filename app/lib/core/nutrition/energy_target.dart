/// The daily energy and macro target, and the goal that shapes it.
///
/// The resting rate comes from a published equation (Cunningham 1980 from
/// fat-free mass when there is a reading, Mifflin-St Jeor 1990 otherwise —
/// see `core/bia/equations.dart`) and the activity band from the NASEM 2023
/// DRI for energy. What this file adds is the goal on top: a deficit or
/// surplus sized from the pace the user chose, and a macro split.
///
/// Two things here are deliberate limits rather than defaults:
///
///   * The target never drops below the resting rate. A deficit that takes
///     intake under what the body spends lying still is not a plan the app
///     should write down, whatever pace was asked for. When the clamp bites,
///     [EnergyTarget.restingFloorApplied] is set and the UI says so.
///   * Protein has a floor of 1.6 g per kg of body weight when the goal is
///     to lose weight or the split is high-protein. That is the intake at
///     which the dose–response for lean-mass retention plateaus in the
///     Morton et al. 2018 meta-analysis (Br J Sports Med 52:376–384).
library;

import 'dart:math' as math;

import '../bia/equations.dart';

/// What the user is trying to do with their weight.
enum GoalKind {
  lose('Lose weight', 'A steady deficit, never below your resting rate.'),
  maintain('Stay where I am', 'Eat what you burn. Hold the line.'),
  gain('Gain weight', 'A modest surplus, sized to the pace you choose.');

  const GoalKind(this.label, this.description);

  final String label;
  final String description;
}

/// How the energy is divided between protein, carbohydrate and fat.
///
/// Shares are of total energy. Balanced sits inside the Acceptable
/// Macronutrient Distribution Ranges (IOM 2005: protein 10–35 %, fat 20–35 %,
/// carbohydrate 45–65 %). The other two are preferences, not recommendations,
/// and are labelled as such in the UI.
enum MacroSplit {
  balanced('Balanced', 0.25, 0.45, 0.30, 'Protein 25 · carbs 45 · fat 30'),
  highProtein(
    'High protein',
    0.35,
    0.35,
    0.30,
    'Protein 35 · carbs 35 · fat 30',
  ),
  lowCarb('Lower carb', 0.30, 0.25, 0.45, 'Protein 30 · carbs 25 · fat 45');

  const MacroSplit(
    this.label,
    this.proteinShare,
    this.carbShare,
    this.fatShare,
    this.description,
  );

  final String label;
  final double proteinShare;
  final double carbShare;
  final double fatShare;
  final String description;
}

/// The conventional energy content of a kilogram of body-weight change.
///
/// Wishnofsky 1958 (Am J Clin Nutr 6:542–546): 3,500 kcal per pound, so
/// 7,700 kcal per kilogram. Hall 2008 (Int J Obes 32:573–576) shows it
/// overstates the long-run loss because the body adapts, which is one reason
/// the target is recomputed from the latest reading rather than fixed at
/// onboarding. It remains the standard planning figure.
const double kcalPerKgBodyWeight = 7700;

/// The slowest and fastest paces the app will plan for, in kg a week. Below
/// a quarter kilo the change is inside the scale's day-to-day noise; above a
/// kilo the deficit is almost always clamped by the resting floor anyway.
const double minPaceKgPerWeek = 0.25;
const double maxPaceKgPerWeek = 1.0;

/// Protein floor, grams per kilogram of body weight, for a loss or a
/// high-protein split. Morton et al. 2018.
const double proteinFloorGPerKg = 1.6;

/// The energy adjustment a pace implies, in kcal a day. 0.5 kg a week is
/// 0.5 × 7,700 / 7 = 550 kcal a day.
double dailyAdjustmentForPace(double paceKgPerWeek) =>
    paceKgPerWeek * kcalPerKgBodyWeight / 7;

/// Today's target: energy, macros, and where every number came from.
class EnergyTarget {
  const EnergyTarget({
    required this.kcal,
    required this.basis,
    required this.restingKcal,
    required this.maintenanceKcal,
    required this.goal,
    required this.split,
    this.proteinG,
    this.fatG,
    this.carbG,
    this.restingFloorApplied = false,
  });

  final int kcal;

  /// Names the equation and the goal, in plain language, for the footer of
  /// the Today card and the onboarding summary.
  final String basis;

  /// The resting rate the target is built on, before activity.
  final int restingKcal;

  /// Resting × activity: what the target would be with no goal applied.
  final int maintenanceKcal;

  final GoalKind goal;
  final MacroSplit split;
  final int? proteinG;
  final int? fatG;
  final int? carbG;

  /// True when the asked-for deficit would have taken the target under the
  /// resting rate and it was held there instead.
  final bool restingFloorApplied;

  /// The deficit (negative) or surplus (positive) actually applied, after
  /// the floor. Zero for maintenance.
  int get adjustmentKcal => kcal - maintenanceKcal;
}

/// Builds the target from a resting-rate prediction and the profile's goal.
///
/// [weightKg] is the current weight the protein floor is sized from; the
/// caller passes the latest reading, or the self-reported weight before
/// there is one.
EnergyTarget computeEnergyTarget({
  required Prediction resting,
  required ActivityLevel activity,
  required double weightKg,
  GoalKind goal = GoalKind.maintain,
  double? paceKgPerWeek,
  MacroSplit split = MacroSplit.balanced,
}) {
  final maintenance = tdee(restingKcal: resting.value, activity: activity);

  final pace = (paceKgPerWeek ?? 0.5).clamp(minPaceKgPerWeek, maxPaceKgPerWeek);
  final adjustment = switch (goal) {
    GoalKind.lose => -dailyAdjustmentForPace(pace),
    GoalKind.maintain => 0.0,
    GoalKind.gain => dailyAdjustmentForPace(pace),
  };

  var target = maintenance + adjustment;
  // Never under the resting rate, whatever the pace asked for.
  final floored = target < resting.value;
  if (floored) target = resting.value;
  final kcal = target.round();

  // Protein from the split's share, raised to the 1.6 g/kg floor when the
  // goal is a loss or the split is high-protein.
  final floorApplies = goal == GoalKind.lose || split == MacroSplit.highProtein;
  final proteinFloor = floorApplies ? proteinFloorGPerKg * weightKg : 0.0;
  final proteinG = math.max(kcal * split.proteinShare / 4, proteinFloor);

  // Carbohydrate and fat share what is left in the split's own ratio.
  final remainder = math.max(kcal - proteinG * 4, 0.0);
  final carbFraction = split.carbShare / (split.carbShare + split.fatShare);
  final carbG = remainder * carbFraction / 4;
  final fatG = remainder * (1 - carbFraction) / 9;

  return EnergyTarget(
    kcal: kcal,
    restingKcal: resting.value.round(),
    maintenanceKcal: maintenance.round(),
    goal: goal,
    split: split,
    proteinG: proteinG.round(),
    carbG: carbG.round(),
    fatG: fatG.round(),
    restingFloorApplied: floored,
    basis: _basis(
      resting: resting,
      activity: activity,
      goal: goal,
      pace: pace,
      adjustment: adjustment,
      floored: floored,
    ),
  );
}

String _basis({
  required Prediction resting,
  required ActivityLevel activity,
  required GoalKind goal,
  required double pace,
  required double adjustment,
  required bool floored,
}) {
  final source = resting.equation == BiaEquation.cunningham1980
      ? 'From your fat-free mass'
      : 'From height, weight and age';
  final base = '$source (${resting.equation.citation}), '
      '${activity.label.toLowerCase()} ×${activity.pal}';
  final paceText = '${formatPace(pace)} kg a week';
  return switch (goal) {
    GoalKind.maintain => '$base, to maintain.',
    GoalKind.lose => floored
        ? '$base, held at your resting rate rather than the full deficit '
            'for $paceText.'
        : '$base, less ${(-adjustment).round()} kcal a day to lose $paceText.',
    GoalKind.gain => '$base, plus ${adjustment.round()} kcal a day to gain '
        '$paceText.',
  };
}

/// 0.5 → "0.5", 0.25 → "0.25", 1.0 → "1".
String formatPace(double pace) {
  if (pace == pace.roundToDouble()) return pace.round().toString();
  final s = pace.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

/// A word for the pace, for the slider label: "0.5 kg a week — steady".
String describePace(double pace) {
  if (pace < 0.4) return 'gentle';
  if (pace < 0.7) return 'steady';
  if (pace < 0.9) return 'brisk';
  return 'fast';
}

/// When the target weight would be reached at [paceKgPerWeek], counting from
/// [from]. Null when there is nothing to reach or no way to get there.
DateTime? projectedDate({
  required double currentKg,
  required double? targetKg,
  required double? paceKgPerWeek,
  required GoalKind goal,
  DateTime? from,
}) {
  if (targetKg == null || paceKgPerWeek == null || paceKgPerWeek <= 0) {
    return null;
  }
  final delta = switch (goal) {
    GoalKind.lose => currentKg - targetKg,
    GoalKind.gain => targetKg - currentKg,
    GoalKind.maintain => 0.0,
  };
  if (delta <= 0) return null;
  final days = (delta / paceKgPerWeek * 7).ceil();
  return (from ?? DateTime.now()).add(Duration(days: days));
}
