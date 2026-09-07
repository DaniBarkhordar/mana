/// Local schema, mirroring `supabase/migrations/` column for column.
///
/// The names are identical to Postgres on purpose: the sync layer moves rows
/// as plain maps and never has to translate a field, which keeps it boring.
/// Two kinds of column exist only locally — `synced_at`, set when a row has
/// reached the server, and the `sync_state` table itself.
///
/// Every synced table has a client-generated uuid primary key, so a row made
/// in aeroplane mode keeps its identity when it lands.
library;

import 'package:drift/drift.dart';

/// Timestamps every synced table carries. `synced_at` is local only.
mixin SyncColumns on Table {
  DateTimeColumn get createdAt => dateTime()();

  /// Last-write-wins compares this. Always UTC.
  DateTimeColumn get updatedAt => dateTime()();

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// A deletion made offline has to reach the other devices, so synced rows are
/// tombstoned rather than removed. Every read filters `deleted_at is null`.
mixin Tombstone on Table {
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Profiles extends Table with SyncColumns {
  /// The user id. Before sign-in this is a local placeholder; on sign-in every
  /// row is re-keyed to the real uid in one pass (see AppDatabase.adoptUser).
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();

  /// ISO date, `YYYY-MM-DD`. Stored as the date so a birthday advances the age
  /// naturally; every measurement snapshots the age it was taken at.
  TextColumn get dateOfBirth => text().nullable()();
  TextColumn get sex => text().nullable()();
  RealColumn get heightCm => real().nullable()();
  TextColumn get activity => text().withDefault(const Constant('low_active'))();
  TextColumn get units => text().withDefault(const Constant('metric'))();
  TextColumn get country => text().withDefault(const Constant('GB'))();

  // The goal (0004_goals.sql). What the daily target is shaped towards;
  // the target itself is recomputed from the latest reading, never stored
  // here.
  TextColumn get goal => text().withDefault(const Constant('maintain'))();
  RealColumn get targetWeightKg => real().nullable()();

  /// 0.25–1.0. Null means the default pace.
  RealColumn get paceKgPerWeek => real().nullable()();
  TextColumn get macroSplit => text().withDefault(const Constant('balanced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per grant or withdrawal, never updated. Insert-only on the server
/// too, so the history is the evidence.
class Consents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get purpose => text()();
  TextColumn get policyVersion => text()();
  BoolColumn get granted => boolean()();
  DateTimeColumn get grantedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('app'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every raw measurement from any source. See 0003_observations_and_sync.sql.
class Observations extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get kind => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  TextColumn get source => text()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get method => text().nullable()();
  TextColumn get confidence => text().nullable()();
  RealColumn get referenceLow => real().nullable()();
  RealColumn get referenceHigh => real().nullable()();
  TextColumn get referenceSource => text().nullable()();

  /// JSON. The source payload, never discarded.
  TextColumn get raw => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BodyMeasurements extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get takenAt => dateTime()();

  // Raw sensor output. Never overwritten, never recomputed.
  RealColumn get weightKg => real()();
  RealColumn get impedanceOhm => real().nullable()();
  RealColumn get reactanceOhm => real().nullable()();

  /// JSON. Vendor-encoded segmental values, kept raw for a later decode.
  TextColumn get segmentalRaw => text().nullable()();
  IntColumn get heartRateBpm => integer().nullable()();

  // Inputs, snapshotted, so a birthday cannot rewrite history.
  RealColumn get heightCmAtTime => real().nullable()();
  IntColumn get ageYearsAtTime => integer().nullable()();
  TextColumn get sexAtTime => text().nullable()();

  // Derived values, with provenance.
  RealColumn get fatFreeMassKg => real().nullable()();
  RealColumn get bodyFatPercent => real().nullable()();
  RealColumn get totalBodyWaterL => real().nullable()();
  RealColumn get skeletalMuscleKg => real().nullable()();
  IntColumn get restingKcal => integer().nullable()();

  /// Which published equation produced the derived columns, e.g. `sun2003`.
  TextColumn get equation => text().nullable()();
  TextColumn get confidence => text().withDefault(const Constant('good'))();

  /// JSON. Conditions the user reported.
  TextColumn get context => text().withDefault(const Constant('{}'))();

  /// JSON list. What the user was told about this reading.
  TextColumn get notes => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Meals extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get slot => text().withDefault(const Constant('snack'))();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MealComponents extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get mealId => text()();
  TextColumn get userId => text()();
  TextColumn get foodId => text().nullable()();

  // Denormalised so a deleted catalogue row cannot rewrite a user's history.
  TextColumn get foodName => text()();
  TextColumn get foodSource => text().nullable()();
  RealColumn get grams => real()();
  TextColumn get method => text()();

  // Totals for this component, not per 100 g.
  RealColumn get kcal => real()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  RealColumn get sugarG => real().nullable()();
  RealColumn get saturatesG => real().nullable()();
  RealColumn get fibreG => real().nullable()();
  RealColumn get saltG => real().nullable()();

  BoolColumn get isCookingFat => boolean().withDefault(const Constant(false))();
  RealColumn get estimatedGrams => real().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A user's own foods and recipes-as-foods. The shared catalogue ships as a
/// separate read-only database (Phase 2), not in here.
class Foods extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get source => text()();
  BoolColumn get isCooked => boolean().withDefault(const Constant(false))();
  RealColumn get kcal100g => real().named('kcal_100g')();
  RealColumn get protein100g => real().named('protein_100g').nullable()();
  RealColumn get carb100g => real().named('carb_100g').nullable()();
  RealColumn get sugar100g => real().named('sugar_100g').nullable()();
  RealColumn get fat100g => real().named('fat_100g').nullable()();
  RealColumn get saturates100g => real().named('saturates_100g').nullable()();
  RealColumn get fibre100g => real().named('fibre_100g').nullable()();
  RealColumn get salt100g => real().named('salt_100g').nullable()();

  /// JSON list of `{label, grams}`.
  TextColumn get householdMeasures =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Recipes extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();

  /// The finished dish as weighed, not the sum of its ingredients.
  RealColumn get yieldGrams => real()();
  RealColumn get kcal100g => real().named('kcal_100g')();
  RealColumn get protein100g => real().named('protein_100g').nullable()();
  RealColumn get carb100g => real().named('carb_100g').nullable()();
  RealColumn get fat100g => real().named('fat_100g').nullable()();

  /// JSON list of components.
  TextColumn get ingredients => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DailyTargets extends Table with SyncColumns, Tombstone {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// ISO date, `YYYY-MM-DD`.
  TextColumn get effectiveFrom => text()();
  IntColumn get kcal => integer()();
  IntColumn get proteinG => integer().nullable()();
  IntColumn get carbG => integer().nullable()();
  IntColumn get fatG => integer().nullable()();
  TextColumn get basis => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local-only key/value: the placeholder user id, and the last pull marker per
/// table.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
