import 'package:flutter/material.dart';

enum AppThemeMode {
  system('system', 'Theo hệ thống', Icons.brightness_auto),
  light('light', 'Sáng', Icons.light_mode),
  dark('dark', 'Tối', Icons.dark_mode);

  const AppThemeMode(this.id, this.displayName, this.icon);

  final String id;
  final String displayName;
  final IconData icon;
}

enum AppColorScheme {
  blue('blue', 'Xanh dương', Color(0xFF2196F3)),
  green('green', 'Xanh lá', Color(0xFF4CAF50)),
  purple('purple', 'Tím', Color(0xFF9C27B0)),
  orange('orange', 'Cam', Color(0xFFFF9800)),
  red('red', 'Đỏ', Color(0xFFF44336)),
  teal('teal', 'Xanh ngọc', Color(0xFF009688)),
  indigo('indigo', 'Chàm', Color(0xFF3F51B5)),
  pink('pink', 'Hồng', Color(0xFFE91E63));

  const AppColorScheme(this.id, this.displayName, this.color);

  final String id;
  final String displayName;
  final Color color;
}

enum FontSize {
  small('small', 'Nhỏ', 0.9),
  normal('normal', 'Bình thường', 1.0),
  large('large', 'Lớn', 1.1),
  extraLarge('extraLarge', 'Rất lớn', 1.2);

  const FontSize(this.id, this.displayName, this.scale);

  final String id;
  final String displayName;
  final double scale;
}

class ThemeSettings {
  final AppThemeMode themeMode;
  final AppColorScheme colorScheme;
  final FontSize fontSize;
  final bool useSystemFont;
  final bool enableAnimations;
  final bool enableHapticFeedback;
  final double borderRadius;
  final bool compactMode;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.colorScheme = AppColorScheme.blue,
    this.fontSize = FontSize.normal,
    this.useSystemFont = false,
    this.enableAnimations = true,
    this.enableHapticFeedback = true,
    this.borderRadius = 12.0,
    this.compactMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.id,
      'colorScheme': colorScheme.id,
      'fontSize': fontSize.id,
      'useSystemFont': useSystemFont,
      'enableAnimations': enableAnimations,
      'enableHapticFeedback': enableHapticFeedback,
      'borderRadius': borderRadius,
      'compactMode': compactMode,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.id == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      colorScheme: AppColorScheme.values.firstWhere(
        (scheme) => scheme.id == json['colorScheme'],
        orElse: () => AppColorScheme.blue,
      ),
      fontSize: FontSize.values.firstWhere(
        (size) => size.id == json['fontSize'],
        orElse: () => FontSize.normal,
      ),
      useSystemFont: json['useSystemFont'] ?? false,
      enableAnimations: json['enableAnimations'] ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      borderRadius: json['borderRadius']?.toDouble() ?? 12.0,
      compactMode: json['compactMode'] ?? false,
    );
  }

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
    FontSize? fontSize,
    bool? useSystemFont,
    bool? enableAnimations,
    bool? enableHapticFeedback,
    double? borderRadius,
    bool? compactMode,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      fontSize: fontSize ?? this.fontSize,
      useSystemFont: useSystemFont ?? this.useSystemFont,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      borderRadius: borderRadius ?? this.borderRadius,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeMode == themeMode &&
        other.colorScheme == colorScheme &&
        other.fontSize == fontSize &&
        other.useSystemFont == useSystemFont &&
        other.enableAnimations == enableAnimations &&
        other.enableHapticFeedback == enableHapticFeedback &&
        other.borderRadius == borderRadius &&
        other.compactMode == compactMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      colorScheme,
      fontSize,
      useSystemFont,
      enableAnimations,
      enableHapticFeedback,
      borderRadius,
      compactMode,
    );
  }
}
