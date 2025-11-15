import mongoose from "mongoose";
import "../config/env.js";
import UsageLimit from "../models/UsageLimit.js";
import User from "../models/User.js";

async function checkAllUsersToday() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB\n");

    const today = UsageLimit.getCurrentDateVN();
    console.log(`📅 Today (VN timezone): ${today}`);
    console.log("─".repeat(60));
    console.log();

    const records = await UsageLimit.find({ date: today }).populate(
      "userId",
      "email subscription.tier subscription.status"
    );

    if (records.length === 0) {
      console.log("⚠️  No usage records found for today");
      console.log("This means:");
      console.log("- No users have opened Add Expense screen yet");
      console.log("- No users have scanned any receipts yet");
      console.log();
      console.log("✅ This is normal for early morning hours!");
      process.exit(0);
    }

    console.log(`📊 Found ${records.length} usage record(s) for today:\n`);

    // Sort by count (highest first) to see most active users
    const sorted = records.sort((a, b) => b.ocrScans.count - a.ocrScans.count);

    sorted.forEach((record, index) => {
      const user = record.userId;
      const isPremium = user.subscription.tier === "premium";

      console.log(`${index + 1}. 👤 ${user.email}`);
      console.log(
        `   Tier: ${user.subscription.tier.toUpperCase()} ${isPremium ? "⭐" : ""}`
      );
      console.log(
        `   OCR Usage: ${record.ocrScans.count}/${record.ocrScans.limit === -1 ? "∞" : record.ocrScans.limit}`
      );

      if (record.ocrScans.lastUsedAt) {
        const lastUsed = new Date(record.ocrScans.lastUsedAt);
        const time = lastUsed.toLocaleTimeString("vi-VN", {
          hour: "2-digit",
          minute: "2-digit",
          timeZone: "Asia/Ho_Chi_Minh",
        });
        console.log(`   Last Scan: ${time}`);
      } else {
        console.log(`   Last Scan: Never (only opened screen)`);
      }

      // Show status
      if (record.ocrScans.count === 0) {
        console.log(
          `   Status: ✅ No scans yet today (0/${record.ocrScans.limit})`
        );
      } else if (
        record.ocrScans.count >= record.ocrScans.limit &&
        record.ocrScans.limit !== -1
      ) {
        console.log(`   Status: 🚫 Quota exhausted`);
      } else {
        const remaining = isPremium
          ? "∞"
          : record.ocrScans.limit - record.ocrScans.count;
        console.log(`   Status: ✅ ${remaining} scans remaining`);
      }

      console.log();
    });

    console.log("─".repeat(60));
    console.log();

    // Summary
    const totalScans = records.reduce((sum, r) => sum + r.ocrScans.count, 0);
    const usersWithScans = records.filter((r) => r.ocrScans.count > 0).length;
    const usersWithoutScans = records.filter(
      (r) => r.ocrScans.count === 0
    ).length;

    console.log("📈 Summary:");
    console.log(`   Total users active today: ${records.length}`);
    console.log(`   Users who scanned: ${usersWithScans}`);
    console.log(`   Users who only opened screen: ${usersWithoutScans}`);
    console.log(`   Total scans today: ${totalScans}`);
    console.log();

    // Most active user
    if (usersWithScans > 0) {
      const mostActive = sorted[0];
      console.log("🏆 Most active user:");
      console.log(`   ${mostActive.userId.email}`);
      console.log(`   Scans: ${mostActive.ocrScans.count}`);
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

checkAllUsersToday();
