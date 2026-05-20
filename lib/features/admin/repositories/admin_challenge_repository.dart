import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/database_connection.dart';
import '../models/admin_challenge_model.dart';
import '../models/admin_challenge_submission_model.dart';

// =====================================================================
// ADMIN CHALLENGE REPOSITORY
// Data-access layer for challenges and submissions.
// Uses DatabaseConnection.client only.
// =====================================================================
class AdminChallengeRepository {
  SupabaseClient get _db => DatabaseConnection.client;

  // ─── Challenges ─────────────────────────────────────────────────────

  Future<List<AdminChallengeModel>> fetchChallenges() async {
    final data = await _db
        .from('challenge')
        .select('*')
        .order('is_active', ascending: false)
        .order('create_date', ascending: false);
    return (data as List)
        .map((e) => AdminChallengeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminChallengeModel?> fetchChallenge(int challId) async {
    final data = await _db
        .from('challenge')
        .select('*')
        .eq('chall_id', challId)
        .maybeSingle();
    if (data == null) return null;
    return AdminChallengeModel.fromJson(data);
  }

  /// Direct write to challenge table.
  /// Requires RLS policies allowing admin inserts (see SQL below).
  Future<void> createChallenge(Map<String, dynamic> data) async {
    await _db.from('challenge').insert(data);
  }

  Future<void> updateChallenge(int challId, Map<String, dynamic> data) async {
    await _db.from('challenge').update(data).eq('chall_id', challId);
  }

  Future<void> deleteChallenge(int challId) async {
    await _db.from('challenge').delete().eq('chall_id', challId);
  }

  Future<void> toggleChallengeActive(int challId, bool isActive) async {
    await _db
        .from('challenge')
        .update({'is_active': isActive})
        .eq('chall_id', challId);
  }

  // ─── Submissions ───────────────────────────────────────────────────

  Future<List<AdminChallengeSubmissionModel>> fetchSubmissions({
    String? status,
  }) async {
    // Fetch submissions
    dynamic query = _db
        .from('challenge_submission')
        .select('*')
        .order('submission_date', ascending: false);

    if (status != null && status != 'all') {
      query = query.eq('chall_status', status);
    }

    final submissionsData = await query;
    final submissions = (submissionsData as List).cast<Map<String, dynamic>>();

    if (submissions.isEmpty) return [];

    // Batch fetch challenge names
    final challIds = submissions
        .map((s) => s['chall_id'] as int)
        .toSet()
        .toList();
    final Map<int, String> challengeNames = {};
    if (challIds.isNotEmpty) {
      try {
        final challengesData = await _db
            .from('challenge')
            .select('chall_id, name')
            .inFilter('chall_id', challIds);
        for (final c in challengesData) {
          challengeNames[c['chall_id'] as int] = c['name'] as String;
        }
      } catch (_) {
        // If batch fetch fails, names remain empty
      }
    }

    // Batch fetch usernames
    final userIds = submissions
        .map((s) => s['submitted_by'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
    final Map<String, String> usernames = {};
    if (userIds.isNotEmpty) {
      try {
        final usersData = await _db
            .from('user')
            .select('user_id, username')
            .inFilter('user_id', userIds);
        for (final u in usersData) {
          usernames[u['user_id'] as String] = u['username'] as String;
        }
      } catch (_) {}
    }

    return submissions
        .map(
          (s) => AdminChallengeSubmissionModel.fromJson(
            s,
            challengeName: challengeNames[s['chall_id'] as int] ?? '',
            username: usernames[s['submitted_by'] ?? ''],
          ),
        )
        .toList();
  }

  Future<void> approveSubmission(int challSubmissionId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _db
        .from('challenge_submission')
        .update({
          'chall_status': 'approved',
          'verify_by': userId,
          'verify_date': DateTime.now().toIso8601String(),
        })
        .eq('chall_submission_id', challSubmissionId);
  }

  Future<void> rejectSubmission(int challSubmissionId, String reason) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _db
        .from('challenge_submission')
        .update({
          'chall_status': 'rejected',
          'reject_reason': reason,
          'verify_by': userId,
          'verify_date': DateTime.now().toIso8601String(),
        })
        .eq('chall_submission_id', challSubmissionId);
  }
}
