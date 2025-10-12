import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import '../utils/theme_extensions.dart';
import '../widgets/unified_header_widget.dart';
import 'settings/profile/profile_screen.dart';
import 'settings/security/security_screen_simple.dart';
import 'settings/theme/theme_screen_simple.dart';
import 'settings/language/language_screen.dart';
import 'settings/help/help_screen.dart';
import 'settings/feedback/feedback_screen.dart';
import 'settings/about/about_screen.dart';
import 'settings/premium/premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Unified Header
          HeaderConfigs.getHeader('settings'),

          // Content
          Expanded(
            child: ListView(
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
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                Consumer<NotificationService>(
                  builder: (context, notificationService, child) {
                    final isEnabled = notificationService
                        .notificationSettings
                        .isGlobalEnabled;
                    final enabledCount = notificationService
                        .notificationSettings
                        .enabledTypes
                        .length;
                    return _buildSettingItem(
                      context: context,
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: isEnabled
                          ? '$enabledCount loại thông báo đang bật'
                          : 'Tất cả thông báo đã tắt',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildSectionHeader('Bảo mật'),
                _buildSettingItem(
                  context: context,
                  icon: Icons.security,
                  title: 'Bảo mật',
                  subtitle: 'Cài đặt bảo mật và xác thực',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SecurityScreenSimple(),
                      ),
                    );
                  },
                ),
                _buildSectionHeader('Giao diện'),
                _buildSettingItem(
                  context: context,
                  icon: Icons.palette,
                  title: 'Chủ đề',
                  subtitle: 'Tùy chỉnh giao diện ứng dụng',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThemeScreenSimple(),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  context: context,
                  icon: Icons.language,
                  title: 'Ngôn ngữ',
                  subtitle: 'Thay đổi ngôn ngữ ứng dụng',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LanguageScreen(),
                      ),
                    );
                  },
                ),
                _buildSectionHeader('Hỗ trợ'),
                _buildSettingItem(
                  context: context,
                  icon: Icons.help,
                  title: 'Trợ giúp',
                  subtitle: 'Câu hỏi thường gặp và hướng dẫn',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  context: context,
                  icon: Icons.feedback,
                  title: 'Phản hồi',
                  subtitle: 'Gửi ý kiến và báo lỗi',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  context: context,
                  icon: Icons.info,
                  title: 'Giới thiệu',
                  subtitle: 'Thông tin về ứng dụng',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildSectionHeader('Premium'),
                _buildSettingItem(
                  context: context,
                  icon: Icons.star,
                  title: 'Premium',
                  subtitle: 'Nâng cấp lên phiên bản cao cấp',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildLogoutButton(context),
                const SizedBox(height: AppSpacing.xl2),
              ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary500, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: context.primaryTextColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: context.settingsItemSubtitleColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: context.settingsItemSubtitleColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.itemSpacing),
      child: ElevatedButton(
        onPressed: () {
          _showLogoutDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textInverse,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Đăng xuất',
            style: AppTypography.button.copyWith(color: AppColors.textInverse),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Thực hiện đăng xuất
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );
              appProvider.logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
