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
  });

  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final String level;
  /// One of: 'gym_member', 'expert', 'admin'
  final String role;

  bool get isAdmin => role == 'admin';
  bool get isExpert => role == 'expert';

  /// Builds an AppUser from a Supabase row.
  factory AppUser.fromSupabase(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String? ?? '',
      username: row['username'] as String? ?? '',
      email: row['email'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String? ?? '',
      level: row['level'] as String? ?? '',
      role: row['role'] as String? ?? 'gym_member',
    );
  }

  AppUser copyWith({String? role}) => AppUser(
        id: id,
        username: username,
        email: email,
        avatarUrl: avatarUrl,
        level: level,
        role: role ?? this.role,
      );

  @override
  String toString() => 'AppUser(id: $id, username: $username, role: $role)';
}
