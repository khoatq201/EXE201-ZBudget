import express from "express";
import {
  getDashboardSummary,
  getQuickStats,
  getAllTransactions,
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
 * @route   GET /api/dashboard/transactions
 * @desc    Get all transactions with filtering
 * @access  Private
 * @query   type - all|income|expense (default: all)
 * @query   startDate - ISO date string (optional)
 * @query   endDate - ISO date string (optional)
 * @query   limit - number of transactions to return (optional)
 * @query   skip - number of transactions to skip for pagination (optional)
 */
router.get("/transactions", getAllTransactions);

/**
 * @route   GET /api/dashboard/quick-stats
 * @desc    Get quick financial stats
 * @access  Private
 */
router.get("/quick-stats", getQuickStats);

export default router;
