import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_manager.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/theme_extensions.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _buildHeroSection(context),
                        const SizedBox(height: AppSpacing.xl),
                        _buildPricingSection(context),
                        const SizedBox(height: AppSpacing.xl),
                        _buildFeaturesSection(context),
                        const SizedBox(height: AppSpacing.xl),
                        _buildTestimonialSection(context),
                        const SizedBox(height: AppSpacing.xl6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: context.headerGradientStart,
      foregroundColor: context.headerTextColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.headerGradientStart,
                context.headerGradientEnd,
                context.headerGradientEnd.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colorScheme.onPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(Icons.star, color: Colors.amber, size: 40),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'ZBudget Premium',
                  style: AppTypography.h2.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Trải nghiệm đầy đủ tính năng',
                  style: AppTypography.body.copyWith(
                    color: context.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.primary.withOpacity(0.1),
            context.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 60,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nâng cấp lên Premium',
            style: AppTypography.h3.copyWith(
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mở khóa toàn bộ tiềm năng của ZBudget với các tính năng cao cấp và AI thông minh',
            style: AppTypography.body.copyWith(
              color: context.customTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn gói phù hợp',
            style: AppTypography.h4.copyWith(
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Free Trial Card
          _buildPricingCard(
            context: context,
            title: 'Dùng thử miễn phí',
            subtitle: 'Miễn phí một tháng đầu',
            price: '0 VND',
            period: 'tháng đầu tiên',
            isPopular: false,
            isFree: true,
            onTap: () => _showSubscriptionDialog(context, true),
          ),

          const SizedBox(height: AppSpacing.md),

          // Monthly Plan
          _buildPricingCard(
            context: context,
            title: 'Gói hàng tháng',
            subtitle: 'Thanh toán hàng tháng',
            price: '50.000 VND',
            period: 'mỗi tháng',
            isPopular: false,
            isFree: false,
            onTap: () => _showSubscriptionDialog(context, false),
          ),

          const SizedBox(height: AppSpacing.md),

          // Yearly Plan
          _buildPricingCard(
            context: context,
            title: 'Gói hàng năm',
            subtitle: 'Tiết kiệm 40% so với gói tháng',
            price: '360.000 VND',
            period: 'mỗi năm',
            originalPrice: '600.000 VND',
            isPopular: true,
            isFree: false,
            onTap: () => _showSubscriptionDialog(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? originalPrice,
    required bool isPopular,
    required bool isFree,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? context.colorScheme.primary : context.cardBorder,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'PHỔ BIẾN',
                  style: AppTypography.caption.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isFree ? Icons.card_giftcard : Icons.star,
                          color: isFree
                              ? Colors.green
                              : context.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.body.copyWith(
                                  color: context.customTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: AppTypography.caption.copyWith(
                                  color: context.customTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: AppTypography.h3.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          period,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.customTextSecondary,
                          ),
                        ),
                        if (originalPrice != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            originalPrice,
                            style: AppTypography.bodySmall.copyWith(
                              color: context.customTextSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isFree) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'MIỄN PHÍ',
                          style: AppTypography.caption.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      {
        'icon': Icons.palette,
        'title': 'Giao diện đặc biệt',
        'description': 'Chủ đề độc quyền và tùy chỉnh giao diện nâng cao',
        'color': Colors.purple,
      },
      {
        'icon': Icons.psychology,
        'title': 'AI phân tích thông minh',
        'description':
            'Phân tích chi tiêu và đưa ra lời khuyên tài chính cá nhân',
        'color': Colors.blue,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Mở giới hạn tạo mục tiêu',
        'description': 'Tạo không giới hạn Saving Goals và Budget',
        'color': Colors.green,
      },
      {
        'icon': Icons.cloud_sync,
        'title': 'Đồng bộ đám mây',
        'description': 'Sao lưu và đồng bộ dữ liệu trên nhiều thiết bị',
        'color': Colors.orange,
      },
      {
        'icon': Icons.analytics,
        'title': 'Báo cáo nâng cao',
        'description':
            'Báo cáo chi tiết và xuất dữ liệu định dạng chuyên nghiệp',
        'color': Colors.red,
      },
      {
        'icon': Icons.support_agent,
        'title': 'Hỗ trợ ưu tiên',
        'description': 'Hỗ trợ khách hàng 24/7 với đội ngũ chuyên nghiệp',
        'color': Colors.teal,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tính năng Premium',
            style: AppTypography.h4.copyWith(
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...features.map(
            (feature) => _buildFeatureItem(
              context: context,
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              description: feature['description'] as String,
              color: feature['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: context.customTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.customTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildTestimonialSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.primary.withOpacity(0.1),
            context.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote,
            size: 40,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"ZBudget Premium đã giúp tôi tiết kiệm được 30% chi phí hàng tháng nhờ AI phân tích thông minh và các tính năng nâng cao."',
            style: AppTypography.body.copyWith(
              color: context.customTextPrimary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.colorScheme.primary,
                child: Text(
                  'N',
                  style: AppTypography.body.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nguyễn Minh Quân',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.customTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Khách hàng Premium',
                    style: AppTypography.caption.copyWith(
                      color: context.customTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, bool isFree) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isFree ? 'Bắt đầu dùng thử miễn phí' : 'Xác nhận đăng ký Premium',
          style: AppTypography.h5.copyWith(color: context.customTextPrimary),
        ),
        content: Text(
          isFree
              ? 'Bạn sẽ được sử dụng miễn phí tất cả tính năng Premium trong 1 tháng đầu tiên.'
              : 'Bạn sẽ được truy cập vào tất cả tính năng Premium ngay lập tức.',
          style: AppTypography.body.copyWith(
            color: context.customTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTypography.body.copyWith(
                color: context.customTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSubscription(isFree);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.headerTextColor,
            ),
            child: Text(
              isFree ? 'Bắt đầu miễn phí' : 'Đăng ký ngay',
              style: AppTypography.button.copyWith(
                color: context.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processSubscription(bool isFree) {
    // TODO: Implement subscription logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFree
              ? 'Đã bắt đầu dùng thử miễn phí Premium!'
              : 'Đã đăng ký thành công gói Premium!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
