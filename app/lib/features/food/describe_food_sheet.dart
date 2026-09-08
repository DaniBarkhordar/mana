/// The food in words. For when there is no photo worth taking — a plate
/// already half eaten, a takeaway named on the receipt — the user says what
/// it was, the model names the components, and the amount still comes from
/// the scale or from an honest estimate. Identification only, as ever.
library;

import 'package:flutter/material.dart';

import '../../core/data/providers.dart';
import '../../core/food/food_identifier.dart';
import '../../theme/tokens.dart';

class DescribeFoodSheet extends StatefulWidget {
  const DescribeFoodSheet({super.key});

  /// The trimmed description, or null when the user backed out.
  static Future<String?> show(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const DescribeFoodSheet(),
      );

  @override
  State<DescribeFoodSheet> createState() => _DescribeFoodSheetState();
}

class _DescribeFoodSheetState extends State<DescribeFoodSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _trimmed => _text.text.trim();

  void _submit() {
    if (_trimmed.isEmpty) return;
    Navigator.of(context).pop(_trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
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
          const Text('Describe it', style: MananuType.title),
          const SizedBox(height: MananuSpacing.sm),
          Text(
            'Say what was on the plate and Mananu works out the parts. The '
            'amount still comes from the scale, or from what you enter.',
            style: MananuType.body.copyWith(color: muted),
          ),
          const SizedBox(height: MananuSpacing.lg),
          TextField(
            controller: _text,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: IdentifyRequest.maxDescriptionLength,
            maxLines: 3,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Chicken tikka with rice and a naan',
              border: OutlineInputBorder(borderRadius: MananuSpacing.radiusMd),
            ),
          ),
          const SizedBox(height: MananuSpacing.sm),
          // Where the words go, stated plainly. This is all that is sent:
          // no name, no weight, no body data, no photo.
          Text(
            'These words are sent to ${VisionConfig.providerName} to work '
            'out what the food is. Nothing else goes with them.',
            style: MananuType.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: MananuSpacing.lg),
          FilledButton.icon(
            onPressed: _trimmed.isEmpty ? null : _submit,
            icon: const Icon(Icons.short_text),
            label: const Text('Identify'),
          ),
        ],
      ),
    );
  }
}
