import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../constants/spacing.dart';
import '../../services/auth_service.dart';

class PasswordResetOTPScreen extends StatefulWidget {
  final String email;

  const PasswordResetOTPScreen({super.key, required this.email});

  @override
  State<PasswordResetOTPScreen> createState() => _PasswordResetOTPScreenState();
}

class _PasswordResetOTPScreenState extends State<PasswordResetOTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown <= 0) {
          setState(() {
            _canResend = true;
          });
          return false;
        }
        return true;
      }
      return false;
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOTPComplete => _otpCode.length == 6;

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_isOTPComplete) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.verifyPasswordResetOTP(
        widget.email,
        _otpCode,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to reset password screen
          context.go(
            '/reset-password',
            extra: {'email': widget.email, 'otp': _otpCode},
          );
        }
      } else {
        _clearOTP();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _clearOTP();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.forgotPassword(widget.email);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _startResendTimer();
        _clearOTP();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mã OTP mới đã được gửi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Xác thực OTP',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 40,
                  color: AppColors.primary500,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Nhập mã xác thực',
                style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Chúng tôi đã gửi mã 6 số đến\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      enabled: !_isLoading,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderSecondary,
                            width: 1.5,
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
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _onOTPChanged(value, index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Loading indicator
              if (_isLoading)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary500,
                  ),
                ),

              const Spacer(),

              // Resend section
              Column(
                children: [
                  Text(
                    'Không nhận được mã?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_canResend)
                    TextButton(
                      onPressed: _isLoading ? null : _resendOTP,
                      child: Text(
                        'Gửi lại mã',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Gửi lại sau $_resendCountdown giây',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
