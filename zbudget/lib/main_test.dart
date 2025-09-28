import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'constants/colors.dart';
import 'widgets/welcome_banner.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: MaterialApp(
        title: 'ZBudget Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: AppColors.primary500,
          scaffoldBackgroundColor: AppColors.backgroundPrimary,
        ),
        home: const TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AppProvider>(
                builder: (context, app, _) {
                  final userName = app.user?.name ?? 'Sinh viên';
                  return WelcomeBanner(
                    userName: userName,
                    onNotificationTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔔 Bạn có 3 thông báo mới!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '🎉 Welcome Banner đã hoạt động!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Banner welcome đã được tích hợp thành công vào ứng dụng Flutter ZBudget!',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
