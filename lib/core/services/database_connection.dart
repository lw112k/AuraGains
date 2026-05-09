import 'package:supabase_flutter/supabase_flutter.dart';

/// A centralized configuration and connection manager for the AuraGains Supabase backend.
///
/// This class utilizes the singleton pattern provided by the `supabase_flutter` package
/// to ensure that a single, persistent database connection and authentication session
/// is shared across the entire application.
class DatabaseConnection {
  /// The RESTful endpoint for the Supabase project.
  static const String supabaseUrl = 'https://hmksipflmovmtsbtstpg.supabase.co';

  /// The public anonymous key used for client-side API requests.
  /// This key relies on the database's Row Level Security (RLS) policies to restrict data access.
  static const String supabaseAnonKey =
      'sb_publishable_InaLmiaQtI0527Q44CFhrQ_DBg5bTOi';

  /// The globally shared Supabase client instance.
  ///
  /// This acts as the master connection pipeline. It should be used by all repositories
  /// (e.g., `AuthRepository`) to execute database queries and authentication methods.
  ///
  /// **Important:** [initialize] must be called before accessing this client.
  static final SupabaseClient client = Supabase.instance.client;

  /// Initializes the Supabase master client and automatically restores any saved user sessions.
  ///
  /// This method must be awaited in `main.dart` inside `main()` immediately after
  /// `WidgetsFlutterBinding.ensureInitialized()` and before `runApp()`.
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
