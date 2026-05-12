// =====================================================================
// ADMIN MODELS
// Data shapes for all admin-facing Supabase tables.
// Tables: users, report, post, expert_application, expert_application_image
// =====================================================================

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final i = int.tryParse(v);
    if (i != null) return i;
    final d = double.tryParse(v);
    if (d != null) return d.toInt();
  }
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

String _toStr(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

class AdminUserModel {
  final String userId;
  final String username;
  final String email;
  final String? profilePicUrl;
  final String systemRole; // 'admin', 'user', 'expert'
  final bool isBanned;
  final DateTime? registerDate;
  final String? gender;

  const AdminUserModel({
    required this.userId,
    required this.username,
    required this.email,
    this.profilePicUrl,
    required this.systemRole,
    required this.isBanned,
    this.registerDate,
    this.gender,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      userId: _toStr(json['user_id']),
      username: json['username'] as String? ?? '(no name)',
      email: json['email'] as String? ?? '',
      profilePicUrl: json['profile_pic_url'] as String?,
      systemRole: json['system_role'] as String? ?? 'user',
      isBanned: json['is_banned'] as bool? ?? false,
      registerDate: _toDate(json['register_date']),
      gender: json['gender'] as String?,
    );
  }
}

class AdminReportModel {
  final int reportId;
  final String? reportBy;
  final String? targetType;
  final int? targetId;
  final String? reason;
  final DateTime? createDate;
  final String? status;
  final int? postId;

  const AdminReportModel({
    required this.reportId,
    this.reportBy,
    this.targetType,
    this.targetId,
    this.reason,
    this.createDate,
    this.status,
    this.postId,
  });

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    return AdminReportModel(
      reportId: _toInt(json['report_id']) ?? 0,
      reportBy: _toStr(json['report_by']),
      targetType: json['target_type'] as String?,
      targetId: _toInt(json['target_id']),
      reason: json['reason'] as String?,
      createDate: _toDate(json['create_date']),
      status: json['status'] as String?
          ?? json['report_status'] as String?
          ?? json['state'] as String?
          ?? (json['is_resolved'] != null
              ? ((json['is_resolved'] as bool) ? 'resolved' : 'pending')
              : null),
      postId: json.containsKey('post_id') && json['post_id'] != null
          ? _toInt(json['post_id'])
          : (json['target_type'] == 'post' && json['target_id'] != null)
              ? _toInt(json['target_id'])
              : null,
    );
  }
}

class AdminPostModel {
  final int postId;
  final String? postBy;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? postType;
  final int postLike;
  final DateTime? createDate;

  const AdminPostModel({
    required this.postId,
    this.postBy,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.postType,
    required this.postLike,
    this.createDate,
  });

  factory AdminPostModel.fromJson(Map<String, dynamic> json) {
    return AdminPostModel(
      postId: _toInt(json['post_id']) ?? 0,
      postBy: _toStr(json['post_by']),
      title: json['title'] as String? ?? '(untitled)',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      postType: json['post_type'] as String?,
      postLike: _toInt(json['post_like']) ?? 0,
      createDate: _toDate(json['create_date']),
    );
  }
}

class AdminApplicationModel {
  final String applicationId;
  final String userId;
  final String? expertTitle;
  final int? experienceYears;
  final String? experienceDescription;
  final String? applicationStatus; // 'pending', 'approved', 'rejected'
  final DateTime? createDate;
  final String? username;
  final String? profilePicUrl;
  final String? email;
  final List<String> imageUrls;

  const AdminApplicationModel({
    required this.applicationId,
    required this.userId,
    this.expertTitle,
    this.experienceYears,
    this.experienceDescription,
    this.applicationStatus,
    this.createDate,
    this.username,
    this.profilePicUrl,
    this.email,
    this.imageUrls = const [],
  });

  factory AdminApplicationModel.fromJson(
    Map<String, dynamic> json, {
    List<String> imageUrls = const [],
    Map<String, dynamic>? userJson,
  }) {
    return AdminApplicationModel(
      applicationId: _toStr(json['expert_application_id']),
      userId: _toStr(json['user_id']),
      expertTitle: json['expert_title'] as String?,
      experienceYears: _toInt(json['experience_year']) ?? _toInt(json['experience_years']),
      experienceDescription: json['experience_description'] as String?,
      applicationStatus: json['application_status'] as String?,
      createDate: _toDate(json['create_date']),
      username: userJson?['username'] as String? ?? '(unknown)',
      profilePicUrl: userJson?['profile_pic_url'] as String?,
      email: userJson?['email'] as String?,
      imageUrls: imageUrls,
    );
  }
}

class AdminDashboardStats {
  final int totalUsers;
  final int bannedUsers;
  final int pendingReports;
  final int pendingApplications;
  final int totalPosts;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.bannedUsers,
    required this.pendingReports,
    required this.pendingApplications,
    required this.totalPosts,
  });

  const AdminDashboardStats.empty()
      : totalUsers = 0,
        bannedUsers = 0,
        pendingReports = 0,
        pendingApplications = 0,
        totalPosts = 0;
}
