// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
      'date_of_birth', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heightCmMeta =
      const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
      'height_cm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _activityMeta =
      const VerificationMeta('activity');
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
      'activity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('low_active'));
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
      'units', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('metric'));
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('GB'));
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
      'goal', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('maintain'));
  static const VerificationMeta _targetWeightKgMeta =
      const VerificationMeta('targetWeightKg');
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
      'target_weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _paceKgPerWeekMeta =
      const VerificationMeta('paceKgPerWeek');
  @override
  late final GeneratedColumn<double> paceKgPerWeek = GeneratedColumn<double>(
      'pace_kg_per_week', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _macroSplitMeta =
      const VerificationMeta('macroSplit');
  @override
  late final GeneratedColumn<String> macroSplit = GeneratedColumn<String>(
      'macro_split', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('balanced'));
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        id,
        displayName,
        dateOfBirth,
        sex,
        heightCm,
        activity,
        units,
        country,
        goal,
        targetWeightKg,
        paceKgPerWeek,
        macroSplit
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta,
          heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    }
    if (data.containsKey('activity')) {
      context.handle(_activityMeta,
          activity.isAcceptableOrUnknown(data['activity']!, _activityMeta));
    }
    if (data.containsKey('units')) {
      context.handle(
          _unitsMeta, units.isAcceptableOrUnknown(data['units']!, _unitsMeta));
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    }
    if (data.containsKey('goal')) {
      context.handle(
          _goalMeta, goal.isAcceptableOrUnknown(data['goal']!, _goalMeta));
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
          _targetWeightKgMeta,
          targetWeightKg.isAcceptableOrUnknown(
              data['target_weight_kg']!, _targetWeightKgMeta));
    }
    if (data.containsKey('pace_kg_per_week')) {
      context.handle(
          _paceKgPerWeekMeta,
          paceKgPerWeek.isAcceptableOrUnknown(
              data['pace_kg_per_week']!, _paceKgPerWeekMeta));
    }
    if (data.containsKey('macro_split')) {
      context.handle(
          _macroSplitMeta,
          macroSplit.isAcceptableOrUnknown(
              data['macro_split']!, _macroSplitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_of_birth']),
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex']),
      heightCm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height_cm']),
      activity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity'])!,
      units: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}units'])!,
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country'])!,
      goal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal'])!,
      targetWeightKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_weight_kg']),
      paceKgPerWeek: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}pace_kg_per_week']),
      macroSplit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}macro_split'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;

  /// The user id. Before sign-in this is a local placeholder; on sign-in every
  /// row is re-keyed to the real uid in one pass (see AppDatabase.adoptUser).
  final String id;
  final String? displayName;

  /// ISO date, `YYYY-MM-DD`. Stored as the date so a birthday advances the age
  /// naturally; every measurement snapshots the age it was taken at.
  final String? dateOfBirth;
  final String? sex;
  final double? heightCm;
  final String activity;
  final String units;
  final String country;
  final String goal;
  final double? targetWeightKg;

  /// 0.25–1.0. Null means the default pace.
  final double? paceKgPerWeek;
  final String macroSplit;
  const Profile(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      required this.id,
      this.displayName,
      this.dateOfBirth,
      this.sex,
      this.heightCm,
      required this.activity,
      required this.units,
      required this.country,
      required this.goal,
      this.targetWeightKg,
      this.paceKgPerWeek,
      required this.macroSplit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    map['activity'] = Variable<String>(activity);
    map['units'] = Variable<String>(units);
    map['country'] = Variable<String>(country);
    map['goal'] = Variable<String>(goal);
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    if (!nullToAbsent || paceKgPerWeek != null) {
      map['pace_kg_per_week'] = Variable<double>(paceKgPerWeek);
    }
    map['macro_split'] = Variable<String>(macroSplit);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      id: Value(id),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      activity: Value(activity),
      units: Value(units),
      country: Value(country),
      goal: Value(goal),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
      paceKgPerWeek: paceKgPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(paceKgPerWeek),
      macroSplit: Value(macroSplit),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      dateOfBirth: serializer.fromJson<String?>(json['dateOfBirth']),
      sex: serializer.fromJson<String?>(json['sex']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      activity: serializer.fromJson<String>(json['activity']),
      units: serializer.fromJson<String>(json['units']),
      country: serializer.fromJson<String>(json['country']),
      goal: serializer.fromJson<String>(json['goal']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
      paceKgPerWeek: serializer.fromJson<double?>(json['paceKgPerWeek']),
      macroSplit: serializer.fromJson<String>(json['macroSplit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String?>(displayName),
      'dateOfBirth': serializer.toJson<String?>(dateOfBirth),
      'sex': serializer.toJson<String?>(sex),
      'heightCm': serializer.toJson<double?>(heightCm),
      'activity': serializer.toJson<String>(activity),
      'units': serializer.toJson<String>(units),
      'country': serializer.toJson<String>(country),
      'goal': serializer.toJson<String>(goal),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
      'paceKgPerWeek': serializer.toJson<double?>(paceKgPerWeek),
      'macroSplit': serializer.toJson<String>(macroSplit),
    };
  }

  Profile copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          String? id,
          Value<String?> displayName = const Value.absent(),
          Value<String?> dateOfBirth = const Value.absent(),
          Value<String?> sex = const Value.absent(),
          Value<double?> heightCm = const Value.absent(),
          String? activity,
          String? units,
          String? country,
          String? goal,
          Value<double?> targetWeightKg = const Value.absent(),
          Value<double?> paceKgPerWeek = const Value.absent(),
          String? macroSplit}) =>
      Profile(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        id: id ?? this.id,
        displayName: displayName.present ? displayName.value : this.displayName,
        dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
        sex: sex.present ? sex.value : this.sex,
        heightCm: heightCm.present ? heightCm.value : this.heightCm,
        activity: activity ?? this.activity,
        units: units ?? this.units,
        country: country ?? this.country,
        goal: goal ?? this.goal,
        targetWeightKg:
            targetWeightKg.present ? targetWeightKg.value : this.targetWeightKg,
        paceKgPerWeek:
            paceKgPerWeek.present ? paceKgPerWeek.value : this.paceKgPerWeek,
        macroSplit: macroSplit ?? this.macroSplit,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      activity: data.activity.present ? data.activity.value : this.activity,
      units: data.units.present ? data.units.value : this.units,
      country: data.country.present ? data.country.value : this.country,
      goal: data.goal.present ? data.goal.value : this.goal,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      paceKgPerWeek: data.paceKgPerWeek.present
          ? data.paceKgPerWeek.value
          : this.paceKgPerWeek,
      macroSplit:
          data.macroSplit.present ? data.macroSplit.value : this.macroSplit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('activity: $activity, ')
          ..write('units: $units, ')
          ..write('country: $country, ')
          ..write('goal: $goal, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('paceKgPerWeek: $paceKgPerWeek, ')
          ..write('macroSplit: $macroSplit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      createdAt,
      updatedAt,
      syncedAt,
      id,
      displayName,
      dateOfBirth,
      sex,
      heightCm,
      activity,
      units,
      country,
      goal,
      targetWeightKg,
      paceKgPerWeek,
      macroSplit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.dateOfBirth == this.dateOfBirth &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.activity == this.activity &&
          other.units == this.units &&
          other.country == this.country &&
          other.goal == this.goal &&
          other.targetWeightKg == this.targetWeightKg &&
          other.paceKgPerWeek == this.paceKgPerWeek &&
          other.macroSplit == this.macroSplit);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String> id;
  final Value<String?> displayName;
  final Value<String?> dateOfBirth;
  final Value<String?> sex;
  final Value<double?> heightCm;
  final Value<String> activity;
  final Value<String> units;
  final Value<String> country;
  final Value<String> goal;
  final Value<double?> targetWeightKg;
  final Value<double?> paceKgPerWeek;
  final Value<String> macroSplit;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.activity = const Value.absent(),
    this.units = const Value.absent(),
    this.country = const Value.absent(),
    this.goal = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.paceKgPerWeek = const Value.absent(),
    this.macroSplit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    required String id,
    this.displayName = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.activity = const Value.absent(),
    this.units = const Value.absent(),
    this.country = const Value.absent(),
    this.goal = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.paceKgPerWeek = const Value.absent(),
    this.macroSplit = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id);
  static Insertable<Profile> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? dateOfBirth,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<String>? activity,
    Expression<String>? units,
    Expression<String>? country,
    Expression<String>? goal,
    Expression<double>? targetWeightKg,
    Expression<double>? paceKgPerWeek,
    Expression<String>? macroSplit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (activity != null) 'activity': activity,
      if (units != null) 'units': units,
      if (country != null) 'country': country,
      if (goal != null) 'goal': goal,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (paceKgPerWeek != null) 'pace_kg_per_week': paceKgPerWeek,
      if (macroSplit != null) 'macro_split': macroSplit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<String>? id,
      Value<String?>? displayName,
      Value<String?>? dateOfBirth,
      Value<String?>? sex,
      Value<double?>? heightCm,
      Value<String>? activity,
      Value<String>? units,
      Value<String>? country,
      Value<String>? goal,
      Value<double?>? targetWeightKg,
      Value<double?>? paceKgPerWeek,
      Value<String>? macroSplit,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      activity: activity ?? this.activity,
      units: units ?? this.units,
      country: country ?? this.country,
      goal: goal ?? this.goal,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      paceKgPerWeek: paceKgPerWeek ?? this.paceKgPerWeek,
      macroSplit: macroSplit ?? this.macroSplit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (paceKgPerWeek.present) {
      map['pace_kg_per_week'] = Variable<double>(paceKgPerWeek.value);
    }
    if (macroSplit.present) {
      map['macro_split'] = Variable<String>(macroSplit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('activity: $activity, ')
          ..write('units: $units, ')
          ..write('country: $country, ')
          ..write('goal: $goal, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('paceKgPerWeek: $paceKgPerWeek, ')
          ..write('macroSplit: $macroSplit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentsTable extends Consents with TableInfo<$ConsentsTable, Consent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _policyVersionMeta =
      const VerificationMeta('policyVersion');
  @override
  late final GeneratedColumn<String> policyVersion = GeneratedColumn<String>(
      'policy_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grantedMeta =
      const VerificationMeta('granted');
  @override
  late final GeneratedColumn<bool> granted = GeneratedColumn<bool>(
      'granted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("granted" IN (0, 1))'));
  static const VerificationMeta _grantedAtMeta =
      const VerificationMeta('grantedAt');
  @override
  late final GeneratedColumn<DateTime> grantedAt = GeneratedColumn<DateTime>(
      'granted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('app'));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        purpose,
        policyVersion,
        granted,
        grantedAt,
        source,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consents';
  @override
  VerificationContext validateIntegrity(Insertable<Consent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    if (data.containsKey('policy_version')) {
      context.handle(
          _policyVersionMeta,
          policyVersion.isAcceptableOrUnknown(
              data['policy_version']!, _policyVersionMeta));
    } else if (isInserting) {
      context.missing(_policyVersionMeta);
    }
    if (data.containsKey('granted')) {
      context.handle(_grantedMeta,
          granted.isAcceptableOrUnknown(data['granted']!, _grantedMeta));
    } else if (isInserting) {
      context.missing(_grantedMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(_grantedAtMeta,
          grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta));
    } else if (isInserting) {
      context.missing(_grantedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Consent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Consent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose'])!,
      policyVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policy_version'])!,
      granted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}granted'])!,
      grantedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}granted_at'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $ConsentsTable createAlias(String alias) {
    return $ConsentsTable(attachedDatabase, alias);
  }
}

class Consent extends DataClass implements Insertable<Consent> {
  final String id;
  final String userId;
  final String purpose;
  final String policyVersion;
  final bool granted;
  final DateTime grantedAt;
  final String source;
  final DateTime? syncedAt;
  const Consent(
      {required this.id,
      required this.userId,
      required this.purpose,
      required this.policyVersion,
      required this.granted,
      required this.grantedAt,
      required this.source,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['purpose'] = Variable<String>(purpose);
    map['policy_version'] = Variable<String>(policyVersion);
    map['granted'] = Variable<bool>(granted);
    map['granted_at'] = Variable<DateTime>(grantedAt);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  ConsentsCompanion toCompanion(bool nullToAbsent) {
    return ConsentsCompanion(
      id: Value(id),
      userId: Value(userId),
      purpose: Value(purpose),
      policyVersion: Value(policyVersion),
      granted: Value(granted),
      grantedAt: Value(grantedAt),
      source: Value(source),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory Consent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Consent(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      purpose: serializer.fromJson<String>(json['purpose']),
      policyVersion: serializer.fromJson<String>(json['policyVersion']),
      granted: serializer.fromJson<bool>(json['granted']),
      grantedAt: serializer.fromJson<DateTime>(json['grantedAt']),
      source: serializer.fromJson<String>(json['source']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'purpose': serializer.toJson<String>(purpose),
      'policyVersion': serializer.toJson<String>(policyVersion),
      'granted': serializer.toJson<bool>(granted),
      'grantedAt': serializer.toJson<DateTime>(grantedAt),
      'source': serializer.toJson<String>(source),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  Consent copyWith(
          {String? id,
          String? userId,
          String? purpose,
          String? policyVersion,
          bool? granted,
          DateTime? grantedAt,
          String? source,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      Consent(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        purpose: purpose ?? this.purpose,
        policyVersion: policyVersion ?? this.policyVersion,
        granted: granted ?? this.granted,
        grantedAt: grantedAt ?? this.grantedAt,
        source: source ?? this.source,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  Consent copyWithCompanion(ConsentsCompanion data) {
    return Consent(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      policyVersion: data.policyVersion.present
          ? data.policyVersion.value
          : this.policyVersion,
      granted: data.granted.present ? data.granted.value : this.granted,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
      source: data.source.present ? data.source.value : this.source,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Consent(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('purpose: $purpose, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('granted: $granted, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, purpose, policyVersion, granted, grantedAt, source, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Consent &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.purpose == this.purpose &&
          other.policyVersion == this.policyVersion &&
          other.granted == this.granted &&
          other.grantedAt == this.grantedAt &&
          other.source == this.source &&
          other.syncedAt == this.syncedAt);
}

class ConsentsCompanion extends UpdateCompanion<Consent> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> purpose;
  final Value<String> policyVersion;
  final Value<bool> granted;
  final Value<DateTime> grantedAt;
  final Value<String> source;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const ConsentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.purpose = const Value.absent(),
    this.policyVersion = const Value.absent(),
    this.granted = const Value.absent(),
    this.grantedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentsCompanion.insert({
    required String id,
    required String userId,
    required String purpose,
    required String policyVersion,
    required bool granted,
    required DateTime grantedAt,
    this.source = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        purpose = Value(purpose),
        policyVersion = Value(policyVersion),
        granted = Value(granted),
        grantedAt = Value(grantedAt);
  static Insertable<Consent> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? purpose,
    Expression<String>? policyVersion,
    Expression<bool>? granted,
    Expression<DateTime>? grantedAt,
    Expression<String>? source,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (purpose != null) 'purpose': purpose,
      if (policyVersion != null) 'policy_version': policyVersion,
      if (granted != null) 'granted': granted,
      if (grantedAt != null) 'granted_at': grantedAt,
      if (source != null) 'source': source,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? purpose,
      Value<String>? policyVersion,
      Value<bool>? granted,
      Value<DateTime>? grantedAt,
      Value<String>? source,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return ConsentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      purpose: purpose ?? this.purpose,
      policyVersion: policyVersion ?? this.policyVersion,
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      source: source ?? this.source,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (policyVersion.present) {
      map['policy_version'] = Variable<String>(policyVersion.value);
    }
    if (granted.present) {
      map['granted'] = Variable<bool>(granted.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<DateTime>(grantedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('purpose: $purpose, ')
          ..write('policyVersion: $policyVersion, ')
          ..write('granted: $granted, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('source: $source, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObservationsTable extends Observations
    with TableInfo<$ObservationsTable, Observation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
      'taken_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
      'confidence', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _referenceLowMeta =
      const VerificationMeta('referenceLow');
  @override
  late final GeneratedColumn<double> referenceLow = GeneratedColumn<double>(
      'reference_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _referenceHighMeta =
      const VerificationMeta('referenceHigh');
  @override
  late final GeneratedColumn<double> referenceHigh = GeneratedColumn<double>(
      'reference_high', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _referenceSourceMeta =
      const VerificationMeta('referenceSource');
  @override
  late final GeneratedColumn<String> referenceSource = GeneratedColumn<String>(
      'reference_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
      'raw', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        takenAt,
        kind,
        value,
        unit,
        source,
        deviceId,
        method,
        confidence,
        referenceLow,
        referenceHigh,
        referenceSource,
        raw
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observations';
  @override
  VerificationContext validateIntegrity(Insertable<Observation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('reference_low')) {
      context.handle(
          _referenceLowMeta,
          referenceLow.isAcceptableOrUnknown(
              data['reference_low']!, _referenceLowMeta));
    }
    if (data.containsKey('reference_high')) {
      context.handle(
          _referenceHighMeta,
          referenceHigh.isAcceptableOrUnknown(
              data['reference_high']!, _referenceHighMeta));
    }
    if (data.containsKey('reference_source')) {
      context.handle(
          _referenceSourceMeta,
          referenceSource.isAcceptableOrUnknown(
              data['reference_source']!, _referenceSourceMeta));
    }
    if (data.containsKey('raw')) {
      context.handle(
          _rawMeta, raw.isAcceptableOrUnknown(data['raw']!, _rawMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Observation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Observation(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}taken_at'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id']),
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}confidence']),
      referenceLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reference_low']),
      referenceHigh: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reference_high']),
      referenceSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_source']),
      raw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw']),
    );
  }

  @override
  $ObservationsTable createAlias(String alias) {
    return $ObservationsTable(attachedDatabase, alias);
  }
}

class Observation extends DataClass implements Insertable<Observation> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final DateTime takenAt;
  final String kind;
  final double value;
  final String unit;
  final String source;
  final String? deviceId;
  final String? method;
  final String? confidence;
  final double? referenceLow;
  final double? referenceHigh;
  final String? referenceSource;

  /// JSON. The source payload, never discarded.
  final String? raw;
  const Observation(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.userId,
      required this.takenAt,
      required this.kind,
      required this.value,
      required this.unit,
      required this.source,
      this.deviceId,
      this.method,
      this.confidence,
      this.referenceLow,
      this.referenceHigh,
      this.referenceSource,
      this.raw});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<String>(confidence);
    }
    if (!nullToAbsent || referenceLow != null) {
      map['reference_low'] = Variable<double>(referenceLow);
    }
    if (!nullToAbsent || referenceHigh != null) {
      map['reference_high'] = Variable<double>(referenceHigh);
    }
    if (!nullToAbsent || referenceSource != null) {
      map['reference_source'] = Variable<String>(referenceSource);
    }
    if (!nullToAbsent || raw != null) {
      map['raw'] = Variable<String>(raw);
    }
    return map;
  }

  ObservationsCompanion toCompanion(bool nullToAbsent) {
    return ObservationsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      takenAt: Value(takenAt),
      kind: Value(kind),
      value: Value(value),
      unit: Value(unit),
      source: Value(source),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      method:
          method == null && nullToAbsent ? const Value.absent() : Value(method),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      referenceLow: referenceLow == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceLow),
      referenceHigh: referenceHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceHigh),
      referenceSource: referenceSource == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceSource),
      raw: raw == null && nullToAbsent ? const Value.absent() : Value(raw),
    );
  }

  factory Observation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Observation(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      source: serializer.fromJson<String>(json['source']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      method: serializer.fromJson<String?>(json['method']),
      confidence: serializer.fromJson<String?>(json['confidence']),
      referenceLow: serializer.fromJson<double?>(json['referenceLow']),
      referenceHigh: serializer.fromJson<double?>(json['referenceHigh']),
      referenceSource: serializer.fromJson<String?>(json['referenceSource']),
      raw: serializer.fromJson<String?>(json['raw']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'source': serializer.toJson<String>(source),
      'deviceId': serializer.toJson<String?>(deviceId),
      'method': serializer.toJson<String?>(method),
      'confidence': serializer.toJson<String?>(confidence),
      'referenceLow': serializer.toJson<double?>(referenceLow),
      'referenceHigh': serializer.toJson<double?>(referenceHigh),
      'referenceSource': serializer.toJson<String?>(referenceSource),
      'raw': serializer.toJson<String?>(raw),
    };
  }

  Observation copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? userId,
          DateTime? takenAt,
          String? kind,
          double? value,
          String? unit,
          String? source,
          Value<String?> deviceId = const Value.absent(),
          Value<String?> method = const Value.absent(),
          Value<String?> confidence = const Value.absent(),
          Value<double?> referenceLow = const Value.absent(),
          Value<double?> referenceHigh = const Value.absent(),
          Value<String?> referenceSource = const Value.absent(),
          Value<String?> raw = const Value.absent()}) =>
      Observation(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId ?? this.userId,
        takenAt: takenAt ?? this.takenAt,
        kind: kind ?? this.kind,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        source: source ?? this.source,
        deviceId: deviceId.present ? deviceId.value : this.deviceId,
        method: method.present ? method.value : this.method,
        confidence: confidence.present ? confidence.value : this.confidence,
        referenceLow:
            referenceLow.present ? referenceLow.value : this.referenceLow,
        referenceHigh:
            referenceHigh.present ? referenceHigh.value : this.referenceHigh,
        referenceSource: referenceSource.present
            ? referenceSource.value
            : this.referenceSource,
        raw: raw.present ? raw.value : this.raw,
      );
  Observation copyWithCompanion(ObservationsCompanion data) {
    return Observation(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      source: data.source.present ? data.source.value : this.source,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      method: data.method.present ? data.method.value : this.method,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      referenceLow: data.referenceLow.present
          ? data.referenceLow.value
          : this.referenceLow,
      referenceHigh: data.referenceHigh.present
          ? data.referenceHigh.value
          : this.referenceHigh,
      referenceSource: data.referenceSource.present
          ? data.referenceSource.value
          : this.referenceSource,
      raw: data.raw.present ? data.raw.value : this.raw,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Observation(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('takenAt: $takenAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('source: $source, ')
          ..write('deviceId: $deviceId, ')
          ..write('method: $method, ')
          ..write('confidence: $confidence, ')
          ..write('referenceLow: $referenceLow, ')
          ..write('referenceHigh: $referenceHigh, ')
          ..write('referenceSource: $referenceSource, ')
          ..write('raw: $raw')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      createdAt,
      updatedAt,
      syncedAt,
      deletedAt,
      id,
      userId,
      takenAt,
      kind,
      value,
      unit,
      source,
      deviceId,
      method,
      confidence,
      referenceLow,
      referenceHigh,
      referenceSource,
      raw);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Observation &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.takenAt == this.takenAt &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.source == this.source &&
          other.deviceId == this.deviceId &&
          other.method == this.method &&
          other.confidence == this.confidence &&
          other.referenceLow == this.referenceLow &&
          other.referenceHigh == this.referenceHigh &&
          other.referenceSource == this.referenceSource &&
          other.raw == this.raw);
}

class ObservationsCompanion extends UpdateCompanion<Observation> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> takenAt;
  final Value<String> kind;
  final Value<double> value;
  final Value<String> unit;
  final Value<String> source;
  final Value<String?> deviceId;
  final Value<String?> method;
  final Value<String?> confidence;
  final Value<double?> referenceLow;
  final Value<double?> referenceHigh;
  final Value<String?> referenceSource;
  final Value<String?> raw;
  final Value<int> rowid;
  const ObservationsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.source = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.method = const Value.absent(),
    this.confidence = const Value.absent(),
    this.referenceLow = const Value.absent(),
    this.referenceHigh = const Value.absent(),
    this.referenceSource = const Value.absent(),
    this.raw = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObservationsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    required DateTime takenAt,
    required String kind,
    required double value,
    required String unit,
    required String source,
    this.deviceId = const Value.absent(),
    this.method = const Value.absent(),
    this.confidence = const Value.absent(),
    this.referenceLow = const Value.absent(),
    this.referenceHigh = const Value.absent(),
    this.referenceSource = const Value.absent(),
    this.raw = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        userId = Value(userId),
        takenAt = Value(takenAt),
        kind = Value(kind),
        value = Value(value),
        unit = Value(unit),
        source = Value(source);
  static Insertable<Observation> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? takenAt,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<String>? source,
    Expression<String>? deviceId,
    Expression<String>? method,
    Expression<String>? confidence,
    Expression<double>? referenceLow,
    Expression<double>? referenceHigh,
    Expression<String>? referenceSource,
    Expression<String>? raw,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (takenAt != null) 'taken_at': takenAt,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (source != null) 'source': source,
      if (deviceId != null) 'device_id': deviceId,
      if (method != null) 'method': method,
      if (confidence != null) 'confidence': confidence,
      if (referenceLow != null) 'reference_low': referenceLow,
      if (referenceHigh != null) 'reference_high': referenceHigh,
      if (referenceSource != null) 'reference_source': referenceSource,
      if (raw != null) 'raw': raw,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObservationsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? takenAt,
      Value<String>? kind,
      Value<double>? value,
      Value<String>? unit,
      Value<String>? source,
      Value<String?>? deviceId,
      Value<String?>? method,
      Value<String?>? confidence,
      Value<double?>? referenceLow,
      Value<double?>? referenceHigh,
      Value<String?>? referenceSource,
      Value<String?>? raw,
      Value<int>? rowid}) {
    return ObservationsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      takenAt: takenAt ?? this.takenAt,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      deviceId: deviceId ?? this.deviceId,
      method: method ?? this.method,
      confidence: confidence ?? this.confidence,
      referenceLow: referenceLow ?? this.referenceLow,
      referenceHigh: referenceHigh ?? this.referenceHigh,
      referenceSource: referenceSource ?? this.referenceSource,
      raw: raw ?? this.raw,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (referenceLow.present) {
      map['reference_low'] = Variable<double>(referenceLow.value);
    }
    if (referenceHigh.present) {
      map['reference_high'] = Variable<double>(referenceHigh.value);
    }
    if (referenceSource.present) {
      map['reference_source'] = Variable<String>(referenceSource.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservationsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('takenAt: $takenAt, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('source: $source, ')
          ..write('deviceId: $deviceId, ')
          ..write('method: $method, ')
          ..write('confidence: $confidence, ')
          ..write('referenceLow: $referenceLow, ')
          ..write('referenceHigh: $referenceHigh, ')
          ..write('referenceSource: $referenceSource, ')
          ..write('raw: $raw, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _takenAtMeta =
      const VerificationMeta('takenAt');
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
      'taken_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _weightKgMeta =
      const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
      'weight_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _impedanceOhmMeta =
      const VerificationMeta('impedanceOhm');
  @override
  late final GeneratedColumn<double> impedanceOhm = GeneratedColumn<double>(
      'impedance_ohm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reactanceOhmMeta =
      const VerificationMeta('reactanceOhm');
  @override
  late final GeneratedColumn<double> reactanceOhm = GeneratedColumn<double>(
      'reactance_ohm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _segmentalRawMeta =
      const VerificationMeta('segmentalRaw');
  @override
  late final GeneratedColumn<String> segmentalRaw = GeneratedColumn<String>(
      'segmental_raw', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heartRateBpmMeta =
      const VerificationMeta('heartRateBpm');
  @override
  late final GeneratedColumn<int> heartRateBpm = GeneratedColumn<int>(
      'heart_rate_bpm', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightCmAtTimeMeta =
      const VerificationMeta('heightCmAtTime');
  @override
  late final GeneratedColumn<double> heightCmAtTime = GeneratedColumn<double>(
      'height_cm_at_time', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ageYearsAtTimeMeta =
      const VerificationMeta('ageYearsAtTime');
  @override
  late final GeneratedColumn<int> ageYearsAtTime = GeneratedColumn<int>(
      'age_years_at_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sexAtTimeMeta =
      const VerificationMeta('sexAtTime');
  @override
  late final GeneratedColumn<String> sexAtTime = GeneratedColumn<String>(
      'sex_at_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fatFreeMassKgMeta =
      const VerificationMeta('fatFreeMassKg');
  @override
  late final GeneratedColumn<double> fatFreeMassKg = GeneratedColumn<double>(
      'fat_free_mass_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bodyFatPercentMeta =
      const VerificationMeta('bodyFatPercent');
  @override
  late final GeneratedColumn<double> bodyFatPercent = GeneratedColumn<double>(
      'body_fat_percent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalBodyWaterLMeta =
      const VerificationMeta('totalBodyWaterL');
  @override
  late final GeneratedColumn<double> totalBodyWaterL = GeneratedColumn<double>(
      'total_body_water_l', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _skeletalMuscleKgMeta =
      const VerificationMeta('skeletalMuscleKg');
  @override
  late final GeneratedColumn<double> skeletalMuscleKg = GeneratedColumn<double>(
      'skeletal_muscle_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _restingKcalMeta =
      const VerificationMeta('restingKcal');
  @override
  late final GeneratedColumn<int> restingKcal = GeneratedColumn<int>(
      'resting_kcal', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _equationMeta =
      const VerificationMeta('equation');
  @override
  late final GeneratedColumn<String> equation = GeneratedColumn<String>(
      'equation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
      'confidence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('good'));
  static const VerificationMeta _contextMeta =
      const VerificationMeta('context');
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
      'context', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        deviceId,
        takenAt,
        weightKg,
        impedanceOhm,
        reactanceOhm,
        segmentalRaw,
        heartRateBpm,
        heightCmAtTime,
        ageYearsAtTime,
        sexAtTime,
        fatFreeMassKg,
        bodyFatPercent,
        totalBodyWaterL,
        skeletalMuscleKg,
        restingKcal,
        equation,
        confidence,
        context,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(Insertable<BodyMeasurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    if (data.containsKey('taken_at')) {
      context.handle(_takenAtMeta,
          takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta));
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta,
          weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('impedance_ohm')) {
      context.handle(
          _impedanceOhmMeta,
          impedanceOhm.isAcceptableOrUnknown(
              data['impedance_ohm']!, _impedanceOhmMeta));
    }
    if (data.containsKey('reactance_ohm')) {
      context.handle(
          _reactanceOhmMeta,
          reactanceOhm.isAcceptableOrUnknown(
              data['reactance_ohm']!, _reactanceOhmMeta));
    }
    if (data.containsKey('segmental_raw')) {
      context.handle(
          _segmentalRawMeta,
          segmentalRaw.isAcceptableOrUnknown(
              data['segmental_raw']!, _segmentalRawMeta));
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
          _heartRateBpmMeta,
          heartRateBpm.isAcceptableOrUnknown(
              data['heart_rate_bpm']!, _heartRateBpmMeta));
    }
    if (data.containsKey('height_cm_at_time')) {
      context.handle(
          _heightCmAtTimeMeta,
          heightCmAtTime.isAcceptableOrUnknown(
              data['height_cm_at_time']!, _heightCmAtTimeMeta));
    }
    if (data.containsKey('age_years_at_time')) {
      context.handle(
          _ageYearsAtTimeMeta,
          ageYearsAtTime.isAcceptableOrUnknown(
              data['age_years_at_time']!, _ageYearsAtTimeMeta));
    }
    if (data.containsKey('sex_at_time')) {
      context.handle(
          _sexAtTimeMeta,
          sexAtTime.isAcceptableOrUnknown(
              data['sex_at_time']!, _sexAtTimeMeta));
    }
    if (data.containsKey('fat_free_mass_kg')) {
      context.handle(
          _fatFreeMassKgMeta,
          fatFreeMassKg.isAcceptableOrUnknown(
              data['fat_free_mass_kg']!, _fatFreeMassKgMeta));
    }
    if (data.containsKey('body_fat_percent')) {
      context.handle(
          _bodyFatPercentMeta,
          bodyFatPercent.isAcceptableOrUnknown(
              data['body_fat_percent']!, _bodyFatPercentMeta));
    }
    if (data.containsKey('total_body_water_l')) {
      context.handle(
          _totalBodyWaterLMeta,
          totalBodyWaterL.isAcceptableOrUnknown(
              data['total_body_water_l']!, _totalBodyWaterLMeta));
    }
    if (data.containsKey('skeletal_muscle_kg')) {
      context.handle(
          _skeletalMuscleKgMeta,
          skeletalMuscleKg.isAcceptableOrUnknown(
              data['skeletal_muscle_kg']!, _skeletalMuscleKgMeta));
    }
    if (data.containsKey('resting_kcal')) {
      context.handle(
          _restingKcalMeta,
          restingKcal.isAcceptableOrUnknown(
              data['resting_kcal']!, _restingKcalMeta));
    }
    if (data.containsKey('equation')) {
      context.handle(_equationMeta,
          equation.isAcceptableOrUnknown(data['equation']!, _equationMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('context')) {
      context.handle(_contextMeta,
          this.context.isAcceptableOrUnknown(data['context']!, _contextMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id']),
      takenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}taken_at'])!,
      weightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      impedanceOhm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}impedance_ohm']),
      reactanceOhm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reactance_ohm']),
      segmentalRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}segmental_raw']),
      heartRateBpm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heart_rate_bpm']),
      heightCmAtTime: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}height_cm_at_time']),
      ageYearsAtTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age_years_at_time']),
      sexAtTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex_at_time']),
      fatFreeMassKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fat_free_mass_kg']),
      bodyFatPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}body_fat_percent']),
      totalBodyWaterL: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_body_water_l']),
      skeletalMuscleKg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}skeletal_muscle_kg']),
      restingKcal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}resting_kcal']),
      equation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equation']),
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}confidence'])!,
      context: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}context'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final String? deviceId;
  final DateTime takenAt;
  final double weightKg;
  final double? impedanceOhm;
  final double? reactanceOhm;

  /// JSON. Vendor-encoded segmental values, kept raw for a later decode.
  final String? segmentalRaw;
  final int? heartRateBpm;
  final double? heightCmAtTime;
  final int? ageYearsAtTime;
  final String? sexAtTime;
  final double? fatFreeMassKg;
  final double? bodyFatPercent;
  final double? totalBodyWaterL;
  final double? skeletalMuscleKg;
  final int? restingKcal;

  /// Which published equation produced the derived columns, e.g. `sun2003`.
  final String? equation;
  final String confidence;

  /// JSON. Conditions the user reported.
  final String context;

  /// JSON list. What the user was told about this reading.
  final String notes;
  const BodyMeasurement(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.userId,
      this.deviceId,
      required this.takenAt,
      required this.weightKg,
      this.impedanceOhm,
      this.reactanceOhm,
      this.segmentalRaw,
      this.heartRateBpm,
      this.heightCmAtTime,
      this.ageYearsAtTime,
      this.sexAtTime,
      this.fatFreeMassKg,
      this.bodyFatPercent,
      this.totalBodyWaterL,
      this.skeletalMuscleKg,
      this.restingKcal,
      this.equation,
      required this.confidence,
      required this.context,
      required this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || impedanceOhm != null) {
      map['impedance_ohm'] = Variable<double>(impedanceOhm);
    }
    if (!nullToAbsent || reactanceOhm != null) {
      map['reactance_ohm'] = Variable<double>(reactanceOhm);
    }
    if (!nullToAbsent || segmentalRaw != null) {
      map['segmental_raw'] = Variable<String>(segmentalRaw);
    }
    if (!nullToAbsent || heartRateBpm != null) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm);
    }
    if (!nullToAbsent || heightCmAtTime != null) {
      map['height_cm_at_time'] = Variable<double>(heightCmAtTime);
    }
    if (!nullToAbsent || ageYearsAtTime != null) {
      map['age_years_at_time'] = Variable<int>(ageYearsAtTime);
    }
    if (!nullToAbsent || sexAtTime != null) {
      map['sex_at_time'] = Variable<String>(sexAtTime);
    }
    if (!nullToAbsent || fatFreeMassKg != null) {
      map['fat_free_mass_kg'] = Variable<double>(fatFreeMassKg);
    }
    if (!nullToAbsent || bodyFatPercent != null) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent);
    }
    if (!nullToAbsent || totalBodyWaterL != null) {
      map['total_body_water_l'] = Variable<double>(totalBodyWaterL);
    }
    if (!nullToAbsent || skeletalMuscleKg != null) {
      map['skeletal_muscle_kg'] = Variable<double>(skeletalMuscleKg);
    }
    if (!nullToAbsent || restingKcal != null) {
      map['resting_kcal'] = Variable<int>(restingKcal);
    }
    if (!nullToAbsent || equation != null) {
      map['equation'] = Variable<String>(equation);
    }
    map['confidence'] = Variable<String>(confidence);
    map['context'] = Variable<String>(context);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      takenAt: Value(takenAt),
      weightKg: Value(weightKg),
      impedanceOhm: impedanceOhm == null && nullToAbsent
          ? const Value.absent()
          : Value(impedanceOhm),
      reactanceOhm: reactanceOhm == null && nullToAbsent
          ? const Value.absent()
          : Value(reactanceOhm),
      segmentalRaw: segmentalRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentalRaw),
      heartRateBpm: heartRateBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateBpm),
      heightCmAtTime: heightCmAtTime == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCmAtTime),
      ageYearsAtTime: ageYearsAtTime == null && nullToAbsent
          ? const Value.absent()
          : Value(ageYearsAtTime),
      sexAtTime: sexAtTime == null && nullToAbsent
          ? const Value.absent()
          : Value(sexAtTime),
      fatFreeMassKg: fatFreeMassKg == null && nullToAbsent
          ? const Value.absent()
          : Value(fatFreeMassKg),
      bodyFatPercent: bodyFatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercent),
      totalBodyWaterL: totalBodyWaterL == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBodyWaterL),
      skeletalMuscleKg: skeletalMuscleKg == null && nullToAbsent
          ? const Value.absent()
          : Value(skeletalMuscleKg),
      restingKcal: restingKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(restingKcal),
      equation: equation == null && nullToAbsent
          ? const Value.absent()
          : Value(equation),
      confidence: Value(confidence),
      context: Value(context),
      notes: Value(notes),
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      impedanceOhm: serializer.fromJson<double?>(json['impedanceOhm']),
      reactanceOhm: serializer.fromJson<double?>(json['reactanceOhm']),
      segmentalRaw: serializer.fromJson<String?>(json['segmentalRaw']),
      heartRateBpm: serializer.fromJson<int?>(json['heartRateBpm']),
      heightCmAtTime: serializer.fromJson<double?>(json['heightCmAtTime']),
      ageYearsAtTime: serializer.fromJson<int?>(json['ageYearsAtTime']),
      sexAtTime: serializer.fromJson<String?>(json['sexAtTime']),
      fatFreeMassKg: serializer.fromJson<double?>(json['fatFreeMassKg']),
      bodyFatPercent: serializer.fromJson<double?>(json['bodyFatPercent']),
      totalBodyWaterL: serializer.fromJson<double?>(json['totalBodyWaterL']),
      skeletalMuscleKg: serializer.fromJson<double?>(json['skeletalMuscleKg']),
      restingKcal: serializer.fromJson<int?>(json['restingKcal']),
      equation: serializer.fromJson<String?>(json['equation']),
      confidence: serializer.fromJson<String>(json['confidence']),
      context: serializer.fromJson<String>(json['context']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'weightKg': serializer.toJson<double>(weightKg),
      'impedanceOhm': serializer.toJson<double?>(impedanceOhm),
      'reactanceOhm': serializer.toJson<double?>(reactanceOhm),
      'segmentalRaw': serializer.toJson<String?>(segmentalRaw),
      'heartRateBpm': serializer.toJson<int?>(heartRateBpm),
      'heightCmAtTime': serializer.toJson<double?>(heightCmAtTime),
      'ageYearsAtTime': serializer.toJson<int?>(ageYearsAtTime),
      'sexAtTime': serializer.toJson<String?>(sexAtTime),
      'fatFreeMassKg': serializer.toJson<double?>(fatFreeMassKg),
      'bodyFatPercent': serializer.toJson<double?>(bodyFatPercent),
      'totalBodyWaterL': serializer.toJson<double?>(totalBodyWaterL),
      'skeletalMuscleKg': serializer.toJson<double?>(skeletalMuscleKg),
      'restingKcal': serializer.toJson<int?>(restingKcal),
      'equation': serializer.toJson<String?>(equation),
      'confidence': serializer.toJson<String>(confidence),
      'context': serializer.toJson<String>(context),
      'notes': serializer.toJson<String>(notes),
    };
  }

  BodyMeasurement copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? userId,
          Value<String?> deviceId = const Value.absent(),
          DateTime? takenAt,
          double? weightKg,
          Value<double?> impedanceOhm = const Value.absent(),
          Value<double?> reactanceOhm = const Value.absent(),
          Value<String?> segmentalRaw = const Value.absent(),
          Value<int?> heartRateBpm = const Value.absent(),
          Value<double?> heightCmAtTime = const Value.absent(),
          Value<int?> ageYearsAtTime = const Value.absent(),
          Value<String?> sexAtTime = const Value.absent(),
          Value<double?> fatFreeMassKg = const Value.absent(),
          Value<double?> bodyFatPercent = const Value.absent(),
          Value<double?> totalBodyWaterL = const Value.absent(),
          Value<double?> skeletalMuscleKg = const Value.absent(),
          Value<int?> restingKcal = const Value.absent(),
          Value<String?> equation = const Value.absent(),
          String? confidence,
          String? context,
          String? notes}) =>
      BodyMeasurement(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId ?? this.userId,
        deviceId: deviceId.present ? deviceId.value : this.deviceId,
        takenAt: takenAt ?? this.takenAt,
        weightKg: weightKg ?? this.weightKg,
        impedanceOhm:
            impedanceOhm.present ? impedanceOhm.value : this.impedanceOhm,
        reactanceOhm:
            reactanceOhm.present ? reactanceOhm.value : this.reactanceOhm,
        segmentalRaw:
            segmentalRaw.present ? segmentalRaw.value : this.segmentalRaw,
        heartRateBpm:
            heartRateBpm.present ? heartRateBpm.value : this.heartRateBpm,
        heightCmAtTime:
            heightCmAtTime.present ? heightCmAtTime.value : this.heightCmAtTime,
        ageYearsAtTime:
            ageYearsAtTime.present ? ageYearsAtTime.value : this.ageYearsAtTime,
        sexAtTime: sexAtTime.present ? sexAtTime.value : this.sexAtTime,
        fatFreeMassKg:
            fatFreeMassKg.present ? fatFreeMassKg.value : this.fatFreeMassKg,
        bodyFatPercent:
            bodyFatPercent.present ? bodyFatPercent.value : this.bodyFatPercent,
        totalBodyWaterL: totalBodyWaterL.present
            ? totalBodyWaterL.value
            : this.totalBodyWaterL,
        skeletalMuscleKg: skeletalMuscleKg.present
            ? skeletalMuscleKg.value
            : this.skeletalMuscleKg,
        restingKcal: restingKcal.present ? restingKcal.value : this.restingKcal,
        equation: equation.present ? equation.value : this.equation,
        confidence: confidence ?? this.confidence,
        context: context ?? this.context,
        notes: notes ?? this.notes,
      );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      impedanceOhm: data.impedanceOhm.present
          ? data.impedanceOhm.value
          : this.impedanceOhm,
      reactanceOhm: data.reactanceOhm.present
          ? data.reactanceOhm.value
          : this.reactanceOhm,
      segmentalRaw: data.segmentalRaw.present
          ? data.segmentalRaw.value
          : this.segmentalRaw,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      heightCmAtTime: data.heightCmAtTime.present
          ? data.heightCmAtTime.value
          : this.heightCmAtTime,
      ageYearsAtTime: data.ageYearsAtTime.present
          ? data.ageYearsAtTime.value
          : this.ageYearsAtTime,
      sexAtTime: data.sexAtTime.present ? data.sexAtTime.value : this.sexAtTime,
      fatFreeMassKg: data.fatFreeMassKg.present
          ? data.fatFreeMassKg.value
          : this.fatFreeMassKg,
      bodyFatPercent: data.bodyFatPercent.present
          ? data.bodyFatPercent.value
          : this.bodyFatPercent,
      totalBodyWaterL: data.totalBodyWaterL.present
          ? data.totalBodyWaterL.value
          : this.totalBodyWaterL,
      skeletalMuscleKg: data.skeletalMuscleKg.present
          ? data.skeletalMuscleKg.value
          : this.skeletalMuscleKg,
      restingKcal:
          data.restingKcal.present ? data.restingKcal.value : this.restingKcal,
      equation: data.equation.present ? data.equation.value : this.equation,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      context: data.context.present ? data.context.value : this.context,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('takenAt: $takenAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('impedanceOhm: $impedanceOhm, ')
          ..write('reactanceOhm: $reactanceOhm, ')
          ..write('segmentalRaw: $segmentalRaw, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('heightCmAtTime: $heightCmAtTime, ')
          ..write('ageYearsAtTime: $ageYearsAtTime, ')
          ..write('sexAtTime: $sexAtTime, ')
          ..write('fatFreeMassKg: $fatFreeMassKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('totalBodyWaterL: $totalBodyWaterL, ')
          ..write('skeletalMuscleKg: $skeletalMuscleKg, ')
          ..write('restingKcal: $restingKcal, ')
          ..write('equation: $equation, ')
          ..write('confidence: $confidence, ')
          ..write('context: $context, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        deviceId,
        takenAt,
        weightKg,
        impedanceOhm,
        reactanceOhm,
        segmentalRaw,
        heartRateBpm,
        heightCmAtTime,
        ageYearsAtTime,
        sexAtTime,
        fatFreeMassKg,
        bodyFatPercent,
        totalBodyWaterL,
        skeletalMuscleKg,
        restingKcal,
        equation,
        confidence,
        context,
        notes
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.takenAt == this.takenAt &&
          other.weightKg == this.weightKg &&
          other.impedanceOhm == this.impedanceOhm &&
          other.reactanceOhm == this.reactanceOhm &&
          other.segmentalRaw == this.segmentalRaw &&
          other.heartRateBpm == this.heartRateBpm &&
          other.heightCmAtTime == this.heightCmAtTime &&
          other.ageYearsAtTime == this.ageYearsAtTime &&
          other.sexAtTime == this.sexAtTime &&
          other.fatFreeMassKg == this.fatFreeMassKg &&
          other.bodyFatPercent == this.bodyFatPercent &&
          other.totalBodyWaterL == this.totalBodyWaterL &&
          other.skeletalMuscleKg == this.skeletalMuscleKg &&
          other.restingKcal == this.restingKcal &&
          other.equation == this.equation &&
          other.confidence == this.confidence &&
          other.context == this.context &&
          other.notes == this.notes);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> deviceId;
  final Value<DateTime> takenAt;
  final Value<double> weightKg;
  final Value<double?> impedanceOhm;
  final Value<double?> reactanceOhm;
  final Value<String?> segmentalRaw;
  final Value<int?> heartRateBpm;
  final Value<double?> heightCmAtTime;
  final Value<int?> ageYearsAtTime;
  final Value<String?> sexAtTime;
  final Value<double?> fatFreeMassKg;
  final Value<double?> bodyFatPercent;
  final Value<double?> totalBodyWaterL;
  final Value<double?> skeletalMuscleKg;
  final Value<int?> restingKcal;
  final Value<String?> equation;
  final Value<String> confidence;
  final Value<String> context;
  final Value<String> notes;
  final Value<int> rowid;
  const BodyMeasurementsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.impedanceOhm = const Value.absent(),
    this.reactanceOhm = const Value.absent(),
    this.segmentalRaw = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.heightCmAtTime = const Value.absent(),
    this.ageYearsAtTime = const Value.absent(),
    this.sexAtTime = const Value.absent(),
    this.fatFreeMassKg = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.totalBodyWaterL = const Value.absent(),
    this.skeletalMuscleKg = const Value.absent(),
    this.restingKcal = const Value.absent(),
    this.equation = const Value.absent(),
    this.confidence = const Value.absent(),
    this.context = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    this.deviceId = const Value.absent(),
    required DateTime takenAt,
    required double weightKg,
    this.impedanceOhm = const Value.absent(),
    this.reactanceOhm = const Value.absent(),
    this.segmentalRaw = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.heightCmAtTime = const Value.absent(),
    this.ageYearsAtTime = const Value.absent(),
    this.sexAtTime = const Value.absent(),
    this.fatFreeMassKg = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.totalBodyWaterL = const Value.absent(),
    this.skeletalMuscleKg = const Value.absent(),
    this.restingKcal = const Value.absent(),
    this.equation = const Value.absent(),
    this.confidence = const Value.absent(),
    this.context = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        userId = Value(userId),
        takenAt = Value(takenAt),
        weightKg = Value(weightKg);
  static Insertable<BodyMeasurement> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<DateTime>? takenAt,
    Expression<double>? weightKg,
    Expression<double>? impedanceOhm,
    Expression<double>? reactanceOhm,
    Expression<String>? segmentalRaw,
    Expression<int>? heartRateBpm,
    Expression<double>? heightCmAtTime,
    Expression<int>? ageYearsAtTime,
    Expression<String>? sexAtTime,
    Expression<double>? fatFreeMassKg,
    Expression<double>? bodyFatPercent,
    Expression<double>? totalBodyWaterL,
    Expression<double>? skeletalMuscleKg,
    Expression<int>? restingKcal,
    Expression<String>? equation,
    Expression<String>? confidence,
    Expression<String>? context,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (deviceId != null) 'device_id': deviceId,
      if (takenAt != null) 'taken_at': takenAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (impedanceOhm != null) 'impedance_ohm': impedanceOhm,
      if (reactanceOhm != null) 'reactance_ohm': reactanceOhm,
      if (segmentalRaw != null) 'segmental_raw': segmentalRaw,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (heightCmAtTime != null) 'height_cm_at_time': heightCmAtTime,
      if (ageYearsAtTime != null) 'age_years_at_time': ageYearsAtTime,
      if (sexAtTime != null) 'sex_at_time': sexAtTime,
      if (fatFreeMassKg != null) 'fat_free_mass_kg': fatFreeMassKg,
      if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
      if (totalBodyWaterL != null) 'total_body_water_l': totalBodyWaterL,
      if (skeletalMuscleKg != null) 'skeletal_muscle_kg': skeletalMuscleKg,
      if (restingKcal != null) 'resting_kcal': restingKcal,
      if (equation != null) 'equation': equation,
      if (confidence != null) 'confidence': confidence,
      if (context != null) 'context': context,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? userId,
      Value<String?>? deviceId,
      Value<DateTime>? takenAt,
      Value<double>? weightKg,
      Value<double?>? impedanceOhm,
      Value<double?>? reactanceOhm,
      Value<String?>? segmentalRaw,
      Value<int?>? heartRateBpm,
      Value<double?>? heightCmAtTime,
      Value<int?>? ageYearsAtTime,
      Value<String?>? sexAtTime,
      Value<double?>? fatFreeMassKg,
      Value<double?>? bodyFatPercent,
      Value<double?>? totalBodyWaterL,
      Value<double?>? skeletalMuscleKg,
      Value<int?>? restingKcal,
      Value<String?>? equation,
      Value<String>? confidence,
      Value<String>? context,
      Value<String>? notes,
      Value<int>? rowid}) {
    return BodyMeasurementsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      takenAt: takenAt ?? this.takenAt,
      weightKg: weightKg ?? this.weightKg,
      impedanceOhm: impedanceOhm ?? this.impedanceOhm,
      reactanceOhm: reactanceOhm ?? this.reactanceOhm,
      segmentalRaw: segmentalRaw ?? this.segmentalRaw,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      heightCmAtTime: heightCmAtTime ?? this.heightCmAtTime,
      ageYearsAtTime: ageYearsAtTime ?? this.ageYearsAtTime,
      sexAtTime: sexAtTime ?? this.sexAtTime,
      fatFreeMassKg: fatFreeMassKg ?? this.fatFreeMassKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      totalBodyWaterL: totalBodyWaterL ?? this.totalBodyWaterL,
      skeletalMuscleKg: skeletalMuscleKg ?? this.skeletalMuscleKg,
      restingKcal: restingKcal ?? this.restingKcal,
      equation: equation ?? this.equation,
      confidence: confidence ?? this.confidence,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (impedanceOhm.present) {
      map['impedance_ohm'] = Variable<double>(impedanceOhm.value);
    }
    if (reactanceOhm.present) {
      map['reactance_ohm'] = Variable<double>(reactanceOhm.value);
    }
    if (segmentalRaw.present) {
      map['segmental_raw'] = Variable<String>(segmentalRaw.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm.value);
    }
    if (heightCmAtTime.present) {
      map['height_cm_at_time'] = Variable<double>(heightCmAtTime.value);
    }
    if (ageYearsAtTime.present) {
      map['age_years_at_time'] = Variable<int>(ageYearsAtTime.value);
    }
    if (sexAtTime.present) {
      map['sex_at_time'] = Variable<String>(sexAtTime.value);
    }
    if (fatFreeMassKg.present) {
      map['fat_free_mass_kg'] = Variable<double>(fatFreeMassKg.value);
    }
    if (bodyFatPercent.present) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent.value);
    }
    if (totalBodyWaterL.present) {
      map['total_body_water_l'] = Variable<double>(totalBodyWaterL.value);
    }
    if (skeletalMuscleKg.present) {
      map['skeletal_muscle_kg'] = Variable<double>(skeletalMuscleKg.value);
    }
    if (restingKcal.present) {
      map['resting_kcal'] = Variable<int>(restingKcal.value);
    }
    if (equation.present) {
      map['equation'] = Variable<String>(equation.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('takenAt: $takenAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('impedanceOhm: $impedanceOhm, ')
          ..write('reactanceOhm: $reactanceOhm, ')
          ..write('segmentalRaw: $segmentalRaw, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('heightCmAtTime: $heightCmAtTime, ')
          ..write('ageYearsAtTime: $ageYearsAtTime, ')
          ..write('sexAtTime: $sexAtTime, ')
          ..write('fatFreeMassKg: $fatFreeMassKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('totalBodyWaterL: $totalBodyWaterL, ')
          ..write('skeletalMuscleKg: $skeletalMuscleKg, ')
          ..write('restingKcal: $restingKcal, ')
          ..write('equation: $equation, ')
          ..write('confidence: $confidence, ')
          ..write('context: $context, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eatenAtMeta =
      const VerificationMeta('eatenAt');
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
      'eaten_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('snack'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        eatenAt,
        slot,
        note,
        photoPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(Insertable<Meal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('eaten_at')) {
      context.handle(_eatenAtMeta,
          eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta));
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      eatenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}eaten_at'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final DateTime eatenAt;
  final String slot;
  final String? note;
  final String? photoPath;
  const Meal(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.userId,
      required this.eatenAt,
      required this.slot,
      this.note,
      this.photoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    map['slot'] = Variable<String>(slot);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      eatenAt: Value(eatenAt),
      slot: Value(slot),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      slot: serializer.fromJson<String>(json['slot']),
      note: serializer.fromJson<String?>(json['note']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'slot': serializer.toJson<String>(slot),
      'note': serializer.toJson<String?>(note),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  Meal copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? userId,
          DateTime? eatenAt,
          String? slot,
          Value<String?> note = const Value.absent(),
          Value<String?> photoPath = const Value.absent()}) =>
      Meal(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId ?? this.userId,
        eatenAt: eatenAt ?? this.eatenAt,
        slot: slot ?? this.slot,
        note: note.present ? note.value : this.note,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
      );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      slot: data.slot.present ? data.slot.value : this.slot,
      note: data.note.present ? data.note.value : this.note,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('slot: $slot, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(createdAt, updatedAt, syncedAt, deletedAt, id,
      userId, eatenAt, slot, note, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.eatenAt == this.eatenAt &&
          other.slot == this.slot &&
          other.note == this.note &&
          other.photoPath == this.photoPath);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> eatenAt;
  final Value<String> slot;
  final Value<String?> note;
  final Value<String?> photoPath;
  final Value<int> rowid;
  const MealsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.slot = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    required DateTime eatenAt,
    this.slot = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        userId = Value(userId),
        eatenAt = Value(eatenAt);
  static Insertable<Meal> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? eatenAt,
    Expression<String>? slot,
    Expression<String>? note,
    Expression<String>? photoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (slot != null) 'slot': slot,
      if (note != null) 'note': note,
      if (photoPath != null) 'photo_path': photoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? eatenAt,
      Value<String>? slot,
      Value<String?>? note,
      Value<String?>? photoPath,
      Value<int>? rowid}) {
    return MealsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eatenAt: eatenAt ?? this.eatenAt,
      slot: slot ?? this.slot,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('slot: $slot, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealComponentsTable extends MealComponents
    with TableInfo<$MealComponentsTable, MealComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
      'food_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _foodNameMeta =
      const VerificationMeta('foodName');
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
      'food_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foodSourceMeta =
      const VerificationMeta('foodSource');
  @override
  late final GeneratedColumn<String> foodSource = GeneratedColumn<String>(
      'food_source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
      'grams', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
      'kcal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
      'protein_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
      'carb_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
      'fat_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
      'sugar_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saturatesGMeta =
      const VerificationMeta('saturatesG');
  @override
  late final GeneratedColumn<double> saturatesG = GeneratedColumn<double>(
      'saturates_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fibreGMeta = const VerificationMeta('fibreG');
  @override
  late final GeneratedColumn<double> fibreG = GeneratedColumn<double>(
      'fibre_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saltGMeta = const VerificationMeta('saltG');
  @override
  late final GeneratedColumn<double> saltG = GeneratedColumn<double>(
      'salt_g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isCookingFatMeta =
      const VerificationMeta('isCookingFat');
  @override
  late final GeneratedColumn<bool> isCookingFat = GeneratedColumn<bool>(
      'is_cooking_fat', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_cooking_fat" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _estimatedGramsMeta =
      const VerificationMeta('estimatedGrams');
  @override
  late final GeneratedColumn<double> estimatedGrams = GeneratedColumn<double>(
      'estimated_grams', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        mealId,
        userId,
        foodId,
        foodName,
        foodSource,
        grams,
        method,
        kcal,
        proteinG,
        carbG,
        fatG,
        sugarG,
        saturatesG,
        fibreG,
        saltG,
        isCookingFat,
        estimatedGrams,
        position,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_components';
  @override
  VerificationContext validateIntegrity(Insertable<MealComponent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(_foodIdMeta,
          foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta));
    }
    if (data.containsKey('food_name')) {
      context.handle(_foodNameMeta,
          foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta));
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('food_source')) {
      context.handle(
          _foodSourceMeta,
          foodSource.isAcceptableOrUnknown(
              data['food_source']!, _foodSourceMeta));
    }
    if (data.containsKey('grams')) {
      context.handle(
          _gramsMeta, grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta));
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carb_g')) {
      context.handle(
          _carbGMeta, carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('sugar_g')) {
      context.handle(_sugarGMeta,
          sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta));
    }
    if (data.containsKey('saturates_g')) {
      context.handle(
          _saturatesGMeta,
          saturatesG.isAcceptableOrUnknown(
              data['saturates_g']!, _saturatesGMeta));
    }
    if (data.containsKey('fibre_g')) {
      context.handle(_fibreGMeta,
          fibreG.isAcceptableOrUnknown(data['fibre_g']!, _fibreGMeta));
    }
    if (data.containsKey('salt_g')) {
      context.handle(
          _saltGMeta, saltG.isAcceptableOrUnknown(data['salt_g']!, _saltGMeta));
    }
    if (data.containsKey('is_cooking_fat')) {
      context.handle(
          _isCookingFatMeta,
          isCookingFat.isAcceptableOrUnknown(
              data['is_cooking_fat']!, _isCookingFatMeta));
    }
    if (data.containsKey('estimated_grams')) {
      context.handle(
          _estimatedGramsMeta,
          estimatedGrams.isAcceptableOrUnknown(
              data['estimated_grams']!, _estimatedGramsMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealComponent(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      foodId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_id']),
      foodName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_name'])!,
      foodSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}food_source']),
      grams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grams'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_g']),
      carbG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_g']),
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_g']),
      sugarG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sugar_g']),
      saturatesG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saturates_g']),
      fibreG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fibre_g']),
      saltG: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}salt_g']),
      isCookingFat: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cooking_fat'])!,
      estimatedGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}estimated_grams']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $MealComponentsTable createAlias(String alias) {
    return $MealComponentsTable(attachedDatabase, alias);
  }
}

class MealComponent extends DataClass implements Insertable<MealComponent> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String mealId;
  final String userId;
  final String? foodId;
  final String foodName;
  final String? foodSource;
  final double grams;
  final String method;
  final double kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;
  final double? sugarG;
  final double? saturatesG;
  final double? fibreG;
  final double? saltG;
  final bool isCookingFat;
  final double? estimatedGrams;
  final int position;
  final String? note;
  const MealComponent(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.mealId,
      required this.userId,
      this.foodId,
      required this.foodName,
      this.foodSource,
      required this.grams,
      required this.method,
      required this.kcal,
      this.proteinG,
      this.carbG,
      this.fatG,
      this.sugarG,
      this.saturatesG,
      this.fibreG,
      this.saltG,
      required this.isCookingFat,
      this.estimatedGrams,
      required this.position,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    map['food_name'] = Variable<String>(foodName);
    if (!nullToAbsent || foodSource != null) {
      map['food_source'] = Variable<String>(foodSource);
    }
    map['grams'] = Variable<double>(grams);
    map['method'] = Variable<String>(method);
    map['kcal'] = Variable<double>(kcal);
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<double>(carbG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || sugarG != null) {
      map['sugar_g'] = Variable<double>(sugarG);
    }
    if (!nullToAbsent || saturatesG != null) {
      map['saturates_g'] = Variable<double>(saturatesG);
    }
    if (!nullToAbsent || fibreG != null) {
      map['fibre_g'] = Variable<double>(fibreG);
    }
    if (!nullToAbsent || saltG != null) {
      map['salt_g'] = Variable<double>(saltG);
    }
    map['is_cooking_fat'] = Variable<bool>(isCookingFat);
    if (!nullToAbsent || estimatedGrams != null) {
      map['estimated_grams'] = Variable<double>(estimatedGrams);
    }
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MealComponentsCompanion toCompanion(bool nullToAbsent) {
    return MealComponentsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      mealId: Value(mealId),
      userId: Value(userId),
      foodId:
          foodId == null && nullToAbsent ? const Value.absent() : Value(foodId),
      foodName: Value(foodName),
      foodSource: foodSource == null && nullToAbsent
          ? const Value.absent()
          : Value(foodSource),
      grams: Value(grams),
      method: Value(method),
      kcal: Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbG:
          carbG == null && nullToAbsent ? const Value.absent() : Value(carbG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      sugarG:
          sugarG == null && nullToAbsent ? const Value.absent() : Value(sugarG),
      saturatesG: saturatesG == null && nullToAbsent
          ? const Value.absent()
          : Value(saturatesG),
      fibreG:
          fibreG == null && nullToAbsent ? const Value.absent() : Value(fibreG),
      saltG:
          saltG == null && nullToAbsent ? const Value.absent() : Value(saltG),
      isCookingFat: Value(isCookingFat),
      estimatedGrams: estimatedGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedGrams),
      position: Value(position),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory MealComponent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealComponent(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      userId: serializer.fromJson<String>(json['userId']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      foodSource: serializer.fromJson<String?>(json['foodSource']),
      grams: serializer.fromJson<double>(json['grams']),
      method: serializer.fromJson<String>(json['method']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbG: serializer.fromJson<double?>(json['carbG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      sugarG: serializer.fromJson<double?>(json['sugarG']),
      saturatesG: serializer.fromJson<double?>(json['saturatesG']),
      fibreG: serializer.fromJson<double?>(json['fibreG']),
      saltG: serializer.fromJson<double?>(json['saltG']),
      isCookingFat: serializer.fromJson<bool>(json['isCookingFat']),
      estimatedGrams: serializer.fromJson<double?>(json['estimatedGrams']),
      position: serializer.fromJson<int>(json['position']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'userId': serializer.toJson<String>(userId),
      'foodId': serializer.toJson<String?>(foodId),
      'foodName': serializer.toJson<String>(foodName),
      'foodSource': serializer.toJson<String?>(foodSource),
      'grams': serializer.toJson<double>(grams),
      'method': serializer.toJson<String>(method),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbG': serializer.toJson<double?>(carbG),
      'fatG': serializer.toJson<double?>(fatG),
      'sugarG': serializer.toJson<double?>(sugarG),
      'saturatesG': serializer.toJson<double?>(saturatesG),
      'fibreG': serializer.toJson<double?>(fibreG),
      'saltG': serializer.toJson<double?>(saltG),
      'isCookingFat': serializer.toJson<bool>(isCookingFat),
      'estimatedGrams': serializer.toJson<double?>(estimatedGrams),
      'position': serializer.toJson<int>(position),
      'note': serializer.toJson<String?>(note),
    };
  }

  MealComponent copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? mealId,
          String? userId,
          Value<String?> foodId = const Value.absent(),
          String? foodName,
          Value<String?> foodSource = const Value.absent(),
          double? grams,
          String? method,
          double? kcal,
          Value<double?> proteinG = const Value.absent(),
          Value<double?> carbG = const Value.absent(),
          Value<double?> fatG = const Value.absent(),
          Value<double?> sugarG = const Value.absent(),
          Value<double?> saturatesG = const Value.absent(),
          Value<double?> fibreG = const Value.absent(),
          Value<double?> saltG = const Value.absent(),
          bool? isCookingFat,
          Value<double?> estimatedGrams = const Value.absent(),
          int? position,
          Value<String?> note = const Value.absent()}) =>
      MealComponent(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        userId: userId ?? this.userId,
        foodId: foodId.present ? foodId.value : this.foodId,
        foodName: foodName ?? this.foodName,
        foodSource: foodSource.present ? foodSource.value : this.foodSource,
        grams: grams ?? this.grams,
        method: method ?? this.method,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG.present ? proteinG.value : this.proteinG,
        carbG: carbG.present ? carbG.value : this.carbG,
        fatG: fatG.present ? fatG.value : this.fatG,
        sugarG: sugarG.present ? sugarG.value : this.sugarG,
        saturatesG: saturatesG.present ? saturatesG.value : this.saturatesG,
        fibreG: fibreG.present ? fibreG.value : this.fibreG,
        saltG: saltG.present ? saltG.value : this.saltG,
        isCookingFat: isCookingFat ?? this.isCookingFat,
        estimatedGrams:
            estimatedGrams.present ? estimatedGrams.value : this.estimatedGrams,
        position: position ?? this.position,
        note: note.present ? note.value : this.note,
      );
  MealComponent copyWithCompanion(MealComponentsCompanion data) {
    return MealComponent(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      userId: data.userId.present ? data.userId.value : this.userId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      foodSource:
          data.foodSource.present ? data.foodSource.value : this.foodSource,
      grams: data.grams.present ? data.grams.value : this.grams,
      method: data.method.present ? data.method.value : this.method,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      saturatesG:
          data.saturatesG.present ? data.saturatesG.value : this.saturatesG,
      fibreG: data.fibreG.present ? data.fibreG.value : this.fibreG,
      saltG: data.saltG.present ? data.saltG.value : this.saltG,
      isCookingFat: data.isCookingFat.present
          ? data.isCookingFat.value
          : this.isCookingFat,
      estimatedGrams: data.estimatedGrams.present
          ? data.estimatedGrams.value
          : this.estimatedGrams,
      position: data.position.present ? data.position.value : this.position,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealComponent(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodSource: $foodSource, ')
          ..write('grams: $grams, ')
          ..write('method: $method, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('sugarG: $sugarG, ')
          ..write('saturatesG: $saturatesG, ')
          ..write('fibreG: $fibreG, ')
          ..write('saltG: $saltG, ')
          ..write('isCookingFat: $isCookingFat, ')
          ..write('estimatedGrams: $estimatedGrams, ')
          ..write('position: $position, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        mealId,
        userId,
        foodId,
        foodName,
        foodSource,
        grams,
        method,
        kcal,
        proteinG,
        carbG,
        fatG,
        sugarG,
        saturatesG,
        fibreG,
        saltG,
        isCookingFat,
        estimatedGrams,
        position,
        note
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealComponent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.userId == this.userId &&
          other.foodId == this.foodId &&
          other.foodName == this.foodName &&
          other.foodSource == this.foodSource &&
          other.grams == this.grams &&
          other.method == this.method &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.sugarG == this.sugarG &&
          other.saturatesG == this.saturatesG &&
          other.fibreG == this.fibreG &&
          other.saltG == this.saltG &&
          other.isCookingFat == this.isCookingFat &&
          other.estimatedGrams == this.estimatedGrams &&
          other.position == this.position &&
          other.note == this.note);
}

class MealComponentsCompanion extends UpdateCompanion<MealComponent> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> mealId;
  final Value<String> userId;
  final Value<String?> foodId;
  final Value<String> foodName;
  final Value<String?> foodSource;
  final Value<double> grams;
  final Value<String> method;
  final Value<double> kcal;
  final Value<double?> proteinG;
  final Value<double?> carbG;
  final Value<double?> fatG;
  final Value<double?> sugarG;
  final Value<double?> saturatesG;
  final Value<double?> fibreG;
  final Value<double?> saltG;
  final Value<bool> isCookingFat;
  final Value<double?> estimatedGrams;
  final Value<int> position;
  final Value<String?> note;
  final Value<int> rowid;
  const MealComponentsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.userId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.foodSource = const Value.absent(),
    this.grams = const Value.absent(),
    this.method = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.saturatesG = const Value.absent(),
    this.fibreG = const Value.absent(),
    this.saltG = const Value.absent(),
    this.isCookingFat = const Value.absent(),
    this.estimatedGrams = const Value.absent(),
    this.position = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealComponentsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String mealId,
    required String userId,
    this.foodId = const Value.absent(),
    required String foodName,
    this.foodSource = const Value.absent(),
    required double grams,
    required String method,
    required double kcal,
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.saturatesG = const Value.absent(),
    this.fibreG = const Value.absent(),
    this.saltG = const Value.absent(),
    this.isCookingFat = const Value.absent(),
    this.estimatedGrams = const Value.absent(),
    this.position = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        mealId = Value(mealId),
        userId = Value(userId),
        foodName = Value(foodName),
        grams = Value(grams),
        method = Value(method),
        kcal = Value(kcal);
  static Insertable<MealComponent> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? userId,
    Expression<String>? foodId,
    Expression<String>? foodName,
    Expression<String>? foodSource,
    Expression<double>? grams,
    Expression<String>? method,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbG,
    Expression<double>? fatG,
    Expression<double>? sugarG,
    Expression<double>? saturatesG,
    Expression<double>? fibreG,
    Expression<double>? saltG,
    Expression<bool>? isCookingFat,
    Expression<double>? estimatedGrams,
    Expression<int>? position,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      if (foodName != null) 'food_name': foodName,
      if (foodSource != null) 'food_source': foodSource,
      if (grams != null) 'grams': grams,
      if (method != null) 'method': method,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (saturatesG != null) 'saturates_g': saturatesG,
      if (fibreG != null) 'fibre_g': fibreG,
      if (saltG != null) 'salt_g': saltG,
      if (isCookingFat != null) 'is_cooking_fat': isCookingFat,
      if (estimatedGrams != null) 'estimated_grams': estimatedGrams,
      if (position != null) 'position': position,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealComponentsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? mealId,
      Value<String>? userId,
      Value<String?>? foodId,
      Value<String>? foodName,
      Value<String?>? foodSource,
      Value<double>? grams,
      Value<String>? method,
      Value<double>? kcal,
      Value<double?>? proteinG,
      Value<double?>? carbG,
      Value<double?>? fatG,
      Value<double?>? sugarG,
      Value<double?>? saturatesG,
      Value<double?>? fibreG,
      Value<double?>? saltG,
      Value<bool>? isCookingFat,
      Value<double?>? estimatedGrams,
      Value<int>? position,
      Value<String?>? note,
      Value<int>? rowid}) {
    return MealComponentsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      foodSource: foodSource ?? this.foodSource,
      grams: grams ?? this.grams,
      method: method ?? this.method,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      sugarG: sugarG ?? this.sugarG,
      saturatesG: saturatesG ?? this.saturatesG,
      fibreG: fibreG ?? this.fibreG,
      saltG: saltG ?? this.saltG,
      isCookingFat: isCookingFat ?? this.isCookingFat,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      position: position ?? this.position,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (foodSource.present) {
      map['food_source'] = Variable<String>(foodSource.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (saturatesG.present) {
      map['saturates_g'] = Variable<double>(saturatesG.value);
    }
    if (fibreG.present) {
      map['fibre_g'] = Variable<double>(fibreG.value);
    }
    if (saltG.present) {
      map['salt_g'] = Variable<double>(saltG.value);
    }
    if (isCookingFat.present) {
      map['is_cooking_fat'] = Variable<bool>(isCookingFat.value);
    }
    if (estimatedGrams.present) {
      map['estimated_grams'] = Variable<double>(estimatedGrams.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealComponentsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodSource: $foodSource, ')
          ..write('grams: $grams, ')
          ..write('method: $method, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('sugarG: $sugarG, ')
          ..write('saturatesG: $saturatesG, ')
          ..write('fibreG: $fibreG, ')
          ..write('saltG: $saltG, ')
          ..write('isCookingFat: $isCookingFat, ')
          ..write('estimatedGrams: $estimatedGrams, ')
          ..write('position: $position, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCookedMeta =
      const VerificationMeta('isCooked');
  @override
  late final GeneratedColumn<bool> isCooked = GeneratedColumn<bool>(
      'is_cooked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cooked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _kcal100gMeta =
      const VerificationMeta('kcal100g');
  @override
  late final GeneratedColumn<double> kcal100g = GeneratedColumn<double>(
      'kcal_100g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _protein100gMeta =
      const VerificationMeta('protein100g');
  @override
  late final GeneratedColumn<double> protein100g = GeneratedColumn<double>(
      'protein_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carb100gMeta =
      const VerificationMeta('carb100g');
  @override
  late final GeneratedColumn<double> carb100g = GeneratedColumn<double>(
      'carb_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sugar100gMeta =
      const VerificationMeta('sugar100g');
  @override
  late final GeneratedColumn<double> sugar100g = GeneratedColumn<double>(
      'sugar_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fat100gMeta =
      const VerificationMeta('fat100g');
  @override
  late final GeneratedColumn<double> fat100g = GeneratedColumn<double>(
      'fat_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _saturates100gMeta =
      const VerificationMeta('saturates100g');
  @override
  late final GeneratedColumn<double> saturates100g = GeneratedColumn<double>(
      'saturates_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fibre100gMeta =
      const VerificationMeta('fibre100g');
  @override
  late final GeneratedColumn<double> fibre100g = GeneratedColumn<double>(
      'fibre_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _salt100gMeta =
      const VerificationMeta('salt100g');
  @override
  late final GeneratedColumn<double> salt100g = GeneratedColumn<double>(
      'salt_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _householdMeasuresMeta =
      const VerificationMeta('householdMeasures');
  @override
  late final GeneratedColumn<String> householdMeasures =
      GeneratedColumn<String>('household_measures', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        name,
        brand,
        barcode,
        source,
        isCooked,
        kcal100g,
        protein100g,
        carb100g,
        sugar100g,
        fat100g,
        saturates100g,
        fibre100g,
        salt100g,
        householdMeasures
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(Insertable<Food> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('is_cooked')) {
      context.handle(_isCookedMeta,
          isCooked.isAcceptableOrUnknown(data['is_cooked']!, _isCookedMeta));
    }
    if (data.containsKey('kcal_100g')) {
      context.handle(_kcal100gMeta,
          kcal100g.isAcceptableOrUnknown(data['kcal_100g']!, _kcal100gMeta));
    } else if (isInserting) {
      context.missing(_kcal100gMeta);
    }
    if (data.containsKey('protein_100g')) {
      context.handle(
          _protein100gMeta,
          protein100g.isAcceptableOrUnknown(
              data['protein_100g']!, _protein100gMeta));
    }
    if (data.containsKey('carb_100g')) {
      context.handle(_carb100gMeta,
          carb100g.isAcceptableOrUnknown(data['carb_100g']!, _carb100gMeta));
    }
    if (data.containsKey('sugar_100g')) {
      context.handle(_sugar100gMeta,
          sugar100g.isAcceptableOrUnknown(data['sugar_100g']!, _sugar100gMeta));
    }
    if (data.containsKey('fat_100g')) {
      context.handle(_fat100gMeta,
          fat100g.isAcceptableOrUnknown(data['fat_100g']!, _fat100gMeta));
    }
    if (data.containsKey('saturates_100g')) {
      context.handle(
          _saturates100gMeta,
          saturates100g.isAcceptableOrUnknown(
              data['saturates_100g']!, _saturates100gMeta));
    }
    if (data.containsKey('fibre_100g')) {
      context.handle(_fibre100gMeta,
          fibre100g.isAcceptableOrUnknown(data['fibre_100g']!, _fibre100gMeta));
    }
    if (data.containsKey('salt_100g')) {
      context.handle(_salt100gMeta,
          salt100g.isAcceptableOrUnknown(data['salt_100g']!, _salt100gMeta));
    }
    if (data.containsKey('household_measures')) {
      context.handle(
          _householdMeasuresMeta,
          householdMeasures.isAcceptableOrUnknown(
              data['household_measures']!, _householdMeasuresMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      isCooked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cooked'])!,
      kcal100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal_100g'])!,
      protein100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_100g']),
      carb100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_100g']),
      sugar100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sugar_100g']),
      fat100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_100g']),
      saturates100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saturates_100g']),
      fibre100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fibre_100g']),
      salt100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}salt_100g']),
      householdMeasures: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}household_measures'])!,
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }
}

class Food extends DataClass implements Insertable<Food> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String? userId;
  final String name;
  final String? brand;
  final String? barcode;
  final String source;
  final bool isCooked;
  final double kcal100g;
  final double? protein100g;
  final double? carb100g;
  final double? sugar100g;
  final double? fat100g;
  final double? saturates100g;
  final double? fibre100g;
  final double? salt100g;

  /// JSON list of `{label, grams}`.
  final String householdMeasures;
  const Food(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      this.userId,
      required this.name,
      this.brand,
      this.barcode,
      required this.source,
      required this.isCooked,
      required this.kcal100g,
      this.protein100g,
      this.carb100g,
      this.sugar100g,
      this.fat100g,
      this.saturates100g,
      this.fibre100g,
      this.salt100g,
      required this.householdMeasures});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['source'] = Variable<String>(source);
    map['is_cooked'] = Variable<bool>(isCooked);
    map['kcal_100g'] = Variable<double>(kcal100g);
    if (!nullToAbsent || protein100g != null) {
      map['protein_100g'] = Variable<double>(protein100g);
    }
    if (!nullToAbsent || carb100g != null) {
      map['carb_100g'] = Variable<double>(carb100g);
    }
    if (!nullToAbsent || sugar100g != null) {
      map['sugar_100g'] = Variable<double>(sugar100g);
    }
    if (!nullToAbsent || fat100g != null) {
      map['fat_100g'] = Variable<double>(fat100g);
    }
    if (!nullToAbsent || saturates100g != null) {
      map['saturates_100g'] = Variable<double>(saturates100g);
    }
    if (!nullToAbsent || fibre100g != null) {
      map['fibre_100g'] = Variable<double>(fibre100g);
    }
    if (!nullToAbsent || salt100g != null) {
      map['salt_100g'] = Variable<double>(salt100g);
    }
    map['household_measures'] = Variable<String>(householdMeasures);
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      name: Value(name),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      source: Value(source),
      isCooked: Value(isCooked),
      kcal100g: Value(kcal100g),
      protein100g: protein100g == null && nullToAbsent
          ? const Value.absent()
          : Value(protein100g),
      carb100g: carb100g == null && nullToAbsent
          ? const Value.absent()
          : Value(carb100g),
      sugar100g: sugar100g == null && nullToAbsent
          ? const Value.absent()
          : Value(sugar100g),
      fat100g: fat100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fat100g),
      saturates100g: saturates100g == null && nullToAbsent
          ? const Value.absent()
          : Value(saturates100g),
      fibre100g: fibre100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fibre100g),
      salt100g: salt100g == null && nullToAbsent
          ? const Value.absent()
          : Value(salt100g),
      householdMeasures: Value(householdMeasures),
    );
  }

  factory Food.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      source: serializer.fromJson<String>(json['source']),
      isCooked: serializer.fromJson<bool>(json['isCooked']),
      kcal100g: serializer.fromJson<double>(json['kcal100g']),
      protein100g: serializer.fromJson<double?>(json['protein100g']),
      carb100g: serializer.fromJson<double?>(json['carb100g']),
      sugar100g: serializer.fromJson<double?>(json['sugar100g']),
      fat100g: serializer.fromJson<double?>(json['fat100g']),
      saturates100g: serializer.fromJson<double?>(json['saturates100g']),
      fibre100g: serializer.fromJson<double?>(json['fibre100g']),
      salt100g: serializer.fromJson<double?>(json['salt100g']),
      householdMeasures: serializer.fromJson<String>(json['householdMeasures']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'barcode': serializer.toJson<String?>(barcode),
      'source': serializer.toJson<String>(source),
      'isCooked': serializer.toJson<bool>(isCooked),
      'kcal100g': serializer.toJson<double>(kcal100g),
      'protein100g': serializer.toJson<double?>(protein100g),
      'carb100g': serializer.toJson<double?>(carb100g),
      'sugar100g': serializer.toJson<double?>(sugar100g),
      'fat100g': serializer.toJson<double?>(fat100g),
      'saturates100g': serializer.toJson<double?>(saturates100g),
      'fibre100g': serializer.toJson<double?>(fibre100g),
      'salt100g': serializer.toJson<double?>(salt100g),
      'householdMeasures': serializer.toJson<String>(householdMeasures),
    };
  }

  Food copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          Value<String?> userId = const Value.absent(),
          String? name,
          Value<String?> brand = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          String? source,
          bool? isCooked,
          double? kcal100g,
          Value<double?> protein100g = const Value.absent(),
          Value<double?> carb100g = const Value.absent(),
          Value<double?> sugar100g = const Value.absent(),
          Value<double?> fat100g = const Value.absent(),
          Value<double?> saturates100g = const Value.absent(),
          Value<double?> fibre100g = const Value.absent(),
          Value<double?> salt100g = const Value.absent(),
          String? householdMeasures}) =>
      Food(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        name: name ?? this.name,
        brand: brand.present ? brand.value : this.brand,
        barcode: barcode.present ? barcode.value : this.barcode,
        source: source ?? this.source,
        isCooked: isCooked ?? this.isCooked,
        kcal100g: kcal100g ?? this.kcal100g,
        protein100g: protein100g.present ? protein100g.value : this.protein100g,
        carb100g: carb100g.present ? carb100g.value : this.carb100g,
        sugar100g: sugar100g.present ? sugar100g.value : this.sugar100g,
        fat100g: fat100g.present ? fat100g.value : this.fat100g,
        saturates100g:
            saturates100g.present ? saturates100g.value : this.saturates100g,
        fibre100g: fibre100g.present ? fibre100g.value : this.fibre100g,
        salt100g: salt100g.present ? salt100g.value : this.salt100g,
        householdMeasures: householdMeasures ?? this.householdMeasures,
      );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      source: data.source.present ? data.source.value : this.source,
      isCooked: data.isCooked.present ? data.isCooked.value : this.isCooked,
      kcal100g: data.kcal100g.present ? data.kcal100g.value : this.kcal100g,
      protein100g:
          data.protein100g.present ? data.protein100g.value : this.protein100g,
      carb100g: data.carb100g.present ? data.carb100g.value : this.carb100g,
      sugar100g: data.sugar100g.present ? data.sugar100g.value : this.sugar100g,
      fat100g: data.fat100g.present ? data.fat100g.value : this.fat100g,
      saturates100g: data.saturates100g.present
          ? data.saturates100g.value
          : this.saturates100g,
      fibre100g: data.fibre100g.present ? data.fibre100g.value : this.fibre100g,
      salt100g: data.salt100g.present ? data.salt100g.value : this.salt100g,
      householdMeasures: data.householdMeasures.present
          ? data.householdMeasures.value
          : this.householdMeasures,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('source: $source, ')
          ..write('isCooked: $isCooked, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carb100g: $carb100g, ')
          ..write('sugar100g: $sugar100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('saturates100g: $saturates100g, ')
          ..write('fibre100g: $fibre100g, ')
          ..write('salt100g: $salt100g, ')
          ..write('householdMeasures: $householdMeasures')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      createdAt,
      updatedAt,
      syncedAt,
      deletedAt,
      id,
      userId,
      name,
      brand,
      barcode,
      source,
      isCooked,
      kcal100g,
      protein100g,
      carb100g,
      sugar100g,
      fat100g,
      saturates100g,
      fibre100g,
      salt100g,
      householdMeasures);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.barcode == this.barcode &&
          other.source == this.source &&
          other.isCooked == this.isCooked &&
          other.kcal100g == this.kcal100g &&
          other.protein100g == this.protein100g &&
          other.carb100g == this.carb100g &&
          other.sugar100g == this.sugar100g &&
          other.fat100g == this.fat100g &&
          other.saturates100g == this.saturates100g &&
          other.fibre100g == this.fibre100g &&
          other.salt100g == this.salt100g &&
          other.householdMeasures == this.householdMeasures);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> barcode;
  final Value<String> source;
  final Value<bool> isCooked;
  final Value<double> kcal100g;
  final Value<double?> protein100g;
  final Value<double?> carb100g;
  final Value<double?> sugar100g;
  final Value<double?> fat100g;
  final Value<double?> saturates100g;
  final Value<double?> fibre100g;
  final Value<double?> salt100g;
  final Value<String> householdMeasures;
  final Value<int> rowid;
  const FoodsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.source = const Value.absent(),
    this.isCooked = const Value.absent(),
    this.kcal100g = const Value.absent(),
    this.protein100g = const Value.absent(),
    this.carb100g = const Value.absent(),
    this.sugar100g = const Value.absent(),
    this.fat100g = const Value.absent(),
    this.saturates100g = const Value.absent(),
    this.fibre100g = const Value.absent(),
    this.salt100g = const Value.absent(),
    this.householdMeasures = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.userId = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    required String source,
    this.isCooked = const Value.absent(),
    required double kcal100g,
    this.protein100g = const Value.absent(),
    this.carb100g = const Value.absent(),
    this.sugar100g = const Value.absent(),
    this.fat100g = const Value.absent(),
    this.saturates100g = const Value.absent(),
    this.fibre100g = const Value.absent(),
    this.salt100g = const Value.absent(),
    this.householdMeasures = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        name = Value(name),
        source = Value(source),
        kcal100g = Value(kcal100g);
  static Insertable<Food> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? barcode,
    Expression<String>? source,
    Expression<bool>? isCooked,
    Expression<double>? kcal100g,
    Expression<double>? protein100g,
    Expression<double>? carb100g,
    Expression<double>? sugar100g,
    Expression<double>? fat100g,
    Expression<double>? saturates100g,
    Expression<double>? fibre100g,
    Expression<double>? salt100g,
    Expression<String>? householdMeasures,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (barcode != null) 'barcode': barcode,
      if (source != null) 'source': source,
      if (isCooked != null) 'is_cooked': isCooked,
      if (kcal100g != null) 'kcal_100g': kcal100g,
      if (protein100g != null) 'protein_100g': protein100g,
      if (carb100g != null) 'carb_100g': carb100g,
      if (sugar100g != null) 'sugar_100g': sugar100g,
      if (fat100g != null) 'fat_100g': fat100g,
      if (saturates100g != null) 'saturates_100g': saturates100g,
      if (fibre100g != null) 'fibre_100g': fibre100g,
      if (salt100g != null) 'salt_100g': salt100g,
      if (householdMeasures != null) 'household_measures': householdMeasures,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String?>? userId,
      Value<String>? name,
      Value<String?>? brand,
      Value<String?>? barcode,
      Value<String>? source,
      Value<bool>? isCooked,
      Value<double>? kcal100g,
      Value<double?>? protein100g,
      Value<double?>? carb100g,
      Value<double?>? sugar100g,
      Value<double?>? fat100g,
      Value<double?>? saturates100g,
      Value<double?>? fibre100g,
      Value<double?>? salt100g,
      Value<String>? householdMeasures,
      Value<int>? rowid}) {
    return FoodsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      source: source ?? this.source,
      isCooked: isCooked ?? this.isCooked,
      kcal100g: kcal100g ?? this.kcal100g,
      protein100g: protein100g ?? this.protein100g,
      carb100g: carb100g ?? this.carb100g,
      sugar100g: sugar100g ?? this.sugar100g,
      fat100g: fat100g ?? this.fat100g,
      saturates100g: saturates100g ?? this.saturates100g,
      fibre100g: fibre100g ?? this.fibre100g,
      salt100g: salt100g ?? this.salt100g,
      householdMeasures: householdMeasures ?? this.householdMeasures,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isCooked.present) {
      map['is_cooked'] = Variable<bool>(isCooked.value);
    }
    if (kcal100g.present) {
      map['kcal_100g'] = Variable<double>(kcal100g.value);
    }
    if (protein100g.present) {
      map['protein_100g'] = Variable<double>(protein100g.value);
    }
    if (carb100g.present) {
      map['carb_100g'] = Variable<double>(carb100g.value);
    }
    if (sugar100g.present) {
      map['sugar_100g'] = Variable<double>(sugar100g.value);
    }
    if (fat100g.present) {
      map['fat_100g'] = Variable<double>(fat100g.value);
    }
    if (saturates100g.present) {
      map['saturates_100g'] = Variable<double>(saturates100g.value);
    }
    if (fibre100g.present) {
      map['fibre_100g'] = Variable<double>(fibre100g.value);
    }
    if (salt100g.present) {
      map['salt_100g'] = Variable<double>(salt100g.value);
    }
    if (householdMeasures.present) {
      map['household_measures'] = Variable<String>(householdMeasures.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('source: $source, ')
          ..write('isCooked: $isCooked, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carb100g: $carb100g, ')
          ..write('sugar100g: $sugar100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('saturates100g: $saturates100g, ')
          ..write('fibre100g: $fibre100g, ')
          ..write('salt100g: $salt100g, ')
          ..write('householdMeasures: $householdMeasures, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yieldGramsMeta =
      const VerificationMeta('yieldGrams');
  @override
  late final GeneratedColumn<double> yieldGrams = GeneratedColumn<double>(
      'yield_grams', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _kcal100gMeta =
      const VerificationMeta('kcal100g');
  @override
  late final GeneratedColumn<double> kcal100g = GeneratedColumn<double>(
      'kcal_100g', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _protein100gMeta =
      const VerificationMeta('protein100g');
  @override
  late final GeneratedColumn<double> protein100g = GeneratedColumn<double>(
      'protein_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _carb100gMeta =
      const VerificationMeta('carb100g');
  @override
  late final GeneratedColumn<double> carb100g = GeneratedColumn<double>(
      'carb_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fat100gMeta =
      const VerificationMeta('fat100g');
  @override
  late final GeneratedColumn<double> fat100g = GeneratedColumn<double>(
      'fat_100g', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ingredientsMeta =
      const VerificationMeta('ingredients');
  @override
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
      'ingredients', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        name,
        yieldGrams,
        kcal100g,
        protein100g,
        carb100g,
        fat100g,
        ingredients
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(Insertable<Recipe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('yield_grams')) {
      context.handle(
          _yieldGramsMeta,
          yieldGrams.isAcceptableOrUnknown(
              data['yield_grams']!, _yieldGramsMeta));
    } else if (isInserting) {
      context.missing(_yieldGramsMeta);
    }
    if (data.containsKey('kcal_100g')) {
      context.handle(_kcal100gMeta,
          kcal100g.isAcceptableOrUnknown(data['kcal_100g']!, _kcal100gMeta));
    } else if (isInserting) {
      context.missing(_kcal100gMeta);
    }
    if (data.containsKey('protein_100g')) {
      context.handle(
          _protein100gMeta,
          protein100g.isAcceptableOrUnknown(
              data['protein_100g']!, _protein100gMeta));
    }
    if (data.containsKey('carb_100g')) {
      context.handle(_carb100gMeta,
          carb100g.isAcceptableOrUnknown(data['carb_100g']!, _carb100gMeta));
    }
    if (data.containsKey('fat_100g')) {
      context.handle(_fat100gMeta,
          fat100g.isAcceptableOrUnknown(data['fat_100g']!, _fat100gMeta));
    }
    if (data.containsKey('ingredients')) {
      context.handle(
          _ingredientsMeta,
          ingredients.isAcceptableOrUnknown(
              data['ingredients']!, _ingredientsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      yieldGrams: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}yield_grams'])!,
      kcal100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kcal_100g'])!,
      protein100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}protein_100g']),
      carb100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carb_100g']),
      fat100g: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fat_100g']),
      ingredients: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ingredients'])!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final String name;

  /// The finished dish as weighed, not the sum of its ingredients.
  final double yieldGrams;
  final double kcal100g;
  final double? protein100g;
  final double? carb100g;
  final double? fat100g;

  /// JSON list of components.
  final String ingredients;
  const Recipe(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.userId,
      required this.name,
      required this.yieldGrams,
      required this.kcal100g,
      this.protein100g,
      this.carb100g,
      this.fat100g,
      required this.ingredients});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['yield_grams'] = Variable<double>(yieldGrams);
    map['kcal_100g'] = Variable<double>(kcal100g);
    if (!nullToAbsent || protein100g != null) {
      map['protein_100g'] = Variable<double>(protein100g);
    }
    if (!nullToAbsent || carb100g != null) {
      map['carb_100g'] = Variable<double>(carb100g);
    }
    if (!nullToAbsent || fat100g != null) {
      map['fat_100g'] = Variable<double>(fat100g);
    }
    map['ingredients'] = Variable<String>(ingredients);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      yieldGrams: Value(yieldGrams),
      kcal100g: Value(kcal100g),
      protein100g: protein100g == null && nullToAbsent
          ? const Value.absent()
          : Value(protein100g),
      carb100g: carb100g == null && nullToAbsent
          ? const Value.absent()
          : Value(carb100g),
      fat100g: fat100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fat100g),
      ingredients: Value(ingredients),
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      yieldGrams: serializer.fromJson<double>(json['yieldGrams']),
      kcal100g: serializer.fromJson<double>(json['kcal100g']),
      protein100g: serializer.fromJson<double?>(json['protein100g']),
      carb100g: serializer.fromJson<double?>(json['carb100g']),
      fat100g: serializer.fromJson<double?>(json['fat100g']),
      ingredients: serializer.fromJson<String>(json['ingredients']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'yieldGrams': serializer.toJson<double>(yieldGrams),
      'kcal100g': serializer.toJson<double>(kcal100g),
      'protein100g': serializer.toJson<double?>(protein100g),
      'carb100g': serializer.toJson<double?>(carb100g),
      'fat100g': serializer.toJson<double?>(fat100g),
      'ingredients': serializer.toJson<String>(ingredients),
    };
  }

  Recipe copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? userId,
          String? name,
          double? yieldGrams,
          double? kcal100g,
          Value<double?> protein100g = const Value.absent(),
          Value<double?> carb100g = const Value.absent(),
          Value<double?> fat100g = const Value.absent(),
          String? ingredients}) =>
      Recipe(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        yieldGrams: yieldGrams ?? this.yieldGrams,
        kcal100g: kcal100g ?? this.kcal100g,
        protein100g: protein100g.present ? protein100g.value : this.protein100g,
        carb100g: carb100g.present ? carb100g.value : this.carb100g,
        fat100g: fat100g.present ? fat100g.value : this.fat100g,
        ingredients: ingredients ?? this.ingredients,
      );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      yieldGrams:
          data.yieldGrams.present ? data.yieldGrams.value : this.yieldGrams,
      kcal100g: data.kcal100g.present ? data.kcal100g.value : this.kcal100g,
      protein100g:
          data.protein100g.present ? data.protein100g.value : this.protein100g,
      carb100g: data.carb100g.present ? data.carb100g.value : this.carb100g,
      fat100g: data.fat100g.present ? data.fat100g.value : this.fat100g,
      ingredients:
          data.ingredients.present ? data.ingredients.value : this.ingredients,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('yieldGrams: $yieldGrams, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carb100g: $carb100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('ingredients: $ingredients')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      createdAt,
      updatedAt,
      syncedAt,
      deletedAt,
      id,
      userId,
      name,
      yieldGrams,
      kcal100g,
      protein100g,
      carb100g,
      fat100g,
      ingredients);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.yieldGrams == this.yieldGrams &&
          other.kcal100g == this.kcal100g &&
          other.protein100g == this.protein100g &&
          other.carb100g == this.carb100g &&
          other.fat100g == this.fat100g &&
          other.ingredients == this.ingredients);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<double> yieldGrams;
  final Value<double> kcal100g;
  final Value<double?> protein100g;
  final Value<double?> carb100g;
  final Value<double?> fat100g;
  final Value<String> ingredients;
  final Value<int> rowid;
  const RecipesCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.yieldGrams = const Value.absent(),
    this.kcal100g = const Value.absent(),
    this.protein100g = const Value.absent(),
    this.carb100g = const Value.absent(),
    this.fat100g = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    required String name,
    required double yieldGrams,
    required double kcal100g,
    this.protein100g = const Value.absent(),
    this.carb100g = const Value.absent(),
    this.fat100g = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        userId = Value(userId),
        name = Value(name),
        yieldGrams = Value(yieldGrams),
        kcal100g = Value(kcal100g);
  static Insertable<Recipe> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<double>? yieldGrams,
    Expression<double>? kcal100g,
    Expression<double>? protein100g,
    Expression<double>? carb100g,
    Expression<double>? fat100g,
    Expression<String>? ingredients,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (yieldGrams != null) 'yield_grams': yieldGrams,
      if (kcal100g != null) 'kcal_100g': kcal100g,
      if (protein100g != null) 'protein_100g': protein100g,
      if (carb100g != null) 'carb_100g': carb100g,
      if (fat100g != null) 'fat_100g': fat100g,
      if (ingredients != null) 'ingredients': ingredients,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<double>? yieldGrams,
      Value<double>? kcal100g,
      Value<double?>? protein100g,
      Value<double?>? carb100g,
      Value<double?>? fat100g,
      Value<String>? ingredients,
      Value<int>? rowid}) {
    return RecipesCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      kcal100g: kcal100g ?? this.kcal100g,
      protein100g: protein100g ?? this.protein100g,
      carb100g: carb100g ?? this.carb100g,
      fat100g: fat100g ?? this.fat100g,
      ingredients: ingredients ?? this.ingredients,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (yieldGrams.present) {
      map['yield_grams'] = Variable<double>(yieldGrams.value);
    }
    if (kcal100g.present) {
      map['kcal_100g'] = Variable<double>(kcal100g.value);
    }
    if (protein100g.present) {
      map['protein_100g'] = Variable<double>(protein100g.value);
    }
    if (carb100g.present) {
      map['carb_100g'] = Variable<double>(carb100g.value);
    }
    if (fat100g.present) {
      map['fat_100g'] = Variable<double>(fat100g.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('yieldGrams: $yieldGrams, ')
          ..write('kcal100g: $kcal100g, ')
          ..write('protein100g: $protein100g, ')
          ..write('carb100g: $carb100g, ')
          ..write('fat100g: $fat100g, ')
          ..write('ingredients: $ingredients, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyTargetsTable extends DailyTargets
    with TableInfo<$DailyTargetsTable, DailyTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _effectiveFromMeta =
      const VerificationMeta('effectiveFrom');
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
      'effective_from', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
      'kcal', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _proteinGMeta =
      const VerificationMeta('proteinG');
  @override
  late final GeneratedColumn<int> proteinG = GeneratedColumn<int>(
      'protein_g', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  @override
  late final GeneratedColumn<int> carbG = GeneratedColumn<int>(
      'carb_g', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<int> fatG = GeneratedColumn<int>(
      'fat_g', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  @override
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
      'basis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        createdAt,
        updatedAt,
        syncedAt,
        deletedAt,
        id,
        userId,
        effectiveFrom,
        kcal,
        proteinG,
        carbG,
        fatG,
        basis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_targets';
  @override
  VerificationContext validateIntegrity(Insertable<DailyTarget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
          _effectiveFromMeta,
          effectiveFrom.isAcceptableOrUnknown(
              data['effective_from']!, _effectiveFromMeta));
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
          _kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(_proteinGMeta,
          proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta));
    }
    if (data.containsKey('carb_g')) {
      context.handle(
          _carbGMeta, carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta));
    }
    if (data.containsKey('fat_g')) {
      context.handle(
          _fatGMeta, fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta));
    }
    if (data.containsKey('basis')) {
      context.handle(
          _basisMeta, basis.isAcceptableOrUnknown(data['basis']!, _basisMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyTarget(
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      effectiveFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effective_from'])!,
      kcal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kcal'])!,
      proteinG: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}protein_g']),
      carbG: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}carb_g']),
      fatG: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fat_g']),
      basis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}basis']),
    );
  }

  @override
  $DailyTargetsTable createAlias(String alias) {
    return $DailyTargetsTable(attachedDatabase, alias);
  }
}

class DailyTarget extends DataClass implements Insertable<DailyTarget> {
  final DateTime createdAt;

  /// Last-write-wins compares this. Always UTC.
  final DateTime updatedAt;

  /// Null until the row has been pushed. Compared against `updated_at` to find
  /// rows that changed since.
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;

  /// ISO date, `YYYY-MM-DD`.
  final String effectiveFrom;
  final int kcal;
  final int? proteinG;
  final int? carbG;
  final int? fatG;
  final String? basis;
  const DailyTarget(
      {required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      this.deletedAt,
      required this.id,
      required this.userId,
      required this.effectiveFrom,
      required this.kcal,
      this.proteinG,
      this.carbG,
      this.fatG,
      this.basis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['effective_from'] = Variable<String>(effectiveFrom);
    map['kcal'] = Variable<int>(kcal);
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<int>(proteinG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<int>(carbG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<int>(fatG);
    }
    if (!nullToAbsent || basis != null) {
      map['basis'] = Variable<String>(basis);
    }
    return map;
  }

  DailyTargetsCompanion toCompanion(bool nullToAbsent) {
    return DailyTargetsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      effectiveFrom: Value(effectiveFrom),
      kcal: Value(kcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbG:
          carbG == null && nullToAbsent ? const Value.absent() : Value(carbG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      basis:
          basis == null && nullToAbsent ? const Value.absent() : Value(basis),
    );
  }

  factory DailyTarget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyTarget(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      kcal: serializer.fromJson<int>(json['kcal']),
      proteinG: serializer.fromJson<int?>(json['proteinG']),
      carbG: serializer.fromJson<int?>(json['carbG']),
      fatG: serializer.fromJson<int?>(json['fatG']),
      basis: serializer.fromJson<String?>(json['basis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'kcal': serializer.toJson<int>(kcal),
      'proteinG': serializer.toJson<int?>(proteinG),
      'carbG': serializer.toJson<int?>(carbG),
      'fatG': serializer.toJson<int?>(fatG),
      'basis': serializer.toJson<String?>(basis),
    };
  }

  DailyTarget copyWith(
          {DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          String? id,
          String? userId,
          String? effectiveFrom,
          int? kcal,
          Value<int?> proteinG = const Value.absent(),
          Value<int?> carbG = const Value.absent(),
          Value<int?> fatG = const Value.absent(),
          Value<String?> basis = const Value.absent()}) =>
      DailyTarget(
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        id: id ?? this.id,
        userId: userId ?? this.userId,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG.present ? proteinG.value : this.proteinG,
        carbG: carbG.present ? carbG.value : this.carbG,
        fatG: fatG.present ? fatG.value : this.fatG,
        basis: basis.present ? basis.value : this.basis,
      );
  DailyTarget copyWithCompanion(DailyTargetsCompanion data) {
    return DailyTarget(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      basis: data.basis.present ? data.basis.value : this.basis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyTarget(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('basis: $basis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(createdAt, updatedAt, syncedAt, deletedAt, id,
      userId, effectiveFrom, kcal, proteinG, carbG, fatG, basis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyTarget &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.effectiveFrom == this.effectiveFrom &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbG == this.carbG &&
          other.fatG == this.fatG &&
          other.basis == this.basis);
}

class DailyTargetsCompanion extends UpdateCompanion<DailyTarget> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<String> effectiveFrom;
  final Value<int> kcal;
  final Value<int?> proteinG;
  final Value<int?> carbG;
  final Value<int?> fatG;
  final Value<String?> basis;
  final Value<int> rowid;
  const DailyTargetsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.basis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyTargetsCompanion.insert({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    required String effectiveFrom,
    required int kcal,
    this.proteinG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.basis = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        id = Value(id),
        userId = Value(userId),
        effectiveFrom = Value(effectiveFrom),
        kcal = Value(kcal);
  static Insertable<DailyTarget> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? effectiveFrom,
    Expression<int>? kcal,
    Expression<int>? proteinG,
    Expression<int>? carbG,
    Expression<int>? fatG,
    Expression<String>? basis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbG != null) 'carb_g': carbG,
      if (fatG != null) 'fat_g': fatG,
      if (basis != null) 'basis': basis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyTargetsCompanion copyWith(
      {Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? id,
      Value<String>? userId,
      Value<String>? effectiveFrom,
      Value<int>? kcal,
      Value<int?>? proteinG,
      Value<int?>? carbG,
      Value<int?>? fatG,
      Value<String?>? basis,
      Value<int>? rowid}) {
    return DailyTargetsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbG: carbG ?? this.carbG,
      fatG: fatG ?? this.fatG,
      basis: basis ?? this.basis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<int>(proteinG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<int>(carbG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<int>(fatG.value);
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyTargetsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbG: $carbG, ')
          ..write('fatG: $fatG, ')
          ..write('basis: $basis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateData copyWith({String? key, String? value}) => SyncStateData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ConsentsTable consents = $ConsentsTable(this);
  late final $ObservationsTable observations = $ObservationsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements =
      $BodyMeasurementsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealComponentsTable mealComponents = $MealComponentsTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $DailyTargetsTable dailyTargets = $DailyTargetsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        consents,
        observations,
        bodyMeasurements,
        meals,
        mealComponents,
        foods,
        recipes,
        dailyTargets,
        syncState
      ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  required String id,
  Value<String?> displayName,
  Value<String?> dateOfBirth,
  Value<String?> sex,
  Value<double?> heightCm,
  Value<String> activity,
  Value<String> units,
  Value<String> country,
  Value<String> goal,
  Value<double?> targetWeightKg,
  Value<double?> paceKgPerWeek,
  Value<String> macroSplit,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<String> id,
  Value<String?> displayName,
  Value<String?> dateOfBirth,
  Value<String?> sex,
  Value<double?> heightCm,
  Value<String> activity,
  Value<String> units,
  Value<String> country,
  Value<String> goal,
  Value<double?> targetWeightKg,
  Value<double?> paceKgPerWeek,
  Value<String> macroSplit,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activity => $composableBuilder(
      column: $table.activity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get goal => $composableBuilder(
      column: $table.goal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paceKgPerWeek => $composableBuilder(
      column: $table.paceKgPerWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get macroSplit => $composableBuilder(
      column: $table.macroSplit, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm => $composableBuilder(
      column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activity => $composableBuilder(
      column: $table.activity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get goal => $composableBuilder(
      column: $table.goal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paceKgPerWeek => $composableBuilder(
      column: $table.paceKgPerWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get macroSplit => $composableBuilder(
      column: $table.macroSplit, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
      column: $table.targetWeightKg, builder: (column) => column);

  GeneratedColumn<double> get paceKgPerWeek => $composableBuilder(
      column: $table.paceKgPerWeek, builder: (column) => column);

  GeneratedColumn<String> get macroSplit => $composableBuilder(
      column: $table.macroSplit, builder: (column) => column);
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> dateOfBirth = const Value.absent(),
            Value<String?> sex = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<String> activity = const Value.absent(),
            Value<String> units = const Value.absent(),
            Value<String> country = const Value.absent(),
            Value<String> goal = const Value.absent(),
            Value<double?> targetWeightKg = const Value.absent(),
            Value<double?> paceKgPerWeek = const Value.absent(),
            Value<String> macroSplit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            id: id,
            displayName: displayName,
            dateOfBirth: dateOfBirth,
            sex: sex,
            heightCm: heightCm,
            activity: activity,
            units: units,
            country: country,
            goal: goal,
            targetWeightKg: targetWeightKg,
            paceKgPerWeek: paceKgPerWeek,
            macroSplit: macroSplit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            required String id,
            Value<String?> displayName = const Value.absent(),
            Value<String?> dateOfBirth = const Value.absent(),
            Value<String?> sex = const Value.absent(),
            Value<double?> heightCm = const Value.absent(),
            Value<String> activity = const Value.absent(),
            Value<String> units = const Value.absent(),
            Value<String> country = const Value.absent(),
            Value<String> goal = const Value.absent(),
            Value<double?> targetWeightKg = const Value.absent(),
            Value<double?> paceKgPerWeek = const Value.absent(),
            Value<String> macroSplit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            id: id,
            displayName: displayName,
            dateOfBirth: dateOfBirth,
            sex: sex,
            heightCm: heightCm,
            activity: activity,
            units: units,
            country: country,
            goal: goal,
            targetWeightKg: targetWeightKg,
            paceKgPerWeek: paceKgPerWeek,
            macroSplit: macroSplit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProfilesTable, Profile>(table),
                    BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
    Profile,
    PrefetchHooks Function()>;
typedef $$ConsentsTableCreateCompanionBuilder = ConsentsCompanion Function({
  required String id,
  required String userId,
  required String purpose,
  required String policyVersion,
  required bool granted,
  required DateTime grantedAt,
  Value<String> source,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$ConsentsTableUpdateCompanionBuilder = ConsentsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> purpose,
  Value<String> policyVersion,
  Value<bool> granted,
  Value<DateTime> grantedAt,
  Value<String> source,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$ConsentsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policyVersion => $composableBuilder(
      column: $table.policyVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get granted => $composableBuilder(
      column: $table.granted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$ConsentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policyVersion => $composableBuilder(
      column: $table.policyVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get granted => $composableBuilder(
      column: $table.granted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get grantedAt => $composableBuilder(
      column: $table.grantedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConsentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get policyVersion => $composableBuilder(
      column: $table.policyVersion, builder: (column) => column);

  GeneratedColumn<bool> get granted =>
      $composableBuilder(column: $table.granted, builder: (column) => column);

  GeneratedColumn<DateTime> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ConsentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConsentsTable,
    Consent,
    $$ConsentsTableFilterComposer,
    $$ConsentsTableOrderingComposer,
    $$ConsentsTableAnnotationComposer,
    $$ConsentsTableCreateCompanionBuilder,
    $$ConsentsTableUpdateCompanionBuilder,
    (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
    Consent,
    PrefetchHooks Function()> {
  $$ConsentsTableTableManager(_$AppDatabase db, $ConsentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> purpose = const Value.absent(),
            Value<String> policyVersion = const Value.absent(),
            Value<bool> granted = const Value.absent(),
            Value<DateTime> grantedAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentsCompanion(
            id: id,
            userId: userId,
            purpose: purpose,
            policyVersion: policyVersion,
            granted: granted,
            grantedAt: grantedAt,
            source: source,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String purpose,
            required String policyVersion,
            required bool granted,
            required DateTime grantedAt,
            Value<String> source = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsentsCompanion.insert(
            id: id,
            userId: userId,
            purpose: purpose,
            policyVersion: policyVersion,
            granted: granted,
            grantedAt: grantedAt,
            source: source,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ConsentsTable, Consent>(table),
                    BaseReferences<_$AppDatabase, $ConsentsTable, Consent>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConsentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConsentsTable,
    Consent,
    $$ConsentsTableFilterComposer,
    $$ConsentsTableOrderingComposer,
    $$ConsentsTableAnnotationComposer,
    $$ConsentsTableCreateCompanionBuilder,
    $$ConsentsTableUpdateCompanionBuilder,
    (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
    Consent,
    PrefetchHooks Function()>;
typedef $$ObservationsTableCreateCompanionBuilder = ObservationsCompanion
    Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  required DateTime takenAt,
  required String kind,
  required double value,
  required String unit,
  required String source,
  Value<String?> deviceId,
  Value<String?> method,
  Value<String?> confidence,
  Value<double?> referenceLow,
  Value<double?> referenceHigh,
  Value<String?> referenceSource,
  Value<String?> raw,
  Value<int> rowid,
});
typedef $$ObservationsTableUpdateCompanionBuilder = ObservationsCompanion
    Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<DateTime> takenAt,
  Value<String> kind,
  Value<double> value,
  Value<String> unit,
  Value<String> source,
  Value<String?> deviceId,
  Value<String?> method,
  Value<String?> confidence,
  Value<double?> referenceLow,
  Value<double?> referenceHigh,
  Value<String?> referenceSource,
  Value<String?> raw,
  Value<int> rowid,
});

class $$ObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get referenceLow => $composableBuilder(
      column: $table.referenceLow, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get referenceHigh => $composableBuilder(
      column: $table.referenceHigh, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceSource => $composableBuilder(
      column: $table.referenceSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get raw => $composableBuilder(
      column: $table.raw, builder: (column) => ColumnFilters(column));
}

class $$ObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get referenceLow => $composableBuilder(
      column: $table.referenceLow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get referenceHigh => $composableBuilder(
      column: $table.referenceHigh,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceSource => $composableBuilder(
      column: $table.referenceSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get raw => $composableBuilder(
      column: $table.raw, builder: (column) => ColumnOrderings(column));
}

class $$ObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<double> get referenceLow => $composableBuilder(
      column: $table.referenceLow, builder: (column) => column);

  GeneratedColumn<double> get referenceHigh => $composableBuilder(
      column: $table.referenceHigh, builder: (column) => column);

  GeneratedColumn<String> get referenceSource => $composableBuilder(
      column: $table.referenceSource, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);
}

class $$ObservationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ObservationsTable,
    Observation,
    $$ObservationsTableFilterComposer,
    $$ObservationsTableOrderingComposer,
    $$ObservationsTableAnnotationComposer,
    $$ObservationsTableCreateCompanionBuilder,
    $$ObservationsTableUpdateCompanionBuilder,
    (
      Observation,
      BaseReferences<_$AppDatabase, $ObservationsTable, Observation>
    ),
    Observation,
    PrefetchHooks Function()> {
  $$ObservationsTableTableManager(_$AppDatabase db, $ObservationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> takenAt = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String?> confidence = const Value.absent(),
            Value<double?> referenceLow = const Value.absent(),
            Value<double?> referenceHigh = const Value.absent(),
            Value<String?> referenceSource = const Value.absent(),
            Value<String?> raw = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObservationsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            takenAt: takenAt,
            kind: kind,
            value: value,
            unit: unit,
            source: source,
            deviceId: deviceId,
            method: method,
            confidence: confidence,
            referenceLow: referenceLow,
            referenceHigh: referenceHigh,
            referenceSource: referenceSource,
            raw: raw,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String userId,
            required DateTime takenAt,
            required String kind,
            required double value,
            required String unit,
            required String source,
            Value<String?> deviceId = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String?> confidence = const Value.absent(),
            Value<double?> referenceLow = const Value.absent(),
            Value<double?> referenceHigh = const Value.absent(),
            Value<String?> referenceSource = const Value.absent(),
            Value<String?> raw = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObservationsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            takenAt: takenAt,
            kind: kind,
            value: value,
            unit: unit,
            source: source,
            deviceId: deviceId,
            method: method,
            confidence: confidence,
            referenceLow: referenceLow,
            referenceHigh: referenceHigh,
            referenceSource: referenceSource,
            raw: raw,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ObservationsTable, Observation>(table),
                    BaseReferences<_$AppDatabase, $ObservationsTable,
                        Observation>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ObservationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ObservationsTable,
    Observation,
    $$ObservationsTableFilterComposer,
    $$ObservationsTableOrderingComposer,
    $$ObservationsTableAnnotationComposer,
    $$ObservationsTableCreateCompanionBuilder,
    $$ObservationsTableUpdateCompanionBuilder,
    (
      Observation,
      BaseReferences<_$AppDatabase, $ObservationsTable, Observation>
    ),
    Observation,
    PrefetchHooks Function()>;
typedef $$BodyMeasurementsTableCreateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  Value<String?> deviceId,
  required DateTime takenAt,
  required double weightKg,
  Value<double?> impedanceOhm,
  Value<double?> reactanceOhm,
  Value<String?> segmentalRaw,
  Value<int?> heartRateBpm,
  Value<double?> heightCmAtTime,
  Value<int?> ageYearsAtTime,
  Value<String?> sexAtTime,
  Value<double?> fatFreeMassKg,
  Value<double?> bodyFatPercent,
  Value<double?> totalBodyWaterL,
  Value<double?> skeletalMuscleKg,
  Value<int?> restingKcal,
  Value<String?> equation,
  Value<String> confidence,
  Value<String> context,
  Value<String> notes,
  Value<int> rowid,
});
typedef $$BodyMeasurementsTableUpdateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<String?> deviceId,
  Value<DateTime> takenAt,
  Value<double> weightKg,
  Value<double?> impedanceOhm,
  Value<double?> reactanceOhm,
  Value<String?> segmentalRaw,
  Value<int?> heartRateBpm,
  Value<double?> heightCmAtTime,
  Value<int?> ageYearsAtTime,
  Value<String?> sexAtTime,
  Value<double?> fatFreeMassKg,
  Value<double?> bodyFatPercent,
  Value<double?> totalBodyWaterL,
  Value<double?> skeletalMuscleKg,
  Value<int?> restingKcal,
  Value<String?> equation,
  Value<String> confidence,
  Value<String> context,
  Value<String> notes,
  Value<int> rowid,
});

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get impedanceOhm => $composableBuilder(
      column: $table.impedanceOhm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reactanceOhm => $composableBuilder(
      column: $table.reactanceOhm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get segmentalRaw => $composableBuilder(
      column: $table.segmentalRaw, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartRateBpm => $composableBuilder(
      column: $table.heartRateBpm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCmAtTime => $composableBuilder(
      column: $table.heightCmAtTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ageYearsAtTime => $composableBuilder(
      column: $table.ageYearsAtTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sexAtTime => $composableBuilder(
      column: $table.sexAtTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatFreeMassKg => $composableBuilder(
      column: $table.fatFreeMassKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalBodyWaterL => $composableBuilder(
      column: $table.totalBodyWaterL,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get skeletalMuscleKg => $composableBuilder(
      column: $table.skeletalMuscleKg,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restingKcal => $composableBuilder(
      column: $table.restingKcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equation => $composableBuilder(
      column: $table.equation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get context => $composableBuilder(
      column: $table.context, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
      column: $table.takenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg => $composableBuilder(
      column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get impedanceOhm => $composableBuilder(
      column: $table.impedanceOhm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reactanceOhm => $composableBuilder(
      column: $table.reactanceOhm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get segmentalRaw => $composableBuilder(
      column: $table.segmentalRaw,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartRateBpm => $composableBuilder(
      column: $table.heartRateBpm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCmAtTime => $composableBuilder(
      column: $table.heightCmAtTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ageYearsAtTime => $composableBuilder(
      column: $table.ageYearsAtTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sexAtTime => $composableBuilder(
      column: $table.sexAtTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatFreeMassKg => $composableBuilder(
      column: $table.fatFreeMassKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalBodyWaterL => $composableBuilder(
      column: $table.totalBodyWaterL,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get skeletalMuscleKg => $composableBuilder(
      column: $table.skeletalMuscleKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restingKcal => $composableBuilder(
      column: $table.restingKcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equation => $composableBuilder(
      column: $table.equation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get context => $composableBuilder(
      column: $table.context, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get impedanceOhm => $composableBuilder(
      column: $table.impedanceOhm, builder: (column) => column);

  GeneratedColumn<double> get reactanceOhm => $composableBuilder(
      column: $table.reactanceOhm, builder: (column) => column);

  GeneratedColumn<String> get segmentalRaw => $composableBuilder(
      column: $table.segmentalRaw, builder: (column) => column);

  GeneratedColumn<int> get heartRateBpm => $composableBuilder(
      column: $table.heartRateBpm, builder: (column) => column);

  GeneratedColumn<double> get heightCmAtTime => $composableBuilder(
      column: $table.heightCmAtTime, builder: (column) => column);

  GeneratedColumn<int> get ageYearsAtTime => $composableBuilder(
      column: $table.ageYearsAtTime, builder: (column) => column);

  GeneratedColumn<String> get sexAtTime =>
      $composableBuilder(column: $table.sexAtTime, builder: (column) => column);

  GeneratedColumn<double> get fatFreeMassKg => $composableBuilder(
      column: $table.fatFreeMassKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercent => $composableBuilder(
      column: $table.bodyFatPercent, builder: (column) => column);

  GeneratedColumn<double> get totalBodyWaterL => $composableBuilder(
      column: $table.totalBodyWaterL, builder: (column) => column);

  GeneratedColumn<double> get skeletalMuscleKg => $composableBuilder(
      column: $table.skeletalMuscleKg, builder: (column) => column);

  GeneratedColumn<int> get restingKcal => $composableBuilder(
      column: $table.restingKcal, builder: (column) => column);

  GeneratedColumn<String> get equation =>
      $composableBuilder(column: $table.equation, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()> {
  $$BodyMeasurementsTableTableManager(
      _$AppDatabase db, $BodyMeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<DateTime> takenAt = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<double?> impedanceOhm = const Value.absent(),
            Value<double?> reactanceOhm = const Value.absent(),
            Value<String?> segmentalRaw = const Value.absent(),
            Value<int?> heartRateBpm = const Value.absent(),
            Value<double?> heightCmAtTime = const Value.absent(),
            Value<int?> ageYearsAtTime = const Value.absent(),
            Value<String?> sexAtTime = const Value.absent(),
            Value<double?> fatFreeMassKg = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<double?> totalBodyWaterL = const Value.absent(),
            Value<double?> skeletalMuscleKg = const Value.absent(),
            Value<int?> restingKcal = const Value.absent(),
            Value<String?> equation = const Value.absent(),
            Value<String> confidence = const Value.absent(),
            Value<String> context = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMeasurementsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            deviceId: deviceId,
            takenAt: takenAt,
            weightKg: weightKg,
            impedanceOhm: impedanceOhm,
            reactanceOhm: reactanceOhm,
            segmentalRaw: segmentalRaw,
            heartRateBpm: heartRateBpm,
            heightCmAtTime: heightCmAtTime,
            ageYearsAtTime: ageYearsAtTime,
            sexAtTime: sexAtTime,
            fatFreeMassKg: fatFreeMassKg,
            bodyFatPercent: bodyFatPercent,
            totalBodyWaterL: totalBodyWaterL,
            skeletalMuscleKg: skeletalMuscleKg,
            restingKcal: restingKcal,
            equation: equation,
            confidence: confidence,
            context: context,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String userId,
            Value<String?> deviceId = const Value.absent(),
            required DateTime takenAt,
            required double weightKg,
            Value<double?> impedanceOhm = const Value.absent(),
            Value<double?> reactanceOhm = const Value.absent(),
            Value<String?> segmentalRaw = const Value.absent(),
            Value<int?> heartRateBpm = const Value.absent(),
            Value<double?> heightCmAtTime = const Value.absent(),
            Value<int?> ageYearsAtTime = const Value.absent(),
            Value<String?> sexAtTime = const Value.absent(),
            Value<double?> fatFreeMassKg = const Value.absent(),
            Value<double?> bodyFatPercent = const Value.absent(),
            Value<double?> totalBodyWaterL = const Value.absent(),
            Value<double?> skeletalMuscleKg = const Value.absent(),
            Value<int?> restingKcal = const Value.absent(),
            Value<String?> equation = const Value.absent(),
            Value<String> confidence = const Value.absent(),
            Value<String> context = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BodyMeasurementsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            deviceId: deviceId,
            takenAt: takenAt,
            weightKg: weightKg,
            impedanceOhm: impedanceOhm,
            reactanceOhm: reactanceOhm,
            segmentalRaw: segmentalRaw,
            heartRateBpm: heartRateBpm,
            heightCmAtTime: heightCmAtTime,
            ageYearsAtTime: ageYearsAtTime,
            sexAtTime: sexAtTime,
            fatFreeMassKg: fatFreeMassKg,
            bodyFatPercent: bodyFatPercent,
            totalBodyWaterL: totalBodyWaterL,
            skeletalMuscleKg: skeletalMuscleKg,
            restingKcal: restingKcal,
            equation: equation,
            confidence: confidence,
            context: context,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BodyMeasurementsTable, BodyMeasurement>(table),
                    BaseReferences<_$AppDatabase, $BodyMeasurementsTable,
                        BodyMeasurement>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyMeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()>;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  required DateTime eatenAt,
  Value<String> slot,
  Value<String?> note,
  Value<String?> photoPath,
  Value<int> rowid,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<DateTime> eatenAt,
  Value<String> slot,
  Value<String?> note,
  Value<String?> photoPath,
  Value<int> rowid,
});

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
      column: $table.eatenAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
      column: $table.eatenAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);
}

class $$MealsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, BaseReferences<_$AppDatabase, $MealsTable, Meal>),
    Meal,
    PrefetchHooks Function()> {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> eatenAt = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            eatenAt: eatenAt,
            slot: slot,
            note: note,
            photoPath: photoPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String userId,
            required DateTime eatenAt,
            Value<String> slot = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            eatenAt: eatenAt,
            slot: slot,
            note: note,
            photoPath: photoPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MealsTable, Meal>(table),
                    BaseReferences<_$AppDatabase, $MealsTable, Meal>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, BaseReferences<_$AppDatabase, $MealsTable, Meal>),
    Meal,
    PrefetchHooks Function()>;
typedef $$MealComponentsTableCreateCompanionBuilder = MealComponentsCompanion
    Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String mealId,
  required String userId,
  Value<String?> foodId,
  required String foodName,
  Value<String?> foodSource,
  required double grams,
  required String method,
  required double kcal,
  Value<double?> proteinG,
  Value<double?> carbG,
  Value<double?> fatG,
  Value<double?> sugarG,
  Value<double?> saturatesG,
  Value<double?> fibreG,
  Value<double?> saltG,
  Value<bool> isCookingFat,
  Value<double?> estimatedGrams,
  Value<int> position,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$MealComponentsTableUpdateCompanionBuilder = MealComponentsCompanion
    Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> mealId,
  Value<String> userId,
  Value<String?> foodId,
  Value<String> foodName,
  Value<String?> foodSource,
  Value<double> grams,
  Value<String> method,
  Value<double> kcal,
  Value<double?> proteinG,
  Value<double?> carbG,
  Value<double?> fatG,
  Value<double?> sugarG,
  Value<double?> saturatesG,
  Value<double?> fibreG,
  Value<double?> saltG,
  Value<bool> isCookingFat,
  Value<double?> estimatedGrams,
  Value<int> position,
  Value<String?> note,
  Value<int> rowid,
});

class $$MealComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $MealComponentsTable> {
  $$MealComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodId => $composableBuilder(
      column: $table.foodId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foodSource => $composableBuilder(
      column: $table.foodSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sugarG => $composableBuilder(
      column: $table.sugarG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saturatesG => $composableBuilder(
      column: $table.saturatesG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fibreG => $composableBuilder(
      column: $table.fibreG, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saltG => $composableBuilder(
      column: $table.saltG, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCookingFat => $composableBuilder(
      column: $table.isCookingFat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get estimatedGrams => $composableBuilder(
      column: $table.estimatedGrams,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$MealComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealComponentsTable> {
  $$MealComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodId => $composableBuilder(
      column: $table.foodId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodName => $composableBuilder(
      column: $table.foodName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foodSource => $composableBuilder(
      column: $table.foodSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get grams => $composableBuilder(
      column: $table.grams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sugarG => $composableBuilder(
      column: $table.sugarG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saturatesG => $composableBuilder(
      column: $table.saturatesG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fibreG => $composableBuilder(
      column: $table.fibreG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saltG => $composableBuilder(
      column: $table.saltG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCookingFat => $composableBuilder(
      column: $table.isCookingFat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get estimatedGrams => $composableBuilder(
      column: $table.estimatedGrams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$MealComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealComponentsTable> {
  $$MealComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<String> get foodSource => $composableBuilder(
      column: $table.foodSource, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get saturatesG => $composableBuilder(
      column: $table.saturatesG, builder: (column) => column);

  GeneratedColumn<double> get fibreG =>
      $composableBuilder(column: $table.fibreG, builder: (column) => column);

  GeneratedColumn<double> get saltG =>
      $composableBuilder(column: $table.saltG, builder: (column) => column);

  GeneratedColumn<bool> get isCookingFat => $composableBuilder(
      column: $table.isCookingFat, builder: (column) => column);

  GeneratedColumn<double> get estimatedGrams => $composableBuilder(
      column: $table.estimatedGrams, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$MealComponentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealComponentsTable,
    MealComponent,
    $$MealComponentsTableFilterComposer,
    $$MealComponentsTableOrderingComposer,
    $$MealComponentsTableAnnotationComposer,
    $$MealComponentsTableCreateCompanionBuilder,
    $$MealComponentsTableUpdateCompanionBuilder,
    (
      MealComponent,
      BaseReferences<_$AppDatabase, $MealComponentsTable, MealComponent>
    ),
    MealComponent,
    PrefetchHooks Function()> {
  $$MealComponentsTableTableManager(
      _$AppDatabase db, $MealComponentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealComponentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealComponentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> mealId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> foodId = const Value.absent(),
            Value<String> foodName = const Value.absent(),
            Value<String?> foodSource = const Value.absent(),
            Value<double> grams = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<double> kcal = const Value.absent(),
            Value<double?> proteinG = const Value.absent(),
            Value<double?> carbG = const Value.absent(),
            Value<double?> fatG = const Value.absent(),
            Value<double?> sugarG = const Value.absent(),
            Value<double?> saturatesG = const Value.absent(),
            Value<double?> fibreG = const Value.absent(),
            Value<double?> saltG = const Value.absent(),
            Value<bool> isCookingFat = const Value.absent(),
            Value<double?> estimatedGrams = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealComponentsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            mealId: mealId,
            userId: userId,
            foodId: foodId,
            foodName: foodName,
            foodSource: foodSource,
            grams: grams,
            method: method,
            kcal: kcal,
            proteinG: proteinG,
            carbG: carbG,
            fatG: fatG,
            sugarG: sugarG,
            saturatesG: saturatesG,
            fibreG: fibreG,
            saltG: saltG,
            isCookingFat: isCookingFat,
            estimatedGrams: estimatedGrams,
            position: position,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String mealId,
            required String userId,
            Value<String?> foodId = const Value.absent(),
            required String foodName,
            Value<String?> foodSource = const Value.absent(),
            required double grams,
            required String method,
            required double kcal,
            Value<double?> proteinG = const Value.absent(),
            Value<double?> carbG = const Value.absent(),
            Value<double?> fatG = const Value.absent(),
            Value<double?> sugarG = const Value.absent(),
            Value<double?> saturatesG = const Value.absent(),
            Value<double?> fibreG = const Value.absent(),
            Value<double?> saltG = const Value.absent(),
            Value<bool> isCookingFat = const Value.absent(),
            Value<double?> estimatedGrams = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MealComponentsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            mealId: mealId,
            userId: userId,
            foodId: foodId,
            foodName: foodName,
            foodSource: foodSource,
            grams: grams,
            method: method,
            kcal: kcal,
            proteinG: proteinG,
            carbG: carbG,
            fatG: fatG,
            sugarG: sugarG,
            saturatesG: saturatesG,
            fibreG: fibreG,
            saltG: saltG,
            isCookingFat: isCookingFat,
            estimatedGrams: estimatedGrams,
            position: position,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MealComponentsTable, MealComponent>(table),
                    BaseReferences<_$AppDatabase, $MealComponentsTable,
                        MealComponent>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealComponentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealComponentsTable,
    MealComponent,
    $$MealComponentsTableFilterComposer,
    $$MealComponentsTableOrderingComposer,
    $$MealComponentsTableAnnotationComposer,
    $$MealComponentsTableCreateCompanionBuilder,
    $$MealComponentsTableUpdateCompanionBuilder,
    (
      MealComponent,
      BaseReferences<_$AppDatabase, $MealComponentsTable, MealComponent>
    ),
    MealComponent,
    PrefetchHooks Function()>;
typedef $$FoodsTableCreateCompanionBuilder = FoodsCompanion Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  Value<String?> userId,
  required String name,
  Value<String?> brand,
  Value<String?> barcode,
  required String source,
  Value<bool> isCooked,
  required double kcal100g,
  Value<double?> protein100g,
  Value<double?> carb100g,
  Value<double?> sugar100g,
  Value<double?> fat100g,
  Value<double?> saturates100g,
  Value<double?> fibre100g,
  Value<double?> salt100g,
  Value<String> householdMeasures,
  Value<int> rowid,
});
typedef $$FoodsTableUpdateCompanionBuilder = FoodsCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String?> userId,
  Value<String> name,
  Value<String?> brand,
  Value<String?> barcode,
  Value<String> source,
  Value<bool> isCooked,
  Value<double> kcal100g,
  Value<double?> protein100g,
  Value<double?> carb100g,
  Value<double?> sugar100g,
  Value<double?> fat100g,
  Value<double?> saturates100g,
  Value<double?> fibre100g,
  Value<double?> salt100g,
  Value<String> householdMeasures,
  Value<int> rowid,
});

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCooked => $composableBuilder(
      column: $table.isCooked, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal100g => $composableBuilder(
      column: $table.kcal100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carb100g => $composableBuilder(
      column: $table.carb100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sugar100g => $composableBuilder(
      column: $table.sugar100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat100g => $composableBuilder(
      column: $table.fat100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saturates100g => $composableBuilder(
      column: $table.saturates100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fibre100g => $composableBuilder(
      column: $table.fibre100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salt100g => $composableBuilder(
      column: $table.salt100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdMeasures => $composableBuilder(
      column: $table.householdMeasures,
      builder: (column) => ColumnFilters(column));
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCooked => $composableBuilder(
      column: $table.isCooked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal100g => $composableBuilder(
      column: $table.kcal100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carb100g => $composableBuilder(
      column: $table.carb100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sugar100g => $composableBuilder(
      column: $table.sugar100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat100g => $composableBuilder(
      column: $table.fat100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saturates100g => $composableBuilder(
      column: $table.saturates100g,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fibre100g => $composableBuilder(
      column: $table.fibre100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salt100g => $composableBuilder(
      column: $table.salt100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdMeasures => $composableBuilder(
      column: $table.householdMeasures,
      builder: (column) => ColumnOrderings(column));
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isCooked =>
      $composableBuilder(column: $table.isCooked, builder: (column) => column);

  GeneratedColumn<double> get kcal100g =>
      $composableBuilder(column: $table.kcal100g, builder: (column) => column);

  GeneratedColumn<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => column);

  GeneratedColumn<double> get carb100g =>
      $composableBuilder(column: $table.carb100g, builder: (column) => column);

  GeneratedColumn<double> get sugar100g =>
      $composableBuilder(column: $table.sugar100g, builder: (column) => column);

  GeneratedColumn<double> get fat100g =>
      $composableBuilder(column: $table.fat100g, builder: (column) => column);

  GeneratedColumn<double> get saturates100g => $composableBuilder(
      column: $table.saturates100g, builder: (column) => column);

  GeneratedColumn<double> get fibre100g =>
      $composableBuilder(column: $table.fibre100g, builder: (column) => column);

  GeneratedColumn<double> get salt100g =>
      $composableBuilder(column: $table.salt100g, builder: (column) => column);

  GeneratedColumn<String> get householdMeasures => $composableBuilder(
      column: $table.householdMeasures, builder: (column) => column);
}

class $$FoodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoodsTable,
    Food,
    $$FoodsTableFilterComposer,
    $$FoodsTableOrderingComposer,
    $$FoodsTableAnnotationComposer,
    $$FoodsTableCreateCompanionBuilder,
    $$FoodsTableUpdateCompanionBuilder,
    (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
    Food,
    PrefetchHooks Function()> {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<bool> isCooked = const Value.absent(),
            Value<double> kcal100g = const Value.absent(),
            Value<double?> protein100g = const Value.absent(),
            Value<double?> carb100g = const Value.absent(),
            Value<double?> sugar100g = const Value.absent(),
            Value<double?> fat100g = const Value.absent(),
            Value<double?> saturates100g = const Value.absent(),
            Value<double?> fibre100g = const Value.absent(),
            Value<double?> salt100g = const Value.absent(),
            Value<String> householdMeasures = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoodsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            name: name,
            brand: brand,
            barcode: barcode,
            source: source,
            isCooked: isCooked,
            kcal100g: kcal100g,
            protein100g: protein100g,
            carb100g: carb100g,
            sugar100g: sugar100g,
            fat100g: fat100g,
            saturates100g: saturates100g,
            fibre100g: fibre100g,
            salt100g: salt100g,
            householdMeasures: householdMeasures,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            Value<String?> userId = const Value.absent(),
            required String name,
            Value<String?> brand = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            required String source,
            Value<bool> isCooked = const Value.absent(),
            required double kcal100g,
            Value<double?> protein100g = const Value.absent(),
            Value<double?> carb100g = const Value.absent(),
            Value<double?> sugar100g = const Value.absent(),
            Value<double?> fat100g = const Value.absent(),
            Value<double?> saturates100g = const Value.absent(),
            Value<double?> fibre100g = const Value.absent(),
            Value<double?> salt100g = const Value.absent(),
            Value<String> householdMeasures = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoodsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            name: name,
            brand: brand,
            barcode: barcode,
            source: source,
            isCooked: isCooked,
            kcal100g: kcal100g,
            protein100g: protein100g,
            carb100g: carb100g,
            sugar100g: sugar100g,
            fat100g: fat100g,
            saturates100g: saturates100g,
            fibre100g: fibre100g,
            salt100g: salt100g,
            householdMeasures: householdMeasures,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$FoodsTable, Food>(table),
                    BaseReferences<_$AppDatabase, $FoodsTable, Food>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FoodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FoodsTable,
    Food,
    $$FoodsTableFilterComposer,
    $$FoodsTableOrderingComposer,
    $$FoodsTableAnnotationComposer,
    $$FoodsTableCreateCompanionBuilder,
    $$FoodsTableUpdateCompanionBuilder,
    (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
    Food,
    PrefetchHooks Function()>;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  required String name,
  required double yieldGrams,
  required double kcal100g,
  Value<double?> protein100g,
  Value<double?> carb100g,
  Value<double?> fat100g,
  Value<String> ingredients,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<double> yieldGrams,
  Value<double> kcal100g,
  Value<double?> protein100g,
  Value<double?> carb100g,
  Value<double?> fat100g,
  Value<String> ingredients,
  Value<int> rowid,
});

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get yieldGrams => $composableBuilder(
      column: $table.yieldGrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal100g => $composableBuilder(
      column: $table.kcal100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carb100g => $composableBuilder(
      column: $table.carb100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat100g => $composableBuilder(
      column: $table.fat100g, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => ColumnFilters(column));
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get yieldGrams => $composableBuilder(
      column: $table.yieldGrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal100g => $composableBuilder(
      column: $table.kcal100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carb100g => $composableBuilder(
      column: $table.carb100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat100g => $composableBuilder(
      column: $table.fat100g, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => ColumnOrderings(column));
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get yieldGrams => $composableBuilder(
      column: $table.yieldGrams, builder: (column) => column);

  GeneratedColumn<double> get kcal100g =>
      $composableBuilder(column: $table.kcal100g, builder: (column) => column);

  GeneratedColumn<double> get protein100g => $composableBuilder(
      column: $table.protein100g, builder: (column) => column);

  GeneratedColumn<double> get carb100g =>
      $composableBuilder(column: $table.carb100g, builder: (column) => column);

  GeneratedColumn<double> get fat100g =>
      $composableBuilder(column: $table.fat100g, builder: (column) => column);

  GeneratedColumn<String> get ingredients => $composableBuilder(
      column: $table.ingredients, builder: (column) => column);
}

class $$RecipesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipesTable,
    Recipe,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
    Recipe,
    PrefetchHooks Function()> {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> yieldGrams = const Value.absent(),
            Value<double> kcal100g = const Value.absent(),
            Value<double?> protein100g = const Value.absent(),
            Value<double?> carb100g = const Value.absent(),
            Value<double?> fat100g = const Value.absent(),
            Value<String> ingredients = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            name: name,
            yieldGrams: yieldGrams,
            kcal100g: kcal100g,
            protein100g: protein100g,
            carb100g: carb100g,
            fat100g: fat100g,
            ingredients: ingredients,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String userId,
            required String name,
            required double yieldGrams,
            required double kcal100g,
            Value<double?> protein100g = const Value.absent(),
            Value<double?> carb100g = const Value.absent(),
            Value<double?> fat100g = const Value.absent(),
            Value<String> ingredients = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            name: name,
            yieldGrams: yieldGrams,
            kcal100g: kcal100g,
            protein100g: protein100g,
            carb100g: carb100g,
            fat100g: fat100g,
            ingredients: ingredients,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecipesTable, Recipe>(table),
                    BaseReferences<_$AppDatabase, $RecipesTable, Recipe>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipesTable,
    Recipe,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
    Recipe,
    PrefetchHooks Function()>;
typedef $$DailyTargetsTableCreateCompanionBuilder = DailyTargetsCompanion
    Function({
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  required String effectiveFrom,
  required int kcal,
  Value<int?> proteinG,
  Value<int?> carbG,
  Value<int?> fatG,
  Value<String?> basis,
  Value<int> rowid,
});
typedef $$DailyTargetsTableUpdateCompanionBuilder = DailyTargetsCompanion
    Function({
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<String> effectiveFrom,
  Value<int> kcal,
  Value<int?> proteinG,
  Value<int?> carbG,
  Value<int?> fatG,
  Value<String?> basis,
  Value<int> rowid,
});

class $$DailyTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyTargetsTable> {
  $$DailyTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get basis => $composableBuilder(
      column: $table.basis, builder: (column) => ColumnFilters(column));
}

class $$DailyTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyTargetsTable> {
  $$DailyTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kcal => $composableBuilder(
      column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get proteinG => $composableBuilder(
      column: $table.proteinG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get carbG => $composableBuilder(
      column: $table.carbG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fatG => $composableBuilder(
      column: $table.fatG, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get basis => $composableBuilder(
      column: $table.basis, builder: (column) => ColumnOrderings(column));
}

class $$DailyTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyTargetsTable> {
  $$DailyTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get effectiveFrom => $composableBuilder(
      column: $table.effectiveFrom, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<int> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<int> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<int> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get basis =>
      $composableBuilder(column: $table.basis, builder: (column) => column);
}

class $$DailyTargetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyTargetsTable,
    DailyTarget,
    $$DailyTargetsTableFilterComposer,
    $$DailyTargetsTableOrderingComposer,
    $$DailyTargetsTableAnnotationComposer,
    $$DailyTargetsTableCreateCompanionBuilder,
    $$DailyTargetsTableUpdateCompanionBuilder,
    (
      DailyTarget,
      BaseReferences<_$AppDatabase, $DailyTargetsTable, DailyTarget>
    ),
    DailyTarget,
    PrefetchHooks Function()> {
  $$DailyTargetsTableTableManager(_$AppDatabase db, $DailyTargetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> effectiveFrom = const Value.absent(),
            Value<int> kcal = const Value.absent(),
            Value<int?> proteinG = const Value.absent(),
            Value<int?> carbG = const Value.absent(),
            Value<int?> fatG = const Value.absent(),
            Value<String?> basis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyTargetsCompanion(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            effectiveFrom: effectiveFrom,
            kcal: kcal,
            proteinG: proteinG,
            carbG: carbG,
            fatG: fatG,
            basis: basis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            required String id,
            required String userId,
            required String effectiveFrom,
            required int kcal,
            Value<int?> proteinG = const Value.absent(),
            Value<int?> carbG = const Value.absent(),
            Value<int?> fatG = const Value.absent(),
            Value<String?> basis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyTargetsCompanion.insert(
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            deletedAt: deletedAt,
            id: id,
            userId: userId,
            effectiveFrom: effectiveFrom,
            kcal: kcal,
            proteinG: proteinG,
            carbG: carbG,
            fatG: fatG,
            basis: basis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DailyTargetsTable, DailyTarget>(table),
                    BaseReferences<_$AppDatabase, $DailyTargetsTable,
                        DailyTarget>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyTargetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyTargetsTable,
    DailyTarget,
    $$DailyTargetsTableFilterComposer,
    $$DailyTargetsTableOrderingComposer,
    $$DailyTargetsTableAnnotationComposer,
    $$DailyTargetsTableCreateCompanionBuilder,
    $$DailyTargetsTableUpdateCompanionBuilder,
    (
      DailyTarget,
      BaseReferences<_$AppDatabase, $DailyTargetsTable, DailyTarget>
    ),
    DailyTarget,
    PrefetchHooks Function()>;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()> {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncStateTable, SyncStateData>(table),
                    BaseReferences<_$AppDatabase, $SyncStateTable,
                        SyncStateData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStateTable,
    SyncStateData,
    $$SyncStateTableFilterComposer,
    $$SyncStateTableOrderingComposer,
    $$SyncStateTableAnnotationComposer,
    $$SyncStateTableCreateCompanionBuilder,
    $$SyncStateTableUpdateCompanionBuilder,
    (
      SyncStateData,
      BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>
    ),
    SyncStateData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ConsentsTableTableManager get consents =>
      $$ConsentsTableTableManager(_db, _db.consents);
  $$ObservationsTableTableManager get observations =>
      $$ObservationsTableTableManager(_db, _db.observations);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealComponentsTableTableManager get mealComponents =>
      $$MealComponentsTableTableManager(_db, _db.mealComponents);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$DailyTargetsTableTableManager get dailyTargets =>
      $$DailyTargetsTableTableManager(_db, _db.dailyTargets);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
