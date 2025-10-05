import 'currency_settings.dart';
import 'notification_settings.dart';
import 'security_settings.dart';
import 'theme_settings.dart';
import 'language_settings.dart';

/// Comprehensive user settings model that combines all setting categories
/// This model represents the complete settings state for a user
class UserSettings {
  final LanguageSettings language;
  final ThemeSettings theme;
  final CurrencySettings currency;
  final NotificationSettings notifications;
  final SecuritySettings security;
  final DateTime? lastSyncedAt;
  final String? version; // For migration purposes

  const UserSettings({
    this.language = const LanguageSettings(),
    this.theme = const ThemeSettings(),
    this.currency = const CurrencySettings(),
    this.notifications = const NotificationSettings(),
    this.security = const SecuritySettings(),
    this.lastSyncedAt,
    this.version,
  });

  /// Create default settings for a new user
  factory UserSettings.defaultSettings() {
    return const UserSettings(
      language: LanguageSettings(),
      theme: ThemeSettings(),
      currency: CurrencySettings(),
      notifications: NotificationSettings(),
      security: SecuritySettings(),
      version: '1.0.0',
    );
  }

  /// Create from JSON
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      language: json['language'] != null
          ? LanguageSettings.fromJson(json['language'])
          : const LanguageSettings(),
      theme: json['theme'] != null
          ? ThemeSettings.fromJson(json['theme'])
          : const ThemeSettings(),
      currency: json['currency'] != null
          ? CurrencySettings.fromJson(json['currency'])
          : const CurrencySettings(),
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(json['notifications'])
          : const NotificationSettings(),
      security: json['security'] != null
          ? SecuritySettings.fromJson(json['security'])
          : const SecuritySettings(),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'])
          : null,
      version: json['version'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'language': language.toJson(),
      'theme': theme.toJson(),
      'currency': currency.toJson(),
      'notifications': notifications.toJson(),
      'security': security.toJson(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'version': version,
    };
  }

  /// Copy settings with modifications
  UserSettings copyWith({
    LanguageSettings? language,
    ThemeSettings? theme,
    CurrencySettings? currency,
    NotificationSettings? notifications,
    SecuritySettings? security,
    DateTime? lastSyncedAt,
    String? version,
  }) {
    return UserSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      currency: currency ?? this.currency,
      notifications: notifications ?? this.notifications,
      security: security ?? this.security,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      version: version ?? this.version,
    );
  }

  /// Copy settings with sync timestamp
  UserSettings withSync() {
    return copyWith(lastSyncedAt: DateTime.now());
  }

  /// Check if settings need to be synced (if local changes are newer than server)
  bool needsSync({DateTime? serverLastModified}) {
    if (serverLastModified == null) return false;
    if (lastSyncedAt == null) return true;
    return lastSyncedAt!.isBefore(serverLastModified);
  }

  /// Get a summary of current settings for debugging
  Map<String, dynamic> getSummary() {
    return {
      'language': language.language.code,
      'theme': theme.themeMode.name,
      'currency': currency.primaryCurrency.code,
      'notifications_enabled': notifications.isGlobalEnabled,
      'biometric_enabled': security.isBiometricEnabled,
      'last_synced': lastSyncedAt?.toIso8601String(),
      'version': version,
    };
  }

  /// Check if this is the first time user is setting up
  bool get isFirstTimeSetup => version == null;

  /// Check if settings are using default values
  bool get isUsingDefaults {
    final defaultSettings = UserSettings.defaultSettings();
    return language == defaultSettings.language &&
        theme == defaultSettings.theme &&
        currency == defaultSettings.currency &&
        notifications == defaultSettings.notifications &&
        security == defaultSettings.security;
  }

  /// Get a user-friendly description of current settings
  String get settingsDescription {
    return 'Language: ${language.language.nativeName}, '
        'Theme: ${theme.themeMode.name}, '
        'Currency: ${currency.primaryCurrency.code}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.language == language &&
        other.theme == theme &&
        other.currency == currency &&
        other.notifications == notifications &&
        other.security == security &&
        other.lastSyncedAt == lastSyncedAt &&
        other.version == version;
  }

  @override
  int get hashCode {
    return language.hashCode ^
        theme.hashCode ^
        currency.hashCode ^
        notifications.hashCode ^
        security.hashCode ^
        lastSyncedAt.hashCode ^
        version.hashCode;
  }

  @override
  String toString() {
    return 'UserSettings(language: $language, theme: $theme, currency: $currency, '
        'notifications: $notifications, security: $security, '
        'lastSyncedAt: $lastSyncedAt, version: $version)';
  }
}
