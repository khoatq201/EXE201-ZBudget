import express from "express";
import {
  getTrendReport,
  getCategoryReport,
  getComparisonReport,
  getSpendingPatterns,
  getForecastReport,
} from "../controllers/reportController.js";
import { authenticate } from "../middleware/auth.js";
const router = express.Router();
// Apply authentication to all report routes
router.use(authenticate);
/**
 * @route   GET /api/reports/trend
 * @desc    Get income vs expense trend report
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   startDate - ISO date string (optional, for custom range)
 * @query   endDate - ISO date string (optional, for custom range)
 */
router.get("/trend", getTrendReport);
/**
 * @route   GET /api/reports/categories
 * @desc    Get category breakdown report
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   type - income|expense (default: expense)
 * @query   startDate - ISO date string (optional)
 * @query   endDate - ISO date string (optional)
 */
router.get("/categories", getCategoryReport);
/**
 * @route   GET /api/reports/comparison
 * @desc    Get period-over-period comparison report
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   compareCount - number of periods to compare (default: 3, max: 12)
 */
router.get("/comparison", getComparisonReport);
/**
 * @route   GET /api/reports/patterns
 * @desc    Get spending patterns analysis
 * @access  Private
 * @query   period - month|week|year (default: month)
 */
router.get("/patterns", getSpendingPatterns);
/**
 * @route   GET /api/reports/forecast
 * @desc    Get financial forecast based on historical data
 * @access  Private
 * @query   months - number of months to forecast (default: 3, max: 12)
 */
router.get("/forecast", getForecastReport);
export default router;