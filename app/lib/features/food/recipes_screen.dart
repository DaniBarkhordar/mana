import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../../theme/instruments.dart';
import '../../theme/tokens.dart';

/// Your recipes.
///
/// Each one was weighed once — ingredients in, finished dish out — and from
/// then on a portion is logged by putting the plate on the scale and picking
/// the recipe from search. This screen is the list, with the number that
/// matters (kcal per 100 g of the finished dish) and the way to remove one.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final recipes = ref.watch(recipesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: recipes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(MananuSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MananuMark(height: 24),
                    const SizedBox(height: MananuSpacing.lg),
                    const Text('No recipes yet', style: MananuType.heading),
                    const SizedBox(height: MananuSpacing.sm),
                    Text(
                      'Weigh the ingredients on the Weigh food screen, then '
                      'tap the recipe icon and weigh the finished dish. From '
                      'then on a portion is one search and one weighing.',
                      textAlign: TextAlign.center,
                      style: MananuType.body.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                MananuSpacing.lg,
                MananuSpacing.sm,
                MananuSpacing.lg,
                MananuSpacing.huge,
              ),
              itemCount: recipes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: MananuSpacing.sm),
              itemBuilder: (context, i) {
                final r = recipes[i];
                final per100 = r.per100gOfFinished;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: MananuSpacing.lg,
                      vertical: MananuSpacing.sm,
                    ),
                    title: Text(r.name, style: MananuType.bodyStrong),
                    subtitle: Text(
                      '${per100.kcal.round()} kcal / 100 g · '
                      '${r.totalYieldGrams.round()} g made · '
                      '${r.components.length} '
                      '${r.components.length == 1 ? 'ingredient' : 'ingredients'}',
                      style: MananuType.caption.copyWith(color: muted),
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, r),
                    ),
                    onTap: () => _show(context, r),
                  ),
                );
              },
            ),
    );
  }

  void _show(BuildContext context, Recipe r) {
    final per100 = r.per100gOfFinished;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final muted = scheme.onSurface.withValues(alpha: 0.6);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MananuSpacing.xl,
              0,
              MananuSpacing.xl,
              MananuSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: MananuType.title),
                const SizedBox(height: MananuSpacing.xs),
                Text(
                  'Per 100 g of the finished dish: ${per100.kcal.round()} kcal'
                  '${per100.proteinG == null ? '' : ' · ${per100.proteinG!.toStringAsFixed(0)} g protein'}'
                  '${per100.carbG == null ? '' : ' · ${per100.carbG!.toStringAsFixed(0)} g carbs'}'
                  '${per100.fatG == null ? '' : ' · ${per100.fatG!.toStringAsFixed(0)} g fat'}',
                  style: MananuType.caption.copyWith(color: muted),
                ),
                const SizedBox(height: MananuSpacing.lg),
                for (final c in r.components)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.food.displayName,
                            style: MananuType.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${c.grams.toStringAsFixed(0)} g',
                          style: MananuType.number,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: MananuSpacing.lg),
                Text(
                  'Made ${r.totalYieldGrams.round()} g. To log a portion, put '
                  'the plate on the scale and search for "${r.name}".',
                  style: MananuType.caption.copyWith(color: muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Recipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${r.name}?'),
        content: const Text('Meals already logged from it are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: MananuColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final services = await ref.read(appServicesProvider.future);
    await services.recipes.delete(r.id);
  }
}
