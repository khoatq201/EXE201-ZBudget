import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isResetSuccessful = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.resetPassword(
        widget.email,
        widget.otp,
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isResetSuccessful = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: context.colorScheme.primary,
            ),
          );

          // Auto redirect to login after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: context.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt lại mật khẩu',
          style: AppTypography.h4.copyWith(
            color: context.primaryTextColor,
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
                const SizedBox(height: AppSpacing.xl2),

                // Icon and illustration
                Container(
                  height: 120,
                  width: 120,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    _isResetSuccessful ? Icons.check_circle : Icons.lock_reset,
                    size: 60,
                    color: _isResetSuccessful
                        ? context.colorScheme.primary
                        : context.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Title and description
                Text(
                  _isResetSuccessful ? 'Thành công!' : 'Tạo mật khẩu mới',
                  style: AppTypography.h2.copyWith(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.itemSpacing),
                Text(
                  _isResetSuccessful
                      ? 'Mật khẩu của bạn đã được đặt lại thành công. Bạn sẽ được chuyển đến trang đăng nhập trong giây lát.'
                      : 'Mật khẩu mới của bạn phải khác với mật khẩu đã sử dụng trước đây.',
                  style: AppTypography.body.copyWith(
                    color: context.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl2),

                if (!_isResetSuccessful) ...[
                  // New Password input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    style: AppTypography.body.copyWith(
                      color: context.primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      labelStyle: AppTypography.body.copyWith(
                        color: context.secondaryTextColor,
                      ),
                      hintText: 'Nhập mật khẩu mới',
                      hintStyle: AppTypography.body.copyWith(
                        color: context.tertiaryTextColor,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: context.secondaryTextColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: context.secondaryTextColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: context.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.cardBackground),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.itemSpacing,
                        vertical: AppSpacing.itemSpacing,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới';
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
                    obscureText: !_confirmPasswordVisible,
                    style: AppTypography.body.copyWith(
                      color: context.primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      labelStyle: AppTypography.body.copyWith(
                        color: context.secondaryTextColor,
                      ),
                      hintText: 'Nhập lại mật khẩu mới',
                      hintStyle: AppTypography.body.copyWith(
                        color: context.tertiaryTextColor,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: context.secondaryTextColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: context.secondaryTextColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: context.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.cardBackground),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.errorColor,
                          width: 2,
                        ),
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
                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Reset password button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.itemSpacing,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Đặt lại mật khẩu',
                            style: AppTypography.h5.copyWith(
                              color: context.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ] else ...[
                  // Success message
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sectionSpacing),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colorScheme.primary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        Text(
                          'Mật khẩu đã được đặt lại!',
                          style: AppTypography.h4.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Bạn có thể đăng nhập với mật khẩu mới ngay bây giờ.',
                          style: AppTypography.body.copyWith(
                            color: context.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // Go to login button
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.itemSpacing,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Đến trang đăng nhập',
                      style: AppTypography.h5.copyWith(
                        color: context.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl2),

                // Additional help
                if (!_isResetSuccessful) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Quay lại',
                      style: AppTypography.body.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
