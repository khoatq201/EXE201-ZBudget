import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        title: const Text('Thử thách tiết kiệm'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          _buildChallengeCard(
            emoji: '💧',
            title: 'Không uống trà sữa 7 ngày',
            description: 'Tiết kiệm 150k/tuần',
            color: AppColors.primary500,
          ),
          _buildChallengeCard(
            emoji: '🚶',
            title: 'Đi bộ đi làm 3 ngày',
            description: 'Tiết kiệm 60k/tuần',
            color: AppColors.secondary500,
          ),
          _buildChallengeCard(
            emoji: '🍱',
            title: 'Tự nấu cơm 5 ngày',
            description: 'Tiết kiệm 200k/tuần',
            color: AppColors.accent500,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: AppTypography.h4),
          ),
          const SizedBox(width: AppSpacing.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.textInverse,
            ),
            child: Text(
              'Tham gia',
              style: AppTypography.button.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
