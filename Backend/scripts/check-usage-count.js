import mongoose from "mongoose";
import "../config/env.js";
import UsageLimit from "../models/UsageLimit.js";
import User from "../models/User.js";

async function checkUsageCount() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB\n");

    // Find any user (preferably free tier)
    const testUser = await User.findOne({ "subscription.tier": "free" }).sort({
      createdAt: -1,
    });
    if (!testUser) {
      console.log("❌ No users found in database");
      process.exit(1);
    }

    console.log("📊 Test User:", testUser.email);
    console.log("Tier:", testUser.subscription.tier);
    console.log("User ID:", testUser._id.toString());
    console.log();

    // Get today's date in Vietnam timezone
    const today = UsageLimit.getCurrentDateVN();
    console.log("📅 Today (VN):", today);
    console.log();

    // Find today's usage record
    const usage = await UsageLimit.findOne({
      userId: testUser._id,
      date: today,
    });

    if (!usage) {
      console.log("⚠️  No usage record found for today");
      console.log("This is NORMAL - record will be created when:");
      console.log("1. User opens Add Expense screen (calls getUsage)");
      console.log("2. User scans their first receipt");
      console.log();
      console.log("Expected behavior:");
      console.log("- Before any scan: 0/10");
      console.log("- After 1st scan: 1/10");
      console.log("- After 2nd scan: 2/10");
      console.log("- etc.");
    } else {
      console.log("📈 Today's Usage Record:");
      console.log(JSON.stringify(usage, null, 2));
      console.log();
      console.log(`OCR Count: ${usage.ocrScans.count}/${usage.ocrScans.limit}`);
      console.log(`Last Used: ${usage.ocrScans.lastUsedAt || "Never (today)"}`);
    }

    console.log();
    console.log("🔍 Checking behavior:");
    console.log();

    // Simulate getUsage call (what happens when user opens screen)
    console.log("1️⃣  Simulating user opening Add Expense screen...");
    const statsBeforeScan = await UsageLimit.getUserUsageStats(
      testUser._id,
      testUser.subscription.tier
    );
    console.log("   Stats returned to frontend:");
    console.log(
      `   OCR: ${statsBeforeScan.ocr.count}/${statsBeforeScan.ocr.limit}`
    );
    console.log(`   Remaining: ${statsBeforeScan.ocr.remaining}`);
    console.log();

    // Check if record was created
    const recordAfterGet = await UsageLimit.findOne({
      userId: testUser._id,
      date: today,
    });
    console.log(
      `   ✅ Record ${recordAfterGet ? "CREATED" : "already existed"}`
    );
    console.log(
      `   Count in DB: ${recordAfterGet?.ocrScans.count || 0}/${recordAfterGet?.ocrScans.limit || 10}`
    );
    console.log();

    // Show what SHOULD display on screen
    console.log("📱 What Frontend SHOULD Show:");
    if (statsBeforeScan.ocr.count === 0) {
      console.log("   ✅ 0/10 (User hasn't scanned yet today)");
    } else {
      console.log(
        `   ✅ ${statsBeforeScan.ocr.count}/${statsBeforeScan.ocr.limit} (User already scanned ${statsBeforeScan.ocr.count} times today)`
      );
    }
    console.log();

    // Explain the issue
    console.log("🐛 If Frontend Shows 1/10 Instead:");
    console.log("   Possible causes:");
    console.log(
      "   1. Frontend is calling incrementOCRCount somewhere (CHECK LOGS)"
    );
    console.log("   2. Frontend is parsing response incorrectly");
    console.log(
      "   3. There's a phantom scan from earlier today that wasn't visible"
    );
    console.log();
    console.log("   To debug:");
    console.log("   - Check Backend logs when opening Add Expense screen");
    console.log(
      "   - Look for '[OCR] Incrementing OCR count...' message (should NOT appear)"
    );
    console.log("   - Check frontend network tab for API responses");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

checkUsageCount();
