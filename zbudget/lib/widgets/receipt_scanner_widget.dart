import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/ai_ocr_service.dart';
import '../services/receipt_parser_service.dart';
import '../utils/theme_extensions.dart';

/// Widget for scanning receipts with camera or gallery
class ReceiptScannerWidget extends StatefulWidget {
  final Function(ReceiptData) onReceiptScanned;
  final VoidCallback? onCancel;

  const ReceiptScannerWidget({
    super.key,
    required this.onReceiptScanned,
    this.onCancel,
  });

  @override
  State<ReceiptScannerWidget> createState() => _ReceiptScannerWidgetState();
}

class _ReceiptScannerWidgetState extends State<ReceiptScannerWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _checkPermissions() async {
    // Check if we have necessary permissions
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;

    // For gallery access, we need either storage or photos permission
    return storageStatus.isGranted || photosStatus.isGranted;
  }

  Future<void> _requestPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();

      // Request storage/photos permission based on Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      PermissionStatus storageStatus;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+)
        storageStatus = await Permission.photos.request();
      } else {
        // Android 12 and below
        storageStatus = await Permission.storage.request();
      }

      if (cameraStatus.isGranted && storageStatus.isGranted) {
        setState(() {
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cấp quyền thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Vui lòng cấp quyền để sử dụng tính năng quét hóa đơn';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi cấp quyền: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: const Text(
          'Quét hóa đơn',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isProcessing ? _buildProcessingView() : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Camera preview placeholder
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Chụp ảnh hóa đơn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Đặt hóa đơn trong khung và chụp ảnh rõ nét',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Corner guides
                  _buildCornerGuides(),
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Only show error if it's not a permission error
              if (_errorMessage != null &&
                  !_errorMessage!.contains('quyền truy cập')) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Mẹo để quét tốt hơn:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Đảm bảo hóa đơn rõ nét, không bị nhòe\n'
                      '• Tránh ánh sáng chói và bóng đổ\n'
                      '• Giữ điện thoại ổn định khi chụp\n'
                      '• Chụp toàn bộ hóa đơn trong khung',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang xử lý hóa đơn...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng chờ trong giây lát',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGuides() {
    return Stack(
      children: [
        // Top-left corner
        Positioned(top: 20, left: 20, child: _buildCornerGuide()),
        // Top-right corner
        Positioned(
          top: 20,
          right: 20,
          child: Transform.rotate(
            angle: 1.5708, // 90 degrees
            child: _buildCornerGuide(),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 20,
          left: 20,
          child: Transform.rotate(
            angle: -1.5708, // -90 degrees
            child: _buildCornerGuide(),
          ),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 20,
          right: 20,
          child: Transform.rotate(
            angle: 3.14159, // 180 degrees
            child: _buildCornerGuide(),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerGuide() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _takePicture() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    // Check permission first for gallery access
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      // Check permissions
      if (source == ImageSource.camera) {
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          if (cameraPermission.isPermanentlyDenied) {
            throw Exception(
              'Quyền truy cập camera bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt > Ứng dụng > ZBudget > Quyền',
            );
          }
          throw Exception('Cần quyền truy cập camera để chụp ảnh');
        }
      } else {
        // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
        Permission permission;
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ (API 33+)
          permission = Permission.photos;
        } else {
          // Android 12 and below
          permission = Permission.storage;
        }

        final photosPermission = await permission.request();
        if (!photosPermission.isGranted) {
          if (photosPermission.isPermanentlyDenied) {
            throw Exception(
              'Quyền truy cập thư viện ảnh bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt > Ứng dụng > ZBudget > Quyền',
            );
          }
          throw Exception('Cần quyền truy cập thư viện ảnh');
        }
      }

      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Process image with OCR
      await _processImage(image.path);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quyền truy cập thư viện ảnh'),
          content: const Text(
            'Ứng dụng cần quyền truy cập thư viện ảnh để chọn hóa đơn từ thiết bị của bạn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Cài đặt'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Use AI OCR only (no local OCR fallback)
      final aiResult = await AIOCRService.smartExtract(imagePath);
      print(
        '🤖 AI OCR Result: ${aiResult.provider} - Confidence: ${(aiResult.confidence * 100).toStringAsFixed(1)}%',
      );

      if (aiResult.text.isEmpty) {
        throw Exception(
          'Không thể nhận diện text từ ảnh. Hãy thử chụp lại với góc tốt hơn.',
        );
      }

      print('📝 OCR Text: ${aiResult.text.substring(0, 100)}...');
      print(
        '🎯 Confidence: ${(aiResult.confidence * 100).toStringAsFixed(1)}%',
      );

      // Parse receipt data
      final receiptData = ReceiptParserService.parseReceipt(aiResult.text);

      if (!receiptData.hasValidAmount) {
        throw Exception(
          'Không thể nhận diện số tiền từ hóa đơn. Hãy đảm bảo hóa đơn rõ ràng và không bị che khuất.',
        );
      }

      print('💰 Parsed Amount: ${receiptData.amount}');
      print('🏪 Store: ${receiptData.storeName}');
      print('📝 Description: ${receiptData.description}');

      // Return result
      if (mounted) {
        widget.onReceiptScanned(receiptData);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
