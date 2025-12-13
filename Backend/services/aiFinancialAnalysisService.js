import Groq from "groq-sdk";
import NodeCache from "node-cache";
import {
  User,
  Income,
  Expense,
  Budget,
  SavingsGoal,
  Challenge,
  UserChallenge,
} from "../models/index.js";
import { config } from "../config/env.js";

const groq = new Groq({
  apiKey: config.GROQ_API_KEY,
  timeout: 30000, // 30s timeout for non-streaming
  maxRetries: 0, // We handle retries ourselves
});
const cache = new NodeCache({
  stdTTL: config.AI_ANALYSIS_CACHE_TTL, // 5 min cache
  checkperiod: 120, // Check for expired keys every 2 minutes
  useClones: false, // Better performance
});

// Enhanced rate limit protection
let isRateLimited = false;
let rateLimitResetTime = null;
let lastApiCallTime = null;
const MIN_API_INTERVAL = 3000; // 3 seconds between API calls (giảm từ 5s)

// Smart queue system
const requestQueue = [];
let isProcessingQueue = false;

function checkRateLimit() {
  const now = Date.now();

  // Check if we're still in rate limit period
  if (isRateLimited && rateLimitResetTime && now < rateLimitResetTime) {
    throw new Error(
      `Rate limit exceeded. Try again in ${Math.ceil(
        (rateLimitResetTime - now) / 1000
      )} seconds`
    );
  }

  // Check if too soon since last API call
  if (lastApiCallTime && now - lastApiCallTime < MIN_API_INTERVAL) {
    console.log(
      `⏳ Rate limit: Please wait ${Math.ceil(
        (MIN_API_INTERVAL - (now - lastApiCallTime)) / 1000
      )} seconds before next request`
    );

    // Return cached data if available instead of throwing error
    // Note: userId and period are not available in checkRateLimit function
    // So we can't return cached data here, just throw the error

    throw new Error(
      `Please wait ${Math.ceil(
        (MIN_API_INTERVAL - (now - lastApiCallTime)) / 1000
      )} seconds before next request`
    );
  }

  // Reset rate limit if time has passed
  if (isRateLimited && rateLimitResetTime && now >= rateLimitResetTime) {
    isRateLimited = false;
    rateLimitResetTime = null;
  }
}

function setRateLimit(retryAfterSeconds) {
  isRateLimited = true;
  rateLimitResetTime = Date.now() + retryAfterSeconds * 1000;
}

function recordApiCall() {
  lastApiCallTime = Date.now();
}

// Retry helper for network errors with exponential backoff
async function retryableApiCall(apiCallFn, maxRetries = 5) {
  let lastError;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`[AI] API call attempt ${attempt}/${maxRetries}...`);
      recordApiCall();
      return await apiCallFn();
    } catch (error) {
      lastError = error;

      // Handle rate limits differently
      if (error.status === 429) {
        const retryAfter = error.headers?.["retry-after"] || 600;
        setRateLimit(parseInt(retryAfter));
        console.error(
          `🚫 Rate limit exceeded. Setting cooldown for ${retryAfter} seconds`
        );
        throw new Error(
          `Rate limit exceeded. Please try again in ${Math.ceil(
            retryAfter / 60
          )} minutes`
        );
      }

      // Check if it's a network error
      const isNetworkError =
        error.code === "ECONNRESET" ||
        error.code === "ETIMEDOUT" ||
        error.code === "ENOTFOUND" ||
        error.message?.includes("ECONNRESET") ||
        error.message?.includes("Connection error") ||
        error.message?.includes("timeout");

      if (!isNetworkError || attempt === maxRetries) {
        console.error(
          `[AI] ❌ API call failed (attempt ${attempt}):`,
          error.message
        );
        console.error(`[AI] Error details:`, {
          code: error.code,
          status: error.status,
          cause: error.cause?.message,
        });
        throw error;
      }

      // Exponential backoff: 2s, 4s, 8s, 16s, 30s
      const delay = Math.min(Math.pow(2, attempt) * 1000, 30000);
      console.log(
        `[AI] ⏳ Network error (${error.code}), retrying in ${delay}ms...`
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}

// Smart queue processing
async function processQueue() {
  if (isProcessingQueue || requestQueue.length === 0) return;

  isProcessingQueue = true;

  while (requestQueue.length > 0) {
    const { resolve, reject, userId, period } = requestQueue.shift();

    try {
      // Check rate limit before processing
      checkRateLimit();

      // Process the request
      const result = await analyzeFinancialHealth(userId, period);
      resolve(result);

      // Wait between requests
      await new Promise((resolve) => setTimeout(resolve, MIN_API_INTERVAL));
    } catch (error) {
      reject(error);
    }
  }

  isProcessingQueue = false;
}

// Add request to queue
function queueRequest(userId, period) {
  return new Promise((resolve, reject) => {
    requestQueue.push({ resolve, reject, userId, period });
    processQueue();
  });
}

// Deep financial health analysis
export async function analyzeFinancialHealth(userId, period = "month") {
  const cacheKey = `analysis_${userId}_${period}`;
  const cached = cache.get(cacheKey);
  if (cached) {
    console.log(`✅ Using cached analysis for ${userId}_${period}`);
    return cached;
  }

  // Check rate limit before making API call (only if no cache)
  try {
    checkRateLimit();
  } catch (rateLimitError) {
    // If rate limited, try to return any available cache for this user
    console.log(`⏳ Rate limited, looking for cached data for user ${userId}`);

    // Try different periods for this user
    const periods = ["month", "week", "year"];
    for (const period of periods) {
      const fallbackCacheKey = `analysis_${userId}_${period}`;
      const fallbackCache = cache.get(fallbackCacheKey);
      if (fallbackCache) {
        console.log(
          `✅ Returning cached data for ${userId}_${period} due to rate limit`
        );
        return fallbackCache;
      }
    }

    // If no cache found, return a basic fallback analysis instead of throwing error
    console.log(
      `❌ No cached data found for user ${userId}, returning fallback analysis`
    );

    const fallbackAnalysis = {
      healthScore: "Trung bình",
      strengths: ["Dữ liệu đang được cập nhật"],
      weaknesses: ["Không thể phân tích do rate limit"],
      risks: ["API đang bị giới hạn"],
      opportunities: ["Thử lại sau ít phút"],
      recommendations: [
        {
          title: "Thử lại sau",
          description: "API đang bị giới hạn, vui lòng thử lại sau",
          priority: "low",
          estimatedSavings: 0,
        },
      ],
      summary: "Phân tích tạm thời không khả dụng do rate limit",
    };

    // Cache this fallback for future use
    cache.set(cacheKey, fallbackAnalysis);
    console.log(`💾 Cached fallback analysis for ${userId}_${period}`);

    return fallbackAnalysis;
  }

  // Aggregate ALL financial data
  const financialData = await buildComprehensiveFinancialContext(
    userId,
    period
  );

  // System prompt for deep analysis
  const systemPrompt = `Bạn là chuyên gia tài chính cá nhân hàng đầu Việt Nam.
  
NHIỆM VỤ: Phân tích CHUYÊN SÂU tình hình tài chính và đưa ra đánh giá, cảnh báo, khuyến nghị.

PHÂN TÍCH:
1. SỨC KHỎE TÀI CHÍNH: Đánh giá tổng quan (Tốt/Khá/Trung bình/Kém)
2. ĐIỂM MẠNH: 3 điểm tích cực nhất
3. ĐIỂM YẾU: 3 vấn đề cần cải thiện khẩn cấp
4. RỦI RO: Cảnh báo các khoản chi bất thường, vượt ngân sách
5. CƠ HỘI: Tiết kiệm thêm ở đâu, tối ưu ngân sách
6. KHUYẾN NGHỊ: 5 hành động CỤ THỂ, CÓ THỂ THỰC HIỆN NGAY

ĐỊNH DẠNG JSON BẮT BUỘC:
{
  "healthScore": "Tốt/Khá/Trung bình/Kém",
  "strengths": ["điểm mạnh 1", "điểm mạnh 2", "điểm mạnh 3"],
  "weaknesses": ["điểm yếu 1", "điểm yếu 2", "điểm yếu 3"],
  "risks": ["rủi ro 1", "rủi ro 2"],
  "opportunities": ["cơ hội 1", "cơ hội 2"],
  "recommendations": [
    {
      "title": "Tiêu đề khuyến nghị",
      "description": "Mô tả chi tiết",
      "priority": "high/medium/low",
      "estimatedSavings": 1000000
    }
  ],
  "summary": "Tóm tắt tổng quan"
}

OUTPUT: Tiếng Việt, ngắn gọn, dễ hiểu, actionable

Dữ liệu tài chính:
${financialData}`;

  let completion;
  try {
    completion = await retryableApiCall(() =>
      groq.chat.completions.create({
        model: config.GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          {
            role: "user",
            content: "Hãy phân tích chuyên sâu tài chính của tôi.",
          },
        ],
        temperature: 0.3,
        response_format: { type: "json_object" },
      })
    );
  } catch (error) {
    throw error;
  }

  const rawAnalysis = JSON.parse(completion.choices[0].message.content);

  // Force correct field mapping (handle Vietnamese field names)
  const analysis = {
    healthScore:
      rawAnalysis.healthScore || rawAnalysis.sucKhoeTaiChinh || "N/A",
    strengths: rawAnalysis.strengths || rawAnalysis.diemManh || [],
    weaknesses: rawAnalysis.weaknesses || rawAnalysis.diemYeu || [],
    risks: rawAnalysis.risks || rawAnalysis.ruoiRo || rawAnalysis.ruRo || [],
    opportunities: rawAnalysis.opportunities || rawAnalysis.coHoi || [],
    recommendations:
      rawAnalysis.recommendations || rawAnalysis.khuyenNghi || [],
    summary: rawAnalysis.summary || rawAnalysis.tomTat || "",
  };

  cache.set(cacheKey, analysis);
  return analysis;
}

// Build comprehensive financial context (similar to chatbot but MORE detailed)
async function buildComprehensiveFinancialContext(userId, period = "month") {
  const now = new Date();
  let startDate, endDate, startCompareDate, endCompareDate;

  // Calculate date ranges based on period
  switch (period) {
    case "week":
      // Current week (Monday to Sunday)
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
      startOfWeek.setHours(0, 0, 0, 0);
      startDate = startOfWeek;
      endDate = new Date(startOfWeek.getTime() + 6 * 24 * 60 * 60 * 1000); // Sunday

      // Previous week
      startCompareDate = new Date(
        startOfWeek.getTime() - 7 * 24 * 60 * 60 * 1000
      );
      endCompareDate = new Date(
        startOfWeek.getTime() - 1 * 24 * 60 * 60 * 1000
      );
      break;

    case "year":
      // Current year
      startDate = new Date(now.getFullYear(), 0, 1);
      endDate = new Date(now.getFullYear(), 11, 31);

      // Previous year
      startCompareDate = new Date(now.getFullYear() - 1, 0, 1);
      endCompareDate = new Date(now.getFullYear() - 1, 11, 31);
      break;

    case "month":
    default:
      // Current month
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      // Previous month
      startCompareDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      endCompareDate = new Date(now.getFullYear(), now.getMonth(), 0);
      break;
  }

  const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const last90Days = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

  const [
    user,
    currentPeriodIncome,
    currentPeriodExpenses,
    last30DaysExpenses,
    last90DaysExpenses,
    comparePeriodIncome,
    comparePeriodExpenses,
    activeBudgets,
    savingsGoals,
    activeChallenges,
  ] = await Promise.all([
    User.findById(userId).select("name email currency"),
    Income.find({
      userId,
      date: { $gte: startDate, $lte: endDate },
      isConfirmed: true,
    }).select("amount category date description"),
    Expense.find({ userId, date: { $gte: startDate, $lte: endDate } }).select(
      "amount category date description"
    ),
    Expense.find({ userId, date: { $gte: last30Days } }).select(
      "amount category date"
    ),
    Expense.find({ userId, date: { $gte: last90Days } }).select(
      "amount category date"
    ),
    Income.find({
      userId,
      date: { $gte: startCompareDate, $lte: endCompareDate },
      isConfirmed: true,
    }).select("amount"),
    Expense.find({
      userId,
      date: { $gte: startCompareDate, $lte: endCompareDate },
    }).select("amount"),
    Budget.find({ userId, isActive: true }).select(
      "category limit spentAmount period"
    ),
    SavingsGoal.find({ userId, status: "in_progress" }).select(
      "name targetAmount currentAmount deadline"
    ),
    UserChallenge.find({ userId, status: "active" })
      .populate("challengeId", "title description target")
      .select("progress"),
  ]);

  // Calculate comprehensive metrics
  const currentPeriodIncomeTotal = currentPeriodIncome.reduce(
    (sum, inc) => sum + (validateAmount(inc.amount) || 0),
    0
  );
  const currentPeriodExpenseTotal = currentPeriodExpenses.reduce(
    (sum, exp) => sum + (validateAmount(exp.amount) || 0),
    0
  );
  const comparePeriodIncomeTotal = comparePeriodIncome.reduce(
    (sum, inc) => sum + (validateAmount(inc.amount) || 0),
    0
  );
  const comparePeriodExpenseTotal = comparePeriodExpenses.reduce(
    (sum, exp) => sum + (validateAmount(exp.amount) || 0),
    0
  );

  const savingsRate =
    currentPeriodIncomeTotal > 0
      ? (
          ((currentPeriodIncomeTotal - currentPeriodExpenseTotal) /
            currentPeriodIncomeTotal) *
          100
        ).toFixed(1)
      : 0;

  // Category breakdown
  const categoryBreakdown = {};
  currentPeriodExpenses.forEach((exp) => {
    const cat = exp.category || "Khác";
    categoryBreakdown[cat] =
      (categoryBreakdown[cat] || 0) + (validateAmount(exp.amount) || 0);
  });

  // Budget health
  const budgetHealth = activeBudgets.map((budget) => ({
    category: budget.category,
    limit: budget.limit,
    spent: budget.spentAmount || 0,
    remaining: Math.max(0, budget.limit - (budget.spentAmount || 0)),
    percentUsed: (((budget.spentAmount || 0) / budget.limit) * 100).toFixed(1),
    status: (budget.spentAmount || 0) > budget.limit * 0.9 ? "warning" : "ok",
  }));

  // Spending trends (30-day vs 90-day average)
  const avg30Days =
    last30DaysExpenses.reduce(
      (sum, exp) => sum + (validateAmount(exp.amount) || 0),
      0
    ) / 30;
  const avg90Days =
    last90DaysExpenses.reduce(
      (sum, exp) => sum + (validateAmount(exp.amount) || 0),
      0
    ) / 90;
  const spendingTrend =
    avg30Days > avg90Days * 1.2
      ? "increasing"
      : avg30Days < avg90Days * 0.8
      ? "decreasing"
      : "stable";

  // Get period labels
  const periodLabels = {
    week: { current: "Tuần này", compare: "Tuần trước" },
    month: { current: "Tháng này", compare: "Tháng trước" },
    year: { current: "Năm nay", compare: "Năm trước" },
  };

  const labels = periodLabels[period] || periodLabels.month;

  return JSON.stringify(
    {
      period: labels.current,
      periodType: period,
      income: {
        current: currentPeriodIncomeTotal,
        compare: comparePeriodIncomeTotal,
        change:
          comparePeriodIncomeTotal > 0
            ? (
                ((currentPeriodIncomeTotal - comparePeriodIncomeTotal) /
                  comparePeriodIncomeTotal) *
                100
              ).toFixed(1) + "%"
            : "N/A",
      },
      expenses: {
        current: currentPeriodExpenseTotal,
        compare: comparePeriodExpenseTotal,
        change:
          comparePeriodExpenseTotal > 0
            ? (
                ((currentPeriodExpenseTotal - comparePeriodExpenseTotal) /
                  comparePeriodExpenseTotal) *
                100
              ).toFixed(1) + "%"
            : "N/A",
        byCategory: categoryBreakdown,
        trend: spendingTrend,
        avg30Days: avg30Days.toFixed(0),
        avg90Days: avg90Days.toFixed(0),
      },
      balance: currentPeriodIncomeTotal - currentPeriodExpenseTotal,
      savingsRate: savingsRate + "%",
      budgets: budgetHealth,
      savingsGoals: savingsGoals.map((goal) => ({
        name: goal.name,
        target: goal.targetAmount,
        current: goal.currentAmount,
        remaining: goal.targetAmount - goal.currentAmount,
        progress:
          ((goal.currentAmount / goal.targetAmount) * 100).toFixed(1) + "%",
        deadline: goal.deadline,
      })),
      challenges: activeChallenges.map((ch) => ({
        title: ch.challengeId.title,
        progress: ch.progress + "%",
      })),
    },
    null,
    2
  );
}

// Validate amount (cap at 100M)
function validateAmount(amount) {
  const num = parseFloat(amount);
  if (isNaN(num) || num < 0 || num > 100000000) return null;
  return num;
}

// Anomaly detection (rule-based)
export async function detectAnomalies(userId, period = "month") {
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

  // Calculate mean and std dev by category
  const categoryStats = {};
  expenses.forEach((exp) => {
    const cat = exp.category || "Khác";
    if (!categoryStats[cat]) categoryStats[cat] = [];
    categoryStats[cat].push(parseFloat(exp.amount));
  });

  const anomalies = [];
  for (const [category, amounts] of Object.entries(categoryStats)) {
    if (amounts.length < 3) continue; // Need at least 3 data points

    const mean = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance =
      amounts.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) /
      amounts.length;
    const stdDev = Math.sqrt(variance);
    const threshold = mean + config.ANOMALY_THRESHOLD * stdDev;

    expenses.forEach((exp) => {
      if (exp.category === category && parseFloat(exp.amount) > threshold) {
        anomalies.push({
          date: exp.date,
          category: exp.category,
          amount: exp.amount,
          description: exp.description,
          expectedRange: `0 - ${threshold.toFixed(0)}`,
          severity:
            parseFloat(exp.amount) > mean + 3 * stdDev ? "high" : "medium",
        });
      }
    });
  }

  return anomalies;
}

// Smart recommendations
export async function getSmartRecommendations(userId, period = "month") {
  const analysis = await analyzeFinancialHealth(userId, period);
  const anomalies = await detectAnomalies(userId, period);

  const systemPrompt = `Bạn là chuyên gia tư vấn tài chính.

NHIỆM VỤ: Dựa vào phân tích và anomalies, đưa ra 5 KHUYẾN NGHỊ CỤ THỂ, CÓ THỂ THỰC HIỆN NGAY.

YÊU CẦU:
- Mỗi khuyến nghị có: title, description, priority (high/medium/low), estimatedSavings (số tiền tiết kiệm được)
- Ưu tiên các hành động có impact cao, dễ thực hiện
- Tiếng Việt, ngắn gọn, actionable

ĐỊNH DẠNG JSON BẮT BUỘC:
{
  "recommendations": [
    {
      "title": "Tiêu đề khuyến nghị",
      "description": "Mô tả chi tiết",
      "priority": "high/medium/low",
      "estimatedSavings": 1000000
    }
  ]
}

OUTPUT: JSON object với field "recommendations"`;

  const completion = await retryableApiCall(() =>
    groq.chat.completions.create({
      model: config.GROQ_MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: JSON.stringify({ analysis, anomalies }) },
      ],
      temperature: 0.5,
      response_format: { type: "json_object" },
    })
  );

  return JSON.parse(completion.choices[0].message.content);
}

// Clear cache for user (for real-time updates)
export function clearUserCache(userId) {
  cache.del(`analysis_${userId}`);
}
