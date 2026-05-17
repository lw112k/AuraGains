import 'package:flutter/material.dart';

import 'package:auragains/features/post_feed/models/comment_model.dart';

import 'package:auragains/features/post_feed/repositories/comment_repository.dart';
import 'package:auragains/features/post_feed/repositories/like_repository.dart';


class CommentViewModel extends ChangeNotifier {

  final CommentRepository _repo = CommentRepository();
  final LikeRepository _likeRepo = LikeRepository();

  final int postId;
  final String currentUserId;

  List<CommentModel> commentList = [];

  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;

  bool isLoadingReplies = false;

  CommentViewModel({
    required this.postId,
    required this.currentUserId,
  });

  Future<void> loadComments() async {
    isLoading = true;

    notifyListeners();

    try {
      commentList = await _repo.getComments(
        postId: postId,
        offset: 0,
      );

    } finally {

      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {

    if (isFetchingMore || !hasMore) return;

    isFetchingMore = true;
    notifyListeners();

    try {

      final newCommentList = await _repo.getComments(
        postId: postId,
        offset: commentList.length,
      );

      if (newCommentList.isEmpty) {
        hasMore = false;

      } else {
        commentList.addAll(newCommentList);
      }

    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadReplies(CommentModel comment) async {
    comment.replies.clear();

    if (comment.repliesLoaded) { 
      comment.showReplies = false;
      comment.repliesLoaded = false;
      
      notifyListeners();
      return;
    }

    isLoadingReplies = true;
    notifyListeners();

    try {

      final replies = await _repo.getReplies(
        parentId: comment.commentId,
      );

      comment.replies.addAll(replies);

      comment.repliesLoaded = true;
      comment.showReplies = true;
    } finally {

      isLoadingReplies = false;
      notifyListeners();
    }
  }

  Future<void> submitComment({
    required String text,
    int? parentId, //optional
  }) async {
    final newComment = await _repo.createComment(
      postId: postId,
      userId: currentUserId,
      text: text,
      parentId: parentId,
    );

    if (parentId == null) {
      // This is a new comment, add it to the top of the list
      commentList.insert(0, newComment);
    } else {
      // This is a reply, find the parent comment and add it to its replies
      final parentComment = commentList.firstWhere((c) => c.commentId == parentId);
      parentComment.replies.add(newComment);
      parentComment.replyCount += 1; // Increment the reply count for the parent comment
    }

    notifyListeners();
  }

  Future<void> toggleCommentLike(CommentModel comment) async {
    final oldLiked = comment.isLiked;
    final oldCount = comment.likeCount;

    // optimistic update
    comment.isLiked = !comment.isLiked;

    if (comment.isLiked) {
      comment.likeCount++;
    } else {
      comment.likeCount--;
    }

    notifyListeners();

    try {

      await _likeRepo.updateCommentLike(
        commentId: comment.commentId,
        isLiked: comment.isLiked,
        currentLikeCount: oldCount,
      );

    } catch (e) {

      // rollback
      comment.isLiked = oldLiked;
      comment.likeCount = oldCount;

      notifyListeners();
    }
  }

}