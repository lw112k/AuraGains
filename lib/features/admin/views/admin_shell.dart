import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auragains/features/admin/admin_palette.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';
import '../../../providers/admin_provider.dart';
import 'admin_content_screen.dart';
import 'admin_panel_screen.dart';
import 'admin_view.dart';
import 'applications_screen.dart';
import 'user_management_screen.dart';

/// The persistent shell for all admin screens.
///
/// Uses an [IndexedStack] to keep every tab alive while the custom
/// bottom nav bar switches between them.
///
/// Tab layout:
///   0 – Content      → [AdminContentScreen]
///   1 – Dashboard    → [AdminPanelScreen]      ← default start tab
///   2 – Users        → [UserManagementScreen]
///   3 – Applications → [ApplicationsScreen]
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 1; // Start on the Dashboard tab

  final List<Widget> _pages = [
    AdminContentScreen(),
    AdminPanelScreen(),
    UserManagementScreen(),
    ApplicationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Overlay stack so we can show a persistent logout button above
      // each child screen without changing per-screen AppBars.
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Top-right persistent logout button (prominent, accessible).
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      try {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logging out...')),
                        );
                        await context.read<AuthViewModel>().logout();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: $e')),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _AdminNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// Using built-in Icon for logout; no inline SVG required.

class _AdminNavBar extends StatelessWidget {
  const _AdminNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'Content',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Users',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'Applications',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withAlpha(20),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight wrapper used by `main.dart`'s `case 'admin'` branch.
/// Keeps the existing `AdminShell` behaviour but ensures the
/// required provider is created in one place.
class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider()..loadData(),
      child: const AdminShell(),
    );
  }
}
