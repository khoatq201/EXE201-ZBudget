import mongoose from "mongoose";
import { connectDB } from "../models/index.js";
import NotificationService from "../services/notificationService.js";
import notificationSchedulerJob from "../services/NotificationSchedulerJob.js";

/**
 * Test script for notification system
 * Usage: node scripts/test-notifications.js [test-type]
 *
 * Test types:
 * - create: Test creating notifications
 * - schedule: Test scheduled notifications
 * - budget: Test budget alerts
 * - anomaly: Test anomaly detection
 * - all: Run all tests
 */

const TEST_USER_ID = "507f1f77bcf86cd799439011"; // Replace with actual user ID

async function testCreateNotifications() {
  console.log("🧪 Testing notification creation...");

  try {
    // Test basic notification
    const basicNotification = await NotificationService.createNotification(
      TEST_USER_ID,
      "system",
      {},
      {
        title: "Test Notification",
        message: "This is a test notification",
        category: "system",
        priority: "normal",
      }
    );
    console.log("✅ Basic notification created:", basicNotification._id);

    // Test budget alert
    const budgetAlert = await NotificationService.createNotification(
      TEST_USER_ID,
      "budget_alert",
      {
        budgetId: "507f1f77bcf86cd799439012",
        budgetName: "Test Budget",
        category: "Food",
        spentPercentage: 85,
        remainingAmount: 150000,
      },
      {
        title: "⚠️ Cảnh báo ngân sách",
        message: "Ngân sách Test Budget đã sử dụng 85%",
        category: "budget",
        priority: "high",
      }
    );
    console.log("✅ Budget alert created:", budgetAlert._id);

    // Test anomaly alert
    const anomalyAlert = await NotificationService.createNotification(
      TEST_USER_ID,
      "large_expense_alert",
      {
        expenseId: "507f1f77bcf86cd799439013",
        expenseAmount: 2500000,
        category: "Shopping",
        description: "Large purchase",
      },
      {
        title: "🚨 Chi tiêu bất thường",
        message: "Bạn vừa chi 2,500,000đ cho Shopping - số tiền khá lớn!",
        category: "expense",
        priority: "high",
      }
    );
    console.log("✅ Anomaly alert created:", anomalyAlert._id);

    // Test daily reminder
    const dailyReminder = await NotificationService.createNotification(
      TEST_USER_ID,
      "expense_added",
      {
        reminderType: "daily_expense",
        message: "Bạn đã ghi chi tiêu hôm nay chưa?",
      },
      {
        title: "📝 Nhắc ghi chi tiêu",
        message: "Bạn đã ghi chi tiêu hôm nay chưa?",
        category: "expense",
        priority: "normal",
      }
    );
    console.log("✅ Daily reminder created:", dailyReminder?._id);

    console.log("✅ All notification creation tests passed!");
  } catch (error) {
    console.error("❌ Notification creation test failed:", error.message);
  }
}

async function testScheduledNotifications() {
  console.log("🧪 Testing scheduled notifications...");

  try {
    // Test weekly report
    const weeklyReport = await NotificationService.createNotification(
      TEST_USER_ID,
      "monthly_budget_summary",
      {
        totalExpenses: 500000,
        totalIncome: 1000000,
        savings: 500000,
        period: "2024-01-01 to 2024-01-07",
      },
      {
        title: "📊 Báo cáo tuần",
        message: "Tổng chi: 500,000đ, Thu: 1,000,000đ, Tiết kiệm: 500,000đ",
        category: "budget",
        priority: "normal",
      }
    );
    console.log("✅ Weekly report created:", weeklyReport._id);

    // Test bill reminder
    const billReminder = await NotificationService.createNotification(
      TEST_USER_ID,
      "expense_added",
      {
        billName: "Electricity Bill",
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
        amount: 500000,
        daysUntilDue: 2,
      },
      {
        title: "💡 Nhắc hóa đơn",
        message: "Hóa đơn điện sắp đến hạn trong 2 ngày",
        category: "expense",
        priority: "high",
      }
    );
    console.log("✅ Bill reminder created:", billReminder._id);

    console.log("✅ All scheduled notification tests passed!");
  } catch (error) {
    console.error("❌ Scheduled notification test failed:", error.message);
  }
}

async function testBudgetAlerts() {
  console.log("🧪 Testing budget alerts...");

  try {
    // Test different budget percentages
    const percentages = [80, 90, 100, 110];

    for (const percentage of percentages) {
      const alert = await NotificationService.triggerBudgetAlert(TEST_USER_ID, {
        budgetId: `budget_${percentage}`,
        budgetName: `Test Budget ${percentage}%`,
        category: "Test Category",
        spentPercentage: percentage,
        remainingAmount: Math.max(0, 1000000 - percentage * 10000),
      });
      console.log(`✅ Budget alert at ${percentage}% created:`, alert._id);
    }

    console.log("✅ All budget alert tests passed!");
  } catch (error) {
    console.error("❌ Budget alert test failed:", error.message);
  }
}

async function testAnomalyDetection() {
  console.log("🧪 Testing anomaly detection...");

  try {
    // Test different expense amounts
    const amounts = [1000000, 2000000, 5000000, 10000000];

    for (const amount of amounts) {
      const alert = await NotificationService.triggerAnomalyAlert(
        TEST_USER_ID,
        {
          expenseId: `expense_${amount}`,
          expenseAmount: amount,
          category: "Test Category",
          description: `Test expense of ${amount.toLocaleString()}đ`,
        }
      );
      console.log(
        `✅ Anomaly alert for ${amount.toLocaleString()}đ created:`,
        alert._id
      );
    }

    console.log("✅ All anomaly detection tests passed!");
  } catch (error) {
    console.error("❌ Anomaly detection test failed:", error.message);
  }
}

async function testNotificationScheduler() {
  console.log("🧪 Testing notification scheduler...");

  try {
    // Test manual runs
    const dailyResult = await notificationSchedulerJob.manualRun("daily");
    console.log("✅ Daily notification run:", dailyResult);

    const weeklyResult = await notificationSchedulerJob.manualRun("weekly");
    console.log("✅ Weekly notification run:", weeklyResult);

    const monthlyResult = await notificationSchedulerJob.manualRun("monthly");
    console.log("✅ Monthly notification run:", monthlyResult);

    const billsResult = await notificationSchedulerJob.manualRun("bills");
    console.log("✅ Bills notification run:", billsResult);

    const savingsResult = await notificationSchedulerJob.manualRun("savings");
    console.log("✅ Savings notification run:", savingsResult);

    console.log("✅ All scheduler tests passed!");
  } catch (error) {
    console.error("❌ Scheduler test failed:", error.message);
  }
}

async function testNotificationAPI() {
  console.log("🧪 Testing notification API...");

  try {
    // Test getting notifications
    const notifications = await NotificationService.getUserNotifications(
      TEST_USER_ID,
      {
        page: 1,
        limit: 10,
      }
    );
    console.log(
      "✅ Retrieved notifications:",
      notifications.notifications.length
    );

    // Test unread count
    const unreadCount = await NotificationService.getUnreadCount(TEST_USER_ID);
    console.log("✅ Unread count:", unreadCount);

    // Test marking as read
    if (notifications.notifications.length > 0) {
      const firstNotification = notifications.notifications[0];
      await NotificationService.markAsRead(firstNotification._id);
      console.log("✅ Marked notification as read:", firstNotification._id);
    }

    // Test marking all as read
    const markAllResult = await NotificationService.markAllAsRead(TEST_USER_ID);
    console.log("✅ Marked all as read:", markAllResult.modifiedCount);

    console.log("✅ All API tests passed!");
  } catch (error) {
    console.error("❌ API test failed:", error.message);
  }
}

async function cleanupTestData() {
  console.log("🧹 Cleaning up test data...");

  try {
    const { Notification } = await import("../models/Notification.js");

    // Delete test notifications
    const result = await Notification.deleteMany({
      userId: TEST_USER_ID,
      title: { $regex: /Test|test/ },
    });

    console.log(`✅ Cleaned up ${result.deletedCount} test notifications`);
  } catch (error) {
    console.error("❌ Cleanup failed:", error.message);
  }
}

async function runAllTests() {
  console.log("🚀 Running all notification tests...\n");

  try {
    await testCreateNotifications();
    console.log("");

    await testScheduledNotifications();
    console.log("");

    await testBudgetAlerts();
    console.log("");

    await testAnomalyDetection();
    console.log("");

    await testNotificationScheduler();
    console.log("");

    await testNotificationAPI();
    console.log("");

    await cleanupTestData();

    console.log("🎉 All tests completed successfully!");
  } catch (error) {
    console.error("❌ Test suite failed:", error.message);
  }
}

async function main() {
  const testType = process.argv[2] || "all";

  try {
    // Connect to database
    await connectDB();
    console.log("📡 Connected to database");

    switch (testType) {
      case "create":
        await testCreateNotifications();
        break;
      case "schedule":
        await testScheduledNotifications();
        break;
      case "budget":
        await testBudgetAlerts();
        break;
      case "anomaly":
        await testAnomalyDetection();
        break;
      case "scheduler":
        await testNotificationScheduler();
        break;
      case "api":
        await testNotificationAPI();
        break;
      case "all":
        await runAllTests();
        break;
      default:
        console.log("❌ Unknown test type:", testType);
        console.log(
          "Available types: create, schedule, budget, anomaly, scheduler, api, all"
        );
        process.exit(1);
    }

    console.log("\n✅ Test completed successfully!");
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log("📡 Database connection closed");
  }
}

// Run the test
main();
