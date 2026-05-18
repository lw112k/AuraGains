import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_model.dart';

class AuthRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Returns the current active session if one exists
  Session? get currentSession => _supabase.auth.currentSession;

  /// Fetches the user's custom data (role, username, etc.) from the profiles table
  Future<AuthModel?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('user')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        return AuthModel.fromJson(data);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  /// Standard Supabase Login (Using supabase api)
  Future<AuthResponse> signIn(String email, String password) async {
    // 1. Authenticate the user credentials normally
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    
    if (user != null) {
      // 2. The Bouncer: Check the 'user' table for the ban status
      final userData = await _supabase
          .from('user')
          .select('is_banned')
          .eq('user_id', user.id)
          .single();

      final isBanned = userData['is_banned'] as bool? ?? false;

      // 3. If they are banned, revoke their session immediately
      if (isBanned) {
        await _supabase.auth.signOut();
        // Throw a specific error so the ViewModel knows exactly what happened
        throw Exception('BANNED_USER'); 
      }
    }

    // 4. If they are NOT banned, return the successful response
    return response;
  }

  /// Register
  Future<AuthModel> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    // 1. SECURITY LAYER:
    // Register the user's secure credentials (Email & Password) via Supabase Auth.
    // These are stored in a protected, hidden schema that we don't manage directly
    // to ensure industry-standard security and encryption.
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final User? authUser = response.user;
    if (authUser == null) {
      throw Exception("Failed to create secure authentication account.");
    }

    // 2. PROFILE LAYER (DATA MAPPING):
    // Map the unique ID from the Auth system to our public 'user' table.
    // While Supabase handles the email and password, all AuraGains-specific data (username,
    // roles, levels, etc.) is stored in user table.
    final Map<String, dynamic> profileData = await _supabase
        .from('user')
        .insert({
          'user_id': authUser.id,
          'username': username,
          // NOTE: We leave gender, date_of_birth, profile_pic_url, and level_id out
          // of this insert. They will default to NULL in your database until the
          // user updates their profile later in the app.
        })
        .select()
        .single();

    // 3. Return the fully formed user model
    return AuthModel.fromJson(profileData);
  }

  /// Clears the session from the device
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
