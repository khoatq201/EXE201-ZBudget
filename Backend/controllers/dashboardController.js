import { User, Expense, Income, Budget } from "../models/index.js";
import { successResponse } from "../middleware/errorHandler.js";
import mongoose from "mongoose";

/**
 * @desc    Get dashboard summary - All data needed for dashboard screen
 * @route   GET /api/dashboard/summary
 * @access  Private
 */
export const getDashboardSummary = async (req, res) => {
  const userId = req.userId;
  const { period = "month" } = req.query; // month, week, year

  console.log("🎯 getDashboardSummary called for userId:", userId);

  try {
    // Get date range based on period
    const dateRange = getDateRange(period);
    const { startDate, endDate } = dateRange;
    console.log("📅 Date range:", { startDate, endDate, period });

    console.log("⏳ Starting parallel queries...");
    console.log("🆔 userId type:", typeof userId, "value:", userId);

    // Parallel queries for performance
    const [user, incomeStats, expenseStats, recentTransactions, activeBudget] =
      await Promise.all([
        // 1. Get user with financial summary
        User.findById(userId).select(
          "email profile.name financialSummary stats"
        ),

        // 2. Get income statistics for period
        Income.aggregate([
          {
            $match: {
              userId: new mongoose.Types.ObjectId(userId),
              date: { $gte: startDate, $lte: endDate },
              isConfirmed: true,
            },
          },
          {
            $group: {
              _id: null,
              totalIncome: { $sum: { $toDouble: "$amount" } },
              count: { $sum: 1 },
            },
          },
        ]),

        // 3. Get expense statistics for period
        Expense.aggregate([
          {
            $match: {
              userId: new mongoose.Types.ObjectId(userId),
              date: { $gte: startDate, $lte: endDate },
            },
          },
          {
            $group: {
              _id: null,
              totalExpense: { $sum: { $toDouble: "$amount" } },
              count: { $sum: 1 },
            },
          },
        ]),

        // 4. Get recent transactions (combined income + expense)
        getRecentTransactions(userId, 5),

        // 5. Get active budget for current month
        Budget.findOne({
          userId: new mongoose.Types.ObjectId(userId),
          isActive: true,
          "period.startDate": { $lte: new Date() },
          "period.endDate": { $gte: new Date() },
        }),
      ]);

    console.log("✅ All parallel queries completed!");
    console.log("📊 Results:", {
      user: user ? "found" : "not found",
      incomeStats: incomeStats?.length || 0,
      expenseStats: expenseStats?.length || 0,
      transactions: recentTransactions?.length || 0,
      budget: activeBudget ? "found" : "not found"
    });

    // Calculate summary
    const periodIncome = incomeStats[0]?.totalIncome || 0;
    const periodExpense = expenseStats[0]?.totalExpense || 0;
    const periodBalance = periodIncome - periodExpense;

    // Get financial summary from user
    const financialSummary = user.financialSummary || {};
    const currentBalance = parseFloat(
      financialSummary.currentBalance?.toString() || "0"
    );
    const totalIncome = parseFloat(
      financialSummary.totalIncome?.toString() || "0"
    );
    const totalExpenses = parseFloat(
      financialSummary.totalExpenses?.toString() || "0"
    );
    const monthlyAllowance = parseFloat(
      financialSummary.monthlyAllowance?.toString() || "0"
    );
    const totalSavings = parseFloat(
      financialSummary.totalSavings?.toString() || "0"
    );

    // Budget info
    let budgetInfo = null;
    if (activeBudget) {
      const budgetTotal = parseFloat(
        activeBudget.totalAmount?.toString() || "0"
      );
      const budgetSpent = parseFloat(
        activeBudget.status?.totalSpent?.toString() || "0"
      );
      const budgetRemaining = budgetTotal - budgetSpent;
      const spentPercentage = activeBudget.status?.spentPercentage || 0;

      // Calculate daily budget (remaining / remaining days)
      const now = new Date();
      const endDate = new Date(activeBudget.period.endDate);
      const remainingDays = Math.ceil(
        (endDate - now) / (1000 * 60 * 60 * 24)
      );
      const dailyBudget =
        remainingDays > 0 ? Math.floor(budgetRemaining / remainingDays) : 0;

      budgetInfo = {
        id: activeBudget._id,
        name: activeBudget.name,
        totalAmount: budgetTotal,
        spent: budgetSpent,
        remaining: budgetRemaining,
        spentPercentage: Math.round(spentPercentage),
        dailyBudget,
        remainingDays,
        isOverBudget: activeBudget.status?.isOverBudget || false,
        periodType: activeBudget.period.type,
        startDate: activeBudget.period.startDate,
        endDate: activeBudget.period.endDate,
      };
    }

    // Spending insights
    const insights = generateInsights({
      periodExpense,
      periodIncome,
      currentBalance,
      budgetInfo,
      monthlyAllowance,
    });

    // Category breakdown for period
    const categoryBreakdown = await Expense.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          date: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: "$category",
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
        },
      },
      { $sort: { total: -1 } },
      { $limit: 5 },
    ]);

    const response = {
      // Financial summary
      currentBalance,
      totalIncome,
      totalExpenses,
      totalSavings,
      monthlyAllowance,

      // Period statistics
      period: {
        type: period,
        startDate,
        endDate,
        income: periodIncome,
        expense: periodExpense,
        balance: periodBalance,
        incomeCount: incomeStats[0]?.count || 0,
        expenseCount: expenseStats[0]?.count || 0,
      },

      // Budget information
      budget: budgetInfo,

      // Recent transactions
      recentTransactions,

      // Category breakdown
      categoryBreakdown: categoryBreakdown.map((cat) => ({
        category: cat._id,
        total: cat.total,
        count: cat.count,
        percentage:
          periodExpense > 0
            ? Math.round((cat.total / periodExpense) * 100)
            : 0,
      })),

      // Insights & recommendations
      insights,

      // User stats
      userStats: {
        level: user.stats?.level || 1,
        points: user.stats?.points || 0,
        currentStreak: user.stats?.currentStreak || 0,
        longestStreak: user.stats?.longestStreak || 0,
      },

      // Metadata
      generatedAt: new Date(),
    };

    res.status(200).json({
      success: true,
      message: "Dashboard data retrieved successfully",
      data: response
    });
  } catch (error) {
    console.error("Dashboard summary error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve dashboard data",
    });
  }
};

/**
 * Get date range based on period type
 * Returns UTC dates to match database stored dates
 */
function getDateRange(period) {
  const now = new Date();
  let startDate, endDate;

  switch (period) {
    case "week":
      // Last 7 days from today (UTC)
      startDate = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() - 7, 0, 0, 0, 0));
      endDate = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999));
      break;

    case "year":
      // Current year: Jan 1 00:00:00 to Dec 31 23:59:59 (UTC)
      startDate = new Date(Date.UTC(now.getFullYear(), 0, 1, 0, 0, 0, 0));
      endDate = new Date(Date.UTC(now.getFullYear(), 11, 31, 23, 59, 59, 999));
      break;

    case "month":
    default:
      // Current month: 1st 00:00:00 to last day 23:59:59 (UTC)
      startDate = new Date(Date.UTC(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0));
      endDate = new Date(Date.UTC(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999));
      break;
  }

  return { startDate, endDate };
}

/**
 * @desc    Get all transactions with filtering
 * @route   GET /api/dashboard/transactions
 * @access  Private
 */
export const getAllTransactions = async (req, res) => {
  const userId = req.userId;
  const { type, startDate, endDate, limit, skip } = req.query;

  try {
    console.log("📋 getAllTransactions called:", { userId, type, startDate, endDate, limit, skip });

    // Build date filter
    const dateFilter = {};
    if (startDate || endDate) {
      dateFilter.date = {};
      if (startDate) dateFilter.date.$gte = new Date(startDate);
      if (endDate) dateFilter.date.$lte = new Date(endDate);
    }

    // Fetch based on type filter
    let incomes = [];
    let expenses = [];

    if (type === "income" || !type || type === "all") {
      incomes = await Income.find({
        userId: new mongoose.Types.ObjectId(userId),
        isConfirmed: true,
        ...dateFilter,
      })
        .select("title description amount category date paymentMethod createdAt")
        .sort({ date: -1 })
        .lean();
    }

    if (type === "expense" || !type || type === "all") {
      expenses = await Expense.find({
        userId: new mongoose.Types.ObjectId(userId),
        ...dateFilter,
      })
        .select("title description amount category date paymentMethod createdAt")
        .sort({ date: -1 })
        .lean();
    }

    // Combine and format transactions
    const transactions = [
      ...incomes.map((inc) => ({
        ...inc,
        type: "income",
        isIncome: true,
        amount: parseFloat(inc.amount.toString()),
      })),
      ...expenses.map((exp) => ({
        ...exp,
        type: "expense",
        isIncome: false,
        amount: parseFloat(exp.amount.toString()),
      })),
    ];

    // Sort by date descending, then by createdAt for same-day transactions
    transactions.sort((a, b) => {
      const dateCompare = new Date(b.date) - new Date(a.date);
      if (dateCompare !== 0) return dateCompare;
      // If same date, sort by createdAt (newest first)
      return new Date(b.createdAt) - new Date(a.createdAt);
    });

    // Apply pagination if provided
    const skipNum = parseInt(skip) || 0;
    const limitNum = parseInt(limit) || transactions.length;
    const paginatedTransactions = transactions.slice(skipNum, skipNum + limitNum);

    console.log(`✅ Found ${transactions.length} transactions, returning ${paginatedTransactions.length}`);

    res.status(200).json({
      success: true,
      message: "Transactions retrieved successfully",
      data: {
        transactions: paginatedTransactions,
        total: transactions.length,
        hasMore: skipNum + limitNum < transactions.length,
      },
    });
  } catch (error) {
    console.error("❌ Get all transactions error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve transactions",
    });
  }
};

/**
 * Get recent transactions (combined income + expense)
 */
async function getRecentTransactions(userId, limit = 10) {
  const [incomes, expenses] = await Promise.all([
    Income.find({
      userId: new mongoose.Types.ObjectId(userId),
      isConfirmed: true,
    })
      .select("title description amount category date paymentMethod createdAt")
      .sort({ date: -1, createdAt: -1 })
      .limit(limit)
      .lean(),

    Expense.find({ userId: new mongoose.Types.ObjectId(userId) })
      .select("title description amount category date paymentMethod createdAt")
      .sort({ date: -1, createdAt: -1 })
      .limit(limit)
      .lean(),
  ]);

  // Combine and mark type
  const transactions = [
    ...incomes.map((inc) => ({
      ...inc,
      type: "income",
      isIncome: true,
      amount: parseFloat(inc.amount.toString()),
    })),
    ...expenses.map((exp) => ({
      ...exp,
      type: "expense",
      isIncome: false,
      amount: parseFloat(exp.amount.toString()),
    })),
  ];

  // Sort by date descending, then by createdAt for same-day transactions
  transactions.sort((a, b) => {
    const dateCompare = new Date(b.date) - new Date(a.date);
    if (dateCompare !== 0) return dateCompare;
    // If same date, sort by createdAt (newest first)
    return new Date(b.createdAt) - new Date(a.createdAt);
  });

  return transactions.slice(0, limit);
}

/**
 * Generate insights based on financial data
 */
function generateInsights({ periodExpense, periodIncome, currentBalance, budgetInfo, monthlyAllowance }) {
  const insights = [];

  // Budget insights
  if (budgetInfo) {
    if (budgetInfo.spentPercentage >= 90) {
      insights.push({
        type: "warning",
        icon: "⚠️",
        title: "Ngân sách sắp hết",
        message: `Bạn đã chi ${budgetInfo.spentPercentage}% ngân sách tháng này`,
        action: "Giảm chi tiêu",
      });
    } else if (budgetInfo.spentPercentage >= 70) {
      insights.push({
        type: "info",
        icon: "📊",
        title: "Theo dõi ngân sách",
        message: `Đã dùng ${budgetInfo.spentPercentage}% ngân sách`,
        action: "Xem chi tiết",
      });
    } else {
      insights.push({
        type: "success",
        icon: "✅",
        title: "Ngân sách ổn định",
        message: `Còn ${budgetInfo.remaining.toLocaleString()} VND trong tháng`,
        action: null,
      });
    }

    // Daily budget recommendation
    if (budgetInfo.dailyBudget > 0) {
      insights.push({
        type: "info",
        icon: "💰",
        title: "Ngân sách hàng ngày",
        message: `Nên chi tối đa ${budgetInfo.dailyBudget.toLocaleString()} VND/ngày`,
        action: null,
      });
    }
  }

  // Balance insights
  if (currentBalance < monthlyAllowance * 0.2) {
    insights.push({
      type: "warning",
      icon: "🏦",
      title: "Số dư thấp",
      message: "Cân nhắc tăng thu nhập hoặc giảm chi tiêu",
      action: "Xem gợi ý",
    });
  }

  // Income vs Expense
  if (periodIncome > 0 && periodExpense > periodIncome) {
    insights.push({
      type: "alert",
      icon: "📉",
      title: "Chi nhiều hơn thu",
      message: `Chi vượt thu ${(
        periodExpense - periodIncome
      ).toLocaleString()} VND tháng này`,
      action: "Điều chỉnh",
    });
  } else if (periodIncome > 0 && periodExpense < periodIncome * 0.7) {
    insights.push({
      type: "success",
      icon: "🎯",
      title: "Tiết kiệm tốt",
      message: `Tiết kiệm được ${(periodIncome - periodExpense).toLocaleString()} VND`,
      action: null,
    });
  }

  return insights;
}

/**
 * @desc    Get quick stats for widgets
 * @route   GET /api/dashboard/quick-stats
 * @access  Private
 */
export const getQuickStats = async (req, res) => {
  const userId = req.userId;

  try {
    const user = await User.findById(userId).select("financialSummary");

    const stats = {
      currentBalance: parseFloat(
        user.financialSummary?.currentBalance?.toString() || "0"
      ),
      totalIncome: parseFloat(
        user.financialSummary?.totalIncome?.toString() || "0"
      ),
      totalExpenses: parseFloat(
        user.financialSummary?.totalExpenses?.toString() || "0"
      ),
      totalSavings: parseFloat(
        user.financialSummary?.totalSavings?.toString() || "0"
      ),
    };

    res.status(200).json({
      success: true,
      message: "Quick stats retrieved",
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Failed to retrieve stats",
    });
  }
};

export default {
  getDashboardSummary,
  getQuickStats,
};
