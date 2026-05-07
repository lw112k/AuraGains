import 'package:flutter/material.dart';

import '../../core/theme/constants.dart';

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
    required this.label,
    required this.value,
    required this.icon,
    this.variant = AdminStatVariant.normal,
  });

  final String label;
  final String value;
  final IconData icon;
  final AdminStatVariant variant;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color get _accentColor => switch (variant) {
        AdminStatVariant.success => AppColors.acid,
        AdminStatVariant.warning => AppColors.warning,
        AdminStatVariant.danger  => AppColors.error,
        _                        => AppColors.acid,
      };

  Color get _bgColor => switch (variant) {
        AdminStatVariant.success => AppColors.acidBg,
        AdminStatVariant.warning => AppColors.orangeBg,
        AdminStatVariant.danger  => AppColors.errorBg,
        _                        => AppColors.acidBgLight,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
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
                label,
                style: AppTextStyles.monoLabel
                    .copyWith(color: AppColors.muted),
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
