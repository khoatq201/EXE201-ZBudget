import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';
import '../utils/theme_extensions.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
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
    return Consumer<ChallengeService>(
      builder: (context, service, child) {
        final challenge = service.challenges.firstWhere(
          (c) => c.id == widget.challengeId,
        );

        return Scaffold(
          backgroundColor: context.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(challenge),
              SliverToBoxAdapter(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      _buildChallengeHeader(challenge),
                      _buildChallengeStats(challenge),
                      _buildChallengeDescription(challenge),
                      _buildMilestones(challenge),
                      _buildParticipants(challenge),
                      _buildJoinButton(context, challenge, service),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(Challenge challenge) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: context.headerTextColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(challenge.emoji, style: const TextStyle(fontSize: 32)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.headerGradientStart, context.headerGradientEnd],
            ),
          ),
          child: Center(
            child: Text(challenge.emoji, style: const TextStyle(fontSize: 80)),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeHeader(Challenge challenge) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDifficultyChip(challenge.difficulty),
              const SizedBox(width: 12),
              _buildCategoryChip(challenge.category),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(ChallengeDifficulty difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        color = context.incomeColor;
        text = 'Dễ';
        break;
      case ChallengeDifficulty.medium:
        color = context.warningColor;
        text = 'Trung bình';
        break;
      case ChallengeDifficulty.hard:
        color = context.errorColor;
        text = 'Khó';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ChallengeCategory category) {
    String text = _getCategoryText(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.headerGradientStart.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getCategoryText(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.drinks:
        return 'Đồ uống';
      case ChallengeCategory.food:
        return 'Ăn uống';
      case ChallengeCategory.transport:
        return 'Di chuyển';
      case ChallengeCategory.shopping:
        return 'Mua sắm';
      case ChallengeCategory.entertainment:
        return 'Giải trí';
      case ChallengeCategory.special:
        return 'Đặc biệt';
      case ChallengeCategory.digital:
        return 'Số hóa';
    }
  }

  Widget _buildChallengeStats(Challenge challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.customCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            value: challenge.participants.toString(),
            label: 'Người tham gia',
          ),
          _buildStatItem(
            icon: Icons.schedule,
            value: challenge.duration,
            label: 'Thời gian',
          ),
          _buildStatItem(
            icon: Icons.stars,
            value: challenge.points.toString(),
            label: 'Điểm thưởng',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: context.incomeColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildChallengeDescription(Challenge challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.customCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả thử thách',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 16,
              color: context.primaryTextColor.withOpacity(0.95),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.previewBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: context.headerGradientEnd,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mục tiêu tiết kiệm: ${_formatCurrency(challenge.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(Challenge challenge) {
    if (challenge.milestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.customCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mốc thành tích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...challenge.milestones.map(
            (milestone) => _buildMilestoneItem(milestone),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(ChallengeMilestone milestone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: milestone.isCompleted
            ? context.previewBackground
            : context.customCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone.isCompleted
              ? context.headerGradientStart.withOpacity(0.18)
              : context.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            milestone.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: milestone.isCompleted
                ? context.headerGradientEnd
                : context.tertiaryTextColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày ${milestone.day}: ${milestone.description}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phần thưởng: ${milestone.reward}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants(Challenge challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.customCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Người tham gia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.primaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.participants} người',
                style: TextStyle(
                  fontSize: 14,
                  color: context.secondaryTextColor.withOpacity(0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...List.generate(
                challenge.participants > 5 ? 5 : challenge.participants,
                (index) => Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: context.headerGradientStart.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.scaffoldBackground,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (challenge.participants > 5)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: context.previewBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.scaffoldBackground,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+${challenge.participants - 5}',
                      style: TextStyle(
                        color: context.secondaryTextColor.withOpacity(0.95),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(
    BuildContext context,
    Challenge challenge,
    ChallengeService service,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: challenge.status == ChallengeStatus.available
            ? () => _showJoinConfirmation(context, challenge, service)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: challenge.status == ChallengeStatus.available
              ? context.primaryButtonBackground
              : Theme.of(context).disabledColor,
          foregroundColor: context.primaryButtonForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: challenge.status == ChallengeStatus.available ? 4 : 0,
        ),
        child: Text(
          _getButtonText(challenge.status),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getButtonText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return 'Tham gia thử thách';
      case ChallengeStatus.active:
        return 'Đang tham gia';
      case ChallengeStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  void _showJoinConfirmation(
    BuildContext context,
    Challenge challenge,
    ChallengeService service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildJoinConfirmationSheet(context, challenge, service),
    );
  }

  Widget _buildJoinConfirmationSheet(
    BuildContext context,
    Challenge challenge,
    ChallengeService service,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.customCardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.previewBackground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🎯 Sẵn sàng tham gia?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn sẽ cam kết thực hiện thử thách "${challenge.title}" trong ${challenge.duration}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: context.secondaryTextColor.withOpacity(0.95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.previewBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: context.headerGradientEnd),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bạn sẽ nhận được ${challenge.points} điểm khi hoàn thành!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(color: context.secondaryTextColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _joinChallenge(context, challenge.id, service);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryButtonBackground,
                    foregroundColor: context.primaryButtonForeground,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tham gia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.primaryButtonForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _joinChallenge(
    BuildContext context,
    String challengeId,
    ChallengeService service,
  ) async {
    try {
      await service.joinChallenge(challengeId);

      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.celebration, color: context.primaryButtonForeground),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('🎉 Đã tham gia thử thách thành công!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Navigate to active challenge screen
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/challenge-progress', arguments: challengeId);
      }
    } catch (error) {
      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }
}
