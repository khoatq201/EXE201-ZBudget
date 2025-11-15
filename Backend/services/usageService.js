import UsageLimit from "../models/UsageLimit.js";
import User from "../models/User.js";

/**
 * Usage Tracking Service
 *
 * Service layer for tracking and managing feature usage
 * Wrapper around UsageLimit model with additional business logic
 */

class UsageService {
  /**
   * Check OCR scan availability
   */
  static async checkOCRLimit(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) {
      throw new Error("User not found");
    }

    const tier = user.subscription.tier;
    return await UsageLimit.checkOCRLimit(userId, tier);
  }

  /**
   * Increment OCR usage counter
   */
  static async incrementOCRCount(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) {
      throw new Error("User not found");
    }

    const tier = user.subscription.tier;
    return await UsageLimit.incrementOCRCount(userId, tier);
  }

  /**
   * Check AI Analysis availability
   */
  static async checkAILimit(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) {
      throw new Error("User not found");
    }

    const tier = user.subscription.tier;
    return await UsageLimit.checkAILimit(userId, tier);
  }

  /**
   * Increment AI analysis counter
   */
  static async incrementAICount(userId) {
    return await UsageLimit.incrementAICount(userId);
  }

  /**
   * Get comprehensive usage stats for a user
   */
  static async getUserUsageStats(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) {
      throw new Error("User not found");
    }

    const tier = user.subscription.tier;
    const usage = await UsageLimit.getUserUsageStats(userId, tier);
    const limits = user.getFeatureLimits();

    return {
      tier,
      isPremium: user.isPremium(),
      usage: {
        ocr: {
          ...usage.ocr,
          percentage: this.calculatePercentage(
            usage.ocr.count,
            usage.ocr.limit
          ),
        },
        aiAnalysis: {
          ...usage.aiAnalysis,
          enabled: limits.aiAnalysisEnabled,
        },
      },
      limits: {
        maxBudgets: limits.maxBudgets,
        maxSavingsGoals: limits.maxSavingsGoals,
        ocrScansPerDay: limits.ocrScansPerDay,
        aiAnalysisEnabled: limits.aiAnalysisEnabled,
      },
      resetTime: {
        nextReset: "00:00",
        timezone: "Asia/Ho_Chi_Minh",
        description: "Số lượt sử dụng sẽ reset vào 0h đêm (giờ Việt Nam)",
      },
    };
  }

  /**
   * Reset daily limits (called by cron job)
   */
  static async resetDailyLimits() {
    return await UsageLimit.resetDailyLimits();
  }

  /**
   * Update user limits after subscription change
   */
  static async updateUserLimits(userId, newTier) {
    return await UsageLimit.updateUserLimits(userId, newTier);
  }

  /**
   * Get usage summary for multiple users (admin function)
   */
  static async getUsageSummary(userIds = null, dateRange = null) {
    const query = {};

    if (userIds && Array.isArray(userIds) && userIds.length > 0) {
      query.userId = { $in: userIds };
    }

    if (dateRange && dateRange.start && dateRange.end) {
      query.date = {
        $gte: dateRange.start,
        $lte: dateRange.end,
      };
    } else {
      // Default to today only
      query.date = UsageLimit.getCurrentDateVN();
    }

    const usageRecords = await UsageLimit.find(query).populate(
      "userId",
      "email profile.name subscription.tier"
    );

    return usageRecords.map((record) => ({
      userId: record.userId._id,
      email: record.userId.email,
      name: record.userId.profile?.name,
      tier: record.userId.subscription?.tier,
      date: record.date,
      ocr: {
        count: record.ocrScans.count,
        limit: record.ocrScans.limit,
        lastUsedAt: record.ocrScans.lastUsedAt,
      },
      aiAnalysis: {
        count: record.aiAnalysis.count,
        lastUsedAt: record.aiAnalysis.lastUsedAt,
      },
    }));
  }

  /**
   * Get total usage stats across all users (analytics)
   */
  static async getTotalUsageStats() {
    const today = UsageLimit.getCurrentDateVN();

    const stats = await UsageLimit.aggregate([
      { $match: { date: today } },
      {
        $group: {
          _id: null,
          totalOCRScans: { $sum: "$ocrScans.count" },
          totalAIAnalysis: { $sum: "$aiAnalysis.count" },
          uniqueUsers: { $addToSet: "$userId" },
        },
      },
    ]);

    const result = stats[0] || {
      totalOCRScans: 0,
      totalAIAnalysis: 0,
      uniqueUsers: [],
    };

    return {
      date: today,
      totalOCRScans: result.totalOCRScans,
      totalAIAnalysis: result.totalAIAnalysis,
      activeUsers: result.uniqueUsers.length,
    };
  }

  /**
   * Get usage trends over time (for charts/analytics)
   */
  static async getUsageTrends(days = 7) {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const trends = await UsageLimit.aggregate([
      {
        $match: {
          date: {
            $gte: UsageLimit.getCurrentDateVN.call({}, startDate),
            $lte: UsageLimit.getCurrentDateVN.call({}, endDate),
          },
        },
      },
      {
        $group: {
          _id: "$date",
          totalOCRScans: { $sum: "$ocrScans.count" },
          totalAIAnalysis: { $sum: "$aiAnalysis.count" },
          activeUsers: { $addToSet: "$userId" },
        },
      },
      {
        $project: {
          date: "$_id",
          totalOCRScans: 1,
          totalAIAnalysis: 1,
          activeUsers: { $size: "$activeUsers" },
        },
      },
      { $sort: { date: 1 } },
    ]);

    return trends.map((trend) => ({
      date: trend.date,
      ocrScans: trend.totalOCRScans,
      aiAnalysis: trend.totalAIAnalysis,
      activeUsers: trend.activeUsers,
    }));
  }

  /**
   * Helper: Calculate percentage
   */
  static calculatePercentage(current, limit) {
    if (limit === -1 || limit === 0) return 0;
    return Math.min(100, Math.round((current / limit) * 100));
  }

  /**
   * Get time until reset
   */
  static getTimeUntilReset() {
    const now = new Date();
    const vnTime = new Date(
      now.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" })
    );

    // Calculate time until midnight Vietnam time
    const midnight = new Date(vnTime);
    midnight.setHours(24, 0, 0, 0);

    const diff = midnight - vnTime;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

    return {
      hours,
      minutes,
      formatted: `${hours}h ${minutes}m`,
      timestamp: midnight.toISOString(),
    };
  }

  /**
   * Check if user has reached limit for any feature
   */
  static async hasReachedAnyLimit(userId) {
    const stats = await this.getUserUsageStats(userId);

    const ocrLimitReached =
      stats.usage.ocr.limit !== -1 &&
      stats.usage.ocr.count >= stats.usage.ocr.limit;

    return {
      hasReachedLimit: ocrLimitReached,
      limits: {
        ocr: ocrLimitReached,
      },
      upgradeRecommended: ocrLimitReached && stats.tier === "free",
    };
  }
}

export default UsageService;
