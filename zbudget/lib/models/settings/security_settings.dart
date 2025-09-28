import 'package:flutter/material.dart';

enum AuthenticationMethod { password, biometric, pin, pattern }

extension AuthenticationMethodExtension on AuthenticationMethod {
  String get displayName {
    switch (this) {
      case AuthenticationMethod.password:
        return 'Mật khẩu';
      case AuthenticationMethod.biometric:
        return 'Sinh trắc học';
      case AuthenticationMethod.pin:
        return 'Mã PIN';
      case AuthenticationMethod.pattern:
        return 'Hình vẽ';
    }
  }

  IconData get icon {
    switch (this) {
      case AuthenticationMethod.password:
        return Icons.password;
      case AuthenticationMethod.biometric:
        return Icons.fingerprint;
      case AuthenticationMethod.pin:
        return Icons.pin;
      case AuthenticationMethod.pattern:
        return Icons.pattern;
    }
  }

  String get description {
    switch (this) {
      case AuthenticationMethod.password:
        return 'Sử dụng mật khẩu để bảo vệ ứng dụng';
      case AuthenticationMethod.biometric:
        return 'Sử dụng vân tay hoặc khuôn mặt để mở khóa';
      case AuthenticationMethod.pin:
        return 'Sử dụng mã PIN 4-6 số để bảo vệ';
      case AuthenticationMethod.pattern:
        return 'Sử dụng hình vẽ để mở khóa ứng dụng';
    }
  }
}

enum SessionTimeout { never, minutes5, minutes15, minutes30, hour1, hour4 }

extension SessionTimeoutExtension on SessionTimeout {
  String get displayName {
    switch (this) {
      case SessionTimeout.never:
        return 'Không bao giờ';
      case SessionTimeout.minutes5:
        return '5 phút';
      case SessionTimeout.minutes15:
        return '15 phút';
      case SessionTimeout.minutes30:
        return '30 phút';
      case SessionTimeout.hour1:
        return '1 giờ';
      case SessionTimeout.hour4:
        return '4 giờ';
    }
  }

  Duration? get duration {
    switch (this) {
      case SessionTimeout.never:
        return null;
      case SessionTimeout.minutes5:
        return const Duration(minutes: 5);
      case SessionTimeout.minutes15:
        return const Duration(minutes: 15);
      case SessionTimeout.minutes30:
        return const Duration(minutes: 30);
      case SessionTimeout.hour1:
        return const Duration(hours: 1);
      case SessionTimeout.hour4:
        return const Duration(hours: 4);
    }
  }
}

class LoginSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String location;
  final String ipAddress;
  final DateTime loginTime;
  final DateTime lastActiveTime;
  final bool isCurrent;

  const LoginSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.ipAddress,
    required this.loginTime,
    required this.lastActiveTime,
    this.isCurrent = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastActiveTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }

  IconData get deviceIcon {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'android':
      case 'ios':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      case 'web':
      case 'browser':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }

  LoginSession copyWith({
    String? id,
    String? deviceName,
    String? deviceType,
    String? location,
    String? ipAddress,
    DateTime? loginTime,
    DateTime? lastActiveTime,
    bool? isCurrent,
  }) {
    return LoginSession(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      location: location ?? this.location,
      ipAddress: ipAddress ?? this.ipAddress,
      loginTime: loginTime ?? this.loginTime,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'location': location,
    'ipAddress': ipAddress,
    'loginTime': loginTime.toIso8601String(),
    'lastActiveTime': lastActiveTime.toIso8601String(),
    'isCurrent': isCurrent,
  };

  factory LoginSession.fromJson(Map<String, dynamic> json) => LoginSession(
    id: json['id'] ?? '',
    deviceName: json['deviceName'] ?? '',
    deviceType: json['deviceType'] ?? '',
    location: json['location'] ?? '',
    ipAddress: json['ipAddress'] ?? '',
    loginTime: json['loginTime'] != null
        ? DateTime.parse(json['loginTime'])
        : DateTime.now(),
    lastActiveTime: json['lastActiveTime'] != null
        ? DateTime.parse(json['lastActiveTime'])
        : DateTime.now(),
    isCurrent: json['isCurrent'] ?? false,
  );
}

class SecuritySettings {
  final bool isBiometricEnabled;
  final bool isTwoFactorEnabled;
  final bool isAutoLockEnabled;
  final SessionTimeout sessionTimeout;
  final bool isLoginNotificationEnabled;
  final bool isDataEncryptionEnabled;
  final int maxFailedAttempts;
  final bool isScreenshotBlocked;
  final bool isAppPinEnabled;
  final AuthenticationMethod primaryAuthMethod;
  final List<AuthenticationMethod> enabledAuthMethods;
  final DateTime? lastPasswordChange;
  final List<LoginSession> activeSessions;

  const SecuritySettings({
    this.isBiometricEnabled = false,
    this.isTwoFactorEnabled = false,
    this.isAutoLockEnabled = true,
    this.sessionTimeout = SessionTimeout.minutes30,
    this.isLoginNotificationEnabled = true,
    this.isDataEncryptionEnabled = true,
    this.maxFailedAttempts = 5,
    this.isScreenshotBlocked = false,
    this.isAppPinEnabled = false,
    this.primaryAuthMethod = AuthenticationMethod.password,
    this.enabledAuthMethods = const [AuthenticationMethod.password],
    this.lastPasswordChange,
    this.activeSessions = const [],
  });

  bool get isSecure {
    int securityScore = 0;

    if (isBiometricEnabled) securityScore += 2;
    if (isTwoFactorEnabled) securityScore += 3;
    if (isAutoLockEnabled) securityScore += 1;
    if (sessionTimeout != SessionTimeout.never) securityScore += 1;
    if (isDataEncryptionEnabled) securityScore += 2;
    if (maxFailedAttempts <= 5) securityScore += 1;
    if (isScreenshotBlocked) securityScore += 1;

    return securityScore >= 6; // Threshold for "secure"
  }

  String get securityLevel {
    if (!isSecure) return 'Cơ bản';
    if (isTwoFactorEnabled && isBiometricEnabled) return 'Cao';
    return 'Trung bình';
  }

  Color get securityLevelColor {
    switch (securityLevel) {
      case 'Cơ bản':
        return Colors.orange;
      case 'Trung bình':
        return Colors.blue;
      case 'Cao':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get passwordStrengthDescription {
    if (lastPasswordChange == null) {
      return 'Chưa đặt mật khẩu';
    }

    final daysSinceChange = DateTime.now()
        .difference(lastPasswordChange!)
        .inDays;

    if (daysSinceChange > 90) {
      return 'Nên thay đổi mật khẩu ($daysSinceChange ngày)';
    } else if (daysSinceChange > 30) {
      return 'Cân nhắc thay đổi mật khẩu ($daysSinceChange ngày)';
    } else {
      return 'Mật khẩu tốt ($daysSinceChange ngày trước)';
    }
  }

  SecuritySettings copyWith({
    bool? isBiometricEnabled,
    bool? isTwoFactorEnabled,
    bool? isAutoLockEnabled,
    SessionTimeout? sessionTimeout,
    bool? isLoginNotificationEnabled,
    bool? isDataEncryptionEnabled,
    int? maxFailedAttempts,
    bool? isScreenshotBlocked,
    bool? isAppPinEnabled,
    AuthenticationMethod? primaryAuthMethod,
    List<AuthenticationMethod>? enabledAuthMethods,
    DateTime? lastPasswordChange,
    List<LoginSession>? activeSessions,
  }) {
    return SecuritySettings(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      isAutoLockEnabled: isAutoLockEnabled ?? this.isAutoLockEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      isLoginNotificationEnabled:
          isLoginNotificationEnabled ?? this.isLoginNotificationEnabled,
      isDataEncryptionEnabled:
          isDataEncryptionEnabled ?? this.isDataEncryptionEnabled,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      isScreenshotBlocked: isScreenshotBlocked ?? this.isScreenshotBlocked,
      isAppPinEnabled: isAppPinEnabled ?? this.isAppPinEnabled,
      primaryAuthMethod: primaryAuthMethod ?? this.primaryAuthMethod,
      enabledAuthMethods: enabledAuthMethods ?? this.enabledAuthMethods,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      activeSessions: activeSessions ?? this.activeSessions,
    );
  }

  Map<String, dynamic> toJson() => {
    'isBiometricEnabled': isBiometricEnabled,
    'isTwoFactorEnabled': isTwoFactorEnabled,
    'isAutoLockEnabled': isAutoLockEnabled,
    'sessionTimeout': sessionTimeout.name,
    'isLoginNotificationEnabled': isLoginNotificationEnabled,
    'isDataEncryptionEnabled': isDataEncryptionEnabled,
    'maxFailedAttempts': maxFailedAttempts,
    'isScreenshotBlocked': isScreenshotBlocked,
    'isAppPinEnabled': isAppPinEnabled,
    'primaryAuthMethod': primaryAuthMethod.name,
    'enabledAuthMethods': enabledAuthMethods.map((e) => e.name).toList(),
    'lastPasswordChange': lastPasswordChange?.toIso8601String(),
    'activeSessions': activeSessions.map((e) => e.toJson()).toList(),
  };

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        isBiometricEnabled: json['isBiometricEnabled'] ?? false,
        isTwoFactorEnabled: json['isTwoFactorEnabled'] ?? false,
        isAutoLockEnabled: json['isAutoLockEnabled'] ?? true,
        sessionTimeout: SessionTimeout.values.firstWhere(
          (e) => e.name == json['sessionTimeout'],
          orElse: () => SessionTimeout.minutes30,
        ),
        isLoginNotificationEnabled: json['isLoginNotificationEnabled'] ?? true,
        isDataEncryptionEnabled: json['isDataEncryptionEnabled'] ?? true,
        maxFailedAttempts: json['maxFailedAttempts'] ?? 5,
        isScreenshotBlocked: json['isScreenshotBlocked'] ?? false,
        isAppPinEnabled: json['isAppPinEnabled'] ?? false,
        primaryAuthMethod: AuthenticationMethod.values.firstWhere(
          (e) => e.name == json['primaryAuthMethod'],
          orElse: () => AuthenticationMethod.password,
        ),
        enabledAuthMethods: json['enabledAuthMethods'] != null
            ? (json['enabledAuthMethods'] as List)
                  .map(
                    (e) => AuthenticationMethod.values.firstWhere(
                      (method) => method.name == e,
                    ),
                  )
                  .toList()
            : [AuthenticationMethod.password],
        lastPasswordChange: json['lastPasswordChange'] != null
            ? DateTime.parse(json['lastPasswordChange'])
            : null,
        activeSessions: json['activeSessions'] != null
            ? (json['activeSessions'] as List)
                  .map((e) => LoginSession.fromJson(e))
                  .toList()
            : [],
      );
}
