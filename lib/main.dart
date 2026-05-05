import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart'; 

// --- Services ---
// The foundational layer. This interacts directly with external systems (Supabase).
import 'core/services/database_connection.dart';

// --- ViewModels ---
// The "State" layer. This acts as the global broadcast station holding user data.
import 'features/auth/view_models/auth_viewmodel.dart';

// --- Views ---
// The "UI" layer. These are the different screens the user can see.
import 'core/widgets/splash_screen.dart';
import 'features/auth/views/login_view.dart';
import 'features/admin/views/admin_home.dart';
import 'features/homepage/views/user_home.dart';

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

  // 3. App Launch & State Injection
  runApp(
    // Added DevicePreview Wrapper here
    DevicePreview(
      enabled: !kReleaseMode, // Automatically turns off when you build the .exe
      builder: (context) => MultiProvider(
        providers: [
          // Initializes [AuthViewModel] at the absolute root of the app.
          // The cascade operator (..restoreSession()) triggers the login check
          // the exact millisecond the app is born, pulling data into global memory.
          ChangeNotifierProvider(
            create: (_) => AuthViewModel()..restoreSession(),
          ),
        ],
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

      theme: ThemeData.dark(), // Global dark theme for AuraGains
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
    if (authViewModel.currentUser == null) return const Login();

    // CASE 3: Session restored! Implement Role-Based Access Control.
    // Interacts with the 'role' string inside the [UserModel].
    // This safely separates the Admin and User features into their own environments.
    switch (authViewModel.currentUser!.role) {
      case 'admin':
        return const AdminHome();
      case 'user':
        return const UserHome();
      default:
        // Security Fallback: If a role is corrupted or unrecognized, force a login.
        return const Login();
    }
  }
}
