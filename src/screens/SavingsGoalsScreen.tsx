import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Animated,
  Alert,
  Modal,
  TextInput,
  FlatList,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';

import { Colors } from '../constants/colors';
import { useApp } from '../context/AppContext';
import {
  SavingsGoal,
  SavingsPrediction,
  SavingsSuggestion,
  BehavioralInsight,
  SavingsCategory,
  SavingsPriority,
} from '../types';
import SavingsAIService from '../services/SavingsAIService';

interface CreateGoalData {
  name: string;
  description: string;
  targetAmount: string;
  targetDate: Date;
  category: SavingsCategory;
  priority: SavingsPriority;
  icon: string;
  color: string;
  autoSaveEnabled: boolean;
  reminderEnabled: boolean;
  reminderFrequency: 'daily' | 'weekly' | 'monthly';
  reminderAmount: string;
}

const GOAL_CATEGORIES = [
  {
    id: SavingsCategory.EMERGENCY,
    name: 'Emergency Fund',
    icon: '🚨',
    color: '#FF6B6B',
    description: 'Financial safety net',
  },
  {
    id: SavingsCategory.PURCHASE,
    name: 'Major Purchase',
    icon: '🛍️',
    color: '#4ECDC4',
    description: 'Phone, laptop, etc.',
  },
  {
    id: SavingsCategory.TRAVEL,
    name: 'Travel & Vacation',
    icon: '✈️',
    color: '#45B7D1',
    description: 'Trips and experiences',
  },
  {
    id: SavingsCategory.EDUCATION,
    name: 'Education',
    icon: '🎓',
    color: '#96CEB4',
    description: 'Courses and learning',
  },
  {
    id: SavingsCategory.INVESTMENT,
    name: 'Investment',
    icon: '📈',
    color: '#FFEAA7',
    description: 'Stocks, crypto, etc.',
  },
  {
    id: SavingsCategory.HOME,
    name: 'Home & Property',
    icon: '🏠',
    color: '#DDA0DD',
    description: 'House down payment',
  },
  {
    id: SavingsCategory.VEHICLE,
    name: 'Vehicle',
    icon: '🚗',
    color: '#FFB6C1',
    description: 'Car or motorbike',
  },
  {
    id: SavingsCategory.HEALTH,
    name: 'Health & Wellness',
    icon: '🏥',
    color: '#87CEEB',
    description: 'Medical expenses',
  },
  {
    id: SavingsCategory.RETIREMENT,
    name: 'Retirement',
    icon: '👴',
    color: '#F0E68C',
    description: 'Long-term savings',
  },
  {
    id: SavingsCategory.OTHER,
    name: 'Other',
    icon: '🎯',
    color: '#D3D3D3',
    description: 'Custom goal',
  },
];

const PRIORITY_LEVELS = [
  { id: SavingsPriority.CRITICAL, name: 'Critical', color: '#FF4444', description: 'Must achieve' },
  { id: SavingsPriority.HIGH, name: 'High', color: '#FF8800', description: 'Very important' },
  {
    id: SavingsPriority.MEDIUM,
    name: 'Medium',
    color: '#FFD700',
    description: 'Moderately important',
  },
  { id: SavingsPriority.LOW, name: 'Low', color: '#32CD32', description: 'Nice to have' },
];

const SavingsGoalsScreen: React.FC = () => {
  const navigation = useNavigation();
  const { dataActions, state } = useApp();

  const [goals, setGoals] = useState<SavingsGoal[]>([]);
  const [predictions, setPredictions] = useState<Record<string, SavingsPrediction>>({});
  const [suggestions, setSuggestions] = useState<Record<string, SavingsSuggestion[]>>({});
  const [insights, setInsights] = useState<BehavioralInsight[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedGoal, setSelectedGoal] = useState<SavingsGoal | null>(null);
  const [showAIInsights, setShowAIInsights] = useState(false);

  const [createGoalData, setCreateGoalData] = useState<CreateGoalData>({
    name: '',
    description: '',
    targetAmount: '',
    targetDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
    category: SavingsCategory.PURCHASE,
    priority: SavingsPriority.MEDIUM,
    icon: '🎯',
    color: '#4ECDC4',
    autoSaveEnabled: false,
    reminderEnabled: true,
    reminderFrequency: 'weekly',
    reminderAmount: '',
  });

  const [animationValue] = useState(new Animated.Value(0));

  useEffect(() => {
    loadSavingsData();
  }, []);

  useEffect(() => {
    if (goals.length > 0) {
      loadAIData();
    }
  }, [goals]);

  const loadSavingsData = async () => {
    try {
      setLoading(true);
      const savedGoals = await dataActions.getSavingsGoals();
      setGoals(savedGoals);

      // Animate on load
      Animated.timing(animationValue, {
        toValue: 1,
        duration: 800,
        useNativeDriver: true,
      }).start();
    } catch (error) {
      console.error('Error loading savings data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadAIData = async () => {
    try {
      const expenses = await dataActions.getExpenses();
      const incomes = await dataActions.getIncomes();

      // Load predictions and suggestions for each goal
      for (const goal of goals) {
        try {
          // Generate AI prediction
          const prediction = await SavingsAIService.calculateGoalPrediction(
            goal,
            expenses,
            incomes
          );
          setPredictions(prev => ({ ...prev, [goal.id]: prediction }));

          // Generate suggestions
          const goalSuggestions = await SavingsAIService.generateSavingSuggestions(goal, expenses);
          setSuggestions(prev => ({ ...prev, [goal.id]: goalSuggestions }));
        } catch (error) {
          console.error(`Error loading AI data for goal ${goal.id}:`, error);
        }
      }

      // Load behavioral insights
      if (state.user) {
        const userInsights = await SavingsAIService.analyzeBehavioralInsights(
          state.user.id,
          expenses
        );
        setInsights(userInsights);
      }
    } catch (error) {
      console.error('Error loading AI data:', error);
    }
  };

  const handleCreateGoal = async () => {
    try {
      if (!createGoalData.name.trim() || !createGoalData.targetAmount) {
        Alert.alert('Error', 'Please fill in all required fields');
        return;
      }

      const targetAmount = parseFloat(createGoalData.targetAmount.replace(/[^0-9]/g, ''));
      if (isNaN(targetAmount) || targetAmount <= 0) {
        Alert.alert('Error', 'Please enter a valid target amount');
        return;
      }

      const monthsToTarget = Math.max(
        1,
        Math.ceil((createGoalData.targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24 * 30))
      );

      const newGoal: Partial<SavingsGoal> = {
        userId: state.user?.id || 'user',
        name: createGoalData.name.trim(),
        description: createGoalData.description.trim(),
        targetAmount,
        currentAmount: 0,
        targetDate: createGoalData.targetDate,
        category: createGoalData.category,
        priority: createGoalData.priority,
        autoSaveEnabled: createGoalData.autoSaveEnabled,
        weeklyTarget: targetAmount / (monthsToTarget * 4),
        monthlyTarget: targetAmount / monthsToTarget,
        icon: createGoalData.icon,
        color: createGoalData.color,
        reminder: {
          enabled: createGoalData.reminderEnabled,
          frequency: createGoalData.reminderFrequency,
          amount: parseFloat(createGoalData.reminderAmount) || targetAmount / monthsToTarget,
          time: '19:00', // Default reminder time
        },
        isCompleted: false,
      };

      await dataActions.addSavingsGoal(newGoal);
      await loadSavingsData();
      setShowCreateModal(false);
      resetCreateForm();
    } catch (error) {
      console.error('Error creating goal:', error);
      Alert.alert('Error', 'Failed to create savings goal');
    }
  };

  const resetCreateForm = () => {
    setCreateGoalData({
      name: '',
      description: '',
      targetAmount: '',
      targetDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      category: SavingsCategory.PURCHASE,
      priority: SavingsPriority.MEDIUM,
      icon: '🎯',
      color: '#4ECDC4',
      autoSaveEnabled: false,
      reminderEnabled: true,
      reminderFrequency: 'weekly',
      reminderAmount: '',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const formatCurrencyInput = (value: string) => {
    const numericValue = value.replace(/[^0-9]/g, '');
    if (!numericValue) return '';
    return new Intl.NumberFormat('vi-VN').format(parseInt(numericValue));
  };

  const getProgressPercentage = (goal: SavingsGoal) => {
    return Math.min(100, (goal.currentAmount / goal.targetAmount) * 100);
  };

  const getDaysRemaining = (targetDate: Date) => {
    const days = Math.ceil((targetDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    return Math.max(0, days);
  };

  const getPriorityColor = (priority: SavingsPriority) => {
    const priorityLevel = PRIORITY_LEVELS.find(p => p.id === priority);
    return priorityLevel?.color || '#D3D3D3';
  };

  const renderGoalCard = (goal: SavingsGoal) => {
    const progress = getProgressPercentage(goal);
    const daysRemaining = getDaysRemaining(new Date(goal.targetDate));
    const prediction = predictions[goal.id];
    const goalSuggestions = suggestions[goal.id] || [];

    return (
      <TouchableOpacity key={goal.id} style={styles.goalCard} onPress={() => setSelectedGoal(goal)}>
        <LinearGradient
          colors={[goal.color, goal.color + '88']}
          style={styles.goalGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.goalHeader}>
            <View style={styles.goalIcon}>
              <Text style={styles.goalEmoji}>{goal.icon}</Text>
            </View>
            <View style={styles.goalInfo}>
              <Text style={styles.goalName}>{goal.name}</Text>
              <Text style={styles.goalCategory}>
                {GOAL_CATEGORIES.find(c => c.id === goal.category)?.name}
              </Text>
            </View>
            <View
              style={[styles.priorityBadge, { backgroundColor: getPriorityColor(goal.priority) }]}
            >
              <Text style={styles.priorityText}>{goal.priority.toUpperCase()}</Text>
            </View>
          </View>

          <View style={styles.goalProgress}>
            <View style={styles.progressInfo}>
              <Text style={styles.progressAmount}>
                {formatCurrency(goal.currentAmount)} / {formatCurrency(goal.targetAmount)}
              </Text>
              <Text style={styles.progressPercentage}>{progress.toFixed(1)}%</Text>
            </View>

            <View style={styles.progressBarContainer}>
              <View style={styles.progressBarBackground} />
              <Animated.View
                style={[
                  styles.progressBarFill,
                  {
                    transform: [
                      {
                        scaleX: animationValue.interpolate({
                          inputRange: [0, 1],
                          outputRange: [0, progress / 100],
                        }),
                      },
                    ],
                  },
                ]}
              />
            </View>
          </View>

          <View style={styles.goalDetails}>
            <View style={styles.detailItem}>
              <Ionicons name="calendar-outline" size={16} color="#FFFFFF" />
              <Text style={styles.detailText}>{daysRemaining} days left</Text>
            </View>
            <View style={styles.detailItem}>
              <Ionicons name="trending-up" size={16} color="#FFFFFF" />
              <Text style={styles.detailText}>{formatCurrency(goal.monthlyTarget)}/month</Text>
            </View>
          </View>

          {/* AI Prediction Badge */}
          {prediction && (
            <View style={styles.aiPredictionBadge}>
              <Ionicons name="bulb" size={14} color="#FFD700" />
              <Text style={styles.aiPredictionText}>
                {prediction.probability}% success probability
              </Text>
            </View>
          )}

          {/* Quick Actions */}
          <View style={styles.quickActions}>
            <TouchableOpacity
              style={styles.actionButton}
              onPress={() => {
                /* Add money */
              }}
            >
              <Ionicons name="add" size={16} color="#FFFFFF" />
              <Text style={styles.actionText}>Add</Text>
            </TouchableOpacity>

            {goalSuggestions.length > 0 && (
              <TouchableOpacity
                style={[styles.actionButton, styles.aiActionButton]}
                onPress={() => {
                  /* Show AI suggestions */
                }}
              >
                <Ionicons name="bulb-outline" size={16} color="#FFD700" />
                <Text style={styles.actionText}>AI Tips</Text>
              </TouchableOpacity>
            )}
          </View>
        </LinearGradient>
      </TouchableOpacity>
    );
  };

  const renderAIInsights = () => {
    if (insights.length === 0) return null;

    return (
      <View style={styles.aiInsightsSection}>
        <View style={styles.sectionHeader}>
          <Ionicons name="bulb" size={24} color={Colors.primary[500]} />
          <Text style={styles.sectionTitle}>AI Behavioral Insights</Text>
        </View>

        {insights.slice(0, 3).map((insight, index) => (
          <View key={index} style={styles.insightCard}>
            <View style={styles.insightHeader}>
              <Text style={styles.insightIcon}>
                {insight.impact === 'positive' ? '✅' : insight.impact === 'negative' ? '⚠️' : 'ℹ️'}
              </Text>
              <View style={styles.insightContent}>
                <Text style={styles.insightTitle}>{insight.title}</Text>
                <Text style={styles.insightDescription}>{insight.description}</Text>
              </View>
              <Text style={styles.insightConfidence}>{insight.confidence}%</Text>
            </View>

            {insight.recommendations.length > 0 && (
              <View style={styles.insightRecommendations}>
                <Text style={styles.recommendationsTitle}>Recommendations:</Text>
                {insight.recommendations.slice(0, 2).map((rec, idx) => (
                  <Text key={idx} style={styles.recommendationText}>
                    • {rec}
                  </Text>
                ))}
              </View>
            )}
          </View>
        ))}
      </View>
    );
  };

  const renderCreateGoalModal = () => (
    <Modal visible={showCreateModal} animationType="slide" presentationStyle="pageSheet">
      <View style={styles.modalContainer}>
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Create Savings Goal</Text>
          <TouchableOpacity onPress={() => setShowCreateModal(false)}>
            <Ionicons name="close" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.modalContent} showsVerticalScrollIndicator={false}>
          {/* Goal Name */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Goal Name *</Text>
            <TextInput
              style={styles.textInput}
              placeholder="e.g., iPhone 15 Pro Max"
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              value={createGoalData.name}
              onChangeText={text => setCreateGoalData(prev => ({ ...prev, name: text }))}
            />
          </View>

          {/* Target Amount */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Target Amount *</Text>
            <TextInput
              style={styles.textInput}
              placeholder="0"
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              value={formatCurrencyInput(createGoalData.targetAmount)}
              onChangeText={text =>
                setCreateGoalData(prev => ({ ...prev, targetAmount: text.replace(/[^0-9]/g, '') }))
              }
              keyboardType="numeric"
            />
          </View>

          {/* Category Selection */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Category</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.categoryScroll}
            >
              {GOAL_CATEGORIES.map(category => (
                <TouchableOpacity
                  key={category.id}
                  style={[
                    styles.categoryChip,
                    createGoalData.category === category.id && styles.selectedCategoryChip,
                  ]}
                  onPress={() =>
                    setCreateGoalData(prev => ({
                      ...prev,
                      category: category.id,
                      icon: category.icon,
                      color: category.color,
                    }))
                  }
                >
                  <Text style={styles.categoryEmoji}>{category.icon}</Text>
                  <Text style={styles.categoryName}>{category.name}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Priority Selection */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Priority</Text>
            <View style={styles.priorityContainer}>
              {PRIORITY_LEVELS.map(priority => (
                <TouchableOpacity
                  key={priority.id}
                  style={[
                    styles.priorityChip,
                    { borderColor: priority.color },
                    createGoalData.priority === priority.id && {
                      backgroundColor: priority.color + '20',
                    },
                  ]}
                  onPress={() => setCreateGoalData(prev => ({ ...prev, priority: priority.id }))}
                >
                  <Text style={[styles.priorityLabel, { color: priority.color }]}>
                    {priority.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Description */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Description (Optional)</Text>
            <TextInput
              style={[styles.textInput, styles.textArea]}
              placeholder="Add details about your goal..."
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              value={createGoalData.description}
              onChangeText={text => setCreateGoalData(prev => ({ ...prev, description: text }))}
              multiline
              numberOfLines={3}
            />
          </View>
        </ScrollView>

        <View style={styles.modalActions}>
          <TouchableOpacity style={styles.cancelButton} onPress={() => setShowCreateModal(false)}>
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.createButton} onPress={handleCreateGoal}>
            <LinearGradient
              colors={[Colors.primary[500], Colors.primary[600]]}
              style={styles.createButtonGradient}
            >
              <Text style={styles.createButtonText}>Create Goal</Text>
            </LinearGradient>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <Text style={styles.loadingText}>Loading savings goals...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#FFFFFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Savings Goals</Text>
        <TouchableOpacity onPress={() => setShowAIInsights(!showAIInsights)}>
          <Ionicons name="bulb" size={24} color={Colors.primary[500]} />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* AI Insights (toggleable) */}
        {showAIInsights && renderAIInsights()}

        {/* Goals Summary */}
        <View style={styles.summarySection}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Goals</Text>
            <Text style={styles.summaryValue}>{goals.length}</Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Target</Text>
            <Text style={styles.summaryValue}>
              {formatCurrency(goals.reduce((sum, goal) => sum + goal.targetAmount, 0))}
            </Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Saved</Text>
            <Text style={styles.summaryValue}>
              {formatCurrency(goals.reduce((sum, goal) => sum + goal.currentAmount, 0))}
            </Text>
          </View>
        </View>

        {/* Goals List */}
        <View style={styles.goalsSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Your Goals</Text>
            <TouchableOpacity style={styles.addButton} onPress={() => setShowCreateModal(true)}>
              <Ionicons name="add" size={20} color="#FFFFFF" />
              <Text style={styles.addButtonText}>Add Goal</Text>
            </TouchableOpacity>
          </View>

          {goals.length === 0 ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyStateIcon}>🎯</Text>
              <Text style={styles.emptyStateTitle}>No savings goals yet</Text>
              <Text style={styles.emptyStateDescription}>
                Create your first savings goal and let AI help you achieve it!
              </Text>
              <TouchableOpacity
                style={styles.emptyStateButton}
                onPress={() => setShowCreateModal(true)}
              >
                <Text style={styles.emptyStateButtonText}>Create First Goal</Text>
              </TouchableOpacity>
            </View>
          ) : (
            goals.map(renderGoalCard)
          )}
        </View>
      </ScrollView>

      {renderCreateGoalModal()}
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  content: {
    flex: 1,
  },
  aiInsightsSection: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginLeft: 10,
  },
  insightCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: Colors.primary[500],
  },
  insightHeader: {
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
  insightDescription: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 16,
  },
  insightConfidence: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.primary[500],
  },
  insightRecommendations: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  recommendationsTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 6,
  },
  recommendationText: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 14,
    marginBottom: 2,
  },
  summarySection: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
    gap: 12,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  goalsSection: {
    paddingHorizontal: 20,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    gap: 6,
  },
  addButtonText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  goalCard: {
    marginBottom: 16,
    borderRadius: 16,
    overflow: 'hidden',
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
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  goalEmoji: {
    fontSize: 20,
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
  goalCategory: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  priorityBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  priorityText: {
    fontSize: 10,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  goalProgress: {
    marginBottom: 16,
  },
  progressInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  progressAmount: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
  },
  progressPercentage: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  progressBarContainer: {
    position: 'relative',
    height: 6,
    borderRadius: 3,
  },
  progressBarBackground: {
    position: 'absolute',
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 3,
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 3,
    width: '100%',
    transformOrigin: 'left',
  },
  goalDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  detailItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  detailText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginLeft: 6,
  },
  aiPredictionBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 215, 0, 0.2)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    alignSelf: 'flex-start',
    marginBottom: 12,
  },
  aiPredictionText: {
    fontSize: 11,
    color: '#FFD700',
    fontWeight: '600',
    marginLeft: 4,
  },
  quickActions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    gap: 4,
  },
  aiActionButton: {
    backgroundColor: 'rgba(255, 215, 0, 0.2)',
  },
  actionText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyStateIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyStateTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    marginBottom: 20,
    lineHeight: 20,
  },
  emptyStateButton: {
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
  },
  emptyStateButtonText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  modalContent: {
    flex: 1,
    paddingHorizontal: 20,
  },
  inputGroup: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  textInput: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    color: '#FFFFFF',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  categoryScroll: {
    marginTop: 8,
  },
  categoryChip: {
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    marginRight: 12,
    minWidth: 80,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  selectedCategoryChip: {
    borderColor: Colors.primary[500],
    backgroundColor: Colors.primary[500] + '20',
  },
  categoryEmoji: {
    fontSize: 20,
    marginBottom: 4,
  },
  categoryName: {
    fontSize: 10,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  priorityContainer: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
  },
  priorityChip: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
  },
  priorityLabel: {
    fontSize: 12,
    fontWeight: '600',
  },
  modalActions: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 20,
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  cancelButton: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  cancelButtonText: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  createButton: {
    flex: 1,
    borderRadius: 12,
    overflow: 'hidden',
  },
  createButtonGradient: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  createButtonText: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
});

export default SavingsGoalsScreen;
