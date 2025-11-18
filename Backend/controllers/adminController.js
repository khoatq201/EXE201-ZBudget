import PaymentService from "../services/paymentService.js";
import SubscriptionService from "../services/subscriptionService.js";
import User from "../models/User.js";

/**
 * Admin Controller
 * Handles admin-only operations
 */

/**
 * @desc    Get pending payments
 * @route   GET /api/admin/payments/pending
 * @access  Private (Admin only)
 */
export const getPendingPayments = async (req, res) => {
  try {
    const payments = await PaymentService.getPendingPayments();

    res.status(200).json({
      success: true,
      data: {
        payments,
        count: payments.length,
      },
    });
  } catch (error) {
    console.error("[Admin Controller] Get pending payments error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy danh sách thanh toán chờ duyệt",
      error: error.message,
    });
  }
};

/**
 * @desc    Get all payments with filters
 * @route   GET /api/admin/payments
 * @access  Private (Admin only)
 */
export const getAllPayments = async (req, res) => {
  try {
    const { status, page, limit } = req.query;

    const result = await PaymentService.getAllPayments({
      status,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("[Admin Controller] Get all payments error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy danh sách thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Approve payment
 * @route   POST /api/admin/payments/:id/approve
 * @access  Public (localhost only)
 */
export const approvePayment = async (req, res) => {
  try {
    const adminUserId = null; // No auth required for localhost
    const { id } = req.params;

    const result = await PaymentService.approvePayment(id, adminUserId);

    res.status(200).json(result);
  } catch (error) {
    console.error("[Admin Controller] Approve payment error:", error);

    if (error.message === "Payment not found") {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thanh toán",
      });
    }

    if (error.message === "Payment is not pending") {
      return res.status(400).json({
        success: false,
        message: "Thanh toán không ở trạng thái chờ duyệt",
      });
    }

    if (error.message === "User is already premium") {
      return res.status(400).json({
        success: false,
        message: "User đã là Premium rồi",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi duyệt thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Reject payment
 * @route   POST /api/admin/payments/:id/reject
 * @access  Public (localhost only)
 */
export const rejectPayment = async (req, res) => {
  try {
    const adminUserId = null; // No auth required for localhost
    const { id } = req.params;
    const { reason } = req.body;

    const result = await PaymentService.rejectPayment(id, adminUserId, reason);

    res.status(200).json(result);
  } catch (error) {
    console.error("[Admin Controller] Reject payment error:", error);

    if (error.message === "Payment not found") {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thanh toán",
      });
    }

    if (error.message === "Payment is not pending") {
      return res.status(400).json({
        success: false,
        message: "Thanh toán không ở trạng thái chờ duyệt",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi từ chối thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Get payment statistics
 * @route   GET /api/admin/stats/payments
 * @access  Private (Admin only)
 */
export const getPaymentStats = async (req, res) => {
  try {
    const stats = await PaymentService.getPaymentStats();

    res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("[Admin Controller] Get payment stats error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thống kê thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Get subscription statistics
 * @route   GET /api/admin/stats/subscriptions
 * @access  Private (Admin only)
 */
export const getSubscriptionStats = async (req, res) => {
  try {
    const stats = await SubscriptionService.getSubscriptionStats();

    res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error("[Admin Controller] Get subscription stats error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thống kê subscription",
      error: error.message,
    });
  }
};

/**
 * @desc    Get all users with filters
 * @route   GET /api/admin/users
 * @access  Private (Admin only)
 */
export const getAllUsers = async (req, res) => {
  try {
    const { tier, page = 1, limit = 20, search } = req.query;

    // Build query
    const query = {};
    if (tier) {
      query["subscription.tier"] = tier;
    }
    if (search) {
      query.$or = [
        { email: { $regex: search, $options: "i" } },
        { "profile.name": { $regex: search, $options: "i" } },
      ];
    }

    const users = await User.find(query)
      .select("email profile subscription createdAt lastLogin")
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        users,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total,
      },
    });
  } catch (error) {
    console.error("[Admin Controller] Get all users error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy danh sách users",
      error: error.message,
    });
  }
};

/**
 * @desc    Manually activate premium for user
 * @route   POST /api/admin/users/:id/activate-premium
 * @access  Private (Admin only)
 */
export const manualActivatePremium = async (req, res) => {
  try {
    const { id } = req.params;
    const { duration = "monthly" } = req.body;

    // Validate duration
    if (!["monthly", "yearly"].includes(duration)) {
      return res.status(400).json({
        success: false,
        message: "Duration không hợp lệ",
      });
    }

    const result = await SubscriptionService.upgradeToPremium(
      id,
      duration,
      "admin"
    );

    res.status(200).json({
      success: true,
      message: "Đã kích hoạt Premium thành công",
      data: result,
    });
  } catch (error) {
    console.error("[Admin Controller] Manual activate premium error:", error);

    if (error.message === "User not found") {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy user",
      });
    }

    if (error.message === "User is already premium") {
      return res.status(400).json({
        success: false,
        message: "User đã là Premium rồi",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi kích hoạt Premium",
      error: error.message,
    });
  }
};

/**
 * @desc    Get dashboard overview
 * @route   GET /api/admin/dashboard
 * @access  Public (localhost only)
 */
export const getDashboardOverview = async (req, res) => {
  try {
    // Get all stats in parallel
    const [paymentStats, subscriptionStats, userCount, premiumCount] =
      await Promise.all([
        PaymentService.getPaymentStats(),
        SubscriptionService.getSubscriptionStats(),
        User.countDocuments(),
        User.countDocuments({ "subscription.tier": "premium" }),
      ]);

    // Calculate monthly revenue (completed payments this month)
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const Payment = (await import("../models/Payment.js")).default;
    const monthlyPayments = await Payment.aggregate([
      {
        $match: {
          status: "completed",
          createdAt: { $gte: startOfMonth },
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: "$amount" },
        },
      },
    ]);

    const monthlyRevenue = monthlyPayments[0]?.total || 0;
    const pendingPayments = await Payment.countDocuments({ status: "pending" });

    res.status(200).json({
      success: true,
      totalUsers: userCount,
      premiumUsers: premiumCount,
      freeUsers: userCount - premiumCount,
      pendingPayments: pendingPayments,
      monthlyRevenue: monthlyRevenue,
      payments: paymentStats,
      subscriptions: subscriptionStats,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("[Admin Controller] Get dashboard overview error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thông tin dashboard",
      error: error.message,
    });
  }
};

/**
 * @desc    Get recent activity
 * @route   GET /api/admin/recent-activity
 * @access  Public (localhost only)
 */
export const getRecentActivity = async (req, res) => {
  try {
    const Payment = (await import("../models/Payment.js")).default;

    // Get recent payments (last 10)
    const recentPayments = await Payment.find()
      .sort({ createdAt: -1 })
      .limit(10)
      .populate("userId", "email profile.name");

    // Get recent users (last 10)
    const recentUsers = await User.find()
      .sort({ createdAt: -1 })
      .limit(10)
      .select("email profile.name subscription.tier createdAt");

    // Combine and format activities
    const activities = [];

    // Add payment activities
    recentPayments.forEach((payment) => {
      const userName = payment.userId?.profile?.name || payment.userId?.email || "Unknown";
      const planText = payment.planType === "monthly" ? "Tháng" : "Năm";
      let message = "";
      let time = new Date(payment.createdAt).toLocaleString("vi-VN");

      if (payment.status === "pending") {
        message = `${userName} đã tạo thanh toán gói ${planText} - ${(payment.amount / 1000).toFixed(0)}k VND`;
      } else if (payment.status === "completed") {
        message = `Thanh toán gói ${planText} của ${userName} đã được duyệt`;
      } else if (payment.status === "rejected") {
        message = `Thanh toán gói ${planText} của ${userName} đã bị từ chối`;
      } else if (payment.status === "cancelled") {
        message = `Thanh toán gói ${planText} của ${userName} đã bị hủy`;
      }

      activities.push({
        type: "payment",
        message,
        time,
        timestamp: payment.createdAt,
      });
    });

    // Add user registration activities
    recentUsers.forEach((user) => {
      const userName = user.profile?.name || user.email;
      const tier = user.subscription?.tier === "premium" ? "Premium" : "Free";

      activities.push({
        type: "user",
        message: `User mới: ${userName} (${tier})`,
        time: new Date(user.createdAt).toLocaleString("vi-VN"),
        timestamp: user.createdAt,
      });
    });

    // Sort by timestamp (most recent first)
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Return top 15 activities
    res.status(200).json({
      success: true,
      data: activities.slice(0, 15),
    });
  } catch (error) {
    console.error("[Admin Controller] Get recent activity error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy hoạt động gần đây",
      error: error.message,
    });
  }
};

export default {
  getPendingPayments,
  getAllPayments,
  approvePayment,
  rejectPayment,
  getPaymentStats,
  getSubscriptionStats,
  getAllUsers,
  manualActivatePremium,
  getDashboardOverview,
  getRecentActivity,
};
