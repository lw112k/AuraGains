import 'package:flutter/material.dart';
import '../models/admin_model.dart';

const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kWarn = Color(0xFFFF6B35);
const Color _kSuccess = Color(0xFF00E676);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kError = Color(0xFFEF5350);

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
      'approved' => _kSuccess,
      'dismissed' => _kMuted,
      _ => _kWarn,
    };

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? _kWarn.withValues(alpha: 0.4) : _kBorder,
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                    style: const TextStyle(
                      color: _kMuted,
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
              report.reason ?? '(no reason provided)',
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
              style: const TextStyle(
                color: _kMuted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // ─ Actions ───────────────────────────────────────
          if (isPending) ...[
            const Divider(color: _kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  if (report.postId != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onViewContent,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('View'),
                        style: TextButton.styleFrom(
                          foregroundColor: _kAccent,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(foregroundColor: _kMuted),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kSuccess.withValues(alpha: 0.15),
                        foregroundColor: _kSuccess,
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
