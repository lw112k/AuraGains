import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:auragains/features/admin/models/app_user_model.dart';
import 'package:auragains/features/admin/models/report_model.dart';
import 'package:auragains/features/admin/repositories/admin_repository.dart';

/// State provider for the Admin Panel screen.
///
/// Fetches and caches:
///   • [userCount]        — total rows in the `users` table
///   • [reports]          — pending reports (joined with reporter profile)
///   • [currentAdminUser] — the signed-in admin's own `users` row
///
/// A realtime channel on `reports` keeps the queue live; the channel is
/// cancelled when the provider is disposed.
class AdminProvider extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  RealtimeChannel? _channel;

  bool _isLoading = false;
  String? _error;
  int _userCount = 0;
  List<Report> _reports = [];
  AppUser? _currentAdminUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get userCount => _userCount;
  List<Report> get reports => List.unmodifiable(_reports);
  AppUser? get currentAdminUser => _currentAdminUser;

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final results = await Future.wait([
        _repo.fetchUserCount(),
        _repo.fetchPendingReports(),
        if (userId.isNotEmpty) _repo.fetchUserById(userId) else Future.value(null),
      ]);

      _userCount = results[0] as int;
      _reports = (results[1] as List<Map<String, dynamic>>).map(Report.fromSupabase).toList();

      final adminRow = results[2] as Map<String, dynamic>?;
      _currentAdminUser = adminRow != null ? AppUser.fromSupabase(adminRow) : null;

      _subscribeRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> approveReport(String reportId) async {
    await _repo.approveReport(reportId);
    _reports = _reports.where((r) => r.id != reportId).toList();
    notifyListeners();
  }

  Future<void> rejectReport(String reportId) async {
    await _repo.rejectReport(reportId);
    _reports = _reports.where((r) => r.id != reportId).toList();
    notifyListeners();
  }
}
