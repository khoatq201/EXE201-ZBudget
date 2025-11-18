import PaymentService from "../services/paymentService.js";
import Payment from "../models/Payment.js";

/**
 * Payment Controller
 * Handles payment-related HTTP requests
 */

/**
 * @desc    Create payment QR request
 * @route   POST /api/payment/create
 * @access  Private
 */
export const createPaymentQR = async (req, res) => {
  try {
    const userId = req.userId;
    const { planType } = req.body;

    console.log('💳 [Payment Controller] Request body:', req.body);
    console.log('💳 [Payment Controller] planType received:', planType);
    console.log('💳 [Payment Controller] planType type:', typeof planType);

    // Validate plan type
    if (!planType || !["monthly", "yearly"].includes(planType)) {
      console.log('❌ [Payment Controller] Invalid planType!');
      return res.status(400).json({
        success: false,
        message: "Loại gói không hợp lệ",
      });
    }

    // Create payment
    const payment = await PaymentService.createPayment(userId, planType);

    res.status(201).json({
      success: true,
      message: "Tạo thanh toán thành công",
      data: {
        paymentId: payment._id,
        referenceCode: payment.referenceCode,
        amount: payment.amount,
        currency: payment.currency,
        planType: payment.planType,
        qrCodeUrl: payment.qrCodeUrl,
        bankAccount: payment.bankAccount,
        status: payment.status,
        createdAt: payment.createdAt,
        instructions:
          "Quét mã QR hoặc chuyển khoản với nội dung chính xác để được admin kích hoạt Premium",
      },
    });
  } catch (error) {
    console.error("[Payment Controller] Create payment error:", error);

    if (error.message === "User is already premium") {
      return res.status(400).json({
        success: false,
        message: "Bạn đã là Premium rồi",
      });
    }

    if (error.message === "Invalid plan type") {
      return res.status(400).json({
        success: false,
        message: "Loại gói không hợp lệ",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi tạo thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Get user's payments
 * @route   GET /api/payment/my-payments
 * @access  Private
 */
export const getMyPayments = async (req, res) => {
  try {
    const userId = req.userId;

    const payments = await PaymentService.getPaymentsByUser(userId);

    res.status(200).json({
      success: true,
      data: {
        payments,
        count: payments.length,
      },
    });
  } catch (error) {
    console.error("[Payment Controller] Get my payments error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy danh sách thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Get payment details
 * @route   GET /api/payment/:id
 * @access  Private
 */
export const getPaymentDetails = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const payment = await Payment.findById(id);

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thanh toán",
      });
    }

    // Check ownership
    if (payment.userId.toString() !== userId.toString()) {
      return res.status(403).json({
        success: false,
        message: "Bạn không có quyền xem thanh toán này",
      });
    }

    res.status(200).json({
      success: true,
      data: payment,
    });
  } catch (error) {
    console.error("[Payment Controller] Get payment details error:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thông tin thanh toán",
      error: error.message,
    });
  }
};

/**
 * @desc    Cancel payment
 * @route   POST /api/payment/:id/cancel
 * @access  Private
 */
export const cancelPayment = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const result = await PaymentService.cancelPayment(id, userId);

    res.status(200).json(result);
  } catch (error) {
    console.error("[Payment Controller] Cancel payment error:", error);

    if (error.message === "Payment not found") {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thanh toán",
      });
    }

    if (error.message === "Unauthorized") {
      return res.status(403).json({
        success: false,
        message: "Bạn không có quyền hủy thanh toán này",
      });
    }

    if (error.message === "Cannot cancel this payment") {
      return res.status(400).json({
        success: false,
        message: "Không thể hủy thanh toán này",
      });
    }

    res.status(500).json({
      success: false,
      message: "Lỗi khi hủy thanh toán",
      error: error.message,
    });
  }
};

export default {
  createPaymentQR,
  getMyPayments,
  getPaymentDetails,
  cancelPayment,
};
