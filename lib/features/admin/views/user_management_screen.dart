import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/constants.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
        final rows = await _client
          .from('user')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _users = (rows as List).map((r) => AppUser.fromSupabase(r as Map<String, dynamic>)).toList();
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
                    itemCount: _users.length,
                    itemBuilder: (context, index) => _buildUserTile(_users[index]),
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
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: AppTextStyles.bodyLarge),
                Text(user.email, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor(user.role).withAlpha(30),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    user.role,
                    style: AppTextStyles.caption.copyWith(color: _roleColor(user.role)),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surfaceVariant,
            onSelected: (value) {
              if (value == 'ban') {
                _toggleBan(user);
              } else {
                _updateRole(user, value);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'gym_member', child: Text('Set: Member')),
              const PopupMenuItem(value: 'expert', child: Text('Set: Expert')),
              const PopupMenuItem(value: 'admin', child: Text('Set: Admin')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'ban', child: Text('Toggle Ban')),
            ],
          ),
        ],
      ),
    );
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
