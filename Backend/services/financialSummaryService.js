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
   * @param {boolean} hasBudget - Whether expense is linked to a budget
   * @returns {Promise<User>} - Updated user document
   */
  static async addExpense(userId, amount, hasBudget = false) {
    const updateFields = {
      $inc: {
        'financialSummary.totalExpenses': amount,
        'financialSummary.currentBalance': -amount,
      },
      'financialSummary.lastUpdated': new Date(),
    };

    // If expense has NO budget, subtract from readyToAssign
    if (!hasBudget) {
      // First check if user has enough readyToAssign
      const user = await User.findById(userId).select('financialSummary');
      if (!user) {
        throw new NotFoundError("Không tìm thấy người dùng");
      }

      const readyToAssign = parseFloat(user.financialSummary?.readyToAssign?.toString() || '0');
      if (readyToAssign < amount) {
        throw new Error(
          `Không đủ tiền Ready to Assign. Có sẵn: ${readyToAssign.toLocaleString('vi-VN')} đ, cần: ${amount.toLocaleString('vi-VN')} đ. Vui lòng gắn chi tiêu vào budget hoặc thêm thu nhập.`
        );
      }

      updateFields.$inc['financialSummary.readyToAssign'] = -amount;
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateFields,
      { new: true, runValidators: false }
    );

    if (!updatedUser) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return updatedUser;
  }

  /**
   * Remove expense from user's financial summary (for deletion/cancellation)
   * @param {string} userId - User ID
   * @param {number} amount - Expense amount to remove
   * @param {boolean} hasBudget - Whether expense was linked to a budget
   * @returns {Promise<User>} - Updated user document
   */
  static async removeExpense(userId, amount, hasBudget = false) {
    const updateFields = {
      $inc: {
        'financialSummary.totalExpenses': -amount,
        'financialSummary.currentBalance': amount,
      },
      'financialSummary.lastUpdated': new Date(),
    };

    // If expense had NO budget, return money to readyToAssign
    if (!hasBudget) {
      updateFields.$inc['financialSummary.readyToAssign'] = amount;
    }

    const user = await User.findByIdAndUpdate(
      userId,
      updateFields,
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
   * @param {boolean} oldHasBudget - Whether old expense had budget
   * @param {boolean} newHasBudget - Whether new expense has budget
   * @returns {Promise<User>} - Updated user document
   */
  static async updateExpense(userId, oldAmount, newAmount, oldHasBudget = false, newHasBudget = false) {
    const difference = newAmount - oldAmount;

    const updateFields = {
      $inc: {
        'financialSummary.totalExpenses': difference,
        'financialSummary.currentBalance': -difference,
      },
      'financialSummary.lastUpdated': new Date(),
    };

    // Handle readyToAssign based on budget changes
    // Case 1: Old had no budget, new has no budget -> adjust by difference
    if (!oldHasBudget && !newHasBudget) {
      // Check if user has enough readyToAssign for increase
      if (difference > 0) {
        const user = await User.findById(userId).select('financialSummary');
        const readyToAssign = parseFloat(user.financialSummary?.readyToAssign?.toString() || '0');
        if (readyToAssign < difference) {
          throw new Error(
            `Không đủ tiền Ready to Assign. Có sẵn: ${readyToAssign.toLocaleString('vi-VN')} đ, cần thêm: ${difference.toLocaleString('vi-VN')} đ.`
          );
        }
      }
      updateFields.$inc['financialSummary.readyToAssign'] = -difference;
    }
    // Case 2: Old had no budget, new has budget -> return oldAmount to readyToAssign
    else if (!oldHasBudget && newHasBudget) {
      updateFields.$inc['financialSummary.readyToAssign'] = oldAmount;
    }
    // Case 3: Old had budget, new has no budget -> subtract newAmount from readyToAssign
    else if (oldHasBudget && !newHasBudget) {
      const user = await User.findById(userId).select('financialSummary');
      const readyToAssign = parseFloat(user.financialSummary?.readyToAssign?.toString() || '0');
      if (readyToAssign < newAmount) {
        throw new Error(
          `Không đủ tiền Ready to Assign. Có sẵn: ${readyToAssign.toLocaleString('vi-VN')} đ, cần: ${newAmount.toLocaleString('vi-VN')} đ.`
        );
      }
      updateFields.$inc['financialSummary.readyToAssign'] = -newAmount;
    }
    // Case 4: Old had budget, new has budget -> no readyToAssign change

    const user = await User.findByIdAndUpdate(
      userId,
      updateFields,
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
