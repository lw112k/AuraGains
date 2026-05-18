import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import 'admin_applications_view.dart';
import 'admin_dashboard_view.dart';
import 'admin_users_view.dart';
import 'admin_challenges_view.dart';
import 'admin_reports_view.dart';
import 'package:auragains/features/admin/admin_palette.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminViewModel>(
      create: (_) => AdminViewModel(),
      child: const _AdminShell(),
    );
  }
}

class _AdminShell extends StatefulWidget {
  const _AdminShell();

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _currentIndex = 2;
  int _reportsRefreshKey = 0;

  static const _tabs = [
    (label: 'Verify Expert', icon: Icons.assignment_rounded),
    (label: 'User', icon: Icons.people_rounded),
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Challenges', icon: Icons.emoji_events_rounded),
    (label: 'Reports', icon: Icons.flag_rounded),
  ];

  List<Widget> get _pages => [
        const AdminApplicationsView(),
        const AdminUsersView(),
        const AdminDashboardView(),
        const AdminChallengesView(),
        AdminReportsView(
          key: ValueKey('reports_$_reportsRefreshKey'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              _tabs[_currentIndex].label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          if (vm.isActionLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: () async {
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
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _AdminNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _currentIndex = i;
          if (i == 4) _reportsRefreshKey++;
        }),
        pendingApplications: vm.stats.pendingApplications,
      ),
    );
  }
}

class _AdminNavBar extends StatelessWidget {
  const _AdminNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.pendingApplications,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final int pendingApplications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.assignment_rounded,
                label: 'Verify Expert',
                active: currentIndex == 0,
                onTap: () => onTap(0),
                badge: pendingApplications,
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'User',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Challenges',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.flag_rounded,
                label: 'Reports',
                active: currentIndex == 4,
                onTap: () => onTap(4),
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
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accent : AppTheme.muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: active
                      ? AppTheme.accent.withOpacity(0.12)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                    if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.warn,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
