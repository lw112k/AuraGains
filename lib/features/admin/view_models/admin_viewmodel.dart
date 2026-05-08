import 'package:flutter/foundation.dart';

import '../repositories/admin_repository.dart';
import '../models/trainer_application_model.dart';

/// Lightweight ChangeNotifier for admin operations that supplement
/// [AdminProvider].
///
/// Handles trainer-application state for [ApplicationsScreen] and
/// [VerifyTrainerScreen].  For dashboard + reports state, see [AdminProvider].
class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repo = AdminRepository();

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  List<TrainerApplication> _applications = [];

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<TrainerApplication> get applications =>
      List.unmodifiable(_applications);

  List<TrainerApplication> get pending =>
      _applications.where((a) => a.isPending).toList();

  List<TrainerApplication> get approved =>
      _applications.where((a) => a.isApproved).toList();

  List<TrainerApplication> get rejected =>
      _applications.where((a) => a.isRejected).toList();

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> loadApplications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _repo.fetchAllApplications();
      _applications = rows
          .map((r) => TrainerApplication.fromSupabase(r))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Approves an application and promotes the applicant to 'expert'.
  Future<void> approveApplication(
      String applicationId, String userId) async {
    try {
      await _repo.approveApplication(applicationId, userId);
      _applications = _applications.map((a) {
        if (a.id == applicationId) return a.copyWith(status: 'approved');
        return a;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Rejects a trainer application.
  Future<void> rejectApplication(String applicationId) async {
    try {
      await _repo.rejectApplication(applicationId);
      _applications = _applications.map((a) {
        if (a.id == applicationId) return a.copyWith(status: 'rejected');
        return a;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
