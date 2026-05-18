import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/post_feed/models/post_preview_model.dart';

class FeedRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  // seed for exploration feed, can be refreshed to get new feed
  // this is used in fyp feed algorithm to shuffle the feed, so that user can see different posts when they refresh the feed
  // One time will only have one seed, and all the feed will be generated based on this seed, until the seed is refreshed, then new feed will be generated based on the new seed
  int _explorationSeed = DateTime.now().millisecondsSinceEpoch;

  void refreshSeed() {
    _explorationSeed = DateTime.now().millisecondsSinceEpoch;
  }

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
        'p_seed': _explorationSeed,
      },
    );

    return (response as List<dynamic>)
        .map(
          (json) => PostPreviewModel.fromJson(json),
        )
        .toList();
  }
}