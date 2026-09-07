/// Goals.
///
/// The same four fields onboarding asked for — goal, target weight, pace and
/// macro split — with the daily target recomputed live above them, so the
/// effect of a change is visible before it is felt. Every change is saved as
/// it is made; there is no separate save step to forget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../theme/tokens.dart';
import '../onboarding/goal_controls.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  /// Used only for the preview above when no weight exists at all.
  static const double _previewWeightKg = 75;

  /// Local copy of the goal fields, so a slider moves freely and the target
  /// follows it on the same frame; the database catches up on release.
  GoalKind? _goal;
  double? _targetWeightKg;
  double? _paceKgPerWeek;
  MacroSplit? _split;

  void _adopt(UserProfile profile) {
    _goal ??= profile.goal;
    _paceKgPerWeek ??= profile.paceKgPerWeek ?? 0.5;
    _split ??= profile.macroSplit;
    _targetWeightKg ??= profile.targetWeightKg;
  }

  Future<void> _save() async {
    final goal = _goal;
    if (goal == null) return;
    final services = await ref.read(appServicesProvider.future);
    await services.profiles.saveGoal(
      goal: goal,
      targetWeightKg: goal == GoalKind.maintain ? null : _targetWeightKg,
      paceKgPerWeek: goal == GoalKind.maintain ? null : _paceKgPerWeek,
      macroSplit: _split ?? MacroSplit.balanced,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goals')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _adopt(profile);
    final goal = _goal!;
    final knownWeightKg = ref.watch(targetWeightBasisProvider);
    // Only an install that skipped the weight step has no figure at all. The
    // preview then says plainly what it is sized from; Today shows no target
    // until a real weight exists (see dailyTargetProvider).
    final weightKg = knownWeightKg ?? _previewWeightKg;
    final latest = ref.watch(latestBodyMeasurementProvider);
    final targetKg = goal == GoalKind.maintain
        ? null
        : (_targetWeightKg ?? TargetWeightControl.defaultFor(goal, weightKg));
    final pace = _paceKgPerWeek ?? 0.5;
    final split = _split ?? MacroSplit.balanced;

    final target = energyTargetFor(
      profile: profile.copyWith(
        goal: goal,
        targetWeightKg: targetKg,
        paceKgPerWeek: pace,
        macroSplit: split,
      ),
      latest: latest,
      weightKg: weightKg,
    );
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MananuSpacing.lg,
          MananuSpacing.sm,
          MananuSpacing.lg,
          MananuSpacing.huge,
        ),
        children: [
          MananuSection(
            title: 'Your daily target',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(MananuSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TargetSummary(target: target, compact: true),
                    const SizedBox(height: MananuSpacing.md),
                    Text(
                      latest != null
                          ? 'Sized from your latest reading, '
                              '${latest.weightKg.toStringAsFixed(1)} kg. '
                              'This will move as your weight does.'
                          : knownWeightKg != null
                              ? 'Sized from ${weightKg.toStringAsFixed(1)} kg, '
                                  'as typed in. This will move as your weight '
                                  'does: the first reading takes over.'
                              : 'A preview sized from $_previewWeightKg kg, '
                                  'because no weight has been entered yet. '
                                  'Today shows no target until you step on '
                                  'the scale.',
                      style: MananuType.caption.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Goal',
            child: GoalCards(
              selected: goal,
              onChanged: (g) {
                setState(() {
                  _goal = g;
                  _targetWeightKg = g == GoalKind.maintain
                      ? null
                      : TargetWeightControl.defaultFor(g, weightKg);
                });
                unawaited(_save());
              },
            ),
          ),
          if (goal != GoalKind.maintain && targetKg != null) ...[
            const SizedBox(height: MananuSpacing.md),
            MananuSection(
              title: 'Target weight',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(MananuSpacing.lg),
                  child: TargetWeightControl(
                    goal: goal,
                    currentKg: weightKg,
                    targetKg: targetKg,
                    onChanged: (v) => setState(() => _targetWeightKg = v),
                    // Saved on release, not on every tick of the drag.
                    onChangeEnd: (_) => unawaited(_save()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.xl),
            MananuSection(
              title: 'Pace',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(MananuSpacing.lg),
                  child: PaceControl(
                    goal: goal,
                    paceKgPerWeek: pace,
                    currentKg: weightKg,
                    targetKg: targetKg,
                    dailyKcal: target.adjustmentKcal.abs(),
                    onChanged: (v) => setState(() => _paceKgPerWeek = v),
                    onChangeEnd: (_) => unawaited(_save()),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: MananuSpacing.xl),
          MananuSection(
            title: 'Macro split',
            child: MacroSplitControl(
              selected: split,
              onChanged: (s) {
                setState(() => _split = s);
                unawaited(_save());
              },
            ),
          ),
        ],
      ),
    );
  }
}
