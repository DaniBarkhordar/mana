/// Portion mathematics — the part of the product that photo-only apps cannot
/// copy.
///
/// The published failure mode of photo calorie apps is not that they cannot
/// identify food. It is that they cannot see quantity, and they cannot see the
/// oil that went into the pan. A controlled-feeding study presented at NUTRITION
/// 2026 found the leading apps underestimated meals by roughly 250-345 kcal,
/// with fat the dominant error term.
///
/// This file attacks both halves:
///   * quantity  -> [WeighSession], a running-tare builder that captures each
///                  ingredient's own mass rather than one blended guess
///   * hidden fat -> [CookingFatCapture], which weighs the oil actually absorbed
///                  instead of assuming it away
///   * raw/cooked -> [YieldFactor], so 75 g of dry pasta is not logged as 75 g
///                  of cooked pasta
library;

import 'dart:math' as math;

import 'models.dart';

/// One weighed component of a meal.
class LoggedComponent {
  const LoggedComponent({
    required this.food,
    required this.grams,
    required this.method,
    this.note,
  });

  final FoodItem food;

  /// Edible grams actually consumed, after any yield conversion.
  final double grams;

  final PortionMethod method;
  final String? note;

  NutrientsPer100g get nutrients => food.per100g.scaled(grams / 100.0);

  /// Contribution of this component to the meal's energy uncertainty, in kcal.
  ///
  /// Two independent error terms combined in quadrature: the quantity error from
  /// [PortionMethod], and the identification error — near zero when the user
  /// scanned a barcode or picked from a reference dataset, substantial when a
  /// vision model guessed what the food was.
  double get energyErrorKcal {
    final kcal = nutrients.kcal;
    final quantityError = kcal * method.relativeError;
    final identityError =
        food.source.isReferenceData ? kcal * 0.05 : kcal * 0.18;
    return math.sqrt(
      quantityError * quantityError + identityError * identityError,
    );
  }
}

/// Raw-to-cooked conversion.
///
/// Dry pasta roughly doubles in cooked mass; rice roughly triples; meat loses
/// water. Logging a cooked weight against a raw database row (or vice versa) is
/// one of the largest routine errors in food tracking, and it is entirely
/// avoidable when you own the scale.
///
/// Factors are cooked mass / raw mass. They are approximate by nature — cooking
/// time and method move them — which is why [YieldFactor.uncertainty] exists and
/// why the app prefers to have the user weigh both ends when it matters.
class YieldFactor {
  const YieldFactor({
    required this.foodKey,
    required this.label,
    required this.cookedPerRaw,
    required this.uncertainty,
  });

  final String foodKey;
  final String label;
  final double cookedPerRaw;
  final double uncertainty;

  /// Grams of cooked food produced by [rawGrams] of raw food.
  double rawToCooked(double rawGrams) => rawGrams * cookedPerRaw;

  /// Raw-equivalent grams represented by [cookedGrams] of cooked food. This is
  /// the direction that matters most: the user weighs what is on the plate, and
  /// the database row is per 100 g raw.
  double cookedToRaw(double cookedGrams) => cookedGrams / cookedPerRaw;

  static const table = <YieldFactor>[
    YieldFactor(
      foodKey: 'pasta_dry',
      label: 'Dried pasta',
      cookedPerRaw: 2.2,
      uncertainty: 0.2,
    ),
    YieldFactor(
      foodKey: 'rice_white_dry',
      label: 'White rice',
      cookedPerRaw: 3.0,
      uncertainty: 0.3,
    ),
    YieldFactor(
      foodKey: 'rice_brown_dry',
      label: 'Brown rice',
      cookedPerRaw: 2.7,
      uncertainty: 0.3,
    ),
    YieldFactor(
      foodKey: 'lentils_dry',
      label: 'Dried lentils',
      cookedPerRaw: 2.4,
      uncertainty: 0.25,
    ),
    YieldFactor(
      foodKey: 'oats_dry',
      label: 'Porridge oats',
      cookedPerRaw: 3.0,
      uncertainty: 0.4,
    ),
    YieldFactor(
      foodKey: 'chicken_breast_raw',
      label: 'Chicken breast',
      cookedPerRaw: 0.73,
      uncertainty: 0.06,
    ),
    YieldFactor(
      foodKey: 'beef_mince_raw',
      label: 'Beef mince',
      cookedPerRaw: 0.72,
      uncertainty: 0.07,
    ),
    YieldFactor(
      foodKey: 'salmon_raw',
      label: 'Salmon fillet',
      cookedPerRaw: 0.79,
      uncertainty: 0.06,
    ),
    YieldFactor(
      foodKey: 'potato_raw',
      label: 'Boiled potato',
      cookedPerRaw: 0.95,
      uncertainty: 0.05,
    ),
  ];

  static YieldFactor? lookup(String foodKey) {
    for (final f in table) {
      if (f.foodKey == foodKey) return f;
    }
    return null;
  }
}

/// Cooking fat that ends up in the food rather than in the pan.
///
/// The method: put the pan on the scale, tare, add oil, read it. Cook. Put the
/// pan back on with whatever is left in it, and the difference is what went into
/// the food. Split across however many portions came out of it.
///
/// No photo can see this. It is the single largest correctable error in the
/// category.
class CookingFatCapture {
  const CookingFatCapture({
    required this.fat,
    required this.gramsAdded,
    required this.gramsRemaining,
    required this.portions,
  }) : assert(portions > 0, 'a pan must serve at least one portion');

  /// The oil or butter itself, so its own nutrition is used rather than a
  /// generic "oil" figure.
  final FoodItem fat;

  final double gramsAdded;

  /// What was still in the pan afterwards. Zero when it was all absorbed.
  final double gramsRemaining;

  /// How many portions the pan produced.
  final int portions;

  double get gramsAbsorbed => math.max(0, gramsAdded - gramsRemaining);

  double get gramsPerPortion => gramsAbsorbed / portions;

  LoggedComponent componentForOnePortion() => LoggedComponent(
        food: fat,
        grams: gramsPerPortion,
        method: PortionMethod.weighed,
        note: 'Cooking fat absorbed — '
            '${gramsAbsorbed.toStringAsFixed(0)} g across $portions '
            '${portions == 1 ? 'portion' : 'portions'}',
      );
}

/// A meal being built one weighed ingredient at a time.
///
/// The scale streams a live weight; the user adds an ingredient, the app
/// captures the delta, and the running tare means they never have to empty the
/// bowl. Each capture yields an exact (food, grams) pair.
///
/// That pair is also the asset: every meal logged this way is a piece of ground
/// truth about what this user actually eats and how much of it, which a
/// photo-only competitor can never obtain.
class WeighSession {
  WeighSession();

  final List<LoggedComponent> _components = [];
  double _lastStableGrams = 0;

  List<LoggedComponent> get components => List.unmodifiable(_components);

  /// Total mass currently on the platform, as captured so far.
  double get platformGrams => _lastStableGrams;

  /// Record an ingredient. [totalOnScaleGrams] is the live reading *after* the
  /// ingredient went in; the component's own mass is the difference from the
  /// previous stable reading.
  ///
  /// Returns the captured mass. A non-positive delta means the user removed
  /// something or the scale drifted; the caller should prompt rather than log a
  /// negative ingredient.
  double addFromRunningTotal({
    required FoodItem food,
    required double totalOnScaleGrams,
    String? note,
  }) {
    final delta = totalOnScaleGrams - _lastStableGrams;
    if (delta <= 0) return delta;
    _components.add(
      LoggedComponent(
        food: food,
        grams: delta,
        method: PortionMethod.weighed,
        note: note,
      ),
    );
    _lastStableGrams = totalOnScaleGrams;
    return delta;
  }

  /// Record an ingredient the user weighed on its own, having tared between
  /// each one.
  void addTared({
    required FoodItem food,
    required double grams,
    String? note,
  }) {
    if (grams <= 0) return;
    _components.add(
      LoggedComponent(
        food: food,
        grams: grams,
        method: PortionMethod.weighed,
        note: note,
      ),
    );
  }

  /// Add something that could not be weighed — a restaurant side, a colleague's
  /// birthday cake. Logged honestly at lower confidence rather than omitted,
  /// because an unlogged item is a 100% error.
  void addUnweighed({
    required FoodItem food,
    required double grams,
    required PortionMethod method,
    String? note,
  }) {
    _components.add(
      LoggedComponent(food: food, grams: grams, method: method, note: note),
    );
  }

  void addCookingFat(CookingFatCapture capture) {
    if (capture.gramsPerPortion <= 0) return;
    _components.add(capture.componentForOnePortion());
  }

  void removeAt(int index) {
    if (index < 0 || index >= _components.length) return;
    _components.removeAt(index);
  }

  void reset() {
    _components.clear();
    _lastStableGrams = 0;
  }

  MealTotals totals() => MealTotals.from(_components);
}

/// The finished sum of a meal, with the honesty layer attached.
class MealTotals {
  const MealTotals({
    required this.nutrients,
    required this.totalGrams,
    required this.energyErrorKcal,
    required this.weighedFraction,
    required this.componentCount,
  });

  factory MealTotals.from(List<LoggedComponent> components) {
    var nutrients = NutrientsPer100g.zero;
    var grams = 0.0;
    var weighedKcal = 0.0;
    var totalKcal = 0.0;
    var sumSquaredError = 0.0;

    for (final c in components) {
      nutrients = nutrients + c.nutrients;
      grams += c.grams;
      final kcal = c.nutrients.kcal;
      totalKcal += kcal;
      if (c.method == PortionMethod.weighed) weighedKcal += kcal;
      final e = c.energyErrorKcal;
      sumSquaredError += e * e;
    }

    return MealTotals(
      nutrients: nutrients,
      totalGrams: grams,
      energyErrorKcal: math.sqrt(sumSquaredError),
      weighedFraction: totalKcal <= 0 ? 0 : weighedKcal / totalKcal,
      componentCount: components.length,
    );
  }

  final NutrientsPer100g nutrients;
  final double totalGrams;

  /// Combined 1-sigma energy uncertainty in kcal. Errors are combined in
  /// quadrature, not summed, because component errors are independent.
  final double energyErrorKcal;

  /// Share of this meal's calories that came from something actually weighed.
  /// This is the number to show the user, and the number to make them want to
  /// raise.
  final double weighedFraction;

  final int componentCount;

  double get kcal => nutrients.kcal;

  /// Relative uncertainty, for the "±x%" badge.
  double get relativeError => kcal <= 0 ? 0 : energyErrorKcal / kcal;

  /// The claim shown next to the total. Note what it does not say: it never
  /// states a system-wide accuracy percentage, because accuracy depends
  /// entirely on the meal, and a headline figure is a claim that cannot be
  /// substantiated.
  String get confidenceLabel {
    if (weighedFraction >= 0.95) return 'Weighed';
    if (weighedFraction >= 0.6) return 'Mostly weighed';
    if (weighedFraction > 0) return 'Partly weighed';
    return 'Estimated';
  }
}

/// A saved recipe: weigh the ingredients once, then log a portion of it forever.
///
/// This is the retention mechanic for a scale product. It converts one careful
/// session into weeks of one-tap logging, and it is the reason a user keeps the
/// scale on the counter instead of in a drawer.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.components,
    required this.totalYieldGrams,
  });

  final String id;
  final String name;
  final List<LoggedComponent> components;

  /// What the finished dish weighed, which is not the sum of the raw
  /// ingredients — water boils off, fat renders out. Weighing the finished dish
  /// is what makes per-portion figures correct.
  final double totalYieldGrams;

  NutrientsPer100g get totalNutrients {
    var n = NutrientsPer100g.zero;
    for (final c in components) {
      n = n + c.nutrients;
    }
    return n;
  }

  /// Nutrition per 100 g of the finished dish, so a served portion can be
  /// weighed straight off the plate.
  NutrientsPer100g get per100gOfFinished {
    if (totalYieldGrams <= 0) return NutrientsPer100g.zero;
    return totalNutrients.scaled(100.0 / totalYieldGrams);
  }

  FoodItem asFoodItem() => FoodItem(
        id: 'recipe:$id',
        name: name,
        per100g: per100gOfFinished,
        source: NutritionSource.userRecipe,
        state: FoodState.cooked,
      );

  /// Log a serving by weighing what actually went on the plate.
  LoggedComponent serving(double platedGrams) => LoggedComponent(
        food: asFoodItem(),
        grams: platedGrams,
        method: PortionMethod.weighed,
      );
}

/// Per-food correction learned from the user's own weighing history.
///
/// Because the app holds true grams for foods this user eats repeatedly, it can
/// measure the vision model's systematic bias for those foods and correct it.
/// A photo-only app has no ground truth and can never close this loop.
class PersonalCalibration {
  const PersonalCalibration({
    required this.foodId,
    required this.samples,
    required this.meanRatio,
  });

  /// Build a correction from paired (model estimate, weighed truth) samples.
  /// Returns null below [minSamples], because a correction fitted on two points
  /// is worse than no correction.
  static PersonalCalibration? fit({
    required String foodId,
    required List<({double estimatedGrams, double weighedGrams})> pairs,
    int minSamples = 5,
  }) {
    final usable =
        pairs.where((p) => p.estimatedGrams > 0 && p.weighedGrams > 0).toList();
    if (usable.length < minSamples) return null;
    var sum = 0.0;
    for (final p in usable) {
      sum += p.weighedGrams / p.estimatedGrams;
    }
    return PersonalCalibration(
      foodId: foodId,
      samples: usable.length,
      meanRatio: sum / usable.length,
    );
  }

  final String foodId;
  final int samples;

  /// Multiply a model estimate by this to get the corrected grams.
  final double meanRatio;

  double correct(double estimatedGrams) => estimatedGrams * meanRatio;

  /// How far off the model has been, as a percentage, for this user's version of
  /// this food. Shown in the UI as "we've learned your usual portion".
  double get biasPercent => (meanRatio - 1.0) * 100.0;
}
