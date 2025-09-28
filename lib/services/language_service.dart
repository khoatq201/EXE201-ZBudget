import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings/language_settings.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageSettingsKey = 'language_settings';

  LanguageSettings _languageSettings = const LanguageSettings();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  LanguageSettings get languageSettings => _languageSettings;
  bool get isInitialized => _isInitialized;

  // Quick access properties
  AppLanguage get currentLanguage => _languageSettings.language;
  String get currentLanguageCode => _languageSettings.language.code;
  String get currentLanguageName => _languageSettings.language.nativeName;
  String get currentLanguageFlag => _languageSettings.language.flag;

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
      debugPrint('LanguageService initialization error: $e');
      _isInitialized = true;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(_languageSettingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = Map<String, dynamic>.from(
          _parseJsonString(settingsJson),
        );
        _languageSettings = LanguageSettings.fromJson(settingsMap);
      } else {
        _languageSettings = const LanguageSettings();
      }
    } catch (e) {
      debugPrint('Error loading language settings: $e');
      _languageSettings = const LanguageSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (_prefs != null) {
        final settingsJson = _languageSettings.toJson().toString();
        await _prefs!.setString(_languageSettingsKey, settingsJson);
      }
    } catch (e) {
      debugPrint('Error saving language settings: $e');
    }
  }

  // Simple JSON string parser (for demo purposes)
  Map<String, dynamic> _parseJsonString(String jsonStr) {
    // This is a simplified parser - in real app use json.decode
    return {
      'language': 'vi',
      'dateFormat': 'dd/MM/yyyy',
      'numberFormat': 'comma',
      'currencyFormat': 'afterSpace',
      'use24HourFormat': true,
      'useLocalizedNumbers': true,
      'timeZone': 'Asia/Ho_Chi_Minh',
      'autoDetectLanguage': false,
    };
  }

  // Update methods
  Future<void> updateLanguage(AppLanguage language) async {
    if (_languageSettings.language != language) {
      _languageSettings = _languageSettings.copyWith(language: language);
      await _saveSettings();
      notifyListeners();

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Update system locale if possible
      await _updateSystemLocale(language);
    }
  }

  Future<void> updateDateFormat(DateFormat dateFormat) async {
    if (_languageSettings.dateFormat != dateFormat) {
      _languageSettings = _languageSettings.copyWith(dateFormat: dateFormat);
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> updateNumberFormat(NumberFormat numberFormat) async {
    if (_languageSettings.numberFormat != numberFormat) {
      _languageSettings = _languageSettings.copyWith(
        numberFormat: numberFormat,
      );
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> updateCurrencyFormat(CurrencyFormat currencyFormat) async {
    if (_languageSettings.currencyFormat != currencyFormat) {
      _languageSettings = _languageSettings.copyWith(
        currencyFormat: currencyFormat,
      );
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> toggle24HourFormat(bool use24Hour) async {
    if (_languageSettings.use24HourFormat != use24Hour) {
      _languageSettings = _languageSettings.copyWith(
        use24HourFormat: use24Hour,
      );
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> toggleLocalizedNumbers(bool useLocalized) async {
    if (_languageSettings.useLocalizedNumbers != useLocalized) {
      _languageSettings = _languageSettings.copyWith(
        useLocalizedNumbers: useLocalized,
      );
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> updateTimeZone(String timeZone) async {
    if (_languageSettings.timeZone != timeZone) {
      _languageSettings = _languageSettings.copyWith(timeZone: timeZone);
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> toggleAutoDetectLanguage(bool autoDetect) async {
    if (_languageSettings.autoDetectLanguage != autoDetect) {
      _languageSettings = _languageSettings.copyWith(
        autoDetectLanguage: autoDetect,
      );
      await _saveSettings();
      notifyListeners();
      HapticFeedback.selectionClick();

      if (autoDetect) {
        await _detectAndSetSystemLanguage();
      }
    }
  }

  Future<void> resetToDefaults() async {
    _languageSettings = const LanguageSettings();
    await _saveSettings();
    notifyListeners();
    HapticFeedback.heavyImpact();
  }

  // System integration methods
  Future<void> _updateSystemLocale(AppLanguage language) async {
    try {
      // In a real app, you would update the app's locale here
      // For demo purposes, we'll just show a debug message
      debugPrint('Updated system locale to: ${language.code}');
    } catch (e) {
      debugPrint('Error updating system locale: $e');
    }
  }

  Future<void> _detectAndSetSystemLanguage() async {
    try {
      // In a real app, you would detect system language here
      // For demo purposes, we'll use a default
      final systemLanguage = AppLanguage.vietnamese;
      await updateLanguage(systemLanguage);
    } catch (e) {
      debugPrint('Error detecting system language: $e');
    }
  }

  // Formatting utility methods
  String formatDate(DateTime date) {
    return _languageSettings.formatDate(date);
  }

  String formatNumber(double number) {
    return _languageSettings.formatNumber(number);
  }

  String formatCurrency(double amount, [String currencySymbol = 'VND']) {
    return _languageSettings.formatCurrency(amount, currencySymbol);
  }

  String formatTime(DateTime time) {
    return _languageSettings.formatTime(time);
  }

  // Sample data methods for preview
  String getSampleDate() {
    final now = DateTime.now();
    return formatDate(now);
  }

  String getSampleNumber() {
    return formatNumber(1234567.89);
  }

  String getSampleCurrency() {
    return formatCurrency(1000000, 'VND');
  }

  String getSampleTime() {
    final now = DateTime.now();
    return formatTime(now);
  }

  // Get display names
  String getDateFormatDisplayName() {
    return _languageSettings.dateFormat.display;
  }

  String getNumberFormatDisplayName() {
    return _languageSettings.numberFormat.displayName;
  }

  String getCurrencyFormatDisplayName() {
    return _languageSettings.currencyFormat.displayName;
  }

  String getTimeFormatDisplayName() {
    return _languageSettings.use24HourFormat ? '24 giờ' : '12 giờ';
  }

  // Get supported languages by region
  List<AppLanguage> getAsianLanguages() {
    return [
      AppLanguage.vietnamese,
    ];
  }

  List<AppLanguage> getEuropeanLanguages() {
    return [
      AppLanguage.english,
    ];
  }

  List<AppLanguage> getAllLanguages() {
    return AppLanguage.values;
  }

  // Language statistics
  Map<String, dynamic> getLanguageStatistics() {
    return {
      'currentLanguage': _languageSettings.language.nativeName,
      'totalLanguages': AppLanguage.values.length,
      'currentRegion': _getCurrentRegion(),
      'formatSettings': {
        'dateFormat': _languageSettings.dateFormat.display,
        'numberFormat': _languageSettings.numberFormat.displayName,
        'currencyFormat': _languageSettings.currencyFormat.displayName,
        'timeFormat': getTimeFormatDisplayName(),
      },
    };
  }

  String _getCurrentRegion() {
    final language = _languageSettings.language;
    if ([
      AppLanguage.vietnamese,
    ].contains(language)) {
      return 'Châu Á';
    } else if ([
      AppLanguage.english,
    ].contains(language)) {
      return 'Châu Âu/Mỹ';
    }
    return 'Khác';
  }

  // Search functionality
  List<AppLanguage> searchLanguages(String query) {
    if (query.isEmpty) return getAllLanguages();

    final lowercaseQuery = query.toLowerCase();
    return getAllLanguages().where((language) {
      return language.nativeName.toLowerCase().contains(lowercaseQuery) ||
          language.englishName.toLowerCase().contains(lowercaseQuery) ||
          language.code.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Validation methods
  bool isRTLLanguage() {
    // Add RTL languages here if needed
    return false;
  }

  bool isAsianLanguage() {
    return getAsianLanguages().contains(_languageSettings.language);
  }

  bool isEuropeanLanguage() {
    return getEuropeanLanguages().contains(_languageSettings.language);
  }

  // Export/Import settings
  Map<String, dynamic> exportSettings() {
    return _languageSettings.toJson();
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      _languageSettings = LanguageSettings.fromJson(settings);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing language settings: $e');
      throw Exception('Không thể nhập cài đặt ngôn ngữ');
    }
  }
}
