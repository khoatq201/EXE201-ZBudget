import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
  Animated,
  Dimensions,
  Alert,
  RefreshControl,
  ImageBackground,
  Platform,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { Colors, ThemeColors } from '../constants/colors';
import { Spacing, Layout } from '../constants/spacing';
import { Typography } from '../constants/typography';
import { VietnameseText } from '../constants/vietnamese';
import { BackButton, LoadingState } from '../components';
import { useApp } from '../context/AppContext';
import { formatCurrency } from '../utils/formatters';
import { ErrorHandler } from '../utils/errorHandler';

const { width, height } = Dimensions.get('window');

// Challenge interfaces
interface Challenge {
  id: string;
  emoji: string;
  title: string;
  description: string;
  participants: number;
  duration: string;
  amount: number;
  difficulty: 'easy' | 'medium' | 'hard';
  points: number;
  status: 'available' | 'active' | 'completed';
  progress?: number;
  category: 'drinks' | 'food' | 'transport' | 'shopping' | 'entertainment' | 'special' | 'digital';
  startDate?: Date;
  endDate?: Date;
  currentSavings?: number;
  streak?: number;
  badgeIcon?: string;
  completedAt?: Date;
}

interface UserStats {
  streak: number;
  level: number;
  points: number;
  totalChallengesCompleted: number;
  totalSavings: number;
  rank: number;
  nextLevelPoints: number;
}

const ChallengeScreen: React.FC = () => {
  const navigation = useNavigation();
  const { state } = useApp();
  // Override to use dark theme for better appearance
  const isDarkMode = true; // Force dark mode
  const theme = {
    ...ThemeColors.dark,
    background: '#1A2E3A', // Sử dụng màu từ header có sẵn
    surface: '#2A4A5A'
  };
  
  const [activeTab, setActiveTab] = useState<'explore' | 'active' | 'completed'>('explore');
  const [isLoading, setIsLoading] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  
  // Enhanced user stats
  const [userStats] = useState<UserStats>({
    streak: 12,
    level: 5,
    points: 2450,
    totalChallengesCompleted: 18,
    totalSavings: 3200000,
    rank: 247,
    nextLevelPoints: 500,
  });

  // Categories
  const categories = [
    { id: 'all', name: 'Tất cả', icon: '🎯', color: Colors.primary[500] },
    { id: 'drinks', name: 'Đồ uống', icon: '🧋', color: Colors.secondary[500] },
    { id: 'food', name: 'Ăn uống', icon: '🍜', color: Colors.accent[500] },
    { id: 'transport', name: 'Di chuyển', icon: '🚌', color: Colors.primary[600] },
    { id: 'shopping', name: 'Mua sắm', icon: '🛍️', color: Colors.secondary[600] },
    { id: 'entertainment', name: 'Giải trí', icon: '🎬', color: Colors.accent[600] },
  ];

  // Enhanced challenge data
  const challengeData = useMemo((): Challenge[] => [
    // Active challenges
    {
      id: 'coffee-home-1',
      emoji: '☕',
      title: 'Coffee Champion',
      description: 'Pha cà phê tại nhà thay vì mua ngoài',
      participants: 1247,
      duration: '7 ngày',
      amount: 150000,
      difficulty: 'easy',
      points: 50,
      status: 'active',
      progress: 85,
      category: 'drinks',
      currentSavings: 127500,
      streak: 6,
      badgeIcon: '🏅',
    },
    {
      id: 'lunch-prep',
      emoji: '🍱',
      title: 'Meal Prep Master',
      description: 'Chuẩn bị bữa trưa tại nhà cho tuần',
      participants: 892,
      duration: '5 ngày',
      amount: 300000,
      difficulty: 'medium',
      points: 120,
      status: 'active',
      progress: 40,
      category: 'food',
      currentSavings: 120000,
      streak: 2,
      badgeIcon: '🥇',
    },
    
    // Available challenges
    {
      id: 'bubble-tea-detox',
      emoji: '🧋',
      title: 'Bubble Tea Detox',
      description: 'Thay trà sữa bằng trà xanh tự pha',
      participants: 2156,
      duration: '14 ngày',
      amount: 420000,
      difficulty: 'medium',
      points: 180,
      status: 'available',
      category: 'drinks',
      badgeIcon: '🏆',
    },
    {
      id: 'walk-challenge',
      emoji: '🚶',
      title: 'Walk & Save',
      description: 'Đi bộ thay vì đi taxi cho quãng đường gần',
      participants: 3421,
      duration: '21 ngày',
      amount: 600000,
      difficulty: 'easy',
      points: 200,
      status: 'available',
      category: 'transport',
      badgeIcon: '🥇',
    },
    
    // Completed challenges
    {
      id: 'morning-coffee',
      emoji: '☕',
      title: 'Morning Ritual',
      description: 'Pha cà phê sáng tại nhà',
      participants: 1654,
      duration: '7 ngày',
      amount: 105000,
      difficulty: 'easy',
      points: 50,
      status: 'completed',
      progress: 100,
      category: 'drinks',
      currentSavings: 105000,
      streak: 7,
      badgeIcon: '🏅',
      completedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    },
  ], []);

  const getChallengesByTab = useCallback((tab: string) => {
    const filtered = challengeData.filter(challenge => challenge.status === tab);
    return selectedCategory === 'all' 
      ? filtered 
      : filtered.filter(challenge => challenge.category === selectedCategory);
  }, [challengeData, selectedCategory]);

  const handleJoinChallenge = useCallback(async (challengeId: string) => {
    try {
      setIsLoading(true);
      await new Promise(resolve => setTimeout(resolve, 1000));
      Alert.alert(
        '🎉 Chúc mừng!',
        'Bạn đã tham gia thử thách thành công! Hãy bắt đầu tiết kiệm ngay hôm nay.',
        [{ text: 'Bắt đầu' }]
      );
    } catch (error) {
      ErrorHandler.getInstance().handleError(error as Error, 'handleJoinChallenge');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const onRefresh = useCallback(async () => {
    setIsRefreshing(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1500));
    } catch (error) {
      ErrorHandler.getInstance().handleError(error as Error, 'onRefresh');
    } finally {
      setIsRefreshing(false);
    }
  }, []);

  // Header component
  const renderHeader = () => (
    <View style={[styles.header, { backgroundColor: theme.background }]}>
      <StatusBar 
        barStyle={isDarkMode ? "light-content" : "dark-content"} 
        backgroundColor={theme.background}
        translucent={false}
      />
      <BackButton title="Thử thách tiết kiệm" showHomeIcon={true} />
    </View>
  );

  // Hero stats section
  const renderHeroStats = () => (
    <View style={[styles.heroStats, { backgroundColor: theme.surface }]}>
      <LinearGradient
        colors={isDarkMode ? ['rgba(0,0,0,0.3)', 'rgba(0,0,0,0.1)'] : ['rgba(255,255,255,0.9)', 'rgba(255,255,255,0.6)']}
        style={styles.heroGradient}
      >
        <View style={styles.heroContent}>
          <Text style={[styles.heroTitle, { color: theme.text }]}>
            🏆 Thử thách tiết kiệm
          </Text>
          <Text style={[styles.heroSubtitle, { color: theme.textSecondary }]}>
            Biến tiết kiệm thành thói quen vui nhộn
          </Text>
          
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: `${Colors.primary[500]}20` }]}>
                <Ionicons name="flame" size={20} color={Colors.primary[500]} />
              </View>
              <Text style={[styles.statValue, { color: theme.text }]}>{userStats.streak}</Text>
              <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Chuỗi ngày</Text>
            </View>
            
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: `${Colors.secondary[500]}20` }]}>
                <Ionicons name="trophy" size={20} color={Colors.secondary[500]} />
              </View>
              <Text style={[styles.statValue, { color: theme.text }]}>#{userStats.rank}</Text>
              <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Xếp hạng</Text>
            </View>
            
            <View style={styles.statItem}>
              <View style={[styles.statIcon, { backgroundColor: `${Colors.accent[500]}20` }]}>
                <Ionicons name="star" size={20} color={Colors.accent[500]} />
              </View>
              <Text style={[styles.statValue, { color: theme.text }]}>{userStats.points}</Text>
              <Text style={[styles.statLabel, { color: theme.textSecondary }]}>Điểm</Text>
            </View>
          </View>
          
          <View style={styles.levelSection}>
            <View style={styles.levelInfo}>
              <Text style={[styles.levelText, { color: theme.text }]}>Cấp {userStats.level}</Text>
              <Text style={[styles.levelNextText, { color: theme.textSecondary }]}>
                {userStats.nextLevelPoints} điểm đến cấp {userStats.level + 1}
              </Text>
            </View>
            <View style={[styles.progressBar, { backgroundColor: `${theme.textSecondary}30` }]}>
              <View 
                style={[
                  styles.progressFill, 
                  { 
                    width: `${(userStats.points % 1000) / 10}%`,
                    backgroundColor: Colors.primary[500]
                  }
                ]} 
              />
            </View>
          </View>
        </View>
      </LinearGradient>
    </View>
  );

  // Category selector
  const renderCategorySelector = () => (
    <View style={styles.categorySection}>
      <ScrollView 
        horizontal 
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoryScrollContent}
      >
        {categories.map((category) => (
          <TouchableOpacity
            key={category.id}
            style={[
              styles.categoryItem,
              {
                backgroundColor: selectedCategory === category.id 
                  ? `${category.color}20` 
                  : theme.surface,
                borderColor: selectedCategory === category.id ? category.color : theme.border,
              }
            ]}
            onPress={() => setSelectedCategory(category.id)}
          >
            <Text style={styles.categoryIcon}>{category.icon}</Text>
            <Text style={[
              styles.categoryName,
              { 
                color: selectedCategory === category.id ? category.color : theme.textSecondary 
              }
            ]}>
              {category.name}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );

  // Tab selector
  const renderTabSelector = () => (
    <View style={[styles.tabSection, { backgroundColor: theme.surface }]}>
      {[
        { id: 'explore', label: 'Khám phá', icon: 'compass-outline' },
        { id: 'active', label: 'Đang tham gia', icon: 'play-circle-outline' },
        { id: 'completed', label: 'Hoàn thành', icon: 'checkmark-circle-outline' }
      ].map((tab) => (
        <TouchableOpacity
          key={tab.id}
          style={[
            styles.tabItem,
            {
              backgroundColor: activeTab === tab.id ? Colors.primary[500] : 'transparent'
            }
          ]}
          onPress={() => setActiveTab(tab.id as any)}
        >
          <Ionicons 
            name={tab.icon as any} 
            size={18} 
            color={activeTab === tab.id ? Colors.text.inverse : theme.textSecondary} 
          />
          <Text style={[
            styles.tabText,
            { 
              color: activeTab === tab.id ? Colors.text.inverse : theme.textSecondary 
            }
          ]}>
            {tab.label}
          </Text>
          {getChallengesByTab(tab.id).length > 0 && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>{getChallengesByTab(tab.id).length}</Text>
            </View>
          )}
        </TouchableOpacity>
      ))}
    </View>
  );

  // Challenge card
  const renderChallengeCard = (challenge: Challenge) => (
    <View style={[styles.challengeCard, { backgroundColor: theme.surface }]}>
      <View style={styles.challengeHeader}>
        <View style={styles.challengeEmojiContainer}>
          <Text style={styles.challengeEmoji}>{challenge.emoji}</Text>
          <View style={[styles.difficultyBadge, { backgroundColor: getDifficultyColor(challenge.difficulty) }]}>
            <Text style={styles.difficultyText}>{getDifficultyLabel(challenge.difficulty)}</Text>
          </View>
        </View>
        
        <View style={styles.challengeInfo}>
          <View style={styles.challengeTitleRow}>
            <Text style={[styles.challengeTitle, { color: theme.text }]} numberOfLines={1}>
              {challenge.title}
            </Text>
            {challenge.status === 'completed' && (
              <Text style={styles.completedBadge}>{challenge.badgeIcon}</Text>
            )}
          </View>
          
          <Text style={[styles.challengeDescription, { color: theme.textSecondary }]} numberOfLines={2}>
            {challenge.description}
          </Text>
          
          <View style={styles.challengeStats}>
            <View style={styles.challengeStatItem}>
              <Ionicons name="people" size={14} color={theme.textSecondary} />
              <Text style={[styles.challengeStatText, { color: theme.textSecondary }]}>
                {challenge.participants.toLocaleString()}
              </Text>
            </View>
            <View style={styles.challengeStatItem}>
              <Ionicons name="time" size={14} color={theme.textSecondary} />
              <Text style={[styles.challengeStatText, { color: theme.textSecondary }]}>
                {challenge.duration}
              </Text>
            </View>
            <View style={styles.challengeStatItem}>
              <Ionicons name="star" size={14} color={Colors.warning} />
              <Text style={[styles.challengeStatText, { color: Colors.warning }]}>
                {challenge.points} điểm
              </Text>
            </View>
          </View>
        </View>
      </View>

      <View style={styles.challengeFooter}>
        <View style={styles.challengeAmount}>
          <Text style={[styles.challengeAmountLabel, { color: theme.textSecondary }]}>
            Tiết kiệm mục tiêu
          </Text>
          <Text style={[styles.challengeAmountValue, { color: Colors.primary[500] }]}>
            {formatCurrency(challenge.amount)}
          </Text>
        </View>

        {challenge.status === 'active' && challenge.progress && (
          <View style={styles.activeProgress}>
            <View style={styles.progressInfo}>
              <Text style={[styles.progressText, { color: theme.textSecondary }]}>
                Tiến độ: {challenge.progress}%
              </Text>
              <Text style={[styles.progressAmount, { color: Colors.success }]}>
                {formatCurrency(challenge.currentSavings || 0)}
              </Text>
            </View>
            <View style={[styles.progressBar, { backgroundColor: `${theme.textSecondary}30` }]}>
              <View 
                style={[
                  styles.progressFill, 
                  { 
                    width: `${challenge.progress}%`,
                    backgroundColor: Colors.success
                  }
                ]} 
              />
            </View>
            {challenge.streak && (
              <View style={styles.streakIndicator}>
                <Ionicons name="flame" size={16} color={Colors.warning} />
                <Text style={[styles.streakText, { color: Colors.warning }]}>
                  {challenge.streak} ngày liên tiếp
                </Text>
              </View>
            )}
          </View>
        )}

        {challenge.status === 'completed' && (
          <View style={styles.completedSection}>
            <View style={styles.completedInfo}>
              <Ionicons name="checkmark-circle" size={20} color={Colors.success} />
              <Text style={[styles.completedText, { color: Colors.success }]}>
                Hoàn thành {challenge.completedAt?.toLocaleDateString('vi-VN')}
              </Text>
            </View>
            <Text style={[styles.rewardText, { color: theme.textSecondary }]}>
              Phần thưởng: {formatCurrency(challenge.currentSavings || 0)} + {challenge.points} điểm
            </Text>
          </View>
        )}

        <TouchableOpacity
          style={[
            styles.challengeButton,
            {
              backgroundColor: getButtonColor(challenge.status),
              opacity: isLoading ? 0.7 : 1
            }
          ]}
          onPress={() => {
            if (challenge.status === 'available') {
              handleJoinChallenge(challenge.id);
            }
          }}
          disabled={isLoading || challenge.status !== 'available'}
        >
          <Ionicons 
            name={getButtonIcon(challenge.status)} 
            size={18} 
            color={Colors.text.inverse} 
          />
          <Text style={styles.challengeButtonText}>
            {getButtonText(challenge.status)}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  // Helper functions
  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'easy': return Colors.success;
      case 'medium': return Colors.warning;
      case 'hard': return Colors.error;
      default: return Colors.primary[500];
    }
  };

  const getDifficultyLabel = (difficulty: string) => {
    const labels = { easy: 'Dễ', medium: 'Trung bình', hard: 'Khó' };
    return labels[difficulty as keyof typeof labels] || 'Dễ';
  };

  const getButtonColor = (status: string) => {
    switch (status) {
      case 'available': return Colors.primary[500];
      case 'active': return Colors.secondary[500];
      case 'completed': return Colors.success;
      default: return Colors.primary[500];
    }
  };

  const getButtonIcon = (status: string) => {
    switch (status) {
      case 'available': return 'play-circle';
      case 'active': return 'time';
      case 'completed': return 'checkmark-circle';
      default: return 'play-circle';
    }
  };

  const getButtonText = (status: string) => {
    switch (status) {
      case 'available': return 'Tham gia ngay';
      case 'active': return 'Đang tham gia';
      case 'completed': return 'Đã hoàn thành';
      default: return 'Tham gia';
    }
  };

  if (isLoading && !isRefreshing) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <StatusBar 
          barStyle={isDarkMode ? "light-content" : "dark-content"} 
          backgroundColor={theme.background} 
        />
        <BackButton title={VietnameseText.challenges.title} showHomeIcon={true} />
        <LoadingState message="Đang tải thử thách..." />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {renderHeader()}
      
      <ScrollView
        style={[styles.scrollView, { backgroundColor: theme.background }]}
        contentContainerStyle={{ backgroundColor: theme.background }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={onRefresh}
            tintColor={theme.primary}
            colors={[theme.primary]}
          />
        }
      >
        {renderHeroStats()}
        {renderCategorySelector()}
        {renderTabSelector()}
        
        <View style={styles.challengesList}>
          {getChallengesByTab(activeTab).map((challenge) => (
            <View key={challenge.id}>
              {renderChallengeCard(challenge)}
            </View>
          ))}
        </View>
        
        <View style={styles.bottomSpacing} />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  
  // Header
  header: {
    paddingTop: Platform.OS === 'ios' ? 44 : 24,
    paddingBottom: Spacing.md,
    borderBottomWidth: Layout.borderWidth.hairline,
    borderBottomColor: 'rgba(0,0,0,0.1)',
  },
  
  // Hero stats section
  heroStats: {
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: Layout.radius.xl,
    overflow: 'hidden',
    ...Layout.shadow.md,
  },
  heroGradient: {
    padding: Spacing.xl,
  },
  heroContent: {
    alignItems: 'center',
  },
  heroTitle: {
    ...Typography.styles.h2,
    fontWeight: '800',
    textAlign: 'center',
    marginBottom: Spacing.xs,
  },
  heroSubtitle: {
    ...Typography.styles.body,
    textAlign: 'center',
    marginBottom: Spacing.xl,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    marginBottom: Spacing.xl,
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  statValue: {
    ...Typography.styles.h3,
    fontWeight: '700',
    marginBottom: 2,
  },
  statLabel: {
    ...Typography.styles.caption,
    textAlign: 'center',
  },
  levelSection: {
    width: '100%',
  },
  levelInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  levelText: {
    ...Typography.styles.body,
    fontWeight: '600',
  },
  levelNextText: {
    ...Typography.styles.caption,
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: 4,
  },
  
  // Category section
  categorySection: {
    marginVertical: Spacing.lg,
  },
  categoryScrollContent: {
    paddingHorizontal: Spacing.md,
    gap: Spacing.sm,
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Layout.radius.lg,
    borderWidth: Layout.borderWidth.thin,
    minWidth: 100,
  },
  categoryIcon: {
    fontSize: 18,
    marginRight: Spacing.xs,
  },
  categoryName: {
    ...Typography.styles.bodySmall,
    fontWeight: '600',
  },
  
  // Tab section
  tabSection: {
    flexDirection: 'row',
    marginHorizontal: Spacing.md,
    marginBottom: Spacing.lg,
    borderRadius: Layout.radius.lg,
    padding: Spacing.xs,
    ...Layout.shadow.sm,
  },
  tabItem: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.sm,
    borderRadius: Layout.radius.md,
    gap: Spacing.xs,
    position: 'relative',
  },
  tabText: {
    ...Typography.styles.caption,
    fontWeight: '600',
  },
  tabBadge: {
    position: 'absolute',
    top: -4,
    right: -4,
    backgroundColor: Colors.accent[500],
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  tabBadgeText: {
    color: Colors.text.inverse,
    fontSize: 10,
    fontWeight: '700',
  },
  
  // Challenge cards
  challengesList: {
    paddingHorizontal: Spacing.md,
    gap: Spacing.md,
  },
  challengeCard: {
    borderRadius: Layout.radius.lg,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
    ...Layout.shadow.md,
  },
  challengeHeader: {
    flexDirection: 'row',
    marginBottom: Spacing.md,
  },
  challengeEmojiContainer: {
    position: 'relative',
    marginRight: Spacing.md,
    alignItems: 'center',
  },
  challengeEmoji: {
    fontSize: 36,
  },
  difficultyBadge: {
    position: 'absolute',
    top: -4,
    right: -8,
    paddingHorizontal: Spacing.xs,
    paddingVertical: 2,
    borderRadius: 8,
  },
  difficultyText: {
    color: Colors.text.inverse,
    fontSize: 10,
    fontWeight: '700',
  },
  challengeInfo: {
    flex: 1,
  },
  challengeTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  challengeTitle: {
    ...Typography.styles.h4,
    fontWeight: '700',
    flex: 1,
  },
  completedBadge: {
    fontSize: 18,
    marginLeft: Spacing.xs,
  },
  challengeDescription: {
    ...Typography.styles.body,
    marginBottom: Spacing.sm,
    lineHeight: 20,
  },
  challengeStats: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  challengeStatItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  challengeStatText: {
    ...Typography.styles.caption,
    fontWeight: '500',
  },
  
  // Challenge footer
  challengeFooter: {
    gap: Spacing.md,
  },
  challengeAmount: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  challengeAmountLabel: {
    ...Typography.styles.bodySmall,
  },
  challengeAmountValue: {
    ...Typography.styles.h4,
    fontWeight: '700',
  },
  
  // Active progress
  activeProgress: {
    gap: Spacing.xs,
  },
  progressInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  progressText: {
    ...Typography.styles.bodySmall,
    fontWeight: '600',
  },
  progressAmount: {
    ...Typography.styles.bodySmall,
    fontWeight: '700',
  },
  streakIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: Spacing.xs,
  },
  streakText: {
    ...Typography.styles.caption,
    fontWeight: '600',
  },
  
  // Completed section
  completedSection: {
    gap: Spacing.xs,
  },
  completedInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  completedText: {
    ...Typography.styles.body,
    fontWeight: '600',
  },
  rewardText: {
    ...Typography.styles.bodySmall,
    fontStyle: 'italic',
  },
  
  // Challenge button
  challengeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    borderRadius: Layout.radius.md,
    gap: Spacing.xs,
    ...Layout.shadow.sm,
    marginTop: Spacing.sm,
  },
  challengeButtonText: {
    ...Typography.styles.body,
    fontWeight: '700',
    color: Colors.text.inverse,
  },
  
  bottomSpacing: {
    height: Spacing['2xl'],
  },
});

export default ChallengeScreen;