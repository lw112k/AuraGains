import 'package:flutter/material.dart';
import '../models/admin_model.dart';

const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kWarn = Color(0xFFFF6B35);
const Color _kSuccess = Color(0xFF00E676);
const Color _kMuted = Color(0xFF9E9E9E);

class AdminApplicationCard extends StatelessWidget {
  const AdminApplicationCard({
    super.key,
    required this.application,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  final AdminApplicationModel application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = application.applicationStatus ?? 'pending';
    final isPending = status == 'pending';
    final statusColor = switch (status) {
      'approved' => _kSuccess,
      'rejected' => _kMuted,
      _ => _kWarn,
    };
    final borderColor =
        isPending ? _kWarn.withValues(alpha: 0.35) : _kBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Top row ─────────────────────────────────────
            Row(
              children: [
                _Avatar(url: application.profilePicUrl, name: application.username ?? '?'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.username ?? '(unknown)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (application.email != null)
                        Text(
                          application.email!,
                          style: const TextStyle(color: _kMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),

            // ─ Expert title ────────────────────────────────
            if (application.expertTitle != null) ...[
              Text(
                application.expertTitle!,
                style: const TextStyle(
                  color: _kAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // ─ Experience ─────────────────────────────────
            if (application.experienceYears != null)
              Text(
                '${application.experienceYears} yr${application.experienceYears! == 1 ? '' : 's'} experience',
                style: const TextStyle(color: _kMuted, fontSize: 12),
              ),

            if (application.experienceDescription != null) ...[
              const SizedBox(height: 6),
              Text(
                application.experienceDescription!,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ─ Submitted date ─────────────────────────────
            if (application.createDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Applied ${_shortDate(application.createDate!)}',
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],

            // ─ Action buttons ─────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
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
                        backgroundColor: _kSuccess.withValues(alpha: 0.15),
                        foregroundColor: _kSuccess,
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _shortDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
