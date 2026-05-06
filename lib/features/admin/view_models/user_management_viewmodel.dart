import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_model.dart';
import '../repositories/admin_repository.dart';

/// ViewModel for the admin user-management screen.
///
/// Follows the exact same [ChangeNotifier] pattern as [AdminViewModel],
/// [ApplicationsViewModel], and [ContentDetailViewModel]:
///   - Exposes [isLoading], [error], and [users].
///   - Realtime subscription on `users` keeps the list live.
///   - Per-user [isProcessing] flag lets individual row actions show spinners.
///   - All Supabase I/O is delegated to [AdminRepository].
class UserManagementViewModel extends ChangeNotifier {
  UserManagementViewModel() {
    loadUsers();
    _subscribeRealtime();
  }

  final AdminRepository _repo = AdminRepository();

  // ── Realtime ───────────────────────────────────────────────────────────────
  RealtimeChannel? _channel;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  List<AppUser> _users = [];

  /// Set of user IDs currently undergoing an action (suspend/ban/grant/revoke).
  final Set<String> _processingIds = {};

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppUser> get users => _users;

  /// Returns true while an action is in progress for [userId].
  bool isProcessing(String userId) => _processingIds.contains(userId);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Fetches all rows from `users`, ordered newest-first.
  ///
  /// Client-side search and status filtering is done in the UI layer.
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Queries the `users` table — all roles, ordered newest-first.
      final rows = await _repo.fetchAllUsers();
      _users = rows.map(AppUser.fromSupabase).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Realtime ───────────────────────────────────────────────────────────────

  void _subscribeRealtime() {
    // Subscribes to INSERT / UPDATE / DELETE on `users`.
    // Any change triggers a full reload to keep the list consistent.
    _channel = _repo.subscribeToUsers(loadUsers);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Suspends [userId] by setting `users.level = 'suspended: <reason>'`.
  ///
  /// Optimistically updates the local list so the UI reflects the change
  /// immediately without waiting for the realtime echo.
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> suspendUser(String userId, String reason) async {
    _processingIds.add(userId);
    notifyListeners();
    try {
      await _repo.suspendUser(userId, reason);
      _users = _users
          .map((u) => u.id == userId
              ? u.copyWith(level: 'suspended: $reason')
              : u)
          .toList();
    } finally {
      _processingIds.remove(userId);
      notifyListeners();
    }
  }

  /// Permanently bans [userId] by setting `users.level = 'banned'`.
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> banUser(String userId) async {
    _processingIds.add(userId);
    notifyListeners();
    try {
      await _repo.banUser(userId);
      _users = _users
          .map((u) => u.id == userId ? u.copyWith(level: 'banned') : u)
          .toList();
    } finally {
      _processingIds.remove(userId);
      notifyListeners();
    }
  }

  /// Sets `users.role = 'expert'` for [userId].
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> grantExpertBadge(String userId) async {
    _processingIds.add(userId);
    notifyListeners();
    try {
      await _repo.grantExpertBadge(userId);
      _users = _users
          .map((u) => u.id == userId ? u.copyWith(role: 'expert') : u)
          .toList();
    } finally {
      _processingIds.remove(userId);
      notifyListeners();
    }
  }

  /// Sets `users.role = 'gym_member'` for [userId] (removes expert status).
  ///
  /// Throws on failure so the caller can surface a SnackBar.
  Future<void> revokeExpertBadge(String userId) async {
    _processingIds.add(userId);
    notifyListeners();
    try {
      await _repo.revokeExpertBadge(userId);
      _users = _users
          .map((u) => u.id == userId ? u.copyWith(role: 'gym_member') : u)
          .toList();
    } finally {
      _processingIds.remove(userId);
      notifyListeners();
    }
  }
}
