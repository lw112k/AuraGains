import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../models/app_user_model.dart';
import '../view_models/user_management_viewmodel.dart';

// NOTES ON PROTOTYPE DIFFERENCES:
// • cached_network_image  — NOT in pubspec.yaml → NetworkImage / Image.network used.
// • go_router / context.push/pop — NOT in pubspec → Navigator.of(context)
// • AppNavBar             — currently an empty file → AppBar used directly
// • LoadingSpinner        — currently an empty file → CircularProgressIndicator
// • AppInputDecoration.adminSearch / .standard — don't exist → built inline
// • AppRadius.xl          — doesn't exist → 16.0 used (closest value)
// • AppRoutes.userProfile — go_router route, doesn't exist → TODO detail dialog
// • User.name             — AppUser has only `username`, no `name` field
// • User.avatar           — AppUser field is `avatarUrl`
// • User.isVerified       — doesn't exist; AppUser.isExpert (role == 'expert') used
// • AdminProvider         — doesn't exist → UserManagementViewModel

/// Admin user-management surface for filtering and moderating accounts.
///
/// Wraps itself in a local [ChangeNotifierProvider<UserManagementViewModel>]
/// so it is fully self-contained — no changes to main.dart are required.
///
/// Data sources (all via [UserManagementViewModel] → [AdminRepository] → Supabase):
///   User list        → `users` (all rows, newest-first)
///   Suspend action   → `users.level = 'suspended: <reason>'`
///   Ban action       → `users.level = 'banned'`
///   Grant expert     → `users.role = 'expert'`
///   Revoke expert    → `users.role = 'gym_member'`
///   Realtime updates → Postgres-changes channel on `users`
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserManagementViewModel(),
      child: const _UserManagementView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private stateful view — owns search query, filter, and visible-count state
// ─────────────────────────────────────────────────────────────────────────────

class _UserManagementView extends StatefulWidget {
  const _UserManagementView();

  @override
  State<_UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<_UserManagementView> {
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All Users';
  int _visibleCount = 8;
  bool _isLoadingMore = false;

  static const List<String> _filters = [
    'All Users',
    'Active',
    'Suspended',
    'Verified Experts',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  // ── Infinite scroll ──────────────────────────────────────────────────────────

  void _handleScroll() {
    if (_isLoadingMore || !_scrollController.hasClients) return;

    final total =
        _filtered(context.read<UserManagementViewModel>().users).length;
    if (_visibleCount >= total) return;

    final trigger = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= trigger) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    // Small delay to show the loading indicator — no extra network call
    // because all users are already in memory.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _visibleCount += 6;
      _isLoadingMore = false;
    });
  }

  // ── Filtering helpers ────────────────────────────────────────────────────────

  List<AppUser> _filtered(List<AppUser> users) {
    return users.where((user) {
      // Search across username and email — prototype also searched `user.name`
      // which doesn't exist; `username` is the display identifier.
      final haystack =
          '${user.username} ${user.email}'.toLowerCase();
      final searchMatch = _searchQuery.trim().isEmpty ||
          haystack.contains(_searchQuery.toLowerCase());

      final status = _statusForUser(user);
      final filterMatch = switch (_selectedFilter) {
        'Active'           => status == 'Active',
        'Suspended'        => status == 'Suspended',
        'Verified Experts' => status == 'Expert',
        _                  => true,
      };

      return searchMatch && filterMatch;
    }).toList();
  }

  /// Derives a display-status string from an [AppUser]'s `level` and `role`.
  ///
  /// Mirrors the prototype's `_statusForUser` logic, adapted for [AppUser]:
  ///   • `level` containing 'suspended' or 'banned' → 'Suspended'
  ///   • `role == 'expert'` (isExpert)               → 'Expert'
  ///   • otherwise                                    → 'Active'
  String _statusForUser(AppUser user) {
    final level = user.level.toLowerCase();
    if (level.contains('suspended') || level.contains('banned')) {
      return 'Suspended';
    }
    // Prototype used user.isVerified — AppUser.isExpert (role == 'expert') is
    // the real-model equivalent.
    if (user.isExpert) return 'Expert';
    return 'Active';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // AppNavBar is currently an empty file — using AppBar directly.
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: AppIconSizes.md),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('USER MANAGEMENT', style: AppTextStyles.displaySmall),
        centerTitle: false,
      ),
      body: Consumer<UserManagementViewModel>(
        builder: (context, vm, _) {
          // ── Error state (no data yet) ─────────────────────────────────
          if (vm.error != null && vm.users.isEmpty) {
            return _buildErrorState(vm);
          }

          final filtered = _filtered(vm.users);
          final visible  = filtered
              .take(math.min(_visibleCount, filtered.length))
              .toList();

          return RefreshIndicator(
            // Pull-to-refresh re-fetches all rows from `users`.
            onRefresh: vm.loadUsers,
            color: AppColors.acid,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.mdd),
              children: [
                // ── Search field ───────────────────────────────────────
                // AppInputDecoration.adminSearch() doesn't exist —
                // building InputDecoration inline.
                TextField(
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _visibleCount = 8;
                  }),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search by username or email',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.muted, size: AppIconSizes.md),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _searchQuery = ''),
                            child: const Icon(Icons.clear_rounded,
                                color: AppColors.muted,
                                size: AppIconSizes.md),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.steel,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.inputBorder,
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.inputBorder,
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.inputBorder,
                      borderSide:
                          const BorderSide(color: AppColors.acid),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // ── Filter row ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filtered.length} user${filtered.length == 1 ? '' : 's'}',
                        style: AppTextStyles.monoSmall,
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _selectedFilter,
                      color: AppColors.card,
                      onSelected: (value) => setState(() {
                        _selectedFilter = value;
                        _visibleCount = 8;
                      }),
                      itemBuilder: (context) => _filters
                          .map(
                            (item) => PopupMenuItem<String>(
                              value: item,
                              child: Text(item,
                                  style: AppTextStyles.bodyMedium),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedFilter,
                                style: AppTextStyles.monoSmall),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.acid),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // ── Initial loading indicator ─────────────────────────
                if (vm.isLoading && vm.users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.acid),
                    ),
                  ),
                // ── Empty state ───────────────────────────────────────
                if (!vm.isLoading && visible.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadius.cardBorder,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'No users match the current search or filter.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else
                  ...visible.map(
                    (user) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _UserRow(
                        user: user,
                        status: _statusForUser(user),
                        isProcessing: vm.isProcessing(user.id),
                        // TODO: Replace with Navigator.push to user profile
                        // screen once a teammate builds it.
                        onTap: () => _showUserDetailDialog(context, user),
                        onActionSelected: (action) =>
                            _handleAction(context, action, user, vm),
                      ),
                    ),
                  ),
                // ── Load-more footer ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: _isLoadingMore
                        ? const CircularProgressIndicator(
                            color: AppColors.acid)
                        : Text(
                            visible.length < filtered.length
                                ? 'Scroll to load more'
                                : vm.users.isNotEmpty
                                    ? 'End of user list'
                                    : '',
                            style: AppTextStyles.monoSmall,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(UserManagementViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load users',
                style: AppTextStyles.labelLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(vm.error ?? 'Unknown error',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: vm.loadUsers,
              style: AppButtonStyles.primary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action dispatcher ────────────────────────────────────────────────────────

  Future<void> _handleAction(
    BuildContext context,
    String action,
    AppUser user,
    UserManagementViewModel vm,
  ) async {
    switch (action) {
      case 'view':
        // TODO: Replace with Navigator.push to user profile screen once built.
        if (!mounted) return;
        _showUserDetailDialog(context, user);
      case 'suspend':
        await _showSuspendSheet(context, user, vm);
      case 'ban':
        await _confirmBan(context, user, vm);
      case 'grant':
        await _confirmBadgeUpdate(context, user, vm, grant: true);
      case 'revoke':
        await _confirmBadgeUpdate(context, user, vm, grant: false);
    }
  }

  // ── Suspend bottom sheet ─────────────────────────────────────────────────────

  Future<void> _showSuspendSheet(
    BuildContext context,
    AppUser user,
    UserManagementViewModel vm,
  ) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String duration = '7 days';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        // AppRadius.xl doesn't exist — 16.0 is the closest logical value
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.mdd,
                AppSpacing.mdd,
                AppSpacing.mdd,
                MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppSpacing.mdd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prototype used user.name — AppUser has `username` only
                  Text(
                    'Suspend @${user.username}',
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PopupMenuButton<String>(
                    initialValue: duration,
                    color: AppColors.card,
                    onSelected: (value) =>
                        setModalState(() => duration = value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: '3 days', child: Text('3 days')),
                      PopupMenuItem(
                          value: '7 days', child: Text('7 days')),
                      PopupMenuItem(
                          value: '30 days', child: Text('30 days')),
                    ],
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.steel,
                        borderRadius: AppRadius.cardBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Duration: $duration',
                                style: AppTextStyles.bodyMedium),
                          ),
                          const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.acid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // AppInputDecoration.standard() doesn't exist — inline.
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Reason for suspension',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.steel,
                      contentPadding:
                          const EdgeInsets.all(AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.inputBorder,
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputBorder,
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.inputBorder,
                        borderSide:
                            const BorderSide(color: AppColors.acid),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final reason =
                            '${controller.text.trim()} ($duration)';
                        // Pop the sheet before the async call to avoid
                        // using a stale sheetContext.
                        Navigator.of(sheetContext).pop();
                        try {
                          await vm.suspendUser(user.id, reason);
                          if (!context.mounted) return;
                          messenger.showSnackBar(SnackBar(
                              content: Text(
                                  '@${user.username} suspended.')));
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(SnackBar(
                              content: Text('Error: $e')));
                        }
                      },
                      style: AppButtonStyles.danger,
                      child: const Text('Confirm Suspension'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  // ── Ban dialog ───────────────────────────────────────────────────────────────

  Future<void> _confirmBan(
    BuildContext context,
    AppUser user,
    UserManagementViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Ban user', style: AppTextStyles.labelLarge),
            content: Text(
              'Permanently restrict @${user.username}? This cannot be undone from this screen.',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false),
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true),
                child: Text('Ban',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await vm.banUser(user.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('@${user.username} banned.')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Grant / revoke expert badge dialog ───────────────────────────────────────

  Future<void> _confirmBadgeUpdate(
    BuildContext context,
    AppUser user,
    UserManagementViewModel vm, {
    required bool grant,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              grant ? 'Grant expert badge' : 'Revoke expert badge',
              style: AppTextStyles.labelLarge,
            ),
            content: Text(
              grant
                  ? 'Grant verified expert status to @${user.username}?'
                  : 'Revoke verified expert status from @${user.username}?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false),
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true),
                child: Text(
                  grant ? 'Grant' : 'Revoke',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.acid),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      if (grant) {
        await vm.grantExpertBadge(user.id);
      } else {
        await vm.revokeExpertBadge(user.id);
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(grant
              ? 'Expert badge granted to @${user.username}.'
              : 'Expert badge revoked from @${user.username}.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Temporary user-detail dialog ─────────────────────────────────────────────
  // TODO: Replace with Navigator.push to the real user-profile screen once a
  //       teammate builds it. This stub keeps the tap action non-destructive.

  void _showUserDetailDialog(BuildContext context, AppUser user) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('@${user.username}', style: AppTextStyles.labelLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Email',  user.email),
            _DetailRow('Role',   user.role),
            _DetailRow('Level',  user.level.isNotEmpty ? user.level : '—'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UserRow — individual user list tile
// ─────────────────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.status,
    required this.onTap,
    required this.onActionSelected,
    this.isProcessing = false,
  });

  final AppUser user;
  final String status;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;
  final bool isProcessing;

  Color get _accent => switch (status) {
        'Suspended' => AppColors.orange,
        'Expert'    => AppColors.acid,
        _           => AppColors.white,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: AppRadius.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              // ── Avatar ───────────────────────────────────────────────
              // cached_network_image not in pubspec — using NetworkImage.
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mid,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl)
                    : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.labelSmall,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              // ── Name + email ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prototype used user.name — AppUser only has username.
                    Text(user.username, style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(user.email, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // ── Status pill ──────────────────────────────────────────
              if (isProcessing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.acid,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: AppTextStyles.monoLabel
                        .copyWith(color: _accent),
                  ),
                ),
              // ── Action menu ──────────────────────────────────────────
              PopupMenuButton<String>(
                color: AppColors.card,
                enabled: !isProcessing,
                onSelected: onActionSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'view',
                      child: Text('View Profile')),
                  PopupMenuItem(
                      value: 'suspend',
                      child: Text('Suspend User')),
                  PopupMenuItem(
                      value: 'ban',
                      child: Text('Ban User')),
                  PopupMenuItem(
                      value: 'grant',
                      child: Text('Grant Expert Badge')),
                  PopupMenuItem(
                      value: 'revoke',
                      child: Text('Revoke Expert Badge')),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: isProcessing
                        ? AppColors.muted
                        : AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow — small label/value row used in the user detail dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text('$label:', style: AppTextStyles.monoSmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
