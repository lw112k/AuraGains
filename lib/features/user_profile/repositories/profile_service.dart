import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/auth_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Fetch User Profile
  Future<AuthModel> getProfile(String uid) async {
    final response = await _supabase
        .from('user')
        .select()
        .eq('user_id', uid)
        .single();
    
    return AuthModel.fromJson(response);
  }

  // 2. Update Profile (Name, Bio, Avatar URL)
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _supabase
      .from('user')
      .update(data)
      .eq('user_id', uid);
  }

  // 3. Get User Posts
  // Returns a list of maps representing the posts authored by this user
  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    final response = await _supabase
        .from('post')
        .select()
        .eq('post_by', uid)
        .order('create_date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Get Follower Count
  Future<int> getFollowerCount(String uid) async {
    final response = await _supabase
        .from('friends')
        .select('follower')
        .eq('following', uid)
        .count(CountOption.exact);
        
    return response.count ?? 0;
  }

  // 5. Check if current user is following the target user
  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final response = await _supabase
        .from('friends')
        .select()
        .eq('follower', currentUid)
        .eq('following', targetUid)
        .maybeSingle();
        
    return response != null;
  }

  // 6. Follow User
  Future<void> follow(String currentUid, String targetUid) async {
    await _supabase.from('friends').insert({
      'follower': currentUid,
      'following': targetUid,
    });
  }

  // 7. Unfollow User
  Future<void> unfollow(String currentUid, String targetUid) async {
    await _supabase
        .from('friends')
        .delete()
        .eq('follower', currentUid)
        .eq('following', targetUid);
  }
}