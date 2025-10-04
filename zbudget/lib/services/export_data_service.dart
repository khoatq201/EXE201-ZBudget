import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../models/settings/user_profile.dart';

class ExportDataService {
  /// Xuất dữ liệu profile dưới dạng JSON
  static Future<void> exportProfileAsJSON(UserProfile profile) async {
    try {
      final profileData = {
        'profile': {
          'id': profile.id,
          'name': profile.name,
          'email': profile.email,
          'phone': profile.phone,
          'bio': profile.bio,
          'gender': profile.gender?.displayName,
          'birthday': profile.birthday?.toIso8601String(),
          'avatar': profile.avatar,
          'createdAt': profile.createdAt.toIso8601String(),
          'updatedAt': profile.updatedAt.toIso8601String(),
        },
        'stats': {
          'totalSaved': profile.stats.totalSaved,
          'activeDays': profile.stats.activeDays,
          'completedChallenges': profile.stats.completedChallenges,
          'currentLevel': profile.stats.currentLevel,
          'totalPoints': profile.stats.totalPoints,
          'streakDays': profile.stats.streakDays,
        },
        'achievements': profile.achievements
            .map(
              (achievement) => {
                'id': achievement.id,
                'title': achievement.title,
                'description': achievement.description,
                'emoji': achievement.emoji,
                'unlockedAt': achievement.unlockedAt?.toIso8601String(),
                'isUnlocked': achievement.isUnlocked,
                'pointsReward': achievement.pointsReward,
              },
            )
            .toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(profileData);
      final fileName =
          'profile_${profile.name}_${DateTime.now().millisecondsSinceEpoch}.json';

      await _saveAndShareFile(jsonString, fileName, 'application/json');
    } catch (e) {
      throw Exception('Lỗi khi xuất dữ liệu JSON: $e');
    }
  }

  /// Xuất dữ liệu profile dưới dạng CSV
  static Future<void> exportProfileAsCSV(UserProfile profile) async {
    try {
      // Tạo header và data cho CSV
      List<List<dynamic>> csvData = [
        // Header
        ['Loại dữ liệu', 'Tên trường', 'Giá trị', 'Đơn vị'],

        // Thông tin cá nhân
        ['Thông tin cá nhân', 'ID', profile.id, ''],
        ['Thông tin cá nhân', 'Tên', profile.name, ''],
        ['Thông tin cá nhân', 'Email', profile.email, ''],
        ['Thông tin cá nhân', 'Số điện thoại', profile.phone ?? '', ''],
        [
          'Thông tin cá nhân',
          'Giới tính',
          profile.gender?.displayName ?? '',
          '',
        ],
        [
          'Thông tin cá nhân',
          'Sinh nhật',
          profile.birthday?.toIso8601String() ?? '',
          '',
        ],
        ['Thông tin cá nhân', 'Tiểu sử', profile.bio ?? '', ''],
        [
          'Thông tin cá nhân',
          'Ngày tạo',
          profile.createdAt.toIso8601String(),
          '',
        ],
        [
          'Thông tin cá nhân',
          'Ngày cập nhật',
          profile.updatedAt.toIso8601String(),
          '',
        ],

        // Thống kê
        [
          'Thống kê',
          'Tổng tiết kiệm',
          profile.stats.totalSaved.toString(),
          'VND',
        ],
        [
          'Thống kê',
          'Số ngày hoạt động',
          profile.stats.activeDays.toString(),
          'ngày',
        ],
        [
          'Thống kê',
          'Thử thách hoàn thành',
          profile.stats.completedChallenges.toString(),
          'thử thách',
        ],
        [
          'Thống kê',
          'Cấp độ hiện tại',
          profile.stats.currentLevel.toString(),
          'level',
        ],
        ['Thống kê', 'Tổng điểm', profile.stats.totalPoints.toString(), 'điểm'],
        [
          'Thống kê',
          'Chuỗi ngày liên tiếp',
          profile.stats.streakDays.toString(),
          'ngày',
        ],
      ];

      // Thêm thành tích
      for (var achievement in profile.achievements) {
        csvData.add([
          'Thành tích',
          achievement.title,
          achievement.description,
          achievement.unlockedAt?.toIso8601String() ?? 'Chưa mở khóa',
        ]);
      }

      // Thêm thông tin xuất
      csvData.add([
        'Thông tin xuất',
        'Ngày xuất',
        DateTime.now().toIso8601String(),
        '',
      ]);

      String csvString = const ListToCsvConverter().convert(csvData);
      final fileName =
          'profile_${profile.name}_${DateTime.now().millisecondsSinceEpoch}.csv';

      await _saveAndShareFile(csvString, fileName, 'text/csv');
    } catch (e) {
      throw Exception('Lỗi khi xuất dữ liệu CSV: $e');
    }
  }

  /// Xuất dữ liệu thống kê chi tiết
  static Future<void> exportDetailedStats(UserProfile profile) async {
    try {
      final statsData = {
        'userInfo': {
          'name': profile.name,
          'email': profile.email,
          'level': profile.stats.currentLevel,
        },
        'financialStats': {
          'totalSaved': profile.stats.totalSaved,
          'savingsGoalProgress': _calculateSavingsProgress(profile.stats),
          'averageDailySavings': _calculateAverageDailySavings(profile.stats),
        },
        'activityStats': {
          'activeDays': profile.stats.activeDays,
          'streakDays': profile.stats.streakDays,
          'longestStreak':
              profile.stats.streakDays, // Có thể cần API để lấy streak dài nhất
          'activityRate': _calculateActivityRate(profile.stats),
        },
        'challengeStats': {
          'completedChallenges': profile.stats.completedChallenges,
          'successRate': _calculateChallengeSuccessRate(profile.stats),
          'totalPoints': profile.stats.totalPoints,
          'averagePointsPerChallenge': _calculateAveragePointsPerChallenge(
            profile.stats,
          ),
        },
        'achievements': {
          'totalAchievements': profile.achievements.length,
          'unlockedAchievements': profile.achievements
              .where((a) => a.unlockedAt != null)
              .length,
          'achievementsList': profile.achievements
              .map(
                (a) => {
                  'id': a.id,
                  'title': a.title,
                  'description': a.description,
                  'emoji': a.emoji,
                  'unlockedAt': a.unlockedAt?.toIso8601String(),
                  'isUnlocked': a.isUnlocked,
                  'pointsReward': a.pointsReward,
                },
              )
              .toList(),
        },
        'reportGeneratedAt': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(statsData);
      final fileName =
          'detailed_stats_${profile.name}_${DateTime.now().millisecondsSinceEpoch}.json';

      await _saveAndShareFile(jsonString, fileName, 'application/json');
    } catch (e) {
      throw Exception('Lỗi khi xuất thống kê chi tiết: $e');
    }
  }

  /// Hiển thị dialog chọn định dạng xuất
  static void showExportDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xuất dữ liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn định dạng để xuất dữ liệu profile:'),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                icon: Icons.code,
                title: 'Xuất JSON',
                subtitle: 'Dữ liệu đầy đủ dạng JSON',
                onTap: () async {
                  Navigator.pop(context);
                  await _showProgressDialog(
                    context,
                    () => exportProfileAsJSON(profile),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                context,
                icon: Icons.table_chart,
                title: 'Xuất CSV',
                subtitle: 'Dữ liệu dạng bảng Excel',
                onTap: () async {
                  Navigator.pop(context);
                  await _showProgressDialog(
                    context,
                    () => exportProfileAsCSV(profile),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildExportOption(
                context,
                icon: Icons.analytics,
                title: 'Thống kê chi tiết',
                subtitle: 'Báo cáo phân tích đầy đủ',
                onTap: () async {
                  Navigator.pop(context);
                  await _showProgressDialog(
                    context,
                    () => exportDetailedStats(profile),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  /// Tạo option cho dialog xuất
  static Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog progress
  static Future<void> _showProgressDialog(
    BuildContext context,
    Future<void> Function() exportFunction,
  ) async {
    bool isDialogShown = true;
    OverlayEntry? overlayEntry;

    // Sử dụng Overlay thay vì showDialog để có control tốt hơn
    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Đang xuất dữ liệu...')),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(overlayEntry);

    try {
      print('🔄 Starting export function...');

      // Execute export function và đợi cho xong hoàn toàn
      await exportFunction();

      print('✅ Export function completed');

      // Remove overlay ngay lập tức
      if (isDialogShown && overlayEntry.mounted) {
        overlayEntry.remove();
        isDialogShown = false;
        print('🔒 Dialog closed successfully via overlay');
      }

      // Delay nhỏ trước khi show success message
      await Future.delayed(const Duration(milliseconds: 200));

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Xuất dữ liệu thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Export error: $e');

      // Remove overlay nếu còn showing
      if (isDialogShown && overlayEntry.mounted) {
        overlayEntry.remove();
        isDialogShown = false;
        print('🔒 Dialog closed due to error via overlay');
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xuất dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Lưu và chia sẻ file
  static Future<void> _saveAndShareFile(
    String content,
    String fileName,
    String mimeType,
  ) async {
    try {
      print('💾 Creating file: $fileName');

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      print('✅ File created successfully: ${file.path}');
      print('📤 Starting share operation...');

      // Chia sẻ file và đợi hoàn thành
      final shareResult = await Share.shareXFiles([
        XFile(file.path, mimeType: mimeType),
      ], text: 'Dữ liệu profile đã được xuất');

      print('📤 Share operation completed with result: ${shareResult.status}');

      // Thêm delay nhỏ để đảm bảo operation hoàn tất
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('❌ Error in _saveAndShareFile: $e');
      throw Exception('Lỗi khi lưu và chia sẻ file: $e');
    }
  }

  // Utility methods for calculations
  static double _calculateSavingsProgress(stats) {
    // Giả sử mục tiêu là 10M VND
    const goalAmount = 10000000;
    return (stats.totalSaved / goalAmount * 100).clamp(0, 100);
  }

  static double _calculateAverageDailySavings(stats) {
    if (stats.activeDays == 0) return 0;
    return stats.totalSaved / stats.activeDays;
  }

  static double _calculateActivityRate(stats) {
    // Giả sử tính từ ngày đăng ký (có thể cần API)
    const totalDays = 365; // 1 năm
    return (stats.activeDays / totalDays * 100).clamp(0, 100);
  }

  static double _calculateChallengeSuccessRate(stats) {
    // Giả sử có API để lấy tổng số thử thách đã tham gia
    const totalChallengesParticipated = 50;
    if (totalChallengesParticipated == 0) return 0;
    return (stats.completedChallenges / totalChallengesParticipated * 100)
        .clamp(0, 100);
  }

  static double _calculateAveragePointsPerChallenge(stats) {
    if (stats.completedChallenges == 0) return 0;
    return stats.totalPoints / stats.completedChallenges;
  }
}
