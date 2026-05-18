import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/post_feed/models/comment_model.dart';

class CommentRepository {

  final _supabase = Supabase.instance.client;

  // ===================================
  // GET COMMENTS (get all comment for a post without reply comment)
  // ===================================
  Future<List<CommentModel>> getComments({
    required int postId,
    required int offset,
  }) async {

    final result = await _supabase.rpc(
      'get_comments',
      params: {
        'p_post_id': postId,
        'p_offset': offset,
      },
    );

    return (result as List)
      .map((e) => CommentModel.fromJson(e))
      .toList();
  }

  // ===================================
  // GET REPLIES (return a list of replies base on parent id)
  // ===================================
  // Note: User can only reply for the first level comment, but cannot reply someone's reply (second level comment)
  Future<List<CommentModel>> getReplies({
    required int parentId,
  }) async {

    final result = await _supabase.rpc(
      'get_replies',
      params: {
        'p_parent_id': parentId,
      },
    );

    return (result as List)
      .map((e) => CommentModel.fromJson(e))
      .toList();
  }

  // ===================================
  // CREATE COMMENT
  // ===================================
  Future<CommentModel> createComment({
    required int postId,
    required String userId,
    required String text,
    int? parentId,
  }) async {

    final result = await _supabase
        .from('comment')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'text': text,
          'parent_id': parentId,
        })
        .select('''
          *,
          user:user_id (
            username,
            profile_pic_url
          )
        ''')
        .single();
        
    return CommentModel.fromJson({
      ...result,
      'username': result['user']['username'],
      'profile_pic_url': result['user']['profile_pic_url'],
    });
  }
}