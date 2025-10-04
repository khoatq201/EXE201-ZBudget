import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/settings/user_profile.dart';
import '../utils/currency_formatter.dart';

/// Service để xử lý chia sẻ profile và export data
class ProfileShareService {
  /// Chia sẻ thông tin profile dưới dạng text
  static Future<void> shareProfile(UserProfile profile) async {
    try {
      final shareText = _buildShareText(profile);

      await Share.share(
        shareText,
        subject: 'ZBudget Profile - ${profile.name}',
      );
    } catch (e) {
      debugPrint('❌ Error sharing profile: $e');
      rethrow;
    }
  }

  /// Chia sẻ thông tin profile với thống kê chi tiết
  static Future<void> shareDetailedProfile(UserProfile profile) async {
    try {
      final shareText = _buildDetailedShareText(profile);

      await Share.share(
        shareText,
        subject: 'ZBudget Profile - ${profile.name} (Chi tiết)',
      );
    } catch (e) {
      debugPrint('❌ Error sharing detailed profile: $e');
      rethrow;
    }
  }

  /// Tạo nội dung text để share profile cơ bản
  static String _buildShareText(UserProfile profile) {
    final buffer = StringBuffer();

    buffer.writeln('🎯 ZBudget Profile');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 Tên: ${profile.name}');
    buffer.writeln('⭐ Level: ${profile.stats.currentLevel}');
    buffer.writeln('🏆 Điểm: ${profile.stats.totalPoints}');
    buffer.writeln('');

    // Thống kê cơ bản
    buffer.writeln('📊 Thống kê:');
    buffer.writeln(
      '💰 Tổng tiết kiệm: ${CurrencyFormatter.format(profile.stats.totalSaved)}',
    );
    buffer.writeln('🔥 Streak: ${profile.stats.streakDays} ngày');
    buffer.writeln('📅 Hoạt động: ${profile.stats.activeDays} ngày');
    buffer.writeln(
      '🏅 Challenges: ${profile.stats.completedChallenges} hoàn thành',
    );
    buffer.writeln('');

    buffer.writeln('📱 Được chia sẻ từ ZBudget App');

    return buffer.toString();
  }

  /// Tạo nội dung text để share profile chi tiết
  static String _buildDetailedShareText(UserProfile profile) {
    final buffer = StringBuffer();

    buffer.writeln('🎯 ZBudget Profile (Chi tiết)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('👤 Tên: ${profile.name}');
    buffer.writeln('📧 Email: ${profile.email}');
    if (profile.phone != null) {
      buffer.writeln('📞 SĐT: ${profile.phone}');
    }
    if (profile.birthday != null) {
      final age = DateTime.now().difference(profile.birthday!).inDays ~/ 365;
      buffer.writeln('🎂 Tuổi: $age');
    }
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      buffer.writeln('💬 Bio: ${profile.bio}');
    }
    buffer.writeln('');

    // Level & Points
    buffer.writeln('🏆 LEVEL & ĐIỂM');
    buffer.writeln('⭐ Level: ${profile.stats.currentLevel}');
    buffer.writeln('💎 Tổng điểm: ${profile.stats.totalPoints}');
    buffer.writeln('');

    // Thống kê chi tiết
    buffer.writeln('📊 THỐNG KÊ CHI TIẾT');
    buffer.writeln(
      '💰 Tổng tiết kiệm: ${CurrencyFormatter.format(profile.stats.totalSaved)}',
    );
    buffer.writeln('🔥 Streak hiện tại: ${profile.stats.streakDays} ngày');
    buffer.writeln('📅 Ngày hoạt động: ${profile.stats.activeDays} ngày');
    buffer.writeln(
      '🏅 Challenges hoàn thành: ${profile.stats.completedChallenges}',
    );
    buffer.writeln('');

    // Thành tích
    final unlockedAchievements = profile.achievements
        .where((a) => a.isUnlocked)
        .toList();
    if (unlockedAchievements.isNotEmpty) {
      buffer.writeln(
        '🏆 THÀNH TÍCH ĐÃ MỞ KHÓA (${unlockedAchievements.length}/${profile.achievements.length})',
      );
      for (final achievement in unlockedAchievements.take(5)) {
        // Chỉ hiển thị 5 thành tích đầu
        buffer.writeln(
          '${achievement.emoji} ${achievement.title} (+${achievement.pointsReward} điểm)',
        );
      }
      if (unlockedAchievements.length > 5) {
        buffer.writeln(
          '... và ${unlockedAchievements.length - 5} thành tích khác',
        );
      }
      buffer.writeln('');
    }

    buffer.writeln('📱 Được chia sẻ từ ZBudget App');
    buffer.writeln('🔗 Tải app tại: [App Store/Play Store]');

    return buffer.toString();
  }

  /// Tạo nội dung để share thống kê tháng
  static Future<void> shareMonthlyStats({
    required UserProfile profile,
    required double monthlyIncome,
    required double monthlyExpense,
    required double monthlyBudget,
  }) async {
    try {
      final buffer = StringBuffer();

      buffer.writeln('📊 ZBudget - Thống kê tháng');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln(
        '👤 ${profile.name} - Level ${profile.stats.currentLevel}',
      );
      buffer.writeln('');

      buffer.writeln('💰 TÀI CHÍNH THÁNG NÀY:');
      buffer.writeln('📈 Thu nhập: ${CurrencyFormatter.format(monthlyIncome)}');
      buffer.writeln(
        '📉 Chi tiêu: ${CurrencyFormatter.format(monthlyExpense)}',
      );
      buffer.writeln(
        '🎯 Ngân sách: ${CurrencyFormatter.format(monthlyBudget)}',
      );

      final savingAmount = monthlyIncome - monthlyExpense;
      final savingPercent = monthlyIncome > 0
          ? (savingAmount / monthlyIncome * 100)
          : 0;

      if (savingAmount >= 0) {
        buffer.writeln(
          '💚 Tiết kiệm: ${CurrencyFormatter.format(savingAmount)} (${savingPercent.toStringAsFixed(1)}%)',
        );
      } else {
        buffer.writeln(
          '⚠️ Vượt chi: ${CurrencyFormatter.format(savingAmount.abs())}',
        );
      }

      final budgetUsagePercent = monthlyBudget > 0
          ? (monthlyExpense / monthlyBudget * 100)
          : 0;
      buffer.writeln(
        '📊 Sử dụng ngân sách: ${budgetUsagePercent.toStringAsFixed(1)}%',
      );
      buffer.writeln('');

      buffer.writeln('🎯 Mục tiêu: Tiết kiệm thông minh với ZBudget!');
      buffer.writeln('📱 Chia sẻ từ ZBudget App');

      await Share.share(
        buffer.toString(),
        subject: 'ZBudget - Thống kê tháng của ${profile.name}',
      );
    } catch (e) {
      debugPrint('❌ Error sharing monthly stats: $e');
      rethrow;
    }
  }
}
