import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/nutrition/household_measures.dart';
import 'package:mananu/core/nutrition/models.dart';

FoodItem _food(
  String name, {
  bool per100ml = false,
  List<HouseholdMeasure> measures = const [],
}) =>
    FoodItem(
      id: 'test:$name',
      name: name,
      per100g: const NutrientsPer100g(kcal: 100),
      source: NutritionSource.cofid,
      per100ml: per100ml,
      householdMeasures: measures,
    );

double _grams(FoodItem food, String label) =>
    householdMeasuresFor(food).singleWhere((m) => m.label == label).grams;

void main() {
  group('householdClassOf', () {
    test('sorts common foods into the right class', () {
      expect(householdClassOf(_food('Olive oil')), HouseholdClass.fat);
      expect(householdClassOf(_food('Butter, salted')), HouseholdClass.fat);
      expect(
        householdClassOf(_food('Semi-skimmed milk')),
        HouseholdClass.liquid,
      );
      expect(
        householdClassOf(_food('Bread, white, sliced')),
        HouseholdClass.bread,
      );
      expect(
        householdClassOf(_food('Eggs, chicken, whole')),
        HouseholdClass.egg,
      );
      expect(
        householdClassOf(_food('Cashew nuts')),
        HouseholdClass.nutsAndSnacks,
      );
      expect(householdClassOf(_food('Apple, eating')), HouseholdClass.produce);
      expect(
        householdClassOf(_food('Chicken breast, grilled')),
        HouseholdClass.general,
      );
    });

    test('the tie-breaks go the sensible way', () {
      // Fat before liquid; a one-word "buttermilk" is not butter.
      expect(householdClassOf(_food('Peanut butter')), HouseholdClass.fat);
      expect(householdClassOf(_food('Buttermilk')), HouseholdClass.liquid);
      // Liquid before nuts.
      expect(householdClassOf(_food('Almond milk')), HouseholdClass.liquid);
      // Milk chocolate is not a drink.
      expect(householdClassOf(_food('Milk chocolate')), HouseholdClass.general);
      // Egg noodles and egg fried rice are spoon foods, not eggs.
      expect(householdClassOf(_food('Egg noodles')), HouseholdClass.general);
      expect(householdClassOf(_food('Egg fried rice')), HouseholdClass.general);
    });

    test('a per-100 ml row is a liquid whatever it is called', () {
      expect(
        householdClassOf(_food('Lager, premium', per100ml: true)),
        HouseholdClass.liquid,
      );
    });
  });

  group('householdMeasuresFor', () {
    test('a tablespoon of a water-like liquid is 15 g, a cup 240 g', () {
      final milk = _food('Whole milk');
      expect(_grams(milk, 'Teaspoon'), 5);
      expect(_grams(milk, 'Tablespoon'), 15);
      expect(_grams(milk, 'Cup'), 240);
    });

    test('oil is lighter than water: 15 ml is 14 g', () {
      // 15 ml at 0.92 g/ml is 13.8 g; USDA gives 13.5 g (olive) and 14.2 g
      // (butter) for a tablespoon.
      final oil = _food('Olive oil');
      expect(_grams(oil, 'Tablespoon'), 14);
      expect(_grams(oil, 'Teaspoon'), 5);
      expect(
        householdMeasuresFor(oil).map((m) => m.label),
        isNot(contains('Cup')),
      );
    });

    test('a slice of bread, a medium egg, a handful, a medium piece', () {
      expect(_grams(_food('Bread, wholemeal, sliced'), 'Slice'), 36);
      expect(_grams(_food('Egg, chicken, whole, boiled'), 'Medium egg'), 50);
      expect(_grams(_food('Almonds'), 'Handful'), 30);
      expect(_grams(_food('Banana'), 'Medium piece'), 150);
    });

    test('a general food gets only the spoon measures', () {
      final rice = _food('Rice, white, basmati, boiled');
      expect(
        householdMeasuresFor(rice).map((m) => m.label),
        ['Teaspoon', 'Tablespoon'],
      );
      expect(_grams(rice, 'Tablespoon'), 15);
    });

    test("the pack's own serving comes first and duplicates are dropped", () {
      final crisps = _food(
        'Ready salted crisps',
        measures: const [
          HouseholdMeasure(label: 'Bag (25 g)', grams: 25),
          HouseholdMeasure(label: 'Handful', grams: 28),
          HouseholdMeasure(label: 'Broken', grams: 0),
        ],
      );
      final offered = householdMeasuresFor(crisps);
      expect(offered.map((m) => m.label), ['Bag (25 g)', 'Handful']);
      // The pack's handful wins over the table's.
      expect(offered[1].grams, 28);
    });

    test('every measure in the table has a positive weight and a label', () {
      for (final entry in householdMeasureTable.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key}');
        for (final m in entry.value) {
          expect(m.grams, greaterThan(0));
          expect(m.label.trim(), isNotEmpty);
        }
      }
    });
  });
}
