/// "From the pack": the user types the label's per-100 g figures in. Reference
/// data in the model's sense — it traces to a printed label, not to a guess —
/// and it is what makes the app usable for any product the datasets miss.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/nutrition/models.dart';
import '../../theme/tokens.dart';

class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet({super.key, this.initialName, this.barcode});

  final String? initialName;

  /// Set when a scan found no product, so the typed food is cached against
  /// the barcode and the next scan is instant.
  final String? barcode;

  static Future<FoodItem?> show(
    BuildContext context, {
    String? initialName,
    String? barcode,
  }) =>
      showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) =>
            AddFoodSheet(initialName: initialName, barcode: barcode),
      );

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName ?? '');
  final _brand = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _sugar = TextEditingController();
  final _fat = TextEditingController();
  final _saturates = TextEditingController();
  final _fibre = TextEditingController();
  final _salt = TextEditingController();
  bool _per100ml = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _kcal,
      _protein,
      _carb,
      _sugar,
      _fat,
      _saturates,
      _fibre,
      _salt,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final services = await ref.read(appServicesProvider.future);
    final saved = await services.userFoods.save(
      FoodItem(
        id: 'user:new',
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        barcode: widget.barcode,
        per100g: NutrientsPer100g(
          kcal: _num(_kcal)!,
          proteinG: _num(_protein),
          carbG: _num(_carb),
          sugarG: _num(_sugar),
          fatG: _num(_fat),
          saturatesG: _num(_saturates),
          fibreG: _num(_fibre),
          saltG: _num(_salt),
        ),
        source: NutritionSource.userLabel,
        per100ml: _per100ml,
      ),
    );
    if (mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: MananuSpacing.xl,
        right: MananuSpacing.xl,
        top: MananuSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + MananuSpacing.xl,
      ),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('From the pack', style: MananuType.title),
            const SizedBox(height: MananuSpacing.sm),
            Text(
              'Copy the nutrition table as printed, per 100 g. Leave anything '
              'the label does not give blank — a blank is honest, a zero is '
              'not.',
              style: MananuType.body.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: MananuSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: widget.initialName == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
            ),
            const SizedBox(height: MananuSpacing.md),
            TextFormField(
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: MananuSpacing.lg),
            _NumberField(
              controller: _kcal,
              label: 'Energy',
              suffix: 'kcal',
              required: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _protein,
                    label: 'Protein',
                    suffix: 'g',
                  ),
                ),
                const SizedBox(width: MananuSpacing.md),
                Expanded(
                  child: _NumberField(
                    controller: _carb,
                    label: 'Carbohydrate',
                    suffix: 'g',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _sugar,
                    label: 'of which sugars',
                    suffix: 'g',
                  ),
                ),
                const SizedBox(width: MananuSpacing.md),
                Expanded(
                  child: _NumberField(
                    controller: _fat,
                    label: 'Fat',
                    suffix: 'g',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _saturates,
                    label: 'of which saturates',
                    suffix: 'g',
                  ),
                ),
                const SizedBox(width: MananuSpacing.md),
                Expanded(
                  child: _NumberField(
                    controller: _fibre,
                    label: 'Fibre',
                    suffix: 'g',
                  ),
                ),
              ],
            ),
            _NumberField(controller: _salt, label: 'Salt', suffix: 'g'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _per100ml,
              onChanged: (v) => setState(() => _per100ml = v),
              title:
                  const Text('Values are per 100 ml', style: MananuType.body),
              subtitle: Text(
                'Drinks. The scale reads grams; for water-like drinks that is '
                'within a few percent.',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: MananuSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving' : 'Save food'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MananuSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(labelText: label, suffixText: suffix),
        validator: (v) {
          final t = (v ?? '').trim();
          if (t.isEmpty) return required ? 'Needed' : null;
          final n = double.tryParse(t.replaceAll(',', '.'));
          if (n == null || n < 0) return 'A number';
          return null;
        },
      ),
    );
  }
}
