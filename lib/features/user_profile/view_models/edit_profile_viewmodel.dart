import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Controllers for text inputs
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  // For the avatar image picker
  File? selectedImage;
  String? currentAvatarUrl;

  EditProfileViewModel() {
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    _isLoading = true;
    notifyListeners();

    // TODO: Fetch current user data from ProfileService to pre-fill the fields
    // nameController.text = fetchedName;
    // bioController.text = fetchedBio;
    // currentAvatarUrl = fetchedAvatarUrl;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage = File(image.path);
      notifyListeners();
    }
  }

  Future<void> saveProfile(BuildContext context) async {
    _isSaving = true;
    notifyListeners();

    try {
      // 1. TODO: If selectedImage != null, upload it via StorageService to get the new URL
      // 2. TODO: Call ProfileService.updateProfile(uid, {name, bio, avatar_url})
      
      // Simulating network delay
      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }
}