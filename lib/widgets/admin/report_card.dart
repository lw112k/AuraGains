import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/constants.dart';
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
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Report report;
  final VoidCallback onTap;
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
          color: AppColors.card,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.border),
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
                  backgroundColor: AppColors.acidBg,
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
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'FLAGGED',
                    style: AppTextStyles.monoLabel
                        .copyWith(color: AppColors.orange),
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
            const Divider(color: AppColors.border, height: 1),

            const SizedBox(height: AppSpacing.sm),

            // ── Action buttons ────────────────────────────────────────
            Row(
              children: [
                // View content
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonBorder,
                      ),
                    ),
                    child: Text('VIEW', style: AppTextStyles.monoSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Approve (report upheld)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.acidBg,
                      foregroundColor: AppColors.acid,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonBorder,
                      ),
                    ),
                    child: Text('APPROVE', style: AppTextStyles.monoSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Reject (dismiss report)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorBg,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonBorder,
                      ),
                    ),
                    child: Text('REJECT', style: AppTextStyles.monoSmall),
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
