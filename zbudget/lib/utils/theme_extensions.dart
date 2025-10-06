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

  // Common semantic colors
  Color get errorColor => colorScheme.error;

  Color get warningColor => colorScheme.secondary;

  // Enhanced text colors for better contrast
  Color get primaryTextColor =>
      isDarkTheme ? Colors.white.withOpacity(0.95) : colorScheme.onSurface;

  Color get secondaryTextColor => isDarkTheme
      ? Colors.white.withOpacity(0.80)
      : colorScheme.onSurfaceVariant;

  Color get tertiaryTextColor => colorScheme.outline;

  // Settings specific enhanced colors
  Color get settingsCardTitle => primaryTextColor;
  Color get settingsCardSubtitle => secondaryTextColor;
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
  Color get settingsItemTitleColor => primaryTextColor; // high contrast
  Color get settingsItemSubtitleColor => secondaryTextColor; // secondary text
  Color get settingsItemTrailingColor => colorScheme.onSurfaceVariant;
  Color get settingsItemIconColor => colorScheme.primary;
  Color get settingsItemIconBackground =>
      colorScheme.primary.withOpacity(isDarkTheme ? 0.20 : 0.10);

  // Screen background colors - with green tint for dark theme
  Color get screenBackground => isDarkTheme
      ? Color(
          0xFF06140A,
        ) // Slightly darker green-black for dark theme (improve contrast)
      : colorScheme.surface; // Standard surface for light theme
  Color get scaffoldBackground => isDarkTheme
      ? Color(
          0xFF06140A,
        ) // Slightly darker green-black for dark theme (improve contrast)
      : colorScheme.surface; // Standard surface for light theme

  // App bar colors
  Color get appBarBackground => isDarkTheme
      ? Color(0xFF0D1F0F) // Slightly lighter green-black for app bar
      : colorScheme.surface;
  Color get appBarForeground => colorScheme.onSurface;

  // Card colors - also with green tint for dark theme
  Color get cardBackground => isDarkTheme
      ? Color(
          0xFF0B1F0D,
        ) // Darker green-tinted card background for stronger contrast
      : colorScheme.surfaceContainerHigh;
  Color get cardBorder => colorScheme.outline.withOpacity(0.2);

  // Gradient colors for headers - vibrant and theme-aware
  Color get headerGradientStart => isDarkTheme
      ? Color(0xFF27692A) // Slightly toned-down dark green for better contrast
      : Color(0xFF4CAF50); // Bright green for light theme
  Color get headerGradientEnd => isDarkTheme
      ? Color(0xFF164B16) // Slightly toned-down deep dark green for dark theme
      : Color(0xFF388E3C); // Medium green for light theme

  // Section header colors
  Color get sectionHeaderColor => colorScheme.primary;

  // Header-specific text colors to ensure high contrast over gradient headers
  Color get headerTextColor => isDarkTheme
      ? Colors.white.withOpacity(0.98)
      : colorScheme
            .onPrimary; // usually white on colored primary in light theme

  Color get headerSubtitleColor => isDarkTheme
      ? Colors.white.withOpacity(0.85)
      : colorScheme.onPrimary.withOpacity(0.9);

  // Stats card colors
  Color get statsCardBackground => colorScheme.primaryContainer;
  Color get statsCardText => colorScheme.onPrimaryContainer;

  // Achievement colors
  Color get achievementBackground => colorScheme.secondaryContainer;
  Color get achievementText => colorScheme.onSecondaryContainer;

  // Info row colors
  Color get infoRowBackground => isDarkTheme
      ? Color(0xFF0E2A14) // slightly lighter than card to separate info rows
      : colorScheme.surfaceContainerLow;
  Color get infoRowText => primaryTextColor;

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
  Color get previewText => secondaryTextColor;
}
