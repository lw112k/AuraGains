import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import 'admin_dashboard_view.dart';
import 'admin_users_view.dart';
import 'admin_reports_view.dart';
import 'admin_applications_view.dart';

const Color _kBg = Color(0xFF121212);
const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kMuted = Color(0xFF9E9E9E);

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
  int _currentIndex = 0;

  static const _tabs = [
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Users', icon: Icons.people_rounded),
    (label: 'Reports', icon: Icons.flag_rounded),
    (label: 'Applications', icon: Icons.assignment_rounded),
  ];

  static const _pages = [
    AdminDashboardView(),
    AdminUsersView(),
    AdminReportsView(),
    AdminApplicationsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: _kAccent, size: 20),
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
                  color: _kAccent,
                ),
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
        onTap: (i) => setState(() => _currentIndex = i),
        pendingReports: vm.stats.pendingReports,
        pendingApplications: vm.stats.pendingApplications,
      ),
    );
  }
}

class _AdminNavBar extends StatelessWidget {
  const _AdminNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.pendingReports,
    required this.pendingApplications,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final int pendingReports;
  final int pendingApplications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Users',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.flag_rounded,
                label: 'Reports',
                active: currentIndex == 2,
                onTap: () => onTap(2),
                badge: pendingReports,
              ),
              _NavItem(
                icon: Icons.assignment_rounded,
                label: 'Applications',
                active: currentIndex == 3,
                onTap: () => onTap(3),
                badge: pendingApplications,
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
    final color = active ? _kAccent : _kMuted;

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
                        ? _kAccent.withValues(alpha: 0.12)
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
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
