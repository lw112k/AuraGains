import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:auragains/features/admin/admin_palette.dart';
import '../../features/admin/models/report_model.dart';

/// A card that surfaces a single pending moderation report.
///
/// Displays the reporter's avatar, username, the flagged reason, and a
/// relative timestamp.  Two action buttons — Approve and Reject — forward
/// to the provided callbacks.
///
/// ```dart
/// ReportCard(
///   report: report,
///   onTap:     () => context.push(AppRoutes.adminContentDetail(report.contentId)),
///   onApprove: () => _handleApprove(report),
///   onReject:  () => _handleReject(report),
/// )
/// ```
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onApprove,
    required this.onReject,
    this.onTap,
  });

  final Report report;
  final VoidCallback? onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reporter row ──────────────────────────────────────────
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accent.withOpacity(0.12),
                  backgroundImage: report.reporterAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(report.reporterAvatar)
                      : null,
                  child: report.reporterAvatar.isEmpty
                      ? Text(
                          report.reporterUsername.isNotEmpty
                              ? report.reporterUsername[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.labelSmall,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Username + timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reporterUsername.isNotEmpty
                            ? report.reporterUsername
                            : 'Unknown user',
                        style: AppTextStyles.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(report.reportedAt),
                        style: AppTextStyles.monoLabel,
                      ),
                    ],
                  ),
                ),

                // Flagged badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warn.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'FLAGGED',
                    style: AppTextStyles.caption.copyWith(color: AppTheme.warn),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Reason ───────────────────────────────────────────────
            Text(
              report.reason.isNotEmpty ? report.reason : 'No reason provided.',
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Divider ──────────────────────────────────────────────
            Divider(color: AppTheme.border, height: 1),

            const SizedBox(height: AppSpacing.sm),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                // View content
                Expanded(
                    child: OutlinedButton(
                    onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                    child: const Text('VIEW', style: AppTextStyles.labelMedium),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Approve (report upheld)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent.withOpacity(0.15),
                      foregroundColor: AppTheme.accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                    child: const Text('APPROVE', style: AppTextStyles.labelMedium),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Reject (dismiss report)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error.withOpacity(0.15),
                      foregroundColor: AppTheme.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                    child: const Text('REJECT', style: AppTextStyles.labelMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
