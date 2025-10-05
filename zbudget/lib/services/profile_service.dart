import 'package:flutter/widgets.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../models/settings/user_profile.dart';
import '../utils/auth_utils.dart';
import 'profile_api_service.dart';
import 'image_upload_service.dart';

class ProfileService extends ChangeNotifier {
  static const String _profileKey = 'user_profile';
  static const String _lastSyncKey = 'profile_last_sync';

  UserProfile? _currentProfile;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastSync;

  final ProfileApiService _apiService = ProfileApiService();

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSync => _lastSync;

  // Initialize with backend sync or local fallback
  Future<void> initialize() async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final isAuthenticated = await AuthUtils.isAuthenticated();
      print('ProfileService.initialize: authenticated = $isAuthenticated');

      if (isAuthenticated) {
        print(
          'ProfileService.initialize: Clearing local storage to force sync...',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_profileKey);

        print('ProfileService.initialize: Trying server sync...');
        final syncSuccess = await _syncWithServer();

        if (!syncSuccess) {
          print(
            'ProfileService.initialize: Server sync failed, no profile loaded',
          );
          _currentProfile = null;
        }
      } else {
        print('ProfileService.initialize: Not authenticated, loading local...');
        await _loadLocalProfile();
        if (_currentProfile == null) {
          print(
            'ProfileService.initialize: No local profile, no profile loaded',
          );
        }
      }

      _clearError();
    } catch (e) {
      _setError('Failed to initialize profile: $e');
      debugPrint('ProfileService initialization error: $e');
      _currentProfile = null;
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Sync profile with server
  Future<bool> syncWithServer() async {
    if (!await AuthUtils.isAuthenticated()) return false;

    _setSyncing(true);
    try {
      return await _syncWithServer();
    } finally {
      _setSyncing(false);
    }
  }

  Future<bool> _syncWithServer() async {
    try {
      print('ProfileService: Attempting to sync with server...');
      final backendData = await _apiService.getProfile();
      print('ProfileService: Backend data received: $backendData');

      if (backendData != null) {
        final serverProfile = _apiService.mapBackendToUserProfile(backendData);
        print('ProfileService: Mapped profile: ${serverProfile?.name}');

        if (serverProfile != null) {
          _currentProfile = serverProfile;
          await _saveLocalProfile();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
          print(
            'ProfileService: Sync successful - Profile name: ${serverProfile.name}',
          );
          return true;
        }
      }
      print('ProfileService: Sync failed - no data or mapping failed');
      return false;
    } catch (e) {
      print('Failed to sync profile with server: $e');
      return false;
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

  Future<void> updateProfile(
    UserProfile updatedProfile, {
    bool syncToServer = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentProfile = updatedProfile.copyWith(updatedAt: DateTime.now());

      // Save locally first
      await _saveLocalProfile();

      // Sync to server if authenticated and requested
      if (syncToServer && await AuthUtils.isAuthenticated()) {
        final profilePayload = _apiService.mapUserProfileToBackend(
          _currentProfile!,
        );
        final success = await _apiService.updateProfile(
          name: profilePayload['name'],
          phone: profilePayload['phone'],
          dateOfBirth: _currentProfile!.birthday,
          gender: _currentProfile!.gender,
          location: profilePayload['location'],
        );

        if (success) {
          _lastSync = DateTime.now();
          await _saveLastSync();
        }
      }
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
      // TODO: Upload to server and get URL in real implementation
      // For now, we'll just store the file path locally
      final avatarPath = imageFile.path;

      _currentProfile = _currentProfile!.copyWith(
        avatar: avatarPath,
        updatedAt: DateTime.now(),
      );

      await _saveLocalProfile();

      // TODO: Upload to server when avatar upload endpoint is ready
      // if (await AuthUtils.isAuthenticated()) {
      //   await _apiService.updateAvatar(avatarUrl);
      // }
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update avatar with URL (for server uploads)
  Future<void> updateAvatarUrl(String avatarUrl) async {
    if (_currentProfile == null) return;

    try {
      if (await AuthUtils.isAuthenticated()) {
        final success = await _apiService.updateAvatar(avatarUrl);
        if (success) {
          _currentProfile = _currentProfile!.copyWith(
            avatar: avatarUrl,
            updatedAt: DateTime.now(),
          );
          await _saveLocalProfile();
          _lastSync = DateTime.now();
          await _saveLastSync();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating avatar URL: $e');
      rethrow;
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

  Future<void> _saveLocalProfile() async {
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

  Future<void> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _currentProfile = UserProfile.fromJson(profileData);
      }

      // Load last sync time
      final lastSyncMillis = prefs.getInt(_lastSyncKey);
      if (lastSyncMillis != null) {
        _lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
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

  // Avatar upload methods
  Future<bool> uploadAvatar(File imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await ImageUploadService.uploadAvatar(imageFile);

      if (result != null && result['success'] == true) {
        // Update current profile with new avatar
        if (_currentProfile != null) {
          _currentProfile = _currentProfile!.copyWith(
            avatar: result['data']?['avatar'],
          );
          await _saveLocalProfile();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error uploading avatar: $e');
      _errorMessage = 'Lỗi tải ảnh lên: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAvatar() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await ImageUploadService.deleteAvatar();

      if (success && _currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(avatar: null);
        await _saveLocalProfile();
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error deleting avatar: $e');
      _errorMessage = 'Lỗi xóa ảnh: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        await uploadAvatar(imageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      _errorMessage = 'Lỗi chọn ảnh: $e';
      notifyListeners();
    }
  }
}
