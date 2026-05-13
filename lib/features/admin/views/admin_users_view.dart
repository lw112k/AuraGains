import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_model.dart';
import '../view_models/admin_viewmodel.dart';
import 'package:auragains/features/admin/admin_palette.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        return Column(
          children: [
            // ─ Search + filter bar ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => vm.setUserSearch(v),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search users…',
                        hintStyle: TextStyle(color: AppTheme.muted),
                        prefixIcon: Icon(Icons.search, color: AppTheme.muted, size: 18),
                        filled: true,
                        fillColor: AppTheme.card,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoleFilterChip(
                    current: vm.userRoleFilter,
                    onChanged: (String? v) => vm.setUserRoleFilter(v),
                  ),
                ],
              ),
            ),

            // ─ List ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.card,
                onRefresh: vm.loadUsers,
                child: vm.filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                                  'No users found.',
                                  style: TextStyle(color: AppTheme.muted),
                                ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: vm.filteredUsers.length,
                        separatorBuilder: (_, _) =>
                          Divider(color: AppTheme.border, height: 1),
                        itemBuilder: (ctx, i) {
                          final user = vm.filteredUsers[i];
                          return _UserTile(
                            user: user,
                            isActionLoading: vm.isActionLoading,
                            onBanToggle: () => _toggleBan(ctx, vm, user),
                            onRoleChange: (role) => _changeRole(ctx, vm, user, role),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleBan(
      BuildContext context, AdminViewModel vm, AdminUserModel user) async {
    bool ok;
    if (user.isBanned) {
      ok = await vm.unbanUser(user.userId);
    } else {
      ok = await vm.banUser(user.userId);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? (user.isBanned ? 'User unbanned.' : 'User banned.')
              : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _changeRole(
      BuildContext context, AdminViewModel vm, AdminUserModel user, String role) async {
    final ok = await vm.setUserRole(user.userId, role);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Role updated to $role.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }
}

// ─── User tile ────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isActionLoading,
    required this.onBanToggle,
    required this.onRoleChange,
  });

  final AdminUserModel user;
  final bool isActionLoading;
  final VoidCallback onBanToggle;
  final void Function(String role) onRoleChange;

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.systemRole) {
      'admin' => AppTheme.warn,
      'expert' => AppTheme.accent,
      _ => AppTheme.muted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          _SmallAvatar(url: user.profilePicUrl, name: user.username),
          const SizedBox(width: 12),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isBanned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'BANNED',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    (user.systemRole).toUpperCase(),
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Actions menu
          if (isActionLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            )
          else
              PopupMenuButton<String>(
              color: AppTheme.card,
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.muted),
              onSelected: (val) {
                if (val == 'ban_toggle') {
                  onBanToggle();
                } else {
                  onRoleChange(val);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'ban_toggle',
                  child: Text(
                    user.isBanned ? 'Unban User' : 'Ban User',
                    style: TextStyle(
                      color: user.isBanned ? AppTheme.success : Colors.redAccent,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                _menuRoleItem('Set as User', 'user', user.systemRole),
                _menuRoleItem('Set as Expert', 'expert', user.systemRole),
                _menuRoleItem('Set as Admin', 'admin', user.systemRole),
              ],
            ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuRoleItem(String label, String role, String current) {
    final isCurrent = current == role;
    return PopupMenuItem(
      value: role,
      enabled: !isCurrent,
      child: Text(
        label,
        style: TextStyle(color: isCurrent ? AppTheme.muted : Colors.white),
      ),
    );
  }
}

// ─── Role filter chip ─────────────────────────────────────────────────────────
class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({required this.current, required this.onChanged});

  final String? current;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      color: AppTheme.card,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: current != null ? AppTheme.accent : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                size: 16, color: current != null ? AppTheme.accent : AppTheme.muted),
            const SizedBox(width: 4),
            Text(
              current?.toUpperCase() ?? 'ALL',
              style: TextStyle(
                  color: current != null ? AppTheme.accent : AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All roles')),
        const PopupMenuItem(value: 'user', child: Text('User')),
        const PopupMenuItem(value: 'expert', child: Text('Expert')),
        const PopupMenuItem(value: 'admin', child: Text('Admin')),
      ],
    );
  }
}

// ─── Small avatar ─────────────────────────────────────────────────────────────
class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.border,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.accent.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
