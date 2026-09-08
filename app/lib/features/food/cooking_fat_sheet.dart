/// Cooking fat, captured on the live scale rather than guessed on a slider.
///
/// Three steps, each one a reading:
///
///   1. Pan on the scale, tare. The pan is zeroed out.
///   2. Add the oil. The number climbs; capture it once it settles.
///   3. Cook, then put the pan back. What the scale reads now stayed in the
///      pan; the difference went into the food. Split it across the portions.
///
/// The food takes longer to cook than a bottom sheet lives, so the first
/// reading is parked in the weigh session (`pendingFat`) and the action bar
/// offers to bring the sheet back at step 3 when the pan is ready.
///
/// The old version of this sheet used sliders and still recorded the result
/// as weighed, so a guess counted towards the meal's weighed share. That is
/// exactly the number the product must not inflate. Now the only way to log
/// this as weighed is for the scale to have read it; the typed fallback for a
/// kitchen with no scale connected carries [PortionMethod.manualGrams] and the
/// Estimated badge, the same as any other typed amount.
///
/// The fat is a real food from the catalogue — olive oil, butter, ghee — so
/// the energy comes from that food's own per-100 g figures. There is no
/// "oil is 9 kcal a gram" constant anywhere in the app.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/food/starter_foods.dart';
import '../../core/nutrition/models.dart';
import '../../core/nutrition/portion.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/tokens.dart';
import 'food_search_sheet.dart';
import 'scale_readout.dart';

/// Local key-value entry: the id of the fat used last time, so the sheet
/// opens on the butter a butter household cooks with.
const lastCookingFatKey = 'last_cooking_fat';

class CookingFatSheet extends ConsumerStatefulWidget {
  const CookingFatSheet({super.key, this.fatHint});

  /// What the photo or description suggested the food was cooked in
  /// ("ghee"). Used only to pre-select a fat from the catalogue; the user
  /// can change it, and the amount never comes from the hint.
  final String? fatHint;

  /// The finished capture, or null when the user backed out. A pan left on
  /// the hob is not a back-out: the first reading stays in the weigh session
  /// and the sheet reopens at step 3.
  static Future<CookingFatCapture?> show(
    BuildContext context, {
    String? fatHint,
  }) =>
      showModalBottomSheet<CookingFatCapture>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => CookingFatSheet(fatHint: fatHint),
      );

  @override
  ConsumerState<CookingFatSheet> createState() => _CookingFatSheetState();
}

enum _Step { pan, oil, back, typed }

class _CookingFatSheetState extends ConsumerState<CookingFatSheet> {
  late _Step _step;
  FoodItem _fat = starterOliveOil;

  /// The first reading, once captured (or resumed from the session).
  double? _added;

  /// The second reading, once captured.
  double? _remaining;
  int _portions = 1;

  /// Why the sheet opened on the typed path, when it did.
  String? _typedReason;

  final _addedText = TextEditingController();
  final _remainingText = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pending = ref.read(weighSessionProvider.notifier).pendingFat;
    if (pending != null) {
      // The pan is back. Pick up where the cook left off.
      _fat = pending.fat;
      _added = pending.gramsAdded;
      _portions = pending.portions;
      _step = _Step.back;
      return;
    }
    final connected = ref.read(kitchenConnectionProvider).valueOrNull ==
        ScaleConnectionState.connected;
    if (connected) {
      _step = _Step.pan;
    } else {
      _step = _Step.typed;
      _typedReason = 'No kitchen scale connected, so the two pan readings '
          'are typed and the fat is logged as an estimate.';
    }
    unawaited(_resolveDefaultFat());
  }

  @override
  void dispose() {
    _addedText.dispose();
    _remainingText.dispose();
    super.dispose();
  }

  /// The hint from the photo, else the fat used last time, else olive oil.
  Future<void> _resolveDefaultFat() async {
    FoodItem? found;
    final hint = widget.fatHint?.trim();
    if (hint != null && hint.isNotEmpty) {
      final search = await ref.read(foodSearchProvider.future);
      final result = await search.search(hint, limit: 1);
      if (result.items.isNotEmpty) found = result.items.first;
    }
    if (found == null) {
      final services = await ref.read(appServicesProvider.future);
      final id = await services.db.stateValue(lastCookingFatKey);
      if (id != null) found = await _foodById(id);
    }
    if (!mounted || found == null) return;
    setState(() => _fat = found!);
  }

  /// A food id from any of the three places a food can live.
  Future<FoodItem?> _foodById(String id) async {
    final services = await ref.read(appServicesProvider.future);
    final own = await services.userFoods.byId(id);
    if (own != null) return own;
    final catalog = await ref.read(foodCatalogProvider.future);
    final fromCatalog = catalog?.byId(id);
    if (fromCatalog != null) return fromCatalog;
    for (final f in starterFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  WeighSessionNotifier get _session => ref.read(weighSessionProvider.notifier);

  void _parkPending() {
    final added = _added;
    if (added == null) return;
    _session.setPendingFat(
      PendingCookingFat(fat: _fat, gramsAdded: added, portions: _portions),
    );
  }

  Future<void> _changeFat() async {
    final picked = await FoodSearchSheet.show(context);
    if (picked == null || !mounted) return;
    setState(() => _fat = picked);
    // A pan already on the hob keeps its reading but takes the new name.
    if (_step == _Step.back) _parkPending();
  }

  Future<void> _tare() async {
    await ref.read(kitchenScaleDriverProvider).tare();
    unawaited(HapticFeedback.lightImpact());
    if (!mounted) return;
    setState(() => _step = _Step.oil);
  }

  /// Step 2: the oil is in. Parked in the session straight away, because the
  /// next thing the user does is close this sheet and cook.
  void _captureAdded(double grams) {
    _added = grams;
    _parkPending();
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _step = _Step.back);
  }

  /// Step 3: the pan is back with whatever is left in it.
  void _captureRemaining(double grams) {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _remaining = grams);
  }

  void _setPortions(int n) {
    setState(() => _portions = n.clamp(1, 8));
    if (_step == _Step.back) _parkPending();
  }

  void _typeInstead() {
    final added = _added;
    if (added != null) _addedText.text = _format(added);
    setState(() {
      _step = _Step.typed;
      _typedReason = null;
    });
  }

  void _useScaleInstead() {
    setState(() {
      _step = _added == null ? _Step.pan : _Step.back;
      _remaining = null;
    });
  }

  static String _format(double g) =>
      g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1);

  static double _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _finish(CookingFatCapture capture) async {
    final services = await ref.read(appServicesProvider.future);
    await services.db.setStateValue(lastCookingFatKey, capture.fat.id);
    if (!mounted) return;
    Navigator.of(context).pop(capture);
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveGramsProvider).valueOrNull;
    final connection = ref.watch(kitchenConnectionProvider).valueOrNull;
    final connected = connection == ScaleConnectionState.connected;
    final grams = live?.grams ?? 0;
    final isStable = live?.isStable ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        MananuSpacing.sm,
        MananuSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + MananuSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(step: _step),
          const SizedBox(height: MananuSpacing.md),
          _FatRow(fat: _fat, onChange: _changeFat),
          const SizedBox(height: MananuSpacing.lg),
          switch (_step) {
            _Step.pan => _PanStep(
                grams: grams,
                isStable: isStable,
                connection: connection,
                onTare: connected ? _tare : null,
                onTypeInstead: _typeInstead,
              ),
            _Step.oil => _OilStep(
                grams: grams,
                isStable: isStable,
                connection: connection,
                onCapture: connected && isStable && grams > 0.5
                    ? () => _captureAdded(grams)
                    : null,
                onTypeInstead: _typeInstead,
              ),
            _Step.back => _BackStep(
                fat: _fat,
                added: _added!,
                remaining: _remaining,
                portions: _portions,
                grams: grams,
                isStable: isStable,
                connection: connection,
                onCapture: connected && isStable
                    ? () => _captureRemaining(grams)
                    : null,
                onReweigh: () => setState(() => _remaining = null),
                onPortions: _setPortions,
                onTypeInstead: _typeInstead,
                onAdd: _remaining == null
                    ? null
                    : () => _finish(
                          CookingFatCapture(
                            fat: _fat,
                            gramsAdded: _added!,
                            gramsRemaining: _remaining!,
                            portions: _portions,
                          ),
                        ),
              ),
            _Step.typed => _TypedStep(
                fat: _fat,
                reason: _typedReason,
                addedText: _addedText,
                remainingText: _remainingText,
                portions: _portions,
                onPortions: _setPortions,
                onChanged: () => setState(() {}),
                onUseScale: connected ? _useScaleInstead : null,
                onAdd: () => _finish(
                  CookingFatCapture(
                    fat: _fat,
                    gramsAdded: _parse(_addedText.text),
                    gramsRemaining: _parse(_remainingText.text),
                    portions: _portions,
                    method: PortionMethod.manualGrams,
                  ),
                ),
              ),
          },
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = switch (step) {
      _Step.pan => 1,
      _Step.oil => 2,
      _Step.back => 3,
      _Step.typed => null,
    };
    return Row(
      children: [
        const Expanded(child: Text('Cooking oil', style: MananuType.title)),
        if (n != null)
          Text(
            'STEP $n OF 3',
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

/// Which fat, with its own figures. Butter is not olive oil.
class _FatRow extends StatelessWidget {
  const _FatRow({required this.fat, required this.onChange});

  final FoodItem fat;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Icon(
          Icons.water_drop_outlined,
          color: MananuColors.brass,
          size: 20,
        ),
        const SizedBox(width: MananuSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fat.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MananuType.bodyStrong.copyWith(color: scheme.onSurface),
              ),
              Text(
                '${fat.per100g.kcal.round()} kcal / 100 g · '
                '${fat.source.label}',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onChange, child: const Text('Change')),
      ],
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: MananuType.heading.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: MananuSpacing.xs),
        Text(
          body,
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _PanStep extends StatelessWidget {
  const _PanStep({
    required this.grams,
    required this.isStable,
    required this.connection,
    required this.onTare,
    required this.onTypeInstead,
  });

  final double grams;
  final bool isStable;
  final ScaleConnectionState? connection;
  final VoidCallback? onTare;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepText(
          heading: 'Pan on the scale, then tap Tare',
          body: 'The scale zeroes to the pan, so the next reading is the '
              'oil on its own.',
        ),
        ScaleReadout(
          grams: grams,
          delta: 0,
          isStable: isStable,
          connection: connection,
        ),
        FilledButton.icon(
          onPressed: onTare,
          icon: const Icon(Icons.exposure_zero),
          label: const Text('Tare'),
        ),
        TextButton(
          onPressed: onTypeInstead,
          child: const Text('Type it instead'),
        ),
      ],
    );
  }
}

class _OilStep extends StatelessWidget {
  const _OilStep({
    required this.grams,
    required this.isStable,
    required this.connection,
    required this.onCapture,
    required this.onTypeInstead,
  });

  final double grams;
  final bool isStable;
  final ScaleConnectionState? connection;
  final VoidCallback? onCapture;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepText(
          heading: 'Add the oil',
          body: 'Pour it into the pan. Capture once the reading has settled.',
        ),
        ScaleReadout(
          grams: grams,
          delta: 0,
          isStable: isStable,
          connection: connection,
        ),
        FilledButton.icon(
          onPressed: onCapture,
          icon: const Icon(Icons.check),
          label: Text(
            onCapture == null
                ? 'Waiting for the scale'
                : 'Capture ${grams.toStringAsFixed(1)} g',
          ),
        ),
        TextButton(
          onPressed: onTypeInstead,
          child: const Text('Type it instead'),
        ),
      ],
    );
  }
}

class _BackStep extends StatelessWidget {
  const _BackStep({
    required this.fat,
    required this.added,
    required this.remaining,
    required this.portions,
    required this.grams,
    required this.isStable,
    required this.connection,
    required this.onCapture,
    required this.onReweigh,
    required this.onPortions,
    required this.onTypeInstead,
    required this.onAdd,
  });

  final FoodItem fat;
  final double added;
  final double? remaining;
  final int portions;
  final double grams;
  final bool isStable;
  final ScaleConnectionState? connection;
  final VoidCallback? onCapture;
  final VoidCallback onReweigh;
  final ValueChanged<int> onPortions;
  final VoidCallback onTypeInstead;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = remaining;
    final capture = left == null
        ? null
        : CookingFatCapture(
            fat: fat,
            gramsAdded: added,
            gramsRemaining: left,
            portions: portions,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepText(
          heading: 'Cook, then put the pan back',
          body: '${added.toStringAsFixed(1)} g of ${fat.name.toLowerCase()} '
              'went in. Close this while it cooks; that reading is kept. '
              'When the pan comes back, whatever the scale reads stayed in '
              'the pan.',
        ),
        if (left == null) ...[
          ScaleReadout(
            grams: grams,
            delta: 0,
            isStable: isStable,
            connection: connection,
          ),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.check),
            label: Text(
              onCapture == null
                  ? 'Waiting for the scale'
                  : 'Capture ${grams.toStringAsFixed(1)} g left',
            ),
          ),
          TextButton(
            onPressed: onTypeInstead,
            child: const Text('Type it instead'),
          ),
        ] else ...[
          const SizedBox(height: MananuSpacing.lg),
          Row(
            children: [
              const ProvenanceBadge(weighed: true),
              const SizedBox(width: MananuSpacing.sm),
              Expanded(
                child: Text(
                  '${left.toStringAsFixed(1)} g left in the pan · '
                  '${capture!.gramsAbsorbed.toStringAsFixed(1)} g into the '
                  'food',
                  style: MananuType.caption.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              TextButton(onPressed: onReweigh, child: const Text('Re-weigh')),
            ],
          ),
          const SizedBox(height: MananuSpacing.md),
          _PortionsStepper(portions: portions, onChanged: onPortions),
          const SizedBox(height: MananuSpacing.lg),
          _ResultLine(capture: capture),
          const SizedBox(height: MananuSpacing.lg),
          FilledButton(
            onPressed: capture.gramsAbsorbed > 0 ? onAdd : null,
            child: Text(
              capture.gramsAbsorbed > 0
                  ? 'Add to meal'
                  : 'Nothing left the pan',
            ),
          ),
        ],
      ],
    );
  }
}

/// No scale: the two readings are typed, and the result says so.
class _TypedStep extends StatelessWidget {
  const _TypedStep({
    required this.fat,
    required this.reason,
    required this.addedText,
    required this.remainingText,
    required this.portions,
    required this.onPortions,
    required this.onChanged,
    required this.onUseScale,
    required this.onAdd,
  });

  final FoodItem fat;
  final String? reason;
  final TextEditingController addedText;
  final TextEditingController remainingText;
  final int portions;
  final ValueChanged<int> onPortions;
  final VoidCallback onChanged;
  final VoidCallback? onUseScale;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final added = _CookingFatSheetState._parse(addedText.text);
    final remaining = _CookingFatSheetState._parse(remainingText.text);
    final capture = added <= 0
        ? null
        : CookingFatCapture(
            fat: fat,
            gramsAdded: added,
            gramsRemaining: remaining,
            portions: portions,
            method: PortionMethod.manualGrams,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepText(
          heading: 'Enter the two pan readings',
          body: reason ??
              'What went into the pan, and what was left in it afterwards. '
                  'Typed figures are logged as an estimate.',
        ),
        const SizedBox(height: MananuSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _GramsField(
                controller: addedText,
                label: 'Oil added',
                autofocus: true,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: MananuSpacing.md),
            Expanded(
              child: _GramsField(
                controller: remainingText,
                label: 'Left in the pan',
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.lg),
        _PortionsStepper(portions: portions, onChanged: onPortions),
        const SizedBox(height: MananuSpacing.lg),
        if (capture != null) ...[
          _ResultLine(capture: capture),
          const SizedBox(height: MananuSpacing.md),
        ],
        Row(
          children: [
            const ProvenanceBadge(weighed: false),
            const SizedBox(width: MananuSpacing.sm),
            Expanded(
              child: Text(
                'Entered by hand',
                style: MananuType.caption.copyWith(color: muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: MananuSpacing.lg),
        FilledButton(
          onPressed:
              capture != null && capture.gramsAbsorbed > 0 ? onAdd : null,
          child: Text(
            capture == null
                ? 'Enter the oil added'
                : capture.gramsAbsorbed > 0
                    ? 'Add to meal'
                    : 'Nothing left the pan',
          ),
        ),
        if (onUseScale != null)
          TextButton(
            onPressed: onUseScale,
            child: const Text('Use the scale instead'),
          ),
      ],
    );
  }
}

class _GramsField extends StatelessWidget {
  const _GramsField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        LengthLimitingTextInputFormatter(6),
      ],
      style: MananuType.number,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        suffixText: 'g',
        border: const OutlineInputBorder(borderRadius: MananuSpacing.radiusMd),
      ),
    );
  }
}

/// How many plates came out of the pan. One to eight: a pan that served
/// more than eight is a batch, and a batch is a recipe.
class _PortionsStepper extends StatelessWidget {
  const _PortionsStepper({required this.portions, required this.onChanged});

  final int portions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Portions from this pan',
            style: MananuType.body.copyWith(color: scheme.onSurface),
          ),
        ),
        IconButton.outlined(
          tooltip: 'Fewer portions',
          onPressed: portions > 1 ? () => onChanged(portions - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$portions',
            textAlign: TextAlign.center,
            style: MananuType.number.copyWith(color: scheme.onSurface),
          ),
        ),
        IconButton.outlined(
          tooltip: 'More portions',
          onPressed: portions < 8 ? () => onChanged(portions + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// A fact about this meal, and nothing else: what one portion carries, from
/// the fat's own per-100 g figures. Never a comparison with anyone.
class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.capture});

  final CookingFatCapture capture;

  static String text(CookingFatCapture capture) {
    final component = capture.componentForOnePortion();
    return '${capture.gramsPerPortion.toStringAsFixed(1)} g '
        '${capture.fat.name.toLowerCase()} per portion, '
        '${component.nutrients.kcal.round()} kcal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MananuSpacing.lg),
      decoration: BoxDecoration(
        color: MananuColors.soft(context, MananuColors.brass),
        borderRadius: MananuSpacing.radiusMd,
      ),
      child: Text(
        text(capture),
        style: MananuType.bodyStrong.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
