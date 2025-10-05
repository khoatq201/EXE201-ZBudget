import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/settings/user_profile.dart';
import '../utils/auth_utils.dart';

/// Service for managing user profile through backend API
class ProfileApiService {
  static const String _profileEndpoint = '/settings/profile';
  static const String _statsEndpoint = '/settings/profile/stats';

  /// Get user profile from backend
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) {
        print('ProfileApiService: No auth token found');
        return null;
      }

      print(
        'ProfileApiService: Getting profile from ${ApiConfig.baseUrl}$_profileEndpoint',
      );
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$_profileEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ProfileApiService: Response status: ${response.statusCode}');
      print('ProfileApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    Gender? gender,
    Map<String, String>? location,
  }) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (phone != null) payload['phone'] = phone;
      if (dateOfBirth != null)
        payload['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (gender != null) payload['gender'] = gender.name;
      if (location != null) payload['location'] = location;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$_profileEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Update user avatar
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$_profileEndpoint/avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'avatar': avatarUrl}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating avatar: $e');
      return false;
    }
  }

  /// Get user stats from backend
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$_statsEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting stats: $e');
      return null;
    }
  }

  /// Update user stats
  Future<bool> updateStats({
    int? level,
    int? points,
    int? currentStreak,
    int? longestStreak,
    double? totalSaved,
    int? challengesCompleted,
    String? rank,
  }) async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return false;

      final payload = <String, dynamic>{};
      if (level != null) payload['level'] = level;
      if (points != null) payload['points'] = points;
      if (currentStreak != null) payload['currentStreak'] = currentStreak;
      if (longestStreak != null) payload['longestStreak'] = longestStreak;
      if (totalSaved != null) payload['totalSaved'] = totalSaved;
      if (challengesCompleted != null)
        payload['challengesCompleted'] = challengesCompleted;
      if (rank != null) payload['rank'] = rank;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$_statsEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating stats: $e');
      return false;
    }
  }

  /// Calculate and update stats automatically
  Future<Map<String, dynamic>?> calculateStats() async {
    try {
      final token = await AuthUtils.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$_profileEndpoint/calculate-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error calculating stats: $e');
      return null;
    }
  }

  /// Map backend profile data to UserProfile model
  UserProfile? mapBackendToUserProfile(Map<String, dynamic> backendData) {
    try {
      print('ProfileApiService: Mapping backend data: $backendData');

      final profile = backendData['profile'] ?? {};
      final stats = backendData['stats'] ?? {};

      // Parse gender
      Gender gender = Gender.other;
      final genderStr = profile['gender'] as String?;
      if (genderStr != null) {
        switch (genderStr) {
          case 'male':
            gender = Gender.male;
            break;
          case 'female':
            gender = Gender.female;
            break;
          case 'other':
            gender = Gender.other;
            break;
          default:
            gender = Gender.preferNotToSay;
        }
      }

      // Parse date of birth - handle MongoDB date field
      DateTime? birthday;
      final dobField = profile['dateOfBirth'];
      if (dobField != null) {
        if (dobField is String) {
          birthday = DateTime.tryParse(dobField);
        } else if (dobField is Map && dobField['\$date'] != null) {
          // Handle MongoDB date format: {"$date": "2000-01-19T17:00:00Z"}
          birthday = DateTime.tryParse(dobField['\$date']);
        }
      }

      // Parse decimal128 for totalSaved
      double totalSaved = 0.0;
      final savedField = stats['totalSaved'];
      if (savedField != null) {
        if (savedField is num) {
          totalSaved = savedField.toDouble();
        } else if (savedField is Map && savedField['\$numberDecimal'] != null) {
          // Handle MongoDB Decimal128 format: {"$numberDecimal": "0"}
          totalSaved = double.tryParse(savedField['\$numberDecimal']) ?? 0.0;
        }
      }

      // Map stats with correct field names from MongoDB
      final userStats = UserStats(
        totalSaved: totalSaved,
        activeDays:
            stats['activeDays'] ?? 0, // TODO: Calculate from actual activity
        completedChallenges: stats['challengesCompleted'] ?? 0,
        currentLevel: stats['level'] ?? 1,
        totalPoints: stats['points'] ?? 0,
        streakDays: stats['currentStreak'] ?? 0,
      );

      final userProfile = UserProfile(
        id: backendData['_id'] ?? '',
        name: profile['name'] ?? '',
        email: backendData['email'] ?? '',
        phone: profile['phone'] ?? '',
        avatar: profile['avatar'],
        birthday: birthday,
        gender: gender,
        bio: profile['bio'] ?? '',
        stats: userStats,
        achievements: [], // TODO: Implement achievements from backend
        createdAt:
            DateTime.tryParse(backendData['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(backendData['updatedAt'] ?? '') ?? DateTime.now(),
      );

      print(
        'ProfileApiService: Mapped UserProfile: ${userProfile.name} (${userProfile.id})',
      );
      return userProfile;
    } catch (e) {
      print('Error mapping backend data to UserProfile: $e');
      print('Backend data: $backendData'); // Debug log
      return null;
    }
  }

  /// Map UserProfile to backend payload
  Map<String, dynamic> mapUserProfileToBackend(UserProfile profile) {
    final location = <String, String>{
      'country': 'Vietnam', // Default
    };

    return {
      'name': profile.name,
      'phone': profile.phone,
      'dateOfBirth': profile.birthday?.toIso8601String(),
      'gender': profile.gender?.name ?? 'other',
      'location': location,
    };
  }
}
