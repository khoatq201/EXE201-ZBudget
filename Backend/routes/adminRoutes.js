import express from "express";
import {
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
} from "../controllers/adminController.js";

const router = express.Router();

/**
 * All routes are public for localhost development
 * No authentication required
 */

// Dashboard
// @route   GET /api/admin/dashboard
// @desc    Get dashboard overview
// @access  Public (localhost only)
router.get("/dashboard", getDashboardOverview);

// @route   GET /api/admin/stats
// @desc    Get dashboard stats (alias for dashboard)
// @access  Public (localhost only)
router.get("/stats", getDashboardOverview);

// @route   GET /api/admin/recent-activity
// @desc    Get recent activity
// @access  Public (localhost only)
router.get("/recent-activity", getRecentActivity);

// Payments Management
// @route   GET /api/admin/payments/pending
// @desc    Get pending payments
// @access  Public (localhost only)
router.get("/payments/pending", getPendingPayments);

// @route   GET /api/admin/payments
// @desc    Get all payments with filters
// @access  Public (localhost only)
router.get("/payments", getAllPayments);

// @route   POST /api/admin/payments/:id/approve
// @desc    Approve payment
// @access  Public (localhost only)
router.post("/payments/:id/approve", approvePayment);

// @route   POST /api/admin/payments/:id/reject
// @desc    Reject payment
// @access  Public (localhost only)
router.post("/payments/:id/reject", rejectPayment);

// Statistics
// @route   GET /api/admin/stats/payments
// @desc    Get payment statistics
// @access  Public (localhost only)
router.get("/stats/payments", getPaymentStats);

// @route   GET /api/admin/stats/subscriptions
// @desc    Get subscription statistics
// @access  Public (localhost only)
router.get("/stats/subscriptions", getSubscriptionStats);

// User Management
// @route   GET /api/admin/users
// @desc    Get all users with filters
// @access  Public (localhost only)
router.get("/users", getAllUsers);

// @route   POST /api/admin/users/:id/activate-premium
// @desc    Manually activate premium for user
// @access  Public (localhost only)
router.post("/users/:id/activate-premium", manualActivatePremium);

export default router;
