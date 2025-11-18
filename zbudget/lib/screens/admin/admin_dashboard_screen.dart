import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import 'admin_payments_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardOverviewTab(),
    const AdminPaymentsScreen(),
    const AdminUsersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final adminService = context.read<AdminService>();
    await Future.wait([
      adminService.fetchDashboardStats(),
      adminService.fetchPendingPayments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Consumer<AdminService>(
              builder: (context, adminService, child) {
                final count = adminService.pendingCount;
                return Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.payment),
                );
              },
            ),
            label: 'Thanh toán',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class _DashboardOverviewTab extends StatelessWidget {
  const _DashboardOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminService>(
      builder: (context, adminService, child) {
        if (adminService.isLoading && adminService.stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = adminService.stats;

        if (stats == null) {
          return const Center(
            child: Text('Không thể tải dữ liệu'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await adminService.fetchDashboardStats();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Stats
              Text(
                'Thống kê Users',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Tổng Users',
                      value: stats.users.total.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Premium',
                      value: stats.users.premium.toString(),
                      subtitle: '${stats.users.premiumPercentage.toStringAsFixed(1)}%',
                      icon: Icons.workspace_premium,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Free Users',
                value: stats.users.free.toString(),
                icon: Icons.person,
                color: Colors.grey,
              ),

              const SizedBox(height: 24),

              // Payment Stats
              Text(
                'Thống kê Thanh toán',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Chờ duyệt',
                      value: stats.payments.pending.toString(),
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Hoàn thành',
                      value: stats.payments.completed.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Tổng doanh thu',
                value: stats.payments.formattedRevenue,
                icon: Icons.attach_money,
                color: Colors.purple,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Bị hủy',
                      value: stats.payments.cancelled.toString(),
                      icon: Icons.cancel,
                      color: Colors.grey,
                      isSmall: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Từ chối',
                      value: stats.payments.rejected.toString(),
                      icon: Icons.error,
                      color: Colors.red,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isSmall;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: isSmall ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 6 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
