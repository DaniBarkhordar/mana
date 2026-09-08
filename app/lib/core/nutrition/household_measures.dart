/// Household measures for the person whose scale has not arrived yet.
///
/// Logging without the scale is allowed; pretending it was weighed is not.
/// Everything that comes out of this file is logged with
/// [PortionMethod.householdMeasure], carries the wider error that method
/// declares, and shows the "Estimated" badge. The table is deliberately
/// small: a handful of measures whose gram weights are well established, and
/// nothing whose weight varies so much that offering it would be a guess
/// dressed up as a chip. Anything else, the user types.
///
/// Sources for the figures are in the comments beside each one. Do not add a
/// measure without one.
library;

import 'models.dart';

/// The coarse class of a food, used only to decide which household measures
/// are sensible to offer. It is a keyword heuristic over the name, so it is
/// allowed to be wrong in the harmless direction: an odd chip is easy to
/// ignore, and the typed field is always there.
enum HouseholdClass {
  /// Water-like drinks: measured by volume, and 1 ml is close enough to 1 g.
  liquid,

  /// Oils, butter and spreads. Lighter than water: 15 ml of oil is 14 g.
  fat,

  /// Sliced bread.
  bread,

  /// Eggs, which come in regulated size bands.
  egg,

  /// Nuts, seeds, crisps, dried fruit: the "handful" foods.
  nutsAndSnacks,

  /// Whole fruit and vegetables eaten as a piece.
  produce,

  /// Everything else. Only the spoon measures are offered.
  general,
}

// UK metric spoons: 5 ml and 15 ml (BS 6887 / every UK recipe since the
// 1970s). For water-like liquids (density 1.00 g/ml; milk is 1.03, juice
// about 1.04) the millilitres are the grams to well within the 20% error the
// household-measure method already declares.
const _teaspoon = HouseholdMeasure(label: 'Teaspoon', grams: 5);
const _tablespoon = HouseholdMeasure(label: 'Tablespoon', grams: 15);

// The 240 ml cup: the figure UK and US nutrition labelling both use for
// "1 cup" of a drink (a UK metric cup is 250 ml; the difference is 4%).
const _cup = HouseholdMeasure(label: 'Cup', grams: 240);

// Cooking oils are 0.91-0.92 g/ml, so 5 ml is 4.6 g and 15 ml is 13.8 g.
// USDA FoodData Central gives 1 tbsp of butter as 14.2 g and of olive oil
// as 13.5 g; 14 g is the round figure that sits between them.
const _teaspoonFat = HouseholdMeasure(label: 'Teaspoon', grams: 5);
const _tablespoonFat = HouseholdMeasure(label: 'Tablespoon', grams: 14);

// CoFID portion sizes: a medium slice from a large (800 g) sliced loaf is
// 36 g. Thick-cut is 44 g and a small loaf's slice 25 g; the medium slice
// is what most UK sliced bread is.
const _slice = HouseholdMeasure(label: 'Slice', grams: 36);

// A UK medium egg is 53-63 g in the shell (EC 1308/2013 size bands);
// the shell is about 12% of that, leaving 50 g of egg. The number people
// eat, not the number on the box.
const _mediumEgg = HouseholdMeasure(label: 'Medium egg', grams: 50);

// The British Nutrition Foundation's "small handful" of nuts, seeds or dried
// fruit is 30 g, and that is the portion the NHS Eatwell material uses.
const _handful = HouseholdMeasure(label: 'Handful', grams: 30);

// A round figure for a medium apple (160 g), pear (170 g), orange (150 g),
// peeled banana (120 g) or potato (175 g) — the fruits and vegetables
// listed in [_produceWords], chosen because 150 g is within a quarter of
// each. Plums, kiwis and satsumas are not in the list for exactly that
// reason: a "medium piece" of those is half this, and a chip that is wrong
// by a factor of two is worse than no chip.
const _mediumPiece = HouseholdMeasure(label: 'Medium piece', grams: 150);

/// The measures offered for each class. Kept as a list per class rather than
/// one flat table so a chip never appears next to a food it makes no sense
/// for: nobody wants a "slice" of milk.
const householdMeasureTable = <HouseholdClass, List<HouseholdMeasure>>{
  HouseholdClass.liquid: [_teaspoon, _tablespoon, _cup],
  HouseholdClass.fat: [_teaspoonFat, _tablespoonFat],
  HouseholdClass.bread: [_slice],
  HouseholdClass.egg: [_mediumEgg],
  HouseholdClass.nutsAndSnacks: [_handful],
  HouseholdClass.produce: [_mediumPiece],
  HouseholdClass.general: [_teaspoon, _tablespoon],
};

const _fatWords = [
  'oil',
  'butter',
  'ghee',
  'lard',
  'margarine',
  'spread',
  'mayonnaise',
  'mayo',
];

const _liquidWords = [
  'milk',
  'buttermilk',
  'juice',
  'water',
  'drink',
  'smoothie',
  'squash',
  'lemonade',
  'cola',
  'beer',
  'lager',
  'wine',
  'cider',
  'coffee',
  'tea',
  'soup',
  'stock',
];

const _breadWords = ['bread', 'toast', 'loaf'];

const _nutWords = [
  'nut',
  'nuts',
  'almond',
  'almonds',
  'cashew',
  'cashews',
  'peanut',
  'peanuts',
  'walnut',
  'walnuts',
  'pistachio',
  'pistachios',
  'hazelnut',
  'hazelnuts',
  'pecan',
  'pecans',
  'seeds',
  'crisps',
  'raisins',
  'sultanas',
  'popcorn',
];

const _produceWords = [
  'apple',
  'pear',
  'orange',
  'banana',
  'potato',
  'nectarine',
  'peach',
  'avocado',
];

/// Which class a food falls into, from its name. Fat is checked before
/// liquid so "olive oil" is a fat and "buttermilk" (one word, so not
/// "butter") is a drink; liquid is checked before nuts so "almond milk" is a
/// drink; the egg rule refuses egg noodles and egg fried rice, which are
/// spoon foods. A food the datasets give per 100 ml is a liquid whatever it
/// is called.
HouseholdClass householdClassOf(FoodItem food) {
  final words = _words(food.displayName);
  bool has(List<String> list) => words.any(list.contains);

  if (has(_fatWords)) return HouseholdClass.fat;
  if (food.per100ml || (has(_liquidWords) && !words.contains('chocolate'))) {
    return HouseholdClass.liquid;
  }
  if ((words.contains('egg') || words.contains('eggs')) &&
      !words.contains('noodles') &&
      !words.contains('rice') &&
      !words.contains('custard')) {
    return HouseholdClass.egg;
  }
  if (has(_breadWords)) return HouseholdClass.bread;
  if (has(_nutWords)) return HouseholdClass.nutsAndSnacks;
  if (has(_produceWords)) return HouseholdClass.produce;
  return HouseholdClass.general;
}

/// The chips to offer for [food]: the product's own serving size first, when
/// a barcode lookup supplied one (that is the pack's figure, so it beats
/// anything generic), then the class table. Labels are unique so two chips
/// never say the same thing.
List<HouseholdMeasure> householdMeasuresFor(FoodItem food) {
  final out = <HouseholdMeasure>[];
  final seen = <String>{};
  for (final m in [
    ...food.householdMeasures,
    ...householdMeasureTable[householdClassOf(food)]!,
  ]) {
    if (m.grams <= 0) continue;
    if (seen.add(m.label.trim().toLowerCase())) out.add(m);
  }
  return out;
}

List<String> _words(String name) => name
    .toLowerCase()
    .split(RegExp(r'[^a-z]+'))
    .where((w) => w.isNotEmpty)
    .toList();
