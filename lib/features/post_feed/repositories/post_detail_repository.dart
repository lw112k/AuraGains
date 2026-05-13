import 'package:auragains/features/post_feed/models/post_detail_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostDetailRepository {

  final SupabaseClient supabase = Supabase.instance.client;

  Future<PostDetailModel> getPostDetail({
    required int postId,
    required String currentUserId,
  }) async {

    final response = await supabase.rpc(
      'get_post_detail',

      params: {
        'p_post_id': postId,
        'p_user_id': currentUserId,
      },
    );

    final data = (response as List<dynamic>).first;

    return PostDetailModel.fromJson(data);
  }
}