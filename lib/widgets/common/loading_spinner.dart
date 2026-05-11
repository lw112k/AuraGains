import 'package:flutter/material.dart';

import 'package:auragains/core/theme/app_theme.dart';

/// A simple branded circular loading indicator.
///
/// Uses [AppColors.acid] as the active stroke colour to stay consistent with
/// the AuraGains design system.
///
/// ```dart
/// const LoadingSpinner()          // default size
/// const LoadingSpinner(size: 24)  // explicit size
/// ```
class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key, this.size = 20.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
      ),
    );
  }
}
