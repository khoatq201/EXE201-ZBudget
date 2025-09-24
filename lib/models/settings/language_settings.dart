enum AppLanguage {
  vietnamese('vi', 'VI', 'Tiếng Việt', 'Vietnamese', '🇻🇳'),
  english('en', 'EN', 'English', 'English', '🇺🇸'),
  japanese('ja', 'JP', '日本語', 'Japanese', '🇯🇵'),
  korean('ko', 'KR', '한국어', 'Korean', '🇰🇷'),
  chinese('zh', 'CN', '中文', 'Chinese (Simplified)', '🇨🇳'),
  french('fr', 'FR', 'Français', 'French', '🇫🇷'),
  german('de', 'DE', 'Deutsch', 'German', '🇩🇪'),
  spanish('es', 'ES', 'Español', 'Spanish', '🇪🇸');

  const AppLanguage(
    this.code,
    this.countryCode,
    this.nativeName,
    this.englishName,
    this.flag,
  );

  final String code;
  final String countryCode;
  final String nativeName;
  final String englishName;
  final String flag;
}

enum DateFormat {
  ddMMyyyy('dd/MM/yyyy', 'DD/MM/YYYY'),
  mmDdYyyy('MM/dd/yyyy', 'MM/DD/YYYY'),
  yyyyMmDd('yyyy-MM-dd', 'YYYY-MM-DD'),
  ddMmmYyyy('dd MMM yyyy', 'DD MMM YYYY');

  const DateFormat(this.pattern, this.display);

  final String pattern;
  final String display;
}

enum NumberFormat {
  comma('comma', '1,234.56', 'Dấu phẩy'),
  dot('dot', '1.234,56', 'Dấu chấm'),
  space('space', '1 234.56', 'Dấu cách'),
  indian('indian', '1,23,456.78', 'Ấn Độ');

  const NumberFormat(this.id, this.example, this.displayName);

  final String id;
  final String example;
  final String displayName;
}

enum CurrencyFormat {
  before('before', 'VND 100,000', 'Trước số'),
  after('after', '100,000 VND', 'Sau số'),
  beforeWithSpace('beforeSpace', 'VND 100,000', 'Trước số có khoảng cách'),
  afterWithSpace('afterSpace', '100,000 VND', 'Sau số có khoảng cách');

  const CurrencyFormat(this.id, this.example, this.displayName);

  final String id;
  final String example;
  final String displayName;
}

class LanguageSettings {
  final AppLanguage language;
  final DateFormat dateFormat;
  final NumberFormat numberFormat;
  final CurrencyFormat currencyFormat;
  final bool use24HourFormat;
  final bool useLocalizedNumbers;
  final String timeZone;
  final bool autoDetectLanguage;

  const LanguageSettings({
    this.language = AppLanguage.vietnamese,
    this.dateFormat = DateFormat.ddMMyyyy,
    this.numberFormat = NumberFormat.comma,
    this.currencyFormat = CurrencyFormat.afterWithSpace,
    this.use24HourFormat = true,
    this.useLocalizedNumbers = true,
    this.timeZone = 'Asia/Ho_Chi_Minh',
    this.autoDetectLanguage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language.code,
      'dateFormat': dateFormat.pattern,
      'numberFormat': numberFormat.id,
      'currencyFormat': currencyFormat.id,
      'use24HourFormat': use24HourFormat,
      'useLocalizedNumbers': useLocalizedNumbers,
      'timeZone': timeZone,
      'autoDetectLanguage': autoDetectLanguage,
    };
  }

  factory LanguageSettings.fromJson(Map<String, dynamic> json) {
    return LanguageSettings(
      language: AppLanguage.values.firstWhere(
        (lang) => lang.code == json['language'],
        orElse: () => AppLanguage.vietnamese,
      ),
      dateFormat: DateFormat.values.firstWhere(
        (format) => format.pattern == json['dateFormat'],
        orElse: () => DateFormat.ddMMyyyy,
      ),
      numberFormat: NumberFormat.values.firstWhere(
        (format) => format.id == json['numberFormat'],
        orElse: () => NumberFormat.comma,
      ),
      currencyFormat: CurrencyFormat.values.firstWhere(
        (format) => format.id == json['currencyFormat'],
        orElse: () => CurrencyFormat.afterWithSpace,
      ),
      use24HourFormat: json['use24HourFormat'] ?? true,
      useLocalizedNumbers: json['useLocalizedNumbers'] ?? true,
      timeZone: json['timeZone'] ?? 'Asia/Ho_Chi_Minh',
      autoDetectLanguage: json['autoDetectLanguage'] ?? false,
    );
  }

  LanguageSettings copyWith({
    AppLanguage? language,
    DateFormat? dateFormat,
    NumberFormat? numberFormat,
    CurrencyFormat? currencyFormat,
    bool? use24HourFormat,
    bool? useLocalizedNumbers,
    String? timeZone,
    bool? autoDetectLanguage,
  }) {
    return LanguageSettings(
      language: language ?? this.language,
      dateFormat: dateFormat ?? this.dateFormat,
      numberFormat: numberFormat ?? this.numberFormat,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      useLocalizedNumbers: useLocalizedNumbers ?? this.useLocalizedNumbers,
      timeZone: timeZone ?? this.timeZone,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageSettings &&
        other.language == language &&
        other.dateFormat == dateFormat &&
        other.numberFormat == numberFormat &&
        other.currencyFormat == currencyFormat &&
        other.use24HourFormat == use24HourFormat &&
        other.useLocalizedNumbers == useLocalizedNumbers &&
        other.timeZone == timeZone &&
        other.autoDetectLanguage == autoDetectLanguage;
  }

  @override
  int get hashCode {
    return Object.hash(
      language,
      dateFormat,
      numberFormat,
      currencyFormat,
      use24HourFormat,
      useLocalizedNumbers,
      timeZone,
      autoDetectLanguage,
    );
  }

  // Utility methods
  String get displayName => language.nativeName;
  String get flagEmoji => language.flag;

  String formatDate(DateTime date) {
    // Simple date formatting - in real app you'd use intl package
    switch (dateFormat) {
      case DateFormat.ddMMyyyy:
        return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
      case DateFormat.mmDdYyyy:
        return '${_pad(date.month)}/${_pad(date.day)}/${date.year}';
      case DateFormat.yyyyMmDd:
        return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
      case DateFormat.ddMmmYyyy:
        return '${_pad(date.day)} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    String formattedInteger;
    switch (numberFormat) {
      case NumberFormat.comma:
        formattedInteger = _addSeparator(integerPart, ',');
        return '$formattedInteger.$decimalPart';
      case NumberFormat.dot:
        formattedInteger = _addSeparator(integerPart, '.');
        return '$formattedInteger,$decimalPart';
      case NumberFormat.space:
        formattedInteger = _addSeparator(integerPart, ' ');
        return '$formattedInteger.$decimalPart';
      case NumberFormat.indian:
        formattedInteger = _addIndianSeparator(integerPart);
        return '$formattedInteger.$decimalPart';
    }
  }

  String formatCurrency(double amount, String currencySymbol) {
    final formattedAmount = formatNumber(amount);

    switch (currencyFormat) {
      case CurrencyFormat.before:
        return '$currencySymbol$formattedAmount';
      case CurrencyFormat.after:
        return '$formattedAmount$currencySymbol';
      case CurrencyFormat.beforeWithSpace:
        return '$currencySymbol $formattedAmount';
      case CurrencyFormat.afterWithSpace:
        return '$formattedAmount $currencySymbol';
    }
  }

  String formatTime(DateTime time) {
    if (use24HourFormat) {
      return '${_pad(time.hour)}:${_pad(time.minute)}';
    } else {
      final hour = time.hour == 0
          ? 12
          : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${_pad(hour)}:${_pad(time.minute)} $period';
    }
  }

  String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _addSeparator(String number, String separator) {
    final reversed = number.split('').reversed.toList();
    final separated = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        separated.add(separator);
      }
      separated.add(reversed[i]);
    }

    return separated.reversed.join('');
  }

  String _addIndianSeparator(String number) {
    if (number.length <= 3) return number;

    final reversed = number.split('').reversed.toList();
    final separated = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i == 3) {
        separated.add(',');
      } else if (i > 3 && (i - 3) % 2 == 0) {
        separated.add(',');
      }
      separated.add(reversed[i]);
    }

    return separated.reversed.join('');
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
