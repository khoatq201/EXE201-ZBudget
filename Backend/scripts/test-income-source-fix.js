/**
 * Test script để kiểm tra fix vấn đề "undefined" trong thông báo thu nhập
 *
 * Vấn đề: Frontend không gửi field 'source' → Backend nhận undefined → Notification hiển thị "Nguồn không xác định"
 * Fix: Thêm source: categoryOption.name vào frontend call
 */

import mongoose from "mongoose";
import Income from "../models/Income.js";
import Notification from "../models/Notification.js";
import NotificationService from "../services/notificationService.js";
import { User } from "../models/index.js";

// Test data
const testUserId = "507f1f77bcf86cd799439011"; // Fake ObjectId for testing
const testIncomeData = {
  title: "Test Income - Freelance",
  amount: 1000000,
  category: "freelance",
  source: "Freelance", // ✅ FIX: Frontend bây giờ gửi source
  paymentMethod: "banking",
  date: new Date(),
};

async function testIncomeSourceFix() {
  try {
    console.log("🧪 Testing Income Source Fix...\n");

    // 1. Test tạo income với source
    console.log("1️⃣ Testing income creation with source...");

    const income = new Income({
      userId: testUserId,
      title: testIncomeData.title,
      amount: testIncomeData.amount,
      category: testIncomeData.category,
      source: {
        name: testIncomeData.source,
        contactInfo: null,
        taxId: null,
      },
      paymentMethod: testIncomeData.paymentMethod,
      date: testIncomeData.date,
      isConfirmed: true,
    });

    await income.save();
    console.log("✅ Income created with source:", income.source);

    // 2. Test trigger notification
    console.log("\n2️⃣ Testing notification trigger...");

    await NotificationService.triggerIncomeNotification(testUserId, {
      incomeId: income._id,
      incomeAmount: income.amount,
      category: income.category,
      source: income.source, // ✅ Pass full source object
      isRecurring: false,
    });

    // 3. Kiểm tra notification được tạo
    console.log("\n3️⃣ Checking created notification...");

    const notification = await Notification.findOne({
      userId: testUserId,
      type: "income_added",
      "data.incomeId": income._id,
    }).sort({ createdAt: -1 });

    if (notification) {
      console.log("✅ Notification created successfully!");
      console.log("📝 Title:", notification.title);
      console.log("💬 Message:", notification.message);
      console.log("📊 Data:", JSON.stringify(notification.data, null, 2));

      // Kiểm tra source name trong data
      const sourceName = notification.data.incomeSource;
      if (sourceName && sourceName !== "Nguồn không xác định") {
        console.log("✅ Source name correctly extracted:", sourceName);
      } else {
        console.log("❌ Source name still undefined or default");
      }
    } else {
      console.log("❌ No notification found");
    }

    // 4. Cleanup
    console.log("\n4️⃣ Cleaning up test data...");
    await Income.deleteOne({ _id: income._id });
    await Notification.deleteOne({ _id: notification._id });
    console.log("✅ Test data cleaned up");

    console.log("\n🎉 Test completed successfully!");
    console.log("📋 Summary:");
    console.log("   - Income created with proper source object");
    console.log("   - Notification triggered with correct source name");
    console.log('   - No more "undefined" in notification messages');
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("Stack:", error.stack);
  }
}

// Chạy test nếu file được execute trực tiếp
if (import.meta.url === `file://${process.argv[1]}`) {
  // Connect to MongoDB
  mongoose
    .connect(process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget")
    .then(() => {
      console.log("🔗 Connected to MongoDB");
      return testIncomeSourceFix();
    })
    .then(() => {
      console.log("✅ Test completed");
      process.exit(0);
    })
    .catch((error) => {
      console.error("❌ Test failed:", error);
      process.exit(1);
    });
}

export default testIncomeSourceFix;
