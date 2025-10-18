import 'package:flutter/material.dart';
import '../../../utils/theme_extensions.dart';

class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Test'),
        backgroundColor: context.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme Test Screen', style: context.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Colors', style: context.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Primary'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          color: context.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Secondary'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Typography', style: context.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Headline Large',
                      style: context.textTheme.headlineLarge,
                    ),
                    Text(
                      'Headline Medium',
                      style: context.textTheme.headlineMedium,
                    ),
                    Text('Title Large', style: context.textTheme.titleLarge),
                    Text('Body Large', style: context.textTheme.bodyLarge),
                    Text('Body Medium', style: context.textTheme.bodyMedium),
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
