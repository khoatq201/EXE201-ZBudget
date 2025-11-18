import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../services/subscription_service.dart';

class PaymentQRScreen extends StatefulWidget {
  final String planType;

  const PaymentQRScreen({
    super.key,
    required this.planType,
  });

  @override
  State<PaymentQRScreen> createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen> {
  PaymentRequest? _paymentRequest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay payment creation until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createPayment();
    });
  }

  Future<void> _createPayment() async {
    if (!mounted) return;

    final paymentService = context.read<PaymentService>();

    final payment = await paymentService.createPayment(widget.planType);

    if (!mounted) return;

    if (payment != null) {
      setState(() {
        _paymentRequest = payment;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = paymentService.error ?? 'Lỗi khi tạo thanh toán';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã copy $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePaymentCompleted() async {
    // Refresh subscription status
    final subscriptionService = context.read<SubscriptionService>();
    await subscriptionService.getStatus();

    if (mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('Thanh toán đang chờ duyệt'),
          content: const Text(
            'Thanh toán của bạn đã được ghi nhận và đang chờ admin xác nhận. Bạn sẽ nhận được thông báo khi Premium được kích hoạt.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                context.pop(); // Back to premium screen
              },
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cancelPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán'),
        content: const Text('Bạn có chắc muốn hủy thanh toán này?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );

    if (confirmed == true && _paymentRequest != null && mounted) {
      final paymentService = context.read<PaymentService>();
      final success = await paymentService.cancelPayment(_paymentRequest!.paymentId);

      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tạo thanh toán...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _paymentRequest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Không thể tạo thanh toán',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Quét mã QR để thanh toán',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _paymentRequest!.qrCodeUrl,
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('❌ QR Image error: $error');
                            debugPrint('QR URL: ${_paymentRequest!.qrCodeUrl}');
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không thể tải QR code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Vui lòng chuyển khoản thủ công theo thông tin bên dưới',
                                    style: TextStyle(fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {}); // Retry
                                      },
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Thử tải lại QR'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bank Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin chuyển khoản',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Ngân hàng',
                      _paymentRequest!.bankAccount.bankName,
                      canCopy: false,
                    ),
                    _buildInfoRow(
                      'Số tài khoản',
                      _paymentRequest!.bankAccount.accountNumber,
                      canCopy: true,
                    ),
                    _buildInfoRow(
                      'Tên tài khoản',
                      _paymentRequest!.bankAccount.accountName,
                      canCopy: false,
                    ),
                    _buildInfoRow(
                      'Số tiền',
                      '${_paymentRequest!.amount.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )} ${_paymentRequest!.currency}',
                      canCopy: false,
                      isHighlight: true,
                    ),
                    _buildInfoRow(
                      'Nội dung CK',
                      _paymentRequest!.referenceCode,
                      canCopy: true,
                      isHighlight: true,
                      isImportant: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Warning Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lưu ý: Vui lòng chuyển khoản CHÍNH XÁC nội dung "${_paymentRequest!.referenceCode}" để admin có thể xác nhận và kích hoạt Premium cho bạn.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _handlePaymentCompleted,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Tôi đã thanh toán'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _cancelPayment,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy thanh toán'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              'Hướng dẫn:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Quét mã QR bằng ứng dụng ngân hàng\n'
              '2. Hoặc chuyển khoản thủ công với thông tin trên\n'
              '3. Đảm bảo nội dung chuyển khoản CHÍNH XÁC\n'
              '4. Sau khi chuyển khoản, ấn "Tôi đã thanh toán"\n'
              '5. Admin sẽ xác nhận và kích hoạt Premium cho bạn',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool canCopy = false,
    bool isHighlight = false,
    bool isImportant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isImportant ? Colors.red : null,
                      fontSize: isHighlight ? 15 : 14,
                    ),
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(value, label),
                    tooltip: 'Copy',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
