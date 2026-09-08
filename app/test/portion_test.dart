import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/nutrition/models.dart';
import 'package:mananu/core/nutrition/portion.dart';

const chicken = FoodItem(
  id: 'cofid:13-001',
  name: 'Chicken breast, raw',
  per100g: NutrientsPer100g(kcal: 106, proteinG: 24, fatG: 1.1, carbG: 0),
  source: NutritionSource.cofid,
);

const riceDry = FoodItem(
  id: 'cofid:11-020',
  name: 'Basmati rice, dry',
  per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
  source: NutritionSource.cofid,
);

const oliveOil = FoodItem(
  id: 'cofid:17-100',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100),
  source: NutritionSource.cofid,
);

const guessedSalad = FoodItem(
  id: 'est:1',
  name: 'Side salad',
  per100g: NutrientsPer100g(kcal: 90, proteinG: 2, carbG: 5, fatG: 7),
  source: NutritionSource.estimated,
);

void main() {
  group('NutrientsPer100g', () {
    test('scales linearly with grams', () {
      final n = chicken.per100g.scaled(150 / 100);
      expect(n.kcal, closeTo(159, 1e-9));
      expect(n.proteinG, closeTo(36, 1e-9));
    });

    test('a missing field stays missing rather than becoming a zero', () {
      // A blank in a reference dataset is not the same as a measured zero, and
      // coercing it is how a food log quietly under-reports.
      const a = NutrientsPer100g(kcal: 100, proteinG: 5);
      const b = NutrientsPer100g(kcal: 50);
      final sum = a + b;
      expect(sum.kcal, 150);
      expect(sum.proteinG, 5);
      expect(sum.fibreG, isNull);
    });

    test('flags a row whose stated energy contradicts its own macros', () {
      // 10g protein + 10g carb + 10g fat = 170 kcal by Atwater, not 400.
      const bad = NutrientsPer100g(
        kcal: 400,
        proteinG: 10,
        carbG: 10,
        fatG: 10,
      );
      expect(bad.isInternallyInconsistent, isTrue);
      expect(chicken.per100g.isInternallyInconsistent, isFalse);
    });
  });

  group('WeighSession running tare', () {
    test('captures each ingredient from the change in total weight', () {
      final s = WeighSession();
      // Bowl tared to zero, then ingredients added one at a time.
      s.addFromRunningTotal(food: riceDry, totalOnScaleGrams: 75);
      s.addFromRunningTotal(food: chicken, totalOnScaleGrams: 235);

      expect(s.components.length, 2);
      expect(s.components[0].grams, closeTo(75, 1e-9));
      expect(s.components[1].grams, closeTo(160, 1e-9));
      expect(s.platformGrams, closeTo(235, 1e-9));
    });

    test('refuses to log a negative ingredient when something is removed', () {
      final s = WeighSession();
      s.addFromRunningTotal(food: riceDry, totalOnScaleGrams: 75);
      final delta = s.addFromRunningTotal(food: chicken, totalOnScaleGrams: 60);
      expect(delta, lessThan(0));
      expect(s.components.length, 1);
    });

    test('everything captured this way is marked weighed', () {
      final s = WeighSession();
      s.addFromRunningTotal(food: riceDry, totalOnScaleGrams: 75);
      expect(s.components.single.method, PortionMethod.weighed);
    });
  });

  group('Cooking fat', () {
    test('logs what the food absorbed, not what went in the pan', () {
      const capture = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 20,
        gramsRemaining: 6,
        portions: 2,
      );
      expect(capture.gramsAbsorbed, closeTo(14, 1e-9));
      expect(capture.gramsPerPortion, closeTo(7, 1e-9));

      final c = capture.componentForOnePortion();
      // 7 g of olive oil = 61.88 kcal. This is the line item no photo app can
      // produce, and the published error it targets is 250-345 kcal per meal
      // driven mainly by fat.
      expect(c.nutrients.kcal, closeTo(61.88, 0.01));
      expect(c.method, PortionMethod.weighed);
      expect(c.note, contains('2 portions'));
    });

    test('never returns a negative absorption', () {
      const capture = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 10,
        gramsRemaining: 14, // user weighed the pan itself by mistake
        portions: 1,
      );
      expect(capture.gramsAbsorbed, 0);
    });

    test('the capture method travels into the component', () {
      // Weighed is the default: the scale read both pan readings.
      const weighed = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 20,
        gramsRemaining: 6,
        portions: 2,
      );
      expect(weighed.method, PortionMethod.weighed);
      expect(weighed.componentForOnePortion().method, PortionMethod.weighed);

      // Typed without a scale: the same grams, the same kcal, but never
      // allowed to look weighed.
      const typed = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 20,
        gramsRemaining: 6,
        portions: 2,
        method: PortionMethod.manualGrams,
      );
      final c = typed.componentForOnePortion();
      expect(c.method, PortionMethod.manualGrams);
      expect(c.isCookingFat, isTrue);
      expect(c.grams, closeTo(7, 1e-9));
      expect(c.nutrients.kcal, closeTo(61.88, 0.01));
      // The typed one carries the hand-entered quantity error, so its band
      // is wider than the weighed one's for the same grams.
      expect(
        c.energyErrorKcal,
        greaterThan(weighed.componentForOnePortion().energyErrorKcal),
      );
    });

    test('only a weighed capture counts towards the weighed share', () {
      const weighed = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 20,
        gramsRemaining: 6,
        portions: 2,
      );
      const typed = CookingFatCapture(
        fat: oliveOil,
        gramsAdded: 20,
        gramsRemaining: 6,
        portions: 2,
        method: PortionMethod.manualGrams,
      );
      expect(
        (WeighSession()..addCookingFat(weighed)).totals().weighedFraction,
        closeTo(1, 1e-9),
      );
      expect(
        (WeighSession()..addCookingFat(typed)).totals().weighedFraction,
        0,
      );
    });

    test('a pending pan completes into a capture with what is left', () {
      const pending = PendingCookingFat(
        fat: oliveOil,
        gramsAdded: 15,
        portions: 1,
      );
      final capture = pending.complete(gramsRemaining: 3, portions: 2);
      expect(capture.gramsAdded, 15);
      expect(capture.gramsRemaining, 3);
      expect(capture.portions, 2);
      expect(capture.method, PortionMethod.weighed);
      // 12 g across two portions: 6 g, 6 × 8.84 = 53.04 kcal.
      expect(capture.gramsPerPortion, closeTo(6, 1e-9));
      expect(
        capture.componentForOnePortion().nutrients.kcal,
        closeTo(53.04, 1e-6),
      );
      // Portions default to the pan's own count when not overridden.
      expect(pending.complete(gramsRemaining: 3).portions, 1);
    });
  });

  group('Yield factors', () {
    test('converts a plated cooked weight back to its raw equivalent', () {
      final rice = YieldFactor.lookup('rice_white_dry')!;
      // 225 g of cooked rice came from 75 g dry at a factor of 3.0.
      expect(rice.cookedToRaw(225), closeTo(75, 1e-9));
      expect(rice.rawToCooked(75), closeTo(225, 1e-9));
    });

    test('meat loses mass rather than gaining it', () {
      final chickenYield = YieldFactor.lookup('chicken_breast_raw')!;
      expect(chickenYield.cookedPerRaw, lessThan(1.0));
      expect(chickenYield.rawToCooked(200), closeTo(146, 1e-9));
    });

    test('logging cooked rice against a dry row would triple the calories', () {
      // The error this table exists to prevent.
      final asIfDry = riceDry.per100g.scaled(225 / 100).kcal;
      final correct = riceDry.per100g.scaled(75 / 100).kcal;
      expect(asIfDry / correct, closeTo(3.0, 1e-9));
      expect(asIfDry - correct, greaterThan(500));
    });
  });

  group('MealTotals', () {
    test('sums nutrients across components', () {
      final s = WeighSession()
        ..addTared(food: riceDry, grams: 75)
        ..addTared(food: chicken, grams: 160);
      final t = s.totals();
      // 356*0.75 = 267, 106*1.60 = 169.6
      expect(t.kcal, closeTo(436.6, 0.01));
      expect(t.totalGrams, closeTo(235, 1e-9));
    });

    test('weighed fraction is by calories, not by item count', () {
      // One small weighed item and one large guess must not read as "50%".
      final s = WeighSession()
        ..addTared(food: riceDry, grams: 10) // 35.6 kcal, weighed
        ..addUnweighed(
          food: guessedSalad,
          grams: 400, // 360 kcal, guessed
          method: PortionMethod.photoEstimate,
        );
      final t = s.totals();
      expect(t.weighedFraction, closeTo(35.6 / (35.6 + 360), 0.001));
      expect(t.weighedFraction, lessThan(0.15));
      expect(t.confidenceLabel, 'Partly weighed');
    });

    test('an all-weighed meal reads as weighed with a tight band', () {
      final s = WeighSession()
        ..addTared(food: riceDry, grams: 75)
        ..addTared(food: chicken, grams: 160);
      final t = s.totals();
      expect(t.confidenceLabel, 'Weighed');
      // Reference data plus a measured quantity: identification error dominates
      // and stays small.
      expect(t.relativeError, lessThan(0.08));
    });

    test('a photo-estimated meal carries a visibly wider band', () {
      final s = WeighSession()
        ..addUnweighed(
          food: guessedSalad,
          grams: 300,
          method: PortionMethod.photoEstimate,
        );
      final t = s.totals();
      expect(t.relativeError, greaterThan(0.25));
      expect(t.confidenceLabel, 'Estimated');
    });

    test('errors combine in quadrature, not by addition', () {
      // Two independent 10% errors give ~14%, not 20%.
      final s = WeighSession()
        ..addTared(food: riceDry, grams: 100)
        ..addTared(food: riceDry, grams: 100);
      final one =
          (WeighSession()..addTared(food: riceDry, grams: 100)).totals();
      final two = s.totals();
      expect(two.energyErrorKcal, lessThan(one.energyErrorKcal * 2));
      expect(two.energyErrorKcal, greaterThan(one.energyErrorKcal));
    });

    test('an empty meal does not divide by zero', () {
      final t = WeighSession().totals();
      expect(t.kcal, 0);
      expect(t.relativeError, 0);
      expect(t.weighedFraction, 0);
    });
  });

  group('Recipe', () {
    test('per-100g uses the weighed finished dish, not the ingredient sum', () {
      // 500 g of ingredients cooked down to 400 g. Using 500 would understate
      // the concentration by 20% on every portion, forever.
      const recipe = Recipe(
        id: 'r1',
        name: 'Chicken and rice',
        components: [
          LoggedComponent(
            food: riceDry,
            grams: 150,
            method: PortionMethod.weighed,
          ),
          LoggedComponent(
            food: chicken,
            grams: 350,
            method: PortionMethod.weighed,
          ),
        ],
        totalYieldGrams: 400,
      );
      // 356*1.5 = 534, 106*3.5 = 371 -> 905 kcal over 400 g
      expect(recipe.totalNutrients.kcal, closeTo(905, 0.01));
      expect(recipe.per100gOfFinished.kcal, closeTo(226.25, 0.01));

      // A 200 g plated serving is half the dish.
      final serving = recipe.serving(200);
      expect(serving.nutrients.kcal, closeTo(452.5, 0.01));
      expect(serving.method, PortionMethod.weighed);
    });

    test('becomes a food item that can be logged like any other', () {
      const recipe = Recipe(
        id: 'r1',
        name: 'Overnight oats',
        components: [
          LoggedComponent(
            food: riceDry,
            grams: 100,
            method: PortionMethod.weighed,
          ),
        ],
        totalYieldGrams: 250,
      );
      final item = recipe.asFoodItem();
      expect(item.source, NutritionSource.userRecipe);
      expect(item.state, FoodState.cooked);
      expect(item.id, 'recipe:r1');
    });
  });

  group('PersonalCalibration', () {
    test('learns the model bias from weighed ground truth', () {
      // The model consistently guesses 100 g where the scale says 130 g.
      final pairs = [
        for (var i = 0; i < 6; i++)
          (estimatedGrams: 100.0, weighedGrams: 130.0),
      ];
      final cal = PersonalCalibration.fit(foodId: 'porridge', pairs: pairs)!;
      expect(cal.meanRatio, closeTo(1.3, 1e-9));
      expect(cal.correct(100), closeTo(130, 1e-9));
      expect(cal.biasPercent, closeTo(30, 1e-9));
    });

    test('refuses to fit from too few samples', () {
      // A correction fitted on two points is worse than no correction.
      final cal = PersonalCalibration.fit(
        foodId: 'porridge',
        pairs: [
          (estimatedGrams: 100, weighedGrams: 130),
          (estimatedGrams: 100, weighedGrams: 90),
        ],
      );
      expect(cal, isNull);
    });

    test('discards unusable pairs', () {
      final cal = PersonalCalibration.fit(
        foodId: 'x',
        pairs: [
          (estimatedGrams: 0, weighedGrams: 100),
          (estimatedGrams: 100, weighedGrams: 0),
          (estimatedGrams: 100, weighedGrams: 110),
        ],
        minSamples: 1,
      )!;
      expect(cal.samples, 1);
      expect(cal.meanRatio, closeTo(1.1, 1e-9));
    });
  });
}
