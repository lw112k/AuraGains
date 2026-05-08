import 'package:auragains/core/services/database_connection.dart';
import 'package:auragains/models/user_settings_model.dart';

/// Data-access layer for the `user_setting` table.
///
/// All methods use [DatabaseConnection.client].
/// Exceptions are rethrown so the calling ViewModel can update UI state.
///
/// TEAM NOTE: The `user_setting` table must have a UNIQUE constraint on the
/// `user_id` column for the upsert operations below to work correctly.
/// Verify this in the Supabase dashboard under Table Editor → user_setting →
/// Constraints before wiring up the settings screen.
class UserSettingsService {
  final _client = DatabaseConnection.client;

  static const _table = 'user_setting';

  // ─────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────

  /// Fetches the settings row for [uid] from `user_setting`.
  ///
  /// Returns [UserSettingsModel.defaults] if no row exists yet (new user).
  /// Throws on any Supabase error so the ViewModel can show an error state.
  Future<UserSettingsModel> getSettings(String uid) async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) {
        // No settings row yet — return safe defaults without touching the DB.
        return UserSettingsModel.defaults(uid);
      }

      return UserSettingsModel.fromSupabase(row);
    } catch (e) {
      throw Exception('UserSettingsService.getSettings failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // WRITE — NOTIFICATIONS
  // ─────────────────────────────────────────────────────────

  /// Upserts the `notification_prefs` jsonb field for [uid].
  ///
  /// [prefs] example: {'likes': true, 'comments': false, 'challenges': true, 'messages': true}
  ///
  /// Uses upsert so it creates the row on first call and updates on subsequent
  /// calls. Requires a UNIQUE constraint on `user_id` — see class-level note.
  Future<void> updateNotificationSettings(
    String uid,
    Map<String, bool> prefs,
  ) async {
    try {
      await _client.from(_table).upsert(
        {
          'user_id': uid,
          'notification_prefs': prefs,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception(
          'UserSettingsService.updateNotificationSettings failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // WRITE — PRIVACY
  // ─────────────────────────────────────────────────────────

  /// Upserts the `privacy_setting` field for [uid].
  ///
  /// [privacy] must be one of: 'public' | 'friends'
  ///
  /// Throws an [ArgumentError] immediately if an invalid value is passed,
  /// before any network call is made.
  Future<void> updatePrivacySettings(String uid, String privacy) async {
    if (privacy != 'public' && privacy != 'friends') {
      throw ArgumentError(
        "Invalid privacy value '$privacy'. Must be 'public' or 'friends'.",
      );
    }

    try {
      await _client.from(_table).upsert(
        {
          'user_id': uid,
          'privacy_setting': privacy,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('UserSettingsService.updatePrivacySettings failed: $e');
    }
  }
}
