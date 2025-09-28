import mongoose from "mongoose";
import validator from "validator";

// Sub-schemas
const LocationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      maxlength: [200, "Tên địa điểm không được vượt quá 200 ký tự"],
    },
    address: {
      type: String,
      maxlength: [500, "Địa chỉ không được vượt quá 500 ký tự"],
    },
    coordinates: {
      lat: {
        type: Number,
        min: [-90, "Vĩ độ phải trong khoảng -90 đến 90"],
        max: [90, "Vĩ độ phải trong khoảng -90 đến 90"],
      },
      lng: {
        type: Number,
        min: [-180, "Kinh độ phải trong khoảng -180 đến 180"],
        max: [180, "Kinh độ phải trong khoảng -180 đến 180"],
      },
    },
  },
  { _id: false }
);

const PaymentDetailsSchema = new mongoose.Schema(
  {
    accountLast4: {
      type: String,
      maxlength: [4, "Account last 4 không được vượt quá 4 ký tự"],
      validate: {
        validator: function (v) {
          return !v || /^\d{4}$/.test(v);
        },
        message: "Account last 4 phải là 4 chữ số",
      },
    },
    transactionId: {
      type: String,
      maxlength: [100, "Transaction ID không được vượt quá 100 ký tự"],
    },
  },
  { _id: false }
);

const ReceiptSchema = new mongoose.Schema(
  {
    imageUrl: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || validator.isURL(v);
        },
        message: "Receipt image phải là URL hợp lệ",
      },
    },
    ocrText: {
      type: String,
      maxlength: [5000, "OCR text không được vượt quá 5000 ký tự"],
    },
    confidence: {
      type: Number,
      min: [0, "Confidence phải từ 0 đến 1"],
      max: [1, "Confidence phải từ 0 đến 1"],
    },
  },
  { _id: false }
);

const SplitDetailsSchema = new mongoose.Schema(
  {
    isShared: {
      type: Boolean,
      default: false,
    },
    sharedWith: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    userShare: {
      type: mongoose.Schema.Types.Decimal128,
      required: function () {
        return this.isShared;
      },
    },
  },
  { _id: false }
);

const CategoryDisplaySchema = new mongoose.Schema(
  {
    icon: {
      type: String,
      maxlength: [10, "Icon không được vượt quá 10 ký tự"],
    },
    nameVi: {
      type: String,
      maxlength: [50, "Tên tiếng Việt không được vượt quá 50 ký tự"],
    },
    nameEn: {
      type: String,
      maxlength: [50, "Tên tiếng Anh không được vượt quá 50 ký tự"],
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
  },
  { _id: false }
);

// Main Expense Schema
const ExpenseSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },

    // Core Expense Data
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
        "food",
        "transport",
        "shopping",
        "entertainment",
        "healthcare",
        "education",
        "utilities",
        "other",
      ],
      required: [true, "Danh mục chi tiêu là bắt buộc"],
      index: true,
    },
    subCategory: {
      type: String,
      maxlength: [50, "Danh mục con không được vượt quá 50 ký tự"],
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
      trim: true,
      maxlength: [1000, "Mô tả không được vượt quá 1000 ký tự"],
    },
    tags: [
      {
        type: String,
        lowercase: true,
        trim: true,
        maxlength: [30, "Tag không được vượt quá 30 ký tự"],
      },
    ],

    // Date & Location
    date: {
      type: Date,
      required: [true, "Ngày giao dịch là bắt buộc"],
      index: true,
    },
    location: {
      type: LocationSchema,
    },

    // Payment Information
    paymentMethod: {
      type: String,
      enum: ["cash", "card", "momo", "banking", "other"],
      default: "cash",
    },
    paymentDetails: {
      type: PaymentDetailsSchema,
    },

    // Receipt & Proof
    receipt: {
      type: ReceiptSchema,
    },

    // Group & Sharing
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Group",
      index: { sparse: true },
    },
    splitDetails: {
      type: SplitDetailsSchema,
      default: () => ({ isShared: false }),
    },

    // Challenge Integration
    challengeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Challenge",
      index: { sparse: true },
    },
    challengeContribution: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },

    // Budget Integration
    budgetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Budget",
      index: { sparse: true },
    },
    budgetImpact: {
      type: mongoose.Schema.Types.Decimal128,
      default: function () {
        return mongoose.Types.Decimal128.fromString(
          (-parseFloat(this.amount.toString())).toFixed(2)
        );
      },
    },

    // Denormalization for Performance
    userEmail: {
      type: String,
      lowercase: true,
    },
    categoryDisplay: {
      type: CategoryDisplaySchema,
    },

    // Status & Metadata
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    syncStatus: {
      type: String,
      enum: ["pending", "synced", "failed"],
      default: "synced",
      index: true,
    },
    lastSyncAt: {
      type: Date,
      default: Date.now,
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
        if (ret.amount) ret.amount = parseFloat(ret.amount.toString());
        if (ret.budgetImpact)
          ret.budgetImpact = parseFloat(ret.budgetImpact.toString());
        if (ret.challengeContribution)
          ret.challengeContribution = parseFloat(
            ret.challengeContribution.toString()
          );
        if (ret.splitDetails && ret.splitDetails.userShare) {
          ret.splitDetails.userShare = parseFloat(
            ret.splitDetails.userShare.toString()
          );
        }
        return ret;
      },
    },
  }
);

// Compound Indexes
ExpenseSchema.index({ userId: 1, date: -1 }); // User's expenses by date
ExpenseSchema.index({ userId: 1, category: 1, date: -1 }); // Category expenses by date
ExpenseSchema.index({ groupId: 1, date: -1 }, { sparse: true }); // Group expenses
ExpenseSchema.index({ budgetId: 1, date: -1 }, { sparse: true }); // Budget expenses
ExpenseSchema.index({ challengeId: 1, date: -1 }, { sparse: true }); // Challenge expenses
ExpenseSchema.index({ isDeleted: 1, syncStatus: 1 }); // Sync management
ExpenseSchema.index({ date: -1, category: 1 }); // Analytics queries

// Instance Methods
ExpenseSchema.methods.updateBudgetImpact = function () {
  this.budgetImpact = mongoose.Types.Decimal128.fromString(
    (-parseFloat(this.amount.toString())).toFixed(2)
  );
};

ExpenseSchema.methods.markAsDeleted = function () {
  this.isDeleted = true;
  this.version += 1;
};

ExpenseSchema.methods.addTag = function (tag) {
  if (this.tags.length >= 10) {
    throw new Error("Không được có quá 10 tags");
  }

  const normalizedTag = tag.toLowerCase().trim();
  if (!this.tags.includes(normalizedTag)) {
    this.tags.push(normalizedTag);
  }
};

ExpenseSchema.methods.removeTag = function (tag) {
  const normalizedTag = tag.toLowerCase().trim();
  this.tags = this.tags.filter((t) => t !== normalizedTag);
};

// Pre-save middleware
ExpenseSchema.pre("save", function (next) {
  // Auto-set budget impact
  if (this.isModified("amount")) {
    this.updateBudgetImpact();
  }

  // Set category display based on category
  if (this.isModified("category")) {
    this.categoryDisplay = getCategoryDisplay(this.category);
  }

  // Update sync status
  if (this.isModified() && !this.isModified("syncStatus")) {
    this.syncStatus = "pending";
    this.lastSyncAt = new Date();
  }

  next();
});

ExpenseSchema.pre("save", function (next) {
  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  next();
});

// Static Methods
ExpenseSchema.statics.findByUser = function (userId, options = {}) {
  const query = { userId, isDeleted: false };

  // Add date filters if provided
  if (options.startDate) {
    query.date = { $gte: options.startDate };
  }
  if (options.endDate) {
    query.date = { ...query.date, $lte: options.endDate };
  }

  // Add category filter if provided
  if (options.category) {
    query.category = options.category;
  }

  return this.find(query)
    .sort({ date: -1 })
    .limit(options.limit || 50);
};

ExpenseSchema.statics.getTotalByCategory = function (
  userId,
  startDate,
  endDate
) {
  return this.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(userId),
        isDeleted: false,
        date: {
          $gte: startDate,
          $lte: endDate,
        },
      },
    },
    {
      $group: {
        _id: "$category",
        totalAmount: {
          $sum: { $toDouble: "$amount" },
        },
        count: { $sum: 1 },
      },
    },
    {
      $sort: { totalAmount: -1 },
    },
  ]);
};

ExpenseSchema.statics.getMonthlyStats = function (userId, year, month) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0, 23, 59, 59);

  return this.aggregate([
    {
      $match: {
        userId: new mongoose.Types.ObjectId(userId),
        isDeleted: false,
        date: { $gte: startDate, $lte: endDate },
      },
    },
    {
      $group: {
        _id: null,
        totalAmount: { $sum: { $toDouble: "$amount" } },
        totalTransactions: { $sum: 1 },
        avgTransaction: { $avg: { $toDouble: "$amount" } },
        categories: {
          $addToSet: "$category",
        },
      },
    },
  ]);
};

// Helper function for category display
function getCategoryDisplay(category) {
  const categoryMap = {
    food: { icon: "🍜", nameVi: "Ăn uống", nameEn: "Food", color: "#FF6B6B" },
    transport: {
      icon: "🚗",
      nameVi: "Di chuyển",
      nameEn: "Transport",
      color: "#4ECDC4",
    },
    shopping: {
      icon: "🛍️",
      nameVi: "Mua sắm",
      nameEn: "Shopping",
      color: "#45B7D1",
    },
    entertainment: {
      icon: "🎬",
      nameVi: "Giải trí",
      nameEn: "Entertainment",
      color: "#FFA07A",
    },
    healthcare: {
      icon: "🏥",
      nameVi: "Y tế",
      nameEn: "Healthcare",
      color: "#98D8C8",
    },
    education: {
      icon: "📚",
      nameVi: "Giáo dục",
      nameEn: "Education",
      color: "#F7DC6F",
    },
    utilities: {
      icon: "💡",
      nameVi: "Tiện ích",
      nameEn: "Utilities",
      color: "#BB8FCE",
    },
    other: { icon: "📦", nameVi: "Khác", nameEn: "Other", color: "#85C1E9" },
  };

  return categoryMap[category] || categoryMap.other;
}

const Expense = mongoose.model("Expense", ExpenseSchema);

export default Expense;
