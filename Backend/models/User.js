import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import validator from "validator";
// Sub-schemas cho nested objects
const ProfileSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Tên người dùng là bắt buộc"],
      trim: true,
      maxlength: [100, "Tên không được vượt quá 100 ký tự"],
    },
    avatar: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || validator.isURL(v);
        },
        message: "Avatar phải là URL hợp lệ",
      },
    },
    phone: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^(\+84|84|0)(3|5|7|8|9)[0-9]{8}$/.test(v);
        },
        message: "Số điện thoại không hợp lệ",
      },
    },
    dateOfBirth: {
      type: Date,
    },
    gender: {
      type: String,
      enum: ["male", "female", "other"],
      default: "other",
    },
    location: {
      city: {
        type: String,
        maxlength: [50, "Tên thành phố không được vượt quá 50 ký tự"],
      },
      country: {
        type: String,
        default: "Vietnam",
        maxlength: [50, "Tên quốc gia không được vượt quá 50 ký tự"],
      },
    },
  },
  { _id: false }
);
const CurrencySettingsSchema = new mongoose.Schema(
  {
    primary: {
      type: String,
      enum: ["VND", "USD", "EUR"],
      default: "VND",
    },
    displayFormat: {
      type: String,
      enum: ["đ", "VND", "₫", "$", "€"],
      default: "đ",
    },
    decimalPlaces: {
      type: Number,
      min: 0,
      max: 4,
      default: 0,
    },
  },
  { _id: false }
);
// Notification Types Schema
const NotificationTypeSettingSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: [
        "budget",
        "expense",
        "income",
        "challenge",
        "reminder",
        "achievement",
        "security",
        "system",
        "marketing",
      ],
      required: true,
    },
    isEnabled: { type: Boolean, default: true },
    showBadge: { type: Boolean, default: true },
    playSound: { type: Boolean, default: true },
    vibrate: { type: Boolean, default: true },
    frequency: {
      type: String,
      enum: ["immediately", "daily", "weekly", "monthly", "never"],
      default: "immediately",
    },
    scheduledTime: String, // Format: "HH:mm"
  },
  { _id: false }
);
// Quiet Hours Schema
const QuietHoursSchema = new mongoose.Schema(
  {
    isEnabled: { type: Boolean, default: false },
    startTime: { type: String, default: "22:00" },
    endTime: { type: String, default: "07:00" },
    selectedDays: { type: [Number], default: [1, 2, 3, 4, 5, 6, 7] }, // 1=Monday, 7=Sunday
  },
  { _id: false }
);
const NotificationSettingsSchema = new mongoose.Schema(
  {
    // Global Settings
    isGlobalEnabled: { type: Boolean, default: true },
    groupNotifications: { type: Boolean, default: true },
    showPreviewInNotifications: { type: Boolean, default: true },
    notificationSound: { type: String, default: "default" },
    maxNotificationsPerDay: { type: Number, default: 50 },
    enableSmartNotifications: { type: Boolean, default: true },
    // Individual notification type settings
    notificationSettings: {
      type: [NotificationTypeSettingSchema],
      default: [],
    },
    // Quiet hours
    quietHours: { type: QuietHoursSchema, default: () => ({}) },
    // Legacy fields for backward compatibility
    challenges: { type: Boolean, default: true },
    budgetAlerts: { type: Boolean, default: true },
    groupActivities: { type: Boolean, default: true },
    weeklyReports: { type: Boolean, default: true },
    pushEnabled: { type: Boolean, default: true },
  },
  { _id: false }
);
// Login Session Schema for tracking active sessions
const SessionSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true },
    deviceName: { type: String, required: true },
    deviceType: {
      type: String,
      enum: ["mobile", "tablet", "desktop", "web"],
      default: "web",
    },
    location: { type: String, default: "Unknown" },
    ipAddress: { type: String, required: true },
    userAgent: { type: String, default: "" },
    loginTime: { type: Date, default: Date.now },
    lastActiveTime: { type: Date, default: Date.now },
    isCurrent: { type: Boolean, default: false },
    isRevoked: { type: Boolean, default: false },
  },
  { _id: false }
);
const SecuritySettingsSchema = new mongoose.Schema(
  {
    // Authentication
    biometricEnabled: { type: Boolean, default: false },
    pinEnabled: { type: Boolean, default: false },
    isTwoFactorEnabled: { type: Boolean, default: false },
    twoFactorSecret: { type: String, default: null }, // For TOTP
    primaryAuthMethod: {
      type: String,
      enum: ["password", "biometric", "pin", "pattern"],
      default: "password",
    },
    enabledAuthMethods: [
      {
        type: String,
        enum: ["password", "biometric", "pin", "pattern"],
        default: ["password"],
      },
    ],
    // Session Management
    isAutoLockEnabled: { type: Boolean, default: true },
    sessionTimeout: {
      type: Number,
      min: 5,
      max: 1440, // 24 hours max instead of 180 (3 hours)
      default: 30,
    },
    // Additional security fields to match frontend
    twoFactorEnabled: { type: Boolean, default: false },
    autoLockEnabled: { type: Boolean, default: true },
    loginNotificationEnabled: { type: Boolean, default: true },
    dataEncryptionEnabled: { type: Boolean, default: true },
    maxFailedAttempts: { type: Number, min: 3, max: 10, default: 5 },
    screenshotBlocked: { type: Boolean, default: false },
    appPinEnabled: { type: Boolean, default: false },
    primaryAuthMethod: {
      type: String,
      enum: ["password", "biometric", "pin"],
      default: "password",
    },
    lastPasswordChange: { type: Date, default: Date.now },
    // Fields for current backend compatibility
    sessionPersistence: { type: Boolean, default: true },
    keepSessionsAcrossDevices: { type: Boolean, default: false },
    enablePrivacyMode: { type: Boolean, default: false },
    enhancedProtection: { type: Boolean, default: false },
    biometricAuth: { type: Boolean, default: false }, // alias for biometricEnabled
  },
  { _id: false }
);
const SettingsSchema = new mongoose.Schema(
  {
    currency: {
      type: CurrencySettingsSchema,
      default: () => ({}),
    },
    language: {
      type: String,
      enum: ["vi", "en"],
      default: "vi",
    },
    theme: {
      type: String,
      enum: ["light", "dark", "auto"],
      default: "light",
    },
    notifications: {
      type: NotificationSettingsSchema,
      default: () => ({}),
    },
    security: {
      type: SecuritySettingsSchema,
      default: () => ({}),
    },
  },
  { _id: false }
);
const StatsSchema = new mongoose.Schema(
  {
    level: {
      type: Number,
      min: 1,
      default: 1,
    },
    points: {
      type: Number,
      min: 0,
      default: 0,
    },
    currentStreak: {
      type: Number,
      min: 0,
      default: 0,
    },
    longestStreak: {
      type: Number,
      min: 0,
      default: 0,
    },
    totalSaved: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    challengesCompleted: {
      type: Number,
      min: 0,
      default: 0,
    },
    rank: {
      type: String,
      enum: ["Bronze", "Silver", "Gold", "Platinum"],
      default: "Bronze",
    },
  },
  { _id: false }
);
const FinancialSummarySchema = new mongoose.Schema(
  {
    monthlyAllowance: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) >= 0;
        },
        message: "Định mức tháng phải >= 0",
      },
    },
    currentBalance: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    totalIncome: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    totalExpenses: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    totalSavings: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    // YNAB-style Budget Fields
    readyToAssign: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Số tiền thu nhập chưa được phân bổ vào budget/savings (Ready to Assign)",
    },
    totalAssigned: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Tổng số tiền đã phân bổ vào budgets",
    },
    totalSaved: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Tổng số tiền đã gửi vào savings goals",
    },
    lastAssignmentDate: {
      type: Date,
      description: "Lần cuối cùng user phân bổ thu nhập",
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);
// Main User Schema
const UserSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: [true, "Email là bắt buộc"],
      unique: true,
      lowercase: true,
      validate: [validator.isEmail, "Email không hợp lệ"],
      index: true,
    },
    passwordHash: {
      type: String,
      required: function () {
        return this.authProvider === "local";
      },
      minlength: [8, "Mật khẩu phải có ít nhất 8 ký tự"],
      select: false,
    },
    // Profile Information
    profile: {
      type: ProfileSchema,
      required: true,
      default: () => ({}),
    },
    // App Settings
    settings: {
      type: SettingsSchema,
      default: () => ({}),
    },
    // Gamification Stats
    stats: {
      type: StatsSchema,
      default: () => ({}),
    },
    // Financial Summary
    financialSummary: {
      type: FinancialSummarySchema,
      default: () => ({}),
    },
    // Auth & Security
    emailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationToken: {
      type: String,
      select: false,
    },
    emailVerificationOTP: {
      type: String,
      select: false,
    },
    emailVerificationExpires: {
      type: Date,
      select: false,
    },
    passwordResetToken: {
      type: String,
      select: false,
    },
    passwordResetOTP: {
      type: String,
      select: false,
    },
    passwordResetExpires: {
      type: Date,
      select: false,
    },
    lastLogin: {
      type: Date,
      default: Date.now,
    },
    // Google OAuth fields
    googleId: {
      type: String,
      sparse: true, // Allows multiple null values
    },
    authProvider: {
      type: String,
      enum: ["local", "google"],
      default: "local",
    },
    deviceTokens: [
      {
        type: String,
        validate: {
          validator: function (v) {
            return v.length > 0;
          },
          message: "Device token không được rỗng",
        },
      },
    ],
    // Audit fields
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    version: {
      type: Number,
      default: 1,
    },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      transform: function (doc, ret) {
        // Convert Decimal128 to number for JSON
        if (ret.stats && ret.stats.totalSaved) {
          ret.stats.totalSaved = parseFloat(ret.stats.totalSaved.toString());
        }
        return ret;
      },
    },
  }
);
// Indexes
UserSchema.index({ "profile.phone": 1 }, { sparse: true });
UserSchema.index({ "stats.points": -1 }); // Leaderboards
UserSchema.index({ isActive: 1, createdAt: -1 });
// Instance methods
UserSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.passwordHash);
};
UserSchema.methods.addPoints = function (points) {
  this.stats.points += points;
  // Update level based on points
  const newLevel = Math.floor(this.stats.points / 1000) + 1;
  if (newLevel > this.stats.level) {
    this.stats.level = newLevel;
    // Update rank based on level
    if (newLevel >= 50) this.stats.rank = "Platinum";
    else if (newLevel >= 25) this.stats.rank = "Gold";
    else if (newLevel >= 10) this.stats.rank = "Silver";
    else this.stats.rank = "Bronze";
  }
};
UserSchema.methods.updateStreak = function (increment = true) {
  if (increment) {
    this.stats.currentStreak += 1;
    if (this.stats.currentStreak > this.stats.longestStreak) {
      this.stats.longestStreak = this.stats.currentStreak;
    }
  } else {
    this.stats.currentStreak = 0;
  }
};
UserSchema.methods.addSavings = function (amount) {
  const currentSaved = parseFloat(this.stats.totalSaved.toString()) || 0;
  this.stats.totalSaved = mongoose.Types.Decimal128.fromString(
    (currentSaved + amount).toFixed(2)
  );
};
// Pre-save middleware
UserSchema.pre("save", async function (next) {
  // Only hash password if it's modified
  if (!this.isModified("passwordHash")) return next();
  // Check if password is already hashed (bcrypt hashes start with $2a$, $2b$, etc.)
  if (this.passwordHash && this.passwordHash.startsWith("$2")) {
    return next();
  }
  // Hash password only if it's plain text
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});
UserSchema.pre("save", function (next) {
  // Update version on save
  this.version += 1;
  next();
});
// Static methods
UserSchema.statics.findByEmail = function (email) {
  return this.findOne({ email: email.toLowerCase(), isActive: true });
};
UserSchema.statics.findActiveUsers = function (limit = 10) {
  return this.find({ isActive: true })
    .sort({ "stats.points": -1 })
    .limit(limit);
};
UserSchema.statics.getLeaderboard = function (limit = 100) {
  return this.find({ isActive: true })
    .select("profile.name profile.avatar stats")
    .sort({ "stats.points": -1, "stats.level": -1 })
    .limit(limit);
};
const User = mongoose.model("User", UserSchema);
export default User;