class UserProfileModel {
  final String userId;
  final String username;
  final String? profilePicUrl;
  final String systemRole; 

  UserProfileModel({
    required this.userId,
    required this.username,
    this.profilePicUrl,
    required this.systemRole,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? 'Unknown Gym Bro',
      profilePicUrl: json['profile_pic_url'],
      systemRole: json['system_role'] ?? 'user',
    );
  }
}
