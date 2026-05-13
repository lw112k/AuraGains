import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//--- Repositories ---
import 'features/message/repositories/message_repository.dart';

// --- Services ---
// The foundational layer. This interacts directly with external systems (Supabase).
import 'core/services/database_connection.dart';

// --- ViewModels ---
// The "State" layer. This acts as the global broadcast station holding user data.
import 'features/auth/view_models/auth_viewmodel.dart';
import 'features/message/view_models/message_view_model.dart';

// --- Views ---
// The "UI" layer. These are the different screens the user can see.
import 'core/widgets/splash_screen.dart';
import 'features/auth/views/login_view.dart';
import 'features/admin/views/admin_view.dart';
import 'features/challenges/view_models/challenge_viewmodel.dart';
import 'core/widgets/user_homepage_frame.dart';

// --- Theme ---
import 'core/theme/app_theme.dart';

/// The entry point of the AuraGains application.
/// It initializes background services and starts the Global Auth Broadcast.
void main() async {
  // 1. Engine Initialization
  // Tells the Flutter engine to pause and prepare for asynchronous background tasks.
  // Required before interacting with any native code or external databases.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Database Initialization
  // Interacts with [DatabaseConnection] in the services folder to wake up Supabase.
  // This MUST finish before runApp is called so the ViewModel has a database to talk to.
  await DatabaseConnection.initialize();

  // =======================================================================
  // 3. APP LAUNCH & THE "RADIO TOWER" (GLOBAL STATE)
  // =======================================================================
  // TEAMMATES, READ THIS CAREFULLY! 📢
  // Think of `MultiProvider` as a giant Radio Tower at the top of a mountain.
  // Every ViewModel we put in this list is a "Radio Station".
  // By plugging them in here at the very root of the app, EVERY screen inside
  // AuraGains can easily "tune in" to get data (using context.watch) without
  // us having to pass variables between a hundred different files.
  runApp(
    // DevicePreview lets us test how the app looks on different phone sizes
    // right on our computer screens. It automatically hides in the final .exe build.
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        // 👇 THE MASTER PROVIDER LIST 👇
        // CRITICAL RULE: If you build a new ViewModel for your feature,
        // YOU MUST ADD IT TO THIS LIST! If you don't, your screen will crash
        // with a "ProviderNotFoundException" red screen of death.
        providers: [
          // 1. Auth Station (Master Access)
          // The cascade operator (..restoreSession()) triggers the login check
          // the exact millisecond the app is born, pulling data into global memory.
          ChangeNotifierProvider(
            create: (_) => AuthViewModel()..restoreSession(),
          ),

          // 2. Challenge Station
          // Handles data for Browse, Leaderboard, and Video Submissions.
          ChangeNotifierProvider(create: (_) => ChallengeViewModel()),

          // -----------------------------------------------------------
          // 🚨 TODO FOR TEAMMATES: ADD YOUR VIEWMODELS HERE! 🚨
          // -----------------------------------------------------------
          // Just copy the format above. For example:
          //
          // Post Feature:
          // ChangeNotifierProvider(create: (_) => PostViewModel()),
          //
          ChangeNotifierProvider(
            create: (_) => MessageViewModel(
              repository: MessageRepository(),
              currentUserId:
                  Supabase.instance.client.auth.currentUser?.id ?? '',
            ),
          ),
        ],

        // After building the Radio Tower and turning on all the stations,
        // we finally boot up the actual visual UI.
        child: const AuraGainsApp(),
      ),
    ),
  );
}

/// The root material application widget.
/// Sets up the global theme and delegates initial routing to the [AuthWrapper].
class AuraGainsApp extends StatelessWidget {
  const AuraGainsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      // Injecting our custom global theme from app_theme
      theme: AppTheme.darkTheme,

      // Instead of hardcoding a starting screen, we hand control to our router.
      home: const AuthWrapper(),
    );
  }
}

/// The Traffic Controller for the entire app.
/// It listens to the [AuthViewModel] broadcast and dynamically routes the user
/// based on their current authentication state and database role.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listens to the global state variables (isLoading, currentUser).
    // Whenever AuthViewModel calls [notifyListeners()], this widget automatically rebuilds.
    final authViewModel = context.watch<AuthViewModel>();

    // CASE 1: Data is still fetching.
    // Interacts with [SplashScreen] to provide a visual buffer so the app doesn't crash
    // or show blank screens while waiting for Supabase to return the user's role.
    if (authViewModel.isLoading) return const SplashScreen();

    // CASE 2: No active session or user is logged out.
    // Interacts with [Login] view, forcing unauthenticated users to authenticate.
    if (authViewModel.currentUser == null) return const LoginView();

    // CASE 3: Session restored! Implement Role-Based Access Control.
    // Interacts with the 'role' string inside the [UserModel].
    // This safely separates the Admin and User features into their own environments.
    switch (authViewModel.currentUser!.role) {
      case 'admin':
        return const AdminView();
      case 'user':
        return const UserHomepageFrame();
      default:
        // Security Fallback: If a role is corrupted or unrecognized, force a login.
        return const LoginView();
    }
  }
}
