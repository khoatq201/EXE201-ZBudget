import express from "express";
import {
  getDashboardSummary,
  getQuickStats,
} from "../controllers/dashboardController.js";
import { getDashboardSummarySimple } from "../controllers/dashboardController_simple.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

// Apply authentication to all dashboard routes
router.use(authenticate);

/**
 * @route   GET /api/dashboard/test
 * @desc    Simple test endpoint
 * @access  Private
 */
router.get("/test", getDashboardSummarySimple);

/**
 * @route   GET /api/dashboard/summary
 * @desc    Get complete dashboard data
 * @access  Private
 * @query   period - month|week|year (default: month)
 */
router.get("/summary", getDashboardSummary);

/**
 * @route   GET /api/dashboard/quick-stats
 * @desc    Get quick financial stats
 * @access  Private
 */
router.get("/quick-stats", getQuickStats);

export default router;
