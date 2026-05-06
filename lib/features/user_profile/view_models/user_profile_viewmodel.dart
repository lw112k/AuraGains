// Location: lib/features/user_profile/view_models/user_profile_viewmodel.dart

import 'package:flutter/material.dart';
// TODO: Import your UserModel and BodyStatusModel once ready

class UserProfileViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Variables to hold the fetched data
  String? userName;
  String? avatarUrl;
  String? levelName;
  int totalWorkouts = 0;
  int totalVolume = 0;
  int streak = 0;
  String? currentProtocolName;
  int postCount = 0;

  UserProfileViewModel() {
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Call ProfileService.getProfile(uid)
      // TODO: Call ProgressService.getTotalWorkouts(uid), etc.
      
      // Simulating a network fetch delay
      await Future.delayed(const Duration(seconds: 1));

      // After fetching, assign the real data to the variables here
      
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}