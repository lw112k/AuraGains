import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../repositories/onboarding_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  final OnboardingRepository _repository;

  // The state we are building up
  OnboardingModel _onboardingData;
  OnboardingModel get data => _onboardingData;

  // Track which page of the onboarding we are on
  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OnboardingViewModel({
    required OnboardingRepository repository,
    required String currentUserId,
  }) : _repository = repository,
       _onboardingData = OnboardingModel(userId: currentUserId);

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void updateGender(String gender) {
    _onboardingData = _onboardingData.copyWith(gender: gender);
    notifyListeners();
  }

  void updateMetrics({int? age, double? weight, double? height}) {
    _onboardingData = _onboardingData.copyWith(
      age: age,
      weight: weight,
      height: height,
    );
    notifyListeners();
  }

  void toggleUnits(String system) {
    _onboardingData = _onboardingData.copyWith(unitSystem: system);
    notifyListeners();
  }

  void updateObjective(String objective) {
    _onboardingData = _onboardingData.copyWith(objective: objective);
    notifyListeners();
  }

  Future<bool> submitOnboarding() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.completeOnboarding(_onboardingData);
      return true; // Success
    } catch (e) {
      print("Error saving onboarding: $e");
      return false; // Failed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
