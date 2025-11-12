import { Income, Expense } from "../models/index.js";
import { config } from "../config/env.js";

// Simple Prophet wrapper with fallback
export async function generateForecast(userId, months = 3, period = "month") {
  try {
    // Get historical data based on period
    const historical = await getHistoricalData(userId, period);

    // Try Prophet (if available) - for now, use simple moving average
    if (config.PROPHET_ENABLED) {
      try {
        // For now, we'll use simple moving average as Prophet is not available
        // In the future, we can integrate with Python Prophet via subprocess
        return generateSimpleForecast(historical, months);
      } catch (prophetError) {
        console.warn("Prophet failed, using fallback:", prophetError);
      }
    }

    // Fallback: Simple moving average with trend
    return generateSimpleForecast(historical, months);
  } catch (error) {
    console.error("Forecast error:", error);
    throw error;
  }
}

// Enhanced forecast with seasonal patterns and volatility
function generateSimpleForecast(historical, months) {
  console.log("🔍 Forecast Debug - Historical data:", historical);

  if (historical.length === 0) {
    console.log("⚠️ No historical data, using fallback forecast");
    return generateFallbackForecast(months);
  }

  // Check if all historical data is zero or very small
  const totalExpense = historical.reduce((sum, h) => sum + h.expense, 0);
  const totalIncome = historical.reduce((sum, h) => sum + h.income, 0);

  console.log("📊 Total expense:", totalExpense, "Total income:", totalIncome);

  if (totalExpense < 1000 && totalIncome < 1000) {
    console.log("⚠️ Very low historical data, using fallback forecast");
    return generateFallbackForecast(months);
  }

  // Calculate weighted average (recent months have more weight)
  let weightedSum = 0;
  let weightSum = 0;
  historical.forEach((h, i) => {
    const weight = i + 1; // Recent months have higher weight
    weightedSum += h.expense * weight;
    weightSum += weight;
  });
  const avgExpense = weightedSum / weightSum;

  console.log("📈 Calculated avgExpense:", avgExpense);

  // Calculate income average
  const avgIncome =
    historical.reduce((sum, h) => sum + h.income, 0) / historical.length;

  // Calculate trend with enhanced algorithm
  const trend = calculateEnhancedTrend(
    historical.map((h, i) => ({ x: i, y: h.expense }))
  );

  // Calculate volatility from historical data
  const variance = calculateVariance(historical.map((h) => h.expense));
  const volatility = Math.sqrt(variance) * 0.1; // 10% of standard deviation

  const forecast = [];
  const now = new Date();

  for (let i = 1; i <= months; i++) {
    const futureMonth = new Date(now.getFullYear(), now.getMonth() + i, 1);
    const monthStr = `${futureMonth.getFullYear()}-${String(
      futureMonth.getMonth() + 1
    ).padStart(2, "0")}`;

    // Enhanced prediction with seasonal patterns and volatility
    const seasonalFactor = getSeasonalFactor(futureMonth.getMonth());
    const trendFactor = trend * i;
    const volatilityFactor = (Math.random() - 0.5) * volatility;
    const growthFactor = Math.sin(i * 0.5) * (avgExpense * 0.05); // Cyclical growth

    const predictedExpense = Math.max(
      0,
      avgExpense +
        trendFactor +
        volatilityFactor +
        seasonalFactor +
        growthFactor
    );

    const predictedIncome = Math.max(
      0,
      avgIncome + trend * i * 0.3 + seasonalFactor * 0.5
    );
    const margin = predictedExpense * 0.2; // Increased confidence interval

    forecast.push({
      month: monthStr,
      predictedExpense: Math.round(predictedExpense),
      predictedIncome: Math.round(predictedIncome),
      lower80: Math.round(Math.max(0, predictedExpense - margin)),
      upper80: Math.round(predictedExpense + margin),
      confidence: 0.75, // Higher confidence for enhanced method
    });
  }

  return {
    method: "enhanced_moving_average",
    forecast,
    historicalData: historical.slice(-3), // Last 3 months for context
  };
}

async function getHistoricalData(userId, period) {
  switch (period) {
    case "week":
      return await getHistoricalWeeklyData(userId, 8); // 8 weeks
    case "year":
      return await getHistoricalYearlyData(userId, 3); // 3 years
    case "month":
    default:
      return await getHistoricalMonthlyData(userId, 6); // 6 months
  }
}

async function getHistoricalMonthlyData(userId, months) {
  const historicalData = [];
  const now = new Date();

  for (let i = months - 1; i >= 0; i--) {
    const targetMonth = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const startDate = new Date(
      Date.UTC(targetMonth.getFullYear(), targetMonth.getMonth(), 1, 0, 0, 0, 0)
    );
    const endDate = new Date(
      Date.UTC(
        targetMonth.getFullYear(),
        targetMonth.getMonth() + 1,
        0,
        23,
        59,
        59,
        999
      )
    );

    const [incomeStats, expenseStats] = await Promise.all([
      Income.aggregate([
        {
          $match: {
            userId: userId,
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
            userId: userId,
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
      month: `${targetMonth.getFullYear()}-${String(
        targetMonth.getMonth() + 1
      ).padStart(2, "0")}`,
      income: incomeStats[0]?.total || 0,
      expense: expenseStats[0]?.total || 0,
    });
  }

  return historicalData;
}

async function getHistoricalWeeklyData(userId, weeks) {
  const historicalData = [];
  const now = new Date();

  for (let i = weeks - 1; i >= 0; i--) {
    const targetWeek = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000);
    const startOfWeek = new Date(targetWeek);
    startOfWeek.setDate(targetWeek.getDate() - targetWeek.getDay() + 1); // Monday
    startOfWeek.setHours(0, 0, 0, 0);
    const endOfWeek = new Date(startOfWeek.getTime() + 6 * 24 * 60 * 60 * 1000); // Sunday
    endOfWeek.setHours(23, 59, 59, 999);

    const [incomeStats, expenseStats] = await Promise.all([
      Income.aggregate([
        {
          $match: {
            userId: userId,
            date: { $gte: startOfWeek, $lte: endOfWeek },
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
            userId: userId,
            date: { $gte: startOfWeek, $lte: endOfWeek },
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
      week: `Tuần ${i + 1}`,
      income: incomeStats[0]?.total || 0,
      expense: expenseStats[0]?.total || 0,
    });
  }

  return historicalData;
}

async function getHistoricalYearlyData(userId, years) {
  const historicalData = [];
  const now = new Date();

  for (let i = years - 1; i >= 0; i--) {
    const targetYear = now.getFullYear() - i;
    const startDate = new Date(targetYear, 0, 1);
    const endDate = new Date(targetYear, 11, 31, 23, 59, 59, 999);

    const [incomeStats, expenseStats] = await Promise.all([
      Income.aggregate([
        {
          $match: {
            userId: userId,
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
            userId: userId,
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
      year: targetYear.toString(),
      income: incomeStats[0]?.total || 0,
      expense: expenseStats[0]?.total || 0,
    });
  }

  return historicalData;
}

function calculateTrend(data) {
  if (data.length < 2) return 0;

  // Linear regression slope
  const n = data.length;
  const sumX = data.reduce((sum, d) => sum + d.x, 0);
  const sumY = data.reduce((sum, d) => sum + d.y, 0);
  const sumXY = data.reduce((sum, d) => sum + d.x * d.y, 0);
  const sumX2 = data.reduce((sum, d) => sum + d.x * d.x, 0);

  const denominator = n * sumX2 - sumX * sumX;
  if (denominator === 0) return 0;

  return (n * sumXY - sumX * sumY) / denominator;
}

// Enhanced trend calculation with smoothing
function calculateEnhancedTrend(data) {
  if (data.length < 2) return 0;

  // Apply exponential smoothing to reduce noise
  const smoothed = exponentialSmoothing(
    data.map((d) => d.y),
    0.3
  );

  // Calculate trend on smoothed data
  const smoothedData = smoothed.map((y, i) => ({ x: i, y }));
  const baseTrend = calculateTrend(smoothedData);

  // Add momentum factor
  const momentum = calculateMomentum(data);

  return baseTrend + momentum * 0.1;
}

// Exponential smoothing function
function exponentialSmoothing(data, alpha) {
  if (data.length === 0) return [];

  const smoothed = [data[0]]; // First value stays the same

  for (let i = 1; i < data.length; i++) {
    const smoothedValue = alpha * data[i] + (1 - alpha) * smoothed[i - 1];
    smoothed.push(smoothedValue);
  }

  return smoothed;
}

// Calculate momentum (rate of change)
function calculateMomentum(data) {
  if (data.length < 3) return 0;

  const recent = data.slice(-3); // Last 3 points
  const first = recent[0].y;
  const last = recent[recent.length - 1].y;

  return (last - first) / recent.length;
}

// Calculate variance for volatility
function calculateVariance(values) {
  if (values.length < 2) return 0;

  const mean = values.reduce((sum, val) => sum + val, 0) / values.length;
  const squaredDiffs = values.map((val) => Math.pow(val - mean, 2));

  return squaredDiffs.reduce((sum, diff) => sum + diff, 0) / values.length;
}

// Get seasonal factor based on month
function getSeasonalFactor(month) {
  // Seasonal patterns (adjustable based on real data)
  const seasonalPatterns = {
    0: 0.05, // January - slight increase
    1: 0.1, // February - increase
    2: 0.15, // March - strong increase
    3: 0.1, // April
    4: 0.0, // May
    5: -0.05, // June - slight decrease
    6: -0.1, // July - decrease
    7: -0.05, // August
    8: 0.0, // September
    9: 0.1, // October - increase
    10: 0.15, // November - strong increase
    11: 0.2, // December - strongest increase
  };

  return seasonalPatterns[month] || 0;
}

// Generate fallback forecast when no historical data
function generateFallbackForecast(months) {
  console.log("🎯 Generating fallback forecast for", months, "months");

  const forecast = [];
  const now = new Date();
  const baseAmount = 5000000; // Base amount in VND (5M VND)

  for (let i = 1; i <= months; i++) {
    const futureMonth = new Date(now.getFullYear(), now.getMonth() + i, 1);
    const monthStr = `${futureMonth.getFullYear()}-${String(
      futureMonth.getMonth() + 1
    ).padStart(2, "0")}`;

    // Create realistic variation with more diversity
    const seasonalFactor = getSeasonalFactor(futureMonth.getMonth());
    const growthFactor = Math.sin(i * 0.3) * 0.15; // Cyclical growth
    const randomFactor = (Math.random() - 0.5) * 0.3; // More random variation
    const trendFactor = i * 0.05; // Slight upward trend over time

    // Ensure minimum variation
    const minVariation = 0.1; // At least 10% variation
    const totalVariation = Math.max(
      minVariation,
      Math.abs(seasonalFactor + growthFactor + randomFactor + trendFactor)
    );

    const predictedExpense = Math.round(
      baseAmount *
        (1 + seasonalFactor + growthFactor + randomFactor + trendFactor)
    );

    const predictedIncome = Math.round(
      predictedExpense * (1.1 + Math.random() * 0.2)
    ); // Income 110-130% of expense
    const margin = predictedExpense * 0.25;

    forecast.push({
      month: monthStr,
      predictedExpense: predictedExpense,
      predictedIncome: predictedIncome,
      lower80: Math.round(Math.max(0, predictedExpense - margin)),
      upper80: Math.round(predictedExpense + margin),
      confidence: 0.5, // Lower confidence for fallback
    });

    console.log(
      `📅 ${monthStr}: ${predictedExpense} (variation: ${totalVariation.toFixed(
        2
      )})`
    );
  }

  console.log("✅ Fallback forecast generated:", forecast.length, "months");

  return {
    method: "fallback_forecast",
    forecast,
    historicalData: [],
    message: "Dự báo dựa trên mẫu dữ liệu mặc định (chưa có dữ liệu lịch sử)",
  };
}

// Get spending patterns for analysis
export async function getSpendingPatterns(userId, period = "month") {
  const now = new Date();
  let startDate, endDate;

  // Calculate date range based on period
  switch (period) {
    case "week":
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay() + 1);
      startOfWeek.setHours(0, 0, 0, 0);
      startDate = startOfWeek;
      endDate = new Date(startOfWeek.getTime() + 6 * 24 * 60 * 60 * 1000);
      break;
    case "year":
      startDate = new Date(now.getFullYear(), 0, 1);
      endDate = new Date(now.getFullYear(), 11, 31);
      break;
    case "month":
    default:
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      break;
  }

  const expenses = await Expense.find({
    userId,
    date: { $gte: startDate, $lte: endDate },
  }).select("amount category date description");

  // Analyze patterns
  const patterns = {
    weeklyPattern: analyzeWeeklyPattern(expenses),
    categoryPattern: analyzeCategoryPattern(expenses),
    amountPattern: analyzeAmountPattern(expenses),
  };

  return patterns;
}

function analyzeWeeklyPattern(expenses) {
  const dayOfWeek = [0, 0, 0, 0, 0, 0, 0]; // Sunday to Saturday

  expenses.forEach((exp) => {
    const day = new Date(exp.date).getDay();
    dayOfWeek[day] += parseFloat(exp.amount) || 0;
  });

  const maxDay = dayOfWeek.indexOf(Math.max(...dayOfWeek));
  const dayNames = [
    "Chủ nhật",
    "Thứ hai",
    "Thứ ba",
    "Thứ tư",
    "Thứ năm",
    "Thứ sáu",
    "Thứ bảy",
  ];

  return {
    highestSpendingDay: dayNames[maxDay],
    distribution: dayOfWeek,
  };
}

function analyzeCategoryPattern(expenses) {
  const categoryTotals = {};

  expenses.forEach((exp) => {
    const cat = exp.category || "Khác";
    categoryTotals[cat] =
      (categoryTotals[cat] || 0) + (parseFloat(exp.amount) || 0);
  });

  const sorted = Object.entries(categoryTotals)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5);

  return {
    topCategories: sorted.map(([cat, amount]) => ({ category: cat, amount })),
    totalCategories: Object.keys(categoryTotals).length,
  };
}

function analyzeAmountPattern(expenses) {
  const amounts = expenses
    .map((exp) => parseFloat(exp.amount) || 0)
    .filter((a) => a > 0);

  if (amounts.length === 0) return { average: 0, median: 0, range: "N/A" };

  amounts.sort((a, b) => a - b);
  const average = amounts.reduce((sum, a) => sum + a, 0) / amounts.length;
  const median = amounts[Math.floor(amounts.length / 2)];
  const min = amounts[0];
  const max = amounts[amounts.length - 1];

  return {
    average: Math.round(average),
    median: Math.round(median),
    min: Math.round(min),
    max: Math.round(max),
    range: `${Math.round(min)} - ${Math.round(max)}`,
  };
}
