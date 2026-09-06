/// Meals and their weighed components. Reads and writes SQLite only; the UI
/// never waits on the network.
library;

import 'package:drift/drift.dart';

import '../../nutrition/models.dart';
import '../../nutrition/portion.dart';
import '../db/database.dart';
import '../models.dart';

class MealRepository {
  MealRepository(this._db);

  final AppDatabase _db;

  /// Every meal eaten on the local calendar day of [day], oldest first, with
  /// its components. Re-emits when either table changes.
  Stream<List<LoggedMeal>> watchMealsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return watchMealsBetween(start, end);
  }

  Stream<List<LoggedMeal>> watchMealsBetween(DateTime start, DateTime end) {
    final meals = _db.meals;
    final comps = _db.mealComponents;
    final q = _db.select(meals).join([
      leftOuterJoin(
        comps,
        comps.mealId.equalsExp(meals.id) & comps.deletedAt.isNull(),
      ),
    ])
      ..where(
        meals.deletedAt.isNull() &
            meals.eatenAt.isBiggerOrEqualValue(start.toUtc()) &
            meals.eatenAt.isSmallerThanValue(end.toUtc()),
      )
      ..orderBy([
        OrderingTerm.asc(meals.eatenAt),
        OrderingTerm.asc(comps.position),
      ]);

    return q.watch().map((rows) {
      final byMeal = <String, ({Meal meal, List<MealComponent> comps})>{};
      for (final row in rows) {
        final meal = row.readTable(meals);
        final entry =
            byMeal.putIfAbsent(meal.id, () => (meal: meal, comps: []));
        final c = row.readTableOrNull(comps);
        if (c != null) entry.comps.add(c);
      }
      return [
        for (final e in byMeal.values) _toLoggedMeal(e.meal, e.comps),
      ];
    });
  }

  /// Persists a meal and its components as one transaction. Returns the id.
  Future<String> logMeal({
    required List<LoggedComponent> components,
    required DateTime eatenAt,
    required MealSlot slot,
    String? note,
  }) async {
    if (components.isEmpty) {
      throw ArgumentError('a meal needs at least one component');
    }
    final userId = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final mealId = AppDatabase.newId();

    await _db.transaction(() async {
      await _db.into(_db.meals).insert(
            MealsCompanion.insert(
              id: mealId,
              userId: userId,
              eatenAt: eatenAt.toUtc(),
              slot: Value(slot.name),
              note: Value(note),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var i = 0; i < components.length; i++) {
        final c = components[i];
        final n = c.nutrients;
        await _db.into(_db.mealComponents).insert(
              MealComponentsCompanion.insert(
                id: AppDatabase.newId(),
                mealId: mealId,
                userId: userId,
                foodId: Value(c.food.id),
                foodName: c.food.displayName,
                foodSource: Value(encodeNutritionSource(c.food.source)),
                grams: c.grams,
                method: encodePortionMethod(c.method),
                kcal: n.kcal,
                proteinG: Value(n.proteinG),
                carbG: Value(n.carbG),
                fatG: Value(n.fatG),
                sugarG: Value(n.sugarG),
                saturatesG: Value(n.saturatesG),
                fibreG: Value(n.fibreG),
                saltG: Value(n.saltG),
                isCookingFat: Value(c.isCookingFat),
                position: Value(i),
                note: Value(c.note),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
    return mealId;
  }

  /// Tombstones the meal and its components so the deletion syncs.
  Future<void> deleteMeal(String mealId) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.meals)..where((m) => m.id.equals(mealId))).write(
        MealsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncedAt: const Value(null),
        ),
      );
      await (_db.update(_db.mealComponents)
            ..where((c) => c.mealId.equals(mealId)))
          .write(
        MealComponentsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncedAt: const Value(null),
        ),
      );
    });
  }

  /// How many meals are still only on this phone.
  Stream<int> watchUnsyncedCount() {
    final count = _db.meals.id.count();
    final q = _db.selectOnly(_db.meals)
      ..addColumns([count])
      ..where(
        _db.meals.syncedAt.isNull() |
            _db.meals.updatedAt.equalsExp(_db.meals.syncedAt).not(),
      );
    return q.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// `synced_at` holds the `updated_at` of the version the server has, so a
  /// row is synced exactly when the two agree.
  static bool isRowSynced(DateTime updatedAt, DateTime? syncedAt) =>
      syncedAt != null && updatedAt.isAtSameMomentAs(syncedAt);

  LoggedMeal _toLoggedMeal(Meal m, List<MealComponent> comps) => LoggedMeal(
        id: m.id,
        eatenAt: m.eatenAt.toLocal(),
        slot: MealSlot.parse(m.slot),
        components: [for (final c in comps) componentFromRow(c)],
        isSynced: isRowSynced(m.updatedAt, m.syncedAt),
      );

  /// Rebuilds a component from its stored totals. Per-100 g figures are
  /// recovered by scaling back, so a deleted catalogue row cannot change what
  /// was eaten.
  static LoggedComponent componentFromRow(MealComponent c) {
    final f = c.grams <= 0 ? 0.0 : 100.0 / c.grams;
    double? per(double? total) => total == null ? null : total * f;
    return LoggedComponent(
      food: FoodItem(
        id: c.foodId ?? 'component:${c.id}',
        name: c.foodName,
        per100g: NutrientsPer100g(
          kcal: c.kcal * f,
          proteinG: per(c.proteinG),
          carbG: per(c.carbG),
          fatG: per(c.fatG),
          sugarG: per(c.sugarG),
          saturatesG: per(c.saturatesG),
          fibreG: per(c.fibreG),
          saltG: per(c.saltG),
        ),
        source: decodeNutritionSource(c.foodSource),
      ),
      grams: c.grams,
      method: decodePortionMethod(c.method),
      note: c.note,
      isCookingFat: c.isCookingFat,
    );
  }
}
