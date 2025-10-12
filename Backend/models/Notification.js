import mongoose from "mongoose";
// Sub-schemas
const NotificationDataSchema = new mongoose.Schema(
  {
    // Challenge related data
    challengeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Challenge",
    },
    challengeName: String,
    milestoneDay: Number,
    pointsEarned: Number,
    // Budget related data
    budgetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Budget",
    },
    budgetName: String,
    category: String,
    spentPercentage: Number,
    remainingAmount: mongoose.Schema.Types.Decimal128,
    // Expense related data
    expenseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Expense",
    },
    expenseAmount: mongoose.Schema.Types.Decimal128,
    // Group related data
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Group",
    },
    groupName: String,
    memberName: String,
    // Social related data
    fromUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    fromUserName: String,
    // Generic data for custom notifications
    customData: {
      type: mongoose.Schema.Types.Mixed,
    },
  },
  { _id: false }
);
const ActionButtonSchema = new mongoose.Schema(
  {
    text: {
      type: String,
      required: true,
      maxlength: [30, "Text button không được vượt quá 30 ký tự"],
    },
    action: {
      type: String,
      enum: [
        "view_challenge",
        "view_budget",
        "view_expense",
        "view_group",
        "accept_invite",
        "reject_invite",
        "mark_read",
        "dismiss",
      ],
      required: true,
    },
    actionData: {
      type: mongoose.Schema.Types.Mixed,
    },
  },
  { _id: false }
);
// Main Notification Schema
const NotificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },
    // Notification Type & Category
    type: {
      type: String,
      enum: [
        // Challenge notifications
        "challenge_started",
        "challenge_completed",
        "challenge_failed",
        "milestone_achieved",
        "challenge_reminder",
        "challenge_invitation",
        // Budget notifications
        "budget_alert",
        "budget_exceeded",
        "budget_low_funds",
        "budget_category_exceeded",
        "monthly_budget_summary",
        // Expense notifications
        "expense_added",
        "expense_approved",
        "expense_rejected",
        "receipt_processed",
        "large_expense_alert",
        // Group notifications
        "group_invitation",
        "group_expense_added",
        "member_joined",
        "member_left",
        "group_challenge_started",
        // Social notifications
        "encouragement_received",
        "achievement_shared",
        "friend_request",
        "leaderboard_position",
        "streak_milestone",
        // System notifications
        "app_update",
        "maintenance_notice",
        "security_alert",
        "backup_completed",
        "sync_failed",
      ],
      required: [true, "Loại thông báo là bắt buộc"],
      index: true,
    },
    category: {
      type: String,
      enum: ["challenge", "budget", "expense", "group", "social", "system"],
      required: [true, "Danh mục thông báo là bắt buộc"],
      index: true,
    },
    // Content
    title: {
      type: String,
      required: [true, "Tiêu đề thông báo là bắt buộc"],
      trim: true,
      maxlength: [200, "Tiêu đề không được vượt quá 200 ký tự"],
    },
    message: {
      type: String,
      required: [true, "Nội dung thông báo là bắt buộc"],
      trim: true,
      maxlength: [1000, "Nội dung không được vượt quá 1000 ký tự"],
    },
    // Visual Elements
    icon: {
      type: String,
      maxlength: [10, "Icon không được vượt quá 10 ký tự"],
    },
    color: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^#[0-9A-F]{6}$/i.test(v);
        },
        message: "Màu sắc phải là hex color hợp lệ",
      },
    },
    imageUrl: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^https?:\/\/.+/.test(v);
        },
        message: "Image URL phải là URL hợp lệ",
      },
    },
    // Priority & Behavior
    priority: {
      type: String,
      enum: ["low", "normal", "high", "urgent"],
      default: "normal",
      index: true,
    },
    requiresAction: {
      type: Boolean,
      default: false,
    },
    actionButtons: [ActionButtonSchema],
    // Data & Context
    data: {
      type: NotificationDataSchema,
      default: () => ({}),
    },
    // Delivery & Status
    deliveryMethod: {
      type: String,
      enum: ["in_app", "push", "email", "sms"],
      default: "in_app",
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
    },
    isArchived: {
      type: Boolean,
      default: false,
      index: true,
    },
    archivedAt: {
      type: Date,
    },
    // Scheduling
    scheduledFor: {
      type: Date,
      index: true,
    },
    sentAt: {
      type: Date,
    },
    // Expiry
    expiresAt: {
      type: Date,
      // index: true, // Removed - using compound index below
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
        if (ret.data) {
          if (ret.data.remainingAmount)
            ret.data.remainingAmount = parseFloat(
              ret.data.remainingAmount.toString()
            );
          if (ret.data.expenseAmount)
            ret.data.expenseAmount = parseFloat(
              ret.data.expenseAmount.toString()
            );
        }
        return ret;
      },
    },
  }
);
// Compound Indexes
NotificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, category: 1, createdAt: -1 });
NotificationSchema.index({ userId: 1, priority: 1, isRead: 1 });
NotificationSchema.index({ scheduledFor: 1, sentAt: 1 }); // For scheduled notifications
NotificationSchema.index({ expiresAt: 1 }); // For cleanup
// Instance Methods
NotificationSchema.methods.markAsRead = function () {
  if (!this.isRead) {
    this.isRead = true;
    this.readAt = new Date();
  }
  return this;
};
NotificationSchema.methods.markAsUnread = function () {
  this.isRead = false;
  this.readAt = null;
  return this;
};
NotificationSchema.methods.archive = function () {
  this.isArchived = true;
  this.archivedAt = new Date();
  return this;
};
NotificationSchema.methods.unarchive = function () {
  this.isArchived = false;
  this.archivedAt = null;
  return this;
};
NotificationSchema.methods.isExpired = function () {
  return this.expiresAt && new Date() > this.expiresAt;
};
NotificationSchema.methods.canBeDelivered = function () {
  const now = new Date();
  // Check if expired
  if (this.isExpired()) return false;
  // Check if already sent
  if (this.sentAt) return false;
  // Check if scheduled for future
  if (this.scheduledFor && now < this.scheduledFor) return false;
  return true;
};
NotificationSchema.methods.markAsSent = function () {
  this.sentAt = new Date();
  return this;
};
NotificationSchema.methods.addActionButton = function (
  text,
  action,
  actionData = null
) {
  if (this.actionButtons.length >= 3) {
    throw new Error("Không được có quá 3 action buttons");
  }
  this.actionButtons.push({
    text,
    action,
    actionData,
  });
  if (!this.requiresAction) {
    this.requiresAction = true;
  }
  return this;
};
// Pre-save middleware
NotificationSchema.pre("save", function (next) {
  // Set default icon and color based on category
  if (!this.icon || !this.color) {
    const defaults = this.getCategoryDefaults();
    if (!this.icon) this.icon = defaults.icon;
    if (!this.color) this.color = defaults.color;
  }
  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  next();
});
NotificationSchema.methods.getCategoryDefaults = function () {
  const categoryDefaults = {
    challenge: { icon: "🏆", color: "#FFD700" },
    budget: { icon: "💰", color: "#32CD32" },
    expense: { icon: "💳", color: "#FF6347" },
    group: { icon: "👥", color: "#1E90FF" },
    social: { icon: "❤️", color: "#FF69B4" },
    system: { icon: "⚙️", color: "#708090" },
  };
  return categoryDefaults[this.category] || categoryDefaults.system;
};
// Static Methods
NotificationSchema.statics.findUnreadForUser = function (userId, limit = 50) {
  return this.find({
    userId,
    isRead: false,
    isArchived: false,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } },
    ],
  })
    .sort({ priority: -1, createdAt: -1 })
    .limit(limit);
};
NotificationSchema.statics.findByCategory = function (
  userId,
  category,
  limit = 20
) {
  return this.find({
    userId,
    category,
    isArchived: false,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } },
    ],
  })
    .sort({ createdAt: -1 })
    .limit(limit);
};
NotificationSchema.statics.markAllAsReadForUser = function (
  userId,
  category = null
) {
  const query = {
    userId,
    isRead: false,
    isArchived: false,
  };
  if (category) {
    query.category = category;
  }
  return this.updateMany(query, {
    $set: {
      isRead: true,
      readAt: new Date(),
    },
  });
};
NotificationSchema.statics.getUnreadCount = function (userId) {
  return this.countDocuments({
    userId,
    isRead: false,
    isArchived: false,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } },
    ],
  });
};
NotificationSchema.statics.getUnreadCountByCategory = function (userId) {
  return this.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(userId),
        isRead: false,
        isArchived: false,
        $or: [
          { expiresAt: { $exists: false } },
          { expiresAt: { $gt: new Date() } },
        ],
      },
    },
    {
      $group: {
        _id: "$category",
        count: { $sum: 1 },
      },
    },
  ]);
};
NotificationSchema.statics.findScheduledNotifications = function () {
  const now = new Date();
  return this.find({
    scheduledFor: { $lte: now },
    sentAt: { $exists: false },
    $or: [{ expiresAt: { $exists: false } }, { expiresAt: { $gt: now } }],
  });
};
NotificationSchema.statics.cleanupExpiredNotifications = function () {
  const now = new Date();
  return this.deleteMany({
    expiresAt: { $lt: now },
  });
};
NotificationSchema.statics.createChallengeNotification = function (
  userId,
  type,
  challengeData
) {
  const notificationMap = {
    challenge_started: {
      title: "🎯 Thách thức mới bắt đầu!",
      message: `Bạn đã bắt đầu thách thức "${challengeData.challengeName}". Chúc bạn may mắn!`,
      category: "challenge",
    },
    challenge_completed: {
      title: "🏆 Hoàn thành thách thức!",
      message: `Chúc mừng! Bạn đã hoàn thành thách thức "${challengeData.challengeName}" và kiếm được ${challengeData.pointsEarned} điểm!`,
      category: "challenge",
      priority: "high",
    },
    milestone_achieved: {
      title: "⭐ Đạt mốc quan trọng!",
      message: `Bạn đã đạt mốc ngày ${challengeData.milestoneDay} trong thách thức "${challengeData.challengeName}"!`,
      category: "challenge",
      priority: "high",
    },
  };
  const template = notificationMap[type];
  if (!template) {
    throw new Error(`Không tìm thấy template cho loại thông báo: ${type}`);
  }
  return new this({
    userId,
    type,
    category: template.category,
    title: template.title,
    message: template.message,
    priority: template.priority || "normal",
    data: challengeData,
  });
};
NotificationSchema.statics.createBudgetAlert = function (userId, budgetData) {
  return new this({
    userId,
    type: "budget_alert",
    category: "budget",
    title: "⚠️ Cảnh báo ngân sách",
    message: `Bạn đã chi ${budgetData.spentPercentage}% ngân sách ${budgetData.category} trong "${budgetData.budgetName}"`,
    priority: budgetData.spentPercentage >= 90 ? "high" : "normal",
    data: budgetData,
  });
};
const Notification = mongoose.model("Notification", NotificationSchema);
export default Notification;