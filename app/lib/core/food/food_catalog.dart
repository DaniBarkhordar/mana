/// The offline food database: UK CoFID plus USDA FoodData Central, built by
/// `scripts/build_food_db.py` into `assets/food/core.sqlite` and opened here
/// read-only.
///
/// Licence boundary, restated because it matters: only those two datasets may
/// ship inside the binary. Open Food Facts rows are cached per user in the
/// writable database (see UserFoodRepository), never merged into this one.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../nutrition/models.dart';

/// Lower-cased, accent-stripped, punctuation to spaces — the same
/// normalisation the build script applies to `name_norm`, so exact and prefix
/// comparisons hold.
String normaliseFoodName(String s) {
  const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
  const plain = 'aaaaaaeeeeiiiiooooouuuuyycn';
  final sb = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final i = accents.indexOf(ch);
    sb.write(i >= 0 ? plain[i] : ch);
  }
  return sb
      .toString()
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(' +'), ' ');
}

/// Every token as a prefix: "chick br" finds "Chicken breast".
String ftsQuery(String text) {
  final tokens = normaliseFoodName(text).split(' ').where((t) => t.isNotEmpty);
  return tokens.map((t) => '"$t"*').join(' ');
}

class FoodCatalog {
  FoodCatalog._(this._db);

  final Database _db;

  static const assetPath = 'assets/food/core.sqlite';

  /// Opens the shipped database, copying it out of the asset bundle the first
  /// time and whenever the bundled file changes. Null when the build carries
  /// no database, which the app treats as "search covers your own foods only".
  static Future<FoodCatalog?> openAsset({String asset = assetPath}) async {
    final ByteData data;
    try {
      data = await rootBundle.load(asset);
    } on Object {
      return null;
    }
    if (data.lengthInBytes == 0) return null;

    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'core.sqlite'));
    final stamp = File('${file.path}.stamp');
    final fingerprint = _fingerprint(data);
    final current = stamp.existsSync() ? stamp.readAsStringSync() : null;
    if (!file.existsSync() || current != fingerprint) {
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await stamp.writeAsString(fingerprint);
    }
    return openFile(file.path);
  }

  /// Length plus a sample of bytes: enough to notice a rebuilt asset without
  /// hashing several megabytes on every launch.
  static String _fingerprint(ByteData d) {
    final n = d.lengthInBytes;
    var h = n;
    for (var i = 0; i < n; i += (n ~/ 4096).clamp(1, n)) {
      h = (h * 31 + d.getUint8(i)) & 0x7fffffff;
    }
    return '$n:$h';
  }

  /// Opens a database file directly. Null if it does not exist.
  static FoodCatalog? openFile(String path) {
    if (!File(path).existsSync()) return null;
    return FoodCatalog._(sqlite3.open(path, mode: OpenMode.readOnly));
  }

  /// For tests: an in-memory catalogue with the shipped schema.
  static FoodCatalog inMemory() {
    final db = sqlite3.openInMemory();
    db.execute(schemaSql);
    return FoodCatalog._(db);
  }

  /// The same DDL as build_food_db.py. Kept in step by a test that reads the
  /// shipped file's columns when one is present.
  static const schemaSql = '''
create table foods (
  id text primary key, name text not null, brand text,
  source text not null, source_id text not null, food_group text,
  is_cooked integer not null default 0, per_100ml integer not null default 0,
  kcal_100g real not null,
  protein_100g real, carb_100g real, sugar_100g real,
  fat_100g real, saturates_100g real, fibre_100g real, salt_100g real,
  name_norm text not null, name_len integer not null
);
create index foods_name_norm_idx on foods (name_norm);
create virtual table foods_fts using fts5(
  name, brand, content='foods', content_rowid='rowid',
  tokenize='unicode61 remove_diacritics 2'
);
create table meta (key text primary key, value text);
''';

  String? get attribution => _meta('attribution');

  int get rowCount => int.tryParse(_meta('rows') ?? '') ?? 0;

  String? _meta(String key) {
    final rows = _db.select('select value from meta where key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// Ranked search. Tier 0 exact name, tier 1 prefix, tier 2 anywhere; within
  /// a tier UK data first, then relevance, then the shorter name. Synchronous
  /// because it is a local index and takes a few milliseconds.
  List<FoodItem> search(String query, {int limit = 25}) {
    final norm = normaliseFoodName(query);
    if (norm.isEmpty) return const [];
    final rows =
        _db.select(_searchSql, [norm, '$norm%', ftsQuery(query), limit]);
    return [for (final r in rows) _toFood(r)];
  }

  static const _searchSql = '''
select f.*,
       case when f.name_norm = ? then 0
            when f.name_norm like ? then 1
            else 2 end as tier,
       bm25(foods_fts) as rank
from foods_fts
join foods f on f.rowid = foods_fts.rowid
where foods_fts match ?
order by tier, (f.source = 'cofid') desc, rank, f.name_len
limit ?
''';

  FoodItem? byId(String id) {
    final rows = _db.select('select * from foods where id = ?', [id]);
    return rows.isEmpty ? null : _toFood(rows.first);
  }

  /// For tests and tooling: insert a row and refresh the index.
  void insert({
    required String id,
    required String name,
    required String source,
    required double kcal,
    double? protein,
    double? carb,
    double? sugar,
    double? fat,
    double? saturates,
    double? fibre,
    double? salt,
    bool isCooked = false,
    bool per100ml = false,
  }) {
    final norm = normaliseFoodName(name);
    _db.execute(
      'insert or replace into foods (id, name, brand, source, source_id, '
      'food_group, is_cooked, per_100ml, kcal_100g, protein_100g, carb_100g, '
      'sugar_100g, fat_100g, saturates_100g, fibre_100g, salt_100g, '
      'name_norm, name_len) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        id,
        name,
        null,
        source,
        id.split(':').last,
        null,
        isCooked ? 1 : 0,
        per100ml ? 1 : 0,
        kcal,
        protein,
        carb,
        sugar,
        fat,
        saturates,
        fibre,
        salt,
        norm,
        norm.length,
      ],
    );
    _db.execute("insert into foods_fts(foods_fts) values ('rebuild')");
  }

  static FoodItem _toFood(Row r) {
    double? d(String c) => (r[c] as num?)?.toDouble();
    return FoodItem(
      id: r['id'] as String,
      name: r['name'] as String,
      brand: r['brand'] as String?,
      per100g: NutrientsPer100g(
        kcal: (r['kcal_100g'] as num).toDouble(),
        proteinG: d('protein_100g'),
        carbG: d('carb_100g'),
        sugarG: d('sugar_100g'),
        fatG: d('fat_100g'),
        saturatesG: d('saturates_100g'),
        fibreG: d('fibre_100g'),
        saltG: d('salt_100g'),
      ),
      source:
          r['source'] == 'cofid' ? NutritionSource.cofid : NutritionSource.usda,
      state: (r['is_cooked'] as int) == 1
          ? FoodState.cooked
          : FoodState.asPurchased,
      per100ml: (r['per_100ml'] as int) == 1,
    );
  }

  void close() => _db.close();
}
