/// Pick a food: the user's own foods and recipes first, then the catalogue,
/// with a barcode scan and "from the pack" for anything the datasets miss.
///
/// Its own file because two flows need it — the weigh screen's Search, and
/// the cooking-fat sheet choosing which oil or butter went into the pan — and
/// the second must use the same index, so butter is butter's figures and
/// never a generic "oil".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../core/food/food_search.dart';
import '../../core/nutrition/models.dart';
import '../../theme/tokens.dart';
import 'add_food_sheet.dart';
import 'barcode_scan_screen.dart';

class FoodSearchSheet extends ConsumerStatefulWidget {
  const FoodSearchSheet({super.key});

  /// The chosen food, or null when the user backed out.
  static Future<FoodItem?> show(BuildContext context) =>
      showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const FoodSearchSheet(),
      );

  @override
  ConsumerState<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<FoodSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  FoodSearchResult _result = FoodSearchResult.empty;
  bool _busy = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    unawaited(_run(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () => _run(value));
  }

  /// Local index; the whole round trip is a few milliseconds. Results for a
  /// stale query are dropped so fast typing never shows the wrong list.
  Future<void> _run(String query) async {
    final search = await ref.read(foodSearchProvider.future);
    final result = await search.search(query);
    if (!mounted || _controller.text.trim() != query.trim()) return;
    setState(() => _result = result);
  }

  /// Scan, then: the user's own cache, then Open Food Facts, then the form.
  Future<void> _scanBarcode() async {
    final code = await BarcodeScanScreen.scan(context);
    if (code == null || !mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    final services = await ref.read(appServicesProvider.future);
    var food = await services.userFoods.byBarcode(code);
    if (food == null) {
      final looked = await ref.read(openFoodFactsProvider).lookup(code);
      if (looked != null) food = await services.userFoods.save(looked);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (food != null) {
      Navigator.of(context).pop(food);
      return;
    }
    setState(
      () => _notice = 'No match for that barcode. Add it from the pack once '
          'and it is remembered.',
    );
    final added = await AddFoodSheet.show(context, barcode: code);
    if (added != null && mounted) Navigator.of(context).pop(added);
  }

  Future<void> _addFromPack() async {
    final added = await AddFoodSheet.show(
      context,
      initialName:
          _controller.text.trim().isEmpty ? null : _controller.text.trim(),
    );
    if (added != null && mounted) Navigator.of(context).pop(added);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _result.items;
    final query = _controller.text.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MananuSpacing.lg,
              MananuSpacing.sm,
              MananuSpacing.lg,
              MananuSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search foods',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: MananuSpacing.radiusMd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MananuSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Scan a barcode',
                  onPressed: _busy ? null : _scanBarcode,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                ),
              ],
            ),
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.lg,
                0,
                MananuSpacing.lg,
                MananuSpacing.sm,
              ),
              child: Text(
                _notice!,
                style: MananuType.caption.copyWith(color: MananuColors.warning),
              ),
            ),
          if (!_result.catalogueAvailable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.lg,
                0,
                MananuSpacing.lg,
                MananuSpacing.sm,
              ),
              child: Text(
                'This build has no food database yet, so search covers your '
                'own foods and a small starter list.',
                style: MananuType.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          if (query.isEmpty && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.xl,
                MananuSpacing.xs,
                MananuSpacing.xl,
                MananuSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RECENT',
                  style: MananuType.label.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? _NoResults(query: query)
                : ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, i) => _FoodResultTile(
                      food: items[i],
                      onTap: () => Navigator.of(context).pop(items[i]),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MananuSpacing.lg,
              MananuSpacing.sm,
              MananuSpacing.lg,
              MediaQuery.of(context).viewInsets.bottom + MananuSpacing.lg,
            ),
            child: OutlinedButton.icon(
              onPressed: _addFromPack,
              icon: const Icon(Icons.edit_note),
              label: Text(
                query.isEmpty
                    ? 'Add a food from the pack'
                    : "Add '$query' from the pack",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodResultTile extends ConsumerWidget {
  const _FoodResultTile({required this.food, required this.onTap});

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final n = food.per100g;
    // "We've learned your usual portion": the median of this person's own
    // weighings, once there are five. Ground truth a photo app never has.
    final usual = ref.watch(usualPortionProvider(food.id)).valueOrNull;
    final parts = <String>[
      '${n.kcal.round()} kcal / 100 ${food.per100ml ? 'ml' : 'g'}',
      if (n.proteinG != null) '${n.proteinG!.toStringAsFixed(0)} g protein',
      food.source.label,
      if (usual != null)
        'usually ${usual.grams.toStringAsFixed(0)} g (${usual.samples} weighings)',
    ];
    return ListTile(
      title: Text(
        food.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: MananuType.body,
      ),
      subtitle: Text(
        parts.join(' · '),
        style: MananuType.caption.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: food.source.isReferenceData
          ? null
          : const ProvenanceBadge(weighed: false, dense: true),
      onTap: onTap,
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MananuSpacing.xxl),
        child: Text(
          query.isEmpty
              ? 'Type a food, or scan the barcode on the pack.'
              : "Nothing called '$query'. Try a shorter word, scan the "
                  'barcode, or add it from the pack.',
          textAlign: TextAlign.center,
          style: MananuType.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
