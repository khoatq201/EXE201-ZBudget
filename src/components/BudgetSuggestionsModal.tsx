import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Modal } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors } from '../constants/colors';

interface BudgetSuggestion {
  category: string;
  currentAmount: number;
  suggestedReduction: number;
  reasoning: string;
}

interface BudgetSuggestionsModalProps {
  visible: boolean;
  onClose: () => void;
  suggestions: BudgetSuggestion[];
  goalName: string;
}

const BudgetSuggestionsModal: React.FC<BudgetSuggestionsModalProps> = ({
  visible,
  onClose,
  suggestions,
  goalName,
}) => {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const getCategoryIcon = (category: string) => {
    const icons: { [key: string]: string } = {
      food: '🍽️',
      transport: '🚗',
      entertainment: '🎬',
      shopping: '🛍️',
      utilities: '💡',
      healthcare: '🏥',
      education: '📚',
      other: '📱',
    };
    return icons[category.toLowerCase()] || '💰';
  };

  const totalSavings = suggestions.reduce((sum, s) => sum + s.suggestedReduction, 0);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        {/* Header */}
        <LinearGradient colors={[Colors.primary[500], '#2E8B57']} style={styles.header}>
          <View style={styles.headerContent}>
            <View>
              <Text style={styles.headerTitle}>Đề xuất tối ưu ngân sách</Text>
              <Text style={styles.headerSubtitle}>Cho mục tiêu: {goalName}</Text>
            </View>
            <TouchableOpacity style={styles.closeButton} onPress={onClose}>
              <Ionicons name="close" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </LinearGradient>

        <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
          {/* Summary Card */}
          <View style={styles.summaryCard}>
            <View style={styles.summaryHeader}>
              <Text style={styles.summaryIcon}>💡</Text>
              <View>
                <Text style={styles.summaryTitle}>Tổng tiết kiệm có thể</Text>
                <Text style={styles.summaryAmount}>{formatCurrency(totalSavings)}/tháng</Text>
              </View>
            </View>
            <Text style={styles.summaryDescription}>
              Bằng cách điều chỉnh ngân sách theo đề xuất, bạn có thể tiết kiệm thêm{' '}
              <Text style={styles.highlightText}>{formatCurrency(totalSavings)}</Text> mỗi tháng để
              đạt mục tiêu nhanh hơn.
            </Text>
          </View>

          {/* Suggestions List */}
          <View style={styles.suggestionsSection}>
            <Text style={styles.sectionTitle}>Đề xuất chi tiết</Text>

            {suggestions.map((suggestion, index) => (
              <View key={index} style={styles.suggestionCard}>
                <View style={styles.suggestionHeader}>
                  <View style={styles.suggestionLeft}>
                    <Text style={styles.categoryIcon}>{getCategoryIcon(suggestion.category)}</Text>
                    <View>
                      <Text style={styles.categoryName}>{suggestion.category}</Text>
                      <Text style={styles.currentAmount}>
                        Hiện tại: {formatCurrency(suggestion.currentAmount)}
                      </Text>
                    </View>
                  </View>
                  <View style={styles.suggestionRight}>
                    <Text style={styles.reductionLabel}>Giảm</Text>
                    <Text style={styles.reductionAmount}>
                      {formatCurrency(suggestion.suggestedReduction)}
                    </Text>
                  </View>
                </View>

                <View style={styles.reasoningContainer}>
                  <Ionicons name="information-circle" size={16} color={Colors.primary[500]} />
                  <Text style={styles.reasoningText}>{suggestion.reasoning}</Text>
                </View>

                {/* Visual Progress */}
                <View style={styles.visualContainer}>
                  <View style={styles.amountBar}>
                    <View
                      style={[
                        styles.currentBar,
                        {
                          flex: suggestion.currentAmount - suggestion.suggestedReduction,
                          backgroundColor: Colors.primary[500],
                        },
                      ]}
                    />
                    <View
                      style={[
                        styles.reductionBar,
                        {
                          flex: suggestion.suggestedReduction,
                          backgroundColor: '#FF6B6B',
                        },
                      ]}
                    />
                  </View>
                  <View style={styles.barLabels}>
                    <Text style={styles.barLabel}>
                      Sau điều chỉnh:{' '}
                      {formatCurrency(suggestion.currentAmount - suggestion.suggestedReduction)}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </View>

          {/* Impact Analysis */}
          <View style={styles.impactSection}>
            <Text style={styles.sectionTitle}>Ảnh hưởng tích cực</Text>

            <View style={styles.impactList}>
              <View style={styles.impactItem}>
                <Text style={styles.impactIcon}>⚡</Text>
                <View style={styles.impactContent}>
                  <Text style={styles.impactTitle}>Đạt mục tiêu nhanh hơn</Text>
                  <Text style={styles.impactDescription}>
                    Tiết kiệm thêm {formatCurrency(totalSavings)}/tháng sẽ giúp bạn đạt mục tiêu sớm
                    hơn dự kiến
                  </Text>
                </View>
              </View>

              <View style={styles.impactItem}>
                <Text style={styles.impactIcon}>📊</Text>
                <View style={styles.impactContent}>
                  <Text style={styles.impactTitle}>Kiểm soát chi tiêu tốt hơn</Text>
                  <Text style={styles.impactDescription}>
                    Giảm chi tiêu không cần thiết và tối ưu hóa ngân sách hiệu quả
                  </Text>
                </View>
              </View>

              <View style={styles.impactItem}>
                <Text style={styles.impactIcon}>🎯</Text>
                <View style={styles.impactContent}>
                  <Text style={styles.impactTitle}>Tạo thói quen tốt</Text>
                  <Text style={styles.impactDescription}>
                    Xây dựng kỷ luật tài chính và thói quen tiết kiệm lâu dài
                  </Text>
                </View>
              </View>
            </View>
          </View>

          {/* Action Buttons */}
          <View style={styles.actionsContainer}>
            <TouchableOpacity style={styles.secondaryButton} onPress={onClose}>
              <Text style={styles.secondaryButtonText}>Để sau</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.primaryButton}>
              <LinearGradient
                colors={[Colors.primary[500], '#2E8B57']}
                style={styles.primaryButtonGradient}
              >
                <Text style={styles.primaryButtonText}>Áp dụng đề xuất</Text>
                <Ionicons name="checkmark" size={16} color="#FFFFFF" />
              </LinearGradient>
            </TouchableOpacity>
          </View>

          <View style={styles.bottomSpacing} />
        </ScrollView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  header: {
    paddingTop: 50,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  headerSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 4,
  },
  closeButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  summaryCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginTop: 20,
    marginBottom: 24,
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  summaryIcon: {
    fontSize: 32,
    marginRight: 16,
  },
  summaryTitle: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  summaryAmount: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  summaryDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 20,
  },
  highlightText: {
    color: Colors.primary[500],
    fontWeight: '600',
  },
  suggestionsSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  suggestionCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  suggestionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  suggestionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  categoryIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  categoryName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  currentAmount: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  suggestionRight: {
    alignItems: 'flex-end',
  },
  reductionLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  reductionAmount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF6B6B',
  },
  reasoningContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  reasoningText: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.8)',
    marginLeft: 8,
    flex: 1,
    lineHeight: 18,
  },
  visualContainer: {
    marginTop: 8,
  },
  amountBar: {
    flexDirection: 'row',
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 6,
  },
  currentBar: {
    borderTopLeftRadius: 4,
    borderBottomLeftRadius: 4,
  },
  reductionBar: {
    borderTopRightRadius: 4,
    borderBottomRightRadius: 4,
  },
  barLabels: {
    alignItems: 'center',
  },
  barLabel: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  impactSection: {
    marginBottom: 24,
  },
  impactList: {
    gap: 16,
  },
  impactItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  impactIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  impactContent: {
    flex: 1,
  },
  impactTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  impactDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 18,
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  secondaryButton: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
  },
  secondaryButtonText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '500',
  },
  primaryButton: {
    flex: 2,
    borderRadius: 12,
    overflow: 'hidden',
  },
  primaryButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
  },
  primaryButtonText: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
    marginRight: 8,
  },
  bottomSpacing: {
    height: 40,
  },
});

export default BudgetSuggestionsModal;
