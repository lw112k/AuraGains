import 'package:flutter/material.dart';

import 'package:auragains/features/admin/admin_palette.dart';

// ─────────────────────────────────────────────────────────
// VARIANT
// ─────────────────────────────────────────────────────────

/// Controls the accent colour of an [AdminStatCard].
enum AdminStatVariant {
  /// Neutral blue accent — default.
  normal,

  /// Green/acid accent — all clear.
  success,

  /// Orange accent — requires attention.
  warning,

  /// Red accent — critical.
  danger,
}

// ─────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────

/// A compact KPI card used on the admin dashboard.
///
/// ```dart
/// AdminStatCard(
///   label: 'Total Users',
///   value: '1 024',
///   icon: Icons.groups_rounded,
/// )
///
/// AdminStatCard(
///   label: 'Active Reports',
///   value: '3',
///   icon: Icons.flag_rounded,
///   variant: AdminStatVariant.warning,
/// )
/// ```
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isAlert = false,
    this.variant = AdminStatVariant.normal,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isAlert;
  final AdminStatVariant variant;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color get _accentColor => isAlert
      ? AppTheme.warn
      : switch (variant) {
          AdminStatVariant.success => AppTheme.success,
          AdminStatVariant.warning => AppTheme.warn,
          AdminStatVariant.danger  => AppTheme.error,
          _                        => AppTheme.accent,
        };

  Color get _bgColor => isAlert
      ? AppTheme.warn.withOpacity(0.12)
      : switch (variant) {
          AdminStatVariant.success => AppTheme.success.withOpacity(0.12),
          AdminStatVariant.warning => AppTheme.warn.withOpacity(0.12),
          AdminStatVariant.danger  => AppTheme.error.withOpacity(0.12),
          _                        => AppTheme.accent.withOpacity(0.08),
        };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppTheme.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
                child: Icon(icon, color: _accentColor, size: AppIconSizes.md),
          ),

          // Value + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.statMedium),
              const SizedBox(height: AppSpacing.xxs),
                Text(
                title,
                style: AppTextStyles.monoLabel
                    .copyWith(color: AppTheme.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
