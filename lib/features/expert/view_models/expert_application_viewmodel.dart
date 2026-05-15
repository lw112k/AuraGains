// Location: lib/features/expert/view_models/expert_application_viewmodel.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/expert_application_repository.dart';

/// The ViewModel acts as the middle-man between the UI Screen and the Database Repository.
/// It holds the state (loading spinners, text inputs) and notifies the UI when things change.
class TrainerApplicationViewModel extends ChangeNotifier {
  // Connect to the repository we just built
  final ExpertRepository _repository = ExpertRepository();

  // Track whether we are currently sending data to the server (to show a spinner)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Controllers to read what the user types into the text fields
  final titleController = TextEditingController();
  final experienceController = TextEditingController();
  final descriptionController = TextEditingController();

  // A list to hold the files the user selects from their phone gallery (native)
  List<File> selectedImages = [];

  // On web the picker returns XFile objects; keep them separate so we don't
  // attempt to construct dart:io `File` instances which are not supported.
  List<XFile> selectedXFiles = [];

  /// Opens the phone's gallery and lets the user pick multiple images
  Future<void> pickImages() async {
    final picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    // If the user actually picked images (didn't cancel), add them to our list
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      if (kIsWeb) {
        // Keep XFile objects on web; we will render them with Image.memory
        selectedXFiles.addAll(pickedFiles);
      } else {
        selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
      }
      // Tell the UI to rebuild and show the new images
      notifyListeners();
    }
  }

  /// Removes an image from the list if the user taps the 'X' button
  void removeImage(int index) {
    if (kIsWeb) {
      if (index >= 0 && index < selectedXFiles.length) {
        selectedXFiles.removeAt(index);
        notifyListeners();
      }
    } else {
      if (index >= 0 && index < selectedImages.length) {
        selectedImages.removeAt(index);
        notifyListeners();
      }
    }
  }

  /// Validates the form and sends it to the repository
  Future<void> submitApplication(
    BuildContext context,
    String currentUserId,
  ) async {
    // --- VALIDATION ---
    // Prevent submission if fields are empty or no images are uploaded
    if (titleController.text.trim().isEmpty ||
        experienceController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        (selectedImages.isEmpty && selectedXFiles.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields and upload at least one certificate.',
          ),
        ),
      );
      return;
    }

    // Ensure the user typed a real number for 'Years of Experience'
    final int expYears = int.tryParse(experienceController.text.trim()) ?? -1;
    if (expYears < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number for experience years.'),
        ),
      );
      return;
    }

    // NOTE: Previously web uploads were blocked here. We now support web by
    // sending XFile bytes to the repository (which uses uploadBinary).

    // --- SUBMISSION ---
    _isLoading = true;
    notifyListeners(); // Turn on the loading spinner in the UI

    try {
      // Call the repository to actually do the Supabase work
      await _repository.submitApplication(
        userId: currentUserId,
        title: titleController.text.trim(),
        experienceYear: expYears,
        description: descriptionController.text.trim(),
        evidenceImages: kIsWeb ? selectedXFiles : selectedImages,
      );

      // If successful, show a message and go back to the profile screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // If Supabase throws an error (e.g. no internet), show it to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    } finally {
      // Turn off the loading spinner regardless of success or failure
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Always clean up controllers when this screen is closed to prevent memory leaks!
  @override
  void dispose() {
    titleController.dispose();
    experienceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
