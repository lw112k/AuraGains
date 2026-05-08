import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/admin/models/app_user_model.dart';
import '../features/admin/models/report_model.dart';
import '../features/admin/repositories/admin_repository.dart';

/// State provider for the Admin Panel screen.
///
/// Fetches and caches:
///   • [userCount]        — total rows in the `users` table
///   • [reports]          — pending reports (joined with reporter profile)
///   • [currentAdminUser] — the signed-in admin's own `users` row
///
/// A realtime channel on `reports` keeps the queue live; the channel is
/// cancelled when the provider is disposed.
///
/// Usage — register above [AdminPanelScreen]:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => AdminProvider()..loadData(),
///   child: const AdminPanelScreen(),
/// )
/// ```
class AdminProvider extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── Realtime ───────────────────────────────────────────────────────────────
  RealtimeChannel? _channel;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  int _userCount = 0;
  List<Report> _reports = [];
  AppUser? _currentAdminUser;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get userCount => _userCount;
  List<Report> get reports => List.unmodifiable(_reports);
  AppUser? get currentAdminUser => _currentAdminUser;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Fetches all admin-panel data in parallel and starts the realtime
  /// subscription.  Safe to call from a pull-to-refresh handler.
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? '';

      final results = await Future.wait([
        _repo.fetchUserCount(),          // 0 — total user count
        _repo.fetchPendingReports(),     // 1 — pending report rows
        if (userId.isNotEmpty)
          _repo.fetchUserById(userId)    // 2 — current admin profile
        else
          Future.value(null),
      ]);

      _userCount = results[0] as int;
      _reports = (results[1] as List<Map<String, dynamic>>)
          .map(Report.fromSupabase)
          .toList();

      final adminRow = results[2] as Map<String, dynamic>?;
      _currentAdminUser =
          adminRow != null ? AppUser.fromSupabase(adminRow) : null;

      _subscribeRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('admin-reports-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'report',
          callback: (_) => loadData(),
        )
        .subscribe();
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Sets the report's status to `'approved'` and removes it from the local
  /// queue immediately (optimistic update).
  Future<void> approveReport(String reportId) async {
    await _repo.approveReport(reportId);
    _reports = _reports.where((r) => r.id != reportId).toList();
    notifyListeners();
  }

  /// Sets the report's status to `'rejected'` and removes it from the local
  /// queue immediately (optimistic update).
  Future<void> rejectReport(String reportId) async {
    await _repo.rejectReport(reportId);
    _reports = _reports.where((r) => r.id != reportId).toList();
    notifyListeners();
  }
}
