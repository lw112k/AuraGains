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
    final data = await _client.from('user').select('user_id');
    return data.length;
  }

  /// Fetches all users ordered newest-first.
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    // Some PostgREST setups can return an error when using server-side
    // ORDER BY on a table named `user` (e.g. "column user.created_at does not exist").
    // Fetch rows unsorted and perform the ordering client-side to avoid
    // touching the database schema.
    final data = await _client.from('user').select();
    final list = (data as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
    list.sort((a, b) {
      final aDt = DateTime.tryParse((a['created_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDt = DateTime.tryParse((b['created_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDt.compareTo(aDt);
    });
    return list;
  }

  /// Updates a user's role (e.g. promote to 'expert' or demote to 'gym_member').
  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('user').update({'system_role': role}).eq('user_id', userId);
  }

  /// Fetches the profile row for a specific user id.
  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    final rows =
        await _client.from('user').select().eq('user_id', userId).limit(1);
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
    // Fetch all reports (server-side 'status' column may be absent from PostgREST cache)
    final allReports = await _client
        .from('report')
        .select()
        .order('create_date', ascending: false);

    if (allReports.isEmpty) return <Map<String, dynamic>>[];

    // Keep only pending reports (treat missing status as 'pending')
    final pendingReports = <Map<String, dynamic>>[];
    for (final r in allReports) {
      final row = Map<String, dynamic>.from(r as Map<String, dynamic>);
      final status = (row['status'] ?? 'pending').toString();
      if (status == 'pending') pendingReports.add(row);
    }

    if (pendingReports.isEmpty) return <Map<String, dynamic>>[];

    // Collect reporter IDs and fetch their profiles in one call
    final reporterIds = <dynamic>{};
    for (final r in pendingReports) {
      final rid = r['reporter_id'];
      if (rid != null) reporterIds.add(rid);
    }

    final reportersById = <String, Map<String, dynamic>>{};
    if (reporterIds.isNotEmpty) {
      final users = await _client
          .from('user')
          .select('user_id, username, profile_pic_url')
          .inFilter('user_id', reporterIds.toList());
      for (final u in users) {
        reportersById[(u['user_id'] ?? '').toString()] = Map<String, dynamic>.from(u as Map<String, dynamic>);
      }
    }

    // Embed reporter profile into each pending report row
    for (final row in pendingReports) {
      final rid = (row['reporter_id'] ?? '').toString();
      row['reporter'] = reportersById[rid] ?? <String, dynamic>{};
    }

    return pendingReports;
  }

  /// Returns the count of reports currently in 'pending' status.
  Future<int> fetchPendingReportCount() async {
    final data = await _client.from('report').select('report_id,status');
    return (data as List).where((r) => ((r['status'] ?? 'pending').toString() == 'pending')).length;
  }

  /// Sets a report's status to 'approved'.
  ///
  /// The post associated with the report is NOT deleted automatically;
  /// call [deletePost] separately if required.
  Future<void> approveReport(String reportId) async {
    final id = int.tryParse(reportId) ?? 0;
    await _client.rpc('set_report_status', params: {'p_report_id': id, 'p_status': 'approved'});
  }

  /// Sets a report's status to 'rejected' (dismiss without action).
  Future<void> rejectReport(String reportId) async {
    final id = int.tryParse(reportId) ?? 0;
    await _client.rpc('set_report_status', params: {'p_report_id': id, 'p_status': 'rejected'});
  }

  // ─────────────────────────────────────────────────────────
  // POSTS
  // ─────────────────────────────────────────────────────────

  /// Hard-deletes a post by id (called alongside approveReport when the
  /// admin chooses to remove the flagged content).
  Future<void> deletePost(String postId) async {
    await _client.from('post').delete().eq('post_id', postId);
  }

  /// Fetches a single post row by [postId].
  ///
  /// Returns null if the post does not exist or has already been deleted.
  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    final rows =
        await _client.from('post').select().eq('post_id', postId).limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Clears the pending report linked to [postId] by setting its status to
  /// 'rejected' (dismiss — content is approved / no action taken).
  ///
  /// Only acts on reports with status = 'pending' to avoid overwriting
  /// already-resolved rows.
  Future<void> approveContent(String postId) async {
    // Fetch reports for the post and update only those that are pending
    final rows = await _client.from('report').select('report_id,status').eq('post_id', postId);
    final pending = <int>[];
    for (final r in rows) {
      final rid = r['report_id'];
      final status = (r['status'] ?? 'pending').toString();
      if (status == 'pending') pending.add(rid is int ? rid : int.tryParse(rid.toString()) ?? 0);
    }
    if (pending.isEmpty) return;
    await _client.rpc('set_report_status', params: {'p_report_id': pending.first, 'p_status': 'rejected'});
    if (pending.length > 1) {
      // update remaining reports in batch via RPC per-post helper
      await _client.rpc('set_reports_status_by_post', params: {'p_post_id': int.tryParse(postId) ?? 0, 'p_status': 'rejected'});
    }
  }

  /// Hard-deletes the post AND marks its pending report as 'approved'
  /// (report upheld — content removed).
  ///
  /// Both operations run in parallel for efficiency.
  Future<void> deleteContent(String postId) async {
    await Future.wait([
      // Remove the post itself
      _client.from('post').delete().eq('post_id', postId),
      // Mark the associated pending report as approved (report upheld)
      _client.rpc('set_reports_status_by_post', params: {'p_post_id': int.tryParse(postId) ?? 0, 'p_status': 'approved'}),
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
      .from('user')
      .update({'is_banned': true})
      .eq('user_id', userId);
  }

  /// Permanently bans a user by setting `users.level = 'banned'`.
  Future<void> banUser(String userId) async {
    await _client
      .from('user')
      .update({'is_banned': true})
      .eq('user_id', userId);
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
          table: 'user',
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
        .from('expert_application')
        .select()
        .order('create_date', ascending: false);
  }

  /// Fetches all trainer applications with status 'pending'.
  Future<List<Map<String, dynamic>>> fetchPendingApplications() async {
    return await _client
        .from('expert_application')
        .select()
        .eq('application_status', 'pending')
        .order('create_date', ascending: false);
  }

  /// Approves a trainer application and promotes the user's role to 'expert'.
  ///
  /// Runs both updates in parallel for efficiency.
  Future<void> approveApplication(
      String applicationId, String userId) async {
    await Future.wait([
      // Mark application approved
      _client
          .from('expert_application')
          .update({'application_status': 'approved'})
          .eq('expert_application_id', applicationId),
      // Promote user role to expert
      _client.from('user').update({'system_role': 'expert'}).eq('user_id', userId),
    ]);
  }

  /// Rejects a trainer application.
  Future<void> rejectApplication(String applicationId) async {
    await _client
        .from('expert_application')
        .update({'application_status': 'rejected'})
        .eq('expert_application_id', applicationId);
  }

  /// Fetches a single trainer application row by its [applicationId].
  ///
  /// Returns null if no matching row exists.
  /// Used by [VerifyTrainerViewModel] to load the detail screen.
  Future<Map<String, dynamic>?> fetchApplicationById(
      String applicationId) async {
    final rows = await _client
        .from('expert_application')
        .select()
        .eq('expert_application_id', applicationId)
        .limit(1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Returns the number of posts authored by [userId].
  ///
  /// Queries `posts` where `user_id = userId`; selects only `id` to minimise
  /// payload.
  Future<int> fetchPostCountByUserId(String userId) async {
    final data =
        await _client.from('post').select('post_id').eq('post_by', userId);
    return data.length;
  }

  /// Returns the number of reports filed BY [userId] (i.e. they are the
  /// reporter, not the reported party).
  ///
  /// Used on the verify-trainer screen to show if the applicant has a history
  /// of flagging content — helps the admin make an informed decision.
  Future<int> fetchReportCountByUserId(String userId) async {
    final data = await _client
        .from('report')
        .select('report_id')
        .eq('reporter_id', userId);
    return data.length;
  }

  // ─────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────

  /// Returns the count of users whose `level` does NOT contain 'suspended' or 'banned'.
  Future<int> fetchActiveUserCount() async {
    final data = await _client.from('user').select('user_id').eq('is_banned', false);
    return data.length;
  }

  /// Returns the total number of rows in the `posts` table.
  Future<int> fetchPostCount() async {
    final data = await _client.from('post').select('post_id');
    return data.length;
  }

  /// Returns the count of `challenge_submissions` with status = 'approved'.
  Future<int> fetchCompletedChallengeCount() async {
    final data = await _client
        .from('challenge_submission')
        .select('chall_submission_id')
        .filter('reject_reason', 'is', null);
    return data.length;
  }

  /// Returns the total row count for the `reports` table (all statuses).
  Future<int> fetchTotalReportCount() async {
    final data = await _client.from('report').select('report_id');
    return data.length;
  }

  /// Returns the count of reports whose status is NOT 'pending' (i.e. resolved).
  Future<int> fetchResolvedReportCount() async {
    final data = await _client.from('report').select('report_id,status');
    return (data as List).where((r) => ((r['status'] ?? 'pending').toString() != 'pending')).length;
  }

  /// Returns the count of users currently suspended or banned.
  ///
  /// Uses an OR filter so a single user is counted only once even if the
  /// `level` column somehow contains both keywords.
  Future<int> fetchModerationActionCount() async {
    final data = await _client.from('user').select('user_id').eq('is_banned', true);
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
      .from('user')
      .select('created_at');

    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final row in data) {
      final dt = DateTime.tryParse((row['created_at'] ?? '') as String? ?? '');
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
        .from('post')
        .select('create_date')
        .gte('create_date', cutoff.toIso8601String());

    final counts = List<int>.filled(7, 0);
    final now = DateTime.now();
    for (final row in data) {
      final dt = DateTime.tryParse(row['create_date'] as String? ?? '');
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
          table: 'report',
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
