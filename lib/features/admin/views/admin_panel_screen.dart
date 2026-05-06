import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/constants.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import '../../../widgets/admin/report_card.dart';
import '../../../widgets/common/loading_spinner.dart';
import '../models/app_user_model.dart';
import '../models/report_model.dart';

/// Admin moderation dashboard.
///
/// Data is powered by [AdminProvider] which fetches from Supabase:
///   • Total user count         → `users` table (count only)
///   • Pending report count     → `reports` WHERE status = 'pending'
///   • Reports queue            → `reports` JOIN `users` (reporter)
///   • Current admin profile    → `users` WHERE id = auth.currentUser.id
///
/// A realtime channel on the `reports` table keeps the queue live.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing dot on the system-status card.
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // [AdminProvider] auto-calls loadData() in its constructor, so data
    // starts fetching as soon as the provider is created.  If you want an
    // explicit refresh on every visit uncomment the next block:
    //
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<AdminProvider>().loadData();
    // });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, _) {
            // ── Error state ────────────────────────────────────────────
            if (adminProvider.error != null && adminProvider.reports.isEmpty) {
              return _buildErrorState(adminProvider);
            }

            // Reports fetched from Supabase already have status='pending'
            // (filtered in AdminRepository.fetchPendingReports).
            // The where() guard is kept for safety against stale local state.
            final pendingReports = adminProvider.reports
                .where((r) => r.status.toLowerCase() == 'pending')
                .toList();

            return RefreshIndicator(
              // Pull-to-refresh triggers a full re-fetch from Supabase.
              onRefresh: adminProvider.loadData,
              color: AppColors.acid,
              child: ListView(
                padding:
                    const EdgeInsets.all(AppSpacing.mdd),
                children: [
                  // ── Top bar ─────────────────────────────────────────
                  // currentAdminUser is resolved from
                  // `users` WHERE id = auth.currentUser.id
                  _AdminTopBar(
                    adminUser: adminProvider.currentAdminUser,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── KPI stat cards ──────────────────────────────────
                  // userCount  → SELECT count(*) FROM users
                  // reports    → SELECT count(*) FROM reports WHERE status='pending'
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.24,
                    children: [
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.adminUsers),
                        child: AdminStatCard(
                          label: 'Total Users',
                          value: adminProvider.isLoading
                              ? '—'
                              : '${adminProvider.userCount}',
                          icon: Icons.groups_rounded,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.adminReports),
                        child: AdminStatCard(
                          label: 'Active Reports',
                          value: adminProvider.isLoading
                              ? '—'
                              : '${pendingReports.length}',
                          icon: Icons.flag_rounded,
                          variant: pendingReports.isNotEmpty
                              ? AdminStatVariant.warning
                              : AdminStatVariant.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Platform status ─────────────────────────────────
                  _buildSystemStatusCard(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Action queue header ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ACTION QUEUE',
                          style: AppTextStyles.displayMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${pendingReports.length} FLAGGED',
                          style: AppTextStyles.monoSmall
                              .copyWith(color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Loading indicator ───────────────────────────────
                  if (adminProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: Center(child: LoadingSpinner()),
                    ),

                  // ── Empty state ─────────────────────────────────────
                  if (!adminProvider.isLoading && pendingReports.isEmpty)
                    _buildEmptyState()
                  else
                    // ── Report cards ──────────────────────────────────
                    // Each ReportCard gets reporter info directly from the
                    // Report model (populated via the Supabase JOIN).
                    ...pendingReports.map(
                      (report) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReportCard(
                          report: report,
                          onTap: () => context.push(
                            AppRoutes.adminContentDetail(report.contentId),
                          ),
                          onApprove: () => _handleApprove(report),
                          onReject: () => _handleReject(report),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.acid,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLATFORM STATUS', style: AppTextStyles.monoLabel),
                const SizedBox(height: AppSpacing.xxs),
                Text('All Systems Nominal',
                    style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Icon(Icons.shield_outlined, color: AppColors.acid),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.acid, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No flagged items are waiting for review.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminProvider adminProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load admin data',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              adminProvider.error ?? 'Unknown error',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: adminProvider.loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acid,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────────────────

  /// Approves a report:
  ///   UPDATE reports SET status = 'approved' WHERE id = [report.id]
  Future<void> _handleApprove(Report report) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AdminProvider>().approveReport(report.id);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Report approved and removed from queue.'),
      ),
    );
  }

  /// Rejects a report after user confirmation:
  ///   UPDATE reports SET status = 'rejected' WHERE id = [report.id]
  Future<void> _handleReject(Report report) async {
    final messenger = ScaffoldMessenger.of(context);
    final adminProvider = context.read<AdminProvider>();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Reject report'),
            content: const Text(
                'Are you sure you want to dismiss this flagged item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child:
                    Text('Reject', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await adminProvider.rejectReport(report.id);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Report dismissed.')),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────

/// Admin dashboard header.
///
/// [adminUser] is the currently signed-in admin's profile row from
/// `users` WHERE id = auth.currentUser.id — fetched in [AdminProvider].
class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({required this.adminUser});

  final AppUser? adminUser;

  @override
  Widget build(BuildContext context) {
    final username = adminUser?.username ?? '…';
    final avatarUrl = adminUser?.avatarUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.steel,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AURAGAINS ADMIN',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text('Moderation command center',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          // Admin avatar — populated from `users.avatar_url`
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.acidBg,
            backgroundImage: avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    username.isNotEmpty
                        ? username[0].toUpperCase()
                        : 'A',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.white),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
