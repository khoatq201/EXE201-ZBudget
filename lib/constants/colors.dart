import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors from design system
  static const Color primary50 = Color(0xFFE8F5E8);
  static const Color primary100 = Color(0xFFC6E6C6);
  static const Color primary200 = Color(0xFFA0D6A0);
  static const Color primary300 = Color(0xFF7AC67A);
  static const Color primary400 = Color(0xFF5CB85C);
  static const Color primary500 = Color(
    0xFF3DA13D,
  ); // Main primary (Bangladesh Green)
  static const Color primary600 = Color(0xFF378537);
  static const Color primary700 = Color(0xFF2F6A2F);
  static const Color primary800 = Color(0xFF275027);
  static const Color primary900 = Color(0xFF1A351A);

  // Secondary Colors
  static const Color secondary50 = Color(0xFFE8F8F8);
  static const Color secondary100 = Color(0xFFC6EEEE);
  static const Color secondary200 = Color(0xFFA0E3E3);
  static const Color secondary300 = Color(0xFF7AD8D8);
  static const Color secondary400 = Color(0xFF5ECFCF);
  static const Color secondary500 = Color(0xFF42C5C5); // Mountain Meadow
  static const Color secondary600 = Color(0xFF3CB8B8);
  static const Color secondary700 = Color(0xFF34A6A6);
  static const Color secondary800 = Color(0xFF2D9494);
  static const Color secondary900 = Color(0xFF1F7474);

  // Caribbean Green
  static const Color accent50 = Color(0xFFE8FBF8);
  static const Color accent100 = Color(0xFFC6F4EE);
  static const Color accent200 = Color(0xFFA0ECE3);
  static const Color accent300 = Color(0xFF7AE4D8);
  static const Color accent400 = Color(0xFF5EDECF);
  static const Color accent500 = Color(0xFF42D8C5); // Caribbean Green
  static const Color accent600 = Color(0xFF3CC5B3);
  static const Color accent700 = Color(0xFF34B09E);
  static const Color accent800 = Color(0xFF2D9B89);
  static const Color accent900 = Color(0xFF1F7A65);

  // Dark colors
  static const Color dark50 = Color(0xFFF5F5F5);
  static const Color dark100 = Color(0xFFE0E0E0);
  static const Color dark200 = Color(0xFFBDBDBD);
  static const Color dark300 = Color(0xFF9E9E9E);
  static const Color dark400 = Color(0xFF757575);
  static const Color dark500 = Color(0xFF616161); // Rich Black
  static const Color dark600 = Color(0xFF424242);
  static const Color dark700 = Color(0xFF303030);
  static const Color dark800 = Color(0xFF212121);
  static const Color dark900 = Color(0xFF1C1C1C);

  // Background colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundTertiary = Color(0xFFE8F5E8);
  static const Color backgroundDark = Color(0xFF1C1C1C);
  static const Color backgroundDarkSecondary = Color(0xFF2A2A2A);

  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF8F9FA);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textSuccess = Color(0xFF3DA13D);
  static const Color textWarning = Color(0xFFFFA726);
  static const Color textError = Color(0xFFF44336);

  // System colors
  static const Color success = Color(0xFF3DA13D);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF42C5C5);

  // Vietnamese currency colors
  static const Color vndPositive = Color(0xFF3DA13D);
  static const Color vndNegative = Color(0xFFF44336);
  static const Color vndNeutral = Color(0xFF616161);

  // Gradient colors
  static const List<Color> gradientPrimary = [primary500, accent500];
  static const List<Color> gradientSecondary = [secondary500, accent500];
  static const List<Color> gradientAccent = [accent500, accent300];
  static const List<Color> gradientDark = [backgroundDark, dark700];
}

class ThemeColors {
  static const light = {
    'primary': AppColors.primary500,
    'secondary': AppColors.secondary500,
    'accent': AppColors.accent500,
    'background': AppColors.backgroundPrimary,
    'surface': AppColors.backgroundSecondary,
    'text': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'border': AppColors.dark200,
    'success': AppColors.success,
    'warning': AppColors.warning,
    'error': AppColors.error,
  };

  static const dark = {
    'primary': AppColors.primary400,
    'secondary': AppColors.secondary400,
    'accent': AppColors.accent400,
    'background': AppColors.backgroundDark,
    'surface': AppColors.backgroundDarkSecondary,
    'text': AppColors.textInverse,
    'textSecondary': AppColors.dark300,
    'border': AppColors.dark700,
    'success': AppColors.success,
    'warning': AppColors.warning,
    'error': AppColors.error,
  };
}
