import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
  Animated,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../../constants/colors';
import { useApp } from '../../context/AppContext';
import { CustomAlert, NotificationList, BudgetSavingsCard, LoadingState } from '../../components';
import BudgetSavingsService from '../../services/BudgetSavingsService';
import StorageService from '../../services/StorageService';
import { formatCurrency } from '../../utils/formatters';
import { VietnameseText } from '../../constants/vietnamese';

const DashboardScreen: React.FC = () => {
  const navigation = useNavigation();
  const { logout, state } = useApp();

  // Student-focused financial data (lower amounts for Vietnamese students)
  const [monthlyAllowance] = useState(3000000); // 3M VND monthly from family
  const [totalExpense] = useState(2200000); // 2.2M VND monthly expenses
  const [currentBalance] = useState(800000); // 800K VND remaining
  const [selectedPeriod] = useState('Tháng này');
  const [userName] = useState(state.user?.name || 'Người dùng');
  const [studentYear] = useState('Năm 2'); // Second year student
  const [university] = useState('ĐH Bách Khoa'); // University name
  const [progressAnimation] = useState(new Animated.Value(0));
  const [insightAnimation] = useState(new Animated.Value(0));
  const [showLogoutAlert, setShowLogoutAlert] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [showNotificationList, setShowNotificationList] = useState(false);
  const [showAutoAllocateAlert, setShowAutoAllocateAlert] = useState(false);
  const [isAutoAllocating, setIsAutoAllocating] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingData, setIsLoadingData] = useState(false);

  // User-specific features
  const [savingsGoal] = useState(5000000); // 5M VND savings goal
  const [dailyBudget] = useState(100000); // 100K VND daily budget
  const [daysUntilExam] = useState(25); // Days until exam period
  const [upcomingEvent] = useState('Ngày lấy vợ'); // Upcoming event

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setIsLoading(true);
    try {
      // Simulate loading user data, budgets, expenses
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Animate progress bars and insights after data loads
      Animated.parallel([
        Animated.timing(progressAnimation, {
          toValue: 1,
          duration: 1000,
          useNativeDriver: false,
        }),
        Animated.timing(insightAnimation, {
          toValue: 1,
          duration: 800,
          useNativeDriver: true,
        }),
      ]).start();
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const formatCurrencyVND = (amount: number) => {
    return formatCurrency(amount);
  };

  // Student-specific smart insights
  const getStudentInsight = () => {
    const dailyAverage = totalExpense / 30;
    const remainingDays = 30 - new Date().getDate();
    const budgetRemaining = currentBalance / remainingDays;

    if (daysUntilExam <= 30 && daysUntilExam > 0) {
      return {
        icon: '📚',
        title: `${daysUntilExam} ngày đến ${upcomingEvent}`,
        message: `Ngân sách cho ${upcomingEvent} đã đầy!`,
        type: 'academic',
      };
    } else if (budgetRemaining < dailyBudget) {
      return {
        icon: '⚠️',
        title: 'Ngân sách thấp',
        message: `Chỉ còn ${formatCurrencyVND(budgetRemaining)}/ngày. Ăn cơm tại căng-tin hoặc nấu ăn tại nhà!`,
        type: 'warning',
      };
    } else if (dailyAverage < 80000) {
      return {
        icon: '🎉',
        title: 'Sinh viên tiết kiệm!',
        message: 'Chi tiêu dưới 80K/ngày - tuyệt vời! Tiếp tục duy trì thói quen này.',
        type: 'achievement',
      };
    } else if (new Date().getMonth() < 6) {
      // First half of year
      return {
        icon: '📖',
        title: 'Mẹo sinh viên năm học mới',
        message: 'Mua sách cũ, ăn cơm trường, đi xe bus để tiết kiệm tối đa!',
        type: 'tip',
      };
    } else {
      return {
        icon: '☕',
        title: 'Tiết kiệm cà phê',
        message: 'Sinh viên VN uống cà phê 2-3 lần/ngày. Thử cà phê pha máy trường để tiết kiệm!',
        type: 'tip',
      };
    }
  };

  // Student-specific quick amounts (lower prices for students)
  const getStudentQuickAmounts = () => [
    { amount: 15000, label: 'Cà phê trường' },
    { amount: 25000, label: 'Cơm căng tin' },
    { amount: 35000, label: 'Xe bus' },
    { amount: 50000, label: 'Sách photo' },
    { amount: 80000, label: 'Đồ ăn vặt' },
    { amount: 100000, label: 'Học phí ngắn hạn' },
  ];

  // Student-specific transaction history with realistic amounts and locations
  const studentTransactionHistory = [
    {
      id: '1',
      date: '26/06/2025',
      day: 'Thứ 5',
      description: 'Mua giáo trình',
      amount: -120000,
      balance: 800000,
      type: 'expense',
      category: 'education',
      icon: '📚',
      location: 'Nhà sách Trần Hưng Đạo',
    },
    {
      id: '2',
      date: '25/06/2025',
      day: 'Thứ 4',
      description: 'Tiền phụ cấp tháng',
      amount: 3000000,
      balance: 920000,
      type: 'income',
      category: 'allowance',
      icon: '👨‍👩‍👧‍👦',
      location: 'Chuyển khoản từ gia đình',
    },
    {
      id: '3',
      date: '24/06/2025',
      day: 'Thứ 3',
      description: 'Cơm căng tin trường',
      amount: -25000,
      balance: 480000,
      type: 'expense',
      category: 'food',
      icon: '🍽️',
      location: 'Căng tin ĐH Bách Khoa',
    },
    {
      id: '4',
      date: '23/06/2025',
      day: 'Thứ 2',
      description: 'Xe bus đến trường',
      amount: -7000,
      balance: 505000,
      type: 'expense',
      category: 'transport',
      icon: '🚌',
      location: 'Tuyến bus 32',
    },
    {
      id: '5',
      date: '22/06/2025',
      day: 'Chủ nhật',
      description: 'Gia sư toán lớp 9',
      amount: 200000,
      balance: 512000,
      type: 'income',
      category: 'part_time',
      icon: '🎓',
      location: 'Quận 1',
    },
    {
      id: '6',
      date: '21/06/2025',
      day: 'Thứ 7',
      description: 'Cà phê học nhóm',
      amount: -35000,
      balance: 312000,
      type: 'expense',
      category: 'education',
      icon: '☕',
      location: 'Highlands Coffee - Campus',
    },
  ];

  const renderTransactionItem = (transaction: any) => {
    return (
      <TouchableOpacity key={transaction.id} style={styles.transactionItem}>
        <View style={styles.transactionIcon}>
          <Text style={styles.transactionEmoji}>{transaction.icon}</Text>
        </View>
        <View style={styles.transactionContent}>
          <View style={styles.transactionLeft}>
            <Text style={styles.transactionDescription}>{transaction.description}</Text>
            <Text style={styles.transactionMeta}>
              {transaction.location} • {transaction.date} {transaction.day}
            </Text>
          </View>
          <View style={styles.transactionRight}>
            <Text
              style={[
                styles.transactionAmount,
                {
                  color: transaction.type === 'income' ? Colors.primary[500] : '#FF6B6B',
                },
              ]}
            >
              {transaction.amount > 0 ? '+' : ''}
              {formatCurrency(transaction.amount)}
            </Text>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const renderQuickAmount = (item: any) => (
    <TouchableOpacity
      key={item.amount}
      style={styles.quickAmountChip}
      onPress={() => navigation.navigate('AddExpense' as never)}
    >
      <Text style={styles.quickAmountLabel}>{item.label}</Text>
      <Text style={styles.quickAmountValue}>{formatCurrency(item.amount)}</Text>
    </TouchableOpacity>
  );

  const handleLogout = async () => {
    if (isLoggingOut) return;

    setIsLoggingOut(true);
    setShowLogoutAlert(false);

    try {
      await logout();
    } catch (error) {
      console.error('Logout error:', error);
      setIsLoggingOut(false);
    }
  };

  const handleAutoAllocate = async () => {
    setShowAutoAllocateAlert(true);
  };

  const confirmAutoAllocate = async () => {
    if (isAutoAllocating) return;

    setIsAutoAllocating(true);
    setShowAutoAllocateAlert(false);

    try {
      // Find active budget
      const budgets = await StorageService.getBudgets();
      const activeBudget = budgets.find(b => b.isActive);

      if (activeBudget) {
        await BudgetSavingsService.autoAllocateBudgetSurplus(activeBudget.id);
        // You might want to show a success message here
      }
    } catch (error) {
      console.error('Auto-allocate error:', error);
    } finally {
      setIsAutoAllocating(false);
    }
  };

  const savingsProgress = (currentBalance / savingsGoal) * 100;

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />

      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.greeting}>Xin chào {userName}! 👋</Text>
            <TouchableOpacity style={styles.periodSelector}>
              <Text style={styles.periodText}>{selectedPeriod}</Text>
              <Ionicons name="chevron-down" size={16} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={styles.notificationButton}
            onPress={() => setShowNotificationList(true)}
          >
            <Ionicons name="notifications" size={24} color="#FFFFFF" />
            <View style={styles.notificationBadge}>
              <Text style={styles.notificationBadgeText}>3</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Budget-Savings Integration Card */}
        <BudgetSavingsCard
          userId={state.user?.id || ''}
          onNavigateToBudget={() => navigation.navigate('BudgetList' as never)}
          onNavigateToSavings={() => navigation.navigate('SavingsGoals' as never)}
          onAutoAllocate={handleAutoAllocate}
        />

        {/* Student Smart Insight Card */}
        <Animated.View style={[styles.insightCard, { opacity: insightAnimation }]}>
          <View style={styles.insightContent}>
            <Text style={styles.insightIcon}>{getStudentInsight().icon}</Text>
            <View style={styles.insightText}>
              <Text style={styles.insightTitle}>{getStudentInsight().title}</Text>
              <Text style={styles.insightMessage}>{getStudentInsight().message}</Text>
            </View>
          </View>
        </Animated.View>

        {/* Student Balance Card with Daily Budget */}
        <LinearGradient
          colors={[Colors.primary[500], '#2E8B57']}
          style={styles.balanceCard}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
        >
          <View style={styles.balanceHeader}>
            <Text style={styles.balanceLabel}>Số dư tháng này</Text>
            <Text style={styles.balanceAmount}>{formatCurrency(currentBalance)}</Text>
            <Text style={styles.dailyBudgetText}>
              Ngân sách hàng ngày: {formatCurrency(dailyBudget)}
            </Text>
          </View>

          <View style={styles.savingsProgress}>
            <View style={styles.progressInfo}>
              <Text style={styles.progressLabel}>Mục tiêu tiết kiệm</Text>
              <Text style={styles.progressPercentage}>
                {((currentBalance / savingsGoal) * 100).toFixed(0)}%
              </Text>
            </View>
            <View style={styles.progressBarContainer}>
              <Animated.View
                style={[
                  styles.progressBarFill,
                  {
                    width: progressAnimation.interpolate({
                      inputRange: [0, 1],
                      outputRange: ['0%', `${(currentBalance / savingsGoal) * 100}%`],
                    }),
                  },
                ]}
              />
            </View>
            <Text style={styles.progressTarget}>Mục tiêu: {formatCurrency(savingsGoal)}</Text>
          </View>
        </LinearGradient>

        {/* Student Income and Expense Summary */}
        <View style={styles.summaryContainer}>
          <View style={styles.summaryCard}>
            <View style={styles.summaryIcon}>
              <Ionicons name="wallet" size={20} color={Colors.primary[500]} />
            </View>
            <Text style={styles.summaryLabel}>Thu nhập tháng</Text>
            <Text style={styles.summaryAmount}>{formatCurrency(monthlyAllowance)}</Text>
            {/* <Text style={styles.summaryChange}>Từ gia đình</Text> */}
          </View>

          <View style={styles.summaryCard}>
            <View style={styles.summaryIcon}>
              <Ionicons name="trending-down" size={20} color="#FF6B6B" />
            </View>
            <Text style={styles.summaryLabel}>Đã chi</Text>
            <Text style={styles.summaryAmount}>{formatCurrency(totalExpense)}</Text>
            <Text style={styles.summaryChange}>
              {((totalExpense / monthlyAllowance) * 100).toFixed(0)}% thu nhập
            </Text>
          </View>
        </View>

        {/* Student Quick Amount Suggestions */}

        {/* Enhanced Quick Actions */}
        <View style={styles.quickActionsContainer}>
          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('AddExpense' as never)}
          >
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.quickActionGradient}
            >
              <Ionicons name="add" size={24} color="#FFFFFF" />
            </LinearGradient>
            <Text style={styles.quickActionText}>Thêm chi tiêu</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('AddIncome' as never)}
          >
            <LinearGradient colors={['#4CAF50', '#2E7D32']} style={styles.quickActionGradient}>
              <Ionicons name="trending-up" size={24} color="#FFFFFF" />
            </LinearGradient>
            <Text style={styles.quickActionText}>Thu nhập</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('BudgetList' as never)}
          >
            <View style={styles.quickActionCircle}>
              <Ionicons name="pie-chart" size={24} color={Colors.primary[500]} />
            </View>
            <Text style={styles.quickActionText}>Ngân sách</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('Reports' as never)}
          >
            <View style={styles.quickActionCircle}>
              <Ionicons name="bar-chart" size={24} color={Colors.primary[500]} />
            </View>
            <Text style={styles.quickActionText}>Báo cáo</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('SavingsGoals' as never)}
          >
            <LinearGradient colors={['#FFD700', '#FFA500']} style={styles.quickActionGradient}>
              <Ionicons name="bulb" size={24} color="#FFFFFF" />
            </LinearGradient>
            <Text style={styles.quickActionText}>AI Goals</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.quickAction}
            onPress={() => navigation.navigate('Profile' as never)}
          >
            <View style={styles.quickActionCircle}>
              <Ionicons name="person" size={24} color={Colors.primary[500]} />
            </View>
            <Text style={styles.quickActionText}>Profile</Text>
          </TouchableOpacity>
        </View>

        {/* Additional Features Section */}
        <View style={styles.featuresSection}>
          <Text style={styles.sectionTitle}>Thêm tính năng</Text>

          <View style={styles.featuresContainer}>
            <TouchableOpacity
              style={styles.featureCard}
              onPress={() => navigation.navigate('GroupList' as never)}
            >
              <View style={styles.featureIcon}>
                <Ionicons name="people" size={24} color="#FF6B6B" />
              </View>
              <Text style={styles.featureTitle}>Nhóm</Text>
              <Text style={styles.featureSubtitle}>Chia sẻ chi phí</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.featureCard}
              onPress={() => navigation.navigate('Challenge' as never)}
            >
              <View style={styles.featureIcon}>
                <Ionicons name="trophy" size={24} color="#FFEAA7" />
              </View>
              <Text style={styles.featureTitle}>Thử thách</Text>
              <Text style={styles.featureSubtitle}>Tiết kiệm vui</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.featureCard}
              onPress={() => navigation.navigate('Settings' as never)}
            >
              <View style={styles.featureIcon}>
                <Ionicons name="settings" size={24} color="#A29BFE" />
              </View>
              <Text style={styles.featureTitle}>Cài đặt</Text>
              <Text style={styles.featureSubtitle}>Tùy chỉnh app</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.featureCard}
              onPress={() => navigation.navigate('Premium' as never)}
            >
              <View style={styles.featureIcon}>
                <Ionicons name="diamond" size={24} color="#E17055" />
              </View>
              <Text style={styles.featureTitle}>Premium</Text>
              <Text style={styles.featureSubtitle}>Nâng cấp</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Enhanced Transaction History */}
        <View style={styles.historySection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Giao dịch gần đây</Text>
            <TouchableOpacity onPress={() => navigation.navigate('TransactionHistory' as never)}>
              <Text style={styles.seeAllText}>Xem tất cả</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.transactionList}>
            {studentTransactionHistory.slice(0, 4).map(renderTransactionItem)}
          </View>
        </View>

        <View style={styles.bottomSpacing} />

        {/* Logout Button */}
        <View style={styles.logoutContainer}>
          <TouchableOpacity style={styles.logoutButton} onPress={() => setShowLogoutAlert(true)}>
            <Ionicons name="log-out" size={20} color="#FF6B6B" />
            <Text style={styles.logoutText}>Đăng xuất</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* Logout Confirmation Alert */}
      <CustomAlert
        visible={showLogoutAlert}
        onClose={() => setShowLogoutAlert(false)}
        title="Đăng xuất"
        message="Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?"
        type="warning"
        buttons={[
          {
            text: 'Hủy',
            onPress: () => setShowLogoutAlert(false),
            type: 'secondary',
            icon: 'close-outline',
          },
          {
            text: isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
            onPress: handleLogout,
            type: 'danger',
            icon: 'log-out-outline',
          },
        ]}
      />

      {/* Auto Allocate Confirmation */}
      <CustomAlert
        visible={showAutoAllocateAlert}
        onClose={() => setShowAutoAllocateAlert(false)}
        title="Tự động phân bổ tiết kiệm"
        message="Hệ thống sẽ tự động chuyển tiền thừa từ ngân sách vào các mục tiêu tiết kiệm theo độ ưu tiên. Bạn có đồng ý?"
        type="info"
        buttons={[
          {
            text: 'Hủy',
            onPress: () => setShowAutoAllocateAlert(false),
            type: 'secondary',
            icon: 'close-outline',
          },
          {
            text: isAutoAllocating ? 'Đang xử lý...' : 'Đồng ý',
            onPress: confirmAutoAllocate,
            type: 'primary',
            icon: 'checkmark-outline',
          },
        ]}
      />

      {/* Notification List */}
      <NotificationList
        visible={showNotificationList}
        onClose={() => setShowNotificationList(false)}
        onNotificationPress={notification => {
          console.log('Notification pressed:', notification);
          // Handle notification press (navigate to specific screen, etc.)
        }}
      />

      {/* Loading State */}
      {isLoading && (
        <LoadingState
          message="Đang tải dữ liệu dashboard..."
          backgroundColor="rgba(26, 46, 58, 0.9)"
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  headerLeft: {
    flex: 1,
  },
  greeting: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  periodSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    alignSelf: 'flex-start',
  },
  periodText: {
    fontSize: 12,
    color: '#FFFFFF',
    marginRight: 4,
  },
  notificationButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  notificationBadge: {
    position: 'absolute',
    top: -2,
    right: -2,
    backgroundColor: '#FF6B6B',
    borderRadius: 10,
    width: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  notificationBadgeText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: 'bold',
  },
  insightCard: {
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    borderLeftWidth: 4,
    borderLeftColor: Colors.primary[500],
  },
  insightContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  insightIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  insightText: {
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
  balanceCard: {
    marginHorizontal: 20,
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  balanceHeader: {
    alignItems: 'center',
    marginBottom: 16,
  },
  balanceLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 4,
  },
  balanceAmount: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  savingsProgress: {
    width: '100%',
  },
  progressInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  progressLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  progressPercentage: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  progressBarContainer: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 3,
    marginBottom: 6,
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
  },
  progressTarget: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
  },
  summaryContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 24,
    gap: 12,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  summaryIcon: {
    marginBottom: 12,
  },
  summaryLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  summaryAmount: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  summaryChange: {
    fontSize: 11,
    color: Colors.primary[500],
  },
  quickAmountSection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  quickAmountGrid: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 12,
  },
  quickAmountChip: {
    flex: 1,
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
    borderRadius: 8,
    padding: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  quickAmountLabel: {
    fontSize: 10,
    color: Colors.primary[500],
    marginBottom: 2,
  },
  quickAmountValue: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  quickActionsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 24,
    gap: 12,
  },
  quickAction: {
    flex: 1,
    alignItems: 'center',
  },
  quickActionGradient: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  quickActionCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  quickActionText: {
    fontSize: 11,
    color: '#FFFFFF',
    textAlign: 'center',
    fontWeight: '500',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  historySection: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  seeAllText: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '500',
  },
  transactionList: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    overflow: 'hidden',
  },
  transactionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  transactionIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  transactionEmoji: {
    fontSize: 18,
  },
  transactionContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  transactionLeft: {
    flex: 1,
  },
  transactionDescription: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '500',
    marginBottom: 2,
  },
  transactionMeta: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  transactionRight: {
    alignItems: 'flex-end',
  },
  transactionAmount: {
    fontSize: 14,
    fontWeight: '600',
  },
  bottomSpacing: {
    height: 20,
  },
  logoutContainer: {
    paddingHorizontal: 20,
    paddingVertical: 20,
    paddingBottom: 100,
  },
  logoutButton: {
    backgroundColor: 'transparent',
    borderWidth: 2,
    borderColor: '#FF6B6B',
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoutText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF6B6B',
    marginLeft: 8,
  },
  // Student-specific styles
  studentInfo: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  dailyBudgetText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.9)',
    marginTop: 4,
  },
  // Features section styles
  featuresSection: {
    paddingHorizontal: 20,
    marginBottom: 30,
  },
  featuresContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginTop: 16,
  },
  featureCard: {
    width: '48%',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  featureIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  featureTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  featureSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
  },
});

export default DashboardScreen;
