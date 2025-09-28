import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../services/profile_service.dart';
import '../../../models/settings/user_profile.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          if (profileService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary500),
            );
          }

          final profile = profileService.currentProfile;
          if (profile == null) {
            return const Center(child: Text('Không thể tải thông tin profile'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, profile),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildStatsSection(context, profile),
                      const SizedBox(height: AppSpacing.xl),
                      _buildAchievementsSection(context, profile),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPersonalInfoSection(context, profile),
                      const SizedBox(height: AppSpacing.xl),
                      _buildActionButtons(context),
                      const SizedBox(height: AppSpacing.xl6),
                    ],
                  ),
                ),
              ),
            ],
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
      foregroundColor: AppColors.textInverse,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary500,
                AppColors.primary600,
                AppColors.primary700,
              ],
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
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary800.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.textInverse.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: profile.levelColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${profile.stats.currentLevel} • ${profile.levelTitle}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToEditProfile(context),
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Chỉnh sửa',
        ),
        IconButton(
          onPressed: () => _showMoreOptions(context),
          icon: const Icon(Icons.more_vert),
          tooltip: 'Tùy chọn khác',
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserProfile profile) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textInverse.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary300,
            backgroundImage: profile.avatar != null
                ? FileImage(File(profile.avatar!))
                : null,
            child: profile.avatar == null
                ? Text(
                    profile.initials,
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary700,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showAvatarOptions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent500,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textInverse, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppColors.textInverse,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, UserProfile profile) {
    final profileService = Provider.of<ProfileService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.savings_rounded,
                  title: 'Tổng tiết kiệm',
                  value: profileService.formatCurrency(
                    profile.stats.totalSaved,
                  ),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak hiện tại',
                  value: '${profile.stats.streakDays} ngày',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Ngày hoạt động',
                  value: profileService.formatDuration(
                    profile.stats.activeDays,
                  ),
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Challenges',
                  value: '${profile.stats.completedChallenges} hoàn thành',
                  color: AppColors.primary500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLevelProgressCard(context, profile),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressCard(BuildContext context, UserProfile profile) {
    final currentLevel = profile.stats.currentLevel;
    final currentPoints = profile.stats.totalPoints;
    final pointsToNextLevel = (currentLevel * 200);
    final progress = (currentPoints % 200) / 200;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profile.levelColor.withValues(alpha: 0.1),
            profile.levelColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: profile.levelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: profile.levelColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Level $currentLevel - ${profile.levelTitle}',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$currentPoints điểm',
                style: AppTypography.body.copyWith(
                  color: profile.levelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(profile.levelColor),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Còn ${pointsToNextLevel - (currentPoints % 200)} điểm để lên Level ${currentLevel + 1}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, UserProfile profile) {
    final unlockedAchievements = profile.achievements
        .where((a) => a.isUnlocked)
        .toList();
    final lockedAchievements = profile.achievements
        .where((a) => !a.isUnlocked)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành tích',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${unlockedAchievements.length}/${profile.achievements.length}',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (unlockedAchievements.isNotEmpty) ...[
            Text(
              'Đã mở khóa',
              style: AppTypography.body.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: unlockedAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(
                  unlockedAchievements[index],
                  isUnlocked: true,
                );
              },
            ),
          ],
          if (lockedAchievements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa mở khóa',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: lockedAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(
                  lockedAchievements[index],
                  isUnlocked: false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement, {
    required bool isUnlocked,
  }) {
    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.dark200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.emoji,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              achievement.title,
              style: AppTypography.bodySmall.copyWith(
                color: isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${achievement.pointsReward} điểm',
                style: AppTypography.caption.copyWith(
                  color: isUnlocked
                      ? AppColors.success
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, UserProfile profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email,
                ),
                if (profile.phone != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: profile.phone!,
                  ),
                ],
                if (profile.birthday != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Ngày sinh',
                    value:
                        '${profile.birthday!.day}/${profile.birthday!.month}/${profile.birthday!.year} (${profile.age} tuổi)',
                  ),
                ],
                if (profile.gender != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    icon: profile.gender!.icon,
                    label: 'Giới tính',
                    value: profile.gender!.displayName,
                  ),
                ],
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.info_outline,
                    label: 'Giới thiệu',
                    value: profile.bio!,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary500, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEditProfile(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Chỉnh sửa thông tin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareProfile(context),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Chia sẻ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary500,
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
                child: OutlinedButton.icon(
                  onPressed: () => _exportData(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Xuất dữ liệu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary500,
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dark200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primary500,
              ),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _changeAvatar();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary500,
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _changeAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Xóa ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);
                _removeAvatar();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _changeAvatar() async {
    // Implement avatar change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng thay đổi ảnh đại diện đang được phát triển'),
      ),
    );
  }

  void _removeAvatar() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    await profileService.updateAvatar(null);
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
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    achievement.isUnlocked ? Icons.check_circle : Icons.lock,
                    color: achievement.isUnlocked
                        ? AppColors.success
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    achievement.isUnlocked
                        ? 'Đã mở khóa • ${achievement.pointsReward} điểm'
                        : 'Chưa mở khóa • ${achievement.pointsReward} điểm',
                    style: AppTypography.bodySmall.copyWith(
                      color: achievement.isUnlocked
                          ? AppColors.success
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mở khóa: ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                style: AppTypography.caption.copyWith(
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dark200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.primary500),
              title: const Text('QR Code'),
              subtitle: const Text('Tạo mã QR để chia sẻ profile'),
              onTap: () {
                Navigator.pop(context);
                _showQRCode(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: AppColors.info),
              title: const Text('Sao lưu dữ liệu'),
              subtitle: const Text('Sao lưu thông tin profile'),
              onTap: () {
                Navigator.pop(context);
                _backupData(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.warning),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chia sẻ profile đang được phát triển'),
      ),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng xuất dữ liệu đang được phát triển'),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng QR Code đang được phát triển')),
    );
  }

  void _backupData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng sao lưu dữ liệu đang được phát triển'),
      ),
    );
  }
}
