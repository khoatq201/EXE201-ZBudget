import express from "express";
import {
  createIncome,
  getIncomes,
  getIncomeById,
  updateIncome,
  deleteIncome,
  getIncomeStats,
} from "../controllers/incomeController.js";
import { authenticate, rateLimitGeneral } from "../middleware/auth.js";

const router = express.Router();

// Apply authentication to all income routes
router.use(authenticate);

// Apply general rate limiting
router.use(rateLimitGeneral());

/**
 * @route   POST /api/income
 * @desc    Create new income
 * @access  Private
 */
router.post("/", createIncome);

/**
 * @route   GET /api/income
 * @desc    Get all incomes with filters
 * @access  Private
 * @query   category, startDate, endDate, isRecurring, page, limit, sort
 */
router.get("/", getIncomes);

/**
 * @route   GET /api/income/stats
 * @desc    Get income statistics
 * @access  Private
 */
router.get("/stats", getIncomeStats);

/**
 * @route   GET /api/income/:id
 * @desc    Get income by ID
 * @access  Private
 */
router.get("/:id", getIncomeById);

/**
 * @route   PUT /api/income/:id
 * @desc    Update income
 * @access  Private
 */
router.put("/:id", updateIncome);

/**
 * @route   DELETE /api/income/:id
 * @desc    Delete income
 * @access  Private
 */
router.delete("/:id", deleteIncome);

export default router;
