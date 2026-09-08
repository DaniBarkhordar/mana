/// The screen the whole product exists for.
///
/// The flow it enables, which no photo-only app can copy:
///
///   1. Bowl on the scale, tare.
///   2. Add an ingredient. The live number climbs; tap once and that
///      ingredient's own mass is captured from the delta.
///   3. Repeat. The running tare means the bowl is never emptied.
///   4. Optionally photograph the plate, or describe it in words — the model
///      names the components, and the scale supplies the grams. Identity from
///      the camera or the keyboard, quantity from the hardware.
///   5. Log the oil that actually went into the food, by weighing the pan before
///      and after.
///
/// Without a scale connected — the box has not arrived, or it is a restaurant
/// — the amount can be entered instead, and the tile says "Estimated". An
/// estimate is allowed; an estimate dressed up as a measurement is not.
///
/// Step 5 is the one worth defending. A controlled-feeding study presented at
/// NUTRITION 2026 found the leading photo apps underestimated meals by roughly
/// 250-345 kcal, with fat the dominant error term. No camera can see the oil
/// that went into a pan. A scale can.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/food/food_identifier.dart';
import '../../core/nutrition/models.dart';
import '../../core/nutrition/portion.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/tokens.dart';
import '../settings/paywall_screen.dart';
import '../settings/scale_pairing_sheet.dart';
import 'cooking_fat_sheet.dart';
import 'describe_food_sheet.dart';
import 'enter_grams_sheet.dart';
import 'food_search_sheet.dart';
import 'photo_identify_sheet.dart';
import 'scale_readout.dart';

class WeighFoodScreen extends ConsumerStatefulWidget {
  const WeighFoodScreen({super.key});

  @override
  ConsumerState<WeighFoodScreen> createState() => _WeighFoodScreenState();
}

class _WeighFoodScreenState extends ConsumerState<WeighFoodScreen> {
  FoodItem? _pending;

  /// Held from initState because `ref` is not usable in dispose, and giving
  /// the radio back is the whole point of leaving.
  late final StateController<ScaleKind> _focus;

  @override
  void initState() {
    super.initState();
    _focus = ref.read(scaleFocusProvider.notifier);
    // The kitchen scale holds the radio while this screen is open; the body
    // scale gets it back on the way out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.state = ScaleKind.kitchen;
    });
  }

  @override
  void dispose() {
    if (_focus.mounted) _focus.state = ScaleKind.body;
    super.dispose();
  }

  /// The last photo's components, so the next one can be picked without
  /// another scan.
  List<MatchedCandidate> _fromPhoto = const [];

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveGramsProvider);
    final components = ref.watch(weighSessionProvider);
    final totals = ref.watch(mealTotalsProvider);
    final pendingFat = ref.watch(pendingCookingFatProvider);
    final connection = ref.watch(kitchenConnectionProvider).valueOrNull;

    final grams = live.valueOrNull?.grams ?? 0;
    final isStable = live.valueOrNull?.isStable ?? false;
    final captured = ref.read(weighSessionProvider.notifier).platformGrams;
    final delta = grams - captured;
    final driver = ref.watch(kitchenScaleDriverProvider);
    final scaleConnected = connection == ScaleConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weigh food'),
        actions: [
          IconButton(
            tooltip: 'Tare',
            onPressed: () async {
              await ref.read(kitchenScaleDriverProvider).tare();
              await HapticFeedback.lightImpact();
            },
            icon: const Icon(Icons.exposure_zero),
          ),
        ],
      ),
      body: Column(
        children: [
          ScaleReadout(
            grams: grams,
            delta: delta,
            isStable: isStable,
            connection: connection,
            needsPairing: !(ref.watch(demoScaleProvider).valueOrNull ?? true) &&
                ref.watch(pairedScaleProvider(ScaleKind.kitchen)).valueOrNull ==
                    null,
            onPair: () => ScalePairingSheet.show(context, ScaleKind.kitchen),
          ),
          if (driver is SimulatedScaleDriver)
            _DemoLoadControls(driver: driver, currentGrams: grams),
          const Divider(height: 1),
          if (_fromPhoto.isNotEmpty)
            _FromPhotoStrip(
              matched: _fromPhoto,
              onPick: (food) => setState(() => _pending = food),
              onDismiss: () => setState(() => _fromPhoto = const []),
            ),
          Expanded(
            child: components.isEmpty
                ? _EmptyState(onPickFood: _pickFood)
                : _ComponentList(
                    components: components,
                    onRemove: (i) =>
                        ref.read(weighSessionProvider.notifier).removeAt(i),
                    onEditGrams: _editGrams,
                  ),
          ),
          _ActionBar(
            pending: _pending,
            pendingFat: pendingFat,
            scaleConnected: scaleConnected,
            canCapture: scaleConnected && isStable && delta > 0.5,
            deltaGrams: delta,
            onPickFood: _pickFood,
            onPhoto: _identifyFromPhoto,
            onDescribe: _describe,
            onCapture: () => _capture(grams),
            onEnterGrams: _enterGrams,
            onClearPending: () => setState(() => _pending = null),
            onCookingFat: _addCookingFat,
          ),
          if (components.isNotEmpty)
            _MealSummaryBar(
              totals: totals,
              onSave: _save,
              onSaveRecipe: () => _saveAsRecipe(grams),
            ),
        ],
      ),
    );
  }

  Future<void> _pickFood() async {
    final food = await FoodSearchSheet.show(context);
    if (food != null) setState(() => _pending = food);
  }

  void _capture(double totalGrams) {
    final food = _pending;
    if (food == null) return;
    ref.read(weighSessionProvider.notifier).addFromRunningTotal(
          food: food,
          totalOnScaleGrams: totalGrams,
        );
    HapticFeedback.mediumImpact();
    setState(() => _pending = null);
  }

  /// No scale connected: the amount is typed or picked from a household
  /// measure, and logged as the estimate it is. Never offered while the scale
  /// is there to be used — an estimate of something that could have been
  /// measured is the wrong number.
  Future<void> _enterGrams() async {
    final food = _pending;
    if (food == null) return;
    final portion = await EnterGramsSheet.show(context, food: food);
    if (portion == null || !mounted) return;
    ref.read(weighSessionProvider.notifier).addUnweighed(
          food: food,
          grams: portion.grams,
          method: portion.method,
          note: portion.note,
        );
    unawaited(HapticFeedback.lightImpact());
    setState(() => _pending = null);
  }

  /// Correct a component after capture. The replacement keeps its place in
  /// the list and its cooking-fat flag, but its provenance — method and note
  /// both — becomes the entered figure's: a corrected weighing is no longer
  /// a weighing, and a stale "One tablespoon" next to a typed 22 g would be
  /// a lie.
  Future<void> _editGrams(int index) async {
    final components = ref.read(weighSessionProvider);
    if (index < 0 || index >= components.length) return;
    final current = components[index];
    final portion = await EnterGramsSheet.show(
      context,
      food: current.food,
      initialGrams: current.grams,
    );
    if (portion == null || !mounted) return;
    ref.read(weighSessionProvider.notifier).replaceAt(
          index,
          LoggedComponent(
            food: current.food,
            grams: portion.grams,
            method: portion.method,
            note: portion.note,
            isCookingFat: current.isCookingFat,
          ),
        );
  }

  Future<void> _identifyFromPhoto() async {
    // The camera names the food. The scale weighs it. Nothing here asks a model
    // how many grams are on the plate, which is where the rest of the category
    // spends its error budget.
    final outcome = await PhotoIdentifySheet.show(
      context,
      measuredGrams: _liveGramsForContext(),
    );
    await _applyOutcome(outcome);
  }

  /// The same identification, from words instead of pixels. The description
  /// sheet collects the text; the results are matched and picked exactly as
  /// a photo's are.
  Future<void> _describe() async {
    final description = await DescribeFoodSheet.show(context);
    if (description == null || !mounted) return;
    final outcome = await PhotoIdentifySheet.show(
      context,
      description: description,
      measuredGrams: _liveGramsForContext(),
    );
    await _applyOutcome(outcome);
  }

  /// Sent as context only, so the model knows how many components are
  /// plausible. Never a question about quantity.
  double? _liveGramsForContext() {
    final live = ref.read(liveGramsProvider).valueOrNull?.grams;
    return live != null && live > 1 ? live : null;
  }

  Future<void> _applyOutcome(PhotoOutcome? outcome) async {
    if (outcome == null || !mounted) return;
    setState(() {
      _fromPhoto = outcome.matched.where((m) => m.best != null).toList();
      if (outcome.picked != null) _pending = outcome.picked;
    });
    if (outcome.wantsCookingFat) {
      await _addCookingFat(fatHint: outcome.fatHint);
    }
  }

  /// Weigh the pan, weigh the oil, weigh what is left. The sheet drives the
  /// scale itself; a pan still on the hob comes back here as `pendingFat`
  /// and the action bar's chip reopens the sheet at the last step.
  Future<void> _addCookingFat({String? fatHint}) async {
    final capture = await CookingFatSheet.show(context, fatHint: fatHint);
    if (capture != null) {
      ref.read(weighSessionProvider.notifier).addCookingFat(capture);
    }
  }

  /// Writes the meal to SQLite and returns. Sync happens on its own, later;
  /// nothing here waits for a network.
  Future<void> _save() async {
    final components = ref.read(weighSessionProvider);
    if (components.isEmpty) return;
    final services = await ref.read(appServicesProvider.future);
    final now = DateTime.now();
    await services.meals.logMeal(
      components: components,
      eatenAt: now,
      slot: MealSlot.forHour(now.hour),
    );
    ref.read(weighSessionProvider.notifier).reset();
    if (mounted) Navigator.of(context).pop();
  }

  /// Weigh the ingredients once, weigh the finished dish, log portions by
  /// weight forever. Plus, where purchases are configured.
  Future<void> _saveAsRecipe(double liveGrams) async {
    final components = ref.read(weighSessionProvider);
    if (components.isEmpty) return;
    if (BillingConfig.isConfigured &&
        !(ref.read(plusStatusProvider).valueOrNull?.isPlus ?? false)) {
      await PaywallScreen.show(
        context,
        reason: 'Recipes are part of Plus: weigh a dish once, log a portion '
            'by weight forever.',
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecipeSaveSheet(
        components: components,
        suggestedYieldGrams: liveGrams > 0 ? liveGrams : null,
      ),
    );
    if (saved == true && mounted) {
      ref.read(weighSessionProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved. Search for it by name to log a portion.'),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------

/// Stands in for putting something on the scale when the driver is the
/// simulator. Present in the release build on purpose: App Review cannot test
/// a Bluetooth scale they do not have, and this is their route through the
/// flow (CLAUDE.md rule 9). Labelled as a demo so it can never be mistaken for
/// a measurement.
class _DemoLoadControls extends StatelessWidget {
  const _DemoLoadControls({required this.driver, required this.currentGrams});

  final SimulatedScaleDriver driver;
  final double currentGrams;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, double grams) => ActionChip(
          label: Text(label),
          labelStyle: MananuType.caption.copyWith(fontWeight: FontWeight.w600),
          side: BorderSide(color: scheme.outline),
          onPressed: () => driver.setLoadGrams(grams),
        );
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.lg,
        0,
        MananuSpacing.lg,
        MananuSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            'Demo scale',
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: MananuSpacing.md),
          Expanded(
            child: Wrap(
              spacing: MananuSpacing.sm,
              children: [
                chip('+75 g', currentGrams + 75),
                chip('+160 g', currentGrams + 160),
                chip('Empty', 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickFood});

  final VoidCallback onPickFood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Scrolls rather than overflows: with a food pending the bar below is
    // taller, and on a small phone with the demo controls showing the space
    // left here can be less than the text needs.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MananuSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, size: 40, color: scheme.outline),
            const SizedBox(height: MananuSpacing.lg),
            Text(
              'Put the bowl on, then tare',
              style: MananuType.heading.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Add one ingredient at a time. Mananu captures each one from the '
              'change in weight, so you never have to empty the bowl.',
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

class _ComponentList extends StatelessWidget {
  const _ComponentList({
    required this.components,
    required this.onRemove,
    required this.onEditGrams,
  });

  final List<LoggedComponent> components;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEditGrams;

  /// Long press: correct the grams, or take the row out. Swipe still removes;
  /// this is the discoverable route to both.
  Future<void> _menu(BuildContext context, int index) async {
    final c = components[index];
    final action = await showModalBottomSheet<_RowAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.xl,
                0,
                MananuSpacing.xl,
                MananuSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${c.food.displayName} · ${c.grams.toStringAsFixed(0)} g',
                  style: MananuType.bodyStrong,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit grams'),
              subtitle: const Text('Marked as an estimate once changed'),
              onTap: () => Navigator.of(context).pop(_RowAction.edit),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: MananuColors.danger),
              title: const Text('Remove'),
              onTap: () => Navigator.of(context).pop(_RowAction.remove),
            ),
            const SizedBox(height: MananuSpacing.sm),
          ],
        ),
      ),
    );
    switch (action) {
      case _RowAction.edit:
        onEditGrams(index);
      case _RowAction.remove:
        onRemove(index);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: MananuSpacing.sm),
      itemCount: components.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, i) {
        final c = components[i];
        final weighed = c.method == PortionMethod.weighed;
        return Dismissible(
          key: ValueKey('${c.food.id}-$i'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onRemove(i),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: MananuSpacing.xl),
            color: MananuColors.danger.withValues(alpha: 0.12),
            child: const Icon(Icons.delete_outline, color: MananuColors.danger),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MananuSpacing.lg,
              vertical: MananuSpacing.xs,
            ),
            onLongPress: () => _menu(context, i),
            title: Text(c.food.displayName, style: MananuType.bodyStrong),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  ProvenanceBadge(weighed: weighed, dense: true),
                  const SizedBox(width: MananuSpacing.sm),
                  Text(
                    '${c.grams.toStringAsFixed(0)} g',
                    style: MananuType.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (c.note != null) ...[
                    const SizedBox(width: MananuSpacing.sm),
                    Expanded(
                      child: Text(
                        c.note!,
                        overflow: TextOverflow.ellipsis,
                        style: MananuType.caption.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Text(
              '${c.nutrients.kcal.round()} kcal',
              style: MananuType.number.copyWith(color: scheme.onSurface),
            ),
          ),
        );
      },
    );
  }
}

enum _RowAction { edit, remove }

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.pending,
    required this.pendingFat,
    required this.scaleConnected,
    required this.canCapture,
    required this.deltaGrams,
    required this.onPickFood,
    required this.onPhoto,
    required this.onDescribe,
    required this.onCapture,
    required this.onEnterGrams,
    required this.onClearPending,
    required this.onCookingFat,
  });

  final FoodItem? pending;

  /// Oil weighed into a pan that is still cooking. The chip brings the
  /// cooking-fat sheet back for the second reading.
  final PendingCookingFat? pendingFat;

  /// With the scale there, the only way to add the pending food is to weigh
  /// it. Without it, the amount is entered and marked as an estimate.
  final bool scaleConnected;
  final bool canCapture;
  final double deltaGrams;
  final VoidCallback onPickFood;
  final VoidCallback onPhoto;
  final VoidCallback onDescribe;
  final VoidCallback onCapture;
  final VoidCallback onEnterGrams;
  final VoidCallback onClearPending;
  final VoidCallback onCookingFat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (pending != null) {
      final hint = !scaleConnected
          ? 'No scale connected. Enter the amount instead; it is logged as '
              'an estimate.'
          : canCapture
              ? 'Reading has settled. Tap to capture '
                  '${deltaGrams.toStringAsFixed(1)} g.'
              : 'Add it to the bowl and wait for the number to settle.';
      return Container(
        padding: const EdgeInsets.all(MananuSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pendingFat != null) ...[
                _PendingFatChip(pending: pendingFat!, onTap: onCookingFat),
                const SizedBox(height: MananuSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Adding: ${pending!.displayName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MananuType.bodyStrong
                          .copyWith(color: scheme.onSurface),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Not this one',
                    visualDensity: VisualDensity.compact,
                    // Text height, not a 48 px hit box: the bar must stay
                    // short so the list above keeps its room.
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onClearPending,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: MananuSpacing.xs),
              Text(
                hint,
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: MananuSpacing.md),
              if (scaleConnected)
                FilledButton.icon(
                  onPressed: canCapture ? onCapture : null,
                  icon: const Icon(Icons.check),
                  label: Text(
                    canCapture
                        ? 'Capture ${deltaGrams.toStringAsFixed(1)} g'
                        : 'Waiting for the scale',
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: onEnterGrams,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Enter grams'),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MananuSpacing.lg,
        vertical: MananuSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingFat != null) ...[
              _PendingFatChip(pending: pendingFat!, onTap: onCookingFat),
              const SizedBox(height: MananuSpacing.xs),
            ],
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.search,
                    label: 'Search',
                    onTap: onPickFood,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Photo',
                    onTap: onPhoto,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.short_text,
                    label: 'Describe',
                    onTap: onDescribe,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.water_drop_outlined,
                    label: 'Cooking oil',
                    onTap: onCookingFat,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Pan: 15 g olive oil captured · weigh what is left". The first pan
/// reading is in; the food is cooking; one tap brings the sheet back for
/// the second reading.
class _PendingFatChip extends StatelessWidget {
  const _PendingFatChip({required this.pending, required this.onTap});

  final PendingCookingFat pending;
  final VoidCallback onTap;

  static String label(PendingCookingFat pending) =>
      'Pan: ${pending.gramsAdded.toStringAsFixed(0)} g '
      '${pending.fat.name.toLowerCase()} captured · weigh what is left';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(
          Icons.water_drop_outlined,
          size: 16,
          color: MananuColors.brass,
        ),
        label: Text(
          label(pending),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        labelStyle: MananuType.caption.copyWith(
          color: MananuColors.brass,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: MananuColors.soft(context, MananuColors.brass),
        side: BorderSide.none,
        onPressed: onTap,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = highlight ? MananuColors.brass : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: MananuSpacing.radiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MananuSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: colour, size: 22),
            const SizedBox(height: MananuSpacing.xs),
            // Four of these share a 390 px row; the label shrinks rather
            // than wrapping under large text.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: MananuType.caption.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSummaryBar extends StatelessWidget {
  const _MealSummaryBar({
    required this.totals,
    required this.onSave,
    required this.onSaveRecipe,
  });

  final MealTotals totals;
  final VoidCallback onSave;
  final VoidCallback onSaveRecipe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(MananuSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shrinks as one piece under large text rather than
                  // pushing the button off the edge.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${totals.kcal.round()}',
                          style: MananuType.display
                              .copyWith(color: scheme.onSurface, fontSize: 30),
                        ),
                        const SizedBox(width: 4),
                        const Text('kcal', style: MananuType.caption),
                        const SizedBox(width: MananuSpacing.sm),

                        // The honest uncertainty band. Never a single headline
                        // accuracy percentage: accuracy depends entirely on the
                        // meal, and a system-wide figure is a claim that cannot be
                        // substantiated.
                        Text(
                          '±${(totals.relativeError * 100).round()}%',
                          style: MananuType.caption.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${totals.confidenceLabel} · '
                    '${(totals.weighedFraction * 100).round()}% of these '
                    'calories were weighed',
                    style: MananuType.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MananuSpacing.sm),
            IconButton(
              tooltip: 'Save as recipe',
              onPressed: onSaveRecipe,
              icon: const Icon(Icons.menu_book_outlined),
            ),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size(112, 50),
              ),
              child: const Text('Log meal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name it, then weigh the finished dish. The yield is what makes the
/// per-portion figures right: water boils off and fat renders out, so the
/// sum of the ingredients would overstate every portion, forever.
class _RecipeSaveSheet extends ConsumerStatefulWidget {
  const _RecipeSaveSheet({
    required this.components,
    required this.suggestedYieldGrams,
  });

  final List<LoggedComponent> components;
  final double? suggestedYieldGrams;

  @override
  ConsumerState<_RecipeSaveSheet> createState() => _RecipeSaveSheetState();
}

class _RecipeSaveSheetState extends ConsumerState<_RecipeSaveSheet> {
  final _name = TextEditingController();
  late final TextEditingController _yield;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _yield = TextEditingController(
      text: widget.suggestedYieldGrams == null
          ? ''
          : widget.suggestedYieldGrams!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _yield.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final yieldGrams = double.tryParse(_yield.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty || yieldGrams <= 0) return;
    setState(() => _busy = true);
    final services = await ref.read(appServicesProvider.future);
    await services.recipes.save(
      name: _name.text,
      components: widget.components,
      yieldGrams: yieldGrams,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final ingredientGrams =
        widget.components.fold<double>(0, (a, c) => a + c.grams);
    final live = ref.watch(liveGramsProvider).valueOrNull;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        0,
        MananuSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + MananuSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Save as a recipe', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            '${widget.components.length} '
            '${widget.components.length == 1 ? 'ingredient' : 'ingredients'}, '
            '${ingredientGrams.toStringAsFixed(0)} g in. Now put the finished '
            'dish on the scale: what it weighs cooked is what a portion is '
            'measured against.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.lg),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Chicken tikka',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: MananuSpacing.md),
          TextField(
            controller: _yield,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Finished dish, grams',
              border: const OutlineInputBorder(),
              suffixIcon: live != null && live.grams > 0
                  ? TextButton(
                      onPressed: () => setState(
                        () => _yield.text = live.grams.toStringAsFixed(0),
                      ),
                      child: Text('Use ${live.grams.toStringAsFixed(0)} g'),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: MananuSpacing.lg),
          FilledButton(
            onPressed: _busy ||
                    _name.text.trim().isEmpty ||
                    (double.tryParse(_yield.text.trim()) ?? 0) <= 0
                ? null
                : _save,
            child: const Text('Save recipe'),
          ),
        ],
      ),
    );
  }
}

/// The components the last photo found, one tap each. The chosen one becomes
/// the pending ingredient; the grams still come from the scale.
class _FromPhotoStrip extends StatelessWidget {
  const _FromPhotoStrip({
    required this.matched,
    required this.onPick,
    required this.onDismiss,
  });

  final List<MatchedCandidate> matched;
  final ValueChanged<FoodItem> onPick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.lg,
        MananuSpacing.sm,
        MananuSpacing.sm,
        MananuSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'From your photo',
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: MananuSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in matched)
                    Padding(
                      padding: const EdgeInsets.only(right: MananuSpacing.sm),
                      child: ActionChip(
                        label: Text(m.candidate.name),
                        labelStyle: MananuType.caption
                            .copyWith(fontWeight: FontWeight.w600),
                        side: BorderSide(color: scheme.outline),
                        onPressed: () => onPick(m.best!),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
