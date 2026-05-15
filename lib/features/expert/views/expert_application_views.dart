import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// drop_preventer removed — web drag/drop prevention is handled in web/index.html
import 'package:provider/provider.dart';

// IMPORTANT: Import the real ViewModel file we created above!
import '../view_models/expert_application_viewmodel.dart';

/// The View handles ONLY the visual layout. It passes button clicks to the ViewModel.
class TrainerApplicationScreen extends StatefulWidget {
  // We need to know who is applying, so we require the user ID from the previous screen.
  final String currentUserId;

  const TrainerApplicationScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  _TrainerApplicationScreenState createState() =>
      _TrainerApplicationScreenState();
}

class _TrainerApplicationScreenState extends State<TrainerApplicationScreen> {
  @override
  void initState() {
    super.initState();
    // Web drag/drop prevention is handled in `web/index.html`.
  }

  @override
  void dispose() {
    // Nothing to cleanup here; web handlers are global and managed in `web/index.html`.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider creates the ViewModel and makes it available to the widgets below it
    return ChangeNotifierProvider(
      create: (_) => TrainerApplicationViewModel(),
      child: Scaffold(
        backgroundColor: const Color(
          0xFF0A0A0A,
        ), // AuraGains Dark Theme Background
        // --- APP BAR ---
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(), // Go back button
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

        // --- MAIN BODY ---
        // The Consumer listens to the ViewModel. Anytime notifyListeners() is called
        // (like when an image is picked or loading starts), ONLY this block rebuilds.
        body: Consumer<TrainerApplicationViewModel>(
          builder: (context, viewModel, child) {
            return SafeArea(
              child: Column(
                children: [
                  // Expanded ensures the scrollable area takes up all space ABOVE the bottom button
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- HEADER TEXT ---
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

                          // --- INPUT FORMS ---
                          // Title Field
                          _buildSectionLabel('Professional Title'),
                          _buildTextField(
                            controller: viewModel
                                .titleController, // Connects to ViewModel
                            hintText: 'e.g. Certified Personal Trainer',
                          ),
                          const SizedBox(height: 20),

                          // Experience Field
                          _buildSectionLabel('Years of Experience'),
                          _buildTextField(
                            controller: viewModel
                                .experienceController, // Connects to ViewModel
                            hintText: 'e.g. 5',
                            isNumber: true, // Shows number keyboard on phones
                          ),
                          const SizedBox(height: 20),

                          // Description Field
                          _buildSectionLabel('Experience Description'),
                          _buildTextField(
                            controller: viewModel
                                .descriptionController, // Connects to ViewModel
                            hintText:
                                'Briefly describe your background, specialties, and coaching style...',
                            maxLines: 5, // Makes the box taller for paragraphs
                          ),
                          const SizedBox(height: 32),

                          // --- DOCUMENT UPLOAD ZONE ---
                          _buildSectionLabel('Certifications & Evidence'),
                          const SizedBox(height: 8),
                          _buildUploadZone(viewModel),

                          // Only show the image grid if the user has actually picked images
                          if (viewModel.selectedImages.isNotEmpty ||
                              viewModel.selectedXFiles.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildImageGrid(viewModel),
                          ],

                          // Extra padding at the bottom so content isn't hidden behind the sticky button
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // --- STICKY BOTTOM SUBMIT BUTTON ---
                  // This container stays at the bottom of the screen regardless of scrolling
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
                        // If loading, disable button (null). Otherwise, run submit logic.
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.submitApplication(
                                context,
                                widget.currentUserId,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0066FF,
                          ), // AuraGains Accent Blue
                          disabledBackgroundColor: const Color(
                            0xFF0066FF,
                          ).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        // Swap text for a spinner if the ViewModel is currently loading
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

  // --- HELPER WIDGETS ---
  // Using helper methods for repetitive UI elements keeps the build() method clean and readable.

  /// Creates the small white labels above text fields
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

  /// Creates a styled AuraGains text input box
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
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF161616), // Dark grey card color
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Highlights blue when the user taps on it
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1),
        ),
      ),
    );
  }

  /// Creates the large dashed box users tap to pick images
  Widget _buildUploadZone(TrainerApplicationViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.pickImages, // Triggers phone gallery
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
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
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

  /// Displays the images the user has picked in a grid
  Widget _buildImageGrid(TrainerApplicationViewModel viewModel) {
    final isWeb = kIsWeb;
    final count = isWeb
        ? viewModel.selectedXFiles.length
        : viewModel.selectedImages.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
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
            // The image itself (web uses XFile -> bytes, native uses File)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isWeb
                  ? FutureBuilder<Uint8List>(
                      future: viewModel.selectedXFiles[index].readAsBytes(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done ||
                            snap.data == null) {
                          return Container(color: const Color(0xFF1E1E1E));
                        }
                        return Image.memory(snap.data!, fit: BoxFit.cover);
                      },
                    )
                  : Image.file(
                      viewModel.selectedImages[index],
                      fit: BoxFit.cover,
                    ),
            ),

            // The tiny 'X' delete button over the top right corner
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => viewModel.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.6,
                    ), // Semi-transparent black background
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
