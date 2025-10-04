import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../services/report_service.dart';
import '../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  String selectedPeriod = 'month'; // month, week, year
  String selectedTab = 'overview'; // overview, categories, trends
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final reportService = Provider.of<ReportService>(context, listen: false);
    await reportService.refreshAllReports(period: selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
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
                      colors: [
                        AppColors.primary500,
                        AppColors.primary600,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Period Selector
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildPeriodButton('Tuần', 'week'),
                    const SizedBox(width: 8),
                    _buildPeriodButton('Tháng', 'month'),
                    const SizedBox(width: 8),
                    _buildPeriodButton('Năm', 'year'),
                  ],
                ),
              ),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary500,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary500,
                tabs: const [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Danh mục'),
                  Tab(text: 'Xu hướng'),
                ],
              ),
            ),

            // Tab Content
            SliverFillRemaining(
              child: Consumer<ReportService>(
                builder: (context, reportService, child) {
                  if (reportService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (reportService.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Lỗi: ${reportService.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadReports,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(reportService),
                      _buildCategoriesTab(reportService),
                      _buildTrendsTab(reportService),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedPeriod = period;
          });
          _loadReports();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary500 : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
          elevation: isSelected ? 4 : 1,
        ),
        child: Text(label),
      ),
    );
  }

  // ========== Overview Tab ==========
  Widget _buildOverviewTab(ReportService reportService) {
    final trend = reportService.trendReport;
    final comparison = reportService.comparisonReport;

    if (trend == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        _buildSummaryCard('Tổng thu', trend.summary.totalIncome, Colors.green, Icons.arrow_upward),
        const SizedBox(height: 12),
        _buildSummaryCard('Tổng chi', trend.summary.totalExpense, Colors.red, Icons.arrow_downward),
        const SizedBox(height: 12),
        _buildSummaryCard('Số dư', trend.summary.totalBalance,
          trend.summary.totalBalance >= 0 ? Colors.green : Colors.red,
          Icons.account_balance_wallet),
        const SizedBox(height: 12),
        _buildSavingsRateCard(trend.summary.savingsRate),

        const SizedBox(height: 24),

        // Trend Chart
        _buildTrendChart(trend),

        const SizedBox(height: 24),

        // Comparison Section
        if (comparison != null) _buildComparisonSection(comparison),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatVND(amount),
                  style: AppTypography.h3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateCard(double savingsRate) {
    final color = savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tỷ lệ tiết kiệm',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: AppTypography.h2.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            savingsRate >= 20 ? '🎉 Xuất sắc!' : savingsRate >= 10 ? '👍 Tốt' : '⚠️ Cần cải thiện',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(TrendReportData trend) {
    if (trend.trendData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.insights, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Chưa có dữ liệu xu hướng', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Biểu đồ xu hướng', style: AppTypography.h3),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trend.trendData.length) {
                          final date = trend.trendData[index].date;
                          return Text(date.split('-').last, style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: trend.trendData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: trend.trendData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                        .toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Thu nhập', Colors.green),
              const SizedBox(width: 24),
              _buildLegend('Chi tiêu', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildComparisonSection(ComparisonReportData comparison) {
    // Helper to format period label
    String formatPeriodLabel(String period) {
      final parts = period.split('-');
      if (parts.length == 2) {
        final months = ['', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
        final monthIndex = int.tryParse(parts[1]) ?? 0;
        return monthIndex > 0 && monthIndex <= 12 ? months[monthIndex] : period;
      }
      return period;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.primary500, size: 20),
              const SizedBox(width: 8),
              Text('So sánh theo thời gian', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 16),
          ...comparison.comparisons.take(3).map((period) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: period.isCurrent ? AppColors.primary50 : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: period.isCurrent ? Border.all(color: AppColors.primary500, width: 2) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: period.isCurrent ? AppColors.primary500 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatPeriodLabel(period.period),
                      style: TextStyle(
                        color: period.isCurrent ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Thu: ${CurrencyFormatter.formatCompact(period.income)}',
                              style: const TextStyle(fontSize: 12, color: Colors.green)),
                            Text('Chi: ${CurrencyFormatter.formatCompact(period.expense)}',
                              style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Tiết kiệm: ${period.savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========== Categories Tab ==========
  Widget _buildCategoriesTab(ReportService reportService) {
    final category = reportService.categoryReport;

    if (category == null || category.categories.isEmpty) {
      return const Center(child: Text('Không có dữ liệu danh mục'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng ${category.type == "expense" ? "chi" : "thu"}:', style: AppTypography.bodyMedium),
                  Text(CurrencyFormatter.formatVND(category.summary.grandTotal),
                    style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${category.summary.categoryCount} danh mục'),
                  Text('${category.summary.transactionCount} giao dịch'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Pie Chart
        _buildCategoryPieChart(category),

        const SizedBox(height: 16),

        // Category List
        ...category.categories.map((cat) => _buildCategoryItem(cat)),
      ],
    );
  }

  Widget _buildCategoryPieChart(CategoryReportData category) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFFEAA7),
      const Color(0xFFDFE6E9),
    ];

    final categoryNames = {
      'food': 'Ăn uống',
      'transport': 'Di chuyển',
      'shopping': 'Mua sắm',
      'entertainment': 'Giải trí',
      'health': 'Sức khỏe',
      'education': 'Giáo dục',
      'bills': 'Hóa đơn',
      'other': 'Khác',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: category.topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  return PieChartSectionData(
                    value: cat.total,
                    title: '${cat.percentage.toStringAsFixed(0)}%',
                    color: colors[index % colors.length],
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: category.topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    categoryNames[cat.category] ?? cat.category,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryDataPoint cat) {
    final categoryNames = {
      'food': '🍜 Ăn uống',
      'transport': '🚗 Di chuyển',
      'shopping': '🛍️ Mua sắm',
      'entertainment': '🎮 Giải trí',
      'health': '🏥 Sức khỏe',
      'education': '📚 Giáo dục',
      'bills': '💡 Hóa đơn',
      'other': '📝 Khác',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryNames[cat.category] ?? cat.category, style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text('${cat.count} giao dịch • TB: ${CurrencyFormatter.formatCompact(cat.avgAmount)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.formatVND(cat.total), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('${cat.percentage.toStringAsFixed(1)}%',
                style: AppTypography.caption.copyWith(color: AppColors.primary500)),
            ],
          ),
        ],
      ),
    );
  }

  // ========== Trends Tab ==========
  Widget _buildTrendsTab(ReportService reportService) {
    final patterns = reportService.patternsReport;
    final forecast = reportService.forecastReport;

    if (patterns == null && forecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Chưa có dữ liệu xu hướng', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Spending Patterns first (user sees habits first)
        if (patterns != null) ...[
          _buildPatternsSection(patterns),
          const SizedBox(height: 16),
        ],

        // Forecast second (prediction comes after current habits)
        if (forecast != null) ...[
          _buildForecastSection(forecast),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPatternsSection(PatternsReportData patterns) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primary500, size: 20),
              const SizedBox(width: 8),
              Text('Thói quen chi tiêu', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 16),

          // Insights Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInsightRow('📅 Ngày chi nhiều nhất', patterns.insights.mostExpensiveDay),
                const Divider(height: 16),
                _buildInsightRow('🔄 Ngày giao dịch nhiều nhất', patterns.insights.mostFrequentDay),
                const Divider(height: 16),
                _buildInsightRow('💳 Phương thức thanh toán ưa thích', patterns.insights.preferredPaymentMethod),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Day of week chart
          Text('Chi tiêu theo ngày trong tuần', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...patterns.patterns.dayOfWeek.map((day) {
            final maxTotal = patterns.patterns.dayOfWeek.map((d) => d.total).reduce((a, b) => a > b ? a : b);
            final percentage = day.total / maxTotal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(day.dayName, style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      CurrencyFormatter.formatCompact(day.total),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildForecastSection(ForecastReportData forecast) {
    // Helper to format month label
    String formatMonthLabel(String month) {
      final parts = month.split('-');
      if (parts.length == 2) {
        final months = ['', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
                        'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
        final monthIndex = int.tryParse(parts[1]) ?? 0;
        if (monthIndex > 0 && monthIndex <= 12) {
          return '${months[monthIndex]} ${parts[0]}';
        }
      }
      return month;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primary500.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_graph, color: AppColors.primary500, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dự báo tài chính', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Thu: ${forecast.trends.incomeTrend == "increasing" ? "📈 Tăng" : forecast.trends.incomeTrend == "decreasing" ? "📉 Giảm" : "➡️ Ổn định"} • '
                      'Chi: ${forecast.trends.expenseTrend == "increasing" ? "📈 Tăng" : forecast.trends.expenseTrend == "decreasing" ? "📉 Giảm" : "➡️ Ổn định"}',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...forecast.forecast.map((f) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatMonthLabel(f.month),
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.offline_bolt, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('Độ tin cậy: ${f.confidence.toStringAsFixed(0)}%',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatCompact(f.forecastBalance),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: f.forecastBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dự kiến',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
