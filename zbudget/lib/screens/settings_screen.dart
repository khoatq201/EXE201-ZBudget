import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import '../utils/theme_extensions.dart';
import 'settings/profile/profile_screen.dart';
import 'settings/security/security_screen_simple.dart';
import 'settings/theme/theme_screen_simple.dart';
import 'settings/language/language_screen.dart';
import 'settings/currency/currency_screen.dart';
import 'settings/help/help_screen.dart';
import 'settings/feedback/feedback_screen.dart';
import 'settings/about/about_screen.dart';
import 'debug/device_info_test_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Không hardcode backgroundColor để theme tự động áp dụng
      appBar: AppBar(
        // Không hardcode backgroundColor để theme tự động áp dụng
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildSectionHeader('Tài khoản'),
          _buildSettingItem(
            context: context,
            icon: Icons.person,
            title: 'Thông tin cá nhân',
            subtitle: 'Cập nhật thông tin cá nhân',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              final isEnabled =
                  notificationService.notificationSettings.isGlobalEnabled;
              final enabledCount = notificationService
                  .notificationSettings
                  .enabledNotificationCount;
              final totalCount = notificationService
                  .notificationSettings
                  .totalNotificationCount;

              return _buildNotificationSettingItem(
                context: context,
                isEnabled: isEnabled,
                enabledCount: enabledCount,
                totalCount: totalCount,
                onTap: () {
                  context.push('/notifications-settings');
                },
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.security,
            title: 'Bảo mật',
            subtitle: 'Mật khẩu và xác thực',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityScreenSimple(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          _buildSectionHeader('Ứng dụng'),
          _buildSettingItem(
            context: context,
            icon: Icons.palette,
            title: 'Giao diện',
            subtitle: 'Thay đổi theme và màu sắc',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeScreen()),
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.currency_exchange,
            title: 'Tiền tệ',
            subtitle: 'VND',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyScreen()),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          _buildSectionHeader('Hỗ trợ'),
          _buildSettingItem(
            context: context,
            icon: Icons.help,
            title: 'Trợ giúp',
            subtitle: 'Hướng dẫn sử dụng',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.feedback,
            title: 'Gửi phản hồi',
            subtitle: 'Đóng góp ý kiến',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.info,
            title: 'Về ứng dụng',
            subtitle: 'Phiên bản 1.0.0',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Debug Section (Development only)
          _buildSectionHeader('Debug & Testing'),
          _buildSettingItem(
            context: context,
            icon: Icons.bug_report,
            title: 'Device Info Test',
            subtitle: 'Test device tracking functionality',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceInfoTestScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.buttonPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Đăng xuất',
                style: AppTypography.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sectionSpacing,
        bottom: AppSpacing.itemSpacing,
      ),
      child: Text(
        title,
        style: AppTypography.h5.copyWith(
          color: AppColors.primary500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.settingsItemIconBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20, color: context.settingsItemIconColor),
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: context.settingsItemTitleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: context.settingsItemSubtitleColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: context.settingsItemTrailingColor,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Đăng xuất',
            style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất?',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hủy',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textInverse,
              ),
              child: Text(
                'Đăng xuất',
                style: AppTypography.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    debugPrint('🎯 Settings._logout() called');

    try {
      final appProvider = context.read<AppProvider>();
      debugPrint('🔧 Calling AppProvider.logout()...');

      await appProvider.logout(context);
      debugPrint('🔧 AppProvider.logout() completed');

      if (context.mounted) {
        debugPrint('🏠 IMMEDIATE navigation to login...');

        // Direct navigation to login - no delays, no root navigation
        context.go('/login');
        debugPrint('🏠 Navigation to login completed');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng xuất thành công!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint('❌ Logout error in Settings: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng xuất thất bại: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildNotificationSettingItem({
    required BuildContext context,
    required bool isEnabled,
    required int enabledCount,
    required int totalCount,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.settingsItemIconBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.notifications,
          size: 20,
          color: context.settingsItemIconColor,
        ),
      ),
      title: Text(
        'Thông báo',
        style: AppTypography.body.copyWith(
          color: context.settingsItemTitleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isEnabled
            ? '$enabledCount/$totalCount loại đang bật'
            : 'Đã tắt thông báo',
        style: AppTypography.caption.copyWith(
          color: context.settingsItemSubtitleColor,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isEnabled ? 'BẬT' : 'TẮT',
          style: AppTypography.caption.copyWith(
            color: isEnabled ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
