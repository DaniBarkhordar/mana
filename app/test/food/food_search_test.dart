import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/models.dart';
import 'package:mananu/core/data/repositories/meal_repository.dart';
import 'package:mananu/core/data/repositories/user_food_repository.dart';
import 'package:mananu/core/food/food_catalog.dart';
import 'package:mananu/core/food/food_search.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

void main() {
  late AppDatabase db;
  late UserFoodRepository userFoods;
  late FoodCatalog catalog;

  setUp(() {
    db = AppDatabase.memory();
    userFoods = UserFoodRepository(db);
    catalog = FoodCatalog.inMemory();
    catalog.insert(
      id: 'cofid:18-016',
      name: 'Chicken, breast, grilled, meat only',
      source: 'cofid',
      kcal: 148,
    );
    catalog.insert(
      id: 'cofid:1',
      name: 'Chicken tikka masala',
      source: 'cofid',
      kcal: 160,
    );
  });

  tearDown(() async {
    catalog.close();
    await db.close();
  });

  const packChicken = FoodItem(
    id: 'user:new',
    name: 'Chicken tikka masala',
    brand: 'Own brand',
    per100g: NutrientsPer100g(kcal: 150, proteinG: 9),
    source: NutritionSource.userLabel,
  );

  group('UserFoodRepository', () {
    test('saves, finds by barcode, and refreshes rather than duplicates',
        () async {
      final saved = await userFoods.save(
        const FoodItem(
          id: 'off:5000159461122',
          name: 'Porridge Oats',
          brand: 'Quaker',
          barcode: '5000159461122',
          per100g: NutrientsPer100g(kcal: 374),
          source: NutritionSource.openFoodFacts,
        ),
      );
      expect(saved.id, startsWith('user:'));
      expect(
        (await userFoods.byBarcode('5000159461122'))!.name,
        'Porridge Oats',
      );

      await userFoods.save(
        const FoodItem(
          id: 'off:5000159461122',
          name: 'Porridge Oats, jumbo',
          barcode: '5000159461122',
          per100g: NutrientsPer100g(kcal: 375),
          source: NutritionSource.openFoodFacts,
        ),
      );
      final all = await db.select(db.foods).get();
      expect(all, hasLength(1));
      expect(all.single.name, 'Porridge Oats, jumbo');
      expect(all.single.syncedAt, isNull);
    });

    test('search matches name and brand without case or accents', () async {
      await userFoods.save(packChicken);
      expect(await userFoods.search('OWN BRAND'), hasLength(1));
      expect(await userFoods.search('tikka'), hasLength(1));
      expect(await userFoods.search('beef'), isEmpty);
    });

    test('recently logged foods come from meal components, newest first',
        () async {
      final meals = MealRepository(db);
      const rice = FoodItem(
        id: 'cofid:11-020',
        name: 'Rice, basmati, raw',
        per100g: NutrientsPer100g(kcal: 356),
        source: NutritionSource.cofid,
      );
      await meals.logMeal(
        components:
            (WeighSession()..addTared(food: rice, grams: 75)).components,
        eatenAt: DateTime(2026, 9, 5, 8),
        slot: MealSlot.breakfast,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await meals.logMeal(
        components: (WeighSession()
              ..addTared(food: packChicken, grams: 200)
              ..addTared(food: rice, grams: 80))
            .components,
        eatenAt: DateTime(2026, 9, 6, 12),
        slot: MealSlot.lunch,
      );
      final recent = await userFoods.recentlyLogged();
      expect(
        recent.map((f) => f.name),
        ['Own brand Chicken tikka masala', 'Rice, basmati, raw'],
      );
      expect(recent.last.per100g.kcal, closeTo(356, 1e-6));
    });
  });

  group('FoodSearch', () {
    test("the user's own version of a food comes before the catalogue's",
        () async {
      await userFoods.save(packChicken);
      final search = FoodSearch(catalog: catalog, userFoods: userFoods);
      final r = await search.search('chicken');
      expect(r.catalogueAvailable, isTrue);
      expect(r.items.first.source, NutritionSource.userLabel);
      expect(r.items.map((f) => f.id), contains('cofid:18-016'));
      // A branded pack and the generic dish are different foods: both show,
      // the user's own first.
      final tikka = r.items.where((f) => f.name == 'Chicken tikka masala');
      expect(tikka, hasLength(2));
      expect(tikka.first.brand, 'Own brand');
    });

    test('a saved copy of a catalogue food is not shown twice', () async {
      await userFoods.save(
        const FoodItem(
          id: 'user:new',
          name: 'Chicken, breast, grilled, meat only',
          per100g: NutrientsPer100g(kcal: 148),
          source: NutritionSource.cofid,
        ),
      );
      final search = FoodSearch(catalog: catalog, userFoods: userFoods);
      final r = await search.search('chicken breast');
      expect(
        r.items.where((f) => f.name == 'Chicken, breast, grilled, meat only'),
        hasLength(1),
      );
      expect(r.items.first.id, startsWith('user:'));
    });

    test('an empty query is the recent list', () async {
      final search = FoodSearch(catalog: catalog, userFoods: userFoods);
      final r = await search.search('   ');
      expect(r.query, '');
      expect(r.items, isEmpty);
    });

    test('with no catalogue the starter list stands in, and says so', () async {
      const starter = [
        FoodItem(
          id: 'starter:x',
          name: 'Chicken breast, grilled',
          per100g: NutrientsPer100g(kcal: 165),
          source: NutritionSource.estimated,
        ),
      ];
      final search =
          FoodSearch(catalog: null, userFoods: userFoods, fallback: starter);
      final r = await search.search('chick');
      expect(r.catalogueAvailable, isFalse);
      expect(r.items.single.id, 'starter:x');
      final withCatalog =
          FoodSearch(catalog: catalog, userFoods: userFoods, fallback: starter);
      expect(
        (await withCatalog.search('chick'))
            .items
            .any((f) => f.id == 'starter:x'),
        isFalse,
      );
    });
  });
}
