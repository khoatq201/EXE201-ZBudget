import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_budget_service.dart';
import '../../services/auth_service.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';

class MemberInput {
  final TextEditingController nameController;
  final TextEditingController percentageController;
  String? userId; // For known users
  String? email; // For display
  String? avatar; // For display
  bool isCurrentUser;

  MemberInput({
    String? name,
    double? percentage,
    this.userId,
    this.email,
    this.avatar,
    this.isCurrentUser = false,
  })  : nameController = TextEditingController(text: name),
        percentageController = TextEditingController(
          text: percentage != null ? percentage.toString() : '',
        );

  void dispose() {
    nameController.dispose();
    percentageController.dispose();
  }

  double get percentage =>
      double.tryParse(percentageController.text) ?? 0.0;
}

class CreateGroupBudgetScreen extends StatefulWidget {
  const CreateGroupBudgetScreen({super.key});

  @override
  State<CreateGroupBudgetScreen> createState() =>
      _CreateGroupBudgetScreenState();
}

class _CreateGroupBudgetScreenState extends State<CreateGroupBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalBudgetController = TextEditingController();
  final _searchController = TextEditingController();

  List<MemberInput> _members = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _autoSplitByContribution = true;

  @override
  void initState() {
    super.initState();
    _initializeMembers();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeMembers() {
    // Add current user as first member
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    _members.add(MemberInput(
      name: currentUser?.name ?? 'Bạn',
      percentage: 0,
      userId: currentUser?.id,
      email: currentUser?.email,
      isCurrentUser: true,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalBudgetController.dispose();
    _searchController.dispose();
    for (var member in _members) {
      member.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final results = await authService.searchUsers(query);

      // Filter out already added members
      final existingUserIds = _members
          .where((m) => m.userId != null)
          .map((m) => m.userId)
          .toSet();

      setState(() {
        _searchResults = results
            .where((user) => !existingUserIds.contains(user['id']))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _addUserAsMember(Map<String, dynamic> user) {
    setState(() {
      _members.add(MemberInput(
        name: user['name'],
        userId: user['id'],
        email: user['email'],
        avatar: user['avatar'],
        percentage: 0,
      ));
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(int index) {
    if (_members[index].isCurrentUser) return; // Can't remove current user
    setState(() {
      _members[index].dispose();
      _members.removeAt(index);
    });
  }

  double get _totalPercentage {
    return _members.fold(0.0, (sum, member) => sum + member.percentage);
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate total percentage if multiple members
    if (_members.length > 1 && _totalPercentage != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tổng phần trăm đóng góp phải bằng 100%'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare members data with all added users
      final membersData = _members.map((m) {
        return {
          'userId': m.userId,
          'name': m.nameController.text.trim(),
          'contributionPercentage': m.percentage,
        };
      }).toList();

      final service = Provider.of<GroupBudgetService>(context, listen: false);
      final result = await service.createGroupBudget(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalBudget: double.parse(_totalBudgetController.text.replaceAll(',', '')),
        members: membersData,
        autoSplitByContribution: _autoSplitByContribution,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo ngân sách thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/group-budgets');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        title: Text('Tạo ngân sách nhóm', style: AppTypography.h2),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildMembersSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSettingsSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildCreateButton(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin cơ bản', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ngân sách',
                hintText: 'VD: Du lịch Đà Lạt',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên ngân sách';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Mô tả chi tiết về ngân sách',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Total budget field
            TextFormField(
              controller: _totalBudgetController,
              decoration: const InputDecoration(
                labelText: 'Tổng ngân sách',
                hintText: '0',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VND',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tổng ngân sách';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Số tiền không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Thành viên', style: AppTypography.h3),
                ),
                Text(
                  'Tổng: ${_totalPercentage.toStringAsFixed(0)}%',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _totalPercentage == 100 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng theo tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),

            // Search results
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : null,
                        child: user['avatar'] == null
                            ? Text(user['name'][0].toUpperCase())
                            : null,
                      ),
                      title: Text(user['name']),
                      subtitle: Text(user['email']),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _addUserAsMember(user),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Members list
            ..._members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildMemberCard(member, index),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberInput member, int index) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (member.avatar != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(member.avatar!),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    child: Text(member.nameController.text.isNotEmpty
                        ? member.nameController.text[0].toUpperCase()
                        : '?'),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.nameController.text,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (member.email != null)
                        Text(
                          member.email!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      if (member.isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bạn',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!member.isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _removeMember(index),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Percentage input
            TextFormField(
              controller: member.percentageController,
              decoration: const InputDecoration(
                labelText: 'Phần trăm đóng góp',
                hintText: '0',
                suffixText: '%',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final percentage = double.tryParse(value ?? '');
                if (percentage == null || percentage < 0 || percentage > 100) {
                  return 'Phải từ 0-100%';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cài đặt', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              title: const Text('Tự động chia chi tiêu theo đóng góp'),
              subtitle: const Text(
                'Chi tiêu sẽ được chia tự động theo tỉ lệ đóng góp',
              ),
              value: _autoSplitByContribution,
              onChanged: (value) {
                setState(() => _autoSplitByContribution = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createBudget,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text('Tạo ngân sách', style: AppTypography.button),
    );
  }
}
