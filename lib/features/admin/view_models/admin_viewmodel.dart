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
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? errorMessage;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;

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

  // Deterministic label→DB-token map; prevents bad inference from _allUsers.
  static const Map<String, String> _roleLabelToDbToken = {
    'user': 'gym_member',
    'expert': 'expert',
    'admin': 'admin',
  };

  String labelForSystemRole(String? sysRole) {
    final r = (sysRole ?? '').toLowerCase();
    if (_userTokens.contains(r)) return 'User';
    if (_expertTokens.contains(r)) return 'Expert';
    if (_adminTokens.contains(r)) return 'Admin';
    if (r.isEmpty) return 'User';
    return r[0].toUpperCase() + r.substring(1);
  }

  String _labelForSystemRole(String? sysRole) => labelForSystemRole(sysRole);

  String _dbTokenForLabel(String label) {
    return _roleLabelToDbToken[label.toLowerCase()] ?? label;
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
      if (detailPost?.postBy != null && detailPost!.postBy!.isNotEmpty) {
        detailPostAuthor = await _repo.fetchUser(detailPost!.postBy!);
      }
      if (reportId != null) {
        final reportMatch =
            _allReports.where((r) => r.reportId == reportId).toList();
        detailReport = reportMatch.isNotEmpty
            ? reportMatch.first
            : await _repo.fetchReportById(reportId);
        if (detailReport?.reportBy != null &&
            detailReport!.reportBy!.isNotEmpty) {
          detailReporter = await _repo.fetchUser(detailReport!.reportBy!);
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

  void selectApplication(AdminApplicationModel app) {
    detailApplication = app;
    notifyListeners();
  }

  // ─── Actions ─────────────────────────────────────────────────────────

  Future<bool> banUser(String userId) async {
    _isActionLoading = true;
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
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unbanUser(String userId) async {
    _isActionLoading = true;
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
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setUserRole(String userId, String role) async {
    _isActionLoading = true;
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
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Approve report → delete the flagged post, keep the report row, stamp [APPROVED].
  Future<bool> approveReport(int reportId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      // Stamp [APPROVED] first, then try to delete the flagged post.
      await _repo.approveReport(reportId);
      final postId = _findPostIdForReport(reportId);
      if (postId != null) {
        await _repo.deletePost(postId);
      }
      // Refresh all report lists so every view sees fresh data.
      await loadReports();
      stats = await _repo.fetchDashboardStats();
      recentReports = await _repo.fetchReports(status: 'pending');
      if (recentReports.length > 5) {
        recentReports = recentReports.sublist(0, 5);
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to approve report: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Dismiss report → keep the post, keep the report row, stamp [DISMISSED].
  Future<bool> dismissReport(int reportId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectReport(reportId);
      await loadReports();
      stats = await _repo.fetchDashboardStats();
      recentReports = await _repo.fetchReports(status: 'pending');
      if (recentReports.length > 5) {
        recentReports = recentReports.sublist(0, 5);
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to dismiss report: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  /// Delete post + all its reports (used by ContentDetailView).
  Future<bool> deletePost(int postId, int reportId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.deletePost(postId);
      await _repo.deleteReportsByPostId(postId);
      _removeReportsByPostId(postId);
      detailPost = null;
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete post: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveApplication(String applicationId, String userId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.approveApplication(applicationId, userId);
      _updateAppStatus(applicationId, 'approved');
      return true;
    } catch (e) {
      errorMessage = 'Failed to approve application: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectApplication(String applicationId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectApplication(applicationId);
      _updateAppStatus(applicationId, 'rejected');
      return true;
    } catch (e) {
      errorMessage = 'Failed to reject application: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  /// Find the postId for a report using local state.
  int? _findPostIdForReport(int reportId) {
    for (final r in _allReports) {
      if (r.reportId == reportId) return r.postId;
    }
    for (final r in recentReports) {
      if (r.reportId == reportId) return r.postId;
    }
    return null;
  }

  /// Remove a single report from both local lists.
  void _removeReportById(int reportId) {
    _allReports = _allReports.where((r) => r.reportId != reportId).toList();
    recentReports = recentReports.where((r) => r.reportId != reportId).toList();
  }

  /// Remove all reports referencing a post from local lists.
  void _removeReportsByPostId(int postId) {
    _allReports = _allReports
        .where((r) => r.postId != postId)
        .toList();
    recentReports = recentReports
        .where((r) => r.postId != postId)
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _updateAppStatus(String appId, String status) {
    _allApplications = _allApplications
        .map((a) => a.applicationId == appId
            ? a.copyWith(applicationStatus: status)
            : a)
        .toList();
    if (detailApplication?.applicationId == appId) {
      detailApplication = detailApplication!.copyWith(applicationStatus: status);
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
