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
            // ─ Search + inline role buttons ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Role filter buttons row
                  Row(
                    children: [
                      Expanded(
                        child: _RoleFilterBtn(
                          label: 'All',
                          value: 'All',
                          current: vm.userRoleFilter,
                          onTap: (v) => vm.setUserRoleFilter(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoleFilterBtn(
                          label: 'User',
                          value: 'User',
                          current: vm.userRoleFilter,
                          onTap: (v) => vm.setUserRoleFilter(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoleFilterBtn(
                          label: 'Expert',
                          value: 'Expert',
                          current: vm.userRoleFilter,
                          onTap: (v) => vm.setUserRoleFilter(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoleFilterBtn(
                          label: 'Admin',
                          value: 'Admin',
                          current: vm.userRoleFilter,
                          onTap: (v) => vm.setUserRoleFilter(v),
                        ),
                      ),
                    ],
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
                        separatorBuilder: (_, __) =>
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0,2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallAvatar(url: user.profilePicUrl, name: user.username),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Role pill on the top-right
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: roleColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    (user.systemRole).toUpperCase(),
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Email (primary) and email again (replaced Joined date with email)
            Text(user.email, style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(color: Colors.white, fontSize: 12)),

            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Show role dialog
                    final chosen = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Change Role'),
                        children: [
                          SimpleDialogOption(child: const Text('User'), onPressed: () => Navigator.pop(ctx, 'user')),
                          SimpleDialogOption(child: const Text('Expert'), onPressed: () => Navigator.pop(ctx, 'expert')),
                          SimpleDialogOption(child: const Text('Admin'), onPressed: () => Navigator.pop(ctx, 'admin')),
                          SimpleDialogOption(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, null)),
                        ],
                      ),
                    );
                    if (chosen != null) onRoleChange(chosen);
                  },
                  icon: Icon(Icons.edit, size: 14, color: Colors.black),
                  label: Text('Change Role', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onBanToggle,
                  icon: Icon(user.isBanned ? Icons.lock_open : Icons.block, size: 14, color: user.isBanned ? AppTheme.success : Colors.redAccent),
                  label: Text(user.isBanned ? 'Unban' : 'Ban', style: TextStyle(color: user.isBanned ? AppTheme.success : Colors.redAccent)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: (user.isBanned ? AppTheme.success : Colors.redAccent).withOpacity(0.25))),
                ),
                const Spacer(),
                if (isActionLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role filter button ─────────────────────────────────────────────────────
class _RoleFilterBtn extends StatelessWidget {
  const _RoleFilterBtn({required this.label, required this.value, required this.current, required this.onTap});

  final String label;
  final String value;
  final String current;
  final void Function(String?) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    if (selected) {
      return ElevatedButton(
        onPressed: () => onTap(value),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
        child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
      );
    }

    return OutlinedButton(
      onPressed: () => onTap(value),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.border)),
      child: Text(label, style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600, fontSize: 12)),
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
        onBackgroundImageError: (_, __) {},
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

String _formatDate(DateTime? d) {
  if (d == null) return 'Unknown';
  final y = d.year.toString();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
