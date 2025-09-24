import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../constants/colors.dart';

class ChallengeService extends ChangeNotifier {
  List<Challenge> _challenges = [];
  UserStats _userStats = UserStats(
    streak: 12,
    level: 5,
    points: 2450,
    totalChallengesCompleted: 18,
    totalSavings: 3200000,
    rank: 247,
    nextLevelPoints: 500,
  );

  List<Challenge> get challenges => _challenges;
  UserStats get userStats => _userStats;

  final List<ChallengeCategoryModel> categories = [
    ChallengeCategoryModel(
      id: 'all',
      name: 'Tất cả',
      icon: '🎯',
      color: AppColors.primary500,
    ),
    ChallengeCategoryModel(
      id: 'drinks',
      name: 'Đồ uống',
      icon: '🧋',
      color: AppColors.secondary500,
    ),
    ChallengeCategoryModel(
      id: 'food',
      name: 'Ăn uống',
      icon: '🍜',
      color: AppColors.accent500,
    ),
    ChallengeCategoryModel(
      id: 'transport',
      name: 'Di chuyển',
      icon: '🚌',
      color: AppColors.primary600,
    ),
    ChallengeCategoryModel(
      id: 'shopping',
      name: 'Mua sắm',
      icon: '🛍️',
      color: AppColors.secondary600,
    ),
    ChallengeCategoryModel(
      id: 'entertainment',
      name: 'Giải trí',
      icon: '🎬',
      color: AppColors.accent600,
    ),
  ];

  ChallengeService() {
    _loadChallenges();
  }

  void _loadChallenges() {
    _challenges = [
      // Active challenge
      Challenge(
        id: 'coffee-reduction',
        emoji: '☕',
        title: 'Cà phê tự pha 7 ngày',
        description:
            'Pha cà phê tại nhà thay vì mua ngoài trong 7 ngày. Tiết kiệm 15,000đ mỗi ngày bằng cách tự pha cà phê thay vì mua ở quán.',
        participants: 1234,
        duration: '7 ngày',
        amount: 105000,
        difficulty: ChallengeDifficulty.easy,
        points: 150,
        status: ChallengeStatus.active,
        category: ChallengeCategory.drinks,
        progress: 65,
        startDate: DateTime.now().subtract(const Duration(days: 4)),
        currentSaved: 45000.0,
        streakDays: 3,
        milestones: [
          ChallengeMilestone(
            day: 3,
            targetAmount: 45000,
            reward: '10 điểm bonus',
            description: 'Đã quen với việc pha cà phê',
            isCompleted: true,
          ),
          ChallengeMilestone(
            day: 7,
            targetAmount: 105000,
            reward: '50 điểm chính + 20 điểm hoàn thành',
            description: 'Master pha cà phê tại nhà',
            isCompleted: false,
          ),
        ],
        endDate: DateTime.now().add(const Duration(days: 3)),
        currentSavings: 120000,
        streak: 2,
        badgeIcon: '🥇',
      ),

      // Available challenges
      Challenge(
        id: 'bubble-tea-detox',
        emoji: '🧋',
        title: 'Bubble Tea Detox',
        description:
            'Thay trà sữa bằng trà xanh tự pha trong 14 ngày. Detox khỏi đường và tiết kiệm 30,000đ mỗi ngày.',
        participants: 2156,
        duration: '14 ngày',
        amount: 420000,
        difficulty: ChallengeDifficulty.medium,
        points: 180,
        status: ChallengeStatus.available,
        category: ChallengeCategory.drinks,
        currentSaved: 0.0,
        streakDays: 0,
        milestones: [
          ChallengeMilestone(
            day: 3,
            targetAmount: 90000,
            reward: '15 điểm bonus',
            description: 'Bắt đầu cai nghiện trà sữa',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 7,
            targetAmount: 210000,
            reward: '30 điểm bonus',
            description: 'Làm chủ cảm giác thèm',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 14,
            targetAmount: 420000,
            reward: '50 điểm chính + 30 điểm hoàn thành',
            description: 'Bubble Tea Detox Master',
            isCompleted: false,
          ),
        ],
        badgeIcon: '🏆',
      ),

      Challenge(
        id: 'walk-challenge',
        emoji: '🚶',
        title: 'Walk & Save',
        description:
            'Đi bộ thay vì đi taxi cho quãng đường dưới 2km trong 21 ngày. Vừa tiết kiệm vừa tốt cho sức khỏe.',
        participants: 3421,
        duration: '21 ngày',
        amount: 600000,
        difficulty: ChallengeDifficulty.easy,
        points: 200,
        status: ChallengeStatus.available,
        category: ChallengeCategory.transport,
        currentSaved: 0.0,
        streakDays: 0,
        milestones: [
          ChallengeMilestone(
            day: 7,
            targetAmount: 200000,
            reward: '20 điểm bonus + Sticker "Bước chân đầu tiên"',
            description: 'Hình thành thói quen đi bộ',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 14,
            targetAmount: 400000,
            reward: '30 điểm bonus + Achievement "Steady Walker"',
            description: 'Duy trì đều đặn',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 21,
            targetAmount: 600000,
            reward:
                '50 điểm chính + 40 điểm hoàn thành + Badge "Walking Master"',
            description: 'Master đi bộ tiết kiệm',
            isCompleted: false,
          ),
        ],
        badgeIcon: '🚶‍♀️',
      ),

      Challenge(
        id: 'home-cook-master',
        emoji: '🍳',
        title: 'Home Cook Master',
        description:
            'Nấu ăn tại nhà thay vì đặt đồ ăn trong 30 ngày. Challenge khó nhất với phần thưởng lớn nhất!',
        participants: 1879,
        duration: '30 ngày',
        amount: 1200000,
        difficulty: ChallengeDifficulty.hard,
        points: 300,
        status: ChallengeStatus.available,
        category: ChallengeCategory.food,
        currentSaved: 0.0,
        streakDays: 0,
        milestones: [
          ChallengeMilestone(
            day: 7,
            targetAmount: 280000,
            reward: '25 điểm bonus + Recipe Book Digital',
            description: 'Tuần đầu thành công',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 15,
            targetAmount: 600000,
            reward: '40 điểm bonus + Kitchen Tools Set',
            description: 'Nửa chặng đường',
            isCompleted: false,
          ),
          ChallengeMilestone(
            day: 30,
            targetAmount: 1200000,
            reward:
                '100 điểm chính + 50 điểm hoàn thành + Title "Home Cook Master"',
            description: 'Bậc thầy nấu ăn tại nhà',
            isCompleted: false,
          ),
        ],
        badgeIcon: '👨‍🍳',
      ),

      // Completed challenge
      Challenge(
        id: 'no-shopping-weekend',
        emoji: '🛍️',
        title: 'Weekend Không Mua Sắm',
        description:
            'Không mua sắm trực tuyến vào cuối tuần trong 8 tuần. Challenge hoàn thành xuất sắc!',
        participants: 892,
        duration: '8 tuần',
        amount: 800000,
        difficulty: ChallengeDifficulty.medium,
        points: 250,
        status: ChallengeStatus.completed,
        category: ChallengeCategory.shopping,
        currentSaved: 850000.0,
        streakDays: 56,
        milestones: [
          ChallengeMilestone(
            day: 14,
            targetAmount: 200000,
            reward: '20 điểm bonus',
            description: '2 tuần kháng cự thành công',
            isCompleted: true,
          ),
          ChallengeMilestone(
            day: 28,
            targetAmount: 400000,
            reward: '35 điểm bonus + Shopping Detox Badge',
            description: '1 tháng kiểm soát được cảm xúc mua sắm',
            isCompleted: true,
          ),
          ChallengeMilestone(
            day: 56,
            targetAmount: 800000,
            reward:
                '70 điểm chính + 40 điểm hoàn thành + Title "Shopping Master"',
            description: '8 tuần hoàn hảo không mua sắm bốc đồng',
            isCompleted: true,
          ),
        ],
        currentSavings: 850000,
        completedAt: DateTime.now().subtract(const Duration(days: 15)),
        badgeIcon: '🏅',
      ),
    ];
    notifyListeners();
  }

  List<Challenge> getChallengesByTab(String tab) {
    switch (tab) {
      case 'active':
        return _challenges
            .where((c) => c.status == ChallengeStatus.active)
            .toList();
      case 'completed':
        return _challenges
            .where((c) => c.status == ChallengeStatus.completed)
            .toList();
      default:
        return _challenges
            .where((c) => c.status == ChallengeStatus.available)
            .toList();
    }
  }

  List<Challenge> getChallengesByCategory(String categoryId) {
    if (categoryId == 'all') return _challenges;
    return _challenges
        .where((c) => c.category.toString().split('.').last == categoryId)
        .toList();
  }

  Future<void> joinChallenge(String challengeId) async {
    await Future.delayed(const Duration(seconds: 1));

    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      _challenges[challengeIndex] = _challenges[challengeIndex].copyWith(
        participants: _challenges[challengeIndex].participants + 1,
        status: ChallengeStatus.active,
        progress: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        currentSavings: 0,
        streak: 0,
      );
      notifyListeners();
    }
  }

  String formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}đ';
  }

  String getDifficultyText(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Dễ';
      case ChallengeDifficulty.medium:
        return 'Trung bình';
      case ChallengeDifficulty.hard:
        return 'Khó';
    }
  }

  Color getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.success;
      case ChallengeDifficulty.medium:
        return AppColors.warning;
      case ChallengeDifficulty.hard:
        return AppColors.error;
    }
  }

  String getButtonText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return 'Tham gia ngay';
      case ChallengeStatus.active:
        return 'Đang tham gia';
      case ChallengeStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  Color getButtonColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.available:
        return AppColors.primary500;
      case ChallengeStatus.active:
        return AppColors.secondary500;
      case ChallengeStatus.completed:
        return AppColors.success;
    }
  }
}
