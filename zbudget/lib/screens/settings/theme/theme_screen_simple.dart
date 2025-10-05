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

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đây là ví dụ về thẻ',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nội dung sẽ thay đổi màu theo theme được chọn.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Nút ví dụ'),
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
