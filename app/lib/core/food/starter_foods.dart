/// A handful of foods for a build that ships no `core.sqlite`, so the weighing
/// flow can be walked end to end (App Review's route, and a developer's first
/// run). Replaced entirely by the real catalogue once it is built.
///
/// These figures are the original demo values and are not traced to a
/// dataset row, so they are labelled [NutritionSource.estimated]: the app
/// treats them with the wider identification error and says "Estimated" next
/// to them. Nothing in here is a substitute for the database.
library;

import '../nutrition/models.dart';

const starterFoods = <FoodItem>[
  FoodItem(
    id: 'starter:chicken-breast-grilled',
    name: 'Chicken breast, grilled',
    per100g: NutrientsPer100g(kcal: 165, proteinG: 31, fatG: 3.6, carbG: 0),
    source: NutritionSource.estimated,
    state: FoodState.cooked,
  ),
  FoodItem(
    id: 'starter:basmati-rice-dry',
    name: 'Basmati rice, dry',
    per100g: NutrientsPer100g(kcal: 356, proteinG: 8.1, carbG: 78, fatG: 1.0),
    source: NutritionSource.estimated,
  ),
  FoodItem(
    id: 'starter:olive-oil',
    name: 'Olive oil',
    per100g: NutrientsPer100g(kcal: 884, fatG: 100, saturatesG: 14),
    source: NutritionSource.estimated,
  ),
  FoodItem(
    id: 'starter:greek-yogurt',
    name: 'Greek yogurt, natural',
    per100g: NutrientsPer100g(kcal: 133, proteinG: 5.7, carbG: 4.8, fatG: 10.2),
    source: NutritionSource.estimated,
  ),
  FoodItem(
    id: 'starter:porridge-oats',
    name: 'Porridge oats, dry',
    per100g: NutrientsPer100g(kcal: 379, proteinG: 11, carbG: 60, fatG: 8),
    source: NutritionSource.estimated,
  ),
];

/// The oil used by the cooking-fat sheet's default. Real olive oil is close
/// to 884 kcal and 100 g fat per 100 g in every dataset; the user can pick
/// another fat from search.
const starterOliveOil = FoodItem(
  id: 'starter:olive-oil',
  name: 'Olive oil',
  per100g: NutrientsPer100g(kcal: 884, fatG: 100, saturatesG: 14),
  source: NutritionSource.estimated,
);
