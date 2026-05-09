import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import '../repositories/challenge_repository.dart';

/// =====================================================================
/// [ChallengeViewModel]
/// PURPOSE: The "Brain" that connects the UI to the Repository.
/// =====================================================================
class ChallengeViewModel extends ChangeNotifier {
  // 1. Connect to the Repository
  final ChallengeRepository _repository = ChallengeRepository();

  // 2. State Variables
  List<ChallengeModel> _browseChallenges = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _lastErrorMessage; // Error for the UI
  String _currentFilter = 'Daily';
  List<Map<String, dynamic>> _leaderboard = [];
  int _totalPoints = 0;
  List<Map<String, dynamic>> _history = [];

  // 3. The Time Sync Offset
  Duration _timeOffset = Duration.zero;

  // 4. Getters for the UI to read
  List<ChallengeModel> get browseChallenges => _browseChallenges;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get lastErrorMessage => _lastErrorMessage;
  String get currentFilter => _currentFilter;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  int get totalPoints => _totalPoints;
  List<Map<String, dynamic>> get history => _history;

  // 5. Getter for the TRUE Server Time
  DateTime get trueNow => DateTime.now().add(_timeOffset);

  // Logic Methods
  // Function to sync time when the app starts
  Future<void> syncServerTime() async {
    try {
      final response = await Supabase.instance.client.rpc('get_server_time');
      final DateTime serverTime = DateTime.parse(response as String);
      final DateTime phoneTime = DateTime.now();

      _timeOffset = serverTime.difference(phoneTime);
      print("Time synchronized. Offset is: $_timeOffset");
    } catch (e) {
      print("Failed to sync time, falling back to local time. $e");
    }
  }

  Future<void> loadLeaderboardData(String currentUserId) async {
    try {
      // 1. Fetch the data from the repository (using the SQL View we made)
      final data = await _repository.fetchLeaderboard();
      _leaderboard = data;

      // 2. Find the current user in the list to update the 'totalPoints'
      // This ensures the points in the header match the leaderboard rank
      final currentUserEntry = _leaderboard.firstWhere(
        (entry) => entry['user_id'] == currentUserId,
        orElse: () => {'total_points': 0},
      );

      _totalPoints = currentUserEntry['total_points'] ?? 0;

      // 3. Tell the UI to refresh
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading leaderboard in ViewModel: $e");
    }
  }

  Future<void> fetchChallenges() async {
    _isLoading = true;
    notifyListeners(); // Turn on loading spinner

    try {
      final bool isDaily = _currentFilter == 'Daily';

      // Get the actual user ID from Supabase Auth
      final String currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';

      if (currentUserId.isEmpty) {
        print("Error: No user logged in!");
        return; // Stop the fetch if they aren't logged in
      }

      // Pass the currentUserId into the repo
      _browseChallenges = await _repository.fetchChallenges(
        currentUserId,
        isDaily,
      );
    } catch (e) {
      print("ViewModel Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitChallenge(
    int challengeId,
    Uint8List mediaBytes,
    String fileExtension,
  ) async {
    _isSubmitting = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final String currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';

      if (currentUserId.isEmpty) {
        throw Exception("Session expired. Please log in again.");
      }

      await _repository.submitChallenge(
        userId: currentUserId,
        challengeId: challengeId,
        mediaBytes: mediaBytes,
        fileExtension: fileExtension,
      );

      await fetchChallenges();
      await loadLeaderboardData(currentUserId);
      return true;
    } catch (e) {
      _lastErrorMessage = e.toString();
      print("Submission Error: $e");
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String userId) async {
    try {
      _history = await _repository.fetchHistory(userId);
      notifyListeners();
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    }
  }

  String _historyFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  String get historyFilter => _historyFilter;

  void setHistoryFilter(String status) {
    _historyFilter = status;
    notifyListeners();
  }

  // This getter automatically filters the list for the UI
  List<Map<String, dynamic>> get filteredHistory {
    if (_historyFilter == 'all') return _history;
    return _history
        .where(
          (item) =>
              item['chall_status'].toString().toLowerCase() == _historyFilter,
        )
        .toList();
  }

  void setFilter(String newFilter) {
    if (_currentFilter != newFilter) {
      _currentFilter = newFilter;
      fetchChallenges();
    }
  }
}
