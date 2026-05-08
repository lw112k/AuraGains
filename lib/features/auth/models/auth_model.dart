class AuthModel {
  final String id;
  final String email;
  final String username;
  final String role; // 'admin', 'user', 'gym_member', 'expert'

  AuthModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  // Converts Supabase JSON into this Dart Model
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['system_role'] ?? json['role'] ?? 'user',
    );
  }
}

// Backward-compatibility alias
typedef UserModel = AuthModel;
