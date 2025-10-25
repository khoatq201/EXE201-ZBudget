import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../services/profile_service.dart';
import '../../../services/image_upload_service.dart';
import '../../../models/settings/user_profile.dart';
import '../../../services/profile_share_service.dart';
import '../../../services/qr_code_service.dart';
import '../../../services/export_data_service.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/spacing.dart';
import '../../../utils/auth_utils.dart';
import '../../../utils/theme_extensions.dart';
import 'edit_profile_screen.dart';
import '../security/security_screen_simple.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isUploadingAvatar = false;

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

    // Debug profile status and force sync
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
      final success = await profileService.syncWithServer();
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
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          if (profileService.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: context.colorScheme.primary,
              ),
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
                      // _buildStatsSection(context, profile),
                      // const SizedBox(height: AppSpacing.xl),
                      // _buildAchievementsSection(context, profile),
                      // const SizedBox(height: AppSpacing.xl),
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
      backgroundColor: context.headerGradientStart,
      foregroundColor: context.headerTextColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.headerGradientStart,
                context.headerGradientEnd,
                context.headerGradientEnd.withOpacity(0.9),
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
                    color: context.colorScheme.onPrimary,
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
                    color: context.colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colorScheme.onPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: _getLevelColor(profile.stats.currentLevel),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${profile.stats.currentLevel} • ${_getLevelTitle(profile.stats.currentLevel)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.colorScheme.onPrimary,
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
              color: context.colorScheme.onPrimary.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _isUploadingAvatar
              ? Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: context.colorScheme.primaryContainer,
                  backgroundImage:
                      profile.avatar != null && profile.avatar!.isNotEmpty
                      ? NetworkImage(
                          profile.avatar!,
                        ) // Use NetworkImage for API avatar
                      : null,
                  child: profile.avatar == null || profile.avatar!.isEmpty
                      ? Text(
                          _getInitials(profile.name),
                          style: AppTypography.h2.copyWith(
                            color: context.colorScheme.onPrimaryContainer,
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
            onTap: _isUploadingAvatar
                ? null
                : () => _showAvatarOptions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isUploadingAvatar
                    ? Colors.grey
                    : context.colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.onPrimary,
                  width: 2,
                ),
              ),
              child: Icon(
                _isUploadingAvatar ? Icons.hourglass_empty : Icons.camera_alt,
                color: context.colorScheme.onSecondary,
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
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
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
                  context: context,
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
                  context: context,
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
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  title: 'Challenges',
                  value: '${profile.stats.completedChallenges} hoàn thành',
                  color: context.colorScheme.primary,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
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
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: context.customTextSecondary,
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
    final levelColor = _getLevelColor(currentLevel);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withOpacity(0.1), levelColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: levelColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Level $currentLevel - ${_getLevelTitle(currentLevel)}',
                  style: AppTypography.body.copyWith(
                    color: context.customTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$currentPoints điểm',
                style: AppTypography.body.copyWith(
                  color: levelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Còn ${pointsToNextLevel - (currentPoints % 200)} điểm để lên Level ${currentLevel + 1}',
            style: AppTypography.bodySmall.copyWith(
              color: context.customTextSecondary,
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
                  color: context.customTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${unlockedAchievements.length}/${profile.achievements.length}',
                style: AppTypography.body.copyWith(
                  color: context.customTextSecondary,
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
                color: context.customTextSecondary,
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
          // Show default achievements if none from API
          if (profile.achievements.isEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: _getDefaultAchievements().length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(
                  _getDefaultAchievements()[index],
                  isUnlocked: index < 2,
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
              ? AppColors.success.withOpacity(0.1)
              : context.achievementBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppColors.success.withOpacity(0.3)
                : context.cardBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.emoji,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : context.customTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              achievement.title,
              style: AppTypography.bodySmall.copyWith(
                color: isUnlocked
                    ? context.achievementText
                    : context.customTextSecondary,
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
                    ? AppColors.success.withOpacity(0.2)
                    : context.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${achievement.pointsReward} điểm',
                style: AppTypography.caption.copyWith(
                  color: isUnlocked
                      ? AppColors.success
                      : context.customTextSecondary,
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
              color: context.customTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBackground,
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
                        '${profile.birthday!.day}/${profile.birthday!.month}/${profile.birthday!.year} (${_calculateAge(profile.birthday!)} tuổi)',
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
          Icon(icon, color: context.colorScheme.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.customTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    color: context.infoRowText,
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
                backgroundColor: context.primaryButtonBackground,
                foregroundColor: context.primaryButtonForeground,
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
                  onPressed: () {
                    print('🔴 BUTTON "Chia sẻ" CLICKED!');
                    _shareProfile(context);
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Chia sẻ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
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
                  onPressed: () {
                    print('🔴 BUTTON "Xuất dữ liệu" CLICKED!');
                    _exportData(context);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Xuất dữ liệu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
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

  // Helper methods
  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
  }

  Color _getLevelColor(int level) {
    if (level <= 5) return AppColors.success;
    if (level <= 10) return AppColors.info;
    if (level <= 20) return AppColors.warning;
    return AppColors.primary500;
  }

  String _getLevelTitle(int level) {
    if (level <= 5) return 'Người mới';
    if (level <= 10) return 'Học viên';
    if (level <= 20) return 'Chuyên gia';
    return 'Bậc thầy';
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: '1',
        title: 'Người mới',
        description: 'Hoàn thành hồ sơ cá nhân',
        emoji: '🎉',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 7)),
        pointsReward: 50,
      ),
      Achievement(
        id: '2',
        title: 'Tiết kiệm',
        description: 'Tiết kiệm được 100,000 VND',
        emoji: '💰',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
        pointsReward: 100,
      ),
      Achievement(
        id: '3',
        title: 'Kỷ luật',
        description: 'Ghi chép chi tiêu 7 ngày liên tiếp',
        emoji: '📝',
        isUnlocked: false,
        pointsReward: 150,
      ),
    ];
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
                _changeAvatar(ImageSource.camera);
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
                _changeAvatar(ImageSource.gallery);
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

  void _changeAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        // Set loading state instead of showing dialog
        setState(() {
          _isUploadingAvatar = true;
        });

        try {
          // Upload avatar using ImageUploadService
          final File imageFile = File(image.path);
          print('🔄 Starting avatar upload...');
          print('📤 File path: ${imageFile.path}');
          print('📤 File size: ${await imageFile.length()} bytes');

          final uploadResult = await ImageUploadService.uploadAvatar(imageFile);
          print('📤 Upload result: $uploadResult');

          if (uploadResult != null && uploadResult['success'] == true) {
            // Update profile with new avatar URL
            final profileService = Provider.of<ProfileService>(
              context,
              listen: false,
            );
            final currentProfile = profileService.currentProfile;

            print('🔄 Before update - isLoading: ${profileService.isLoading}');

            if (currentProfile != null) {
              // Lấy avatar URL từ nested data object - sửa key từ 'avatarUrl' thành 'avatar'
              final avatarUrl = uploadResult['data']?['avatar'] as String?;
              print('🔄 Avatar URL from response: $avatarUrl');

              if (avatarUrl != null) {
                await profileService.updateProfile(
                  currentProfile.copyWith(avatar: avatarUrl),
                  syncToServer: false, // Tạm thời disable sync để test
                );

                print(
                  '🔄 Profile updated, isLoading: ${profileService.isLoading}',
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cập nhật ảnh đại diện thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Không thể lấy URL ảnh từ server!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Không thể cập nhật profile!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Không thể tải ảnh lên. Vui lòng thử lại!',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Avatar upload error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi upload: ${e.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } finally {
          // Always reset loading state
          if (mounted) {
            setState(() {
              _isUploadingAvatar = false;
            });
            print('🔄 Avatar upload process completed, loading state reset');
          }
        }
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                print('🔴 QR CODE BUTTON CLICKED!');
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
                _navigateToSecuritySettings(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  // IMPLEMENTED SERVICES (with debug logging)
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng sao lưu dữ liệu đang được phát triển'),
      ),
    );
  }

  void _navigateToSecuritySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityScreenSimple()),
    );
  }
}
