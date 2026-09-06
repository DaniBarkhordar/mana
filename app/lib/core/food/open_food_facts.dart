/// Barcode lookup against Open Food Facts.
///
/// Free, and stays free: MyFitnessPal and Lose It! both moved barcode behind
/// a paywall in 2026 and took the backlash; ours costs nothing. Two rules of
/// the road from their API terms — a real User-Agent that names the app, and
/// a polite request rate — are enforced here, not left to the caller.
///
/// The data is ODbL. A looked-up product is cached in the user's own foods
/// (their writable database) and never merged into the shipped catalogue,
/// which is what keeps the share-alike obligation off the app binary.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nutrition/models.dart';

class OpenFoodFactsClient {
  OpenFoodFactsClient({
    http.Client? client,
    this.userAgent = defaultUserAgent,
    this.minInterval = const Duration(seconds: 4),
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  /// Open Food Facts asks for an identifying agent with a contact; the
  /// default is generic and blocks with a 403 on their side.
  static const defaultUserAgent = 'Mananu/0.1 (https://getmananu.com)';

  static const host = 'world.openfoodfacts.org';

  /// Only the fields the app stores. Smaller replies, and nothing personal in
  /// the request beyond the barcode itself.
  static const fields =
      'code,product_name,product_name_en,brands,serving_size,nutriments,status';

  final http.Client _client;
  final String userAgent;

  /// About 15 requests a minute, as their rate limit for product reads.
  final Duration minInterval;
  final DateTime Function() _clock;
  DateTime? _lastCall;

  Uri productUri(String barcode) => Uri.https(
        host,
        '/api/v2/product/$barcode.json',
        {'fields': fields},
      );

  /// Null when the product is unknown, the network is down, or the reply is
  /// unusable. Callers fall back to "add it from the pack".
  Future<FoodItem?> lookup(String barcode) async {
    final code = barcode.trim();
    if (!RegExp(r'^\d{6,14}$').hasMatch(code)) return null;

    final last = _lastCall;
    if (last != null) {
      final wait = minInterval - _clock().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastCall = _clock();

    try {
      final response = await _client.get(
        productUri(code),
        headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      return parseProduct(body, code);
    } on Object {
      return null;
    }
  }

  /// Pure, so it can be tested against a captured reply. Energy is taken in
  /// kcal where given and derived from kJ otherwise; salt is preferred over
  /// sodium and derived (×2.5) when only sodium is present.
  static FoodItem? parseProduct(Map<String, dynamic> json, String barcode) {
    if (json['status'] != 1 && json['status'] != '1') return null;
    final product = json['product'];
    if (product is! Map<String, dynamic>) return null;

    final name = _firstText(product, ['product_name_en', 'product_name']);
    if (name == null) return null;
    final nutriments = product['nutriments'];
    if (nutriments is! Map<String, dynamic>) return null;

    double? n(String key) {
      final v = nutriments[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    var kcal = n('energy-kcal_100g');
    if (kcal == null) {
      final kj = n('energy-kj_100g') ?? n('energy_100g');
      if (kj != null) kcal = kj / 4.184;
    }
    if (kcal == null) return null;

    var salt = n('salt_100g');
    final sodium = n('sodium_100g');
    if (salt == null && sodium != null) salt = sodium * 2.5;

    final brands = _firstText(product, ['brands']);
    final brand = brands?.split(',').first.trim();

    return FoodItem(
      id: 'off:$barcode',
      name: name,
      brand: brand == null || brand.isEmpty ? null : brand,
      barcode: barcode,
      per100g: NutrientsPer100g(
        kcal: kcal,
        proteinG: n('proteins_100g'),
        carbG: n('carbohydrates_100g'),
        sugarG: n('sugars_100g'),
        fatG: n('fat_100g'),
        saturatesG: n('saturated-fat_100g'),
        fibreG: n('fiber_100g'),
        saltG: salt,
      ),
      source: NutritionSource.openFoodFacts,
      householdMeasures: _servingMeasure(product),
    );
  }

  static String? _firstText(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// "30 g" / "250ml" style serving sizes become a household measure. Anything
  /// not in grams or millilitres is dropped rather than guessed.
  static List<HouseholdMeasure> _servingMeasure(Map<String, dynamic> product) {
    final s = product['serving_size'];
    if (s is! String) return const [];
    final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*(g|ml)\b', caseSensitive: false)
        .firstMatch(s);
    if (m == null) return const [];
    final grams = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    if (grams == null || grams <= 0) return const [];
    return [HouseholdMeasure(label: '1 serving ($s)', grams: grams)];
  }

  void close() => _client.close();
}
