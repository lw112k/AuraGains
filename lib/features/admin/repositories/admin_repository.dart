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

  /// Fetches a single post row by [postId].
  ///
  /// Returns null if the post does not exist or has already been deleted.
  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    final rows =
        await _client.from('posts').select().eq('id', postId).limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Clears the pending report linked to [postId] by setting its status to
  /// 'rejected' (dismiss — content is approved / no action taken).
  ///
  /// Only acts on reports with status = 'pending' to avoid overwriting
  /// already-resolved rows.
  Future<void> approveContent(String postId) async {
    await _client
        .from('reports')
        .update({'status': 'rejected'})
        .eq('post_id', postId)
        .eq('status', 'pending');
  }

  /// Hard-deletes the post AND marks its pending report as 'approved'
  /// (report upheld — content removed).
  ///
  /// Both operations run in parallel for efficiency.
  Future<void> deleteContent(String postId) async {
    await Future.wait([
      // Remove the post itself
      _client.from('posts').delete().eq('id', postId),
      // Mark the associated pending report as approved (report upheld)
      _client
          .from('reports')
          .update({'status': 'approved'})
          .eq('post_id', postId)
          .eq('status', 'pending'),
    ]);
  }

  /// Suspends a user by appending a 'suspended' marker to their `level` field.
  ///
  /// The `level` column is repurposed for suspension tracking by the team's
  /// existing convention (see [AppUser.isAdmin] — level contains 'suspended'
  /// or 'banned' substrings).
  ///
  /// [reason] is stored alongside in `level` so the reason is auditable.
  /// Format: "suspended: <reason>"
  Future<void> suspendUser(String userId, String reason) async {
    await _client
        .from('users')
        .update({'level': 'suspended: $reason'})
        .eq('id', userId);
  }

  /// Permanently bans a user by setting `users.level = 'banned'`.
  Future<void> banUser(String userId) async {
    await _client
        .from('users')
        .update({'level': 'banned'})
        .eq('id', userId);
  }

  /// Promotes a user to expert by setting `users.role = 'expert'`.
  ///
  /// Named wrapper around [updateUserRole] for clarity at call sites.
  Future<void> grantExpertBadge(String userId) async {
    await updateUserRole(userId, 'expert');
  }

  /// Demotes a user from expert back to standard member.
  ///
  /// Named wrapper around [updateUserRole] for clarity at call sites.
  Future<void> revokeExpertBadge(String userId) async {
    await updateUserRole(userId, 'gym_member');
  }

  /// Returns a [RealtimeChannel] that fires [onChanged] whenever any row
  /// in the `users` table is inserted, updated, or deleted.
  ///
  /// Used by [UserManagementViewModel] to keep the list live.
  /// The caller is responsible for calling `.unsubscribe()` on dispose.
  RealtimeChannel subscribeToUsers(void Function() onChanged) {
    return _client
        .channel('admin-users-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  // ─────────────────────────────────────────────────────────
  // TRAINER APPLICATIONS
  // ─────────────────────────────────────────────────────────

  /// Fetches ALL trainer applications across all statuses, newest-first.
  ///
  /// Used by [ApplicationsViewModel] to populate All / Pending / Approved tabs
  /// with client-side filtering.
  Future<List<Map<String, dynamic>>> fetchAllApplications() async {
    return await _client
        .from('trainer_applications')
        .select()
        .order('created_at', ascending: false);
  }

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

  /// Fetches a single trainer application row by its [applicationId].
  ///
  /// Returns null if no matching row exists.
  /// Used by [VerifyTrainerViewModel] to load the detail screen.
  Future<Map<String, dynamic>?> fetchApplicationById(
      String applicationId) async {
    final rows = await _client
        .from('trainer_applications')
        .select()
        .eq('id', applicationId)
        .limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Returns the number of posts authored by [userId].
  ///
  /// Queries `posts` where `user_id = userId`; selects only `id` to minimise
  /// payload.
  Future<int> fetchPostCountByUserId(String userId) async {
    final data =
        await _client.from('posts').select('id').eq('user_id', userId);
    return data.length;
  }

  /// Returns the number of reports filed BY [userId] (i.e. they are the
  /// reporter, not the reported party).
  ///
  /// Used on the verify-trainer screen to show if the applicant has a history
  /// of flagging content — helps the admin make an informed decision.
  Future<int> fetchReportCountByUserId(String userId) async {
    final data = await _client
        .from('reports')
        .select('id')
        .eq('reporter_id', userId);
    return data.length;
  }

  // ─────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────

  /// Returns the count of users whose `level` does NOT contain 'suspended' or 'banned'.
  Future<int> fetchActiveUserCount() async {
    final data = await _client
        .from('users')
        .select('id')
        .not('level', 'ilike', '%suspended%')
        .not('level', 'ilike', '%banned%');
    return data.length;
  }

  /// Returns the total number of rows in the `posts` table.
  Future<int> fetchPostCount() async {
    final data = await _client.from('posts').select('id');
    return data.length;
  }

  /// Returns the count of `challenge_submissions` with status = 'approved'.
  Future<int> fetchCompletedChallengeCount() async {
    final data = await _client
        .from('challenge_submissions')
        .select('id')
        .eq('status', 'approved');
    return data.length;
  }

  /// Returns the total row count for the `reports` table (all statuses).
  Future<int> fetchTotalReportCount() async {
    final data = await _client.from('reports').select('id');
    return data.length;
  }

  /// Returns the count of reports whose status is NOT 'pending' (i.e. resolved).
  Future<int> fetchResolvedReportCount() async {
    final data = await _client
        .from('reports')
        .select('id')
        .neq('status', 'pending');
    return data.length;
  }

  /// Returns the count of users currently suspended or banned.
  ///
  /// Uses an OR filter so a single user is counted only once even if the
  /// `level` column somehow contains both keywords.
  Future<int> fetchModerationActionCount() async {
    final data = await _client
        .from('users')
        .select('id')
        .or('level.ilike.%suspended%,level.ilike.%banned%');
    return data.length;
  }

  /// Fetches `created_at` timestamps for every user created in the last 7 weeks
  /// and returns a 7-element list of values normalised to [0.0, 1.0].
  ///
  /// Index 0 = oldest week, index 6 = current (most recent) week.
  /// Returns all-zeros if no users exist in the window.
  Future<List<double>> fetchWeeklyUserGrowth() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 49));
    final data = await _client
        .from('users')
        .select('created_at')
        .gte('created_at', cutoff.toIso8601String());

    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final row in data) {
      final dt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (dt == null) continue;
      final daysAgo = now.difference(dt).inDays;
      final weekIndex = (6 - (daysAgo ~/ 7)).clamp(0, 6);
      counts[weekIndex]++;
    }

    final maxVal = counts.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(7, 0.05); // flat baseline for empty data
    return counts.map((c) => (c / maxVal).clamp(0.05, 1.0)).toList();
  }

  /// Fetches `created_at` timestamps for every post created in the last 7 days
  /// and returns a 7-element list of values normalised to [0.0, 1.0].
  ///
  /// Index 0 = 6 days ago, index 6 = today.
  Future<List<double>> fetchDailyPostCounts() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final data = await _client
        .from('posts')
        .select('created_at')
        .gte('created_at', cutoff.toIso8601String());

    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final row in data) {
      final dt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (dt == null) continue;
      final daysAgo = now.difference(dt).inDays;
      final dayIndex = (6 - daysAgo).clamp(0, 6);
      counts[dayIndex]++;
    }

    final maxVal = counts.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(7, 0.05);
    return counts.map((c) => (c / maxVal).clamp(0.05, 1.0)).toList();
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

  /// Returns a [RealtimeChannel] that fires [onChanged] whenever any row
  /// in the `trainer_applications` table is inserted, updated, or deleted.
  ///
  /// The caller is responsible for calling `.unsubscribe()` on dispose.
  RealtimeChannel subscribeToApplications(void Function() onChanged) {
    return _client
        .channel('admin-applications-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trainer_applications',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }
}
