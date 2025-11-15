import 'package:flutter/material.dart';
import '../../models/subscription_models.dart';

/// Upgrade Dialog - Dialog yêu cầu nâng cấp Premium
class UpgradeDialog extends StatelessWidget {
  final String feature;
  final String reason;
  final PricingInfo? pricing;
  final VoidCallback? onUpgrade;

  const UpgradeDialog({
    super.key,
    required this.feature,
    required this.reason,
    this.pricing,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.orange.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Nâng cấp Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Feature name
            Text(
              feature,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Reason
            Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Pricing info (if available)
            if (pricing != null) ...[
              _buildPricingCard(pricing!),
              const SizedBox(height: 24),
            ],

            // Benefits
            _buildBenefits(),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Để sau'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUpgrade?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Nâng cấp ngay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(PricingInfo pricing) {
    // Find monthly and yearly plans
    final monthlyPlan = pricing.plans.firstWhere(
      (plan) => plan.id == 'monthly',
      orElse: () => pricing.plans.first,
    );
    final yearlyPlan = pricing.plans.firstWhere(
      (plan) => plan.id == 'yearly',
      orElse: () => pricing.plans.last,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPriceOption(
                monthlyPlan.name,
                monthlyPlan.price.toInt(),
                monthlyPlan.durationLabel,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildPriceOption(
                yearlyPlan.name,
                yearlyPlan.price.toInt(),
                yearlyPlan.durationLabel,
                savings: yearlyPlan.savings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceOption(
    String label,
    int price,
    String duration, {
    double? savings,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${price ~/ 1000}k',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFA500),
          ),
        ),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        if (savings != null && savings > 0) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Tiết kiệm ${savings.toInt()}k',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quyền lợi Premium:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildBenefitItem('Quét hóa đơn không giới hạn'),
        _buildBenefitItem('Tạo tối đa 20 ngân sách'),
        _buildBenefitItem('Tạo tối đa 10 mục tiêu tiết kiệm'),
        _buildBenefitItem('Phân tích AI chi tiết'),
        _buildBenefitItem('Dự báo chi tiêu thông minh'),
        _buildBenefitItem('Hỗ trợ ưu tiên'),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple Upgrade Dialog - Version đơn giản hơn
class SimpleUpgradeDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onUpgrade;

  const SimpleUpgradeDialog({
    super.key,
    required this.message,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Premium Required',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpgrade?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.white,
          ),
          child: const Text('Nâng cấp'),
        ),
      ],
    );
  }
}

/// Show upgrade dialog helper function
void showUpgradeDialog(
  BuildContext context, {
  required String feature,
  required String reason,
  PricingInfo? pricing,
  VoidCallback? onUpgrade,
}) {
  showDialog(
    context: context,
    builder: (context) => UpgradeDialog(
      feature: feature,
      reason: reason,
      pricing: pricing,
      onUpgrade: onUpgrade,
    ),
  );
}

/// Show simple upgrade dialog helper function
void showSimpleUpgradeDialog(
  BuildContext context, {
  required String message,
  VoidCallback? onUpgrade,
}) {
  showDialog(
    context: context,
    builder: (context) => SimpleUpgradeDialog(
      message: message,
      onUpgrade: onUpgrade,
    ),
  );
}
