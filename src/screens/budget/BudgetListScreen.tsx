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
import type { StackNavigationProp } from '@react-navigation/stack';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

import { Colors } from '../../constants/colors';
import { BudgetPeriod, ExpenseCategory, BudgetStackParamList } from '../../types';
import { BackButton, CustomAlert } from '../../components';

type BudgetListNavigationProp = StackNavigationProp<BudgetStackParamList, 'BudgetList'>;

const { width: screenWidth } = Dimensions.get('window');

interface BudgetItem {
  id: string;
  name: string;
  totalAmount: number;
  spentAmount: number;
  period: BudgetPeriod;
  isActive: boolean;
  createdAt: string;
  categories: number;
  icon: string;
  color: string;
}

interface SavingsGoal {
  id: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: string;
  category: string;
  icon: string;
  color: string;
  weeklyNeeded: number;
  monthlyNeeded: number;
}

const BudgetListScreen: React.FC = () => {
  const navigation = useNavigation<BudgetListNavigationProp>();
  const [selectedTab, setSelectedTab] = useState<'budgets' | 'goals'>('budgets');
  const [animationValue] = useState(new Animated.Value(0));
  const [showGoalAlert, setShowGoalAlert] = useState(false);
  const [selectedGoal, setSelectedGoal] = useState<SavingsGoal | null>(null);

  useEffect(() => {
    Animated.timing(animationValue, {
      toValue: 1,
      duration: 1000,
      useNativeDriver: false,
    }).start();
  }, []);

  // Vietnamese budget data for investors to understand
  const mockBudgets: BudgetItem[] = [
    {
      id: '1',
      name: 'Ngân sách Tháng 12 - Chuẩn bị Tết',
      totalAmount: 12000000,
      spentAmount: 7800000,
      period: BudgetPeriod.MONTHLY,
      isActive: true,
      createdAt: '2025-07-01',
      categories: 5,
      icon: '🧧',
      color: '#FF6B6B',
    },
    {
      id: '2',
      name: 'Sinh viên - Học kỳ 1',
      totalAmount: 3500000,
      spentAmount: 2100000,
      period: BudgetPeriod.MONTHLY,
      isActive: true,
      createdAt: '2025-06-15',
      categories: 4,
      icon: '🎓',
      color: '#4ECDC4',
    },
    {
      id: '3',
      name: 'Gia đình 4 người',
      totalAmount: 18000000,
      spentAmount: 12500000,
      period: BudgetPeriod.MONTHLY,
      isActive: false,
      createdAt: '2025-05-20',
      categories: 6,
      icon: '👨‍👩‍👧‍👦',
      color: '#45B7D1',
    },
    {
      id: '4',
      name: 'Freelancer - Q4',
      totalAmount: 25000000,
      spentAmount: 18200000,
      period: BudgetPeriod.QUARTERLY,
      isActive: true,
      createdAt: '2025-04-01',
      categories: 7,
      icon: '💼',
      color: '#96CEB4',
    },
  ];

  // Savings goals inspired by popular Vietnamese financial goals
  const mockSavingsGoals: SavingsGoal[] = [
    {
      id: '1',
      name: 'Mua iPhone 15 Pro Max',
      targetAmount: 25000000,
      currentAmount: 8500000,
      targetDate: '2025-12-31',
      category: 'Công nghệ',
      icon: '📱',
      color: '#007AFF',
      weeklyNeeded: 660000,
      monthlyNeeded: 2650000,
    },
    {
      id: '2',
      name: 'Du lịch Hàn Quốc',
      targetAmount: 35000000,
      currentAmount: 12000000,
      targetDate: '2026-06-01',
      category: 'Du lịch',
      icon: '✈️',
      color: '#FF6B6B',
      weeklyNeeded: 520000,
      monthlyNeeded: 2080000,
    },
    {
      id: '3',
      name: 'Mua Honda Vision',
      targetAmount: 32000000,
      currentAmount: 15000000,
      targetDate: '2025-10-15',
      category: 'Phương tiện',
      icon: '🛵',
      color: '#FFD700',
      weeklyNeeded: 850000,
      monthlyNeeded: 3400000,
    },
    {
      id: '4',
      name: 'Quỹ cưới hỏi',
      targetAmount: 150000000,
      currentAmount: 45000000,
      targetDate: '2026-12-31',
      category: 'Gia đình',
      icon: '💒',
      color: '#FF69B4',
      weeklyNeeded: 1350000,
      monthlyNeeded: 5250000,
    },
  ];

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const getTimeRemaining = (targetDate: string) => {
    const target = new Date(targetDate);
    const now = new Date();
    const diffTime = target.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    const diffMonths = Math.ceil(diffDays / 30);

    if (diffDays < 30) return `${diffDays} ngày`;
    return `${diffMonths} tháng`;
  };

  const renderBudgetItem = ({ item }: { item: BudgetItem }) => {
    const progressPercentage = (item.spentAmount / item.totalAmount) * 100;
    const isOverBudget = progressPercentage > 100;

    return (
      <TouchableOpacity
        style={[styles.budgetCard, !item.isActive && styles.inactiveBudgetCard]}
        onPress={() => navigation.navigate('BudgetDetail', { budgetId: item.id })}
      >
        <LinearGradient
          colors={item.isActive ? [item.color, `${item.color}CC`] : ['#4A5568', '#2D3748']}
          style={styles.budgetGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.budgetHeader}>
            <View style={styles.budgetInfo}>
              <Text style={styles.budgetIcon}>{item.icon}</Text>
              <View style={styles.budgetTitleSection}>
                <Text style={styles.budgetName}>{item.name}</Text>
                <Text style={styles.budgetMeta}>
                  {item.categories} danh mục •{' '}
                  {item.period === BudgetPeriod.MONTHLY
                    ? 'Hàng tháng'
                    : item.period === BudgetPeriod.QUARTERLY
                      ? 'Hàng quý'
                      : 'Hàng năm'}
                </Text>
              </View>
            </View>
            {!item.isActive && (
              <View style={styles.inactiveLabel}>
                <Text style={styles.inactiveLabelText}>Tạm dừng</Text>
              </View>
            )}
          </View>

          <View style={styles.budgetAmount}>
            <Text style={styles.spentAmount}>{formatCurrency(item.spentAmount)}</Text>
            <Text style={styles.totalAmount}>/ {formatCurrency(item.totalAmount)}</Text>
          </View>

          <View style={styles.progressSection}>
            <View style={styles.progressBar}>
              <Animated.View
                style={[
                  styles.progressFill,
                  {
                    transform: [
                      {
                        scaleX: animationValue.interpolate({
                          inputRange: [0, 1],
                          outputRange: [0, Math.min(progressPercentage / 100, 1)],
                        }),
                      },
                    ],
                    backgroundColor: isOverBudget ? '#FF4444' : '#FFFFFF',
                  },
                ]}
              />
            </View>
            <View style={styles.progressInfo}>
              <Text style={styles.progressText}>{Math.round(progressPercentage)}% đã sử dụng</Text>
              <Text style={styles.remainingText}>
                Còn {formatCurrency(Math.max(0, item.totalAmount - item.spentAmount))}
              </Text>
            </View>
          </View>
        </LinearGradient>
      </TouchableOpacity>
    );
  };

  const renderSavingsGoal = ({ item }: { item: SavingsGoal }) => {
    const progressPercentage = (item.currentAmount / item.targetAmount) * 100;
    const timeRemaining = getTimeRemaining(item.targetDate);

    return (
      <TouchableOpacity
        style={styles.goalCard}
        onPress={() => {
          setSelectedGoal(item);
          setShowGoalAlert(true);
        }}
      >
        <View style={styles.goalHeader}>
          <View style={styles.goalInfo}>
            <View style={[styles.goalIcon, { backgroundColor: item.color }]}>
              <Text style={styles.goalIconText}>{item.icon}</Text>
            </View>
            <View style={styles.goalTitleSection}>
              <Text style={styles.goalName}>{item.name}</Text>
              <Text style={styles.goalCategory}>
                {item.category} • {timeRemaining} nữa
              </Text>
            </View>
          </View>
          <TouchableOpacity style={styles.goalMenu}>
            <Ionicons name="ellipsis-horizontal" size={20} color="rgba(255,255,255,0.7)" />
          </TouchableOpacity>
        </View>

        <View style={styles.goalAmount}>
          <Text style={styles.goalCurrentAmount}>{formatCurrency(item.currentAmount)}</Text>
          <Text style={styles.goalTargetAmount}>/ {formatCurrency(item.targetAmount)}</Text>
        </View>

        <View style={styles.goalProgress}>
          <View style={styles.goalProgressBar}>
            <Animated.View
              style={[
                styles.goalProgressFill,
                {
                  width: animationValue.interpolate({
                    inputRange: [0, 1],
                    outputRange: ['0%', `${progressPercentage}%`],
                  }),
                  backgroundColor: item.color,
                },
              ]}
            />
          </View>
          <Text style={styles.goalProgressText}>{Math.round(progressPercentage)}% hoàn thành</Text>
        </View>

        <View style={styles.goalSuggestions}>
          <View style={styles.suggestionItem}>
            <Text style={styles.suggestionLabel}>Cần tiết kiệm/tuần:</Text>
            <Text style={styles.suggestionAmount}>{formatCurrency(item.weeklyNeeded)}</Text>
          </View>
          <View style={styles.suggestionItem}>
            <Text style={styles.suggestionLabel}>Cần tiết kiệm/tháng:</Text>
            <Text style={styles.suggestionAmount}>{formatCurrency(item.monthlyNeeded)}</Text>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const renderQuickStats = () => {
    const activeBudgets = mockBudgets.filter(b => b.isActive);
    const totalBudget = activeBudgets.reduce((sum, b) => sum + b.totalAmount, 0);
    const totalSpent = activeBudgets.reduce((sum, b) => sum + b.spentAmount, 0);
    const totalGoalsTarget = mockSavingsGoals.reduce((sum, g) => sum + g.targetAmount, 0);
    const totalGoalsCurrent = mockSavingsGoals.reduce((sum, g) => sum + g.currentAmount, 0);

    return (
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
          <Ionicons name="wallet" size={24} color={Colors.primary[500]} />
          <Text style={styles.statValue}>{formatCurrency(totalBudget)}</Text>
          <Text style={styles.statLabel}>Tổng ngân sách</Text>
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
          <Ionicons name="trending-down" size={24} color="#FF6B6B" />
          <Text style={styles.statValue}>{formatCurrency(totalSpent)}</Text>
          <Text style={styles.statLabel}>Đã chi tiêu</Text>
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
          <Ionicons name="flag" size={24} color="#FFD700" />
          <Text style={styles.statValue}>{formatCurrency(totalGoalsCurrent)}</Text>
          <Text style={styles.statLabel}>Tiến độ mục tiêu</Text>
        </Animated.View>
      </View>
    );
  };

  const renderTabSelector = () => (
    <View style={styles.tabSelector}>
      <TouchableOpacity
        style={[styles.tabButton, selectedTab === 'budgets' && styles.activeTabButton]}
        onPress={() => setSelectedTab('budgets')}
      >
        <Ionicons
          name="wallet"
          size={20}
          color={selectedTab === 'budgets' ? '#FFFFFF' : Colors.primary[500]}
        />
        <Text
          style={[styles.tabButtonText, selectedTab === 'budgets' && styles.activeTabButtonText]}
        >
          Ngân sách
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.tabButton, selectedTab === 'goals' && styles.activeTabButton]}
        onPress={() => setSelectedTab('goals')}
      >
        <Ionicons
          name="flag"
          size={20}
          color={selectedTab === 'goals' ? '#FFFFFF' : Colors.primary[500]}
        />
        <Text style={[styles.tabButtonText, selectedTab === 'goals' && styles.activeTabButtonText]}>
          Mục tiêu tiết kiệm
        </Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <BackButton title="Quản lý tài chính thông minh" showHomeIcon={true} />
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Quick Stats */}
        {renderQuickStats()}

        {/* Tab Selector */}
        {renderTabSelector()}

        {/* Content based on selected tab */}
        {selectedTab === 'budgets' ? (
          <View style={styles.budgetsSection}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Danh sách ngân sách</Text>
              <Text style={styles.sectionSubtitle}>
                {mockBudgets.filter(b => b.isActive).length} ngân sách đang hoạt động
              </Text>
            </View>

            <FlatList
              data={mockBudgets}
              renderItem={renderBudgetItem}
              keyExtractor={item => item.id}
              scrollEnabled={false}
              contentContainerStyle={styles.budgetsList}
              showsVerticalScrollIndicator={false}
            />
          </View>
        ) : (
          <View style={styles.goalsSection}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Mục tiêu tiết kiệm</Text>
              <Text style={styles.sectionSubtitle}>
                {mockSavingsGoals.length} mục tiêu đang theo dõi
              </Text>
            </View>

            <FlatList
              data={mockSavingsGoals}
              renderItem={renderSavingsGoal}
              keyExtractor={item => item.id}
              scrollEnabled={false}
              contentContainerStyle={styles.goalsList}
              showsVerticalScrollIndicator={false}
            />
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.primaryActionButton}
            onPress={() => navigation.navigate('CreateBudget')}
          >
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.primaryActionGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Ionicons name="add-circle" size={20} color="#FFFFFF" />
              <Text style={styles.primaryActionText}>
                {selectedTab === 'budgets' ? 'Tạo ngân sách mới' : 'Thêm mục tiêu mới'}
              </Text>
            </LinearGradient>
          </TouchableOpacity>

          <View style={styles.secondaryActions}>
            <TouchableOpacity style={styles.secondaryActionButton}>
              <Ionicons name="analytics" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Phân tích</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryActionButton}>
              <Ionicons name="download" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Xuất báo cáo</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.secondaryActionButton}>
              <Ionicons name="settings" size={18} color={Colors.primary[500]} />
              <Text style={styles.secondaryActionText}>Cài đặt</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>

      {/* Custom Alert for Savings Goal Details */}
      <CustomAlert
        visible={showGoalAlert}
        onClose={() => setShowGoalAlert(false)}
        title={selectedGoal ? `${selectedGoal.icon} ${selectedGoal.name}` : 'Chi tiết mục tiêu'}
        message={
          selectedGoal
            ? `🎯 Mục tiêu: ${formatCurrency(selectedGoal.targetAmount)}\n💰 Đã tiết kiệm: ${formatCurrency(selectedGoal.currentAmount)}\n📅 Thời hạn: ${selectedGoal.targetDate}\n\n📈 Tiến độ: ${Math.round((selectedGoal.currentAmount / selectedGoal.targetAmount) * 100)}%\n\n💡 Gợi ý tiết kiệm:\n• Hàng tuần: ${formatCurrency(selectedGoal.weeklyNeeded)}\n• Hàng tháng: ${formatCurrency(selectedGoal.monthlyNeeded)}`
            : ''
        }
        type="info"
        buttons={[
          {
            text: 'Đóng',
            onPress: () => setShowGoalAlert(false),
            type: 'secondary',
            icon: 'close-outline',
          },
          {
            text: 'Chỉnh sửa',
            onPress: () => {
              setShowGoalAlert(false);
              // Navigate to edit goal screen
            },
            type: 'primary',
            icon: 'create-outline',
          },
        ]}
      />
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
    backgroundColor: '#1A2E3A',
  },
  headerLeft: {
    flex: 1,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  headerSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 4,
  },
  addButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
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
    paddingVertical: 16,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
  },
  statValue: {
    fontSize: 14,
    color: '#FFFFFF',
    marginTop: 6,
    marginBottom: 4,
    fontWeight: 'bold',
  },
  statLabel: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
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
    paddingVertical: 12,
    borderRadius: 8,
    gap: 8,
  },
  activeTabButton: {
    backgroundColor: Colors.primary[500],
  },
  tabButtonText: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  activeTabButtonText: {
    color: '#FFFFFF',
  },
  sectionHeader: {
    paddingHorizontal: 20,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    color: '#FFFFFF',
    fontWeight: 'bold',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  budgetsSection: {
    marginBottom: 20,
  },
  budgetsList: {
    paddingHorizontal: 20,
  },
  budgetCard: {
    marginBottom: 16,
    borderRadius: 16,
    overflow: 'hidden',
  },
  inactiveBudgetCard: {
    opacity: 0.7,
  },
  budgetGradient: {
    padding: 20,
  },
  budgetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  budgetInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  budgetIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  budgetTitleSection: {
    flex: 1,
  },
  budgetName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: 'bold',
    marginBottom: 4,
  },
  budgetMeta: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  inactiveLabel: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  inactiveLabelText: {
    fontSize: 10,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  budgetAmount: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 16,
  },
  spentAmount: {
    fontSize: 24,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  totalAmount: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    marginLeft: 4,
  },
  progressSection: {
    marginTop: 8,
  },
  progressBar: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 3,
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  progressInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  progressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.9)',
    fontWeight: '500',
  },
  remainingText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.9)',
    fontWeight: '500',
  },
  goalsSection: {
    marginBottom: 20,
  },
  goalsList: {
    paddingHorizontal: 20,
  },
  goalCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  goalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  goalInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  goalIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  goalIconText: {
    fontSize: 20,
  },
  goalTitleSection: {
    flex: 1,
  },
  goalName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: 'bold',
    marginBottom: 4,
  },
  goalCategory: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  goalMenu: {
    padding: 4,
  },
  goalAmount: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 16,
  },
  goalCurrentAmount: {
    fontSize: 20,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  goalTargetAmount: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginLeft: 4,
  },
  goalProgress: {
    marginBottom: 16,
  },
  goalProgressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 4,
    marginBottom: 8,
  },
  goalProgressFill: {
    height: '100%',
    borderRadius: 4,
  },
  goalProgressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'right',
  },
  goalSuggestions: {
    gap: 8,
  },
  suggestionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  suggestionLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  suggestionAmount: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  actionsContainer: {
    paddingHorizontal: 20,
    paddingBottom: 40,
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

export default BudgetListScreen;
