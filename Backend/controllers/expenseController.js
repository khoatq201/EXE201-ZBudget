import Expense from "../models/Expense.js";
import Budget from "../models/Budget.js";
import { User } from "../models/index.js";
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  successResponse,
} from "../middleware/errorHandler.js";
import {
  performanceLogger,
  dbLogger,
  errorLogger,
} from "../middleware/logger.js";
import { getFileUrl, deleteFile } from "../middleware/upload.js";
import mongoose from "mongoose";

// ✅ NEW: Import utilities and services
import { FinancialSummaryService } from "../services/financialSummaryService.js";
import { toNumber } from "../utils/currencyHelper.js";
/**
 * @desc    Tạo chi tiêu mới
 * @route   POST /api/expenses
 * @access  Private
 */
export const createExpense = async (req, res) => {
  const startTime = Date.now();
  const userId = req.userId;
  const {
    title,
    description,
    amount,
    category,
    subcategory,
    date,
    paymentMethod,
    location,
    tags,
    groupId,
    budgetId,
    receiptFile,
  } = req.body;
  // Handle receipt upload
  let receipt = null;
  if (req.file || receiptFile) {
    const file = req.file || receiptFile;
    receipt = getFileUrl(file);
  }
  try {
    // Create expense
    const expense = new Expense({
      userId,
      title,
      description,
      amount,
      category,
      subcategory,
      date: new Date(date),
      paymentMethod,
      location,
      tags: tags || [],
      receipt,
      groupId: groupId || null,
      budgetId: budgetId || null,
    });
    await expense.save();
    // Update user financial summary
    try {
      const hasBudget = !!budgetId;
      await FinancialSummaryService.addExpense(userId, amount, hasBudget); // ✅ Pass hasBudget flag
    } catch (summaryError) {
      console.error('⚠️ Financial summary update failed:', summaryError.message);
      // If it's readyToAssign validation error, delete the expense and throw
      if (summaryError.message.includes('Ready to Assign')) {
        await Expense.findByIdAndDelete(expense._id);
        throw summaryError;
      }
    }
    // Update budget if specified (simplified without transaction)
    if (budgetId) {
      try {
        const budget = await Budget.findOne({
          _id: budgetId,
          userId,
          isActive: true,
        });
        if (budget) {
          // Note: Budget model uses categoryAllocations, not categories
          const categoryAllocation = budget.categoryAllocations?.find(
            (cat) => cat.category === category
          );
          if (categoryAllocation) {
            categoryAllocation.spent = (categoryAllocation.spent || 0) + amount;
            await budget.save();
          }
        }
      } catch (budgetError) {
        console.error('⚠️ Budget update failed (non-critical):', budgetError.message);
        // Don't fail the whole request if budget update fails
      }
    }
    res.locals.expenseId = expense._id;
    dbLogger("CREATE", "expenses", {
      expenseId: expense._id,
      userId,
      amount,
      category,
    });
    performanceLogger("create_expense", Date.now() - startTime, {
      userId,
      hasReceipt: !!receipt,
      hasBudget: !!budgetId,
    });
    return successResponse(res, "Tạo chi tiêu thành công!", { expense }, 201);
  } catch (error) {
    console.error('❌ Create expense error:', error);
    // Clean up uploaded file if failed
    if (receipt) {
      try {
        await deleteFile(receipt);
      } catch (cleanupError) {
        console.error(
          "Error cleaning up file after failed request:",
          cleanupError
        );
      }
    }
    throw error;
  }
};
/**
 * @desc    Lấy danh sách chi tiêu
 * @route   GET /api/expenses
 * @access  Private
 */
export const getExpenses = async (req, res) => {
  const startTime = Date.now();
  const userId = req.userId;
  const {
    page = 1,
    limit = 20,
    sort = "desc",
    startDate,
    endDate,
    category,
    subcategory,
    minAmount,
    maxAmount,
    paymentMethod,
    tags,
    groupId,
    budgetId,
    search,
  } = req.query;
  // Build query
  const query = { userId };
  // Date range filter
  if (startDate || endDate) {
    query.date = {};
    if (startDate) query.date.$gte = new Date(startDate);
    if (endDate) query.date.$lte = new Date(endDate);
  }
  // Category filters
  if (category) query.category = category;
  if (subcategory) query.subcategory = subcategory;
  // Amount range
  if (minAmount || maxAmount) {
    query.amount = {};
    if (minAmount) query.amount.$gte = parseInt(minAmount);
    if (maxAmount) query.amount.$lte = parseInt(maxAmount);
  }
  // Payment method
  if (paymentMethod) query.paymentMethod = paymentMethod;
  // Tags filter
  if (tags) {
    const tagArray = Array.isArray(tags) ? tags : [tags];
    query.tags = { $in: tagArray };
  }
  // Group and budget filters
  if (groupId) query.groupId = groupId;
  if (budgetId) query.budgetId = budgetId;
  // Text search
  if (search) {
    query.$or = [
      { title: { $regex: search, $options: "i" } },
      { description: { $regex: search, $options: "i" } },
      { location: { $regex: search, $options: "i" } },
    ];
  }
  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const sortOrder = sort === "asc" ? 1 : -1;
  // Execute query
  const [expenses, total] = await Promise.all([
    Expense.find(query)
      .sort({ date: sortOrder, createdAt: sortOrder })
      .skip(skip)
      .limit(parseInt(limit))
      .populate([
        { path: "budgetId", select: "name totalAmount" },
        { path: "groupId", select: "name type" },
      ])
      .lean(),
    Expense.countDocuments(query),
  ]);
  // Calculate totals for current filter
  const totalAmount = await Expense.aggregate([
    { $match: query },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);
  const pagination = {
    currentPage: parseInt(page),
    totalPages: Math.ceil(total / parseInt(limit)),
    totalItems: total,
    itemsPerPage: parseInt(limit),
    hasNextPage: parseInt(page) < Math.ceil(total / parseInt(limit)),
    hasPrevPage: parseInt(page) > 1,
  };
  performanceLogger("get_expenses", Date.now() - startTime, {
    userId,
    resultCount: expenses.length,
    hasFilters: Object.keys(query).length > 1,
  });
  return successResponse(res, "Lấy danh sách chi tiêu thành công", {
    expenses,
    pagination,
    totalAmount: totalAmount[0]?.total || 0,
    filters: {
      startDate,
      endDate,
      category,
      subcategory,
      paymentMethod,
      tags,
      search,
    },
  });
};
/**
 * @desc    Lấy chi tiết một chi tiêu
 * @route   GET /api/expenses/:id
 * @access  Private
 */
export const getExpenseById = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const expense = await Expense.findOne({ _id: id, userId }).populate([
    { path: "budgetId", select: "name totalAmount categories" },
    { path: "groupId", select: "name type members" },
  ]);
  if (!expense) {
    throw new NotFoundError("Không tìm thấy chi tiêu");
  }
  return successResponse(res, "Lấy chi tiết chi tiêu thành công", { expense });
};
/**
 * @desc    Cập nhật chi tiêu
 * @route   PUT /api/expenses/:id
 * @access  Private
 */
export const updateExpense = async (req, res) => {
  const startTime = Date.now();
  const { id } = req.params;
  const userId = req.userId;
  const {
    title,
    description,
    amount,
    category,
    subcategory,
    date,
    paymentMethod,
    location,
    tags,
    receiptFile,
    removeReceipt,
  } = req.body;
  const expense = await Expense.findOne({ _id: id, userId });
  if (!expense) {
    throw new NotFoundError("Không tìm thấy chi tiêu");
  }
  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    const oldAmount = expense.amount;
    const oldCategory = expense.category;
    const oldBudgetId = expense.budgetId;
    const newBudgetId = req.body.budgetId !== undefined ? req.body.budgetId : expense.budgetId;

    // Handle receipt update
    if (receiptFile || req.file) {
      // Delete old receipt if exists
      if (expense.receipt) {
        try {
          await deleteFile(expense.receipt);
        } catch (error) {
          console.error("Error deleting old receipt:", error);
        }
      }
      // Set new receipt
      const file = receiptFile || req.file;
      expense.receipt = getFileUrl(file);
    } else if (removeReceipt) {
      // Remove receipt
      if (expense.receipt) {
        try {
          await deleteFile(expense.receipt);
        } catch (error) {
          console.error("Error deleting receipt:", error);
        }
      }
      expense.receipt = null;
    }
    // Update expense fields
    if (title !== undefined) expense.title = title;
    if (description !== undefined) expense.description = description;
    if (amount !== undefined) expense.amount = amount;
    if (category !== undefined) expense.category = category;
    if (subcategory !== undefined) expense.subcategory = subcategory;
    if (date !== undefined) expense.date = new Date(date);
    if (paymentMethod !== undefined) expense.paymentMethod = paymentMethod;
    if (location !== undefined) expense.location = location;
    if (tags !== undefined) expense.tags = tags;
    if (req.body.budgetId !== undefined) expense.budgetId = newBudgetId;
    await expense.save({ session });

    // Update financial summary if amount or budget changed
    if (amount !== undefined || req.body.budgetId !== undefined) {
      const newAmount = amount !== undefined ? amount : oldAmount;
      const oldHasBudget = !!oldBudgetId;
      const newHasBudget = !!newBudgetId;

      await FinancialSummaryService.updateExpense(
        userId,
        oldAmount,
        newAmount,
        oldHasBudget,
        newHasBudget
      );
    }
    // Update budget if amount or category changed
    if (expense.budgetId && (amount !== undefined || category !== undefined)) {
      const budget = await Budget.findById(expense.budgetId).session(session);
      if (budget) {
        // Remove old amount from old category
        const oldCategoryBudget = budget.categories.find(
          (cat) => cat.category === oldCategory
        );
        if (oldCategoryBudget) {
          oldCategoryBudget.spent = Math.max(
            0,
            (oldCategoryBudget.spent || 0) - oldAmount
          );
        }
        // Add new amount to new category
        const newCategoryBudget = budget.categories.find(
          (cat) => cat.category === expense.category
        );
        if (newCategoryBudget) {
          newCategoryBudget.spent =
            (newCategoryBudget.spent || 0) + expense.amount;
        }
        // Recalculate total spent
        budget.totalSpent = budget.categories.reduce(
          (total, cat) => total + (cat.spent || 0),
          0
        );
        await budget.save({ session });
      }
    }
    await session.commitTransaction();
    // Populate for response
    await expense.populate([
      { path: "budgetId", select: "name totalAmount" },
      { path: "groupId", select: "name type" },
    ]);
    dbLogger("UPDATE", "expenses", {
      expenseId: expense._id,
      userId,
      oldAmount,
      newAmount: expense.amount,
    });
    performanceLogger("update_expense", Date.now() - startTime, {
      userId,
      hasReceiptUpdate: !!(receiptFile || req.file || removeReceipt),
    });
    return successResponse(res, "Cập nhật chi tiêu thành công!", { expense });
  } catch (error) {
    await session.abortTransaction();
    // Clean up new file if transaction failed
    if (receiptFile || req.file) {
      const file = receiptFile || req.file;
      try {
        await deleteFile(getFileUrl(file));
      } catch (cleanupError) {
        console.error(
          "Error cleaning up file after failed update:",
          cleanupError
        );
      }
    }
    throw error;
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Xóa chi tiêu
 * @route   DELETE /api/expenses/:id
 * @access  Private
 */
export const deleteExpense = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const expense = await Expense.findOne({ _id: id, userId });
  if (!expense) {
    throw new NotFoundError("Không tìm thấy chi tiêu");
  }
  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    const hasBudget = !!expense.budgetId;

    // Update financial summary - return money if no budget
    await FinancialSummaryService.removeExpense(userId, expense.amount, hasBudget);

    // Update budget if expense was linked
    if (expense.budgetId) {
      const budget = await Budget.findById(expense.budgetId).session(session);
      if (budget) {
        const categoryBudget = budget.categories.find(
          (cat) => cat.category === expense.category
        );
        if (categoryBudget) {
          categoryBudget.spent = Math.max(
            0,
            (categoryBudget.spent || 0) - expense.amount
          );
          budget.totalSpent = Math.max(
            0,
            (budget.totalSpent || 0) - expense.amount
          );
          await budget.save({ session });
        }
      }
    }
    // Delete receipt file if exists
    if (expense.receipt) {
      try {
        await deleteFile(expense.receipt);
      } catch (error) {
        console.error("Error deleting receipt file:", error);
      }
    }
    // Delete expense
    await Expense.deleteOne({ _id: id }, { session });
    await session.commitTransaction();
    dbLogger("DELETE", "expenses", {
      expenseId: id,
      userId,
      amount: expense.amount,
      category: expense.category,
    });
    return successResponse(res, "Xóa chi tiêu thành công!");
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Lấy thống kê chi tiêu
 * @route   GET /api/expenses/stats
 * @access  Private
 */
export const getExpenseStats = async (req, res) => {
  const startTime = Date.now();
  const userId = req.userId;
  const { startDate, endDate, groupBy = "category", category } = req.query;
  // Build base query
  const baseQuery = { userId };
  if (startDate || endDate) {
    baseQuery.date = {};
    if (startDate) baseQuery.date.$gte = new Date(startDate);
    if (endDate) baseQuery.date.$lte = new Date(endDate);
  }
  if (category) baseQuery.category = category;
  let groupStage;
  let sortStage = { totalAmount: -1 };
  switch (groupBy) {
    case "day":
      groupStage = {
        _id: {
          year: { $year: "$date" },
          month: { $month: "$date" },
          day: { $dayOfMonth: "$date" },
        },
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      };
      sortStage = { "_id.year": -1, "_id.month": -1, "_id.day": -1 };
      break;
    case "week":
      groupStage = {
        _id: {
          year: { $year: "$date" },
          week: { $week: "$date" },
        },
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      };
      sortStage = { "_id.year": -1, "_id.week": -1 };
      break;
    case "month":
      groupStage = {
        _id: {
          year: { $year: "$date" },
          month: { $month: "$date" },
        },
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      };
      sortStage = { "_id.year": -1, "_id.month": -1 };
      break;
    case "year":
      groupStage = {
        _id: { year: { $year: "$date" } },
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      };
      sortStage = { "_id.year": -1 };
      break;
    case "paymentMethod":
      groupStage = {
        _id: "$paymentMethod",
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      };
      break;
    default: // category
      groupStage = {
        _id: "$category",
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
        subcategories: {
          $push: {
            subcategory: "$subcategory",
            amount: "$amount",
          },
        },
      };
      break;
  }
  const pipeline = [
    { $match: baseQuery },
    { $group: groupStage },
    { $sort: sortStage },
    { $limit: 100 }, // Limit results for performance
  ];
  const [stats, summary] = await Promise.all([
    Expense.aggregate(pipeline),
    Expense.aggregate([
      { $match: baseQuery },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: "$amount" },
          totalCount: { $sum: 1 },
          avgAmount: { $avg: "$amount" },
          maxAmount: { $max: "$amount" },
          minAmount: { $min: "$amount" },
        },
      },
    ]),
  ]);
  performanceLogger("get_expense_stats", Date.now() - startTime, {
    userId,
    groupBy,
    hasDateFilter: !!(startDate || endDate),
    resultCount: stats.length,
  });
  return successResponse(res, "Lấy thống kê chi tiêu thành công", {
    stats,
    summary: summary[0] || {
      totalAmount: 0,
      totalCount: 0,
      avgAmount: 0,
      maxAmount: 0,
      minAmount: 0,
    },
    groupBy,
    period: { startDate, endDate },
  });
};
/**
 * @desc    Lấy chi tiêu theo danh mục
 * @route   GET /api/expenses/by-category
 * @access  Private
 */
export const getExpensesByCategory = async (req, res) => {
  const userId = req.userId;
  const { startDate, endDate, includeSubcategories = false } = req.query;
  const baseQuery = { userId };
  if (startDate || endDate) {
    baseQuery.date = {};
    if (startDate) baseQuery.date.$gte = new Date(startDate);
    if (endDate) baseQuery.date.$lte = new Date(endDate);
  }
  let pipeline = [
    { $match: baseQuery },
    {
      $group: {
        _id: "$category",
        totalAmount: { $sum: "$amount" },
        count: { $sum: 1 },
        avgAmount: { $avg: "$amount" },
      },
    },
    { $sort: { totalAmount: -1 } },
  ];
  if (includeSubcategories) {
    pipeline = [
      { $match: baseQuery },
      {
        $group: {
          _id: {
            category: "$category",
            subcategory: "$subcategory",
          },
          totalAmount: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      {
        $group: {
          _id: "$_id.category",
          totalAmount: { $sum: "$totalAmount" },
          count: { $sum: "$count" },
          subcategories: {
            $push: {
              name: "$_id.subcategory",
              amount: "$totalAmount",
              count: "$count",
            },
          },
        },
      },
      { $sort: { totalAmount: -1 } },
    ];
  }
  const categories = await Expense.aggregate(pipeline);
  return successResponse(res, "Lấy chi tiêu theo danh mục thành công", {
    categories,
    includeSubcategories,
  });
};
/**
 * @desc    Lấy chi tiêu theo khoảng thời gian
 * @route   GET /api/expenses/by-date-range
 * @access  Private
 */
export const getExpensesByDateRange = async (req, res) => {
  const userId = req.userId;
  const { startDate, endDate, groupBy = "day" } = req.query;
  const baseQuery = {
    userId,
    date: {
      $gte: new Date(startDate),
      $lte: new Date(endDate),
    },
  };
  let groupStage;
  switch (groupBy) {
    case "week":
      groupStage = {
        _id: {
          year: { $year: "$date" },
          week: { $week: "$date" },
        },
      };
      break;
    case "month":
      groupStage = {
        _id: {
          year: { $year: "$date" },
          month: { $month: "$date" },
        },
      };
      break;
    default: // day
      groupStage = {
        _id: {
          year: { $year: "$date" },
          month: { $month: "$date" },
          day: { $dayOfMonth: "$date" },
        },
      };
      break;
  }
  groupStage.totalAmount = { $sum: "$amount" };
  groupStage.count = { $sum: 1 };
  const expenses = await Expense.aggregate([
    { $match: baseQuery },
    { $group: groupStage },
    { $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1, "_id.week": 1 } },
  ]);
  return successResponse(res, "Lấy chi tiêu theo thời gian thành công", {
    expenses,
    groupBy,
    period: { startDate, endDate },
  });
};
/**
 * @desc    Xuất dữ liệu chi tiêu
 * @route   GET /api/expenses/export
 * @access  Private
 */
export const exportExpenses = async (req, res) => {
  const userId = req.userId;
  const {
    format = "csv",
    startDate,
    endDate,
    category,
    includeReceipts = false,
  } = req.query;
  const query = { userId };
  if (startDate || endDate) {
    query.date = {};
    if (startDate) query.date.$gte = new Date(startDate);
    if (endDate) query.date.$lte = new Date(endDate);
  }
  if (category) query.category = category;
  const expenses = await Expense.find(query)
    .populate("budgetId", "name")
    .populate("groupId", "name")
    .sort({ date: -1 });
  // Format data for export
  const exportData = expenses.map((expense) => ({
    Ngày: expense.date.toLocaleDateString("vi-VN"),
    "Tiêu đề": expense.title,
    "Mô tả": expense.description || "",
    "Số tiền": expense.amount,
    "Danh mục": expense.category,
    "Danh mục phụ": expense.subcategory || "",
    "Phương thức thanh toán": expense.paymentMethod,
    "Địa điểm": expense.location || "",
    Thẻ: expense.tags.join(", "),
    "Ngân sách": expense.budgetId?.name || "",
    Nhóm: expense.groupId?.name || "",
    ...(includeReceipts && { "Hóa đơn": expense.receipt || "" }),
  }));
  if (format === "csv") {
    // Convert to CSV (simplified implementation)
    const headers = Object.keys(exportData[0] || {});
    const csvContent = [
      headers.join(","),
      ...exportData.map((row) =>
        headers
          .map(
            (header) =>
              `"${(row[header] || "").toString().replace(/"/g, '""')}"`
          )
          .join(",")
      ),
    ].join("\n");
    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=chi-tieu-${Date.now()}.csv`
    );
    res.send("\uFEFF" + csvContent); // Add BOM for UTF-8
  } else {
    // For Excel format, return JSON that frontend can convert
    return successResponse(res, "Xuất dữ liệu thành công", {
      data: exportData,
      format,
      total: exportData.length,
    });
  }
};
/**
 * @desc    Xóa nhiều chi tiêu
 * @route   DELETE /api/expenses
 * @access  Private
 */
export const bulkDeleteExpenses = async (req, res) => {
  const { expenseIds } = req.body;
  const userId = req.userId;
  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    // Find expenses to delete
    const expenses = await Expense.find({
      _id: { $in: expenseIds },
      userId,
    }).session(session);
    if (expenses.length === 0) {
      throw new NotFoundError("Không tìm thấy chi tiêu nào để xóa");
    }
    // Update budgets
    const budgetUpdates = {};
    const receiptFiles = [];
    for (const expense of expenses) {
      // Collect receipt files for deletion
      if (expense.receipt) {
        receiptFiles.push(expense.receipt);
      }
      // Calculate budget updates
      if (expense.budgetId) {
        const budgetId = expense.budgetId.toString();
        if (!budgetUpdates[budgetId]) {
          budgetUpdates[budgetId] = {};
        }
        const category = expense.category;
        if (!budgetUpdates[budgetId][category]) {
          budgetUpdates[budgetId][category] = 0;
        }
        budgetUpdates[budgetId][category] += expense.amount;
      }
    }
    // Update budgets
    for (const [budgetId, categories] of Object.entries(budgetUpdates)) {
      const budget = await Budget.findById(budgetId).session(session);
      if (budget) {
        let totalReduction = 0;
        for (const [category, amount] of Object.entries(categories)) {
          const categoryBudget = budget.categories.find(
            (cat) => cat.category === category
          );
          if (categoryBudget) {
            categoryBudget.spent = Math.max(
              0,
              (categoryBudget.spent || 0) - amount
            );
            totalReduction += amount;
          }
        }
        budget.totalSpent = Math.max(
          0,
          (budget.totalSpent || 0) - totalReduction
        );
        await budget.save({ session });
      }
    }
    // Delete expenses
    const result = await Expense.deleteMany(
      {
        _id: { $in: expenseIds },
        userId,
      },
      { session }
    );
    await session.commitTransaction();
    // Delete receipt files
    for (const receiptUrl of receiptFiles) {
      try {
        await deleteFile(receiptUrl);
      } catch (error) {
        console.error("Error deleting receipt file:", error);
      }
    }
    dbLogger("BULK_DELETE", "expenses", {
      userId,
      deletedCount: result.deletedCount,
      expenseIds,
    });
    return successResponse(res, `Xóa thành công ${result.deletedCount} chi tiêu!`, {
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};
/**
 * @desc    Nhân bản chi tiêu
 * @route   POST /api/expenses/:id/duplicate
 * @access  Private
 */
export const duplicateExpense = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const { date, title, amount } = req.body;
  const originalExpense = await Expense.findOne({ _id: id, userId });
  if (!originalExpense) {
    throw new NotFoundError("Không tìm thấy chi tiêu");
  }
  // Create duplicate with modified fields
  const duplicateData = {
    ...originalExpense.toObject(),
    _id: undefined,
    date: date ? new Date(date) : new Date(),
    title: title || `${originalExpense.title} (Sao chép)`,
    amount: amount || originalExpense.amount,
    receipt: null, // Don't copy receipt
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  const duplicatedExpense = await Expense.create(duplicateData);
  // Populate for response
  await duplicatedExpense.populate([
    { path: "budgetId", select: "name totalAmount" },
    { path: "groupId", select: "name type" },
  ]);
  res.locals.expenseId = duplicatedExpense._id;
  return successResponse(res, "Nhân bản chi tiêu thành công!", {
    expense: duplicatedExpense,
  }, 201);
};