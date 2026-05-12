import 'package:flutter/material.dart';

import 'package:auragains/features/post_feed/models/post_preview_model.dart';
import 'package:auragains/features/post_feed/repositories/feed_repository.dart';

class FypViewModel extends ChangeNotifier {
  final FeedRepository _repository = FeedRepository();

  final ScrollController scrollController = ScrollController();

  final String currentUserId;

  List<PostPreviewModel> posts = [];

  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;

  FypViewModel(this.currentUserId) {
    scrollController.addListener(_onScroll);
  }

  // when user scroll to the bottom of the feed, load more feed, 200 is the threshold, you can adjust it based on your need, 
  // if you want to load more feed earlier, you can increase the threshold, otherwise decrease it
  void _onScroll() { 
    if ( scrollController.position.pixels > scrollController.position.maxScrollExtent - 200) { 
      loadMore();
    }
  }

  Future<void> loadFeed() async {
    isLoading = true;
    notifyListeners();

    try {
      posts = await _repository.getFypFeed(
        userId: currentUserId,
        offset: 0,
      );
    } catch (e) {
      debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isFetchingMore || !hasMore) return;

    isFetchingMore = true;
    notifyListeners();

    try {
      final newPosts = await _repository.getFypFeed(
        userId: currentUserId,
        offset: posts.length, // offset is the number of posts already loaded, so that we can load the next batch of posts
      );

      if (newPosts.isEmpty) {
        hasMore = false;
      } else {
        posts.addAll(newPosts); // add new posts to the existing posts list, so that we can show the new posts in the feed
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    isFetchingMore = false;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    _repository.refreshSeed();
    hasMore = true;

    if (scrollController.hasClients) {
      await scrollController.animateTo( // auto scroll back to top when refresh feed
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    posts = await _repository.getFypFeed(
      userId: currentUserId,
      offset: 0, 
    );

    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose(); // dispose the scroll controller when the viewmodel is disposed, to prevent memory leak
    super.dispose();
  }
}