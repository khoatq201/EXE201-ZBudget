import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../constants/colors';
import BudgetSavingsService from '../services/BudgetSavingsService';

interface BudgetSavingsCardProps {
  userId: string;
  onNavigateToBudget?: () => void;
  onNavigateToSavings?: () => void;
  onAutoAllocate?: () => void;
}

const BudgetSavingsCard: React.FC<BudgetSavingsCardProps> = ({
  userId,
  onNavigateToBudget,
  onNavigateToSavings,
  onAutoAllocate,
}) => {
  const [insights, setInsights] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [animatedValue] = useState(new Animated.Value(0));

  useEffect(() => {
    loadInsights();
  }, [userId]);

  const loadInsights = async () => {
    try {
      setIsLoading(true);
      const data = await BudgetSavingsService.getBudgetSavingsInsights(userId);
      setInsights(data);

      // Animation
      Animated.timing(animatedValue, {
        toValue: 1,
        duration: 800,
        useNativeDriver: true,
      }).start();
    } catch (error) {
      console.error('Error loading budget-savings insights:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const getInsightColor = (type: string) => {
    switch (type) {
      case 'positive':
        return Colors.primary[500];
      case 'warning':
        return '#FFA726';
      case 'info':
        return '#45B7D1';
      default:
        return Colors.primary[500];
    }
  };

  const handleInsightAction = (insight: any) => {
    switch (insight.actionType) {
      case 'auto_allocate':
        onAutoAllocate?.();
        break;
      case 'view_goal':
        onNavigateToSavings?.();
        break;
      case 'review_budget':
        onNavigateToBudget?.();
        break;
    }
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Đang phân tích ngân sách...</Text>
      </View>
    );
  }

  if (!insights?.hasBudget) {
    return (
      <View style={styles.noBudgetContainer}>
        <Text style={styles.noBudgetIcon}>📊</Text>
        <Text style={styles.noBudgetTitle}>Chưa có ngân sách</Text>
        <Text style={styles.noBudgetMessage}>Tạo ngân sách để xem khả năng tiết kiệm của bạn</Text>
        <TouchableOpacity style={styles.createBudgetButton} onPress={onNavigateToBudget}>
          <Text style={styles.createBudgetText}>Tạo ngân sách</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <Animated.View style={[styles.container, { opacity: animatedValue }]}>
      <LinearGradient
        colors={['#2A4A5A', '#1A3A4A']}
        style={styles.card}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.headerIcon}>💰📊</Text>
            <View>
              <Text style={styles.headerTitle}>Budget ↔ Tiết kiệm</Text>
              <Text style={styles.headerSubtitle}>Phân tích thông minh</Text>
            </View>
          </View>
          <TouchableOpacity style={styles.refreshButton} onPress={loadInsights}>
            <Ionicons name="refresh" size={16} color="rgba(255,255,255,0.7)" />
          </TouchableOpacity>
        </View>

        {/* Current Analysis Summary */}
        {insights.currentAnalysis && (
          <View style={styles.summarySection}>
            <View style={styles.summaryRow}>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Ngân sách tháng</Text>
                <Text style={styles.summaryValue}>
                  {formatCurrency(insights.currentAnalysis.totalBudget)}
                </Text>
              </View>
              <View style={styles.summaryItem}>
                <Text style={styles.summaryLabel}>Đã chi</Text>
                <Text style={[styles.summaryValue, { color: '#FF6B6B' }]}>
                  {formatCurrency(insights.currentAnalysis.totalSpent)}
                </Text>
              </View>
            </View>

            <View style={styles.savingsPotentialContainer}>
              <View style={styles.savingsPotentialHeader}>
                <Text style={styles.savingsPotentialLabel}>Khả năng tiết kiệm</Text>
                <Text style={styles.savingsPotentialValue}>
                  {formatCurrency(insights.currentAnalysis.monthlySavingsPotential)}
                  <Text style={styles.savingsPotentialUnit}>/tháng</Text>
                </Text>
              </View>

              {/* Progress bar showing budget utilization */}
              <View style={styles.budgetProgressContainer}>
                <View style={styles.budgetProgressBar}>
                  <View
                    style={[
                      styles.budgetProgressFill,
                      {
                        width: `${Math.min(100, (insights.currentAnalysis.totalSpent / insights.currentAnalysis.totalBudget) * 100)}%`,
                        backgroundColor:
                          insights.currentAnalysis.totalSpent >
                          insights.currentAnalysis.totalBudget * 0.9
                            ? '#FF6B6B'
                            : Colors.primary[500],
                      },
                    ]}
                  />
                </View>
                <Text style={styles.budgetProgressText}>
                  {(
                    (insights.currentAnalysis.totalSpent / insights.currentAnalysis.totalBudget) *
                    100
                  ).toFixed(0)}
                  % đã sử dụng
                </Text>
              </View>
            </View>
          </View>
        )}

        {/* Insights */}
        <View style={styles.insightsSection}>
          {insights.insights.slice(0, 2).map((insight: any, index: number) => (
            <TouchableOpacity
              key={index}
              style={styles.insightItem}
              onPress={() => handleInsightAction(insight)}
            >
              <View style={styles.insightIcon}>
                <Text style={styles.insightEmoji}>{insight.icon}</Text>
              </View>
              <View style={styles.insightContent}>
                <Text style={styles.insightTitle}>{insight.title}</Text>
                <Text style={styles.insightMessage}>{insight.message}</Text>
              </View>
              <View
                style={[
                  styles.insightIndicator,
                  { backgroundColor: getInsightColor(insight.type) },
                ]}
              />
            </TouchableOpacity>
          ))}
        </View>

        {/* Action Buttons */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity style={styles.actionButton} onPress={onNavigateToBudget}>
            <Ionicons name="pie-chart" size={16} color={Colors.primary[500]} />
            <Text style={styles.actionButtonText}>Xem Budget</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton} onPress={onNavigateToSavings}>
            <Ionicons name="trending-up" size={16} color={Colors.primary[500]} />
            <Text style={styles.actionButtonText}>Mục tiêu</Text>
          </TouchableOpacity>

          {insights.currentAnalysis?.monthlySavingsPotential > 0 && (
            <TouchableOpacity
              style={[styles.actionButton, styles.primaryActionButton]}
              onPress={onAutoAllocate}
            >
              <Ionicons name="flash" size={16} color="#FFFFFF" />
              <Text style={[styles.actionButtonText, { color: '#FFFFFF' }]}>Auto Save</Text>
            </TouchableOpacity>
          )}
        </View>
      </LinearGradient>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 20,
    marginBottom: 20,
  },
  card: {
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  loadingContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 20,
    marginBottom: 20,
    alignItems: 'center',
  },
  loadingText: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 14,
  },
  noBudgetContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 20,
    marginBottom: 20,
    alignItems: 'center',
  },
  noBudgetIcon: {
    fontSize: 32,
    marginBottom: 12,
  },
  noBudgetTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  noBudgetMessage: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    marginBottom: 16,
  },
  createBudgetButton: {
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
  },
  createBudgetText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  headerSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  refreshButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  summarySection: {
    marginBottom: 16,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  summaryItem: {
    flex: 1,
  },
  summaryLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  savingsPotentialContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 12,
  },
  savingsPotentialHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  savingsPotentialLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  savingsPotentialValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  savingsPotentialUnit: {
    fontSize: 12,
    fontWeight: 'normal',
  },
  budgetProgressContainer: {
    marginTop: 8,
  },
  budgetProgressBar: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 3,
    marginBottom: 6,
  },
  budgetProgressFill: {
    height: '100%',
    borderRadius: 3,
  },
  budgetProgressText: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
    textAlign: 'center',
  },
  insightsSection: {
    marginBottom: 16,
  },
  insightItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    position: 'relative',
  },
  insightIcon: {
    marginRight: 12,
  },
  insightEmoji: {
    fontSize: 20,
  },
  insightContent: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  insightMessage: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 16,
  },
  insightIndicator: {
    position: 'absolute',
    right: 0,
    top: 0,
    bottom: 0,
    width: 4,
    borderTopRightRadius: 12,
    borderBottomRightRadius: 12,
  },
  actionsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 8,
  },
  primaryActionButton: {
    backgroundColor: Colors.primary[500],
  },
  actionButtonText: {
    fontSize: 12,
    color: Colors.primary[500],
    marginLeft: 4,
    fontWeight: '500',
  },
});

export default BudgetSavingsCard;
