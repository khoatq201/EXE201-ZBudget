import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/profile_service.dart';
import '../../../models/settings/user_profile.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedBirthday;
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
      _bioController.text = profile.bio ?? '';
      _selectedBirthday = profile.birthday;
      _selectedGender = profile.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.textInverse,
        title: const Text('Chỉnh sửa thông tin'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Lưu',
              style: AppTypography.button.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Họ và tên',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildBirthdayField(),
            const SizedBox(height: AppSpacing.lg),
            _buildGenderField(),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _bioController,
              label: 'Giới thiệu bản thân',
              icon: Icons.info,
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dark200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dark200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
      ),
    );
  }

  Widget _buildBirthdayField() {
    return InkWell(
      onTap: _selectBirthday,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dark200),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.backgroundSecondary,
        ),
        child: Row(
          children: [
            const Icon(Icons.cake, color: AppColors.primary500),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày sinh',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedBirthday != null
                        ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                        : 'Chọn ngày sinh',
                    style: AppTypography.body.copyWith(
                      color: _selectedBirthday != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dark200),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary500),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Giới tính',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: Gender.values.map((gender) {
              final isSelected = _selectedGender == gender;
              return FilterChip(
                label: Text(gender.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedGender = selected ? gender : null;
                  });
                },
                selectedColor: AppColors.primary100,
                checkmarkColor: AppColors.primary500,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _selectBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary500),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileService = Provider.of<ProfileService>(context, listen: false);

    try {
      await profileService.updatePersonalInfo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        birthday: _selectedBirthday,
        gender: _selectedGender,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
