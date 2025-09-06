import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/group_service.dart';
import '../../models/group_models.dart';
import '../../constants/colors.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String selectedEmoji = '🎯';
  String? selectedTemplate;
  SplitMethod splitMethod = SplitMethod.equal;
  List<String> selectedCategories = ['food', 'transport'];
  bool debtSimplification = true;
  bool autoReminders = true;
  bool receiptScanning = true;
  bool expenseApproval = false;

  final List<String> emojiOptions = [
    '🎯', '🏔️', '🏖️', '🎉', '🏠', '🚗', '✈️', '🍽️',
    '🎵', '📚', '💼', '🎮', '💒', '🎓', '🏪', '🍜',
  ];

  final List<Map<String, dynamic>> vietnameseTemplates = [
    {
      'id': 'travel',
      'name': 'Du lịch cuối tuần',
      'description': 'Đà Lạt, Vũng Tàu, Sapa...',
      'emoji': '🏔️',
      'suggestedBudget': 5000000,
      'categories': ['food', 'transport', 'accommodation', 'entertainment'],
      'nameTemplate': 'Du lịch [Địa điểm]',
      'descriptionTemplate': 'Chuyến đi cuối tuần với bạn bè',
    },
    {
      'id': 'wedding',
      'name': 'Đám cưới',
      'description': 'Mừng cưới, quà cưới, tiệc cưới',
      'emoji': '💒',
      'suggestedBudget': 10000000,
      'categories': ['other', 'food', 'transport'],
      'nameTemplate': 'Cưới [Tên cô dâu] & [Tên chú rể]',
      'descriptionTemplate': 'Mừng cưới bạn thân ❤️',
    },
    {
      'id': 'roommate',
      'name': 'Nhà trọ/Căn hộ',
      'description': 'Chi phí sinh hoạt hàng tháng',
      'emoji': '🏠',
      'suggestedBudget': 4000000,
      'categories': ['utilities', 'food', 'other'],
      'nameTemplate': 'Nhà trọ [Địa chỉ]',
      'descriptionTemplate': 'Chi phí sinh hoạt hàng tháng',
    },
    {
      'id': 'teambuilding',
      'name': 'Team Building',
      'description': 'Hoạt động công ty',
      'emoji': '🎯',
      'suggestedBudget': 8000000,
      'categories': ['food', 'transport', 'entertainment', 'accommodation'],
      'nameTemplate': 'Team Building [Công ty]',
      'descriptionTemplate': 'Hoạt động team building [Tháng/Năm]',
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {'id': 'food', 'name': 'Ăn uống', 'icon': '🍽️'},
    {'id': 'transport', 'name': 'Di chuyển', 'icon': '🚗'},
    {'id': 'accommodation', 'name': 'Lưu trú', 'icon': '🏨'},
    {'id': 'entertainment', 'name': 'Giải trí', 'icon': '🎢'},
    {'id': 'shopping', 'name': 'Mua sắm', 'icon': '🛍️'},
    {'id': 'utilities', 'name': 'Tiện ích', 'icon': '💡'},
    {'id': 'healthcare', 'name': 'Y tế', 'icon': '🏥'},
    {'id': 'education', 'name': 'Giáo dục', 'icon': '📚'},
    {'id': 'other', 'name': 'Khác', 'icon': '📝'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount);
  }

  void applyTemplate(Map<String, dynamic> template) {
    setState(() {
      selectedTemplate = template['id'];
      selectedEmoji = template['emoji'];
      _nameController.text = template['nameTemplate'];
      _descriptionController.text = template['descriptionTemplate'];
      _budgetController.text = template['suggestedBudget'].toString();
      selectedCategories = List<String>.from(template['categories']);
    });
  }

  void toggleCategory(String categoryId) {
    setState(() {
      if (selectedCategories.contains(categoryId)) {
        selectedCategories.remove(categoryId);
      } else {
        selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một danh mục chi tiêu')),
      );
      return;
    }

    try {
      final groupService = Provider.of<GroupService>(context, listen: false);
      
      // Tạo group mới
      final newGroup = Group(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        coverEmoji: selectedEmoji,
        totalBudget: double.parse(_budgetController.text.replaceAll(',', '')),
        spent: 0,
        createdAt: DateTime.now(),
        members: [
          GroupMember(
            id: groupService.currentUserId,
            name: groupService.currentUserName,
            avatar: '👤',
            balance: 0,
            role: GroupMemberRole.owner,
            joinedAt: DateTime.now(),
            totalPaid: 0,
            totalOwed: 0,
          ),
        ],
        transactions: [],
        inviteCode: groupService.generateInviteCode(),
        defaultSplitMethod: splitMethod,
        debtSimplification: debtSimplification,
        autoReminders: autoReminders,
        receiptScanning: receiptScanning,
        expenseApproval: expenseApproval,
      );

      await groupService.createGroup(newGroup);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhóm đã được tạo thành công!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo nhóm: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: createGroup,
            child: const Text(
              'Tạo',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTemplatesSection(),
              const SizedBox(height: 24),
              _buildEmojiSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildCategoriesSection(),
              const SizedBox(height: 24),
              _buildAdvancedSettings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mẫu nhóm phổ biến',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chọn mẫu có sẵn để tạo nhóm nhanh chóng',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vietnameseTemplates.length,
            itemBuilder: (context, index) {
              final template = vietnameseTemplates[index];
              final isSelected = selectedTemplate == template['id'];
              
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => applyTemplate(template),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary100 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary500 : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['emoji'],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          template['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template['description'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biểu tượng nhóm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojiOptions.map((emoji) {
            final isSelected = selectedEmoji == emoji;
            return GestureDetector(
              onTap: () => setState(() => selectedEmoji = emoji),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary100 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cơ bản',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tên nhóm',
            hintText: 'Nhập tên nhóm...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên nhóm';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            hintText: 'Mô tả về nhóm...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _budgetController,
          decoration: const InputDecoration(
            labelText: 'Tổng ngân sách (VND)',
            hintText: 'Nhập số tiền...',
            border: OutlineInputBorder(),
            prefixText: '₫ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập ngân sách';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục chi tiêu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = selectedCategories.contains(category['id']);
            return GestureDetector(
              onTap: () => toggleCategory(category['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary500 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt nâng cao',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildSplitMethodSection(),
        const SizedBox(height: 16),
        _buildSettingRow(
          'Đơn giản hóa nợ',
          'Tự động tính toán cách thanh toán tối ưu',
          debtSimplification,
          (value) => setState(() => debtSimplification = value),
        ),
        _buildSettingRow(
          'Nhắc nhở tự động',
          'Gửi thông báo nhắc nhở thanh toán',
          autoReminders,
          (value) => setState(() => autoReminders = value),
        ),
        _buildSettingRow(
          'Quét hóa đơn',
          'Cho phép quét hóa đơn để thêm chi tiêu',
          receiptScanning,
          (value) => setState(() => receiptScanning = value),
        ),
        _buildSettingRow(
          'Phê duyệt chi tiêu',
          'Yêu cầu phê duyệt trước khi ghi nhận chi tiêu',
          expenseApproval,
          (value) => setState(() => expenseApproval = value),
        ),
      ],
    );
  }

  Widget _buildSplitMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức chia tiền',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...SplitMethod.values.map((method) {
          return RadioListTile<SplitMethod>(
            title: Text(_getSplitMethodName(method)),
            subtitle: Text(_getSplitMethodDescription(method)),
            value: method,
            groupValue: splitMethod,
            onChanged: (value) => setState(() => splitMethod = value!),
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildSettingRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary500,
          ),
        ],
      ),
    );
  }

  String _getSplitMethodName(SplitMethod method) {
    switch (method) {
      case SplitMethod.equal:
        return 'Chia đều';
      case SplitMethod.percentage:
        return 'Theo phần trăm';
      case SplitMethod.custom:
        return 'Tùy chỉnh';
    }
  }

  String _getSplitMethodDescription(SplitMethod method) {
    switch (method) {
      case SplitMethod.equal:
        return 'Chia đều cho tất cả thành viên';
      case SplitMethod.percentage:
        return 'Chia theo tỷ lệ phần trăm';
      case SplitMethod.custom:
        return 'Tự chọn số tiền cho từng người';
    }
  }
}
