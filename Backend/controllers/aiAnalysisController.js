import * as aiFinancialAnalysisService from "../services/aiFinancialAnalysisService.js";
import * as prophetForecastService from "../services/prophetForecastService.js";

/**
 * @desc    Get deep financial analysis with AI insights
 * @route   POST /api/ai/analysis/deep
 * @access  Private
 */
export const getDeepAnalysis = async (req, res) => {
  try {
    const userId = req.userId;
    const { period = "month" } = req.query;
    const analysis = await aiFinancialAnalysisService.analyzeFinancialHealth(
      userId,
      period
    );

    res.json({
      success: true,
      data: analysis,
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("Deep analysis error:", error);

    // Handle rate limit specifically
    if (error.message?.includes("Rate limit exceeded")) {
      res.status(429).json({
        success: false,
        error: error.message,
        retryAfter: 600, // 10 minutes
      });
    } else {
      res.status(500).json({
        success: false,
        error: error.message || "Failed to get deep analysis",
      });
    }
  }
};

/**
 * @desc    Get AI-powered financial forecast
 * @route   POST /api/ai/analysis/forecast
 * @access  Private
 * @query   months - number of months to forecast (default: 3, max: 12)
 */
export const getAIForecast = async (req, res) => {
  try {
    const userId = req.userId;
    const { months = 3, period = "month" } = req.query;

    const forecast = await prophetForecastService.generateForecast(
      userId,
      Math.min(parseInt(months), 12),
      period
    );

    res.json({
      success: true,
      data: forecast,
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("AI forecast error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to get forecast",
    });
  }
};

/**
 * @desc    Get spending anomalies and alerts
 * @route   GET /api/ai/analysis/anomalies
 * @access  Private
 */
export const getAnomalies = async (req, res) => {
  try {
    const userId = req.userId;
    const { period = "month" } = req.query;
    const anomalies = await aiFinancialAnalysisService.detectAnomalies(
      userId,
      period
    );

    res.json({
      success: true,
      data: {
        anomalies,
        count: anomalies.length,
        highSeverity: anomalies.filter((a) => a.severity === "high").length,
        mediumSeverity: anomalies.filter((a) => a.severity === "medium").length,
      },
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("Anomaly detection error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to detect anomalies",
    });
  }
};

/**
 * @desc    Get smart financial recommendations
 * @route   POST /api/ai/analysis/recommendations
 * @access  Private
 */
export const getRecommendations = async (req, res) => {
  try {
    const userId = req.userId;
    const { period = "month" } = req.query;
    const recommendations =
      await aiFinancialAnalysisService.getSmartRecommendations(userId, period);

    res.json({
      success: true,
      data: {
        recommendations: recommendations.recommendations || recommendations,
      },
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("Recommendations error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to get recommendations",
    });
  }
};

/**
 * @desc    Get quick insights summary
 * @route   GET /api/ai/analysis/insights
 * @access  Private
 */
export const getQuickInsights = async (req, res) => {
  try {
    const userId = req.userId;
    const { period = "month" } = req.query;

    // Fast parallel queries
    const [analysis, anomalies] = await Promise.all([
      aiFinancialAnalysisService.analyzeFinancialHealth(userId, period),
      aiFinancialAnalysisService.detectAnomalies(userId, period),
    ]);

    res.json({
      success: true,
      data: {
        healthScore: analysis.healthScore || "N/A",
        summary:
          typeof analysis.summary === "string"
            ? { text: analysis.summary }
            : analysis.summary || {},
        alerts: anomalies.filter((a) => a.severity === "high").length,
        topIssue: analysis.weaknesses?.[0] || null,
        strengths: analysis.strengths || [],
        weaknesses: analysis.weaknesses || [],
        opportunities: analysis.opportunities || [],
      },
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("Quick insights error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to get quick insights",
    });
  }
};

/**
 * @desc    Get spending patterns analysis
 * @route   GET /api/ai/analysis/patterns
 * @access  Private
 */
export const getSpendingPatterns = async (req, res) => {
  try {
    const userId = req.userId;
    const { period = "month" } = req.query;
    const patterns = await prophetForecastService.getSpendingPatterns(
      userId,
      period
    );

    res.json({
      success: true,
      data: patterns,
      generatedAt: new Date(),
    });
  } catch (error) {
    console.error("Spending patterns error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to get spending patterns",
    });
  }
};

/**
 * @desc    Clear AI analysis cache for user
 * @route   DELETE /api/ai/analysis/cache
 * @access  Private
 */
export const clearCache = async (req, res) => {
  try {
    const userId = req.userId;
    aiFinancialAnalysisService.clearUserCache(userId);

    res.json({
      success: true,
      message: "AI analysis cache cleared successfully",
    });
  } catch (error) {
    console.error("Clear cache error:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Failed to clear cache",
    });
  }
};

export default {
  getDeepAnalysis,
  getAIForecast,
  getAnomalies,
  getRecommendations,
  getQuickInsights,
  getSpendingPatterns,
  clearCache,
};
