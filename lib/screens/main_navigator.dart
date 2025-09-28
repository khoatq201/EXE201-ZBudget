import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'home/new_dashboard_screen.dart';
import './budget/budget_list_screen.dart';
import './group/group_list_screen.dart';
import 'challenge_screen.dart';
import './reports_screen.dart';
import './settings_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const NewDashboardScreen(),
      const BudgetListScreen(),
      const GroupListScreen(),
      const ChallengeScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
