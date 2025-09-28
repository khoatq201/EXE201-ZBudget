import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Animated,
  Alert,
  Dimensions,
} from 'react-native';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import Slider from '@react-native-community/slider';

import { Colors } from '../../constants/colors';
import { ExpenseCategory, BudgetStackParamList } from '../../types';
import { BackButton } from '../../components';

const { width: screenWidth } = Dimensions.get('window');

type BudgetDetailRouteProp = RouteProp<BudgetStackParamList, 'BudgetDetail'>;

interface CategoryBudget {
  category: ExpenseCategory;
  allocatedAmount: number;
  spentAmount: number;
  percentage: number;
  color: string;
  icon: string;
  priority: 'high' | 'medium' | 'low';
}

interface BudgetData {
  id: string;
  name: string;
  totalAmount: number;
  monthlyIncome: number;
  categories: CategoryBudget[];
}

const BudgetDetailScreen: React.FC = () => {
  const navigation = useNavigation();
  const route = useRoute<BudgetDetailRouteProp>();
  const { budgetId } = route.params;

  const [selectedTab, setSelectedTab] = useState<'planner' | 'analysis' | 'goals'>('planner');
  const [isEditing, setIsEditing] = useState(false);
  const [animationValue] = useState(new Animated.Value(0));
  const [budgetData, setBudgetData] = useState<BudgetData | null>(null);

  useEffect(() => {
    loadBudgetData();
    Animated.timing(animationValue, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: false,
    }).start();
  }, [budgetId]);

  const loadBudgetData = () => {
    // Mock data - in real app, fetch from API
    const mockData: BudgetData = {
      id: budgetId,
      name: 'Ngân sách Tháng 12 - Chuẩn bị Tết',
      totalAmount: 12000000,
      monthlyIncome: 15000000,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          allocatedAmount: 4000000,
          spentAmount: 3200000,
          percentage: 33.3,
          color: '#FF6B6B',
          icon: '🍽️',
          priority: 'high',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          allocatedAmount: 1800000,
          spentAmount: 1500000,
          percentage: 15,
          color: '#4ECDC4',
          icon: '🚗',
          priority: 'high',
        },
        {
          category: ExpenseCategory.SHOPPING,
          allocatedAmount: 3000000,
          spentAmount: 2100000,
          percentage: 25,
          color: '#45B7D1',
          icon: '🛍️',
          priority: 'medium',
        },
        {
          category: ExpenseCategory.ENTERTAINMENT,
          allocatedAmount: 1200000,
          spentAmount: 1000000,
          percentage: 10,
          color: '#96CEB4',
          icon: '🎮',
          priority: 'medium',
        },
        {
          category: ExpenseCategory.UTILITIES,
          allocatedAmount: 1000000,
          spentAmount: 800000,
          percentage: 8.3,
          color: '#FFD93D',
          icon: '💡',
          priority: 'high',
        },
        {
          category: ExpenseCategory.OTHER,
          allocatedAmount: 1000000,
          spentAmount: 200000,
          percentage: 8.4,
          color: '#C7CEEA',
          icon: '📝',
          priority: 'low',
        },
      ],
    };
    setBudgetData(mockData);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const getCategoryName = (category: ExpenseCategory) => {
    const names = {
      [ExpenseCategory.FOOD]: 'Ăn uống',
      [ExpenseCategory.TRANSPORT]: 'Di chuyển',
      [ExpenseCategory.SHOPPING]: 'Mua sắm',
      [ExpenseCategory.ENTERTAINMENT]: 'Giải trí',
      [ExpenseCategory.UTILITIES]: 'Tiện ích',
      [ExpenseCategory.HEALTHCARE]: 'Y tế',
      [ExpenseCategory.EDUCATION]: 'Giáo dục',
      [ExpenseCategory.OTHER]: 'Khác',
    };
    return names[category];
  };

  const updateCategoryBudget = (categoryIndex: number, newPercentage: number) => {
    if (!budgetData) return;

    const newCategories = [...budgetData.categories];
    const oldPercentage = newCategories[categoryIndex].percentage;
    const difference = newPercentage - oldPercentage;

    // Update the selected category
    newCategories[categoryIndex].percentage = newPercentage;
    newCategories[categoryIndex].allocatedAmount = (budgetData.totalAmount * newPercentage) / 100;

    // Distribute the difference among other categories proportionally
    const otherCategories = newCategories.filter((_, index) => index !== categoryIndex);
    const otherTotalPercentage = otherCategories.reduce((sum, cat) => sum + cat.percentage, 0);

    if (otherTotalPercentage > 0) {
      otherCategories.forEach((cat, index) => {
        const adjustmentRatio = cat.percentage / otherTotalPercentage;
        const adjustment = difference * adjustmentRatio;
        const newCatPercentage = Math.max(0, cat.percentage - adjustment);

        // Find the original index
        const originalIndex = budgetData.categories.findIndex(c => c.category === cat.category);
        newCategories[originalIndex].percentage = newCatPercentage;
        newCategories[originalIndex].allocatedAmount =
          (budgetData.totalAmount * newCatPercentage) / 100;
      });
    }

    setBudgetData({
      ...budgetData,
      categories: newCategories,
    });
  };

  const renderInteractivePlanner = () => {
    if (!budgetData) return null;

    return (
      <View style={styles.plannerSection}>
        <View style={styles.plannerHeader}>
          <Text style={styles.plannerTitle}>Trình lập kế hoạch tương tác</Text>
          <Text style={styles.plannerSubtitle}>
            Kéo thanh trượt để phân bổ {formatCurrency(budgetData.totalAmount)} theo tỷ lệ % thu
            nhập
          </Text>
          <TouchableOpacity style={styles.editButton} onPress={() => setIsEditing(!isEditing)}>
            <Ionicons
              name={isEditing ? 'checkmark' : 'create'}
              size={16}
              color={Colors.primary[500]}
            />
            <Text style={styles.editButtonText}>{isEditing ? 'Hoàn thành' : 'Chỉnh sửa'}</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.incomeInfo}>
          <Text style={styles.incomeLabel}>Thu nhập hàng tháng:</Text>
          <Text style={styles.incomeAmount}>{formatCurrency(budgetData.monthlyIncome)}</Text>
          <Text style={styles.budgetRatio}>
            Ngân sách = {((budgetData.totalAmount / budgetData.monthlyIncome) * 100).toFixed(1)}%
            thu nhập
          </Text>
        </View>

        {budgetData.categories.map((category, index) => (
          <Animated.View
            key={category.category}
            style={[
              styles.categorySlider,
              {
                opacity: animationValue,
                transform: [
                  {
                    translateX: animationValue.interpolate({
                      inputRange: [0, 1],
                      outputRange: [20, 0],
                    }),
                  },
                ],
              },
            ]}
          >
            <View style={styles.categorySliderHeader}>
              <View style={styles.categorySliderInfo}>
                <Text style={styles.categorySliderIcon}>{category.icon}</Text>
                <View style={styles.categorySliderText}>
                  <Text style={styles.categorySliderName}>
                    {getCategoryName(category.category)}
                  </Text>
                  <Text style={styles.categorySliderAmount}>
                    {formatCurrency(category.allocatedAmount)} ({category.percentage.toFixed(1)}%)
                  </Text>
                </View>
              </View>
              <View
                style={[
                  styles.priorityBadge,
                  {
                    backgroundColor:
                      category.priority === 'high'
                        ? '#FF6B6B'
                        : category.priority === 'medium'
                          ? '#FFD93D'
                          : '#96CEB4',
                  },
                ]}
              >
                <Text style={styles.priorityText}>
                  {category.priority === 'high'
                    ? 'Cao'
                    : category.priority === 'medium'
                      ? 'Trung bình'
                      : 'Thấp'}
                </Text>
              </View>
            </View>

            {isEditing && (
              <View style={styles.sliderContainer}>
                <Slider
                  style={styles.slider}
                  minimumValue={0}
                  maximumValue={50}
                  value={category.percentage}
                  onValueChange={value => updateCategoryBudget(index, value)}
                  minimumTrackTintColor={category.color}
                  maximumTrackTintColor="rgba(255,255,255,0.3)"
                />
                <View style={styles.sliderLabels}>
                  <Text style={styles.sliderLabel}>0%</Text>
                  <Text style={styles.sliderLabel}>50%</Text>
                </View>
              </View>
            )}

            <View style={styles.categoryProgress}>
              <View style={styles.progressBarContainer}>
                <Animated.View
                  style={[
                    styles.progressBarFill,
                    {
                      transform: [
                        {
                          scaleX: animationValue.interpolate({
                            inputRange: [0, 1],
                            outputRange: [0, category.spentAmount / category.allocatedAmount],
                          }),
                        },
                      ],
                      backgroundColor: category.color,
                    },
                  ]}
                />
              </View>
              <Text style={styles.progressText}>
                Đã chi: {formatCurrency(category.spentAmount)} /{' '}
                {formatCurrency(category.allocatedAmount)}
              </Text>
            </View>
          </Animated.View>
        ))}

        <View style={styles.budgetSummary}>
          <View style={styles.summaryItem}>
            <Text style={styles.summaryLabel}>Tổng phân bổ:</Text>
            <Text style={styles.summaryValue}>
              {formatCurrency(
                budgetData.categories.reduce((sum, cat) => sum + cat.allocatedAmount, 0)
              )}
            </Text>
          </View>
          <View style={styles.summaryItem}>
            <Text style={styles.summaryLabel}>Còn lại để phân bổ:</Text>
            <Text style={[styles.summaryValue, { color: Colors.primary[500] }]}>
              {formatCurrency(
                budgetData.totalAmount -
                  budgetData.categories.reduce((sum, cat) => sum + cat.allocatedAmount, 0)
              )}
            </Text>
          </View>
        </View>
      </View>
    );
  };

  const renderAnalysis = () => {
    if (!budgetData) return null;

    const totalSpent = budgetData.categories.reduce((sum, cat) => sum + cat.spentAmount, 0);
    const spentPercentage = (totalSpent / budgetData.totalAmount) * 100;

    return (
      <View style={styles.analysisSection}>
        <Text style={styles.sectionTitle}>Phân tích chi tiêu thông minh</Text>

        <View style={styles.analysisCard}>
          <View style={styles.analysisHeader}>
            <Text style={styles.analysisTitle}>Tình hình tổng quan</Text>
            <Text style={styles.analysisPercentage}>{spentPercentage.toFixed(1)}%</Text>
          </View>
          <View style={styles.analysisProgressBar}>
            <Animated.View
              style={[
                styles.analysisProgressFill,
                {
                  transform: [
                    {
                      scaleX: animationValue.interpolate({
                        inputRange: [0, 1],
                        outputRange: [0, Math.min(spentPercentage / 100, 1)],
                      }),
                    },
                  ],
                  backgroundColor: spentPercentage > 80 ? '#FF6B6B' : Colors.primary[500],
                },
              ]}
            />
          </View>
          <Text style={styles.analysisText}>
            Đã chi {formatCurrency(totalSpent)} / {formatCurrency(budgetData.totalAmount)}
          </Text>
        </View>

        <View style={styles.insightsContainer}>
          <Text style={styles.insightsTitle}>Đề xuất từ AI</Text>

          {budgetData.categories
            .filter(cat => cat.spentAmount / cat.allocatedAmount > 0.8)
            .map(category => (
              <View key={category.category} style={styles.insightCard}>
                <Text style={styles.insightIcon}>⚠️</Text>
                <View style={styles.insightContent}>
                  <Text style={styles.insightTitle}>
                    {getCategoryName(category.category)} sắp vượt ngân sách
                  </Text>
                  <Text style={styles.insightText}>
                    Đã chi {((category.spentAmount / category.allocatedAmount) * 100).toFixed(0)}%.
                    Hãy cân nhắc giảm chi tiêu hoặc tăng ngân sách.
                  </Text>
                </View>
              </View>
            ))}

          <View style={styles.insightCard}>
            <Text style={styles.insightIcon}>💡</Text>
            <View style={styles.insightContent}>
              <Text style={styles.insightTitle}>Mẹo tiết kiệm cho mùa Tết</Text>
              <Text style={styles.insightText}>
                Chuẩn bị danh sách mua sắm cụ thể và so sánh giá ở nhiều nơi để tiết kiệm 15-20%.
              </Text>
            </View>
          </View>
        </View>
      </View>
    );
  };

  const renderSavingsGoals = () => {
    return (
      <View style={styles.goalsSection}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>AI Savings Goals</Text>
          <TouchableOpacity
            style={styles.viewAllButton}
            onPress={() => navigation.navigate('SavingsGoals' as never)}
          >
            <Text style={styles.viewAllText}>View All</Text>
            <Ionicons name="arrow-forward" size={16} color={Colors.primary[500]} />
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          style={styles.goalCard}
          onPress={() => navigation.navigate('SavingsGoals' as never)}
        >
          <LinearGradient
            colors={['#007AFF', '#0056CC']}
            style={styles.goalGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            <View style={styles.goalHeader}>
              <Text style={styles.goalIcon}>📱</Text>
              <View style={styles.goalInfo}>
                <Text style={styles.goalName}>iPhone 15 Pro Max</Text>
                <Text style={styles.goalTarget}>Target: {formatCurrency(25000000)}</Text>
              </View>
              <View style={styles.aiPredictionBadge}>
                <Ionicons name="bulb" size={12} color="#FFD700" />
                <Text style={styles.aiPredictionText}>78%</Text>
              </View>
            </View>

            <View style={styles.goalProgress}>
              <View style={styles.goalProgressBar}>
                <Animated.View
                  style={[
                    styles.goalProgressFill,
                    {
                      transform: [
                        {
                          scaleX: animationValue.interpolate({
                            inputRange: [0, 1],
                            outputRange: [0, 0.34],
                            extrapolate: 'clamp',
                          }),
                        },
                      ],
                    },
                  ]}
                />
              </View>
              <Text style={styles.goalProgressText}>
                {formatCurrency(8500000)} / {formatCurrency(25000000)} (34%)
              </Text>
            </View>

            <View style={styles.aiSuggestionContainer}>
              <View style={styles.aiSuggestionHeader}>
                <Ionicons name="bulb" size={14} color={Colors.primary[500]} />
                <Text style={styles.aiSuggestionTitle}>AI Recommendation</Text>
              </View>
              <Text style={styles.goalSuggestionText}>
                Reduce food delivery by 30% to save {formatCurrency(450000)}/month
              </Text>
              <View style={styles.suggestionActions}>
                <TouchableOpacity style={styles.suggestionButton}>
                  <Text style={styles.suggestionButtonText}>Apply</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.suggestionButton}>
                  <Text style={styles.suggestionButtonText}>More Tips</Text>
                </TouchableOpacity>
              </View>
            </View>
          </LinearGradient>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.addGoalButton}
          onPress={() => navigation.navigate('SavingsGoals' as never)}
        >
          <Ionicons name="add-circle-outline" size={24} color={Colors.primary[500]} />
          <Text style={styles.addGoalText}>Create AI-Powered Savings Goal</Text>
        </TouchableOpacity>
      </View>
    );
  };

  const renderTabSelector = () => (
    <View style={styles.tabSelector}>
      {[
        { id: 'planner', label: 'Lập kế hoạch', icon: 'options' },
        { id: 'analysis', label: 'Phân tích', icon: 'analytics' },
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

  if (!budgetData) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Đang tải...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <BackButton
        title={budgetData.name}
        rightComponent={
          <View style={styles.headerActions}>
            <TouchableOpacity
              style={styles.aiChatButton}
              onPress={() => (navigation as any).navigate('Home', { screen: 'Chat' })}
            >
              <Ionicons name="chatbubble-ellipses" size={18} color="#FFFFFF" />
              <Text style={styles.aiChatText}>AI</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.moreButton}>
              <Ionicons name="ellipsis-horizontal" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        }
      />
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Budget Overview */}
        <Animated.View
          style={[
            styles.overviewCard,
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
            style={styles.overviewGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            <Text style={styles.overviewTitle}>Tổng ngân sách</Text>
            <Text style={styles.overviewAmount}>{formatCurrency(budgetData.totalAmount)}</Text>
            <Text style={styles.overviewSubtitle}>
              {((budgetData.totalAmount / budgetData.monthlyIncome) * 100).toFixed(1)}% thu nhập
              hàng tháng
            </Text>
          </LinearGradient>
        </Animated.View>

        {/* Tab Selector */}
        {renderTabSelector()}

        {/* Content based on selected tab */}
        {selectedTab === 'planner' && renderInteractivePlanner()}
        {selectedTab === 'analysis' && renderAnalysis()}
        {selectedTab === 'goals' && renderSavingsGoals()}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1A2E3A',
  },
  loadingText: {
    color: '#FFFFFF',
    fontSize: 16,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  aiChatButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 14,
    gap: 4,
  },
  aiChatText: {
    fontSize: 11,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  moreButton: {
    marginLeft: 8,
  },
  overviewCard: {
    marginHorizontal: 20,
    marginBottom: 20,
    borderRadius: 16,
    overflow: 'hidden',
  },
  overviewGradient: {
    padding: 20,
    alignItems: 'center',
  },
  overviewTitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  overviewAmount: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  overviewSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  tabSelector: {
    flexDirection: 'row',
    marginHorizontal: 20,
    marginBottom: 20,
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
  plannerSection: {
    paddingHorizontal: 20,
  },
  plannerHeader: {
    marginBottom: 20,
  },
  plannerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  plannerSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 12,
  },
  editButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    alignSelf: 'flex-start',
    gap: 4,
  },
  editButtonText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  incomeInfo: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    alignItems: 'center',
  },
  incomeLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  incomeAmount: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  budgetRatio: {
    fontSize: 12,
    color: Colors.primary[500],
  },
  categorySlider: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  categorySliderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  categorySliderInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  categorySliderIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  categorySliderText: {
    flex: 1,
  },
  categorySliderName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  categorySliderAmount: {
    fontSize: 14,
    color: Colors.primary[500],
  },
  priorityBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  priorityText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  sliderContainer: {
    marginBottom: 12,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  sliderLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: -10,
  },
  sliderLabel: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  categoryProgress: {
    marginTop: 8,
  },
  progressBarContainer: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 3,
    marginBottom: 6,
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  progressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'right',
  },
  budgetSummary: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginTop: 8,
  },
  summaryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  analysisSection: {
    paddingHorizontal: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  analysisCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  analysisHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  analysisTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  analysisPercentage: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  analysisProgressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 4,
    marginBottom: 8,
  },
  analysisProgressFill: {
    height: '100%',
    borderRadius: 4,
    width: '100%',
    transformOrigin: 'left',
  },
  analysisText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  insightsContainer: {
    marginTop: 8,
  },
  insightsTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  insightCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  insightIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  insightContent: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  insightText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 16,
  },
  goalsSection: {
    paddingHorizontal: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  viewAllText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  aiPredictionBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 215, 0, 0.2)',
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 8,
    gap: 2,
  },
  aiPredictionText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#FFD700',
  },
  aiSuggestionContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 12,
    marginTop: 12,
  },
  aiSuggestionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
    gap: 6,
  },
  aiSuggestionTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.primary[500],
  },
  suggestionActions: {
    flexDirection: 'row',
    marginTop: 8,
    gap: 8,
  },
  suggestionButton: {
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  suggestionButtonText: {
    fontSize: 10,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  goalCard: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 16,
  },
  goalGradient: {
    padding: 20,
  },
  goalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  goalIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  goalInfo: {
    flex: 1,
  },
  goalName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  goalTarget: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  goalProgress: {
    marginBottom: 12,
  },
  goalProgressBar: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 3,
    marginBottom: 8,
    width: '100%',
  },
  goalProgressFill: {
    height: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  goalProgressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.9)',
    textAlign: 'right',
  },
  goalSuggestion: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 12,
  },
  goalSuggestionText: {
    fontSize: 12,
    color: '#FFFFFF',
    lineHeight: 16,
  },
  addGoalButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
    gap: 8,
  },
  addGoalText: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
});

export default BudgetDetailScreen;
