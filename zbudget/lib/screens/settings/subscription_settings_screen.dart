import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../services/payment_service.dart';
import '../../models/subscription_models.dart';
import '../../models/payment_model.dart';
import '../../widgets/premium/premium_badge.dart';
import '../../widgets/premium/usage_progress_widget.dart';
import '../../widgets/premium/premium_paywall.dart';
import '../../utils/date_formatter.dart';

class SubscriptionSettingsScreen extends StatefulWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  State<SubscriptionSettingsScreen> createState() =>
      _SubscriptionSettingsScreenState();
}

class _SubscriptionSettingsScreenState
    extends State<SubscriptionSettingsScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  Future<List<Payment>>? _paymentsFuture;

  @override
  void initState() {
    super.initState();
    // Defer the API call until after the build is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _loadSubscriptionData();
      }
    });
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;
    final subscriptionService = context.read<SubscriptionService>();
    final paymentService = context.read<PaymentService>();

    // Load status and usage
    await Future.wait([
      subscriptionService.getStatus(),
      subscriptionService.getUsage(),
    ]);

    // Load payment history once and cache it
    if (mounted) {
      setState(() {
        _paymentsFuture = _loadPayments();
      });
    }
  }

  Future<List<Payment>> _loadPayments() async {
    final paymentService = context.read<PaymentService>();
    await paymentService.fetchMyPayments();
    return paymentService.payments;
  }

  Future<void> _handleUpgrade() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()),
    );

    if (result == true) {
      // Refresh subscription data after upgrade
      await _loadSubscriptionData();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Subscription'), elevation: 0),
      body: Consumer<SubscriptionService>(
        builder: (context, subscriptionService, child) {
          final subscription = subscriptionService.subscription;
          final usageStats = subscriptionService.usageStats;
          final isLoading = subscriptionService.isLoading || _isLoading;

          if (isLoading && subscription == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadSubscriptionData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription Status Card
                  _buildSubscriptionStatusCard(subscription),
                  const SizedBox(height: 24),

                  // Usage Statistics (for free users)
                  if (subscription != null && !subscription.isPremium) ...[
                    _buildUsageSection(subscription, usageStats),
                    const SizedBox(height: 24),
                  ],

                  // Features Section
                  _buildFeaturesSection(subscription),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(subscription),
                  const SizedBox(height: 24),

                  // Subscription History
                  _buildHistorySection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(Subscription? subscription) {
    final isPremium = subscription?.isPremium ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [Colors.grey[300]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.account_circle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium' : 'Free',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subscription?.status.value.toUpperCase() ?? 'INACTIVE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                const PremiumBadge(
                  size: 20,
                  showText: false,
                  backgroundColor: Colors.white,
                  iconColor: Color(0xFFFFD700),
                ),
            ],
          ),
          if (isPremium && subscription?.expiryDate != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Hết hạn: ${DateFormatter.toDisplayFormat(subscription!.expiryDate!)}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            if (subscription.daysRemaining != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Còn ${subscription.daysRemaining} ngày',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildUsageSection(Subscription subscription, UsageStats? usageStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sử dụng hôm nay',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (usageStats?.ocr != null)
          OCRQuotaWidget(
            used: usageStats!.ocr.count,
            limit: usageStats.ocr.limit,
            isPremium: subscription.isPremium,
            onUpgrade: _handleUpgrade,
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(Subscription? subscription) {
    final features = subscription?.features;
    final isPremium = subscription?.isPremium ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tính năng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.document_scanner,
          'Quét hóa đơn',
          isPremium
              ? 'Không giới hạn'
              : '${features?.ocrScansPerDay ?? 10} lần/ngày',
          isPremium,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          Icons.account_balance_wallet,
          'Ngân sách',
          isPremium
              ? 'Tối đa ${features?.maxBudgets ?? 20}'
              : 'Tối đa ${features?.maxBudgets ?? 2}',
          isPremium,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          Icons.savings,
          'Mục tiêu tiết kiệm',
          isPremium
              ? 'Tối đa ${features?.maxSavingsGoals ?? 10}'
              : 'Tối đa ${features?.maxSavingsGoals ?? 2}',
          isPremium,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          Icons.analytics,
          'Phân tích AI',
          features?.aiAnalysisEnabled ?? false
              ? 'Đã kích hoạt'
              : 'Chỉ dành cho Premium',
          features?.aiAnalysisEnabled ?? false,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String value,
    bool isEnabled,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEnabled ? const Color(0xFFFFA500) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          if (isEnabled)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Subscription? subscription) {
    final isPremium = subscription?.isPremium ?? false;

    // If user is already premium, don't show cancel button
    if (isPremium) {
      return const SizedBox.shrink();
    }

    // If user is free, show upgrade button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleUpgrade,
        icon: const Icon(Icons.star),
        label: const Text('Nâng cấp Premium'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử giao dịch',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Payment>>(
          future: _paymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              final theme = Theme.of(context);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final payments = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentItem(payment);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;

    switch (payment.status) {
      case PaymentStatus.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case PaymentStatus.pending:
        icon = Icons.pending;
        iconColor = Colors.orange;
        break;
      case PaymentStatus.rejected:
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case PaymentStatus.cancelled:
        icon = Icons.block;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.planDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.status.displayName,
                  style: TextStyle(fontSize: 12, color: iconColor),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.toDisplayFormat(payment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${payment.amount ~/ 1000}k',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
