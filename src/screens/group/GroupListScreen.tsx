import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  StatusBar,
  Alert,
  Share,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { StackNavigationProp } from '@react-navigation/stack';
import { Colors } from '../../constants/colors';
import { GroupStackParamList } from '../../types';
import { BackButton, CustomAlert } from '../../components';

type GroupListNavigationProp = StackNavigationProp<GroupStackParamList, 'GroupList'>;

interface GroupData {
  id: string;
  name: string;
  description: string;
  memberCount: number;
  totalBudget: number;
  spent: number;
  balance: number;
  currency: string;
  lastActivity: string;
  coverImage: string;
  members: GroupMember[];
  inviteCode: string;
}

interface GroupMember {
  id: string;
  name: string;
  avatar: string;
  balance: number;
  isOwner: boolean;
}

const GroupListScreen: React.FC = () => {
  const navigation = useNavigation<GroupListNavigationProp>();
  const [activeTab, setActiveTab] = useState<'my-groups' | 'shared-with-me'>('my-groups');
  const [showShareErrorAlert, setShowShareErrorAlert] = useState(false);

  // Enhanced Vietnamese mock data with cultural context
  const myGroups: GroupData[] = [
    {
      id: '1',
      name: 'Du lịch Đà Lạt',
      description: 'Chuyến đi cuối tuần với bạn bè - Tết Dương lịch 2025',
      memberCount: 4,
      totalBudget: 5000000,
      spent: 2850000,
      balance: 2150000,
      currency: 'VND',
      lastActivity: '2 giờ trước',
      coverImage: '🏔️',
      inviteCode: 'DALAT2025',
      members: [
        { id: '1', name: 'Bạn', avatar: '👤', balance: -50000, isOwner: true },
        { id: '2', name: 'Minh', avatar: '🧑', balance: -350000, isOwner: false },
        { id: '3', name: 'Linh', avatar: '👩', balance: 250000, isOwner: false },
        { id: '4', name: 'Tuấn', avatar: '👨', balance: 150000, isOwner: false },
      ],
    },
    {
      id: '2',
      name: 'Nhà trọ Quận 3',
      description: 'Chi phí sinh hoạt: điện, nước, internet, dọn dẹp',
      memberCount: 3,
      totalBudget: 4500000,
      spent: 2100000,
      balance: 2400000,
      currency: 'VND',
      lastActivity: '1 ngày trước',
      coverImage: '🏠',
      inviteCode: 'TRONHQ3',
      members: [
        { id: '1', name: 'Bạn', avatar: '👤', balance: 150000, isOwner: true },
        { id: '2', name: 'Hương', avatar: '👩', balance: -80000, isOwner: false },
        { id: '3', name: 'Nam', avatar: '👨', balance: -70000, isOwner: false },
      ],
    },
    {
      id: '5',
      name: 'Cưới Tuấn & Linh',
      description: 'Mừng cưới anh Tuấn - chị Linh 💍',
      memberCount: 12,
      totalBudget: 15000000,
      spent: 8500000,
      balance: 6500000,
      currency: 'VND',
      lastActivity: '5 ngày trước',
      coverImage: '💒',
      inviteCode: 'WEDDING2025',
      members: [
        { id: '1', name: 'Bạn', avatar: '👤', balance: 50000, isOwner: false },
        { id: '13', name: 'Anh Hùng (tổ chức)', avatar: '👨‍💼', balance: 0, isOwner: true },
      ],
    },
  ];

  const sharedGroups: GroupData[] = [
    {
      id: '3',
      name: 'Team Building Công ty',
      description: 'Du lịch Vũng Tàu - Tháng 12/2024',
      memberCount: 8,
      totalBudget: 12000000,
      spent: 7800000,
      balance: 4200000,
      currency: 'VND',
      lastActivity: '3 ngày trước',
      coverImage: '🏖️',
      inviteCode: 'TEAMVT24',
      members: [
        { id: '1', name: 'Bạn', avatar: '👤', balance: 120000, isOwner: false },
        { id: '2', name: 'Anh Dũng (HR)', avatar: '👔', balance: 0, isOwner: true },
      ],
    },
    {
      id: '4',
      name: 'Họp lớp 12A1',
      description: 'Gặp mặt 10 năm tốt nghiệp - Khách sạn Rex Sài Gòn',
      memberCount: 25,
      totalBudget: 25000000,
      spent: 18500000,
      balance: 6500000,
      currency: 'VND',
      lastActivity: '1 tuần trước',
      coverImage: '🎓',
      inviteCode: 'LOP12A1',
      members: [
        { id: '1', name: 'Bạn', avatar: '👤', balance: 80000, isOwner: false },
        { id: '15', name: 'Thảo (lớp trưởng)', avatar: '👩‍🎓', balance: -50000, isOwner: true },
      ],
    },
  ];

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount);
  };

  const getBalanceColor = (balance: number) => {
    if (balance > 0) return Colors.primary[500];
    if (balance < 0) return '#FF6B6B';
    return '#666666';
  };

  const handleCreateGroup = () => {
    navigation.navigate('CreateGroup');
  };

  const handleGroupPress = (group: GroupData) => {
    navigation.navigate('GroupDetail', { groupId: group.id });
  };

  const handleShareInvite = async (group: GroupData) => {
    try {
      await Share.share({
        message: `Tham gia nhóm "${group.name}" trên ZBudget!\nMã mời: ${group.inviteCode}\nTải app ZBudget để quản lý chi tiêu nhóm dễ dàng!`,
        title: `Mời tham gia nhóm ${group.name}`,
      });
    } catch (error) {
      setShowShareErrorAlert(true);
    }
  };

  const renderGroupCard = (group: GroupData) => {
    const spentPercentage = (group.spent / group.totalBudget) * 100;
    const yourBalance = group.members.find(m => m.id === '1')?.balance || 0;

    return (
      <TouchableOpacity
        key={group.id}
        style={styles.groupCard}
        onPress={() => handleGroupPress(group)}
      >
        <View style={styles.groupHeader}>
          <View style={styles.groupInfo}>
            <View style={styles.groupTitleRow}>
              <Text style={styles.groupEmoji}>{group.coverImage}</Text>
              <View style={styles.groupTitleContainer}>
                <Text style={styles.groupName}>{group.name}</Text>
                <Text style={styles.groupDescription}>{group.description}</Text>
              </View>
            </View>
            <TouchableOpacity style={styles.shareButton} onPress={() => handleShareInvite(group)}>
              <Ionicons name="share-outline" size={20} color={Colors.primary[500]} />
            </TouchableOpacity>
          </View>

          <View style={styles.groupMeta}>
            <Text style={styles.memberCount}>{group.memberCount} thành viên</Text>
            <Text style={styles.lastActivity}>{group.lastActivity}</Text>
          </View>
        </View>

        <View style={styles.budgetInfo}>
          <View style={styles.budgetRow}>
            <Text style={styles.budgetLabel}>Ngân sách</Text>
            <Text style={styles.budgetAmount}>
              {formatCurrency(group.totalBudget)} {group.currency}
            </Text>
          </View>

          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View
                style={[styles.progressFill, { width: `${Math.min(spentPercentage, 100)}%` }]}
              />
            </View>
            <Text style={styles.progressText}>
              Đã chi: {formatCurrency(group.spent)} ({spentPercentage.toFixed(1)}%)
            </Text>
          </View>

          <View style={styles.balanceRow}>
            <Text style={styles.balanceLabel}>Số dư của bạn:</Text>
            <Text style={[styles.balanceAmount, { color: getBalanceColor(yourBalance) }]}>
              {yourBalance >= 0 ? '+' : ''}
              {formatCurrency(yourBalance)} {group.currency}
            </Text>
          </View>
        </View>

        <View style={styles.memberPreview}>
          <View style={styles.memberAvatars}>
            {group.members.slice(0, 4).map((member, index) => (
              <View
                key={member.id}
                style={[styles.memberAvatar, { marginLeft: index > 0 ? -8 : 0 }]}
              >
                <Text style={styles.memberAvatarText}>{member.avatar}</Text>
              </View>
            ))}
            {group.memberCount > 4 && (
              <View style={[styles.memberAvatar, styles.moreMembers, { marginLeft: -8 }]}>
                <Text style={styles.moreMembersText}>+{group.memberCount - 4}</Text>
              </View>
            )}
          </View>
          <Ionicons name="chevron-forward" size={20} color="#666666" />
        </View>
      </TouchableOpacity>
    );
  };

  const currentGroups = activeTab === 'my-groups' ? myGroups : sharedGroups;

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />
      <BackButton title="Nhóm của tôi" showHomeIcon={true} />

      {/* Tab Navigation */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'my-groups' && styles.activeTab]}
          onPress={() => setActiveTab('my-groups')}
        >
          <Text style={[styles.tabText, activeTab === 'my-groups' && styles.activeTabText]}>
            Nhóm của tôi ({myGroups.length})
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tab, activeTab === 'shared-with-me' && styles.activeTab]}
          onPress={() => setActiveTab('shared-with-me')}
        >
          <Text style={[styles.tabText, activeTab === 'shared-with-me' && styles.activeTabText]}>
            Được chia sẻ ({sharedGroups.length})
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {currentGroups.length > 0 ? (
          <View style={styles.groupList}>{currentGroups.map(renderGroupCard)}</View>
        ) : (
          <View style={styles.emptyState}>
            <Ionicons name="people-outline" size={64} color="#666666" />
            <Text style={styles.emptyTitle}>
              {activeTab === 'my-groups' ? 'Chưa có nhóm nào' : 'Chưa tham gia nhóm nào'}
            </Text>
            <Text style={styles.emptyDescription}>
              {activeTab === 'my-groups'
                ? 'Tạo nhóm đầu tiên để quản lý chi tiêu chung với bạn bè'
                : 'Chờ bạn bè mời bạn tham gia nhóm hoặc nhập mã mời'}
            </Text>
            {activeTab === 'my-groups' && (
              <TouchableOpacity style={styles.createGroupButton} onPress={handleCreateGroup}>
                <LinearGradient
                  colors={[Colors.primary[500], '#2E8B57']}
                  style={styles.createGroupGradient}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 0 }}
                >
                  <Ionicons name="add" size={20} color="#FFFFFF" />
                  <Text style={styles.createGroupText}>Tạo nhóm đầu tiên</Text>
                </LinearGradient>
              </TouchableOpacity>
            )}
          </View>
        )}

        <View style={styles.bottomSpacing} />
      </ScrollView>

      {/* Floating Action Button */}
      <TouchableOpacity style={styles.fab} onPress={handleCreateGroup}>
        <LinearGradient
          colors={[Colors.primary[500], '#2E8B57']}
          style={styles.fabGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <Ionicons name="add" size={28} color="#FFFFFF" />
        </LinearGradient>
      </TouchableOpacity>

      {/* Custom Alert for Share Error */}
      <CustomAlert
        visible={showShareErrorAlert}
        onClose={() => setShowShareErrorAlert(false)}
        title="Không thể chia sẻ"
        message="Xin lỗi, hiện tại không thể chia sẻ lời mời nhóm. Vui lòng thử lại sau hoặc copy mã mời để gửi thủ công."
        type="error"
        buttons={[
          {
            text: 'Đã hiểu',
            onPress: () => setShowShareErrorAlert(false),
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  createButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
  },
  tabContainer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginHorizontal: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  activeTab: {
    backgroundColor: Colors.primary[500],
  },
  tabText: {
    fontSize: 14,
    fontWeight: '500',
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
  },
  activeTabText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  scrollContainer: {
    flex: 1,
  },
  groupList: {
    paddingHorizontal: 20,
  },
  groupCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  groupHeader: {
    marginBottom: 16,
  },
  groupInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  groupTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  groupEmoji: {
    fontSize: 24,
    marginRight: 12,
  },
  groupTitleContainer: {
    flex: 1,
  },
  groupName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  groupDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  shareButton: {
    padding: 8,
    borderRadius: 8,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
  },
  groupMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  memberCount: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '500',
  },
  lastActivity: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  budgetInfo: {
    marginBottom: 16,
  },
  budgetRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  budgetLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  budgetAmount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  progressContainer: {
    marginBottom: 12,
  },
  progressBar: {
    height: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 3,
    marginBottom: 6,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primary[500],
    borderRadius: 3,
  },
  progressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  balanceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  balanceLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  balanceAmount: {
    fontSize: 14,
    fontWeight: '600',
  },
  memberPreview: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  memberAvatars: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  memberAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#2A4A5A',
  },
  memberAvatarText: {
    fontSize: 14,
  },
  moreMembers: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  moreMembersText: {
    fontSize: 10,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 20,
    marginBottom: 12,
    textAlign: 'center',
  },
  emptyDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 32,
  },
  createGroupButton: {
    borderRadius: 12,
    overflow: 'hidden',
  },
  createGroupGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 24,
  },
  createGroupText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
  },
  fab: {
    position: 'absolute',
    bottom: 30,
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  fabGradient: {
    width: '100%',
    height: '100%',
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bottomSpacing: {
    height: 100,
  },
});

export default GroupListScreen;
