import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  FlatList,
  StatusBar,
  Dimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { RouteProp } from '@react-navigation/native';
import type { HomeStackParamList, ReportsStackParamList } from '../../types';
import { LinearGradient } from 'expo-linear-gradient';

import { Colors } from '../../constants/colors';
import { Expense } from '../../types';

const { width: screenWidth } = Dimensions.get('window');

type TransactionHistoryRouteProp =
  | RouteProp<HomeStackParamList, 'TransactionHistory'>
  | RouteProp<ReportsStackParamList, 'TransactionHistory'>;

interface Transaction {
  id: string;
  type: 'expense' | 'income';
  amount: number;
  category: string;
  description: string;
  date: Date;
  icon: string;
  color: string;
}

interface FilterOption {
  label: string;
  value: string;
}

const TransactionHistoryScreen: React.FC = () => {
  const navigation = useNavigation();
  const route = useRoute<TransactionHistoryRouteProp>();
  const { period, category, type } = route.params || {};

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState(() => {
    // Set initial filter based on params
    if (type) return type;
    // For period and category, show 'all' so user can see all transactions from that filter
    return 'all';
  });
  const [transactions, setTransactions] = useState<Transaction[]>([]);

  // Mock data - in real app this would come from context/storage
  const mockTransactions: Transaction[] = [
    {
      id: '1',
      type: 'expense',
      amount: 250000,
      category: 'Ăn uống',
      description: 'Cơm trưa tại nhà hàng',
      date: new Date('2024-07-06'),
      icon: '🍜',
      color: '#FF6B6B',
    },
    {
      id: '2',
      type: 'income',
      amount: 5000000,
      category: 'Lương',
      description: 'Lương tháng 7',
      date: new Date('2024-07-05'),
      icon: '💰',
      color: '#4ECDC4',
    },
    {
      id: '3',
      type: 'expense',
      amount: 150000,
      category: 'Di chuyển',
      description: 'Grab về nhà',
      date: new Date('2024-07-05'),
      icon: '🚗',
      color: '#95E1D3',
    },
    {
      id: '4',
      type: 'expense',
      amount: 800000,
      category: 'Mua sắm',
      description: 'Mua quần áo',
      date: new Date('2024-07-04'),
      icon: '🛍️',
      color: '#74B9FF',
    },
    {
      id: '5',
      type: 'expense',
      amount: 50000,
      category: 'Giải trí',
      description: 'Xem phim',
      date: new Date('2024-07-03'),
      icon: '🎬',
      color: '#A29BFE',
    },
    {
      id: '6',
      type: 'income',
      amount: 1000000,
      category: 'Freelance',
      description: 'Dự án thiết kế',
      date: new Date('2024-07-02'),
      icon: '💼',
      color: '#FFEAA7',
    },
  ];

  const filterOptions: FilterOption[] = [
    { label: 'Tất cả', value: 'all' },
    { label: 'Chi tiêu', value: 'expense' },
    { label: 'Thu nhập', value: 'income' },
    { label: 'Hôm nay', value: 'today' },
    { label: 'Tuần này', value: 'week' },
    { label: 'Tháng này', value: 'month' },
  ];

  useEffect(() => {
    setTransactions(mockTransactions);
  }, []);

  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (date: Date): string => {
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Hôm nay';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Hôm qua';
    } else {
      return date.toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      });
    }
  };

  const filterTransactions = (): Transaction[] => {
    let filtered = transactions;

    // Filter by period from params (if specified)
    if (period) {
      // Extract month and year from period (e.g., "T7/2025")
      const [monthStr, yearStr] = period.split('/');
      const month = parseInt(monthStr.replace('T', '')) - 1; // Convert to 0-based month
      const year = parseInt(yearStr);

      filtered = filtered.filter(transaction => {
        const transactionDate = transaction.date;
        return transactionDate.getMonth() === month && transactionDate.getFullYear() === year;
      });
    }

    // Filter by category from params (highest priority)
    if (category) {
      filtered = filtered.filter(transaction => transaction.category === category);
    }

    // Filter by type from params
    if (type) {
      filtered = filtered.filter(transaction => transaction.type === type);
    }

    // Filter by search query
    if (searchQuery) {
      filtered = filtered.filter(
        transaction =>
          transaction.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
          transaction.category.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    // Filter by additional selected filters (only if no param filters are active)
    if (selectedFilter !== 'all' && !period && !category && !type) {
      const today = new Date();
      const startOfWeek = new Date(today.setDate(today.getDate() - today.getDay()));
      const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

      filtered = filtered.filter(transaction => {
        switch (selectedFilter) {
          case 'expense':
            return transaction.type === 'expense';
          case 'income':
            return transaction.type === 'income';
          case 'today':
            return transaction.date.toDateString() === new Date().toDateString();
          case 'week':
            return transaction.date >= startOfWeek;
          case 'month':
            return transaction.date >= startOfMonth;
          default:
            return true;
        }
      });
    }

    return filtered.sort((a, b) => b.date.getTime() - a.date.getTime());
  };

  const renderTransactionItem = ({ item }: { item: Transaction }) => (
    <TouchableOpacity style={styles.transactionItem}>
      <View style={styles.transactionContent}>
        <View style={[styles.transactionIcon, { backgroundColor: item.color + '20' }]}>
          <Text style={styles.iconText}>{item.icon}</Text>
        </View>

        <View style={styles.transactionDetails}>
          <Text style={styles.transactionCategory}>{item.category}</Text>
          <Text style={styles.transactionDescription}>{item.description}</Text>
          <Text style={styles.transactionDate}>{formatDate(item.date)}</Text>
        </View>

        <View style={styles.transactionAmount}>
          <Text
            style={[styles.amountText, { color: item.type === 'income' ? '#4ECDC4' : '#FF6B6B' }]}
          >
            {item.type === 'income' ? '+' : '-'}
            {formatCurrency(item.amount)}
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );

  const renderFilterChip = (option: FilterOption) => (
    <TouchableOpacity
      key={option.value}
      style={[styles.filterChip, selectedFilter === option.value && styles.filterChipActive]}
      onPress={() => setSelectedFilter(option.value)}
    >
      <Text
        style={[
          styles.filterChipText,
          selectedFilter === option.value && styles.filterChipTextActive,
        ]}
      >
        {option.label}
      </Text>
    </TouchableOpacity>
  );

  const filteredTransactions = filterTransactions();
  const totalIncome = filteredTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  const totalExpenses = filteredTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />

      {/* Header */}
      <LinearGradient colors={['#1A2E3A', '#2A4A5A']} style={styles.header}>
        <View style={styles.headerContent}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <Ionicons name="arrow-back" size={24} color="#FFFFFF" />
          </TouchableOpacity>

          <Text style={styles.headerTitle}>
            {category
              ? `${category}`
              : period
                ? `Tháng ${period}`
                : type
                  ? type === 'expense'
                    ? 'Chi tiêu'
                    : 'Thu nhập'
                  : 'Lịch sử giao dịch'}
          </Text>

          <TouchableOpacity style={styles.exportButton}>
            <Ionicons name="download-outline" size={20} color="#3DA13D" />
          </TouchableOpacity>
        </View>

        {/* Summary Cards */}
        <View style={styles.summaryContainer}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Thu nhập</Text>
            <Text style={styles.summaryIncome}>+{formatCurrency(totalIncome)}</Text>
          </View>

          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Chi tiêu</Text>
            <Text style={styles.summaryExpense}>-{formatCurrency(totalExpenses)}</Text>
          </View>
        </View>
      </LinearGradient>

      {/* Search and Filters */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Ionicons name="search" size={20} color="rgba(255, 255, 255, 0.6)" />
          <TextInput
            style={styles.searchInput}
            placeholder="Tìm kiếm giao dịch..."
            placeholderTextColor="rgba(255, 255, 255, 0.6)"
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={20} color="rgba(255, 255, 255, 0.6)" />
            </TouchableOpacity>
          )}
        </View>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.filtersContainer}
          contentContainerStyle={styles.filtersContent}
        >
          {filterOptions.map(renderFilterChip)}
        </ScrollView>
      </View>

      {/* Transactions List */}
      <FlatList
        data={filteredTransactions}
        renderItem={renderTransactionItem}
        keyExtractor={item => item.id}
        style={styles.transactionsList}
        contentContainerStyle={styles.transactionsContent}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📋</Text>
            <Text style={styles.emptyTitle}>Không có giao dịch nào</Text>
            <Text style={styles.emptyDescription}>
              {searchQuery || selectedFilter !== 'all'
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Bắt đầu thêm giao dịch đầu tiên của bạn'}
            </Text>
          </View>
        }
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
    paddingTop: 50,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  exportButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  summaryContainer: {
    flexDirection: 'row',
    gap: 12,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  summaryLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: 4,
  },
  summaryIncome: {
    fontSize: 16,
    fontWeight: '700',
    color: '#4ECDC4',
  },
  summaryExpense: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FF6B6B',
  },
  searchContainer: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#2A4A5A',
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  searchInput: {
    flex: 1,
    marginLeft: 12,
    fontSize: 16,
    color: '#FFFFFF',
  },
  filtersContainer: {
    flexGrow: 0,
  },
  filtersContent: {
    gap: 8,
  },
  filterChip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  filterChipActive: {
    backgroundColor: '#3DA13D',
    borderColor: '#3DA13D',
  },
  filterChipText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '500',
  },
  filterChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  transactionsList: {
    flex: 1,
  },
  transactionsContent: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  transactionItem: {
    marginBottom: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.02)',
    borderRadius: 12,
    padding: 16,
  },
  transactionContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  transactionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  iconText: {
    fontSize: 20,
  },
  transactionDetails: {
    flex: 1,
  },
  transactionCategory: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  transactionDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 2,
  },
  transactionDate: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  transactionAmount: {
    alignItems: 'flex-end',
  },
  amountText: {
    fontSize: 16,
    fontWeight: '700',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.6)',
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 32,
  },
});

export default TransactionHistoryScreen;
