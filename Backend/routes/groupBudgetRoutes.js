import express from 'express';
import { authenticate } from '../middleware/auth.js';
import {
  createGroupBudget,
  getGroupBudgets,
  getGroupBudgetById,
  joinGroupBudget,
  inviteToGroupBudget,
  updateGroupBudget,
  deleteGroupBudget,
  addExpenseToGroupBudget,
  recordFunding,
  recordPayment,
  getSettlementPlan,
  settleGroupBudget,
  getGroupBudgetSummary,
} from '../controllers/groupBudgetController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * Independent GroupBudget routes (no Group required)
 */

// CRUD operations
router.post('/', createGroupBudget);                      // Create new budget
router.get('/', getGroupBudgets);                         // Get all budgets for user
router.get('/:id', getGroupBudgetById);                   // Get budget detail
router.put('/:id', updateGroupBudget);                    // Update budget
router.delete('/:id', deleteGroupBudget);                 // Delete budget

// Invite & Join
router.post('/join', joinGroupBudget);                    // Join by invite code
router.post('/:id/invite', inviteToGroupBudget);          // Invite user by email/userId

// Expense operations
router.post('/:id/expenses', addExpenseToGroupBudget);    // Add expense

// Funding & Settlement
router.post('/:id/funding', recordFunding);               // Record funding
router.post('/:id/payments', recordPayment);              // Record debt payment
router.get('/:id/settlement-plan', getSettlementPlan);    // Get settlement plan
router.post('/:id/settle', settleGroupBudget);            // Mark as settled

// Summary
router.get('/:id/summary', getGroupBudgetSummary);        // Get summary

export default router;
