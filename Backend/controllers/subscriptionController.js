import SubscriptionService from "../services/subscriptionService.js";
import UsageService from "../services/usageService.js";

/**
 * Subscription Controller
 *
 * Handles all subscription-related HTTP requests
 */

/**
 * @desc    Get current subscription status
 * @route   GET /api/subscription/status
 * @access  Private
 */
export const getSubscriptionStatus = async (req, res) => {
  try {
    const userId = req.userId;

    const status = await SubscriptionService.checkSubscriptionStatus(userId);

    res.status(200).json({
      success: true,
      data: status,
    });
  } catch (error) {
    console.error("[Subscription Controller] Get status error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy trạng thái subscription",
      error: error.message,
    });
  }
};

/**
 * @desc    Get feature limits for current user
 * @route   GET /api/subscription/features
 * @access  Private
 */
export const getFeatureLimits = async (req, res) => {
  try {
    const userId = req.userId;

    const limits = await SubscriptionService.getFeatureLimits(userId);

    res.status(200).json({
      success: true,
      data: limits,
    });
  } catch (error) {
    console.error("[Subscription Controller] Get limits error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy giới hạn tính năng",
      error: error.message,
    });
  }
};

/**
 * @desc    Get usage statistics
 * @route   GET /api/subscription/usage
 * @access  Private
 */
export const getUsageStats = async (req, res) => {
  try {
    const userId = req.userId;

    const stats = await UsageService.getUserUsageStats(userId);

    // Add time until reset
    const timeUntilReset = UsageService.getTimeUntilReset();

    res.status(200).json({
      success: true,
      data: {
        ...stats,
        resetTime: {
          ...stats.resetTime,
          countdown: timeUntilReset,
        },
      },
    });
  } catch (error) {
    console.error("[Subscription Controller] Get usage stats error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thống kê sử dụng",
      error: error.message,
    });
  }
};

/**
 * @desc    Get pricing information
 * @route   GET /api/subscription/pricing
 * @access  Public
 */
export const getPricing = async (req, res) => {
  try {
    const pricing = SubscriptionService.getPricing();

    res.status(200).json({
      success: true,
      data: pricing,
    });
  } catch (error) {
    console.error("[Subscription Controller] Get pricing error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thông tin giá",
      error: error.message,
    });
  }
};

/**
 * @desc    Upgrade to premium
 * @route   POST /api/subscription/upgrade
 * @access  Private (Admin only in production)
 */
export const upgradeToPremium = async (req, res) => {
  try {
    const userId = req.userId;
    const { duration = "monthly" } = req.body;

    // Validate duration
    if (!["monthly", "yearly"].includes(duration)) {
      return res.status(400).json({
        success: false,
        message: "Loại gói không hợp lệ. Chỉ chấp nhận 'monthly' hoặc 'yearly'",
      });
    }

    const result = await SubscriptionService.upgradeToPremium(
      userId,
      duration,
      "user" // In production with payment, this would be "payment_gateway"
    );

    res.status(200).json({
      success: true,
      message: result.message,
      data: result.subscription,
    });
  } catch (error) {
    console.error("[Subscription Controller] Upgrade error:", error);

    if (error.message === "User is already premium") {
      return res.status(400).json({
        success: false,
        message: "Bạn đã là Premium rồi",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi nâng cấp subscription",
      error: error.message,
    });
  }
};

/**
 * @desc    Downgrade to free tier
 * @route   POST /api/subscription/downgrade
 * @access  Private
 */
export const downgradeToFree = async (req, res) => {
  try {
    const userId = req.userId;
    const { reason = "User requested" } = req.body;

    const result = await SubscriptionService.downgradeToFree(
      userId,
      reason,
      "user"
    );

    res.status(200).json({
      success: true,
      message: result.message,
      data: result.subscription,
    });
  } catch (error) {
    console.error("[Subscription Controller] Downgrade error:", error);

    if (error.message === "User is already on free tier") {
      return res.status(400).json({
        success: false,
        message: "Bạn đang dùng gói Miễn phí rồi",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi hạ cấp subscription",
      error: error.message,
    });
  }
};

/**
 * @desc    Get subscription history
 * @route   GET /api/subscription/history
 * @access  Private
 */
export const getSubscriptionHistory = async (req, res) => {
  try {
    const userId = req.userId;
    const limit = parseInt(req.query.limit) || 10;

    const history = await SubscriptionService.getSubscriptionHistory(
      userId,
      limit
    );

    res.status(200).json({
      success: true,
      data: {
        history,
        count: history.length,
      },
    });
  } catch (error) {
    console.error("[Subscription Controller] Get history error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy lịch sử subscription",
      error: error.message,
    });
  }
};

/**
 * @desc    Get subscription statistics (admin)
 * @route   GET /api/subscription/stats
 * @access  Private (Admin only)
 */
export const getSubscriptionStats = async (req, res) => {
  try {
    // TODO: Add admin check middleware in production
    // For now, anyone can access for testing

    const stats = await SubscriptionService.getSubscriptionStats();
    const usageStats = await UsageService.getTotalUsageStats();

    res.status(200).json({
      success: true,
      data: {
        subscription: stats,
        usage: usageStats,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error("[Subscription Controller] Get stats error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thống kê subscription",
      error: error.message,
    });
  }
};

export default {
  getSubscriptionStatus,
  getFeatureLimits,
  getUsageStats,
  getPricing,
  upgradeToPremium,
  downgradeToFree,
  getSubscriptionHistory,
  getSubscriptionStats,
};
