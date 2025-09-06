import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Animated } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../constants/colors';
import BudgetSavingsService, { SavingsProjection } from '../services/BudgetSavingsService';

interface SavingsProjectionCardProps {
  goalId: string;
  goalName: string;
  goalIcon: string;
  onViewBudgetSuggestions?: (suggestions: any[]) => void;
}

const SavingsProjectionCard: React.FC<SavingsProjectionCardProps> = ({
  goalId,
  goalName,
  goalIcon,
  onViewBudgetSuggestions,
}) => {
  const [projection, setProjection] = useState<SavingsProjection | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [animatedValue] = useState(new Animated.Value(0));

  useEffect(() => {
    loadProjection();
  }, [goalId]);

  const loadProjection = async () => {
    try {
      setIsLoading(true);
      const data = await BudgetSavingsService.projectSavingsCompletion(goalId);
      setProjection(data);

      Animated.timing(animatedValue, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }).start();
    } catch (error) {
      console.error('Error loading savings projection:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const getCompletionText = () => {
    if (!projection) return '';

    if (projection.projectedMonthsToComplete === Infinity) {
      return 'Cần điều chỉnh ngân sách';
    }

    if (projection.projectedMonthsToComplete <= 1) {
      return 'Có thể hoàn thành trong tháng này!';
    }

    if (projection.projectedMonthsToComplete <= 12) {
      return `${projection.projectedMonthsToComplete} tháng nữa`;
    }

    const years = Math.floor(projection.projectedMonthsToComplete / 12);
    const months = projection.projectedMonthsToComplete % 12;
    return `${years} năm ${months > 0 ? `${months} tháng` : ''}`;
  };

  const getProgressPercentage = () => {
    if (!projection) return 0;
    return Math.min(100, (projection.currentAmount / projection.targetAmount) * 100);
  };

  const getStatusColor = () => {
    if (!projection) return '#666';

    if (projection.projectedMonthsToComplete === Infinity) {
      return '#FF6B6B';
    }

    if (projection.projectedMonthsToComplete <= 12) {
      return Colors.primary[500];
    }

    return '#FFA726';
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Đang phân tích...</Text>
      </View>
    );
  }

  if (!projection) {
    return null;
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
            <Text style={styles.goalIcon}>{goalIcon}</Text>
            <View>
              <Text style={styles.goalName}>{goalName}</Text>
              <Text style={styles.subtitle}>Dự đoán từ ngân sách</Text>
            </View>
          </View>
          <TouchableOpacity style={styles.refreshButton} onPress={loadProjection}>
            <Ionicons name="refresh" size={16} color="rgba(255,255,255,0.7)" />
          </TouchableOpacity>
        </View>

        {/* Progress Overview */}
        <View style={styles.progressSection}>
          <View style={styles.progressHeader}>
            <Text style={styles.progressLabel}>Tiến độ hiện tại</Text>
            <Text style={styles.progressPercentage}>{getProgressPercentage().toFixed(0)}%</Text>
          </View>

          <View style={styles.progressBarContainer}>
            <View style={styles.progressBar}>
              <Animated.View
                style={[
                  styles.progressFill,
                  {
                    width: animatedValue.interpolate({
                      inputRange: [0, 1],
                      outputRange: ['0%', `${getProgressPercentage()}%`],
                    }),
                    backgroundColor: getStatusColor(),
                  },
                ]}
              />
            </View>
          </View>

          <View style={styles.amountRow}>
            <Text style={styles.currentAmount}>{formatCurrency(projection.currentAmount)}</Text>
            <Text style={styles.targetAmount}>/ {formatCurrency(projection.targetAmount)}</Text>
          </View>
        </View>

        {/* Budget Analysis */}
        <View style={styles.analysisSection}>
          <View style={styles.analysisRow}>
            <View style={styles.analysisItem}>
              <Text style={styles.analysisLabel}>Từ ngân sách</Text>
              <Text style={[styles.analysisValue, { color: getStatusColor() }]}>
                {formatCurrency(projection.monthlyBudgetSurplus)}/tháng
              </Text>
            </View>
            <View style={styles.analysisItem}>
              <Text style={styles.analysisLabel}>Thời gian hoàn thành</Text>
              <Text style={[styles.analysisValue, { color: getStatusColor() }]}>
                {getCompletionText()}
              </Text>
            </View>
          </View>
        </View>

        {/* Suggestions */}
        {projection.suggestedBudgetAdjustments.length > 0 && (
          <View style={styles.suggestionsSection}>
            <View style={styles.suggestionsHeader}>
              <Text style={styles.suggestionsTitle}>Đề xuất tối ưu</Text>
              <TouchableOpacity
                onPress={() => onViewBudgetSuggestions?.(projection.suggestedBudgetAdjustments)}
              >
                <Text style={styles.viewAllText}>Xem chi tiết</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.suggestionsList}>
              {projection.suggestedBudgetAdjustments.slice(0, 2).map((suggestion, index) => (
                <View key={index} style={styles.suggestionItem}>
                  <View style={styles.suggestionIcon}>
                    <Ionicons name="bulb" size={14} color="#FFA726" />
                  </View>
                  <View style={styles.suggestionContent}>
                    <Text style={styles.suggestionCategory}>{suggestion.category}</Text>
                    <Text style={styles.suggestionText}>
                      Giảm {formatCurrency(suggestion.suggestedReduction)}
                    </Text>
                  </View>
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Action Buttons */}
        <View style={styles.actionsContainer}>
          {projection.monthlyBudgetSurplus > 0 ? (
            <TouchableOpacity style={styles.positiveAction}>
              <Ionicons name="trending-up" size={16} color="#FFFFFF" />
              <Text style={styles.actionText}>Đang tiến bộ tốt</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={styles.warningAction}>
              <Ionicons name="warning" size={16} color="#FFFFFF" />
              <Text style={styles.actionText}>Cần điều chỉnh budget</Text>
            </TouchableOpacity>
          )}
        </View>
      </LinearGradient>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  card: {
    borderRadius: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  loadingContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    alignItems: 'center',
  },
  loadingText: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 14,
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
  goalIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  goalName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  subtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  refreshButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  progressSection: {
    marginBottom: 16,
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  progressLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  progressPercentage: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  progressBarContainer: {
    marginBottom: 8,
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 4,
  },
  progressFill: {
    height: '100%',
    borderRadius: 4,
  },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  currentAmount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  targetAmount: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  analysisSection: {
    marginBottom: 16,
  },
  analysisRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  analysisItem: {
    flex: 1,
  },
  analysisLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  analysisValue: {
    fontSize: 14,
    fontWeight: '600',
  },
  suggestionsSection: {
    marginBottom: 16,
  },
  suggestionsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  suggestionsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  viewAllText: {
    fontSize: 12,
    color: Colors.primary[500],
  },
  suggestionsList: {
    gap: 6,
  },
  suggestionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 8,
    padding: 8,
  },
  suggestionIcon: {
    marginRight: 8,
  },
  suggestionContent: {
    flex: 1,
  },
  suggestionCategory: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  suggestionText: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  actionsContainer: {
    flexDirection: 'row',
  },
  positiveAction: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.primary[500],
    borderRadius: 8,
    paddingVertical: 10,
  },
  warningAction: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FF6B6B',
    borderRadius: 8,
    paddingVertical: 10,
  },
  actionText: {
    fontSize: 12,
    color: '#FFFFFF',
    marginLeft: 6,
    fontWeight: '500',
  },
});

export default SavingsProjectionCard;
