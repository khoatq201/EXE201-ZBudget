import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  Modal,
  FlatList,
  Animated,
  Vibration,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useNavigation } from '@react-navigation/native';

import { Colors } from '../../constants/colors';
import { Spacing, Layout } from '../../constants/spacing';
import { Typography } from '../../constants/typography';
import { VietnameseText } from '../../constants/vietnamese';
import { ExpenseCategory, PaymentMethod } from '../../types';
import { BackButton } from '../../components';
import { useApp } from '../../context/AppContext';

// Enhanced Vietnamese Payment Methods
const VIETNAMESE_PAYMENT_METHODS = [
  { id: 'momo', name: 'MoMo', icon: '🎯', color: '#D82D8B' },
  { id: 'zalopay', name: 'ZaloPay', icon: '💙', color: '#0068FF' },
  { id: 'cash', name: 'Tiền mặt', icon: '💰', color: '#4CAF50' },
  { id: 'banking', name: 'Chuyển khoản', icon: '🏦', color: '#FF9800' },
  { id: 'card', name: 'Thẻ', icon: '💳', color: '#9C27B0' },
  { id: 'viettelpay', name: 'ViettelPay', icon: '📱', color: '#FF5722' },
];

interface CategoryOption {
  id: string;
  category: ExpenseCategory;
  name: string;
  icon: string;
  color: string;
}

const categoryOptions: CategoryOption[] = [
  {
    id: '1',
    category: ExpenseCategory.FOOD,
    name: VietnameseText.categories.food,
    icon: '🍜',
    color: Colors.primary[500],
  },
  {
    id: '2',
    category: ExpenseCategory.TRANSPORT,
    name: VietnameseText.categories.transport,
    icon: '🚗',
    color: Colors.secondary[500],
  },
  {
    id: '3',
    category: ExpenseCategory.SHOPPING,
    name: VietnameseText.categories.shopping,
    icon: '🛍️',
    color: Colors.accent[500],
  },
  {
    id: '4',
    category: ExpenseCategory.ENTERTAINMENT,
    name: VietnameseText.categories.entertainment,
    icon: '🎬',
    color: Colors.primary[600],
  },
  {
    id: '5',
    category: ExpenseCategory.HEALTHCARE,
    name: VietnameseText.categories.healthcare,
    icon: '🏥',
    color: Colors.error,
  },
  {
    id: '6',
    category: ExpenseCategory.EDUCATION,
    name: VietnameseText.categories.education,
    icon: '📚',
    color: Colors.secondary[600],
  },
  {
    id: '7',
    category: ExpenseCategory.UTILITIES,
    name: VietnameseText.categories.utilities,
    icon: '💡',
    color: Colors.warning,
  },
  {
    id: '8',
    category: ExpenseCategory.OTHER,
    name: VietnameseText.categories.other,
    icon: '💰',
    color: Colors.text.secondary,
  },
];

const AddExpenseScreen: React.FC = () => {
  const navigation = useNavigation();
  const { dataActions } = useApp();
  const [activeTab, setActiveTab] = useState<'manual' | 'receipt'>('manual');
  const [amount, setAmount] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<CategoryOption | null>(null);
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(new Date());
  const [time, setTime] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Enhanced Vietnamese features
  const [isVoiceRecording, setIsVoiceRecording] = useState(false);
  const [showQuickAmounts, setShowQuickAmounts] = useState(false);
  const [showSmartSuggestions, setShowSmartSuggestions] = useState(false);
  const [recentLocations, setRecentLocations] = useState<string[]>([]);
  const [suggestedDescription, setSuggestedDescription] = useState('');
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState(VIETNAMESE_PAYMENT_METHODS[0]);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [recurringType, setRecurringType] = useState<'none' | 'daily' | 'weekly' | 'monthly'>(
    'none'
  );

  const voiceAnimation = useRef(new Animated.Value(1)).current;
  const suggestionsAnimation = useRef(new Animated.Value(0)).current;

  // Enhanced Vietnamese smart amounts based on research
  const smartQuickAmounts = [
    // Morning (6-10 AM)
    {
      amount: '15000',
      label: 'Cà phê',
      icon: '☕',
      category: ExpenseCategory.FOOD,
      time: 'morning',
    },
    {
      amount: '20000',
      label: 'Bánh mì',
      icon: '🥖',
      category: ExpenseCategory.FOOD,
      time: 'morning',
    },
    {
      amount: '7000',
      label: 'Xe bus',
      icon: '🚌',
      category: ExpenseCategory.TRANSPORT,
      time: 'morning',
    },

    // Lunch (11-14 PM)
    {
      amount: '25000',
      label: 'Cơm căng tin',
      icon: '🍽️',
      category: ExpenseCategory.FOOD,
      time: 'lunch',
    },
    {
      amount: '35000',
      label: 'Cơm quán',
      icon: '🍚',
      category: ExpenseCategory.FOOD,
      time: 'lunch',
    },
    { amount: '45000', label: 'Phở', icon: '🍜', category: ExpenseCategory.FOOD, time: 'lunch' },

    // Afternoon (14-18 PM)
    {
      amount: '18000',
      label: 'Trà sữa',
      icon: '🧋',
      category: ExpenseCategory.FOOD,
      time: 'afternoon',
    },
    {
      amount: '50000',
      label: 'Photo sách',
      icon: '📚',
      category: ExpenseCategory.EDUCATION,
      time: 'afternoon',
    },

    // Evening (18-22 PM)
    {
      amount: '40000',
      label: 'Cơm tối',
      icon: '🍛',
      category: ExpenseCategory.FOOD,
      time: 'evening',
    },
    {
      amount: '25000',
      label: 'Grab/Bike',
      icon: '🛵',
      category: ExpenseCategory.TRANSPORT,
      time: 'evening',
    },

    // Common amounts
    {
      amount: '100000',
      label: 'Mua sắm',
      icon: '🛍️',
      category: ExpenseCategory.SHOPPING,
      time: 'all',
    },
    {
      amount: '200000',
      label: 'Học phí',
      icon: '🎓',
      category: ExpenseCategory.EDUCATION,
      time: 'all',
    },
  ];

  // Enhanced Vietnamese merchants with AI categorization
  const vietnameseMerchants = [
    // Food & Beverages
    { name: 'Highlands Coffee', category: ExpenseCategory.FOOD, icon: '☕', confidence: 0.95 },
    { name: 'Phở 24', category: ExpenseCategory.FOOD, icon: '🍜', confidence: 0.98 },
    { name: 'Lotteria', category: ExpenseCategory.FOOD, icon: '🍔', confidence: 0.95 },
    { name: 'KFC', category: ExpenseCategory.FOOD, icon: '🍗', confidence: 0.95 },
    { name: 'Căng tin trường', category: ExpenseCategory.FOOD, icon: '🍽️', confidence: 0.9 },
    { name: 'Cơm tấm', category: ExpenseCategory.FOOD, icon: '🍚', confidence: 0.88 },
    { name: 'Bánh mì', category: ExpenseCategory.FOOD, icon: '🥖', confidence: 0.85 },
    { name: 'Trà sữa', category: ExpenseCategory.FOOD, icon: '🧋', confidence: 0.85 },

    // Shopping
    { name: 'Big C', category: ExpenseCategory.SHOPPING, icon: '🛒', confidence: 0.92 },
    { name: 'Coopmart', category: ExpenseCategory.SHOPPING, icon: '🛒', confidence: 0.9 },
    { name: 'Circle K', category: ExpenseCategory.SHOPPING, icon: '🏪', confidence: 0.88 },
    { name: 'Vinmart', category: ExpenseCategory.SHOPPING, icon: '🛒', confidence: 0.9 },
    { name: 'Chợ', category: ExpenseCategory.SHOPPING, icon: '🏪', confidence: 0.8 },

    // Transportation
    { name: 'Grab', category: ExpenseCategory.TRANSPORT, icon: '🚗', confidence: 0.97 },
    { name: 'Xe bus', category: ExpenseCategory.TRANSPORT, icon: '🚌', confidence: 0.95 },
    { name: 'Xe ôm', category: ExpenseCategory.TRANSPORT, icon: '🛵', confidence: 0.9 },
    { name: 'Taxi', category: ExpenseCategory.TRANSPORT, icon: '🚕', confidence: 0.9 },
    { name: 'Xăng', category: ExpenseCategory.TRANSPORT, icon: '⛽', confidence: 0.95 },

    // Education
    { name: 'Nhà sách', category: ExpenseCategory.EDUCATION, icon: '📚', confidence: 0.9 },
    { name: 'Photo', category: ExpenseCategory.EDUCATION, icon: '📄', confidence: 0.85 },
    { name: 'Học phí', category: ExpenseCategory.EDUCATION, icon: '🎓', confidence: 0.95 },
    { name: 'Khóa học', category: ExpenseCategory.EDUCATION, icon: '💻', confidence: 0.9 },

    // Healthcare
    { name: 'Nhà thuốc', category: ExpenseCategory.HEALTHCARE, icon: '💊', confidence: 0.93 },
    { name: 'Bệnh viện', category: ExpenseCategory.HEALTHCARE, icon: '🏥', confidence: 0.95 },
    { name: 'Phòng khám', category: ExpenseCategory.HEALTHCARE, icon: '👩‍⚕️', confidence: 0.9 },
  ];

  // Enhanced intelligent suggestions based on time and Vietnamese patterns
  const getSmartSuggestions = () => {
    const hour = new Date().getHours();
    const day = new Date().getDay(); // 0 = Sunday, 1 = Monday, etc.

    // Morning suggestions (6-10 AM)
    if (hour >= 6 && hour <= 10) {
      return [
        { description: 'Cà phê sáng', category: ExpenseCategory.FOOD, amount: '15000', icon: '☕' },
        { description: 'Bánh mì', category: ExpenseCategory.FOOD, amount: '20000', icon: '🥖' },
        { description: 'Xe bus', category: ExpenseCategory.TRANSPORT, amount: '7000', icon: '🚌' },
      ];
    }
    // Lunch time (11-14 PM)
    else if (hour >= 11 && hour <= 14) {
      return [
        {
          description: 'Cơm căng tin',
          category: ExpenseCategory.FOOD,
          amount: '25000',
          icon: '🍽️',
        },
        { description: 'Phở', category: ExpenseCategory.FOOD, amount: '45000', icon: '🍜' },
        { description: 'Cơm quán', category: ExpenseCategory.FOOD, amount: '35000', icon: '🍚' },
      ];
    }
    // Afternoon (14-18 PM)
    else if (hour >= 14 && hour <= 18) {
      return [
        { description: 'Trà sữa', category: ExpenseCategory.FOOD, amount: '18000', icon: '🧋' },
        {
          description: 'Photo tài liệu',
          category: ExpenseCategory.EDUCATION,
          amount: '50000',
          icon: '📚',
        },
        {
          description: 'Grab về nhà',
          category: ExpenseCategory.TRANSPORT,
          amount: '25000',
          icon: '🛵',
        },
      ];
    }
    // Evening (18-22 PM)
    else if (hour >= 18 && hour <= 22) {
      return [
        { description: 'Cơm tối', category: ExpenseCategory.FOOD, amount: '40000', icon: '🍛' },
        { description: 'Đi chợ', category: ExpenseCategory.SHOPPING, amount: '100000', icon: '🛒' },
        {
          description: 'Xe về nhà',
          category: ExpenseCategory.TRANSPORT,
          amount: '15000',
          icon: '🚌',
        },
      ];
    }

    // Weekend specific suggestions
    if (day === 0 || day === 6) {
      return [
        {
          description: 'Đi chơi',
          category: ExpenseCategory.ENTERTAINMENT,
          amount: '200000',
          icon: '🎬',
        },
        {
          description: 'Ăn uống cuối tuần',
          category: ExpenseCategory.FOOD,
          amount: '150000',
          icon: '🍽️',
        },
        {
          description: 'Mua sắm',
          category: ExpenseCategory.SHOPPING,
          amount: '300000',
          icon: '🛍️',
        },
      ];
    }

    // Default suggestions
    return [
      {
        description: 'Chi tiêu khác',
        category: ExpenseCategory.OTHER,
        amount: '50000',
        icon: '💰',
      },
      { description: 'Ăn uống', category: ExpenseCategory.FOOD, amount: '30000', icon: '🍽️' },
      {
        description: 'Di chuyển',
        category: ExpenseCategory.TRANSPORT,
        amount: '20000',
        icon: '🚗',
      },
    ];
  };

  // Get time-specific quick amounts
  const getTimeBasedQuickAmounts = () => {
    const hour = new Date().getHours();

    if (hour >= 6 && hour <= 10) {
      return smartQuickAmounts.filter(item => item.time === 'morning' || item.time === 'all');
    } else if (hour >= 11 && hour <= 14) {
      return smartQuickAmounts.filter(item => item.time === 'lunch' || item.time === 'all');
    } else if (hour >= 14 && hour <= 18) {
      return smartQuickAmounts.filter(item => item.time === 'afternoon' || item.time === 'all');
    } else if (hour >= 18 && hour <= 22) {
      return smartQuickAmounts.filter(item => item.time === 'evening' || item.time === 'all');
    }

    return smartQuickAmounts.filter(item => item.time === 'all');
  };

  // Smart payment method suggestion based on amount
  const suggestPaymentMethod = (amount: number) => {
    if (amount <= 50000) return VIETNAMESE_PAYMENT_METHODS.find(p => p.id === 'cash');
    if (amount <= 200000) return VIETNAMESE_PAYMENT_METHODS.find(p => p.id === 'momo');
    return VIETNAMESE_PAYMENT_METHODS.find(p => p.id === 'banking');
  };

  const formatCurrencyDisplay = (value: string) => {
    const numericValue = value.replace(/[^0-9]/g, '');
    if (!numericValue) return '';

    const formatted = new Intl.NumberFormat('vi-VN').format(parseInt(numericValue));
    return formatted;
  };

  const handleAmountChange = (text: string) => {
    const numericValue = text.replace(/[^0-9]/g, '');
    setAmount(numericValue);

    // Auto-suggest payment method based on amount
    if (numericValue) {
      const suggestedMethod = suggestPaymentMethod(parseInt(numericValue));
      if (suggestedMethod) {
        setSelectedPaymentMethod(suggestedMethod);
      }
    }

    // Show smart suggestions when amount is entered
    if (numericValue && !showSmartSuggestions) {
      setShowSmartSuggestions(true);
      Animated.timing(suggestionsAnimation, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }).start();
    }
  };

  const handleVoiceInput = () => {
    if (isVoiceRecording) {
      // Stop recording
      setIsVoiceRecording(false);
      Animated.timing(voiceAnimation, {
        toValue: 1,
        duration: 200,
        useNativeDriver: true,
      }).start();

      // Simulate voice recognition result
      setTimeout(() => {
        Alert.alert(
          'Nhận diện giọng nói',
          'Đã nghe được: "Cà phê 25 nghìn đồng tại Highlands Coffee"',
          [
            { text: 'Hủy', style: 'cancel' },
            {
              text: 'Áp dụng',
              onPress: () => {
                setAmount('25000');
                setDescription('Cà phê tại Highlands Coffee');
                const coffeeCategory = categoryOptions.find(
                  cat => cat.category === ExpenseCategory.FOOD
                );
                if (coffeeCategory) setSelectedCategory(coffeeCategory);
              },
            },
          ]
        );
      }, 1500);
    } else {
      // Start recording
      setIsVoiceRecording(true);
      Vibration.vibrate(50);

      Animated.loop(
        Animated.sequence([
          Animated.timing(voiceAnimation, {
            toValue: 1.2,
            duration: 500,
            useNativeDriver: true,
          }),
          Animated.timing(voiceAnimation, {
            toValue: 0.8,
            duration: 500,
            useNativeDriver: true,
          }),
        ])
      ).start();
    }
  };

  const handleQuickAmount = (quickAmount: any) => {
    setAmount(quickAmount.amount);
    setDescription(quickAmount.label);

    // Auto-select category based on quick amount
    const suggestedCategory = categoryOptions.find(cat => cat.category === quickAmount.category);
    if (suggestedCategory) {
      setSelectedCategory(suggestedCategory);
    }

    // Auto-suggest payment method
    const suggestedMethod = suggestPaymentMethod(parseInt(quickAmount.amount));
    if (suggestedMethod) {
      setSelectedPaymentMethod(suggestedMethod);
    }
  };

  const handleSmartSuggestion = (suggestion: any) => {
    setAmount(suggestion.amount);
    setDescription(suggestion.description);

    const suggestedCategory = categoryOptions.find(cat => cat.category === suggestion.category);
    if (suggestedCategory) {
      setSelectedCategory(suggestedCategory);
    }

    // Auto-suggest payment method
    const suggestedMethod = suggestPaymentMethod(parseInt(suggestion.amount));
    if (suggestedMethod) {
      setSelectedPaymentMethod(suggestedMethod);
    }
  };

  const handleMerchantSuggestion = (merchant: any) => {
    setDescription(merchant.name);
    const suggestedCategory = categoryOptions.find(cat => cat.category === merchant.category);
    if (suggestedCategory && !selectedCategory) {
      setSelectedCategory(suggestedCategory);
    }
  };

  const handleSaveExpense = async () => {
    if (!amount || !selectedCategory) {
      Alert.alert('Lỗi', 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setIsLoading(true);
    try {
      const numericAmount = parseInt(amount.replace(/[^0-9]/g, ''));

      const expense = {
        amount: numericAmount,
        category: selectedCategory.category,
        description: description || selectedCategory.name,
        date: date,
        paymentMethod: PaymentMethod.CASH,
        currency: 'VND',
        location: '',
      };

      await dataActions.addExpense(expense);

      Alert.alert(
        'Thành công',
        `Chi tiêu ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(numericAmount)} đã được lưu!`,
        [{ text: 'OK', onPress: () => navigation.goBack() }]
      );
    } catch (error) {
      console.error('Error saving expense:', error);
      Alert.alert('Lỗi', 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  const renderCategoryItem = ({ item }: { item: CategoryOption }) => (
    <TouchableOpacity
      style={styles.categoryItem}
      onPress={() => {
        setSelectedCategory(item);
        setShowCategoryModal(false);
      }}
    >
      <View style={[styles.categoryIcon, { backgroundColor: item.color }]}>
        <Text style={styles.categoryEmoji}>{item.icon}</Text>
      </View>
      <Text style={styles.categoryName}>{item.name}</Text>
      {selectedCategory?.id === item.id && (
        <Ionicons name="checkmark-circle" size={24} color={Colors.success} />
      )}
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <BackButton title="Thêm chi tiêu" />
      {/* Tab Header */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'manual' && styles.activeTab]}
          onPress={() => setActiveTab('manual')}
        >
          <Text style={[styles.tabText, activeTab === 'manual' && styles.activeTabText]}>
            Nhập tay
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'receipt' && styles.activeTab]}
          onPress={() => setActiveTab('receipt')}
        >
          <Text style={[styles.tabText, activeTab === 'receipt' && styles.activeTabText]}>
            Quét hoá đơn
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {activeTab === 'manual' ? (
          <>
            {/* Smart AI Suggestions Card */}
            <View style={styles.suggestionCard}>
              <View style={styles.suggestionHeader}>
                <Text style={styles.suggestionIcon}>🤖</Text>
                <Text style={styles.suggestionTitle}>Gợi ý thông minh</Text>
                <Text style={styles.suggestionSubtitle}>Dựa trên thời gian và thói quen</Text>
              </View>
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                style={styles.suggestionsScroll}
              >
                {getSmartSuggestions().map((suggestion, index) => (
                  <TouchableOpacity
                    key={index}
                    style={styles.smartSuggestionChip}
                    onPress={() => handleSmartSuggestion(suggestion)}
                  >
                    <Text style={styles.suggestionChipIcon}>{suggestion.icon}</Text>
                    <Text style={styles.suggestionChipLabel}>{suggestion.description}</Text>
                    <Text style={styles.suggestionChipAmount}>
                      {formatCurrencyDisplay(suggestion.amount)}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            <View style={styles.amountSection}>
              <View style={styles.amountHeader}>
                <Text style={styles.amountLabel}>Số tiền</Text>
                <TouchableOpacity style={styles.voiceButton} onPress={handleVoiceInput}>
                  <Animated.View
                    style={[styles.voiceButtonInner, { transform: [{ scale: voiceAnimation }] }]}
                  >
                    <Ionicons
                      name={isVoiceRecording ? 'stop' : 'mic'}
                      size={20}
                      color={isVoiceRecording ? '#FF6B6B' : Colors.primary[500]}
                    />
                  </Animated.View>
                  <Text style={styles.voiceButtonText}>{isVoiceRecording ? 'Dừng' : 'Nói'}</Text>
                </TouchableOpacity>
              </View>

              <View style={styles.amountInputContainer}>
                <TextInput
                  style={styles.amountInput}
                  placeholder="0"
                  placeholderTextColor="rgba(255, 255, 255, 0.4)"
                  value={formatCurrencyDisplay(amount)}
                  onChangeText={handleAmountChange}
                  keyboardType="numeric"
                />
                <Text style={styles.currencyText}>VND</Text>
              </View>

              {/* Time-Based Quick Amount Chips */}
              <View style={styles.quickAmountsContainer}>
                <Text style={styles.quickAmountsLabel}>Số tiền phù hợp thời gian hiện tại</Text>
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  style={styles.quickAmountsScroll}
                >
                  {getTimeBasedQuickAmounts().map((item, index) => (
                    <TouchableOpacity
                      key={index}
                      style={styles.quickAmountChip}
                      onPress={() => handleQuickAmount(item)}
                    >
                      <Text style={styles.quickAmountIcon}>{item.icon}</Text>
                      <Text style={styles.quickAmountLabel}>{item.label}</Text>
                      <Text style={styles.quickAmountValue}>
                        {formatCurrencyDisplay(item.amount)}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            </View>

            <View style={styles.formSection}>
              <TouchableOpacity
                style={styles.inputContainer}
                onPress={() => setShowCategoryModal(true)}
              >
                <View style={styles.inputIcon}>
                  <Ionicons name="grid-outline" size={20} color={Colors.text.secondary} />
                </View>
                <View style={styles.inputContent}>
                  <Text style={styles.inputLabel}>Danh mục</Text>
                  <Text style={[styles.inputValue, !selectedCategory && styles.placeholder]}>
                    {selectedCategory ? selectedCategory.name : 'Chọn danh mục...'}
                  </Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color={Colors.text.secondary} />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.inputContainer}
                onPress={() => setShowPaymentModal(true)}
              >
                <View
                  style={[
                    styles.inputIcon,
                    { backgroundColor: selectedPaymentMethod.color + '20' },
                  ]}
                >
                  <Text style={styles.paymentMethodIcon}>{selectedPaymentMethod.icon}</Text>
                </View>
                <View style={styles.inputContent}>
                  <Text style={styles.inputLabel}>Phương thức thanh toán</Text>
                  <Text style={styles.inputValue}>{selectedPaymentMethod.name}</Text>
                  {amount && (
                    <Text style={styles.paymentSuggestion}>
                      Gợi ý cho {formatCurrencyDisplay(amount)} VND
                    </Text>
                  )}
                </View>
                <Ionicons name="chevron-forward" size={20} color={Colors.text.secondary} />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.inputContainer}
                onPress={() => setShowDatePicker(true)}
              >
                <View style={styles.inputIcon}>
                  <Ionicons name="calendar-outline" size={20} color={Colors.text.secondary} />
                </View>
                <View style={styles.inputContent}>
                  <Text style={styles.inputLabel}>Ngày</Text>
                  <Text style={styles.inputValue}>{date.toLocaleDateString('vi-VN')}</Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color={Colors.text.secondary} />
              </TouchableOpacity>

              <View style={styles.inputContainer}>
                <View style={styles.inputIcon}>
                  <Ionicons name="document-text-outline" size={20} color={Colors.text.secondary} />
                </View>
                <View style={styles.inputContent}>
                  <Text style={styles.inputLabel}>Ghi chú (tùy chọn)</Text>
                  <TextInput
                    style={styles.textInput}
                    placeholder={suggestedDescription || 'Thêm ghi chú về khoản chi này...'}
                    placeholderTextColor="rgba(255, 255, 255, 0.5)"
                    value={description}
                    onChangeText={setDescription}
                    multiline
                    numberOfLines={2}
                  />

                  {/* AI-Enhanced Vietnamese Merchant Suggestions */}
                  {description.length > 0 && (
                    <View style={styles.merchantSuggestions}>
                      <Text style={styles.merchantSuggestionsTitle}>Gợi ý địa điểm thông minh</Text>
                      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                        {vietnameseMerchants
                          .filter(
                            merchant =>
                              merchant.name.toLowerCase().includes(description.toLowerCase()) ||
                              description
                                .toLowerCase()
                                .includes(merchant.name.toLowerCase().substring(0, 3))
                          )
                          .sort((a, b) => b.confidence - a.confidence)
                          .slice(0, 6)
                          .map((merchant, index) => (
                            <TouchableOpacity
                              key={index}
                              style={[
                                styles.merchantChip,
                                {
                                  borderColor:
                                    merchant.confidence > 0.9
                                      ? '#4CAF50'
                                      : 'rgba(61, 161, 61, 0.3)',
                                },
                              ]}
                              onPress={() => handleMerchantSuggestion(merchant)}
                            >
                              <Text style={styles.merchantIcon}>{merchant.icon}</Text>
                              <Text style={styles.merchantName}>{merchant.name}</Text>
                              <Text style={styles.merchantConfidence}>
                                {Math.round(merchant.confidence * 100)}%
                              </Text>
                            </TouchableOpacity>
                          ))}
                      </ScrollView>
                    </View>
                  )}
                </View>
              </View>
            </View>
          </>
        ) : (
          <View style={styles.receiptSection}>
            <View style={styles.receiptUploadArea}>
              <Ionicons name="camera-outline" size={48} color={Colors.primary[500]} />
              <Text style={styles.receiptTitle}>Chụp hoá đơn</Text>
              <Text style={styles.receiptDescription}>
                Chụp ảnh hoá đơn để tự động nhận diện thông tin chi tiêu
              </Text>
              <TouchableOpacity style={styles.cameraButton}>
                <Text style={styles.cameraButtonText}>📷 Chụp ảnh</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.galleryButton}>
                <Text style={styles.galleryButtonText}>🖼️ Chọn từ thư viện</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        <TouchableOpacity
          style={styles.saveButton}
          onPress={handleSaveExpense}
          disabled={isLoading}
        >
          <LinearGradient
            colors={Colors.gradients.primary}
            style={styles.saveButtonGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          >
            <Text style={styles.saveButtonText}>{isLoading ? 'Đang lưu...' : 'Lưu chi tiêu'}</Text>
          </LinearGradient>
        </TouchableOpacity>
      </ScrollView>

      {/* Payment Method Selection Modal */}
      <Modal visible={showPaymentModal} animationType="slide" presentationStyle="pageSheet">
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Chọn phương thức thanh toán</Text>
            <TouchableOpacity onPress={() => setShowPaymentModal(false)}>
              <Ionicons name="close" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          <ScrollView showsVerticalScrollIndicator={false}>
            {VIETNAMESE_PAYMENT_METHODS.map((method, index) => (
              <TouchableOpacity
                key={index}
                style={styles.paymentMethodItem}
                onPress={() => {
                  setSelectedPaymentMethod(method);
                  setShowPaymentModal(false);
                }}
              >
                <View
                  style={[
                    styles.paymentMethodIconContainer,
                    { backgroundColor: method.color + '20' },
                  ]}
                >
                  <Text style={styles.paymentMethodItemIcon}>{method.icon}</Text>
                </View>
                <Text style={styles.paymentMethodName}>{method.name}</Text>
                {selectedPaymentMethod.id === method.id && (
                  <Ionicons name="checkmark-circle" size={24} color={Colors.success} />
                )}
              </TouchableOpacity>
            ))}
            <View style={styles.paymentMethodTips}>
              <Text style={styles.paymentMethodTipsTitle}>💡 Gợi ý thanh toán</Text>
              <Text style={styles.paymentMethodTip}>• Dưới 50K: Nên dùng tiền mặt</Text>
              <Text style={styles.paymentMethodTip}>• 50K - 200K: MoMo, ZaloPay tiện lợi</Text>
              <Text style={styles.paymentMethodTip}>• Trên 200K: Chuyển khoản an toàn</Text>
            </View>
          </ScrollView>
        </View>
      </Modal>

      {/* Category Selection Modal */}
      <Modal visible={showCategoryModal} animationType="slide" presentationStyle="pageSheet">
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Chọn danh mục</Text>
            <TouchableOpacity onPress={() => setShowCategoryModal(false)}>
              <Ionicons name="close" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          <FlatList
            data={categoryOptions}
            renderItem={renderCategoryItem}
            keyExtractor={item => item.id}
            showsVerticalScrollIndicator={false}
          />
        </View>
      </Modal>

      {/* Date Picker */}
      {showDatePicker && (
        <DateTimePicker
          value={date}
          mode="date"
          display="default"
          onChange={(event, selectedDate) => {
            setShowDatePicker(false);
            if (selectedDate) {
              setDate(selectedDate);
            }
          }}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#1A2E3A',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 16,
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  activeTab: {
    borderBottomColor: Colors.primary[500],
  },
  tabText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.6)',
    fontWeight: '500',
  },
  activeTabText: {
    color: Colors.primary[500],
    fontWeight: '600',
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  amountSection: {
    padding: Spacing['2xl'],
    alignItems: 'center',
  },
  amountLabel: {
    ...Typography.styles.body,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: Spacing.md,
  },
  amountInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  amountInput: {
    ...Typography.styles.h1,
    color: '#FFFFFF',
    textAlign: 'center',
    minWidth: 200,
    fontWeight: 'bold',
    fontSize: 36,
  },
  currencyText: {
    ...Typography.styles.h3,
    color: '#FFFFFF',
    marginLeft: Spacing.sm,
    fontWeight: '600',
    fontSize: 20,
  },
  formSection: {
    paddingHorizontal: Spacing['2xl'],
    marginBottom: Spacing['2xl'],
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    borderRadius: Layout.radius.md,
    padding: Spacing.md,
    marginBottom: Spacing.md,
    ...Layout.shadow.sm,
  },
  inputIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  inputContent: {
    flex: 1,
  },
  inputLabel: {
    ...Typography.styles.bodySmall,
    color: 'rgba(255, 255, 255, 0.7)',
    marginBottom: Spacing.xs,
    fontWeight: '500',
  },
  inputValue: {
    ...Typography.styles.body,
    color: '#FFFFFF',
    fontWeight: '600',
    fontSize: 16,
  },
  placeholder: {
    color: 'rgba(255, 255, 255, 0.5)',
    fontWeight: 'normal',
  },
  textInput: {
    ...Typography.styles.body,
    color: '#FFFFFF',
    minHeight: 40,
    textAlignVertical: 'top',
    fontSize: 15,
  },
  saveButton: {
    marginHorizontal: Spacing['2xl'],
    marginBottom: Spacing['3xl'],
    borderRadius: Layout.radius.md,
    overflow: 'hidden',
    ...Layout.shadow.md,
  },
  saveButtonGradient: {
    paddingVertical: Spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  saveButtonText: {
    ...Typography.styles.button,
    color: Colors.text.inverse,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing['2xl'],
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  modalTitle: {
    ...Typography.styles.h4,
    color: '#FFFFFF',
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing['2xl'],
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  categoryIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  categoryEmoji: {
    fontSize: 20,
  },
  categoryName: {
    ...Typography.styles.body,
    color: '#FFFFFF',
    flex: 1,
  },
  receiptSection: {
    flex: 1,
    padding: Spacing['2xl'],
    justifyContent: 'center',
  },
  receiptUploadArea: {
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 16,
    borderWidth: 2,
    borderColor: Colors.primary[500],
    borderStyle: 'dashed',
    padding: 40,
    alignItems: 'center',
    minHeight: 300,
    justifyContent: 'center',
  },
  receiptTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 16,
    marginBottom: 8,
  },
  receiptDescription: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    marginBottom: 32,
    lineHeight: 20,
  },
  cameraButton: {
    backgroundColor: Colors.primary[500],
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 32,
    marginBottom: 12,
  },
  cameraButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  galleryButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 32,
  },
  galleryButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  // Enhanced Vietnamese styles
  suggestionCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    marginHorizontal: Spacing['2xl'],
    marginBottom: Spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: Colors.primary[500],
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  suggestionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  suggestionIcon: {
    fontSize: 20,
    marginRight: 8,
  },
  suggestionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.primary[500],
    flex: 1,
  },
  suggestionSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    fontStyle: 'italic',
  },
  suggestionsScroll: {
    marginTop: 8,
  },
  smartSuggestionChip: {
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
    borderRadius: 12,
    padding: 12,
    marginRight: 8,
    alignItems: 'center',
    minWidth: 90,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  suggestionChipIcon: {
    fontSize: 18,
    marginBottom: 4,
  },
  suggestionChipLabel: {
    fontSize: 11,
    color: Colors.primary[500],
    fontWeight: '600',
    marginBottom: 2,
    textAlign: 'center',
  },
  suggestionChipAmount: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  suggestionText: {
    fontSize: 13,
    color: '#FFFFFF',
    lineHeight: 18,
    marginBottom: 12,
  },
  applySuggestionButton: {
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 8,
    paddingVertical: 8,
    paddingHorizontal: 12,
    alignSelf: 'flex-start',
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  applySuggestionText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  amountHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    marginBottom: Spacing.md,
  },
  voiceButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  voiceButtonInner: {
    marginRight: 4,
  },
  voiceButtonText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  quickAmountsContainer: {
    marginTop: 20,
    width: '100%',
  },
  quickAmountsLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
    textAlign: 'center',
  },
  quickAmountsScroll: {
    maxHeight: 80,
  },
  quickAmountChip: {
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
    borderRadius: 12,
    padding: 12,
    marginRight: 8,
    alignItems: 'center',
    minWidth: 80,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  quickAmountIcon: {
    fontSize: 16,
    marginBottom: 4,
  },
  quickAmountLabel: {
    fontSize: 10,
    color: Colors.primary[500],
    fontWeight: '600',
    marginBottom: 2,
  },
  quickAmountValue: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  merchantSuggestions: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  merchantSuggestionsTitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  merchantChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginRight: 8,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  merchantIcon: {
    fontSize: 14,
    marginRight: 4,
  },
  merchantName: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '500',
  },
  merchantConfidence: {
    fontSize: 10,
    color: '#4CAF50',
    fontWeight: '600',
    marginLeft: 4,
  },
  // Payment Method Styles
  paymentMethodIcon: {
    fontSize: 20,
  },
  paymentSuggestion: {
    fontSize: 11,
    color: Colors.primary[500],
    fontStyle: 'italic',
    marginTop: 2,
  },
  paymentMethodItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing['2xl'],
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.05)',
  },
  paymentMethodIconContainer: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  paymentMethodItemIcon: {
    fontSize: 24,
  },
  paymentMethodName: {
    ...Typography.styles.body,
    color: '#FFFFFF',
    flex: 1,
    fontWeight: '600',
  },
  paymentMethodTips: {
    backgroundColor: 'rgba(61, 161, 61, 0.1)',
    margin: 20,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  paymentMethodTipsTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.primary[500],
    marginBottom: 8,
  },
  paymentMethodTip: {
    fontSize: 12,
    color: '#FFFFFF',
    marginBottom: 4,
    lineHeight: 16,
  },
});

export default AddExpenseScreen;
