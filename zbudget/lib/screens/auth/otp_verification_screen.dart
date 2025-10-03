import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../services/auth_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;

  const OTPVerificationScreen({
    Key? key,
    required this.email,
    required this.fullName,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String _errorMessage = '';
  late Timer _timer;
  int _remainingTime = 600; // 10 minutes in seconds
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onOTPChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Clear error when user starts typing
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }

    // Auto-verify when all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyOTP();
    }
  }

  void _onKeyPressed(RawKeyEvent event, int index) {
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_isLoading) return;

    final otp = _controllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ 6 chữ số';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.verifyOTP(email: widget.email, otp: otp);

      if (mounted && result['success'] == true) {
        // Success - user is now created and authenticated in AuthService
        // No need to manually update AppProvider, AuthService already handles authentication state

        context.go(
          '/result',
          extra: {
            'isSuccess': true,
            'title': 'Đăng ký thành công!',
            'message': 'Tài khoản của bạn đã được tạo và kích hoạt thành công.',
            'buttonText': 'Bắt đầu sử dụng ZBudget',
            'nextRoute': '/home',
          },
        );
      } else {
        // Error from server
        setState(() {
          _errorMessage = result['message'] ?? 'Mã OTP không chính xác';
          _clearOTP();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại sau.';
        _clearOTP();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    // TODO: Implement resend OTP functionality
    setState(() {
      _remainingTime = 600; // Reset timer to 10 minutes
    });
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mã OTP mới đã được gửi đến email của bạn'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/signup'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3DA13D), Color(0xFF42D8C5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Xác thực tài khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Chúng tôi đã gửi mã xác thực 6 chữ số đến\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3DA13D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPressed(event, index),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage.isNotEmpty
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3DA13D),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOTPChanged(value, index),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mã sẽ hết hạn sau $_formattedTime',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Verify Button
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3DA13D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Xác thực',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Resend OTP
              TextButton(
                onPressed: _remainingTime == 0 ? _resendOTP : null,
                child: Text(
                  _remainingTime == 0
                      ? 'Gửi lại mã OTP'
                      : 'Gửi lại mã OTP sau $_formattedTime',
                  style: TextStyle(
                    color: _remainingTime == 0
                        ? const Color(0xFF3DA13D)
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
