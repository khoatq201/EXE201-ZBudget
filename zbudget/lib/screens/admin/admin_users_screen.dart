import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with AutomaticKeepAliveClientMixin {
  String? _filterTier;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final adminService = context.read<AdminService>();
    await adminService.fetchUsers(
      tier: _filterTier,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  Future<void> _manualActivatePremium(AdminUser user) async {
    String? duration = 'monthly';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kích hoạt Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user.email}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: duration,
              decoration: const InputDecoration(
                labelText: 'Chọn gói',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Gói Tháng')),
                DropdownMenuItem(value: 'yearly', child: Text('Gói Năm')),
              ],
              onChanged: (value) => duration = value,
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
            child: const Text('Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirmed == true && duration != null && mounted) {
      final adminService = context.read<AdminService>();
      final success = await adminService.manualActivatePremium(user.id, duration!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã kích hoạt Premium'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminService.error ?? 'Lỗi khi kích hoạt Premium'),
            backgroundColor: Colors.red,
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
        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm email hoặc tên...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadUsers();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _loadUsers(),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _filterTier == null,
                      onSelected: (selected) {
                        setState(() => _filterTier = null);
                        _loadUsers();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Free'),
                      selected: _filterTier == 'free',
                      onSelected: (selected) {
                        setState(() => _filterTier = selected ? 'free' : null);
                        _loadUsers();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Premium'),
                      selected: _filterTier == 'premium',
                      onSelected: (selected) {
                        setState(() => _filterTier = selected ? 'premium' : null);
                        _loadUsers();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Users list
        Expanded(
          child: Consumer<AdminService>(
            builder: (context, adminService, child) {
              if (adminService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (adminService.users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy users',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadUsers,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adminService.users.length,
                  itemBuilder: (context, index) {
                    final user = adminService.users[index];
                    return _UserCard(
                      user: user,
                      onActivatePremium: () => _manualActivatePremium(user),
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

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onActivatePremium;

  const _UserCard({
    required this.user,
    required this.onActivatePremium,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isPremium ? Colors.amber : Colors.blue,
          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
          child: user.avatar == null
              ? Text(
                  user.email[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name ?? user.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isPremium
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.isPremium)
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                  if (user.isPremium) const SizedBox(width: 4),
                  Text(
                    user.tier.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: user.isPremium ? Colors.amber[700] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user.name != null)
              Text(
                user.email,
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              'Tham gia: ${dateFormat.format(user.createdAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (user.subscriptionExpiryDate != null)
              Text(
                'Hết hạn: ${dateFormat.format(user.subscriptionExpiryDate!)}',
                style: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
          ],
        ),
        trailing: !user.isPremium
            ? IconButton(
                icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                onPressed: onActivatePremium,
                tooltip: 'Kích hoạt Premium',
              )
            : null,
        isThreeLine: true,
      ),
    );
  }
}
