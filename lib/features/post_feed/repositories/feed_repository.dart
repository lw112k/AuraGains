import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/post_feed/models/post_preview_model.dart';

class FeedRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<PostPreviewModel>> getFypFeed({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {

    final response = await supabase.rpc(
      'get_fyp_feed',
      params: {
        'p_user_id': userId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return (response as List<dynamic>)
        .map((json) => PostPreviewModel.fromJson(json))
        .toList();
  }
}