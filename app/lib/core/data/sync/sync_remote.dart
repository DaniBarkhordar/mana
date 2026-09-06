/// What the sync engine needs from a server. Kept minimal so a fake can stand
/// in for Supabase in tests, and so the engine never sees a client type.
library;

abstract class SyncRemote {
  /// The signed-in user's id. Implementations may establish a session on the
  /// way (anonymous sign-in); null means no session could be had, and the
  /// engine leaves everything local.
  Future<String?> ensureUserId();

  /// Upserts [rows] into [table]. With [insertOnly], rows that already exist
  /// are ignored rather than updated (consents).
  Future<void> upsert(
    String table,
    List<Map<String, Object?>> rows, {
    bool insertOnly = false,
  });

  /// Rows of [table] owned by [userId] whose [cursorColumn] is after [since],
  /// oldest first, at most [limit].
  Future<List<Map<String, Object?>>> pullSince(
    String table, {
    required String userColumn,
    required String userId,
    required String cursorColumn,
    DateTime? since,
    int limit = 500,
  });
}
