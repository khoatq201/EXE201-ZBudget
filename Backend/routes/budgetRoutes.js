import express from 'express';
import {
  getBudgets,
  getBudgetById,
  createBudget,
  updateBudget,
  deleteBudget,
  fundBudgetCategory,
  getBudgetStats,
  getCurrentBudget,
} from '../controllers/budgetController.js';
import { authenticate } from '../middleware/auth.js';
const router = express.Router();
// All routes require authentication
router.use(authenticate);
// Budget CRUD
router.get('/', getBudgets);
router.get('/current', getCurrentBudget);
router.get('/stats/summary', getBudgetStats);
router.get('/:id', getBudgetById);
router.post('/', createBudget);
router.put('/:id', updateBudget);
router.delete('/:id', deleteBudget);
// YNAB-style funding
router.post('/:id/fund', fundBudgetCategory);
export default router;