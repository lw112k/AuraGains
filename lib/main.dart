import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

// --- Services ---
// The foundational layer. This interacts directly with external systems (Supabase).
import 'core/services/database_connection.dart';

// --- Routes ---
import 'core/routes/app_routes.dart';

// --- ViewModels ---
// The "State" layer. This acts as the global broadcast station holding user data.
import 'features/auth/view_models/auth_viewmodel.dart';

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
/// Uses [MaterialApp.router] + [GoRouter] for type-safe, auth-aware navigation.
class AuraGainsApp extends StatefulWidget {
  const AuraGainsApp({super.key});

  @override
  State<AuraGainsApp> createState() => _AuraGainsAppState();
}

class _AuraGainsAppState extends State<AuraGainsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // context.read is safe here: MultiProvider is an ancestor in the tree.
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData.dark(), // Global dark theme for AuraGains
      routerConfig: _router,
    );
  }
}
