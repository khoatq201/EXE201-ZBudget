import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const ResultScreen({
    Key? key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _crossController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _crossAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Scale animation for the circle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Check mark animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Cross mark animation
    _crossController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _crossAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _crossController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() {
    _scaleController.forward();

    if (widget.isSuccess) {
      _checkController.forward();
    } else {
      _crossController.forward();
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _crossController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isSuccess
          ? const Color(0xFFE8F5E8)
          : Colors.red[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: widget.isSuccess
                            ? const Color(0xFF3DA13D)
                            : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (widget.isSuccess
                                        ? const Color(0xFF3DA13D)
                                        : Colors.red)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: widget.isSuccess
                          ? AnimatedBuilder(
                              animation: _checkAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: CheckmarkPainter(
                                    _checkAnimation.value,
                                  ),
                                  size: const Size(120, 120),
                                );
                              },
                            )
                          : AnimatedBuilder(
                              animation: _crossAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: CrossPainter(_crossAnimation.value),
                                  size: const Size(120, 120),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Animated Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.isSuccess
                        ? const Color(0xFF2F6A2F)
                        : Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Animated Message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Animated Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isSuccess
                          ? const Color(0xFF3DA13D)
                          : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      widget.buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for checkmark
class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Define checkmark points
    final startPoint = Offset(size.width * 0.3, size.height * 0.5);
    final middlePoint = Offset(size.width * 0.45, size.height * 0.65);
    final endPoint = Offset(size.width * 0.7, size.height * 0.35);

    if (progress < 0.5) {
      // First half: draw line from start to middle
      final firstProgress = progress * 2;
      final currentPoint = Offset.lerp(startPoint, middlePoint, firstProgress)!;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Second half: draw full first line and part of second line
      final secondProgress = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(middlePoint, endPoint, secondProgress)!;

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(middlePoint.dx, middlePoint.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Custom painter for cross mark
class CrossPainter extends CustomPainter {
  final double progress;

  CrossPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.2;

    if (progress < 0.5) {
      // First line
      final firstProgress = progress * 2;
      final start1 = Offset(center.dx - radius, center.dy - radius);
      final end1 = Offset(center.dx + radius, center.dy + radius);
      final current1 = Offset.lerp(start1, end1, firstProgress)!;

      canvas.drawLine(start1, current1, paint);
    } else {
      // Second line
      final secondProgress = (progress - 0.5) * 2;
      final start1 = Offset(center.dx - radius, center.dy - radius);
      final end1 = Offset(center.dx + radius, center.dy + radius);
      final start2 = Offset(center.dx + radius, center.dy - radius);
      final end2 = Offset(center.dx - radius, center.dy + radius);
      final current2 = Offset.lerp(start2, end2, secondProgress)!;

      // Draw complete first line
      canvas.drawLine(start1, end1, paint);
      // Draw partial second line
      canvas.drawLine(start2, current2, paint);
    }
  }

  @override
  bool shouldRepaint(CrossPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
