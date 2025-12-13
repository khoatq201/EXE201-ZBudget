import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_extensions.dart';
import '../constants/typography.dart';
import '../services/report_service.dart';
import '../services/subscription_service.dart';
import '../utils/formatters.dart';
import '../widgets/floating_ai_button.dart';
import '../widgets/premium/premium_paywall.dart';
import '../services/ai_analysis_service.dart';
import '../models/ai_analysis_models.dart';

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

  // Progress animation controllers for each period
  Map<String, AnimationController> _progressControllers = {};
  Map<String, Animation<double>> _progressAnimations = {};

  // Smart cache for AI analysis - cache by period
  Map<String, Map<String, dynamic>> _aiAnalysisCache =
      <String, Map<String, dynamic>>{};
  Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};
  static const Duration _cacheValidityDuration = Duration(
    hours: 2,
  ); // Tăng cache lên 2 giờ

  // Cache for each tab - cache by tab and period
  Map<String, Map<String, dynamic>> _overviewCache =
      <String, Map<String, dynamic>>{};
  Map<String, Map<String, dynamic>> _categoriesCache =
      <String, Map<String, dynamic>>{};
  Map<String, Map<String, dynamic>> _trendsCache =
      <String, Map<String, dynamic>>{};
  Map<String, DateTime> _tabCacheTimestamps = <String, DateTime>{};

  // Getters to ensure maps are never null
  Map<String, Map<String, dynamic>> get aiAnalysisCache => _aiAnalysisCache;
  Map<String, DateTime> get cacheTimestamps => _cacheTimestamps;

  // Rate limit protection
  DateTime? _lastApiCallTime;
  static const Duration _minApiCallInterval = Duration(
    seconds: 5, // Giảm xuống 5 giây để cho phép gọi API thường xuyên hơn
  );
  bool _isApiCallInProgress = false;

  // Progress tracking for AI analysis
  Map<String, double> _analysisProgress = <String, double>{};
  Map<String, String> _analysisStatus = <String, String>{};
  Map<String, List<String>> _analysisSteps = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
      // Disable background preloading to avoid API spam
      // _preloadOtherPeriods();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all progress animation controllers
    for (var controller in _progressControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReports() async {
    // Only load data for current tab
    _loadTabData(selectedTab);
  }

  // Handle tab changes
  void _onTabChanged() {
    final currentIndex = _tabController.index;
    String tabName;

    switch (currentIndex) {
      case 0:
        tabName = 'overview';
        break;
      case 1:
        tabName = 'categories';
        break;
      case 2:
        tabName = 'trends';
        break;
      case 3:
        tabName = 'ai_analysis';
        // Reset AI cache when switching to AI tab to ensure fresh data
        _clearAIAnalysisCache();
        break;
      default:
        tabName = 'overview';
    }

    selectedTab = tabName;
    print('🔄 Tab changed to: $tabName');

    // Load data for specific tab
    _loadTabData(tabName);
  }

  // Load data for specific tab
  Future<void> _loadTabData(String tabName) async {
    final cacheKey = '${tabName}_$selectedPeriod';
    final now = DateTime.now();

    // Check cache first
    if (_isTabDataCached(tabName, selectedPeriod)) {
      print('✅ Using cached data for $tabName - $selectedPeriod');
      return;
    }

    print('🔄 Loading fresh data for $tabName - $selectedPeriod');

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);

      switch (tabName) {
        case 'overview':
          await _loadOverviewData(reportService);
          break;
        case 'categories':
          await _loadCategoriesData(reportService);
          break;
        case 'trends':
          await _loadTrendsData(reportService);
          break;
        case 'ai_analysis':
          // AI analysis is handled separately
          break;
      }

      // Cache the data
      _cacheTabData(tabName, selectedPeriod, now);
    } catch (e) {
      print('❌ Error loading $tabName data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadReports,
            child: CustomScrollView(
              slivers: [
                // App Bar (use same header style as Dashboard)
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    title: null,
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.headerGradientStart,
                            context.headerGradientEnd,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Báo cáo chi tiêu',
                                style: AppTypography.h3.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                    labelColor: context.colorScheme.primary,
                    unselectedLabelColor: context.settingsItemSubtitleColor,
                    indicatorColor: context.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Tổng quan'),
                      Tab(text: 'Danh mục'),
                      Tab(text: 'Xu hướng'),
                      Tab(text: 'AI Phân tích'),
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
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
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
                          _buildAIAnalysisTab(reportService),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const FloatingAiButton(),
        ],
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
            // Clear tab cache when period changes
            _overviewCache.clear();
            _categoriesCache.clear();
            _trendsCache.clear();
            _tabCacheTimestamps.clear();
            // Clear AI analysis cache when period changes
            if (aiAnalysisCache.isNotEmpty) aiAnalysisCache.clear();
            if (cacheTimestamps.isNotEmpty) cacheTimestamps.clear();
            // Clear progress tracking for current period
            if (_analysisProgress.isNotEmpty) _analysisProgress.clear();
            if (_analysisStatus.isNotEmpty) _analysisStatus.clear();
            if (_analysisSteps.isNotEmpty) _analysisSteps.clear();
          });
          _loadReports();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? context.headerGradientStart
              : context.cardBackground,
          foregroundColor: isSelected
              ? context.colorScheme.onPrimary
              : context.settingsItemTitleColor,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              ? [context.headerGradientStart, context.headerGradientEnd]
              : [Colors.red.shade400, Colors.deepOrange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
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
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.warning,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPositive ? 'Tài chính tích cực' : 'Cần chú ý',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trong kỳ báo cáo này',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    // Use cardBackground with subtle opacity so it adapts to dark/light themes
                    color: context.cardBackground.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.cardBorder.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng thu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    // Use cardBackground with subtle opacity so it adapts to dark/light themes
                    color: context.cardBackground.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.cardBorder.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tổng chi',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
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
              // Slightly lighter card background for the balance row so it adapts with theme
              color: context.cardBackground.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.cardBorder.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Số dư',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
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
          Divider(
            color: context.sectionHeaderColor.withOpacity(0.12),
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // Savings Rate with Badge and Advice
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.savings,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ lệ tiết kiệm',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${savingsRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: savingsRate >= 20
                                ? context.incomeColor.withOpacity(0.85)
                                : savingsRate >= 10
                                ? Colors.orange.withOpacity(0.85)
                                : context.expenseColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                savingsRate >= 20
                                    ? Icons.celebration
                                    : savingsRate >= 10
                                    ? Icons.thumb_up
                                    : Icons.warning,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                savingsRate >= 20
                                    ? 'Xuất sắc!'
                                    : savingsRate >= 10
                                    ? 'Tốt'
                                    : 'Cần cải thiện',
                                style: TextStyle(
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
                        color: Colors.white.withValues(alpha: 0.85),
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
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: context.settingsItemSubtitleColor.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu biến động số dư',
                style: TextStyle(color: context.settingsItemSubtitleColor),
              ),
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
        : balanceChanges
              .where((c) => c < 0)
              .reduce((a, b) => a < b ? a : b)
              .abs();

    final absMaxChange = maxPositive > maxNegative ? maxPositive : maxNegative;
    final padding = absMaxChange * 0.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
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
              Icon(
                Icons.trending_up,
                color: context.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biến động số dư', style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text(
                      'So với đầu kỳ: ${CurrencyFormatter.formatCompact(startingBalance)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.settingsItemSubtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: balanceChanges.last >= 0
                      ? context.incomeColor.withOpacity(0.12)
                      : context.expenseColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      balanceChanges.last >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                      color: balanceChanges.last >= 0
                          ? context.incomeColor
                          : context.expenseColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balanceChanges.last >= 0 ? "+" : ""}${CurrencyFormatter.formatCompact(balanceChanges.last)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: balanceChanges.last >= 0
                            ? context.incomeColor
                            : context.expenseColor,
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
                  horizontalInterval: absMaxChange > 0
                      ? (absMaxChange * 2 + padding * 2) / 4
                      : 1000000,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0) {
                      return FlLine(
                        color: context.settingsItemSubtitleColor.withOpacity(
                          0.9,
                        ),
                        strokeWidth: 2,
                      );
                    }
                    return FlLine(
                      color: context.settingsItemSubtitleColor.withOpacity(
                        0.18,
                      ),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.settingsItemTitleColor,
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
                      interval: absMaxChange > 0
                          ? (absMaxChange * 2 + padding * 2) / 4
                          : 1000000,
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
                              color: value >= 0
                                  ? context.incomeColor
                                  : context.expenseColor,
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
                    bottom: BorderSide(
                      color: context.settingsItemSubtitleColor.withAlpha(51),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: context.settingsItemSubtitleColor.withAlpha(51),
                      width: 1,
                    ),
                  ),
                ),

                // Tooltip configuration - Improved positioning
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                        final formattedDate = parts.length >= 3
                            ? '${parts[2]}/${parts[1]}'
                            : date;

                        return LineTooltipItem(
                          'Biến động: ${change >= 0 ? "+" : ""}${CurrencyFormatter.formatCompact(change)}\nSố dư: ${CurrencyFormatter.formatCompact(currentBalance)}\n$formattedDate',
                          TextStyle(
                            color: context.colorScheme.onPrimary,
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
                          color: context.settingsItemSubtitleColor.withOpacity(
                            0.9,
                          ),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color:
                                  barData.color ?? context.colorScheme.primary,
                              strokeWidth: 2,
                              strokeColor: context.cardBackground,
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
                    color: balanceChanges.last >= 0
                        ? context.incomeColor
                        : context.expenseColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final change = balanceChanges[index];
                        return FlDotCirclePainter(
                          radius: 5,
                          color: change >= 0
                              ? context.incomeColor
                              : context.expenseColor,
                          strokeWidth: 2,
                          strokeColor: context.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: balanceChanges.last >= 0
                          ? context.incomeColor.withOpacity(0.08)
                          : Colors.transparent,
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                    aboveBarData: BarAreaData(
                      show: true,
                      color: balanceChanges.last >= 0
                          ? Colors.transparent
                          : context.expenseColor.withOpacity(0.08),
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
              color: context.infoRowBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceChangeStat(
                  'Số dư đầu kỳ',
                  startingBalance,
                  context.colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: context.cardBorder.withOpacity(0.6),
                ),
                _buildBalanceChangeStat(
                  'Số dư hiện tại',
                  trend.trendData.last.balance,
                  balanceChanges.last >= 0
                      ? context.incomeColor
                      : context.expenseColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: context.cardBorder.withOpacity(0.6),
                ),
                _buildBalanceChangeStat(
                  'Thay đổi',
                  balanceChanges.last,
                  balanceChanges.last >= 0
                      ? context.incomeColor
                      : context.expenseColor,
                ),
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
            color: context.settingsItemSubtitleColor,
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
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insights,
                size: 48,
                color: context.settingsItemSubtitleColor.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu xu hướng',
                style: TextStyle(color: context.settingsItemSubtitleColor),
              ),
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
        color: context.cardBackground,
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
                      color: context.settingsItemSubtitleColor.withOpacity(
                        0.12,
                      ),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: context.settingsItemSubtitleColor.withOpacity(
                        0.12,
                      ),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.settingsItemSubtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return Text(
                            date.split('-').last,
                            style: const TextStyle(fontSize: 10),
                          );
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
                            style: TextStyle(
                              fontSize: 10,
                              color: context.settingsItemSubtitleColor,
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
                    bottom: BorderSide(
                      color: context.settingsItemSubtitleColor.withOpacity(0.2),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: context.settingsItemSubtitleColor.withOpacity(0.2),
                      width: 1,
                    ),
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
                        final color = isIncome
                            ? context.incomeColor
                            : context.expenseColor;

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
                          color: context.settingsItemSubtitleColor.withOpacity(
                            0.9,
                          ),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color:
                                  barData.color ?? context.colorScheme.primary,
                              strokeWidth: 2,
                              strokeColor: context.cardBackground,
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
                    color: context.incomeColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: context.incomeColor,
                          strokeWidth: 2,
                          strokeColor: context.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.incomeColor.withOpacity(0.06),
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
                    color: context.expenseColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: context.expenseColor,
                          strokeWidth: 2,
                          strokeColor: context.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.expenseColor.withOpacity(0.06),
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
              _buildLegend('Thu nhập', context.incomeColor),
              const SizedBox(width: 24),
              _buildLegend('Chi tiêu', context.expenseColor),
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
        final months = [
          '',
          'T1',
          'T2',
          'T3',
          'T4',
          'T5',
          'T6',
          'T7',
          'T8',
          'T9',
          'T10',
          'T11',
          'T12',
        ];
        final monthIndex = int.tryParse(parts[1]) ?? 0;
        return monthIndex > 0 && monthIndex <= 12 ? months[monthIndex] : period;
      }
      return period;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
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
              Icon(
                Icons.compare_arrows,
                color: context.colorScheme.primary,
                size: 20,
              ),
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
                color: period.isCurrent
                    ? context.headerGradientEnd.withOpacity(0.08)
                    : context.infoRowBackground,
                borderRadius: BorderRadius.circular(8),
                border: period.isCurrent
                    ? Border.all(color: context.headerGradientEnd, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: period.isCurrent
                          ? context.headerGradientStart
                          : (context.isDarkTheme
                                ? context.cardBackground.withOpacity(0.6)
                                : context.cardBackground.withOpacity(0.95)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatPeriodLabel(period.period),
                      style: TextStyle(
                        color: period.isCurrent
                            ? context.colorScheme.onPrimary
                            : context.settingsItemTitleColor,
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
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(
                                    period.income,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(
                                    period.expense,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                color: period.savingsRate >= 0
                                    ? Colors.green
                                    : Colors.red,
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
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng ${category.type == "expense" ? "chi" : "thu"}:',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    CurrencyFormatter.formatVND(category.summary.grandTotal),
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        color: context.cardBackground,
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
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onPrimary,
                    ),
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
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryNames[cat.category] ?? cat.category,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${cat.count} giao dịch • TB: ${CurrencyFormatter.formatCompact(cat.avgAmount)}',
                  style: AppTypography.caption.copyWith(
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatVND(cat.total),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${cat.percentage.toStringAsFixed(1)}%',
                style: AppTypography.caption.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
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
            Icon(
              Icons.trending_up,
              size: 64,
              color: context.settingsItemSubtitleColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu xu hướng',
              style: TextStyle(color: context.settingsItemSubtitleColor),
            ),
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
      ],
    );
  }

  Widget _buildPatternsSection(PatternsReportData patterns) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
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
              Icon(
                Icons.psychology,
                color: context.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Thói quen chi tiêu', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: 16),

          // Insights Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Use header gradient end as a subtle background to match header theme
              color: context.headerGradientEnd.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInsightRowWithIcon(
                  Icons.calendar_today,
                  'Ngày chi nhiều nhất',
                  patterns.insights.mostExpensiveDay,
                ),
                const Divider(height: 16),
                _buildInsightRowWithIcon(
                  Icons.repeat,
                  'Ngày giao dịch nhiều nhất',
                  patterns.insights.mostFrequentDay,
                ),
                const Divider(height: 16),
                _buildInsightRowWithIcon(
                  Icons.credit_card,
                  'Phương thức thanh toán ưa thích',
                  patterns.insights.preferredPaymentMethod,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Day of week chart
          Text(
            'Chi tiêu theo ngày trong tuần',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...patterns.patterns.dayOfWeek.map((day) {
            final maxTotal = patterns.patterns.dayOfWeek
                .map((d) => d.total)
                .reduce((a, b) => a > b ? a : b);
            final percentage = day.total / maxTotal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      day.dayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: context.infoRowBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary,
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

  Widget _buildInsightRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.bodySmall),
            ],
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== AI Analysis Tab ==========
  Widget _buildAIAnalysisTab(ReportService reportService) {
    // Check if user has premium access to AI Analysis
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final canUseAI = subscriptionService.isPremium;

        // Show premium paywall if not premium
        if (!canUseAI) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tính năng Premium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Phân tích AI chi tiết chỉ dành cho người dùng Premium',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Features preview
                  _buildPremiumFeatureItem(
                    Icons.analytics,
                    'Phân tích xu hướng chi tiêu',
                    'Hiểu rõ thói quen chi tiêu của bạn',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeatureItem(
                    Icons.trending_up,
                    'Dự báo ngân sách',
                    'Dự đoán chi tiêu trong tương lai',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeatureItem(
                    Icons.lightbulb,
                    'Gợi ý thông minh',
                    'Nhận insight và lời khuyên tiết kiệm',
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumFeatureItem(
                    Icons.warning,
                    'Phát hiện bất thường',
                    'Cảnh báo chi tiêu không bình thường',
                  ),
                  const SizedBox(height: 32),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumPaywallScreen(
                              feature: 'Phân tích AI chi tiết',
                              reason: 'Nhận insight thông minh về chi tiêu',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Nâng cấp Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User has premium - show AI analysis
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadAIAnalysis(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // AI Analysis Header with Refresh Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Phân tích AI - ${_getPeriodLabel(selectedPeriod)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.settingsItemTitleColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _clearAIAnalysisCache();
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Làm mới phân tích',
                          ),
                        ],
                      ),
                    ),
                    // Progress bar
                    _buildAnalysisProgressBar(selectedPeriod),
                    // Loading shimmer effect
                    _buildLoadingShimmer(),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              // Check if it's a rate limit error
              final errorMessage = snapshot.error.toString();
              final isRateLimited =
                  errorMessage.contains('Rate limit') ||
                  errorMessage.contains('429') ||
                  errorMessage.contains('rate_limit_exceeded') ||
                  errorMessage.contains('Vui lòng chờ');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRateLimited ? Icons.schedule : Icons.error_outline,
                      size: 64,
                      color: context.settingsItemSubtitleColor.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRateLimited
                          ? 'AI đang quá tải. Vui lòng thử lại sau 10 phút.'
                          : 'Lỗi: ${snapshot.error}',
                      style: TextStyle(
                        color: context.settingsItemSubtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (isRateLimited) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(height: 8),
                            const Text(
                              'AI đã đạt giới hạn sử dụng hôm nay.\nHãy thử lại vào ngày mai.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        _clearAIAnalysisCache();
                        setState(() {});
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final analysis = snapshot.data!;

            // Process analysis data

            // Safe type casting with fallback
            final financialAnalysis =
                analysis['financialAnalysis'] is FinancialAnalysis
                ? analysis['financialAnalysis'] as FinancialAnalysis
                : analysis['financialAnalysis'] is Map
                ? FinancialAnalysis.fromJson(
                    analysis['financialAnalysis'] as Map<String, dynamic>,
                  )
                : FinancialAnalysis(
                    healthScore: 'N/A',
                    strengths: [],
                    weaknesses: [],
                    risks: [],
                    opportunities: [],
                    recommendations: [],
                    summary: 'Dữ liệu tạm thời không khả dụng',
                  );

            final forecast = analysis['forecast'] is AIForecast
                ? analysis['forecast'] as AIForecast
                : analysis['forecast'] is Map
                ? AIForecast.fromJson(
                    analysis['forecast'] as Map<String, dynamic>,
                  )
                : AIForecast(
                    method: 'fallback',
                    forecast: [],
                    historicalData: null,
                    message: 'Dự báo tạm thời không khả dụng',
                  );

            final anomalies = analysis['anomalies'] is List
                ? (analysis['anomalies'] as List).map((a) {
                    if (a is Anomaly) {
                      return a; // Already an Anomaly object
                    } else if (a is Map<String, dynamic>) {
                      return Anomaly.fromJson(a); // Convert from Map
                    } else {
                      return Anomaly(
                        date: DateTime.now(),
                        category: 'unknown',
                        amount: 0,
                        description: 'Unknown anomaly',
                        expectedRange: 'N/A',
                        severity: 'low',
                      );
                    }
                  }).toList()
                : <Anomaly>[];

            final recommendations = analysis['recommendations'] is List
                ? (analysis['recommendations'] as List).map((r) {
                    if (r is Recommendation) {
                      return r; // Already a Recommendation object
                    } else if (r is Map<String, dynamic>) {
                      return Recommendation.fromJson(r); // Convert from Map
                    } else {
                      return Recommendation(
                        title: 'Unknown',
                        description: 'Unknown recommendation',
                        priority: 'low',
                        estimatedSavings: 0,
                      );
                    }
                  }).toList()
                : <Recommendation>[];

            final quickInsights = analysis['quickInsights'] is QuickInsights
                ? analysis['quickInsights'] as QuickInsights
                : analysis['quickInsights'] is Map
                ? QuickInsights.fromJson(
                    analysis['quickInsights'] as Map<String, dynamic>,
                  )
                : QuickInsights(
                    healthScore: 'N/A',
                    summary: {'text': 'Dữ liệu tạm thời không khả dụng'},
                    alerts: 0,
                    topIssue: null,
                    strengths: [],
                    weaknesses: [],
                    opportunities: [],
                  );

            return Column(
              children: [
                // AI Analysis Header with Refresh Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phân tích AI - ${_getPeriodLabel(selectedPeriod)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.settingsItemTitleColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _clearAIAnalysisCache();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Làm mới phân tích',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Health Score Card
                      _buildHealthScoreCard(financialAnalysis),
                      const SizedBox(height: 16),

                      // Quick Insights
                      _buildQuickInsightsCardAI(quickInsights),
                      const SizedBox(height: 16),

                      // Strengths/Weaknesses
                      _buildStrengthsWeaknessesCard(financialAnalysis),
                      const SizedBox(height: 16),

                      // Recommendations
                      _buildRecommendationsCard(recommendations),
                      const SizedBox(height: 16),

                      // AI Forecast Chart
                      _buildAIForecastChart(forecast),
                      const SizedBox(height: 16),

                      // Anomalies Alert
                      if (anomalies.isNotEmpty) ...[
                        _buildAnomaliesCard(anomalies),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAIAnalysis() async {
    // Check premium status FIRST - prevent API calls for free users
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );
    if (!subscriptionService.isPremium) {
      debugPrint('❌ [AI Analysis] User is not premium, blocking API call');
      throw Exception('Premium subscription required for AI Analysis');
    }

    debugPrint('✅ [AI Analysis] User is premium, proceeding with analysis');

    // Check if we have valid cache for this period
    final now = DateTime.now();
    final cacheKey = selectedPeriod;

    // Check cache status - but allow fresh load for AI tab
    // Only use cache if it's very recent (less than 1 minute) to ensure fresh data
    final cacheValidityForAI = const Duration(minutes: 1);

    // Null safety check
    if (aiAnalysisCache.isNotEmpty &&
        aiAnalysisCache.containsKey(cacheKey) &&
        cacheTimestamps.isNotEmpty &&
        cacheTimestamps.containsKey(cacheKey) &&
        cacheTimestamps[cacheKey] != null &&
        now.difference(cacheTimestamps[cacheKey]!) < cacheValidityForAI) {
      return aiAnalysisCache[cacheKey]!;
    }

    // Initialize progress tracking after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProgressTracking(cacheKey);
    });

    // Rate limit protection - prevent too frequent API calls
    if (_isApiCallInProgress) {
      _updateProgress(cacheKey, 0.1, 'Đang chờ API call khác hoàn thành...');
      // Wait for current call to complete
      await Future.delayed(const Duration(seconds: 2));
      if (aiAnalysisCache.containsKey(cacheKey)) {
        return aiAnalysisCache[cacheKey]!;
      }
    }

    if (_lastApiCallTime != null &&
        now.difference(_lastApiCallTime!) < _minApiCallInterval) {
      _updateProgress(cacheKey, 0.2, 'Đang chờ rate limit...');
      // Return cached data if available, even if expired
      if (aiAnalysisCache.containsKey(cacheKey)) {
        return aiAnalysisCache[cacheKey]!;
      }
      // If no cache, wait a bit and try again instead of throwing error
      await Future.delayed(const Duration(seconds: 2));
      // Continue with API call after waiting
    }

    _isApiCallInProgress = true;
    _lastApiCallTime = now;

    try {
      final aiService = AiAnalysisService();

      // Simulate progress steps
      await _simulateProgressSteps(cacheKey);

      final result = await aiService.getComprehensiveAnalysis(
        period: selectedPeriod,
      );

      // Cache the result with timestamp for this specific period
      aiAnalysisCache[cacheKey] = result;
      cacheTimestamps[cacheKey] = now;

      return result;
    } catch (e) {
      // Return fallback data instead of throwing error
      final fallbackData = _createFallbackAnalysis();
      aiAnalysisCache[cacheKey] = fallbackData;
      cacheTimestamps[cacheKey] = now;
      return fallbackData;
    } finally {
      _isApiCallInProgress = false;
    }
  }

  void _clearAIAnalysisCache() {
    if (aiAnalysisCache.isNotEmpty) aiAnalysisCache.clear();
    if (cacheTimestamps.isNotEmpty) cacheTimestamps.clear();
    if (_analysisProgress.isNotEmpty) _analysisProgress.clear();
    if (_analysisStatus.isNotEmpty) _analysisStatus.clear();
    if (_analysisSteps.isNotEmpty) _analysisSteps.clear();
  }

  // Initialize progress tracking for a period
  void _initializeProgressTracking(String period) {
    // Ensure maps are initialized
    if (_analysisProgress.isEmpty) _analysisProgress = <String, double>{};
    if (_analysisStatus.isEmpty) _analysisStatus = <String, String>{};
    if (_analysisSteps.isEmpty) _analysisSteps = <String, List<String>>{};

    _analysisProgress[period] = 0.0;
    _analysisStatus[period] = 'Đang chuẩn bị phân tích...';
    _analysisSteps[period] = [];

    // Create animation controller for this period if not exists
    if (!_progressControllers.containsKey(period)) {
      _progressControllers[period] = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );
      _progressAnimations[period] = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _progressControllers[period]!,
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // Reset existing animation
      _progressControllers[period]!.reset();
    }

    // Don't call setState here - it's called during build phase
  }

  // Update progress for a period
  void _updateProgress(
    String period,
    double progress,
    String status, {
    String? step,
  }) {
    // Ensure maps are initialized
    if (_analysisProgress.isEmpty) _analysisProgress = <String, double>{};
    if (_analysisStatus.isEmpty) _analysisStatus = <String, String>{};
    if (_analysisSteps.isEmpty) _analysisSteps = <String, List<String>>{};

    _analysisProgress[period] = progress;
    _analysisStatus[period] = status;
    if (step != null) {
      _analysisSteps[period] = [...(_analysisSteps[period] ?? []), step];
    }

    // Update progress animation for this period
    if (_progressControllers.containsKey(period)) {
      _progressControllers[period]!.animateTo(progress);
    }

    // Don't call setState here - it's called during build phase
  }

  // Simulate progress steps for better UX
  Future<void> _simulateProgressSteps(String period) async {
    final steps = [
      {
        'progress': 0.1,
        'status': 'Đang tải dữ liệu tài chính...',
        'step': 'Thu thập dữ liệu giao dịch',
      },
      {
        'progress': 0.2,
        'status': 'Phân tích thu nhập và chi tiêu...',
        'step': 'Phân tích thu nhập',
      },
      {
        'progress': 0.3,
        'status': 'Tính toán ngân sách...',
        'step': 'Phân tích chi tiêu',
      },
      {
        'progress': 0.4,
        'status': 'Phát hiện bất thường...',
        'step': 'Tính toán ngân sách',
      },
      {
        'progress': 0.5,
        'status': 'Tạo dự báo tài chính...',
        'step': 'Phát hiện bất thường',
      },
      {
        'progress': 0.6,
        'status': 'Phân tích mẫu chi tiêu...',
        'step': 'Tạo dự báo',
      },
      {
        'progress': 0.7,
        'status': 'Tạo khuyến nghị thông minh...',
        'step': 'Phân tích mẫu',
      },
      {
        'progress': 0.8,
        'status': 'Tổng hợp kết quả...',
        'step': 'Tạo khuyến nghị',
      },
      {
        'progress': 0.9,
        'status': 'Hoàn thiện phân tích...',
        'step': 'Tổng hợp kết quả',
      },
      {'progress': 1.0, 'status': 'Hoàn thành!', 'step': 'Phân tích hoàn tất'},
    ];

    for (final step in steps) {
      _updateProgress(
        period,
        step['progress'] as double,
        step['status'] as String,
        step: step['step'] as String,
      );
      // Vary delay for more realistic progress
      final delay = step['progress'] as double < 0.5
          ? const Duration(milliseconds: 600) // Faster at start
          : const Duration(milliseconds: 1000); // Slower at end
      await Future.delayed(delay);
    }
  }

  // Preload cache for other periods in background
  Future<void> _preloadOtherPeriods() async {
    final periods = ['week', 'month', 'year'];
    final currentPeriod = selectedPeriod;

    for (final period in periods) {
      if (period != currentPeriod && !aiAnalysisCache.containsKey(period)) {
        // Preload in background without blocking UI
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            final aiService = AiAnalysisService();
            final result = await aiService.getComprehensiveAnalysis(
              period: period,
            );

            // Cache the result
            aiAnalysisCache[period] = result;
            cacheTimestamps[period] = DateTime.now();
            print('✅ Preloaded cache for $period');
          } catch (e) {
            print('⚠️ Failed to preload cache for $period: $e');
          }
        });
      }
    }
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'week':
        return 'Tuần';
      case 'year':
        return 'Năm';
      case 'month':
      default:
        return 'Tháng';
    }
  }

  // Check if tab data is cached
  bool _isTabDataCached(String tabName, String period) {
    final cacheKey = '${tabName}_$period';
    final now = DateTime.now();

    if (!_tabCacheTimestamps.containsKey(cacheKey)) return false;

    final timestamp = _tabCacheTimestamps[cacheKey]!;
    return now.difference(timestamp) < _cacheValidityDuration;
  }

  // Cache tab data
  void _cacheTabData(String tabName, String period, DateTime timestamp) {
    final cacheKey = '${tabName}_$period';
    _tabCacheTimestamps[cacheKey] = timestamp;
    print('💾 Cached $tabName data for $period');
  }

  // Load overview data
  Future<void> _loadOverviewData(ReportService reportService) async {
    await reportService.getTrendReport(period: selectedPeriod);
    await reportService.getComparisonReport(period: selectedPeriod);
  }

  // Load categories data
  Future<void> _loadCategoriesData(ReportService reportService) async {
    await reportService.getCategoryReport(period: selectedPeriod);
  }

  // Load trends data
  Future<void> _loadTrendsData(ReportService reportService) async {
    await reportService.getTrendReport(period: selectedPeriod);
    await reportService.getSpendingPatterns(period: selectedPeriod);
    await reportService.getForecastReport();
  }

  // Create fallback data when API fails
  Map<String, dynamic> _createFallbackAnalysis() {
    return {
      'financialAnalysis': {
        'healthScore': 'Trung bình',
        'strengths': ['Dữ liệu đang được cập nhật'],
        'weaknesses': ['Không thể phân tích do lỗi API'],
        'risks': ['API tạm thời không khả dụng'],
        'opportunities': ['Thử lại sau ít phút'],
        'recommendations': [
          {
            'title': 'Thử lại sau',
            'description': 'API đang gặp sự cố, vui lòng thử lại sau',
            'priority': 'low',
            'estimatedSavings': 0,
          },
        ],
        'summary': 'Phân tích tạm thời không khả dụng do lỗi API',
      },
      'forecast': {
        'method': 'fallback',
        'forecast': [],
        'historicalData': [],
        'message': 'Dự báo tạm thời không khả dụng',
      },
      'anomalies': [],
      'recommendations': [
        {
          'title': 'Thử lại sau',
          'description': 'API đang gặp sự cố, vui lòng thử lại sau',
          'priority': 'low',
          'estimatedSavings': 0,
        },
      ],
      'quickInsights': {
        'healthScore': 'Trung bình',
        'summary': {'text': 'Phân tích tạm thời không khả dụng'},
        'alerts': 0,
        'topIssue': 'API tạm thời không khả dụng',
        'strengths': ['Dữ liệu đang được cập nhật'],
        'weaknesses': ['Không thể phân tích do lỗi API'],
        'opportunities': ['Thử lại sau ít phút'],
      },
      'spendingPatterns': {
        'weeklyPattern': {
          'highestSpendingDay': 'Chủ nhật',
          'distribution': [0, 0, 0, 0, 0, 0, 0],
        },
        'categoryPattern': {'topCategories': [], 'totalCategories': 0},
        'amountPattern': {
          'average': 0,
          'median': 0,
          'min': 0,
          'max': 0,
          'range': '0 - 0',
        },
      },
      'generatedAt': DateTime.now(),
    };
  }

  // Build progress bar for AI analysis
  Widget _buildAnalysisProgressBar(String period) {
    final progress = _analysisProgress[period] ?? 0.0;
    final status = _analysisStatus[period] ?? 'Đang chuẩn bị...';
    final steps = _analysisSteps[period] ?? [];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
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
              // Animated AI icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Icon(
                      Icons.analytics,
                      color: context.colorScheme.primary,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Phân tích ${_getPeriodLabel(period)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.settingsItemTitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Animated status text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        status,
                        key: ValueKey(status),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.settingsItemSubtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Animated percentage
              _progressAnimations.containsKey(period)
                  ? AnimatedBuilder(
                      animation: _progressAnimations[period]!,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimations[period]!.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated progress bar with smooth animation
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _progressAnimations.containsKey(period)
                ? AnimatedBuilder(
                    animation: _progressAnimations[period]!,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimations[period]!.value,
                        backgroundColor: context.settingsItemSubtitleColor
                            .withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colorScheme.primary,
                        ),
                        minHeight: 8,
                      );
                    },
                  )
                : LinearProgressIndicator(
                    value: progress,
                    backgroundColor: context.settingsItemSubtitleColor
                        .withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                    minHeight: 8,
                  ),
          ),

          if (steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Animated steps list
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: context.colorScheme.primary.withOpacity(
                                0.7,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.settingsItemSubtitleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  // Build loading shimmer effect
  Widget _buildLoadingShimmer() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Health Score Card Shimmer
          _buildShimmerCard(
            child: Column(
              children: [
                _buildShimmerLine(width: 0.6),
                const SizedBox(height: 8),
                _buildShimmerLine(width: 0.8),
                const SizedBox(height: 6),
                _buildShimmerLine(width: 0.4),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Insights Card Shimmer
          _buildShimmerCard(
            child: Column(
              children: [
                _buildShimmerLine(width: 0.7),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildShimmerCircle(),
                    const SizedBox(width: 8),
                    Expanded(child: _buildShimmerLine(width: 0.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildShimmerCircle(),
                    const SizedBox(width: 8),
                    Expanded(child: _buildShimmerLine(width: 0.6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Forecast Chart Shimmer (smaller)
          _buildShimmerCard(
            child: Column(
              children: [
                _buildShimmerLine(width: 0.5),
                const SizedBox(height: 12),
                _buildShimmerBar(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildShimmerLine({required double width}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          height: 12,
          width: MediaQuery.of(context).size.width * width,
          decoration: BoxDecoration(
            color: context.settingsItemSubtitleColor.withOpacity(
              0.1 + (value * 0.2),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: context.settingsItemSubtitleColor.withOpacity(
              0.1 + (value * 0.2),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildShimmerBar({required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: context.settingsItemSubtitleColor.withOpacity(
              0.1 + (value * 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _buildHealthScoreCard(FinancialAnalysis analysis) {
    Color healthColor;
    IconData healthIcon;

    switch (analysis.healthScore.toLowerCase()) {
      case 'tốt':
        healthColor = Colors.green;
        healthIcon = Icons.trending_up;
        break;
      case 'khá':
        healthColor = Colors.blue;
        healthIcon = Icons.trending_flat;
        break;
      case 'trung bình':
        healthColor = Colors.orange;
        healthIcon = Icons.trending_down;
        break;
      default:
        healthColor = Colors.red;
        healthIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(healthIcon, color: healthColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Sức khỏe tài chính',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.settingsItemTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.healthScore,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: healthColor,
            ),
          ),
          if (analysis.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              analysis.summary,
              style: TextStyle(
                fontSize: 14,
                color: context.settingsItemSubtitleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInsightsCardAI(QuickInsights insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: context.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.settingsItemTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Cảnh báo',
                  '${insights.alerts}',
                  insights.alerts > 0 ? Colors.red : Colors.green,
                  Icons.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightItem(
                  'Điểm mạnh',
                  '${insights.strengths.length}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.settingsItemSubtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthsWeaknessesCard(FinancialAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điểm mạnh & Điểm yếu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.settingsItemTitleColor,
            ),
          ),
          const SizedBox(height: 12),
          if (analysis.strengths.isNotEmpty) ...[
            _buildStrengthsSection(analysis.strengths),
            const SizedBox(height: 12),
          ],
          if (analysis.weaknesses.isNotEmpty) ...[
            _buildWeaknessesSection(analysis.weaknesses),
          ],
        ],
      ),
    );
  }

  Widget _buildStrengthsSection(List<String> strengths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              'Điểm mạnh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...strengths
            .take(3)
            .map(
              (strength) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text(
                  '• $strength',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildWeaknessesSection(List<String> weaknesses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Text(
              'Cần cải thiện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...weaknesses
            .take(3)
            .map(
              (weakness) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text(
                  '• $weakness',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildRecommendationsCard(List<Recommendation> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: context.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Khuyến nghị AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.settingsItemTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations
              .take(3)
              .map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Recommendation rec) {
    Color priorityColor;
    switch (rec.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.screenBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.settingsItemTitleColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rec.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rec.description,
            style: TextStyle(
              fontSize: 12,
              color: context.settingsItemSubtitleColor,
            ),
          ),
          if (rec.estimatedSavings > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Tiết kiệm ước tính: ${CurrencyFormatter.format(rec.estimatedSavings)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIForecastChart(AIForecast forecast) {
    // Debug logging for forecast data
    print('🔍 Forecast Debug:');
    print('Method: ${forecast.method}');
    print('Forecast length: ${forecast.forecast.length}');
    print(
      'Forecast data: ${forecast.forecast.map((f) => '${f.month}: ${f.predictedExpense}').join(', ')}',
    );

    if (forecast.forecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'Không có dữ liệu dự báo',
                style: TextStyle(color: context.settingsItemSubtitleColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Method: ${forecast.method}',
                style: TextStyle(
                  color: context.settingsItemSubtitleColor,
                  fontSize: 12,
                ),
              ),
              if (forecast.message != null)
                Text(
                  'Message: ${forecast.message}',
                  style: TextStyle(
                    color: context.settingsItemSubtitleColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Check if all values are the same (flat line issue)
    final values = forecast.forecast.map((f) => f.predictedExpense).toList();
    final isFlatLine =
        values.isNotEmpty && values.every((v) => v == values.first);

    if (isFlatLine) {
      print('⚠️ Warning: All forecast values are the same: ${values.first}');
    }

    // Calculate chart bounds including confidence intervals
    final allValues = <double>[];

    // Add main forecast values
    allValues.addAll(values);

    // Add confidence interval bounds
    for (final forecast in forecast.forecast) {
      allValues.add(forecast.lower80);
      allValues.add(forecast.upper80);
    }

    final maxValue = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a > b ? a : b)
        : 0;
    final minValue = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a < b ? a : b)
        : 0;
    final range = maxValue - minValue;

    // Calculate Y-axis bounds with proper padding for confidence intervals
    double yPadding;
    double chartMinY;
    double chartMaxY;

    if (isFlatLine && maxValue > 0) {
      // For flat lines, create a small range around the value
      yPadding = maxValue * 0.1;
      chartMinY = (maxValue - yPadding).clamp(0, double.infinity);
      chartMaxY = maxValue + yPadding;
    } else if (range > 0) {
      yPadding = range * 0.15; // 15% padding
      chartMinY = (minValue - yPadding).clamp(0, double.infinity);
      chartMaxY = maxValue + yPadding;
    } else {
      // Fallback for edge cases
      yPadding = maxValue * 0.1;
      chartMinY = 0;
      chartMaxY = maxValue + yPadding;
    }

    // Calculate interval for Y-axis labels
    final yInterval = range > 0 ? range / 4 : (chartMaxY - chartMinY) / 4;

    print(
      '📊 Chart Debug - Min: ${minValue.toInt()}, Max: ${maxValue.toInt()}, Range: ${range.toInt()}, ChartMinY: ${chartMinY.toInt()}, ChartMaxY: ${chartMaxY.toInt()}, Y-Interval: ${yInterval.toInt()}',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: context.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Dự báo AI (${forecast.method})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.settingsItemTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add warning for flat line
          if (isFlatLine)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dữ liệu dự báo có thể chưa chính xác (tất cả giá trị bằng nhau). Hãy thêm dữ liệu lịch sử để có dự báo tốt hơn.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 250, // Tăng height để có thêm không gian
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 8,
            ), // Thêm padding cho chart
            decoration: BoxDecoration(
              color: context.cardBackground.withOpacity(
                0.3,
              ), // Background nhẹ cho chart area
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.settingsItemSubtitleColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: LineChart(
              LineChartData(
                minY: chartMinY.toDouble(),
                maxY: chartMaxY.toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.settingsItemSubtitleColor.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 120, // Tăng thêm để có đủ không gian
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return Container(
                          width: 100, // Tăng width để tránh cắt
                          padding: const EdgeInsets.only(
                            right: 12,
                            left: 8,
                          ), // Thêm padding trái
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyFormatter.formatCompact(value),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.settingsItemSubtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50, // Tăng reserved size
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < forecast.forecast.length) {
                          final monthData = forecast.forecast[value.toInt()];
                          final monthStr = monthData.month;
                          // Extract month number and format properly
                          final monthNum = monthStr.split('-')[1];
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 12.0,
                              left: 4,
                              right: 4,
                            ), // Thêm padding
                            child: Text(
                              monthNum,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.settingsItemSubtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: context.settingsItemSubtitleColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  // Confidence interval area (shaded) - only show if we have valid bounds
                  if (range > 0)
                    LineChartBarData(
                      spots: [
                        // Start with lower bound
                        ...forecast.forecast.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.lower80);
                        }).toList(),
                        // Then upper bound in reverse
                        ...forecast.forecast
                            .asMap()
                            .entries
                            .toList()
                            .reversed
                            .map((e) {
                              return FlSpot(e.key.toDouble(), e.value.upper80);
                            })
                            .toList(),
                      ],
                      isCurved: false,
                      color: context.colorScheme.primary.withOpacity(0.1),
                      barWidth: 0,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  // Main forecast line
                  LineChartBarData(
                    spots: forecast.forecast.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.predictedExpense);
                    }).toList(),
                    isCurved: true,
                    color: context.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: context.colorScheme.primary,
                          strokeWidth: 3,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),

          // Add legend
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.settingsItemSubtitleColor.withOpacity(0.1),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildLegendItem(
                  'Dự báo chính',
                  context.colorScheme.primary,
                  Icons.trending_up,
                ),
                _buildLegendItem(
                  'Khoảng tin cậy',
                  context.colorScheme.primary.withOpacity(0.3),
                  Icons.area_chart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.settingsItemSubtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnomaliesCard(List<Anomaly> anomalies) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Cảnh báo bất thường',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...anomalies.take(3).map((anomaly) => _buildAnomalyItem(anomaly)),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(Anomaly anomaly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.screenBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: anomaly.severity == 'high' ? Colors.red : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  anomaly.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.settingsItemTitleColor,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(anomaly.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            anomaly.description,
            style: TextStyle(
              fontSize: 12,
              color: context.settingsItemSubtitleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Khoảng dự kiến: ${anomaly.expectedRange}',
            style: TextStyle(
              fontSize: 10,
              color: context.settingsItemSubtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for premium feature items
  Widget _buildPremiumFeatureItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFFA500), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
