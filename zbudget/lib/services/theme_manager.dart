import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

enum AppTheme { light, dark, system }

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.system;
  SharedPreferences? _prefs;

  AppTheme get currentTheme => _currentTheme;

  // Convert enum to ThemeMode
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  // Initialize theme manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs?.getString(_themeKey);
    
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _currentTheme = AppTheme.light;
          break;
        case 'dark':
          _currentTheme = AppTheme.dark;
          break;
        case 'system':
          _currentTheme = AppTheme.system;
          break;
      }
    }
    
    debugPrint('🎨 ThemeManager initialized: $_currentTheme');
    notifyListeners();
  }

  // Change theme
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs?.setString(_themeKey, theme.name);
    
    debugPrint('🎨 Theme changed to: $theme');
    notifyListeners();
  }

  // Get light theme with custom colors
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary500,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      
      // Card theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF212121)),
        displayMedium: TextStyle(color: Color(0xFF212121)),
        displaySmall: TextStyle(color: Color(0xFF212121)),
        headlineLarge: TextStyle(color: Color(0xFF212121)),
        headlineMedium: TextStyle(color: Color(0xFF212121)),
        headlineSmall: TextStyle(color: Color(0xFF212121)),
        titleLarge: TextStyle(color: Color(0xFF212121)),
        titleMedium: TextStyle(color: Color(0xFF212121)),
        titleSmall: TextStyle(color: Color(0xFF212121)),
        bodyLarge: TextStyle(color: Color(0xFF212121)),
        bodyMedium: TextStyle(color: Color(0xFF212121)),
        bodySmall: TextStyle(color: Color(0xFF757575)),
        labelLarge: TextStyle(color: Color(0xFF212121)),
        labelMedium: TextStyle(color: Color(0xFF212121)),
        labelSmall: TextStyle(color: Color(0xFF757575)),
      ),
    );
  }

  // Get dark theme with custom colors
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary400,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFE0E0E0)),
        displayMedium: TextStyle(color: Color(0xFFE0E0E0)),
        displaySmall: TextStyle(color: Color(0xFFE0E0E0)),
        headlineLarge: TextStyle(color: Color(0xFFE0E0E0)),
        headlineMedium: TextStyle(color: Color(0xFFE0E0E0)),
        headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
        titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
        titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
        titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
        bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
        bodySmall: TextStyle(color: Color(0xFFBDBDBD)),
        labelLarge: TextStyle(color: Color(0xFFE0E0E0)),
        labelMedium: TextStyle(color: Color(0xFFE0E0E0)),
        labelSmall: TextStyle(color: Color(0xFFBDBDBD)),
      ),
    );
  }
}

// Helper class for custom colors
class AppThemeColors {
  // Light theme colors
  static const lightGradientStart = AppColors.primary500;
  static const lightGradientEnd = AppColors.primary600;
  static const lightCardBackground = Colors.white;
  static const lightTextPrimary = Color(0xFF212121);
  static const lightTextSecondary = Color(0xFF757575);
  static const lightIncomeColor = Color(0xFF4CAF50);
  static const lightExpenseColor = Color(0xFFF44336);
  
  // Dark theme colors
  static const darkGradientStart = AppColors.primary400;
  static const darkGradientEnd = AppColors.primary500;
  static const darkCardBackground = Color(0xFF1E1E1E);
  static const darkTextPrimary = Color(0xFFE0E0E0);
  static const darkTextSecondary = Color(0xFFBDBDBD);
  static const darkIncomeColor = Color(0xFF66BB6A);
  static const darkExpenseColor = Color(0xFFEF5350);
}