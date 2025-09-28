import 'package:flutter/material.dart';

enum Gender { male, female, other, preferNotToSay }

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
      case Gender.preferNotToSay:
        return 'Không muốn tiết lộ';
    }
  }

  IconData get icon {
    switch (this) {
      case Gender.male:
        return Icons.male;
      case Gender.female:
        return Icons.female;
      case Gender.other:
        return Icons.transgender;
      case Gender.preferNotToSay:
        return Icons.help_outline;
    }
  }
}

class UserStats {
  final double totalSaved;
  final int activeDays;
  final int completedChallenges;
  final int currentLevel;
  final int totalPoints;
  final int streakDays;

  const UserStats({
    this.totalSaved = 0.0,
    this.activeDays = 0,
    this.completedChallenges = 0,
    this.currentLevel = 1,
    this.totalPoints = 0,
    this.streakDays = 0,
  });

  UserStats copyWith({
    double? totalSaved,
    int? activeDays,
    int? completedChallenges,
    int? currentLevel,
    int? totalPoints,
    int? streakDays,
  }) {
    return UserStats(
      totalSaved: totalSaved ?? this.totalSaved,
      activeDays: activeDays ?? this.activeDays,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      currentLevel: currentLevel ?? this.currentLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalSaved': totalSaved,
    'activeDays': activeDays,
    'completedChallenges': completedChallenges,
    'currentLevel': currentLevel,
    'totalPoints': totalPoints,
    'streakDays': streakDays,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalSaved: json['totalSaved']?.toDouble() ?? 0.0,
    activeDays: json['activeDays'] ?? 0,
    completedChallenges: json['completedChallenges'] ?? 0,
    currentLevel: json['currentLevel'] ?? 1,
    totalPoints: json['totalPoints'] ?? 0,
    streakDays: json['streakDays'] ?? 0,
  );
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int pointsReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlockedAt,
    this.isUnlocked = false,
    this.pointsReward = 0,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? pointsReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      pointsReward: pointsReward ?? this.pointsReward,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
    'pointsReward': pointsReward,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    emoji: json['emoji'] ?? '🏆',
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'])
        : null,
    isUnlocked: json['isUnlocked'] ?? false,
    pointsReward: json['pointsReward'] ?? 0,
  );
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final DateTime? birthday;
  final Gender? gender;
  final String? bio;
  final UserStats stats;
  final List<Achievement> achievements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.birthday,
    this.gender,
    this.bio,
    this.stats = const UserStats(),
    this.achievements = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    DateTime? birthday,
    Gender? gender,
    String? bio,
    UserStats? stats,
    List<Achievement>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    final names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0].substring(0, 1)}${names[names.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  int get age {
    if (birthday == null) return 0;
    final now = DateTime.now();
    final age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      return age - 1;
    }
    return age;
  }

  String get levelTitle {
    final level = stats.currentLevel;
    if (level <= 5) return 'Người mới bắt đầu';
    if (level <= 10) return 'Tiết kiệm cơ bản';
    if (level <= 20) return 'Tiết kiệm thông minh';
    if (level <= 35) return 'Chuyên gia tiết kiệm';
    if (level <= 50) return 'Bậc thầy tài chính';
    return 'Huyền thoại ZBudget';
  }

  Color get levelColor {
    final level = stats.currentLevel;
    if (level <= 5) return Colors.grey;
    if (level <= 10) return Colors.green;
    if (level <= 20) return Colors.blue;
    if (level <= 35) return Colors.purple;
    if (level <= 50) return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'birthday': birthday?.toIso8601String(),
    'gender': gender?.name,
    'bio': bio,
    'stats': stats.toJson(),
    'achievements': achievements.map((a) => a.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    avatar: json['avatar'],
    birthday: json['birthday'] != null
        ? DateTime.parse(json['birthday'])
        : null,
    gender: json['gender'] != null
        ? Gender.values.firstWhere((g) => g.name == json['gender'])
        : null,
    bio: json['bio'],
    stats: json['stats'] != null
        ? UserStats.fromJson(json['stats'])
        : const UserStats(),
    achievements: json['achievements'] != null
        ? (json['achievements'] as List)
              .map((a) => Achievement.fromJson(a))
              .toList()
        : [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );
}
