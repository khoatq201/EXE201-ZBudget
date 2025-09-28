import 'package:flutter/material.dart';

enum ChallengeDifficulty { easy, medium, hard }

enum ChallengeStatus { available, active, completed }

enum ChallengeCategory {
  drinks,
  food,
  transport,
  shopping,
  entertainment,
  special,
  digital,
}

class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final DateTime date;
  final double amountSaved;
  final String note;
  final List<String> proofImages;
  final bool isVerified;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.date,
    required this.amountSaved,
    this.note = '',
    this.proofImages = const [],
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'date': date.toIso8601String(),
      'amountSaved': amountSaved,
      'note': note,
      'proofImages': proofImages,
      'isVerified': isVerified,
    };
  }

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      id: json['id'],
      challengeId: json['challengeId'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      amountSaved: json['amountSaved'].toDouble(),
      note: json['note'] ?? '',
      proofImages: List<String>.from(json['proofImages'] ?? []),
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class ChallengeMilestone {
  final int day;
  final double targetAmount;
  final String reward;
  final bool isCompleted;
  final String description;

  ChallengeMilestone({
    required this.day,
    required this.targetAmount,
    required this.reward,
    this.isCompleted = false,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'targetAmount': targetAmount,
      'reward': reward,
      'isCompleted': isCompleted,
      'description': description,
    };
  }

  factory ChallengeMilestone.fromJson(Map<String, dynamic> json) {
    return ChallengeMilestone(
      day: json['day'],
      targetAmount: json['targetAmount'].toDouble(),
      reward: json['reward'],
      isCompleted: json['isCompleted'] ?? false,
      description: json['description'],
    );
  }
}

class Challenge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int participants;
  final String duration;
  final int amount;
  final ChallengeDifficulty difficulty;
  final int points;
  final ChallengeStatus status;
  final ChallengeCategory category;
  final int? progress;
  final DateTime? startDate;
  final List<ChallengeMilestone> milestones;
  final double? currentSaved;
  final int? streakDays;
  final DateTime? endDate;
  final int? currentSavings;
  final int? streak;
  final String? badgeIcon;
  final DateTime? completedAt;

  Challenge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.participants,
    required this.duration,
    required this.amount,
    required this.difficulty,
    required this.points,
    required this.status,
    required this.category,
    this.progress,
    this.startDate,
    this.endDate,
    this.currentSavings,
    this.streak,
    this.badgeIcon,
    this.completedAt,
    this.milestones = const [],
    this.currentSaved,
    this.streakDays,
  });

  Challenge copyWith({
    String? id,
    String? emoji,
    String? title,
    String? description,
    int? participants,
    String? duration,
    int? amount,
    ChallengeDifficulty? difficulty,
    int? points,
    ChallengeStatus? status,
    ChallengeCategory? category,
    int? progress,
    DateTime? startDate,
    DateTime? endDate,
    int? currentSavings,
    int? streak,
    String? badgeIcon,
    DateTime? completedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      duration: duration ?? this.duration,
      amount: amount ?? this.amount,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      status: status ?? this.status,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentSavings: currentSavings ?? this.currentSavings,
      streak: streak ?? this.streak,
      badgeIcon: badgeIcon ?? this.badgeIcon,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class UserStats {
  final int streak;
  final int level;
  final int points;
  final int totalChallengesCompleted;
  final int totalSavings;
  final int rank;
  final int nextLevelPoints;

  UserStats({
    required this.streak,
    required this.level,
    required this.points,
    required this.totalChallengesCompleted,
    required this.totalSavings,
    required this.rank,
    required this.nextLevelPoints,
  });
}

class ChallengeCategoryModel {
  final String id;
  final String name;
  final String icon;
  final Color color;

  ChallengeCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
