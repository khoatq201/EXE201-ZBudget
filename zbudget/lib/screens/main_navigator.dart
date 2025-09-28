import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class MainNavigator extends StatefulWidget {
  final Widget child;

  const MainNavigator({required this.child, super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/budget')) return 1;
    if (location.startsWith('/groups')) return 2;
    if (location.startsWith('/challenges')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/budget');
        break;
      case 2:
        context.go('/groups');
        break;
      case 3:
        context.go('/challenges');
        break;
      case 4:
        context.go('/reports');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.backgroundPrimary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ngân sách',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Nhóm'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Thử thách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
