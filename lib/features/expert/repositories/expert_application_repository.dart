import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Repository handles all direct communication with the Supabase database.
/// The ViewModel will call these methods so the UI doesn't have to know about SQL.
class ExpertRepository {
  // Get a reference to the global Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submits the application text to the database, then uploads the images to storage.
  Future<void> submitApplication({
    required String userId,
    required String title,
    required int experienceYear,
    required String description,
    required List<File> evidenceImages,
  }) async {
    // --- STEP 1: INSERT TEXT DATA ---
    // Insert the text fields into the 'expert_application' table.
    // We use .select().single() to immediately get the inserted row back.
    // This is crucial because we need the newly generated ID to link the images!
    final applicationResponse = await _supabase
        .from('expert_application')
        .insert({
          'user_id': userId,
          'expert_title': title,
          'experience_year': experienceYear,
          'experience_description': description,
          'application_status': 'pending',
        })
        .select()
        .single();

    // Extract the new ID robustly (can be int or string depending on driver)
    dynamic rawId;
    if (applicationResponse is Map<String, dynamic>) {
      rawId = applicationResponse['expert_application_id'];
    } else {
      rawId = applicationResponse;
    }

    final int applicationId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    // --- STEP 2: UPLOAD IMAGES AND LINK THEM ---
    // Loop through every image the user selected in the UI
    for (var i = 0; i < evidenceImages.length; i++) {
      final file = evidenceImages[i];

      // Get the file extension (e.g., 'jpg' or 'png')
      final fileExt = file.path.split('.').last;

      // Create a unique file name using the User ID, Application ID, and timestamp
      final fileName =
          '$userId-$applicationId-${DateTime.now().millisecondsSinceEpoch}-$i.$fileExt';
      final path = 'certificates/$fileName';

      // 1. Upload the physical file to the 'expert-docs' Supabase Storage bucket
      await _supabase.storage.from('expert-docs').upload(path, file);

      // 2. Ask Supabase for the public web link to that newly uploaded image
      final imageUrlRaw = _supabase.storage
          .from('expert-docs')
          .getPublicUrl(path);
      final String imageUrl = imageUrlRaw is String
          ? imageUrlRaw
          : imageUrlRaw.toString();

      // 3. Insert that web link into the 'expert_application_image' table
      // so the admin can see it later when reviewing the application.
      await _supabase.from('expert_application_image').insert({
        'expert_application_id': applicationId,
        'image_url': imageUrl,
      });
    }
  }
}
