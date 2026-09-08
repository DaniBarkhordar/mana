import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';
import 'package:mananu/features/home/log_again.dart';

/// "Log again" keeps the foods and grams and tells the truth about how the
/// grams were established the second time.
void main() {
  const rice = FoodItem(
    id: 'cofid:11-020',
    name: 'Basmati rice, dry',
    per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
    source: NutritionSource.cofid,
  );
  const oil = FoodItem(
    id: 'cofid:oil',
    name: 'Olive oil',
    per100g: NutrientsPer100g(kcal: 884, fatG: 100),
    source: NutritionSource.cofid,
  );

  test('a weighed component becomes entered by hand, grams unchanged', () {
    const source = [
      LoggedComponent(
        food: rice,
        grams: 75,
        method: PortionMethod.weighed,
        note: 'from the packet',
      ),
    ];
    final again = componentsForLogAgain(source);
    expect(again, hasLength(1));
    expect(again.single.food.id, rice.id);
    expect(again.single.grams, 75);
    expect(again.single.method, PortionMethod.manualGrams);
    expect(again.single.note, 'from the packet');
    expect(again.single.isCookingFat, isFalse);
    // Same energy: 356 × 0.75 = 267 kcal.
    expect(again.single.nutrients.kcal, closeTo(267, 1e-9));
  });

  test('an estimate keeps its own method', () {
    const source = [
      LoggedComponent(
        food: rice,
        grams: 90,
        method: PortionMethod.householdMeasure,
      ),
      LoggedComponent(
        food: rice,
        grams: 60,
        method: PortionMethod.photoEstimate,
      ),
    ];
    final again = componentsForLogAgain(source);
    expect(again[0].method, PortionMethod.householdMeasure);
    expect(again[1].method, PortionMethod.photoEstimate);
  });

  test('cooking fat stays flagged as cooking fat', () {
    const source = [
      LoggedComponent(
        food: oil,
        grams: 6,
        method: PortionMethod.weighed,
        isCookingFat: true,
      ),
    ];
    final again = componentsForLogAgain(source);
    expect(again.single.isCookingFat, isTrue);
    expect(again.single.method, PortionMethod.manualGrams);
  });

  test('the repeated meal is no longer weighed, and says so', () {
    const source = [
      LoggedComponent(food: rice, grams: 75, method: PortionMethod.weighed),
    ];
    expect(MealTotals.from(source).confidenceLabel, 'Weighed');
    expect(
      MealTotals.from(componentsForLogAgain(source)).confidenceLabel,
      'Estimated',
    );
  });
}
