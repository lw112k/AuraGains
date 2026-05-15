import 'package:flutter/foundation.dart';
import '../models/admin_challenge_model.dart';
import '../models/admin_challenge_submission_model.dart';
import '../repositories/admin_challenge_repository.dart';

// =====================================================================
// ADMIN CHALLENGE VIEW MODEL
// State management for challenges and submissions management screens.
// Scoped locally inside AdminChallengesView – not registered in main.dart.
// =====================================================================
class AdminChallengeViewModel extends ChangeNotifier {
  final AdminChallengeRepository _repo = AdminChallengeRepository();

  // ─── Loading / Error ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? errorMessage;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;

  // ─── Challenges ──────────────────────────────────────────────────────
  List<AdminChallengeModel> _allChallenges = [];
  List<AdminChallengeModel> get challenges => _allChallenges;

  // ─── Submissions ─────────────────────────────────────────────────────
  List<AdminChallengeSubmissionModel> _allSubmissions = [];
  String submissionFilter = 'pending'; // 'all', 'pending', 'approved', 'rejected'

  List<AdminChallengeSubmissionModel> get filteredSubmissions {
    if (submissionFilter == 'all') return _allSubmissions;
    return _allSubmissions
        .where((s) => s.challStatus == submissionFilter)
        .toList();
  }

  // ─── Tab state ───────────────────────────────────────────────────────
  int currentTabIndex = 0; // 0 = Challenges list, 1 = Submissions

  // ─── Load methods ────────────────────────────────────────────────────

  Future<void> loadChallenges() async {
    _setLoading(true);
    try {
      _allChallenges = await _repo.fetchChallenges();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load challenges: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSubmissions() async {
    _setLoading(true);
    try {
      _allSubmissions = await _repo.fetchSubmissions();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load submissions: $e';
      debugPrint(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Challenge CRUD ─────────────────────────────────────────────────

  Future<bool> createChallenge(Map<String, dynamic> data) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.createChallenge(data);
      await loadChallenges();
      return true;
    } catch (e) {
      errorMessage = 'Failed to create challenge: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChallenge(int id, Map<String, dynamic> data) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.updateChallenge(id, data);
      await loadChallenges();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update challenge: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChallenge(int id) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.deleteChallenge(id);
      _allChallenges = _allChallenges.where((c) => c.challId != id).toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete challenge: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleActive(int id, bool value) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.toggleChallengeActive(id, value);
      _allChallenges = _allChallenges
          .map((c) => c.challId == id ? c.copyWith(isActive: value) : c)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to toggle active status: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ─── Submission Actions ─────────────────────────────────────────────

  Future<bool> approveSubmission(int id) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.approveSubmission(id);
      _allSubmissions = _allSubmissions
          .map((s) =>
              s.challSubmissionId == id ? s.copyWith(challStatus: 'approved') : s)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to approve submission: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectSubmission(int id, String reason) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectSubmission(id, reason);
      _allSubmissions = _allSubmissions
          .map((s) => s.challSubmissionId == id
              ? s.copyWith(challStatus: 'rejected', rejectReason: reason)
              : s)
          .toList();
      return true;
    } catch (e) {
      errorMessage = 'Failed to reject submission: $e';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  // ─── Setters ─────────────────────────────────────────────────────────

  void setSubmissionFilter(String filter) {
    submissionFilter = filter;
    notifyListeners();
  }

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
