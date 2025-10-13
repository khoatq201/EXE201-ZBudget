import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../services/backend_ocr_service.dart';
import 'receipt_scanner_widget.dart';

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

  Future<void> _startRealOCR() async {
    // Navigate to real OCR scanner
    Navigator.of(context).pop(); // Close modal first

    final result = await Navigator.of(context).push<ReceiptData>(
      MaterialPageRoute(
        builder: (context) => ReceiptScannerWidget(
          onReceiptScanned: (receiptData) {
            Navigator.of(context).pop(receiptData);
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );

    if (result != null) {
      // Convert ReceiptData to Map format expected by onReceiptScanned
      final receiptMap = {
        'merchant': result.storeName,
        'amount': result.amount,
        'items': result.items,
        'category': result.category,
        'confidence': (result.confidence * 100).round(),
        'description': result.description,
      };

      // Auto-fill form and close modal
      widget.onReceiptScanned(receiptMap);
      widget.onClose();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Process image with OCR FIRST, then close modal
        await _processImageFromFile(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi chọn ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _processImageFromFile(File imageFile) async {
    try {
      // Show loading state
      setState(() {
        _isProcessing = true;
        _currentStep = 'Đang xử lý ảnh...';
      });

      // Process with backend OCR
      final result = await BackendOCRService.processReceipt(imageFile.path);

      if (result.success && result.data != null) {
        // Convert ReceiptData to Map format
        final receiptMap = {
          'merchant': result.data!.storeName,
          'amount': result.data!.amount,
          'items': result.data!.items,
          'category': result.data!.category,
          'confidence': (result.confidence * 100).round(),
          'description': result.data!.description,
        };

        // Auto-fill form and close modal
        widget.onReceiptScanned(receiptMap);
        // Close modal after a short delay to avoid navigation conflicts
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            widget.onClose();
          }
        });
      } else {
        setState(() {
          _isProcessing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.error ?? 'Không thể nhận diện ảnh'}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xử lý ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                    'Chọn ảnh từ thư viện hoặc chụp ảnh mới',
                    style: AppTypography.body.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Action buttons
            if (!_isProcessing)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.accent500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent500.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Camera button
                    GestureDetector(
                      onTap: _startRealOCR,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary500.withValues(
                                alpha: 0.3,
                              ),
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
                    // Placeholder for symmetry
                    const SizedBox(width: 60),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
