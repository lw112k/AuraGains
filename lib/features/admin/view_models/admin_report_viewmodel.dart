import 'package:flutter/foundation.dart';
import '../models/admin_model.dart';
import '../repositories/admin_report_repository.dart';

// =====================================================================
// ADMIN REPORT VIEW MODEL
// State management for the dedicated admin reports management screen.
// Scoped locally inside AdminReportsView – not registered in main.dart.
// =====================================================================
class AdminReportViewModel extends ChangeNotifier {
  final AdminReportRepository _repo = AdminReportRepository();

  // ─── Loading / Error ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? errorMessage;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;

  // ─── Reports ─────────────────────────────────────────────────────────
  List<AdminReportModel> _allReports = [];
  String? statusFilter; // null = all, 'pending', 'approved', 'rejected'

  List<AdminReportModel> get filteredReports {
    if (statusFilter == null || statusFilter == 'all') return _allReports;
    return _allReports
        .where((r) => (r.status ?? 'pending') == statusFilter)
        .toList();
  }

  // ─── Load ────────────────────────────────────────────────────────────

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

  // ─── Actions ─────────────────────────────────────────────────────────

  /// Approve report → delete the flagged post + all reports for it.
  Future<bool> approveReport(int reportId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final postId = _findPostIdForReport(reportId);
      if (postId != null) {
        await _repo.deletePost(postId);
        await _repo.deleteReportsByPostId(postId);
        _removeReportsByPostId(postId);
      } else {
        await _repo.deleteReportById(reportId);
        _removeReportById(reportId);
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

  /// Reject/dismiss report → delete just that one report.
  Future<bool> rejectReport(int reportId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.deleteReportById(reportId);
      _removeReportById(reportId);
      return true;
    } catch (e) {
      errorMessage = 'Failed to reject report: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ─── Post management ─────────────────────────────────────────────────
  AdminPostModel? detailPost;
  List<String> detailMediaUrls = [];

  Future<void> loadPostDetail(int postId) async {
    try {
      detailPost = await _repo.fetchPost(postId);
      detailMediaUrls = await _repo.fetchPostMediaUrls(postId);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load post detail: $e';
    }
  }

  /// Delete post + all its reports.
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

  // ─── Helpers ─────────────────────────────────────────────────────────

  int? _findPostIdForReport(int reportId) {
    for (final r in _allReports) {
      if (r.reportId == reportId) return r.postId;
    }
    return null;
  }

  void _removeReportById(int reportId) {
    _allReports = _allReports.where((r) => r.reportId != reportId).toList();
  }

  void _removeReportsByPostId(int postId) {
    _allReports = _allReports
        .where((r) => r.postId != postId)
        .toList();
  }

  // ─── Filters ─────────────────────────────────────────────────────────

  void setStatusFilter(String? filter) {
    statusFilter = filter;
    notifyListeners();
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
