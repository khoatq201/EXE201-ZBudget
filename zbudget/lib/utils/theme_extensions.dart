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

  // Screen background colors
  Color get screenBackground => colorScheme.surface;
  Color get scaffoldBackground => colorScheme.surface;

  // App bar colors
  Color get appBarBackground => colorScheme.surface;
  Color get appBarForeground => colorScheme.onSurface;

  // Card colors
  Color get cardBackground => colorScheme.surfaceContainerHigh;
  Color get cardBorder => colorScheme.outline.withOpacity(0.2);

  // Gradient colors for headers
  Color get headerGradientStart => colorScheme.primary;
  Color get headerGradientEnd => colorScheme.primary.withOpacity(0.8);

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
