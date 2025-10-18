import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_manager.dart';
import 'theme_test_screen.dart';

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
              // Light theme option
              Card(
                child: ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Sáng'),
                  trailing: Radio<AppTheme>(
                    value: AppTheme.light,
                    groupValue: themeManager.currentTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeManager.setTheme(value);
                      }
                    },
                  ),
                  onTap: () => themeManager.setTheme(AppTheme.light),
                ),
              ),

              const SizedBox(height: 8),

              // Dark theme option
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Tối'),
                  trailing: Radio<AppTheme>(
                    value: AppTheme.dark,
                    groupValue: themeManager.currentTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeManager.setTheme(value);
                      }
                    },
                  ),
                  onTap: () => themeManager.setTheme(AppTheme.dark),
                ),
              ),

              const SizedBox(height: 8),

              // System theme option
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings_suggest),
                  title: const Text('Theo hệ thống'),
                  trailing: Radio<AppTheme>(
                    value: AppTheme.system,
                    groupValue: themeManager.currentTheme,
                    onChanged: (AppTheme? value) {
                      if (value != null) {
                        themeManager.setTheme(value);
                      }
                    },
                  ),
                  onTap: () => themeManager.setTheme(AppTheme.system),
                ),
              ),

              const SizedBox(height: 24),

              // Theme test link
              Card(
                child: ListTile(
                  leading: const Icon(Icons.preview),
                  title: const Text('Test Theme Demo'),
                  subtitle: const Text(
                    'Xem các thành phần UI với theme hiện tại',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThemeTestScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Preview section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xem trước',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZBudget',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quản lý tài chính cá nhân',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary.withOpacity(0.8),
                                  ),
                            ),
                          ],
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
