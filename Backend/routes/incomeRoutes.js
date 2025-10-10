import express from "express";
import {
  createIncome,
  getIncomes,
  getIncomeById,
  updateIncome,
  deleteIncome,
  getIncomeStats,
  assignReadyToAssign,
  getReadyToAssign,
} from "../controllers/incomeController.js";
import { authenticate, rateLimitGeneral } from "../middleware/auth.js";

const router = express.Router();

// Apply authentication to all income routes
router.use(authenticate);

// Apply general rate limiting
router.use(rateLimitGeneral());

/**
 * @route   POST /api/income
 * @desc    Create new income with optional YNAB-style allocations
 * @access  Private
 * @body    { title, amount, category, date, paymentMethod, allocations: [{ type, targetId, amount, categoryAllocationId, note }] }
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
 * @route   POST /api/income/assign
 * @desc    Assign from Ready to Assign pool to budgets/savings
 * @access  Private
 * @body    { assignments: [{ type, targetId, amount, categoryAllocationId, note }] }
 */
router.post("/assign", assignReadyToAssign);

/**
 * @route   GET /api/income/ready-to-assign
 * @desc    Get current Ready to Assign amount
 * @access  Private
 */
router.get("/ready-to-assign", getReadyToAssign);

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
