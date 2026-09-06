/// [SyncRemote] over the Supabase client.
///
/// Every table is behind row-level security keyed to `auth.uid()`, so nothing
/// moves without a session. A fresh install gets an anonymous one: the diary
/// is backed up from the first day, and Phase 4 links that user to Apple,
/// Google or an email address without re-keying a single row.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_remote.dart';

class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> ensureUserId() async {
    final current = _client.auth.currentSession;
    if (current != null) return current.user.id;
    try {
      final response = await _client.auth.signInAnonymously();
      return response.user?.id;
    } on Object {
      // Offline, or anonymous sign-ins not enabled on the project. Either way
      // the app carries on locally and tries again on the next tick.
      return null;
    }
  }

  @override
  Future<void> upsert(
    String table,
    List<Map<String, Object?>> rows, {
    bool insertOnly = false,
  }) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows, ignoreDuplicates: insertOnly);
  }

  @override
  Future<List<Map<String, Object?>>> pullSince(
    String table, {
    required String userColumn,
    required String userId,
    required String cursorColumn,
    DateTime? since,
    int limit = 500,
  }) async {
    var query = _client.from(table).select().eq(userColumn, userId);
    if (since != null) {
      query = query.gt(cursorColumn, since.toUtc().toIso8601String());
    }
    final rows = await query.order(cursorColumn, ascending: true).limit(limit);
    return [for (final r in rows) Map<String, Object?>.from(r)];
  }
}
