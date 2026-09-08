/// Grams without a scale. For the person whose scale has not arrived, the
/// restaurant plate, or a number that needs correcting after capture.
///
/// The sheet never lets an entered figure look weighed: it is logged with
/// [PortionMethod.householdMeasure] when a chip supplied it and
/// [PortionMethod.manualGrams] when the user typed it, and the tile shows the
/// "Estimated" badge either way. The quick picks come from the small,
/// sourced table in `core/nutrition/household_measures.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/nutrition/household_measures.dart';
import '../../core/nutrition/models.dart';
import '../../theme/tokens.dart';

/// What the sheet hands back: a number, and how honest it is.
class ManualPortion {
  const ManualPortion({
    required this.grams,
    required this.method,
    this.note,
  });

  final double grams;
  final PortionMethod method;

  /// "One tablespoon", so the tile says where the number came from.
  final String? note;
}

class EnterGramsSheet extends StatefulWidget {
  const EnterGramsSheet({super.key, required this.food, this.initialGrams});

  final FoodItem food;

  /// Set when correcting a component that is already in the meal.
  final double? initialGrams;

  static Future<ManualPortion?> show(
    BuildContext context, {
    required FoodItem food,
    double? initialGrams,
  }) =>
      showModalBottomSheet<ManualPortion>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => EnterGramsSheet(food: food, initialGrams: initialGrams),
      );

  @override
  State<EnterGramsSheet> createState() => _EnterGramsSheetState();
}

class _EnterGramsSheetState extends State<EnterGramsSheet> {
  late final TextEditingController _grams = TextEditingController(
    text: widget.initialGrams == null ? '' : _format(widget.initialGrams!),
  );

  /// The chip the number came from, or null once the user has typed over it.
  HouseholdMeasure? _measure;

  bool get _editing => widget.initialGrams != null;

  double get _value =>
      double.tryParse(_grams.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  static String _format(double g) =>
      g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1);

  void _pick(HouseholdMeasure m) {
    setState(() {
      _measure = m;
      _grams.text = _format(m.grams);
    });
  }

  void _typed(String _) => setState(() => _measure = null);

  void _submit() {
    final grams = _value;
    if (grams <= 0) return;
    final measure = _measure;
    Navigator.of(context).pop(
      ManualPortion(
        grams: grams,
        method: measure == null
            ? PortionMethod.manualGrams
            : PortionMethod.householdMeasure,
        note: measure == null ? null : 'One ${measure.label.toLowerCase()}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final measures = householdMeasuresFor(widget.food);
    final value = _value;

    return Padding(
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
          Text(
            widget.food.displayName,
            style: MananuType.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            _editing
                ? 'Change the amount. An entered number is an estimate, and '
                    'it stays marked as one.'
                : 'No scale, so this is an estimate. It is marked as one, '
                    'and it counts for less in the total than a weighed '
                    'amount would.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.xl),
          TextField(
            controller: _grams,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: MananuType.display.copyWith(color: scheme.onSurface),
            onChanged: _typed,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: MananuType.display.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.25),
              ),
              suffixText: 'g',
              suffixStyle: MananuType.heading.copyWith(color: muted),
              border: const OutlineInputBorder(
                borderRadius: MananuSpacing.radiusMd,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MananuSpacing.lg,
                vertical: MananuSpacing.lg,
              ),
            ),
          ),
          if (measures.isNotEmpty) ...[
            const SizedBox(height: MananuSpacing.lg),
            Text(
              'QUICK PICKS',
              style: MananuType.label.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: MananuSpacing.sm),
            Wrap(
              spacing: MananuSpacing.sm,
              runSpacing: MananuSpacing.sm,
              children: [
                for (final m in measures)
                  ChoiceChip(
                    label: Text('${m.label} · ${_format(m.grams)} g'),
                    labelStyle: MananuType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    selected: _measure == m,
                    side: BorderSide(color: scheme.outline),
                    onSelected: (_) => _pick(m),
                  ),
              ],
            ),
          ],
          const SizedBox(height: MananuSpacing.lg),
          Row(
            children: [
              const ProvenanceBadge(weighed: false),
              const SizedBox(width: MananuSpacing.sm),
              Expanded(
                child: Text(
                  _measure == null
                      ? 'Entered by hand'
                      : 'One ${_measure!.label.toLowerCase()}, from a '
                          'standard table',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: MananuSpacing.lg),
          FilledButton(
            onPressed: value > 0 ? _submit : null,
            child: Text(
              value > 0
                  ? '${_editing ? 'Save' : 'Add'} ${_format(value)} g'
                  : 'Enter an amount',
            ),
          ),
        ],
      ),
    );
  }
}
