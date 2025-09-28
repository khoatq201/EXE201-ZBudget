import mongoose from "mongoose";

// Sub-schemas
const PeriodSchema = new mongoose.Schema(
  {
    startDate: {
      type: Date,
      required: [true, "Ngày bắt đầu là bắt buộc"],
    },
    endDate: {
      type: Date,
      required: [true, "Ngày kết thúc là bắt buộc"],
      validate: {
        validator: function (v) {
          return v > this.startDate;
        },
        message: "Ngày kết thúc phải sau ngày bắt đầu",
      },
    },
    type: {
      type: String,
      enum: ["daily", "weekly", "monthly", "yearly", "custom"],
      required: [true, "Loại kỳ hạn là bắt buộc"],
    },
  },
  { _id: false }
);

const CategoryAllocationSchema = new mongoose.Schema(
  {
    category: {
      type: String,
      enum: [
        "food",
        "transport",
        "shopping",
        "entertainment",
        "healthcare",
        "education",
        "utilities",
        "other",
      ],
      required: [true, "Danh mục là bắt buộc"],
    },
    allocated: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền phân bổ là bắt buộc"],
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) >= 0;
        },
        message: "Số tiền phân bổ phải >= 0",
      },
    },
    spent: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) >= 0;
        },
        message: "Số tiền đã chi phải >= 0",
      },
    },
    remaining: {
      type: mongoose.Schema.Types.Decimal128,
      default: function () {
        return this.allocated;
      },
    },
    percentage: {
      type: Number,
      min: [0, "Phần trăm phải >= 0"],
      max: [100, "Phần trăm phải <= 100"],
      required: [true, "Phần trăm phân bổ là bắt buộc"],
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const StatusSchema = new mongoose.Schema(
  {
    totalSpent: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    totalRemaining: {
      type: mongoose.Schema.Types.Decimal128,
      default: function () {
        return this.parent().totalAmount;
      },
    },
    spentPercentage: {
      type: Number,
      min: 0,
      max: 200, // Allow over-budget
      default: 0,
    },
    isOverBudget: {
      type: Boolean,
      default: false,
    },
    daysRemaining: {
      type: Number,
      default: 0,
    },
    dailyAverageSpent: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    projectedTotal: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
  },
  { _id: false }
);

const AlertsSchema = new mongoose.Schema(
  {
    enabled: {
      type: Boolean,
      default: true,
    },
    thresholds: [
      {
        type: Number,
        min: 0,
        max: 200,
        default: [50, 75, 90, 100],
      },
    ],
    lastAlertSent: {
      type: Date,
    },
    alertsSent: [
      {
        type: String,
        validate: {
          validator: function (v) {
            return /^\d+%$/.test(v);
          },
          message: "Alert format phải là số%",
        },
      },
    ],
  },
  { _id: false }
);

const CategoryTargetSchema = new mongoose.Schema(
  {
    category: {
      type: String,
      enum: [
        "food",
        "transport",
        "shopping",
        "entertainment",
        "healthcare",
        "education",
        "utilities",
        "other",
      ],
      required: true,
    },
    targetReduction: {
      type: Number,
      min: 0,
      max: 100,
      required: [true, "Mục tiêu giảm chi tiêu là bắt buộc"],
    },
  },
  { _id: false }
);

const GoalsSchema = new mongoose.Schema(
  {
    savingsTarget: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) >= 0;
        },
        message: "Mục tiêu tiết kiệm phải >= 0",
      },
    },
    reductionTarget: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    categoryTargets: [CategoryTargetSchema],
  },
  { _id: false }
);

// Main Budget Schema
const BudgetSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },

    // Basic Budget Info
    name: {
      type: String,
      required: [true, "Tên ngân sách là bắt buộc"],
      trim: true,
      maxlength: [200, "Tên ngân sách không được vượt quá 200 ký tự"],
    },
    category: {
      type: String,
      enum: ["monthly", "weekly", "yearly", "custom", "challenge-based"],
      default: "monthly",
    },

    // Amount & Currency
    totalAmount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Tổng số tiền là bắt buộc"],
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) > 0;
        },
        message: "Tổng số tiền phải > 0",
      },
    },
    currency: {
      type: String,
      enum: ["VND", "USD", "EUR"],
      default: "VND",
    },

    // Period
    period: {
      type: PeriodSchema,
      required: [true, "Kỳ hạn là bắt buộc"],
    },

    // Category Allocations
    categoryAllocations: {
      type: [CategoryAllocationSchema],
      validate: {
        validator: function (v) {
          const totalPercentage = v.reduce(
            (sum, cat) => sum + cat.percentage,
            0
          );
          return totalPercentage <= 100;
        },
        message: "Tổng phần trăm phân bổ không được vượt quá 100%",
      },
    },

    // Current Status
    status: {
      type: StatusSchema,
      default: () => ({}),
    },

    // Alerts & Notifications
    alerts: {
      type: AlertsSchema,
      default: () => ({}),
    },

    // Goals & Targets
    goals: {
      type: GoalsSchema,
      default: () => ({}),
    },

    // Status
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
        if (ret.totalAmount)
          ret.totalAmount = parseFloat(ret.totalAmount.toString());

        if (ret.categoryAllocations) {
          ret.categoryAllocations.forEach((cat) => {
            if (cat.allocated)
              cat.allocated = parseFloat(cat.allocated.toString());
            if (cat.spent) cat.spent = parseFloat(cat.spent.toString());
            if (cat.remaining)
              cat.remaining = parseFloat(cat.remaining.toString());
          });
        }

        if (ret.status) {
          if (ret.status.totalSpent)
            ret.status.totalSpent = parseFloat(
              ret.status.totalSpent.toString()
            );
          if (ret.status.totalRemaining)
            ret.status.totalRemaining = parseFloat(
              ret.status.totalRemaining.toString()
            );
          if (ret.status.dailyAverageSpent)
            ret.status.dailyAverageSpent = parseFloat(
              ret.status.dailyAverageSpent.toString()
            );
          if (ret.status.projectedTotal)
            ret.status.projectedTotal = parseFloat(
              ret.status.projectedTotal.toString()
            );
        }

        if (ret.goals && ret.goals.savingsTarget) {
          ret.goals.savingsTarget = parseFloat(
            ret.goals.savingsTarget.toString()
          );
        }

        return ret;
      },
    },
  }
);

// Indexes
BudgetSchema.index({ userId: 1, isActive: 1 });
BudgetSchema.index({ userId: 1, "period.startDate": 1, "period.endDate": 1 });
BudgetSchema.index({ "period.endDate": 1 }); // For cleanup tasks

// Instance Methods
BudgetSchema.methods.addExpense = function (amount, category) {
  // Find category allocation
  const categoryAllocation = this.categoryAllocations.find(
    (cat) => cat.category === category
  );

  if (!categoryAllocation) {
    throw new Error(`Không tìm thấy phân bổ cho danh mục: ${category}`);
  }

  // Update category allocation
  const amountDecimal = mongoose.Types.Decimal128.fromString(amount.toFixed(2));
  categoryAllocation.spent = mongoose.Types.Decimal128.fromString(
    (parseFloat(categoryAllocation.spent.toString()) + amount).toFixed(2)
  );
  categoryAllocation.remaining = mongoose.Types.Decimal128.fromString(
    (
      parseFloat(categoryAllocation.allocated.toString()) -
      parseFloat(categoryAllocation.spent.toString())
    ).toFixed(2)
  );
  categoryAllocation.lastUpdated = new Date();

  // Update overall status
  this.updateStatus();

  return categoryAllocation;
};

BudgetSchema.methods.updateStatus = function () {
  // Calculate total spent
  const totalSpent = this.categoryAllocations.reduce(
    (sum, cat) => sum + parseFloat(cat.spent.toString()),
    0
  );

  // Calculate remaining
  const totalBudget = parseFloat(this.totalAmount.toString());
  const totalRemaining = totalBudget - totalSpent;

  // Calculate spent percentage
  const spentPercentage = (totalSpent / totalBudget) * 100;

  // Calculate days remaining
  const now = new Date();
  const endDate = new Date(this.period.endDate);
  const daysRemaining = Math.max(
    0,
    Math.ceil((endDate - now) / (1000 * 60 * 60 * 24))
  );

  // Calculate daily average spent
  const startDate = new Date(this.period.startDate);
  const daysPassed = Math.max(
    1,
    Math.ceil((now - startDate) / (1000 * 60 * 60 * 24))
  );
  const dailyAverageSpent = totalSpent / daysPassed;

  // Calculate projected total
  const totalDays = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
  const projectedTotal = dailyAverageSpent * totalDays;

  // Update status
  this.status = {
    totalSpent: mongoose.Types.Decimal128.fromString(totalSpent.toFixed(2)),
    totalRemaining: mongoose.Types.Decimal128.fromString(
      totalRemaining.toFixed(2)
    ),
    spentPercentage: Math.round(spentPercentage * 100) / 100,
    isOverBudget: spentPercentage > 100,
    daysRemaining,
    dailyAverageSpent: mongoose.Types.Decimal128.fromString(
      dailyAverageSpent.toFixed(2)
    ),
    projectedTotal: mongoose.Types.Decimal128.fromString(
      projectedTotal.toFixed(2)
    ),
  };
};

BudgetSchema.methods.checkAlertThresholds = function () {
  const spentPercentage = this.status.spentPercentage;
  const alertsToSend = [];

  for (const threshold of this.alerts.thresholds) {
    const alertKey = `${threshold}%`;

    if (
      spentPercentage >= threshold &&
      !this.alerts.alertsSent.includes(alertKey)
    ) {
      alertsToSend.push({
        threshold,
        message: `Bạn đã chi ${spentPercentage.toFixed(0)}% ngân sách`,
      });
      this.alerts.alertsSent.push(alertKey);
    }
  }

  if (alertsToSend.length > 0) {
    this.alerts.lastAlertSent = new Date();
  }

  return alertsToSend;
};

BudgetSchema.methods.getCategoryStatus = function (category) {
  const allocation = this.categoryAllocations.find(
    (cat) => cat.category === category
  );
  if (!allocation) return null;

  const spent = parseFloat(allocation.spent.toString());
  const allocated = parseFloat(allocation.allocated.toString());
  const percentage = (spent / allocated) * 100;

  return {
    category,
    allocated,
    spent,
    remaining: parseFloat(allocation.remaining.toString()),
    percentage: Math.round(percentage * 100) / 100,
    isOverBudget: percentage > 100,
    lastUpdated: allocation.lastUpdated,
  };
};

// Pre-save middleware
BudgetSchema.pre("save", function (next) {
  // Update status before saving
  if (this.isModified("categoryAllocations")) {
    this.updateStatus();
  }

  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }

  next();
});

// Static Methods
BudgetSchema.statics.findActiveBudgets = function (userId) {
  return this.find({ userId, isActive: true }).sort({ createdAt: -1 });
};

BudgetSchema.statics.findCurrentBudget = function (userId) {
  const now = new Date();
  return this.findOne({
    userId,
    isActive: true,
    "period.startDate": { $lte: now },
    "period.endDate": { $gte: now },
  });
};

BudgetSchema.statics.findExpiredBudgets = function () {
  const now = new Date();
  return this.find({
    isActive: true,
    "period.endDate": { $lt: now },
  });
};

BudgetSchema.statics.getBudgetSummary = function (userId, year, month = null) {
  const matchConditions = { userId: new mongoose.Types.ObjectId(userId) };

  if (month) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);
    matchConditions["period.startDate"] = { $gte: startDate };
    matchConditions["period.endDate"] = { $lte: endDate };
  } else {
    matchConditions["period.startDate"] = {
      $gte: new Date(year, 0, 1),
      $lt: new Date(year + 1, 0, 1),
    };
  }

  return this.aggregate([
    { $match: matchConditions },
    {
      $group: {
        _id: null,
        totalBudget: { $sum: { $toDouble: "$totalAmount" } },
        totalSpent: { $sum: { $toDouble: "$status.totalSpent" } },
        budgetCount: { $sum: 1 },
        overBudgetCount: {
          $sum: { $cond: ["$status.isOverBudget", 1, 0] },
        },
      },
    },
  ]);
};

const Budget = mongoose.model("Budget", BudgetSchema);

export default Budget;
