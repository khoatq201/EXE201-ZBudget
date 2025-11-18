import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with AutomaticKeepAliveClientMixin {
  String _currentFilter = 'pending';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final adminService = context.read<AdminService>();
    if (_currentFilter == 'pending') {
      await adminService.fetchPendingPayments();
    } else {
      await adminService.fetchAllPayments(
        status: _currentFilter == 'all' ? null : _currentFilter,
      );
    }
  }

  Future<void> _approvePayment(AdminPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn duyệt thanh toán này?'),
            const SizedBox(height: 12),
            Text('User: ${payment.user?.email ?? "Unknown"}'),
            Text('Số tiền: ${payment.payment.formattedAmount}'),
            Text('Gói: ${payment.payment.planDisplayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final adminService = context.read<AdminService>();
      final success = await adminService.approvePayment(payment.payment.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã duyệt thanh toán và kích hoạt Premium'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminService.error ?? 'Lỗi khi duyệt thanh toán'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(AdminPayment payment) async {
    String? reason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${payment.user?.email ?? "Unknown"}'),
            Text('Số tiền: ${payment.payment.formattedAmount}'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final adminService = context.read<AdminService>();
      final success = await adminService.rejectPayment(
        payment.payment.id,
        reason: reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối thanh toán'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'pending',
                label: Text('Chờ duyệt'),
                icon: Icon(Icons.schedule),
              ),
              ButtonSegment(
                value: 'completed',
                label: Text('Hoàn thành'),
                icon: Icon(Icons.check_circle),
              ),
              ButtonSegment(
                value: 'all',
                label: Text('Tất cả'),
                icon: Icon(Icons.list),
              ),
            ],
            selected: {_currentFilter},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _currentFilter = selection.first;
              });
              _loadPayments();
            },
          ),
        ),

        // Payments list
        Expanded(
          child: Consumer<AdminService>(
            builder: (context, adminService, child) {
              if (adminService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = _currentFilter == 'pending'
                  ? adminService.pendingPayments
                  : adminService.allPayments;

              if (payments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không có thanh toán nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadPayments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _AdminPaymentCard(
                      payment: payment,
                      onApprove: () => _approvePayment(payment),
                      onReject: () => _rejectPayment(payment),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  final AdminPayment payment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminPaymentCard({
    required this.payment,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isPending = payment.payment.isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (payment.user?.email[0] ?? 'U').toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.user?.email ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (payment.user?.name != null)
                        Text(
                          payment.user!.name!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: payment.user?.isPremium == true
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.user?.tier.toUpperCase() ?? 'FREE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: payment.user?.isPremium == true
                          ? Colors.amber[700]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Payment details
            _buildDetailRow('Gói', payment.payment.planDisplayName),
            _buildDetailRow('Số tiền', payment.payment.formattedAmount),
            _buildDetailRow('Mã thanh toán', payment.payment.referenceCode),
            _buildDetailRow(
                'Ngày tạo', dateFormat.format(payment.payment.createdAt)),
            _buildDetailRow('Trạng thái', payment.payment.status.displayName),

            // Action buttons (only for pending)
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
