import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/search/models/search_tag_model.dart';

class SearchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Fetch Trending Tags ---
  Future<List<SearchTagModel>> getTrendingTags({int limit = 8}) async {
    try {
      final data = await _supabase
          .from('tag')
          .select('*')
          .eq('tag_type', 'system')
          .limit(limit);
      return (data as List)
          .map((e) => SearchTagModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('SearchRepository.getTrendingTags error: $e');
      return [];
    }
  }

  // --- Fetch Mutual Friend IDs ---
  Future<List<String>> getFriendIds(String currentUserId) async {
    try {
      final followingResponse = await _supabase
          .from('friends')
          .select('following')
          .eq('follower', currentUserId);

      final followerResponse = await _supabase
          .from('friends')
          .select('follower')
          .eq('following', currentUserId);

      final Set<String> followingIds = (followingResponse as List)
          .map((e) => e['following'].toString())
          .toSet();

      final Set<String> followerIds = (followerResponse as List)
          .map((e) => e['follower'].toString())
          .toSet();

      final mutualFriends = followingIds.intersection(followerIds);

      return mutualFriends.toList();
    } catch (e) {
      print('SearchRepository.getFriendIds error: $e');
      return [];
    }
  }

  // --- POST SEARCH  ---
  Future<List<Map<String, dynamic>>> searchPosts(
    String query,
    String currentUserId,
    List<String> friendIds, {
    int limit = 20,
  }) async {
    try {
      final List<Map<String, dynamic>> results = [];
      final Set<int> seen = {};

      void mapAndAppend(dynamic row) {
        if (row == null) return;
        final pid = int.tryParse(row['post_id'].toString()) ?? 0;
        if (pid == 0 || seen.contains(pid)) return;
        seen.add(pid);
        results.add(row as Map<String, dynamic>);
      }

      final String selectString =
          'post_id, title, thumbnail_url, post_type, visibility, post_media(media_url, media_type), post_like, create_date, post_by, user:post_by(username, profile_pic_url)';

      // 1. Build the exact visibility logic using the passed-in IDs
      String visibilityFilter =
          'visibility.eq.public,post_by.eq.$currentUserId';
      if (friendIds.isNotEmpty) {
        final safeFriendIds = friendIds.map((id) => '"$id"').join(',');
        visibilityFilter +=
            ',and(visibility.eq.friends,post_by.in.($safeFriendIds))';
      }

      // 2. Search Titles
      final byTitle = await _supabase
          .from('post')
          .select(selectString)
          .ilike(
            'title',
            '%$query%',
          ) 
          .or(visibilityFilter)
          .limit(limit);
      for (final r in (byTitle as List<dynamic>)) mapAndAppend(r);

      // 3. Search Tags
      final tagMatches = await _supabase
          .from('tag')
          .select('tag_id')
          .ilike('name', '%$query%')
          .limit(5);
      final tagIds = (tagMatches as List).map((e) => e['tag_id']).toList();

      if (tagIds.isNotEmpty) {
        final postTags = await _supabase
            .from('post_tag')
            .select('post_id')
            .inFilter('tag_id', tagIds);
        final postIdsFromTags = (postTags as List)
            .map((e) => e['post_id'])
            .toList();

        if (postIdsFromTags.isNotEmpty) {
          final postsByTags = await _supabase
              .from('post')
              .select(selectString)
              .inFilter('post_id', postIdsFromTags)
              .or(visibilityFilter) 
              .limit(limit);
          for (final r in (postsByTags as List<dynamic>)) mapAndAppend(r);
        }
      }

      // 4. Catch Expert Keyword
      final cleanQuery = query.toLowerCase();
      if (cleanQuery.contains('expert') ||
          cleanQuery.contains('ask') ||
          cleanQuery.contains('qna')) {
        final expertPosts = await _supabase
            .from('post')
            .select(selectString)
            .eq('post_type', 'ask_expert')
            .or(visibilityFilter)
            .limit(limit);
        for (final r in (expertPosts as List<dynamic>)) mapAndAppend(r);
      }

      return results;
    } catch (e) {
      print('SearchRepository.searchPosts error: $e');
      return [];
    }
  }
}
