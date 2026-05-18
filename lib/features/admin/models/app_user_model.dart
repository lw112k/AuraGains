/// App user model — maps to the `users` table.
///
/// DB schema: id, username, email, avatar_url, level, role, created_at
/// Named AppUser to avoid collision with supabase_flutter's User type.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.level,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final String level;
  /// One of: 'gym_member', 'expert', 'admin'
  final String role;
  /// The user's join date if available from the DB.
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isExpert => role == 'expert';

  /// Builds an AppUser from a Supabase row.
  factory AppUser.fromSupabase(Map<String, dynamic> row) {
    // Parse created_at which may be a String or DateTime depending on client
    DateTime? created;
    final createdRaw = row['created_at'];
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      created = createdRaw;
    } else if (createdRaw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    }

    return AppUser(
      id: (row['id'] ?? row['user_id'] ?? '').toString(),
      username: row['username'] as String? ?? '',
      email: row['email'] as String? ?? '',
      avatarUrl: (row['avatar_url'] ?? row['profile_pic_url']) as String? ?? '',
      level: row['level'] as String? ?? '',
      role: row['role'] as String? ?? row['system_role'] as String? ?? 'gym_member',
      createdAt: created,
    );
  }

  AppUser copyWith({String? role, String? level, DateTime? createdAt}) => AppUser(
        id: id,
        username: username,
        email: email,
        avatarUrl: avatarUrl,
        level: level ?? this.level,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'AppUser(id: $id, username: $username, role: $role)';
}
