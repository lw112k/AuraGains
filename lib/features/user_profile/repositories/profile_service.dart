import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/user_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Fetch User Profile
  Future<UserModel> getProfile(String uid) async {
    final response = await _supabase
        .from('user')
        .select()
        .eq('id', uid)
        .single();
    
    return UserModel.fromJson(response);
  }

  // 2. Update Profile (Name, Bio, Avatar URL)
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _supabase
        .from('user')
        .update(data)
        .eq('id', uid);
  }

  // 3. Get User Posts
  // Returns a list of maps representing the posts authored by this user
  Future<List<Map<String, dynamic>>> getUserPosts(String uid) async {
    final response = await _supabase
        .from('post')
        .select()
        .eq('author_id', uid)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Get Follower Count
  Future<int> getFollowerCount(String uid) async {
    final response = await _supabase
        .from('friends')
        .select('requester_id')
        .eq('receiver_id', uid)
        .eq('status', 'accepted')
        .count(CountOption.exact);
        
    return response.count ?? 0;
  }

  // 5. Check if current user is following the target user
  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final response = await _supabase
        .from('friends')
        .select()
        .eq('requester_id', currentUid)
        .eq('receiver_id', targetUid)
        .maybeSingle();
        
    // If a record exists and status is accepted, they are following
    return response != null && response['status'] == 'accepted';
  }

  // 6. Follow User
  Future<void> follow(String currentUid, String targetUid) async {
    await _supabase.from('friends').insert({
      'requester_id': currentUid,
      'receiver_id': targetUid,
      'status': 'accepted', // or 'pending' depending on your app's friend request logic
    });
  }

  // 7. Unfollow User
  Future<void> unfollow(String currentUid, String targetUid) async {
    await _supabase
        .from('friends')
        .delete()
        .eq('requester_id', currentUid)
        .eq('receiver_id', targetUid);
  }
}