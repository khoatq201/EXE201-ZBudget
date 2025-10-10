import express from "express";
import {
  createSavingsGoal,
  getSavingsGoals,
  getSavingsGoalById,
  updateSavingsGoal,
  deleteSavingsGoal,
  addContribution,
  withdrawFromSavings,
  getSavingsStats,
} from "../controllers/savingsController.js";
import { authenticate, rateLimitGeneral } from "../middleware/auth.js";

const router = express.Router();

// Apply authentication to all savings routes
router.use(authenticate);

// Apply general rate limiting
router.use(rateLimitGeneral());

/**
 * @route   POST /api/savings
 * @desc    Create new savings goal
 * @access  Private
 * @body    { name, targetAmount, targetDate, category, description, priority, autoSave, icon, color, tags, notes }
 */
router.post("/", createSavingsGoal);

/**
 * @route   GET /api/savings
 * @desc    Get all savings goals with filters
 * @access  Private
 * @query   status, category, priority, page, limit, sort
 */
router.get("/", getSavingsGoals);

/**
 * @route   GET /api/savings/stats
 * @desc    Get savings statistics
 * @access  Private
 */
router.get("/stats", getSavingsStats);

/**
 * @route   GET /api/savings/:id
 * @desc    Get savings goal by ID
 * @access  Private
 */
router.get("/:id", getSavingsGoalById);

/**
 * @route   PUT /api/savings/:id
 * @desc    Update savings goal
 * @access  Private
 */
router.put("/:id", updateSavingsGoal);

/**
 * @route   DELETE /api/savings/:id
 * @desc    Delete savings goal
 * @access  Private
 */
router.delete("/:id", deleteSavingsGoal);

/**
 * @route   POST /api/savings/:id/contribute
 * @desc    Add contribution to savings goal
 * @access  Private
 * @body    { amount, source, incomeId, note }
 */
router.post("/:id/contribute", addContribution);

/**
 * @route   POST /api/savings/:id/withdraw
 * @desc    Withdraw from savings goal
 * @access  Private
 * @body    { amount, reason }
 */
router.post("/:id/withdraw", withdrawFromSavings);

export default router;
