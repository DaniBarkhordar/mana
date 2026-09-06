import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mananu/core/auth/auth_service.dart';
import 'package:mananu/core/bia/equations.dart';
import 'package:mananu/core/data/db/database.dart';
import 'package:mananu/core/data/repositories/profile_repository.dart';

/// A backend that can be told what it will do.
class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend(this._status, {this.identityTaken = false});

  AccountStatus _status;
  final bool identityTaken;
  final calls = <String>[];
  final _changes = StreamController<AccountStatus>.broadcast();

  @override
  AccountStatus get current => _status;

  @override
  Stream<AccountStatus> get changes => _changes.stream;

  @override
  Future<void> linkIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) async {
    calls.add('link ${provider.name}');
    if (identityTaken) throw const IdentityTakenException();
    _status = AccountStatus(
      kind: AccountKind.signedIn,
      userId: _status.userId,
      provider: provider,
    );
  }

  @override
  Future<String> signInWithIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) async {
    calls.add('signIn ${provider.name}');
    _status = AccountStatus(
      kind: AccountKind.signedIn,
      userId: 'existing-user',
      provider: provider,
    );
    return 'existing-user';
  }

  @override
  Future<void> sendEmailCode(String email, {required bool linking}) async {
    calls.add('send $email linking=$linking');
  }

  @override
  Future<String> verifyEmailCode(
    String email,
    String code, {
    required bool linking,
  }) async {
    calls.add('verify $email $code linking=$linking');
    final uid = linking ? _status.userId! : 'existing-user';
    _status = AccountStatus(
      kind: AccountKind.signedIn,
      userId: uid,
      email: email,
      provider: IdentityProvider.email,
    );
    return uid;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _status = AccountStatus.none;
  }
}

void main() {
  late AppDatabase db;
  late String anonymousUid;

  setUp(() async {
    db = AppDatabase.memory();
    // Sync already adopted an anonymous user, and the diary has a row.
    anonymousUid = 'anon-1';
    await db.adoptUser(anonymousUid);
    await ProfileRepository(db).save(
      heightCm: 178,
      dateOfBirth: DateTime(1992, 3, 4),
      sex: Sex.male,
      activity: ActivityLevel.lowActive,
    );
  });

  tearDown(() => db.close());

  test('linking keeps the user id, so nothing is re-keyed', () async {
    final backend = FakeAuthBackend(
      AccountStatus(kind: AccountKind.anonymous, userId: anonymousUid),
    );
    final auth = AuthService(backend, db);
    await auth.linkOrSignInWithIdToken(
      provider: IdentityProvider.apple,
      idToken: 't',
      nonce: 'n',
    );
    expect(backend.calls, ['link apple']);
    expect(auth.status.isSignedIn, isTrue);
    expect(await db.localUserId(), anonymousUid);
  });

  test(
      'an identity that already has an account switches user and carries '
      'the rows along', () async {
    final backend = FakeAuthBackend(
      AccountStatus(kind: AccountKind.anonymous, userId: anonymousUid),
      identityTaken: true,
    );
    final auth = AuthService(backend, db);
    await auth.linkOrSignInWithIdToken(
      provider: IdentityProvider.google,
      idToken: 't',
    );
    expect(backend.calls, ['link google', 'signIn google']);
    expect(await db.localUserId(), 'existing-user');
    final profile = await db.select(db.profiles).getSingle();
    expect(profile.id, 'existing-user');
  });

  test(
      'email: an anonymous user attaches the address; a signed-out phone '
      'signs in', () async {
    final backend = FakeAuthBackend(
      AccountStatus(kind: AccountKind.anonymous, userId: anonymousUid),
    );
    final auth = AuthService(backend, db);
    await auth.sendEmailCode(' dan@example.com ');
    await auth.verifyEmailCode('dan@example.com', ' 123456 ');
    expect(backend.calls, [
      'send dan@example.com linking=true',
      'verify dan@example.com 123456 linking=true',
    ]);
    expect(auth.status.email, 'dan@example.com');
    expect(await db.localUserId(), anonymousUid);

    final fresh = FakeAuthBackend(AccountStatus.none);
    final auth2 = AuthService(fresh, db);
    await auth2.sendEmailCode('dan@example.com');
    await auth2.verifyEmailCode('dan@example.com', '654321');
    expect(fresh.calls.last, 'verify dan@example.com 654321 linking=false');
    expect(await db.localUserId(), 'existing-user');
  });

  test('sign-out wipes this phone', () async {
    final backend = FakeAuthBackend(
      const AccountStatus(kind: AccountKind.signedIn, userId: 'u'),
    );
    var wiped = false;
    await AuthService(backend, db).signOut(wipeLocal: () async => wiped = true);
    expect(backend.calls, ['signOut']);
    expect(wiped, isTrue);
  });

  test('status labels', () {
    expect(AccountStatus.none.label, 'Not signed in');
    expect(
      const AccountStatus(kind: AccountKind.anonymous).label,
      'Temporary account on this phone',
    );
    expect(
      const AccountStatus(
        kind: AccountKind.signedIn,
        provider: IdentityProvider.apple,
      ).label,
      'Signed in with Apple',
    );
    expect(
      const AccountStatus(kind: AccountKind.signedIn, email: 'a@b.c').label,
      'a@b.c',
    );
  });
}
