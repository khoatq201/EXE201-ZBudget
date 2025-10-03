import { User } from "../models/index.js";
import { successResponse } from "../middleware/errorHandler.js";

/**
 * Simple dashboard summary - just user data
 */
export const getDashboardSummarySimple = async (req, res) => {
  console.log("🔥 SIMPLE dashboard called");
  const userId = req.userId;

  try {
    console.log("🔍 Finding user:", userId);
    const user = await User.findById(userId).select("email financialSummary");
    console.log("✅ User found:", user ? "yes" : "no");

    if (!user) {
      return res.status(404).json({ success: false, error: "User not found" });
    }

    const response = {
      email: user.email,
      currentBalance: parseFloat(user.financialSummary?.currentBalance?.toString() || "0"),
      totalIncome: parseFloat(user.financialSummary?.totalIncome?.toString() || "0"),
      totalExpenses: parseFloat(user.financialSummary?.totalExpenses?.toString() || "0"),
    };

    console.log("📤 Sending response:", response);
    res.status(200).json({
      success: true,
      message: "Simple dashboard data",
      data: response
    });
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
};
