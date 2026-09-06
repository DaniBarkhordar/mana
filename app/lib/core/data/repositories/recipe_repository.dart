/// Recipes: weigh the ingredients once, weigh the finished dish, then log a
/// portion by weight forever.
///
/// The highest-retention feature in the product: one careful session becomes
/// weeks of one-tap logging, and the reason the scale stays on the counter.
/// The one rule that makes the numbers right is in [Recipe]: the yield is
/// what the *finished dish* weighed, never the sum of the ingredients.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../nutrition/models.dart';
import '../../nutrition/portion.dart';
import '../db/database.dart' as db;
import '../models.dart';

class RecipeRepository {
  RecipeRepository(this._db);

  final db.AppDatabase _db;

  /// Saves the weighed ingredients as a recipe and returns its id.
  Future<String> save({
    required String name,
    required List<LoggedComponent> components,
    required double yieldGrams,
  }) async {
    if (yieldGrams <= 0) throw ArgumentError('yield must be weighed');
    final userId = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final id = db.AppDatabase.newId();
    final recipe = Recipe(
      id: id,
      name: name.trim(),
      components: components,
      totalYieldGrams: yieldGrams,
    );
    final per100 = recipe.per100gOfFinished;
    await _db.into(_db.recipes).insert(
          db.RecipesCompanion.insert(
            id: id,
            userId: userId,
            name: recipe.name,
            yieldGrams: yieldGrams,
            kcal100g: per100.kcal,
            protein100g: Value(per100.proteinG),
            carb100g: Value(per100.carbG),
            fat100g: Value(per100.fatG),
            ingredients: Value(
              jsonEncode([for (final c in components) componentToJson(c)]),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Stream<List<Recipe>> watchAll() {
    final q = _db.select(_db.recipes)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    return q.watch().map((rows) => rows.map(fromRow).toList());
  }

  Future<List<Recipe>> all() async {
    final rows = await (_db.select(_db.recipes)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .get();
    return rows.map(fromRow).toList();
  }

  Future<Recipe?> byId(String id) async {
    final row = await (_db.select(_db.recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : fromRow(row);
  }

  /// A tombstone, so the deletion syncs.
  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      db.RecipesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncedAt: const Value(null),
      ),
    );
  }

  /// Recipes as foods, for search and the weigh flow: per 100 g of the
  /// finished dish, so a served portion is weighed straight off the plate.
  Future<List<FoodItem>> asFoodItems() async =>
      [for (final r in await all()) r.asFoodItem()];

  static Recipe fromRow(db.Recipe row) {
    List<LoggedComponent> components;
    try {
      final list = jsonDecode(row.ingredients) as List;
      components = [
        for (final e in list) componentFromJson(e as Map<String, dynamic>),
      ];
    } on Object {
      components = const [];
    }
    final recipe = Recipe(
      id: row.id,
      name: row.name,
      components: components,
      totalYieldGrams: row.yieldGrams,
    );
    // The stored per-100 g figures are what sync carried; if the ingredient
    // list survived they agree, and if it did not (a row from another
    // client) they are still the truth.
    if (components.isEmpty) {
      return _StoredRecipe(
        recipe,
        NutrientsPer100g(
          kcal: row.kcal100g,
          proteinG: row.protein100g,
          carbG: row.carb100g,
          fatG: row.fat100g,
        ),
      );
    }
    return recipe;
  }

  /// The ingredient list as JSON: enough to rebuild each component with its
  /// nutrition, so a recipe never depends on the catalogue still having the
  /// same row.
  static Map<String, dynamic> componentToJson(LoggedComponent c) => {
        'foodId': c.food.id,
        'name': c.food.displayName,
        'source': encodeNutritionSource(c.food.source),
        'grams': c.grams,
        'method': encodePortionMethod(c.method),
        'isCookingFat': c.isCookingFat,
        'note': c.note,
        'per100g': {
          'kcal': c.food.per100g.kcal,
          'proteinG': c.food.per100g.proteinG,
          'carbG': c.food.per100g.carbG,
          'fatG': c.food.per100g.fatG,
          'sugarG': c.food.per100g.sugarG,
          'saturatesG': c.food.per100g.saturatesG,
          'fibreG': c.food.per100g.fibreG,
          'saltG': c.food.per100g.saltG,
        },
      };

  static LoggedComponent componentFromJson(Map<String, dynamic> j) {
    final n = (j['per100g'] as Map?)?.cast<String, dynamic>() ?? const {};
    double? d(Object? v) => v == null ? null : (v as num).toDouble();
    return LoggedComponent(
      food: FoodItem(
        id: j['foodId'] as String? ?? 'component',
        name: j['name'] as String? ?? 'Ingredient',
        per100g: NutrientsPer100g(
          kcal: d(n['kcal']) ?? 0,
          proteinG: d(n['proteinG']),
          carbG: d(n['carbG']),
          fatG: d(n['fatG']),
          sugarG: d(n['sugarG']),
          saturatesG: d(n['saturatesG']),
          fibreG: d(n['fibreG']),
          saltG: d(n['saltG']),
        ),
        source: decodeNutritionSource(j['source'] as String?),
      ),
      grams: d(j['grams']) ?? 0,
      method: decodePortionMethod(j['method'] as String? ?? 'weighed'),
      note: j['note'] as String?,
      isCookingFat: j['isCookingFat'] == true,
    );
  }
}

/// A recipe whose ingredient list did not survive the trip, carrying the
/// per-100 g figures the row stored instead.
class _StoredRecipe extends Recipe {
  _StoredRecipe(Recipe base, this._per100)
      : super(
          id: base.id,
          name: base.name,
          components: base.components,
          totalYieldGrams: base.totalYieldGrams,
        );

  final NutrientsPer100g _per100;

  @override
  NutrientsPer100g get per100gOfFinished => _per100;
}

/// "We've learned your usual portion": the median of what this person has
/// weighed of a food, once there are enough weighings to mean something.
///
/// This is the calibration a photo app can never do, because it has no
/// ground truth. Five samples is the floor: below that a suggestion is worse
/// than none (the same threshold as [PersonalCalibration.fit]).
class UsualPortion {
  const UsualPortion({
    required this.foodId,
    required this.grams,
    required this.samples,
  });

  final String foodId;
  final double grams;
  final int samples;

  static const minSamples = 5;

  static Future<UsualPortion?> forFood(
    db.AppDatabase database,
    String foodId,
  ) async {
    final rows = await database.customSelect(
      'SELECT grams FROM meal_components '
      'WHERE food_id = ? AND method = ? AND deleted_at IS NULL '
      'ORDER BY created_at DESC LIMIT 30',
      variables: [
        Variable.withString(foodId),
        Variable.withString(encodePortionMethod(PortionMethod.weighed)),
      ],
      readsFrom: {database.mealComponents},
    ).get();
    final grams = [for (final r in rows) r.read<double>('grams')]..sort();
    if (grams.length < minSamples) return null;
    final mid = grams.length ~/ 2;
    final median =
        grams.length.isOdd ? grams[mid] : (grams[mid - 1] + grams[mid]) / 2;
    return UsualPortion(
      foodId: foodId,
      grams: double.parse(median.toStringAsFixed(0)),
      samples: grams.length,
    );
  }

  /// The correction for photo estimates, from stored (estimate, weighed)
  /// pairs, when the schema has both for a food.
  static Future<PersonalCalibration?> calibrationFor(
    db.AppDatabase database,
    String foodId,
  ) async {
    final rows = await database.customSelect(
      'SELECT estimated_grams, grams FROM meal_components '
      'WHERE food_id = ? AND estimated_grams IS NOT NULL AND method = ? '
      'AND deleted_at IS NULL ORDER BY created_at DESC LIMIT 50',
      variables: [
        Variable.withString(foodId),
        Variable.withString(encodePortionMethod(PortionMethod.weighed)),
      ],
      readsFrom: {database.mealComponents},
    ).get();
    return PersonalCalibration.fit(
      foodId: foodId,
      pairs: [
        for (final r in rows)
          (
            estimatedGrams: r.read<double>('estimated_grams'),
            weighedGrams: r.read<double>('grams'),
          ),
      ],
    );
  }
}
