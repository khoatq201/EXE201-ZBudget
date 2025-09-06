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
  Modal,
  Platform,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import type { StackNavigationProp } from '@react-navigation/stack';
import { Colors } from '../../constants/colors';
import { GroupStackParamList } from '../../types';

type GroupDetailNavigationProp = StackNavigationProp<GroupStackParamList, 'GroupDetail'>;
type GroupDetailRouteProp = RouteProp<GroupStackParamList, 'GroupDetail'>;

interface GroupMember {
  id: string;
  name: string;
  avatar: string;
  balance: number;
  isOwner: boolean;
  joinedAt: string;
  totalPaid: number;
  totalOwed: number;
}

interface Transaction {
  id: string;
  type: 'expense' | 'payment' | 'settlement';
  amount: number;
  description: string;
  paidBy: string;
  paidByName: string;
  paidByAvatar: string;
  splitBetween: string[];
  date: string;
  time: string;
  category: string;
  categoryIcon: string;
  receiptImage?: string;
}

interface GroupData {
  id: string;
  name: string;
  description: string;
  coverImage: string;
  totalBudget: number;
  spent: number;
  currency: string;
  inviteCode: string;
  createdAt: string;
  members: GroupMember[];
  transactions: Transaction[];
}

const GroupDetailScreen: React.FC = () => {
  const navigation = useNavigation<GroupDetailNavigationProp>();
  const route = useRoute<GroupDetailRouteProp>();
  const { groupId } = route.params;
  const [activeTab, setActiveTab] = useState<'overview' | 'transactions' | 'members'>('overview');
  const [showSettingsModal, setShowSettingsModal] = useState(false);

  // Get group data based on groupId from route params
  const getGroupData = (id: string): GroupData => {
    // In a real app, this would fetch from API/database
    const allGroups: Record<string, GroupData> = {
      '1': {
        id: '1',
        name: 'Du lịch Đà Lạt',
        description: 'Chuyến đi cuối tuần với bạn bè - Tết Dương lịch 2025',
        coverImage: '🏔️',
        totalBudget: 5000000,
        spent: 2850000,
        currency: 'VND',
        inviteCode: 'DALAT2025',
        createdAt: '2025-06-20',
        members: [
          {
            id: '1',
            name: 'Bạn (Quản trị viên)',
            avatar: '👤',
            balance: -50000,
            isOwner: true,
            joinedAt: '2025-06-20',
            totalPaid: 1200000,
            totalOwed: 712500,
          },
          {
            id: '2',
            name: 'Minh',
            avatar: '🧑',
            balance: -350000,
            isOwner: false,
            joinedAt: '2025-06-20',
            totalPaid: 450000,
            totalOwed: 712500,
          },
          {
            id: '3',
            name: 'Linh',
            avatar: '👩',
            balance: 250000,
            isOwner: false,
            joinedAt: '2025-06-20',
            totalPaid: 950000,
            totalOwed: 712500,
          },
          {
            id: '4',
            name: 'Tuấn',
            avatar: '👨',
            balance: 150000,
            isOwner: false,
            joinedAt: '2025-06-21',
            totalPaid: 250000,
            totalOwed: 712500,
          },
        ],
        transactions: [
          {
            id: '1',
            type: 'expense',
            amount: 800000,
            description: 'Khách sạn Đà Lạt Palace - 2 đêm',
            paidBy: '3',
            paidByName: 'Linh',
            paidByAvatar: '👩',
            splitBetween: ['1', '2', '3', '4'],
            date: '26/06/2025',
            time: '14:30',
            category: 'Lưu trú',
            categoryIcon: '🏨',
          },
          {
            id: '2',
            type: 'expense',
            amount: 450000,
            description: 'Bữa tối BBQ - Quán Út Bích',
            paidBy: '1',
            paidByName: 'Bạn',
            paidByAvatar: '👤',
            splitBetween: ['1', '2', '3', '4'],
            date: '26/06/2025',
            time: '19:15',
            category: 'Ăn uống',
            categoryIcon: '🍽️',
          },
          {
            id: '3',
            type: 'expense',
            amount: 350000,
            description: 'Xe thuê đi chợ Đà Lạt',
            paidBy: '2',
            paidByName: 'Minh',
            paidByAvatar: '🧑',
            splitBetween: ['1', '2', '3', '4'],
            date: '27/06/2025',
            time: '09:45',
            category: 'Di chuyển',
            categoryIcon: '🚗',
          },
          {
            id: '4',
            type: 'expense',
            amount: 280000,
            description: 'Đặc sản Đà Lạt - Artichoke, socola',
            paidBy: '4',
            paidByName: 'Tuấn',
            paidByAvatar: '👨',
            splitBetween: ['1', '2', '3', '4'],
            date: '27/06/2025',
            time: '16:20',
            category: 'Mua sắm',
            categoryIcon: '🛍️',
          },
          {
            id: '5',
            type: 'payment',
            amount: 500000,
            description: 'Minh trả tiền cho Linh',
            paidBy: '2',
            paidByName: 'Minh',
            paidByAvatar: '🧑',
            splitBetween: ['3'],
            date: '27/06/2025',
            time: '20:00',
            category: 'Thanh toán',
            categoryIcon: '💰',
          },
        ],
      },
      '2': {
        id: '2',
        name: 'Nhà trọ Quận 3',
        description: 'Chi phí sinh hoạt: điện, nước, internet, dọn dẹp',
        coverImage: '🏠',
        totalBudget: 4500000,
        spent: 2100000,
        currency: 'VND',
        inviteCode: 'TRONHQ3',
        createdAt: '2025-01-15',
        members: [
          {
            id: '1',
            name: 'Bạn (Quản trị viên)',
            avatar: '👤',
            balance: 150000,
            isOwner: true,
            joinedAt: '2025-01-15',
            totalPaid: 850000,
            totalOwed: 700000,
          },
          {
            id: '5',
            name: 'Hương',
            avatar: '👩',
            balance: -80000,
            isOwner: false,
            joinedAt: '2025-01-15',
            totalPaid: 620000,
            totalOwed: 700000,
          },
          {
            id: '6',
            name: 'Nam',
            avatar: '👨',
            balance: -70000,
            isOwner: false,
            joinedAt: '2025-01-20',
            totalPaid: 630000,
            totalOwed: 700000,
          },
        ],
        transactions: [
          {
            id: '6',
            type: 'expense',
            amount: 450000,
            description: 'Tiền điện tháng 6',
            paidBy: '1',
            paidByName: 'Bạn',
            paidByAvatar: '👤',
            splitBetween: ['1', '5', '6'],
            date: '05/06/2025',
            time: '18:00',
            category: 'Tiện ích',
            categoryIcon: '⚡',
          },
          {
            id: '7',
            type: 'expense',
            amount: 120000,
            description: 'Tiền nước tháng 6',
            paidBy: '5',
            paidByName: 'Hương',
            paidByAvatar: '👩',
            splitBetween: ['1', '5', '6'],
            date: '10/06/2025',
            time: '19:30',
            category: 'Tiện ích',
            categoryIcon: '💧',
          },
        ],
      },
    };

    return allGroups[id] || allGroups['1']; // Default to first group if not found
  };

  const groupData: GroupData = getGroupData(groupId);

  // Mock data backup
  const backupGroupData: GroupData = {
    id: groupId,
    name: 'Du lịch Đà Lạt',
    description: 'Chuyến đi cuối tuần với bạn bè - Tết Dương lịch 2025',
    coverImage: '🏔️',
    totalBudget: 5000000,
    spent: 2850000,
    currency: 'VND',
    inviteCode: 'DALAT2025',
    createdAt: '2025-06-20',
    members: [
      {
        id: '1',
        name: 'Bạn (Quản trị viên)',
        avatar: '👤',
        balance: -50000,
        isOwner: true,
        joinedAt: '2025-06-20',
        totalPaid: 1200000,
        totalOwed: 712500,
      },
      {
        id: '2',
        name: 'Minh',
        avatar: '🧑',
        balance: -350000,
        isOwner: false,
        joinedAt: '2025-06-20',
        totalPaid: 450000,
        totalOwed: 712500,
      },
      {
        id: '3',
        name: 'Linh',
        avatar: '👩',
        balance: 250000,
        isOwner: false,
        joinedAt: '2025-06-20',
        totalPaid: 950000,
        totalOwed: 712500,
      },
      {
        id: '4',
        name: 'Tuấn',
        avatar: '👨',
        balance: 150000,
        isOwner: false,
        joinedAt: '2025-06-21',
        totalPaid: 250000,
        totalOwed: 712500,
      },
    ],
    transactions: [
      {
        id: '1',
        type: 'expense',
        amount: 800000,
        description: 'Khách sạn Đà Lạt Palace - 2 đêm',
        paidBy: '3',
        paidByName: 'Linh',
        paidByAvatar: '👩',
        splitBetween: ['1', '2', '3', '4'],
        date: '26/06/2025',
        time: '14:30',
        category: 'Lưu trú',
        categoryIcon: '🏨',
      },
      {
        id: '2',
        type: 'expense',
        amount: 450000,
        description: 'Bữa tối BBQ - Quán Út Bích',
        paidBy: '1',
        paidByName: 'Bạn',
        paidByAvatar: '👤',
        splitBetween: ['1', '2', '3', '4'],
        date: '26/06/2025',
        time: '19:15',
        category: 'Ăn uống',
        categoryIcon: '🍽️',
      },
      {
        id: '3',
        type: 'expense',
        amount: 300000,
        description: 'Vé cáp treo Núi Bà - 4 vé',
        paidBy: '2',
        paidByName: 'Minh',
        paidByAvatar: '🧑',
        splitBetween: ['1', '2', '3', '4'],
        date: '27/06/2025',
        time: '09:00',
        category: 'Giải trí',
        categoryIcon: '🎢',
      },
      {
        id: '4',
        type: 'expense',
        amount: 600000,
        description: 'Thuê xe Vios - 2 ngày từ Grab Car',
        paidBy: '3',
        paidByName: 'Linh',
        paidByAvatar: '👩',
        splitBetween: ['1', '2', '3', '4'],
        date: '27/06/2025',
        time: '10:30',
        category: 'Di chuyển',
        categoryIcon: '🚗',
      },
      {
        id: '5',
        type: 'payment',
        amount: 200000,
        description: 'Minh trả Linh',
        paidBy: '2',
        paidByName: 'Minh',
        paidByAvatar: '🧑',
        splitBetween: ['3'],
        date: '27/06/2025',
        time: '20:00',
        category: 'Thanh toán',
        categoryIcon: '💰',
      },
      {
        id: '6',
        type: 'expense',
        amount: 350000,
        description: 'Bánh mì xíu mại + cà phê sữa đá - Quán Bà Năm',
        paidBy: '4',
        paidByName: 'Tuấn',
        paidByAvatar: '👨',
        splitBetween: ['1', '2', '3', '4'],
        date: '28/06/2025',
        time: '08:30',
        category: 'Ăn uống',
        categoryIcon: '☕',
      },
      {
        id: '7',
        type: 'expense',
        amount: 350000,
        description: 'Mứt dâu tây + bánh tráng nướng - Chợ Đà Lạt',
        paidBy: '1',
        paidByName: 'Bạn',
        paidByAvatar: '👤',
        splitBetween: ['1', '2', '3', '4'],
        date: '28/06/2025',
        time: '16:45',
        category: 'Mua sắm',
        categoryIcon: '🛍️',
      },
    ],
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN').format(amount);
  };

  const getBalanceColor = (balance: number) => {
    if (balance > 0) return Colors.primary[500];
    if (balance < 0) return '#FF6B6B';
    return '#666666';
  };

  const getBalanceText = (balance: number) => {
    if (balance > 0) return `Được nợ ${formatCurrency(balance)}`;
    if (balance < 0) return `Nợ ${formatCurrency(Math.abs(balance))}`;
    return 'Đã thanh toán đủ';
  };

  const handleAddExpense = () => {
    Alert.alert('💰 Thêm chi tiêu nhóm', `Thêm chi tiêu cho nhóm "${groupData.name}"`, [
      { text: 'Hủy', style: 'cancel' },
      {
        text: '📷 Chụp hoá đơn',
        onPress: () =>
          Alert.alert('AI Scanner', 'Tính năng quét hoá đơn cho nhóm đang được phát triển!'),
      },
      {
        text: '✏️ Nhập tay',
        onPress: () => {
          // In a real app, navigate to AddExpense with group context
          Alert.alert('🚀 Chuyển hướng', 'Sẽ chuyển đến màn hình nhập chi tiêu với ngữ cảnh nhóm!');
        },
      },
    ]);
  };

  const handleSettleUp = () => {
    // Enhanced debt simplification algorithm (Splitwise-inspired)
    const membersWhoOwe = groupData.members.filter(m => m.balance < 0);
    const membersWhoPaid = groupData.members.filter(m => m.balance > 0);

    if (membersWhoOwe.length === 0) {
      Alert.alert('✅ Hoàn tất', 'Tất cả thành viên đã thanh toán xong!');
      return;
    }

    // Smart debt simplification - minimize number of transactions
    const optimizedTransactions = calculateOptimalSettlement(membersWhoOwe, membersWhoPaid);

    let settleMessage = '🧠 Tối ưu hóa thanh toán thông minh:\n\n';

    optimizedTransactions.forEach(transaction => {
      settleMessage += `💸 ${transaction.from} → ${transaction.to}: ${formatCurrency(transaction.amount)}\n`;
    });

    settleMessage += `\n✨ Chỉ cần ${optimizedTransactions.length} giao dịch thay vì ${membersWhoOwe.length * membersWhoPaid.length}!\n\n`;

    settleMessage += '💰 Chi tiết số dư:\n\n';

    membersWhoOwe.forEach(member => {
      settleMessage += `• ${member.name}: cần trả ${formatCurrency(Math.abs(member.balance))}\n`;
    });

    membersWhoPaid.forEach(member => {
      settleMessage += `• ${member.name}: được nhận ${formatCurrency(member.balance)}\n`;
    });

    Alert.alert('🧾 Thanh toán nhóm thông minh', settleMessage, [
      { text: 'Hủy', style: 'cancel' },
      {
        text: '📱 Gửi nhắc nhở',
        onPress: () => handleSendReminders(optimizedTransactions),
      },
      {
        text: '📧 Xuất báo cáo',
        onPress: () => handleExportReport(optimizedTransactions),
      },
      {
        text: '💳 Thanh toán',
        onPress: () => handleProcessPayments(optimizedTransactions),
      },
    ]);
  };

  // Splitwise-inspired debt simplification algorithm
  const calculateOptimalSettlement = (debtors: GroupMember[], creditors: GroupMember[]) => {
    const transactions = [];
    const debtorsCopy = debtors.map(d => ({ ...d, remaining: Math.abs(d.balance) }));
    const creditorsCopy = creditors.map(c => ({ ...c, remaining: c.balance }));

    for (const debtor of debtorsCopy) {
      for (const creditor of creditorsCopy) {
        if (debtor.remaining <= 0 || creditor.remaining <= 0) continue;

        const amount = Math.min(debtor.remaining, creditor.remaining);
        transactions.push({
          from: debtor.name,
          to: creditor.name,
          amount: amount,
        });

        debtor.remaining -= amount;
        creditor.remaining -= amount;
      }
    }

    return transactions;
  };

  const handleSendReminders = (transactions: any[]) => {
    Alert.alert(
      '🚀 Nhắc nhở đã gửi',
      `Đã gửi ${transactions.length} thông báo thanh toán tới các thành viên!`
    );
  };

  const handleExportReport = (transactions: any[]) => {
    Alert.alert('📊 Xuất báo cáo', 'Đang xuất báo cáo chi tiết... Sẽ chia sẻ qua email/Zalo!');
  };

  const handleProcessPayments = (transactions: any[]) => {
    Alert.alert(
      '🎉 Thanh toán thành công!',
      'Tất cả giao dịch đã được ghi nhận. Số dư nhóm đã cân bằng!'
    );
  };

  const handleShareInvite = async () => {
    try {
      const shareMessage = `🎉 Hãy tham gia nhóm "${groupData.name}" trên ZBudget!\n\n📝 Mô tả: ${groupData.description}\n💰 Ngân sách: ${formatCurrency(groupData.totalBudget)} ${groupData.currency}\n👥 Hiện tại: ${groupData.members.length} thành viên\n\n🔑 Mã mời: ${groupData.inviteCode}\n\n📱 Tải ZBudget để quản lý chi tiêu nhóm thông minh và dễ dàng!`;

      await Share.share({
        message: shareMessage,
        title: `🎉 Mời tham gia nhóm ${groupData.name} - ZBudget`,
      });
    } catch (error) {
      Alert.alert('😞 Lỗi', 'Không thể chia sẻ lời mời. Vui lòng thử lại.');
    }
  };

  const handleInviteMembers = () => {
    Alert.alert(
      '👥 Mời thành viên mới',
      `Mã mời nhóm: ${groupData.inviteCode}\n\nChia sẻ mã này với bạn bè để họ tham gia nhóm!`,
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: '📱 Chia sẻ mã',
          onPress: handleShareInvite,
        },
        {
          text: '📧 Gửi email',
          onPress: () => {
            Alert.alert('🚀 Tính năng email', 'Sẽ mở ứng dụng email với nội dung mời sẵn!');
          },
        },
      ]
    );
  };

  const renderOverviewTab = () => {
    const spentPercentage = (groupData.spent / groupData.totalBudget) * 100;
    const remaining = groupData.totalBudget - groupData.spent;

    return (
      <View style={styles.tabContent}>
        {/* Budget Overview */}
        <View style={styles.budgetOverview}>
          <View style={styles.budgetHeader}>
            <Text style={styles.sectionTitle}>Tổng quan ngân sách</Text>
            <View style={styles.budgetAmount}>
              <Text style={styles.budgetTotalAmount}>
                {formatCurrency(groupData.totalBudget)} {groupData.currency}
              </Text>
              <Text style={styles.budgetLabel}>Tổng ngân sách</Text>
            </View>
          </View>

          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View
                style={[styles.progressFill, { width: `${Math.min(spentPercentage, 100)}%` }]}
              />
            </View>
            <View style={styles.progressLabels}>
              <Text style={styles.progressText}>Đã chi: {formatCurrency(groupData.spent)}</Text>
              <Text style={styles.progressText}>Còn lại: {formatCurrency(remaining)}</Text>
            </View>
          </View>
        </View>

        {/* Balance Summary */}
        <View style={styles.balanceSummary}>
          <Text style={styles.sectionTitle}>Số dư thành viên</Text>
          {groupData.members.map(member => (
            <View key={member.id} style={styles.memberBalanceItem}>
              <View style={styles.memberInfo}>
                <Text style={styles.memberAvatar}>{member.avatar}</Text>
                <Text style={styles.memberName}>{member.name}</Text>
              </View>
              <View style={styles.memberBalanceInfo}>
                <Text style={[styles.memberBalance, { color: getBalanceColor(member.balance) }]}>
                  {member.balance >= 0 ? '+' : ''}
                  {formatCurrency(member.balance)}
                </Text>
                <Text style={styles.memberBalanceDescription}>
                  {getBalanceText(member.balance)}
                </Text>
              </View>
            </View>
          ))}
        </View>

        {/* Enhanced Quick Actions */}
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.actionButton} onPress={handleAddExpense}>
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.actionButtonGradient}
            >
              <Ionicons name="add" size={20} color="#FFFFFF" />
              <Text style={styles.actionButtonText}>Thêm chi tiêu</Text>
            </LinearGradient>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton} onPress={handleSettleUp}>
            <View style={styles.actionButtonSecondary}>
              <Ionicons name="git-compare" size={20} color={Colors.primary[500]} />
              <Text style={styles.actionButtonTextSecondary}>Tối ưu thanh toán</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Splitwise-inspired Analytics */}
        <View style={styles.analyticsSection}>
          <Text style={styles.sectionTitle}>Phân tích chi tiêu</Text>

          <View style={styles.analyticsGrid}>
            <View style={styles.analyticsCard}>
              <Text style={styles.analyticsValue}>
                {formatCurrency(groupData.spent / groupData.members.length)}
              </Text>
              <Text style={styles.analyticsLabel}>Chi bình quân/người</Text>
            </View>

            <View style={styles.analyticsCard}>
              <Text style={styles.analyticsValue}>
                {Math.round((groupData.spent / groupData.totalBudget) * 100)}%
              </Text>
              <Text style={styles.analyticsLabel}>Tỉ lệ sử dụng</Text>
            </View>

            <View style={styles.analyticsCard}>
              <Text style={styles.analyticsValue}>{groupData.transactions.length}</Text>
              <Text style={styles.analyticsLabel}>Tổng giao dịch</Text>
            </View>
          </View>

          <TouchableOpacity style={styles.detailedReportButton}>
            <Ionicons name="analytics" size={16} color={Colors.primary[500]} />
            <Text style={styles.detailedReportText}>Xem báo cáo chi tiết</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const renderTransactionsTab = () => {
    return (
      <View style={styles.tabContent}>
        <View style={styles.transactionsList}>
          {groupData.transactions.map(transaction => (
            <View key={transaction.id} style={styles.transactionItem}>
              <View style={styles.transactionLeft}>
                <View style={styles.transactionIcon}>
                  <Text style={styles.transactionIconText}>{transaction.categoryIcon}</Text>
                </View>
                <View style={styles.transactionInfo}>
                  <Text style={styles.transactionDescription}>{transaction.description}</Text>
                  <Text style={styles.transactionMeta}>
                    {transaction.paidByName} thanh toán • {transaction.date} {transaction.time}
                  </Text>
                  <Text style={styles.transactionCategory}>{transaction.category}</Text>
                </View>
              </View>
              <View style={styles.transactionRight}>
                <Text style={styles.transactionAmount}>
                  {formatCurrency(transaction.amount)} {groupData.currency}
                </Text>
                <Text style={styles.transactionSplit}>
                  Chia {transaction.splitBetween.length} người
                </Text>
              </View>
            </View>
          ))}
        </View>
      </View>
    );
  };

  const renderMembersTab = () => {
    return (
      <View style={styles.tabContent}>
        <View style={styles.membersList}>
          {groupData.members.map(member => (
            <View key={member.id} style={styles.memberItem}>
              <View style={styles.memberLeft}>
                <Text style={styles.memberAvatarLarge}>{member.avatar}</Text>
                <View style={styles.memberDetails}>
                  <View style={styles.memberNameRow}>
                    <Text style={styles.memberNameLarge}>{member.name}</Text>
                    {member.isOwner && (
                      <View style={styles.ownerBadge}>
                        <Text style={styles.ownerBadgeText}>ADMIN</Text>
                      </View>
                    )}
                  </View>
                  <Text style={styles.memberJoinDate}>Tham gia {member.joinedAt}</Text>
                  <View style={styles.memberStats}>
                    <Text style={styles.memberStat}>
                      Đã trả: {formatCurrency(member.totalPaid)}
                    </Text>
                    <Text style={styles.memberStat}>
                      Phần của mình: {formatCurrency(member.totalOwed)}
                    </Text>
                  </View>
                </View>
              </View>
              <View style={styles.memberRight}>
                <Text
                  style={[styles.memberBalanceLarge, { color: getBalanceColor(member.balance) }]}
                >
                  {member.balance >= 0 ? '+' : ''}
                  {formatCurrency(member.balance)}
                </Text>
                <Text
                  style={[styles.memberBalanceStatus, { color: getBalanceColor(member.balance) }]}
                >
                  {getBalanceText(member.balance)}
                </Text>
              </View>
            </View>
          ))}
        </View>

        <TouchableOpacity style={styles.inviteButton} onPress={handleInviteMembers}>
          <Ionicons name="person-add" size={20} color={Colors.primary[500]} />
          <Text style={styles.inviteButtonText}>Mời thêm thành viên</Text>
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.primary[500]} />

      {/* Header */}
      <LinearGradient
        colors={[Colors.primary[500], '#2E8B57']}
        style={styles.header}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
      >
        <View style={styles.headerTop}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <Ionicons name="chevron-back" size={24} color="#FFFFFF" />
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setShowSettingsModal(true)}>
            <Ionicons name="ellipsis-vertical" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        <View style={styles.groupInfo}>
          <Text style={styles.groupEmoji}>{groupData.coverImage}</Text>
          <View style={styles.groupDetails}>
            <Text style={styles.groupName}>{groupData.name}</Text>
            <Text style={styles.groupDescription}>{groupData.description}</Text>
            <Text style={styles.groupMemberCount}>{groupData.members.length} thành viên</Text>
          </View>
        </View>
      </LinearGradient>

      {/* Tab Navigation */}
      <View style={styles.tabNavigation}>
        <TouchableOpacity
          style={[styles.tabButton, activeTab === 'overview' && styles.activeTabButton]}
          onPress={() => setActiveTab('overview')}
        >
          <Text
            style={[styles.tabButtonText, activeTab === 'overview' && styles.activeTabButtonText]}
          >
            Tổng quan
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tabButton, activeTab === 'transactions' && styles.activeTabButton]}
          onPress={() => setActiveTab('transactions')}
        >
          <Text
            style={[
              styles.tabButtonText,
              activeTab === 'transactions' && styles.activeTabButtonText,
            ]}
          >
            Giao dịch
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.tabButton, activeTab === 'members' && styles.activeTabButton]}
          onPress={() => setActiveTab('members')}
        >
          <Text
            style={[styles.tabButtonText, activeTab === 'members' && styles.activeTabButtonText]}
          >
            Thành viên
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {activeTab === 'overview' && renderOverviewTab()}
        {activeTab === 'transactions' && renderTransactionsTab()}
        {activeTab === 'members' && renderMembersTab()}

        <View style={styles.bottomSpacing} />
      </ScrollView>

      {/* Settings Modal */}
      <Modal
        visible={showSettingsModal}
        transparent={true}
        animationType="slide"
        onRequestClose={() => setShowSettingsModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Tùy chọn nhóm</Text>
              <TouchableOpacity onPress={() => setShowSettingsModal(false)}>
                <Ionicons name="close" size={24} color="#666666" />
              </TouchableOpacity>
            </View>

            <TouchableOpacity style={styles.modalOption} onPress={handleShareInvite}>
              <Ionicons name="share-outline" size={20} color={Colors.primary[500]} />
              <Text style={styles.modalOptionText}>Chia sẻ mã mời</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalOption} onPress={handleInviteMembers}>
              <Ionicons name="person-add-outline" size={20} color={Colors.primary[500]} />
              <Text style={styles.modalOptionText}>Mời thành viên</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalOption}>
              <Ionicons name="settings-outline" size={20} color="#666666" />
              <Text style={styles.modalOptionText}>Cài đặt nhóm</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalOption} onPress={() => handleExportReport([])}>
              <Ionicons name="download-outline" size={20} color="#666666" />
              <Text style={styles.modalOptionText}>Xuất báo cáo Excel/PDF</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalOption}>
              <Ionicons name="notifications-outline" size={20} color="#666666" />
              <Text style={styles.modalOptionText}>Cài đặt nhắc nhở</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalOption}>
              <Ionicons name="card-outline" size={20} color="#666666" />
              <Text style={styles.modalOptionText}>Kết nối ngân hàng</Text>
            </TouchableOpacity>

            <TouchableOpacity style={[styles.modalOption, styles.modalOptionDanger]}>
              <Ionicons name="exit-outline" size={20} color="#FF6B6B" />
              <Text style={[styles.modalOptionText, styles.modalOptionTextDanger]}>
                Rời khỏi nhóm
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
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
    paddingTop: Platform.OS === 'ios' ? 50 : 30,
    paddingBottom: 24,
    minHeight: Platform.OS === 'ios' ? 200 : 180,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
    paddingTop: Platform.OS === 'android' ? 8 : 0,
  },
  groupInfo: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingBottom: 8,
  },
  groupEmoji: {
    fontSize: 32,
    marginRight: 12,
    marginTop: 2,
  },
  groupDetails: {
    flex: 1,
    paddingRight: 8,
  },
  groupName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 6,
    lineHeight: 24,
  },
  groupDescription: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.85)',
    marginBottom: 6,
    lineHeight: 18,
  },
  groupMemberCount: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  tabNavigation: {
    flexDirection: 'row',
    backgroundColor: '#1A2E3A',
    paddingHorizontal: 0,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  tabButton: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
    borderBottomWidth: 3,
    borderBottomColor: 'transparent',
  },
  activeTabButton: {
    borderBottomColor: Colors.primary[500],
    backgroundColor: 'rgba(61, 161, 61, 0.1)',
  },
  tabButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: 'rgba(255, 255, 255, 0.7)',
  },
  activeTabButtonText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  scrollContainer: {
    flex: 1,
  },
  tabContent: {
    padding: 20,
  },
  budgetOverview: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  budgetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  budgetAmount: {
    alignItems: 'flex-end',
  },
  budgetTotalAmount: {
    fontSize: 20,
    fontWeight: 'bold',
    color: Colors.primary[500],
  },
  budgetLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginTop: 2,
  },
  progressContainer: {
    marginTop: 16,
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 4,
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primary[500],
    borderRadius: 4,
  },
  progressLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  progressText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  balanceSummary: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  memberBalanceItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  memberInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  memberAvatar: {
    fontSize: 20,
    marginRight: 12,
  },
  memberName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  memberBalanceInfo: {
    alignItems: 'flex-end',
  },
  memberBalance: {
    fontSize: 16,
    fontWeight: '600',
  },
  memberBalanceDescription: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginTop: 2,
  },
  quickActions: {
    flexDirection: 'row',
    gap: 12,
  },
  actionButton: {
    flex: 1,
    borderRadius: 12,
    overflow: 'hidden',
  },
  actionButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
  },
  actionButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
  },
  actionButtonSecondary: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  actionButtonTextSecondary: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.primary[500],
    marginLeft: 8,
  },
  transactionsList: {
    gap: 16,
  },
  transactionItem: {
    flexDirection: 'row',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  transactionLeft: {
    flexDirection: 'row',
    flex: 1,
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
  transactionIconText: {
    fontSize: 18,
  },
  transactionInfo: {
    flex: 1,
  },
  transactionDescription: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  transactionMeta: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginBottom: 2,
  },
  transactionCategory: {
    fontSize: 12,
    color: Colors.primary[500],
  },
  transactionRight: {
    alignItems: 'flex-end',
  },
  transactionAmount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  transactionSplit: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginTop: 4,
  },
  membersList: {
    gap: 16,
  },
  memberItem: {
    flexDirection: 'row',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  memberLeft: {
    flexDirection: 'row',
    flex: 1,
  },
  memberAvatarLarge: {
    fontSize: 24,
    marginRight: 16,
  },
  memberDetails: {
    flex: 1,
  },
  memberNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  memberNameLarge: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginRight: 8,
  },
  ownerBadge: {
    backgroundColor: Colors.primary[500],
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  ownerBadgeText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  memberJoinDate: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginBottom: 8,
  },
  memberStats: {
    gap: 2,
  },
  memberStat: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  memberRight: {
    alignItems: 'flex-end',
  },
  memberBalanceLarge: {
    fontSize: 18,
    fontWeight: '600',
  },
  memberBalanceStatus: {
    fontSize: 12,
    marginTop: 4,
  },
  inviteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 12,
    paddingVertical: 16,
    marginTop: 20,
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  inviteButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.primary[500],
    marginLeft: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingTop: 20,
    paddingBottom: 40,
    paddingHorizontal: 20,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333333',
  },
  modalOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
  },
  modalOptionText: {
    fontSize: 16,
    color: '#333333',
    marginLeft: 12,
  },
  modalOptionDanger: {
    borderBottomWidth: 0,
  },
  modalOptionTextDanger: {
    color: '#FF6B6B',
  },
  bottomSpacing: {
    height: 40,
  },
  // Enhanced Analytics Styles
  analyticsSection: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 20,
    marginTop: 20,
  },
  analyticsGrid: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 16,
    marginBottom: 16,
  },
  analyticsCard: {
    flex: 1,
    backgroundColor: '#1A2E3A',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  analyticsValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.primary[500],
    marginBottom: 4,
  },
  analyticsLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
  },
  detailedReportButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 8,
    paddingVertical: 12,
    gap: 8,
  },
  detailedReportText: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
});

export default GroupDetailScreen;
