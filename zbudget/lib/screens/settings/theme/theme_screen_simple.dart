import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_manager.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao diện')),
      body: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Chọn giao diện',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Light Theme
              Card(
                child: ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Sáng'),
                  subtitle: const Text('Giao diện sáng với nền trắng'),
                  trailing: themeManager.currentTheme == AppTheme.light
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    themeManager.setTheme(AppTheme.light);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã chuyển sang giao diện sáng'),
                      ),
                    );
                  },
                ),
              ),

              // Dark Theme
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Tối'),
                  subtitle: const Text('Giao diện tối với nền đen'),
                  trailing: themeManager.currentTheme == AppTheme.dark
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    themeManager.setTheme(AppTheme.dark);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã chuyển sang giao diện tối'),
                      ),
                    );
                  },
                ),
              ),

              // System Theme
              Card(
                child: ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('Theo hệ thống'),
                  subtitle: const Text('Tự động theo cài đặt hệ thống'),
                  trailing: themeManager.currentTheme == AppTheme.system
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    themeManager.setTheme(AppTheme.system);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã chuyển sang theo hệ thống'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Preview
              const Text(
                'Xem trước',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Preview Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xem trước giao diện',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sample App Bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ZBudget',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.notifications,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sample Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.savings,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tiết kiệm',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                  Text(
                                    '2.5M VND',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chi tiêu',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                  Text(
                                    '1.2M VND',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sample List Items
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.home,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Trang chủ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.analytics,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Thống kê',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sample Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                              child: const Text('Nút chính'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: const Text('Nút phụ'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sample Text Styles
                      Text(
                        'Văn bản tiêu đề',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đây là văn bản mô tả để xem cách màu sắc và kiểu chữ thay đổi theo theme.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
