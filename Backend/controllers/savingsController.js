import SavingsGoal from "../models/SavingsGoal.js";
import { User } from "../models/index.js";
import {
  BadRequestError,
  NotFoundError,
  successResponse,
} from "../middleware/errorHandler.js";
import mongoose from "mongoose";
/**
 * @desc    Create new savings goal
 * @route   POST /api/savings
 * @access  Private
 */
export const createSavingsGoal = async (req, res) => {
  const userId = req.userId;
  const {
    name,
    description,
    targetAmount,
    targetDate,
    category,
    priority,
    autoSave,
    icon,
    color,
    tags,
    notes,
  } = req.body;
  try {
    const savingsGoal = new SavingsGoal({
      userId,
      name,
      description,
      targetAmount,
      targetDate: new Date(targetDate),
      category,
      priority: priority || "medium",
      autoSave,
      icon,
      color,
      tags,
      notes,
    });
    await savingsGoal.save();
    // Format response
    const formattedGoal = {
      ...savingsGoal.toObject({ virtuals: true }),
      targetAmount: parseFloat(savingsGoal.targetAmount.toString()),
      currentAmount: parseFloat(savingsGoal.currentAmount.toString()),
      progressPercentage: savingsGoal.progressPercentage,
      remainingAmount: savingsGoal.remainingAmount,
      daysRemaining: savingsGoal.daysRemaining,
      suggestedMonthlyContribution: savingsGoal.suggestedMonthlyContribution,
    };
    res.status(201).json({
      success: true,
      message: "Savings goal created successfully",
      data: formattedGoal,
    });
  } catch (error) {
    console.error("❌ Create savings goal error:", error);
    throw new BadRequestError(error.message);
  }
};
/**
 * @desc    Get all savings goals for user
 * @route   GET /api/savings
 * @access  Private
 */
export const getSavingsGoals = async (req, res) => {
  const userId = req.userId;
  const {
    status,
    category,
    priority,
    page = 1,
    limit = 50,
    sort = "-targetDate",
  } = req.query;
  try {
    const query = { userId };
    // Filters
    if (status) query.status = status;
    if (category) query.category = category;
    if (priority) query.priority = priority;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [goals, total] = await Promise.all([
      SavingsGoal.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      SavingsGoal.countDocuments(query),
    ]);
    // Format goals with virtuals calculated manually
    const formattedGoals = goals.map((goal) => {
      const current = parseFloat(goal.currentAmount.toString());
      const target = parseFloat(goal.targetAmount.toString());
      const progressPercentage =
        target > 0 ? Math.min((current / target) * 100, 100) : 0;
      const remainingAmount = Math.max(target - current, 0);
      const now = new Date();
      const targetDate = new Date(goal.targetDate);
      const diffTime = targetDate - now;
      const daysRemaining = Math.max(
        Math.ceil(diffTime / (1000 * 60 * 60 * 24)),
        0
      );
      const monthsRemaining = Math.max(daysRemaining / 30, 1);
      const suggestedMonthlyContribution =
        goal.status === "completed" ? 0 : remainingAmount / monthsRemaining;
      return {
        ...goal,
        targetAmount: target,
        currentAmount: current,
        progressPercentage,
        remainingAmount,
        daysRemaining,
        suggestedMonthlyContribution,
      };
    });
    res.status(200).json({
      success: true,
      message: "Savings goals retrieved successfully",
      data: {
        goals: formattedGoals,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("Get savings goals error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve savings goals",
    });
  }
};
/**
 * @desc    Get savings goal by ID
 * @route   GET /api/savings/:id
 * @access  Private
 */
export const getSavingsGoalById = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;
  try {
    const goal = await SavingsGoal.findOne({ _id: id, userId });
    if (!goal) {
      throw new NotFoundError("Savings goal not found");
    }
    const formattedGoal = {
      ...goal.toObject({ virtuals: true }),
      targetAmount: parseFloat(goal.targetAmount.toString()),
      currentAmount: parseFloat(goal.currentAmount.toString()),
      progressPercentage: goal.progressPercentage,
      remainingAmount: goal.remainingAmount,
      daysRemaining: goal.daysRemaining,
      suggestedMonthlyContribution: goal.suggestedMonthlyContribution,
      contributions: goal.contributions.map((c) => ({
        ...c.toObject(),
        amount: parseFloat(c.amount.toString()),
      })),
      withdrawals: goal.withdrawals.map((w) => ({
        ...w.toObject(),
        amount: parseFloat(w.amount.toString()),
      })),
    };
    res.status(200).json({
      success: true,
      message: "Savings goal retrieved successfully",
      data: formattedGoal,
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    res.status(500).json({
      success: false,
      error: "Failed to retrieve savings goal",
    });
  }
};
/**
 * @desc    Update savings goal
 * @route   PUT /api/savings/:id
 * @access  Private
 */
export const updateSavingsGoal = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;
  try {
    const goal = await SavingsGoal.findOne({ _id: id, userId });
    if (!goal) {
      throw new NotFoundError("Savings goal not found");
    }
    // Update allowed fields
    const allowedUpdates = [
      "name",
      "description",
      "targetAmount",
      "targetDate",
      "category",
      "priority",
      "status",
      "autoSave",
      "icon",
      "color",
      "tags",
      "notes",
    ];
    allowedUpdates.forEach((field) => {
      if (req.body[field] !== undefined) {
        goal[field] = req.body[field];
      }
    });
    await goal.save();
    const formattedGoal = {
      ...goal.toObject({ virtuals: true }),
      targetAmount: parseFloat(goal.targetAmount.toString()),
      currentAmount: parseFloat(goal.currentAmount.toString()),
      progressPercentage: goal.progressPercentage,
      remainingAmount: goal.remainingAmount,
      daysRemaining: goal.daysRemaining,
      suggestedMonthlyContribution: goal.suggestedMonthlyContribution,
    };
    res.status(200).json({
      success: true,
      message: "Savings goal updated successfully",
      data: formattedGoal,
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    console.error("Update savings goal error:", error);
    throw new BadRequestError(error.message);
  }
};
/**
 * @desc    Delete savings goal
 * @route   DELETE /api/savings/:id
 * @access  Private
 */
export const deleteSavingsGoal = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      const goal = await SavingsGoal.findOne({ _id: id, userId }).session(
        session
      );
      if (!goal) {
        throw new NotFoundError("Savings goal not found");
      }
      const currentAmount = parseFloat(goal.currentAmount.toString());
      // Delete the goal
      await SavingsGoal.findByIdAndDelete(id).session(session);
      // Update user's financial summary
      await User.findByIdAndUpdate(
        userId,
        {
          $inc: {
            "financialSummary.totalSaved": -currentAmount,
          },
          "financialSummary.lastUpdated": new Date(),
        },
        { session }
      );
      res.status(200).json({
        success: true,
        message: "Savings goal deleted successfully",
        data: null,
      });
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    console.error("Delete savings goal error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to delete savings goal",
    });
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Add contribution to savings goal
 * @route   POST /api/savings/:id/contribute
 * @access  Private
 */
export const addContribution = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;
  const { amount, source = "manual", incomeId, note } = req.body;
  if (!amount || amount <= 0) {
    throw new BadRequestError("Amount must be greater than 0");
  }
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      const goal = await SavingsGoal.findOne({ _id: id, userId }).session(
        session
      );
      if (!goal) {
        throw new NotFoundError("Savings goal not found");
      }
      if (goal.status !== "active") {
        throw new BadRequestError(
          "Cannot contribute to inactive savings goal"
        );
      }

      // Check if user has enough readyToAssign (unless from income_allocation)
      if (source !== 'income_allocation') {
        const user = await User.findById(userId).select('financialSummary');
        const readyToAssign = parseFloat(user.financialSummary?.readyToAssign?.toString() || '0');

        if (readyToAssign < parseFloat(amount)) {
          throw new BadRequestError(
            `Không đủ tiền Ready to Assign. Có sẵn: ${readyToAssign.toLocaleString('vi-VN')} đ, cần: ${parseFloat(amount).toLocaleString('vi-VN')} đ. Vui lòng thêm thu nhập hoặc phân bổ từ thu nhập.`
          );
        }
      }

      // Add contribution
      goal.addContribution(parseFloat(amount), source, incomeId, note);
      await goal.save({ session });

      // Update user's financial summary
      const updateFields = {
        $inc: {
          "financialSummary.totalSaved": parseFloat(amount),
        },
        "financialSummary.lastUpdated": new Date(),
      };

      // If not from income_allocation, subtract from readyToAssign
      if (source !== 'income_allocation') {
        updateFields.$inc["financialSummary.readyToAssign"] = -parseFloat(amount);
      }

      await User.findByIdAndUpdate(userId, updateFields, { session });
      const formattedGoal = {
        ...goal.toObject({ virtuals: true }),
        targetAmount: parseFloat(goal.targetAmount.toString()),
        currentAmount: parseFloat(goal.currentAmount.toString()),
        progressPercentage: goal.progressPercentage,
        remainingAmount: goal.remainingAmount,
        daysRemaining: goal.daysRemaining,
        suggestedMonthlyContribution: goal.suggestedMonthlyContribution,
      };
      res.status(200).json({
        success: true,
        message: "Contribution added successfully",
        data: formattedGoal,
      });
    });
  } catch (error) {
    console.error("❌ Add contribution error:", error);
    if (error instanceof NotFoundError || error instanceof BadRequestError)
      throw error;
    throw new BadRequestError(error.message);
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Withdraw from savings goal
 * @route   POST /api/savings/:id/withdraw
 * @access  Private
 */
export const withdrawFromSavings = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;
  const { amount, reason } = req.body;
  if (!amount || amount <= 0) {
    throw new BadRequestError("Amount must be greater than 0");
  }
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      const goal = await SavingsGoal.findOne({ _id: id, userId }).session(
        session
      );
      if (!goal) {
        throw new NotFoundError("Savings goal not found");
      }
      // Withdraw
      goal.withdraw(parseFloat(amount), reason);
      await goal.save({ session });
      // Update user's totalSaved and return to readyToAssign
      await User.findByIdAndUpdate(
        userId,
        {
          $inc: {
            "financialSummary.totalSaved": -parseFloat(amount),
            "financialSummary.readyToAssign": parseFloat(amount), // Return to readyToAssign
          },
          "financialSummary.lastUpdated": new Date(),
        },
        { session }
      );
      const formattedGoal = {
        ...goal.toObject({ virtuals: true }),
        targetAmount: parseFloat(goal.targetAmount.toString()),
        currentAmount: parseFloat(goal.currentAmount.toString()),
        progressPercentage: goal.progressPercentage,
        remainingAmount: goal.remainingAmount,
        daysRemaining: goal.daysRemaining,
        suggestedMonthlyContribution: goal.suggestedMonthlyContribution,
      };
      res.status(200).json({
        success: true,
        message: "Withdrawal successful",
        data: formattedGoal,
      });
    });
  } catch (error) {
    console.error("❌ Withdrawal error:", error);
    if (error instanceof NotFoundError || error instanceof BadRequestError)
      throw error;
    throw new BadRequestError(error.message);
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Get savings statistics
 * @route   GET /api/savings/stats
 * @access  Private
 */
export const getSavingsStats = async (req, res) => {
  const userId = req.userId;
  try {
    const stats = await SavingsGoal.getStats(userId);
    res.status(200).json({
      success: true,
      message: "Savings statistics retrieved successfully",
      data: stats,
    });
  } catch (error) {
    console.error("Get savings stats error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve savings statistics",
    });
  }
};
export default {
  createSavingsGoal,
  getSavingsGoals,
  getSavingsGoalById,
  updateSavingsGoal,
  deleteSavingsGoal,
  addContribution,
  withdrawFromSavings,
  getSavingsStats,
};