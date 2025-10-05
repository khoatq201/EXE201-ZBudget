import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/settings/theme_settings.dart';
import '../constants/colors.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeSettingsKey = 'theme_settings';

  ThemeSettings _themeSettings = const ThemeSettings();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  ThemeSettings get themeSettings => _themeSettings;
  bool get isInitialized => _isInitialized;

  // Theme data getters
  ThemeData get lightTheme => _buildThemeData(Brightness.light);
  ThemeData get darkTheme => _buildThemeData(Brightness.dark);

  ThemeMode get themeMode {
    switch (_themeSettings.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> initialize() async {
    debugPrint('🎨 ThemeService: Initializing...');
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;

      debugPrint('🎨 ThemeService: Initialized successfully');
      debugPrint(
        '🎨 Current theme mode: ${_themeSettings.themeMode.displayName}',
      );
      debugPrint('🎨 ThemeMode getter returns: ${themeMode}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🎨 ThemeService: Notifying listeners after initialization');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('🎨 ThemeService initialization error: $e');
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(_themeSettingsKey);
      debugPrint(
        '🎨 ThemeService: Loading settings from storage: $settingsJson',
      );

      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        _themeSettings = ThemeSettings.fromJson(settingsMap);
        debugPrint(
          '🎨 ThemeService: Loaded theme mode: ${_themeSettings.themeMode.displayName}',
        );
      } else {
        _themeSettings = const ThemeSettings();
        debugPrint(
          '🎨 ThemeService: No saved settings, using default (system)',
        );
      }
    } catch (e) {
      debugPrint('🎨 Error loading theme settings: $e');
      _themeSettings = const ThemeSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (_prefs != null) {
        final settingsJson = jsonEncode(_themeSettings.toJson());
        await _prefs!.setString(_themeSettingsKey, settingsJson);
      }
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }

  // Theme data builder
  ThemeData _buildThemeData(Brightness brightness) {
    final colorScheme = _getColorScheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Scaffold background color
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundPrimary,

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        color: brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightness == Brightness.dark
              ? AppColors.primary400
              : AppColors.primary500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? AppColors.primary400
                : AppColors.primary500,
            width: 2.0,
          ),
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.primary500,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light,
      ),
    );
  }

  ColorScheme _getColorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.fromSeed(
        seedColor: AppColors.primary500,
        brightness: Brightness.dark,
        // Override specific colors for better dark theme
        surface: AppColors.backgroundDark,
        onSurface: AppColors.textDarkPrimary,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textDarkPrimary,
        primary: AppColors.primary400,
        onPrimary: Colors.white,
        secondary: AppColors.secondary400,
        onSecondary: Colors.white,
        tertiary: AppColors.accent400,
        onTertiary: Colors.white,
      );
    } else {
      return ColorScheme.fromSeed(
        seedColor: AppColors.primary500,
        brightness: Brightness.light,
        surface: AppColors.backgroundPrimary,
        onSurface: AppColors.textPrimary,
        background: AppColors.backgroundPrimary,
        onBackground: AppColors.textPrimary,
      );
    }
  }

  // Theme mode update
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    debugPrint(
      '🎨 ThemeService: Updating theme mode to ${themeMode.displayName}',
    );

    if (_themeSettings.themeMode != themeMode) {
      _themeSettings = _themeSettings.copyWith(themeMode: themeMode);
      await _saveSettings();

      debugPrint('🎨 ThemeService: Theme mode updated, notifying listeners');
      notifyListeners();

      debugPrint(
        '🎨 ThemeService: New themeMode getter returns ${this.themeMode}',
      );
    } else {
      debugPrint('🎨 ThemeService: Theme mode unchanged, no update needed');
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _themeSettings = const ThemeSettings();
    await _saveSettings();
    notifyListeners();
  }

  // Helper methods
  String getThemeModeDisplayName() {
    return _themeSettings.themeMode.displayName;
  }

  Color getPrimaryColor() {
    return AppColors.primary500;
  }

  // Get preview theme for UI
  ThemeData getPreviewTheme(AppThemeMode themeMode) {
    final brightness = themeMode == AppThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    return _buildThemeData(brightness);
  }
}
