import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../repositories/user_profile_repository.dart';
import '../models/user_profile_model.dart';
import '../models/body_stats_model.dart';
import '../models/level_model.dart';
import '../../auth/view_models/auth_viewmodel.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileRepository _repository = UserProfileRepository();

  final String targetUserId;
  late final String currentUserId;

  UserProfileViewModel({required this.targetUserId});

  bool _isLoading = true;
  bool _isMe = false;
  bool _isSavingStats = false;
  bool _isUploadingPic = false;

  LevelModel? _currentLevel;
  List<LevelModel> _availableLevels = [];

  int _followerCount = 0;
  int _followingCount = 0;

  UserProfileModel? _profile;
  BodyStatsModel? _bodyStats;
  String? _expertStatus;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  bool get isLoading => _isLoading;
  bool get isMe => _isMe;
  bool get isSavingStats => _isSavingStats;
  bool get isUploadingPic => _isUploadingPic;

  UserProfileModel? get profile => _profile;
  BodyStatsModel? get bodyStats => _bodyStats;
  String? get expertStatus => _expertStatus;

  bool get isFollowing => _isFollowing;
  bool get isFollowLoading => _isFollowLoading;
  int get followerCount => _followerCount;
  int get followingCount => _followingCount;

  List<LevelModel> get availableLevels => _availableLevels;
  LevelModel? get currentLevel => _currentLevel;

  Future<void> initializeProfile(String sessionUserId) async {
    _isLoading = true;
    currentUserId = sessionUserId;
    _isMe = currentUserId == targetUserId;

    await Future.wait(<Future<void>>[
      _fetchLevels(),
      _fetchProfileAndExpertStatus(),
      _fetchBodyStats(),
      _fetchNetworkStats(),
      if (!_isMe) _checkFollowStatus(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchLevels() async {
    _availableLevels = await _repository.getAllLevels();
    final userCurrentLevelId = await _repository.getUserCurrentLevelId(
      targetUserId,
    );

    if (userCurrentLevelId != null) {
      _currentLevel = _availableLevels
          .where((lvl) => lvl.levelId == userCurrentLevelId)
          .firstOrNull;
    }
  }

  Future<void> saveLevel(LevelModel selectedLevel) async {
    final success = await _repository.updateUserLevel(
      targetUserId,
      selectedLevel.levelId,
    );
    if (success) {
      _currentLevel = selectedLevel;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      _isUploadingPic = true;
      notifyListeners();

      try {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        final String fileExtension = pickedFile.path.split('.').last;

        final newUrl = await _repository.uploadProfilePicture(
          targetUserId,
          imageBytes,
          fileExtension,
        );

        if (newUrl != null) {
          await _fetchProfileAndExpertStatus();

          if (context.mounted) {
            final authViewModel = Provider.of<AuthViewModel>(
              context,
              listen: false,
            );
            await authViewModel.refreshUser();
          }
        }
      } catch (e) {
        debugPrint("Upload failed: $e");
      } finally {
        _isUploadingPic = false;
        notifyListeners();
      }
    }
  }

  Future<void> clearProfileImage(BuildContext context) async {
    _isUploadingPic = true;
    notifyListeners();

    try {
      final currentPicUrl = _profile?.profilePicUrl ?? '';

      final success = await _repository.clearProfilePicture(
        targetUserId,
        currentPicUrl,
      );

      if (success) {
        await _fetchProfileAndExpertStatus();

        if (context.mounted) {
          await Provider.of<AuthViewModel>(
            context,
            listen: false,
          ).refreshUser();
        }
      }
    } catch (e) {
      debugPrint("Clear failed: $e");
    } finally {
      _isUploadingPic = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProfileAndExpertStatus() async {
    _profile = await _repository.getUserProfile(targetUserId);
    if (_profile?.systemRole == 'expert') {
      _expertStatus = 'approved';
    } else {
      _expertStatus = await _repository.getExpertApplicationStatus(
        targetUserId,
      );
    }
  }

  Future<void> _fetchBodyStats() async {
    _bodyStats = await _repository.getUserBodyStats(targetUserId);
  }

  Future<void> _checkFollowStatus() async {
    _isFollowing = await _repository.checkIsFollowing(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  Future<void> toggleFollow() async {
    if (_isFollowLoading) return;

    _isFollowLoading = true;
    notifyListeners();

    _isFollowing = await _repository.toggleFollow(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
      isCurrentlyFollowing: _isFollowing,
    );

    // Tell the ViewModel to recount the followers/following
    // immediately after the database updates
    await _fetchNetworkStats();

    _isFollowLoading = false;
    notifyListeners();
  }

  Future<bool> saveBodyStats({
    required double inputHeight,
    required double inputWeight,
    required String selectedUnitSystem,
  }) async {
    _isSavingStats = true;
    notifyListeners();

    final isImperial = selectedUnitSystem == 'ft/lbs';
    final finalHeightCm = isImperial ? inputHeight * 2.54 : inputHeight;
    final finalWeightKg = isImperial ? inputWeight / 2.20462 : inputWeight;

    final success = await _repository.updateBodyStats(
      userId: targetUserId,
      heightCm: finalHeightCm,
      weightKg: finalWeightKg,
      unitSystem: selectedUnitSystem,
    );

    if (success) {
      _bodyStats = null;
      await _fetchBodyStats();
    }

    _isSavingStats = false;
    notifyListeners();
    return success;
  }

  Future<void> _fetchNetworkStats() async {
    final stats = await _repository.getNetworkStats(targetUserId);
    _followerCount = stats['followers'] ?? 0;
    _followingCount = stats['following'] ?? 0;
  }
}
