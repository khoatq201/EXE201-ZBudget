import { User } from "../models/index.js";
import { NotFoundError } from "../middleware/errorHandler.js";

/**
 * Financial Summary Service - Manage user financial summary updates
 */
export class FinancialSummaryService {
  /**
   * Add expense to user's financial summary
   * @param {string} userId - User ID
   * @param {number} amount - Expense amount
   * @returns {Promise<User>} - Updated user document
   */
  static async addExpense(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalExpenses': amount,
          'financialSummary.currentBalance': -amount,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Remove expense from user's financial summary (for deletion/cancellation)
   * @param {string} userId - User ID
   * @param {number} amount - Expense amount to remove
   * @returns {Promise<User>} - Updated user document
   */
  static async removeExpense(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalExpenses': -amount,
          'financialSummary.currentBalance': amount,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Add income to user's financial summary
   * @param {string} userId - User ID
   * @param {number} amount - Income amount
   * @returns {Promise<User>} - Updated user document
   */
  static async addIncome(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalIncome': amount,
          'financialSummary.currentBalance': amount,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Remove income from user's financial summary (for deletion/cancellation)
   * @param {string} userId - User ID
   * @param {number} amount - Income amount to remove
   * @returns {Promise<User>} - Updated user document
   */
  static async removeIncome(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalIncome': -amount,
          'financialSummary.currentBalance': -amount,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Update expense amount (when editing expense)
   * @param {string} userId - User ID
   * @param {number} oldAmount - Previous expense amount
   * @param {number} newAmount - New expense amount
   * @returns {Promise<User>} - Updated user document
   */
  static async updateExpense(userId, oldAmount, newAmount) {
    const difference = newAmount - oldAmount;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalExpenses': difference,
          'financialSummary.currentBalance': -difference,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Update income amount (when editing income)
   * @param {string} userId - User ID
   * @param {number} oldAmount - Previous income amount
   * @param {number} newAmount - New income amount
   * @returns {Promise<User>} - Updated user document
   */
  static async updateIncome(userId, oldAmount, newAmount) {
    const difference = newAmount - oldAmount;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalIncome': difference,
          'financialSummary.currentBalance': difference,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Add to savings
   * @param {string} userId - User ID
   * @param {number} amount - Savings amount
   * @returns {Promise<User>} - Updated user document
   */
  static async addSavings(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalSavings': amount,
          'financialSummary.currentBalance': -amount, // Remove from balance
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Withdraw from savings
   * @param {string} userId - User ID
   * @param {number} amount - Withdrawal amount
   * @returns {Promise<User>} - Updated user document
   */
  static async withdrawSavings(userId, amount) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalSavings': -amount,
          'financialSummary.currentBalance': amount, // Add back to balance
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Update monthly allowance
   * @param {string} userId - User ID
   * @param {number} allowance - Monthly allowance amount
   * @returns {Promise<User>} - Updated user document
   */
  static async updateMonthlyAllowance(userId, allowance) {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        'financialSummary.monthlyAllowance': allowance,
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Get user's financial summary
   * @param {string} userId - User ID
   * @returns {Promise<Object>} - Financial summary object
   */
  static async getSummary(userId) {
    const user = await User.findById(userId).select('financialSummary');

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user.financialSummary;
  }

  /**
   * Recalculate user's financial summary from scratch
   * Useful for fixing inconsistencies
   * @param {string} userId - User ID
   * @param {Object} totals - Recalculated totals { totalIncome, totalExpenses, totalSavings }
   * @returns {Promise<User>} - Updated user document
   */
  static async recalculate(userId, totals) {
    const { totalIncome = 0, totalExpenses = 0, totalSavings = 0 } = totals;
    const currentBalance = totalIncome - totalExpenses - totalSavings;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          'financialSummary.totalIncome': totalIncome,
          'financialSummary.totalExpenses': totalExpenses,
          'financialSummary.totalSavings': totalSavings,
          'financialSummary.currentBalance': currentBalance,
          'financialSummary.lastUpdated': new Date(),
        }
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }
}

export default FinancialSummaryService;
