/// The three things the law requires and the product should be proud of:
/// withdrawing consent is as easy as giving it (UK GDPR Art 7(3)); everything
/// can be exported (Art 20); and deleting an account actually deletes it
/// (Art 17, Apple 5.1.1(v)). None of them is a feature flag.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'db/database.dart';
import 'models.dart';
import 'repositories/profile_repository.dart';

/// Every row the person owns, as CSV files a spreadsheet opens cleanly.
class DataExporter {
  DataExporter(this._db);

  final AppDatabase _db;

  /// Writes one CSV per table into [dir] and returns the paths, in the order
  /// a person would want to open them.
  Future<List<File>> writeAll(Directory dir) async {
    final files = <File>[];
    for (final spec in _tables) {
      final rows = await _db.customSelect(spec.sql).get();
      final file = File(p.join(dir.path, '${spec.name}.csv'));
      final buf = StringBuffer();
      buf.writeln(csvLine(spec.columns));
      for (final row in rows) {
        buf.writeln(csvLine([for (final c in spec.columns) row.data[c]]));
      }
      await file.writeAsString(buf.toString());
      files.add(file);
    }
    return files;
  }

  /// Hands the files to the share sheet. AirDrop, Files, mail — the person's
  /// choice, never ours.
  Future<void> shareAll() async {
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'mananu-export'),
    );
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final files = await writeAll(dir);
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path, mimeType: 'text/csv')],
        subject: 'Mananu export',
        text: 'Every measurement and meal, as CSV.',
      ),
    );
  }

  /// RFC 4180: quote when needed, double the quotes inside, ISO dates as
  /// stored, empty for null.
  static String csvLine(List<Object?> values) => values.map((v) {
        if (v == null) return '';
        var s = v is DateTime ? v.toUtc().toIso8601String() : v.toString();
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          s = '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }).join(',');

  static const _tables = [
    _Export(
      'body_measurements',
      'select taken_at, weight_kg, impedance_ohm, body_fat_percent, '
          'fat_free_mass_kg, total_body_water_l, skeletal_muscle_kg, '
          'resting_kcal, equation, confidence, height_cm_at_time, '
          'age_years_at_time, sex_at_time, notes, id '
          'from body_measurements where deleted_at is null order by taken_at',
      [
        'taken_at',
        'weight_kg',
        'impedance_ohm',
        'body_fat_percent',
        'fat_free_mass_kg',
        'total_body_water_l',
        'skeletal_muscle_kg',
        'resting_kcal',
        'equation',
        'confidence',
        'height_cm_at_time',
        'age_years_at_time',
        'sex_at_time',
        'notes',
        'id',
      ],
    ),
    _Export(
      'observations',
      'select taken_at, kind, value, unit, source, method, confidence, '
          'reference_low, reference_high, reference_source, id '
          'from observations where deleted_at is null order by taken_at',
      [
        'taken_at',
        'kind',
        'value',
        'unit',
        'source',
        'method',
        'confidence',
        'reference_low',
        'reference_high',
        'reference_source',
        'id',
      ],
    ),
    _Export(
      'meals',
      'select eaten_at, slot, note, id from meals '
          'where deleted_at is null order by eaten_at',
      ['eaten_at', 'slot', 'note', 'id'],
    ),
    _Export(
      'meal_components',
      'select m.eaten_at, c.food_name, c.food_source, c.grams, c.method, '
          'c.kcal, c.protein_g, c.carb_g, c.fat_g, c.sugar_g, c.saturates_g, '
          'c.fibre_g, c.salt_g, c.is_cooking_fat, c.meal_id, c.id '
          'from meal_components c join meals m on m.id = c.meal_id '
          'where c.deleted_at is null order by m.eaten_at, c.position',
      [
        'eaten_at',
        'food_name',
        'food_source',
        'grams',
        'method',
        'kcal',
        'protein_g',
        'carb_g',
        'fat_g',
        'sugar_g',
        'saturates_g',
        'fibre_g',
        'salt_g',
        'is_cooking_fat',
        'meal_id',
        'id',
      ],
    ),
    _Export(
      'consents',
      'select granted_at, purpose, granted, policy_version, source '
          'from consents order by granted_at',
      ['granted_at', 'purpose', 'granted', 'policy_version', 'source'],
    ),
  ];
}

class _Export {
  const _Export(this.name, this.sql, this.columns);

  final String name;
  final String sql;
  final List<String> columns;
}

/// Withdrawal, sign-out and erasure.
class AccountActions {
  AccountActions({
    required AppDatabase db,
    required ProfileRepository profiles,
    SupabaseClient? supabase,
  })  : _db = db,
        _profiles = profiles,
        _supabase = supabase;

  final AppDatabase _db;
  final ProfileRepository _profiles;
  final SupabaseClient? _supabase;

  /// A new consent row, never an edit. With [deleteExisting], every
  /// composition figure already stored is removed; the weights stay.
  Future<void> withdrawBodyComposition({required bool deleteExisting}) async {
    await _profiles.recordConsent(
      ConsentRecord(
        purpose: ConsentRecord.bodyComposition,
        policyVersion: ConsentRecord.currentPolicyVersion,
        granted: false,
        grantedAt: DateTime.now(),
      ),
    );
    if (deleteExisting) await stripComposition();
  }

  /// Turns every stored reading into weight-only: composition columns null,
  /// the impedance gone, the derived observations tombstoned. Sync carries
  /// the same change to the server.
  Future<void> stripComposition() async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.update(_db.bodyMeasurements).write(
            BodyMeasurementsCompanion(
              impedanceOhm: const Value(null),
              reactanceOhm: const Value(null),
              segmentalRaw: const Value(null),
              fatFreeMassKg: const Value(null),
              bodyFatPercent: const Value(null),
              totalBodyWaterL: const Value(null),
              skeletalMuscleKg: const Value(null),
              restingKcal: const Value(null),
              equation: const Value(null),
              confidence: const Value('weight_only'),
              notes: const Value(
                '["Body composition consent was withdrawn; only the weight '
                'was kept."]',
              ),
              updatedAt: Value(now),
              syncedAt: const Value(null),
            ),
          );
      await (_db.update(_db.observations)
            ..where(
              (o) => o.kind.isIn(compositionKinds) & o.deletedAt.isNull(),
            ))
          .write(
        ObservationsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncedAt: const Value(null),
        ),
      );
    });
  }

  /// Observation kinds that are composition, not weight.
  static const compositionKinds = [
    'impedance_ohm',
    'body_fat_pct',
    'fat_free_mass_kg',
    'skeletal_muscle_kg',
    'total_body_water_l',
  ];

  /// Empties every table on this phone. The next launch starts as a fresh
  /// install, with a new local user id.
  Future<void> wipeLocal() async {
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
  }

  /// Erases the account server-side — `delete_my_account()` cascades from
  /// `auth.users`, so no row survives anywhere — then signs out and wipes
  /// this phone. Without a backend it is a local wipe.
  Future<void> deleteAccount() async {
    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      await client.rpc('delete_my_account');
      try {
        await client.auth.signOut();
      } on Object {
        // The user no longer exists server-side; the local session is all
        // that is left, and the wipe below clears it.
      }
    }
    await wipeLocal();
  }
}
