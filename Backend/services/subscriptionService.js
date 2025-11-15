import User from "../models/User.js";
import UsageLimit from "../models/UsageLimit.js";

/**
 * Subscription Service
 *
 * Handles all subscription-related business logic:
 * - Checking subscription status
 * - Upgrading/downgrading tiers
 * - Getting feature limits
 * - Auto-expiring subscriptions
 */

class SubscriptionService {
  /**
   * Pricing configuration
   */
  static PRICING = {
    monthly: {
      amount: 25000,
      currency: "VND",
      duration: 30, // days
      displayName: "Gói Tháng",
    },
    yearly: {
      amount: 250000,
      currency: "VND",
      duration: 365, // days
      displayName: "Gói Năm",
      savings: 50000, // Save 50k compared to 12 months
    },
  };

  /**
   * Feature limits configuration
   */
  static FEATURE_LIMITS = {
    free: {
      maxBudgets: 2,
      maxSavingsGoals: 2,
      ocrScansPerDay: 10,
      aiAnalysisEnabled: false,
      displayName: "Miễn phí",
    },
    premium: {
      maxBudgets: 20,
      maxSavingsGoals: 10,
      ocrScansPerDay: -1, // unlimited
      aiAnalysisEnabled: true,
      displayName: "Premium",
    },
  };

  /**
   * Check if user subscription is active and valid
   */
  static async checkSubscriptionStatus(userId) {
    const user = await User.findById(userId).select("subscription");

    if (!user) {
      throw new Error("User not found");
    }

    // Check if subscription has expired
    const hasExpired = user.checkSubscriptionExpiry();

    if (hasExpired) {
      await user.save();
    }

    return {
      tier: user.subscription.tier,
      status: user.subscription.status,
      isPremium: user.isPremium(),
      expiryDate: user.subscription.expiryDate,
      daysRemaining: this.getDaysRemaining(user.subscription.expiryDate),
      features: user.getFeatureLimits(),
    };
  }

  /**
   * Get feature limits for a user
   */
  static async getFeatureLimits(userId) {
    const user = await User.findById(userId).select("subscription");

    if (!user) {
      throw new Error("User not found");
    }

    const limits = user.getFeatureLimits();
    const tier = user.subscription.tier;

    return {
      tier,
      isPremium: user.isPremium(),
      limits,
      config: this.FEATURE_LIMITS[tier],
    };
  }

  /**
   * Upgrade user to premium
   */
  static async upgradeToPremium(userId, duration = "monthly", performedBy = "admin") {
    const user = await User.findById(userId);

    if (!user) {
      throw new Error("User not found");
    }

    if (user.isPremium()) {
      throw new Error("User is already premium");
    }

    // Upgrade using User model method
    user.upgradeToPremium(duration);

    // Update subscription history metadata
    const lastHistory = user.subscriptionHistory[user.subscriptionHistory.length - 1];
    if (lastHistory) {
      lastHistory.performedBy = performedBy;
    }

    await user.save();

    // Update usage limits for today
    await UsageLimit.updateUserLimits(userId, "premium");

    return {
      success: true,
      message: `Đã nâng cấp lên Premium ${this.PRICING[duration].displayName}`,
      subscription: {
        tier: user.subscription.tier,
        status: user.subscription.status,
        expiryDate: user.subscription.expiryDate,
        price: user.subscription.price,
      },
    };
  }

  /**
   * Downgrade user to free tier
   */
  static async downgradeToFree(userId, reason = "User requested", performedBy = "user") {
    const user = await User.findById(userId);

    if (!user) {
      throw new Error("User not found");
    }

    if (user.subscription.tier === "free") {
      throw new Error("User is already on free tier");
    }

    // Downgrade using User model method
    user.downgradeToFree(reason);

    // Update subscription history metadata
    const lastHistory = user.subscriptionHistory[user.subscriptionHistory.length - 1];
    if (lastHistory) {
      lastHistory.performedBy = performedBy;
    }

    await user.save();

    // Update usage limits for today
    await UsageLimit.updateUserLimits(userId, "free");

    return {
      success: true,
      message: "Đã hạ xuống gói Miễn phí",
      subscription: {
        tier: user.subscription.tier,
        status: user.subscription.status,
      },
    };
  }

  /**
   * Get usage statistics for a user
   */
  static async getUsageStats(userId) {
    const user = await User.findById(userId).select("subscription");

    if (!user) {
      throw new Error("User not found");
    }

    const tier = user.subscription.tier;
    const usage = await UsageLimit.getUserUsageStats(userId, tier);

    return {
      tier,
      isPremium: user.isPremium(),
      usage,
      limits: user.getFeatureLimits(),
    };
  }

  /**
   * Get pricing information
   */
  static getPricing() {
    return {
      plans: [
        {
          id: "monthly",
          name: this.PRICING.monthly.displayName,
          price: this.PRICING.monthly.amount,
          currency: this.PRICING.monthly.currency,
          duration: this.PRICING.monthly.duration,
          durationLabel: "tháng",
          pricePerMonth: this.PRICING.monthly.amount,
          features: this.FEATURE_LIMITS.premium,
        },
        {
          id: "yearly",
          name: this.PRICING.yearly.displayName,
          price: this.PRICING.yearly.amount,
          currency: this.PRICING.yearly.currency,
          duration: this.PRICING.yearly.duration,
          durationLabel: "năm",
          pricePerMonth: Math.round(this.PRICING.yearly.amount / 12),
          savings: this.PRICING.yearly.savings,
          savingsLabel: `Tiết kiệm ${this.formatPrice(this.PRICING.yearly.savings)}`,
          recommended: true,
        },
      ],
      freeTier: {
        name: "Miễn phí",
        price: 0,
        currency: "VND",
        features: this.FEATURE_LIMITS.free,
      },
    };
  }

  /**
   * Auto-expire subscriptions (called by cron job)
   */
  static async autoExpireSubscriptions() {
    const now = new Date();

    // Find all premium users with expired subscriptions
    const expiredUsers = await User.find({
      "subscription.tier": "premium",
      "subscription.expiryDate": { $lte: now },
    });

    let expiredCount = 0;

    for (const user of expiredUsers) {
      user.downgradeToFree("Subscription expired (auto)");
      await user.save();

      // Update usage limits
      await UsageLimit.updateUserLimits(user._id, "free");

      expiredCount++;
    }

    console.log(`[SubscriptionService] Auto-expired ${expiredCount} premium subscriptions`);

    return {
      expiredCount,
      timestamp: now,
    };
  }

  /**
   * Get subscription history for a user
   */
  static async getSubscriptionHistory(userId, limit = 10) {
    const user = await User.findById(userId).select("subscriptionHistory");

    if (!user) {
      throw new Error("User not found");
    }

    // Sort by most recent first
    const history = user.subscriptionHistory
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice(0, limit);

    return history;
  }

  /**
   * Check if user can create more budgets
   */
  static async canCreateBudget(userId, currentCount) {
    const limits = await this.getFeatureLimits(userId);
    return currentCount < limits.limits.maxBudgets;
  }

  /**
   * Check if user can create more savings goals
   */
  static async canCreateSavingsGoal(userId, currentCount) {
    const limits = await this.getFeatureLimits(userId);
    return currentCount < limits.limits.maxSavingsGoals;
  }

  /**
   * Check if user can use OCR
   */
  static async canUseOCR(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) throw new Error("User not found");

    const tier = user.subscription.tier;
    return await UsageLimit.checkOCRLimit(userId, tier);
  }

  /**
   * Check if user can use AI Analysis
   */
  static async canUseAIAnalysis(userId) {
    const user = await User.findById(userId).select("subscription");
    if (!user) throw new Error("User not found");

    return {
      allowed: user.isPremium(),
      tier: user.subscription.tier,
      premiumRequired: true,
    };
  }

  /**
   * Helper: Get days remaining until expiry
   */
  static getDaysRemaining(expiryDate) {
    if (!expiryDate) return null;

    const now = new Date();
    const expiry = new Date(expiryDate);
    const diffTime = expiry - now;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays > 0 ? diffDays : 0;
  }

  /**
   * Helper: Format price for display
   */
  static formatPrice(amount) {
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(amount);
  }

  /**
   * Get subscription stats for admin dashboard
   */
  static async getSubscriptionStats() {
    const [totalUsers, freeUsers, premiumUsers, activeUsers, expiredUsers] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ "subscription.tier": "free" }),
      User.countDocuments({ "subscription.tier": "premium" }),
      User.countDocuments({
        "subscription.tier": "premium",
        "subscription.status": "active",
      }),
      User.countDocuments({
        "subscription.tier": "premium",
        "subscription.status": "expired",
      }),
    ]);

    // Calculate revenue (mock - for future payment integration)
    const monthlyRevenue = await User.aggregate([
      {
        $match: {
          "subscription.tier": "premium",
          "subscription.price.duration": "monthly",
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: "$subscription.price.amount" },
        },
      },
    ]);

    const yearlyRevenue = await User.aggregate([
      {
        $match: {
          "subscription.tier": "premium",
          "subscription.price.duration": "yearly",
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: "$subscription.price.amount" },
        },
      },
    ]);

    const monthlyRev = monthlyRevenue[0]?.total || 0;
    const yearlyRev = yearlyRevenue[0]?.total || 0;

    return {
      users: {
        total: totalUsers,
        free: freeUsers,
        premium: premiumUsers,
        active: activeUsers,
        expired: expiredUsers,
      },
      revenue: {
        monthly: monthlyRev,
        yearly: yearlyRev,
        total: monthlyRev + yearlyRev,
        formatted: {
          monthly: this.formatPrice(monthlyRev),
          yearly: this.formatPrice(yearlyRev),
          total: this.formatPrice(monthlyRev + yearlyRev),
        },
      },
      conversionRate: totalUsers > 0 ? ((premiumUsers / totalUsers) * 100).toFixed(2) : 0,
    };
  }
}

export default SubscriptionService;
