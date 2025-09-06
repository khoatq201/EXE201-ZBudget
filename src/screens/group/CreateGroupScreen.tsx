import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  StatusBar,
  Alert,
  Switch,
  Modal,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { Colors } from '../../constants/colors';
import { BackButton } from '../../components';

const CreateGroupScreen: React.FC = () => {
  const navigation = useNavigation();
  const [groupName, setGroupName] = useState('');
  const [groupDescription, setGroupDescription] = useState('');
  const [totalBudget, setTotalBudget] = useState('');
  const [selectedCoverEmoji, setSelectedCoverEmoji] = useState('🎯');
  const [selectedCategories, setSelectedCategories] = useState<string[]>(['food', 'transport']);
  const [splitMethod, setSplitMethod] = useState<'equal' | 'percentage' | 'custom'>('equal');
  const [selectedTemplate, setSelectedTemplate] = useState<string | null>(null);

  // Enhanced Splitwise-inspired features
  const [showAdvancedSettings, setShowAdvancedSettings] = useState(false);
  const [debtSimplification, setDebtSimplification] = useState(true);
  const [autoReminders, setAutoReminders] = useState(true);
  const [currencyConversion, setCurrencyConversion] = useState(false);
  const [receiptScanning, setReceiptScanning] = useState(true);
  const [expenseApproval, setExpenseApproval] = useState(false);
  const [spendingLimits, setSpendingLimits] = useState(false);
  const [categoryBudgets, setCategoryBudgets] = useState<Record<string, number>>({});
  const [memberRoles, setMemberRoles] = useState<'democratic' | 'admin_controlled'>('democratic');
  const [privacyLevel, setPrivacyLevel] = useState<'open' | 'members_only' | 'admin_only'>(
    'members_only'
  );
  const [groupDuration, setGroupDuration] = useState<'permanent' | 'temporary' | 'event_based'>(
    'temporary'
  );
  const [endDate, setEndDate] = useState('');
  const [budgetAlerts, setBudgetAlerts] = useState(true);
  const [weeklyReports, setWeeklyReports] = useState(false);

  const coverEmojiOptions = [
    '🎯',
    '🏔️',
    '🏖️',
    '🎉',
    '🏠',
    '🚗',
    '✈️',
    '🍽️',
    '🎵',
    '📚',
    '💼',
    '🎮',
    '💒',
    '🎓',
    '🏪',
    '🍜',
  ];

  // Enhanced Vietnamese cultural group templates with advanced features
  const vietnameseTemplates = [
    {
      id: 'travel',
      name: 'Du lịch cuối tuần',
      description: 'Đà Lạt, Vũng Tàu, Sapa...',
      emoji: '🏔️',
      suggestedBudget: '5000000',
      categories: ['food', 'transport', 'accommodation', 'entertainment'],
      nameTemplate: 'Du lịch [Địa điểm]',
      descriptionTemplate: 'Chuyến đi cuối tuần với bạn bè',
      suggestedSettings: {
        splitMethod: 'equal',
        debtSimplification: true,
        receiptScanning: true,
        groupDuration: 'temporary',
        autoReminders: true,
        budgetAlerts: true,
      },
    },
    {
      id: 'wedding',
      name: 'Đám cưới',
      description: 'Mừng cưới, quà cưới, tiệc cưới',
      emoji: '💒',
      suggestedBudget: '10000000',
      categories: ['other', 'food', 'transport'],
      nameTemplate: 'Cưới [Tên cô dâu] & [Tên chú rể]',
      descriptionTemplate: 'Mừng cưới bạn thân ❤️',
      suggestedSettings: {
        splitMethod: 'percentage',
        debtSimplification: true,
        receiptScanning: true,
        groupDuration: 'event_based',
        memberRoles: 'admin_controlled',
        expenseApproval: true,
      },
    },
    {
      id: 'reunion',
      name: 'Họp lớp',
      description: 'Gặp mặt cựu học sinh',
      emoji: '🎓',
      suggestedBudget: '3000000',
      categories: ['food', 'entertainment', 'transport'],
      nameTemplate: 'Họp lớp [Tên lớp]',
      descriptionTemplate: 'Gặp mặt [X] năm tốt nghiệp',
    },
    {
      id: 'roommate',
      name: 'Nhà trọ/Căn hộ',
      description: 'Chi phí sinh hoạt hàng tháng',
      emoji: '🏠',
      suggestedBudget: '4000000',
      categories: ['utilities', 'food', 'other'],
      nameTemplate: 'Nhà trọ [Địa chỉ]',
      descriptionTemplate: 'Chi phí sinh hoạt hàng tháng',
      suggestedSettings: {
        splitMethod: 'equal',
        debtSimplification: true,
        receiptScanning: true,
        groupDuration: 'permanent',
        autoReminders: true,
        weeklyReports: true,
        spendingLimits: true,
      },
    },
    {
      id: 'teambuilding',
      name: 'Team Building',
      description: 'Hoạt động công ty',
      emoji: '🎯',
      suggestedBudget: '8000000',
      categories: ['food', 'transport', 'entertainment', 'accommodation'],
      nameTemplate: 'Team Building [Công ty]',
      descriptionTemplate: 'Hoạt động team building [Tháng/Năm]',
    },
    {
      id: 'tet',
      name: 'Tết Nguyên Đán',
      description: 'Mua sắm Tết, li xi, cúng kiếng',
      emoji: '🧧',
      suggestedBudget: '6000000',
      categories: ['food', 'shopping', 'other'],
      nameTemplate: 'Tết [Năm]',
      descriptionTemplate: 'Chuẩn bị Tết cùng gia đình',
      suggestedSettings: {
        splitMethod: 'custom',
        debtSimplification: true,
        receiptScanning: true,
        groupDuration: 'event_based',
        memberRoles: 'democratic',
        budgetAlerts: true,
        spendingLimits: true,
      },
    },
  ];

  const categories = [
    { id: 'food', name: 'Ăn uống', icon: '🍽️' },
    { id: 'transport', name: 'Di chuyển', icon: '🚗' },
    { id: 'accommodation', name: 'Lưu trú', icon: '🏨' },
    { id: 'entertainment', name: 'Giải trí', icon: '🎢' },
    { id: 'shopping', name: 'Mua sắm', icon: '🛍️' },
    { id: 'utilities', name: 'Tiện ích', icon: '💡' },
    { id: 'healthcare', name: 'Y tế', icon: '🏥' },
    { id: 'education', name: 'Giáo dục', icon: '📚' },
    { id: 'other', name: 'Khác', icon: '📝' },
  ];

  const formatCurrency = (value: string) => {
    const numericValue = value.replace(/[^0-9]/g, '');
    if (!numericValue) return '';
    return new Intl.NumberFormat('vi-VN').format(parseInt(numericValue));
  };

  const handleBudgetChange = (text: string) => {
    const numericValue = text.replace(/[^0-9]/g, '');
    setTotalBudget(numericValue);
  };

  const toggleCategory = (categoryId: string) => {
    setSelectedCategories(prev => {
      if (prev.includes(categoryId)) {
        return prev.filter(id => id !== categoryId);
      } else {
        return [...prev, categoryId];
      }
    });
  };

  const applyTemplate = (template: any) => {
    setSelectedTemplate(template.id);
    setSelectedCoverEmoji(template.emoji);
    setGroupName(template.nameTemplate);
    setGroupDescription(template.descriptionTemplate);
    setTotalBudget(template.suggestedBudget);
    setSelectedCategories(template.categories);

    // Apply suggested settings
    if (template.suggestedSettings) {
      setSplitMethod(template.suggestedSettings.splitMethod || 'equal');
      setDebtSimplification(template.suggestedSettings.debtSimplification ?? true);
      setReceiptScanning(template.suggestedSettings.receiptScanning ?? true);
      setGroupDuration(template.suggestedSettings.groupDuration || 'temporary');
      setAutoReminders(template.suggestedSettings.autoReminders ?? true);
      setBudgetAlerts(template.suggestedSettings.budgetAlerts ?? true);
      setWeeklyReports(template.suggestedSettings.weeklyReports ?? false);
      setSpendingLimits(template.suggestedSettings.spendingLimits ?? false);
      setMemberRoles(template.suggestedSettings.memberRoles || 'democratic');
      setExpenseApproval(template.suggestedSettings.expenseApproval ?? false);
    }
  };

  const handleCreateGroup = () => {
    if (!groupName.trim()) {
      Alert.alert('Lỗi', 'Vui lòng nhập tên nhóm');
      return;
    }

    if (!totalBudget) {
      Alert.alert('Lỗi', 'Vui lòng nhập tổng ngân sách');
      return;
    }

    if (selectedCategories.length === 0) {
      Alert.alert('Lỗi', 'Vui lòng chọn ít nhất một danh mục chi tiêu');
      return;
    }

    // In a real app, this would call an API to create the group
    Alert.alert('Thành công', 'Nhóm đã được tạo thành công!', [
      {
        text: 'OK',
        onPress: () => navigation.goBack(),
      },
    ]);
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1A2E3A" />
      <BackButton title="Tạo nhóm" />

      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        {/* Vietnamese Group Templates */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Mẫu nhóm phổ biến</Text>
          <Text style={styles.sectionHint}>Chọn mẫu có sẵn để tạo nhóm nhanh chóng</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.templatesScroll}
          >
            {vietnameseTemplates.map(template => (
              <TouchableOpacity
                key={template.id}
                style={[
                  styles.templateCard,
                  selectedTemplate === template.id && styles.selectedTemplateCard,
                ]}
                onPress={() => applyTemplate(template)}
              >
                <Text style={styles.templateEmoji}>{template.emoji}</Text>
                <Text style={styles.templateName}>{template.name}</Text>
                <Text style={styles.templateDescription}>{template.description}</Text>
                <Text style={styles.templateBudget}>
                  {formatCurrency(template.suggestedBudget)} VND
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Group Cover Selection */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Biểu tượng nhóm</Text>
          <View style={styles.emojiGrid}>
            {coverEmojiOptions.map(emoji => (
              <TouchableOpacity
                key={emoji}
                style={[
                  styles.emojiOption,
                  selectedCoverEmoji === emoji && styles.selectedEmojiOption,
                ]}
                onPress={() => setSelectedCoverEmoji(emoji)}
              >
                <Text style={styles.emojiText}>{emoji}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Group Name */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Tên nhóm *</Text>
          <TextInput
            style={styles.input}
            placeholder="VD: Du lịch Đà Lạt, Nhà trọ, Team Building..."
            placeholderTextColor="rgba(255, 255, 255, 0.5)"
            value={groupName}
            onChangeText={setGroupName}
          />
        </View>

        {/* Group Description */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Mô tả nhóm</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Mô tả ngắn về nhóm này..."
            placeholderTextColor="rgba(255, 255, 255, 0.5)"
            value={groupDescription}
            onChangeText={setGroupDescription}
            multiline
            numberOfLines={3}
          />
        </View>

        {/* Total Budget */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Tổng ngân sách *</Text>
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
          <Text style={styles.inputHint}>Tổng số tiền dự kiến cho nhóm này</Text>
        </View>

        {/* Split Method */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Cách chia chi phí</Text>
          <View style={styles.splitMethodContainer}>
            <TouchableOpacity
              style={[styles.splitMethodCard, splitMethod === 'equal' && styles.activeSplitMethod]}
              onPress={() => setSplitMethod('equal')}
            >
              <View style={styles.splitMethodIcon}>
                <Ionicons
                  name="people"
                  size={20}
                  color={splitMethod === 'equal' ? '#FFFFFF' : Colors.primary[500]}
                />
              </View>
              <Text
                style={[
                  styles.splitMethodTitle,
                  splitMethod === 'equal' && styles.activeSplitMethodText,
                ]}
              >
                Chia đều
              </Text>
              <Text
                style={[
                  styles.splitMethodSubtitle,
                  splitMethod === 'equal' && styles.activeSplitMethodText,
                ]}
              >
                Mọi người trả như nhau
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.splitMethodCard,
                splitMethod === 'percentage' && styles.activeSplitMethod,
              ]}
              onPress={() => setSplitMethod('percentage')}
            >
              <View style={styles.splitMethodIcon}>
                <Ionicons
                  name="pie-chart"
                  size={20}
                  color={splitMethod === 'percentage' ? '#FFFFFF' : Colors.primary[500]}
                />
              </View>
              <Text
                style={[
                  styles.splitMethodTitle,
                  splitMethod === 'percentage' && styles.activeSplitMethodText,
                ]}
              >
                Theo tỷ lệ
              </Text>
              <Text
                style={[
                  styles.splitMethodSubtitle,
                  splitMethod === 'percentage' && styles.activeSplitMethodText,
                ]}
              >
                Chia theo phần trăm
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.splitMethodCard, splitMethod === 'custom' && styles.activeSplitMethod]}
              onPress={() => setSplitMethod('custom')}
            >
              <View style={styles.splitMethodIcon}>
                <Ionicons
                  name="settings"
                  size={20}
                  color={splitMethod === 'custom' ? '#FFFFFF' : Colors.primary[500]}
                />
              </View>
              <Text
                style={[
                  styles.splitMethodTitle,
                  splitMethod === 'custom' && styles.activeSplitMethodText,
                ]}
              >
                Tùy chỉnh
              </Text>
              <Text
                style={[
                  styles.splitMethodSubtitle,
                  splitMethod === 'custom' && styles.activeSplitMethodText,
                ]}
              >
                Tự định số tiền
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Categories */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Danh mục chi tiêu *</Text>
          <Text style={styles.sectionHint}>Chọn các loại chi phí mà nhóm sẽ có</Text>
          <View style={styles.categoryGrid}>
            {categories.map(category => (
              <TouchableOpacity
                key={category.id}
                style={[
                  styles.categoryItem,
                  selectedCategories.includes(category.id) && styles.selectedCategoryItem,
                ]}
                onPress={() => toggleCategory(category.id)}
              >
                <Text style={styles.categoryIcon}>{category.icon}</Text>
                <Text
                  style={[
                    styles.categoryText,
                    selectedCategories.includes(category.id) && styles.selectedCategoryText,
                  ]}
                >
                  {category.name}
                </Text>
                {selectedCategories.includes(category.id) && (
                  <View style={styles.selectedIndicator}>
                    <Ionicons name="checkmark" size={14} color="#FFFFFF" />
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Advanced Splitwise-inspired Features */}
        <View style={styles.section}>
          <TouchableOpacity
            style={styles.advancedToggle}
            onPress={() => setShowAdvancedSettings(!showAdvancedSettings)}
          >
            <Text style={styles.sectionLabel}>Cài đặt nâng cao</Text>
            <Ionicons
              name={showAdvancedSettings ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={Colors.primary[500]}
            />
          </TouchableOpacity>

          {showAdvancedSettings && (
            <View style={styles.advancedSettings}>
              {/* Debt Simplification */}
              <View style={styles.settingItem}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingTitle}>Tối giản nợ thông minh</Text>
                  <Text style={styles.settingDescription}>
                    Giảm số lượng giao dịch thanh toán cần thiết
                  </Text>
                </View>
                <Switch
                  value={debtSimplification}
                  onValueChange={setDebtSimplification}
                  trackColor={{ false: '#767577', true: Colors.primary[500] }}
                  thumbColor={debtSimplification ? '#FFFFFF' : '#f4f3f4'}
                />
              </View>

              {/* Auto Reminders */}
              <View style={styles.settingItem}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingTitle}>Nhắc nhở tự động</Text>
                  <Text style={styles.settingDescription}>
                    Gửi thông báo thanh toán cho các thành viên
                  </Text>
                </View>
                <Switch
                  value={autoReminders}
                  onValueChange={setAutoReminders}
                  trackColor={{ false: '#767577', true: Colors.primary[500] }}
                  thumbColor={autoReminders ? '#FFFFFF' : '#f4f3f4'}
                />
              </View>

              {/* Receipt Scanning */}
              <View style={styles.settingItem}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingTitle}>Quét hóa đơn AI</Text>
                  <Text style={styles.settingDescription}>
                    Tự động nhận diện và phân chia chi tiêu
                  </Text>
                </View>
                <Switch
                  value={receiptScanning}
                  onValueChange={setReceiptScanning}
                  trackColor={{ false: '#767577', true: Colors.primary[500] }}
                  thumbColor={receiptScanning ? '#FFFFFF' : '#f4f3f4'}
                />
              </View>

              {/* Budget Alerts */}
              <View style={styles.settingItem}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingTitle}>Cảnh báo ngân sách</Text>
                  <Text style={styles.settingDescription}>
                    Thông báo khi vượt quá 80% ngân sách
                  </Text>
                </View>
                <Switch
                  value={budgetAlerts}
                  onValueChange={setBudgetAlerts}
                  trackColor={{ false: '#767577', true: Colors.primary[500] }}
                  thumbColor={budgetAlerts ? '#FFFFFF' : '#f4f3f4'}
                />
              </View>

              {/* Expense Approval */}
              <View style={styles.settingItem}>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingTitle}>Phê duyệt chi tiêu</Text>
                  <Text style={styles.settingDescription}>Admin phê duyệt trước khi chia tách</Text>
                </View>
                <Switch
                  value={expenseApproval}
                  onValueChange={setExpenseApproval}
                  trackColor={{ false: '#767577', true: Colors.primary[500] }}
                  thumbColor={expenseApproval ? '#FFFFFF' : '#f4f3f4'}
                />
              </View>

              {/* Member Roles */}
              <View style={styles.settingSection}>
                <Text style={styles.settingSubtitle}>Phân quyền thành viên</Text>
                <View style={styles.roleOptions}>
                  <TouchableOpacity
                    style={[
                      styles.roleOption,
                      memberRoles === 'democratic' && styles.activeRoleOption,
                    ]}
                    onPress={() => setMemberRoles('democratic')}
                  >
                    <Ionicons
                      name="people"
                      size={16}
                      color={memberRoles === 'democratic' ? '#FFFFFF' : Colors.primary[500]}
                    />
                    <Text
                      style={[
                        styles.roleOptionText,
                        memberRoles === 'democratic' && styles.activeRoleOptionText,
                      ]}
                    >
                      Dân chủ
                    </Text>
                    <Text
                      style={[
                        styles.roleOptionDesc,
                        memberRoles === 'democratic' && styles.activeRoleOptionText,
                      ]}
                    >
                      Mọi người đều có quyền như nhau
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[
                      styles.roleOption,
                      memberRoles === 'admin_controlled' && styles.activeRoleOption,
                    ]}
                    onPress={() => setMemberRoles('admin_controlled')}
                  >
                    <Ionicons
                      name="person"
                      size={16}
                      color={memberRoles === 'admin_controlled' ? '#FFFFFF' : Colors.primary[500]}
                    />
                    <Text
                      style={[
                        styles.roleOptionText,
                        memberRoles === 'admin_controlled' && styles.activeRoleOptionText,
                      ]}
                    >
                      Quản trị
                    </Text>
                    <Text
                      style={[
                        styles.roleOptionDesc,
                        memberRoles === 'admin_controlled' && styles.activeRoleOptionText,
                      ]}
                    >
                      Admin kiểm soát mọi hoạt động
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>

              {/* Group Duration */}
              <View style={styles.settingSection}>
                <Text style={styles.settingSubtitle}>Thời hạn nhóm</Text>
                <View style={styles.durationOptions}>
                  {[
                    { id: 'temporary', name: 'Tạm thời', desc: 'Vài ngày đến vài tuần' },
                    { id: 'permanent', name: 'Dài hạn', desc: 'Không giới hạn thời gian' },
                    { id: 'event_based', name: 'Theo sự kiện', desc: 'Kết thúc sau sự kiện' },
                  ].map(option => (
                    <TouchableOpacity
                      key={option.id}
                      style={[
                        styles.durationOption,
                        groupDuration === option.id && styles.activeDurationOption,
                      ]}
                      onPress={() => setGroupDuration(option.id as any)}
                    >
                      <Text
                        style={[
                          styles.durationOptionText,
                          groupDuration === option.id && styles.activeDurationOptionText,
                        ]}
                      >
                        {option.name}
                      </Text>
                      <Text
                        style={[
                          styles.durationOptionDesc,
                          groupDuration === option.id && styles.activeDurationOptionText,
                        ]}
                      >
                        {option.desc}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            </View>
          )}
        </View>

        {/* Privacy & Rules Summary */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Tóm tắt cài đặt</Text>
          <View style={styles.ruleCard}>
            <View style={styles.ruleItem}>
              <Ionicons name="shield-checkmark" size={20} color={Colors.primary[500]} />
              <Text style={styles.ruleText}>Chỉ thành viên mới xem được chi tiêu</Text>
            </View>
            <View style={styles.ruleItem}>
              <Ionicons
                name={memberRoles === 'democratic' ? 'people' : 'person'}
                size={20}
                color={Colors.primary[500]}
              />
              <Text style={styles.ruleText}>
                {memberRoles === 'democratic'
                  ? 'Mọi người đều có thể thêm chi tiêu'
                  : 'Chỉ admin mới thêm chi tiêu'}
              </Text>
            </View>
            <View style={styles.ruleItem}>
              <Ionicons
                name={debtSimplification ? 'git-compare' : 'swap-horizontal'}
                size={20}
                color={Colors.primary[500]}
              />
              <Text style={styles.ruleText}>
                {debtSimplification ? 'Tối giản nợ thông minh được bật' : 'Thanh toán trực tiếp'}
              </Text>
            </View>
            {receiptScanning && (
              <View style={styles.ruleItem}>
                <Ionicons name="camera" size={20} color={Colors.primary[500]} />
                <Text style={styles.ruleText}>Quét hóa đơn AI được kích hoạt</Text>
              </View>
            )}
          </View>
        </View>

        {/* Create Button */}
        <View style={styles.createButtonContainer}>
          <TouchableOpacity style={styles.createButton} onPress={handleCreateGroup}>
            <LinearGradient
              colors={[Colors.primary[500], '#2E8B57']}
              style={styles.createButtonGradient}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
            >
              <Ionicons name="add" size={20} color="#FFFFFF" />
              <Text style={styles.createButtonText}>Tạo nhóm</Text>
            </LinearGradient>
          </TouchableOpacity>
        </View>

        <View style={styles.bottomSpacing} />
      </ScrollView>
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
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  inputHint: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.6)',
    marginTop: 6,
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
  emojiGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  emojiOption: {
    width: 56,
    height: 56,
    borderRadius: 12,
    backgroundColor: '#2A4A5A',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedEmojiOption: {
    borderColor: Colors.primary[500],
    backgroundColor: Colors.primary[500],
  },
  emojiText: {
    fontSize: 24,
  },
  splitMethodContainer: {
    gap: 12,
  },
  splitMethodCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    borderWidth: 2,
    borderColor: 'transparent',
    flexDirection: 'row',
    alignItems: 'center',
  },
  activeSplitMethod: {
    borderColor: Colors.primary[500],
    backgroundColor: Colors.primary[500],
  },
  splitMethodIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(61, 161, 61, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  splitMethodTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
    flex: 1,
  },
  splitMethodSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  activeSplitMethodText: {
    color: '#FFFFFF',
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  categoryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2A4A5A',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    position: 'relative',
  },
  selectedCategoryItem: {
    backgroundColor: Colors.primary[500],
    borderColor: Colors.primary[500],
  },
  categoryIcon: {
    fontSize: 16,
    marginRight: 6,
  },
  categoryText: {
    fontSize: 14,
    color: '#FFFFFF',
    marginRight: 4,
  },
  selectedCategoryText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  selectedIndicator: {
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  ruleCard: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
  },
  ruleItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  ruleText: {
    fontSize: 14,
    color: '#FFFFFF',
    marginLeft: 12,
    flex: 1,
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
  // Vietnamese template styles
  templatesScroll: {
    marginHorizontal: -20,
    paddingHorizontal: 20,
  },
  templateCard: {
    width: 140,
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 12,
    marginRight: 12,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  selectedTemplateCard: {
    borderColor: Colors.primary[500],
    backgroundColor: 'rgba(61, 161, 61, 0.15)',
  },
  templateEmoji: {
    fontSize: 24,
    marginBottom: 8,
  },
  templateName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 4,
    textAlign: 'center',
  },
  templateDescription: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'center',
    marginBottom: 6,
    lineHeight: 14,
  },
  templateBudget: {
    fontSize: 10,
    color: Colors.primary[500],
    fontWeight: '600',
  },
  // Advanced Settings Styles
  advancedToggle: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  advancedSettings: {
    backgroundColor: '#2A4A5A',
    borderRadius: 12,
    padding: 16,
    gap: 16,
  },
  settingItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
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
    lineHeight: 16,
  },
  settingSection: {
    paddingTop: 8,
  },
  settingSubtitle: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 12,
  },
  roleOptions: {
    gap: 8,
  },
  roleOption: {
    backgroundColor: '#1A2E3A',
    borderRadius: 8,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  activeRoleOption: {
    backgroundColor: Colors.primary[500],
    borderColor: Colors.primary[500],
  },
  roleOptionText: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 2,
  },
  activeRoleOptionText: {
    color: '#FFFFFF',
  },
  roleOptionDesc: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  durationOptions: {
    gap: 8,
  },
  durationOption: {
    backgroundColor: '#1A2E3A',
    borderRadius: 8,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  activeDurationOption: {
    backgroundColor: Colors.primary[500],
    borderColor: Colors.primary[500],
  },
  durationOptionText: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.primary[500],
    marginBottom: 2,
  },
  activeDurationOptionText: {
    color: '#FFFFFF',
  },
  durationOptionDesc: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
});

export default CreateGroupScreen;
