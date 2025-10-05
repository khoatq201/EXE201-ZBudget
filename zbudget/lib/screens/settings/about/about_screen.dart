import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.colorScheme.onPrimary,
        elevation: 0,
        title: const Text('Về ứng dụng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // App Logo & Info
          _buildAppInfoSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // App Description
          _buildDescriptionSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // App Stats
          _buildStatsSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Developer Info
          _buildDeveloperSection(),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Legal & Policies
          _buildLegalSection(context),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Version & Build Info
          _buildVersionSection(context),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Social Links
          _buildSocialSection(),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary500, AppColors.secondary500],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textInverse,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // App Name
          Text(
            'ZBudget',
            style: AppTypography.h4.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // App Tagline
          Text(
            'Quản lý tài chính thông minh',
            style: AppTypography.body.copyWith(
              color: AppColors.textInverse.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Version Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Phiên bản 1.0.0',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới thiệu',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ZBudget là ứng dụng quản lý tài chính cá nhân được thiết kế dành riêng cho người Việt Nam. Với giao diện thân thiện và các tính năng thông minh, ZBudget giúp bạn theo dõi chi tiêu, lập ngân sách, và đạt được các mục tiêu tài chính một cách dễ dàng.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Key Features
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tính năng chính:',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildFeatureItem('📊', 'Theo dõi chi tiêu hàng ngày'),
              _buildFeatureItem('💰', 'Quản lý ngân sách thông minh'),
              _buildFeatureItem('🎯', 'Đặt mục tiêu tiết kiệm'),
              _buildFeatureItem('👥', 'Chia sẻ chi tiêu nhóm'),
              _buildFeatureItem('📈', 'Báo cáo và phân tích chi tiết'),
              _buildFeatureItem('🔒', 'Bảo mật thông tin tuyệt đối'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê ứng dụng',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Người dùng',
                  value: '10,000+',
                  icon: Icons.people,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Đánh giá',
                  value: '4.8/5',
                  icon: Icons.star,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Lượt tải',
                  value: '25,000+',
                  icon: Icons.download,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Cập nhật',
                  value: 'Tháng 9/2025',
                  icon: Icons.update,
                  color: AppColors.secondary500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhà phát triển',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary500,
                child: Text(
                  'ZT',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZBudget Team',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đội ngũ phát triển tại Việt Nam',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'contact@zbudget.com',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pháp lý & Chính sách',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLegalItem(
            icon: Icons.privacy_tip,
            title: 'Chính sách bảo mật',
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          _buildLegalItem(
            icon: Icons.description,
            title: 'Điều khoản sử dụng',
            onTap: () {
              // Navigate to terms of service
            },
          ),
          _buildLegalItem(
            icon: Icons.security,
            title: 'Chính sách bảo mật dữ liệu',
            onTap: () {
              // Navigate to data security policy
            },
          ),
          _buildLegalItem(
            icon: Icons.gavel,
            title: 'Giấy phép mã nguồn mở',
            onTap: () {
              _showLicensesDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin phiên bản',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildVersionItem('Phiên bản ứng dụng', '1.0.0'),
          _buildVersionItem('Build số', '100'),
          _buildVersionItem('Ngày phát hành', '24/09/2025'),
          _buildVersionItem('Flutter SDK', '3.24.0'),
          _buildVersionItem('Dart SDK', '3.5.0'),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(
                    text:
                        'ZBudget v1.0.0 (Build 100)\nFlutter 3.24.0 • Dart 3.5.0',
                  ),
                );

                // Show copied message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép thông tin phiên bản'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Sao chép thông tin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                side: BorderSide(color: AppColors.primary500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết nối với chúng tôi',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  // Open Facebook page
                },
              ),
              _buildSocialButton(
                icon: Icons.email,
                label: 'Email',
                color: AppColors.error,
                onTap: () {
                  // Open email
                },
              ),
              _buildSocialButton(
                icon: Icons.web,
                label: 'Website',
                color: AppColors.primary500,
                onTap: () {
                  // Open website
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Giấy phép mã nguồn mở'),
        content: const Text(
          'ZBudget sử dụng các thư viện mã nguồn mở. Bạn có thể xem danh sách đầy đủ các giấy phép trong phần cài đặt phát triển.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showLicensePage(context: context);
            },
            child: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }
}
