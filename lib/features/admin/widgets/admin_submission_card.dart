import 'package:flutter/material.dart';
import '../models/admin_challenge_submission_model.dart';
import 'package:auragains/features/admin/admin_palette.dart';

class AdminSubmissionCard extends StatelessWidget {
  const AdminSubmissionCard({
    super.key,
    required this.submission,
    this.onApprove,
    this.onReject,
  });

  final AdminChallengeSubmissionModel submission;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = submission.challStatus == 'pending';
    final statusColor = switch (submission.challStatus) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.muted,
      _ => AppTheme.warn,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppTheme.warn.withOpacity(0.35) : AppTheme.border,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Header row ────────────────────────────────
          Row(
            children: [
              // Avatar
              _Avatar(
                name: submission.username ?? submission.submittedBy,
              ),
              const SizedBox(width: 12),
              // User + challenge info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.username ?? 'User ${submission.submittedBy.substring(0, 8)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      submission.challengeName.isNotEmpty
                          ? submission.challengeName
                          : 'Challenge #${submission.challId}',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              _StatusBadge(
                status: submission.challStatus,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ─ Evidence ─────────────────────────────────
          if (submission.vidEvidenceUrl != null &&
              submission.vidEvidenceUrl!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.videocam_rounded,
                    size: 14, color: AppTheme.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    submission.vidEvidenceUrl!,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // ─ Reject reason (if rejected) ──────────────
          if (submission.challStatus == 'rejected' &&
              submission.rejectReason != null &&
              submission.rejectReason!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warn.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warn.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppTheme.warn),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      submission.rejectReason!,
                      style: TextStyle(
                        color: AppTheme.warn,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ─ Date ─────────────────────────────────────
          if (submission.submissionDate != null)
            Text(
              'Submitted ${_fmtDate(submission.submissionDate!)}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),

          // ─ Actions (pending only) ───────────────────
          if (isPending) ...[
            const SizedBox(height: 12),
            Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warn,
                      side: BorderSide(color: AppTheme.warn.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success.withOpacity(0.15),
                      foregroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.accent.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
