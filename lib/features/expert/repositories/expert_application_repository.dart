import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

/// The Repository handles all direct communication with the Supabase database.
/// The ViewModel will call these methods so the UI doesn't have to know about SQL.
class ExpertRepository {
  // Get a reference to the global Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submits the application text to the database, then uploads the images to storage.
  ///
  /// The `evidenceImages` list accepts either native `File` objects (mobile)
  /// or `XFile` instances (web). Both are read as bytes and uploaded using
  /// `uploadBinary`, which works uniformly across platforms.
  Future<void> submitApplication({
    required String userId,
    required String title,
    required int experienceYear,
    required String description,
    required List<dynamic> evidenceImages,
  }) async {
    // Ensure the Supabase client has an authenticated user matching `userId`.
    final current = _supabase.auth.currentUser;
    if (current == null) {
      throw Exception(
        'No authenticated user found. Please sign in before submitting the application.',
      );
    }
    if (current.id != userId) {
      throw Exception(
        'Authenticated user mismatch: auth=${current.id} vs provided userId=$userId. Ensure the app is passing the correct user id.',
      );
    }

    // --- STEP 1: INSERT TEXT DATA ---
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
    const String bucketName = 'expert_application_images';

    try {
      for (var i = 0; i < evidenceImages.length; i++) {
        final dynamic file = evidenceImages[i];

        // Derive a reasonable filename (XFile has `name`, native File has `path`)
        String fileNameCandidate = '';
        if (file is XFile) {
          fileNameCandidate = file.name;
        } else {
          try {
            fileNameCandidate = (file as dynamic).path as String;
          } catch (_) {
            fileNameCandidate =
                'upload_${DateTime.now().millisecondsSinceEpoch}';
          }
        }

        final String fileExt = fileNameCandidate.contains('.')
            ? fileNameCandidate.split('.').last
            : 'jpg';

        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}-$i.$fileExt';

        // Put uploads under a per-user, per-application folder
        final String path = '$userId/$applicationId/$fileName';

        // Read bytes from either XFile or native File
        late final Uint8List bytes;
        if (file is XFile) {
          bytes = await file.readAsBytes();
        } else {
          bytes = await (file as dynamic).readAsBytes();
        }

        // Upload binary contents (works on web and native) to the dedicated bucket.
        try {
          await _supabase.storage
              .from(bucketName)
              .uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('bucket not found')) {
            throw Exception(
              'Storage bucket "$bucketName" not found. Please create this bucket in the Supabase dashboard and ensure the client has permission to upload to it.',
            );
          }
          if (msg.contains('row-level security') ||
              msg.contains('violates row-level security') ||
              msg.contains('new row violates') ||
              msg.contains('must be owner of table')) {
            throw Exception("""
Upload failed due to Row-Level Security (or ownership) on Supabase storage while attempting to upload to bucket "$bucketName".
If you ran SQL and received "must be owner of table objects", that means your DB role cannot ALTER storage.objects — run the policy changes from the Supabase Project SQL editor as a project admin, or ask the project owner to run them.

Quick fix (run in Supabase SQL editor):

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow insert for bucket $bucketName"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = '$bucketName');

Alternatively, make a bucket public in the Storage dashboard for testing, or create a server-side RPC/Edge Function that performs uploads using a service role.
""");
          }
          rethrow;
        }

        // Get public URL for the uploaded file
        final imageUrlRaw = _supabase.storage
            .from(bucketName)
            .getPublicUrl(path);
        final String imageUrl = imageUrlRaw is String
            ? imageUrlRaw
            : imageUrlRaw.toString();

        // Insert the reference into the DB
        try {
          await _supabase.from('expert_application_image').insert({
            'expert_application_id': applicationId,
            'image_url': imageUrl,
          });
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('row-level security') ||
              msg.contains('violates row-level security') ||
              msg.contains('new row violates')) {
            // Attempt an RPC fallback if the project has a helper function installed.
            try {
              await _supabase.rpc(
                'insert_expert_application_image',
                params: {'p_app_id': applicationId, 'p_image_url': imageUrl},
              );
              // RPC succeeded — continue to next image
              continue;
            } catch (rpcErr) {
              final rpcMsg = rpcErr.toString();
              throw Exception(
                'Failed to insert image metadata: new row violates row-level security policy.\n'
                        'Attempted RPC fallback `insert_expert_application_image` but it failed: $rpcMsg\n\n' +
                    r'''Fix options:

A) Add an RLS policy to allow authenticated users to insert images for their own applications. Run this in Supabase SQL editor:

ALTER TABLE public.expert_application_image ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow insert for owner"
  ON public.expert_application_image
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.expert_application ea
      WHERE ea.expert_application_id = expert_application_image.expert_application_id
        AND ea.user_id = auth.uid()
    )
  );

B) Or create a server-side SECURITY DEFINER function and grant execute to authenticated clients, then the client can call the RPC. Example SQL to create the function:

CREATE FUNCTION public.insert_expert_application_image(p_app_id bigint, p_image_url text)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.expert_application_image (expert_application_id, image_url) VALUES (p_app_id, p_image_url);
END;
$$;

GRANT EXECUTE ON FUNCTION public.insert_expert_application_image(bigint, text) TO authenticated;

Also ensure the storage bucket "expert_application_images" exists and that storage upload permissions allow authenticated clients to upload files.''',
              );
            }
          }
          rethrow;
        }
      }
    } catch (e) {
      // If anything fails during image upload/linking, attempt to delete the
      // previously created application row to avoid leaving orphaned records.
      try {
        await _supabase
            .from('expert_application')
            .delete()
            .eq('expert_application_id', applicationId);
      } catch (_) {
        // ignore - if delete fails due to the same permission problem, there's
        // nothing more we can do from the client side.
      }
      rethrow;
    }
  }
}
