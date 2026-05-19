import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/create_post_model.dart';
import '../repositories/create_post_repository.dart';

/// =====================================================================
/// [CreatePostViewModel]
///
/// Manages the state, input fields, media selections, and tag collections
/// for the post creation flow before executing database transactions.
/// =====================================================================

class CreatePostViewModel extends ChangeNotifier {
  final CreatePostRepository _repository = CreatePostRepository();
  final CreatePostModel _post = CreatePostModel();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;

  bool _isTagsLoading = true;
  bool get isTagsLoading => _isTagsLoading;

  // Cache for system tags retrieved from the database
  List<SelectedTag> _availableSystemTags = [];

  // --- GETTERS ---
  CreatePostModel get post => _post;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SelectedTag> get availableSystemTags => _availableSystemTags;

  // --- INITIALIZATION ---
  /// Pulls the latest system-defined tags directly from the database
  Future<void> loadSystemTags() async {
    _isTagsLoading = true;
    notifyListeners();

    _availableSystemTags = await _repository.fetchSystemTags();

    _isTagsLoading = false;
    notifyListeners();
  }

  // --- CORE TEXT MUTATORS ---
  void setTitle(String title) {
    _post.title = title;
    notifyListeners();
  }

  void setDescription(String desc) {
    _post.description = desc;
    notifyListeners();
  }

  void setPostType(PostType type) {
    _post.postType = type;
    if (type == PostType.askExpert) {
      _post.visibility = PostVisibility.public;
    }
    notifyListeners();
  }

  void setVisibility(PostVisibility visibility) {
    if (_post.postType == PostType.askExpert) return;

    _post.visibility = visibility;
    notifyListeners();
  }

  // --- DEVICE MEDIA PICKING ---
  /// Launches the native gallery view allowing users to multi-select
  /// images and videos seamlessly.
  Future<void> pickMedia() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();

      if (pickedFiles.isNotEmpty) {
        for (var xFile in pickedFiles) {
          final fileName = xFile.name.toLowerCase();

          final isVideo =
              fileName.endsWith('.mp4') ||
              fileName.endsWith('.mov') ||
              fileName.endsWith('.avi') ||
              fileName.endsWith('.mkv') ||
              fileName.endsWith('.webm');

          final type = isVideo ? MediaType.video : MediaType.picture;

          _post.mediaList.add(SelectedMedia(file: xFile, type: type));
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Failed to select media assets: $e";
      notifyListeners();
    }
  }

  void removeMedia(int index) {
    _post.mediaList.removeAt(index);
    notifyListeners();
  }

  // --- SYSTEM & CUSTOM TAG LOGIC ---
  /// Toggles selection status for predefined tags or removes targeted custom tags
  void toggleTag(SelectedTag tag) {
    final exists = _post.tags.any((t) => t.name == tag.name);
    if (exists) {
      _post.tags.removeWhere((t) => t.name == tag.name);
    } else {
      _post.tags.add(tag);
    }
    notifyListeners();
  }

  /// Handles user-generated custom categories, parsing strings to remain safe
  /// and consistent with standardized system formats.
  void addCustomTag(String tagName) {
    if (tagName.trim().isEmpty) return;

    // Convert spaces to underscores for optimal query compatibility
    final cleanName = tagName.trim().toLowerCase().replaceAll(' ', '_');

    bool exists = _post.tags.any((tag) => tag.name == cleanName);
    if (!exists) {
      _post.tags.add(SelectedTag(name: cleanName, type: TagType.user));
      notifyListeners();
    }
  }

  // --- SUPABASE PUBLISHING EXECUTION ---
  Future<bool> publishPost(String currentUserId) async {
    final hasSystemTag = _post.tags.any((tag) => tag.type == TagType.system);
    if (!hasSystemTag) {
      _errorMessage =
          "Please select at least one system category from the pill boxes.";
      notifyListeners();
      return false;
    }

    if (_post.title.trim().isEmpty || _post.description.trim().isEmpty) {
      _errorMessage =
          "A title and description are strictly required to publish.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bool success = await _repository.publishPost(
      currentUserId: currentUserId,
      postModel: _post,
    );

    if (!success) {
      _errorMessage = "Publishing failed. Please verify connection and retry.";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- THUMBNAIL HANDLING ---
  XFile? get thumbnailImage =>
      _post.thumbnailImage; 

  Future<void> pickThumbnail() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        _post.thumbnailImage = pickedFile;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Failed to select thumbnail: $e";
      notifyListeners();
    }
  }

  void removeThumbnail() {
    _post.thumbnailImage = null;
    notifyListeners();
  }
}
