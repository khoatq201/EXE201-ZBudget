import mongoose from "mongoose";
import validator from "validator";

// Sub-schemas
const DurationSchema = new mongoose.Schema(
  {
    days: {
      type: Number,
      min: [1, "Thời gian thách thức phải ít nhất 1 ngày"],
      max: [365, "Thời gian thách thức không được quá 365 ngày"],
      required: [true, "Số ngày là bắt buộc"],
    },
    displayText: {
      type: String,
      maxlength: [50, "Hiển thị thời gian không được vượt quá 50 ký tự"],
    },
    timeLimit: {
      type: Date, // null = no time limit to start
    },
  },
  { _id: false }
);

const TargetsSchema = new mongoose.Schema(
  {
    estimatedSaving: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Mục tiêu tiết kiệm dự kiến là bắt buộc"],
      validate: {
        validator: function (v) {
          return parseFloat(v.toString()) >= 0;
        },
        message: "Mục tiêu tiết kiệm phải >= 0",
      },
    },
    dailySavingTarget: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    maxBudget: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    comparisonPeriod: {
      type: String,
      enum: ["previous_week", "previous_month", "average", "custom"],
      default: "previous_week",
    },
  },
  { _id: false }
);

const MilestoneSchema = new mongoose.Schema(
  {
    day: {
      type: Number,
      min: [1, "Ngày milestone phải >= 1"],
      required: [true, "Ngày milestone là bắt buộc"],
    },
    title: {
      type: String,
      required: [true, "Tiêu đề milestone là bắt buộc"],
      maxlength: [100, "Tiêu đề milestone không được vượt quá 100 ký tự"],
    },
    description: {
      type: String,
      maxlength: [200, "Mô tả milestone không được vượt quá 200 ký tự"],
    },
    points: {
      type: Number,
      min: [0, "Điểm milestone phải >= 0"],
      required: [true, "Điểm milestone là bắt buộc"],
    },
    badge: {
      type: String,
      maxlength: [10, "Badge không được vượt quá 10 ký tự"],
    },
    reward: {
      type: String,
      maxlength: [200, "Phần thưởng không được vượt quá 200 ký tự"],
    },
  },
  { _id: false }
);

const StatsSchema = new mongoose.Schema(
  {
    totalParticipants: {
      type: Number,
      min: 0,
      default: 0,
    },
    activeParticipants: {
      type: Number,
      min: 0,
      default: 0,
    },
    completionRate: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    averageSaving: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    topSaver: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
  },
  { _id: false }
);

const RulesSchema = new mongoose.Schema(
  {
    allowedExpenses: [
      {
        type: String,
        maxlength: [50, "Mục chi tiêu cho phép không được vượt quá 50 ký tự"],
      },
    ],
    forbiddenCategories: [
      {
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
          "coffee-shops",
          "cafe",
          "drinks",
        ],
      },
    ],
    substitutionSuggestions: [
      {
        type: String,
        maxlength: [200, "Gợi ý thay thế không được vượt quá 200 ký tự"],
      },
    ],
    trackingMethod: {
      type: String,
      enum: [
        "expense_category",
        "total_amount",
        "manual_logging",
        "receipt_scan",
      ],
      default: "expense_category",
    },
  },
  { _id: false }
);

// Main Challenge Schema
const ChallengeSchema = new mongoose.Schema(
  {
    // Challenge Identity
    challengeId: {
      type: String,
      required: [true, "Challenge ID là bắt buộc"],
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: [100, "Challenge ID không được vượt quá 100 ký tự"],
      validate: {
        validator: function (v) {
          return /^[a-z0-9-_]+$/.test(v);
        },
        message:
          "Challenge ID chỉ được chứa chữ thường, số, dấu gạch ngang và gạch dưới",
      },
      index: true,
    },
    title: {
      type: String,
      required: [true, "Tiêu đề thách thức là bắt buộc"],
      trim: true,
      maxlength: [200, "Tiêu đề không được vượt quá 200 ký tự"],
    },
    description: {
      type: String,
      required: [true, "Mô tả thách thức là bắt buộc"],
      trim: true,
      maxlength: [1000, "Mô tả không được vượt quá 1000 ký tự"],
    },

    // Visual & Branding
    emoji: {
      type: String,
      maxlength: [10, "Emoji không được vượt quá 10 ký tự"],
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
    bannerImage: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || validator.isURL(v);
        },
        message: "Banner image phải là URL hợp lệ",
      },
    },

    // Challenge Configuration
    type: {
      type: String,
      enum: ["reduction", "savings", "budget", "custom"],
      default: "reduction",
    },
    category: {
      type: String,
      enum: [
        "drinks",
        "food",
        "transport",
        "shopping",
        "entertainment",
        "lifestyle",
      ],
      required: [true, "Danh mục thách thức là bắt buộc"],
      index: true,
    },
    difficulty: {
      type: String,
      enum: ["easy", "medium", "hard"],
      required: [true, "Độ khó là bắt buộc"],
      index: true,
    },

    // Duration & Timeline
    duration: {
      type: DurationSchema,
      required: [true, "Thời gian thách thức là bắt buộc"],
    },

    // Financial Targets
    targets: {
      type: TargetsSchema,
      required: [true, "Mục tiêu tài chính là bắt buộc"],
    },

    // Milestones & Rewards
    milestones: {
      type: [MilestoneSchema],
      validate: {
        validator: function (v) {
          return v.length > 0;
        },
        message: "Phải có ít nhất 1 milestone",
      },
    },

    // Participation & Stats
    stats: {
      type: StatsSchema,
      default: () => ({}),
    },

    // Rules & Guidelines
    rules: {
      type: RulesSchema,
      default: () => ({}),
    },

    // Challenge Status
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    startDate: {
      type: Date,
      default: Date.now,
    },
    endDate: {
      type: Date,
      required: [true, "Ngày kết thúc thách thức là bắt buộc"],
    },
    featured: {
      type: Boolean,
      default: false,
      index: true,
    },

    // Creator Info
    createdBy: {
      type: String,
      default: "system", // 'system' or userId
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
        if (ret.targets) {
          if (ret.targets.estimatedSaving)
            ret.targets.estimatedSaving = parseFloat(
              ret.targets.estimatedSaving.toString()
            );
          if (ret.targets.dailySavingTarget)
            ret.targets.dailySavingTarget = parseFloat(
              ret.targets.dailySavingTarget.toString()
            );
          if (ret.targets.maxBudget)
            ret.targets.maxBudget = parseFloat(
              ret.targets.maxBudget.toString()
            );
        }
        if (ret.stats) {
          if (ret.stats.averageSaving)
            ret.stats.averageSaving = parseFloat(
              ret.stats.averageSaving.toString()
            );
          if (ret.stats.topSaver)
            ret.stats.topSaver = parseFloat(ret.stats.topSaver.toString());
        }
        return ret;
      },
    },
  }
);

// Indexes
ChallengeSchema.index({ isActive: 1, featured: 1 });
ChallengeSchema.index({ category: 1, difficulty: 1 });
ChallengeSchema.index({ startDate: 1, endDate: 1 });

// Instance Methods
ChallengeSchema.methods.addParticipant = function () {
  this.stats.totalParticipants += 1;
  this.stats.activeParticipants += 1;
};

ChallengeSchema.methods.removeParticipant = function () {
  if (this.stats.activeParticipants > 0) {
    this.stats.activeParticipants -= 1;
  }
};

ChallengeSchema.methods.updateCompletionRate = function () {
  if (this.stats.totalParticipants > 0) {
    const completed =
      this.stats.totalParticipants - this.stats.activeParticipants;
    this.stats.completionRate =
      (completed / this.stats.totalParticipants) * 100;
  }
};

ChallengeSchema.methods.updateAverageSaving = function (
  totalSavings,
  participantCount
) {
  if (participantCount > 0) {
    this.stats.averageSaving = mongoose.Types.Decimal128.fromString(
      (totalSavings / participantCount).toFixed(2)
    );
  }
};

ChallengeSchema.methods.updateTopSaver = function (savingAmount) {
  const currentTop = parseFloat(this.stats.topSaver.toString()) || 0;
  if (savingAmount > currentTop) {
    this.stats.topSaver = mongoose.Types.Decimal128.fromString(
      savingAmount.toFixed(2)
    );
  }
};

ChallengeSchema.methods.getMilestoneByDay = function (day) {
  return this.milestones.find((milestone) => milestone.day === day);
};

ChallengeSchema.methods.isExpired = function () {
  return new Date() > this.endDate;
};

ChallengeSchema.methods.getDaysRemaining = function () {
  const now = new Date();
  const diffTime = this.endDate - now;
  return Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
};

// Pre-save middleware
ChallengeSchema.pre("save", function (next) {
  // Calculate daily saving target
  if (
    this.isModified("targets.estimatedSaving") ||
    this.isModified("duration.days")
  ) {
    const estimatedSaving = parseFloat(this.targets.estimatedSaving.toString());
    const dailyTarget = estimatedSaving / this.duration.days;
    this.targets.dailySavingTarget = mongoose.Types.Decimal128.fromString(
      dailyTarget.toFixed(2)
    );
  }

  // Update duration display text
  if (this.isModified("duration.days")) {
    const days = this.duration.days;
    if (days === 1) {
      this.duration.displayText = "1 ngày";
    } else if (days === 7) {
      this.duration.displayText = "1 tuần";
    } else if (days === 30) {
      this.duration.displayText = "1 tháng";
    } else {
      this.duration.displayText = `${days} ngày`;
    }
  }

  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }

  next();
});

// Static Methods
ChallengeSchema.statics.findActive = function () {
  const now = new Date();
  return this.find({
    isActive: true,
    startDate: { $lte: now },
    endDate: { $gte: now },
  }).sort({ featured: -1, createdAt: -1 });
};

ChallengeSchema.statics.findFeatured = function (limit = 5) {
  const now = new Date();
  return this.find({
    isActive: true,
    featured: true,
    startDate: { $lte: now },
    endDate: { $gte: now },
  })
    .sort({ createdAt: -1 })
    .limit(limit);
};

ChallengeSchema.statics.findByCategory = function (category) {
  const now = new Date();
  return this.find({
    isActive: true,
    category,
    startDate: { $lte: now },
    endDate: { $gte: now },
  }).sort({ difficulty: 1, createdAt: -1 });
};

ChallengeSchema.statics.findByDifficulty = function (difficulty) {
  const now = new Date();
  return this.find({
    isActive: true,
    difficulty,
    startDate: { $lte: now },
    endDate: { $gte: now },
  }).sort({ featured: -1, createdAt: -1 });
};

ChallengeSchema.statics.getPopularChallenges = function (limit = 10) {
  return this.find({ isActive: true })
    .sort({ "stats.totalParticipants": -1, featured: -1 })
    .limit(limit);
};

ChallengeSchema.statics.getChallengeStats = function () {
  return this.aggregate([
    {
      $match: { isActive: true },
    },
    {
      $group: {
        _id: null,
        totalChallenges: { $sum: 1 },
        totalParticipants: { $sum: "$stats.totalParticipants" },
        averageCompletionRate: { $avg: "$stats.completionRate" },
        totalSavings: { $sum: { $toDouble: "$stats.averageSaving" } },
        challengesByCategory: {
          $push: {
            category: "$category",
            count: 1,
          },
        },
      },
    },
  ]);
};

const Challenge = mongoose.model("Challenge", ChallengeSchema);

export default Challenge;
