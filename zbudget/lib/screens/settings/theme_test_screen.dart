import 'package:flutter/material.dart';
import '../../utils/theme_extensions.dart';

class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Theme: ${context.isDarkTheme ? "Dark" : "Light"}'),
                    Text('Primary Color: ${context.colorScheme.primary}'),
                    Text('Surface Color: ${context.colorScheme.surface}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Gradient demo
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.gradientStart, context.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Gradient Demo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color samples
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: context.customCardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(
                              color: context.customTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+ 100,000đ',
                            style: Theme.of(context).textTheme.titleMedium
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
                    color: context.customCardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Expense',
                            style: TextStyle(
                              color: context.customTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '- 50,000đ',
                            style: Theme.of(context).textTheme.titleMedium
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

            // Text samples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Samples',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.customTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is primary text',
                      style: TextStyle(color: context.customTextPrimary),
                    ),
                    Text(
                      'This is secondary text',
                      style: TextStyle(color: context.customTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Elevated Button'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
