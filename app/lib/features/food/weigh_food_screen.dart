/// The screen the whole product exists for.
///
/// The flow it enables, which no photo-only app can copy:
///
///   1. Bowl on the scale, tare.
///   2. Add an ingredient. The live number climbs; tap once and that
///      ingredient's own mass is captured from the delta.
///   3. Repeat. The running tare means the bowl is never emptied.
///   4. Optionally photograph the plate — the model names the components, and
///      the scale supplies the grams. Identity from the camera, quantity from
///      the hardware.
///   5. Log the oil that actually went into the food, by weighing the pan before
///      and after.
///
/// Step 5 is the one worth defending. A controlled-feeding study presented at
/// NUTRITION 2026 found the leading photo apps underestimated meals by roughly
/// 250-345 kcal, with fat the dominant error term. No camera can see the oil
/// that went into a pan. A scale can.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/nutrition/models.dart';
import '../../core/nutrition/portion.dart';
import '../../core/scale/scale_driver.dart';
import '../../theme/tokens.dart';

class WeighFoodScreen extends ConsumerStatefulWidget {
  const WeighFoodScreen({super.key});

  @override
  ConsumerState<WeighFoodScreen> createState() => _WeighFoodScreenState();
}

class _WeighFoodScreenState extends ConsumerState<WeighFoodScreen> {
  FoodItem? _pending;

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveGramsProvider);
    final components = ref.watch(weighSessionProvider);
    final totals = ref.watch(mealTotalsProvider);
    final connection = ref.watch(kitchenConnectionProvider).valueOrNull;

    final grams = live.valueOrNull?.grams ?? 0;
    final isStable = live.valueOrNull?.isStable ?? false;
    final captured = ref.read(weighSessionProvider.notifier).platformGrams;
    final delta = grams - captured;
    final driver = ref.watch(kitchenScaleDriverProvider);

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
          _ScaleReadout(
            grams: grams,
            delta: delta,
            isStable: isStable,
            connection: connection,
          ),
          if (driver is SimulatedScaleDriver)
            _DemoLoadControls(driver: driver, currentGrams: grams),
          const Divider(height: 1),
          Expanded(
            child: components.isEmpty
                ? _EmptyState(onPickFood: _pickFood)
                : _ComponentList(
                    components: components,
                    onRemove: (i) =>
                        ref.read(weighSessionProvider.notifier).removeAt(i),
                  ),
          ),
          _ActionBar(
            pending: _pending,
            canCapture: isStable && delta > 0.5,
            deltaGrams: delta,
            onPickFood: _pickFood,
            onPhoto: _identifyFromPhoto,
            onCapture: () => _capture(grams),
            onCookingFat: _addCookingFat,
          ),
          if (components.isNotEmpty)
            _MealSummaryBar(totals: totals, onSave: _save),
        ],
      ),
    );
  }

  Future<void> _pickFood() async {
    final food = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FoodSearchSheet(),
    );
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

  Future<void> _identifyFromPhoto() async {
    // The camera names the food. The scale weighs it. Nothing here asks a model
    // how many grams are on the plate, which is where the rest of the category
    // spends its error budget.
    final picked = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PhotoIdentifySheet(),
    );
    if (picked != null) setState(() => _pending = picked);
  }

  Future<void> _addCookingFat() async {
    final capture = await showModalBottomSheet<CookingFatCapture>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CookingFatSheet(),
    );
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

class _ScaleReadout extends StatelessWidget {
  const _ScaleReadout({
    required this.grams,
    required this.delta,
    required this.isStable,
    required this.connection,
  });

  final double grams;
  final double delta;
  final bool isStable;
  final ScaleConnectionState? connection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = connection == ScaleConnectionState.connected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        MananuSpacing.xl,
        MananuSpacing.lg,
        MananuSpacing.xl,
        MananuSpacing.xl,
      ),
      color: scheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? MananuColors.measured : MananuColors.mist,
                ),
              ),
              const SizedBox(width: MananuSpacing.sm),
              Text(
                connected ? 'Scale connected' : 'Looking for your scale',
                style: MananuType.label.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: MananuSpacing.lg),

          // The readout. Tabular figures so digits do not shuffle sideways as
          // the number climbs, and a colour that only settles once the reading
          // has settled — the user should be able to tell at a glance, without
          // reading a word.
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: MananuType.readout.copyWith(
              color: isStable
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.45),
            ),
            child: Text(grams.toStringAsFixed(grams >= 1000 ? 0 : 1)),
          ),
          Text(
            'grams',
            style: MananuType.label.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          if (delta > 0.5) ...[
            const SizedBox(height: MananuSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MananuSpacing.md,
                vertical: MananuSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: MananuColors.brassSoft,
                borderRadius: MananuSpacing.radiusSm,
              ),
              child: Text(
                '+${delta.toStringAsFixed(1)} g since last ingredient',
                style: MananuType.caption.copyWith(
                  color: MananuColors.brass,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
    return Center(
      child: Padding(
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
  const _ComponentList({required this.components, required this.onRemove});

  final List<LoggedComponent> components;
  final ValueChanged<int> onRemove;

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

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.pending,
    required this.canCapture,
    required this.deltaGrams,
    required this.onPickFood,
    required this.onPhoto,
    required this.onCapture,
    required this.onCookingFat,
  });

  final FoodItem? pending;
  final bool canCapture;
  final double deltaGrams;
  final VoidCallback onPickFood;
  final VoidCallback onPhoto;
  final VoidCallback onCapture;
  final VoidCallback onCookingFat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (pending != null) {
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
              Text(
                'Adding: ${pending!.displayName}',
                style: MananuType.bodyStrong.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: MananuSpacing.xs),
              Text(
                canCapture
                    ? 'Reading has settled. Tap to capture '
                        '${deltaGrams.toStringAsFixed(1)} g.'
                    : 'Add it to the bowl and wait for the number to settle.',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: MananuSpacing.md),
              FilledButton.icon(
                onPressed: canCapture ? onCapture : null,
                icon: const Icon(Icons.check),
                label: Text(
                  canCapture
                      ? 'Capture ${deltaGrams.toStringAsFixed(1)} g'
                      : 'Waiting for the scale',
                ),
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
        child: Row(
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
                icon: Icons.water_drop_outlined,
                label: 'Cooking oil',
                onTap: onCookingFat,
                highlight: true,
              ),
            ),
          ],
        ),
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
            Text(
              label,
              style: MananuType.caption.copyWith(
                color: colour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSummaryBar extends StatelessWidget {
  const _MealSummaryBar({required this.totals, required this.onSave});

  final MealTotals totals;
  final VoidCallback onSave;

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
                  Row(
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
            const SizedBox(width: MananuSpacing.md),
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

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

class _FoodSearchSheet extends ConsumerStatefulWidget {
  const _FoodSearchSheet();

  @override
  ConsumerState<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<_FoodSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _demoCatalogue
        .where(
          (f) =>
              _query.isEmpty ||
              f.displayName.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MananuSpacing.lg),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search foods, or scan a barcode',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: MananuSpacing.radiusMd,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: results.length,
              itemBuilder: (context, i) {
                final f = results[i];
                return ListTile(
                  title: Text(f.displayName),
                  subtitle: Text(
                    '${f.per100g.kcal.round()} kcal / 100 g · ${f.source.label}',
                    style: MananuType.caption,
                  ),
                  onTap: () => Navigator.of(context).pop(f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoIdentifySheet extends StatelessWidget {
  const _PhotoIdentifySheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(MananuSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Photograph the plate', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Mananu uses the photo to work out what the food is. The amount comes '
            'from the scale, so there is no guessing at portion size.',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_demoCatalogue.first),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Open camera'),
          ),
          const SizedBox(height: MananuSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Weigh the pan before and after and log what the food actually absorbed.
class _CookingFatSheet extends StatefulWidget {
  const _CookingFatSheet();

  @override
  State<_CookingFatSheet> createState() => _CookingFatSheetState();
}

class _CookingFatSheetState extends State<_CookingFatSheet> {
  double _added = 15;
  double _remaining = 3;
  int _portions = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final absorbed = (_added - _remaining).clamp(0, 999).toDouble();
    final perPortion = absorbed / _portions;
    final kcal = perPortion * 8.84; // olive oil, per gram

    return Padding(
      padding: EdgeInsets.only(
        left: MananuSpacing.xl,
        right: MananuSpacing.xl,
        top: MananuSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + MananuSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cooking oil', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Put the pan on the scale and tare it, add the oil, and read it. '
            'Afterwards, weigh whatever is left in the pan. The difference went '
            'into your food — and it is the one thing a photo can never see.',
            style: MananuType.body.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: MananuSpacing.xl),
          _Slider(
            label: 'Oil added',
            value: _added,
            max: 60,
            suffix: 'g',
            onChanged: (v) => setState(() => _added = v),
          ),
          _Slider(
            label: 'Left in the pan',
            value: _remaining,
            max: 60,
            suffix: 'g',
            onChanged: (v) => setState(() => _remaining = v),
          ),
          _Slider(
            label: 'Portions from this pan',
            value: _portions.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            suffix: '',
            onChanged: (v) => setState(() => _portions = v.round()),
          ),
          const SizedBox(height: MananuSpacing.lg),
          Container(
            padding: const EdgeInsets.all(MananuSpacing.lg),
            decoration: const BoxDecoration(
              color: MananuColors.brassSoft,
              borderRadius: MananuSpacing.radiusMd,
            ),
            child: Text(
              '${perPortion.toStringAsFixed(1)} g of oil per portion — '
              '${kcal.round()} kcal that most apps miss entirely.',
              style: MananuType.bodyStrong.copyWith(color: MananuColors.ink),
            ),
          ),
          const SizedBox(height: MananuSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              CookingFatCapture(
                fat: _oliveOil,
                gramsAdded: _added,
                gramsRemaining: _remaining,
                portions: _portions,
              ),
            ),
            child: const Text('Add to meal'),
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.max,
    required this.suffix,
    required this.onChanged,
    this.min = 0,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: MananuType.caption),
            Text(
              '${value.toStringAsFixed(suffix.isEmpty ? 0 : 1)}$suffix',
              style: MananuType.number,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder catalogue.
//
// Replaced at build time by the embedded offline database generated from UK
// CoFID (Open Government Licence) and USDA FoodData Central (public domain) —
// see scripts/build_food_db.py. Both licences permit redistribution inside the
// app binary, which is why the offline core is built from those two and not
// from a queried commercial API.
// ---------------------------------------------------------------------------

const _oliveOil = FoodItem(
  id: 'cofid:17-100',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100, saturatesG: 14),
  source: NutritionSource.cofid,
);

const _demoCatalogue = <FoodItem>[
  FoodItem(
    id: 'cofid:13-001',
    name: 'Chicken breast, grilled',
    per100g: NutrientsPer100g(kcal: 165, proteinG: 31, fatG: 3.6, carbG: 0),
    source: NutritionSource.cofid,
    state: FoodState.cooked,
  ),
  FoodItem(
    id: 'cofid:11-020',
    name: 'Basmati rice, dry',
    per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
    source: NutritionSource.cofid,
  ),
  _oliveOil,
  FoodItem(
    id: 'cofid:14-060',
    name: 'Greek yogurt, natural',
    per100g: NutrientsPer100g(kcal: 133, proteinG: 5.7, carbG: 4.8, fatG: 10.2),
    source: NutritionSource.cofid,
  ),
  FoodItem(
    id: 'off:5000159461122',
    name: 'Oat porridge, dry',
    brand: 'Own brand',
    per100g: NutrientsPer100g(kcal: 379, proteinG: 11, carbG: 60, fatG: 8),
    source: NutritionSource.openFoodFacts,
  ),
];
