import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
  StatusBar,
  Animated,
} from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, {
  Circle,
  Path,
  Text as SvgText,
  Defs,
  LinearGradient as SvgLinearGradient,
  Stop,
  G,
} from 'react-native-svg';
import { PieChart } from '../components';

import { Colors } from '../constants/colors';
import { BackButton } from '../components';

const { width: screenWidth } = Dimensions.get('window');

interface MonthlyData {
  month: string;
  income: number;
  expenses: number;
}

interface CategoryData {
  category: string;
  amount: number;
  percentage: number;
  color: string;
  icon: string;
}

interface IncomeData {
  category: string;
  amount: number;
  percentage: number;
  color: string;
  icon: string;
}

interface PeriodData {
  period: string;
  income: number;
  expenses: number;
  savings: number;
  isActive: boolean;
}

const ReportsScreen: React.FC = () => {
  const navigation = useNavigation();
  const [monthlyData, setMonthlyData] = useState<MonthlyData[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryData[]>([]);
  const [incomeData, setIncomeData] = useState<IncomeData[]>([]);
  const [periodData, setPeriodData] = useState<PeriodData[]>([]);
  const [currentBalance, setCurrentBalance] = useState(2450000);
  const [debt, setDebt] = useState(850000);
  const [selectedPeriod, setSelectedPeriod] = useState<'T5/2025' | 'T6/2025' | 'T7/2025'>(
    'T6/2025'
  );
  const [chartAnimation] = useState(new Animated.Value(0));
  const [currentSeason] = useState('mùa mưa'); // Vietnamese season context
  const [selectedTab, setSelectedTab] = useState<'overview' | 'categories' | 'trends'>('overview');

  useEffect(() => {
    loadReportsData();
    // Animate chart on load
    Animated.timing(chartAnimation, {
      toValue: 1,
      duration: 1500,
      useNativeDriver: false,
    }).start();
  }, []);

  const loadReportsData = async () => {
    // Enhanced Vietnamese monthly data with cultural context
    const mockMonthlyData: MonthlyData[] = [
      { month: 'T2', income: 2800000, expenses: 1200000 },
      { month: 'T3', income: 3200000, expenses: 1800000 },
      { month: 'T4', income: 2600000, expenses: 1400000 },
      { month: 'T5', income: 3800000, expenses: 2200000 },
      { month: 'T6', income: 3200000, expenses: 1600000 },
      { month: 'T7', income: 4200000, expenses: 2800000 },
    ];

    // Vietnamese category spending data
    const mockCategoryData: CategoryData[] = [
      { category: 'Ăn uống', amount: 1200000, percentage: 35, color: '#FF6B6B', icon: '🍜' },
      { category: 'Di chuyển', amount: 800000, percentage: 23, color: '#4ECDC4', icon: '🚗' },
      { category: 'Mua sắm', amount: 600000, percentage: 18, color: '#45B7D1', icon: '🛍️' },
      { category: 'Giải trí', amount: 400000, percentage: 12, color: '#96CEB4', icon: '🎮' },
      { category: 'Khác', amount: 400000, percentage: 12, color: '#FFEAA7', icon: '📝' },
    ];

    // Vietnamese income category data
    const mockIncomeData: IncomeData[] = [
      { category: 'Lương chính', amount: 2500000, percentage: 60, color: '#4ECDC4', icon: '💼' },
      { category: 'Freelance', amount: 800000, percentage: 19, color: '#45B7D1', icon: '💻' },
      { category: 'Đầu tư', amount: 500000, percentage: 12, color: '#96CEB4', icon: '📈' },
      { category: 'Thưởng', amount: 300000, percentage: 7, color: '#FFEAA7', icon: '🎁' },
      { category: 'Khác', amount: 100000, percentage: 2, color: '#DDA0DD', icon: '💰' },
    ];

    // Period comparison data
    const mockPeriodData: PeriodData[] = [
      { period: 'T5/2025', income: 3800000, expenses: 2200000, savings: 1600000, isActive: false },
      { period: 'T6/2025', income: 3200000, expenses: 1600000, savings: 1600000, isActive: true },
      { period: 'T7/2025', income: 4200000, expenses: 2800000, savings: 1400000, isActive: false },
    ];

    setMonthlyData(mockMonthlyData);
    setCategoryData(mockCategoryData);
    setIncomeData(mockIncomeData);
    setPeriodData(mockPeriodData);
  };

  // Vietnamese cultural insights based on spending patterns
  const getVietnameseCulturalInsights = () => {
    const totalExpenses = monthlyData.reduce((sum, month) => sum + month.expenses, 0);
    const avgMonthlyExpense = totalExpenses / monthlyData.length;

    if (currentSeason === 'mùa mưa' && avgMonthlyExpense > 2000000) {
      return {
        title: 'Phân tích mùa mưa',
        insight:
          'Chi tiêu đi lại tăng 25% vào mùa mưa. Nên dùng Grab/xe ôm công nghệ thay vì xe cá nhân.',
        icon: '☔',
        color: '#4ECDC4',
      };
    } else if (monthlyData[monthlyData.length - 1]?.month === 'T12') {
      return {
        title: 'Chuẩn bị Tết Nguyên Đán',
        insight:
          'Tháng 12 chi tiêu tăng 40% để chuẩn bị Tết. Nên lập kế hoạch chi tiêu từ tháng 10.',
        icon: '🧧',
        color: '#FF6B6B',
      };
    } else {
      return {
        title: 'Xu hướng chi tiêu Việt Nam',
        insight: 'Cà phê chiếm 15% chi tiêu hàng ngày. Thử pha cà phê tại nhà để tiết kiệm!',
        icon: '☕',
        color: '#8B4513',
      };
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const renderBarChart = () => {
    const maxValue = Math.max(...monthlyData.map(item => Math.max(item.income, item.expenses)));

    return (
      <View style={styles.barChart}>
        {monthlyData.map((item, index) => {
          const incomeHeight = (item.income / maxValue) * 80;
          const expenseHeight = (item.expenses / maxValue) * 80;

          return (
            <View key={index} style={styles.barGroup}>
              <View style={styles.bars}>
                <Animated.View
                  style={[
                    styles.bar,
                    styles.incomeBar,
                    {
                      height: chartAnimation.interpolate({
                        inputRange: [0, 1],
                        outputRange: [0, incomeHeight],
                      }),
                    },
                  ]}
                />
                <Animated.View
                  style={[
                    styles.bar,
                    styles.expenseBar,
                    {
                      height: chartAnimation.interpolate({
                        inputRange: [0, 1],
                        outputRange: [0, expenseHeight],
                      }),
                    },
                  ]}
                />
              </View>
              <Text style={styles.barLabel}>{item.month}</Text>
            </View>
          );
        })}
      </View>
    );
  };

  const renderPeriodSelector = () => (
    <View style={styles.periodSelector}>
      {periodData.map(period => (
        <TouchableOpacity
          key={period.period}
          style={[styles.periodTab, selectedPeriod === period.period && styles.activePeriodTab]}
          onPress={() => setSelectedPeriod(period.period as 'T5/2025' | 'T6/2025' | 'T7/2025')}
        >
          <Text
            style={[styles.periodText, selectedPeriod === period.period && styles.activePeriodText]}
          >
            {period.period}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );

  const renderPieChart = () => {
    const radius = 60;
    const centerX = 80;
    const centerY = 80;
    let cumulativePercentage = 0;

    return (
      <View style={styles.pieChartContainer}>
        <Svg height="160" width="160">
          {categoryData.map((item, index) => {
            const startAngle = (cumulativePercentage / 100) * 360;
            const endAngle = ((cumulativePercentage + item.percentage) / 100) * 360;
            const largeArcFlag = item.percentage > 50 ? 1 : 0;

            const x1 = centerX + radius * Math.cos((startAngle * Math.PI) / 180);
            const y1 = centerY + radius * Math.sin((startAngle * Math.PI) / 180);
            const x2 = centerX + radius * Math.cos((endAngle * Math.PI) / 180);
            const y2 = centerY + radius * Math.sin((endAngle * Math.PI) / 180);

            const pathData = [
              `M ${centerX} ${centerY}`,
              `L ${x1} ${y1}`,
              `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2}`,
              'Z',
            ].join(' ');

            cumulativePercentage += item.percentage;

            return (
              <Path key={index} d={pathData} fill={item.color} stroke="#1A2E3A" strokeWidth="2" />
            );
          })}
          <Circle cx={centerX} cy={centerY} r="25" fill="#1A2E3A" />
          <SvgText x={centerX} y={centerY - 5} fontSize="12" fill="#FFFFFF" textAnchor="middle">
            Tổng
          </SvgText>
          <SvgText x={centerX} y={centerY + 8} fontSize="10" fill="#FFFFFF" textAnchor="middle">
            {formatCurrency(categoryData.reduce((sum, item) => sum + item.amount, 0))}
          </SvgText>
        </Svg>
      </View>
    );
  };

  const renderCategoryBreakdown = () => (
    <View style={styles.categoryBreakdown}>
      {categoryData.map((item, index) => (
        <TouchableOpacity
          key={index}
          style={[styles.categoryItem, styles.enhancedCategoryItem]}
          onPress={() =>
            (navigation as any).navigate('TransactionHistory', {
              category: item.category,
              type: 'expense',
            })
          }
        >
          <View style={styles.categoryMainInfo}>
            <View style={[styles.categoryIconContainer, { backgroundColor: item.color + '20' }]}>
              <Text style={styles.categoryIcon}>{item.icon}</Text>
              <View style={[styles.categoryGlow, { backgroundColor: item.color }]} />
            </View>
            <View style={styles.categoryDetails}>
              <View style={styles.categoryHeader}>
                <Text style={styles.categoryName}>{item.category}</Text>
                <View style={[styles.categoryBadge, { backgroundColor: item.color }]}>
                  <Text style={styles.categoryBadgeText}>{item.percentage}%</Text>
                </View>
              </View>
              <Text style={styles.categoryAmount}>{formatCurrency(item.amount)}</Text>
              <View style={styles.categoryInsights}>
                <Text style={styles.categoryTrend}>
                  {index % 2 === 0 ? '📈 +12% so với tháng trước' : '📉 -5% so với tháng trước'}
                </Text>
              </View>
            </View>
          </View>

          <View style={styles.categoryMetrics}>
            <View style={styles.categoryProgressWrapper}>
              <View style={[styles.categoryProgressBar, { backgroundColor: item.color + '20' }]}>
                <Animated.View
                  style={[
                    styles.progressFill,
                    {
                      width: `${item.percentage}%`,
                      backgroundColor: item.color,
                    },
                  ]}
                />
              </View>
              <View style={styles.categoryStats}>
                <Text style={styles.avgSpend}>TB: {formatCurrency(item.amount / 30)}/ngày</Text>
                <View style={styles.categoryRanking}>
                  <Text style={styles.rankingText}>#{index + 1}</Text>
                </View>
              </View>
            </View>
          </View>

          <View style={styles.categoryActions}>
            <TouchableOpacity style={styles.detailButton}>
              <Ionicons name="analytics-outline" size={14} color={item.color} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.optimizeButton}>
              <Ionicons name="bulb-outline" size={14} color="#FFEAA7" />
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );

  const renderIncomeExpenseChart = () => {
    const currentPeriod = periodData.find(p => p.period === selectedPeriod);
    if (!currentPeriod) return null;

    const maxValue = Math.max(currentPeriod.income, currentPeriod.expenses);
    const incomeHeight = (currentPeriod.income / maxValue) * 100;
    const expenseHeight = (currentPeriod.expenses / maxValue) * 100;

    return (
      <View style={styles.incomeExpenseChart}>
        <View style={styles.chartBars}>
          <View style={styles.barColumn}>
            <Animated.View
              style={[
                styles.chartBar,
                {
                  height: chartAnimation.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, incomeHeight],
                  }),
                  backgroundColor: '#4ECDC4',
                },
              ]}
            />
            <Text style={styles.chartBarLabel}>Thu nhập</Text>
            <Text style={styles.barAmount}>{formatCurrency(currentPeriod.income)}</Text>
          </View>
          <View style={styles.barColumn}>
            <Animated.View
              style={[
                styles.chartBar,
                {
                  height: chartAnimation.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, expenseHeight],
                  }),
                  backgroundColor: '#FF6B6B',
                },
              ]}
            />
            <Text style={styles.chartBarLabel}>Chi tiêu</Text>
            <Text style={styles.barAmount}>{formatCurrency(currentPeriod.expenses)}</Text>
          </View>
        </View>
        <View style={styles.savingsDisplay}>
          <Text style={styles.savingsLabel}>Tiết kiệm</Text>
          <Text
            style={[
              styles.savingsAmount,
              { color: currentPeriod.savings > 0 ? '#4ECDC4' : '#FF6B6B' },
            ]}
          >
            {formatCurrency(currentPeriod.savings)}
          </Text>
        </View>
      </View>
    );
  };

  const renderModernPieChart = (data: CategoryData[] | IncomeData[], title: string) => {
    // Transform data for custom PieChart component
    const chartData = data.map((item, index) => ({
      value: item.amount,
      color: item.color,
      label: item.category,
      percentage: item.percentage,
    }));

    const centerText = {
      title: title,
      value: formatCurrency(data.reduce((sum, item) => sum + item.amount, 0)),
    };

    return (
      <View style={styles.modernPieChartContainer}>
        <View style={styles.chartWrapper}>
          <PieChart
            data={chartData}
            size={200}
            strokeWidth={30}
            showLabels={false}
            centerText={centerText}
          />
        </View>
      </View>
    );
  };

  const renderIncomeBreakdown = () => (
    <View style={styles.categoryBreakdown}>
      {incomeData.map((item, index) => (
        <TouchableOpacity
          key={index}
          style={[styles.categoryItem, styles.enhancedCategoryItem]}
          onPress={() =>
            (navigation as any).navigate('TransactionHistory', {
              category: item.category,
              type: 'income',
            })
          }
        >
          <View style={styles.categoryMainInfo}>
            <View style={[styles.categoryIconContainer, { backgroundColor: item.color + '20' }]}>
              <Text style={styles.categoryIcon}>{item.icon}</Text>
              <View style={[styles.categoryGlow, { backgroundColor: item.color }]} />
            </View>
            <View style={styles.categoryDetails}>
              <View style={styles.categoryHeader}>
                <Text style={styles.categoryName}>{item.category}</Text>
                <View style={[styles.categoryBadge, { backgroundColor: item.color }]}>
                  <Text style={styles.categoryBadgeText}>{item.percentage}%</Text>
                </View>
              </View>
              <Text style={styles.categoryAmount}>{formatCurrency(item.amount)}</Text>
              <View style={styles.categoryInsights}>
                <Text style={[styles.categoryTrend, { color: '#4ECDC4' }]}>
                  {index === 0
                    ? '🎯 Thu nhập chính'
                    : index === 1
                      ? '💼 Thu nhập phụ'
                      : '📈 Tăng trưởng tốt'}
                </Text>
              </View>
            </View>
          </View>

          <View style={styles.categoryMetrics}>
            <View style={styles.categoryProgressWrapper}>
              <View style={[styles.categoryProgressBar, { backgroundColor: item.color + '20' }]}>
                <Animated.View
                  style={[
                    styles.progressFill,
                    {
                      width: `${item.percentage}%`,
                      backgroundColor: item.color,
                    },
                  ]}
                />
              </View>
              <View style={styles.categoryStats}>
                <Text style={styles.avgSpend}>TB: {formatCurrency(item.amount / 30)}/ngày</Text>
                <View style={[styles.categoryRanking, { backgroundColor: '#4ECDC4' + '20' }]}>
                  <Text style={[styles.rankingText, { color: '#4ECDC4' }]}>#{index + 1}</Text>
                </View>
              </View>
            </View>
          </View>

          <View style={styles.categoryActions}>
            <TouchableOpacity style={styles.detailButton}>
              <Ionicons name="trending-up-outline" size={14} color={item.color} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.optimizeButton}>
              <Ionicons name="add-circle-outline" size={14} color="#4ECDC4" />
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );

  const renderMonthlyBreakdown = () => {
    // Detailed monthly data for trends
    const detailedMonthlyData = [
      {
        month: 'Tháng 07/2025',
        netSavings: 3918024,
        income: 29496627,
        expenses: 25578603,
      },
      {
        month: 'Tháng 06/2025',
        netSavings: 2903269,
        income: 507791152,
        expenses: 504887883,
      },
      {
        month: 'Tháng 05/2025',
        netSavings: 3819294,
        income: 1066668349,
        expenses: 1062849055,
      },
      {
        month: 'Tháng 04/2025',
        netSavings: 2600000,
        income: 2800000,
        expenses: 200000,
      },
      {
        month: 'Tháng 03/2025',
        netSavings: 1400000,
        income: 3200000,
        expenses: 1800000,
      },
      {
        month: 'Tháng 02/2025',
        netSavings: 1600000,
        income: 2800000,
        expenses: 1200000,
      },
    ];

    return (
      <View style={styles.monthlyBreakdown}>
        <Text style={styles.breakdownTitle}>Chi tiết theo tháng</Text>
        {detailedMonthlyData.map((monthData, index) => (
          <View key={index} style={styles.monthlyItem}>
            <View style={styles.monthHeader}>
              <Text style={styles.monthTitle}>{monthData.month}</Text>
              <Text
                style={[
                  styles.netAmount,
                  { color: monthData.netSavings > 0 ? '#4ECDC4' : '#FF6B6B' },
                ]}
              >
                {formatCurrency(monthData.netSavings)} VND
              </Text>
            </View>

            <View style={styles.monthDetails}>
              <View style={styles.monthRow}>
                <Text style={styles.monthLabel}>Thu</Text>
                <Text style={[styles.monthValue, { color: '#4ECDC4' }]}>
                  {formatCurrency(monthData.income)} VND
                </Text>
              </View>
              <View style={styles.monthRow}>
                <Text style={styles.monthLabel}>Chi</Text>
                <Text style={[styles.monthValue, { color: '#FF6B6B' }]}>
                  {formatCurrency(monthData.expenses)} VND
                </Text>
              </View>
            </View>
          </View>
        ))}
      </View>
    );
  };

  const renderSmartAnalytics = () => {
    const totalExpenses = categoryData.reduce((sum, item) => sum + item.amount, 0);
    const topCategory = categoryData[0];
    const savingsRate =
      ((periodData.find(p => p.period === selectedPeriod)?.savings || 0) /
        (periodData.find(p => p.period === selectedPeriod)?.income || 1)) *
      100;

    const smartInsights = [
      {
        id: 1,
        type: 'warning',
        icon: '⚠️',
        title: 'Chi tiêu ăn uống cao',
        insight: `${topCategory.category} chiếm ${topCategory.percentage}% tổng chi tiêu. Khuyến nghị giảm 10% bằng cách nấu ăn tại nhà.`,
        potential: `Tiết kiệm: ${formatCurrency(topCategory.amount * 0.1)}/tháng`,
        action: 'Tối ưu hóa',
        color: '#FF6B6B',
      },
      {
        id: 2,
        type: 'success',
        icon: '💡',
        title: 'Cơ hội tiết kiệm',
        insight: `Tỷ lệ tiết kiệm hiện tại ${savingsRate.toFixed(1)}%. Bạn có thể tăng lên 25% với một số điều chỉnh nhỏ.`,
        potential: `Mục tiêu: +${formatCurrency((periodData.find(p => p.period === selectedPeriod)?.income || 0) * 0.1)}/tháng`,
        action: 'Xem gợi ý',
        color: '#4ECDC4',
      },
      {
        id: 3,
        type: 'info',
        icon: '📊',
        title: 'Phân tích xu hướng',
        insight: `Chi tiêu giảm 8% so với tháng trước. Xu hướng tích cực, hãy duy trì!`,
        potential: `Tiến độ tốt: Đang đạt mục tiêu tiết kiệm`,
        action: 'Chi tiết',
        color: '#96CEB4',
      },
    ];

    return (
      <View style={styles.smartAnalyticsSection}>
        <View style={styles.analyticsHeader}>
          <Text style={styles.analyticsTitle}>🤖 AI Phân tích thông minh</Text>
          <TouchableOpacity style={styles.refreshButton}>
            <Ionicons name="refresh" size={16} color={Colors.primary[500]} />
          </TouchableOpacity>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.insightsScroll}>
          {smartInsights.map(insight => (
            <View key={insight.id} style={[styles.insightCard, { borderLeftColor: insight.color }]}>
              <View style={styles.insightHeader}>
                <Text style={styles.insightIcon}>{insight.icon}</Text>
                <Text style={styles.insightType}>{insight.title}</Text>
              </View>
              <Text style={styles.insightDescription}>{insight.insight}</Text>
              <Text style={[styles.insightPotential, { color: insight.color }]}>
                {insight.potential}
              </Text>
              <TouchableOpacity
                style={[styles.insightAction, { backgroundColor: insight.color + '20' }]}
              >
                <Text style={[styles.insightActionText, { color: insight.color }]}>
                  {insight.action}
                </Text>
                <Ionicons name="arrow-forward" size={14} color={insight.color} />
              </TouchableOpacity>
            </View>
          ))}
        </ScrollView>
      </View>
    );
  };

  const renderTabSelector = () => (
    <View style={styles.tabSelector}>
      <TouchableOpacity
        style={[styles.tabItem, selectedTab === 'overview' && styles.activeTab]}
        onPress={() => setSelectedTab('overview')}
      >
        <Text style={[styles.tabText, selectedTab === 'overview' && styles.activeTabText]}>
          Tổng quan
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.tabItem, selectedTab === 'categories' && styles.activeTab]}
        onPress={() => setSelectedTab('categories')}
      >
        <Text style={[styles.tabText, selectedTab === 'categories' && styles.activeTabText]}>
          Danh mục
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.tabItem, selectedTab === 'trends' && styles.activeTab]}
        onPress={() => setSelectedTab('trends')}
      >
        <Text style={[styles.tabText, selectedTab === 'trends' && styles.activeTabText]}>
          Xu hướng
        </Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2332" />
      <BackButton title="Báo cáo tài chính" showHomeIcon={true} />

      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Tab Selector */}
        {renderTabSelector()}

        {/* Period Selector - Only show for overview and categories tabs */}
        {(selectedTab === 'overview' || selectedTab === 'categories') && renderPeriodSelector()}

        {/* Content based on selected tab */}
        {selectedTab === 'overview' && (
          <>
            {/* Income vs Expenses Chart */}
            <View style={styles.chartSection}>
              <View style={styles.chartHeader}>
                <Text style={styles.chartTitle}>Thu chi tháng {selectedPeriod}</Text>
                <TouchableOpacity
                  onPress={() =>
                    (navigation as any).navigate('TransactionHistory', { period: selectedPeriod })
                  }
                >
                  <Text style={styles.viewDetails}>Chi tiết</Text>
                </TouchableOpacity>
              </View>
              {renderIncomeExpenseChart()}
            </View>

            {/* Vietnamese Cultural Insight Card */}
            {(() => {
              const culturalInsight = getVietnameseCulturalInsights();
              return (
                <View style={styles.culturalInsightCard}>
                  <View style={styles.insightHeader}>
                    <Text style={styles.insightIcon}>{culturalInsight.icon}</Text>
                    <View style={styles.insightContent}>
                      <Text style={styles.insightTitle}>{culturalInsight.title}</Text>
                      <Text style={styles.insightText}>{culturalInsight.insight}</Text>
                    </View>
                  </View>
                </View>
              );
            })()}

            {/* Current Balance Section */}
            <View style={styles.balanceSection}>
              <Text style={styles.balanceTitle}>Tình hình tài chính</Text>

              <View style={styles.balanceCard}>
                <View style={styles.balanceItem}>
                  <View style={styles.balanceIndicator}>
                    <View style={[styles.balanceDot, { backgroundColor: '#4ECDC4' }]} />
                    <Text style={styles.balanceLabel}>Tài khoản hiện tại</Text>
                  </View>
                  <Text style={styles.balanceAmount}>{formatCurrency(currentBalance)}</Text>
                </View>

                <View style={styles.balanceItem}>
                  <View style={styles.balanceIndicator}>
                    <View style={[styles.balanceDot, { backgroundColor: '#FFEAA7' }]} />
                    <Text style={styles.balanceLabel}>Mục tiêu tiết kiệm</Text>
                  </View>
                  <Text style={[styles.balanceAmount, { color: '#FFEAA7' }]}>
                    {formatCurrency(5000000)}
                  </Text>
                </View>
              </View>
            </View>
          </>
        )}

        {selectedTab === 'categories' && (
          <>
            {/* Smart Analytics Section */}
            {renderSmartAnalytics()}

            {/* Expense Category Pie Chart */}
            <View style={styles.chartSection}>
              <View style={styles.chartHeader}>
                <Text style={styles.chartTitle}>Chi tiêu theo danh mục</Text>
                <TouchableOpacity>
                  <Text style={styles.viewDetails}>Tháng {selectedPeriod}</Text>
                </TouchableOpacity>
              </View>

              {/* Combined Chart and Category Section */}
              <View style={styles.chartCategoryContainer}>
                {/* Pie Chart Container - Centered */}
                <View style={styles.pieChartCenterContainer}>
                  {renderModernPieChart(categoryData, 'Chi tiêu')}
                </View>

                {/* Visual Separator */}
                <View style={styles.chartSeparator} />

                {/* Category Breakdown - Below Chart */}
                <View style={styles.categoryBreakdownContainer}>{renderCategoryBreakdown()}</View>
              </View>
            </View>

            {/* Income Category Pie Chart */}
            <View style={styles.chartSection}>
              <View style={styles.chartHeader}>
                <Text style={styles.chartTitle}>Thu nhập theo danh mục</Text>
                <TouchableOpacity>
                  <Text style={styles.viewDetails}>Tháng {selectedPeriod}</Text>
                </TouchableOpacity>
              </View>

              {/* Combined Chart and Income Section */}
              <View style={styles.chartCategoryContainer}>
                {/* Pie Chart Container - Centered */}
                <View style={styles.pieChartCenterContainer}>
                  {renderModernPieChart(incomeData, 'Thu nhập')}
                </View>

                {/* Visual Separator */}
                <View style={styles.chartSeparator} />

                {/* Income Breakdown - Below Chart */}
                <View style={styles.categoryBreakdownContainer}>{renderIncomeBreakdown()}</View>
              </View>
            </View>
          </>
        )}

        {selectedTab === 'trends' && (
          <>
            {/* Monthly Trend Chart */}
            <View style={styles.chartSection}>
              <View style={styles.chartHeader}>
                <Text style={styles.chartTitle}>Xu hướng 6 tháng gần đây</Text>
                <TouchableOpacity>
                  <Text style={styles.viewDetails}>Xuất Excel</Text>
                </TouchableOpacity>
              </View>

              {renderBarChart()}

              <View style={styles.legend}>
                <View style={styles.legendItem}>
                  <View style={[styles.legendDot, { backgroundColor: '#4ECDC4' }]} />
                  <Text style={styles.legendText}>Thu nhập</Text>
                </View>
                <View style={styles.legendItem}>
                  <View style={[styles.legendDot, { backgroundColor: '#FF6B6B' }]} />
                  <Text style={styles.legendText}>Chi tiêu</Text>
                </View>
              </View>
            </View>

            {/* Monthly Breakdown Details */}
            {renderMonthlyBreakdown()}
          </>
        )}

        <View style={styles.bottomSpacing} />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  aiChatButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    gap: 6,
  },
  aiChatText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  balanceSection: {
    paddingHorizontal: 20,
    marginBottom: 30,
  },
  balanceTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 15,
  },
  balanceCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 20,
  },
  balanceItem: {
    marginBottom: 20,
  },
  balanceIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  balanceDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 10,
  },
  balanceLabel: {
    fontSize: 14,
    color: '#FFFFFF',
  },
  balanceAmount: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  chartSection: {
    paddingHorizontal: 20,
    marginBottom: 30,
  },
  chartHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  chartTitle: {
    fontSize: 16,
    color: '#FFFFFF',
  },
  viewDetails: {
    fontSize: 14,
    color: Colors.primary[500],
  },
  barChart: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    height: 120,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    paddingHorizontal: 20,
    paddingVertical: 20,
    marginBottom: 15,
  },
  barGroup: {
    alignItems: 'center',
    flex: 1,
  },
  bars: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'center',
    marginBottom: 10,
  },
  bar: {
    width: 10,
    borderRadius: 5,
    marginHorizontal: 2,
  },
  incomeBar: {
    backgroundColor: '#4ECDC4',
  },
  expenseBar: {
    backgroundColor: '#FF6B6B',
  },
  barLabel: {
    fontSize: 12,
    color: '#FFFFFF',
    opacity: 0.7,
  },
  legend: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 30,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  legendText: {
    fontSize: 12,
    color: '#FFFFFF',
    opacity: 0.8,
  },
  analysisSection: {
    paddingHorizontal: 20,
  },
  sectionTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 20,
  },
  analysisGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  analysisCard: {
    width: (screenWidth - 60) / 2,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 20,
    marginBottom: 15,
    alignItems: 'center',
  },
  analysisIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  iconText: {
    fontSize: 24,
  },
  analysisText: {
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'center',
    lineHeight: 18,
  },
  bottomSpacing: {
    height: 50,
  },
  // Vietnamese cultural enhancement styles
  culturalInsightCard: {
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    borderLeftWidth: 4,
    borderLeftColor: Colors.primary[500],
  },
  insightHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  insightIcon: {
    fontSize: 32,
    marginRight: 12,
  },
  insightContent: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 4,
  },
  insightText: {
    fontSize: 14,
    color: '#FFFFFF',
    lineHeight: 20,
  },
  periodSelector: {
    flexDirection: 'row',
    marginBottom: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    padding: 4,
  },
  periodTab: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 8,
  },
  activePeriodTab: {
    backgroundColor: Colors.primary[500],
  },
  periodText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '600',
  },
  activePeriodText: {
    color: '#FFFFFF',
  },
  // Enhanced styles for new components
  tabSelector: {
    flexDirection: 'row',
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    padding: 4,
  },
  tabItem: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 8,
  },
  activeTab: {
    backgroundColor: Colors.primary[500],
  },
  tabText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '600',
  },
  activeTabText: {
    color: '#FFFFFF',
  },
  pieChartSection: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 20,
  },
  pieChartCenterContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
    paddingVertical: 20,
    marginBottom: 0,
  },
  chartCategoryContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  pieChartContainer: {
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  categoryBreakdownContainer: {
    backgroundColor: 'transparent',
    paddingTop: 0,
    paddingHorizontal: 0,
    paddingBottom: 0,
  },
  chartSeparator: {
    height: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    marginHorizontal: 20,
    marginVertical: 16,
  },
  categoryBreakdown: {
    flex: 1,
  },
  categoryItem: {
    flexDirection: 'column',
    marginBottom: 0,
    backgroundColor: 'transparent',
    paddingVertical: 16,
    paddingHorizontal: 16,
  },
  enhancedCategoryItem: {
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.06)',
  },
  categoryMainInfo: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  categoryIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
    position: 'relative',
    overflow: 'hidden',
  },
  categoryIcon: {
    fontSize: 18,
    zIndex: 2,
  },
  categoryGlow: {
    position: 'absolute',
    width: 16,
    height: 16,
    borderRadius: 8,
    opacity: 0.3,
    top: 12,
    left: 12,
  },
  categoryDetails: {
    flex: 1,
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  categoryName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
    flex: 1,
  },
  categoryBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    marginLeft: 8,
  },
  categoryBadgeText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '700',
  },
  categoryAmount: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    fontWeight: '500',
    marginBottom: 4,
  },
  categoryInsights: {
    marginTop: 2,
  },
  categoryTrend: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
    fontStyle: 'italic',
  },
  categoryMetrics: {
    marginBottom: 8,
  },
  categoryProgressWrapper: {
    gap: 6,
  },
  categoryProgressBar: {
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
  },
  categoryStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  avgSpend: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
    fontWeight: '500',
  },
  categoryRanking: {
    backgroundColor: '#FF6B6B20',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  rankingText: {
    fontSize: 10,
    color: '#FF6B6B',
    fontWeight: '700',
  },
  categoryActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 6,
  },
  detailButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
  },
  optimizeButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 234, 167, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 234, 167, 0.3)',
  },
  incomeExpenseChart: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 20,
  },
  chartBars: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'flex-end',
    height: 120,
    marginBottom: 20,
  },
  barColumn: {
    alignItems: 'center',
    flex: 1,
  },
  chartBar: {
    width: 40,
    borderRadius: 6,
    marginBottom: 8,
  },
  chartBarLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  barAmount: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  savingsDisplay: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  savingsLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  savingsAmount: {
    fontSize: 16,
    fontWeight: '600',
  },
  // Monthly breakdown styles
  monthlyBreakdown: {
    paddingHorizontal: 20,
    marginTop: 20,
  },
  breakdownTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
    marginBottom: 16,
    paddingLeft: 4,
  },
  monthlyItem: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#4ECDC4',
  },
  monthHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  monthTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  netAmount: {
    fontSize: 16,
    fontWeight: '700',
  },
  monthDetails: {
    gap: 8,
  },
  monthRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  monthLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  monthValue: {
    fontSize: 14,
    fontWeight: '600',
  },
  // Smart Analytics Styles
  smartAnalyticsSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  analyticsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  analyticsTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  refreshButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  insightsScroll: {
    marginHorizontal: -20,
    paddingHorizontal: 20,
  },
  insightCard: {
    width: 280,
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    marginRight: 12,
    borderLeftWidth: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  insightType: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
    flex: 1,
  },
  insightDescription: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 18,
    marginBottom: 8,
  },
  insightPotential: {
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 12,
  },
  insightAction: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    gap: 4,
  },
  insightActionText: {
    fontSize: 12,
    fontWeight: '600',
  },
  modernPieChartContainer: {
    backgroundColor: 'transparent',
    padding: 16,
    marginBottom: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chartWrapper: {
    position: 'relative',
    alignItems: 'center',
    justifyContent: 'center',
  },
});

export default ReportsScreen;
