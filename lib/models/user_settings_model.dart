/// User settings model — maps to the `user_setting` table.
///
/// DB schema: id, user_id, notification_prefs (jsonb), privacy_setting, updated_at
/// privacy_setting values: 'public' | 'friends'
///
/// TEAM NOTE: This model lives in lib/models/ (shared layer) not inside a feature
/// folder because settings will be read from multiple features (profile, notifications,
/// messaging). Import path: package:auragains/models/user_settings_model.dart
class UserSettingsModel {
  const UserSettingsModel({
    required this.id,
    required this.userId,
    required this.notificationPrefs,
    required this.privacySetting,
    required this.updatedAt,
  });

  final String id;
  final String userId;

  /// Maps to `notification_prefs` jsonb column.
  /// Expected keys: 'likes', 'comments', 'challenges', 'messages'
  final Map<String, bool> notificationPrefs;

  /// Maps to `privacy_setting` — one of: 'public', 'friends'
  final String privacySetting;

  final DateTime updatedAt;

  // ── Convenience getters ──────────────────────────────────

  bool get isPublic => privacySetting == 'public';

  bool get notifyLikes => notificationPrefs['likes'] ?? true;
  bool get notifyComments => notificationPrefs['comments'] ?? true;
  bool get notifyChallenges => notificationPrefs['challenges'] ?? true;
  bool get notifyMessages => notificationPrefs['messages'] ?? true;

  // ── Factories ────────────────────────────────────────────

  /// Builds a UserSettingsModel from a Supabase row.
  factory UserSettingsModel.fromSupabase(Map<String, dynamic> row) {
    // notification_prefs arrives as Map<String, dynamic> from JSONB;
    // cast each value explicitly to bool, defaulting to true if missing.
    final rawPrefs = row['notification_prefs'] as Map<String, dynamic>? ?? {};
    final prefs = <String, bool>{
      'likes': rawPrefs['likes'] as bool? ?? true,
      'comments': rawPrefs['comments'] as bool? ?? true,
      'challenges': rawPrefs['challenges'] as bool? ?? true,
      'messages': rawPrefs['messages'] as bool? ?? true,
    };

    return UserSettingsModel(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      notificationPrefs: prefs,
      privacySetting: row['privacy_setting'] as String? ?? 'public',
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Returns sensible defaults for a user who has no row in `user_setting` yet.
  /// All notifications on, profile public.
  factory UserSettingsModel.defaults(String userId) {
    return UserSettingsModel(
      id: '',
      userId: userId,
      notificationPrefs: const {
        'likes': true,
        'comments': true,
        'challenges': true,
        'messages': true,
      },
      privacySetting: 'public',
      updatedAt: DateTime.now(),
    );
  }

  UserSettingsModel copyWith({
    Map<String, bool>? notificationPrefs,
    String? privacySetting,
  }) =>
      UserSettingsModel(
        id: id,
        userId: userId,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
        privacySetting: privacySetting ?? this.privacySetting,
        updatedAt: DateTime.now(),
      );

  @override
  String toString() =>
      'UserSettingsModel(userId: $userId, privacy: $privacySetting, prefs: $notificationPrefs)';
}
