import mongoose from "mongoose";

// Sub-schemas
const DailyProgressSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      required: [true, "Ngày là bắt buộc"],
    },
    targetAmount: {
      type: mongoose.Schema.Types.Decimal128,
      required: [true, "Mục tiêu số tiền là bắt buộc"],
    },
    actualSaved: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    expensesInCategory: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    completed: {
      type: Boolean,
      default: false,
    },
    notes: {
      type: String,
      maxlength: [500, "Ghi chú không được vượt quá 500 ký tự"],
    },
  },
  { _id: false }
);

const MilestoneAchievedSchema = new mongoose.Schema(
  {
    milestoneIndex: {
      type: Number,
      required: [true, "Chỉ mục milestone là bắt buộc"],
      min: [0, "Chỉ mục milestone phải >= 0"],
    },
    achievedAt: {
      type: Date,
      required: [true, "Thời gian đạt milestone là bắt buộc"],
    },
    pointsEarned: {
      type: Number,
      min: [0, "Điểm kiếm được phải >= 0"],
      required: [true, "Điểm kiếm được là bắt buộc"],
    },
    badgeEarned: {
      type: String,
      maxlength: [10, "Badge không được vượt quá 10 ký tự"],
    },
  },
  { _id: false }
);

const CurrentStatsSchema = new mongoose.Schema(
  {
    daysCompleted: {
      type: Number,
      min: 0,
      default: 0,
    },
    totalDays: {
      type: Number,
      min: 1,
      required: [true, "Tổng số ngày là bắt buộc"],
    },
    completionPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    currentStreak: {
      type: Number,
      min: 0,
      default: 0,
    },
    totalSaved: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    pointsEarned: {
      type: Number,
      min: 0,
      default: 0,
    },
    rank: {
      type: Number,
      min: 1,
    },
    onTrack: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const UserNoteSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      required: [true, "Ngày ghi chú là bắt buộc"],
    },
    note: {
      type: String,
      required: [true, "Nội dung ghi chú là bắt buộc"],
      maxlength: [1000, "Ghi chú không được vượt quá 1000 ký tự"],
    },
  },
  { _id: false }
);

const SocialSchema = new mongoose.Schema(
  {
    shareProgress: {
      type: Boolean,
      default: true,
    },
    allowRankingDisplay: {
      type: Boolean,
      default: true,
    },
    encouragementReceived: {
      type: Number,
      min: 0,
      default: 0,
    },
    encouragementGiven: {
      type: Number,
      min: 0,
      default: 0,
    },
  },
  { _id: false }
);

const CompletionSchema = new mongoose.Schema(
  {
    completedAt: {
      type: Date,
    },
    finalSaving: {
      type: mongoose.Schema.Types.Decimal128,
    },
    totalPointsEarned: {
      type: Number,
      min: 0,
    },
    badgesEarned: [
      {
        type: String,
        maxlength: [10, "Badge không được vượt quá 10 ký tự"],
      },
    ],
    certificateUrl: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^https?:\/\/.+/.test(v);
        },
        message: "Certificate URL phải là URL hợp lệ",
      },
    },
    feedback: {
      type: String,
      maxlength: [2000, "Phản hồi không được vượt quá 2000 ký tự"],
    },
  },
  { _id: false }
);

// Main UserChallenge Schema
const UserChallengeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
      index: true,
    },
    challengeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Challenge",
      required: [true, "Challenge ID là bắt buộc"],
      index: true,
    },

    // Progress Tracking
    status: {
      type: String,
      enum: ["available", "active", "completed", "failed", "abandoned"],
      default: "available",
      index: true,
    },
    startDate: {
      type: Date,
      required: function () {
        return ["active", "completed", "failed"].includes(this.status);
      },
    },
    endDate: {
      type: Date,
      required: function () {
        return ["active", "completed", "failed"].includes(this.status);
      },
      validate: {
        validator: function (v) {
          return !this.startDate || !v || v > this.startDate;
        },
        message: "Ngày kết thúc phải sau ngày bắt đầu",
      },
    },

    // Daily Progress
    dailyProgress: {
      type: [DailyProgressSchema],
      default: [],
    },

    // Milestone Progress
    milestonesAchieved: {
      type: [MilestoneAchievedSchema],
      default: [],
    },

    // Current Stats
    currentStats: {
      type: CurrentStatsSchema,
      required: true,
      default: () => ({}),
    },

    // User Notes & Reflections
    userNotes: {
      type: [UserNoteSchema],
      default: [],
    },

    // Social Features
    social: {
      type: SocialSchema,
      default: () => ({}),
    },

    // Completion Details
    completion: {
      type: CompletionSchema,
      default: () => ({}),
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
        if (ret.dailyProgress) {
          ret.dailyProgress.forEach((day) => {
            if (day.targetAmount)
              day.targetAmount = parseFloat(day.targetAmount.toString());
            if (day.actualSaved)
              day.actualSaved = parseFloat(day.actualSaved.toString());
            if (day.expensesInCategory)
              day.expensesInCategory = parseFloat(
                day.expensesInCategory.toString()
              );
          });
        }

        if (ret.currentStats && ret.currentStats.totalSaved) {
          ret.currentStats.totalSaved = parseFloat(
            ret.currentStats.totalSaved.toString()
          );
        }

        if (ret.completion) {
          if (ret.completion.finalSaving)
            ret.completion.finalSaving = parseFloat(
              ret.completion.finalSaving.toString()
            );
        }

        return ret;
      },
    },
  }
);

// Compound Indexes
UserChallengeSchema.index({ userId: 1, status: 1 });
UserChallengeSchema.index({ challengeId: 1, status: 1 });
UserChallengeSchema.index({ userId: 1, startDate: -1 });
UserChallengeSchema.index({ "currentStats.rank": 1 }, { sparse: true });

// Instance Methods
UserChallengeSchema.methods.startChallenge = function (challenge) {
  if (this.status !== "available") {
    throw new Error("Không thể bắt đầu thách thức đã được kích hoạt");
  }

  this.status = "active";
  this.startDate = new Date();
  this.endDate = new Date(
    Date.now() + challenge.duration.days * 24 * 60 * 60 * 1000
  );

  // Initialize current stats
  this.currentStats = {
    daysCompleted: 0,
    totalDays: challenge.duration.days,
    completionPercentage: 0,
    currentStreak: 0,
    totalSaved: mongoose.Types.Decimal128.fromString("0"),
    pointsEarned: 0,
    onTrack: true,
  };

  // Initialize daily progress array
  this.dailyProgress = [];
  for (let i = 0; i < challenge.duration.days; i++) {
    const date = new Date(this.startDate);
    date.setDate(date.getDate() + i);

    this.dailyProgress.push({
      date,
      targetAmount: challenge.targets.dailySavingTarget,
      actualSaved: mongoose.Types.Decimal128.fromString("0"),
      expensesInCategory: mongoose.Types.Decimal128.fromString("0"),
      completed: false,
    });
  }
};

UserChallengeSchema.methods.updateDailyProgress = function (
  date,
  actualSaved,
  expensesInCategory,
  notes
) {
  const dayProgress = this.dailyProgress.find(
    (day) => day.date.toDateString() === date.toDateString()
  );

  if (!dayProgress) {
    throw new Error("Không tìm thấy ngày trong kế hoạch thách thức");
  }

  // Update progress
  dayProgress.actualSaved = mongoose.Types.Decimal128.fromString(
    actualSaved.toFixed(2)
  );
  dayProgress.expensesInCategory = mongoose.Types.Decimal128.fromString(
    expensesInCategory.toFixed(2)
  );
  dayProgress.completed =
    actualSaved >= parseFloat(dayProgress.targetAmount.toString());
  if (notes) dayProgress.notes = notes;

  // Update overall stats
  this.updateCurrentStats();

  return dayProgress;
};

UserChallengeSchema.methods.updateCurrentStats = function () {
  const completedDays = this.dailyProgress.filter(
    (day) => day.completed
  ).length;
  const totalSaved = this.dailyProgress.reduce(
    (sum, day) => sum + parseFloat(day.actualSaved.toString()),
    0
  );

  // Calculate completion percentage
  const completionPercentage =
    (completedDays / this.currentStats.totalDays) * 100;

  // Calculate current streak
  let currentStreak = 0;
  for (let i = this.dailyProgress.length - 1; i >= 0; i--) {
    if (this.dailyProgress[i].completed) {
      currentStreak++;
    } else {
      break;
    }
  }

  // Check if on track
  const today = new Date();
  const daysSinceStart = Math.floor(
    (today - this.startDate) / (1000 * 60 * 60 * 24)
  );
  const expectedCompletedDays = Math.min(
    daysSinceStart + 1,
    this.currentStats.totalDays
  );
  const onTrack = completedDays >= expectedCompletedDays * 0.8; // 80% threshold

  // Update stats
  this.currentStats = {
    daysCompleted: completedDays,
    totalDays: this.currentStats.totalDays,
    completionPercentage: Math.round(completionPercentage * 100) / 100,
    currentStreak,
    totalSaved: mongoose.Types.Decimal128.fromString(totalSaved.toFixed(2)),
    pointsEarned: this.currentStats.pointsEarned,
    rank: this.currentStats.rank,
    onTrack,
  };
};

UserChallengeSchema.methods.achieveMilestone = function (
  milestoneIndex,
  pointsEarned,
  badgeEarned
) {
  // Check if milestone already achieved
  const alreadyAchieved = this.milestonesAchieved.find(
    (m) => m.milestoneIndex === milestoneIndex
  );

  if (alreadyAchieved) {
    throw new Error("Milestone đã được hoàn thành trước đó");
  }

  // Add milestone
  this.milestonesAchieved.push({
    milestoneIndex,
    achievedAt: new Date(),
    pointsEarned,
    badgeEarned,
  });

  // Update points
  this.currentStats.pointsEarned += pointsEarned;

  return this.milestonesAchieved[this.milestonesAchieved.length - 1];
};

UserChallengeSchema.methods.addNote = function (note) {
  this.userNotes.push({
    date: new Date(),
    note,
  });
};

UserChallengeSchema.methods.completeChallenge = function (
  finalSaving,
  totalPointsEarned,
  badgesEarned
) {
  if (this.status !== "active") {
    throw new Error("Chỉ có thể hoàn thành thách thức đang active");
  }

  this.status = "completed";
  this.completion = {
    completedAt: new Date(),
    finalSaving: mongoose.Types.Decimal128.fromString(finalSaving.toFixed(2)),
    totalPointsEarned,
    badgesEarned: badgesEarned || [],
  };

  // Update final stats
  this.currentStats.completionPercentage = 100;
  this.currentStats.pointsEarned = totalPointsEarned;
};

UserChallengeSchema.methods.failChallenge = function (reason) {
  if (this.status !== "active") {
    throw new Error("Chỉ có thể fail thách thức đang active");
  }

  this.status = "failed";
  if (reason) {
    this.addNote(`Thách thức thất bại: ${reason}`);
  }
};

UserChallengeSchema.methods.abandonChallenge = function (reason) {
  if (!["available", "active"].includes(this.status)) {
    throw new Error("Không thể abandon thách thức đã hoàn thành hoặc thất bại");
  }

  this.status = "abandoned";
  if (reason) {
    this.addNote(`Từ bỏ thách thức: ${reason}`);
  }
};

UserChallengeSchema.methods.getDaysRemaining = function () {
  if (this.status !== "active" || !this.endDate) return 0;

  const now = new Date();
  const diffTime = this.endDate - now;
  return Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
};

UserChallengeSchema.methods.getProgress = function () {
  return {
    status: this.status,
    daysCompleted: this.currentStats.daysCompleted,
    totalDays: this.currentStats.totalDays,
    completionPercentage: this.currentStats.completionPercentage,
    totalSaved: parseFloat(this.currentStats.totalSaved.toString()),
    pointsEarned: this.currentStats.pointsEarned,
    currentStreak: this.currentStats.currentStreak,
    onTrack: this.currentStats.onTrack,
    daysRemaining: this.getDaysRemaining(),
    milestonesCount: this.milestonesAchieved.length,
  };
};

// Pre-save middleware
UserChallengeSchema.pre("save", function (next) {
  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }

  next();
});

// Static Methods
UserChallengeSchema.statics.findUserActiveChallenges = function (userId) {
  return this.find({
    userId,
    status: "active",
  })
    .populate("challengeId")
    .sort({ startDate: -1 });
};

UserChallengeSchema.statics.findUserCompletedChallenges = function (
  userId,
  limit = 10
) {
  return this.find({
    userId,
    status: "completed",
  })
    .populate("challengeId")
    .sort({ "completion.completedAt": -1 })
    .limit(limit);
};

UserChallengeSchema.statics.getChallengeLeaderboard = function (
  challengeId,
  limit = 100
) {
  return this.find({
    challengeId,
    status: { $in: ["active", "completed"] },
    "social.allowRankingDisplay": true,
  })
    .populate("userId", "profile.name profile.avatar")
    .sort({
      "currentStats.totalSaved": -1,
      "currentStats.completionPercentage": -1,
    })
    .limit(limit);
};

UserChallengeSchema.statics.getUserChallengeStats = function (userId) {
  return this.aggregate([
    {
      $match: { userId: new mongoose.Types.ObjectId(userId) },
    },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
        totalSaved: {
          $sum: { $toDouble: "$currentStats.totalSaved" },
        },
        totalPoints: {
          $sum: "$currentStats.pointsEarned",
        },
      },
    },
  ]);
};

UserChallengeSchema.statics.findExpiredActiveChallenges = function () {
  const now = new Date();
  return this.find({
    status: "active",
    endDate: { $lt: now },
  }).populate("challengeId");
};

const UserChallenge = mongoose.model("UserChallenge", UserChallengeSchema);

export default UserChallenge;
