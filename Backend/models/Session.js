import mongoose from "mongoose";
// Schema for user sessions
const SessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    sessionId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    jwtTokenId: {
      type: String,
      required: true,
      index: true,
    },
    deviceInfo: {
      userAgent: {
        type: String,
        required: true,
      },
      platform: {
        type: String,
        enum: [
          "Windows",
          "macOS",
          "Linux",
          "Android",
          "iOS",
          "Flutter",
          "Unknown",
        ],
        default: "Unknown",
      },
      browser: {
        type: String,
        enum: [
          "Chrome",
          "Safari",
          "Firefox",
          "Edge",
          "Opera",
          "Dart",
          "Flutter", // ✅ Added Flutter for mobile app
          "Unknown",
        ],
        default: "Unknown",
      },
      deviceType: {
        type: String,
        enum: ["desktop", "mobile", "tablet"],
        default: "desktop",
      },
      deviceName: String, // Generated name like "Windows 11 - Chrome"
      deviceFingerprint: {
        type: String,
        index: true, // For fast duplicate detection
      },
    },
    location: {
      ip: {
        type: String,
        required: true,
      },
      country: String,
      countryCode: String,
      region: String,
      city: String,
      timezone: String,
      coordinates: {
        lat: Number,
        lng: Number,
      },
    },
    loginTime: {
      type: Date,
      default: Date.now,
    },
    lastActiveTime: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: { expireAfterSeconds: 0 }, // MongoDB TTL index
    },
    metadata: {
      loginMethod: {
        type: String,
        enum: ["password", "google", "biometric"],
        default: "password",
      },
      securityLevel: {
        type: String,
        enum: ["high", "medium", "low"],
        default: "medium",
      },
      riskScore: {
        type: Number,
        min: 0,
        max: 100,
        default: 0,
      },
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);
// Indexes for efficient queries
SessionSchema.index({ userId: 1, isActive: 1 });
SessionSchema.index({ sessionId: 1, isActive: 1 });
SessionSchema.index({ expiresAt: 1 });
SessionSchema.index({ "location.ip": 1 });
// Instance methods
SessionSchema.methods.updateActivity = function () {
  this.lastActiveTime = new Date();
  return this.save();
};
SessionSchema.methods.terminate = function () {
  this.isActive = false;
  this.expiresAt = new Date(); // Expire immediately
  return this.save();
};
SessionSchema.methods.isExpired = function () {
  return this.expiresAt < new Date();
};
SessionSchema.methods.getTimeAgo = function () {
  const now = new Date();
  const diff = now - this.lastActiveTime;
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);
  if (minutes < 1) return "Vừa xong";
  if (minutes < 60) return `${minutes} phút trước`;
  if (hours < 24) return `${hours} giờ trước`;
  return `${days} ngày trước`;
};
// Static methods
SessionSchema.statics.findActiveByUserId = function (userId) {
  return this.find({
    userId,
    isActive: true,
    expiresAt: { $gt: new Date() },
  }).sort({ lastActiveTime: -1 });
};
SessionSchema.statics.findBySessionId = function (sessionId) {
  return this.findOne({
    sessionId,
    isActive: true,
    expiresAt: { $gt: new Date() },
  });
};
SessionSchema.statics.terminateAllUserSessions = function (
  userId,
  excludeSessionId = null
) {
  const query = {
    userId,
    isActive: true,
  };
  if (excludeSessionId) {
    query.sessionId = { $ne: excludeSessionId };
  }
  return this.updateMany(query, {
    isActive: false,
    expiresAt: new Date(),
  });
};
SessionSchema.statics.cleanupExpiredSessions = function () {
  return this.deleteMany({
    $or: [{ expiresAt: { $lt: new Date() } }, { isActive: false }],
  });
};
// Pre-save middleware
SessionSchema.pre("save", function (next) {
  // Generate device name if not set
  if (!this.deviceInfo.deviceName) {
    const platform = this.deviceInfo.platform || "Unknown";
    const browser = this.deviceInfo.browser || "Unknown";
    this.deviceInfo.deviceName = `${platform} - ${browser}`;
  }
  next();
});
const Session = mongoose.model("Session", SessionSchema);
export default Session;