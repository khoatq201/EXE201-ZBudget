import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../widgets/welcome_banner.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import '../budget/budget_list_screen.dart';

class NewDashboardScreen extends StatefulWidget {
  const NewDashboardScreen({super.key});

  @override
  State<NewDashboardScreen> createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends State<NewDashboardScreen>
    with TickerProviderStateMixin {
  // Student-focused financial data (lower amounts for Vietnamese students)
  final int monthlyAllowance = 3000000; // 3M VND monthly from family
  final int totalExpense = 2200000; // 2.2M VND monthly expenses
  final int currentBalance = 800000; // 800K VND remaining
  final String selectedPeriod = 'Tháng này';
  final String studentYear = 'Năm 2'; // Second year student
  final String university = 'ĐH Bách Khoa'; // University name
  final int savingsGoal = 5000000; // 5M VND savings goal
  final int dailyBudget = 100000; // 100K VND daily budget
  final int daysUntilExam = 25; // Days until exam period
  final String upcomingEvent = 'Kỳ thi cuối kỳ'; // Upcoming event

  late AnimationController _progressController;
  late AnimationController _insightController;
  late Animation<double> _progressAnimation;
  late Animation<double> _insightAnimation;

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'icon': '📚',
      'description': 'Mua giáo trình',
      'meta': 'Nhà sách Trần Hưng Đạo • 26/06/2025 Thứ 5',
      'amount': '-120,000',
      'rawAmount': -120000,
      'isIncome': false,
    },
    {
      'id': '2',
      'icon': '👨‍👩‍👧‍👦',
      'description': 'Tiền phụ cấp tháng',
      'meta': 'Chuyển khoản gia đình • 25/06/2025 Thứ 4',
      'amount': '+3,000,000',
      'rawAmount': 3000000,
      'isIncome': true,
    },
    {
      'id': '3',
      'icon': '🍽️',
      'description': 'Cơm căng tin trường',
      'meta': 'Căng tin ĐH Bách Khoa • 24/06/2025 Thứ 3',
      'amount': '-25,000',
      'rawAmount': -25000,
      'isIncome': false,
    },
    {
      'id': '4',
      'icon': '🚌',
      'description': 'Xe bus đến trường',
      'meta': 'Tuyến bus 32 • 23/06/2025 Thứ 2',
      'amount': '-7,000',
      'rawAmount': -7000,
      'isIncome': false,
    },
    {
      'id': '5',
      'icon': '🎓',
      'description': 'Gia sư toán lớp 9',
      'meta': 'Quận 1 • 22/06/2025 Chủ nhật',
      'amount': '+200,000',
      'rawAmount': 200000,
      'isIncome': true,
    },
    {
      'id': '6',
      'icon': '☕',
      'description': 'Cà phê học nhóm',
      'meta': 'Highlands Coffee - Campus • 21/06/2025 Thứ 7',
      'amount': '-35,000',
      'rawAmount': -35000,
      'isIncome': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _insightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _insightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _insightController, curve: Curves.easeInOut),
    );

    // Start animations
    _progressController.forward();
    _insightController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _insightController.dispose();
    super.dispose();
  }

  String formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  Map<String, dynamic> getStudentInsight() {
    final dailyAverage = totalExpense / 30;
    final remainingDays = 30 - DateTime.now().day;
    final budgetRemaining = currentBalance / remainingDays;

    if (daysUntilExam <= 30 && daysUntilExam > 0) {
      return {
        'icon': '📚',
        'title': '$daysUntilExam ngày đến $upcomingEvent',
        'message': 'Chuẩn bị ngân sách cho mùa thi!',
        'type': 'academic',
      };
    } else if (budgetRemaining < dailyBudget) {
      return {
        'icon': '⚠️',
        'title': 'Ngân sách thấp',
        'message':
            'Chỉ còn ${formatCurrency(budgetRemaining.toInt())}/ngày. Ăn cơm căng tin hoặc nấu ăn tại nhà!',
        'type': 'warning',
      };
    } else if (dailyAverage < 80000) {
      return {
        'icon': '🎉',
        'title': 'Sinh viên tiết kiệm!',
        'message':
            'Chi tiêu dưới 80K/ngày - tuyệt vời! Tiếp tục duy trì thói quen này.',
        'type': 'achievement',
      };
    } else {
      return {
        'icon': '💡',
        'title': 'Mẹo tiết kiệm',
        'message': 'Mua sách cũ, ăn cơm trường, đi xe bus để tiết kiệm tối đa!',
        'type': 'tip',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = getStudentInsight();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.itemSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Consumer<AppProvider>(
                builder: (context, app, _) {
                  final userName = app.user?.name ?? 'Sinh viên';
                  return WelcomeBanner(userName: userName);
                },
              ),

              const SizedBox(height: AppSpacing.itemSpacing),

              // Student Smart Insight Card
              _buildInsightCard(insight),

              const SizedBox(height: AppSpacing.itemSpacing),

              // Student Balance Card with Daily Budget
              _buildBalanceCard(),

              const SizedBox(height: AppSpacing.itemSpacing),

              // Income and Expense Summary
              _buildSummaryRow(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Quick Actions
              _buildQuickActions(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Additional Features
              _buildFeatures(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Recent Transaction History
              _buildHistory(),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // Logout Button
              _buildLogout(),

              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return AnimatedBuilder(
      animation: _insightAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _insightAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      insight['icon'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'],
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight['message'],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    final savingsProgress = (currentBalance / savingsGoal) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary500, const Color(0xFF2E8B57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư tháng này',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatCurrency(currentBalance)} VND',
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngân sách hàng ngày: ${formatCurrency(dailyBudget)} VND',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu tiết kiệm',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '${savingsProgress.toInt()}%',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      (savingsProgress / 100) * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu: ${formatCurrency(savingsGoal)} VND',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              'Thu nhập tháng',
              '${formatCurrency(monthlyAllowance)} VND',
              AppColors.primary500,
              icon: Icons.wallet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              'Đã chi',
              '${formatCurrency(totalExpense)} VND',
              AppColors.error,
              icon: Icons.trending_down,
              subtitle:
                  '${((totalExpense / monthlyAllowance) * 100).toInt()}% thu nhập',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    Color color, {
    IconData? icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thao tác nhanh',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _quickActionButton(
                'Thêm chi tiêu',
                Icons.add,
                AppColors.primary500,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                ),
              ),
              _quickActionButton(
                'Thu nhập',
                Icons.trending_up,
                AppColors.success,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddIncomeScreen(),
                  ),
                ),
              ),
              _quickActionButton(
                'Ngân sách',
                Icons.pie_chart,
                AppColors.info,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetListScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm tính năng',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _featureCard(
                  'Nhóm',
                  'Chia sẻ chi phí',
                  Icons.people,
                  AppColors.error,
                  () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Quản lý nhóm'))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _featureCard(
                  'Thử thách',
                  'Tiết kiệm vui',
                  Icons.emoji_events,
                  AppColors.warning,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thử thách tiết kiệm')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giao dịch gần đây',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xem tất cả giao dịch')),
                ),
                child: Text(
                  'Xem tất cả',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_transactions.take(4).map((t) => _transactionRow(t)).toList()),
        ],
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> transaction) {
    final isIncome = transaction['isIncome'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark200.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                transaction['icon'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['meta'],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'],
            style: AppTypography.body.copyWith(
              color: isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: Icon(Icons.logout, color: AppColors.error),
        label: Text(
          'Đăng xuất',
          style: AppTypography.body.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform logout
              final appProvider = context.read<AppProvider>();
              appProvider.logout();
            },
            child: Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
