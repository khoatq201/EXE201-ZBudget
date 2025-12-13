import User from "../models/User.js";
import UsageLimit from "../models/UsageLimit.js";
import SubscriptionService from "../services/subscriptionService.js";

/**
 * Premium Middleware
 *
 * Middleware functions for enforcing premium features and usage limits:
 * 1. requirePremium - Blocks access if user is not premium
 * 2. checkFeatureLimit - Checks if user can use a feature (generic)
 * 3. checkBudgetLimit - Checks if user can create more budgets
 * 4. checkSavingsGoalLimit - Checks if user can create more savings goals
 * 5. checkOCRLimit - Checks if user can scan more receipts
 * 6. trackOCRUsage - Increments OCR usage counter after successful scan
 * 7. trackAIUsage - Increments AI analysis usage counter
 */

/**
 * Require Premium - Blocks non-premium users
 */
export const requirePremium = async (req, res, next) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized - User ID not found",
      });
    }

    const user = await User.findById(userId).select("subscription email");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log(
      `[Premium Check] User: ${user.email}, Tier: ${
        user.subscription.tier
      }, isPremium: ${user.isPremium()}`
    );

    // Check if premium and active
    if (!user.isPremium()) {
      console.log(
        `[Premium Check] ❌ Access denied for ${user.email} - Not premium`
      );
      return res.status(403).json({
        success: false,
        message: "Tính năng này chỉ dành cho người dùng Premium",
        upgradeRequired: true,
        currentTier: user.subscription.tier,
        requiredTier: "premium",
        upgradeTo: "/api/subscription/pricing",
      });
    }

    console.log(`[Premium Check] ✅ Access granted for ${user.email}`);

    // Check if subscription has expired
    const hasExpired = user.checkSubscriptionExpiry();
    if (hasExpired) {
      await user.save();

      return res.status(403).json({
        success: false,
        message: "Gói Premium của bạn đã hết hạn. Vui lòng gia hạn!",
        upgradeRequired: true,
        renewRequired: true,
        currentTier: "free",
      });
    }

    // Attach subscription info to request
    req.subscription = user.subscription;
    req.isPremium = true;

    next();
  } catch (error) {
    console.error("[Premium Middleware] Error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

/**
 * Check Budget Creation Limit
 */
export const checkBudgetLimit = async (req, res, next) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId).select("subscription");
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Get current budget count (active budgets only)
    const Budget = (await import("../models/Budget.js")).default;
    const activeBudgets = await Budget.countDocuments({
      userId,
      isActive: true,
    });

    const limits = user.getFeatureLimits();
    const canCreate = activeBudgets < limits.maxBudgets;

    if (!canCreate) {
      return res.status(403).json({
        success: false,
        message:
          user.subscription.tier === "free"
            ? `Gói Miễn phí chỉ cho phép tạo tối đa ${limits.maxBudgets} ngân sách. Nâng cấp Premium để tạo thêm!`
            : `Bạn đã đạt giới hạn ${limits.maxBudgets} ngân sách.`,
        upgradeRequired: user.subscription.tier === "free",
        currentCount: activeBudgets,
        limit: limits.maxBudgets,
        tier: user.subscription.tier,
      });
    }

    // Attach info to request
    req.budgetCount = activeBudgets;
    req.budgetLimit = limits.maxBudgets;

    next();
  } catch (error) {
    console.error("[Budget Limit Middleware] Error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

/**
 * Check Savings Goal Creation Limit
 */
export const checkSavingsGoalLimit = async (req, res, next) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId).select("subscription");
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Get current savings goal count (active goals only)
    const SavingsGoal = (await import("../models/SavingsGoal.js")).default;
    const activeGoals = await SavingsGoal.countDocuments({
      userId,
      status: "active",
    });

    const limits = user.getFeatureLimits();
    const canCreate = activeGoals < limits.maxSavingsGoals;

    if (!canCreate) {
      return res.status(403).json({
        success: false,
        message:
          user.subscription.tier === "free"
            ? `Gói Miễn phí chỉ cho phép tạo tối đa ${limits.maxSavingsGoals} mục tiêu tiết kiệm. Nâng cấp Premium để tạo thêm!`
            : `Bạn đã đạt giới hạn ${limits.maxSavingsGoals} mục tiêu tiết kiệm.`,
        upgradeRequired: user.subscription.tier === "free",
        currentCount: activeGoals,
        limit: limits.maxSavingsGoals,
        tier: user.subscription.tier,
      });
    }

    // Attach info to request
    req.savingsGoalCount = activeGoals;
    req.savingsGoalLimit = limits.maxSavingsGoals;

    next();
  } catch (error) {
    console.error("[Savings Goal Limit Middleware] Error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

/**
 * Check OCR Scan Limit
 */
export const checkOCRLimit = async (req, res, next) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId).select("subscription");
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const tier = user.subscription.tier;
    const usage = await UsageLimit.checkOCRLimit(userId, tier);

    if (!usage.allowed) {
      return res.status(403).json({
        success: false,
        message: `Bạn đã hết lượt quét hóa đơn hôm nay (${usage.count}/${usage.limit}). Nâng cấp Premium để quét không giới hạn!`,
        upgradeRequired: true,
        quotaExceeded: true,
        currentUsage: usage.count,
        limit: usage.limit,
        remaining: 0,
        tier: tier,
        resetTime: "00:00 (giờ Việt Nam)",
      });
    }

    // Attach usage info to request
    req.ocrUsage = usage;

    next();
  } catch (error) {
    console.error("[OCR Limit Middleware] Error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

/**
 * Track OCR Usage (call AFTER successful OCR)
 */
export const trackOCRUsage = async (req, res, next) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId).select("subscription");
    if (!user) {
      // Don't block response, just log error
      console.error("[Track OCR Usage] User not found:", userId);
      return next();
    }

    const tier = user.subscription.tier;
    await UsageLimit.incrementOCRCount(userId, tier);

    // Get updated usage for response
    const updatedUsage = await UsageLimit.getUserUsageStats(userId, tier);
    req.updatedUsage = updatedUsage;

    next();
  } catch (error) {
    console.error("[Track OCR Usage] Error:", error);
    // Don't block the response, tracking is optional
    next();
  }
};

/**
 * Track AI Analysis Usage (call AFTER successful AI analysis)
 */
export const trackAIUsage = async (req, res, next) => {
  try {
    const userId = req.userId;

    await UsageLimit.incrementAICount(userId);

    next();
  } catch (error) {
    console.error("[Track AI Usage] Error:", error);
    // Don't block the response
    next();
  }
};

/**
 * Add usage info to response (helper middleware)
 */
export const attachUsageInfo = async (req, res, next) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return next();
    }

    const user = await User.findById(userId).select("subscription");
    if (!user) {
      return next();
    }

    const tier = user.subscription.tier;
    const usage = await UsageLimit.getUserUsageStats(userId, tier);

    // Attach to request for use in response
    req.usageInfo = {
      tier,
      isPremium: user.isPremium(),
      ocr: usage.usage.ocr,
      aiAnalysis: usage.usage.aiAnalysis,
    };

    next();
  } catch (error) {
    console.error("[Attach Usage Info] Error:", error);
    // Don't block, just skip
    next();
  }
};

/**
 * Generic feature limit checker (for future features)
 */
export const checkFeatureLimit = (feature, getFreeLimit, getPremiumLimit) => {
  return async (req, res, next) => {
    try {
      const userId = req.userId;

      const user = await User.findById(userId).select("subscription");
      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      const isPremium = user.isPremium();
      const limit = isPremium ? getPremiumLimit() : getFreeLimit();

      // Check current usage (implement based on feature)
      // This is a generic template, specific features should implement their own middleware

      req.featureLimit = {
        feature,
        isPremium,
        limit,
      };

      next();
    } catch (error) {
      console.error(`[Feature Limit ${feature}] Error:`, error);
      return res.status(500).json({
        success: false,
        message: "Internal server error",
        error: error.message,
      });
    }
  };
};

export default {
  requirePremium,
  checkBudgetLimit,
  checkSavingsGoalLimit,
  checkOCRLimit,
  trackOCRUsage,
  trackAIUsage,
  attachUsageInfo,
  checkFeatureLimit,
};
