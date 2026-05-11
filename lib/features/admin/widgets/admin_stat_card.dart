import 'package:flutter/material.dart';
import 'package:auragains/features/admin/admin_palette.dart';

enum AdminStatVariant { normal, warning, success }

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.variant = AdminStatVariant.normal,
  });

  final String label;
  final String value;
  final IconData? icon;
  final AdminStatVariant variant;

  @override
  Widget build(BuildContext context) {
    final accent = switch (variant) {
      AdminStatVariant.warning => AppTheme.warn,
      AdminStatVariant.success => AppTheme.success,
      AdminStatVariant.normal => AppTheme.accent,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
