import 'package:flutter/foundation.dart';

import '../repositories/admin_repository.dart';

/// ViewModel for the admin analytics dashboard.
///
/// Follows the same [ChangeNotifier] pattern as [AuthViewModel]:
///   - Exposes an [isLoading] flag and an [error] string.
///   - Calls [loadAnalytics] once on creation and again on pull-to-refresh.
///   - All Supabase I/O is delegated to [AdminRepository].
class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;

  // Metric counters
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalPosts = 0;
  int _completedChallenges = 0;
  int _reportsReceived = 0;
  int _reportsResolved = 0;
  int _moderationActions = 0;

  // Chart data — 7 normalised values each in [0.05, 1.0]
  List<double> _weeklyGrowthPoints = const [
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05
  ];
  List<double> _dailyPostBars = const [
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05
  ];

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUsers => _totalUsers;
  int get activeUsers => _activeUsers;
  int get totalPosts => _totalPosts;
  int get completedChallenges => _completedChallenges;
  int get reportsReceived => _reportsReceived;
  int get reportsResolved => _reportsResolved;
  int get moderationActions => _moderationActions;

  List<double> get weeklyGrowthPoints => _weeklyGrowthPoints;
  List<double> get dailyPostBars => _dailyPostBars;

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Fetches all analytics data from Supabase in parallel.
  ///
  /// Safe to call from [initState] or a pull-to-refresh handler.
  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fire all read-only queries in parallel to minimise total latency.
      final results = await Future.wait([
        _repo.fetchUserCount(),                // 0 — total users
        _repo.fetchActiveUserCount(),           // 1 — non-suspended/banned
        _repo.fetchPostCount(),                 // 2 — posts table count
        _repo.fetchCompletedChallengeCount(),   // 3 — approved challenge subs
        _repo.fetchTotalReportCount(),          // 4 — all reports
        _repo.fetchResolvedReportCount(),       // 5 — non-pending reports
        _repo.fetchModerationActionCount(),     // 6 — suspended + banned users
        _repo.fetchWeeklyUserGrowth(),          // 7 — 7-week growth chart
        _repo.fetchDailyPostCounts(),           // 8 — 7-day post chart
      ]);

      _totalUsers          = results[0] as int;
      _activeUsers         = results[1] as int;
      _totalPosts          = results[2] as int;
      _completedChallenges = results[3] as int;
      _reportsReceived     = results[4] as int;
      _reportsResolved     = results[5] as int;
      _moderationActions   = results[6] as int;
      _weeklyGrowthPoints  = results[7] as List<double>;
      _dailyPostBars       = results[8] as List<double>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
