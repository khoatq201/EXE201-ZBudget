import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_manager_simple.dart';
import '../../utils/theme_extensions.dart';

class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section using theme colors
            _buildThemeHeader(context),

            // Cards using theme colors
            _buildThemeCard(context),

            // Theme switching controls
            _buildThemeControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.gradientStart, // Sử dụng theme colors
            context.gradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZBudget',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Theme đang hoạt động toàn cục',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Current Theme: ${context.isDarkTheme ? "Dark" : "Light"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Theme Demo Card',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Text chính',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.customTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Text phụ sẽ thay đổi theo theme',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.customTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.incomeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Thu nhập',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.expenseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Chi tiêu',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thay đổi theme (Test)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              themeManager.setTheme(AppTheme.light),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeManager.currentTheme == AppTheme.light
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: const Text('Sáng'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => themeManager.setTheme(AppTheme.dark),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeManager.currentTheme == AppTheme.dark
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: const Text('Tối'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              themeManager.setTheme(AppTheme.system),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeManager.currentTheme == AppTheme.system
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: const Text('System'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
