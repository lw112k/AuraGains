import 'package:supabase_flutter/supabase_flutter.dart';

class SaveRepository {
  final _supabase = Supabase.instance.client;

  // ===================================
  // SAVE POST
  // ===================================
  Future<void> savePost({
    required int postId,
    required String userId,
  }) async {

    await _supabase
        .from('post_save')
        .insert({
          'post_id': postId,
          'user_id': userId,
        });
  }

  // ===================================
  // UNSAVE POST
  // ===================================
  Future<void> unsavePost({
    required int postId,
    required String userId,
  }) async {

    await _supabase
        .from('post_save')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }
}