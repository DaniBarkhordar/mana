/// One search over everything the user can log: their own foods first, then
/// the shipped catalogue. Empty query: what they logged recently.
library;

import '../data/repositories/user_food_repository.dart';
import '../nutrition/models.dart';
import 'food_catalog.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.query,
    required this.items,
    required this.catalogueAvailable,
  });

  final String query;
  final List<FoodItem> items;

  /// False in a build that ships no `core.sqlite`; the sheet says so.
  final bool catalogueAvailable;

  static const empty = FoodSearchResult(
    query: '',
    items: [],
    catalogueAvailable: false,
  );
}

class FoodSearch {
  FoodSearch({
    required this.catalog,
    required this.userFoods,
    this.fallback = const [],
    this.recipes,
  });

  /// Null when the build has no catalogue.
  final FoodCatalog? catalog;
  final UserFoodRepository userFoods;

  /// Searched only when there is no catalogue: the starter list.
  final List<FoodItem> fallback;

  /// The user's recipes as foods (per 100 g of the finished dish). They win
  /// over everything: a person who saved "Mum's dal" wants that one.
  final Future<List<FoodItem>> Function()? recipes;

  Future<FoodSearchResult> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    final saved = await recipes?.call() ?? const <FoodItem>[];
    if (trimmed.isEmpty) {
      final recent = await userFoods.recentlyLogged();
      final seenRecent = recent.map((f) => f.id).toSet();
      return FoodSearchResult(
        query: '',
        items: [
          ...recent,
          for (final r in saved)
            if (!seenRecent.contains(r.id)) r,
        ],
        catalogueAvailable: catalog != null,
      );
    }
    final norm = normaliseFoodName(trimmed);
    final own = [
      for (final r in saved)
        if (normaliseFoodName(r.displayName).contains(norm)) r,
      ...await userFoods.search(trimmed, limit: 8),
    ];
    final fromCatalog = catalog?.search(trimmed, limit: limit) ??
        [
          for (final f in fallback)
            if (normaliseFoodName(f.displayName).contains(norm)) f,
        ];
    // The user's own version of a food wins over the catalogue's.
    final seen = own.map((f) => normaliseFoodName(f.displayName)).toSet();
    final merged = [
      ...own,
      for (final f in fromCatalog)
        if (seen.add(normaliseFoodName(f.displayName))) f,
    ];
    return FoodSearchResult(
      query: trimmed,
      items: merged.take(limit).toList(),
      catalogueAvailable: catalog != null,
    );
  }
}
