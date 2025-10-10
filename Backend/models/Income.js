import mongoose from "mongoose";
import validator from "validator";

// Sub-schemas
const RecurringDetailsSchema = new mongoose.Schema(
  {
    frequency: {
      type: String,
      enum: ["daily", "weekly", "biweekly", "monthly", "quarterly", "yearly"],
      required: function () {
        return this.parent().isRecurring;
      },
    },
    nextOccurrence: {
      type: Date,
      required: function () {
        return this.parent().isRecurring;
      },
    },
    endDate: {
      type: Date,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const SourceDetailsSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      maxlength: [200, "Tên nguồn thu không được vượt quá 200 ký tự"],
    },
    contactInfo: {
      type: String,
      maxlength: [200, "Thông tin liên hệ không được vượt quá 200 ký tự"],
    },
    taxId: {
      type: String,
      maxlength: [50, "Mã số thuế không được vượt quá 50 ký tự"],
    },
  },
  { _id: false }
);

const TaxInfoSchema = new mongoose.Schema(
  {
    isTaxable: {
      type: Boolean,
      default: false,
    },
    taxAmount: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    taxRate: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    grossAmount: {
      type: mongoose.Schema.Types.Decimal128,
      // Amount before tax
    },
  },
  { _id: false }
);

// YNAB-style Income Allocation Schema
const AllocationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ["budget", "savings", "unassigned"],
      required: [true, "Loại phân bổ là bắt buộc"],
    },
    targetId: {
      type: mongoose.Schema.Types.ObjectId,
      refPath: "allocations.targetModel",
    },
    targetModel: {
      type: String,
      enum: ["Budget", "SavingsGoal"],
    },
    amount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền phân bổ là bắt buộc"],
      validate: {
        validator: function (v) {
          const num = parseFloat(v.toString());
          return num > 0;
        },
        message: "Số tiền phân bổ phải lớn hơn 0",
      },
    },
    categoryAllocationId: {
      type: String,
      description: "Category ID trong budget (nếu type = 'budget')",
    },
    note: {
      type: String,
      maxlength: [200, "Ghi chú phân bổ không được vượt quá 200 ký tự"],
    },
    allocatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: true }
);

// Main Income Schema
const IncomeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },

    // Core Income Data
    amount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Số tiền là bắt buộc"],
      validate: {
        validator: function (v) {
          const num = parseFloat(v.toString());
          return num > 0;
        },
        message: "Số tiền phải lớn hơn 0",
      },
    },
    currency: {
      type: String,
      enum: ["VND", "USD", "EUR"],
      default: "VND",
    },
    category: {
      type: String,
      enum: [
        "salary",
        "freelance",
        "business",
        "investment",
        "bonus",
        "gift",
        "scholarship",
        "parttime",
        "allowance",
        "refund",
        "rental",
        "other",
      ],
      required: [true, "Danh mục thu nhập là bắt buộc"],
      index: true,
    },

    // Description & Details
    title: {
      type: String,
      required: [true, "Tiêu đề là bắt buộc"],
      trim: true,
      maxlength: [200, "Tiêu đề không được vượt quá 200 ký tự"],
    },
    description: {
      type: String,
      maxlength: [1000, "Mô tả không được vượt quá 1000 ký tự"],
    },

    // Date & Time
    date: {
      type: Date,
      required: [true, "Ngày thu nhập là bắt buộc"],
      index: true,
      default: Date.now,
    },

    // Payment Method
    paymentMethod: {
      type: String,
      enum: ["cash", "card", "momo", "banking", "zalopay", "viettelpay", "other"],
      required: [true, "Phương thức thanh toán là bắt buộc"],
      default: "banking",
    },

    // Source Details
    source: {
      type: SourceDetailsSchema,
    },

    // Recurring Income
    isRecurring: {
      type: Boolean,
      default: false,
      index: true,
    },
    recurringDetails: {
      type: RecurringDetailsSchema,
    },

    // Tax Information
    taxInfo: {
      type: TaxInfoSchema,
      default: () => ({}),
    },

    // Proof/Documentation
    receiptUrl: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || validator.isURL(v);
        },
        message: "Receipt URL phải là URL hợp lệ",
      },
    },

    // Status
    isConfirmed: {
      type: Boolean,
      default: true,
    },
    isPending: {
      type: Boolean,
      default: false,
    },

    // Notes & Tags
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

    // YNAB-style Budget Allocations
    allocations: {
      type: [AllocationSchema],
      default: [],
      description: "Danh sách phân bổ thu nhập vào budgets/savings",
    },

    // Allocation Tracking
    totalAllocated: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Tổng số tiền đã phân bổ",
    },

    unallocated: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
      description: "Số tiền chưa phân bổ (Ready to Assign)",
    },

    isFullyAllocated: {
      type: Boolean,
      default: false,
      description: "Đã phân bổ hết thu nhập chưa",
    },

    // Metadata
    createdBy: {
      type: String,
      enum: ["user", "system", "import"],
      default: "user",
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
IncomeSchema.index({ userId: 1, date: -1 });
IncomeSchema.index({ userId: 1, category: 1 });
IncomeSchema.index({ userId: 1, isRecurring: 1 });
IncomeSchema.index({ date: 1 });

// Virtual for net amount (after tax)
IncomeSchema.virtual("netAmount").get(function () {
  const amount = parseFloat(this.amount.toString());
  if (this.taxInfo && this.taxInfo.taxAmount) {
    const taxAmount = parseFloat(this.taxInfo.taxAmount.toString());
    return amount - taxAmount;
  }
  return amount;
});

// Static methods
IncomeSchema.statics = {
  // Get total income for user
  async getTotalByUser(userId, startDate, endDate) {
    const match = {
      userId: mongoose.Types.ObjectId(userId),
      isConfirmed: true,
    };

    if (startDate && endDate) {
      match.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const result = await this.aggregate([
      { $match: match },
      {
        $group: {
          _id: null,
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
        },
      },
    ]);

    return result.length > 0
      ? { total: result[0].total, count: result[0].count }
      : { total: 0, count: 0 };
  },

  // Get income by category
  async getTotalByCategory(userId, startDate, endDate) {
    const match = {
      userId: mongoose.Types.ObjectId(userId),
      isConfirmed: true,
    };

    if (startDate && endDate) {
      match.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    return await this.aggregate([
      { $match: match },
      {
        $group: {
          _id: "$category",
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
          avgAmount: { $avg: { $toDouble: "$amount" } },
        },
      },
      { $sort: { total: -1 } },
    ]);
  },

  // Get monthly income stats
  async getMonthlyStats(userId, year) {
    return await this.aggregate([
      {
        $match: {
          userId: mongoose.Types.ObjectId(userId),
          isConfirmed: true,
          date: {
            $gte: new Date(year, 0, 1),
            $lt: new Date(year + 1, 0, 1),
          },
        },
      },
      {
        $group: {
          _id: { $month: "$date" },
          total: { $sum: { $toDouble: "$amount" } },
          count: { $sum: 1 },
          avgAmount: { $avg: { $toDouble: "$amount" } },
        },
      },
      { $sort: { _id: 1 } },
    ]);
  },

  // Get recurring incomes due for processing
  async getDueRecurringIncomes() {
    const now = new Date();
    return await this.find({
      isRecurring: true,
      "recurringDetails.isActive": true,
      "recurringDetails.nextOccurrence": { $lte: now },
      $or: [
        { "recurringDetails.endDate": { $exists: false } },
        { "recurringDetails.endDate": { $gte: now } },
      ],
    }).populate("userId", "email profile.name");
  },

  // Find by user with filters
  async findByUser(userId, filters = {}) {
    const query = { userId };

    if (filters.category) query.category = filters.category;
    if (filters.isRecurring !== undefined)
      query.isRecurring = filters.isRecurring;
    if (filters.startDate && filters.endDate) {
      query.date = {
        $gte: new Date(filters.startDate),
        $lte: new Date(filters.endDate),
      };
    }

    return await this.find(query).sort({ date: -1 }).limit(filters.limit || 100);
  },
};

// Instance methods
IncomeSchema.methods = {
  // Calculate next occurrence for recurring income
  calculateNextOccurrence() {
    if (!this.isRecurring || !this.recurringDetails) return null;

    const current = this.recurringDetails.nextOccurrence || this.date;
    const frequency = this.recurringDetails.frequency;
    const next = new Date(current);

    switch (frequency) {
      case "daily":
        next.setDate(next.getDate() + 1);
        break;
      case "weekly":
        next.setDate(next.getDate() + 7);
        break;
      case "biweekly":
        next.setDate(next.getDate() + 14);
        break;
      case "monthly":
        next.setMonth(next.getMonth() + 1);
        break;
      case "quarterly":
        next.setMonth(next.getMonth() + 3);
        break;
      case "yearly":
        next.setFullYear(next.getFullYear() + 1);
        break;
    }

    return next;
  },

  // Update recurring income's next occurrence
  async updateNextOccurrence() {
    if (!this.isRecurring) return;

    const next = this.calculateNextOccurrence();
    if (next) {
      this.recurringDetails.nextOccurrence = next;
      await this.save();
    }
  },
};

// Middleware
IncomeSchema.pre("save", function (next) {
  // Calculate tax if taxable
  if (this.taxInfo && this.taxInfo.isTaxable && this.taxInfo.taxRate) {
    const amount = parseFloat(this.amount.toString());
    const taxAmount = (amount * this.taxInfo.taxRate) / 100;
    this.taxInfo.taxAmount = mongoose.Types.Decimal128.fromString(
      taxAmount.toFixed(2)
    );
    this.taxInfo.grossAmount = this.amount;
  }

  // Set next occurrence for recurring income
  if (this.isRecurring && this.recurringDetails && !this.recurringDetails.nextOccurrence) {
    this.recurringDetails.nextOccurrence = this.calculateNextOccurrence();
  }

  // Calculate allocation totals
  if (this.allocations && this.allocations.length > 0) {
    const totalAllocated = this.allocations.reduce((sum, alloc) => {
      return sum + parseFloat(alloc.amount.toString());
    }, 0);

    const incomeAmount = parseFloat(this.amount.toString());
    const unallocatedAmount = incomeAmount - totalAllocated;

    this.totalAllocated = mongoose.Types.Decimal128.fromString(totalAllocated.toString());
    this.unallocated = mongoose.Types.Decimal128.fromString(unallocatedAmount.toString());
    this.isFullyAllocated = unallocatedAmount <= 0;
  } else {
    // No allocations, all income is unallocated
    this.totalAllocated = mongoose.Types.Decimal128.fromString("0");
    this.unallocated = this.amount;
    this.isFullyAllocated = false;
  }

  next();
});

const Income = mongoose.model("Income", IncomeSchema);

export default Income;
