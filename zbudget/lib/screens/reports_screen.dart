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
              expandedHeight: 100,
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
        // Quick Insights Card (with savings rate integrated)
        _buildQuickInsightsCard(trend),

        const SizedBox(height: 24),

        // Balance Change Chart
        _buildBalanceChangeChart(trend),

        const SizedBox(height: 24),

        // Trend Chart
        _buildTrendChart(trend),

        const SizedBox(height: 24),

        // Comparison Section
        if (comparison != null) _buildComparisonSection(comparison),
      ],
    );
  }

  Widget _buildQuickInsightsCard(TrendReportData trend) {
    final balance = trend.summary.totalBalance;
    final savingsRate = trend.summary.savingsRate;
    final income = trend.summary.totalIncome;
    final expense = trend.summary.totalExpense;
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
            ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
            : [const Color(0xFFFF5252), const Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red).withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPositive ? '💰 Tài chính tích cực' : '⚠️ Cần chú ý',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trong kỳ báo cáo này',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Thu Chi Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: Colors.white.withAlpha(200), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng thu',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatCompact(income),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.white.withAlpha(200), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng chi',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatCompact(expense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Số dư Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white.withAlpha(200), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Số dư',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCompact(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withAlpha(60), thickness: 1),
          const SizedBox(height: 16),

          // Savings Rate with Badge and Advice
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ lệ tiết kiệm',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: savingsRate >= 20
                                ? Colors.green.withAlpha(200)
                                : savingsRate >= 10
                                    ? Colors.orange.withAlpha(200)
                                    : Colors.red.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                savingsRate >= 20 ? '🎉' : savingsRate >= 10 ? '👍' : '⚠️',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                savingsRate >= 20 ? 'Xuất sắc!' : savingsRate >= 10 ? 'Tốt' : 'Cần cải thiện',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      savingsRate >= 20
                          ? 'Bạn đang tiết kiệm rất tốt!'
                          : savingsRate >= 10
                              ? 'Cố gắng tiết kiệm thêm một chút'
                              : 'Hãy cân nhắc giảm chi tiêu không cần thiết',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChangeChart(TrendReportData trend) {
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
              Icon(Icons.trending_up, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Chưa có dữ liệu biến động số dư', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    // Calculate balance changes from starting point
    final startingBalance = trend.trendData.first.balance;
    final balanceChanges = trend.trendData.map((point) {
      return point.balance - startingBalance;
    }).toList();

    // Calculate symmetric min/max for better visualization
    final maxPositive = balanceChanges.where((c) => c >= 0).isEmpty
        ? 0.0
        : balanceChanges.where((c) => c >= 0).reduce((a, b) => a > b ? a : b);
    final maxNegative = balanceChanges.where((c) => c < 0).isEmpty
        ? 0.0
        : balanceChanges.where((c) => c < 0).reduce((a, b) => a < b ? a : b).abs();

    final absMaxChange = maxPositive > maxNegative ? maxPositive : maxNegative;
    final padding = absMaxChange * 0.2;

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
              const Icon(Icons.trending_up, color: AppColors.primary500, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biến động số dư', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text(
                      'So với đầu kỳ: ${CurrencyFormatter.formatCompact(startingBalance)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: balanceChanges.last >= 0 ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      balanceChanges.last >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: balanceChanges.last >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balanceChanges.last >= 0 ? "+" : ""}${CurrencyFormatter.formatCompact(balanceChanges.last)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: balanceChanges.last >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                // Grid configuration
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: absMaxChange > 0 ? (absMaxChange * 2 + padding * 2) / 4 : 1000000,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0) {
                      return FlLine(
                        color: Colors.grey.withAlpha(128),
                        strokeWidth: 2,
                      );
                    }
                    return FlLine(
                      color: Colors.grey.withAlpha(25),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),

                // Min/Max values centered around zero
                minY: -absMaxChange - padding,
                maxY: absMaxChange + padding,

                // Titles configuration
                titlesData: FlTitlesData(
                  // Bottom axis (dates) - Smart interval
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: trend.trendData.length <= 5
                          ? 1.0
                          : trend.trendData.length <= 10
                              ? 2.0
                              : 3.0,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trend.trendData.length) {
                          final date = trend.trendData[index].date;
                          final parts = date.split('-');
                          if (parts.length >= 3) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${parts[2]}/${parts[1]}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),

                  // Left axis (balance changes) - Improved visibility
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: absMaxChange > 0 ? (absMaxChange * 2 + padding * 2) / 4 : 1000000,
                      getTitlesWidget: (value, meta) {
                        // Skip label at zero to avoid clutter
                        if (value.abs() < 0.01) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            value >= 0
                                ? '+${CurrencyFormatter.formatCompact(value)}'
                                : CurrencyFormatter.formatCompact(value),
                            style: TextStyle(
                              fontSize: 13,
                              color: value >= 0 ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),

                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
                    left: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
                  ),
                ),

                // Tooltip configuration - Improved positioning
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final date = trend.trendData[index].date;
                        final change = balanceChanges[index];
                        final currentBalance = trend.trendData[index].balance;

                        // Format date
                        final parts = date.split('-');
                        final formattedDate = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : date;

                        return LineTooltipItem(
                          'Biến động: ${change >= 0 ? "+" : ""}${CurrencyFormatter.formatCompact(change)}\nSố dư: ${CurrencyFormatter.formatCompact(currentBalance)}\n$formattedDate',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.grey.withAlpha(128),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: barData.color ?? Colors.blue,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),

                // Balance change line
                lineBarsData: [
                  LineChartBarData(
                    spots: balanceChanges
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: balanceChanges.last >= 0 ? Colors.green : Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final change = balanceChanges[index];
                        return FlDotCirclePainter(
                          radius: 5,
                          color: change >= 0 ? Colors.green : Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: balanceChanges.last >= 0
                          ? Colors.green.withAlpha(20)
                          : Colors.transparent,
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                    aboveBarData: BarAreaData(
                      show: true,
                      color: balanceChanges.last >= 0
                          ? Colors.transparent
                          : Colors.red.withAlpha(20),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceChangeStat('Số dư đầu kỳ', startingBalance, Colors.blue),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildBalanceChangeStat('Số dư hiện tại', trend.trendData.last.balance,
                  balanceChanges.last >= 0 ? Colors.green : Colors.red),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildBalanceChangeStat('Thay đổi', balanceChanges.last,
                  balanceChanges.last >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChangeStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

    // Calculate min and max values for better chart scaling
    final allValues = [
      ...trend.trendData.map((e) => e.income),
      ...trend.trendData.map((e) => e.expense),
    ];
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final padding = (maxValue - minValue) * 0.1; // 10% padding

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
                // Grid configuration
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (maxValue - minValue) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(25),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(25),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),

                // Min/Max values for better scaling
                minY: minValue - padding > 0 ? minValue - padding : 0,
                maxY: maxValue + padding,

                // Titles configuration
                titlesData: FlTitlesData(
                  // Bottom axis (dates)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trend.trendData.length) {
                          final date = trend.trendData[index].date;
                          final parts = date.split('-');
                          // Format: DD/MM or just DD if same month
                          if (parts.length >= 3) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${parts[2]}/${parts[1]}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return Text(date.split('-').last, style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),

                  // Left axis (amounts)
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (maxValue - minValue) / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            CurrencyFormatter.formatCompact(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
                    left: BorderSide(color: Colors.grey.withAlpha(51), width: 1),
                  ),
                ),

                // Tooltip configuration
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final date = trend.trendData[index].date;
                        final isIncome = spot.barIndex == 0;
                        final label = isIncome ? 'Thu' : 'Chi';
                        final color = isIncome ? Colors.green : Colors.red;

                        return LineTooltipItem(
                          '$label: ${CurrencyFormatter.format(spot.y)}\n$date',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.grey.withAlpha(128),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: barData.color ?? Colors.blue,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),

                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: trend.trendData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.green,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withAlpha(13),
                    ),
                  ),

                  // Expense line
                  LineChartBarData(
                    spots: trend.trendData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withAlpha(13),
                    ),
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

  Widget _buildTrendBadge(double savingsRate) {
    String icon;
    String label;
    Color color;

    if (savingsRate >= 30) {
      icon = '🚀';
      label = 'Tăng mạnh';
      color = Colors.green[700]!;
    } else if (savingsRate >= 15) {
      icon = '📈';
      label = 'Tăng vừa';
      color = Colors.green;
    } else if (savingsRate >= 5) {
      icon = '↗️';
      label = 'Tăng nhẹ';
      color = Colors.lightGreen;
    } else if (savingsRate >= -5) {
      icon = '➡️';
      label = 'Ổn định';
      color = Colors.blue;
    } else if (savingsRate >= -15) {
      icon = '↘️';
      label = 'Giảm nhẹ';
      color = Colors.orange;
    } else if (savingsRate >= -30) {
      icon = '📉';
      label = 'Giảm vừa';
      color = Colors.deepOrange;
    } else {
      icon = '🔻';
      label = 'Giảm mạnh';
      color = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(CurrencyFormatter.formatCompact(period.income),
                                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward, size: 12, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(CurrencyFormatter.formatCompact(period.expense),
                                  style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTrendBadge(period.savingsRate),
                            Text(
                              '${period.savingsRate >= 0 ? "+" : ""}${period.savingsRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: period.savingsRate >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
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
