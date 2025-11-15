import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription_models.dart';
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
  Future<SubscriptionApiResponse<List<SubscriptionHistory>>>? _historyFuture;

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

    // Load status and usage
    await Future.wait([
      subscriptionService.getStatus(),
      subscriptionService.getUsage(),
    ]);

    // Load history once and cache it
    if (mounted) {
      setState(() {
        _historyFuture = subscriptionService.getHistory();
      });
    }
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

  Future<void> _handleDowngrade() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy Premium'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy gói Premium? Bạn sẽ mất tất cả quyền lợi Premium và quay về giới hạn của gói Free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final subscriptionService = context.read<SubscriptionService>();
    final result = await subscriptionService.downgradeToFree();

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Đã hủy Premium thành công'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadSubscriptionData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Không thể hủy Premium'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

    if (isPremium) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleDowngrade,
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy Premium'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bạn sẽ vẫn có quyền truy cập Premium cho đến ngày hết hạn',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

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
        FutureBuilder<SubscriptionApiResponse<List<SubscriptionHistory>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data?.data == null ||
                snapshot.data!.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final history = snapshot.data!.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryItem(item);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryItem(SubscriptionHistory item) {
    IconData icon;
    Color color;

    switch (item.action.toLowerCase()) {
      case 'upgrade':
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case 'downgrade':
        icon = Icons.arrow_downward;
        color = Colors.orange;
        break;
      case 'renewal':
        icon = Icons.refresh;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.toDisplayFormat(item.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (item.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.amount != null)
            Text(
              '${item.amount! ~/ 1000}k',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
