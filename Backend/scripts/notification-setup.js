import mongoose from "mongoose";
import { connectDB } from "../models/index.js";
import NotificationService from "../services/notificationService.js";
import notificationSchedulerJob from "../services/NotificationSchedulerJob.js";

/**
 * Notification Setup Script
 * Sets up default notifications for all users
 * Usage: node scripts/notification-setup.js
 */

async function setupDefaultNotifications() {
  console.log("🔧 Setting up default notifications for all users...");

  try {
    const { User } = await import("../models/User.js");

    // Get all active users
    const users = await User.find({ isActive: true }).select("_id email");
    console.log(`📊 Found ${users.length} active users`);

    let successCount = 0;
    let errorCount = 0;

    for (const user of users) {
      try {
        // Create welcome notification
        await NotificationService.createNotification(
          user._id,
          "system",
          {},
          {
            title: "🎉 Chào mừng đến với ZBudget!",
            message:
              "Hệ thống thông báo đã được kích hoạt. Bạn sẽ nhận được nhắc nhở về ngân sách, chi tiêu và mục tiêu tiết kiệm.",
            category: "system",
            priority: "normal",
          }
        );

        // Create setup guide notification
        await NotificationService.createNotification(
          user._id,
          "system",
          {},
          {
            title: "📚 Hướng dẫn sử dụng",
            message:
              "Tạo ngân sách đầu tiên và bắt đầu theo dõi chi tiêu của bạn để nhận được insights hữu ích.",
            category: "system",
            priority: "normal",
            requiresAction: true,
            actionButtons: [
              {
                text: "Tạo ngân sách",
                action: "create_budget",
                actionData: {},
              },
              {
                text: "Xem hướng dẫn",
                action: "view_guide",
                actionData: {},
              },
            ],
          }
        );

        successCount++;
        console.log(`✅ Setup notifications for user: ${user.email}`);
      } catch (error) {
        errorCount++;
        console.error(
          `❌ Failed to setup notifications for user ${user.email}:`,
          error.message
        );
      }
    }

    console.log(`\n📊 Setup Summary:`);
    console.log(`✅ Success: ${successCount} users`);
    console.log(`❌ Errors: ${errorCount} users`);
  } catch (error) {
    console.error("❌ Setup failed:", error.message);
  }
}

async function testNotificationChannels() {
  console.log("🧪 Testing notification channels...");

  try {
    const { User } = await import("../models/User.js");
    const testUser = await User.findOne({ isActive: true });

    if (!testUser) {
      console.log("❌ No active users found for testing");
      return;
    }

    console.log(`🧪 Testing with user: ${testUser.email}`);

    // Test different notification types
    const testNotifications = [
      {
        type: "budget_alert",
        title: "⚠️ Cảnh báo ngân sách",
        message: "Bạn đã chi 85% ngân sách Food. Còn lại 150,000đ.",
        category: "budget",
        priority: "high",
      },
      {
        type: "large_expense_alert",
        title: "🔍 Chi tiêu bất thường",
        message:
          "Bạn vừa chi 2,500,000đ cho Shopping. Đây là giao dịch lớn bất thường.",
        category: "expense",
        priority: "high",
      },
      {
        type: "daily_expense_reminder",
        title: "📝 Nhắc ghi chi tiêu",
        message:
          "Bạn chưa ghi chi tiêu hôm nay. Hãy cập nhật để theo dõi tài chính tốt hơn!",
        category: "reminder",
        priority: "normal",
      },
      {
        type: "weekly_report",
        title: "📊 Báo cáo tuần",
        message:
          "Tuần này bạn chi 1,500,000đ, thu 2,000,000đ. Tiết kiệm được 500,000đ.",
        category: "insights",
        priority: "normal",
      },
      {
        type: "savings_reminder",
        title: "💰 Nhắc tiết kiệm",
        message:
          'Bạn chưa đóng góp vào mục tiêu "Mua nhà" tháng này. Tiến độ hiện tại: 45%.',
        category: "savings",
        priority: "normal",
      },
    ];

    for (const notification of testNotifications) {
      await NotificationService.createNotification(
        testUser._id,
        notification.type,
        {},
        {
          title: notification.title,
          message: notification.message,
          category: notification.category,
          priority: notification.priority,
        }
      );
      console.log(`✅ Created test notification: ${notification.type}`);
    }

    console.log("✅ All notification channels tested successfully!");
  } catch (error) {
    console.error("❌ Channel test failed:", error.message);
  }
}

async function scheduleDefaultNotifications() {
  console.log("⏰ Scheduling default notifications...");

  try {
    // Start the notification scheduler
    notificationSchedulerJob.start();
    console.log("✅ Notification scheduler started");

    // Test manual runs
    console.log("🧪 Testing manual notification runs...");

    const dailyResult = await notificationSchedulerJob.manualRun("daily");
    console.log("✅ Daily notifications:", dailyResult.lastRunNotifications);

    const weeklyResult = await notificationSchedulerJob.manualRun("weekly");
    console.log("✅ Weekly notifications:", weeklyResult.lastRunNotifications);

    console.log("✅ Default notifications scheduled successfully!");
  } catch (error) {
    console.error("❌ Scheduling failed:", error.message);
  }
}

async function showNotificationStats() {
  console.log("📊 Notification Statistics:");

  try {
    const { Notification } = await import("../models/Notification.js");
    const { User } = await import("../models/User.js");

    // Get total counts
    const totalNotifications = await Notification.countDocuments();
    const totalUsers = await User.countDocuments({ isActive: true });
    const unreadNotifications = await Notification.countDocuments({
      isRead: false,
    });

    // Get category breakdown
    const categoryStats = await Notification.aggregate([
      { $group: { _id: "$category", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    // Get priority breakdown
    const priorityStats = await Notification.aggregate([
      { $group: { _id: "$priority", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    console.log(`📈 Total Notifications: ${totalNotifications}`);
    console.log(`👥 Active Users: ${totalUsers}`);
    console.log(`🔔 Unread Notifications: ${unreadNotifications}`);
    console.log(
      `📊 Read Rate: ${(
        ((totalNotifications - unreadNotifications) / totalNotifications) *
        100
      ).toFixed(1)}%`
    );

    console.log("\n📂 Category Breakdown:");
    categoryStats.forEach((stat) => {
      console.log(`  ${stat._id}: ${stat.count} notifications`);
    });

    console.log("\n⚡ Priority Breakdown:");
    priorityStats.forEach((stat) => {
      console.log(`  ${stat._id}: ${stat.count} notifications`);
    });

    // Get scheduler stats
    const schedulerStats = notificationSchedulerJob.getStats();
    console.log("\n⏰ Scheduler Stats:");
    console.log(`  Total Runs: ${schedulerStats.totalRuns}`);
    console.log(`  Notifications Sent: ${schedulerStats.notificationsSent}`);
    console.log(`  Errors: ${schedulerStats.errors}`);
    console.log(`  Last Run: ${schedulerStats.lastRun}`);
    console.log(`  Is Running: ${schedulerStats.isRunning}`);
  } catch (error) {
    console.error("❌ Failed to get stats:", error.message);
  }
}

async function main() {
  const action = process.argv[2] || "all";

  try {
    // Connect to database
    await connectDB();
    console.log("📡 Connected to database\n");

    switch (action) {
      case "setup":
        await setupDefaultNotifications();
        break;
      case "test":
        await testNotificationChannels();
        break;
      case "schedule":
        await scheduleDefaultNotifications();
        break;
      case "stats":
        await showNotificationStats();
        break;
      case "all":
        await setupDefaultNotifications();
        console.log("");
        await testNotificationChannels();
        console.log("");
        await scheduleDefaultNotifications();
        console.log("");
        await showNotificationStats();
        break;
      default:
        console.log("❌ Unknown action:", action);
        console.log("Available actions: setup, test, schedule, stats, all");
        process.exit(1);
    }

    console.log("\n✅ Setup completed successfully!");
  } catch (error) {
    console.error("❌ Setup failed:", error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log("📡 Database connection closed");
  }
}

// Run the setup
main();
