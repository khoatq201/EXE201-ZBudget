import mongoose from "mongoose";
import { User, connectDB } from "../models/index.js";

/**
 * Script để nâng cấp 20 users từ Free lên Premium
 * Premium expiry date: 1 tháng kể từ ngày chạy script
 */

async function upgradeToPremium() {
  try {
    console.log("\n🚀 BẮT ĐẦU NÂNG CẤP USERS LÊN PREMIUM");
    console.log("=".repeat(60));

    await connectDB();
    console.log("✅ Đã kết nối MongoDB");

    // Tìm 20 users có tier = "free"
    const freeUsers = await User.find({
      "subscription.tier": "free",
    })
      .limit(20)
      .select("email profile.name subscription");

    if (freeUsers.length === 0) {
      console.log("\n❌ Không tìm thấy user nào có tier = 'free'");
      process.exit(0);
    }

    console.log(`\n📊 Tìm thấy ${freeUsers.length} users có tier = 'free'`);

    // Tính toán ngày bắt đầu và ngày hết hạn
    const startDate = new Date();
    const expiryDate = new Date();
    expiryDate.setMonth(expiryDate.getMonth() + 1); // Thêm 1 tháng

    console.log(`\n📅 Thông tin Premium:`);
    console.log(`   - Ngày bắt đầu: ${startDate.toLocaleDateString("vi-VN")}`);
    console.log(`   - Ngày hết hạn: ${expiryDate.toLocaleDateString("vi-VN")}`);

    // Cập nhật subscription cho từng user
    const updatePromises = freeUsers.map(async (user) => {
      // Thêm vào subscription history
      const historyEntry = {
        tier: "premium",
        action: "upgrade",
        startDate: startDate,
        endDate: expiryDate,
        price: {
          amount: 25000,
          currency: "VND",
          duration: "monthly",
        },
        paymentMethod: "manual",
        note: "Upgraded by admin script",
        timestamp: new Date(),
      };

      return User.findByIdAndUpdate(
        user._id,
        {
          $set: {
            "subscription.tier": "premium",
            "subscription.status": "active",
            "subscription.startDate": startDate,
            "subscription.expiryDate": expiryDate,
            "subscription.price": {
              amount: 25000,
              currency: "VND",
              duration: "monthly",
            },
            "subscription.features": {
              maxBudgets: 20,
              maxSavingsGoals: 10,
              ocrScansPerDay: -1, // unlimited
              aiAnalysisEnabled: true,
            },
            "subscription.paymentMethod": "manual",
            "subscription.lastUpdated": new Date(),
          },
          $push: {
            subscriptionHistory: historyEntry,
          },
        },
        { new: true }
      );
    });

    const updatedUsers = await Promise.all(updatePromises);

    console.log("\n" + "=".repeat(60));
    console.log("✅ ĐÃ NÂNG CẤP THÀNH CÔNG");
    console.log("=".repeat(60));
    console.log(`\n📋 Danh sách ${updatedUsers.length} users đã nâng cấp:\n`);

    updatedUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email}`);
      console.log(`   Tên: ${user.profile.name}`);
      console.log(`   Tier: ${user.subscription.tier}`);
      console.log(`   Status: ${user.subscription.status}`);
      console.log(
        `   Hết hạn: ${user.subscription.expiryDate.toLocaleDateString(
          "vi-VN"
        )}`
      );
      console.log();
    });

    console.log("=".repeat(60));
    console.log("🎉 HOÀN TẤT!\n");

    process.exit(0);
  } catch (error) {
    console.error("\n❌ Lỗi khi nâng cấp users:", error.message);
    console.error(error);
    process.exit(1);
  }
}

// Chạy script
upgradeToPremium();
