import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import '../navigation/app_navigator.dart';
import '../widgets/onboarding_banner.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Theo dõi chi tiêu thông minh',
      description:
          'Quét hóa đơn tự động và phân loại chi tiêu một cách dễ dàng. AI sẽ giúp bạn hiểu rõ thói quen chi tiêu của mình.',
      icon: Icons.receipt_outlined,
      color: AppColors.primary500,
      emoji: '💰',
      gradient: [AppColors.primary500, const Color(0xFF44A08D)],
    ),
    OnboardingPage(
      title: 'Thử thách tiết kiệm vui nhộn',
      description:
          'Tham gia các thử thách tiết kiệm hàng ngày và nhận được huy hiệu. Biến việc tiết kiệm thành một trò chơi thú vị!',
      icon: Icons.emoji_events_outlined,
      color: AppColors.error,
      emoji: '🎯',
      gradient: [AppColors.error, const Color(0xFFEE5A52)],
    ),
    OnboardingPage(
      title: 'Quản lý nhóm dễ dàng',
      description:
          'Chia sẻ chi phí với bạn bè và gia đình. Quản lý ngân sách chung một cách minh bạch và công bằng.',
      icon: Icons.people_outline,
      color: AppColors.info,
      emoji: '👥',
      gradient: [AppColors.info, const Color(0xFF3A9BC1)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Reset animation for new page
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    try {
      final appProvider = context.read<AppProvider>();
      await appProvider.completeOnboarding();
      if (mounted) {
        AppNavigator.navigateToLogin(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary, // White background
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 16,
              right: 20,
              child: TextButton.icon(
                onPressed: _completeOnboarding,
                icon: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  'Bỏ qua',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.backgroundSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced banner with animations and feature cards
          OnboardingBanner(
            emoji: page.emoji,
            iconData: page.icon,
            gradient: page.gradient,
            pageIndex: _currentPage,
            animation: _fadeAnimation,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          // Title with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.title,
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          // Description with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.description,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDotIndicator(index),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.buttonPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentPage < _pages.length - 1 ? 'Tiếp theo' : 'Bắt đầu',
                style: AppTypography.button.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1) ...[
            const SizedBox(height: AppSpacing.itemSpacing),
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Bỏ qua',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? AppColors.primary500 : AppColors.dark200,
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String emoji;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.emoji,
    required this.gradient,
  });
}
