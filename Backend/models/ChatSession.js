import mongoose from "mongoose";

const chatSessionSchema = new mongoose.Schema(
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
    messages: [
      {
        role: {
          type: String,
          enum: ["user", "assistant", "system"],
          required: true,
        },
        content: {
          type: String,
          required: true,
        },
        timestamp: {
          type: Date,
          default: Date.now,
        },
        tokensUsed: Number,
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
    messageCount: {
      type: Number,
      default: 0,
    },
    totalTokensUsed: {
      type: Number,
      default: 0,
    },
    systemMessage: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
chatSessionSchema.index({ userId: 1, isActive: 1 });
chatSessionSchema.index({ sessionId: 1 });
chatSessionSchema.index({ lastMessageAt: -1 });

export default mongoose.model("ChatSession", chatSessionSchema);
