import express from "express";
import {
  getSubscriptionStatus,
  getFeatureLimits,
  getUsageStats,
  getPricing,
  upgradeToPremium,
  downgradeToFree,
  getSubscriptionHistory,
  getSubscriptionStats,
} from "../controllers/subscriptionController.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

/**
 * All routes require authentication
 */

// @route   GET /api/subscription/status
// @desc    Get current subscription status
// @access  Private
router.get("/status", authenticate, getSubscriptionStatus);

// @route   GET /api/subscription/features
// @desc    Get feature limits for current user
// @access  Private
router.get("/features", authenticate, getFeatureLimits);

// @route   GET /api/subscription/usage
// @desc    Get usage statistics (OCR, AI, etc.)
// @access  Private
router.get("/usage", authenticate, getUsageStats);

// @route   GET /api/subscription/pricing
// @desc    Get pricing information for all plans
// @access  Public (no auth required)
router.get("/pricing", getPricing);

// @route   GET /api/subscription/history
// @desc    Get subscription history
// @access  Private
router.get("/history", authenticate, getSubscriptionHistory);

// @route   POST /api/subscription/upgrade
// @desc    Upgrade to premium (manual - for testing)
// @access  Private (Admin only in production)
router.post("/upgrade", authenticate, upgradeToPremium);

// @route   POST /api/subscription/downgrade
// @desc    Downgrade to free tier
// @access  Private
router.post("/downgrade", authenticate, downgradeToFree);

// @route   GET /api/subscription/stats
// @desc    Get subscription statistics (admin)
// @access  Private (Admin only)
router.get("/stats", authenticate, getSubscriptionStats);

export default router;
