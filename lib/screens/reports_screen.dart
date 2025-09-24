import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

// Data models
class CategoryData {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final String icon;

  CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class MonthlyData {
  final String month;
  final double income;
  final double expenses;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expenses,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  String selectedPeriod = 'T6/2025';
  String selectedTab = 'overview';
  String currentSeason = 'mùa mưa';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Vietnamese category data
  final List<CategoryData> categoryData = [
    CategoryData(
      category: 'Ăn uống',
      amount: 1200000,
      percentage: 35,
      color: const Color(0xFFFF6B6B),
      icon: '🍜',
    ),
    CategoryData(
      category: 'Di chuyển',
      amount: 800000,
      percentage: 23,
      color: const Color(0xFF4ECDC4),
      icon: '🚗',
    ),
    CategoryData(
      category: 'Mua sắm',
      amount: 600000,
      percentage: 18,
      color: const Color(0xFF45B7D1),
      icon: '🛍️',
    ),
    CategoryData(
      category: 'Giải trí',
      amount: 400000,
      percentage: 12,
      color: const Color(0xFF96CEB4),
      icon: '🎮',
    ),
    CategoryData(
      category: 'Khác',
      amount: 400000,
      percentage: 12,
      color: const Color(0xFFFFEAA7),
      icon: '📝',
    ),
  ];

  // Monthly data for charts
  final List<MonthlyData> monthlyData = [
    MonthlyData(month: 'T2', income: 2800000, expenses: 1200000),
    MonthlyData(month: 'T3', income: 3200000, expenses: 1800000),
    MonthlyData(month: 'T4', income: 2600000, expenses: 1400000),
    MonthlyData(month: 'T5', income: 3800000, expenses: 2200000),
    MonthlyData(month: 'T6', income: 3200000, expenses: 1600000),
    MonthlyData(month: 'T7', income: 4200000, expenses: 2800000),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to format currency
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary500,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Báo cáo chi tiêu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary500, AppColors.primary600],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // Tab selector
                    _buildTabSelector(),
                    const SizedBox(height: 20),

                    // Content based on selected tab
                    if (selectedTab == 'overview') _buildOverviewTab(),
                    if (selectedTab == 'categories') _buildCategoriesTab(),
                    if (selectedTab == 'trends') _buildTrendsTab(),

                    const SizedBox(height: 20),

                    // Vietnamese cultural insights
                    _buildVietnameseCulturalInsights(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['T5/2025', 'T6/2025', 'T7/2025'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period == selectedPeriod;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedPeriod = period;
                });
              },
              selectedColor: AppColors.primary500,
              backgroundColor: AppColors.backgroundSecondary,
              side: BorderSide(
                color: isSelected ? AppColors.primary500 : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      {'id': 'overview', 'title': 'Tổng quan', 'icon': Icons.dashboard},
      {'id': 'categories', 'title': 'Danh mục', 'icon': Icons.pie_chart},
      {'id': 'trends', 'title': 'Xu hướng', 'icon': Icons.trending_up},
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = tab['id'] == selectedTab;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = tab['id'] as String;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500 : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary500
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['title'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewTab() {
    final currentMonthData = monthlyData.last;
    final savings = currentMonthData.income - currentMonthData.expenses;
    final savingsRate = (savings / currentMonthData.income * 100);

    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Thu nhập',
                amount: currentMonthData.income,
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Chi tiêu',
                amount: currentMonthData.expenses,
                icon: Icons.trending_down,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Tiết kiệm',
                amount: savings,
                icon: Icons.savings,
                color: AppColors.accent500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Tỷ lệ tiết kiệm',
                amount: savingsRate,
                icon: Icons.percent,
                color: AppColors.warning,
                isPercentage: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Monthly Trend Chart
        _buildMonthlyTrendChart(),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        // Pie Chart
        Container(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: categoryData.map((data) {
                return PieChartSectionData(
                  value: data.percentage,
                  title: '${data.percentage.toInt()}%',
                  color: data.color,
                  radius: 100,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Category List
        ...categoryData.map((data) => _buildCategoryItem(data)),
      ],
    );
  }

  Widget _buildTrendsTab() {
    return Column(
      children: [
        // Line Chart for trends
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 1000000).toStringAsFixed(0)}M',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < monthlyData.length) {
                        return Text(
                          monthlyData[index].month,
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Income line
                LineChartBarData(
                  spots: monthlyData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.income);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
                // Expenses line
                LineChartBarData(
                  spots: monthlyData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.expenses);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.error,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Trend insights
        _buildTrendInsights(),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPercentage
                ? '${amount.toStringAsFixed(1)}%'
                : formatCurrency(amount),
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              monthlyData.map((e) => e.income).reduce((a, b) => a > b ? a : b) +
              500000,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < monthlyData.length) {
                    return Text(
                      monthlyData[index].month,
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: monthlyData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.income,
                  color: AppColors.success,
                  width: 12,
                ),
                BarChartRodData(
                  toY: entry.value.expenses,
                  color: AppColors.error,
                  width: 12,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(data.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.category,
                  style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(data.amount),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${data.percentage.toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích xu hướng',
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            icon: Icons.trending_up,
            title: 'Thu nhập tăng',
            description: 'Thu nhập tăng 15% so với tháng trước',
            color: AppColors.success,
          ),
          _buildInsightItem(
            icon: Icons.trending_down,
            title: 'Chi tiêu giảm',
            description: 'Chi tiêu giảm 8% so với tháng trước',
            color: AppColors.error,
          ),
          _buildInsightItem(
            icon: Icons.savings,
            title: 'Tiết kiệm tốt',
            description: 'Đạt mục tiêu tiết kiệm 50% trong tháng',
            color: AppColors.accent500,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVietnameseCulturalInsights() {
    String title = 'Phân tích mùa mưa';
    String insight =
        'Chi tiêu đi lại tăng 25% vào mùa mưa. Nên dùng Grab/xe ôm công nghệ thay vì xe cá nhân.';
    String icon = '☔';
    Color color = AppColors.accent500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
