import mongoose from "mongoose";

// Contribution tracking sub-schema
const ContributionSchema = new mongoose.Schema(
  {
    amount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền đóng góp là bắt buộc"],
      validate: {
        validator: function (v) {
          const num = parseFloat(v.toString());
          return num > 0;
        },
        message: "Số tiền đóng góp phải lớn hơn 0",
      },
    },
    source: {
      type: String,
      enum: ["income_allocation", "manual", "transfer"],
      default: "manual",
      description: "Nguồn đóng góp",
    },
    incomeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Income",
      description: "ID của khoản thu nhập (nếu source = income_allocation)",
    },
    note: {
      type: String,
      maxlength: [200, "Ghi chú không được vượt quá 200 ký tự"],
    },
    date: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: true }
);

// Withdrawal tracking sub-schema
const WithdrawalSchema = new mongoose.Schema(
  {
    amount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền rút là bắt buộc"],
      validate: {
        validator: function (v) {
          const num = parseFloat(v.toString());
          return num > 0;
        },
        message: "Số tiền rút phải lớn hơn 0",
      },
    },
    reason: {
      type: String,
      maxlength: [200, "Lý do rút không được vượt quá 200 ký tự"],
    },
    date: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: true }
);

// Main SavingsGoal Schema
const SavingsGoalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },

    // Core Goal Information
    name: {
      type: String,
      required: [true, "Tên mục tiêu tiết kiệm là bắt buộc"],
      trim: true,
      maxlength: [200, "Tên mục tiêu không được vượt quá 200 ký tự"],
    },
    description: {
      type: String,
      maxlength: [1000, "Mô tả không được vượt quá 1000 ký tự"],
    },

    // Financial Information
    targetAmount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền mục tiêu là bắt buộc"],
      validate: {
        validator: function (v) {
          const num = parseFloat(v.toString());
          return num > 0;
        },
        message: "Số tiền mục tiêu phải lớn hơn 0",
      },
    },
    currentAmount: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Số tiền hiện tại đã tiết kiệm",
    },
    currency: {
      type: String,
      enum: ["VND", "USD", "EUR"],
      default: "VND",
    },

    // Timeline
    startDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    targetDate: {
      type: Date,
      required: [true, "Ngày mục tiêu là bắt buộc"],
      validate: {
        validator: function (v) {
          return v > this.startDate;
        },
        message: "Ngày mục tiêu phải sau ngày bắt đầu",
      },
      index: true,
    },

    // Category & Priority
    category: {
      type: String,
      enum: [
        "emergency_fund",
        "vacation",
        "house",
        "car",
        "education",
        "wedding",
        "retirement",
        "gadget",
        "investment",
        "other",
      ],
      required: [true, "Danh mục mục tiêu là bắt buộc"],
      index: true,
    },
    priority: {
      type: String,
      enum: ["low", "medium", "high", "critical"],
      default: "medium",
    },

    // Progress Tracking
    contributions: {
      type: [ContributionSchema],
      default: [],
      description: "Lịch sử đóng góp",
    },
    withdrawals: {
      type: [WithdrawalSchema],
      default: [],
      description: "Lịch sử rút tiền",
    },

    // Status
    status: {
      type: String,
      enum: ["active", "paused", "completed", "cancelled"],
      default: "active",
      index: true,
    },
    completedDate: {
      type: Date,
      description: "Ngày hoàn thành mục tiêu",
    },

    // Auto-save Settings
    autoSave: {
      enabled: {
        type: Boolean,
        default: false,
      },
      amount: {
        type: mongoose.Schema.Types.Decimal128,
        description: "Số tiền tự động tiết kiệm",
      },
      frequency: {
        type: String,
        enum: ["daily", "weekly", "monthly"],
        description: "Tần suất tự động tiết kiệm",
      },
      nextAutoSaveDate: {
        type: Date,
        description: "Ngày tự động tiết kiệm tiếp theo",
      },
    },

    // Visualization
    icon: {
      type: String,
      default: "piggy_bank",
      description: "Icon cho mục tiêu",
    },
    color: {
      type: String,
      default: "#4CAF50",
      description: "Màu sắc cho mục tiêu",
    },

    // Metadata
    tags: [
      {
        type: String,
        maxlength: [30, "Tag không được vượt quá 30 ký tự"],
      },
    ],
    notes: {
      type: String,
      maxlength: [500, "Ghi chú không được vượt quá 500 ký tự"],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
SavingsGoalSchema.index({ userId: 1, status: 1 });
SavingsGoalSchema.index({ userId: 1, targetDate: 1 });
SavingsGoalSchema.index({ userId: 1, category: 1 });

// Virtual for progress percentage
SavingsGoalSchema.virtual("progressPercentage").get(function () {
  const current = parseFloat(this.currentAmount.toString());
  const target = parseFloat(this.targetAmount.toString());
  return target > 0 ? Math.min((current / target) * 100, 100) : 0;
});

// Virtual for remaining amount
SavingsGoalSchema.virtual("remainingAmount").get(function () {
  const current = parseFloat(this.currentAmount.toString());
  const target = parseFloat(this.targetAmount.toString());
  return Math.max(target - current, 0);
});

// Virtual for days remaining
SavingsGoalSchema.virtual("daysRemaining").get(function () {
  if (this.status === "completed") return 0;
  const now = new Date();
  const target = new Date(this.targetDate);
  const diffTime = target - now;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.max(diffDays, 0);
});

// Virtual for suggested monthly contribution
SavingsGoalSchema.virtual("suggestedMonthlyContribution").get(function () {
  if (this.status === "completed") return 0;
  const remaining = this.remainingAmount;
  const daysRemaining = this.daysRemaining;
  if (daysRemaining <= 0) return remaining;
  const monthsRemaining = Math.max(daysRemaining / 30, 1);
  return remaining / monthsRemaining;
});

// Static methods
SavingsGoalSchema.statics = {
  // Get all active savings goals for user
  async getActiveBUser(userId) {
    return await this.find({
      userId: new mongoose.Types.ObjectId(userId),
      status: "active",
    }).sort({ priority: -1, targetDate: 1 });
  },

  // Get savings goals by category
  async getByCategory(userId, category) {
    return await this.find({
      userId: new mongoose.Types.ObjectId(userId),
      category,
      status: "active",
    }).sort({ targetDate: 1 });
  },

  // Get total saved amount for user
  async getTotalSaved(userId) {
    const result = await this.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(userId),
          status: { $in: ["active", "completed"] },
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: { $toDouble: "$currentAmount" } },
          count: { $sum: 1 },
        },
      },
    ]);

    return result.length > 0
      ? { total: result[0].total, count: result[0].count }
      : { total: 0, count: 0 };
  },

  // Get savings statistics
  async getStats(userId) {
    const goals = await this.find({
      userId: new mongoose.Types.ObjectId(userId),
    });

    const stats = {
      total: goals.length,
      active: goals.filter((g) => g.status === "active").length,
      completed: goals.filter((g) => g.status === "completed").length,
      paused: goals.filter((g) => g.status === "paused").length,
      totalSaved: goals.reduce(
        (sum, g) => sum + parseFloat(g.currentAmount.toString()),
        0
      ),
      totalTarget: goals
        .filter((g) => g.status === "active")
        .reduce((sum, g) => sum + parseFloat(g.targetAmount.toString()), 0),
    };

    stats.overallProgress =
      stats.totalTarget > 0
        ? (stats.totalSaved / stats.totalTarget) * 100
        : 100;

    return stats;
  },
};

// Instance methods
SavingsGoalSchema.methods = {
  // Add contribution to savings goal
  addContribution(amount, source = "manual", incomeId = null, note = null) {
    const contribution = {
      amount: mongoose.Types.Decimal128.fromString(amount.toFixed(2)),
      source,
      incomeId,
      note,
      date: new Date(),
    };

    this.contributions.push(contribution);

    // Update current amount
    const current = parseFloat(this.currentAmount.toString());
    const newAmount = current + amount;
    this.currentAmount = mongoose.Types.Decimal128.fromString(
      newAmount.toFixed(2)
    );

    // Check if goal is completed
    const target = parseFloat(this.targetAmount.toString());
    if (newAmount >= target && this.status === "active") {
      this.status = "completed";
      this.completedDate = new Date();
    }

    return contribution;
  },

  // Withdraw from savings goal
  withdraw(amount, reason = null) {
    const current = parseFloat(this.currentAmount.toString());

    if (amount > current) {
      throw new Error(
        `Số tiền rút (${amount}) vượt quá số dư hiện tại (${current})`
      );
    }

    const withdrawal = {
      amount: mongoose.Types.Decimal128.fromString(amount.toFixed(2)),
      reason,
      date: new Date(),
    };

    this.withdrawals.push(withdrawal);

    // Update current amount
    const newAmount = current - amount;
    this.currentAmount = mongoose.Types.Decimal128.fromString(
      newAmount.toFixed(2)
    );

    // Update status if was completed
    if (this.status === "completed") {
      this.status = "active";
      this.completedDate = null;
    }

    return withdrawal;
  },

  // Calculate next auto-save date
  calculateNextAutoSaveDate() {
    if (!this.autoSave.enabled || !this.autoSave.frequency) return null;

    const current =
      this.autoSave.nextAutoSaveDate || this.startDate || new Date();
    const next = new Date(current);

    switch (this.autoSave.frequency) {
      case "daily":
        next.setDate(next.getDate() + 1);
        break;
      case "weekly":
        next.setDate(next.getDate() + 7);
        break;
      case "monthly":
        next.setMonth(next.getMonth() + 1);
        break;
    }

    return next;
  },

  // Update auto-save next date
  async updateNextAutoSaveDate() {
    if (!this.autoSave.enabled) return;

    const next = this.calculateNextAutoSaveDate();
    if (next) {
      this.autoSave.nextAutoSaveDate = next;
      await this.save();
    }
  },
};

// Middleware
SavingsGoalSchema.pre("save", function (next) {
  // Set next auto-save date if enabled
  if (
    this.autoSave.enabled &&
    this.autoSave.frequency &&
    !this.autoSave.nextAutoSaveDate
  ) {
    this.autoSave.nextAutoSaveDate = this.calculateNextAutoSaveDate();
  }

  next();
});

const SavingsGoal = mongoose.model("SavingsGoal", SavingsGoalSchema);

export default SavingsGoal;
