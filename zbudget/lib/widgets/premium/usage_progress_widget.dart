import 'package:flutter/material.dart';

/// Usage Progress Widget - Hiển thị tiến trình sử dụng feature (OCR, Budget, Savings)
class UsageProgressWidget extends StatelessWidget {
  final String title;
  final int current;
  final int limit;
  final IconData icon;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool showPercentage;

  const UsageProgressWidget({
    super.key,
    required this.title,
    required this.current,
    required this.limit,
    required this.icon,
    this.progressColor,
    this.backgroundColor,
    this.showPercentage = false,
  });

  double get progress => limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => current >= limit;
  bool get isNearLimit => progress >= 0.8;

  Color _getProgressColor() {
    if (progressColor != null) return progressColor!;
    if (isExceeded) return Colors.red;
    if (isNearLimit) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExceeded ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _getProgressColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$current/$limit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getProgressColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          if (showPercentage) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% đã sử dụng',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (isExceeded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 16,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Đã vượt quá giới hạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact Usage Progress - Version nhỏ gọn cho inline display
class CompactUsageProgress extends StatelessWidget {
  final int current;
  final int limit;
  final Color? progressColor;

  const CompactUsageProgress({
    super.key,
    required this.current,
    required this.limit,
    this.progressColor,
  });

  double get progress => limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => current >= limit;
  bool get isNearLimit => progress >= 0.8;

  Color _getProgressColor() {
    if (progressColor != null) return progressColor!;
    if (isExceeded) return Colors.red;
    if (isNearLimit) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$current/$limit',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getProgressColor(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getProgressColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// OCR Quota Widget - Specific widget for OCR usage
class OCRQuotaWidget extends StatelessWidget {
  final int used;
  final int limit;
  final bool isPremium;
  final VoidCallback? onUpgrade;

  const OCRQuotaWidget({
    super.key,
    required this.used,
    required this.limit,
    required this.isPremium,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.all_inclusive, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Unlimited',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return UsageProgressWidget(
      title: 'Quét hóa đơn hôm nay',
      current: used,
      limit: limit,
      icon: Icons.document_scanner,
      showPercentage: true,
    );
  }
}

/// Budget/Savings Limit Widget
class LimitProgressWidget extends StatelessWidget {
  final String type; // 'budget' or 'savings'
  final int current;
  final int limit;
  final bool isPremium;
  final VoidCallback? onUpgrade;

  const LimitProgressWidget({
    super.key,
    required this.type,
    required this.current,
    required this.limit,
    required this.isPremium,
    this.onUpgrade,
  });

  String get title {
    return type == 'budget' ? 'Ngân sách' : 'Mục tiêu tiết kiệm';
  }

  IconData get icon {
    return type == 'budget' ? Icons.account_balance_wallet : Icons.savings;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UsageProgressWidget(
          title: '$title đang hoạt động',
          current: current,
          limit: limit,
          icon: icon,
        ),
        if (!isPremium && current >= limit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Nâng cấp Premium để tạo thêm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
