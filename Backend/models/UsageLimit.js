import mongoose from "mongoose";

/**
 * UsageLimit Model
 *
 * Tracks daily feature usage for quota enforcement
 * - OCR scans per day
 * - AI analysis requests
 * - Resets daily at 0h Vietnam time (UTC+7)
 */

const UsageLimitSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    date: {
      type: String, // Format: YYYY-MM-DD
      required: true,
      index: true,
      description: "Date in YYYY-MM-DD format for Vietnam timezone (UTC+7)",
    },
    ocrScans: {
      count: {
        type: Number,
        default: 0,
        min: 0,
        description: "Number of OCR scans used today",
      },
      limit: {
        type: Number,
        default: 10,
        description:
          "Daily limit for OCR scans (10 for free, -1 for unlimited)",
      },
      lastUsedAt: {
        type: Date,
        description: "Timestamp of last OCR scan",
      },
    },
    aiAnalysis: {
      count: {
        type: Number,
        default: 0,
        min: 0,
        description: "Number of AI analysis requests used",
      },
      limit: {
        type: Number,
        default: -1,
        description: "AI analysis limit (-1 for unlimited for premium)",
      },
      lastUsedAt: {
        type: Date,
        description: "Timestamp of last AI analysis request",
      },
    },
    lastResetAt: {
      type: Date,
      default: Date.now,
      description: "Last time the usage was reset (midnight Vietnam time)",
    },
    timezone: {
      type: String,
      default: "Asia/Ho_Chi_Minh",
      description: "Timezone for date calculation",
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Compound unique index to ensure one record per user per day
UsageLimitSchema.index({ userId: 1, date: 1 }, { unique: true });

// Index for cleanup queries (delete old records)
UsageLimitSchema.index({ date: 1 });

// Static methods for usage tracking

/**
 * Get current date in Vietnam timezone (YYYY-MM-DD format)
 * @param {Date} date - Optional date object, defaults to now
 */
UsageLimitSchema.statics.getCurrentDateVN = function (date = null) {
  const targetDate = date || new Date();
  // Convert to Vietnam time (UTC+7)
  const vnTime = new Date(
    targetDate.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" })
  );
  const year = vnTime.getFullYear();
  const month = String(vnTime.getMonth() + 1).padStart(2, "0");
  const day = String(vnTime.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

/**
 * Get or create usage record for today
 */
UsageLimitSchema.statics.getOrCreateToday = async function (
  userId,
  userTier = "free"
) {
  const today = this.getCurrentDateVN();

  let usage = await this.findOne({ userId, date: today });

  if (!usage) {
    // Create new usage record for today
    const ocrLimit = userTier === "premium" ? -1 : 10;
    usage = await this.create({
      userId,
      date: today,
      ocrScans: { count: 0, limit: ocrLimit },
      aiAnalysis: { count: 0, limit: -1 }, // Premium feature check done elsewhere
      lastResetAt: new Date(),
    });
  }

  return usage;
};

/**
 * Check if OCR scan is allowed
 */
UsageLimitSchema.statics.checkOCRLimit = async function (
  userId,
  userTier = "free"
) {
  const usage = await this.getOrCreateToday(userId, userTier);

  if (userTier === "premium" || usage.ocrScans.limit === -1) {
    return {
      allowed: true,
      count: usage.ocrScans.count,
      limit: -1,
      remaining: -1,
      tier: userTier,
    };
  }

  const allowed = usage.ocrScans.count < usage.ocrScans.limit;

  return {
    allowed,
    count: usage.ocrScans.count,
    limit: usage.ocrScans.limit,
    remaining: Math.max(0, usage.ocrScans.limit - usage.ocrScans.count),
    tier: userTier,
  };
};

/**
 * Increment OCR scan count
 */
UsageLimitSchema.statics.incrementOCRCount = async function (
  userId,
  userTier = "free"
) {
  const today = this.getCurrentDateVN();
  const ocrLimit = userTier === "premium" ? -1 : 10;

  const usage = await this.findOneAndUpdate(
    { userId, date: today },
    {
      $inc: { "ocrScans.count": 1 },
      $set: { "ocrScans.lastUsedAt": new Date() },
      $setOnInsert: {
        "ocrScans.limit": ocrLimit,
        "aiAnalysis.count": 0,
        "aiAnalysis.limit": -1,
        lastResetAt: new Date(),
      },
    },
    { new: true, upsert: true }
  );

  return usage;
};

/**
 * Check if AI analysis is allowed
 */
UsageLimitSchema.statics.checkAILimit = async function (
  userId,
  userTier = "free"
) {
  // AI Analysis is premium-only feature
  if (userTier !== "premium") {
    return {
      allowed: false,
      count: 0,
      limit: 0,
      remaining: 0,
      tier: userTier,
      premiumRequired: true,
    };
  }

  const usage = await this.getOrCreateToday(userId, userTier);

  return {
    allowed: true,
    count: usage.aiAnalysis.count,
    limit: -1,
    remaining: -1,
    tier: userTier,
    premiumRequired: false,
  };
};

/**
 * Increment AI analysis count
 */
UsageLimitSchema.statics.incrementAICount = async function (
  userId,
  userTier = "free"
) {
  const today = this.getCurrentDateVN();
  const ocrLimit = userTier === "premium" ? -1 : 10;

  const usage = await this.findOneAndUpdate(
    { userId, date: today },
    {
      $inc: { "aiAnalysis.count": 1 },
      $set: { "aiAnalysis.lastUsedAt": new Date() },
      $setOnInsert: {
        "ocrScans.count": 0,
        "ocrScans.limit": ocrLimit,
        "aiAnalysis.limit": -1,
        lastResetAt: new Date(),
      },
    },
    { new: true, upsert: true }
  );

  return usage;
};

/**
 * Get usage statistics for a user
 */
UsageLimitSchema.statics.getUserUsageStats = async function (
  userId,
  userTier = "free"
) {
  const usage = await this.getOrCreateToday(userId, userTier);

  const ocrCheck = await this.checkOCRLimit(userId, userTier);
  const aiCheck = await this.checkAILimit(userId, userTier);

  return {
    date: usage.date,
    ocr: {
      count: usage.ocrScans.count,
      limit: ocrCheck.limit,
      remaining: ocrCheck.remaining,
      lastUsedAt: usage.ocrScans.lastUsedAt,
    },
    aiAnalysis: {
      count: usage.aiAnalysis.count,
      enabled: aiCheck.allowed,
      lastUsedAt: usage.aiAnalysis.lastUsedAt,
    },
    lastResetAt: usage.lastResetAt,
  };
};

/**
 * Reset daily limits (called by cron job at midnight Vietnam time)
 */
UsageLimitSchema.statics.resetDailyLimits = async function () {
  const today = this.getCurrentDateVN();
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = this.getCurrentDateVN.call({}, yesterday);

  // Note: We don't actually reset, we create new records for new day
  // This preserves history. Old records can be deleted by cleanup job.

  console.log(`[UsageLimit] Daily reset checkpoint - Today: ${today}`);

  // Optional: Delete records older than 30 days to save space
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const cutoffDate = this.getCurrentDateVN.call({}, thirtyDaysAgo);

  const deleteResult = await this.deleteMany({
    date: { $lt: cutoffDate },
  });

  console.log(
    `[UsageLimit] Deleted ${deleteResult.deletedCount} records older than ${cutoffDate}`
  );

  return {
    today,
    deletedOldRecords: deleteResult.deletedCount,
  };
};

/**
 * Update limits when user subscription changes
 */
UsageLimitSchema.statics.updateUserLimits = async function (userId, newTier) {
  const today = this.getCurrentDateVN();
  const newOCRLimit = newTier === "premium" ? -1 : 10;

  const usage = await this.findOneAndUpdate(
    { userId, date: today },
    {
      $set: {
        "ocrScans.limit": newOCRLimit,
        "aiAnalysis.limit": -1,
      },
    },
    { new: true, upsert: true }
  );

  return usage;
};

// Instance methods

/**
 * Check if OCR quota is exceeded
 */
UsageLimitSchema.methods.isOCRQuotaExceeded = function () {
  if (this.ocrScans.limit === -1) return false; // Unlimited
  return this.ocrScans.count >= this.ocrScans.limit;
};

/**
 * Get remaining OCR scans
 */
UsageLimitSchema.methods.getRemainingOCRScans = function () {
  if (this.ocrScans.limit === -1) return -1; // Unlimited
  return Math.max(0, this.ocrScans.limit - this.ocrScans.count);
};

const UsageLimit = mongoose.model("UsageLimit", UsageLimitSchema);

export default UsageLimit;
