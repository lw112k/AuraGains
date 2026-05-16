import 'package:flutter/material.dart';

import 'package:auragains/features/post_feed/models/post_detail_model.dart';

import 'package:auragains/features/post_feed/repositories/post_detail_repository.dart';
import 'package:auragains/features/post_feed/repositories/like_repository.dart';

class PostDetailViewModel extends ChangeNotifier {

  final PostDetailRepository _postDetailRepo = PostDetailRepository();
  final LikeRepository _likeRepo = LikeRepository();

  final int postId;
  final String currentUserId;

  PostDetailModel? post; // This View Model only holds for one post.

  bool isLoading = false;
  bool isLikeLoading = false;

  PostDetailViewModel({
    required this.postId,
    required this.currentUserId,
  });

  Future<void> loadPost() async {

    isLoading = true;
    notifyListeners();

    try {

      post = await _postDetailRepo.getPostDetail(
        postId: postId,
        currentUserId: currentUserId,
      );

    } catch (e) {

      debugPrint(e.toString());

    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLike() async {
    if (post == null || isLikeLoading) return;

    isLikeLoading = true;

    final currentLiked = post!.isLiked;

    // optimistic update
    post!.isLiked = !currentLiked;

    if (currentLiked) {
      post!.likeCount--;
    } else {
      post!.likeCount++;
    }

    notifyListeners();

    try {

      if (currentLiked) {

        await _likeRepo.unlikePost(
          postId: post!.postId,
          userId: currentUserId,
        );

      } else {

        await _likeRepo.likePost(
          postId: post!.postId,
          userId: currentUserId,
        );
      }

    } catch (e) {

      // rollback
      post!.isLiked = currentLiked;

      if (currentLiked) {
        post!.likeCount++;
      } else {
        post!.likeCount--;
      }

      notifyListeners();

    } finally {

      isLikeLoading = false;
    }
  }

}