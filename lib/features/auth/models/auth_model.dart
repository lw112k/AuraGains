class AuthModel {
  final String id;
  final String email;
  final String username;
  final String role; // 'admin', 'user'
  final String? profilePicUrl;

  AuthModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.profilePicUrl,
  });

  // Converts Supabase JSON into this Dart Model
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: json['id'] ?? json['user_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['system_role'] ?? 'user',
      profilePicUrl: json['profile_pic_url'],
    );
  }
}
