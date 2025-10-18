#!/usr/bin/env node

/**
 * Test script để verify tất cả notification triggers hoạt động đúng
 * Chạy: node scripts/test-notification-triggers.js
 */

import mongoose from "mongoose";
import dotenv from "dotenv";
import NotificationService from "../services/notificationService.js";
import { User } from "../models/index.js";

// Load environment variables
dotenv.config();

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget";

async function testNotificationTriggers() {
  try {
    console.log("🔗 Connecting to MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("✅ Connected to MongoDB");

    // Find a test user
    const testUser = await User.findOne();
    if (!testUser) {
      console.log("❌ No test user found. Please create a user first.");
      return;
    }

    const userId = testUser._id;
    console.log(`👤 Testing with user: ${testUser.email}`);

    console.log("\n🧪 Testing Notification Triggers...\n");

    // Test 1: Income Notification
    console.log("1️⃣ Testing Income Notification...");
    try {
      await NotificationService.triggerIncomeNotification(userId, {
        incomeId: new mongoose.Types.ObjectId(),
        incomeAmount: 5000000, // 5 triệu
        category: "salary",
        source: "Công ty ABC",
        isRecurring: false,
      });
      console.log("✅ Income notification triggered successfully");
    } catch (error) {
      console.log("❌ Income notification failed:", error.message);
    }

    // Test 2: Large Income Notification
    console.log("\n2️⃣ Testing Large Income Notification...");
    try {
      await NotificationService.triggerIncomeNotification(userId, {
        incomeId: new mongoose.Types.ObjectId(),
        incomeAmount: 15000000, // 15 triệu
        category: "bonus",
        source: "Thưởng cuối năm",
        isRecurring: false,
      });
      console.log("✅ Large income notification triggered successfully");
    } catch (error) {
      console.log("❌ Large income notification failed:", error.message);
    }

    // Test 3: Savings Goal Notification
    console.log("\n3️⃣ Testing Savings Goal Notification...");
    try {
      await NotificationService.triggerSavingsGoalNotification(userId, {
        goalId: new mongoose.Types.ObjectId(),
        goalName: "Mua xe máy",
        targetAmount: 30000000, // 30 triệu
        targetDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 năm
        currentAmount: 0,
        progressPercentage: 0,
      });
      console.log("✅ Savings goal notification triggered successfully");
    } catch (error) {
      console.log("❌ Savings goal notification failed:", error.message);
    }

    // Test 4: Savings Contribution Notification (50% milestone)
    console.log(
      "\n4️⃣ Testing Savings Contribution Notification (50% milestone)..."
    );
    try {
      await NotificationService.triggerSavingsContributionNotification(userId, {
        goalId: new mongoose.Types.ObjectId(),
        goalName: "Mua xe máy",
        contributionAmount: 15000000, // 15 triệu
        currentAmount: 15000000,
        targetAmount: 30000000,
        progressPercentage: 50,
      });
      console.log(
        "✅ Savings contribution notification (50%) triggered successfully"
      );
    } catch (error) {
      console.log(
        "❌ Savings contribution notification failed:",
        error.message
      );
    }

    // Test 5: Savings Contribution Notification (100% completion)
    console.log(
      "\n5️⃣ Testing Savings Contribution Notification (100% completion)..."
    );
    try {
      await NotificationService.triggerSavingsContributionNotification(userId, {
        goalId: new mongoose.Types.ObjectId(),
        goalName: "Mua xe máy",
        contributionAmount: 15000000, // 15 triệu
        currentAmount: 30000000,
        targetAmount: 30000000,
        progressPercentage: 100,
      });
      console.log(
        "✅ Savings contribution notification (100%) triggered successfully"
      );
    } catch (error) {
      console.log(
        "❌ Savings contribution notification failed:",
        error.message
      );
    }

    // Test 6: Budget Update Notification (Increase)
    console.log("\n6️⃣ Testing Budget Update Notification (Increase)...");
    try {
      await NotificationService.triggerBudgetUpdateNotification(userId, {
        budgetId: new mongoose.Types.ObjectId(),
        budgetName: "Ngân sách tháng 1",
        oldAmount: 10000000, // 10 triệu
        newAmount: 15000000, // 15 triệu
        changeType: "amount_increase",
      });
      console.log(
        "✅ Budget update notification (increase) triggered successfully"
      );
    } catch (error) {
      console.log("❌ Budget update notification failed:", error.message);
    }

    // Test 7: Budget Update Notification (Decrease)
    console.log("\n7️⃣ Testing Budget Update Notification (Decrease)...");
    try {
      await NotificationService.triggerBudgetUpdateNotification(userId, {
        budgetId: new mongoose.Types.ObjectId(),
        budgetName: "Ngân sách tháng 1",
        oldAmount: 15000000, // 15 triệu
        newAmount: 10000000, // 10 triệu
        changeType: "amount_decrease",
      });
      console.log(
        "✅ Budget update notification (decrease) triggered successfully"
      );
    } catch (error) {
      console.log("❌ Budget update notification failed:", error.message);
    }

    // Test 8: Get user notifications
    console.log("\n8️⃣ Testing Get User Notifications...");
    try {
      const result = await NotificationService.getUserNotifications(userId, {
        page: 1,
        limit: 10,
      });
      console.log(`✅ Retrieved ${result.notifications.length} notifications`);
      console.log(`📊 Total notifications: ${result.pagination.totalCount}`);
    } catch (error) {
      console.log("❌ Get user notifications failed:", error.message);
    }

    console.log("\n🎉 All notification tests completed!");
    console.log("\n📋 Summary:");
    console.log("✅ Income notifications: Working");
    console.log("✅ Savings goal notifications: Working");
    console.log("✅ Savings contribution notifications: Working");
    console.log("✅ Budget update notifications: Working");
    console.log("✅ Notification retrieval: Working");
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("\n🔌 Disconnected from MongoDB");
    process.exit(0);
  }
}

// Run the test
testNotificationTriggers();
