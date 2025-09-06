import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
  FlatList,
  TouchableOpacity,
  StatusBar,
  Animated,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { StackNavigationProp } from '@react-navigation/stack';

import { Colors } from '../constants/colors';
import { useApp } from '../context/AppContext';
import { RootStackParamList } from '../types';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

type OnboardingNavigationProp = StackNavigationProp<RootStackParamList, 'Onboarding'>;

interface OnboardingItem {
  id: string;
  title: string;
  description: string;
  iconName: keyof typeof Ionicons.glyphMap;
  emoji: string;
  color: string;
  gradient: string[];
}

const onboardingData: OnboardingItem[] = [
  {
    id: '1',
    title: 'Theo dõi chi tiêu thông minh',
    description:
      'Quét hóa đơn tự động và phân loại chi tiêu một cách dễ dàng. AI sẽ giúp bạn hiểu rõ thói quen chi tiêu của mình.',
    iconName: 'receipt-outline',
    emoji: '💰',
    color: '#4ECDC4',
    gradient: ['#4ECDC4', '#44A08D'] as const,
  },
  {
    id: '2',
    title: 'Thử thách tiết kiệm vui nhộn',
    description:
      'Tham gia các thử thách tiết kiệm hàng ngày và nhận được huy hiệu. Biến việc tiết kiệm thành một trò chơi thú vị!',
    iconName: 'trophy-outline',
    emoji: '🎯',
    color: '#FF6B6B',
    gradient: ['#FF6B6B', '#EE5A52'] as const,
  },
  {
    id: '3',
    title: 'Quản lý nhóm dễ dàng',
    description:
      'Chia sẻ chi phí với bạn bè và gia đình. Quản lý ngân sách chung một cách minh bạch và công bằng.',
    iconName: 'people-outline',
    emoji: '👥',
    color: '#45B7D1',
    gradient: ['#45B7D1', '#3A9BC1'] as const,
  },
];

const OnboardingScreen: React.FC = () => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [fadeAnim] = useState(new Animated.Value(1));
  const flatListRef = useRef<FlatList>(null);
  const navigation = useNavigation<OnboardingNavigationProp>();
  const { completeOnboarding } = useApp();

  const handleNext = () => {
    if (currentIndex < onboardingData.length - 1) {
      // Animate fade out, then change content, then fade in
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 200,
        useNativeDriver: true,
      }).start(() => {
        const nextIndex = currentIndex + 1;
        setCurrentIndex(nextIndex);
        flatListRef.current?.scrollToIndex({ index: nextIndex, animated: true });

        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }).start();
      });
    } else {
      handleGetStarted();
    }
  };

  const handleSkip = () => {
    handleGetStarted();
  };

  const handleGetStarted = async () => {
    await completeOnboarding();
    navigation.replace('Auth');
  };

  const renderIllustration = (item: OnboardingItem, index: number) => {
    return (
      <View style={styles.illustrationContainer}>
        <LinearGradient
          colors={item.gradient as unknown as readonly [string, string, ...string[]]}
          style={styles.illustrationCircle}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.iconContainer}>
            <Text style={styles.emojiIcon}>{item.emoji}</Text>
            <Ionicons name={item.iconName} size={60} color="#FFFFFF" />
          </View>

          {/* Decorative elements */}
          <View style={[styles.decorativeCircle, styles.circle1]} />
          <View style={[styles.decorativeCircle, styles.circle2]} />
          <View style={[styles.decorativeCircle, styles.circle3]} />
        </LinearGradient>

        {/* Feature cards */}
        <View style={styles.featureCards}>
          {index === 0 && (
            <>
              <View style={[styles.featureCard, styles.card1]}>
                <Text style={styles.cardEmoji}>🍜</Text>
                <Text style={styles.cardText}>Ăn uống</Text>
                <Text style={styles.cardAmount}>150,000đ</Text>
              </View>
              <View style={[styles.featureCard, styles.card2]}>
                <Text style={styles.cardEmoji}>🚗</Text>
                <Text style={styles.cardText}>Di chuyển</Text>
                <Text style={styles.cardAmount}>80,000đ</Text>
              </View>
            </>
          )}

          {index === 1 && (
            <>
              <View style={[styles.challengeCard, styles.challenge1]}>
                <Text style={styles.challengeEmoji}>🏆</Text>
                <Text style={styles.challengeTitle}>Thử thách hôm nay</Text>
                <Text style={styles.challengeTarget}>Tiết kiệm 50,000đ</Text>
              </View>
              <View style={[styles.rewardCard, styles.reward1]}>
                <Text style={styles.rewardText}>+10 điểm</Text>
                <Text style={styles.rewardEmoji}>⭐</Text>
              </View>
            </>
          )}

          {index === 2 && (
            <>
              <View style={[styles.groupCard, styles.group1]}>
                <Text style={styles.groupEmoji}>🏖️</Text>
                <Text style={styles.groupName}>Du lịch Đà Lạt</Text>
                <Text style={styles.groupMembers}>4 người</Text>
              </View>
              <View style={[styles.avatarGroup, styles.avatars1]}>
                <View style={[styles.avatar, { backgroundColor: '#FF6B6B' }]}>
                  <Text style={styles.avatarText}>A</Text>
                </View>
                <View style={[styles.avatar, { backgroundColor: '#4ECDC4' }]}>
                  <Text style={styles.avatarText}>B</Text>
                </View>
                <View style={[styles.avatar, { backgroundColor: '#45B7D1' }]}>
                  <Text style={styles.avatarText}>C</Text>
                </View>
              </View>
            </>
          )}
        </View>
      </View>
    );
  };

  const renderOnboardingItem = ({ item, index }: { item: OnboardingItem; index: number }) => {
    return (
      <View style={styles.slide}>
        <Animated.View style={[styles.content, { opacity: fadeAnim }]}>
          {renderIllustration(item, index)}

          <View style={styles.textContainer}>
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.description}>{item.description}</Text>
          </View>
        </Animated.View>
      </View>
    );
  };

  const renderPagination = () => (
    <View style={styles.pagination}>
      {onboardingData.map((_, index) => (
        <View
          key={index}
          style={[
            styles.dot,
            {
              backgroundColor:
                index === currentIndex ? Colors.primary[500] : 'rgba(255, 255, 255, 0.3)',
              width: index === currentIndex ? 28 : 8,
            },
          ]}
        />
      ))}
    </View>
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />

      {/* Skip button */}
      <TouchableOpacity style={styles.skipButton} onPress={handleSkip}>
        <Text style={styles.skipText}>Bỏ qua</Text>
        <Ionicons name="chevron-forward" size={16} color="#FFFFFF" />
      </TouchableOpacity>

      {/* Main content */}
      <FlatList
        ref={flatListRef}
        data={onboardingData}
        renderItem={renderOnboardingItem}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        keyExtractor={item => item.id}
        scrollEnabled={false} // Disable manual scrolling, use buttons only
      />

      {/* Footer */}
      <View style={styles.footer}>
        {renderPagination()}

        <View style={styles.buttonContainer}>
          {currentIndex > 0 && (
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => {
                const prevIndex = currentIndex - 1;
                setCurrentIndex(prevIndex);
                flatListRef.current?.scrollToIndex({ index: prevIndex, animated: true });
              }}
            >
              <Ionicons name="chevron-back" size={24} color={Colors.primary[500]} />
              <Text style={styles.backButtonText}>Quay lại</Text>
            </TouchableOpacity>
          )}

          <TouchableOpacity style={styles.nextButton} onPress={handleNext}>
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.nextButtonGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Text style={styles.nextButtonText}>
                {currentIndex === onboardingData.length - 1 ? 'Bắt đầu ngay' : 'Tiếp theo'}
              </Text>
              <Ionicons
                name={currentIndex === onboardingData.length - 1 ? 'rocket' : 'chevron-forward'}
                size={20}
                color="#FFFFFF"
              />
            </LinearGradient>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  skipButton: {
    position: 'absolute',
    top: 60,
    right: 20,
    zIndex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 20,
  },
  skipText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '500',
    marginRight: 4,
  },
  slide: {
    width: screenWidth,
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  illustrationContainer: {
    position: 'relative',
    marginBottom: 60,
    width: 300,
    height: 300,
    justifyContent: 'center',
    alignItems: 'center',
  },
  illustrationCircle: {
    width: 200,
    height: 200,
    borderRadius: 100,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
  },
  iconContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  emojiIcon: {
    fontSize: 40,
    marginBottom: 8,
  },
  decorativeCircle: {
    position: 'absolute',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 50,
  },
  circle1: {
    width: 20,
    height: 20,
    top: 30,
    right: 20,
  },
  circle2: {
    width: 12,
    height: 12,
    bottom: 40,
    left: 30,
  },
  circle3: {
    width: 16,
    height: 16,
    top: 60,
    left: 10,
  },
  featureCards: {
    position: 'absolute',
    width: '100%',
    height: '100%',
  },
  featureCard: {
    position: 'absolute',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
  },
  card1: {
    top: 50,
    left: -40,
    width: 80,
  },
  card2: {
    bottom: 50,
    right: -40,
    width: 80,
  },
  cardEmoji: {
    fontSize: 20,
    marginBottom: 4,
  },
  cardText: {
    fontSize: 10,
    color: '#666',
    marginBottom: 2,
  },
  cardAmount: {
    fontSize: 10,
    color: Colors.primary[500],
    fontWeight: 'bold',
  },
  challengeCard: {
    position: 'absolute',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
  },
  challenge1: {
    top: 40,
    left: -60,
    width: 120,
  },
  challengeEmoji: {
    fontSize: 24,
    marginBottom: 8,
  },
  challengeTitle: {
    fontSize: 10,
    color: '#666',
    marginBottom: 4,
    textAlign: 'center',
  },
  challengeTarget: {
    fontSize: 11,
    color: Colors.primary[500],
    fontWeight: 'bold',
  },
  rewardCard: {
    position: 'absolute',
    backgroundColor: '#FFD700',
    borderRadius: 20,
    padding: 8,
    alignItems: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
  },
  reward1: {
    bottom: 60,
    right: -50,
    width: 60,
    height: 60,
  },
  rewardText: {
    fontSize: 10,
    color: '#333',
    fontWeight: 'bold',
  },
  rewardEmoji: {
    fontSize: 16,
  },
  groupCard: {
    position: 'absolute',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
  },
  group1: {
    top: 40,
    left: -50,
    width: 100,
  },
  groupEmoji: {
    fontSize: 20,
    marginBottom: 4,
  },
  groupName: {
    fontSize: 10,
    color: '#333',
    fontWeight: 'bold',
    marginBottom: 2,
  },
  groupMembers: {
    fontSize: 9,
    color: '#666',
  },
  avatarGroup: {
    position: 'absolute',
    flexDirection: 'row',
  },
  avatars1: {
    bottom: 80,
    right: -60,
  },
  avatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: -8,
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  avatarText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  textContainer: {
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 28,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 16,
    fontWeight: 'bold',
    lineHeight: 34,
  },
  description: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: 10,
  },
  footer: {
    paddingHorizontal: 40,
    paddingBottom: 50,
    paddingTop: 20,
  },
  pagination: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 40,
  },
  dot: {
    height: 8,
    borderRadius: 4,
    marginHorizontal: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20,
  },
  backButtonText: {
    fontSize: 16,
    color: Colors.primary[500],
    fontWeight: '500',
    marginLeft: 4,
  },
  nextButton: {
    borderRadius: 12,
    overflow: 'hidden',
    flex: 1,
    marginLeft: 20,
  },
  nextButtonGradient: {
    paddingVertical: 16,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    minHeight: 56,
  },
  nextButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginRight: 8,
  },
});

export default OnboardingScreen;
