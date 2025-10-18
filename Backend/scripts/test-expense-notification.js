import mongoose from "mongoose";
import dotenv from "dotenv";
import Expense from "../models/Expense.js";
import Budget from "../models/Budget.js";
import Notification from "../models/Notification.js";
import User from "../models/User.js";

dotenv.config();

const TEST_USER_ID = "68e0e0e85af682e7a47f48ff"; // User ID từ log

async function testExpenseNotification() {
  try {
    console.log("🔗 Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ MongoDB connected");

    // 1. Tạo expense với số tiền lớn để trigger anomaly alert
    console.log("\n🧪 Testing anomaly alert...");

    const largeExpense = new Expense({
      userId: TEST_USER_ID,
      amount: 3000000, // 3 triệu - lớn hơn ngưỡng 2 triệu
      category: "shopping",
      title: "Test Large Expense",
      description: "Test large expense for anomaly detection",
      date: new Date(),
      paymentMethod: "cash",
      location: {
        name: "Test Location",
        address: "Test Address",
      },
    });

    const savedExpense = await largeExpense.save();
    console.log("✅ Large expense created:", savedExpense._id);

    // 2. Kiểm tra xem có notification nào được tạo không
    console.log("\n🔍 Checking for notifications...");
    const notifications = await Notification.find({ userId: TEST_USER_ID })
      .sort({ createdAt: -1 })
      .limit(5);

    console.log(`📊 Found ${notifications.length} notifications:`);
    notifications.forEach((notif, index) => {
      console.log(
        `${index + 1}. ${notif.title} - ${notif.type} - ${notif.createdAt}`
      );
    });

    // 3. Test budget alert
    console.log("\n🧪 Testing budget alert...");

    // Tìm budget của user
    const budget = await Budget.findOne({ userId: TEST_USER_ID });
    if (budget) {
      console.log(
        "📊 Found budget:",
        budget.name,
        "Amount:",
        budget.totalAmount,
        "Spent:",
        budget.spentAmount
      );

      // Tạo expense để vượt 80% budget
      const budgetExpense = new Expense({
        userId: TEST_USER_ID,
        amount: budget.totalAmount * 0.5, // Chi thêm 50% budget
        category: "food",
        title: "Test Budget Expense",
        description: "Test budget alert expense",
        date: new Date(),
        paymentMethod: "cash",
        budgetId: budget._id,
        location: {
          name: "Test Location",
          address: "Test Address",
        },
      });

      const savedBudgetExpense = await budgetExpense.save();
      console.log("✅ Budget expense created:", savedBudgetExpense._id);

      // Update budget spent amount
      budget.spentAmount += budgetExpense.amount;
      await budget.save();
      console.log("✅ Budget updated, new spent amount:", budget.spentAmount);

      // Kiểm tra notifications sau budget alert
      const newNotifications = await Notification.find({ userId: TEST_USER_ID })
        .sort({ createdAt: -1 })
        .limit(3);
      console.log(
        `📊 Found ${newNotifications.length} notifications after budget test:`
      );
      newNotifications.forEach((notif, index) => {
        console.log(
          `${index + 1}. ${notif.title} - ${notif.type} - ${notif.createdAt}`
        );
      });
    } else {
      console.log("❌ No budget found for user");
    }

    // 4. Test manual notification creation
    console.log("\n🧪 Testing manual notification creation...");

    const manualNotification = new Notification({
      userId: TEST_USER_ID,
      type: "expense_added",
      title: "🧪 Test Notification",
      message: "This is a manual test notification",
      category: "expense",
      priority: "normal",
      isRead: false,
      data: {
        testData: "manual test",
      },
    });

    const savedNotification = await manualNotification.save();
    console.log("✅ Manual notification created:", savedNotification._id);

    // 5. Final notification count
    const finalNotifications = await Notification.find({
      userId: TEST_USER_ID,
    }).sort({ createdAt: -1 });
    console.log(
      `\n📊 Total notifications for user: ${finalNotifications.length}`
    );
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error(error.stack);
  } finally {
    await mongoose.disconnect();
    console.log("📡 Database connection closed");
  }
}

// Run the test
testExpenseNotification();
