import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_model.dart';
import '../view_models/admin_viewmodel.dart';

const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kWarn = Color(0xFFFF6B35);
const Color _kSuccess = Color(0xFF00E676);
const Color _kMuted = Color(0xFF9E9E9E);

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
          return const Center(child: CircularProgressIndicator(color: _kAccent));
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
                        hintStyle: const TextStyle(color: _kMuted),
                        prefixIcon: const Icon(Icons.search, color: _kMuted, size: 18),
                        filled: true,
                        fillColor: _kCard,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _kAccent),
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
                color: _kAccent,
                backgroundColor: _kCard,
                onRefresh: vm.loadUsers,
                child: vm.filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found.',
                          style: TextStyle(color: _kMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: vm.filteredUsers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: _kBorder, height: 1),
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
          backgroundColor: ok ? _kCard : Colors.redAccent,
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
          backgroundColor: ok ? _kCard : Colors.redAccent,
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
      'admin' => _kWarn,
      'expert' => _kAccent,
      _ => _kMuted,
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
                          color: Colors.redAccent.withValues(alpha: 0.15),
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
                  style: const TextStyle(color: _kMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
            )
          else
            PopupMenuButton<String>(
              color: _kCard,
              icon: const Icon(Icons.more_vert_rounded, color: _kMuted),
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
                      color: user.isBanned ? _kSuccess : Colors.redAccent,
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
        style: TextStyle(color: isCurrent ? _kMuted : Colors.white),
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
      color: _kCard,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: current != null ? _kAccent : _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                size: 16, color: current != null ? _kAccent : _kMuted),
            const SizedBox(width: 4),
            Text(
              current?.toUpperCase() ?? 'ALL',
              style: TextStyle(
                  color: current != null ? _kAccent : _kMuted,
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
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: _kAccent.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: _kAccent, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
