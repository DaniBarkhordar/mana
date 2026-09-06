/// The user's own foods: typed in from a pack, cached from a barcode lookup,
/// or saved from a recipe. Writable, synced, and searched alongside the
/// read-only catalogue.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../food/food_catalog.dart' show normaliseFoodName;
import '../../nutrition/models.dart';
import '../db/database.dart';
import '../models.dart';

class UserFoodRepository {
  UserFoodRepository(this._db);

  final AppDatabase _db;

  /// Saves or updates. The id is kept when the item already has a `user:`
  /// id, so a re-scan of the same barcode refreshes rather than duplicates.
  Future<FoodItem> save(FoodItem food) async {
    final userId = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final existing =
        food.barcode == null ? null : await byBarcode(food.barcode!);
    final id = existing?.id ??
        (food.id.startsWith('user:') ? food.id : 'user:${AppDatabase.newId()}');
    final n = food.per100g;
    final created = existing == null
        ? now
        : (await (_db.select(_db.foods)..where((f) => f.id.equals(id)))
                .getSingleOrNull())
            ?.createdAt;
    await _db.into(_db.foods).insertOnConflictUpdate(
          FoodsCompanion(
            id: Value(id),
            userId: Value(userId),
            name: Value(food.name),
            brand: Value(food.brand),
            barcode: Value(food.barcode),
            source: Value(encodeNutritionSource(food.source)),
            isCooked: Value(food.state == FoodState.cooked),
            kcal100g: Value(n.kcal),
            protein100g: Value(n.proteinG),
            carb100g: Value(n.carbG),
            sugar100g: Value(n.sugarG),
            fat100g: Value(n.fatG),
            saturates100g: Value(n.saturatesG),
            fibre100g: Value(n.fibreG),
            salt100g: Value(n.saltG),
            householdMeasures: Value(
              jsonEncode([
                for (final m in food.householdMeasures)
                  {'label': m.label, 'grams': m.grams},
              ]),
            ),
            createdAt: Value(created ?? now),
            updatedAt: Value(now),
            syncedAt: const Value(null),
            deletedAt: const Value(null),
          ),
        );
    return _toFood(
      await (_db.select(_db.foods)..where((f) => f.id.equals(id))).getSingle(),
    );
  }

  Future<FoodItem?> byBarcode(String barcode) async {
    final row = await (_db.select(_db.foods)
          ..where((f) => f.barcode.equals(barcode) & f.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toFood(row);
  }

  Future<FoodItem?> byId(String id) async {
    final row = await (_db.select(_db.foods)
          ..where((f) => f.id.equals(id) & f.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toFood(row);
  }

  /// Case- and accent-insensitive substring match over name and brand. The
  /// user's own list is short, so no index is needed.
  Future<List<FoodItem>> search(String query, {int limit = 20}) async {
    final norm = normaliseFoodName(query);
    final rows = await (_db.select(_db.foods)
          ..where((f) => f.deletedAt.isNull())
          ..orderBy([(f) => OrderingTerm.desc(f.updatedAt)]))
        .get();
    final hits = <FoodItem>[];
    for (final r in rows) {
      final hay = normaliseFoodName('${r.brand ?? ''} ${r.name}');
      if (norm.isEmpty || hay.contains(norm)) hits.add(_toFood(r));
      if (hits.length >= limit) break;
    }
    return hits;
  }

  /// Foods the user has logged most recently, newest first, deduplicated by
  /// name. Rebuilt from meal components, so it works before any food has
  /// been saved and after the catalogue changes.
  Future<List<FoodItem>> recentlyLogged({int limit = 12}) async {
    final rows = await (_db.select(_db.mealComponents)
          ..where((c) => c.deletedAt.isNull() & c.isCookingFat.equals(false))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
          ..limit(200))
        .get();
    final seen = <String>{};
    final out = <FoodItem>[];
    for (final c in rows) {
      final key = normaliseFoodName(c.foodName);
      if (!seen.add(key)) continue;
      final f = c.grams <= 0 ? 0.0 : 100.0 / c.grams;
      double? per(double? total) => total == null ? null : total * f;
      out.add(
        FoodItem(
          id: c.foodId ?? 'component:${c.id}',
          name: c.foodName,
          per100g: NutrientsPer100g(
            kcal: c.kcal * f,
            proteinG: per(c.proteinG),
            carbG: per(c.carbG),
            sugarG: per(c.sugarG),
            fatG: per(c.fatG),
            saturatesG: per(c.saturatesG),
            fibreG: per(c.fibreG),
            saltG: per(c.saltG),
          ),
          source: decodeNutritionSource(c.foodSource),
        ),
      );
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.foods)..where((f) => f.id.equals(id))).write(
      FoodsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncedAt: const Value(null),
      ),
    );
  }

  static FoodItem _toFood(Food r) {
    final measures = <HouseholdMeasure>[];
    try {
      final decoded = jsonDecode(r.householdMeasures);
      if (decoded is List) {
        for (final m in decoded) {
          if (m is Map && m['label'] is String && m['grams'] is num) {
            measures.add(
              HouseholdMeasure(
                label: m['label'] as String,
                grams: (m['grams'] as num).toDouble(),
              ),
            );
          }
        }
      }
    } on FormatException {
      // A malformed list is not worth failing a search over.
    }
    return FoodItem(
      id: r.id,
      name: r.name,
      brand: r.brand,
      barcode: r.barcode,
      per100g: NutrientsPer100g(
        kcal: r.kcal100g,
        proteinG: r.protein100g,
        carbG: r.carb100g,
        sugarG: r.sugar100g,
        fatG: r.fat100g,
        saturatesG: r.saturates100g,
        fibreG: r.fibre100g,
        saltG: r.salt100g,
      ),
      source: decodeNutritionSource(r.source),
      state: r.isCooked ? FoodState.cooked : FoodState.asPurchased,
      householdMeasures: measures,
    );
  }
}
