import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    debugPrint('🔥 _signUp method called!');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    if (_dateOfBirth == null) {
      debugPrint('❌ Date of birth not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ngày sinh'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      debugPrint('❌ Terms not accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản dịch vụ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    debugPrint('✅ Starting signup process...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get AuthService instance
      final authService = context.read<AuthService>();

      // Call register API
      final result = await authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? ''
            : _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Check if this is OTP flow or direct login
          if (result['data'] != null && result['data']['otpSent'] == true) {
            // OTP was sent, navigate to OTP verification screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'OTP đã được gửi đến email của bạn',
                ),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate to OTP verification screen with email
            context.go(
              '/verify-otp',
              extra: {
                'email': _emailController.text.trim().toLowerCase(),
                'fullName': _nameController.text.trim(),
                'fromRegistration': true,
              },
            );
          } else if (result['user'] != null) {
            // Direct login (old flow)
            final appProvider = context.read<AppProvider>();
            await appProvider.login(result['user'] as User);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Đăng ký thành công!'),
                backgroundColor: AppColors.success,
              ),
            );

            context.go('/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đăng ký thất bại'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đăng ký',
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.itemSpacing),

                // Logo and Title
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: AppColors.primary500,
                ),
                const SizedBox(height: AppSpacing.itemSpacing),
                Text(
                  'Tạo tài khoản mới',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Quản lý tài chính thông minh cùng ZBudget',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Name input
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập họ và tên của bạn',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (value.length < 2) {
                      return 'Tên phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Email input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập email của bạn',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Phone input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại (tùy chọn)',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập số điện thoại của bạn',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Basic phone validation if provided
                      if (value.length < 10 || value.length > 15) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      if (!RegExp(r'^[\d\+\-\s\(\)]+$').hasMatch(value)) {
                        return 'Số điện thoại chỉ được chứa số và ký tự +, -, (), khoảng trắng';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Date of Birth input
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth ?? DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now().subtract(
                        Duration(days: 365 * 13),
                      ), // At least 13 years old
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary500,
                              onPrimary: Colors.white,
                              surface: AppColors.backgroundSecondary,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && picked != _dateOfBirth) {
                      setState(() {
                        _dateOfBirth = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _dateOfBirth == null
                            ? AppColors.backgroundSecondary
                            : AppColors.primary500,
                        width: _dateOfBirth == null ? 1 : 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _dateOfBirth == null
                                ? 'Chọn ngày sinh'
                                : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                            style: AppTypography.body.copyWith(
                              color: _dateOfBirth == null
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _gender,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundSecondary,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Nam')),
                    DropdownMenuItem(value: 'female', child: Text('Nữ')),
                    DropdownMenuItem(value: 'other', child: Text('Khác')),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn giới tính';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Password input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập mật khẩu của bạn',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Confirm Password input
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    labelStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Nhập lại mật khẩu của bạn',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.backgroundSecondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.itemSpacing,
                      vertical: AppSpacing.itemSpacing,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Terms and conditions checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary500,
                      checkColor: Colors.white,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: 'Tôi đồng ý với '),
                                TextSpan(
                                  text: 'Điều khoản dịch vụ',
                                  style: TextStyle(
                                    color: AppColors.primary500,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' và '),
                                TextSpan(
                                  text: 'Chính sách bảo mật',
                                  style: TextStyle(
                                    color: AppColors.primary500,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' của ZBudget'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Sign up button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTypography.button.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text('Đăng ký'),
                  ),
                ),
                const SizedBox(height: AppSpacing.itemSpacing),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.go('/login');
                      },
                      child: Text(
                        'Đăng nhập',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
