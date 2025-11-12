import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.headerTextColor,
        elevation: 0,
        title: const Text('Trợ giúp'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // Search Box
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sectionSpacing),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trợ giúp...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.inputFieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.inputFieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colorScheme.primary),
                ),
                filled: true,
                fillColor: context.inputFieldBackground,
              ),
            ),
          ),

          // Quick Help Cards
          _buildQuickHelpSection(context),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // FAQ Section
          _buildFAQSection(context),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // Contact Support
          _buildContactSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trợ giúp nhanh',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickHelpCard(
                context: context,
                icon: Icons.account_balance_wallet,
                title: 'Quản lý\nNgân sách',
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickHelpCard(
                context: context,
                icon: Icons.receipt_long,
                title: 'Theo dõi\nChi tiêu',
                color: AppColors.secondary500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickHelpCard(
                context: context,
                icon: Icons.savings,
                title: 'Mục tiêu\nTiết kiệm',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickHelpCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: context.settingsItemTitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Câu hỏi thường gặp',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFAQItem(
          context: context,
          question: 'Làm thế nào để tạo ngân sách mới?',
          answer:
              'Bạn có thể tạo ngân sách mới bằng cách vào màn hình Ngân sách, nhấn nút "+" và điền các thông tin cần thiết như tên ngân sách, số tiền, thời gian.',
        ),
        _buildFAQItem(
          context: context,
          question: 'Cách theo dõi chi tiêu hàng ngày?',
          answer:
              'Trên màn hình chính, nhấn nút "Thêm chi tiêu" để ghi lại mỗi khoản chi. Bạn có thể phân loại theo danh mục và xem báo cáo chi tiết.',
        ),
        _buildFAQItem(
          context: context,
          question: 'Tôi quên mật khẩu, làm sao để đăng nhập?',
          answer:
              'Trên màn hình đăng nhập, nhấn "Quên mật khẩu" và làm theo hướng dẫn để đặt lại mật khẩu qua email.',
        ),
        _buildFAQItem(
          context: context,
          question: 'Làm thế nào để xuất dữ liệu?',
          answer:
              'Vào Cài đặt > Sao lưu & Khôi phục > Xuất dữ liệu. Bạn có thể xuất dưới dạng Excel hoặc PDF.',
        ),
        _buildFAQItem(
          context: context,
          question: 'Ứng dụng có tính phí không?',
          answer:
              'ZBudget hoàn toàn miễn phí. Một số tính năng nâng cao có thể yêu cầu đăng ký Premium.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTypography.body.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.cardBackground,
        collapsedBackgroundColor: context.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTypography.bodySmall.copyWith(
                color: context.settingsItemSubtitleColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liên hệ hỗ trợ',
          style: AppTypography.h6.copyWith(
            color: context.settingsItemTitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildContactCard(
          context: context,
          icon: Icons.email,
          title: 'Email hỗ trợ',
          subtitle: 'support@zbudget.com',
          color: context.colorScheme.primary,
          onTap: () {
            // Launch email
          },
        ),
        _buildContactCard(
          context: context,
          icon: Icons.phone,
          title: 'Hotline',
          subtitle: '1900 1234 (8:00 - 22:00)',
          color: context.colorScheme.primary,
          onTap: () {
            // Launch phone
          },
        ),
        _buildContactCard(
          context: context,
          icon: Icons.chat,
          title: 'Chat trực tuyến',
          subtitle: 'Phản hồi trong 5 phút',
          color: context.colorScheme.primary,
          onTap: () {
            // Open live chat
          },
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: context.settingsItemTitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.settingsItemSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.settingsItemSubtitleColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
