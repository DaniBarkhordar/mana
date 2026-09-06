/// Core nutrition data model.
///
/// Everything is stored per 100 g and scaled by measured grams at the point of
/// use. That choice is deliberate: the offline food database (UK CoFID and USDA
/// FoodData Central) is published per 100 g, and the whole premise of this
/// product is that we know the grams exactly, so a serving-based model would
/// throw away the one thing we are better at than everyone else.
library;

/// Where a nutrition figure came from. Surfaced in the UI, because "measured"
/// and "guessed" should never look the same to a user.
enum NutritionSource {
  /// UK McCance & Widdowson Composition of Foods Integrated Dataset. Open
  /// Government Licence v3.0. Analytically determined UK foods — the correct
  /// spine for a UK product.
  cofid('CoFID (UK)', true),

  /// USDA FoodData Central: Foundation Foods, SR Legacy, FNDDS. Public domain.
  usda('USDA FoodData Central', true),

  /// Open Food Facts. ODbL — see docs/04-compliance-uk.md for the share-alike
  /// handling. Best free coverage of UK and EU barcoded products.
  openFoodFacts('Open Food Facts', true),

  /// The user typed the label values in themselves.
  userLabel('From the pack', true),

  /// A recipe the user built by weighing its parts.
  userRecipe('Your recipe', true),

  /// Nutrition per 100 g came from a vision model's guess at what the food is.
  /// The grams may still be measured — see [PortionMethod].
  estimated('Estimated', false);

  const NutritionSource(this.label, this.isReferenceData);

  final String label;

  /// True when the per-100 g figures trace to a dataset or a printed label
  /// rather than to a model's guess.
  final bool isReferenceData;
}

/// How the quantity was established. This is the axis the product competes on.
enum PortionMethod {
  /// Read off our scale. The whole point.
  weighed('Weighed', 0.01),

  /// User picked a household measure ("1 medium apple", "1 tbsp").
  householdMeasure('Household measure', 0.20),

  /// A vision model estimated the portion from a photo with no scale involved.
  /// The published error range for photo-only portion estimation is wide; 0.25
  /// is a mid-range figure, not a floor.
  photoEstimate('Photo estimate', 0.25),

  /// User typed a number of grams without weighing.
  manualGrams('Entered by hand', 0.10);

  const PortionMethod(this.label, this.relativeError);

  final String label;

  /// Fractional 1-sigma error contributed by the quantity alone.
  final double relativeError;
}

/// Macro and energy content per 100 g of an edible portion.
///
/// Fields are nullable because reference datasets genuinely have gaps and a
/// zero is not the same as a blank — CoFID codes "trace" and "present but no
/// reliable value" distinctly, and silently coercing those to 0 is how a food
/// log quietly under-reports.
class NutrientsPer100g {
  const NutrientsPer100g({
    required this.kcal,
    this.proteinG,
    this.carbG,
    this.sugarG,
    this.fatG,
    this.saturatesG,
    this.fibreG,
    this.sodiumMg,
    this.saltG,
  });

  final double kcal;
  final double? proteinG;
  final double? carbG;
  final double? sugarG;
  final double? fatG;
  final double? saturatesG;
  final double? fibreG;
  final double? sodiumMg;
  final double? saltG;

  static const zero = NutrientsPer100g(kcal: 0);

  NutrientsPer100g scaled(double factor) => NutrientsPer100g(
        kcal: kcal * factor,
        proteinG: _s(proteinG, factor),
        carbG: _s(carbG, factor),
        sugarG: _s(sugarG, factor),
        fatG: _s(fatG, factor),
        saturatesG: _s(saturatesG, factor),
        fibreG: _s(fibreG, factor),
        sodiumMg: _s(sodiumMg, factor),
        saltG: _s(saltG, factor),
      );

  NutrientsPer100g operator +(NutrientsPer100g other) => NutrientsPer100g(
        kcal: kcal + other.kcal,
        proteinG: _a(proteinG, other.proteinG),
        carbG: _a(carbG, other.carbG),
        sugarG: _a(sugarG, other.sugarG),
        fatG: _a(fatG, other.fatG),
        saturatesG: _a(saturatesG, other.saturatesG),
        fibreG: _a(fibreG, other.fibreG),
        sodiumMg: _a(sodiumMg, other.sodiumMg),
        saltG: _a(saltG, other.saltG),
      );

  static double? _s(double? v, double f) => v == null ? null : v * f;

  /// Null plus a value is that value; null plus null stays null. A missing
  /// field must not silently become a zero contribution that looks complete.
  static double? _a(double? a, double? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }

  /// Energy recomputed from macros using Atwater factors, for cross-checking a
  /// database row against itself. A large disagreement with [kcal] means the row
  /// is bad and should be down-ranked in search results.
  double get atwaterKcal =>
      (proteinG ?? 0) * 4 + (carbG ?? 0) * 4 + (fatG ?? 0) * 9;

  /// True when the stated energy and the macro-derived energy disagree by more
  /// than 20%, i.e. the row is internally inconsistent.
  bool get isInternallyInconsistent {
    if (kcal <= 0) return false;
    if (proteinG == null || carbG == null || fatG == null) return false;
    return (atwaterKcal - kcal).abs() / kcal > 0.20;
  }
}

/// A food as it exists in the database, before any portion is chosen.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.per100g,
    required this.source,
    this.brand,
    this.barcode,
    this.state = FoodState.asPurchased,
    this.householdMeasures = const [],
    this.per100ml = false,
  });

  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final NutrientsPer100g per100g;
  final NutritionSource source;

  /// True for drinks whose reference figures are per 100 ml rather than
  /// per 100 g (CoFID gives alcohol this way). The scale reads grams; for
  /// water-like drinks the two are within a few percent, and the app says so
  /// rather than pretending the row is per 100 g.
  final bool per100ml;

  /// Whether the per-100 g figures describe the food raw or cooked. Getting this
  /// wrong is worth hundreds of calories a day on staples like rice and pasta.
  final FoodState state;

  final List<HouseholdMeasure> householdMeasures;

  String get displayName => brand == null ? name : '$brand $name';
}

/// Whether a database row's figures are for the raw or the cooked food.
enum FoodState {
  /// Dry or raw, as it comes out of the packet.
  asPurchased,

  /// Cooked, drained where relevant.
  cooked,
}

/// A named non-metric portion, e.g. "1 medium (180 g)". Kept because users
/// sometimes log without the scale, but always resolved to grams.
class HouseholdMeasure {
  const HouseholdMeasure({
    required this.label,
    required this.grams,
  });

  final String label;
  final double grams;
}
