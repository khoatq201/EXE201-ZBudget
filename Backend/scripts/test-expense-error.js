import mongoose from "mongoose";
import Expense from "../models/Expense.js";
import User from "../models/User.js";
import dotenv from "dotenv";

dotenv.config();

const TEST_USER_ID = "68f33f108bf7f628357858a9";

async function testExpenseError() {
  try {
    console.log("🔗 Connecting to MongoDB...");
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ MongoDB connected");

    // Test tạo expense với số tiền lớn hơn Ready to Assign
    console.log("\n🧪 Testing expense with large amount...");

    // Tìm user đầu tiên
    const user = await User.findOne();
    if (!user) {
      console.log("❌ No users found");
      return;
    }

    console.log(`👤 Found user: ${user._id}`);

    const readyToAssign = parseFloat(
      user.financialSummary?.readyToAssign?.toString() || "0"
    );
    console.log(
      `📊 User Ready to Assign: ${readyToAssign.toLocaleString("vi-VN")} đ`
    );

    // Tạo expense với số tiền lớn hơn Ready to Assign
    const largeAmount = readyToAssign + 1000000; // Thêm 1 triệu
    console.log(
      `💰 Trying to create expense: ${largeAmount.toLocaleString("vi-VN")} đ`
    );

    const expense = new Expense({
      userId: user._id,
      title: "Test Large Expense",
      description: "Testing error handling",
      amount: largeAmount,
      category: "shopping",
      date: new Date(),
      paymentMethod: "cash",
    });

    await expense.save();
    console.log("✅ Large expense created successfully");
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    if (error.message.includes("Ready to Assign")) {
      console.log(
        "✅ Error handling working correctly - Ready to Assign validation caught"
      );
    }
  } finally {
    await mongoose.disconnect();
    console.log("📡 Database connection closed");
  }
}

testExpenseError();
