import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mananu/core/food/open_food_facts.dart';
import 'package:mananu/core/nutrition/models.dart';

/// A v2 product reply in the shape Open Food Facts returns, trimmed to the
/// fields the app asks for.
const _reply = {
  'code': '5000159461122',
  'status': 1,
  'status_verbose': 'product found',
  'product': {
    'product_name': 'Porridge Oats',
    'product_name_en': '',
    'brands': 'Quaker, PepsiCo',
    'serving_size': '40 g',
    'nutriments': {
      'energy-kcal_100g': 374,
      'energy_100g': 1575,
      'proteins_100g': 11,
      'carbohydrates_100g': 60,
      'sugars_100g': 1.1,
      'fat_100g': 8,
      'saturated-fat_100g': 1.5,
      'fiber_100g': 9,
      'salt_100g': 0.01,
      'sodium_100g': 0.004,
    },
  },
};

void main() {
  group('parseProduct', () {
    test('maps the reply onto a food with the barcode and brand', () {
      final f = OpenFoodFactsClient.parseProduct(
        Map<String, dynamic>.from(_reply),
        '5000159461122',
      )!;
      expect(f.name, 'Porridge Oats');
      expect(f.brand, 'Quaker');
      expect(f.barcode, '5000159461122');
      expect(f.source, NutritionSource.openFoodFacts);
      expect(f.per100g.kcal, 374);
      expect(f.per100g.proteinG, 11);
      expect(f.per100g.saturatesG, 1.5);
      expect(f.per100g.fibreG, 9);
      expect(f.per100g.saltG, 0.01);
      expect(f.householdMeasures.single.grams, 40);
    });

    test('derives kcal from kJ and salt from sodium when needed', () {
      final json = jsonDecode(jsonEncode(_reply)) as Map<String, dynamic>;
      final n = (json['product'] as Map)['nutriments'] as Map;
      n.remove('energy-kcal_100g');
      n.remove('salt_100g');
      final f = OpenFoodFactsClient.parseProduct(json, '5000159461122')!;
      expect(f.per100g.kcal, closeTo(1575 / 4.184, 0.01));
      expect(f.per100g.saltG, closeTo(0.01, 1e-9));
    });

    test('an unknown product is null, not a food with zeros', () {
      expect(
        OpenFoodFactsClient.parseProduct(
          {'status': 0, 'status_verbose': 'product not found'},
          '123',
        ),
        isNull,
      );
      expect(
        OpenFoodFactsClient.parseProduct(
          {
            'status': 1,
            'product': {'product_name': 'No numbers', 'nutriments': {}},
          },
          '123',
        ),
        isNull,
      );
    });
  });

  group('lookup', () {
    test('sends the identifying User-Agent and asks for the fields it stores',
        () async {
      http.Request? seen;
      final client = OpenFoodFactsClient(
        client: MockClient((request) async {
          seen = request;
          return http.Response(jsonEncode(_reply), 200);
        }),
        minInterval: Duration.zero,
      );
      final f = await client.lookup('5000159461122');
      expect(f, isNotNull);
      expect(seen!.headers['User-Agent'], startsWith('Mananu/'));
      expect(seen!.url.host, OpenFoodFactsClient.host);
      expect(seen!.url.path, '/api/v2/product/5000159461122.json');
      expect(seen!.url.queryParameters['fields'], contains('nutriments'));
    });

    test('a non-200 or a network failure is null', () async {
      final down = OpenFoodFactsClient(
        client: MockClient((_) async => http.Response('nope', 503)),
        minInterval: Duration.zero,
      );
      expect(await down.lookup('5000159461122'), isNull);
      final broken = OpenFoodFactsClient(
        client: MockClient((_) async => throw Exception('offline')),
        minInterval: Duration.zero,
      );
      expect(await broken.lookup('5000159461122'), isNull);
    });

    test('rejects anything that is not a retail barcode without a request',
        () async {
      var calls = 0;
      final client = OpenFoodFactsClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
        minInterval: Duration.zero,
      );
      expect(await client.lookup('https://example.com'), isNull);
      expect(await client.lookup('12'), isNull);
      expect(calls, 0);
    });

    test('paces consecutive calls to the minimum interval', () async {
      var now = DateTime(2026, 9, 6, 12);
      final client = OpenFoodFactsClient(
        client: MockClient((_) async => http.Response(jsonEncode(_reply), 200)),
        minInterval: const Duration(milliseconds: 200),
        clock: () => now,
      );
      final sw = Stopwatch()..start();
      await client.lookup('5000159461122');
      // The clock has not moved, so the second call must wait the interval.
      await client.lookup('5000159461122');
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(180));
      now = now.add(const Duration(seconds: 10));
      sw.reset();
      await client.lookup('5000159461122');
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
