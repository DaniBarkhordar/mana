import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/food/food_catalog.dart';
import 'package:mananu/core/nutrition/models.dart';

/// The catalogue is a read-only SQLite file with an FTS5 index. These run on
/// an in-memory copy with the shipped schema, so what they prove holds for
/// the real build too, minus the data.
void main() {
  late FoodCatalog catalog;

  setUp(() {
    catalog = FoodCatalog.inMemory();
    catalog.insert(
      id: 'cofid:18-016',
      name: 'Chicken, breast, grilled, meat only',
      source: 'cofid',
      kcal: 148,
      protein: 32,
      fat: 2.2,
      carb: 0,
      isCooked: true,
    );
    catalog.insert(
      id: 'usda:171077',
      name: 'Chicken, broilers or fryers, breast, meat only, cooked, roasted',
      source: 'usda',
      kcal: 165,
      protein: 31.02,
      fat: 3.57,
      carb: 0,
      isCooked: true,
    );
    catalog.insert(
      id: 'usda:170287',
      name: 'Chickpea flour (besan)',
      source: 'usda',
      kcal: 387,
      protein: 22.39,
      carb: 57.82,
      fat: 6.69,
      fibre: 10.8,
    );
    catalog.insert(
      id: 'cofid:17-300',
      name: 'Beer, bitter, draught',
      source: 'cofid',
      kcal: 32,
      per100ml: true,
    );
    catalog.insert(
      id: 'cofid:x-1',
      name: 'Chicken',
      source: 'cofid',
      kcal: 100,
    );
    catalog.insert(
      id: 'cofid:x-2',
      name: 'Crème fraîche',
      source: 'cofid',
      kcal: 378,
    );
  });

  tearDown(() => catalog.close());

  test('normalisation matches the build script', () {
    expect(normaliseFoodName('Crème fraîche, 30% fat'), 'creme fraiche 30 fat');
    expect(ftsQuery('crème  fra'), '"creme"* "fra"*');
    expect(ftsQuery('  '), '');
  });

  test('a prefix beats a mid-word match: "chick" is chicken, not chickpea', () {
    final hits = catalog.search('chick');
    expect(hits.first.name, startsWith('Chicken'));
    final names = hits.map((f) => f.name).toList();
    expect(
      names.indexOf('Chickpea flour (besan)'),
      greaterThan(names.indexOf('Chicken, breast, grilled, meat only')),
    );
  });

  test('an exact name ranks first, then UK data, then USDA', () {
    final hits = catalog.search('chicken');
    expect(hits[0].name, 'Chicken');
    expect(hits[1].source, NutritionSource.cofid);
    expect(hits.last.source, NutritionSource.usda);
  });

  test('every token is a prefix, in any order', () {
    final hits = catalog.search('breast chick');
    expect(hits, hasLength(2));
    expect(hits.first.source, NutritionSource.cofid);
  });

  test('accents do not matter either way', () {
    expect(catalog.search('creme').single.name, 'Crème fraîche');
    expect(catalog.search('crème').single.name, 'Crème fraîche');
  });

  test('missing nutrients come back null, not zero', () {
    final beer = catalog.search('beer').single;
    expect(beer.per100g.proteinG, isNull);
    expect(beer.per100g.fatG, isNull);
    expect(beer.per100ml, isTrue);
    expect(catalog.byId('usda:171077')!.per100g.fibreG, isNull);
  });

  test('cooked state carries through', () {
    expect(catalog.byId('cofid:18-016')!.state, FoodState.cooked);
    expect(catalog.byId('usda:170287')!.state, FoodState.asPurchased);
  });

  test('an empty query returns nothing rather than everything', () {
    expect(catalog.search(''), isEmpty);
    expect(catalog.search('  ,  '), isEmpty);
  });

  test('search stays under the 100 ms acceptance with thousands of rows', () {
    for (var i = 0; i < 4000; i++) {
      catalog.insert(
        id: 'usda:gen$i',
        name: 'Generated food ${i % 97} variety $i with some words',
        source: 'usda',
        kcal: 100 + (i % 300).toDouble(),
      );
    }
    final sw = Stopwatch()..start();
    final hits = catalog.search('chicken breast');
    sw.stop();
    expect(hits.first.name, 'Chicken, breast, grilled, meat only');
    expect(sw.elapsedMilliseconds, lessThan(100));
  });
}
