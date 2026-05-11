import 'package:flutter/material.dart';
// Admin-scoped palette and layout tokens. Keep this local to the admin
// feature to avoid touching other teams' code.

class AppTheme {
  // Foundation
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceFrame = Color(0xFF1E1E1E);
  static const Color primaryAccent = Colors.cyanAccent;

  // Palette
  static const Color card = surfaceFrame;
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = primaryAccent;
  static const Color warn = Color(0xFFFF6B35);
  static const Color success = Color(0xFF00E676);
  static const Color muted = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFEF5350);
}

class AppColors {
  static const Color accent = AppTheme.accent;
  static const Color muted = AppTheme.muted;
  static const Color border = AppTheme.border;
  static const Color card = AppTheme.card;
  static const Color warn = AppTheme.warn;
  static const Color success = AppTheme.success;
  static const Color background = AppTheme.backgroundDark;
  static const Color backgroundDark = AppTheme.backgroundDark;
  static const Color surface = AppTheme.card;
  static const Color surfaceVariant = AppTheme.surfaceFrame;
  static const Color textMuted = AppTheme.muted;
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color acid = AppTheme.accent;
  static const Color error = AppTheme.error;
  static const Color divider = AppTheme.border;

  static Color get acidBg => AppTheme.accent.withOpacity(0.12);
  static Color get errorBg => AppTheme.error.withOpacity(0.12);
  static Color get orangeBg => AppTheme.warn.withOpacity(0.12);
  static const Color warning = AppTheme.warn;
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle displayMedium = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 14,
    height: 1.4,
  );
  static const TextStyle labelLarge = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 16,
  );
  static const TextStyle headlineLarge = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle headlineMedium = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle bodySmall = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 12,
  );
  static const TextStyle labelSmall = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 11,
  );
  static const TextStyle labelMedium = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle monoLabel = TextStyle(
    fontFamily: 'monospace',
    color: Color(0xFF9E9E9E),
    fontSize: 11,
  );
  static const TextStyle caption = TextStyle(
    color: Color(0xFFBDBDBD),
    fontSize: 11,
  );
  static const TextStyle statMedium = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double xxxxl = 56.0;
}

class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 12.0;
  static const double full = 100.0;
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(12));
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> cardShadow = card;
}

class AppIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xxl = 32.0;
}
 
