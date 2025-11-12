import mongoose from "mongoose";

const FeedbackSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null, // Allow anonymous feedback
    },
    name: {
      type: String,
      required: [true, "Tên là bắt buộc"],
      trim: true,
      maxlength: [100, "Tên không được vượt quá 100 ký tự"],
    },
    email: {
      type: String,
      required: [true, "Email là bắt buộc"],
      trim: true,
      lowercase: true,
      match: [
        /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/,
        "Email không hợp lệ",
      ],
    },
    type: {
      type: String,
      required: [true, "Loại phản hồi là bắt buộc"],
      enum: {
        values: ["suggestion", "bug", "compliment", "complaint"],
        message: "Loại phản hồi không hợp lệ",
      },
    },
    rating: {
      type: Number,
      required: [true, "Đánh giá là bắt buộc"],
      min: [1, "Đánh giá phải từ 1 đến 5"],
      max: [5, "Đánh giá phải từ 1 đến 5"],
    },
    content: {
      type: String,
      required: [true, "Nội dung phản hồi là bắt buộc"],
      trim: true,
      minlength: [10, "Nội dung phải có ít nhất 10 ký tự"],
      maxlength: [2000, "Nội dung không được vượt quá 2000 ký tự"],
    },
    status: {
      type: String,
      enum: ["pending", "reviewed", "resolved", "archived"],
      default: "pending",
    },
    adminResponse: {
      message: {
        type: String,
        trim: true,
        maxlength: [1000, "Phản hồi không được vượt quá 1000 ký tự"],
      },
      respondedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      respondedAt: {
        type: Date,
      },
    },
    deviceInfo: {
      platform: String, // ios, android, web
      version: String,
      osVersion: String,
    },
    attachments: [
      {
        url: String,
        type: String, // image, video, file
        name: String,
      },
    ],
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Indexes for better query performance
FeedbackSchema.index({ userId: 1, createdAt: -1 });
FeedbackSchema.index({ type: 1, status: 1 });
FeedbackSchema.index({ email: 1 });
FeedbackSchema.index({ status: 1, createdAt: -1 });

// Virtual for feedback age
FeedbackSchema.virtual("age").get(function () {
  return Math.floor((Date.now() - this.createdAt) / (1000 * 60 * 60 * 24)); // days
});

// Method to get feedback type label
FeedbackSchema.methods.getTypeLabel = function () {
  const labels = {
    suggestion: "Đề xuất tính năng",
    bug: "Báo lỗi",
    compliment: "Khen ngợi",
    complaint: "Phàn nàn",
  };
  return labels[this.type] || this.type;
};

// Method to get rating text
FeedbackSchema.methods.getRatingText = function () {
  const texts = {
    1: "Rất không hài lòng",
    2: "Không hài lòng",
    3: "Bình thường",
    4: "Hài lòng",
    5: "Rất hài lòng",
  };
  return texts[this.rating] || "";
};

// Static method to get feedback statistics
FeedbackSchema.statics.getStatistics = async function () {
  const stats = await this.aggregate([
    {
      $group: {
        _id: "$type",
        count: { $sum: 1 },
        avgRating: { $avg: "$rating" },
      },
    },
  ]);

  const statusStats = await this.aggregate([
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);

  return {
    byType: stats,
    byStatus: statusStats,
    total: await this.countDocuments(),
  };
};

const Feedback = mongoose.model("Feedback", FeedbackSchema);

export default Feedback;
