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

  Map<String, dynamic>? _activeProtocol;
  Map<String, dynamic>? get activeProtocol => _activeProtocol;

  int _followerCount = 0;
  int _followingCount = 0;

  String _viewerUnitSystem = 'cm/kg';

  UserProfileModel? _profile;
  BodyStatsModel? _bodyStats;
  String? _expertStatus;

  bool _isFollowing = false;
  bool _isFollowLoading = false;

  // Post Data State
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _savedPosts = [];
  bool _isLoadingPosts = true;

  bool get isLoading => _isLoading;
  bool get isMe => _isMe;
  bool get isSavingStats => _isSavingStats;
  bool get isUploadingPic => _isUploadingPic;

  UserProfileModel? get profile => _profile;
  BodyStatsModel? get bodyStats => _bodyStats;
  String? get expertStatus => _expertStatus;

  bool get isFollowing => _isFollowing;
  bool _isMutual = false;
  bool get isFollowLoading => _isFollowLoading;
  int get followerCount => _followerCount;
  int get followingCount => _followingCount;

  List<LevelModel> get availableLevels => _availableLevels;
  LevelModel? get currentLevel => _currentLevel;

  List<Map<String, dynamic>> get userPosts => _userPosts;
  List<Map<String, dynamic>> get savedPosts => _savedPosts;
  bool get isLoadingPosts => _isLoadingPosts;

  String get displayUnitSystem =>
      _isMe ? (_bodyStats?.unitSystem ?? 'cm/kg') : _viewerUnitSystem;

  Future<void> initializeProfile(String sessionUserId) async {
    _isLoading = true;
    currentUserId = sessionUserId;
    _isMe = currentUserId == targetUserId;

    if (!_isMe) {
      await _checkFollowStatus();
    }

    await Future.wait(<Future<void>>[
      _fetchLevels(),
      _fetchProfileAndExpertStatus(),
      _fetchBodyStats(),
      _fetchNetworkStats(),
      _fetchPostsData(),
      _fetchActiveProtocol(),
      if (!_isMe) _fetchViewerUnitSystem(),
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

  Future<void> refreshProfile() async {
    await Future.wait(<Future<void>>[
      _fetchLevels(),
      _fetchProfileAndExpertStatus(),
      _fetchBodyStats(),
      _fetchNetworkStats(),
      _fetchPostsData(),
      if (!_isMe) _checkFollowStatus(),
      _fetchActiveProtocol(),
      if (!_isMe) _fetchViewerUnitSystem(),
    ]);

    notifyListeners();
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
    // 1. Do YOU follow THEM?
    _isFollowing = await _repository.checkIsFollowing(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );

    // 2. Do THEY follow YOU? 
    final followsMe = await _repository.checkIsFollowing(
      currentUserId: targetUserId,
      targetUserId: currentUserId,
    );

    // 3. A friend is only a friend if the feeling is mutual
    _isMutual = _isFollowing && followsMe;
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

  Future<void> _fetchPostsData() async {
    _isLoadingPosts = true;
    notifyListeners();

    try {
      _userPosts = await _repository.getUserPosts(
        targetUserId: targetUserId,
        isMe: _isMe,
        isMutualFriend: _isMutual,
      );

      if (_isMe) {
        _savedPosts = await _repository.getSavedPosts(currentUserId);
      }
    } catch (e) {
      debugPrint("Error fetching posts data: $e");
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> _fetchActiveProtocol() async {
    _activeProtocol = await _repository.getActiveProtocol(targetUserId);
  }

  Future<void> _fetchViewerUnitSystem() async {
    final viewerStats = await _repository.getUserBodyStats(currentUserId);
    _viewerUnitSystem = viewerStats?.unitSystem ?? 'cm/kg';
  }
}
