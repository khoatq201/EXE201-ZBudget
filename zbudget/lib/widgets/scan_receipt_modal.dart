import 'package:flutter/material.dart';
import 'dart:math';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

class ScanReceiptModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onReceiptScanned;
  final VoidCallback onClose;

  const ScanReceiptModal({
    super.key,
    required this.onReceiptScanned,
    required this.onClose,
  });

  @override
  State<ScanReceiptModal> createState() => _ScanReceiptModalState();
}

class _ScanReceiptModalState extends State<ScanReceiptModal>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  double _scanProgress = 0.0;
  String _currentStep = '';

  late AnimationController _scanController;
  late AnimationController _progressController;
  late Animation<double> _scanAnimation;
  late Animation<Color?> _colorAnimation;

  // Vietnamese receipt data for simulation
  final List<Map<String, dynamic>> vietnameseReceiptData = [
    {
      'merchant': 'Cơm tấm Sài Gòn',
      'amount': 45000,
      'items': ['Cơm tấm sướn nướng', 'Trà đá'],
      'category': 'food',
      'confidence': 95,
    },
    {
      'merchant': 'Circle K',
      'amount': 38500,
      'items': ['Nước suối', 'Bánh mì sandwich'],
      'category': 'food',
      'confidence': 92,
    },
    {
      'merchant': 'Grab (Xe ôm)',
      'amount': 28000,
      'items': ['Chuyến đi từ Quận 1 đến Quận 3'],
      'category': 'transport',
      'confidence': 98,
    },
    {
      'merchant': 'Highlands Coffee',
      'amount': 55000,
      'items': ['Cà phê sữa đá', 'Bánh ngọt'],
      'category': 'food',
      'confidence': 96,
    },
    {
      'merchant': 'Nhà thuốc Long Châu',
      'amount': 125000,
      'items': ['Thuốc cảm', 'Vitamin C'],
      'category': 'healthcare',
      'confidence': 91,
    },
  ];

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanController);

    _colorAnimation = ColorTween(
      begin: AppColors.primary500,
      end: AppColors.accent500,
    ).animate(_scanController);

    // Start pulse animation
    _scanController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String getCategoryName(String category) {
    switch (category) {
      case 'food':
        return 'Ăn uống';
      case 'transport':
        return 'Di chuyển';
      case 'healthcare':
        return 'Y tế';
      case 'shopping':
        return 'Mua sắm';
      default:
        return 'Khác';
    }
  }

  Future<void> _simulateAdvancedScan() async {
    setState(() {
      _isProcessing = true;
      _scanProgress = 0.0;
      _currentStep = 'Đang chụp ảnh...';
    });

    final steps = [
      {'progress': 0.2, 'step': 'Đang phân tích ảnh...'},
      {'progress': 0.4, 'step': 'Nhận diện văn bản Tiếng Việt...'},
      {'progress': 0.6, 'step': 'Trích xuất thông tin hóa đơn...'},
      {'progress': 0.8, 'step': 'Phân loại chi tiêu tự động...'},
      {'progress': 1.0, 'step': 'Hoàn thành!'},
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      setState(() {
        _scanProgress = step['progress'] as double;
        _currentStep = step['step'] as String;
      });

      _progressController.animateTo(_scanProgress);
    }

    // Show results
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final randomReceipt =
        vietnameseReceiptData[Random().nextInt(vietnameseReceiptData.length)];

    setState(() {
      _isProcessing = false;
    });

    _showScanResult(randomReceipt);
  }

  void _showScanResult(Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quét thành công (${receipt['confidence']}% chính xác)',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('📍 Cửa hàng:', receipt['merchant']),
            _buildResultRow(
              '💰 Số tiền:',
              '${(receipt['amount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
            ),
            _buildResultRow('📦 Món:', (receipt['items'] as List).join(', ')),
            _buildResultRow(
              '📊 Danh mục:',
              getCategoryName(receipt['category']),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('🤖'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI đã tự động phân loại chi tiêu của bạn!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReceiptScanned(receipt);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Chỉnh sửa',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReceiptScanned(receipt);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã lưu chi tiêu từ hóa đơn!'),
                  backgroundColor: AppColors.success,
                ),
              );
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Lưu ngay',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Camera preview simulation
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[800]!, Colors.grey[900]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Preview',
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scan frame
            if (!_isProcessing)
              Center(
                child: AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 250,
                      height: 350,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _colorAnimation.value ?? AppColors.primary500,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          ...List.generate(4, (index) {
                            return Positioned(
                              top: index < 2 ? 0 : null,
                              bottom: index >= 2 ? 0 : null,
                              left: index % 2 == 0 ? 0 : null,
                              right: index % 2 == 1 ? 0 : null,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2
                                        ? BorderSide(
                                            color:
                                                _colorAnimation.value ??
                                                AppColors.primary500,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    bottom: index >= 2
                                        ? BorderSide(
                                            color:
                                                _colorAnimation.value ??
                                                AppColors.primary500,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    left: index % 2 == 0
                                        ? BorderSide(
                                            color:
                                                _colorAnimation.value ??
                                                AppColors.primary500,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                    right: index % 2 == 1
                                        ? BorderSide(
                                            color:
                                                _colorAnimation.value ??
                                                AppColors.primary500,
                                            width: 4,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Processing overlay
            if (_isProcessing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary500,
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _currentStep,
                        style: AppTypography.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 200,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _scanProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary500,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_scanProgress * 100).toInt()}%',
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Quét hóa đơn',
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Instructions
            if (!_isProcessing)
              Positioned(
                bottom: 120,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đặt hóa đơn vào khung hình và nhấn nút chụp',
                    style: AppTypography.body.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Capture button
            if (!_isProcessing)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _simulateAdvancedScan,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
