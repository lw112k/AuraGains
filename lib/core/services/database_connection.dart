//Supabase Configuration
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseConnection {
  static const String supabaseUrl = 'https://hmksipflmovmtsbtstpg.supabase.co'; // Replace with your Supabase URL
  static const String supabaseAnonKey = 'sb_publishable_InaLmiaQtI0527Q44CFhrQ_DBg5bTOi'; // Replace with your Supabase Anon Key

  static final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}