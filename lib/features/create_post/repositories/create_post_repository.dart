import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/create_post_model.dart';
import 'dart:typed_data';

class CreatePostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // Fetch dynamic system tags
  // ==========================================
  Future<List<SelectedTag>> fetchSystemTags() async {
    try {
      final List<dynamic> response = await _supabase
          .from('tag')
          .select('tag_id, name')
          .eq('tag_type', 'system');

      return response.map((data) {
        return SelectedTag(
          tagId: data['tag_id'] as int,
          name: data['name'] as String,
          type: TagType.system,
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching system tags from database: $e");
      return [];
    }
  }

  // ==========================================
  // PUBLISH POST TRANSACTION
  // ==========================================
  Future<bool> publishPost({
    required String currentUserId,
    required CreatePostModel postModel,
  }) async {
    try {
      // --- STEP 1: UPLOAD MEDIA ---
      List<Map<String, dynamic>> mediaToInsert = [];

      for (int i = 0; i < postModel.mediaList.length; i++) {
        final media = postModel.mediaList[i];

        // 💡 Convert to bytes exactly like your mediaBytes parameter!
        final Uint8List mediaBytes = await media.file.readAsBytes();

        // Use a generic extension or parse it from the original file if needed
        final String fileName =
            '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_file_$i';

        // Upload using uploadBinary just like in submitChallenge
        await _supabase.storage
            .from('posts')
            .uploadBinary(
              fileName,
              mediaBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        // Get the Public URL
        final String mediaUrl = _supabase.storage
            .from('posts')
            .getPublicUrl(fileName);

        mediaToInsert.add({
          'media_url': mediaUrl,
          'media_type': media.type.name,
          'display_order': i,
        });
      }

      // --- STEP 2: REPEAT FOR THUMBNAIL (If exists) ---
      String? thumbnailUrl;
      if (postModel.thumbnailImage != null) {
        final Uint8List thumbBytes = await postModel.thumbnailImage!
            .readAsBytes();
        final String thumbName =
            '$currentUserId/thumb_${DateTime.now().millisecondsSinceEpoch}';

        await _supabase.storage
            .from('posts')
            .uploadBinary(thumbName, thumbBytes);
        thumbnailUrl = _supabase.storage.from('posts').getPublicUrl(thumbName);
      }

      // --- STEP 3: INSERT POST RECORD ---
      final postResponse = await _supabase
          .from('post')
          .insert({
            'post_by': currentUserId,
            'title': postModel.title,
            'description': postModel.description,
            'post_type': postModel.postType == PostType.askExpert
                ? 'ask_expert'
                : 'normal',
            'visibility': postModel.visibility.name,
            'thumbnail_url': thumbnailUrl,
          })
          .select('post_id')
          .single();

      final int newPostId = postResponse['post_id'];

      // --- STEP 4: INSERT POST MEDIA ---
      if (mediaToInsert.isNotEmpty) {
        for (var mediaRow in mediaToInsert) {
          mediaRow['post_id'] = newPostId;
        }
        await _supabase.from('post_media').insert(mediaToInsert);
      }

      // --- STEP 5: HANDLE SYSTEM vs CUSTOM TAGS ---
      List<int> finalTagIds = [];

      for (var tag in postModel.tags) {
        if (tag.tagId != null) {
          // It's an existing system tag
          finalTagIds.add(tag.tagId!);
        } else {
          try {
            final cleanTagName = tag.name.trim().toLowerCase();

            final existingTag = await _supabase
                .from('tag')
                .select('tag_id')
                .ilike('name', cleanTagName)
                .maybeSingle();

            if (existingTag != null) {
              final parsedId = int.parse(existingTag['tag_id'].toString());
              finalTagIds.add(parsedId);
            } else {
              // Brand new tag, insert it
              final newTagResponse = await _supabase
                  .from('tag')
                  .insert({
                    'name': cleanTagName,
                    'create_by': currentUserId,
                    'tag_type': 'user',
                    'create_date': DateTime.now().toUtc().toIso8601String(),
                  })
                  .select('tag_id')
                  .single();

              final parsedNewId = int.parse(
                newTagResponse['tag_id'].toString(),
              );
              finalTagIds.add(parsedNewId);
            }
          } catch (e) {
            debugPrint(
              "🚨 CRITICAL ERROR inserting custom tag '${tag.name}': $e",
            );
            throw Exception("Failed to process tag: ${tag.name}");
          }
        }
      }

      // --- STEP 6: LINK TAGS TO POST ---
      if (finalTagIds.isNotEmpty) {
        List<Map<String, dynamic>> postTagLinks = finalTagIds.map((tagId) {
          return {'post_id': newPostId, 'tag_id': tagId};
        }).toList();
        await _supabase.from('post_tag').insert(postTagLinks);
      }

      return true; // Success!
    } catch (e) {
      debugPrint("Error publishing post: $e");
      return false; // Failed!
    }
  }
}
