import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../models/app_user_model.dart';
import '../models/post_model.dart';
import '../models/report_model.dart';
import '../view_models/content_detail_viewmodel.dart';

// NOTE: cached_network_image is NOT in pubspec.yaml — Image.network is used
// with an errorBuilder to replicate the same fallback UX.

// NOTE: AppNavBar (app_navbar.dart) is currently an empty file — using
// AppBar directly, matching the same workaround used in ApplicationsScreen.

/// Detailed moderation view for a flagged piece of content.
///
/// Wraps itself in a local [ChangeNotifierProvider<ContentDetailViewModel>]
/// so it is fully self-contained. No changes to main.dart are required.
///
/// Data sources (all via [ContentDetailViewModel] → [AdminRepository] → Supabase):
///   Post data       → `posts` (fetched by [postId])
///   Report data     → `reports` joined with reporter user profile
///   Author profile  → `users` (by post.userId)
///   Reporter profile → `users` (by report.reporterId)
///   Delete action   → hard-deletes `posts` row + marks report 'approved'
///   Approve action  → marks `reports.status = 'rejected'` (content cleared)
///   Suspend action  → sets `users.level = 'suspended: <reason>'`
class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentDetailViewModel(postId: postId),
      child: const _ContentDetailView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private stateful view — owns _showFullCaption toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ContentDetailView extends StatefulWidget {
  const _ContentDetailView();

  @override
  State<_ContentDetailView> createState() => _ContentDetailViewState();
}

class _ContentDetailViewState extends State<_ContentDetailView> {
  bool _showFullCaption = false;

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
        title: Text('CONTENT DETAIL', style: AppTextStyles.displaySmall),
        centerTitle: false,
      ),
      body: Consumer<ContentDetailViewModel>(
        builder: (context, vm, _) {
          // ── Initial / full-screen loading ───────────────────────────────
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.acid),
            );
          }

          // ── Error state ────────────────────────────────────────────────
          if (vm.error != null && vm.post == null) {
            return _buildErrorState(vm);
          }

          // ── Post deleted (after admin action) ──────────────────────────
          if (vm.post == null) {
            return Center(
              child: Text(
                'Content not found.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
              ),
            );
          }

          final post     = vm.post!;
          final report   = vm.report;
          final author   = vm.author;
          final reporter = vm.reporter;

          return RefreshIndicator(
            onRefresh: vm.loadAll,
            color: AppColors.acid,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.mdd),
              children: [
                _buildContentPreview(post, author),
                const SizedBox(height: AppSpacing.md),
                _buildCaptionSection(post),
                const SizedBox(height: AppSpacing.md),
                _buildMetricsGrid(post),
                const SizedBox(height: AppSpacing.md),
                _buildReportSummary(report),
                const SizedBox(height: AppSpacing.md),
                _buildReporterSection(reporter, report),
                const SizedBox(height: AppSpacing.lg),
                // Per-action loading indicator replaces full LoadingSpinner.
                if (vm.isActionInProgress)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.acid),
                    ),
                  ),
                _buildActionButtons(context, vm, post, author),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(ContentDetailViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load content',
                style: AppTextStyles.labelLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(vm.error ?? 'Unknown error',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: vm.loadAll,
              style: AppButtonStyles.primary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content preview card (image + title + author + tags) ────────────────────

  Widget _buildContentPreview(PostModel post, AppUser? author) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Media preview ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card)),
            child: AspectRatio(
              aspectRatio: 1.15,
              child: post.imageUrl.isNotEmpty
                  // cached_network_image is not in pubspec.yaml —
                  // using Image.network with error/loading fallbacks instead.
                  ? Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.mid,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                              color: AppColors.acid),
                        );
                      },
                      errorBuilder: (context, _, __) => Container(
                        color: AppColors.mid,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.muted,
                          size: AppIconSizes.xl,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.mid,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                        size: AppIconSizes.xl,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // author?.username falls back to '@unknown' matching prototype
                  '@${author?.username ?? 'unknown'}',
                  style: AppTextStyles.monoSmall
                      .copyWith(color: AppColors.acid),
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: post.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.acidBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.monoSmall
                                  .copyWith(color: AppColors.acid),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Caption / description section ────────────────────────────────────────────

  Widget _buildCaptionSection(PostModel post) {
    final shouldTruncate = post.caption.length > 120;
    final text = !_showFullCaption && shouldTruncate
        ? '${post.caption.substring(0, 120)}...'
        : post.caption;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAPTION', style: AppTextStyles.monoLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: AppTextStyles.bodyMedium),
          if (shouldTruncate) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () =>
                  setState(() => _showFullCaption = !_showFullCaption),
              child: Text(
                _showFullCaption ? 'Show less' : 'Read more',
                style: AppTextStyles.monoSmall
                    .copyWith(color: AppColors.acid),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Metrics grid (Likes / Comments / Saves) ──────────────────────────────────
  // NOTE: The prototype included 'Shares' but the DB schema has no shares_count
  // column. Three metrics are shown (matched to real DB columns).

  Widget _buildMetricsGrid(PostModel post) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      children: [
        _MetricCard(label: 'Likes',    value: '${post.likesCount}'),
        _MetricCard(label: 'Comments', value: '${post.commentsCount}'),
        _MetricCard(label: 'Saves',    value: '${post.savesCount}'),
      ],
    );
  }

  // ── Report summary card ──────────────────────────────────────────────────────

  Widget _buildReportSummary(Report? report) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.orangeBg,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPORT SUMMARY',
            style: AppTextStyles.monoLabel
                .copyWith(color: AppColors.orange),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // DB schema has `reason` — no separate `description` column.
            // prototype's report.reason maps directly; prototype's
            // report.description is the same field used as a fallback.
            report?.reason.isNotEmpty == true
                ? report!.reason
                : 'Flagged content',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report?.reason.isNotEmpty == true
                ? 'This content has been reported by a community member and requires moderation review.'
                : 'Content has been flagged for review by the moderation team.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Reporter section ─────────────────────────────────────────────────────────

  Widget _buildReporterSection(AppUser? reporter, Report? report) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.mid,
            // Image.network as fallback — cached_network_image not in pubspec.
            backgroundImage: reporter?.avatarUrl.isNotEmpty == true
                ? NetworkImage(reporter!.avatarUrl)
                : null,
            child: reporter?.avatarUrl.isEmpty != false
                ? Text(
                    (reporter?.username.isNotEmpty == true
                            ? reporter!.username[0]
                            : 'R')
                        .toUpperCase(),
                    style: AppTextStyles.labelSmall,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reported by', style: AppTextStyles.monoLabel),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '@${reporter?.username ?? 'unknown'}',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  report != null
                      ? '${report.reportedAt.day}/${report.reportedAt.month}/${report.reportedAt.year}'
                      : 'Unknown date',
                  style: AppTextStyles.monoSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    ContentDetailViewModel vm,
    PostModel post,
    AppUser? author,
  ) {
    final disabled = vm.isActionInProgress;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: disabled ? null : () => _confirmDelete(context, vm),
                style: AppButtonStyles.ghost,
                child: vm.isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Delete'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: disabled ? null : () => _confirmApprove(context, vm),
                style: AppButtonStyles.primary,
                child: vm.isApproving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Approve'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : () => _showSuspendSheet(context, vm, author?.id ?? ''),
            style: AppButtonStyles.danger,
            child: vm.isSuspending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Suspend User'),
          ),
        ),
      ],
    );
  }

  // ── Action handlers ──────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, ContentDetailViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Delete content', style: AppTextStyles.labelLarge),
            content: Text(
              'This will permanently remove the post and mark the report as upheld.',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Cancel', style: AppTextStyles.bodyMedium),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Delete',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await vm.deleteContent();
      if (!context.mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Content deleted.')));
      // Pop back to the reports list now the post is gone.
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Error deleting content: $e')));
    }
  }

  Future<void> _confirmApprove(
      BuildContext context, ContentDetailViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Approve content', style: AppTextStyles.labelLarge),
            content: Text(
              'Approve this content and clear the moderation report?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('Cancel', style: AppTextStyles.bodyMedium),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Approve', style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.acid)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await vm.approveContent();
      if (!context.mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('Content approved.')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Error approving content: $e')));
    }
  }

  Future<void> _showSuspendSheet(
    BuildContext context,
    ContentDetailViewModel vm,
    String userId,
  ) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot suspend: author not found.')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String duration = '7 days';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        // AppRadius.xl does not exist — using 16.0 (closest value in AppRadius)
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suspend User',
                        style: AppTextStyles.displayMedium),
                    const SizedBox(height: AppSpacing.md),
                    // Duration picker
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
                    // Reason text field
                    // AppInputDecoration.standard() does not exist —
                    // building InputDecoration inline to match the team's style.
                    TextField(
                      controller: reasonController,
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
                              '${reasonController.text.trim()} ($duration)';
                          // Close the sheet before the async call to avoid
                          // using a stale BuildContext.
                          Navigator.of(sheetContext).pop();
                          try {
                            await vm.suspendUser(userId, reason);
                            if (!context.mounted) return;
                            messenger.showSnackBar(const SnackBar(
                                content: Text('User suspended.')));
                          } catch (e) {
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(
                                content: Text(
                                    'Error suspending user: $e')));
                          }
                        },
                        style: AppButtonStyles.danger,
                        child: const Text('Confirm Suspension'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    reasonController.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetricCard — stat tile
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AppTextStyles.statSmall does not exist — using statMedium (22px
          // Bebas Neue) which is the closest compact stat style available.
          Text(value, style: AppTextStyles.statMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.monoSmall),
        ],
      ),
    );
  }
}
