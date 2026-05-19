import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/body_stats_model.dart';
import '../models/level_model.dart';

class UserProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Post Feeds ---

  // 1. Fetch posts created by the user (With Visibility Logic)
  Future<List<Map<String, dynamic>>> getUserPosts({
    required String targetUserId,
    required bool isMe,
    required bool
    isMutualFriend, 
  }) async {
    try {
      var query = _supabase
          .from('post')
          .select(
            'post_id, title, visibility, thumbnail_url, post_media(media_url, media_type)',
          )
          .eq('post_by', targetUserId);

      // THE STRICT VISIBILITY LOGIC
      if (!isMe) {
        if (isMutualFriend) {
          // They follow each other! Show both public and friends-only posts.
          query = query.or('visibility.eq.public,visibility.eq.friends');
        } else {
          // One-way follow or complete strangers. ONLY show public posts.
          query = query.eq('visibility', 'public');
        }
      }
      // Note: If isMe is true, it skips the filters entirely and loads everything you own!

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Repo Error (User Posts): $e");
      return [];
    }
  }

  // 2. Fetch posts saved by the user
  Future<List<Map<String, dynamic>>> getSavedPosts(String userId) async {
    try {
      final response = await _supabase
          .from('post_save')
          .select(
            'post_id, post!inner(title, visibility, thumbnail_url, post_media(media_url, media_type))',
          )
          .eq('user_id', userId)
          .order('create_date', referencedTable: 'post', ascending: false);

      return (response as List).map((row) {
        final postDetails = row['post'] as Map<String, dynamic>;
        return {
          'post_id': row['post_id'],
          'title': postDetails['title'],
          'visibility': postDetails['visibility'],
          'thumbnail_url': postDetails['thumbnail_url'],
          'post_media': postDetails['post_media'],
        };
      }).toList();
    } catch (e) {
      print("Repo Error (Saved Posts): $e");
      return [];
    }
  }

  // --- Profile Identity ---
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? UserProfileModel.fromJson(response) : null;
    } catch (e) {
      print("Repo Error (Profile): $e");
      return null;
    }
  }

  // --- Expert Status ---
  Future<String?> getExpertApplicationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('expert_application')
          .select('application_status')
          .eq('user_id', userId)
          .order('create_date', ascending: false)
          .limit(1)
          .maybeSingle();
      return response?['application_status'] as String?;
    } catch (e) {
      print("Repo Error (Expert Status): $e");
      return null;
    }
  }

  // --- Body Stats ---
  Future<BodyStatsModel?> getUserBodyStats(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_body_status',
        params: {'p_user_id': userId},
      );
      if (response != null && (response as List).isNotEmpty) {
        return BodyStatsModel.fromJson(response.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Repo Error (Stats): $e");
      return null;
    }
  }

  Future<bool> updateBodyStats({
    required String userId,
    required double heightCm,
    required double weightKg,
    required String unitSystem,
  }) async {
    try {
      await _supabase.from('body_status').upsert({
        'user_id': userId,
        'height': heightCm,
        'weight': weightKg,
        'unit_system': unitSystem,
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      print("Repo Error (Update Stats): $e");
      return false;
    }
  }

  // --- Check if already following ---
  Future<bool> checkIsFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await _supabase
          .from('friends')
          .select()
          .eq('follower', currentUserId)
          .eq('following', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print("Error checking follow status: $e");
      return false;
    }
  }

  // --- Insert or Delete Follow Record ---
  Future<bool> toggleFollow({
    required String currentUserId,
    required String targetUserId,
    required bool isCurrentlyFollowing,
  }) async {
    try {
      if (isCurrentlyFollowing) {
        // ACTION: Unfollow (Delete the row)
        await _supabase
            .from('friends')
            .delete()
            .eq('follower', currentUserId)
            .eq('following', targetUserId);

        return false;
      } else {
        // ACTION: Follow (Insert a new row)
        await _supabase.from('friends').insert({
          'follower': currentUserId,
          'following': targetUserId,
        });

        return true;
      }
    } catch (e) {
      print('Error toggling follow: $e');
      return isCurrentlyFollowing;
    }
  }

  // --- Enhanced Media Actions ---

  // 1. Delete a specific file from storage
  Future<void> _deleteOldImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      // Extract the path from the public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // pathSegments usually looks like: ['storage', 'v1', 'object', 'public', 'profile_pic', 'userId', 'filename']
      final filePath = pathSegments
          .sublist(pathSegments.indexOf('profile_pic') + 1)
          .join('/');

      await _supabase.storage.from('profile_pic').remove([filePath]);
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  // 2. Clear profile pic from DB and Storage
  Future<bool> clearProfilePicture(String userId, String? currentUrl) async {
    try {
      // Remove from storage
      await _deleteOldImage(currentUrl);

      // Reset URL in database
      await _supabase
          .from('user')
          .update({'profile_pic_url': null})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Clear Profile Pic Error: $e');
      return false;
    }
  }

  // 3. Updated Upload (Deletes previous first)
  Future<String?> uploadProfilePicture(
    String userId,
    Uint8List imageBytes,
    String? oldUrl,
  ) async {
    try {
      // 💡 DELETE PREVIOUS PIC FIRST
      await _deleteOldImage(oldUrl);

      final String bucketName = 'profile_pic';
      final path =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from(bucketName).uploadBinary(path, imageBytes);
      final imageUrl = _supabase.storage.from(bucketName).getPublicUrl(path);

      await _supabase
          .from('user')
          .update({'profile_pic_url': imageUrl})
          .eq('user_id', userId);

      return imageUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  // --- Primary Objectives / Levels ---
  Future<List<LevelModel>> getAllLevels() async {
    try {
      final response = await _supabase
          .from('level')
          .select()
          .order('level_id', ascending: true);
      return (response as List)
          .map((json) => LevelModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Fetch Levels Error: $e');
      return [];
    }
  }

  // 1. Fetching the user's current level
  Future<int?> getUserCurrentLevelId(String userId) async {
    try {
      final response = await _supabase
          .from('user') //
          .select('level_id')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['level_id'] as int?;
    } catch (e) {
      print('Fetch User Level ID Error: $e');
      return null;
    }
  }

  // 2. Updating the user's level
  Future<bool> updateUserLevel(String userId, int levelId) async {
    try {
      await _supabase
          .from('user')
          .update({'level_id': levelId})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Update Level Error: $e');
      return false;
    }
  }

  // --- Network Stats (Followers/Following) ---
  Future<Map<String, int>> getNetworkStats(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_network_stats',
        params: {'p_user_id': userId},
      );

      return {
        'followers': response['followers'] as int? ?? 0,
        'following': response['following'] as int? ?? 0,
      };
    } catch (e) {
      print('Network Stats Error: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  Future<Map<String, dynamic>?> getActiveProtocol(String userId) async {
    try {
      // 1. Check for a live session (end_time IS NULL)
      final liveSession = await _supabase
          .from('workout_session')
          .select('train_proto_id')
          .eq('user_id', userId)
          .filter('end_time', 'is', null)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      // 2. Fall back to the most recently completed session
      final lastSession =
          liveSession ??
          await _supabase
              .from('workout_session')
              .select('train_proto_id')
              .eq('user_id', userId)
              .not('end_time', 'is', null)
              .order('start_time', ascending: false)
              .limit(1)
              .maybeSingle();

      if (lastSession == null) return null;

      final int protoId = lastSession['train_proto_id'];

      // 3. Fetch full protocol details — is_public is what the view gate checks
      return await _supabase
          .from('training_protocol')
          .select(
            'train_proto_id, proto_title, goal, is_public, create_by, user:create_by(username)',
          )
          .eq('train_proto_id', protoId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Repo Error (Active Protocol): $e');
      return null;
    }
  }
}
