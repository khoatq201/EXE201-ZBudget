import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/profile_service.dart';
import '../../../models/settings/user_profile.dart';
import '../../../services/profile_share_service.dart';
import '../../../services/qr_code_service.dart';
import '../../../services/export_data_service.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/auth_utils.dart';
import '../../../widgets/avatar_upload_widget.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Debug profile status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugProfileStatus();
    });
  }

  void _debugProfileStatus() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final isAuthenticated = await AuthUtils.isAuthenticated();

    print('=== PROFILE DEBUG ===');
    print('Is Authenticated: $isAuthenticated');
    print('Current Profile: ${profileService.currentProfile?.name}');
    print('Profile ID: ${profileService.currentProfile?.id}');

    if (isAuthenticated && profileService.currentProfile == null) {
      print('Forcing backend sync...');
      final success = await profileService.syncWithBackend();
      print('Sync result: $success');
      print('After sync - Profile: ${profileService.currentProfile?.name}');
      print('After sync - Profile ID: ${profileService.currentProfile?.id}');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          final profile = profileService.currentProfile;

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, profile),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildStatsSection(profile),
                        const SizedBox(height: AppSpacing.xl),
                        _buildLevelProgressCard(profile),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAchievementsSection(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildPersonalInfoSection(profile),
                        const SizedBox(height: AppSpacing.xl),
                        _buildActionButtons(context),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserProfile profile) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary500,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary500, AppColors.primary600],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildAvatarSection(context, profile),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile.name,
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.email,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserProfile profile) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: profile.avatar != null && profile.avatar!.isNotEmpty
                ? Image.network(
                    profile.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.grey200,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.grey600,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.grey200,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.grey600,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showAvatarOptions(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary500,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              title: 'Level',
              value: '${profile.level}',
              subtitle: '${profile.rank}',
              color: AppColors.success500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              title: 'Điểm',
              value: '${profile.points}',
              subtitle: 'Points',
              color: AppColors.warning500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              title: 'Streak',
              value: '${profile.currentStreak}',
              subtitle: 'ngày',
              color: AppColors.error500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressCard(UserProfile profile) {
    final nextLevelPoints = (profile.level) * 100;
    final currentLevelPoints = (profile.level - 1) * 100;
    final progress =
        (profile.points - currentLevelPoints) /
        (nextLevelPoints - currentLevelPoints);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.warning500, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tiến độ Level',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${profile.level}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Level ${profile.level + 1}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            minHeight: 8,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${profile.points}/$nextLevelPoints điểm',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = [
      Achievement(
        id: '1',
        title: 'Người mới',
        description: 'Hoàn thành hồ sơ cá nhân',
        emoji: '🎉',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Achievement(
        id: '2',
        title: 'Tiết kiệm',
        description: 'Tiết kiệm được 100,000 VND',
        emoji: '💰',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Achievement(
        id: '3',
        title: 'Kỷ luật',
        description: 'Ghi chép chi tiêu 7 ngày liên tiếp',
        emoji: '📝',
        isUnlocked: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: AppColors.info500, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Thành tích',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...achievements
              .map((achievement) => _buildAchievementCard(context, achievement))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? AppColors.success500.withOpacity(0.1)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.isUnlocked
              ? AppColors.success500.withOpacity(0.3)
              : AppColors.grey300,
        ),
      ),
      child: InkWell(
        onTap: () => _showAchievementDetail(context, achievement),
        child: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: achievement.isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: achievement.isUnlocked
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (achievement.isUnlocked)
              Icon(Icons.check_circle, color: AppColors.success500, size: 20)
            else
              Icon(Icons.lock, color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primary500, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Thông tin cá nhân',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow('Email', profile.email),
          _buildInfoRow('Số điện thoại', profile.phone ?? 'Chưa cập nhật'),
          _buildInfoRow(
            'Ngày sinh',
            profile.dateOfBirth != null
                ? '${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}'
                : 'Chưa cập nhật',
          ),
          _buildInfoRow('Giới tính', profile.gender ?? 'Chưa cập nhật'),
          _buildInfoRow('Quốc gia', profile.country ?? 'Chưa cập nhật'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔴 BUTTON "Chia sẻ" CLICKED!');
                    _shareProfile(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Chia sẻ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔴 BUTTON "Xuất dữ liệu" CLICKED!');
                    _exportData(context);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Xuất dữ liệu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEditProfile(context),
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa thông tin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn ảnh đại diện', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    // _changeAvatar(ImageSource.camera);
                  },
                ),
                _buildAvatarOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  onTap: () {
                    Navigator.pop(context);
                    // _changeAvatar(ImageSource.gallery);
                  },
                ),
                _buildAvatarOption(
                  context,
                  icon: Icons.delete,
                  label: 'Xóa ảnh',
                  color: AppColors.error500,
                  onTap: () {
                    Navigator.pop(context);
                    // _removeAvatar();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primary500;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: effectiveColor, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                achievement.title,
                style: AppTypography.headingSmall.copyWith(
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
            Text(achievement.description, style: AppTypography.bodyMedium),
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Đạt được: ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tùy chọn khác', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.primary500),
              title: const Text('Tạo mã QR'),
              subtitle: const Text('Chia sẻ thông tin qua QR code'),
              onTap: () {
                print('🔴 QR CODE BUTTON CLICKED!');
                Navigator.pop(context);
                _showQRCode(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: AppColors.info500),
              title: const Text('Sao lưu dữ liệu'),
              subtitle: const Text('Sao lưu thông tin profile'),
              onTap: () {
                Navigator.pop(context);
                _backupData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.warning500),
              title: const Text('Cài đặt bảo mật'),
              subtitle: const Text('Quản lý mật khẩu và bảo mật'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to security settings
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    print('🔴 _shareProfile method called!');
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    if (profile != null) {
      print('🔴 Profile found: ${profile.name}, calling ProfileShareService');
      ProfileShareService.shareProfile(profile);
    } else {
      print('🔴 Profile is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chia sẻ profile')),
      );
    }
  }

  void _exportData(BuildContext context) {
    print('🔴 _exportData method called!');
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    if (profile != null) {
      print('🔴 Profile found: ${profile.name}, calling ExportDataService');
      ExportDataService.showExportDialog(context, profile);
    } else {
      print('🔴 Profile is null for export');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể xuất dữ liệu')));
    }
  }

  void _showQRCode(BuildContext context) {
    print('🔴 _showQRCode method called!');
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = profileService.currentProfile;

    if (profile != null) {
      print('🔴 Profile found: ${profile.name}, calling QRCodeService');
      QRCodeService.showQRCodeDialog(context, profile);
    } else {
      print('🔴 Profile is null for QR code');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể tạo QR code')));
    }
  }

  void _backupData(BuildContext context) {
    // Implement data backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng sao lưu dữ liệu đang được phát triển'),
      ),
    );
  }
}

// Achievement model class
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    this.unlockedAt,
  });
}
