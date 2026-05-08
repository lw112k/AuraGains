import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────
abstract final class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDark = Color(0xFF0097A7);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF666666);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color divider = Color(0xFF2C2C2C);
  static const Color cardBackground = Color(0xFF1C1C1E);
  static const Color shimmer = Color(0xFF2A2A2A);

  // Aliases used by admin widgets
  static const Color card = surface;
  static const Color border = Color(0xFF333333);
  static const Color muted = textMuted;
  static const Color acid = accent;
  static const Color acidBg = Color(0xFF003640);
  static const Color acidBgLight = Color(0xFF002830);
  static const Color orangeBg = Color(0xFF3A2200);
  static const Color errorBg = Color(0xFF3A0010);
}

// ─────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────
abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double section = 48.0;
}

// ─────────────────────────────────────────────────────────
// BORDER RADIUS
// ─────────────────────────────────────────────────────────
abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  // Aliases used by admin widgets
  static const BorderRadius cardBorder = mdAll;
}

// ─────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> accent = [
    BoxShadow(
      color: AppColors.accent.withAlpha(77),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Alias used by admin widgets
  static const List<BoxShadow> cardShadow = card;
}

// ─────────────────────────────────────────────────────────
// ICON SIZES
// ─────────────────────────────────────────────────────────
abstract final class AppIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ─────────────────────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────────────────────
abstract final class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static const TextStyle accentLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  // Aliases / extras used by admin widgets
  static const TextStyle statMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
