import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:auragains/core/services/database_connection.dart';

/// Data-access layer for all admin operations.
///
/// All methods use [DatabaseConnection.client] — no Supabase
/// re-initialization happens here.
class AdminRepository {
  final _client = DatabaseConnection.client;

  // ─────────────────────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────────────────────

  /// Returns the total count of rows in the `users` table.
  ///
  /// Selects only the `id` column to minimise payload.
  Future<int> fetchUserCount() async {
    final data = await _client.from('users').select('id');
    return data.length;
  }

  /// Fetches all users ordered newest-first.
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final data = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return data;
  }

  /// Updates a user's role (e.g. promote to 'expert' or demote to 'gym_member').
  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('users').update({'role': role}).eq('id', userId);
  }

  /// Fetches the profile row for a specific user id.
  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    final rows =
        await _client.from('users').select().eq('id', userId).limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  // ─────────────────────────────────────────────────────────
  // REPORTS
  // ─────────────────────────────────────────────────────────

  /// Fetches all pending reports joined with the reporter's user profile.
  ///
  /// The `reporter` key in each row is populated by the foreign-key join
  /// `reporter:reporter_id(id, username, avatar_url)`.
  Future<List<Map<String, dynamic>>> fetchPendingReports() async {
    return await _client
        .from('reports')
        .select('*, reporter:reporter_id(id, username, avatar_url)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  /// Returns the count of reports currently in 'pending' status.
  Future<int> fetchPendingReportCount() async {
    final data = await _client
        .from('reports')
        .select('id')
        .eq('status', 'pending');
    return data.length;
  }

  /// Sets a report's status to 'approved'.
  ///
  /// The post associated with the report is NOT deleted automatically;
  /// call [deletePost] separately if required.
  Future<void> approveReport(String reportId) async {
    await _client
        .from('reports')
        .update({'status': 'approved'})
        .eq('id', reportId);
  }

  /// Sets a report's status to 'rejected' (dismiss without action).
  Future<void> rejectReport(String reportId) async {
    await _client
        .from('reports')
        .update({'status': 'rejected'})
        .eq('id', reportId);
  }

  // ─────────────────────────────────────────────────────────
  // POSTS
  // ─────────────────────────────────────────────────────────

  /// Hard-deletes a post by id (called alongside approveReport when the
  /// admin chooses to remove the flagged content).
  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  // ─────────────────────────────────────────────────────────
  // TRAINER APPLICATIONS
  // ─────────────────────────────────────────────────────────

  /// Fetches all trainer applications with status 'pending'.
  Future<List<Map<String, dynamic>>> fetchPendingApplications() async {
    return await _client
        .from('trainer_applications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  /// Approves a trainer application and promotes the user's role to 'expert'.
  ///
  /// Runs both updates in parallel for efficiency.
  Future<void> approveApplication(
      String applicationId, String userId) async {
    await Future.wait([
      // Mark application approved
      _client
          .from('trainer_applications')
          .update({'status': 'approved'})
          .eq('id', applicationId),
      // Promote user role to expert
      _client.from('users').update({'role': 'expert'}).eq('id', userId),
    ]);
  }

  /// Rejects a trainer application.
  Future<void> rejectApplication(String applicationId) async {
    await _client
        .from('trainer_applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId);
  }

  // ─────────────────────────────────────────────────────────
  // REALTIME
  // ─────────────────────────────────────────────────────────

  /// Returns a [RealtimeChannel] that fires [onChanged] whenever any row
  /// in the `reports` table is inserted, updated, or deleted.
  ///
  /// The caller is responsible for calling `.unsubscribe()` on dispose.
  RealtimeChannel subscribeToReports(void Function() onChanged) {
    return _client
        .channel('admin-reports-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }
}
