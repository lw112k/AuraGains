import 'package:supabase_flutter/supabase_flutter.dart';

class LikeRepository {
  final _supabase = Supabase.instance.client;

  // ===================================
  // LIKE POST
  // ===================================
  Future<void> likePost({
    required int postId,
    required String userId,
  }) async {

    await _supabase
        .from('user_event')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'event_type': 'like',
        });

    await _supabase.rpc(
      'increment_post_like',
      params: {
        'p_post_id': postId,
      },
    );
  }

  // ===================================
  // UNLIKE POST
  // ===================================
  Future<void> unlikePost({
    required int postId,
    required String userId,
  }) async {

    // remove like event
    await _supabase
        .from('user_event')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .eq('event_type', 'like');

    // decrement like count
    await _supabase.rpc(
      'decrement_post_like',
      params: {
        'p_post_id': postId,
      },
    );
  }

  // ===================================
  // UPDATE COMMENT LIKE
  // ===================================
  Future<void> updateCommentLike({
    required int commentId,
    required bool isLiked,
    required int currentLikeCount,
  }) async {

    final newLikeCount =
        isLiked
            ? currentLikeCount + 1
            : currentLikeCount - 1;

    await _supabase
        .from('comment')
        .update({
          'comment_like': newLikeCount < 0 ? 0 : newLikeCount,
        })
        .eq('comment_id', commentId);
  }
}