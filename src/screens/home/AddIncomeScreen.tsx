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
import { PaymentMethod, Currency } from '../../types';
import { useApp } from '../../context/AppContext';

// Vietnamese Income Categories
enum IncomeCategory {
  SALARY = 'salary',
  FREELANCE = 'freelance',
  BUSINESS = 'business',
  INVESTMENT = 'investment',
  BONUS = 'bonus',
  GIFT = 'gift',
  SCHOLARSHIP = 'scholarship',
  PARTTIME = 'parttime',
  OTHER = 'other',
}

interface IncomeCategoryOption {
  id: string;
  category: IncomeCategory;
  name: string;
  icon: string;
  color: string;
}

// Enhanced Vietnamese Payment Methods for Income
const VIETNAMESE_INCOME_PAYMENT_METHODS = [
  { id: 'banking', name: 'Chuyển khoản ngân hàng', icon: '🏦', color: '#FF9800' },
  { id: 'cash', name: 'Tiền mặt', icon: '💰', color: '#4CAF50' },
  { id: 'momo', name: 'MoMo', icon: '🎯', color: '#D82D8B' },
  { id: 'zalopay', name: 'ZaloPay', icon: '💙', color: '#0068FF' },
  { id: 'viettelpay', name: 'ViettelPay', icon: '📱', color: '#FF5722' },
  { id: 'card', name: 'Thẻ ATM/Credit', icon: '💳', color: '#9C27B0' },
];

const incomeCategoryOptions: IncomeCategoryOption[] = [
  {
    id: '1',
    category: IncomeCategory.SALARY,
    name: 'Lương',
    icon: '💼',
    color: '#4CAF50',
  },
  {
    id: '2',
    category: IncomeCategory.FREELANCE,
    name: 'Freelance',
    icon: '💻',
    color: '#2196F3',
  },
  {
    id: '3',
    category: IncomeCategory.BUSINESS,
    name: 'Kinh doanh',
    icon: '🏪',
    color: '#FF9800',
  },
  {
    id: '4',
    category: IncomeCategory.INVESTMENT,
    name: 'Đầu tư',
    icon: '📈',
    color: '#9C27B0',
  },
  {
    id: '5',
    category: IncomeCategory.BONUS,
    name: 'Thưởng',
    icon: '🎁',
    color: '#FF5722',
  },
  {
    id: '6',
    category: IncomeCategory.SCHOLARSHIP,
    name: 'Học bổng',
    icon: '🎓',
    color: '#795548',
  },
  {
    id: '7',
    category: IncomeCategory.PARTTIME,
    name: 'Part-time',
    icon: '⏰',
    color: '#607D8B',
  },
  {
    id: '8',
    category: IncomeCategory.GIFT,
    name: 'Quà tặng/Lì xì',
    icon: '🧧',
    color: '#E91E63',
  },
  {
    id: '9',
    category: IncomeCategory.OTHER,
    name: 'Khác',
    icon: '💰',
    color: Colors.text.secondary,
  },
];

const AddIncomeScreen: React.FC = () => {
  const navigation = useNavigation();
  const { dataActions } = useApp();
  const [amount, setAmount] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<IncomeCategoryOption | null>(null);
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState(
    VIETNAMESE_INCOME_PAYMENT_METHODS[0]
  );
  const [recurringType, setRecurringType] = useState<'none' | 'weekly' | 'monthly' | 'yearly'>(
    'none'
  );
  const [isVoiceRecording, setIsVoiceRecording] = useState(false);
  const [showSmartSuggestions, setShowSmartSuggestions] = useState(false);

  const voiceAnimation = useRef(new Animated.Value(1)).current;
  const suggestionsAnimation = useRef(new Animated.Value(0)).current;

  // Vietnamese income patterns based on research
  const vietnameseIncomeAmounts = [
    // Student income
    {
      amount: '500000',
      label: 'Học bổng',
      icon: '🎓',
      category: IncomeCategory.SCHOLARSHIP,
      frequency: 'monthly',
    },
    {
      amount: '1000000',
      label: 'Part-time',
      icon: '⏰',
      category: IncomeCategory.PARTTIME,
      frequency: 'monthly',
    },
    {
      amount: '200000',
      label: 'Lì xì Tết',
      icon: '🧧',
      category: IncomeCategory.GIFT,
      frequency: 'once',
    },

    // Professional income
    {
      amount: '8000000',
      label: 'Lương junior',
      icon: '💼',
      category: IncomeCategory.SALARY,
      frequency: 'monthly',
    },
    {
      amount: '15000000',
      label: 'Lương senior',
      icon: '💼',
      category: IncomeCategory.SALARY,
      frequency: 'monthly',
    },
    {
      amount: '25000000',
      label: 'Lương manager',
      icon: '💼',
      category: IncomeCategory.SALARY,
      frequency: 'monthly',
    },

    // Freelance & Business
    {
      amount: '2000000',
      label: 'Freelance web',
      icon: '💻',
      category: IncomeCategory.FREELANCE,
      frequency: 'project',
    },
    {
      amount: '5000000',
      label: 'Dự án lớn',
      icon: '💻',
      category: IncomeCategory.FREELANCE,
      frequency: 'project',
    },
    {
      amount: '3000000',
      label: 'Bán hàng online',
      icon: '🏪',
      category: IncomeCategory.BUSINESS,
      frequency: 'monthly',
    },

    // Investment & Bonus
    {
      amount: '1000000',
      label: 'Cổ tức',
      icon: '📈',
      category: IncomeCategory.INVESTMENT,
      frequency: 'quarterly',
    },
    {
      amount: '10000000',
      label: 'Thưởng cuối năm',
      icon: '🎁',
      category: IncomeCategory.BONUS,
      frequency: 'yearly',
    },
    {
      amount: '2000000',
      label: 'Thưởng tháng 13',
      icon: '🎁',
      category: IncomeCategory.BONUS,
      frequency: 'yearly',
    },
  ];

  // Vietnamese income sources with smart categorization
  const vietnameseIncomeSources = [
    // Companies
    { name: 'FPT Software', category: IncomeCategory.SALARY, icon: '💼', confidence: 0.95 },
    { name: 'Vietcombank', category: IncomeCategory.SALARY, icon: '🏦', confidence: 0.95 },
    { name: 'Shopee', category: IncomeCategory.SALARY, icon: '💼', confidence: 0.95 },
    { name: 'Grab', category: IncomeCategory.SALARY, icon: '💼', confidence: 0.95 },

    // Freelance platforms
    { name: 'Upwork', category: IncomeCategory.FREELANCE, icon: '💻', confidence: 0.9 },
    { name: 'Fiverr', category: IncomeCategory.FREELANCE, icon: '💻', confidence: 0.9 },
    { name: 'Freelancer.com', category: IncomeCategory.FREELANCE, icon: '💻', confidence: 0.9 },

    // Vietnamese platforms
    { name: 'Tiki', category: IncomeCategory.BUSINESS, icon: '🏪', confidence: 0.88 },
    { name: 'Lazada', category: IncomeCategory.BUSINESS, icon: '🏪', confidence: 0.88 },
    { name: 'Sendo', category: IncomeCategory.BUSINESS, icon: '🏪', confidence: 0.85 },

    // Investment
    { name: 'VietStock', category: IncomeCategory.INVESTMENT, icon: '📈', confidence: 0.9 },
    { name: 'SSI', category: IncomeCategory.INVESTMENT, icon: '📈', confidence: 0.9 },
    {
      name: 'Techcombank Securities',
      category: IncomeCategory.INVESTMENT,
      icon: '📈',
      confidence: 0.88,
    },

    // Education
    { name: 'Học bổng', category: IncomeCategory.SCHOLARSHIP, icon: '🎓', confidence: 0.95 },
    { name: 'Trường Đại học', category: IncomeCategory.SCHOLARSHIP, icon: '🎓', confidence: 0.9 },
    { name: 'Chính phủ', category: IncomeCategory.SCHOLARSHIP, icon: '🎓', confidence: 0.85 },
  ];

  // Smart suggestions based on time and context
  const getSmartIncomeSuggestions = () => {
    const day = new Date().getDate();
    const month = new Date().getMonth();

    // End of month salary suggestions
    if (day >= 25) {
      return [
        {
          description: 'Lương tháng',
          category: IncomeCategory.SALARY,
          amount: '12000000',
          icon: '💼',
        },
        {
          description: 'Thưởng hiệu suất',
          category: IncomeCategory.BONUS,
          amount: '2000000',
          icon: '🎁',
        },
        { description: 'Overtime', category: IncomeCategory.SALARY, amount: '1500000', icon: '⏰' },
      ];
    }

    // Tet season (January/February)
    if (month === 0 || month === 1) {
      return [
        { description: 'Lì xì Tết', category: IncomeCategory.GIFT, amount: '500000', icon: '🧧' },
        {
          description: 'Thưởng Tết',
          category: IncomeCategory.BONUS,
          amount: '10000000',
          icon: '🎁',
        },
        {
          description: 'Tháng lương 13',
          category: IncomeCategory.BONUS,
          amount: '12000000',
          icon: '💼',
        },
      ];
    }

    // Quarter end
    if (month === 2 || month === 5 || month === 8 || month === 11) {
      return [
        {
          description: 'Thưởng quý',
          category: IncomeCategory.BONUS,
          amount: '5000000',
          icon: '🎁',
        },
        {
          description: 'Cổ tức',
          category: IncomeCategory.INVESTMENT,
          amount: '2000000',
          icon: '📈',
        },
        {
          description: 'Lương quý',
          category: IncomeCategory.SALARY,
          amount: '15000000',
          icon: '💼',
        },
      ];
    }

    // Default suggestions
    return [
      {
        description: 'Freelance project',
        category: IncomeCategory.FREELANCE,
        amount: '3000000',
        icon: '💻',
      },
      {
        description: 'Bán hàng online',
        category: IncomeCategory.BUSINESS,
        amount: '2000000',
        icon: '🏪',
      },
      {
        description: 'Thu nhập khác',
        category: IncomeCategory.OTHER,
        amount: '1000000',
        icon: '💰',
      },
    ];
  };

  // Get income amounts filtered by category
  const getCategoryIncomeAmounts = (category?: IncomeCategory) => {
    if (!category) return vietnameseIncomeAmounts;
    return vietnameseIncomeAmounts.filter(item => item.category === category);
  };

  // Smart payment method suggestion for income
  const suggestIncomePaymentMethod = (amount: number, category: IncomeCategory) => {
    // Salary usually via bank transfer
    if (category === IncomeCategory.SALARY || category === IncomeCategory.BONUS) {
      return VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'banking');
    }

    // Small gifts/cash
    if (category === IncomeCategory.GIFT && amount <= 1000000) {
      return VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'cash');
    }

    // Freelance - usually MoMo/ZaloPay or bank
    if (category === IncomeCategory.FREELANCE) {
      return amount <= 5000000
        ? VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'momo')
        : VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'banking');
    }

    // Default to banking for large amounts
    if (amount > 2000000) {
      return VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'banking');
    }

    return VIETNAMESE_INCOME_PAYMENT_METHODS.find(p => p.id === 'momo');
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

    // Auto-suggest payment method based on amount and category
    if (numericValue && selectedCategory) {
      const suggestedMethod = suggestIncomePaymentMethod(
        parseInt(numericValue),
        selectedCategory.category
      );
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
      setIsVoiceRecording(false);
      Animated.timing(voiceAnimation, {
        toValue: 1,
        duration: 200,
        useNativeDriver: true,
      }).start();

      setTimeout(() => {
        Alert.alert(
          'Nhận diện giọng nói',
          'Đã nghe được: "Lương tháng 12 triệu đồng từ công ty FPT"',
          [
            { text: 'Hủy', style: 'cancel' },
            {
              text: 'Áp dụng',
              onPress: () => {
                setAmount('12000000');
                setDescription('Lương tháng từ FPT Software');
                const salaryCategory = incomeCategoryOptions.find(
                  cat => cat.category === IncomeCategory.SALARY
                );
                if (salaryCategory) setSelectedCategory(salaryCategory);
              },
            },
          ]
        );
      }, 1500);
    } else {
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

    const suggestedCategory = incomeCategoryOptions.find(
      cat => cat.category === quickAmount.category
    );
    if (suggestedCategory) {
      setSelectedCategory(suggestedCategory);
    }

    const suggestedMethod = suggestIncomePaymentMethod(
      parseInt(quickAmount.amount),
      quickAmount.category
    );
    if (suggestedMethod) {
      setSelectedPaymentMethod(suggestedMethod);
    }
  };

  const handleSmartSuggestion = (suggestion: any) => {
    setAmount(suggestion.amount);
    setDescription(suggestion.description);

    const suggestedCategory = incomeCategoryOptions.find(
      cat => cat.category === suggestion.category
    );
    if (suggestedCategory) {
      setSelectedCategory(suggestedCategory);
    }

    const suggestedMethod = suggestIncomePaymentMethod(
      parseInt(suggestion.amount),
      suggestion.category
    );
    if (suggestedMethod) {
      setSelectedPaymentMethod(suggestedMethod);
    }
  };

  const handleSourceSuggestion = (source: any) => {
    setDescription(source.name);
    const suggestedCategory = incomeCategoryOptions.find(cat => cat.category === source.category);
    if (suggestedCategory && !selectedCategory) {
      setSelectedCategory(suggestedCategory);
    }
  };

  const handleSaveIncome = async () => {
    if (!amount || !selectedCategory) {
      Alert.alert('Lỗi', 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setIsLoading(true);
    try {
      const numericAmount = parseInt(amount.replace(/[^0-9]/g, ''));

      const income = {
        amount: numericAmount,
        category: selectedCategory.category,
        description: description || selectedCategory.name,
        date: date,
        paymentMethod: selectedPaymentMethod.id as PaymentMethod,
        currency: Currency.VND,
        source: description,
        isRecurring: recurringType !== 'none',
        recurringType: recurringType,
      };

      await dataActions.addIncome(income);

      Alert.alert(
        'Thành công',
        `Thu nhập ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(numericAmount)} đã được lưu!`,
        [{ text: 'OK', onPress: () => navigation.goBack() }]
      );
    } catch (error) {
      console.error('Error saving income:', error);
      Alert.alert('Lỗi', 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      setIsLoading(false);
    }
  };

  const renderCategoryItem = ({ item }: { item: IncomeCategoryOption }) => (
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
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Ionicons name="arrow-back" size={24} color="#FFFFFF" />
        </TouchableOpacity>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle}>Thêm Thu nhập</Text>
          <Text style={styles.headerSubtitle}>Ghi lại nguồn thu nhập của bạn</Text>
        </View>
      </View>

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Smart AI Suggestions Card */}
        <View style={styles.suggestionCard}>
          <View style={styles.suggestionHeader}>
            <Text style={styles.suggestionIcon}>💡</Text>
            <Text style={styles.suggestionTitle}>Gợi ý thu nhập thông minh</Text>
            <Text style={styles.suggestionSubtitle}>Phù hợp với thời điểm hiện tại</Text>
          </View>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.suggestionsScroll}
          >
            {getSmartIncomeSuggestions().map((suggestion, index) => (
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
            <Text style={styles.amountLabel}>Số tiền thu nhập</Text>
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
              placeholderTextColor="rgba(76, 175, 80, 0.4)"
              value={formatCurrencyDisplay(amount)}
              onChangeText={handleAmountChange}
              keyboardType="numeric"
            />
            <Text style={styles.currencyText}>VND</Text>
          </View>

          {/* Category-based Quick Amount Chips */}
          <View style={styles.quickAmountsContainer}>
            <Text style={styles.quickAmountsLabel}>
              {selectedCategory
                ? `Thu nhập ${selectedCategory.name.toLowerCase()}`
                : 'Số tiền thu nhập phổ biến'}
            </Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.quickAmountsScroll}
            >
              {getCategoryIncomeAmounts(selectedCategory?.category)
                .slice(0, 8)
                .map((item, index) => (
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
                    <Text style={styles.quickAmountFrequency}>{item.frequency}</Text>
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
              <Ionicons name="briefcase-outline" size={20} color="rgba(255, 255, 255, 0.7)" />
            </View>
            <View style={styles.inputContent}>
              <Text style={styles.inputLabel}>Loại thu nhập</Text>
              <Text style={[styles.inputValue, !selectedCategory && styles.placeholder]}>
                {selectedCategory ? selectedCategory.name : 'Chọn loại thu nhập...'}
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="rgba(255, 255, 255, 0.7)" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.inputContainer} onPress={() => setShowPaymentModal(true)}>
            <View
              style={[styles.inputIcon, { backgroundColor: selectedPaymentMethod.color + '20' }]}
            >
              <Text style={styles.paymentMethodIcon}>{selectedPaymentMethod.icon}</Text>
            </View>
            <View style={styles.inputContent}>
              <Text style={styles.inputLabel}>Phương thức nhận</Text>
              <Text style={styles.inputValue}>{selectedPaymentMethod.name}</Text>
              {amount && selectedCategory && (
                <Text style={styles.paymentSuggestion}>
                  Gợi ý cho {selectedCategory.name.toLowerCase()} {formatCurrencyDisplay(amount)}{' '}
                  VND
                </Text>
              )}
            </View>
            <Ionicons name="chevron-forward" size={20} color="rgba(255, 255, 255, 0.7)" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.inputContainer} onPress={() => setShowDatePicker(true)}>
            <View style={styles.inputIcon}>
              <Ionicons name="calendar-outline" size={20} color="rgba(255, 255, 255, 0.7)" />
            </View>
            <View style={styles.inputContent}>
              <Text style={styles.inputLabel}>Ngày nhận</Text>
              <Text style={styles.inputValue}>{date.toLocaleDateString('vi-VN')}</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="rgba(255, 255, 255, 0.7)" />
          </TouchableOpacity>

          <View style={styles.inputContainer}>
            <View style={styles.inputIcon}>
              <Ionicons name="document-text-outline" size={20} color="rgba(255, 255, 255, 0.7)" />
            </View>
            <View style={styles.inputContent}>
              <Text style={styles.inputLabel}>Nguồn thu nhập (tùy chọn)</Text>
              <TextInput
                style={styles.textInput}
                placeholder="VD: Công ty FPT, Dự án freelance, Đầu tư chứng khoán..."
                placeholderTextColor="rgba(255, 255, 255, 0.5)"
                value={description}
                onChangeText={setDescription}
                multiline
                numberOfLines={2}
              />

              {/* AI-Enhanced Vietnamese Source Suggestions */}
              {description.length > 0 && (
                <View style={styles.sourceSuggestions}>
                  <Text style={styles.sourceSuggestionsTitle}>Gợi ý nguồn thu nhập</Text>
                  <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                    {vietnameseIncomeSources
                      .filter(
                        source =>
                          source.name.toLowerCase().includes(description.toLowerCase()) ||
                          description
                            .toLowerCase()
                            .includes(source.name.toLowerCase().substring(0, 3))
                      )
                      .sort((a, b) => b.confidence - a.confidence)
                      .slice(0, 6)
                      .map((source, index) => (
                        <TouchableOpacity
                          key={index}
                          style={[
                            styles.sourceChip,
                            {
                              borderColor:
                                source.confidence > 0.9 ? '#4CAF50' : 'rgba(61, 161, 61, 0.3)',
                            },
                          ]}
                          onPress={() => handleSourceSuggestion(source)}
                        >
                          <Text style={styles.sourceIcon}>{source.icon}</Text>
                          <Text style={styles.sourceName}>{source.name}</Text>
                          <Text style={styles.sourceConfidence}>
                            {Math.round(source.confidence * 100)}%
                          </Text>
                        </TouchableOpacity>
                      ))}
                  </ScrollView>
                </View>
              )}
            </View>
          </View>
        </View>

        <TouchableOpacity style={styles.saveButton} onPress={handleSaveIncome} disabled={isLoading}>
          <LinearGradient
            colors={['#4CAF50', '#2E7D32']}
            style={styles.saveButtonGradient}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          >
            <Text style={styles.saveButtonText}>
              {isLoading ? 'Đang lưu...' : '💰 Lưu thu nhập'}
            </Text>
          </LinearGradient>
        </TouchableOpacity>
      </ScrollView>

      {/* Payment Method Selection Modal */}
      <Modal visible={showPaymentModal} animationType="slide" presentationStyle="pageSheet">
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Chọn phương thức nhận tiền</Text>
            <TouchableOpacity onPress={() => setShowPaymentModal(false)}>
              <Ionicons name="close" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          <ScrollView showsVerticalScrollIndicator={false}>
            {VIETNAMESE_INCOME_PAYMENT_METHODS.map((method, index) => (
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
              <Text style={styles.paymentMethodTipsTitle}>💡 Phương thức nhận tiền phổ biến</Text>
              <Text style={styles.paymentMethodTip}>• Lương: Chuyển khoản ngân hàng</Text>
              <Text style={styles.paymentMethodTip}>• Freelance: MoMo, ZaloPay</Text>
              <Text style={styles.paymentMethodTip}>• Lì xì, quà: Tiền mặt</Text>
              <Text style={styles.paymentMethodTip}>• Đầu tư: Chuyển khoản</Text>
            </View>
          </ScrollView>
        </View>
      </Modal>

      {/* Category Selection Modal */}
      <Modal visible={showCategoryModal} animationType="slide" presentationStyle="pageSheet">
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Chọn loại thu nhập</Text>
            <TouchableOpacity onPress={() => setShowCategoryModal(false)}>
              <Ionicons name="close" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          <FlatList
            data={incomeCategoryOptions}
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
    backgroundColor: '#1A2E3A',
  },
  backButton: {
    marginRight: 16,
  },
  headerContent: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  headerSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
    marginTop: 2,
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  suggestionCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 16,
    padding: 16,
    marginHorizontal: Spacing['2xl'],
    marginBottom: Spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: '#4CAF50',
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
    color: '#4CAF50',
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
    backgroundColor: 'rgba(76, 175, 80, 0.15)',
    borderRadius: 12,
    padding: 12,
    marginRight: 8,
    alignItems: 'center',
    minWidth: 90,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.3)',
  },
  suggestionChipIcon: {
    fontSize: 18,
    marginBottom: 4,
  },
  suggestionChipLabel: {
    fontSize: 11,
    color: '#4CAF50',
    fontWeight: '600',
    marginBottom: 2,
    textAlign: 'center',
  },
  suggestionChipAmount: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  amountSection: {
    padding: Spacing['2xl'],
    alignItems: 'center',
  },
  amountHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    marginBottom: Spacing.md,
  },
  amountLabel: {
    ...Typography.styles.body,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: Spacing.md,
  },
  voiceButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(76, 175, 80, 0.2)',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: '#4CAF50',
  },
  voiceButtonInner: {
    marginRight: 4,
  },
  voiceButtonText: {
    fontSize: 12,
    color: '#4CAF50',
    fontWeight: '600',
  },
  amountInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  amountInput: {
    ...Typography.styles.h1,
    color: '#4CAF50',
    textAlign: 'center',
    minWidth: 200,
    fontWeight: 'bold',
    fontSize: 36,
  },
  currencyText: {
    ...Typography.styles.h3,
    color: '#4CAF50',
    marginLeft: Spacing.sm,
    fontWeight: '600',
    fontSize: 20,
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
    maxHeight: 100,
  },
  quickAmountChip: {
    backgroundColor: 'rgba(76, 175, 80, 0.15)',
    borderRadius: 12,
    padding: 12,
    marginRight: 8,
    alignItems: 'center',
    minWidth: 90,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.3)',
  },
  quickAmountIcon: {
    fontSize: 16,
    marginBottom: 4,
  },
  quickAmountLabel: {
    fontSize: 10,
    color: '#4CAF50',
    fontWeight: '600',
    marginBottom: 2,
    textAlign: 'center',
  },
  quickAmountValue: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: '500',
    marginBottom: 2,
  },
  quickAmountFrequency: {
    fontSize: 9,
    color: 'rgba(255, 255, 255, 0.6)',
    fontStyle: 'italic',
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
  paymentMethodIcon: {
    fontSize: 20,
  },
  paymentSuggestion: {
    fontSize: 11,
    color: '#4CAF50',
    fontStyle: 'italic',
    marginTop: 2,
  },
  sourceSuggestions: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  sourceSuggestionsTitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  sourceChip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(76, 175, 80, 0.15)',
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginRight: 8,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.3)',
  },
  sourceIcon: {
    fontSize: 14,
    marginRight: 4,
  },
  sourceName: {
    fontSize: 12,
    color: '#4CAF50',
    fontWeight: '500',
  },
  sourceConfidence: {
    fontSize: 10,
    color: '#4CAF50',
    fontWeight: '600',
    marginLeft: 4,
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
    fontSize: 16,
    fontWeight: 'bold',
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
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
    margin: 20,
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.3)',
  },
  paymentMethodTipsTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#4CAF50',
    marginBottom: 8,
  },
  paymentMethodTip: {
    fontSize: 12,
    color: '#FFFFFF',
    marginBottom: 4,
    lineHeight: 16,
  },
});

export default AddIncomeScreen;
