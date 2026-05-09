import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';

/// =====================================================================
/// [ChallengeRepository]
/// PURPOSE: The only layer that interacts with the Supabase database.
/// =====================================================================
class ChallengeRepository {
  final _supabase = Supabase.instance.client;

  /// Fetches a list of active challenges and checks if the user completed them today.
  Future<List<ChallengeModel>> fetchChallenges(
    String currentUserId,
    bool isDaily,
  ) async {
    try {
      // Calls our custom Postgres API Endpoint!
      final response = await _supabase.rpc(
        'get_challenges_with_status',
        params: {'p_user_id': currentUserId, 'p_is_daily': isDaily},
      );

      // Convert the raw JSON list into a neat list of ChallengeModels
      return (response as List<dynamic>)
          .map((json) => ChallengeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Repository Error fetching challenges: $e");
      throw Exception(
        'Failed to load challenges',
      ); // Passes error up to ViewModel
    }
  }

  /// Fetches the calculated points and rankings from our SQL View
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final response = await _supabase
          .from('user_leaderboard') 
          .select('*')
          .order('total_points', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Repository Error fetching leaderboard: $e");
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String userId) async {
    final response = await _supabase
        .from('user_history')
        .select('*')
        .eq('user_id', userId)
        .order('submission_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> submitChallenge({
    required String userId,
    required int challengeId,
    required Uint8List mediaBytes, 
    required String fileExtension, 
  }) async {
    // 1. Generate a unique filename using the actual file extension
    final String fileName =
        '$userId/${challengeId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

    // 2. Upload to the "challenge-videos" bucket using uploadBinary
    await _supabase.storage
        .from('challenge-videos')
        .uploadBinary(
          fileName,
          mediaBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 3. Get the Public URL of the uploaded media
    final String mediaUrl = _supabase.storage
        .from('challenge-videos')
        .getPublicUrl(fileName);

    // 4. Save the record to the challenge_submission table
    await _supabase.from('challenge_submission').insert({
      'chall_id': challengeId,
      'submitted_by': userId,
      'vid_evidence_url': mediaUrl, 
      'chall_status': 'pending',
    });
  }
}
