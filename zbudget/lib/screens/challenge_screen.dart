import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/challenge_service.dart';
import '../models/challenge.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';
import 'challenge_detail_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Creative Animated Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary500,
            foregroundColor: AppColors.textInverse,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary500,
                          AppColors.secondary500,
                          AppColors.primary600,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated Background Shapes
                        Positioned(
                          top: -50 + (100 * _headerAnimation.value),
                          right: -30 + (60 * _headerAnimation.value),
                          child: Transform.rotate(
                            angle: _headerAnimation.value * 0.5,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textInverse.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20 + (40 * _headerAnimation.value),
                          left: -40 + (80 * _headerAnimation.value),
                          child: Transform.rotate(
                            angle: -_headerAnimation.value * 0.3,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppColors.textInverse.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Header Content
                        Positioned(
                          bottom: 60,
                          left: AppSpacing.pagePadding,
                          right: AppSpacing.pagePadding,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              30 * (1 - _headerAnimation.value),
                            ),
                            child: Opacity(
                              opacity: _headerAnimation.value.clamp(0.0, 1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.textInverse
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.emoji_events,
                                          color: AppColors.textInverse,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Thử Thách',
                                              style: AppTypography.h4.copyWith(
                                                color: AppColors.textInverse,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Thành tựu tài chính của bạn',
                                              style: AppTypography.body
                                                  .copyWith(
                                                    color: AppColors.textInverse
                                                        .withValues(alpha: 0.9),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildStatsRow(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Challenge Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Consumer<ChallengeService>(
                builder: (context, service, child) {
                  return AnimatedBuilder(
                    animation: _cardAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          // Quick Actions
                          _buildQuickActions(),

                          const SizedBox(height: AppSpacing.sectionSpacing),

                          // Challenge Categories
                          _buildCategoryTabs(),

                          const SizedBox(height: AppSpacing.lg),

                          // Challenge List
                          ...service.challenges.asMap().entries.map((entry) {
                            final index = entry.key;
                            final challenge = entry.value;
                            return Transform.translate(
                              offset: Offset(
                                0,
                                50 * (1 - _cardAnimation.value),
                              ),
                              child: Opacity(
                                opacity: _cardAnimation.value.clamp(0.0, 1.0),
                                child: _buildEnhancedChallengeCard(
                                  challenge,
                                  index,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: AnimatedBuilder(
        animation: _cardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _showCreateChallengeDialog,
              backgroundColor: AppColors.secondary500,
              foregroundColor: AppColors.textInverse,
              icon: const Icon(Icons.add),
              label: const Text('Tạo thử thách'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<ChallengeService>(
      builder: (context, service, child) {
        final active = service.challenges
            .where((c) => c.status == ChallengeStatus.active)
            .length;
        final completed = service.challenges
            .where((c) => c.status == ChallengeStatus.completed)
            .length;
        final totalPoints = service.challenges
            .where((c) => c.status == ChallengeStatus.completed)
            .fold<int>(0, (sum, c) => sum + c.points);

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Đang tham gia',
                '$active',
                Icons.play_circle_fill,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Hoàn thành',
                '$completed',
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'Điểm tích lũy',
                '$totalPoints',
                Icons.star,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textInverse, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textInverse.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary50, AppColors.secondary50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động nhanh',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.trending_up,
                  title: 'Thống kê',
                  color: AppColors.primary500,
                  onTap: () => _showStatsDialog(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.history,
                  title: 'Lịch sử',
                  color: AppColors.secondary500,
                  onTap: () => _showHistoryDialog(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.leaderboard,
                  title: 'Xếp hạng',
                  color: AppColors.success,
                  onTap: () => _showLeaderboardDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildCategoryTab('Tất cả', true),
            _buildCategoryTab('Tiết kiệm', false),
            _buildCategoryTab('Chi tiêu', false),
            _buildCategoryTab('Đầu tư', false),
            _buildCategoryTab('Thói quen', false),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle category selection
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary500 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.textInverse
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedChallengeCard(Challenge challenge, int index) {
    final statusConfig = _getChallengeStatusConfig(challenge.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        elevation: 8,
        shadowColor: statusConfig['color'].withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                statusConfig['color'].withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: statusConfig['color'].withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusConfig['color'].withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusConfig['color'].withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            statusConfig['icon'],
                            color: statusConfig['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: AppTypography.h6.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusConfig['color'].withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusConfig['text'],
                                  style: AppTypography.bodySmall.copyWith(
                                    color: statusConfig['color'],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Description
                    Text(
                      challenge.description,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Progress Bar (for active challenges)
                    if (challenge.status == ChallengeStatus.active) ...[
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusConfig['color'].withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.6, // Mock progress
                          child: Container(
                            decoration: BoxDecoration(
                              color: statusConfig['color'],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '60% hoàn thành',
                        style: AppTypography.bodySmall.copyWith(
                          color: statusConfig['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Bottom Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '30 ngày',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${challenge.points} điểm',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _navigateToDetail(context, challenge.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: statusConfig['color'],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getButtonText(challenge.status),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getChallengeStatusConfig(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return {
          'color': AppColors.primary500,
          'icon': Icons.play_circle_outline,
          'text': 'Có thể tham gia',
        };
      case ChallengeStatus.active:
        return {
          'color': AppColors.secondary500,
          'icon': Icons.trending_up,
          'text': 'Đang thực hiện',
        };
      case ChallengeStatus.completed:
        return {
          'color': AppColors.success,
          'icon': Icons.check_circle,
          'text': 'Đã hoàn thành',
        };
    }
  }

  void _navigateToDetail(BuildContext context, String challengeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(challengeId: challengeId),
      ),
    );
  }

  String _getButtonText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return 'Tham gia';
      case ChallengeStatus.active:
        return 'Xem tiến độ';
      case ChallengeStatus.completed:
        return 'Xem chi tiết';
    }
  }

  void _showCreateChallengeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo thử thách mới'),
        content: const Text(
          'Tính năng này sẽ được cập nhật trong phiên bản tiếp theo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thống kê thử thách'),
        content: const Text(
          'Tính năng thống kê chi tiết sẽ được cập nhật sớm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Lịch sử thử thách'),
        content: const Text('Xem lại tất cả các thử thách bạn đã tham gia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bảng xếp hạng'),
        content: const Text(
          'So sánh thành tích của bạn với những người dùng khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
