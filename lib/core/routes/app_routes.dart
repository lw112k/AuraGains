import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/admin/views/admin_panel_screen.dart';
import '../../features/admin/views/content_detail_screen.dart';
import '../../features/admin/views/user_management_screen.dart';
import '../../features/auth/view_models/auth_viewmodel.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/homepage/views/user_home.dart';
import '../../core/widgets/splash_screen.dart';
import '../../providers/admin_provider.dart';

// ─────────────────────────────────────────────────────────
// ROUTE PATH CONSTANTS
// ─────────────────────────────────────────────────────────

/// Centralised route path strings used throughout the app.
///
/// Always use these constants with [context.push] / [context.go] rather
/// than raw string literals so refactors stay in one place.
abstract final class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String userHome = '/home';
  static const String adminPanel = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';

  static const String _adminContentBase = '/admin/content';

  /// Returns the full path for the content-detail screen, e.g.
  /// `/admin/content/abc-123`.
  static String adminContentDetail(String contentId) =>
      '$_adminContentBase/$contentId';
}

// ─────────────────────────────────────────────────────────
// ROUTER FACTORY
// ─────────────────────────────────────────────────────────

/// Builds and owns the [GoRouter] instance for the app.
///
/// Call [AppRouter.createRouter] once inside a [StatefulWidget] (e.g. the
/// root `AuraGainsApp`) and pass the result to [MaterialApp.router].
///
/// The router listens to [AuthViewModel] via [GoRouter.refreshListenable] so
/// the redirect guard runs whenever auth state changes (login / logout /
/// session restore).
abstract final class AppRouter {
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: AppRoutes.root,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isLoading = authViewModel.isLoading;
        final isLoggedIn = authViewModel.currentUser != null;
        final path = Uri.parse(state.location).path;

        // While the session is being restored, stay on the root splash.
        if (isLoading) return null;

        // Not authenticated → always send to login.
        if (!isLoggedIn) {
          if (path == AppRoutes.login) return null;
          return AppRoutes.login;
        }

        // Authenticated — redirect away from root/login to the role home.
        if (path == AppRoutes.root || path == AppRoutes.login) {
          final role = authViewModel.currentUser!.role;
          return role == 'admin' ? AppRoutes.adminPanel : AppRoutes.userHome;
        }

        return null;
      },
      routes: [
        // Splash / entry point while session is being restored.
        GoRoute(
          path: AppRoutes.root,
          builder: (_, __) => const SplashScreen(),
        ),

        // Unauthenticated entry point.
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Login(),
        ),

        // Standard user home.
        GoRoute(
          path: AppRoutes.userHome,
          builder: (_, __) => const UserHome(),
        ),

        // ── Admin routes ────────────────────────────────────────────────
        GoRoute(
          path: AppRoutes.adminPanel,
          builder: (_, __) => ChangeNotifierProvider(
            create: (_) => AdminProvider()..loadData(),
            child: const AdminPanelScreen(),
          ),
          routes: [
            GoRoute(
              path: 'users',
              builder: (_, __) => const UserManagementScreen(),
            ),
            // /admin/reports — reuses the admin panel (pending reports queue).
            GoRoute(
              path: 'reports',
              builder: (_, __) => ChangeNotifierProvider(
                create: (_) => AdminProvider()..loadData(),
                child: const AdminPanelScreen(),
              ),
            ),
            GoRoute(
              path: 'content/:id',
              builder: (_, state) => ContentDetailScreen(
                postId: state.params['id']!,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
