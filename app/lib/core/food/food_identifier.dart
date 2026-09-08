/// Food identification: the camera, or the user's own words, say what the
/// food is; the scale says how much. Nothing in this file asks a model for
/// grams, calories or macros (CLAUDE.md rule 1) — the request cannot even
/// carry the question.
///
/// The pipeline: downscale the photo to 512 px on the device (or take a
/// short typed description instead), send it with a little context to the
/// `identify-food` Edge Function, get back candidate names each with search
/// queries for the offline catalogue, and match those queries locally. The
/// user picks the row; the grams come off the scale.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../nutrition/models.dart';
import 'food_search.dart';

/// What goes up. Mirrors `IdentifyRequest` in the Edge Function. A request
/// carries a photo, a description, or both; never a question about
/// quantity.
class IdentifyRequest {
  const IdentifyRequest({
    this.imageBase64,
    this.description,
    this.localTime,
    this.locale,
    this.recentFoods = const [],
    this.hint,
    this.measuredGrams,
  }) : assert(
          imageBase64 != null || description != null,
          'a request needs a photo or a description to identify',
        );

  /// The longest a description can be, matching the function's limit.
  static const maxDescriptionLength = 300;

  final String? imageBase64;

  /// The food in the user's own words — "chicken tikka with rice and a
  /// naan" — for logging without a camera or a scale. Identification only,
  /// exactly like a photo.
  final String? description;
  final String? localTime;
  final String? locale;
  final List<String> recentFoods;
  final String? hint;
  final double? measuredGrams;

  String? get _trimmedDescription {
    final d = description?.trim();
    if (d == null || d.isEmpty) return null;
    return d.length > maxDescriptionLength
        ? d.substring(0, maxDescriptionLength)
        : d;
  }

  Map<String, Object?> toJson() => {
        if (imageBase64 != null) 'imageBase64': imageBase64,
        if (_trimmedDescription != null) 'description': _trimmedDescription,
        if (localTime != null) 'localTime': localTime,
        if (locale != null) 'locale': locale,
        if (recentFoods.isNotEmpty)
          'recentFoods': recentFoods.take(25).toList(),
        if (hint != null && hint!.isNotEmpty) 'hint': hint,
        if (measuredGrams != null && measuredGrams! > 0)
          'measuredGrams': measuredGrams,
      };
}

/// One thing the model saw. Mirrors `FoodCandidate` in the Edge Function.
class FoodCandidate {
  const FoodCandidate({
    required this.name,
    required this.queries,
    required this.confidence,
    required this.cooked,
    this.massShare,
    this.likelyAddedFat,
  });

  final String name;

  /// Search terms for the offline catalogue, most specific first.
  final List<String> queries;
  final double confidence;
  final bool cooked;

  /// Rough share of the plate, for ordering only. Never a quantity.
  final double? massShare;

  /// Fat absorbed in cooking that the photo cannot show — the largest
  /// published error in the category, surfaced so the user can weigh it.
  final String? likelyAddedFat;

  static FoodCandidate? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final queries = <String>[
      if (json['queries'] is List)
        for (final q in json['queries'] as List)
          if (q is String && q.trim().isNotEmpty) q.trim(),
    ];
    return FoodCandidate(
      name: name.trim(),
      queries: queries.isEmpty ? [name.trim()] : queries,
      confidence: _num(json['confidence'])?.clamp(0.0, 1.0) ?? 0.5,
      cooked: json['cooked'] == true,
      massShare: _num(json['massShare']),
      likelyAddedFat: json['likelyAddedFat'] is String &&
              (json['likelyAddedFat'] as String).trim().isNotEmpty
          ? (json['likelyAddedFat'] as String).trim()
          : null,
    );
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;
}

class IdentifyResult {
  const IdentifyResult({
    required this.candidates,
    this.note,
    this.cached = false,
    this.quotaExceeded = false,
    this.degraded = false,
  });

  final List<FoodCandidate> candidates;

  /// A sentence from the model or the function, shown verbatim.
  final String? note;
  final bool cached;

  /// Today's scans are used. Weighing and search still work, always.
  final bool quotaExceeded;

  /// The model could not be reached. Same: weighing still works.
  final bool degraded;

  bool get isEmpty => candidates.isEmpty;

  factory IdentifyResult.fromJson(Map<String, dynamic> json) {
    final raw = json['candidates'];
    final candidates = <FoodCandidate>[
      if (raw is List)
        for (final c in raw)
          if (FoodCandidate.fromJson(c) case final parsed?) parsed,
    ];
    // Largest share first: it is the thing the user is most likely to weigh
    // first.
    candidates.sort(
      (a, b) => (b.massShare ?? 0).compareTo(a.massShare ?? 0),
    );
    return IdentifyResult(
      candidates: candidates,
      note: json['note'] is String ? json['note'] as String : null,
      cached: json['cached'] == true,
      quotaExceeded: json['quotaExceeded'] == true,
      degraded: json['degraded'] == true,
    );
  }

  static const unavailable = IdentifyResult(
    candidates: [],
    degraded: true,
    note: 'Photo recognition needs a connection to Mananu. You can still '
        'search, scan a barcode, or weigh.',
  );
}

abstract class FoodIdentifier {
  Future<IdentifyResult> identify(IdentifyRequest request);
}

/// The real thing, through the Edge Function. The API key stays on the
/// server; the app only ever holds its own session.
class SupabaseFoodIdentifier implements FoodIdentifier {
  SupabaseFoodIdentifier(this._client);

  final SupabaseClient _client;

  @override
  Future<IdentifyResult> identify(IdentifyRequest request) async {
    try {
      final response = await _client.functions
          .invoke('identify-food', body: request.toJson())
          .timeout(const Duration(seconds: 25));
      final data = response.data;
      if (data is Map<String, dynamic>) return IdentifyResult.fromJson(data);
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return IdentifyResult.fromJson(decoded);
        }
      }
      return IdentifyResult.unavailable;
    } on Object {
      return IdentifyResult.unavailable;
    }
  }
}

/// A build with no backend, or no session yet.
class UnavailableFoodIdentifier implements FoodIdentifier {
  const UnavailableFoodIdentifier();

  @override
  Future<IdentifyResult> identify(IdentifyRequest request) async =>
      IdentifyResult.unavailable;
}

/// Downscales to [maxEdge] on the longest side and re-encodes as JPEG. Done
/// on the device before anything leaves it: a 512 px food photo is one to
/// two thousand image tokens, roughly a hundred times cheaper than sending
/// the original. Returns null when the bytes are not an image.
String? prepareImageForIdentification(
  Uint8List bytes, {
  int maxEdge = 512,
  int quality = 82,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    return null;
  }
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxEdge)
        : img.copyResize(image, height: maxEdge);
  }
  return base64Encode(img.encodeJpg(image, quality: quality));
}

/// A candidate with the catalogue rows it maps onto.
class MatchedCandidate {
  const MatchedCandidate({required this.candidate, required this.matches});

  final FoodCandidate candidate;

  /// Best first. Empty when nothing in the catalogue answers to any query;
  /// the sheet then offers search with the candidate's name typed in.
  final List<FoodItem> matches;

  FoodItem? get best => matches.isEmpty ? null : matches.first;
}

/// Turns the model's names into rows the user can log, locally and
/// instantly: each query in order until one hits, then the rows whose
/// cooked/raw state agrees with the photo float to the top.
class FoodMatcher {
  const FoodMatcher(this._search);

  final FoodSearch _search;

  Future<List<MatchedCandidate>> match(List<FoodCandidate> candidates) async {
    final out = <MatchedCandidate>[];
    for (final c in candidates) {
      var found = <FoodItem>[];
      for (final q in [...c.queries, c.name]) {
        final r = await _search.search(q, limit: 6);
        if (r.items.isNotEmpty) {
          found = r.items;
          break;
        }
      }
      final wanted = c.cooked ? FoodState.cooked : FoodState.asPurchased;
      found.sort((a, b) {
        final sa = a.state == wanted ? 0 : 1;
        final sb = b.state == wanted ? 0 : 1;
        return sa.compareTo(sb);
      });
      out.add(MatchedCandidate(candidate: c, matches: found.take(4).toList()));
    }
    return out;
  }
}
