/// The user's measurement profile and their consent records.
library;

import 'package:drift/drift.dart';

import '../../bia/equations.dart';
import '../db/database.dart';
import '../models.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  /// The one profile on this device. Null until onboarding has run.
  Stream<UserProfile?> watchProfile() {
    final q = _db.select(_db.profiles)
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
      ..limit(1);
    return q.watch().map((rows) => rows.isEmpty ? null : _fromRow(rows.first));
  }

  Future<UserProfile?> currentProfile() async {
    final q = _db.select(_db.profiles)
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Creates or updates the profile and marks it for sync.
  Future<UserProfile> save({
    required double heightCm,
    required DateTime dateOfBirth,
    required Sex sex,
    required ActivityLevel activity,
    String? displayName,
  }) async {
    final id = await _db.localUserId();
    final now = DateTime.now().toUtc();
    final existing = await (_db.select(_db.profiles)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    await _db.into(_db.profiles).insertOnConflictUpdate(
          ProfilesCompanion(
            id: Value(id),
            displayName: Value(displayName),
            dateOfBirth: Value(encodeDate(dateOfBirth)),
            sex: Value(encodeSex(sex)),
            heightCm: Value(heightCm),
            activity: Value(encodeActivity(activity)),
            createdAt: Value(existing?.createdAt ?? now),
            updatedAt: Value(now),
            syncedAt: const Value(null),
          ),
        );
    return UserProfile(
      id: id,
      heightCm: heightCm,
      dateOfBirth: dateOfBirth,
      sex: sex,
      activity: activity,
      displayName: displayName,
    );
  }

  /// Appends a grant or withdrawal. Never updates: the history is the record.
  Future<void> recordConsent(ConsentRecord consent) async {
    final userId = await _db.localUserId();
    await _db.into(_db.consents).insert(
          ConsentsCompanion.insert(
            id: AppDatabase.newId(),
            userId: userId,
            purpose: consent.purpose,
            policyVersion: consent.policyVersion,
            granted: consent.granted,
            grantedAt: consent.grantedAt.toUtc(),
          ),
        );
  }

  /// The most recent decision for [purpose], or null if never asked.
  Stream<ConsentRecord?> watchLatestConsent(String purpose) =>
      _latestConsentQuery(purpose).watch().map(_consentFromRows);

  /// The standing decision right now — what a reading being stored this
  /// instant must honour.
  Future<ConsentRecord?> latestConsent(String purpose) async =>
      _consentFromRows(await _latestConsentQuery(purpose).get());

  SimpleSelectStatement<$ConsentsTable, Consent> _latestConsentQuery(
    String purpose,
  ) =>
      _db.select(_db.consents)
        ..where((c) => c.purpose.equals(purpose))
        ..orderBy([(c) => OrderingTerm.desc(c.grantedAt)])
        ..limit(1);

  static ConsentRecord? _consentFromRows(List<Consent> rows) {
    if (rows.isEmpty) return null;
    final r = rows.first;
    return ConsentRecord(
      purpose: r.purpose,
      policyVersion: r.policyVersion,
      granted: r.granted,
      grantedAt: r.grantedAt,
    );
  }

  UserProfile? _fromRow(Profile row) {
    final sex = decodeSex(row.sex);
    final dob = decodeDate(row.dateOfBirth);
    final height = row.heightCm;
    // A profile missing any equation input is not usable yet; onboarding
    // runs again rather than the app guessing.
    if (sex == null || dob == null || height == null) return null;
    return UserProfile(
      id: row.id,
      heightCm: height,
      dateOfBirth: dob,
      sex: sex,
      activity: decodeActivity(row.activity),
      displayName: row.displayName,
    );
  }
}
