import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/dashboard_service.dart';
import '../../utils/theme_extensions.dart';
import '../../utils/formatters.dart';

class DashboardThemeDemo extends StatelessWidget {
  const DashboardThemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Demo')),
      body: Consumer<DashboardService>(
        builder: (context, dashboardService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header with gradient using theme colors
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.gradientStart, context.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào mừng trở lại!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hôm nay bạn đã tiết kiệm được bao nhiêu?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Balance cards using theme colors
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).cardTheme.color,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thu nhập',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.customTextSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.format(5000000),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: context.incomeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Theme.of(context).cardTheme.color,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiêu',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.customTextSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.format(3200000),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: context.expenseColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Summary card
                Card(
                  color: Theme.of(context).cardTheme.color,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tóm tắt tháng này',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.customTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số dư còn lại:',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: context.customTextSecondary,
                                  ),
                            ),
                            Text(
                              CurrencyFormatter.format(1800000),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: context.incomeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.64,
                          backgroundColor: context.customTextSecondary
                              .withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.incomeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bạn đã tiết kiệm được 64% mục tiêu tháng này',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.customTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Thao tác nhanh',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.customTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add,
                        label: 'Thêm thu nhập',
                        color: context.incomeColor,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.remove,
                        label: 'Thêm chi tiêu',
                        color: context.expenseColor,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.customTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
