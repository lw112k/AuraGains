/// AuraGains Design System Constants
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
// BRAND COLORS
// ─────────────────────────────────────────────────────────

abstract final class AppColors {
  static const Color black = Color(0xFF0A0A0A);
  static const Color steel = Color(0xFF1E1E1E);
  static const Color mid = Color(0xFF2C2C2C);
  static const Color card = Color(0xFF161616);
  static const Color white = Color(0xFFF5F3EE);
  static const Color muted = Color(0xFF888888);

  static const Color accentBlue = Color(0xFF0066FF);
  static const Color acid = Color(0xFF0066FF);
  static const Color orange = Color(0xFFFF5C1A);

  static const Color success = Color(0xFF0066FF);
  static const Color warning = Color(0xFFFFA600);
  static const Color error = Color(0xFFFF5555);

  static const Color border = Color(0x14FFFFFF);
  static const Color borderLight = Color(0x26FFFFFF);
  static const Color overlay = Color(0xD9000000);
  static const Color overlayLight = Color(0x99000000);

  static const Color acidBg = Color(0x1A0066FF);
  static const Color acidBgLight = Color(0x140066FF);
  static const Color orangeBg = Color(0x1AFF5C1A);
  static const Color errorBg = Color(0x26FF5555);
}

// ─────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smd = 10.0;
  static const double md = 12.0;
  static const double mdd = 14.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
  static const double screenPaddingH = 14.0;
  static const double cardPadding = 10.0;
}

// ─────────────────────────────────────────────────────────
// BORDER RADII
// ─────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double xs = 3.0;
  static const double sm = 5.0;
  static const double smd = 6.0;
  static const double md = 7.0;
  static const double mdd = 8.0;
  static const double lg = 9.0;
  static const double card = 9.0;
  static const double button = 8.0;
  static const double pill = 100.0;

  static final BorderRadius cardBorder = BorderRadius.circular(card);
  static final BorderRadius buttonBorder = BorderRadius.circular(button);
  static final BorderRadius pillBorder = BorderRadius.circular(pill);
  static final BorderRadius inputBorder = BorderRadius.circular(mdd);
}

// ─────────────────────────────────────────────────────────
// DURATIONS
// ─────────────────────────────────────────────────────────

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pulse = Duration(seconds: 2);
}

// ─────────────────────────────────────────────────────────
// ICON SIZES
// ─────────────────────────────────────────────────────────

abstract final class AppIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

// ─────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────

abstract final class AppShadows {
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.bebasNeue(
        fontSize: 32, letterSpacing: 2, color: AppColors.white, height: 0.92);

  static TextStyle get displayMedium => GoogleFonts.bebasNeue(
        fontSize: 22, letterSpacing: 1.5, color: AppColors.white, height: 0.95);

  static TextStyle get displaySmall => GoogleFonts.bebasNeue(
        fontSize: 18, letterSpacing: 1, color: AppColors.white);

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
        height: 1.5);

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
        height: 1.4);

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        height: 1.4);

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white);

  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white);

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white);

  static TextStyle get mono => GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        letterSpacing: 1);

  static TextStyle get monoSmall => GoogleFonts.spaceMono(
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        letterSpacing: 1);

  static TextStyle get monoBold => GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 1);

  static TextStyle get monoLabel => GoogleFonts.spaceMono(
        fontSize: 7,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        letterSpacing: 1.5);

  static TextStyle get statLarge => GoogleFonts.bebasNeue(
        fontSize: 36, color: AppColors.white, letterSpacing: 1);

  static TextStyle get statMedium =>
      GoogleFonts.bebasNeue(fontSize: 22, color: AppColors.white);
}

// ─────────────────────────────────────────────────────────
// BUTTON STYLES
// ─────────────────────────────────────────────────────────

abstract final class AppButtonStyles {
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.acid,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle:
            GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
      );

  static ButtonStyle get ghost => OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle:
            GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
      );

  static ButtonStyle get danger => ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
        textStyle:
            GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
      );
}
