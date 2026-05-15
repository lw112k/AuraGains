import 'package:flutter/material.dart';
import '../models/admin_challenge_model.dart';
import 'package:auragains/features/admin/admin_palette.dart';

class AdminChallengeCard extends StatelessWidget {
  const AdminChallengeCard({
    super.key,
    required this.challenge,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.isActionLoading = false,
  });

  final AdminChallengeModel challenge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(bool)? onToggleActive;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: challenge.isActive
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Top row: name + active badge ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  challenge.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ActiveBadge(isActive: challenge.isActive),
            ],
          ),
          const SizedBox(height: 6),

          // ─ Description ──────────────────────────────
          Text(
            challenge.description,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ─ Meta row: points + daily/weekly + date ───
          Row(
            children: [
              _MetaChip(
                label: '${challenge.pointReward} pts',
                icon: Icons.stars_rounded,
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                label: challenge.isDaily ? 'Daily' : 'Weekly',
                icon: challenge.isDaily
                    ? Icons.today_rounded
                    : Icons.date_range_rounded,
                color: AppTheme.muted,
              ),
              const Spacer(),
              if (challenge.createDate != null)
                Text(
                  _fmtDate(challenge.createDate!),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),

          // ─ Actions ──────────────────────────────────
          const SizedBox(height: 12),
          Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              // Active toggle
              if (isActionLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                )
              else ...[
                Switch(
                  value: challenge.isActive,
                  onChanged: onToggleActive,
                  activeThumbColor: AppTheme.accent,
                  inactiveThumbColor: AppTheme.muted,
                  inactiveTrackColor: AppTheme.border,
                ),
                const SizedBox(width: 4),
                Text(
                  challenge.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: challenge.isActive ? AppTheme.accent : AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: AppTheme.accent,
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 18),
                color: AppTheme.warn,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
