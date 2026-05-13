import 'package:flutter/material.dart';

import 'package:auragains/features/post_feed/models/post_detail_model.dart';
import 'package:auragains/features/post_feed/repositories/post_detail_repository.dart';

class PostDetailViewModel extends ChangeNotifier {

  final PostDetailRepository _repository = PostDetailRepository();

  final int postId;
  final String currentUserId;

  PostDetailModel? post; // This View Model only holds for one post.

  bool isLoading = false;

  PostDetailViewModel({
    required this.postId,
    required this.currentUserId,
  });

  Future<void> loadPost() async {

    isLoading = true;
    notifyListeners();

    try {

      post = await _repository.getPostDetail(
        postId: postId,
        currentUserId: currentUserId,
      );

    } catch (e) {

      debugPrint(e.toString());

    }

    isLoading = false;
    notifyListeners();
  }
}