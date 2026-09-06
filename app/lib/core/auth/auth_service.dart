/// Accounts.
///
/// A fresh install syncs under an anonymous user from day one, so the diary is
/// backed up before the person has typed anything. Signing in is then a
/// *link*: the anonymous user gains an Apple, Google or email identity and
/// keeps its id, so not one row is re-keyed. Only when that identity already
/// belongs to another account (the person had Mananu on an earlier phone) do
/// we switch users — and then the local rows follow them into that account.
///
/// Apple is offered first on iOS: guideline 4.8 requires it wherever any
/// third-party sign-in is offered, and it is the one that shares the least.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/db/database.dart';

enum AccountKind {
  /// No backend configured, or no session yet.
  none,

  /// Synced under a temporary user. Lost with the phone.
  anonymous,

  /// Linked to an identity the person can sign back in with.
  signedIn,
}

enum IdentityProvider { apple, google, email }

class AccountStatus {
  const AccountStatus({
    required this.kind,
    this.userId,
    this.email,
    this.provider,
  });

  static const none = AccountStatus(kind: AccountKind.none);

  final AccountKind kind;
  final String? userId;
  final String? email;
  final IdentityProvider? provider;

  bool get isSignedIn => kind == AccountKind.signedIn;
  bool get isAnonymous => kind == AccountKind.anonymous;

  /// "Signed in with Apple", "you@example.com" — what the Account screen
  /// shows under the heading.
  String get label => switch (kind) {
        AccountKind.none => 'Not signed in',
        AccountKind.anonymous => 'Temporary account on this phone',
        AccountKind.signedIn => email ??
            switch (provider) {
              IdentityProvider.apple => 'Signed in with Apple',
              IdentityProvider.google => 'Signed in with Google',
              IdentityProvider.email => 'Signed in by email',
              null => 'Signed in',
            },
      };
}

/// What the auth service needs from the backend, so the linking logic can be
/// tested without a Supabase project.
abstract class AuthBackend {
  AccountStatus get current;
  Stream<AccountStatus> get changes;

  /// Adds an identity to the current (anonymous) user. Throws
  /// [IdentityTakenException] when the identity belongs to another account.
  Future<void> linkIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  });

  /// Signs in as whoever owns the identity. Returns the user id.
  Future<String> signInWithIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  });

  /// Sends a one-time code. With [linking], the code attaches the address to
  /// the current anonymous user instead of signing in as someone else.
  Future<void> sendEmailCode(String email, {required bool linking});

  /// Returns the user id the session ends up on.
  Future<String> verifyEmailCode(
    String email,
    String code, {
    required bool linking,
  });

  Future<void> signOut();
}

class IdentityTakenException implements Exception {
  const IdentityTakenException();
}

/// Thrown when the person cancels a native sign-in sheet. Not an error to
/// show.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Google needs a client id per platform to mint an id token we can hand to
/// Supabase. Both come from the Google Cloud console for the project; the
/// web client id is the one Supabase's Google provider is configured with.
class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get isConfigured => webClientId.isNotEmpty;
}

class AuthService {
  AuthService(this._backend, this._db);

  final AuthBackend _backend;
  final AppDatabase _db;

  AccountStatus get status => _backend.current;
  Stream<AccountStatus> get changes => _backend.changes;

  static bool get appleAvailable => Platform.isIOS || Platform.isMacOS;
  static bool get googleAvailable => GoogleAuthConfig.isConfigured;

  Future<void> signInWithApple() async {
    // A nonce ties the Apple token to this request; Apple gets the hash,
    // Supabase gets the raw value to check it.
    final rawNonce = _randomNonce();
    final hashed = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hashed,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null) throw StateError('Apple returned no identity token');
    await linkOrSignInWithIdToken(
      provider: IdentityProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await google.initialize(
      clientId: GoogleAuthConfig.iosClientId.isEmpty
          ? null
          : GoogleAuthConfig.iosClientId,
      serverClientId: GoogleAuthConfig.webClientId,
    );
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google returned no id token');
    await linkOrSignInWithIdToken(
      provider: IdentityProvider.google,
      idToken: idToken,
    );
  }

  Future<void> sendEmailCode(String email) =>
      _backend.sendEmailCode(email.trim(), linking: status.isAnonymous);

  Future<void> verifyEmailCode(String email, String code) async {
    final uid = await _backend.verifyEmailCode(
      email.trim(),
      code.trim(),
      linking: status.isAnonymous,
    );
    await _db.adoptUser(uid);
  }

  /// Link when we can, sign in when the identity is already someone's, and in
  /// the second case carry this phone's rows into that account.
  Future<void> linkOrSignInWithIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
  }) async {
    if (status.isAnonymous) {
      try {
        await _backend.linkIdToken(
          provider: provider,
          idToken: idToken,
          nonce: nonce,
        );
        return;
      } on IdentityTakenException {
        // Fall through: they already have an account elsewhere.
      }
    }
    final uid = await _backend.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: nonce,
    );
    await _db.adoptUser(uid);
  }

  /// Signs out and clears this phone. The account keeps everything that was
  /// synced; a shared phone must not hand the next person a diary.
  Future<void> signOut({required Future<void> Function() wipeLocal}) async {
    await _backend.signOut();
    await wipeLocal();
  }

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer();
    var seed = random;
    for (var i = 0; i < length; i++) {
      seed = (seed * 6364136223846793005 + 1442695040888963407) & 0x7fffffff;
      buf.write(chars[seed % chars.length]);
    }
    return buf.toString();
  }
}

/// The real backend.
class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client);

  final SupabaseClient _client;

  @override
  AccountStatus get current => statusOf(_client.auth.currentUser);

  @override
  Stream<AccountStatus> get changes =>
      _client.auth.onAuthStateChange.map((e) => statusOf(e.session?.user));

  /// Pure: what a Supabase user amounts to.
  static AccountStatus statusOf(User? user) {
    if (user == null) return AccountStatus.none;
    if (user.isAnonymous) {
      return AccountStatus(kind: AccountKind.anonymous, userId: user.id);
    }
    final providers =
        (user.appMetadata['providers'] as List?)?.cast<String>() ??
            [user.appMetadata['provider'] as String? ?? ''];
    final provider = providers.contains('apple')
        ? IdentityProvider.apple
        : providers.contains('google')
            ? IdentityProvider.google
            : IdentityProvider.email;
    return AccountStatus(
      kind: AccountKind.signedIn,
      userId: user.id,
      email: user.email?.isEmpty ?? true ? null : user.email,
      provider: provider,
    );
  }

  static OAuthProvider _oauth(IdentityProvider p) => switch (p) {
        IdentityProvider.apple => OAuthProvider.apple,
        IdentityProvider.google => OAuthProvider.google,
        IdentityProvider.email => throw ArgumentError('email is not OAuth'),
      };

  @override
  Future<void> linkIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) async {
    try {
      await _client.auth.linkIdentityWithIdToken(
        provider: _oauth(provider),
        idToken: idToken,
        nonce: nonce,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      if (_identityTaken(e)) throw const IdentityTakenException();
      rethrow;
    }
  }

  static bool _identityTaken(AuthException e) =>
      e.code == 'identity_already_exists' ||
      e.statusCode == '422' ||
      e.message.toLowerCase().contains('already');

  @override
  Future<String> signInWithIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) async {
    final response = await _client.auth.signInWithIdToken(
      provider: _oauth(provider),
      idToken: idToken,
      nonce: nonce,
      accessToken: accessToken,
    );
    final uid = response.user?.id;
    if (uid == null) throw StateError('sign-in returned no user');
    return uid;
  }

  @override
  Future<void> sendEmailCode(String email, {required bool linking}) async {
    if (linking) {
      // Attaching an address to the anonymous user: Supabase sends an
      // email-change code, and the user keeps their id.
      await _client.auth.updateUser(UserAttributes(email: email));
    } else {
      await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
    }
  }

  @override
  Future<String> verifyEmailCode(
    String email,
    String code, {
    required bool linking,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: linking ? OtpType.emailChange : OtpType.email,
    );
    final uid = response.user?.id ?? _client.auth.currentUser?.id;
    if (uid == null) throw StateError('verification returned no user');
    return uid;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// A build with no backend: nothing to sign in to. The Account screen says
/// so instead of offering buttons that cannot work.
class NoAuthBackend implements AuthBackend {
  const NoAuthBackend();

  @override
  AccountStatus get current => AccountStatus.none;

  @override
  Stream<AccountStatus> get changes => const Stream.empty();

  @override
  Future<void> linkIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) =>
      throw StateError('no backend configured');

  @override
  Future<String> signInWithIdToken({
    required IdentityProvider provider,
    required String idToken,
    String? nonce,
    String? accessToken,
  }) =>
      throw StateError('no backend configured');

  @override
  Future<void> sendEmailCode(String email, {required bool linking}) =>
      throw StateError('no backend configured');

  @override
  Future<String> verifyEmailCode(
    String email,
    String code, {
    required bool linking,
  }) =>
      throw StateError('no backend configured');

  @override
  Future<void> signOut() async {}
}
