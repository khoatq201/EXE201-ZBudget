import { Expense, Income, Budget } from "../models/index.js";
import { successResponse } from "../middleware/errorHandler.js";
import mongoose from "mongoose";

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
      startDate = new Date(
        Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() - 7, 0, 0, 0, 0)
      );
      endDate = new Date(
        Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999)
      );
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
      endDate = new Date(
        Date.UTC(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999)
      );
      break;
  }

  return { startDate, endDate };
}

/**
 * Get date range for custom period
 */
function getCustomDateRange(startDateStr, endDateStr) {
  const start = startDateStr ? new Date(startDateStr) : new Date(Date.UTC(new Date().getFullYear(), 0, 1));
  const end = endDateStr ? new Date(endDateStr) : new Date();

  // Set to start of day for startDate, end of day for endDate
  const startDate = new Date(Date.UTC(start.getFullYear(), start.getMonth(), start.getDate(), 0, 0, 0, 0));
  const endDate = new Date(Date.UTC(end.getFullYear(), end.getMonth(), end.getDate(), 23, 59, 59, 999));

  return { startDate, endDate };
}

/**
 * @desc    Get trend report - Income vs Expense trends by period
 * @route   GET /api/reports/trend
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   startDate - ISO date string (optional, for custom range)
 * @query   endDate - ISO date string (optional, for custom range)
 */
export const getTrendReport = async (req, res) => {
  const userId = req.userId;
  const { period = "month", startDate: customStart, endDate: customEnd } = req.query;

  try {
    console.log("📈 getTrendReport called:", { userId, period, customStart, customEnd });

    // Get date range
    const dateRange = customStart || customEnd
      ? getCustomDateRange(customStart, customEnd)
      : getDateRange(period);
    const { startDate, endDate } = dateRange;

    // Determine grouping format based on period
    let groupByFormat;
    let dateFormat;
    switch (period) {
      case "week":
        groupByFormat = { $dateToString: { format: "%Y-%m-%d", date: "$date" } };
        dateFormat = "daily";
        break;
      case "year":
        groupByFormat = { $dateToString: { format: "%Y-%m", date: "$date" } };
        dateFormat = "monthly";
        break;
      case "month":
      default:
        groupByFormat = { $dateToString: { format: "%Y-%m-%d", date: "$date" } };
        dateFormat = "daily";
        break;
    }

    // Parallel queries for income and expense trends
    const [incomeTrend, expenseTrend] = await Promise.all([
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
            _id: groupByFormat,
            total: { $sum: { $toDouble: "$amount" } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),

      Expense.aggregate([
        {
          $match: {
            userId: new mongoose.Types.ObjectId(userId),
            date: { $gte: startDate, $lte: endDate },
          },
        },
        {
          $group: {
            _id: groupByFormat,
            total: { $sum: { $toDouble: "$amount" } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

    // Combine trends into a unified timeline
    const trendMap = new Map();

    incomeTrend.forEach((item) => {
      trendMap.set(item._id, {
        date: item._id,
        income: item.total,
        incomeCount: item.count,
        expense: 0,
        expenseCount: 0,
        balance: item.total,
      });
    });

    expenseTrend.forEach((item) => {
      if (trendMap.has(item._id)) {
        const existing = trendMap.get(item._id);
        existing.expense = item.total;
        existing.expenseCount = item.count;
        existing.balance = existing.income - item.total;
      } else {
        trendMap.set(item._id, {
          date: item._id,
          income: 0,
          incomeCount: 0,
          expense: item.total,
          expenseCount: item.count,
          balance: -item.total,
        });
      }
    });

    // Convert map to array and sort
    const trendData = Array.from(trendMap.values()).sort((a, b) =>
      a.date.localeCompare(b.date)
    );

    // Calculate totals
    const totalIncome = incomeTrend.reduce((sum, item) => sum + item.total, 0);
    const totalExpense = expenseTrend.reduce((sum, item) => sum + item.total, 0);
    const totalBalance = totalIncome - totalExpense;

    // Calculate averages
    const avgIncome = trendData.length > 0 ? totalIncome / trendData.length : 0;
    const avgExpense = trendData.length > 0 ? totalExpense / trendData.length : 0;

    res.status(200).json({
      success: true,
      message: "Trend report retrieved successfully",
      data: {
        period: {
          type: period,
          startDate,
          endDate,
          format: dateFormat,
        },
        summary: {
          totalIncome,
          totalExpense,
          totalBalance,
          avgIncome,
          avgExpense,
          savingsRate: totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0,
        },
        trendData,
        generatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("❌ Trend report error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve trend report",
    });
  }
};

/**
 * @desc    Get category report - Detailed breakdown by category
 * @route   GET /api/reports/categories
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   type - income|expense (default: expense)
 * @query   startDate - ISO date string (optional)
 * @query   endDate - ISO date string (optional)
 */
export const getCategoryReport = async (req, res) => {
  const userId = req.userId;
  const { period = "month", type = "expense", startDate: customStart, endDate: customEnd } = req.query;

  try {
    console.log("📊 getCategoryReport called:", { userId, period, type });

    // Get date range
    const dateRange = customStart || customEnd
      ? getCustomDateRange(customStart, customEnd)
      : getDateRange(period);
    const { startDate, endDate } = dateRange;

    // Choose model based on type
    const Model = type === "income" ? Income : Expense;
    const matchFilter = {
      userId: new mongoose.Types.ObjectId(userId),
      date: { $gte: startDate, $lte: endDate },
    };

    // Add isConfirmed filter for income
    if (type === "income") {
      matchFilter.isConfirmed = true;
    }

    // Get category breakdown
    const categoryData = await Model.aggregate([
      { $match: matchFilter },
      {
        $group: {
          _id: "$category",
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
          avgAmount: { $avg: { $toDouble: "$amount" } },
        },
      },
      { $sort: { total: -1 } },
    ]);

    // Calculate total for percentage
    const grandTotal = categoryData.reduce((sum, cat) => sum + cat.total, 0);

    // Format category data with percentages and icons
    const categories = categoryData.map((cat) => ({
      category: cat._id,
      total: cat.total,
      count: cat.count,
      avgAmount: cat.avgAmount,
      percentage: grandTotal > 0 ? (cat.total / grandTotal) * 100 : 0,
    }));

    // Get top 3 categories
    const topCategories = categories.slice(0, 3);

    // Get category trends (last 6 periods)
    const categoryTrends = await getCategoryTrends(userId, type, period);

    res.status(200).json({
      success: true,
      message: "Category report retrieved successfully",
      data: {
        period: {
          type: period,
          startDate,
          endDate,
        },
        type,
        summary: {
          grandTotal,
          categoryCount: categories.length,
          transactionCount: categoryData.reduce((sum, cat) => sum + cat.count, 0),
        },
        categories,
        topCategories,
        categoryTrends,
        generatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("❌ Category report error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve category report",
    });
  }
};

/**
 * Helper function to get category trends over last 6 periods
 */
async function getCategoryTrends(userId, type, period) {
  const Model = type === "income" ? Income : Expense;
  const trends = [];
  const now = new Date();

  // Generate date ranges for last 6 periods
  for (let i = 5; i >= 0; i--) {
    let startDate, endDate, label;

    if (period === "month") {
      const targetMonth = new Date(now.getFullYear(), now.getMonth() - i, 1);
      startDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth(), 1, 0, 0, 0, 0));
      endDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth() + 1, 0, 23, 59, 59, 999));
      label = `${targetMonth.getFullYear()}-${String(targetMonth.getMonth() + 1).padStart(2, "0")}`;
    } else if (period === "week") {
      const targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (i * 7));
      startDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 0, 0, 0, 0));
      endDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() + 6, 23, 59, 59, 999));
      label = `Week ${Math.ceil((targetDate.getDate()) / 7)}`;
    } else {
      // year
      const targetYear = now.getFullYear() - i;
      startDate = new Date(Date.UTC(targetYear, 0, 1, 0, 0, 0, 0));
      endDate = new Date(Date.UTC(targetYear, 11, 31, 23, 59, 59, 999));
      label = String(targetYear);
    }

    const matchFilter = {
      userId: new mongoose.Types.ObjectId(userId),
      date: { $gte: startDate, $lte: endDate },
    };

    if (type === "income") {
      matchFilter.isConfirmed = true;
    }

    const categoryData = await Model.aggregate([
      { $match: matchFilter },
      {
        $group: {
          _id: "$category",
          total: { $sum: { $toDouble: "$amount" } },
        },
      },
    ]);

    const periodData = { period: label, categories: {} };
    categoryData.forEach((cat) => {
      periodData.categories[cat._id] = cat.total;
    });

    trends.push(periodData);
  }

  return trends;
}

/**
 * @desc    Get comparison report - Compare periods
 * @route   GET /api/reports/comparison
 * @access  Private
 * @query   period - month|week|year (default: month)
 * @query   compareCount - number of periods to compare (default: 3, max: 12)
 */
export const getComparisonReport = async (req, res) => {
  const userId = req.userId;
  const { period = "month", compareCount = 3 } = req.query;

  try {
    console.log("🔄 getComparisonReport called:", { userId, period, compareCount });

    const count = Math.min(parseInt(compareCount) || 3, 12);
    const comparisons = [];
    const now = new Date();

    // Generate comparison data for each period
    for (let i = 0; i < count; i++) {
      let startDate, endDate, label;

      if (period === "month") {
        const targetMonth = new Date(now.getFullYear(), now.getMonth() - i, 1);
        startDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth(), 1, 0, 0, 0, 0));
        endDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth() + 1, 0, 23, 59, 59, 999));
        label = `${targetMonth.getFullYear()}-${String(targetMonth.getMonth() + 1).padStart(2, "0")}`;
      } else if (period === "week") {
        const targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (i * 7));
        startDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate() - 6, 0, 0, 0, 0));
        endDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 23, 59, 59, 999));
        label = `${targetDate.getFullYear()}-W${Math.ceil(targetDate.getDate() / 7)}`;
      } else {
        // year
        const targetYear = now.getFullYear() - i;
        startDate = new Date(Date.UTC(targetYear, 0, 1, 0, 0, 0, 0));
        endDate = new Date(Date.UTC(targetYear, 11, 31, 23, 59, 59, 999));
        label = String(targetYear);
      }

      // Get stats for this period
      const [incomeStats, expenseStats] = await Promise.all([
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
              total: { $sum: { $toDouble: "$amount" } },
              count: { $sum: 1 },
            },
          },
        ]),

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
              total: { $sum: { $toDouble: "$amount" } },
              count: { $sum: 1 },
            },
          },
        ]),
      ]);

      const income = incomeStats[0]?.total || 0;
      const expense = expenseStats[0]?.total || 0;
      const balance = income - expense;
      const savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;

      comparisons.push({
        period: label,
        startDate,
        endDate,
        income,
        expense,
        balance,
        savingsRate,
        incomeCount: incomeStats[0]?.count || 0,
        expenseCount: expenseStats[0]?.count || 0,
        isCurrent: i === 0,
      });
    }

    // Calculate period-over-period changes
    const changes = comparisons.map((current, index) => {
      if (index === comparisons.length - 1) return null;

      const previous = comparisons[index + 1];
      return {
        period: current.period,
        incomeChange: previous.income > 0 ? ((current.income - previous.income) / previous.income) * 100 : 0,
        expenseChange: previous.expense > 0 ? ((current.expense - previous.expense) / previous.expense) * 100 : 0,
        balanceChange: current.balance - previous.balance,
      };
    }).filter(Boolean);

    res.status(200).json({
      success: true,
      message: "Comparison report retrieved successfully",
      data: {
        periodType: period,
        comparisons,
        changes,
        generatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("❌ Comparison report error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve comparison report",
    });
  }
};

/**
 * @desc    Get spending patterns - Day of week, time of day analysis
 * @route   GET /api/reports/patterns
 * @access  Private
 * @query   period - month|week|year (default: month)
 */
export const getSpendingPatterns = async (req, res) => {
  const userId = req.userId;
  const { period = "month" } = req.query;

  try {
    console.log("🔍 getSpendingPatterns called:", { userId, period });

    const { startDate, endDate } = getDateRange(period);

    // Get expenses with day of week analysis
    const dayOfWeekPattern = await Expense.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          date: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: { $dayOfWeek: "$date" }, // 1 = Sunday, 7 = Saturday
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
          avgAmount: { $avg: { $toDouble: "$amount" } },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Map day numbers to names (Vietnamese)
    const dayNames = ["Chủ nhật", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"];
    const dayOfWeekData = dayOfWeekPattern.map((day) => ({
      dayOfWeek: day._id,
      dayName: dayNames[day._id - 1],
      total: day.total,
      count: day.count,
      avgAmount: day.avgAmount,
    }));

    // Get payment method distribution
    const paymentMethodPattern = await Expense.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          date: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: "$paymentMethod",
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
        },
      },
      { $sort: { total: -1 } },
    ]);

    // Get most frequent expense categories
    const frequentCategories = await Expense.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          date: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: "$category",
          count: { $sum: 1 },
          total: { $sum: { $toDouble: "$amount" } },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 5 },
    ]);

    // Get expense distribution by hour (for detailed analysis)
    const hourlyPattern = await Expense.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          date: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          _id: { $hour: "$createdAt" },
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Find peak spending hour
    const peakHour = hourlyPattern.reduce(
      (max, hour) => (hour.total > max.total ? hour : max),
      { _id: 0, total: 0, count: 0 }
    );

    res.status(200).json({
      success: true,
      message: "Spending patterns retrieved successfully",
      data: {
        period: {
          type: period,
          startDate,
          endDate,
        },
        patterns: {
          dayOfWeek: dayOfWeekData,
          paymentMethods: paymentMethodPattern,
          frequentCategories,
          hourlyDistribution: hourlyPattern,
          peakSpendingHour: peakHour._id,
        },
        insights: {
          mostExpensiveDay: dayOfWeekData.reduce(
            (max, day) => (day.total > max.total ? day : max),
            { total: 0, dayName: "N/A" }
          ).dayName,
          mostFrequentDay: dayOfWeekData.reduce(
            (max, day) => (day.count > max.count ? day : max),
            { count: 0, dayName: "N/A" }
          ).dayName,
          preferredPaymentMethod: paymentMethodPattern[0]?._id || "N/A",
        },
        generatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("❌ Spending patterns error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve spending patterns",
    });
  }
};

/**
 * @desc    Get forecast report - Predictive analytics
 * @route   GET /api/reports/forecast
 * @access  Private
 * @query   months - number of months to forecast (default: 3, max: 12)
 */
export const getForecastReport = async (req, res) => {
  const userId = req.userId;
  const { months = 3 } = req.query;

  try {
    console.log("🔮 getForecastReport called:", { userId, months });

    const forecastMonths = Math.min(parseInt(months) || 3, 12);

    // Get historical data for last 6 months
    const historicalData = [];
    const now = new Date();

    for (let i = 5; i >= 0; i--) {
      const targetMonth = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const startDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth(), 1, 0, 0, 0, 0));
      const endDate = new Date(Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth() + 1, 0, 23, 59, 59, 999));

      const [incomeStats, expenseStats] = await Promise.all([
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
              total: { $sum: { $toDouble: "$amount" } },
            },
          },
        ]),

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
              total: { $sum: { $toDouble: "$amount" } },
            },
          },
        ]),
      ]);

      historicalData.push({
        month: `${targetMonth.getFullYear()}-${String(targetMonth.getMonth() + 1).padStart(2, "0")}`,
        income: incomeStats[0]?.total || 0,
        expense: expenseStats[0]?.total || 0,
      });
    }

    // Simple moving average forecast
    const avgIncome = historicalData.reduce((sum, d) => sum + d.income, 0) / historicalData.length;
    const avgExpense = historicalData.reduce((sum, d) => sum + d.expense, 0) / historicalData.length;

    // Calculate trend (simple linear regression)
    const incomeTrend = calculateTrend(historicalData.map((d) => d.income));
    const expenseTrend = calculateTrend(historicalData.map((d) => d.expense));

    // Generate forecast
    const forecast = [];
    for (let i = 1; i <= forecastMonths; i++) {
      const targetMonth = new Date(now.getFullYear(), now.getMonth() + i, 1);
      const label = `${targetMonth.getFullYear()}-${String(targetMonth.getMonth() + 1).padStart(2, "0")}`;

      const forecastIncome = avgIncome + incomeTrend * i;
      const forecastExpense = avgExpense + expenseTrend * i;

      forecast.push({
        month: label,
        forecastIncome: Math.max(0, forecastIncome),
        forecastExpense: Math.max(0, forecastExpense),
        forecastBalance: forecastIncome - forecastExpense,
        confidence: Math.max(0, 100 - i * 10), // Decreasing confidence over time
      });
    }

    res.status(200).json({
      success: true,
      message: "Forecast report retrieved successfully",
      data: {
        historicalData,
        averages: {
          avgIncome,
          avgExpense,
          avgBalance: avgIncome - avgExpense,
        },
        trends: {
          incomeTrend: incomeTrend > 0 ? "increasing" : incomeTrend < 0 ? "decreasing" : "stable",
          expenseTrend: expenseTrend > 0 ? "increasing" : expenseTrend < 0 ? "decreasing" : "stable",
        },
        forecast,
        generatedAt: new Date(),
      },
    });
  } catch (error) {
    console.error("❌ Forecast report error:", error);
    res.status(500).json({
      success: false,
      error: "Failed to retrieve forecast report",
    });
  }
};

/**
 * Helper function to calculate trend (simple linear regression slope)
 */
function calculateTrend(data) {
  const n = data.length;
  if (n === 0) return 0;

  const xValues = Array.from({ length: n }, (_, i) => i);
  const xMean = xValues.reduce((sum, x) => sum + x, 0) / n;
  const yMean = data.reduce((sum, y) => sum + y, 0) / n;

  let numerator = 0;
  let denominator = 0;

  for (let i = 0; i < n; i++) {
    numerator += (xValues[i] - xMean) * (data[i] - yMean);
    denominator += (xValues[i] - xMean) ** 2;
  }

  return denominator === 0 ? 0 : numerator / denominator;
}

export default {
  getTrendReport,
  getCategoryReport,
  getComparisonReport,
  getSpendingPatterns,
  getForecastReport,
};
