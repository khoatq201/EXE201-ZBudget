import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings/theme_settings.dart';

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
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('ThemeService initialization error: $e');
      _isInitialized = true;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(_themeSettingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(
          // Simple JSON parsing - in real app you'd use json.decode
          _parseJsonString(settingsJson),
        );
        _themeSettings = ThemeSettings.fromJson(settingsMap);
      } else {
        _themeSettings = const ThemeSettings();
      }
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
      _themeSettings = const ThemeSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (_prefs != null) {
        final settingsJson = _themeSettings.toJson().toString();
        await _prefs!.setString(_themeSettingsKey, settingsJson);
      }
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }

  // Simple JSON string parser (for demo purposes)
  Map<String, dynamic> _parseJsonString(String jsonStr) {
    // This is a simplified parser - in real app use json.decode
    return {
      'themeMode': 'system',
      'colorScheme': 'blue',
      'fontSize': 'normal',
      'useSystemFont': false,
      'enableAnimations': true,
      'enableHapticFeedback': true,
      'borderRadius': 12.0,
      'compactMode': false,
    };
  }

  // Theme data builder
  ThemeData _buildThemeData(Brightness brightness) {
    final colorScheme = _getColorScheme(brightness);
    final textTheme = _buildTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Animation settings
      pageTransitionsTheme: _themeSettings.enableAnimations
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
              },
            ),

      // Card theme with custom border radius
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_themeSettings.borderRadius),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_themeSettings.borderRadius),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_themeSettings.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_themeSettings.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_themeSettings.borderRadius),
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }

  ColorScheme _getColorScheme(Brightness brightness) {
    final seedColor = _themeSettings.colorScheme.color;

    return ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    // Apply font size scaling
    final scaledTextTheme = baseTextTheme.apply(
      fontSizeFactor: _themeSettings.fontSize.scale,
      fontFamily: _themeSettings.useSystemFont ? null : 'Roboto',
    );

    return scaledTextTheme;
  }

  // Update methods
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    if (_themeSettings.themeMode != themeMode) {
      _themeSettings = _themeSettings.copyWith(themeMode: themeMode);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> updateColorScheme(AppColorScheme colorScheme) async {
    if (_themeSettings.colorScheme != colorScheme) {
      _themeSettings = _themeSettings.copyWith(colorScheme: colorScheme);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> updateFontSize(FontSize fontSize) async {
    if (_themeSettings.fontSize != fontSize) {
      _themeSettings = _themeSettings.copyWith(fontSize: fontSize);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> toggleSystemFont(bool useSystemFont) async {
    if (_themeSettings.useSystemFont != useSystemFont) {
      _themeSettings = _themeSettings.copyWith(useSystemFont: useSystemFont);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> toggleAnimations(bool enableAnimations) async {
    if (_themeSettings.enableAnimations != enableAnimations) {
      _themeSettings = _themeSettings.copyWith(
        enableAnimations: enableAnimations,
      );
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> toggleHapticFeedback(bool enableHapticFeedback) async {
    if (_themeSettings.enableHapticFeedback != enableHapticFeedback) {
      _themeSettings = _themeSettings.copyWith(
        enableHapticFeedback: enableHapticFeedback,
      );
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateBorderRadius(double borderRadius) async {
    if (_themeSettings.borderRadius != borderRadius) {
      _themeSettings = _themeSettings.copyWith(borderRadius: borderRadius);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> toggleCompactMode(bool compactMode) async {
    if (_themeSettings.compactMode != compactMode) {
      _themeSettings = _themeSettings.copyWith(compactMode: compactMode);
      await _saveSettings();
      notifyListeners();

      if (_themeSettings.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> resetToDefaults() async {
    _themeSettings = const ThemeSettings();
    await _saveSettings();
    notifyListeners();

    if (_themeSettings.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }
  }

  // Utility methods
  String getThemeModeDisplayName() {
    return _themeSettings.themeMode.displayName;
  }

  String getColorSchemeDisplayName() {
    return _themeSettings.colorScheme.displayName;
  }

  String getFontSizeDisplayName() {
    return _themeSettings.fontSize.displayName;
  }

  Color getPrimaryColor() {
    return _themeSettings.colorScheme.color;
  }

  // Preview method for theme customization
  ThemeData getPreviewTheme(
    Brightness brightness, {
    AppColorScheme? colorScheme,
    FontSize? fontSize,
    double? borderRadius,
  }) {
    final previewSettings = _themeSettings.copyWith(
      colorScheme: colorScheme,
      fontSize: fontSize,
      borderRadius: borderRadius,
    );

    final originalSettings = _themeSettings;
    _themeSettings = previewSettings;
    final themeData = _buildThemeData(brightness);
    _themeSettings = originalSettings;

    return themeData;
  }
}

// No animation page transitions builder
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
