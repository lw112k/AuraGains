import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import 'package:auragains/features/admin/admin_palette.dart';

// Removed local color constants in favor of AppTheme colors

class AdminReportCard extends StatelessWidget {
  const AdminReportCard({
    super.key,
    required this.report,
    this.onApprove,
    this.onDismiss,
    this.onViewContent,
  });

  final AdminReportModel report;
  final VoidCallback? onApprove;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewContent;

  @override
  Widget build(BuildContext context) {
    final isPending = (report.status ?? 'pending') == 'pending';
    final statusColor = switch (report.status ?? 'pending') {
      'approved' => AppTheme.success,
      'dismissed' => AppTheme.muted,
      _ => AppTheme.warn,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppTheme.warn.withOpacity(0.4) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    (report.status ?? 'pending').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (report.targetType != null)
                  Text(
                    report.targetType!.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),

          // ─ Reason ────────────────────────────────────────
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              report.displayReason.isNotEmpty ? report.displayReason : '(no reason provided)',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ─ Meta ──────────────────────────────────────────
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              _formatDate(report.createDate),
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // ─ Actions ───────────────────────────────────────
            if (isPending) ...[
            Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  if (report.postId != null || report.targetType == 'comment')
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onViewContent,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('View'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(foregroundColor: AppTheme.muted),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success.withOpacity(0.15),
                        foregroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
