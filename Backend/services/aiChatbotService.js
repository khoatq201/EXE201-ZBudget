import { GoogleGenerativeAI } from "@google/generative-ai";
import config from "../config/env.js";
import ChatSession from "../models/ChatSession.js";
import { v4 as uuidv4 } from "uuid";
import User from "../models/User.js";
import Expense from "../models/Expense.js";
import Income from "../models/Income.js";
import Budget from "../models/Budget.js";
import SavingsGoal from "../models/SavingsGoal.js";
import Challenge from "../models/Challenge.js";
import UserChallenge from "../models/UserChallenge.js";

// Initialize Gemini client
const genAI = new GoogleGenerativeAI(config.GEMINI_API_KEY);

/**
 * Fix common Vietnamese spelling errors from AI response
 * @param {string} text - Text to fix
 * @returns {string} - Fixed text
 */
function fixVietnameseSpelling(text) {
  if (!text) return text;

  // Common misspellings map
  const fixes = [
    // AI misspellings
    { from: /\bAl\b/g, to: "AI" },
    { from: /\bAl\s/g, to: "AI " },
    { from: /\sAl\b/g, to: " AI" },
    // ZBudget misspellings
    { from: /\bZBdget\b/g, to: "ZBudget" },
    { from: /\bZbudget\b/g, to: "ZBudget" },
    { from: /\bzbudget\b/g, to: "ZBudget" },
    // Tài chính misspellings
    { from: /\bài chính\b/g, to: "tài chính" },
    { from: /\btà chính\b/g, to: "tài chính" },
    // Một misspellings
    { from: /\bmt\b/g, to: "một" },
    { from: /\bmt\s/g, to: "một " },
    // Hướng dẫn misspellings - Missing spaces
    { from: /\bhướng dẫnsử\b/g, to: "hướng dẫn sử" },
    { from: /\bsửdụng\b/g, to: "sử dụng" },
    { from: /\bdẫnsử dụng\b/g, to: "dẫn sử dụng" },
    // Phân tích misspellings - Missing 'h'
    { from: /\bphân tíc\b/g, to: "phân tích" },
    { from: /\bphân tíc\s/g, to: "phân tích " },
    // Hôm nay misspellings - Missing space
    { from: /\bhômnay\b/g, to: "hôm nay" },
  ];

  let fixedText = text;
  fixes.forEach(({ from, to }) => {
    fixedText = fixedText.replace(from, to);
  });

  return fixedText;
}

/**
 * Build Vietnamese financial context for AI
 * @param {string} userId - User ID
 * @returns {Promise<string>} Financial context string
 */
export async function buildFinancialContext(userId) {
  try {
    const user = await User.findById(userId);
    const expenses = await Expense.find({ userId })
      .limit(50)
      .sort({ date: -1 });
    const income = await Income.find({ userId }).limit(20).sort({ date: -1 });
    const budgets = await Budget.find({ userId });
    const savingsGoals = await SavingsGoal.find({ userId });
    const userChallenges = await UserChallenge.find({ userId }).populate(
      "challengeId"
    );

    // Helper function to safely format numbers
    const formatCurrency = (amount) => {
      if (!amount || isNaN(amount) || amount === 0) return "0";
      return Number(amount).toLocaleString("vi-VN");
    };

    // Calculate financial summary with validation
    const totalIncome = income.reduce((sum, inc) => {
      const amount = Number(inc.amount) || 0;
      return sum + (amount >= 0 && amount <= 100000000 ? amount : 0); // Max 100 million
    }, 0);

    const totalExpenses = expenses.reduce((sum, exp) => {
      const amount = Number(exp.amount) || 0;
      return sum + (amount >= 0 && amount <= 100000000 ? amount : 0); // Max 100 million
    }, 0);

    const currentBalance = totalIncome - totalExpenses;
    const savingsRate =
      totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

    // Recent expense categories with validation
    const expenseCategories = {};
    expenses.forEach((exp) => {
      const amount = Number(exp.amount) || 0;
      if (amount > 0 && amount < 1000000000) {
        // Max 1 billion
        const category = exp.category || "other";
        expenseCategories[category] =
          (expenseCategories[category] || 0) + amount;
      }
    });

    // Budget status with validation
    const budgetStatus = budgets.map((budget) => {
      const limit = Number(budget.totalAmount) || 0;
      const spent = expenses
        .filter((exp) => exp.category === budget.category)
        .reduce((sum, exp) => {
          const amount = Number(exp.amount) || 0;
          return sum + (amount > 0 && amount < 1000000000 ? amount : 0);
        }, 0);
      return {
        category: budget.category,
        limit: limit,
        spent: spent,
        remaining: limit - spent,
      };
    });

    // Income sources analysis
    const incomeSources = {};
    income.forEach((inc) => {
      const amount = Number(inc.amount) || 0;
      if (amount > 0 && amount < 1000000000) {
        const source = inc.source?.name || "Khác";
        incomeSources[source] = (incomeSources[source] || 0) + amount;
      }
    });

    // Savings goals analysis
    const savingsAnalysis = savingsGoals.map((goal) => {
      const target = Number(goal.targetAmount) || 0;
      const current = Number(goal.currentAmount) || 0;
      const progress = target > 0 ? (current / target) * 100 : 0;
      return {
        title: goal.title,
        target: target,
        current: current,
        progress: Math.min(progress, 100),
        deadline: goal.targetDate,
      };
    });

    // Recent transactions (last 10)
    const recentTransactions = expenses.slice(0, 10).map((exp) => ({
      title: exp.title,
      amount: Number(exp.amount) || 0,
      category: exp.category,
      date: exp.date,
      description: exp.description,
    }));

    // Monthly spending trend (last 3 months)
    const now = new Date();
    const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, 1);
    const monthlyExpenses = {};

    expenses.forEach((exp) => {
      const expDate = new Date(exp.date);
      if (expDate >= threeMonthsAgo) {
        const monthKey = `${expDate.getFullYear()}-${expDate.getMonth() + 1}`;
        const amount = Number(exp.amount) || 0;
        if (amount > 0 && amount < 1000000000) {
          monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] || 0) + amount;
        }
      }
    });

    // Active challenges
    const activeChallenges = userChallenges.filter(
      (uc) => uc.status === "active"
    );

    // Check if we have any meaningful data
    if (totalIncome === 0 && totalExpenses === 0) {
      return `THÔNG TIN TÀI CHÍNH NGƯỜI DÙNG:
- Chưa có dữ liệu tài chính
- Hãy thêm thu nhập và chi tiêu để AI có thể tư vấn tốt hơn

GỢI Ý:
- Thêm thu nhập hàng tháng
- Ghi lại chi tiêu hàng ngày
- Tạo ngân sách cho các danh mục
- Đặt mục tiêu tiết kiệm
- Tham gia thử thách tiết kiệm`;
    }

    return `THÔNG TIN TÀI CHÍNH CHI TIẾT:

TỔNG QUAN:
- Thu nhập: ${formatCurrency(totalIncome)} VND
- Chi tiêu: ${formatCurrency(totalExpenses)} VND  
- Số dư: ${formatCurrency(currentBalance)} VND
- Tỷ lệ tiết kiệm: ${savingsRate.toFixed(1)}%

NGUỒN THU NHẬP:
${Object.entries(incomeSources)
  .sort(([, a], [, b]) => b - a)
  .map(([source, amount]) => `- ${source}: ${formatCurrency(amount)} VND`)
  .join("\n")}

CHI TIÊU THEO DANH MỤC:
${Object.entries(expenseCategories)
  .sort(([, a], [, b]) => b - a)
  .slice(0, 10)
  .map(([cat, amount]) => `- ${cat}: ${formatCurrency(amount)} VND`)
  .join("\n")}

TRẠNG THÁI NGÂN SÁCH:
${budgetStatus
  .map(
    (b) =>
      `- ${b.category}: ${formatCurrency(b.spent)}/${formatCurrency(
        b.limit
      )} VND (còn lại: ${formatCurrency(b.remaining)} VND)`
  )
  .join("\n")}

MỤC TIÊU TIẾT KIỆM:
${
  savingsAnalysis.length > 0
    ? savingsAnalysis
        .map(
          (goal) =>
            `- ${goal.title}: ${formatCurrency(goal.current)}/${formatCurrency(
              goal.target
            )} VND (${goal.progress.toFixed(1)}%)`
        )
        .join("\n")
    : "Chưa có mục tiêu tiết kiệm nào"
}

GIAO DỊCH GẦN NHẤT:
${recentTransactions
  .slice(0, 5)
  .map(
    (tx) =>
      `- ${tx.title}: ${formatCurrency(tx.amount)} VND (${
        tx.category
      }) - ${new Date(tx.date).toLocaleDateString("vi-VN")}`
  )
  .join("\n")}

XU HƯỚNG CHI TIÊU 3 THÁNG GẦN NHẤT:
${Object.entries(monthlyExpenses)
  .sort(([a], [b]) => a.localeCompare(b))
  .map(([month, amount]) => `- ${month}: ${formatCurrency(amount)} VND`)
  .join("\n")}

THỬ THÁCH ĐANG THAM GIA:
${
  activeChallenges.length > 0
    ? activeChallenges
        .map(
          (uc) =>
            `- ${uc.challengeId?.title || "Thử thách"}: ${
              uc.progress
            }% hoàn thành`
        )
        .join("\n")
    : "Chưa tham gia thử thách nào"
}`;
  } catch (error) {
    console.error("Error building financial context:", error);
    return "Không thể lấy thông tin tài chính. Vui lòng thử lại sau.";
  }
}

/**
 * Create new chat session
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Chat session
 */
export async function createChatSession(userId) {
  try {
    const sessionId = uuidv4();
    const context = await buildFinancialContext(userId);

    // System message không lưu vào messages array
    const systemMessage = `⚠️ QUAN TRỌNG - KIỂM TRA CHÍNH TẢ BẮT BUỘC:
- "AI" (chữ I hoa), KHÔNG phải "Al" hay "AL"
- "ZBudget" (B,D hoa), KHÔNG phải "ZBdget" hay "Zbudget"  
- "tài chính" đầy đủ, KHÔNG phải "ài chính"
- "một" đầy đủ, KHÔNG viết tắt "mt"
- "hướng dẫn sử dụng" có khoảng trắng, KHÔNG "dẫnsử"
- Sửa tất cả lỗi chính tả trước khi trả lời

Bạn là trợ lý AI chuyên nghiệp của ZBudget - ứng dụng quản lý tài chính cá nhân.

CHỨC NĂNG CHÍNH:
1. TƯ VẤN TÀI CHÍNH: Phân tích chi tiêu, ngân sách, tiết kiệm, đầu tư
2. HƯỚNG DẪN SỬ DỤNG APP: Cách sử dụng các tính năng của ZBudget

QUY TẮC TRẢ LỜI:
- Ưu tiên câu hỏi về tài chính và phân tích dữ liệu
- Trả lời câu hỏi về cách sử dụng app ZBudget
- TỪ CHỐI câu hỏi không liên quan (y tế, thể thao, giải trí, v.v.)

LOGIC XỬ LÝ CÂU HỎI:
1. CÂU HỎI TÀI CHÍNH: Phân tích chi tiêu, ngân sách, tiết kiệm, đầu tư → Trả lời chi tiết
2. CÂU HỎI VỀ APP: Cách sử dụng ZBudget, tính năng, hướng dẫn → Hướng dẫn cụ thể
3. CÂU HỎI KHÁC: Y tế, thể thao, giải trí, chính trị, v.v. → Từ chối lịch sự
4. CÂU HỎI MƠ HỒ: "Giúp tôi", "Tôi cần tư vấn" → Hỏi rõ mục đích

CÁCH TỪ CHỐI:
- Nếu câu hỏi không về tài chính/app: "Xin lỗi, tôi chỉ có thể tư vấn về tài chính và hướng dẫn sử dụng ZBudget. Bạn có câu hỏi nào về quản lý tiền bạc không?"
- Nếu câu hỏi mơ hồ: "Bạn muốn tư vấn về tài chính hay cần hướng dẫn sử dụng ZBudget?"

PHONG CÁCH TRẢ LỜI:
- Ngắn gọn, súc tích (tối đa 2-3 câu)
- Đi thẳng vào vấn đề
- CHỈ sử dụng số liệu hợp lý (0-100 triệu VND)
- Bỏ qua số liệu bất thường hoặc không hợp lý
- Ngôn ngữ: Tiếng Việt thân thiện
- Nếu không có dữ liệu, hướng dẫn người dùng thêm dữ liệu

HƯỚNG DẪN SỬ DỤNG ZBUDGET:

📱 CÁC MÀN HÌNH CHÍNH:
1. TRANG CHỦ: Tổng quan tài chính, thêm thu nhập/chi tiêu nhanh
2. NGÂN SÁCH: Tạo và quản lý ngân sách theo danh mục
3. TIẾT KIỆM: Đặt mục tiêu tiết kiệm và theo dõi tiến độ
4. NHÓM: Quản lý chi tiêu nhóm, chia sẻ ngân sách
5. THỬ THÁCH: Tham gia thử thách tiết kiệm
6. BÁO CÁO: Xem thống kê chi tiêu, biểu đồ phân tích
7. CÀI ĐẶT: Tùy chỉnh app, bảo mật, Premium

💰 QUẢN LÝ TÀI CHÍNH:
- Thêm thu nhập: Trang chủ → "Thêm thu nhập" hoặc "Thu nhập" tab
- Thêm chi tiêu: Trang chủ → "Thêm chi tiêu" hoặc "Chi tiêu" tab
- Xem tất cả giao dịch: Trang chủ → "Tất cả giao dịch"
- Tạo ngân sách: Ngân sách → "Tạo ngân sách mới"
- Xem chi tiết ngân sách: Ngân sách → Chọn ngân sách
- Đặt mục tiêu tiết kiệm: Tiết kiệm → "Tạo mục tiêu mới"

📊 BÁO CÁO VÀ PHÂN TÍCH:
- Xem báo cáo tổng quan: Báo cáo tab
- Phân tích chi tiêu theo danh mục: Báo cáo → "Chi tiêu theo danh mục"
- Xem biểu đồ thu nhập: Báo cáo → "Thu nhập"
- So sánh tháng: Báo cáo → "So sánh tháng"

👥 TÍNH NĂNG NHÓM:
- Tạo nhóm: Nhóm → "Tạo nhóm mới"
- Tham gia nhóm: Nhóm → "Tham gia bằng mã"
- Quản lý chi tiêu nhóm: Nhóm → Chọn nhóm → "Thêm chi tiêu"
- Tạo ngân sách nhóm: Nhóm → "Ngân sách nhóm"

🏆 THỬ THÁCH:
- Xem thử thách: Thử thách tab
- Tham gia thử thách: Thử thách → Chọn thử thách → "Tham gia"
- Theo dõi tiến độ: Thử thách → "Tiến độ của tôi"

⚙️ CÀI ĐẶT:
- Thông tin cá nhân: Cài đặt → "Thông tin cá nhân"
- Bảo mật: Cài đặt → "Bảo mật" (đổi mật khẩu, 2FA)
- Chủ đề: Cài đặt → "Chủ đề" (sáng/tối)
- Ngôn ngữ: Cài đặt → "Ngôn ngữ"
- Premium: Cài đặt → "Premium" (nâng cấp tài khoản)
- Thông báo: Cài đặt → "Thông báo"
- Trợ giúp: Cài đặt → "Trợ giúp"

VÍ DỤ XỬ LÝ CÂU HỎI:
✅ TÀI CHÍNH: "Tôi nên tiết kiệm như thế nào?" → Phân tích thu nhập, chi tiêu, đưa lời khuyên
✅ APP: "Làm sao để thêm thu nhập?" → "Vào Trang chủ → 'Thêm thu nhập' hoặc tab 'Thu nhập'"
✅ APP: "Cách tạo ngân sách?" → "Vào tab 'Ngân sách' → 'Tạo ngân sách mới'"
✅ APP: "Xem báo cáo ở đâu?" → "Vào tab 'Báo cáo' để xem thống kê chi tiêu"
✅ APP: "Cách tham gia nhóm?" → "Vào tab 'Nhóm' → 'Tham gia bằng mã'"
✅ APP: "Đặt mục tiêu tiết kiệm?" → "Vào tab 'Tiết kiệm' → 'Tạo mục tiêu mới'"
❌ KHÁC: "Đau bụng quá" → "Xin lỗi, tôi chỉ có thể tư vấn về tài chính và hướng dẫn sử dụng ZBudget..."
❌ MƠ HỒ: "Giúp tôi" → "Bạn muốn tư vấn về tài chính hay cần hướng dẫn sử dụng ZBudget?"

Thông tin tài chính người dùng:
${context}`;

    const session = new ChatSession({
      userId,
      sessionId,
      messages: [], // Bỏ system message ra khỏi messages
      systemMessage: systemMessage, // Lưu system message riêng
    });

    await session.save();
    return session;
  } catch (error) {
    console.error("Error creating chat session:", error);
    throw error;
  }
}

/**
 * Send message with streaming response
 * @param {string} sessionId - Session ID
 * @param {string} userMessage - User message
 * @param {string} userId - User ID
 * @returns {AsyncGenerator<string>} Streaming response
 */
export async function* sendMessageStream(sessionId, userMessage, userId) {
  try {
    const session = await ChatSession.findOne({ sessionId, userId });
    if (!session) {
      throw new Error("Session not found");
    }

    // Add user message to session
    session.messages.push({
      role: "user",
      content: userMessage,
      timestamp: new Date(),
    });

    // Save session with user message before calling API
    session.lastMessageAt = new Date();
    session.messageCount += 1;
    await session.save();

    // Get system message
    const systemPrompt =
      session.systemMessage ||
      `⚠️ QUAN TRỌNG - KIỂM TRA CHÍNH TẢ BẮT BUỘC:
- "AI" (chữ I hoa), KHÔNG phải "Al" hay "AL"
- "ZBudget" (B,D hoa), KHÔNG phải "ZBdget" hay "Zbudget"  
- "tài chính" đầy đủ, KHÔNG phải "ài chính"
- "một" đầy đủ, KHÔNG viết tắt "mt"
- "hướng dẫn sử dụng" có khoảng trắng, KHÔNG "dẫnsử"
- Sửa tất cả lỗi chính tả trước khi trả lời

Bạn là trợ lý AI chuyên nghiệp của ZBudget - ứng dụng quản lý tài chính cá nhân.

CHỨC NĂNG CHÍNH:
1. TƯ VẤN TÀI CHÍNH: Phân tích chi tiêu, ngân sách, tiết kiệm, đầu tư
2. HƯỚNG DẪN SỬ DỤNG APP: Cách sử dụng các tính năng của ZBudget

QUY TẮC TRẢ LỜI:
- Ưu tiên câu hỏi về tài chính và phân tích dữ liệu
- Trả lời câu hỏi về cách sử dụng app ZBudget
- TỪ CHỐI câu hỏi không liên quan (y tế, thể thao, giải trí, v.v.)

LOGIC XỬ LÝ CÂU HỎI:
1. CÂU HỎI TÀI CHÍNH: Phân tích chi tiêu, ngân sách, tiết kiệm, đầu tư → Trả lời chi tiết
2. CÂU HỎI VỀ APP: Cách sử dụng ZBudget, tính năng, hướng dẫn → Hướng dẫn cụ thể
3. CÂU HỎI KHÁC: Y tế, thể thao, giải trí, chính trị, v.v. → Từ chối lịch sự
4. CÂU HỎI MƠ HỒ: "Giúp tôi", "Tôi cần tư vấn" → Hỏi rõ mục đích

CÁCH TỪ CHỐI:
- Nếu câu hỏi không về tài chính/app: "Xin lỗi, tôi chỉ có thể tư vấn về tài chính và hướng dẫn sử dụng ZBudget. Bạn có câu hỏi nào về quản lý tiền bạc không?"
- Nếu câu hỏi mơ hồ: "Bạn muốn tư vấn về tài chính hay cần hướng dẫn sử dụng ZBudget?"

PHONG CÁCH TRẢ LỜI:
- Ngắn gọn, súc tích (tối đa 2-3 câu)
- Đi thẳng vào vấn đề
- CHỈ sử dụng số liệu hợp lý (0-100 triệu VND)
- Bỏ qua số liệu bất thường hoặc không hợp lý
- Ngôn ngữ: Tiếng Việt thân thiện
- Nếu không có dữ liệu, hướng dẫn người dùng thêm dữ liệu

HƯỚNG DẪN SỬ DỤNG ZBUDGET:

📱 CÁC MÀN HÌNH CHÍNH:
1. TRANG CHỦ: Tổng quan tài chính, thêm thu nhập/chi tiêu nhanh
2. NGÂN SÁCH: Tạo và quản lý ngân sách theo danh mục
3. TIẾT KIỆM: Đặt mục tiêu tiết kiệm và theo dõi tiến độ
4. NHÓM: Quản lý chi tiêu nhóm, chia sẻ ngân sách
5. THỬ THÁCH: Tham gia thử thách tiết kiệm
6. BÁO CÁO: Xem thống kê chi tiêu, biểu đồ phân tích
7. CÀI ĐẶT: Tùy chỉnh app, bảo mật, Premium

💰 QUẢN LÝ TÀI CHÍNH:
- Thêm thu nhập: Trang chủ → "Thêm thu nhập" hoặc "Thu nhập" tab
- Thêm chi tiêu: Trang chủ → "Thêm chi tiêu" hoặc "Chi tiêu" tab
- Xem tất cả giao dịch: Trang chủ → "Tất cả giao dịch"
- Tạo ngân sách: Ngân sách → "Tạo ngân sách mới"
- Xem chi tiết ngân sách: Ngân sách → Chọn ngân sách
- Đặt mục tiêu tiết kiệm: Tiết kiệm → "Tạo mục tiêu mới"

📊 BÁO CÁO VÀ PHÂN TÍCH:
- Xem báo cáo tổng quan: Báo cáo tab
- Phân tích chi tiêu theo danh mục: Báo cáo → "Chi tiêu theo danh mục"
- Xem biểu đồ thu nhập: Báo cáo → "Thu nhập"
- So sánh tháng: Báo cáo → "So sánh tháng"

👥 TÍNH NĂNG NHÓM:
- Tạo nhóm: Nhóm → "Tạo nhóm mới"
- Tham gia nhóm: Nhóm → "Tham gia bằng mã"
- Quản lý chi tiêu nhóm: Nhóm → Chọn nhóm → "Thêm chi tiêu"
- Tạo ngân sách nhóm: Nhóm → "Ngân sách nhóm"

🏆 THỬ THÁCH:
- Xem thử thách: Thử thách tab
- Tham gia thử thách: Thử thách → Chọn thử thách → "Tham gia"
- Theo dõi tiến độ: Thử thách → "Tiến độ của tôi"

⚙️ CÀI ĐẶT:
- Thông tin cá nhân: Cài đặt → "Thông tin cá nhân"
- Bảo mật: Cài đặt → "Bảo mật" (đổi mật khẩu, 2FA)
- Chủ đề: Cài đặt → "Chủ đề" (sáng/tối)
- Ngôn ngữ: Cài đặt → "Ngôn ngữ"
- Premium: Cài đặt → "Premium" (nâng cấp tài khoản)
- Thông báo: Cài đặt → "Thông báo"
- Trợ giúp: Cài đặt → "Trợ giúp"

VÍ DỤ XỬ LÝ CÂU HỎI:
✅ TÀI CHÍNH: "Tôi nên tiết kiệm như thế nào?" → Phân tích thu nhập, chi tiêu, đưa lời khuyên
✅ APP: "Làm sao để thêm thu nhập?" → "Vào Trang chủ → 'Thêm thu nhập' hoặc tab 'Thu nhập'"
✅ APP: "Cách tạo ngân sách?" → "Vào tab 'Ngân sách' → 'Tạo ngân sách mới'"
✅ APP: "Xem báo cáo ở đâu?" → "Vào tab 'Báo cáo' để xem thống kê chi tiêu"
✅ APP: "Cách tham gia nhóm?" → "Vào tab 'Nhóm' → 'Tham gia bằng mã'"
✅ APP: "Đặt mục tiêu tiết kiệm?" → "Vào tab 'Tiết kiệm' → 'Tạo mục tiêu mới'"
❌ KHÁC: "Đau bụng quá" → "Xin lỗi, tôi chỉ có thể tư vấn về tài chính và hướng dẫn sử dụng ZBudget..."
❌ MƠ HỒ: "Giúp tôi" → "Bạn muốn tư vấn về tài chính hay cần hướng dẫn sử dụng ZBudget?"

Thông tin tài chính người dùng:
${await buildFinancialContext(userId)}`;

    // Call Gemini API with streaming
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash-lite",
      systemInstruction: systemPrompt, // Gemini hỗ trợ systemInstruction riêng
      generationConfig: {
        temperature: 0.3, // Gemini xử lý tốt hơn với temperature 0.3
        maxOutputTokens: 1000, // Tăng lên vì Gemini tốt hơn với response dài hơn
      },
    });

    // Convert messages to Gemini format
    const history = session.messages.slice(0, -1).map((msg) => ({
      role: msg.role === "assistant" ? "model" : "user",
      parts: [{ text: msg.content }],
    }));

    const chat = model.startChat({ history });

    const lastMessage = session.messages[session.messages.length - 1].content;
    const result = await chat.sendMessageStream(lastMessage);

    let fullResponse = "";
    let tokensUsed = 0;

    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      if (chunkText) {
        fullResponse += chunkText;
        tokensUsed += chunkText.length;

        // Split chunk into individual characters for typing effect
        // This creates the typing animation effect like before
        const characters = chunkText.split("");
        for (const char of characters) {
          yield char;
          // Delay for typing effect (30ms per character)
          await new Promise((resolve) => setTimeout(resolve, 30));
        }
      }
    }

    // Apply spelling fix to the full response
    fullResponse = fixVietnameseSpelling(fullResponse);

    // No remaining content to yield

    // Save assistant response to session
    session.messages.push({
      role: "assistant",
      content: fullResponse,
      timestamp: new Date(),
      tokensUsed: tokensUsed,
    });

    session.lastMessageAt = new Date();
    session.messageCount += 1; // Only increment by 1 since we already incremented for user message
    session.totalTokensUsed += tokensUsed;
    await session.save();
  } catch (error) {
    console.error("Error in sendMessageStream:", error);
    yield `Lỗi: ${error.message}`;
  }
}

/**
 * Get chat history
 * @param {string} sessionId - Session ID
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Message history
 */
export async function getChatHistory(sessionId, userId) {
  try {
    const session = await ChatSession.findOne({
      sessionId,
      userId,
    });
    // Chỉ trả về messages không bao gồm system message
    // System message đã được tách ra field riêng
    return session?.messages || [];
  } catch (error) {
    console.error("Error getting chat history:", error);
    throw error;
  }
}

/**
 * End chat session
 * @param {string} sessionId - Session ID
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} Success status
 */
export async function endChatSession(sessionId, userId) {
  try {
    await ChatSession.updateOne({ sessionId, userId }, { isActive: false });
    return true;
  } catch (error) {
    console.error("Error ending chat session:", error);
    throw error;
  }
}

/**
 * Get user's active sessions
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Active sessions
 */
export async function getUserActiveSessions(userId) {
  try {
    const sessions = await ChatSession.find({
      userId,
      isActive: true,
    }).sort({ lastMessageAt: -1 });

    return sessions;
  } catch (error) {
    console.error("Error getting user sessions:", error);
    throw error;
  }
}
