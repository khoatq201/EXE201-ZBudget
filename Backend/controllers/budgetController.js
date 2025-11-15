import mongoose from "mongoose";
import Budget from "../models/Budget.js";
import User from "../models/User.js";
import NotificationService from "../services/notificationService.js";
/**
 * @desc    Get all budgets for a user
 * @route   GET /api/budgets
 * @access  Private
 */
export const getBudgets = async (req, res) => {
  try {
    // Use req.userId (middleware must set this)
    const userId = req.userId;
    const { status, period, year, month } = req.query;
    if (!userId) {
      return res
        .status(401)
        .json({ success: false, error: "Unauthorized: Missing userId" });
    }
    const query = { userId };
    // Filter by active status
    if (status === "active") {
      query.isActive = true;
    } else if (status === "inactive") {
      query.isActive = false;
    }
    // Filter by period type
    if (period) {
      query["period.type"] = period;
    }
    // Filter by year/month
    if (year && month) {
      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0, 23, 59, 59);
      query["period.startDate"] = { $gte: startDate };
      query["period.endDate"] = { $lte: endDate };
    }
    const budgets = await Budget.find(query).sort({
      "period.startDate": -1,
      createdAt: -1,
    });
    // Get user financial summary
    const user = await User.findById(userId).select("financialSummary");
    if (!user) {
      return res.status(404).json({ success: false, error: "User not found" });
    }
    const readyToAssign = parseFloat(
      user.financialSummary?.readyToAssign?.toString() || "0"
    );
    res.status(200).json({
      success: true,
      data: {
        budgets: budgets.map((b) => b.toJSON()),
        readyToAssign,
        count: budgets.length,
      },
    });
  } catch (error) {
    console.error("Error in getBudgets:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy danh sách ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Get budget by ID
 * @route   GET /api/budgets/:id
 * @access  Private
 */
export const getBudgetById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const budget = await Budget.findOne({ _id: id, userId });
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ngân sách",
      });
    }
    res.status(200).json({
      success: true,
      data: budget.toJSON(),
    });
  } catch (error) {
    console.error("Error in getBudgetById:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thông tin ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Create new budget
 * @route   POST /api/budgets
 * @access  Private
 */
export const createBudget = async (req, res) => {
  try {
    const userId = req.userId;
    const {
      name,
      totalAmount,
      currency,
      period,
      categoryAllocations,
      alerts,
      goals,
    } = req.body;
    // Validate period dates
    const startDate = new Date(period.startDate);
    const endDate = new Date(period.endDate);
    if (endDate <= startDate) {
      return res.status(400).json({
        success: false,
        message: "Ngày kết thúc phải sau ngày bắt đầu",
      });
    }
    // Validate category allocations percentage sum
    const totalPercentage = categoryAllocations.reduce(
      (sum, cat) => sum + cat.percentage,
      0
    );
    if (totalPercentage > 100) {
      return res.status(400).json({
        success: false,
        message: "Tổng phần trăm phân bổ không được vượt quá 100%",
      });
    }
    // Create budget
    const budget = new Budget({
      userId,
      name,
      totalAmount,
      currency: currency || "VND",
      period: {
        startDate,
        endDate,
        type: period.type || "monthly",
      },
      categoryAllocations: categoryAllocations.map((cat) => ({
        ...cat,
        funded: 0,
        spent: 0,
        available: 0,
      })),
      alerts: alerts || {},
      goals: goals || {},
    });
    await budget.save();

    // ✅ NEW: Notification trigger for budget creation
    try {
      await NotificationService.createNotification(
        userId,
        "budget_created",
        {
          budgetId: budget._id,
          budgetName: budget.name,
          totalAmount: budget.totalAmount,
          category: budget.categoryAllocations?.[0]?.category || "general",
        },
        {
          title: "💰 Ngân sách mới được tạo",
          message: `Bạn đã tạo ngân sách "${
            budget.name
          }" với tổng số tiền ${budget.totalAmount.toLocaleString()}đ`,
          category: "budget",
          priority: "normal",
        }
      );
    } catch (notificationError) {
      console.error(
        "⚠️ Budget creation notification failed (non-critical):",
        notificationError.message
      );
    }

    const response = {
      success: true,
      message: "Tạo ngân sách thành công",
      data: budget.toJSON(),
    };

    // Add budget limit info if middleware attached it
    if (req.budgetCount !== undefined && req.budgetLimit !== undefined) {
      response.limitInfo = {
        current: req.budgetCount + 1, // +1 because we just created one
        limit: req.budgetLimit,
        remaining: req.budgetLimit - (req.budgetCount + 1),
      };
    }

    res.status(201).json(response);
  } catch (error) {
    console.error("Error in createBudget:", error);
    res.status(400).json({
      success: false,
      message: error.message || "Lỗi khi tạo ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Update budget
 * @route   PUT /api/budgets/:id
 * @access  Private
 */
export const updateBudget = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const updates = req.body;
    const budget = await Budget.findOne({ _id: id, userId });
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ngân sách",
      });
    }
    // Store original values for comparison
    const originalTotalAmount = budget.totalAmount;
    const originalName = budget.name;

    // Update allowed fields
    if (updates.name) budget.name = updates.name;
    if (updates.totalAmount) budget.totalAmount = updates.totalAmount;
    if (updates.currency) budget.currency = updates.currency;
    if (updates.period) budget.period = updates.period;
    if (updates.categoryAllocations)
      budget.categoryAllocations = updates.categoryAllocations;
    if (updates.alerts) budget.alerts = updates.alerts;
    if (updates.goals) budget.goals = updates.goals;
    if (typeof updates.isActive === "boolean")
      budget.isActive = updates.isActive;
    await budget.save();

    // ✅ NEW: Notification trigger for budget updates
    try {
      if (updates.totalAmount && updates.totalAmount !== originalTotalAmount) {
        const changeType =
          updates.totalAmount > originalTotalAmount
            ? "amount_increase"
            : "amount_decrease";
        await NotificationService.triggerBudgetUpdateNotification(userId, {
          budgetId: budget._id,
          budgetName: budget.name,
          oldAmount: originalTotalAmount,
          newAmount: updates.totalAmount,
          changeType,
        });
      }
    } catch (notificationError) {
      console.error(
        "⚠️ Budget update notification trigger failed (non-critical):",
        notificationError.message
      );
    }
    res.status(200).json({
      success: true,
      message: "Cập nhật ngân sách thành công",
      data: budget.toJSON(),
    });
  } catch (error) {
    console.error("Error in updateBudget:", error);
    res.status(400).json({
      success: false,
      message: error.message || "Lỗi khi cập nhật ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Delete budget
 * @route   DELETE /api/budgets/:id
 * @access  Private
 */
export const deleteBudget = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const budget = await Budget.findOneAndDelete({ _id: id, userId });
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ngân sách",
      });
    }
    res.status(200).json({
      success: true,
      message: "Xóa ngân sách thành công",
    });
  } catch (error) {
    console.error("Error in deleteBudget:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi xóa ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Fund a budget category from Ready to Assign (YNAB style)
 * @route   POST /api/budgets/:id/fund
 * @access  Private
 */
export const fundBudgetCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const { category, amount } = req.body;
    if (!category || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Category và amount là bắt buộc",
      });
    }
    // Get budget
    const budget = await Budget.findOne({ _id: id, userId });
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy ngân sách",
      });
    }
    // Get user's ready to assign amount
    const user = await User.findById(userId);
    const readyToAssign = parseFloat(
      user.financialSummary?.readyToAssign?.toString() || "0"
    );
    if (readyToAssign < amount) {
      return res.status(400).json({
        success: false,
        message: `Không đủ tiền Ready to Assign. Có sẵn: ${readyToAssign}, cần: ${amount}`,
      });
    }
    // Store original state for rollback
    const originalBudgetState = budget.toJSON();
    const originalReadyToAssign = readyToAssign;
    try {
      // Fund the category using Budget's instance method
      budget.fundCategory(category, amount);
      await budget.save();
      // Deduct from user's Ready to Assign
      const newReadyToAssign = readyToAssign - amount;
      user.financialSummary.readyToAssign =
        mongoose.Types.Decimal128.fromString(newReadyToAssign.toFixed(2));
      await user.save();
      res.status(200).json({
        success: true,
        message: "Fund ngân sách thành công",
        data: {
          budget: budget.toJSON(),
          readyToAssign: newReadyToAssign,
        },
      });
    } catch (saveError) {
      // Rollback: restore original state
      console.error("Error saving, attempting rollback:", saveError);
      try {
        // Restore budget
        await Budget.findByIdAndUpdate(id, originalBudgetState);
        // Restore user ready to assign
        user.financialSummary.readyToAssign =
          mongoose.Types.Decimal128.fromString(
            originalReadyToAssign.toFixed(2)
          );
        await user.save();
      } catch (rollbackError) {
        console.error("Rollback failed:", rollbackError);
      }
      throw saveError;
    }
  } catch (error) {
    console.error("Error in fundBudgetCategory:", error);
    res.status(400).json({
      success: false,
      message: error.message || "Lỗi khi fund ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Get budget statistics
 * @route   GET /api/budgets/stats/summary
 * @access  Private
 */
export const getBudgetStats = async (req, res) => {
  try {
    const userId = req.userId;
    const { year, month } = req.query;
    const currentYear = year ? parseInt(year) : new Date().getFullYear();
    const currentMonth = month ? parseInt(month) : null;
    const summary = await Budget.getBudgetSummary(
      userId,
      currentYear,
      currentMonth
    );
    res.status(200).json({
      success: true,
      data: summary[0] || {
        totalBudget: 0,
        totalSpent: 0,
        budgetCount: 0,
        overBudgetCount: 0,
      },
    });
  } catch (error) {
    console.error("Error in getBudgetStats:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy thống kê ngân sách",
      error: error.message,
    });
  }
};
/**
 * @desc    Get current active budget
 * @route   GET /api/budgets/current
 * @access  Private
 */
export const getCurrentBudget = async (req, res) => {
  try {
    const userId = req.userId;
    const budget = await Budget.findCurrentBudget(userId);
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: "Không có ngân sách đang hoạt động",
      });
    }
    res.status(200).json({
      success: true,
      data: budget.toJSON(),
    });
  } catch (error) {
    console.error("Error in getCurrentBudget:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy ngân sách hiện tại",
      error: error.message,
    });
  }
};
