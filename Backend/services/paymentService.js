import crypto from "crypto";
import Payment from "../models/Payment.js";
import User from "../models/User.js";
import SubscriptionService from "./subscriptionService.js";

/**
 * Payment Service
 * Handles payment creation, approval, and management
 */
class PaymentService {
  // VietQR Configuration
  static VIETQR_API_URL = "https://img.vietqr.io/image";
  static BANK_BIN = "970441"; // VIB (Ngân hàng Quốc tế Việt Nam)
  static ACCOUNT_NUMBER = process.env.VCB_ACCOUNT_NUMBER || "942601202";
  static ACCOUNT_NAME = process.env.VCB_ACCOUNT_NAME || "NGUYEN MINH QUAN";
  static TEMPLATE = "compact";

  /**
   * Generate unique reference code
   * Format: ZB{M|Y}{userId_last6}{random3}
   * Example: ZBMY654ABC
   */
  static generateReferenceCode(userId, planType) {
    const planPrefix = planType === "yearly" ? "Y" : "M";
    const userIdStr = userId.toString();
    const userSuffix = userIdStr.slice(-6).padStart(6, "0");
    const random = crypto.randomBytes(3).toString("hex").toUpperCase();

    return `ZB${planPrefix}${userSuffix}${random}`;
  }

  /**
   * Generate VietQR URL
   */
  static generateQRCodeUrl(amount, referenceCode) {
    const params = new URLSearchParams({
      amount: amount.toString(),
      addInfo: referenceCode,
      accountName: this.ACCOUNT_NAME,
    });

    return `${this.VIETQR_API_URL}/${this.BANK_BIN}-${this.ACCOUNT_NUMBER}-${this.TEMPLATE}.png?${params.toString()}`;
  }

  /**
   * Create payment request
   */
  static async createPayment(userId, planType) {
    // Validate user
    const user = await User.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    // Check if user already premium
    if (user.isPremium()) {
      throw new Error("User is already premium");
    }

    // Get pricing directly from PRICING config
    const plan = SubscriptionService.PRICING[planType];

    if (!plan) {
      console.log('❌ Plan not found for planType:', planType);
      console.log('❌ Available plans:', Object.keys(SubscriptionService.PRICING));
      throw new Error("Invalid plan type");
    }

    console.log('✅ Plan found:', plan);

    // Generate reference code
    const referenceCode = this.generateReferenceCode(userId, planType);

    // Generate QR code URL
    const qrCodeUrl = this.generateQRCodeUrl(plan.amount, referenceCode);

    // Create payment record
    const payment = await Payment.create({
      userId,
      referenceCode,
      amount: plan.amount,
      planType,
      qrCodeUrl,
      bankAccount: {
        accountNumber: this.ACCOUNT_NUMBER,
        bankName: "VIB",
        accountName: this.ACCOUNT_NAME,
      },
      status: "pending",
    });

    return payment;
  }

  /**
   * Get pending payments (for admin)
   */
  static async getPendingPayments() {
    return Payment.getPendingPayments();
  }

  /**
   * Get all payments with filters
   */
  static async getAllPayments(filters = {}) {
    const { status, page = 1, limit = 20 } = filters;

    const query = status ? { status } : {};

    const payments = await Payment.find(query)
      .populate("userId", "email profile subscription")
      .populate("approvedBy", "email profile.name")
      .populate("rejectedBy", "email profile.name")
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Payment.countDocuments(query);

    return {
      payments,
      totalPages: Math.ceil(total / limit),
      currentPage: parseInt(page),
      total,
    };
  }

  /**
   * Get payments by user
   */
  static async getPaymentsByUser(userId) {
    return Payment.getPaymentsByUser(userId);
  }

  /**
   * Approve payment and activate premium
   */
  static async approvePayment(paymentId, adminUserId) {
    const payment = await Payment.findById(paymentId);

    if (!payment) {
      throw new Error("Payment not found");
    }

    if (payment.status !== "pending") {
      throw new Error("Payment is not pending");
    }

    // Update payment status
    payment.status = "completed";
    if (adminUserId) {
      payment.approvedBy = adminUserId;
    }
    payment.approvedAt = new Date();
    await payment.save();

    // Activate premium subscription
    const result = await SubscriptionService.upgradeToPremium(
      payment.userId,
      payment.planType,
      "admin"
    );

    return {
      success: true,
      message: "Payment approved and premium activated",
      payment,
      subscription: result.subscription,
    };
  }

  /**
   * Reject payment
   */
  static async rejectPayment(paymentId, adminUserId, reason) {
    const payment = await Payment.findById(paymentId);

    if (!payment) {
      throw new Error("Payment not found");
    }

    if (payment.status !== "pending") {
      throw new Error("Payment is not pending");
    }

    // Update payment status
    payment.status = "rejected";
    if (adminUserId) {
      payment.rejectedBy = adminUserId;
    }
    payment.rejectedAt = new Date();
    payment.rejectionReason = reason || "Admin rejected";
    await payment.save();

    return {
      success: true,
      message: "Payment rejected",
      payment,
    };
  }

  /**
   * Cancel payment (by user)
   */
  static async cancelPayment(paymentId, userId) {
    const payment = await Payment.findById(paymentId);

    if (!payment) {
      throw new Error("Payment not found");
    }

    // Check ownership
    if (payment.userId.toString() !== userId.toString()) {
      throw new Error("Unauthorized");
    }

    if (!payment.canCancel()) {
      throw new Error("Cannot cancel this payment");
    }

    payment.status = "cancelled";
    await payment.save();

    return {
      success: true,
      message: "Payment cancelled",
      payment,
    };
  }

  /**
   * Get payment statistics
   */
  static async getPaymentStats() {
    const stats = await Payment.getPaymentStats();

    // Total revenue (completed payments only)
    const completedPayments = await Payment.find({ status: "completed" });
    const totalRevenue = completedPayments.reduce(
      (sum, p) => sum + p.amount,
      0
    );

    // Count by status
    const pending = await Payment.countDocuments({ status: "pending" });
    const completed = await Payment.countDocuments({ status: "completed" });
    const cancelled = await Payment.countDocuments({ status: "cancelled" });
    const rejected = await Payment.countDocuments({ status: "rejected" });

    return {
      totalPayments: pending + completed + cancelled + rejected,
      pending,
      completed,
      cancelled,
      rejected,
      totalRevenue,
      stats,
    };
  }
}

export default PaymentService;
