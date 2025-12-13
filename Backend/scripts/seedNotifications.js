import mongoose from "mongoose";
import { User, Notification, connectDB } from "../models/index.js";

/**
 * ============================================================================
 * SEED NOTIFICATIONS - TẠO THÔNG BÁO TỰ ĐỘNG CHO USER
 * ============================================================================
 *
 * Script này tạo các notifications thực tế cho user minhkhoi.dev98@gmail.com
 * bao gồm: welcome, budget alerts, savings reminders, tips, achievements
 *
 * KHÔNG làm ảnh hưởng đến notifications của users khác
 */

// ============================================================================
// CẤU HÌNH
// ============================================================================
const CONFIG = {
  userEmail: "minhkhoi.dev98@gmail.com",
};

// Helper function để tạo ngày trong quá khứ
const daysAgo = (days) => {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date;
};

// ============================================================================
// DỮ LIỆU NOTIFICATIONS
// ============================================================================
const NOTIFICATIONS_DATA = [
  // Welcome notification - 3 ngày trước
  {
    type: "app_update",
    category: "system",
    title: "🎉 Chào mừng đến với ZBudget!",
    message:
      "Cảm ơn bạn đã tham gia ZBudget. Bắt đầu theo dõi chi tiêu và tiết kiệm thông minh ngay hôm nay!",
    icon: "🎉",
    color: "#4CAF50",
    priority: "normal",
    isRead: true,
    deliveryMethod: "in_app",
    createdAt: daysAgo(3),
  },

  // Budget alert - 2 ngày trước
  {
    type: "budget_alert",
    category: "budget",
    title: "⚠️ Cảnh báo ngân sách",
    message: "Bạn đã chi 98.31% ngân sách tháng này. Chỉ còn 253,450đ!",
    icon: "⚠️",
    color: "#FF9800",
    priority: "high",
    isRead: true,
    deliveryMethod: "in_app",
    data: {
      budgetName: "Ngân sách tháng 12/2025",
      spentPercentage: 98.31,
      remainingAmount: mongoose.Types.Decimal128.fromString("253450"),
    },
    actionButtons: [
      {
        text: "Xem chi tiết",
        action: "view_budget",
      },
    ],
    createdAt: daysAgo(2),
  },

  // Savings milestone - 2 ngày trước
  {
    type: "savings_milestone_achieved",
    category: "savings",
    title: "🎯 Đạt milestone tiết kiệm!",
    message:
      "Chúc mừng! Bạn đã tiết kiệm được 15 triệu cho mục tiêu Macbook M3 Pro (30% hoàn thành)",
    icon: "🎯",
    color: "#9C27B0",
    priority: "normal",
    isRead: false,
    deliveryMethod: "in_app",
    data: {
      savingsGoalName: "Mua Macbook M3 Pro",
      contributionAmount: mongoose.Types.Decimal128.fromString("15000000"),
      progressPercentage: 30,
      targetAmount: mongoose.Types.Decimal128.fromString("50000000"),
    },
    actionButtons: [
      {
        text: "Xem tiến độ",
        action: "view_savings_goal",
      },
    ],
    createdAt: daysAgo(2),
  },

  // Daily tip - 1 ngày trước
  {
    type: "daily_expense_reminder",
    category: "reminder",
    title: "💡 Mẹo tiết kiệm hôm nay",
    message:
      "Hãy thử pha cafe tại nhà thay vì mua ngoài. Bạn có thể tiết kiệm tới 500K/tháng!",
    icon: "💡",
    color: "#2196F3",
    priority: "low",
    isRead: false,
    deliveryMethod: "in_app",
    createdAt: daysAgo(1),
  },

  // Group invitation - 1 ngày trước
  {
    type: "group_invitation",
    category: "group",
    title: "👥 Mời tham gia nhóm",
    message: "Trần Quang Khoa đã mời bạn tham gia nhóm 'Du lịch Đà Lạt 2025'",
    icon: "👥",
    color: "#FF6B6B",
    priority: "high",
    isRead: true,
    deliveryMethod: "in_app",
    data: {
      groupName: "Du lịch Đà Lạt 2025",
      fromUserName: "Trần Quang Khoa",
    },
    actionButtons: [
      {
        text: "Xem nhóm",
        action: "view_group",
      },
    ],
    createdAt: daysAgo(1),
  },

  // Large expense alert - Hôm nay
  {
    type: "large_expense_alert",
    category: "expense",
    title: "💸 Chi tiêu lớn được ghi nhận",
    message:
      "Bạn vừa chi 2,400,000đ cho 'Đặt khách sạn Đà Lạt'. Hãy kiểm tra ngân sách của bạn.",
    icon: "💸",
    color: "#F44336",
    priority: "normal",
    isRead: false,
    deliveryMethod: "in_app",
    data: {
      expenseAmount: mongoose.Types.Decimal128.fromString("2400000"),
      expenseCategory: "other",
      expenseDescription: "Đặt khách sạn Đà Lạt",
    },
    actionButtons: [
      {
        text: "Xem chi tiết",
        action: "view_expense",
      },
    ],
    createdAt: new Date(),
  },

  // Weekly report - Hôm nay
  {
    type: "weekly_report",
    category: "insights",
    title: "📊 Báo cáo tuần này",
    message:
      "Tuần này bạn đã chi 3,450,000đ. Tăng 15% so với tuần trước. Hạng mục chi nhiều nhất: Ăn uống",
    icon: "📊",
    color: "#00BCD4",
    priority: "normal",
    isRead: false,
    deliveryMethod: "in_app",
    createdAt: new Date(),
  },

  // Savings reminder - Hôm nay
  {
    type: "savings_reminder",
    category: "reminder",
    title: "💰 Nhắc nhở tiết kiệm",
    message: "Đừng quên đóng góp 5 triệu vào mục tiêu tiết kiệm tháng này nhé!",
    icon: "💰",
    color: "#4CAF50",
    priority: "normal",
    isRead: false,
    deliveryMethod: "in_app",
    data: {
      savingsGoalName: "Mua Macbook M3 Pro",
      contributionAmount: mongoose.Types.Decimal128.fromString("5000000"),
    },
    actionButtons: [
      {
        text: "Đóng góp ngay",
        action: "add_savings_contribution",
      },
      {
        text: "Để sau",
        action: "snooze",
      },
    ],
    createdAt: new Date(),
  },

  // Streak milestone - Hôm nay
  {
    type: "streak_milestone",
    category: "social",
    title: "🔥 Streak 12 ngày!",
    message:
      "Tuyệt vời! Bạn đã duy trì ghi chép chi tiêu liên tục 12 ngày. Tiếp tục phát huy nhé!",
    icon: "🔥",
    color: "#FF5722",
    priority: "low",
    isRead: false,
    deliveryMethod: "in_app",
    createdAt: new Date(),
  },

  // Achievement - Hôm nay
  {
    type: "leaderboard_position",
    category: "social",
    title: "🏆 Thành tích mới!",
    message: "Bạn đã lên hạng Silver! Tiếp tục ghi chép để đạt hạng Gold nhé!",
    icon: "🏆",
    color: "#FFD700",
    priority: "normal",
    isRead: false,
    deliveryMethod: "in_app",
    createdAt: new Date(),
  },
];

// ============================================================================
// TẠO NOTIFICATIONS
// ============================================================================
async function seedNotifications(userId) {
  console.log("\n🔔 Đang tạo notifications cho user...");

  // Xóa notifications cũ của user này (nếu có)
  const existingCount = await Notification.countDocuments({ userId });
  if (existingCount > 0) {
    await Notification.deleteMany({ userId });
    console.log(`   🗑️  Đã xóa ${existingCount} notifications cũ`);
  }

  // Tạo notifications mới
  const notifications = NOTIFICATIONS_DATA.map((notif) => ({
    userId,
    type: notif.type,
    category: notif.category,
    title: notif.title,
    message: notif.message,
    icon: notif.icon,
    color: notif.color,
    priority: notif.priority,
    requiresAction: notif.actionButtons ? true : false,
    actionButtons: notif.actionButtons || [],
    data: notif.data || {},
    deliveryMethod: notif.deliveryMethod,
    isRead: notif.isRead,
    readAt: notif.isRead ? notif.createdAt : null,
    deliveredAt: notif.createdAt,
    createdAt: notif.createdAt,
    updatedAt: notif.createdAt,
  }));

  const inserted = await Notification.insertMany(notifications);

  console.log(`✅ Đã tạo ${inserted.length} notifications`);

  // Thống kê
  const unreadCount = notifications.filter((n) => !n.isRead).length;
  const readCount = notifications.filter((n) => n.isRead).length;

  console.log(`   - Chưa đọc: ${unreadCount}`);
  console.log(`   - Đã đọc: ${readCount}`);

  // Thống kê theo category
  const categoryStats = {};
  notifications.forEach((n) => {
    categoryStats[n.category] = (categoryStats[n.category] || 0) + 1;
  });

  console.log("\n📊 Phân loại:");
  Object.entries(categoryStats).forEach(([category, count]) => {
    console.log(`   - ${category}: ${count}`);
  });

  return inserted;
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================
async function main() {
  try {
    console.log("\n" + "=".repeat(70));
    console.log("🔔 SEED NOTIFICATIONS - TẠO THÔNG BÁO TỰ ĐỘNG");
    console.log("=".repeat(70));

    await connectDB();
    console.log("✅ Đã kết nối MongoDB");

    // Tìm user
    const user = await User.findOne({ email: CONFIG.userEmail });

    if (!user) {
      throw new Error(`❌ Không tìm thấy user ${CONFIG.userEmail}`);
    }

    console.log(`✅ Đã tìm thấy user: ${user.email} (ID: ${user._id})`);
    console.log(`   Tên: ${user.profile.name}`);

    // Tạo notifications
    await seedNotifications(user._id);

    console.log("\n" + "=".repeat(70));
    console.log("🎉 HOÀN TẤT! NOTIFICATIONS ĐÃ ĐƯỢC TẠO THÀNH CÔNG");
    console.log("=".repeat(70));
    console.log("\n📱 THÔNG TIN:");
    console.log(`   👤 User: ${user.profile.name}`);
    console.log(`   📧 Email: ${user.email}`);
    console.log(`   🔔 Tổng notifications: ${NOTIFICATIONS_DATA.length}`);
    console.log("\n💡 Các notifications bao gồm:");
    console.log("   - Chào mừng");
    console.log("   - Cảnh báo ngân sách");
    console.log("   - Milestone tiết kiệm");
    console.log("   - Tips hàng ngày");
    console.log("   - Mời tham gia nhóm");
    console.log("   - Cảnh báo chi tiêu lớn");
    console.log("   - Báo cáo tuần");
    console.log("   - Nhắc nhở tiết kiệm");
    console.log("   - Streak milestones");
    console.log("   - Thành tích mới");
    console.log("=".repeat(70));
    console.log("\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
