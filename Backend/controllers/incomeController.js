import Income from "../models/Income.js";
import { User } from "../models/index.js";
import {
  BadRequestError,
  NotFoundError,
  successResponse,
} from "../middleware/errorHandler.js";
import mongoose from "mongoose";

/**
 * @desc    Create new income
 * @route   POST /api/income
 * @access  Private
 */
export const createIncome = async (req, res) => {
  const userId = req.userId;
  const {
    title,
    description,
    amount,
    category,
    date,
    paymentMethod,
    source,
    isRecurring,
    recurringDetails,
    taxInfo,
  } = req.body;

  try {
    console.log('💰 Creating income for user:', userId);

    // Create income
    const income = new Income({
      userId,
      title,
      description,
      amount,
      category,
      date: date ? new Date(date) : new Date(),
      paymentMethod: paymentMethod || "banking",
      source,
      isRecurring: isRecurring || false,
      recurringDetails,
      taxInfo,
      isConfirmed: true,
    });

    console.log('💾 Saving income...');
    await income.save();
    console.log('✅ Income saved:', income._id);

    // Update user's financial summary
    console.log('📊 Updating user financial summary...');
    try {
      await User.findByIdAndUpdate(
        userId,
        {
          $inc: {
            'financialSummary.totalIncome': amount,
            'financialSummary.currentBalance': amount,
          },
          'financialSummary.lastUpdated': new Date(),
        },
        { new: true }
      );
      console.log('✅ Financial summary updated');
    } catch (summaryError) {
      console.error('⚠️ Financial summary update failed:', summaryError.message);
    }

    // Format response with proper number conversion
    const formattedIncome = {
      _id: income._id,
      userId: income.userId,
      title: income.title,
      description: income.description,
      amount: parseFloat(income.amount.toString()),
      category: income.category,
      date: income.date,
      paymentMethod: income.paymentMethod,
      source: income.source,
      isConfirmed: income.isConfirmed,
      isRecurring: income.isRecurring,
      recurringDetails: income.recurringDetails,
      taxInfo: income.taxInfo ? {
        isTaxable: income.taxInfo.isTaxable,
        taxRate: income.taxInfo.taxRate || 0,
        taxAmount: income.taxInfo.taxAmount ? parseFloat(income.taxInfo.taxAmount.toString()) : 0,
      } : null,
      createdAt: income.createdAt,
      updatedAt: income.updatedAt,
    };

    res.status(201).json({
      success: true,
      message: "Income created successfully",
      data: formattedIncome
    });
  } catch (error) {
    console.error("❌ Create income error:", error);
    throw new BadRequestError(error.message);
  }
};

/**
 * @desc    Get all incomes for user
 * @route   GET /api/income
 * @access  Private
 */
export const getIncomes = async (req, res) => {
  const userId = req.userId;
  const {
    category,
    startDate,
    endDate,
    isRecurring,
    page = 1,
    limit = 50,
    sort = "-date",
  } = req.query;

  try {
    const query = { userId, isConfirmed: true };

    // Filters
    if (category) query.category = category;
    if (isRecurring !== undefined) query.isRecurring = isRecurring === "true";
    if (startDate && endDate) {
      query.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [incomes, total] = await Promise.all([
      Income.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Income.countDocuments(query),
    ]);

    // Convert Decimal128 to numbers
    const formattedIncomes = incomes.map((income) => ({
      ...income,
      amount: parseFloat(income.amount.toString()),
    }));

    res.status(200).json({
      success: true,
      message: "Incomes retrieved successfully",
      data: {
        incomes: formattedIncomes,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit)),
        },
      }
    });
  } catch (error) {
    console.error("Get incomes error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve incomes",
    });
  }
};

/**
 * @desc    Get income by ID
 * @route   GET /api/income/:id
 * @access  Private
 */
export const getIncomeById = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;

  try {
    const income = await Income.findOne({ _id: id, userId });

    if (!income) {
      throw new NotFoundError("Income not found");
    }

    const formattedIncome = {
      ...income.toObject(),
      amount: parseFloat(income.amount.toString()),
    };

    res.status(200).json({
      success: true,
      message: "Income retrieved successfully",
      data: formattedIncome
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    res.status(500).json({
      success: false,
      error: "Failed to retrieve income",
    });
  }
};

/**
 * @desc    Update income
 * @route   PUT /api/income/:id
 * @access  Private
 */
export const updateIncome = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;

  try {
    const income = await Income.findOne({ _id: id, userId });

    if (!income) {
      throw new NotFoundError("Income not found");
    }

    const oldAmount = parseFloat(income.amount.toString());

    // Update fields
    const allowedUpdates = [
      "title",
      "description",
      "amount",
      "category",
      "date",
      "paymentMethod",
      "source",
      "notes",
    ];

    allowedUpdates.forEach((field) => {
      if (req.body[field] !== undefined) {
        income[field] = req.body[field];
      }
    });

    await income.save();

    // Update user's financial summary if amount changed
    const newAmount = parseFloat(income.amount.toString());
    if (oldAmount !== newAmount) {
      const amountDiff = newAmount - oldAmount;
      await User.findByIdAndUpdate(
        userId,
        {
          $inc: {
            'financialSummary.totalIncome': amountDiff,
            'financialSummary.currentBalance': amountDiff,
          },
          'financialSummary.lastUpdated': new Date(),
        },
        { new: true }
      );
    }

    const formattedIncome = {
      ...income.toObject(),
      amount: parseFloat(income.amount.toString()),
    };

    res.status(200).json({
      success: true,
      message: "Income updated successfully",
      data: formattedIncome
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    console.error("Update income error:", error);
    throw new BadRequestError(error.message);
  }
};

/**
 * @desc    Delete income
 * @route   DELETE /api/income/:id
 * @access  Private
 */
export const deleteIncome = async (req, res) => {
  const userId = req.userId;
  const { id } = req.params;

  try {
    const income = await Income.findOneAndDelete({ _id: id, userId });

    if (!income) {
      throw new NotFoundError("Income not found");
    }

    const amount = parseFloat(income.amount.toString());

    // Update user's financial summary
    await User.findByIdAndUpdate(
      userId,
      {
        $inc: {
          'financialSummary.totalIncome': -amount,
          'financialSummary.currentBalance': -amount,
        },
        'financialSummary.lastUpdated': new Date(),
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Income deleted successfully",
      data: null
    });
  } catch (error) {
    if (error instanceof NotFoundError) throw error;
    console.error("Delete income error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to delete income",
    });
  }
};

/**
 * @desc    Get income statistics
 * @route   GET /api/income/stats
 * @access  Private
 */
export const getIncomeStats = async (req, res) => {
  const userId = req.userId;
  const { startDate, endDate, groupBy = "category" } = req.query;

  try {
    const match = {
      userId: new mongoose.Types.ObjectId(userId),
      isConfirmed: true,
    };

    if (startDate && endDate) {
      match.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    let groupByField = "$category";
    if (groupBy === "month") {
      groupByField = { $month: "$date" };
    } else if (groupBy === "paymentMethod") {
      groupByField = "$paymentMethod";
    }

    const stats = await Income.aggregate([
      { $match: match },
      {
        $group: {
          _id: groupByField,
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
          avgAmount: { $avg: { $toDouble: "$amount" } },
        },
      },
      { $sort: { total: -1 } },
    ]);

    // Get total
    const totalStats = await Income.aggregate([
      { $match: match },
      {
        $group: {
          _id: null,
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
        },
      },
    ]);

    res.status(200).json({
      success: true,
      message: "Income statistics retrieved successfully",
      data: {
        stats,
        total: totalStats[0] || { total: 0, count: 0 },
      }
    });
  } catch (error) {
    console.error("Get income stats error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve income statistics",
    });
  }
};


export default {
  createIncome,
  getIncomes,
  getIncomeById,
  updateIncome,
  deleteIncome,
  getIncomeStats,
};
