import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';

/// Premium Paywall Screen - Full-screen paywall for premium features
class PremiumPaywallScreen extends StatefulWidget {
  final String? feature;
  final String? reason;

  const PremiumPaywallScreen({super.key, this.feature, this.reason});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  PricingInfo? _pricing;
  Subscription? _currentSubscription;
  String _selectedPlan = 'monthly'; // Default to monthly
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subscriptionService = context.read<SubscriptionService>();

    // Load current subscription status
    final statusResult = await subscriptionService.getStatus();
    if (statusResult.success && statusResult.data != null) {
      setState(() {
        _currentSubscription = statusResult.data;
        _isPremium = statusResult.data!.isPremium;
      });
      debugPrint(
        '📊 Current subscription: ${_currentSubscription?.tier.value}, isPremium: $_isPremium',
      );
    }

    // Load pricing
    final result = await subscriptionService.getPricing();
    debugPrint(
      '💰 Pricing loaded: success=${result.success}, data=${result.data}',
    );
    if (result.success && result.data != null) {
      debugPrint('💰 Plans available: ${result.data!.plans.length}');
      for (var plan in result.data!.plans) {
        debugPrint('   - ${plan.name} (${plan.id}): ${plan.price}k');
      }
      setState(() {
        _pricing = result.data;
      });
    } else {
      debugPrint('❌ Failed to load pricing');
    }
  }

  Future<void> _handleUpgrade() async {
    // Navigate to Payment QR Screen with selected plan
    if (!mounted) return;

    context.push(
      '/payment-qr',
      extra: {'planType': _selectedPlan},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.1),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Premium Icon
                      _buildPremiumIcon(),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _isPremium ? 'Gia hạn Premium' : 'Nâng cấp lên Premium',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        _isPremium
                            ? 'Tiếp tục trải nghiệm Premium không giới hạn'
                            : widget.feature ??
                                  'Trải nghiệm đầy đủ tính năng ZBudget',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),

                      // Current subscription info
                      if (_isPremium && _currentSubscription != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gói hiện tại: ${_currentSubscription!.tier.value.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentSubscription!.expiryDate != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• Hết hạn: ${_formatDate(_currentSubscription!.expiryDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Features list (only show if not premium)
                      if (!_isPremium) ...[
                        _buildFeaturesList(),
                        const SizedBox(height: 32),
                      ],

                      // Pricing plans
                      if (_pricing != null) ...[
                        _buildPricingPlans(),
                        const SizedBox(height: 32),
                      ],

                      // CTA Button
                      _buildUpgradeButton(),
                      const SizedBox(height: 16),

                      // Free tier info
                      if (_pricing != null) _buildFreeTierInfo(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, size: 64, color: Colors.white),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.document_scanner,
        'title': 'Quét hóa đơn không giới hạn',
        'subtitle': 'Không còn lo về quota 10 lần/ngày',
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Tối đa 20 ngân sách',
        'subtitle': 'Quản lý chi tiết từng khoản chi',
      },
      {
        'icon': Icons.savings,
        'title': 'Tối đa 10 mục tiêu tiết kiệm',
        'subtitle': 'Theo dõi nhiều mục tiêu cùng lúc',
      },
      {
        'icon': Icons.analytics,
        'title': 'Phân tích AI chi tiết',
        'subtitle': 'Nhận insight thông minh về chi tiêu',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Dự báo chi tiêu',
        'subtitle': 'Biết trước xu hướng tài chính của bạn',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Hỗ trợ ưu tiên',
        'subtitle': 'Được giải đáp nhanh chóng',
      },
    ];

    return Column(
      children: features
          .map(
            (feature) => _buildFeatureItem(
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['subtitle'] as String,
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFFA500), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Chọn gói phù hợp với bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_pricing?.plans.map((plan) => _buildPlanCard(plan)) ?? []),
      ],
    );
  }

  Widget _buildPlanCard(PricingPlan plan) {
    final isSelected = _selectedPlan == plan.id;
    final isRecommended = plan.recommended ?? false;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlan = plan.id);
        debugPrint(
          '✅ Selected plan: ${plan.id} - ${plan.name} - ${plan.price}k',
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                    const Color(0xFFFFA500).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio button with animation
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.grey.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.circle_outlined,
                color: isSelected ? Colors.white : Colors.grey,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFFFFA500)
                          : Colors.black,
                    ),
                  ),
                  if (isRecommended) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Tiết kiệm 50k',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    plan.id == 'monthly'
                        ? 'Thanh toán 1 tháng'
                        : 'Thanh toán 1 năm',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${plan.price.toInt() ~/ 1000}k',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFFFFA500)
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan.id == 'yearly'
                      ? '${plan.pricePerMonth.toInt() ~/ 1000}k/tháng'
                      : 'VND',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    final selectedPlanInfo = _pricing?.plans.firstWhere(
      (plan) => plan.id == _selectedPlan,
      orElse: () => _pricing!.plans.first,
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isPremium
                  ? 'Gia hạn ${selectedPlanInfo?.name ?? "Premium"}'
                  : 'Nâng cấp ${selectedPlanInfo?.name ?? "Premium"}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selectedPlanInfo != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${selectedPlanInfo.price.toInt() ~/ 1000}k',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFreeTierInfo() {
    final freeTier = _pricing!.freeTier;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gói miễn phí bao gồm:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '• ${freeTier.features.maxBudgets} ngân sách',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          Text(
            '• ${freeTier.features.maxSavingsGoals} mục tiêu tiết kiệm',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          Text(
            '• ${freeTier.features.ocrScansPerDay} lần quét hóa đơn/ngày',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
