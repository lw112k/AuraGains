import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../models/trainer_application_model.dart';
import '../view_models/applications_viewmodel.dart';

import 'verify_trainer_screen.dart';

/// Admin screen for reviewing trainer-verification applications.
///
/// Wraps itself in a local [ChangeNotifierProvider<ApplicationsViewModel>] so
/// it is fully self-contained and requires no changes to main.dart.
///
/// Data sources (all via [ApplicationsViewModel] → [AdminRepository] → Supabase):
///   • Application list  → `trainer_applications` (all statuses, newest-first)
///   • Approve action    → `trainer_applications.status = 'approved'`
///                         + `users.role = 'expert'`
///   • Reject action     → `trainer_applications.status = 'rejected'`
///   • Realtime updates  → Postgres-changes channel on `trainer_applications`
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApplicationsViewModel(),
      child: const _ApplicationsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private stateful view — owns the selected-tab index
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationsView extends StatefulWidget {
  const _ApplicationsView();

  @override
  State<_ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends State<_ApplicationsView> {
  int _selectedTab = 0;

  // ── Filtering helpers ────────────────────────────────────────────────────────

  List<TrainerApplication> _filtered(List<TrainerApplication> all) {
    switch (_selectedTab) {
      case 1:
        // Pending tab — only rows with status 'pending'.
        // NOTE: the prototype also matched 'review' here, but 'review' is not
        // a valid DB status (schema: pending | approved | rejected).
        return all
            .where((a) => a.status.toLowerCase() == 'pending')
            .toList();
      case 2:
        // Approved tab.
        return all
            .where((a) => a.status.toLowerCase() == 'approved')
            .toList();
      case 0:
      default:
        return all;
    }
  }

  List<String> _tabLabels(List<TrainerApplication> all) {
    final pendingCount =
        all.where((a) => a.status.toLowerCase() == 'pending').length;
    final approvedCount =
        all.where((a) => a.status.toLowerCase() == 'approved').length;
    return [
      'All (${all.length})',
      'Pending ($pendingCount)',
      'Approved ($approvedCount)',
    ];
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _approve(BuildContext context, TrainerApplication application) async {
    final vm = context.read<ApplicationsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Approves in `trainer_applications` AND promotes `users.role` to 'expert'
      await vm.approveApplication(application.id, application.userId);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '${application.fullName} approved as expert trainer.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error approving application: $e')),
      );
    }
  }

  Future<void> _decline(BuildContext context, TrainerApplication application) async {
    final vm = context.read<ApplicationsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    // Confirmation dialog — preserves the prototype's UX exactly.
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Decline application',
                style: AppTextStyles.labelLarge),
            content: Text(
              'Decline ${application.fullName.isNotEmpty ? application.fullName : 'this applicant'}\'s application?',
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
                child: Text('Decline',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      // Sets `trainer_applications.status = 'rejected'`
      await vm.rejectApplication(application.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Application declined.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error declining application: $e')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // ── AppBar (app_navbar.dart is currently empty — using AppBar directly) ──
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: AppIconSizes.md),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('APPLICATIONS', style: AppTextStyles.displaySmall),
        centerTitle: false,
      ),
      body: Consumer<ApplicationsViewModel>(
        builder: (context, vm, _) {
          // ── Error state ────────────────────────────────────────────────────
          if (vm.error != null && !vm.isLoading && vm.applications.isEmpty) {
            return _buildErrorState(vm);
          }

          final all      = vm.applications;
          final filtered = _filtered(all);
          final labels   = _tabLabels(all);

          return RefreshIndicator(
            // Pull-to-refresh re-fetches all rows from `trainer_applications`
            onRefresh: vm.loadApplications,
            color: AppColors.acid,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.mdd),
              children: [
                _buildFilterTabs(labels),
                const SizedBox(height: AppSpacing.md),
                // ── Loading indicator ──────────────────────────────────────
                if (vm.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.acid),
                    ),
                  ),
                // ── Empty state ────────────────────────────────────────────
                if (!vm.isLoading && filtered.isEmpty)
                  _buildEmptyState()
                else
                  ...filtered.map(
                    (application) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ApplicationCard(
                        application: application,
                        isProcessing: vm.isProcessing(application.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerifyTrainerScreen(
                                applicationId: application.id),
                          ),
                        ),
                        onApproveTap: () =>
                            _approve(context, application),
                        onDeclineTap: () =>
                            _decline(context, application),
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

  // ── Filter tab bar ──────────────────────────────────────────────────────────

  Widget _buildFilterTabs(List<String> labels) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.mid,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                // AppCurves.standard does not exist in constants.dart —
                // using Curves.easeInOut as the equivalent.
                duration: AppDurations.normal,
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected ? AppColors.acid : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

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
          const Icon(Icons.assignment_turned_in_outlined,
              color: AppColors.acid, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No applications match the selected filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(ApplicationsViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load applications',
                style: AppTextStyles.labelLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              vm.error ?? 'Unknown error',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: vm.loadApplications,
              style: AppButtonStyles.primary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail dialog (temporary until VerifyTrainerScreen is built) ────────────

  void _showDetailDialog(
      BuildContext context, TrainerApplication application) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(application.fullName, style: AppTextStyles.labelLarge),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Email',          application.email),
              _DetailRow('Specialization', application.specialization),
              _DetailRow('Experience',
                  '${application.yearsExperience} yrs'),
              _DetailRow('Status',         application.status),
              if (application.bio.isNotEmpty)
                _DetailRow('Bio', application.bio),
            ],
          ),
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
// Private application card widget
// (ApplicationCard from widgets/admin/ does not exist — built inline here)
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
    required this.onApproveTap,
    required this.onDeclineTap,
    this.isProcessing = false,
  });

  final TrainerApplication application;
  final VoidCallback onTap;
  final VoidCallback onApproveTap;
  final VoidCallback onDeclineTap;
  final bool isProcessing;

  // Status pill colour
  Color get _statusColor => switch (application.status.toLowerCase()) {
        'approved' => AppColors.acid,
        'rejected' => AppColors.error,
        _          => AppColors.warning,       // 'pending' and anything else
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Avatar placeholder — initials fallback
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.steel,
                  child: Text(
                    application.fullName.isNotEmpty
                        ? application.fullName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.fullName,
                          style: AppTextStyles.labelMedium),
                      Text(application.email,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(
                    application.status.toUpperCase(),
                    style: AppTextStyles.monoSmall
                        .copyWith(color: _statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // ── Details row ────────────────────────────────────────────────
            Wrap(
              spacing: AppSpacing.md,
              children: [
                _Chip(
                    Icons.fitness_center_rounded,
                    application.specialization),
                _Chip(
                    Icons.timer_outlined,
                    '${application.yearsExperience} yrs exp'),
                if (application.gender.isNotEmpty)
                  _Chip(Icons.person_outline_rounded,
                      application.gender),
              ],
            ),
            if (application.bio.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                application.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // ── Action buttons ─────────────────────────────────────────────
            // Only show action buttons when the application is still pending.
            if (application.status.toLowerCase() == 'pending')
              isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.acid,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDeclineTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side:
                                  const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.buttonBorder),
                            ),
                            child: Text('Decline',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.error)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onApproveTap,
                            style: AppButtonStyles.primary.copyWith(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                              ),
                            ),
                            child: Text('Approve',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.white)),
                          ),
                        ),
                      ],
                    )
            else
              // Read-only view button for resolved applications
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: AppButtonStyles.ghost.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.muted, size: AppIconSizes.xs),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

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
            width: 100,
            child:
                Text('$label:', style: AppTextStyles.monoSmall),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
