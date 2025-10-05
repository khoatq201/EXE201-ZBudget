import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/settings/user_settings.dart';
import '../models/settings/currency_settings.dart';
import '../models/settings/notification_settings.dart';
import '../models/settings/security_settings.dart';
import '../models/settings/theme_settings.dart';
import '../models/settings/language_settings.dart';
import '../utils/auth_utils.dart';

/// Main settings service that synchronizes with backend API
/// Coordinates all settings-related operations including local storage and server sync
class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'user_settings';
  static const String _lastSyncKey = 'settings_last_sync';

  UserSettings _settings = const UserSettings();
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastSync;

  // Getters
  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSync => _lastSync;

  // Quick access to specific settings
  CurrencySettings get currencySettings => _settings.currency;
  NotificationSettings get notificationSettings => _settings.notifications;
  SecuritySettings get securitySettings => _settings.security;
  ThemeSettings get themeSettings => _settings.theme;
  LanguageSettings get languageSettings => _settings.language;

  /// Initialize the settings service
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Load settings from local storage first
      await _loadLocalSettings();

      // Try to sync with server if user is authenticated
      if (await AuthUtils.isAuthenticated()) {
        await _syncWithServer();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to initialize settings: $e');
      debugPrint('SettingsService initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get settings from server
  Future<UserSettings?> getSettingsFromServer() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserSettings.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await AuthUtils.logout();
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to get settings from server: $e');
      return null;
    }
  }

  /// Update all settings
  Future<bool> updateSettings(
    UserSettings newSettings, {
    bool syncToServer = true,
  }) async {
    try {
      _settings = newSettings;

      // Save to local storage
      await _saveLocalSettings();

      // Sync to server if requested and user is authenticated
      if (syncToServer && await AuthUtils.isAuthenticated()) {
        final success = await _updateSettingsOnServer(_settings.toJson());
        if (success) {
          _lastSync = DateTime.now();
          await _saveLastSync();
        }
        notifyListeners();
        return success;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update settings: $e');
      return false;
    }
  }

  /// Update currency settings
  Future<bool> updateCurrencySettings(CurrencySettings currencySettings) async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _updateCurrencyOnServer(
          currencySettings.toJson(),
        );
        if (success) {
          _settings = _settings.copyWith(currency: currencySettings);
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Update locally only
        _settings = _settings.copyWith(currency: currencySettings);
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update currency settings: $e');
      return false;
    }
  }

  /// Update notification settings
  Future<bool> updateNotificationSettings(
    NotificationSettings notificationSettings,
  ) async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _updateNotificationsOnServer(
          notificationSettings.toJson(),
        );
        if (success) {
          _settings = _settings.copyWith(notifications: notificationSettings);
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Update locally only
        _settings = _settings.copyWith(notifications: notificationSettings);
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update notification settings: $e');
      return false;
    }
  }

  /// Update security settings
  Future<bool> updateSecuritySettings(SecuritySettings securitySettings) async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _updateSecurityOnServer(
          securitySettings.toJson(),
        );
        if (success) {
          _settings = _settings.copyWith(security: securitySettings);
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Update locally only
        _settings = _settings.copyWith(security: securitySettings);
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update security settings: $e');
      return false;
    }
  }

  /// Update theme settings
  Future<bool> updateThemeSettings(ThemeSettings themeSettings) async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _updateThemeOnServer({
          'theme': themeSettings.themeMode.name,
        });
        if (success) {
          _settings = _settings.copyWith(theme: themeSettings);
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Update locally only
        _settings = _settings.copyWith(theme: themeSettings);
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update theme settings: $e');
      return false;
    }
  }

  /// Update language settings
  Future<bool> updateLanguageSettings(LanguageSettings languageSettings) async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _updateLanguageOnServer({
          'language': languageSettings.language.code,
        });
        if (success) {
          _settings = _settings.copyWith(language: languageSettings);
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Update locally only
        _settings = _settings.copyWith(language: languageSettings);
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to update language settings: $e');
      return false;
    }
  }

  /// Reset settings to defaults
  Future<bool> resetSettings() async {
    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _resetSettingsOnServer();
        if (success) {
          _settings = const UserSettings(); // Default settings
          await _saveLocalSettings();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        // Reset locally only
        _settings = const UserSettings();
        await _saveLocalSettings();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to reset settings: $e');
      return false;
    }
  }

  /// Sync settings with server
  Future<bool> syncWithServer() async {
    if (!await AuthUtils.isAuthenticated()) return false;

    _setSyncing(true);
    try {
      return await _syncWithServer();
    } finally {
      _setSyncing(false);
    }
  }

  // Private methods

  Future<bool> _syncWithServer() async {
    try {
      final serverSettings = await getSettingsFromServer();
      if (serverSettings != null) {
        _settings = serverSettings;
        await _saveLocalSettings();
        _lastSync = DateTime.now();
        await _saveLastSync();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to sync with server: $e');
      return false;
    }
  }

  Future<bool> _updateSettingsOnServer(Map<String, dynamic> settings) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update settings on server: $e');
      return false;
    }
  }

  Future<bool> _updateCurrencyOnServer(Map<String, dynamic> currency) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/currency'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(currency),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update currency on server: $e');
      return false;
    }
  }

  Future<bool> _updateNotificationsOnServer(
    Map<String, dynamic> notifications,
  ) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(notifications),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update notifications on server: $e');
      return false;
    }
  }

  Future<bool> _updateSecurityOnServer(Map<String, dynamic> security) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/security'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(security),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update security on server: $e');
      return false;
    }
  }

  Future<bool> _updateThemeOnServer(Map<String, dynamic> theme) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/theme'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(theme),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update theme on server: $e');
      return false;
    }
  }

  Future<bool> _updateLanguageOnServer(Map<String, dynamic> language) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/language'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(language),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update language on server: $e');
      return false;
    }
  }

  Future<bool> _resetSettingsOnServer() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/reset'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to reset settings on server: $e');
      return false;
    }
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson);
        _settings = UserSettings.fromJson(settingsMap);
      }

      // Load last sync time
      final lastSyncMillis = prefs.getInt(_lastSyncKey);
      if (lastSyncMillis != null) {
        _lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      }
    } catch (e) {
      debugPrint('Failed to load local settings: $e');
    }
  }

  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Failed to save local settings: $e');
    }
  }

  Future<void> _saveLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSync != null) {
        await prefs.setInt(_lastSyncKey, _lastSync!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Failed to save last sync time: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) _clearError();
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
