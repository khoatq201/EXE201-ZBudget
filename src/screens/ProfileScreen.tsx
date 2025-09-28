import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  StatusBar,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';

import { Colors } from '../constants/colors';
import { useApp } from '../context/AppContext';
import { BackButton, CustomAlert } from '../components';

interface StatCardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, subtitle, icon, color }) => (
  <View style={styles.statCard}>
    <View style={[styles.statIcon, { backgroundColor: color + '20' }]}>
      <Ionicons name={icon} size={24} color={color} />
    </View>
    <View style={styles.statContent}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statTitle}>{title}</Text>
      {subtitle && <Text style={styles.statSubtitle}>{subtitle}</Text>}
    </View>
  </View>
);

interface AchievementProps {
  title: string;
  description: string;
  icon: string;
  isUnlocked: boolean;
  progress?: number;
}

const Achievement: React.FC<AchievementProps> = ({
  title,
  description,
  icon,
  isUnlocked,
  progress,
}) => (
  <View style={[styles.achievementCard, !isUnlocked && styles.lockedAchievement]}>
    <Text style={styles.achievementIcon}>{icon}</Text>
    <View style={styles.achievementContent}>
      <Text style={[styles.achievementTitle, !isUnlocked && styles.lockedText]}>{title}</Text>
      <Text style={[styles.achievementDescription, !isUnlocked && styles.lockedText]}>
        {description}
      </Text>
      {!isUnlocked && progress && (
        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${progress}%` }]} />
          </View>
          <Text style={styles.progressText}>{progress}%</Text>
        </View>
      )}
    </View>
    {isUnlocked && <Ionicons name="checkmark-circle" size={20} color={Colors.primary[500]} />}
  </View>
);

const ProfileScreen: React.FC = () => {
  const { state, logout } = useApp();
  const navigation = useNavigation();
  const [showLogoutAlert, setShowLogoutAlert] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  // Mock user data - in real app, this would come from API/storage
  const userStats = {
    totalSaved: 2400000,
    expensesThisMonth: 1800000,
    budgetGoals: 5,
    streakDays: 15,
    joinDate: '2024-01-15',
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  const achievements = [
    {
      title: 'Người mới bắt đầu',
      description: 'Hoàn thành thiết lập tài khoản đầu tiên',
      icon: '🌟',
      isUnlocked: true,
    },
    {
      title: 'Tiết kiệm đầu tiên',
      description: 'Tiết kiệm được 1 triệu đồng',
      icon: '💰',
      isUnlocked: true,
    },
    {
      title: 'Kỷ luật 7 ngày',
      description: 'Ghi chép chi tiêu liên tục 7 ngày',
      icon: '📝',
      isUnlocked: true,
    },
    {
      title: 'Bậc thầy ngân sách',
      description: 'Đạt được 5 mục tiêu ngân sách',
      icon: '🎯',
      isUnlocked: false,
      progress: 60,
    },
    {
      title: 'Triệu phú nhỏ',
      description: 'Tiết kiệm được 5 triệu đồng',
      icon: '💎',
      isUnlocked: false,
      progress: 48,
    },
    {
      title: 'Streak Master',
      description: 'Ghi chép chi tiêu liên tục 30 ngày',
      icon: '🔥',
      isUnlocked: false,
      progress: 50,
    },
  ];

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

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />
      <BackButton title="Profile" showHomeIcon={true} />

      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Profile Header */}
        <View style={styles.profileHeader}>
          <LinearGradient
            colors={[Colors.primary[500], '#2E8B57']}
            style={styles.profileGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            <View style={styles.avatarContainer}>
              <View style={styles.avatar}>
                <Ionicons name="person" size={40} color="#FFFFFF" />
              </View>
              <TouchableOpacity style={styles.editAvatarButton}>
                <Ionicons name="camera" size={16} color="#FFFFFF" />
              </TouchableOpacity>
            </View>

            <Text style={styles.userName}>{state.user?.name || 'Người dùng'}</Text>
            <Text style={styles.userEmail}>{state.user?.email || 'user@example.com'}</Text>

            <View style={styles.membershipInfo}>
              {state.user?.isPremium ? (
                <View style={styles.premiumBadge}>
                  <Ionicons name="diamond" size={16} color="#FFD700" />
                  <Text style={styles.premiumText}>Premium Member</Text>
                </View>
              ) : (
                <TouchableOpacity
                  style={styles.upgradeButton}
                  onPress={() => navigation.navigate('Premium' as never)}
                >
                  <Text style={styles.upgradeText}>Nâng cấp Premium</Text>
                </TouchableOpacity>
              )}

              <Text style={styles.joinDate}>Tham gia từ {formatDate(userStats.joinDate)}</Text>
            </View>
          </LinearGradient>
        </View>

        {/* Stats Section */}
        <View style={styles.statsSection}>
          <Text style={styles.sectionTitle}>Thống kê cá nhân</Text>
          <View style={styles.statsGrid}>
            <StatCard
              title="Đã tiết kiệm"
              value={formatCurrency(userStats.totalSaved)}
              subtitle="Tổng cộng"
              icon="wallet"
              color={Colors.primary[500]}
            />
            <StatCard
              title="Chi tiêu tháng này"
              value={formatCurrency(userStats.expensesThisMonth)}
              subtitle="30 ngày qua"
              icon="trending-down"
              color="#FF6B6B"
            />
            <StatCard
              title="Mục tiêu hoàn thành"
              value={`${userStats.budgetGoals}/8`}
              subtitle="Ngân sách"
              icon="checkmark-circle"
              color="#4ECDC4"
            />
            <StatCard
              title="Streak hiện tại"
              value={`${userStats.streakDays} ngày`}
              subtitle="Ghi chép liên tục"
              icon="flame"
              color="#FFA726"
            />
          </View>
        </View>

        {/* Achievements Section */}
        <View style={styles.achievementsSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Thành tích</Text>
            <Text style={styles.achievementCount}>
              {achievements.filter(a => a.isUnlocked).length}/{achievements.length}
            </Text>
          </View>

          <View style={styles.achievementsList}>
            {achievements.map((achievement, index) => (
              <Achievement
                key={index}
                title={achievement.title}
                description={achievement.description}
                icon={achievement.icon}
                isUnlocked={achievement.isUnlocked}
                progress={achievement.progress}
              />
            ))}
          </View>
        </View>

        {/* Quick Actions */}
        <View style={styles.quickActionsSection}>
          <Text style={styles.sectionTitle}>Hành động nhanh</Text>
          <View style={styles.quickActionsList}>
            <TouchableOpacity
              style={styles.quickActionItem}
              onPress={() => navigation.navigate('Settings' as never)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="settings" size={20} color={Colors.primary[500]} />
              </View>
              <Text style={styles.quickActionText}>Cài đặt</Text>
              <Ionicons name="chevron-forward" size={16} color="rgba(255,255,255,0.5)" />
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.quickActionItem}
              onPress={() => navigation.navigate('TransactionHistory' as never)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="list" size={20} color={Colors.primary[500]} />
              </View>
              <Text style={styles.quickActionText}>Lịch sử giao dịch</Text>
              <Ionicons name="chevron-forward" size={16} color="rgba(255,255,255,0.5)" />
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.quickActionItem}
              onPress={() => navigation.navigate('Reports' as never)}
            >
              <View style={styles.quickActionIcon}>
                <Ionicons name="bar-chart" size={20} color={Colors.primary[500]} />
              </View>
              <Text style={styles.quickActionText}>Báo cáo tài chính</Text>
              <Ionicons name="chevron-forward" size={16} color="rgba(255,255,255,0.5)" />
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.quickActionItem, styles.logoutAction]}
              onPress={() => setShowLogoutAlert(true)}
            >
              <View style={[styles.quickActionIcon, styles.logoutIcon]}>
                <Ionicons name="log-out" size={20} color="#FF6B6B" />
              </View>
              <Text style={[styles.quickActionText, styles.logoutText]}>Đăng xuất</Text>
              <Ionicons name="chevron-forward" size={16} color="rgba(255,255,255,0.5)" />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.bottomSpacing} />
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
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  profileHeader: {
    marginHorizontal: 20,
    marginTop: 20,
    marginBottom: 30,
    borderRadius: 16,
    overflow: 'hidden',
  },
  profileGradient: {
    padding: 30,
    alignItems: 'center',
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  editAvatarButton: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#2E8B57',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  userName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  userEmail: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 16,
  },
  membershipInfo: {
    alignItems: 'center',
  },
  premiumBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 215, 0, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    marginBottom: 8,
  },
  premiumText: {
    fontSize: 14,
    color: '#FFD700',
    marginLeft: 6,
    fontWeight: '600',
  },
  upgradeButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 16,
    marginBottom: 8,
  },
  upgradeText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  joinDate: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  statsSection: {
    marginHorizontal: 20,
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  achievementCount: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  statCard: {
    flex: 1,
    minWidth: '47%',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  statIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  statContent: {
    flex: 1,
  },
  statValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  statTitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 2,
  },
  statSubtitle: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  achievementsSection: {
    marginHorizontal: 20,
    marginBottom: 30,
  },
  achievementsList: {
    gap: 12,
  },
  achievementCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  lockedAchievement: {
    opacity: 0.6,
  },
  achievementIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  achievementContent: {
    flex: 1,
  },
  achievementTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  achievementDescription: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 16,
  },
  lockedText: {
    color: 'rgba(255, 255, 255, 0.5)',
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  progressBar: {
    flex: 1,
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 2,
    marginRight: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primary[500],
    borderRadius: 2,
  },
  progressText: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.7)',
    minWidth: 30,
  },
  quickActionsSection: {
    marginHorizontal: 20,
    marginBottom: 30,
  },
  quickActionsList: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    overflow: 'hidden',
  },
  quickActionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  quickActionIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  quickActionText: {
    flex: 1,
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  logoutAction: {
    borderBottomWidth: 0,
  },
  logoutIcon: {
    backgroundColor: 'rgba(255, 107, 107, 0.2)',
  },
  logoutText: {
    color: '#FF6B6B',
  },
  bottomSpacing: {
    height: 40,
  },
});

export default ProfileScreen;
