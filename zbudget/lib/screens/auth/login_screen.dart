import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../utils/theme_extensions.dart';
import 'package:go_router/go_router.dart';
import '../debug/network_test_screen.dart';
import '../debug/google_signin_test_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rememberMeKey = GlobalKey(); // ✅ Add key for Remember Me
  final _googleSignInKey = GlobalKey(); // ✅ Add key for Google Sign-In button
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithGoogle();

      if (mounted) {
        if (result['success']) {

          // Check if user needs to complete profile
          final user = result['user'] as Map<String, dynamic>?;
          final needsProfileCompletion =
              user?['needsProfileCompletion'] ?? false;

          if (needsProfileCompletion) {
            context.go('/complete-profile');
          } else {
            context.go('/home');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập Google thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đăng nhập Google thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Google thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      // ⚠️ CRITICAL: Check mounted BEFORE any widget tree operations
      if (!mounted) return;

      if (result['success']) {
        context.go('/home');
        return;
      }

      // Only reach here if login FAILED
      final errorMessage = result['message'] ?? 'Đăng nhập thất bại';
      _showErrorMessage(errorMessage);
    } catch (error) {
      if (!mounted) return;
      _showErrorMessage('Lỗi kết nối. Vui lòng thử lại sau.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Safely show error message with mounted check
  void _showErrorMessage(String message) {
    if (!mounted) return;

    try {
      final backgroundColor = message.contains('khóa')
          ? Colors.orange
          : Theme.of(context).colorScheme.error;

      final duration = message.contains('khóa')
          ? const Duration(seconds: 5)
          : const Duration(seconds: 4);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    } catch (e) {
      // Silently fail if SnackBar cannot be shown
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Ensure layout adjusts for keyboard
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
              .onDrag, // ✅ Dismiss keyboard on scroll
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl4),

                // Logo and Title
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                Text(
                  'ZBudget',
                  style: AppTypography.h1.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.itemSpacing),
                Text(
                  'Đăng nhập để tiếp tục',
                  style: AppTypography.body.copyWith(
                    color: context.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl4),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập email của bạn',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.tertiaryTextColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
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

                const SizedBox(height: AppSpacing.itemSpacing),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.tertiaryTextColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
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

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember Me Checkbox
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          key: _rememberMeKey, // ✅ Use key for stability
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: context.colorScheme.primary,
                          checkColor: Colors.white,
                          tristate: false, // ✅ Explicitly disable tristate
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Text(
                            'Ghi nhớ đăng nhập',
                            style: AppTypography.body.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: AppTypography.body.copyWith(
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Đăng nhập',
                            style: AppTypography.button.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: context.tertiaryTextColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style: AppTypography.body.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.tertiaryTextColor)),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Google Sign-In Button
                SizedBox(
                  key: _googleSignInKey, // ✅ Use key for stability
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://developers.google.com/identity/images/g-logo.png',
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    label: Text(
                      _isLoading ? 'Đang xử lý...' : 'Đăng nhập với Google',
                      style: AppTypography.button.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.tertiaryTextColor,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: context.screenBackground,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: AppTypography.body.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Debug: Sign up button clicked
                        context.push('/signup');
                      },
                      child: Text(
                        'Đăng ký',
                        style: AppTypography.body.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Debug button - only in debug mode
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NetworkTestScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text(
                        'Network Debug',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const GoogleSignInTestScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_circle, size: 16),
                      label: const Text(
                        'Google Sign-In Test',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
