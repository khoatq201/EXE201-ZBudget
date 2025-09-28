import 'package:flutter/widgets.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../models/settings/user_profile.dart';

class ProfileService extends ChangeNotifier {
  static const String _profileKey = 'user_profile';
  UserProfile? _currentProfile;
  bool _isLoading = false;

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;

  // Initialize with sample data for demo
  Future<void> initialize() async {
    _isLoading = true;
    // Defer notifyListeners to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _currentProfile = UserProfile.fromJson(profileData);
      } else {
        // Create demo profile
        _currentProfile = _createDemoProfile();
        await _saveProfile();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _currentProfile = _createDemoProfile();
    } finally {
      _isLoading = false;
      // Defer notifyListeners to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  UserProfile _createDemoProfile() {
    return UserProfile(
      id: 'demo_user_001',
      name: 'Nguyễn Văn Nam',
      email: 'nam.nguyen@example.com',
      phone: '0987654321',
      birthday: DateTime(1995, 6, 15),
      gender: Gender.male,
      bio:
          'Đam mê tiết kiệm và đầu tư thông minh. Mục tiêu mua nhà trong 2 năm tới! 🏠💰',
      stats: const UserStats(
        totalSaved: 15750000,
        activeDays: 125,
        completedChallenges: 8,
        currentLevel: 12,
        totalPoints: 2450,
        streakDays: 23,
      ),
      achievements: _getDemoAchievements(),
      createdAt: DateTime.now().subtract(const Duration(days: 125)),
      updatedAt: DateTime.now(),
    );
  }

  List<Achievement> _getDemoAchievements() {
    return [
      Achievement(
        id: 'first_save',
        title: 'Bước đầu tiết kiệm',
        description: 'Hoàn thành challenge đầu tiên',
        emoji: '🌱',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 120)),
        pointsReward: 50,
      ),
      Achievement(
        id: 'coffee_master',
        title: 'Cà phê Master',
        description: 'Tiết kiệm 100,000đ từ việc pha cà phê tại nhà',
        emoji: '☕',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 100)),
        pointsReward: 100,
      ),
      Achievement(
        id: 'streak_warrior',
        title: 'Chiến binh Streak',
        description: 'Duy trì streak 30 ngày',
        emoji: '🔥',
        isUnlocked: false,
        pointsReward: 200,
      ),
      Achievement(
        id: 'million_saver',
        title: 'Triệu phú nhí',
        description: 'Tiết kiệm được 10 triệu đồng',
        emoji: '💰',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
        pointsReward: 500,
      ),
      Achievement(
        id: 'challenge_champion',
        title: 'Vô địch Challenge',
        description: 'Hoàn thành 10 challenges',
        emoji: '🏆',
        isUnlocked: false,
        pointsReward: 300,
      ),
      Achievement(
        id: 'social_butterfly',
        title: 'Kết nối xã hội',
        description: 'Tham gia 5 group challenges',
        emoji: '🦋',
        isUnlocked: false,
        pointsReward: 150,
      ),
    ];
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentProfile = updatedProfile.copyWith(updatedAt: DateTime.now());
      await _saveProfile();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(File? imageFile) async {
    if (_currentProfile == null || imageFile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, you would upload to a server
      // For demo, we'll just store the file path
      final avatarPath = imageFile.path;

      _currentProfile = _currentProfile!.copyWith(
        avatar: avatarPath,
        updatedAt: DateTime.now(),
      );

      await _saveProfile();
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<void> updatePersonalInfo({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
    Gender? gender,
    String? bio,
  }) async {
    if (_currentProfile == null) return;

    await updateProfile(
      _currentProfile!.copyWith(
        name: name ?? _currentProfile!.name,
        email: email ?? _currentProfile!.email,
        phone: phone ?? _currentProfile!.phone,
        birthday: birthday ?? _currentProfile!.birthday,
        gender: gender ?? _currentProfile!.gender,
        bio: bio ?? _currentProfile!.bio,
      ),
    );
  }

  Future<void> unlockAchievement(String achievementId) async {
    if (_currentProfile == null) return;

    final achievements = _currentProfile!.achievements.map((achievement) {
      if (achievement.id == achievementId && !achievement.isUnlocked) {
        return achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
      return achievement;
    }).toList();

    final unlockedAchievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => achievements.first,
    );

    // Update stats with achievement points
    final newStats = _currentProfile!.stats.copyWith(
      totalPoints:
          _currentProfile!.stats.totalPoints + unlockedAchievement.pointsReward,
    );

    await updateProfile(
      _currentProfile!.copyWith(achievements: achievements, stats: newStats),
    );
  }

  Future<void> updateStats({
    double? totalSaved,
    int? activeDays,
    int? completedChallenges,
    int? currentLevel,
    int? totalPoints,
    int? streakDays,
  }) async {
    if (_currentProfile == null) return;

    final newStats = _currentProfile!.stats.copyWith(
      totalSaved: totalSaved ?? _currentProfile!.stats.totalSaved,
      activeDays: activeDays ?? _currentProfile!.stats.activeDays,
      completedChallenges:
          completedChallenges ?? _currentProfile!.stats.completedChallenges,
      currentLevel: currentLevel ?? _currentProfile!.stats.currentLevel,
      totalPoints: totalPoints ?? _currentProfile!.stats.totalPoints,
      streakDays: streakDays ?? _currentProfile!.stats.streakDays,
    );

    await updateProfile(_currentProfile!.copyWith(stats: newStats));
  }

  Future<void> _saveProfile() async {
    if (_currentProfile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(_currentProfile!.toJson());
      await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      _currentProfile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing profile: $e');
    }
  }

  // Helper methods for formatting
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    } else {
      return '${amount.toStringAsFixed(0)} đ';
    }
  }

  String formatDuration(int days) {
    if (days >= 365) {
      final years = (days / 365).floor();
      final remainingDays = days % 365;
      if (remainingDays == 0) {
        return '$years năm';
      } else {
        return '$years năm $remainingDays ngày';
      }
    } else if (days >= 30) {
      final months = (days / 30).floor();
      final remainingDays = days % 30;
      if (remainingDays == 0) {
        return '$months tháng';
      } else {
        return '$months tháng $remainingDays ngày';
      }
    } else {
      return '$days ngày';
    }
  }
}
