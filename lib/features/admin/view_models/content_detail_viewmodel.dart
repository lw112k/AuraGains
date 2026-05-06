import 'package:flutter/foundation.dart';

import '../models/app_user_model.dart';
import '../models/post_model.dart';
import '../models/report_model.dart';
import '../repositories/admin_repository.dart';

/// ViewModel for the admin content-detail (moderation) screen.
///
/// Follows the same [ChangeNotifier] pattern as [AdminViewModel] and
/// [ApplicationsViewModel]:
///   - Exposes [isLoading], [error], and the three loaded entities.
///   - Action-level loading flags for Delete, Approve, and Suspend.
///   - All Supabase I/O is delegated to [AdminRepository].
class ContentDetailViewModel extends ChangeNotifier {
  ContentDetailViewModel({required this.postId}) {
    loadAll();
  }

  final String postId;
  final AdminRepository _repo = AdminRepository();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;

  PostModel? _post;
  Report? _report;
  AppUser? _author;
  AppUser? _reporter;

  // Per-action loading flags so each button gets its own spinner.
  bool _isDeleting = false;
  bool _isApproving = false;
  bool _isSuspending = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;

  PostModel? get post => _post;
  Report? get report => _report;
  AppUser? get author => _author;
  AppUser? get reporter => _reporter;

  bool get isDeleting => _isDeleting;
  bool get isApproving => _isApproving;
  bool get isSuspending => _isSuspending;

  /// True while any action is in flight — disables all action buttons.
  bool get isActionInProgress => _isDeleting || _isApproving || _isSuspending;

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Loads the post, its associated pending report, and both user profiles
  /// (author + reporter) in parallel.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch the post row from `posts`
      final postRow = await _repo.fetchPostById(postId);
      if (postRow == null) {
        _error = 'Post not found.';
        return;
      }
      _post = PostModel.fromSupabase(postRow);

      // 2. Fetch ALL pending reports for this post (take the first one).
      //    The report table is queried with a reporter JOIN so we get the
      //    reporter's username and avatar in a single round-trip.
      final allPending = await _repo.fetchPendingReports();
      final reportRow = allPending
          .where((r) => (r['post_id'] as String?) == postId)
          .firstOrNull;
      _report = reportRow != null ? Report.fromSupabase(reportRow) : null;

      // 3. Fetch both user profiles in parallel.
      final authorId   = _post!.userId;
      final reporterId = _report?.reporterId;

      final futures = await Future.wait([
        _repo.fetchUserById(authorId),
        if (reporterId != null && reporterId.isNotEmpty)
          _repo.fetchUserById(reporterId),
      ]);

      _author = futures[0] != null
          ? AppUser.fromSupabase(futures[0]!)
          : null;
      if (futures.length > 1 && futures[1] != null) {
        _reporter = AppUser.fromSupabase(futures[1]!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Hard-deletes the post and marks its pending report as 'approved'.
  ///
  /// After success, [post] is set to null so the UI can show a "deleted"
  /// state and pop the screen.
  Future<void> deleteContent() async {
    _isDeleting = true;
    notifyListeners();
    try {
      await _repo.deleteContent(postId);
      _post = null;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Dismisses the report (sets report status → 'rejected').
  ///
  /// The post itself is NOT removed — content is considered clean.
  Future<void> approveContent() async {
    _isApproving = true;
    notifyListeners();
    try {
      await _repo.approveContent(postId);
      // Update the local report so the UI reflects the resolved status
      // without a full reload.
      if (_report != null) {
        _report = _report!.copyWith(status: 'rejected');
      }
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  /// Suspends the post author by writing a 'suspended: <reason>' value to
  /// their `users.level` column.
  Future<void> suspendUser(String userId, String reason) async {
    _isSuspending = true;
    notifyListeners();
    try {
      await _repo.suspendUser(userId, reason);
      // Refresh the author so the UI immediately reflects suspended status.
      final updatedRow = await _repo.fetchUserById(userId);
      if (updatedRow != null) {
        _author = AppUser.fromSupabase(updatedRow);
      }
    } finally {
      _isSuspending = false;
      notifyListeners();
    }
  }
}
