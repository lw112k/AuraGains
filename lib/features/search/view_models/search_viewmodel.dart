import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auragains/features/search/repositories/search_repository.dart';
import 'package:auragains/features/search/models/search_tag_model.dart';

class SearchViewModel extends ChangeNotifier {
  final SearchRepository _repo = SearchRepository();
  Timer? _debounce;

  bool isLoading = false;
  bool isSearching = false;
  bool isInitializing = true;

  List<String> currentFriendIds = [];

  List<Map<String, dynamic>> postResults = [];

  List<String> recentSearches = [];
  List<SearchTagModel> trendingSearches = [];

  SearchViewModel() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList('recent_searches') ?? [];
    trendingSearches = await _repo.getTrendingTags();

    isInitializing = false;
    notifyListeners();
  }

  void onSearchTextChanged(String query, String currentUserId) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      executeSearch(query, currentUserId);
    });
  }

  Future<void> executeSearch(String query, String currentUserId) async {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) {
      clearSearch();
      return;
    }

    isSearching = true;
    isLoading = true;
    notifyListeners();

    currentFriendIds = await _repo.getFriendIds(currentUserId);

    postResults = await _repo.searchPosts(q, currentUserId, currentFriendIds);

    isLoading = false;
    notifyListeners();
  }

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    if (recentSearches.length > 10) recentSearches.removeLast();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    recentSearches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    notifyListeners();
  }

  void clearSearch() {
    isSearching = false;
    postResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
