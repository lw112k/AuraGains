import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trainer_application_model.dart';
import '../repositories/admin_repository.dart';

/// ViewModel for the admin trainer-applications screen.
///
/// Follows the exact same [ChangeNotifier] pattern as [AdminViewModel] and
/// [AuthViewModel]:
///   - Exposes [isLoading], [error], and [applications].
///   - Calls [loadApplications] on creation and after each mutating action.
///   - Maintains a realtime subscription on `trainer_applications` so the
///     list stays live without manual refresh.
///   - All Supabase I/O is delegated to [AdminRepository].
class ApplicationsViewModel extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── Realtime ───────────────────────────────────────────────────────────────
  RealtimeChannel? _channel;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  List<TrainerApplication> _applications = [];

  // Action-level loading flags so individual card buttons can show spinners
  // without blocking the whole list.
  final Set<String> _processingIds = {};

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<TrainerApplication> get applications => _applications;

  /// Returns true while an approve/reject action is in progress for [id].
  bool isProcessing(String id) => _processingIds.contains(id);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  ApplicationsViewModel() {
    loadApplications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Fetches all rows from `trainer_applications`, newest-first.
  ///
  /// Client-side tab filtering (All / Pending / Approved) is done in the UI
  /// layer to avoid multiple round-trips.
  Future<void> loadApplications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Queries `trainer_applications` — all statuses, ordered newest-first.
      final rows = await _repo.fetchAllApplications();
      _applications =
          rows.map(TrainerApplication.fromSupabase).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Approves [applicationId] and promotes the associated [userId] to 'expert'.
  ///
  /// Updates `trainer_applications.status = 'approved'` AND
  /// `users.role = 'expert'` in a single parallel call via [AdminRepository].
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> approveApplication(
      String applicationId, String userId) async {
    _processingIds.add(applicationId);
    notifyListeners();

    try {
      await _repo.approveApplication(applicationId, userId);
      // Update local list immediately without waiting for realtime echo.
      _applications = _applications
          .map((a) => a.id == applicationId ? a.copyWith(status: 'approved') : a)
          .toList();
    } finally {
      _processingIds.remove(applicationId);
      notifyListeners();
    }
  }

  /// Rejects [applicationId] — sets `trainer_applications.status = 'rejected'`.
  ///
  /// NOTE: The prototype used a 'review' status that does NOT exist in the
  /// DB schema (only pending | approved | rejected are valid).  'rejected' is
  /// the correct mapping until the schema is updated.
  /// See Team Note #2 for details.
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> rejectApplication(String applicationId) async {
    _processingIds.add(applicationId);
    notifyListeners();

    try {
      await _repo.rejectApplication(applicationId);
      _applications = _applications
          .map((a) =>
              a.id == applicationId ? a.copyWith(status: 'rejected') : a)
          .toList();
    } finally {
      _processingIds.remove(applicationId);
      notifyListeners();
    }
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  /// Opens a Postgres-changes channel on `trainer_applications`.
  ///
  /// Any INSERT / UPDATE / DELETE triggers a full re-fetch so the list stays
  /// in sync when another admin acts on a different device.
  void _subscribeRealtime() {
    _channel = _repo.subscribeToApplications(loadApplications);
  }
}
