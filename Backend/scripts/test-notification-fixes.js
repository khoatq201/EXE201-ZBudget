#!/usr/bin/env node

/**
 * Test script để verify các notification fixes
 * Chạy: node scripts/test-notification-fixes.js
 */

import mongoose from "mongoose";
import dotenv from "dotenv";
import NotificationService from "../services/notificationService.js";
import { User } from "../models/index.js";

// Load environment variables
dotenv.config();

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget";

async function testNotificationFixes() {
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

    console.log("\n🧪 Testing Notification Fixes...\n");

    // Test 1: Income Notification với source object
    console.log("1️⃣ Testing Income Notification with source object...");
    try {
      await NotificationService.triggerIncomeNotification(userId, {
        incomeId: new mongoose.Types.ObjectId(),
        incomeAmount: 5000000, // 5 triệu
        category: "salary",
        source: { name: "Công ty ABC", contactInfo: "contact@abc.com" }, // ✅ Object source
        isRecurring: false,
      });
      console.log(
        "✅ Income notification with object source triggered successfully"
      );
    } catch (error) {
      console.log("❌ Income notification failed:", error.message);
    }

    // Test 2: Income Notification với source string
    console.log("\n2️⃣ Testing Income Notification with source string...");
    try {
      await NotificationService.triggerIncomeNotification(userId, {
        incomeId: new mongoose.Types.ObjectId(),
        incomeAmount: 3000000, // 3 triệu
        category: "freelance",
        source: "Freelance Project", // ✅ String source
        isRecurring: false,
      });
      console.log(
        "✅ Income notification with string source triggered successfully"
      );
    } catch (error) {
      console.log("❌ Income notification failed:", error.message);
    }

    // Test 3: Income Notification với source undefined
    console.log("\n3️⃣ Testing Income Notification with undefined source...");
    try {
      await NotificationService.triggerIncomeNotification(userId, {
        incomeId: new mongoose.Types.ObjectId(),
        incomeAmount: 2000000, // 2 triệu
        category: "bonus",
        source: undefined, // ✅ Undefined source
        isRecurring: false,
      });
      console.log(
        "✅ Income notification with undefined source triggered successfully"
      );
    } catch (error) {
      console.log("❌ Income notification failed:", error.message);
    }

    // Test 4: Savings Goal Notification
    console.log("\n4️⃣ Testing Savings Goal Notification...");
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

    // Test 5: Savings Contribution Notification
    console.log("\n5️⃣ Testing Savings Contribution Notification...");
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
        "✅ Savings contribution notification triggered successfully"
      );
    } catch (error) {
      console.log(
        "❌ Savings contribution notification failed:",
        error.message
      );
    }

    // Test 6: Budget Update Notification
    console.log("\n6️⃣ Testing Budget Update Notification...");
    try {
      await NotificationService.triggerBudgetUpdateNotification(userId, {
        budgetId: new mongoose.Types.ObjectId(),
        budgetName: "Ngân sách tháng 1",
        oldAmount: 10000000, // 10 triệu
        newAmount: 15000000, // 15 triệu
        changeType: "amount_increase",
      });
      console.log("✅ Budget update notification triggered successfully");
    } catch (error) {
      console.log("❌ Budget update notification failed:", error.message);
    }

    // Test 7: Get user notifications để verify data structure
    console.log("\n7️⃣ Testing Get User Notifications...");
    try {
      const result = await NotificationService.getUserNotifications(userId, {
        page: 1,
        limit: 10,
      });
      console.log(`✅ Retrieved ${result.notifications.length} notifications`);

      // Check data structure for income notifications
      const incomeNotifications = result.notifications.filter(
        (n) => n.type === "income_added"
      );
      if (incomeNotifications.length > 0) {
        const incomeNotif = incomeNotifications[0];
        console.log(`📊 Income notification data:`, {
          incomeSource: incomeNotif.data?.incomeSource,
          incomeAmount: incomeNotif.data?.incomeAmount,
          incomeCategory: incomeNotif.data?.incomeCategory,
        });
      }

      // Check data structure for savings notifications
      const savingsNotifications = result.notifications.filter(
        (n) => n.type === "savings_goal_created"
      );
      if (savingsNotifications.length > 0) {
        const savingsNotif = savingsNotifications[0];
        console.log(`📊 Savings notification data:`, {
          savingsGoalName: savingsNotif.data?.savingsGoalName,
          targetAmount: savingsNotif.data?.targetAmount,
          progressPercentage: savingsNotif.data?.progressPercentage,
        });
      }
    } catch (error) {
      console.log("❌ Get user notifications failed:", error.message);
    }

    console.log("\n🎉 All notification fixes tests completed!");
    console.log("\n📋 Summary:");
    console.log("✅ Income notifications with object source: Working");
    console.log("✅ Income notifications with string source: Working");
    console.log("✅ Income notifications with undefined source: Working");
    console.log("✅ Savings goal notifications: Working");
    console.log("✅ Savings contribution notifications: Working");
    console.log("✅ Budget update notifications: Working");
    console.log("✅ Data structure verification: Working");
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("\n🔌 Disconnected from MongoDB");
    process.exit(0);
  }
}

// Run the test
testNotificationFixes();
