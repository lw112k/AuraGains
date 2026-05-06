import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/app_user_model.dart';
import '../models/trainer_application_model.dart';
import '../repositories/admin_repository.dart';

/// ViewModel for the admin verify-trainer detail screen.
///
/// Follows the exact same [ChangeNotifier] pattern as [AdminViewModel],
/// [ApplicationsViewModel], [ContentDetailViewModel], and
/// [UserManagementViewModel]:
///   - Exposes [isLoading], [error], and the loaded entities.
///   - Per-action loading flags ([isApproving], [isRejecting]).
///   - All Supabase I/O is delegated to [AdminRepository].
///
/// The screen receives an [applicationId].  [loadAll] fetches the application
/// row first, then uses [application.userId] to fetch the user profile, post
/// count, and report count in parallel.
class VerifyTrainerViewModel extends ChangeNotifier {
  VerifyTrainerViewModel({required this.applicationId}) {
    loadAll();
  }

  final String applicationId;
  final AdminRepository _repo = AdminRepository();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;

  TrainerApplication? _application;
  AppUser? _user;
  int _postCount = 0;
  int _reportCount = 0;
  /// Formatted "MMM yyyy" string derived from the raw `created_at` column.
  String _memberSince = '';

  bool _isApproving = false;
  bool _isRejecting = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;

  TrainerApplication? get application => _application;
  AppUser? get user => _user;
  int get postCount => _postCount;
  int get reportCount => _reportCount;
  String get memberSince => _memberSince;

  bool get isApproving => _isApproving;
  bool get isRejecting => _isRejecting;
  bool get isActionInProgress => _isApproving || _isRejecting;

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Loads the application, its applicant's profile, post count, and report
  /// count.  The application row is fetched first (sequential) because the
  /// user ID is only available once we have that row.  The remaining three
  /// calls then run in parallel via [Future.wait].
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1 — fetch application row (we need userId before anything else).
      final appRow = await _repo.fetchApplicationById(applicationId);
      if (appRow == null) {
        _error = 'Application not found.';
        return;
      }
      _application = TrainerApplication.fromSupabase(appRow);

      final userId = _application!.userId;

      // Step 2 — fetch user profile, post count, and report count in parallel.
      final results = await Future.wait([
        _repo.fetchUserById(userId),           // index 0 → Map?
        _repo.fetchPostCountByUserId(userId),  // index 1 → int
        _repo.fetchReportCountByUserId(userId), // index 2 → int
      ]);

      final userRow = results[0] as Map<String, dynamic>?;
      if (userRow != null) {
        _user = AppUser.fromSupabase(userRow);
        // Extract created_at for "Member since" display.
        // AppUser model does not expose created_at, so we read it from the
        // raw row directly here.
        final rawDate = userRow['created_at'] as String?;
        if (rawDate != null) {
          final dt = DateTime.tryParse(rawDate);
          if (dt != null) {
            _memberSince = DateFormat('MMM yyyy').format(dt);
          }
        }
      }

      _postCount = results[1] as int;
      _reportCount = results[2] as int;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Approves the application:
  ///   • `trainer_applications.status = 'approved'`
  ///   • `users.role = 'expert'`
  ///
  /// Optimistically updates [application] so the checklist reflects the
  /// change immediately without a full reload.
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> approveApplication() async {
    if (_application == null) return;
    _isApproving = true;
    notifyListeners();

    try {
      await _repo.approveApplication(
          _application!.id, _application!.userId);
      _application = _application!.copyWith(status: 'approved');
      _user = _user?.copyWith(role: 'expert');
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  /// Rejects the application:
  ///   • `trainer_applications.status = 'rejected'`
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> rejectApplication() async {
    if (_application == null) return;
    _isRejecting = true;
    notifyListeners();

    try {
      await _repo.rejectApplication(_application!.id);
      _application = _application!.copyWith(status: 'rejected');
    } finally {
      _isRejecting = false;
      notifyListeners();
    }
  }
}
