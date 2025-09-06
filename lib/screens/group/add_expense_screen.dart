import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/group_service.dart';
import '../../models/group_models.dart';
import '../../constants/colors.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;
  
  const AddExpenseScreen({super.key, required this.group});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String selectedCategory = 'food';
  String selectedCategoryIcon = '🍽️';
  GroupMember? paidBy;
  SplitMethod splitMethod = SplitMethod.equal;
  List<String> selectedParticipants = [];
  Map<String, double> customAmounts = {};
  DateTime selectedDate = DateTime.now();
  
  final List<Map<String, dynamic>> expenseCategories = [
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
  void initState() {
    super.initState();
    paidBy = widget.group.members.first;
    selectedParticipants = widget.group.members.map((m) => m.id).toList();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  void _selectCategory(Map<String, dynamic> category) {
    setState(() {
      selectedCategory = category['id'];
      selectedCategoryIcon = category['icon'];
    });
  }

  void _toggleParticipant(String memberId) {
    setState(() {
      if (selectedParticipants.contains(memberId)) {
        selectedParticipants.remove(memberId);
        customAmounts.remove(memberId);
      } else {
        selectedParticipants.add(memberId);
      }
      _updateCustomAmounts();
    });
  }

  void _updateCustomAmounts() {
    if (splitMethod == SplitMethod.equal) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final perPerson = selectedParticipants.isNotEmpty 
          ? amount / selectedParticipants.length 
          : 0;
      
      customAmounts.clear();
      for (String memberId in selectedParticipants) {
        customAmounts[memberId] = perPerson.toDouble();
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một người tham gia')),
      );
      return;
    }

    if (paidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người trả tiền')),
      );
      return;
    }

    try {
      final groupService = Provider.of<GroupService>(context, listen: false);
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      // Tạo split details
      final splitDetails = <String, double>{};
      if (splitMethod == SplitMethod.equal) {
        final perPerson = amount / selectedParticipants.length;
        for (String memberId in selectedParticipants) {
          splitDetails[memberId] = perPerson;
        }
      } else {
        splitDetails.addAll(customAmounts);
      }

      // Tạo transaction mới
      final transaction = GroupTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        amount: amount,
        category: selectedCategory,
        categoryIcon: selectedCategoryIcon,
        paidBy: paidBy!.id,
        paidByName: paidBy!.name,
        paidByAvatar: paidBy!.avatar,
        splitDetails: splitDetails,
        participants: selectedParticipants,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        date: selectedDate,
        type: TransactionType.expense,
        splitMethod: splitMethod,
      );

      await groupService.addExpenseToGroup(widget.group.id, transaction);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chi tiêu đã được thêm thành công!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thêm chi tiêu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chi tiêu'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _addExpense,
            child: const Text(
              'Lưu',
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
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildPaidBySection(),
              const SizedBox(height: 24),
              _buildSplitSection(),
              const SizedBox(height: 24),
              _buildParticipantsSection(),
              if (splitMethod == SplitMethod.custom) ...[
                const SizedBox(height: 24),
                _buildCustomAmountsSection(),
              ],
              const SizedBox(height: 24),
              _buildDateSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiêu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            hintText: 'Nhập mô tả chi tiêu...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mô tả';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Số tiền (VND)',
            hintText: 'Nhập số tiền...',
            border: OutlineInputBorder(),
            prefixText: '₫ ',
            prefixIcon: Icon(Icons.payments),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => _updateCustomAmounts(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập số tiền';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Số tiền phải lớn hơn 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: expenseCategories.map((category) {
            final isSelected = selectedCategory == category['id'];
            return GestureDetector(
              onTap: () => _selectCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary500 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.primary500 : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon'],
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
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

  Widget _buildPaidBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Người trả tiền',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<GroupMember>(
            value: paidBy,
            isExpanded: true,
            underline: const SizedBox(),
            items: widget.group.members.map((member) {
              return DropdownMenuItem<GroupMember>(
                value: member,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary500,
                      child: Text(
                        member.avatar,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(member.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (member) => setState(() => paidBy = member),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức chia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...SplitMethod.values.map((method) {
          return RadioListTile<SplitMethod>(
            title: Text(_getSplitMethodName(method)),
            subtitle: Text(_getSplitMethodDescription(method)),
            value: method,
            groupValue: splitMethod,
            onChanged: (value) {
              setState(() {
                splitMethod = value!;
                _updateCustomAmounts();
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Người tham gia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...widget.group.members.map((member) {
          final isSelected = selectedParticipants.contains(member.id);
          return CheckboxListTile(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary500,
                  child: Text(
                    member.avatar,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Text(member.name),
              ],
            ),
            value: isSelected,
            onChanged: (value) => _toggleParticipant(member.id),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary500,
          );
        }),
      ],
    );
  }

  Widget _buildCustomAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số tiền cho từng người',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...selectedParticipants.map((memberId) {
          final member = widget.group.members.firstWhere((m) => m.id == memberId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary500,
                  child: Text(
                    member.avatar,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(member.name)),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: '₫ ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    initialValue: customAmounts[memberId]?.toStringAsFixed(0) ?? '0',
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      setState(() => customAmounts[memberId] = amount);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày chi tiêu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary500),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi chú (tùy chọn)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Thêm ghi chú...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
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
        return 'Chia đều cho tất cả người tham gia';
      case SplitMethod.percentage:
        return 'Chia theo tỷ lệ phần trăm';
      case SplitMethod.custom:
        return 'Tự chọn số tiền cho từng người';
    }
  }
}
