import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Minimal local ViewModel stub to keep this view self-contained.
// The real implementation may live elsewhere; this prevents
// build errors until that file is restored.
class TrainerApplicationViewModel extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<File> selectedImages = [];

  bool isLoading = false;

  Future<void> pickImages() async {
    // Placeholder: integrate ImagePicker/FilePicker in real implementation.
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> submitApplication(BuildContext context, String userId) async {
    isLoading = true;
    notifyListeners();
    // Minimal stub: simulate a short delay.
    await Future.delayed(const Duration(milliseconds: 200));
    isLoading = false;
    notifyListeners();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application submitted (stub).')),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    experienceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

class TrainerApplicationScreen extends StatelessWidget {
  final String currentUserId;

  const TrainerApplicationScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrainerApplicationViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A), // AuraGains Background
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Trainer Application',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<TrainerApplicationViewModel>(
          builder: (context, viewModel, child) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          const Text(
                            'Expert Verification',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Provide your professional details and certifications to unlock expert privileges and the verified badge.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Section
                          _buildSectionLabel('Professional Title'),
                          _buildTextField(
                            controller: viewModel.titleController,
                            hintText: 'e.g. Certified Personal Trainer',
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel('Years of Experience'),
                          _buildTextField(
                            controller: viewModel.experienceController,
                            hintText: 'e.g. 5',
                            isNumber: true,
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel('Experience Description'),
                          _buildTextField(
                            controller: viewModel.descriptionController,
                            hintText:
                                'Briefly describe your background, specialties, and coaching style...',
                            maxLines: 5,
                          ),
                          const SizedBox(height: 32),

                          // Document Upload Section (Based on layout reference)
                          _buildSectionLabel('Certifications & Evidence'),
                          const SizedBox(height: 8),
                          _buildUploadZone(viewModel),

                          // Display Selected Images
                          if (viewModel.selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildImageGrid(viewModel),
                          ],
                          const SizedBox(
                            height: 40,
                          ), // Bottom padding for scroll
                        ],
                      ),
                    ),
                  ),

                  // Sticky Bottom Button
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0A0A),
                      border: Border(
                        top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.submitApplication(
                                context,
                                currentUserId,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0066FF,
                          ), // AuraGains Accent
                          disabledBackgroundColor: const Color(
                            0xFF0066FF,
                          ).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper Widget: Section Labels
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper Widget: Text Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF555555),
        ), // Darker grey for hints
        filled: true,
        fillColor: const Color(0xFF161616), // AuraGains Card color
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0066FF),
            width: 1,
          ), // Blue highlight
        ),
      ),
    );
  }

  // Helper Widget: Upload Zone
  Widget _buildUploadZone(TrainerApplicationViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF0066FF),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to upload documents',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'JPG, PNG or PDF (Max 5MB)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Selected Images Grid
  Widget _buildImageGrid(TrainerApplicationViewModel viewModel) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                viewModel.selectedImages[index],
                fit: BoxFit.cover,
              ),
            ),
            // Semi-transparent overlay for delete button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => viewModel.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
