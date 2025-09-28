import { Budget, SavingsGoal, Expense } from '../types';
import StorageService from './StorageService';

export interface BudgetSavingsAnalysis {
  budgetId: string;
  totalBudget: number;
  totalSpent: number;
  totalRemaining: number;
  categoryBreakdown: {
    category: string;
    budgeted: number;
    spent: number;
    remaining: number;
    savingsPotential: number;
  }[];
  monthlySavingsPotential: number;
  recommendedSavingsAllocation: {
    goalId: string;
    goalName: string;
    recommendedAmount: number;
    priority: string;
  }[];
}

export interface SavingsProjection {
  goalId: string;
  currentAmount: number;
  targetAmount: number;
  monthlyBudgetSurplus: number;
  projectedMonthsToComplete: number;
  suggestedBudgetAdjustments: {
    category: string;
    currentAmount: number;
    suggestedReduction: number;
    reasoning: string;
  }[];
}

class BudgetSavingsService {
  /**
   * Tính toán khả năng tiết kiệm từ ngân sách hiện tại
   */
  static async calculateSavingsPotential(budgetId: string): Promise<BudgetSavingsAnalysis> {
    try {
      const budgets = await StorageService.getBudgets();
      const expenses = await StorageService.getExpenses();
      const savingsGoals = await StorageService.getSavingsGoals();

      const budget = budgets.find(b => b.id === budgetId);
      if (!budget) {
        throw new Error('Budget not found');
      }

      // Lọc chi tiêu trong khoảng thời gian budget
      const budgetExpenses = expenses.filter(expense => {
        const expenseDate = new Date(expense.date);
        return expenseDate >= budget.startDate && expenseDate <= budget.endDate;
      });

      // Tính toán chi tiết cho từng category
      const categoryBreakdown = budget.categories.map(category => {
        const categoryExpenses = budgetExpenses.filter(
          expense => expense.category === category.category
        );

        const spent = categoryExpenses.reduce((sum, expense) => sum + expense.amount, 0);
        const remaining = Math.max(0, category.allocatedAmount - spent);

        // Tính savings potential: 20% của số tiền còn lại + số tiền vượt dự kiến có thể cắt giảm
        const savingsPotential = remaining * 0.8; // Giữ lại 20% buffer

        return {
          category: category.category,
          budgeted: category.allocatedAmount,
          spent,
          remaining,
          savingsPotential: Math.max(0, savingsPotential),
        };
      });

      const totalBudget = budget.totalAmount;
      const totalSpent = categoryBreakdown.reduce((sum, cat) => sum + cat.spent, 0);
      const totalRemaining = totalBudget - totalSpent;
      const monthlySavingsPotential = categoryBreakdown.reduce(
        (sum, cat) => sum + cat.savingsPotential,
        0
      );

      // Đề xuất phân bổ tiết kiệm theo priority của savings goals
      const recommendedSavingsAllocation = savingsGoals
        .filter(goal => !goal.isCompleted)
        .sort((a, b) => {
          const priorityOrder: Record<string, number> = {
            critical: 4,
            high: 3,
            medium: 2,
            low: 1,
          };
          return priorityOrder[b.priority] - priorityOrder[a.priority];
        })
        .slice(0, 3) // Top 3 goals
        .map((goal, index) => {
          // Phân chia theo tỷ lệ priority
          const weights = [0.5, 0.3, 0.2]; // 50%, 30%, 20%
          const recommendedAmount = monthlySavingsPotential * weights[index];

          return {
            goalId: goal.id,
            goalName: goal.name,
            recommendedAmount,
            priority: goal.priority,
          };
        });

      return {
        budgetId,
        totalBudget,
        totalSpent,
        totalRemaining,
        categoryBreakdown,
        monthlySavingsPotential,
        recommendedSavingsAllocation,
      };
    } catch (error) {
      console.error('Error calculating savings potential:', error);
      throw error;
    }
  }

  /**
   * Dự đoán thời gian hoàn thành mục tiêu tiết kiệm dựa trên budget
   */
  static async projectSavingsCompletion(goalId: string): Promise<SavingsProjection> {
    try {
      const savingsGoals = await StorageService.getSavingsGoals();
      const budgets = await StorageService.getBudgets();

      const goal = savingsGoals.find(g => g.id === goalId);
      if (!goal) {
        throw new Error('Savings goal not found');
      }

      // Lấy budget hiện tại (active)
      const activeBudget = budgets.find(b => b.isActive);
      if (!activeBudget) {
        return {
          goalId,
          currentAmount: goal.currentAmount,
          targetAmount: goal.targetAmount,
          monthlyBudgetSurplus: 0,
          projectedMonthsToComplete: Infinity,
          suggestedBudgetAdjustments: [],
        };
      }

      const analysis = await this.calculateSavingsPotential(activeBudget.id);
      const monthlyBudgetSurplus = analysis.monthlySavingsPotential;
      const remainingAmount = goal.targetAmount - goal.currentAmount;

      let projectedMonthsToComplete = Infinity;
      if (monthlyBudgetSurplus > 0) {
        projectedMonthsToComplete = Math.ceil(remainingAmount / monthlyBudgetSurplus);
      }

      // Đề xuất điều chỉnh budget nếu cần thiết
      const suggestedBudgetAdjustments = this.generateBudgetAdjustmentSuggestions(
        analysis,
        goal,
        remainingAmount
      );

      return {
        goalId,
        currentAmount: goal.currentAmount,
        targetAmount: goal.targetAmount,
        monthlyBudgetSurplus,
        projectedMonthsToComplete,
        suggestedBudgetAdjustments,
      };
    } catch (error) {
      console.error('Error projecting savings completion:', error);
      throw error;
    }
  }

  /**
   * Tự động chuyển tiền từ budget surplus vào savings goals
   */
  static async autoAllocateBudgetSurplus(budgetId: string): Promise<void> {
    try {
      const analysis = await this.calculateSavingsPotential(budgetId);

      if (analysis.monthlySavingsPotential <= 0) {
        return; // Không có tiền thừa để tiết kiệm
      }

      // Thực hiện chuyển tiền theo đề xuất
      for (const allocation of analysis.recommendedSavingsAllocation) {
        if (allocation.recommendedAmount > 0) {
          const savingsGoals = await StorageService.getSavingsGoals();
          const goal = savingsGoals.find(g => g.id === allocation.goalId);

          if (goal && !goal.isCompleted) {
            const newAmount = goal.currentAmount + allocation.recommendedAmount;
            const updatedGoal = {
              ...goal,
              currentAmount: Math.min(newAmount, goal.targetAmount),
              isCompleted: newAmount >= goal.targetAmount,
              completedAt: newAmount >= goal.targetAmount ? new Date() : undefined,
              updatedAt: new Date(),
            };

            await StorageService.updateSavingsGoal(goal.id, updatedGoal);
          }
        }
      }
    } catch (error) {
      console.error('Error auto-allocating budget surplus:', error);
      throw error;
    }
  }

  /**
   * Tạo đề xuất điều chỉnh budget
   */
  private static generateBudgetAdjustmentSuggestions(
    analysis: BudgetSavingsAnalysis,
    goal: SavingsGoal,
    remainingAmount: number
  ) {
    const suggestions = [];

    // Tìm categories có thể cắt giảm
    const optimizableCategories = analysis.categoryBreakdown
      .filter(cat => cat.remaining > 0 || cat.spent > cat.budgeted * 0.8)
      .sort((a, b) => b.savingsPotential - a.savingsPotential);

    for (const category of optimizableCategories.slice(0, 3)) {
      let reasoning = '';
      let suggestedReduction = 0;

      if (category.remaining > 0) {
        suggestedReduction = category.remaining * 0.5;
        reasoning = `Bạn còn thừa ${this.formatCurrency(category.remaining)} trong mục này. Có thể cắt giảm 50%.`;
      } else if (category.spent > category.budgeted) {
        suggestedReduction = (category.spent - category.budgeted) * 0.3;
        reasoning = `Mục này đã vượt ngân sách. Nên cắt giảm để kiểm soát chi tiêu.`;
      }

      if (suggestedReduction > 0) {
        suggestions.push({
          category: category.category,
          currentAmount: category.budgeted,
          suggestedReduction,
          reasoning,
        });
      }
    }

    return suggestions;
  }

  /**
   * Lấy insights tích hợp budget-savings
   */
  static async getBudgetSavingsInsights(userId: string) {
    try {
      const budgets = await StorageService.getBudgets();
      const savingsGoals = await StorageService.getSavingsGoals();
      const activeBudget = budgets.find(b => b.isActive && b.userId === userId);

      if (!activeBudget) {
        return {
          hasBudget: false,
          insights: [],
        };
      }

      const analysis = await this.calculateSavingsPotential(activeBudget.id);
      const insights = [];

      // Insight 1: Khả năng tiết kiệm từ budget
      if (analysis.monthlySavingsPotential > 0) {
        insights.push({
          type: 'positive',
          title: 'Cơ hội tiết kiệm',
          message: `Từ ngân sách hiện tại, bạn có thể tiết kiệm thêm ${this.formatCurrency(analysis.monthlySavingsPotential)}/tháng`,
          icon: '💰',
          actionType: 'auto_allocate',
        });
      }

      // Insight 2: Tiến độ mục tiêu
      const activeGoals = savingsGoals.filter(g => !g.isCompleted);
      if (activeGoals.length > 0) {
        for (const goal of activeGoals.slice(0, 2)) {
          const projection = await this.projectSavingsCompletion(goal.id);
          if (projection.projectedMonthsToComplete < Infinity) {
            insights.push({
              type: 'info',
              title: `Mục tiêu: ${goal.name}`,
              message: `Với ngân sách hiện tại, bạn sẽ đạt được mục tiêu trong ${projection.projectedMonthsToComplete} tháng`,
              icon: goal.icon,
              actionType: 'view_goal',
              goalId: goal.id,
            });
          }
        }
      }

      // Insight 3: Cảnh báo vượt budget ảnh hưởng savings
      if (analysis.totalSpent > analysis.totalBudget * 0.9) {
        insights.push({
          type: 'warning',
          title: 'Ngân sách gần hết',
          message: 'Chi tiêu cao có thể ảnh hưởng đến khả năng tiết kiệm. Hãy xem lại ngân sách.',
          icon: '⚠️',
          actionType: 'review_budget',
        });
      }

      return {
        hasBudget: true,
        currentAnalysis: analysis,
        insights,
      };
    } catch (error) {
      console.error('Error getting budget-savings insights:', error);
      return { hasBudget: false, insights: [] };
    }
  }

  private static formatCurrency(amount: number): string {
    return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
  }
}

export default BudgetSavingsService;
