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

class ThemeSettings {
  final AppThemeMode themeMode;

  const ThemeSettings({this.themeMode = AppThemeMode.system});

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.id};
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.id == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
    );
  }

  ThemeSettings copyWith({AppThemeMode? themeMode}) {
    return ThemeSettings(themeMode: themeMode ?? this.themeMode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings && other.themeMode == themeMode;
  }

  @override
  int get hashCode => themeMode.hashCode;
}
