import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../repositories/admin_repository.dart';

// =====================================================================
// ADMIN VIEW MODEL
// Single source of state for all admin screens.
// Scoped locally inside AdminView – not registered in main.dart.
// =====================================================================
class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ─── Loading / Error ─────────────────────────────────────────────────
  bool isLoading = false;
  bool isActionLoading = false;
  String? errorMessage;

  // ─── Dashboard ───────────────────────────────────────────────────────
  AdminDashboardStats stats = const AdminDashboardStats.empty();
  List<AdminReportModel> recentReports = [];

  // ─── Users ───────────────────────────────────────────────────────────
  List<AdminUserModel> _allUsers = [];
  String userSearchQuery = '';
  String userRoleFilter = 'All';

  // Role normalization tokens — helps map DB values to UI labels and back.
  static const Set<String> _userTokens = {
    'gym_member',
    'user',
    'member'
  };
  static const Set<String> _expertTokens = {
    'expert',
    'trainer',
    'pro_trainer'
  };
  static const Set<String> _adminTokens = {
    'admin',
    'super_admin',
    'administrator'
  };

  String _labelForSystemRole(String? sysRole) {
    final r = (sysRole ?? '').toLowerCase();
    if (_userTokens.contains(r)) return 'User';
    if (_expertTokens.contains(r)) return 'Expert';
    if (_adminTokens.contains(r)) return 'Admin';
    if (r.isEmpty) return 'User';
    return r[0].toUpperCase() + r.substring(1);
  }

  String _dbTokenForLabel(String label) {
    final l = label.toLowerCase();
    // Prefer an existing DB token seen in _allUsers for this role, otherwise fall back to a sensible default.
    if (l == 'user') {
      final match = _allUsers.firstWhere(
          (u) => _userTokens.contains((u.systemRole ?? '').toLowerCase()),
          orElse: () => AdminUserModel(
                userId: '',
                username: '',
                email: '',
                systemRole: '',
                isBanned: false,
              ));
      return (match.systemRole != null && match.systemRole!.isNotEmpty)
          ? match.systemRole!
          : 'gym_member';
    }
    if (l == 'expert') {
      final match = _allUsers.firstWhere(
          (u) => _expertTokens.contains((u.systemRole ?? '').toLowerCase()),
          orElse: () => AdminUserModel(
                userId: '',
                username: '',
                email: '',
                systemRole: '',
                isBanned: false,
              ));
      return (match.systemRole != null && match.systemRole!.isNotEmpty)
          ? match.systemRole!
          : 'expert';
    }
    if (l == 'admin') {
      final match = _allUsers.firstWhere(
          (u) => _adminTokens.contains((u.systemRole ?? '').toLowerCase()),
          orElse: () => AdminUserModel(
                userId: '',
                username: '',
                email: '',
                systemRole: '',
                isBanned: false,
              ));
      return (match.systemRole != null && match.systemRole!.isNotEmpty)
          ? match.systemRole!
          : 'admin';
    }
    // Unknown labels: pass through
    return label;
  }

  List<AdminUserModel> get filteredUsers {
    return _allUsers.where((u) {
      final q = userSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      final roleLabel = _labelForSystemRole(u.systemRole);
      final matchesRole = userRoleFilter == 'All' ||
          (userRoleFilter == 'Banned' && u.isBanned) ||
          (userRoleFilter == 'Expert' && roleLabel == 'Expert') ||
          (userRoleFilter == 'Admin' && roleLabel == 'Admin') ||
          (userRoleFilter == 'User' && roleLabel == 'User' && !u.isBanned);
      return matchesSearch && matchesRole;
    }).toList();
  }

  // ─── Reports ─────────────────────────────────────────────────────────
  List<AdminReportModel> _allReports = [];
  String? reportStatusFilter;

  List<AdminReportModel> get filteredReports {
    if (reportStatusFilter == null) return _allReports;
    return _allReports
        .where((r) => (r.status ?? 'pending') == reportStatusFilter)
        .toList();
  }

  // ─── Applications ────────────────────────────────────────────────────
  List<AdminApplicationModel> _allApplications = [];
  String? appStatusFilter;

  List<AdminApplicationModel> get filteredApplications {
    if (appStatusFilter == null) return _allApplications;
    return _allApplications
        .where((a) => (a.applicationStatus ?? 'pending') == appStatusFilter)
        .toList();
  }

  // ─── Content detail ──────────────────────────────────────────────────
  AdminPostModel? detailPost;
  AdminUserModel? detailPostAuthor;
  AdminReportModel? detailReport;
  AdminUserModel? detailReporter;
  List<String> detailMediaUrls = [];

  // ─── Application detail ──────────────────────────────────────────────
  AdminApplicationModel? detailApplication;

  // ─── Load methods ────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      stats = await _repo.fetchDashboardStats();
      recentReports = await _repo.fetchReports(status: 'pending');
      if (recentReports.length > 5) {
        recentReports = recentReports.sublist(0, 5);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load dashboard: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      _allUsers = await _repo.fetchUsers();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load users: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReports() async {
    _setLoading(true);
    try {
      _allReports = await _repo.fetchReports();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load reports: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadApplications() async {
    _setLoading(true);
    try {
      _allApplications = await _repo.fetchApplications();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load applications: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadContentDetail(int postId, int? reportId) async {
    _setLoading(true);
    try {
      detailPost = await _repo.fetchPost(postId);
      detailMediaUrls = await _repo.fetchPostMediaUrls(postId);
      if (detailPost?.postBy != null) {
        detailPostAuthor = await _repo.fetchUser(detailPost!.postBy!.toString());
      }
      if (reportId != null) {
        final reportMatch =
            _allReports.where((r) => r.reportId == reportId).toList();
        detailReport = reportMatch.isNotEmpty ? reportMatch.first : null;
        if (detailReport?.reportBy != null) {
          detailReporter = await _repo.fetchUser(detailReport!.reportBy!.toString());
        }
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load content detail: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Filter setters ──────────────────────────────────────────────────

  void setUserSearch(String query) {
    userSearchQuery = query;
    notifyListeners();
  }

  void setUserRoleFilter(String? filter) {
    userRoleFilter = filter ?? 'All';
    notifyListeners();
  }

  void setReportStatusFilter(String? filter) {
    reportStatusFilter = filter;
    notifyListeners();
  }

  void setAppStatusFilter(String? filter) {
    appStatusFilter = filter;
    notifyListeners();
  }

  void selectApplication(int index) {
    if (index >= 0 && index < _allApplications.length) {
      detailApplication = _allApplications[index];
    }
    notifyListeners();
  }

  // ─── Actions ─────────────────────────────────────────────────────────

  Future<bool> banUser(String userId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.banUser(userId);
      _allUsers = _allUsers
          .map((u) =>
              u.userId == userId ? _copyUserWith(u, isBanned: true) : u)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to ban user: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unbanUser(String userId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.unbanUser(userId);
      _allUsers = _allUsers
          .map((u) =>
              u.userId == userId ? _copyUserWith(u, isBanned: false) : u)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to unban user: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setUserRole(String userId, String role) async {
    isActionLoading = true;
    notifyListeners();
    try {
        // Normalize UI label to DB token before persisting.
        final dbToken = _dbTokenForLabel(role);
        await _repo.setSystemRole(userId, dbToken);
        _allUsers = _allUsers
          .map((u) =>
            u.userId == userId ? _copyUserWith(u, systemRole: dbToken) : u)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update role: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveReport(int reportId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.updateReportStatus(reportId, 'approved');
      _updateReportStatus(reportId, 'approved');
      return true;
    } catch (e) {
      errorMessage = 'Failed to approve report: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> dismissReport(int reportId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.updateReportStatus(reportId, 'dismissed');
      _updateReportStatus(reportId, 'dismissed');
      return true;
    } catch (e) {
      errorMessage = 'Failed to dismiss report: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(int postId, int reportId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.deletePost(postId);
      await _repo.updateReportStatus(reportId, 'approved');
      _updateReportStatus(reportId, 'approved');
      detailPost = null;
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete post: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveApplication(String applicationId, String userId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.approveApplication(applicationId, userId);
      _updateAppStatus(applicationId, 'approved');
      return true;
    } catch (e) {
      errorMessage = 'Failed to approve application: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectApplication(String applicationId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectApplication(applicationId);
      _updateAppStatus(applicationId, 'rejected');
      return true;
    } catch (e) {
      errorMessage = 'Failed to reject application: $e';
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _updateReportStatus(int reportId, String status) {
    _allReports = _allReports
        .map((r) => r.reportId == reportId
            ? AdminReportModel(
                reportId: r.reportId,
                reportBy: r.reportBy,
                targetType: r.targetType,
                targetId: r.targetId,
                reason: r.reason,
                createDate: r.createDate,
                status: status,
                postId: r.postId,
              )
            : r)
        .toList();
    recentReports = recentReports
        .map((r) => r.reportId == reportId
            ? AdminReportModel(
                reportId: r.reportId,
                reportBy: r.reportBy,
                targetType: r.targetType,
                targetId: r.targetId,
                reason: r.reason,
                createDate: r.createDate,
                status: status,
                postId: r.postId,
              )
            : r)
        .toList();
  }

  void _updateAppStatus(String appId, String status) {
    _allApplications = _allApplications
        .map((a) => a.applicationId == appId
            ? AdminApplicationModel(
                applicationId: a.applicationId,
                userId: a.userId,
                expertTitle: a.expertTitle,
                experienceYears: a.experienceYears,
                experienceDescription: a.experienceDescription,
                applicationStatus: status,
                createDate: a.createDate,
                username: a.username,
                profilePicUrl: a.profilePicUrl,
                email: a.email,
                imageUrls: a.imageUrls,
              )
            : a)
        .toList();
    if (detailApplication?.applicationId == appId) {
      detailApplication = AdminApplicationModel(
        applicationId: detailApplication!.applicationId,
        userId: detailApplication!.userId,
        expertTitle: detailApplication!.expertTitle,
        experienceYears: detailApplication!.experienceYears,
        experienceDescription: detailApplication!.experienceDescription,
        applicationStatus: status,
        createDate: detailApplication!.createDate,
        username: detailApplication!.username,
        profilePicUrl: detailApplication!.profilePicUrl,
        email: detailApplication!.email,
        imageUrls: detailApplication!.imageUrls,
      );
    }
  }

  AdminUserModel _copyUserWith(
    AdminUserModel u, {
    bool? isBanned,
    String? systemRole,
  }) {
    return AdminUserModel(
      userId: u.userId,
      username: u.username,
      email: u.email,
      profilePicUrl: u.profilePicUrl,
      systemRole: systemRole ?? u.systemRole,
      isBanned: isBanned ?? u.isBanned,
      registerDate: u.registerDate,
      gender: u.gender,
    );
  }
}
