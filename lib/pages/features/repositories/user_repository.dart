//User, User_setting, body_status, level, friends, preferences_tag_score tables
import 'package:supabase_flutter/supabase_flutter.dart'; 

class UserRepository {
  // Access the global Supabase client
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. USER PROFILE METHODS
  // ==========================================

  /// Inserts a new user profile using a raw Map
  Future<void> insertUserProfile(Map<String, dynamic> userData) async {
    try {
      await _supabase.from('user').insert(userData);
    } catch (e) {
      print('Error inserting user profile: $e');
      rethrow;
    }
  }

  /// Fetches the user profile and returns raw JSON
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('user')
          .select()
          .eq('user_id', userId)
          .single();
          
      return data;
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Updates the user's profile using a raw Map
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('user')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // ==========================================
  // 2. USER SETTINGS METHODS
  // ==========================================

  /// Inserts default user settings using a raw Map
  Future<void> insertUserSettings(Map<String, dynamic> settingsData) async {
    try {
      await _supabase.from('user_setting').insert(settingsData);
    } catch (e) {
      print('Error inserting user settings: $e');
      rethrow;
    }
  }

  /// Fetches the user's settings and returns raw JSON
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final data = await _supabase
          .from('user_setting')
          .select()
          .eq('user_id', userId)
          .single();
          
      return data;
    } catch (e) {
      print('Error fetching user settings: $e');
      rethrow;
    }
  }

  /// Updates user settings using a raw Map
  Future<void> updateUserSettings(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('user_setting')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  // ==========================================
  // 3. BODY STATUS METHODS
  // ==========================================

  /// Logs a new weight/height entry using a raw Map
  Future<void> addBodyStatus(Map<String, dynamic> bodyStatusData) async {
    try {
      await _supabase.from('body_status').insert(bodyStatusData);
    } catch (e) {
      print('Error adding body status: $e');
      rethrow;
    }
  }

  /// Fetches the user's most recent body status as raw JSON
  Future<Map<String, dynamic>?> getLatestBodyStatus(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('body_status')
          .select()
          .eq('user_id', userId)
          .order('create_date', ascending: false)
          .limit(1);
          
      if (data.isEmpty) return null;
      return data.first as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching latest body status: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. FRIENDS (FOLLOWERS/FOLLOWING) METHODS
  // ==========================================

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _supabase.from('friends').insert({
        'follower': followerId,
        'following': followingId,
      });
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabase
          .from('friends')
          .delete()
          .match({
            'follower': followerId, 
            'following': followingId
          });
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if current user is following a specific profile
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final data = await _supabase
          .from('friends')
          .select()
          .match({
            'follower': followerId, 
            'following': followingId
          });
      return data.isNotEmpty;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // ==========================================
  // 5. PREFERENCE TAG SCORE METHODS
  // ==========================================

  /// Updates or inserts a tag score using a raw Map
  Future<void> upsertTagScore(Map<String, dynamic> tagScoreData) async {
    try {
      await _supabase.from('preference_tag_score').upsert(
        tagScoreData,
        onConflict: 'user_id, tag_id', 
      );
    } catch (e) {
      print('Error updating tag score: $e');
      rethrow;
    }
  }
}