import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  Modal,
  Switch,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { Colors } from '../../constants/colors';
import { ExpenseCategory, BudgetPeriod } from '../../types';
import { BackButton } from '../../components';

interface CategoryBudget {
  category: ExpenseCategory;
  name: string;
  icon: string;
  color: string;
  allocatedAmount: number;
  percentage: number;
  isSelected: boolean;
  priority: 'high' | 'medium' | 'low';
}

interface BudgetTemplate {
  id: string;
  name: string;
  description: string;
  icon: string;
  totalAmount: number;
  period: BudgetPeriod;
  categories: CategoryBudget[];
  isVietnameseOptimized: boolean;
}

const CreateBudgetScreen: React.FC = () => {
  const navigation = useNavigation();

  // Basic Budget Info
  const [budgetName, setBudgetName] = useState('');
  const [totalBudget, setTotalBudget] = useState('');
  const [monthlyIncome, setMonthlyIncome] = useState('');
  const [budgetPeriod, setBudgetPeriod] = useState<BudgetPeriod>(BudgetPeriod.MONTHLY);
  const [selectedTemplate, setSelectedTemplate] = useState<string | null>(null);

  // Advanced Settings
  const [autoSaving, setAutoSaving] = useState(true);
  const [emergencyFund, setEmergencyFund] = useState(true);
  const [smartAlerts, setSmartAlerts] = useState(true);
  const [weeklyReview, setWeeklyReview] = useState(false);

  // Categories
  const [categories, setCategories] = useState<CategoryBudget[]>([
    {
      category: ExpenseCategory.FOOD,
      name: 'Ăn uống',
      icon: '🍽️',
      color: '#FF6B6B',
      allocatedAmount: 0,
      percentage: 30,
      isSelected: true,
      priority: 'high',
    },
    {
      category: ExpenseCategory.TRANSPORT,
      name: 'Di chuyển',
      icon: '🚗',
      color: '#4ECDC4',
      allocatedAmount: 0,
      percentage: 15,
      isSelected: true,
      priority: 'high',
    },
    {
      category: ExpenseCategory.UTILITIES,
      name: 'Tiện ích',
      icon: '💡',
      color: '#FFD93D',
      allocatedAmount: 0,
      percentage: 10,
      isSelected: true,
      priority: 'high',
    },
    {
      category: ExpenseCategory.SHOPPING,
      name: 'Mua sắm',
      icon: '🛍️',
      color: '#45B7D1',
      allocatedAmount: 0,
      percentage: 15,
      isSelected: false,
      priority: 'medium',
    },
    {
      category: ExpenseCategory.ENTERTAINMENT,
      name: 'Giải trí',
      icon: '🎮',
      color: '#96CEB4',
      allocatedAmount: 0,
      percentage: 10,
      isSelected: false,
      priority: 'medium',
    },
    {
      category: ExpenseCategory.HEALTHCARE,
      name: 'Y tế',
      icon: '🏥',
      color: '#DDA0DD',
      allocatedAmount: 0,
      percentage: 5,
      isSelected: false,
      priority: 'medium',
    },
    {
      category: ExpenseCategory.EDUCATION,
      name: 'Giáo dục',
      icon: '📚',
      color: '#87CEEB',
      allocatedAmount: 0,
      percentage: 10,
      isSelected: false,
      priority: 'low',
    },
    {
      category: ExpenseCategory.OTHER,
      name: 'Khác',
      icon: '📝',
      color: '#D3D3D3',
      allocatedAmount: 0,
      percentage: 5,
      isSelected: false,
      priority: 'low',
    },
  ]);

  // Vietnamese Budget Templates
  const vietnameseBudgetTemplates: BudgetTemplate[] = [
    {
      id: 'student',
      name: 'Sinh viên Việt Nam',
      description: 'Ngân sách phù hợp cho sinh viên với tiền trợ cấp',
      icon: '🎓',
      totalAmount: 3000000,
      period: BudgetPeriod.MONTHLY,
      isVietnameseOptimized: true,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          name: 'Ăn uống',
          icon: '🍽️',
          color: '#FF6B6B',
          allocatedAmount: 1200000,
          percentage: 40,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          name: 'Di chuyển',
          icon: '🚗',
          color: '#4ECDC4',
          allocatedAmount: 450000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.EDUCATION,
          name: 'Học tập',
          icon: '📚',
          color: '#87CEEB',
          allocatedAmount: 600000,
          percentage: 20,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.ENTERTAINMENT,
          name: 'Giải trí',
          icon: '🎮',
          color: '#96CEB4',
          allocatedAmount: 450000,
          percentage: 15,
          isSelected: true,
          priority: 'medium',
        },
        {
          category: ExpenseCategory.OTHER,
          name: 'Khác',
          icon: '📝',
          color: '#D3D3D3',
          allocatedAmount: 300000,
          percentage: 10,
          isSelected: true,
          priority: 'low',
        },
      ],
    },
    {
      id: 'young_professional',
      name: 'Người trẻ mới đi làm',
      description: 'Ngân sách cho người mới ra trường, lương 8-15 triệu',
      icon: '👔',
      totalAmount: 8000000,
      period: BudgetPeriod.MONTHLY,
      isVietnameseOptimized: true,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          name: 'Ăn uống',
          icon: '🍽️',
          color: '#FF6B6B',
          allocatedAmount: 2400000,
          percentage: 30,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          name: 'Di chuyển',
          icon: '🚗',
          color: '#4ECDC4',
          allocatedAmount: 1200000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.UTILITIES,
          name: 'Tiện ích',
          icon: '💡',
          color: '#FFD93D',
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.SHOPPING,
          name: 'Mua sắm',
          icon: '🛍️',
          color: '#45B7D1',
          allocatedAmount: 1200000,
          percentage: 15,
          isSelected: true,
          priority: 'medium',
        },
        {
          category: ExpenseCategory.ENTERTAINMENT,
          name: 'Giải trí',
          icon: '🎮',
          color: '#96CEB4',
          allocatedAmount: 1600000,
          percentage: 20,
          isSelected: true,
          priority: 'medium',
        },
        {
          category: ExpenseCategory.OTHER,
          name: 'Khác',
          icon: '📝',
          color: '#D3D3D3',
          allocatedAmount: 800000,
          percentage: 10,
          isSelected: true,
          priority: 'low',
        },
      ],
    },
    {
      id: 'family',
      name: 'Gia đình có con nhỏ',
      description: 'Ngân sách cho gia đình 3-4 người, thu nhập 20-30 triệu',
      icon: '👨‍👩‍👧‍👦',
      totalAmount: 20000000,
      period: BudgetPeriod.MONTHLY,
      isVietnameseOptimized: true,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          name: 'Ăn uống',
          icon: '🍽️',
          color: '#FF6B6B',
          allocatedAmount: 8000000,
          percentage: 40,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.UTILITIES,
          name: 'Tiện ích',
          icon: '💡',
          color: '#FFD93D',
          allocatedAmount: 2000000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          name: 'Di chuyển',
          icon: '🚗',
          color: '#4ECDC4',
          allocatedAmount: 2000000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.HEALTHCARE,
          name: 'Y tế',
          icon: '🏥',
          color: '#DDA0DD',
          allocatedAmount: 2000000,
          percentage: 10,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.EDUCATION,
          name: 'Giáo dục con',
          icon: '📚',
          color: '#87CEEB',
          allocatedAmount: 3000000,
          percentage: 15,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.ENTERTAINMENT,
          name: 'Giải trí',
          icon: '🎮',
          color: '#96CEB4',
          allocatedAmount: 2000000,
          percentage: 10,
          isSelected: true,
          priority: 'medium',
        },
        {
          category: ExpenseCategory.OTHER,
          name: 'Khác',
          icon: '📝',
          color: '#D3D3D3',
          allocatedAmount: 1000000,
          percentage: 5,
          isSelected: true,
          priority: 'low',
        },
      ],
    },
    {
      id: 'tet_preparation',
      name: 'Chuẩn bị Tết Nguyên Đán',
      description: 'Ngân sách đặc biệt cho mùa Tết, bao gồm mua sắm và lì xì',
      icon: '🧧',
      totalAmount: 15000000,
      period: BudgetPeriod.MONTHLY,
      isVietnameseOptimized: true,
      categories: [
        {
          category: ExpenseCategory.FOOD,
          name: 'Đồ ăn Tết',
          icon: '🍽️',
          color: '#FF6B6B',
          allocatedAmount: 6000000,
          percentage: 40,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.SHOPPING,
          name: 'Quần áo mới',
          icon: '🛍️',
          color: '#45B7D1',
          allocatedAmount: 3000000,
          percentage: 20,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.OTHER,
          name: 'Lì xì, quà tặng',
          icon: '🎁',
          color: '#FFD700',
          allocatedAmount: 4500000,
          percentage: 30,
          isSelected: true,
          priority: 'high',
        },
        {
          category: ExpenseCategory.TRANSPORT,
          name: 'Về quê, đi chơi',
          icon: '🚗',
          color: '#4ECDC4',
          allocatedAmount: 1500000,
          percentage: 10,
          isSelected: true,
          priority: 'medium',
        },
      ],
    },
  ];

  const [showTemplateModal, setShowTemplateModal] = useState(false);

  const formatCurrency = (value: string) => {
    const numericValue = value.replace(/[^0-9]/g, '');
    if (!numericValue) return '';
    return new Intl.NumberFormat('vi-VN').format(parseInt(numericValue));
  };

  const handleBudgetChange = (text: string) => {
    const numericValue = text.replace(/[^0-9]/g, '');
    setTotalBudget(numericValue);
    updateCategoryAmounts(parseInt(numericValue) || 0);
  };

  const handleIncomeChange = (text: string) => {
    const numericValue = text.replace(/[^0-9]/g, '');
    setMonthlyIncome(numericValue);
  };

  const updateCategoryAmounts = (total: number) => {
    setCategories(prev =>
      prev.map(cat => ({
        ...cat,
        allocatedAmount: Math.round((total * cat.percentage) / 100),
      }))
    );
  };

  const toggleCategory = (categoryId: ExpenseCategory) => {
    setCategories(prev =>
      prev.map(cat => (cat.category === categoryId ? { ...cat, isSelected: !cat.isSelected } : cat))
    );
  };

  const updateCategoryPercentage = (categoryId: ExpenseCategory, percentage: number) => {
    const totalBudgetValue = parseInt(totalBudget) || 0;
    setCategories(prev =>
      prev.map(cat =>
        cat.category === categoryId
          ? {
              ...cat,
              percentage: Math.max(0, Math.min(100, percentage)),
              allocatedAmount: Math.round((totalBudgetValue * percentage) / 100),
            }
          : cat
      )
    );
  };

  const applyTemplate = (template: BudgetTemplate) => {
    setBudgetName(template.name);
    setTotalBudget(template.totalAmount.toString());
    setBudgetPeriod(template.period);
    setCategories(template.categories);
    setSelectedTemplate(template.id);
    setShowTemplateModal(false);
  };

  const getTotalPercentage = () => {
    return categories.filter(cat => cat.isSelected).reduce((sum, cat) => sum + cat.percentage, 0);
  };

  const handleCreateBudget = () => {
    if (!budgetName.trim()) {
      Alert.alert('Lỗi', 'Vui lòng nhập tên ngân sách');
      return;
    }

    if (!totalBudget) {
      Alert.alert('Lỗi', 'Vui lòng nhập tổng ngân sách');
      return;
    }

    const selectedCategories = categories.filter(cat => cat.isSelected);
    if (selectedCategories.length === 0) {
      Alert.alert('Lỗi', 'Vui lòng chọn ít nhất một danh mục chi tiêu');
      return;
    }

    const totalPercentage = getTotalPercentage();
    if (totalPercentage > 100) {
      Alert.alert(
        'Lỗi',
        `Tổng phần trăm (${totalPercentage}%) vượt quá 100%. Vui lòng điều chỉnh lại.`
      );
      return;
    }

    Alert.alert(
      'Tạo ngân sách thành công!',
      `Ngân sách "${budgetName}" đã được tạo với ${selectedCategories.length} danh mục chi tiêu.`,
      [
        {
          text: 'OK',
          onPress: () => navigation.goBack(),
        },
      ]
    );
  };

  const getPeriodName = (period: BudgetPeriod) => {
    switch (period) {
      case BudgetPeriod.WEEKLY:
        return 'Hàng tuần';
      case BudgetPeriod.MONTHLY:
        return 'Hàng tháng';
      case BudgetPeriod.QUARTERLY:
        return 'Hàng quý';
      case BudgetPeriod.YEARLY:
        return 'Hàng năm';
      default:
        return 'Hàng tháng';
    }
  };

  const renderTemplateModal = () => (
    <Modal visible={showTemplateModal} animationType="slide" presentationStyle="pageSheet">
      <View style={styles.modalContainer}>
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Chọn mẫu ngân sách</Text>
          <TouchableOpacity onPress={() => setShowTemplateModal(false)}>
            <Ionicons name="close" size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.modalContent} showsVerticalScrollIndicator={false}>
          {vietnameseBudgetTemplates.map(template => (
            <TouchableOpacity
              key={template.id}
              style={[
                styles.templateCard,
                selectedTemplate === template.id && styles.selectedTemplateCard,
              ]}
              onPress={() => applyTemplate(template)}
            >
              <View style={styles.templateHeader}>
                <Text style={styles.templateIcon}>{template.icon}</Text>
                <View style={styles.templateInfo}>
                  <Text style={styles.templateName}>{template.name}</Text>
                  <Text style={styles.templateDescription}>{template.description}</Text>
                </View>
                <Text style={styles.templateAmount}>
                  {formatCurrency(template.totalAmount.toString())}
                </Text>
              </View>

              <View style={styles.templateCategories}>
                {template.categories.slice(0, 3).map(cat => (
                  <View key={cat.category} style={styles.templateCategoryChip}>
                    <Text style={styles.templateCategoryText}>
                      {cat.icon} {cat.name}
                    </Text>
                  </View>
                ))}
                {template.categories.length > 3 && (
                  <Text style={styles.moreCategories}>+{template.categories.length - 3} khác</Text>
                )}
              </View>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>
    </Modal>
  );

  return (
    <View style={styles.container}>
      <BackButton
        title="Tạo ngân sách"
        rightComponent={
          <TouchableOpacity onPress={() => setShowTemplateModal(true)}>
            <Ionicons name="grid-outline" size={24} color={Colors.primary[500]} />
          </TouchableOpacity>
        }
      />
      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Budget Templates Quick Access */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Mẫu ngân sách phổ biến</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.templatesScroll}
          >
            {vietnameseBudgetTemplates.slice(0, 3).map(template => (
              <TouchableOpacity
                key={template.id}
                style={[
                  styles.templateQuickCard,
                  selectedTemplate === template.id && styles.selectedTemplateQuickCard,
                ]}
                onPress={() => applyTemplate(template)}
              >
                <Text style={styles.templateQuickIcon}>{template.icon}</Text>
                <Text style={styles.templateQuickName}>{template.name}</Text>
                <Text style={styles.templateQuickAmount}>
                  {formatCurrency(template.totalAmount.toString())}
                </Text>
              </TouchableOpacity>
            ))}
            <TouchableOpacity
              style={styles.moreTemplatesCard}
              onPress={() => setShowTemplateModal(true)}
            >
              <Ionicons name="add" size={24} color={Colors.primary[500]} />
              <Text style={styles.moreTemplatesText}>Xem thêm</Text>
            </TouchableOpacity>
          </ScrollView>
        </View>

        {/* Budget Name */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Tên ngân sách *</Text>
          <TextInput
            style={styles.input}
            placeholder="VD: Ngân sách tháng 12, Chuẩn bị Tết..."
            placeholderTextColor="rgba(255, 255, 255, 0.5)"
            value={budgetName}
            onChangeText={setBudgetName}
          />
        </View>

        {/* Income & Budget Amount */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Thu nhập & Ngân sách</Text>
          <View style={styles.inputGroup}>
            <View style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Thu nhập hàng tháng</Text>
              <View style={styles.budgetInputContainer}>
                <TextInput
                  style={styles.budgetInput}
                  placeholder="0"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={formatCurrency(monthlyIncome)}
                  onChangeText={handleIncomeChange}
                  keyboardType="numeric"
                />
                <Text style={styles.currencyLabel}>VND</Text>
              </View>
            </View>

            <View style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Tổng ngân sách *</Text>
              <View style={styles.budgetInputContainer}>
                <TextInput
                  style={styles.budgetInput}
                  placeholder="0"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  value={formatCurrency(totalBudget)}
                  onChangeText={handleBudgetChange}
                  keyboardType="numeric"
                />
                <Text style={styles.currencyLabel}>VND</Text>
              </View>
            </View>
          </View>

          {monthlyIncome && totalBudget && (
            <View style={styles.budgetAnalysis}>
              <Text style={styles.analysisText}>
                📊 Ngân sách ={' '}
                {((parseInt(totalBudget) / parseInt(monthlyIncome)) * 100).toFixed(1)}% thu nhập
              </Text>
              {parseInt(totalBudget) > parseInt(monthlyIncome) && (
                <Text style={styles.warningText}>
                  ⚠️ Ngân sách vượt quá thu nhập. Hãy cân nhắc điều chỉnh!
                </Text>
              )}
            </View>
          )}
        </View>

        {/* Budget Period */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Thời hạn ngân sách</Text>
          <View style={styles.periodContainer}>
            {Object.values(BudgetPeriod).map(period => (
              <TouchableOpacity
                key={period}
                style={[styles.periodCard, budgetPeriod === period && styles.activePeriodCard]}
                onPress={() => setBudgetPeriod(period)}
              >
                <Text
                  style={[styles.periodText, budgetPeriod === period && styles.activePeriodText]}
                >
                  {getPeriodName(period)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Categories */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Danh mục chi tiêu *</Text>
          <Text style={styles.sectionHint}>Tổng phần trăm: {getTotalPercentage()}% / 100%</Text>

          <View style={styles.categoriesContainer}>
            {categories.map(category => (
              <View key={category.category} style={styles.categoryCard}>
                <View style={styles.categoryHeader}>
                  <TouchableOpacity
                    style={styles.categoryToggle}
                    onPress={() => toggleCategory(category.category)}
                  >
                    <View
                      style={[
                        styles.categoryCheckbox,
                        category.isSelected && styles.categoryCheckboxSelected,
                      ]}
                    >
                      {category.isSelected && (
                        <Ionicons name="checkmark" size={14} color="#FFFFFF" />
                      )}
                    </View>
                    <Text style={styles.categoryIcon}>{category.icon}</Text>
                    <Text style={styles.categoryName}>{category.name}</Text>
                  </TouchableOpacity>

                  <View
                    style={[
                      styles.priorityBadge,
                      {
                        backgroundColor:
                          category.priority === 'high'
                            ? '#FF6B6B'
                            : category.priority === 'medium'
                              ? '#FFD93D'
                              : '#96CEB4',
                      },
                    ]}
                  >
                    <Text style={styles.priorityText}>
                      {category.priority === 'high'
                        ? 'Cao'
                        : category.priority === 'medium'
                          ? 'TB'
                          : 'Thấp'}
                    </Text>
                  </View>
                </View>

                {category.isSelected && (
                  <View style={styles.categoryDetails}>
                    <View style={styles.percentageContainer}>
                      <TextInput
                        style={styles.percentageInput}
                        value={category.percentage.toString()}
                        onChangeText={text =>
                          updateCategoryPercentage(category.category, parseFloat(text) || 0)
                        }
                        keyboardType="numeric"
                      />
                      <Text style={styles.percentageSymbol}>%</Text>
                    </View>
                    <Text style={styles.categoryAmount}>
                      {formatCurrency(category.allocatedAmount.toString())} VND
                    </Text>
                  </View>
                )}
              </View>
            ))}
          </View>
        </View>

        {/* Advanced Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Cài đặt nâng cao</Text>
          <View style={styles.settingsContainer}>
            <View style={styles.settingItem}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingTitle}>Tự động tiết kiệm</Text>
                <Text style={styles.settingDescription}>Tự động chuyển tiền dư vào tiết kiệm</Text>
              </View>
              <Switch
                value={autoSaving}
                onValueChange={setAutoSaving}
                trackColor={{ false: '#767577', true: Colors.primary[500] }}
                thumbColor={autoSaving ? '#FFFFFF' : '#f4f3f4'}
              />
            </View>

            <View style={styles.settingItem}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingTitle}>Quỹ khẩn cấp</Text>
                <Text style={styles.settingDescription}>Dành 10% cho chi phí bất ngờ</Text>
              </View>
              <Switch
                value={emergencyFund}
                onValueChange={setEmergencyFund}
                trackColor={{ false: '#767577', true: Colors.primary[500] }}
                thumbColor={emergencyFund ? '#FFFFFF' : '#f4f3f4'}
              />
            </View>

            <View style={styles.settingItem}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingTitle}>Cảnh báo thông minh</Text>
                <Text style={styles.settingDescription}>
                  Nhận thông báo khi chi tiêu vượt ngân sách
                </Text>
              </View>
              <Switch
                value={smartAlerts}
                onValueChange={setSmartAlerts}
                trackColor={{ false: '#767577', true: Colors.primary[500] }}
                thumbColor={smartAlerts ? '#FFFFFF' : '#f4f3f4'}
              />
            </View>

            <View style={styles.settingItem}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingTitle}>Báo cáo hàng tuần</Text>
                <Text style={styles.settingDescription}>Nhận báo cáo chi tiêu mỗi tuần</Text>
              </View>
              <Switch
                value={weeklyReview}
                onValueChange={setWeeklyReview}
                trackColor={{ false: '#767577', true: Colors.primary[500] }}
                thumbColor={weeklyReview ? '#FFFFFF' : '#f4f3f4'}
              />
            </View>
          </View>
        </View>

        {/* Create Button */}
        <View style={styles.createButtonContainer}>
          <TouchableOpacity style={styles.createButton} onPress={handleCreateBudget}>
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.createButtonGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Ionicons name="add" size={20} color="#FFFFFF" />
              <Text style={styles.createButtonText}>Tạo ngân sách</Text>
            </LinearGradient>
          </TouchableOpacity>
        </View>

        <View style={styles.bottomSpacing} />
      </ScrollView>

      {renderTemplateModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A2E3A',
  },
  scrollContainer: {
    flex: 1,
  },
  section: {
    paddingHorizontal: 20,
    marginBottom: 24,
  },
  sectionLabel: {
    fontSize: 16,
    color: Colors.primary[500],
    marginBottom: 8,
    fontWeight: '600',
  },
  sectionHint: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginBottom: 12,
  },
  input: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 16,
    fontSize: 16,
    color: '#FFFFFF',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  inputGroup: {
    gap: 12,
  },
  inputContainer: {
    flex: 1,
  },
  inputLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    marginBottom: 8,
  },
  budgetInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  budgetInput: {
    flex: 1,
    fontSize: 16,
    color: '#FFFFFF',
  },
  currencyLabel: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  budgetAnalysis: {
    marginTop: 12,
    padding: 12,
    backgroundColor: 'rgba(61, 161, 61, 0.1)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(61, 161, 61, 0.3)',
  },
  analysisText: {
    fontSize: 14,
    color: Colors.primary[500],
    marginBottom: 4,
  },
  warningText: {
    fontSize: 12,
    color: '#FF6B6B',
  },
  templatesScroll: {
    marginHorizontal: -20,
    paddingHorizontal: 20,
  },
  templateQuickCard: {
    width: 120,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 12,
    marginRight: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedTemplateQuickCard: {
    borderColor: Colors.primary[500],
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
  },
  templateQuickIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  templateQuickName: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
    textAlign: 'center',
  },
  templateQuickAmount: {
    fontSize: 10,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  moreTemplatesCard: {
    width: 120,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.primary[500],
  },
  moreTemplatesText: {
    fontSize: 12,
    color: Colors.primary[500],
    fontWeight: '600',
    marginTop: 4,
  },
  periodContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  periodCard: {
    flex: 1,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  activePeriodCard: {
    borderColor: Colors.primary[500],
    backgroundColor: Colors.primary[500],
  },
  periodText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  activePeriodText: {
    color: '#FFFFFF',
  },
  categoriesContainer: {
    gap: 12,
  },
  categoryCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  categoryToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  categoryCheckbox: {
    width: 20,
    height: 20,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    marginRight: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  categoryCheckboxSelected: {
    backgroundColor: Colors.primary[500],
    borderColor: Colors.primary[500],
  },
  categoryIcon: {
    fontSize: 18,
    marginRight: 12,
  },
  categoryName: {
    fontSize: 16,
    color: '#FFFFFF',
    fontWeight: '500',
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
  categoryDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
  },
  percentageContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1A2E3A',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  percentageInput: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    minWidth: 30,
    textAlign: 'center',
  },
  percentageSymbol: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 16,
    marginLeft: 4,
  },
  categoryAmount: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  settingsContainer: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    gap: 16,
  },
  settingItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  settingInfo: {
    flex: 1,
    marginRight: 16,
  },
  settingTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  settingDescription: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  createButtonContainer: {
    paddingHorizontal: 20,
    marginTop: 20,
  },
  createButton: {
    borderRadius: 12,
    overflow: 'hidden',
  },
  createButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
  },
  createButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginLeft: 8,
  },
  bottomSpacing: {
    height: 40,
  },
  // Modal Styles
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
  templateCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedTemplateCard: {
    borderColor: Colors.primary[500],
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
  },
  templateHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  templateIcon: {
    fontSize: 32,
    marginRight: 16,
  },
  templateInfo: {
    flex: 1,
  },
  templateName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  templateDescription: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    lineHeight: 16,
  },
  templateAmount: {
    fontSize: 14,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  templateCategories: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  templateCategoryChip: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  templateCategoryText: {
    fontSize: 11,
    color: '#FFFFFF',
  },
  moreCategories: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.6)',
    alignSelf: 'center',
  },
});

export default CreateBudgetScreen;
