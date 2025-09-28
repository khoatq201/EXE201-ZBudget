import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Switch, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { StackNavigationProp } from '@react-navigation/stack';

import { Colors } from '../constants/colors';
import { useApp } from '../context/AppContext';
import { BackButton, CustomAlert } from '../components';
import { Theme } from '../types';
import type { SettingsStackParamList } from '../navigation/SettingsNavigator';

type SettingsNavigationProp = StackNavigationProp<SettingsStackParamList, 'SettingsMain'>;

interface SettingItemProps {
  icon: keyof typeof Ionicons.glyphMap;
  title: string;
  subtitle?: string;
  rightComponent?: React.ReactNode;
  onPress?: () => void;
  showArrow?: boolean;
}

const SettingItem: React.FC<SettingItemProps> = ({
  icon,
  title,
  subtitle,
  rightComponent,
  onPress,
  showArrow = true,
}) => {
  return (
    <TouchableOpacity style={styles.settingItem} onPress={onPress} disabled={!onPress}>
      <View style={styles.settingIcon}>
        <Ionicons name={icon} size={24} color={Colors.primary[500]} />
      </View>
      <View style={styles.settingContent}>
        <Text style={styles.settingTitle}>{title}</Text>
        {subtitle && <Text style={styles.settingSubtitle}>{subtitle}</Text>}
      </View>
      <View style={styles.settingRight}>
        {rightComponent}
        {showArrow && onPress && (
          <Ionicons name="chevron-forward" size={20} color="rgba(255, 255, 255, 0.5)" />
        )}
      </View>
    </TouchableOpacity>
  );
};

const SettingsScreen: React.FC = () => {
  const { state, logout, updateTheme } = useApp();
  const navigation = useNavigation<SettingsNavigationProp>();
  const [notifications, setNotifications] = useState(true);
  const [biometric, setBiometric] = useState(true);
  const [dataSync, setDataSync] = useState(false);
  const [showLogoutAlert, setShowLogoutAlert] = useState(false);
  const [showThemeAlert, setShowThemeAlert] = useState(false);
  const [showFeatureAlert, setShowFeatureAlert] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = () => {
    setShowLogoutAlert(true);
  };

  const handleThemeChange = () => {
    setShowThemeAlert(true);
  };

  const getThemeText = (theme: Theme) => {
    switch (theme) {
      case Theme.LIGHT:
        return 'Giao diện sáng';
      case Theme.DARK:
        return 'Giao diện tối';
      case Theme.SYSTEM:
        return 'Theo hệ thống';
      default:
        return 'Theo hệ thống';
    }
  };

  return (
    <View style={styles.container}>
      <BackButton title="Cài đặt" showHomeIcon={true} />
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Profile Section */}
        <View style={styles.profileCard}>
          <View style={styles.profileContent}>
            <View style={styles.avatarContainer}>
              <Ionicons name="person" size={40} color="#FFFFFF" />
            </View>
            <View style={styles.profileInfo}>
              <Text style={styles.profileName}>{state.user?.name || 'Người dùng'}</Text>
              <Text style={styles.profileEmail}>{state.user?.email || 'user@example.com'}</Text>
              {state.user?.isPremium && (
                <View style={styles.premiumBadge}>
                  <Ionicons name="star" size={12} color="#FFD700" />
                  <Text style={styles.premiumText}>Premium</Text>
                </View>
              )}
            </View>
            <TouchableOpacity style={styles.editProfileButton}>
              <Ionicons name="create-outline" size={20} color={Colors.primary[500]} />
            </TouchableOpacity>
          </View>
        </View>

        {/* App Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Cài đặt ứng dụng</Text>
          <View style={styles.settingsCard}>
            <SettingItem
              icon="notifications-outline"
              title="Thông báo"
              subtitle="Nhận thông báo về chi tiêu và ngân sách"
              rightComponent={
                <Switch
                  value={notifications}
                  onValueChange={setNotifications}
                  trackColor={{ false: Colors.dark[200], true: Colors.primary[200] }}
                  thumbColor={notifications ? Colors.primary[500] : Colors.dark[400]}
                />
              }
              showArrow={false}
            />
            <SettingItem
              icon="finger-print-outline"
              title="Xác thực sinh trắc học"
              subtitle="Sử dụng vân tay hoặc Face ID để đăng nhập"
              rightComponent={
                <Switch
                  value={biometric}
                  onValueChange={setBiometric}
                  trackColor={{ false: Colors.dark[200], true: Colors.primary[200] }}
                  thumbColor={biometric ? Colors.primary[500] : Colors.dark[400]}
                />
              }
              showArrow={false}
            />
            <SettingItem
              icon="color-palette-outline"
              title="Giao diện"
              subtitle={getThemeText(state.theme)}
              onPress={handleThemeChange}
            />
            <SettingItem
              icon="language-outline"
              title="Ngôn ngữ"
              subtitle="Tiếng Việt"
              onPress={() => setShowFeatureAlert(true)}
            />
          </View>
        </View>

        {/* Data & Privacy */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Dữ liệu & Bảo mật</Text>
          <View style={styles.settingsCard}>
            <SettingItem
              icon="list-outline"
              title="Lịch sử giao dịch"
              subtitle="Xem và quản lý tất cả giao dịch"
              onPress={() => (navigation as any).navigate('Home', { screen: 'TransactionHistory' })}
            />
            <SettingItem
              icon="cloud-outline"
              title="Đồng bộ dữ liệu"
              subtitle="Đồng bộ dữ liệu với cloud"
              rightComponent={
                <Switch
                  value={dataSync}
                  onValueChange={setDataSync}
                  trackColor={{ false: Colors.dark[200], true: Colors.primary[200] }}
                  thumbColor={dataSync ? Colors.primary[500] : Colors.dark[400]}
                />
              }
              showArrow={false}
            />
            <SettingItem
              icon="download-outline"
              title="Xuất dữ liệu"
              subtitle="Tải xuống dữ liệu cá nhân"
              onPress={() => setShowFeatureAlert(true)}
            />
            <SettingItem
              icon="shield-checkmark-outline"
              title="Chính sách bảo mật"
              onPress={() => setShowFeatureAlert(true)}
            />
            <SettingItem
              icon="document-text-outline"
              title="Điều khoản sử dụng"
              onPress={() => setShowFeatureAlert(true)}
            />
          </View>
        </View>

        {/* Support */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Hỗ trợ</Text>
          <View style={styles.settingsCard}>
            <SettingItem
              icon="help-circle-outline"
              title="Trung tâm trợ giúp"
              onPress={() => setShowFeatureAlert(true)}
            />
            <SettingItem
              icon="mail-outline"
              title="Liên hệ hỗ trợ"
              onPress={() => setShowFeatureAlert(true)}
            />
            <SettingItem
              icon="star-outline"
              title="Đánh giá ứng dụng"
              onPress={() => setShowFeatureAlert(true)}
            />
            <SettingItem
              icon="information-circle-outline"
              title="Về ứng dụng"
              subtitle="Phiên bản 1.0.0"
              onPress={() => setShowFeatureAlert(true)}
            />
          </View>
        </View>

        {/* Premium */}
        {!state.user?.isPremium && (
          <View style={styles.section}>
            <TouchableOpacity
              style={styles.premiumButton}
              onPress={() => navigation.navigate('Premium')}
            >
              <Ionicons name="star" size={20} color="#FFFFFF" />
              <Text style={styles.premiumButtonText}>Nâng cấp Premium</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Logout */}
        <View style={styles.section}>
          <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
            <Ionicons name="log-out" size={20} color="#FF6B6B" />
            <Text style={styles.logoutButtonText}>Đăng xuất</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.bottomSpacing} />
      </ScrollView>

      {/* Custom Alerts */}
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
            onPress: async () => {
              if (isLoggingOut) return;

              setIsLoggingOut(true);
              setShowLogoutAlert(false);

              try {
                await logout();
              } catch (error) {
                console.error('Logout error:', error);
                setIsLoggingOut(false);
              }
            },
            type: 'danger',
            icon: 'log-out-outline',
          },
        ]}
      />

      <CustomAlert
        visible={showThemeAlert}
        onClose={() => setShowThemeAlert(false)}
        title="Chọn giao diện"
        message="Chọn giao diện bạn muốn sử dụng"
        type="info"
        buttons={[
          {
            text: 'Hủy',
            onPress: () => setShowThemeAlert(false),
            type: 'secondary',
          },
          {
            text: 'Sáng',
            onPress: () => {
              setShowThemeAlert(false);
              updateTheme(Theme.LIGHT);
            },
            type: 'primary',
            icon: 'sunny-outline',
          },
          {
            text: 'Tối',
            onPress: () => {
              setShowThemeAlert(false);
              updateTheme(Theme.DARK);
            },
            type: 'primary',
            icon: 'moon-outline',
          },
        ]}
      />

      <CustomAlert
        visible={showFeatureAlert}
        onClose={() => setShowFeatureAlert(false)}
        title="Thông báo"
        message="Tính năng đang được phát triển và sẽ có mặt trong phiên bản tiếp theo!"
        type="info"
        buttons={[
          {
            text: 'Đã hiểu',
            onPress: () => setShowFeatureAlert(false),
            type: 'primary',
            icon: 'checkmark-outline',
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
  profileCard: {
    margin: 20,
    marginBottom: 16,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 20,
  },
  profileContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatarContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: Colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 4,
    fontWeight: 'bold',
  },
  profileEmail: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  premiumBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFD700' + '20',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
    alignSelf: 'flex-start',
  },
  premiumText: {
    fontSize: 12,
    color: '#FFD700',
    marginLeft: 2,
    fontWeight: '600',
  },
  editProfileButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  section: {
    marginHorizontal: 20,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    color: '#FFFFFF',
    marginBottom: 16,
    fontWeight: 'bold',
  },
  settingsCard: {
    padding: 0,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  settingIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  settingContent: {
    flex: 1,
  },
  settingTitle: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  settingSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 2,
  },
  settingRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  premiumButton: {
    backgroundColor: Colors.primary[500],
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  premiumButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
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
  logoutButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF6B6B',
    marginLeft: 8,
  },
  bottomSpacing: {
    height: 40,
  },
});

export default SettingsScreen;
