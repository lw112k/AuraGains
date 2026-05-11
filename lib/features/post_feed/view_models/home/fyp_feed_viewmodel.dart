import 'package:flutter/material.dart';
import 'package:auragains/features/post_feed/models/post_preview_model.dart';
import 'package:auragains/features/post_feed/repositories/feed_repository.dart';

class FypFeedViewModel extends ChangeNotifier {
  final FeedRepository _repository = FeedRepository();

  final ScrollController scrollController = ScrollController();

  String? currentUserId;

  List<PostPreviewModel> posts = [];

  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;

  int selectedTab = 0;

  FypFeedViewModel() {
    scrollController.addListener(_onScroll);
  }

  void changeTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void _onScroll() {
    if (
      scrollController.position.pixels >
      scrollController.position.maxScrollExtent - 300
    ) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    if (isFetchingMore || !hasMore) return;

    isFetchingMore = true;
    notifyListeners();

    try {
      final newPosts = await _repository.getFypFeed(
        userId: currentUserId!,
        offset: posts.length,
      );

      if (newPosts.isEmpty) {
        hasMore = false;
      } else {
        posts.addAll(newPosts);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    isFetchingMore = false;
    notifyListeners();
  }

  Future<void> loadFeed({
    required String userId,
  }) async {

    currentUserId = userId;

    isLoading = true;
    notifyListeners();

    try {
      posts = await _repository.getFypFeed(
        userId: userId,
        offset: 0,
      );
    } catch (e) {
      debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFeed({
    required String userId,
  }) async {

    _repository.refreshSeed();

    hasMore = true;

    if (scrollController.hasClients) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    posts = await _repository.getFypFeed(
      userId: userId,
      offset: 0,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}