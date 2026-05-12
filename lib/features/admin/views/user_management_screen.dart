import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:auragains/features/admin/admin_palette.dart';
import '../../../core/services/database_connection.dart';
import '../models/app_user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _client = DatabaseConnection.client;
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _error;
  RealtimeChannel? _channel;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Avoid server-side ORDER BY on `created_at` (some PostgREST setups
      // can produce "column user.created_at does not exist"). Fetch rows
      // unsorted and sort in Dart to keep behaviour consistent without
      // changing the database.
      final rows = await _client.from('user').select();
      final rowsList = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      rowsList.sort((a, b) {
        final aDt = DateTime.tryParse((a['created_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDt = DateTime.tryParse((b['created_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDt.compareTo(aDt); // newest-first
      });

      setState(() {
        _users = rowsList.map((r) => AppUser.fromSupabase(r)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('user-management-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user',
          callback: (_) => _loadUsers(),
        )
        .subscribe();
  }

  Future<void> _updateRole(AppUser user, String newRole) async {
    try {
      await _client
          .from('user')
          .update({'system_role': newRole})
          .eq('user_id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _toggleBan(AppUser user) async {
    final isBanned = user.level.contains('banned');
    try {
      await _client
          .from('user')
          .update({'is_banned': !isBanned})
          .eq('user_id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} ${isBanned ? 'unbanned' : 'banned'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute filtered users based on search + role filter
    final filtered = _users.where((u) {
      // Role filter
      final roleMatch = _selectedRoleFilter == 'all' || u.role == _selectedRoleFilter;
      // Search filter (username or email)
      final q = _searchQuery.trim().toLowerCase();
      final searchMatch = q.isEmpty || u.username.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
      return roleMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('User Management', style: AppTextStyles.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.bodyMedium))
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length + 1, // +1 for header (search + filters)
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: AppTextStyles.bodyLarge,
                              decoration: InputDecoration(
                                hintText: 'Search by name or email',
                                hintStyle: AppTextStyles.bodySmall,
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Role filter buttons (All | User | Expert | Admin)
                            Row(
                              children: [
                                Expanded(child: _buildFilterButton('All', 'all')),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: _buildFilterButton('User', 'gym_member')),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: _buildFilterButton('Expert', 'expert')),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: _buildFilterButton('Admin', 'admin')),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        );
                      }

                      final user = filtered[index - 1];
                      return _buildUserTile(user);
                    },
                  ),
                ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + Name
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) as ImageProvider : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(user.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Joined: ${_formatDate(user.createdAt)}', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),

              // Role (top-right)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withOpacity(0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  _roleLabel(user.role),
                  style: AppTextStyles.labelSmall.copyWith(color: _roleColor(user.role), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action Row: Edit (Change Role) | Ban
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showRoleDialog(user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change Role'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _toggleBan(user),
                icon: const Icon(Icons.block, size: 16, color: AppColors.warn),
                label: Text(user.level.contains('banned') ? 'Unban' : 'Ban', style: TextStyle(color: AppColors.warn)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.warn.withOpacity(0.25))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildFilterButton(String label, String roleValue) {
    final selected = _selectedRoleFilter == roleValue;
    if (selected) {
      return ElevatedButton(
        onPressed: () => setState(() => _selectedRoleFilter = roleValue),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
        child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: Colors.black)),
      );
    }

    return OutlinedButton(
      onPressed: () => setState(() => _selectedRoleFilter = roleValue),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border)),
      child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted)),
    );
  }

  void _showRoleDialog(AppUser user) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Change Role'),
          children: [
            SimpleDialogOption(
              child: const Text('Member'),
              onPressed: () {
                Navigator.pop(context);
                _updateRole(user, 'gym_member');
              },
            ),
            SimpleDialogOption(
              child: const Text('Expert'),
              onPressed: () {
                Navigator.pop(context);
                _updateRole(user, 'expert');
              },
            ),
            SimpleDialogOption(
              child: const Text('Admin'),
              onPressed: () {
                Navigator.pop(context);
                _updateRole(user, 'admin');
              },
            ),
            SimpleDialogOption(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'expert':
        return 'Expert';
      default:
        return 'User';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'expert':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
}
