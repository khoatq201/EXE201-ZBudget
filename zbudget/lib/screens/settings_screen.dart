import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_provider.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import '../utils/theme_extensions.dart';
import '../widgets/floating_ai_button.dart';
import '../widgets/unified_header_widget.dart';
import 'settings/profile/profile_screen.dart';
import 'settings/security/security_screen_simple.dart';
import 'settings/theme/theme_screen.dart';
import 'settings/language/language_screen.dart';
import 'settings/premium/premium_screen.dart';
import 'settings/chat_history_screen.dart';
import 'settings/notifications/notification_settings_simple.dart';
import 'settings/help/help_screen.dart';
import 'settings/about/about_screen.dart';
import 'settings/feedback/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
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
                    _buildSettingItem(
                      context: context,
                      icon: Icons.security,
                      title: 'Bảo mật',
                      subtitle: 'Mật khẩu, xác thực 2FA',
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
                      subtitle: 'Thay đổi giao diện ứng dụng',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ThemeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.language,
                      title: 'Ngôn ngữ',
                      subtitle: 'Thay đổi ngôn ngữ hiển thị',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LanguageScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSectionHeader('Tính năng'),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.star,
                      title: 'Premium',
                      subtitle: 'Nâng cấp tài khoản Premium',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PremiumScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Lịch sử Chat AI',
                      subtitle: 'Xem và tiếp tục các cuộc trò chuyện cũ',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatHistoryScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSectionHeader('Khác'),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Cài đặt thông báo',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsSimple(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.help_outline,
                      title: 'Trợ giúp',
                      subtitle: 'Hướng dẫn sử dụng',
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
                      icon: Icons.info_outline,
                      title: 'Giới thiệu',
                      subtitle: 'Thông tin ứng dụng',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.feedback_outlined,
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
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Xem tất cả thông báo',
                      onTap: () {
                        context.go('/notifications');
                      },
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // Logout button
                    TextButton(
                      onPressed: () {
                        final appProvider = Provider.of<AppProvider>(
                          context,
                          listen: false,
                        );
                        appProvider.logout(context);
                        context.go('/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const FloatingAiButton(),
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
        border: Border.all(color: context.cardBorder, width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.settingsItemTitleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
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
}
