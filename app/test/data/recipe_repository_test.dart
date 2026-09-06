import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/db/database.dart' as db;
import 'package:mananu/core/data/providers.dart';
import 'package:mananu/core/food/food_search.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

const _rice = FoodItem(
  id: 'cofid:rice-dry',
  name: 'Rice, basmati, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.cofid,
);
const _oil = FoodItem(
  id: 'cofid:oil',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100),
  source: NutritionSource.cofid,
);

void main() {
  late AppServices s;
  late RecipeRepository recipes;

  setUp(() {
    s = AppServices.inMemory();
    recipes = RecipeRepository(s.db);
  });
  tearDown(() => s.db.close());

  test('a recipe is per 100 g of the finished dish, not of the ingredients',
      () async {
    final session = WeighSession()
      ..addTared(food: _rice, grams: 200)
      ..addTared(food: _oil, grams: 10);
    // 200 g dry rice + 10 g oil = 712 + 88.4 = 800.4 kcal. Cooked, it weighs
    // 610 g (the water), so 131 kcal / 100 g of what goes on the plate.
    final id = await recipes.save(
      name: 'Pilau',
      components: session.components,
      yieldGrams: 610,
    );
    final back = (await recipes.byId(id))!;
    expect(back.name, 'Pilau');
    expect(back.components, hasLength(2));
    expect(back.totalNutrients.kcal, closeTo(800.4, 0.01));
    expect(back.per100gOfFinished.kcal, closeTo(131.2, 0.1));

    final food = back.asFoodItem();
    expect(food.id, 'recipe:$id');
    expect(food.source, NutritionSource.userRecipe);
    expect(food.state, FoodState.cooked);
    expect(back.serving(180).nutrients.kcal, closeTo(236.2, 0.2));

    final row = await s.db.select(s.db.recipes).getSingle();
    expect(row.kcal100g, closeTo(131.2, 0.1));
    expect(row.ingredients, contains('cofid:rice-dry'));
  });

  test('the yield must be weighed', () {
    expect(
      () => recipes.save(name: 'x', components: const [], yieldGrams: 0),
      throwsArgumentError,
    );
  });

  test('recipes show up in search, own first, and a deleted one does not',
      () async {
    final session = WeighSession()..addTared(food: _rice, grams: 100);
    final id = await recipes.save(
      name: 'Rice pilau',
      components: session.components,
      yieldGrams: 300,
    );
    final search = FoodSearch(
      catalog: null,
      userFoods: s.userFoods,
      fallback: const [_rice],
      recipes: recipes.asFoodItems,
    );
    final result = await search.search('rice');
    expect(result.items.first.name, 'Rice pilau');
    expect(result.items.map((f) => f.name), contains('Rice, basmati, dry'));

    await recipes.delete(id);
    expect((await search.search('rice')).items.first.name, isNot('Rice pilau'));
    expect(await recipes.all(), isEmpty);
    // Tombstoned, not gone: sync carries the deletion.
    final row = await s.db.select(s.db.recipes).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.syncedAt, isNull);
  });

  test('a row without its ingredient list still knows its nutrition', () {
    final recipe = RecipeRepository.fromRow(
      db.Recipe(
        id: 'r',
        userId: 'u',
        name: 'From another phone',
        yieldGrams: 500,
        kcal100g: 150,
        protein100g: 9,
        carb100g: null,
        fat100g: 5,
        ingredients: 'not json',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        syncedAt: null,
        deletedAt: null,
      ),
    );
    expect(recipe.components, isEmpty);
    expect(recipe.per100gOfFinished.kcal, 150);
    expect(recipe.per100gOfFinished.proteinG, 9);
  });

  test('the usual portion appears after five weighings, as the median',
      () async {
    for (final g in [70.0, 80.0, 75.0, 400.0]) {
      final session = WeighSession()..addTared(food: _rice, grams: g);
      await s.meals.logMeal(
        components: session.components,
        eatenAt: DateTime(2026, 9, 1, 12),
        slot: MealSlot.lunch,
      );
    }
    expect(await UsualPortion.forFood(s.db, _rice.id), isNull);

    final session = WeighSession()..addTared(food: _rice, grams: 78);
    await s.meals.logMeal(
      components: session.components,
      eatenAt: DateTime(2026, 9, 2, 12),
      slot: MealSlot.lunch,
    );
    final usual = (await UsualPortion.forFood(s.db, _rice.id))!;
    expect(usual.samples, 5);
    // 70, 75, 78, 80, 400 → the outlier does not move the median.
    expect(usual.grams, 78);

    // An estimated portion does not count as a weighing.
    final guessed = WeighSession()
      ..addUnweighed(
        food: _rice,
        grams: 500,
        method: PortionMethod.householdMeasure,
      );
    await s.meals.logMeal(
      components: guessed.components,
      eatenAt: DateTime(2026, 9, 3, 12),
      slot: MealSlot.lunch,
    );
    expect((await UsualPortion.forFood(s.db, _rice.id))!.samples, 5);
  });

  test('calibration is fitted from stored estimate/weighed pairs', () async {
    final userId = await s.db.localUserId();
    final now = DateTime.now().toUtc();
    await s.db.into(s.db.meals).insert(
          db.MealsCompanion.insert(
            id: 'm',
            userId: userId,
            eatenAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (var i = 0; i < 5; i++) {
      await s.db.into(s.db.mealComponents).insert(
            db.MealComponentsCompanion.insert(
              id: 'c$i',
              mealId: 'm',
              userId: userId,
              foodId: const Value('cofid:rice-dry'),
              foodName: 'Rice',
              grams: 120,
              method: 'weighed',
              kcal: 100,
              estimatedGrams: const Value(100),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    final cal = (await UsualPortion.calibrationFor(s.db, 'cofid:rice-dry'))!;
    expect(cal.samples, 5);
    expect(cal.meanRatio, closeTo(1.2, 1e-9));
    expect(cal.correct(100), closeTo(120, 1e-9));
  });
}
