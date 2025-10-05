import 'package:flutter/material.dart';
import '../services/theme_manager.dart';

extension ThemeExtensions on BuildContext {
  // Quick access to theme properties
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  // Access to custom colors based on theme
  Color get gradientStart => isDarkTheme
      ? AppThemeColors.darkGradientStart
      : AppThemeColors.lightGradientStart;

  Color get gradientEnd => isDarkTheme
      ? AppThemeColors.darkGradientEnd
      : AppThemeColors.lightGradientEnd;

  Color get customCardBackground => isDarkTheme
      ? AppThemeColors.darkCardBackground
      : AppThemeColors.lightCardBackground;

  Color get customTextPrimary => isDarkTheme
      ? AppThemeColors.darkTextPrimary
      : AppThemeColors.lightTextPrimary;

  Color get customTextSecondary => isDarkTheme
      ? AppThemeColors.darkTextSecondary
      : AppThemeColors.lightTextSecondary;

  Color get incomeColor => isDarkTheme
      ? AppThemeColors.darkIncomeColor
      : AppThemeColors.lightIncomeColor;

  Color get expenseColor => isDarkTheme
      ? AppThemeColors.darkExpenseColor
      : AppThemeColors.lightExpenseColor;

  // Enhanced text colors for better contrast
  Color get primaryTextColor => colorScheme.onSurface;
  Color get secondaryTextColor => colorScheme.onSurfaceVariant;
  Color get tertiaryTextColor => colorScheme.outline;

  // Settings specific enhanced colors
  Color get settingsCardTitle => colorScheme.onSurface;
  Color get settingsCardSubtitle => colorScheme.onSurfaceVariant;
  Color get settingsSectionTitle => colorScheme.primary;

  // Notification specific colors with better contrast
  Color get notificationCardText =>
      colorScheme.onSurface; // Highest contrast for main text
  Color get notificationCardSubtext => isDarkTheme
      ? colorScheme
            .onSurfaceVariant // Use standard variant color in dark mode
      : colorScheme
            .onSurfaceVariant; // Use standard variant color in light mode
  Color get notificationIconColor => colorScheme.primary;
  Color get notificationIconBackground => isDarkTheme
      ? colorScheme.primary.withOpacity(0.2)
      : colorScheme.primary.withOpacity(0.1);

  // Settings screen - common colors
  Color get settingsItemTitleColor => colorScheme.onSurface; // high contrast
  Color get settingsItemSubtitleColor =>
      colorScheme.onSurfaceVariant; // secondary text
  Color get settingsItemTrailingColor => colorScheme.onSurfaceVariant;
  Color get settingsItemIconColor => colorScheme.primary;
  Color get settingsItemIconBackground =>
      colorScheme.primary.withOpacity(isDarkTheme ? 0.20 : 0.10);

  // Screen background colors - with green tint for dark theme
  Color get screenBackground => isDarkTheme
      ? Color(0xFF0A1A0C) // Very dark green-black for dark theme
      : colorScheme.surface; // Standard surface for light theme
  Color get scaffoldBackground => isDarkTheme
      ? Color(0xFF0A1A0C) // Very dark green-black for dark theme
      : colorScheme.surface; // Standard surface for light theme

  // App bar colors
  Color get appBarBackground => isDarkTheme
      ? Color(0xFF0D1F0F) // Slightly lighter green-black for app bar
      : colorScheme.surface;
  Color get appBarForeground => colorScheme.onSurface;

  // Card colors - also with green tint for dark theme
  Color get cardBackground => isDarkTheme
      ? Color(0xFF0F2311) // Dark green-tinted card background
      : colorScheme.surfaceContainerHigh;
  Color get cardBorder => colorScheme.outline.withOpacity(0.2);

  // Gradient colors for headers - vibrant and theme-aware
  Color get headerGradientStart => isDarkTheme
      ? Color(0xFF2E7D32) // Vibrant dark green for dark theme
      : Color(0xFF4CAF50); // Bright green for light theme
  Color get headerGradientEnd => isDarkTheme
      ? Color(0xFF1B5E20) // Deep dark green for dark theme
      : Color(0xFF388E3C); // Medium green for light theme

  // Section header colors
  Color get sectionHeaderColor => colorScheme.primary;

  // Stats card colors
  Color get statsCardBackground => colorScheme.primaryContainer;
  Color get statsCardText => colorScheme.onPrimaryContainer;

  // Achievement colors
  Color get achievementBackground => colorScheme.secondaryContainer;
  Color get achievementText => colorScheme.onSecondaryContainer;

  // Info row colors
  Color get infoRowBackground => colorScheme.surfaceContainerLow;
  Color get infoRowText => colorScheme.onSurface;

  // Button colors
  Color get primaryButtonBackground => colorScheme.primary;
  Color get primaryButtonForeground => colorScheme.onPrimary;
  Color get secondaryButtonBackground => colorScheme.secondary;
  Color get secondaryButtonForeground => colorScheme.onSecondary;

  // Input field colors
  Color get inputFieldBackground => colorScheme.surfaceContainerHighest;
  Color get inputFieldBorder => colorScheme.outline;
  Color get inputFieldText => colorScheme.onSurface;

  // Preview section colors
  Color get previewBackground => colorScheme.surfaceContainerLow;
  Color get previewText => colorScheme.onSurfaceVariant;
}
