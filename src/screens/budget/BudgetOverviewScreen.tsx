import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
  Animated,
  Alert,
  Dimensions,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

import { Colors } from '../../constants/colors';
import { BudgetPeriod, ExpenseCategory } from '../../types';

const { width: screenWidth } = Dimensions.get('window');

interface BudgetData {
  id: string;
  name: string;
  totalAmount: number;
  spentAmount: number;
  period: BudgetPeriod;
  categories: {
    category: ExpenseCategory;
    allocatedAmount: number;
    spentAmount: number;
    color: string;
  }[];
}

const BudgetOverviewScreen: React.FC = () => {
  const navigation = useNavigation();
  const [selectedPeriod, setSelectedPeriod] = useState<BudgetPeriod>(BudgetPeriod.MONTHLY);
  const [showTemplates, setShowTemplates] = useState(false);
  const [showSmartInsights, setShowSmartInsights] = useState(true);
  const [animationValue] = useState(new Animated.Value(0));
  const [selectedTab, setSelectedTab] = useState<'overview' | 'analytics' | 'goals'>('overview');

  useEffect(() => {
    Animated.timing(animationValue, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: false,
    }).start();
  }, []);

  // Enhanced Vietnamese budget data with cultural context
  const mockBudgets: BudgetData[] = [
    {
      id: '1',
      name: 'Ngân sách Tháng 12 - Chuẩn bị Tết',
      totalAmount: 12000000,
      spentAmount: 7800000,
      period: BudgetPeriod.MONTHLY,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          allocatedAmount: 4000000, // Higher for Tet preparation
          spentAmount: 3200000,
          color: '#FF6B6B',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          allocatedAmount: 1800000, // More travel during holidays
          spentAmount: 1500000,
          color: '#4ECDC4',
        },
        {
          category: ExpenseCategory.SHOPPING,
          allocatedAmount: 3000000, // Tet shopping
          spentAmount: 2100000,
          color: '#45B7D1',
        },
        {
          category: ExpenseCategory.ENTERTAINMENT,
          allocatedAmount: 1200000, // Holiday celebrations
          spentAmount: 1000000,
          color: '#96CEB4',
        },
        {
          category: ExpenseCategory.OTHER,
          allocatedAmount: 2000000, // Li xi money, gifts
          spentAmount: 0,
          color: '#FFD700',
        },
      ],
    },
  ];

  // Vietnamese budget templates
  const vietnameseBudgetTemplates = [
    {
      id: 'student',
      name: 'Sinh viên',
      description: 'Budget cho sinh viên đại học',
      totalAmount: 3000000,
      icon: '🎓',
      categories: [
        { category: ExpenseCategory.FOOD, amount: 1500000, percentage: 50 },
        { category: ExpenseCategory.TRANSPORT, amount: 600000, percentage: 20 },
        { category: ExpenseCategory.EDUCATION, amount: 500000, percentage: 16.7 },
        { category: ExpenseCategory.ENTERTAINMENT, amount: 400000, percentage: 13.3 },
      ],
    },
    {
      id: 'office_worker',
      name: 'Nhân viên văn phòng',
      description: 'Budget cho dân công sở',
      totalAmount: 8000000,
      icon: '💼',
      categories: [
        { category: ExpenseCategory.FOOD, amount: 2400000, percentage: 30 },
        { category: ExpenseCategory.TRANSPORT, amount: 1600000, percentage: 20 },
        { category: ExpenseCategory.SHOPPING, amount: 1600000, percentage: 20 },
        { category: ExpenseCategory.UTILITIES, amount: 1200000, percentage: 15 },
        { category: ExpenseCategory.ENTERTAINMENT, amount: 800000, percentage: 10 },
        { category: ExpenseCategory.OTHER, amount: 400000, percentage: 5 },
      ],
    },
    {
      id: 'family',
      name: 'Gia đình 4 người',
      description: 'Budget cho gia đình có con nhỏ',
      totalAmount: 15000000,
      icon: '👨‍👩‍👧‍👦',
      categories: [
        { category: ExpenseCategory.FOOD, amount: 4500000, percentage: 30 },
        { category: ExpenseCategory.EDUCATION, amount: 3000000, percentage: 20 },
        { category: ExpenseCategory.HEALTHCARE, amount: 2250000, percentage: 15 },
        { category: ExpenseCategory.UTILITIES, amount: 2250000, percentage: 15 },
        { category: ExpenseCategory.TRANSPORT, amount: 1500000, percentage: 10 },
        { category: ExpenseCategory.OTHER, amount: 1500000, percentage: 10 },
      ],
    },
    {
      id: 'tet_special',
      name: 'Đặc biệt - Mùa Tết',
      description: 'Budget tăng cường cho Tết Nguyên Đán',
      totalAmount: 20000000,
      icon: '🧧',
      categories: [
        { category: ExpenseCategory.FOOD, amount: 8000000, percentage: 40 },
        { category: ExpenseCategory.SHOPPING, amount: 6000000, percentage: 30 },
        { category: ExpenseCategory.TRANSPORT, amount: 2000000, percentage: 10 },
        { category: ExpenseCategory.ENTERTAINMENT, amount: 2000000, percentage: 10 },
        { category: ExpenseCategory.OTHER, amount: 2000000, percentage: 10 }, // Li xi
      ],
    },
  ];

  const currentBudget = mockBudgets[0];
  const progressPercentage = (currentBudget.spentAmount / currentBudget.totalAmount) * 100;

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  // AI-powered smart insights based on Vietnamese spending patterns
  const getSmartInsights = () => {
    const spentPercentage = (currentBudget.spentAmount / currentBudget.totalAmount) * 100;
    const remainingDays = 30 - new Date().getDate();
    const dailyBudget = (currentBudget.totalAmount - currentBudget.spentAmount) / remainingDays;

    if (spentPercentage > 80) {
      return {
        type: 'warning',
        icon: '⚠️',
        title: 'Cảnh báo ngân sách',
        message: `Bạn đã chi ${spentPercentage.toFixed(0)}% ngân sách. Hãy tiết kiệm hơn!`,
        action: 'Xem gợi ý tiết kiệm',
        color: '#FF6B6B',
      };
    } else if (dailyBudget < 100000) {
      return {
        type: 'tip',
        icon: '💡',
        title: 'Mẹo tiết kiệm',
        message: `Còn ${formatCurrency(dailyBudget)}/ngày. Thử ăn cơm nhà và đi xe bus!`,
        action: 'Xem mẹo hay',
        color: '#FFD700',
      };
    } else if (spentPercentage < 50 && remainingDays < 15) {
      return {
        type: 'achievement',
        icon: '🎉',
        title: 'Quản lý tốt!',
        message: 'Bạn chi tiêu rất hợp lý. Có thể tăng ngân sách cho tháng sau!',
        action: 'Tạo mục tiêu mới',
        color: Colors.primary[500],
      };
    } else {
      return {
        type: 'seasonal',
        icon: '🧧',
        title: 'Gợi ý theo mùa',
        message: 'Tháng 12 sắp đến Tết! Nên chuẩn bị thêm 40% ngân sách.',
        action: 'Tạo ngân sách Tết',
        color: '#FF6B6B',
      };
    }
  };

  // Gamification features inspired by MoMo
  const getBudgetStreak = () => {
    return {
      currentStreak: 7,
      maxStreak: 15,
      title: 'Chuỗi ngày tiết kiệm',
      reward: 'Hoàn thành 30 ngày để nhận huy hiệu Chuyên gia tiết kiệm!',
    };
  };

  // Multi-currency support like MISA MoneyKeeper
  const getCurrencyRates = () => {
    return [
      { currency: 'USD', rate: '24,100', change: '+0.2%', color: Colors.primary[500] },
      { currency: 'Gold SJC', rate: '76,500,000', change: '+1.2%', color: '#FFD700' },
    ];
  };

  const getCategoryName = (category: ExpenseCategory) => {
    const categoryNames = {
      [ExpenseCategory.FOOD]: 'Ăn uống',
      [ExpenseCategory.TRANSPORT]: 'Di chuyển',
      [ExpenseCategory.SHOPPING]: 'Mua sắm',
      [ExpenseCategory.ENTERTAINMENT]: 'Giải trí',
      [ExpenseCategory.HEALTHCARE]: 'Y tế',
      [ExpenseCategory.EDUCATION]: 'Giáo dục',
      [ExpenseCategory.UTILITIES]: 'Tiện ích',
      [ExpenseCategory.OTHER]: 'Khác',
    };
    return categoryNames[category];
  };

  const renderCategoryItem = ({ item }: { item: (typeof currentBudget.categories)[0] }) => {
    const progress = (item.spentAmount / item.allocatedAmount) * 100;
    const isOverBudget = progress > 100;

    const getCategoryIcon = (category: ExpenseCategory) => {
      const icons = {
        [ExpenseCategory.FOOD]: 'restaurant',
        [ExpenseCategory.TRANSPORT]: 'car',
        [ExpenseCategory.SHOPPING]: 'bag',
        [ExpenseCategory.ENTERTAINMENT]: 'musical-notes',
        [ExpenseCategory.HEALTHCARE]: 'medical',
        [ExpenseCategory.EDUCATION]: 'school',
        [ExpenseCategory.UTILITIES]: 'flash',
        [ExpenseCategory.OTHER]: 'ellipsis-horizontal',
      };
      return icons[category] || 'ellipsis-horizontal';
    };

    return (
      <View style={styles.categoryCard}>
        <View style={styles.categoryHeader}>
          <View style={styles.categoryInfo}>
            <View style={[styles.categoryIcon, { backgroundColor: item.color }]}>
              <Ionicons name={getCategoryIcon(item.category) as any} size={20} color="#FFFFFF" />
            </View>
            <Text style={styles.categoryName}>{getCategoryName(item.category)}</Text>
          </View>
          <Text style={[styles.categoryAmount, isOverBudget && styles.overBudgetText]}>
            {formatCurrency(item.spentAmount)}
          </Text>
        </View>
        <View style={styles.categoryProgress}>
          <View style={styles.progressBarContainer}>
            <View
              style={[
                styles.progressBarFill,
                {
                  width: `${Math.min(progress, 100)}%`,
                  backgroundColor: isOverBudget ? '#FF6B6B' : Colors.primary[500],
                },
              ]}
            />
          </View>
          <Text style={styles.budgetText}>{formatCurrency(item.allocatedAmount)} ngân sách</Text>
        </View>
      </View>
    );
  };

  const renderBudgetTemplate = (template: any) => (
    <TouchableOpacity
      key={template.id}
      style={styles.templateCard}
      onPress={() => {
        Alert.alert(
          'Áp dụng template',
          `Bạn có muốn áp dụng template "${template.name}" với ngân sách ${formatCurrency(template.totalAmount)}?`,
          [
            { text: 'Hủy', style: 'cancel' },
            { text: 'Áp dụng', onPress: () => setShowTemplates(false) },
          ]
        );
      }}
    >
      <Text style={styles.templateIcon}>{template.icon}</Text>
      <Text style={styles.templateName}>{template.name}</Text>
      <Text style={styles.templateDescription}>{template.description}</Text>
      <Text style={styles.templateAmount}>{formatCurrency(template.totalAmount)}</Text>
    </TouchableOpacity>
  );

  const renderSmartInsightCard = () => {
    const insight = getSmartInsights();
    return (
      <Animated.View
        style={[
          styles.smartInsightCard,
          {
            opacity: animationValue,
            transform: [
              {
                translateY: animationValue.interpolate({
                  inputRange: [0, 1],
                  outputRange: [20, 0],
                }),
              },
            ],
          },
        ]}
      >
        <View style={styles.insightHeader}>
          <Text style={styles.insightIcon}>{insight.icon}</Text>
          <View style={styles.insightContent}>
            <Text style={styles.insightTitle}>{insight.title}</Text>
            <Text style={styles.insightMessage}>{insight.message}</Text>
          </View>
          <TouchableOpacity style={[styles.insightAction, { backgroundColor: insight.color }]}>
            <Text style={styles.insightActionText}>{insight.action}</Text>
          </TouchableOpacity>
        </View>
      </Animated.View>
    );
  };

  const renderStreakCard = () => {
    const streak = getBudgetStreak();
    return (
      <View style={styles.streakCard}>
        <View style={styles.streakHeader}>
          <Text style={styles.streakIcon}>🔥</Text>
          <View style={styles.streakInfo}>
            <Text style={styles.streakTitle}>{streak.title}</Text>
            <Text style={styles.streakSubtitle}>
              {streak.currentStreak}/{streak.maxStreak} ngày
            </Text>
          </View>
        </View>
        <View style={styles.streakProgress}>
          <View style={styles.streakProgressBar}>
            <Animated.View
              style={[
                styles.streakProgressFill,
                {
                  transform: [
                    {
                      scaleX: animationValue.interpolate({
                        inputRange: [0, 1],
                        outputRange: [0, streak.currentStreak / streak.maxStreak],
                      }),
                    },
                  ],
                },
              ]}
            />
          </View>
          <Text style={styles.streakReward}>{streak.reward}</Text>
        </View>
      </View>
    );
  };

  const renderCurrencyRates = () => (
    <View style={styles.currencySection}>
      <Text style={styles.currencyTitle}>Tỷ giá hôm nay</Text>
      <View style={styles.currencyList}>
        {getCurrencyRates().map((rate, index) => (
          <View key={index} style={styles.currencyItem}>
            <Text style={styles.currencyName}>{rate.currency}</Text>
            <View style={styles.currencyInfo}>
              <Text style={styles.currencyRate}>{rate.rate}</Text>
              <Text style={[styles.currencyChange, { color: rate.color }]}>{rate.change}</Text>
            </View>
          </View>
        ))}
      </View>
    </View>
  );

  const renderTabSelector = () => (
    <View style={styles.tabSelector}>
      {[
        { id: 'overview', label: 'Tổng quan', icon: 'grid' },
        { id: 'analytics', label: 'Phân tích', icon: 'analytics' },
        { id: 'goals', label: 'Mục tiêu', icon: 'flag' },
      ].map(tab => (
        <TouchableOpacity
          key={tab.id}
          style={[styles.tabButton, selectedTab === tab.id && styles.activeTabButton]}
          onPress={() => setSelectedTab(tab.id as any)}
        >
          <Ionicons
            name={tab.icon as any}
            size={20}
            color={selectedTab === tab.id ? '#FFFFFF' : Colors.primary[500]}
          />
          <Text
            style={[styles.tabButtonText, selectedTab === tab.id && styles.activeTabButtonText]}
          >
            {tab.label}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );

  return (
    <View style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Enhanced Header with AI insights */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.title}>Quản lý ngân sách thông minh</Text>
            <Text style={styles.headerSubtitle}>Được hỗ trợ bởi AI • Phong cách Việt Nam</Text>
          </View>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => navigation.navigate('CreateBudget' as never)}
          >
            <Ionicons name="add" size={24} color={Colors.primary[500]} />
          </TouchableOpacity>
        </View>

        {/* Smart Insight Card - inspired by MoMo's AI features */}
        {showSmartInsights && renderSmartInsightCard()}

        {/* Tab Selector */}
        {renderTabSelector()}

        {/* Period Selector - Enhanced with animations */}
        <Animated.View
          style={[
            styles.periodSelector,
            {
              opacity: animationValue,
              transform: [
                {
                  scale: animationValue.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0.95, 1],
                  }),
                },
              ],
            },
          ]}
        >
          {Object.values(BudgetPeriod).map(period => (
            <TouchableOpacity
              key={period}
              style={[styles.periodTab, selectedPeriod === period && styles.activePeriodTab]}
              onPress={() => setSelectedPeriod(period)}
            >
              <Text
                style={[styles.periodText, selectedPeriod === period && styles.activePeriodText]}
              >
                {period === BudgetPeriod.WEEKLY
                  ? 'Tuần'
                  : period === BudgetPeriod.MONTHLY
                    ? 'Tháng'
                    : period === BudgetPeriod.QUARTERLY
                      ? 'Quý'
                      : 'Năm'}
              </Text>
            </TouchableOpacity>
          ))}
        </Animated.View>

        {/* Enhanced Budget Summary Card with animations */}
        <Animated.View
          style={[
            styles.summaryCard,
            {
              opacity: animationValue,
              transform: [
                {
                  translateY: animationValue.interpolate({
                    inputRange: [0, 1],
                    outputRange: [30, 0],
                  }),
                },
              ],
            },
          ]}
        >
          <LinearGradient
            colors={[Colors.primary[500], '#2E8B57']}
            style={styles.summaryGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            <View style={styles.summaryHeader}>
              <View>
                <Text style={styles.summaryTitle}>{currentBudget.name}</Text>
                <Text style={styles.summaryAmount}>
                  {formatCurrency(currentBudget.spentAmount)}
                </Text>
                <Text style={styles.summarySubtitle}>
                  của {formatCurrency(currentBudget.totalAmount)}
                </Text>
              </View>
              <TouchableOpacity style={styles.summaryAction}>
                <Ionicons name="notifications" size={20} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
            <View style={styles.progressContainer}>
              <View style={styles.progressBarContainer}>
                <Animated.View
                  style={[
                    styles.progressBarFill,
                    {
                      transform: [
                        {
                          scaleX: animationValue.interpolate({
                            inputRange: [0, 1],
                            outputRange: [0, Math.min(progressPercentage / 100, 1)],
                          }),
                        },
                      ],
                      backgroundColor: '#FFFFFF',
                    },
                  ]}
                />
              </View>
              <Text style={styles.progressText}>
                {Math.round(progressPercentage)}% đã sử dụng • {30 - new Date().getDate()} ngày còn
                lại
              </Text>
            </View>
          </LinearGradient>
        </Animated.View>

        {/* Gamification Streak Card */}
        {renderStreakCard()}

        {/* Currency Rates Section */}
        {renderCurrencyRates()}

        {/* Enhanced Quick Stats with more metrics */}
        <View style={styles.statsContainer}>
          <Animated.View
            style={[
              styles.statCard,
              {
                opacity: animationValue,
                transform: [
                  {
                    translateY: animationValue.interpolate({
                      inputRange: [0, 1],
                      outputRange: [20, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <Ionicons name="wallet" size={28} color={Colors.primary[500]} />
            <Text style={styles.statValue}>
              {formatCurrency(currentBudget.totalAmount - currentBudget.spentAmount)}
            </Text>
            <Text style={styles.statLabel}>Còn lại</Text>
          </Animated.View>

          <Animated.View
            style={[
              styles.statCard,
              {
                opacity: animationValue,
                transform: [
                  {
                    translateY: animationValue.interpolate({
                      inputRange: [0, 1],
                      outputRange: [25, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <Ionicons name="trending-up" size={28} color="#FFD700" />
            <Text style={styles.statValue}>{formatCurrency(currentBudget.spentAmount / 30)}</Text>
            <Text style={styles.statLabel}>TB/ngày</Text>
          </Animated.View>

          <Animated.View
            style={[
              styles.statCard,
              {
                opacity: animationValue,
                transform: [
                  {
                    translateY: animationValue.interpolate({
                      inputRange: [0, 1],
                      outputRange: [30, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <Ionicons name="flash" size={28} color="#FF6B6B" />
            <Text style={styles.statValue}>
              {formatCurrency(
                (currentBudget.totalAmount - currentBudget.spentAmount) /
                  (30 - new Date().getDate())
              )}
            </Text>
            <Text style={styles.statLabel}>Có thể chi/ngày</Text>
          </Animated.View>
        </View>

        {/* Categories */}
        <View style={styles.categoriesSection}>
          <Text style={styles.sectionTitle}>Chi tiết theo danh mục</Text>
          <FlatList
            data={currentBudget.categories}
            renderItem={renderCategoryItem}
            keyExtractor={item => item.category}
            scrollEnabled={false}
            showsVerticalScrollIndicator={false}
          />
        </View>

        {/* Vietnamese Budget Templates */}
        <View style={styles.templatesSection}>
          <View style={styles.templateHeader}>
            <Text style={styles.sectionTitle}>Mẫu ngân sách phổ biến</Text>
            <TouchableOpacity onPress={() => setShowTemplates(!showTemplates)}>
              <Text style={styles.toggleText}>{showTemplates ? 'Ẩn' : 'Xem'}</Text>
            </TouchableOpacity>
          </View>

          {showTemplates && (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.templatesScroll}
            >
              {vietnameseBudgetTemplates.map(renderBudgetTemplate)}
            </ScrollView>
          )}
        </View>

        {/* Enhanced Actions with more options */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.primaryActionButton}
            onPress={() => navigation.navigate('CreateBudget' as never)}
          >
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.primaryActionGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Ionicons name="add-circle" size={20} color="#FFFFFF" />
              <Text style={styles.primaryActionText}>Tạo ngân sách thông minh</Text>
            </LinearGradient>
          </TouchableOpacity>

          <View style={styles.secondaryActions}>
            <TouchableOpacity
              style={styles.secondaryActionButton}
              onPress={() => navigation.navigate('EditBudget' as never)}
            >
              <Ionicons name="create" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Chỉnh sửa</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryActionButton}
              onPress={() => Alert.alert('Chia sẻ', 'Chia sẻ ngân sách với gia đình')}
            >
              <Ionicons name="share" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Chia sẻ</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryActionButton}
              onPress={() => Alert.alert('Xuất báo cáo', 'Xuất báo cáo Excel/PDF')}
            >
              <Ionicons name="download" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Xuất</Text>
            </TouchableOpacity>
          </View>
        </View>
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
    paddingBottom: 16,
    backgroundColor: '#1A2E3A',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  headerLeft: {
    flex: 1,
  },
  headerSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 4,
  },
  addButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  periodSelector: {
    flexDirection: 'row',
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 4,
  },
  periodTab: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 12,
  },
  activePeriodTab: {
    backgroundColor: Colors.primary[500],
  },
  periodText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '600',
  },
  activePeriodText: {
    color: '#FFFFFF',
  },
  summaryCard: {
    marginHorizontal: 20,
    marginBottom: 20,
    overflow: 'hidden',
    padding: 0,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
  },
  summaryGradient: {
    padding: 20,
  },
  summaryTitle: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 8,
    fontWeight: '600',
  },
  summaryAmount: {
    fontSize: 28,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  summarySubtitle: {
    fontSize: 16,
    color: '#FFFFFF',
    opacity: 0.8,
    marginBottom: 20,
  },
  progressContainer: {
    marginTop: 16,
  },
  progressText: {
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'right',
    marginTop: 8,
  },
  statsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
    gap: 12,
  },
  statCard: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 20,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
  },
  statValue: {
    fontSize: 18,
    color: '#FFFFFF',
    marginTop: 8,
    marginBottom: 4,
    fontWeight: 'bold',
  },
  statLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  categoriesSection: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 16,
    fontWeight: 'bold',
  },
  categoryCard: {
    marginBottom: 16,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  categoryInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  categoryName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  categoryAmount: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  overBudgetText: {
    color: '#FF6B6B',
  },
  progressBarContainer: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  categoryProgress: {
    marginTop: 8,
  },
  budgetText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'right',
    marginTop: 4,
  },
  actionsContainer: {
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  createButton: {
    backgroundColor: Colors.primary[500],
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  createButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
  },
  editButton: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: Colors.primary[500],
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  editButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.primary[500],
    marginLeft: 8,
  },
  // Vietnamese template styles
  templatesSection: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  templateHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  toggleText: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  templatesScroll: {
    marginHorizontal: -20,
    paddingHorizontal: 20,
  },
  templateCard: {
    width: 140,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginRight: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  templateIcon: {
    fontSize: 28,
    marginBottom: 8,
  },
  templateName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 4,
  },
  templateDescription: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    marginBottom: 8,
    lineHeight: 14,
  },
  templateAmount: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  // Enhanced styles for Vietnamese fintech features
  smartInsightCard: {
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
    fontSize: 24,
    marginRight: 12,
  },
  insightContent: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 4,
  },
  insightMessage: {
    fontSize: 13,
    color: '#FFFFFF',
    lineHeight: 18,
  },
  insightAction: {
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  insightActionText: {
    fontSize: 11,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  tabSelector: {
    flexDirection: 'row',
    marginHorizontal: 20,
    marginBottom: 16,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 4,
  },
  tabButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 8,
    gap: 6,
  },
  activeTabButton: {
    backgroundColor: Colors.primary[500],
  },
  tabButtonText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  activeTabButtonText: {
    color: '#FFFFFF',
  },
  summaryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  summaryAction: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  streakCard: {
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
  },
  streakHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  streakIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  streakInfo: {
    flex: 1,
  },
  streakTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  streakSubtitle: {
    fontSize: 12,
    color: Colors.primary[500],
  },
  streakProgress: {
    marginTop: 8,
  },
  streakProgressBar: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 3,
    marginBottom: 8,
  },
  streakProgressFill: {
    height: '100%',
    backgroundColor: '#FFD700',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  streakReward: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 16,
  },
  currencySection: {
    marginHorizontal: 20,
    marginBottom: 20,
  },
  currencyTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  currencyList: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  currencyItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  currencyName: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  currencyInfo: {
    alignItems: 'flex-end',
  },
  currencyRate: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  currencyChange: {
    fontSize: 12,
    fontWeight: '500',
  },
  primaryActionButton: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 16,
  },
  primaryActionGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20,
    gap: 8,
  },
  primaryActionText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  secondaryActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  secondaryActionButton: {
    flex: 1,
    backgroundColor: 'rgba(61, 161, 61, 0.1)',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
    gap: 4,
  },
  secondaryActionText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
});

export default BudgetOverviewScreen;
