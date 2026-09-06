import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/repositories/user_food_repository.dart';
import 'package:mananu/core/food/food_catalog.dart';
import 'package:mananu/core/food/food_identifier.dart';
import 'package:mananu/core/food/food_search.dart';
import 'package:mananu/core/nutrition/models.dart';

/// A reply in the shape the Edge Function returns.
const _reply = {
  'candidates': [
    {
      'name': 'Basmati rice',
      'queries': ['rice basmati boiled', 'rice white boiled', 'rice'],
      'confidence': 0.9,
      'massShare': 0.5,
      'cooked': true,
    },
    {
      'name': 'Chicken tikka',
      'queries': ['chicken tikka', 'chicken breast grilled'],
      'confidence': 0.8,
      'massShare': 0.35,
      'cooked': true,
      'likelyAddedFat': 'ghee or vegetable oil in the marinade',
    },
    {
      'name': 'Coriander',
      'queries': ['coriander leaves'],
      'confidence': 0.6,
      'massShare': 0.02,
      'cooked': false,
    },
  ],
  'note': null,
  'cached': false,
};

void main() {
  group('IdentifyResult', () {
    test('parses candidates, largest share first, with the fat hint', () {
      final r = IdentifyResult.fromJson(Map<String, dynamic>.from(_reply));
      expect(
        r.candidates.map((c) => c.name),
        ['Basmati rice', 'Chicken tikka', 'Coriander'],
      );
      expect(r.candidates[1].likelyAddedFat, contains('ghee'));
      expect(r.candidates[0].queries.first, 'rice basmati boiled');
      expect(r.candidates[2].cooked, isFalse);
      expect(r.degraded, isFalse);
      expect(r.quotaExceeded, isFalse);
    });

    test('a quota reply is empty, flagged, and never blocks weighing', () {
      final r = IdentifyResult.fromJson({
        'candidates': [],
        'note': "You've used today's photo scans.",
        'quotaExceeded': true,
        'canStillWeigh': true,
      });
      expect(r.isEmpty, isTrue);
      expect(r.quotaExceeded, isTrue);
      expect(r.note, contains('today'));
    });

    test('malformed candidates are dropped, a nameless one included', () {
      final r = IdentifyResult.fromJson({
        'candidates': [
          {'name': '', 'queries': []},
          'not a map',
          {'name': 'Egg', 'confidence': 2, 'cooked': 'yes'},
        ],
      });
      expect(r.candidates, hasLength(1));
      expect(r.candidates.single.name, 'Egg');
      expect(r.candidates.single.confidence, 1.0);
      expect(r.candidates.single.cooked, isFalse);
      // No queries given: the name itself is the query.
      expect(r.candidates.single.queries, ['Egg']);
    });

    test('the request never carries a quantity question', () {
      const req = IdentifyRequest(
        imageBase64: 'abc',
        localTime: '07:40',
        locale: 'en-GB',
        recentFoods: ['Porridge oats'],
        measuredGrams: 235,
      );
      final json = req.toJson();
      expect(json.keys, isNot(contains('estimateGrams')));
      expect(json['measuredGrams'], 235);
      expect(json['recentFoods'], ['Porridge oats']);
      expect(jsonEncode(json), isNot(contains('calorie')));
    });
  });

  group('prepareImageForIdentification', () {
    test('downscales the longest edge to 512 and returns JPEG base64', () {
      final big = img.Image(width: 1600, height: 900);
      img.fill(big, color: img.ColorRgb8(200, 120, 40));
      final bytes = Uint8List.fromList(img.encodePng(big));
      final b64 = prepareImageForIdentification(bytes)!;
      final out = img.decodeJpg(base64Decode(b64))!;
      expect(out.width, 512);
      expect(out.height, 288);
      // Two orders of magnitude smaller than the original.
      expect(b64.length, lessThan(bytes.length));
    });

    test('a small image is not upscaled', () {
      final small = img.Image(width: 300, height: 400);
      final bytes = Uint8List.fromList(img.encodePng(small));
      final out =
          img.decodeJpg(base64Decode(prepareImageForIdentification(bytes)!))!;
      expect(out.width, 300);
      expect(out.height, 400);
    });

    test('non-image bytes are null, not an exception', () {
      expect(
        prepareImageForIdentification(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });
  });

  group('FoodMatcher', () {
    late AppDatabase db;
    late FoodCatalog catalog;
    late FoodMatcher matcher;

    setUp(() {
      db = AppDatabase.memory();
      catalog = FoodCatalog.inMemory();
      catalog.insert(
        id: 'cofid:rice-boiled',
        name: 'Rice, white, basmati, boiled',
        source: 'cofid',
        kcal: 130,
        isCooked: true,
      );
      catalog.insert(
        id: 'cofid:rice-raw',
        name: 'Rice, white, basmati, raw',
        source: 'cofid',
        kcal: 356,
      );
      catalog.insert(
        id: 'cofid:chicken-grilled',
        name: 'Chicken, breast, grilled, meat only',
        source: 'cofid',
        kcal: 148,
        isCooked: true,
      );
      matcher = FoodMatcher(
        FoodSearch(catalog: catalog, userFoods: UserFoodRepository(db)),
      );
    });

    tearDown(() async {
      catalog.close();
      await db.close();
    });

    test('tries queries in order and prefers the matching cooked state',
        () async {
      final r = IdentifyResult.fromJson(Map<String, dynamic>.from(_reply));
      final matched = await matcher.match(r.candidates);
      expect(matched, hasLength(3));
      // "rice basmati boiled" hits; the boiled row comes first.
      expect(matched[0].best!.id, 'cofid:rice-boiled');
      // "chicken tikka" misses, "chicken breast grilled" hits.
      expect(matched[1].best!.id, 'cofid:chicken-grilled');
      // Nothing for coriander: the sheet will offer search instead.
      expect(matched[2].matches, isEmpty);
      expect(matched[2].best, isNull);
    });

    test('a raw candidate floats raw rows up', () async {
      final matched = await matcher.match([
        const FoodCandidate(
          name: 'Rice',
          queries: ['rice basmati'],
          confidence: 0.7,
          cooked: false,
        ),
      ]);
      expect(matched.single.best!.state, FoodState.asPurchased);
    });
  });
}
