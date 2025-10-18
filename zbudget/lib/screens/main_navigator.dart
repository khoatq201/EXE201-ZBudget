import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/theme_extensions.dart';
import '../services/notification_sync_service.dart';
import '../widgets/notification_badge.dart';

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
    if (location.startsWith('/savings')) return 2;
    if (location.startsWith('/group-budgets') || location.startsWith('/groups'))
      return 3;
    // Ẩn tab thử thách - bỏ qua index 4
    // if (location.startsWith('/challenges')) return 4;
    if (location.startsWith('/reports')) return 4; // Giảm index từ 5 xuống 4
    if (location.startsWith('/notifications'))
      return 5; // Giảm index từ 6 xuống 5
    if (location.startsWith('/settings')) return 6; // Giảm index từ 7 xuống 6
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
        context.go('/savings');
        break;
      case 3:
        context.go('/group-budgets');
        break;
      // Ẩn tab thử thách - bỏ qua case 4
      // case 4:
      //   context.go('/challenges');
      //   break;
      case 4: // Giảm index từ 5 xuống 4
        context.go('/reports');
        break;
      case 5: // Giảm index từ 6 xuống 5
        context.go('/notifications');
        break;
      case 6: // Giảm index từ 7 xuống 6
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
        selectedItemColor: context.colorScheme.primary,
        unselectedItemColor: context.settingsItemSubtitleColor,
        backgroundColor: context.cardBackground,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ngân sách',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Tiết kiệm',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Nhóm',
          ),
          // Ẩn tab thử thách - comment out thay vì xóa
          // const BottomNavigationBarItem(
          //   icon: Icon(Icons.emoji_events),
          //   label: 'Thử thách',
          // ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NotificationSyncService>(
              builder: (context, service, child) {
                return NotificationBadge(
                  child: const Icon(Icons.notifications),
                );
              },
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
