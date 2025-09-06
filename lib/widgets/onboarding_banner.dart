import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class OnboardingBanner extends StatelessWidget {
  final String emoji;
  final IconData iconData;
  final List<Color> gradient;
  final int pageIndex;
  final Animation<double> animation;

  const OnboardingBanner({
    super.key,
    required this.emoji,
    required this.iconData,
    required this.gradient,
    required this.pageIndex,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main gradient circle
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Emoji and icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Icon(iconData, size: 60, color: Colors.white),
                  ],
                ),
                // Decorative circles
                ..._buildDecorativeElements(),
              ],
            ),
          ),
          // Feature cards based on page index
          ..._buildFeatureCards(pageIndex, animation),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeElements() {
    return [
      Positioned(
        top: 30,
        right: 40,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 50,
        left: 30,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 60,
        left: 50,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFeatureCards(int pageIndex, Animation<double> animation) {
    switch (pageIndex) {
      case 0:
        return [
          // Spending cards for page 1
          Positioned(
            top: 40,
            left: 20,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildSpendingCard('🍜', 'Ăn uống', '150,000đ'),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildSpendingCard('🚗', 'Di chuyển', '80,000đ'),
              ),
            ),
          ),
        ];
      case 1:
        return [
          // Challenge cards for page 2
          Positioned(
            top: 20,
            right: 30,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildChallengeCard(),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 40,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildRewardCard(),
              ),
            ),
          ),
        ];
      case 2:
        return [
          // Group cards for page 3
          Positioned(
            top: 30,
            left: 30,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, -0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildGroupCard(),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 40,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildAvatarGroup(),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildSpendingCard(String emoji, String title, String amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.accent500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Thử thách hôm nay',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tiết kiệm 50,000đ',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+10 điểm',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          const Text('⭐', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGroupCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏖️', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            'Du lịch Đà Lạt',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '4 người',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGroup() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar('A', AppColors.error),
        const SizedBox(width: 4),
        _buildAvatar('B', AppColors.primary500),
        const SizedBox(width: 4),
        _buildAvatar('C', AppColors.info),
      ],
    );
  }

  Widget _buildAvatar(String text, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
