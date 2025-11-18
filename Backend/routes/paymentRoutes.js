import express from "express";
import {
  createPaymentQR,
  getMyPayments,
  getPaymentDetails,
  cancelPayment,
} from "../controllers/paymentController.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

/**
 * All routes require authentication
 */

// @route   POST /api/payment/create
// @desc    Create payment QR request
// @access  Private
router.post("/create", authenticate, createPaymentQR);

// @route   GET /api/payment/my-payments
// @desc    Get user's payment history
// @access  Private
router.get("/my-payments", authenticate, getMyPayments);

// @route   GET /api/payment/:id
// @desc    Get payment details
// @access  Private
router.get("/:id", authenticate, getPaymentDetails);

// @route   POST /api/payment/:id/cancel
// @desc    Cancel payment
// @access  Private
router.post("/:id/cancel", authenticate, cancelPayment);

export default router;
