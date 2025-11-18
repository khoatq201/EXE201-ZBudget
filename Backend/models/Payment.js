import mongoose from "mongoose";

/**
 * Payment Schema
 * Tracks premium subscription payment requests
 */
const PaymentSchema = new mongoose.Schema(
  {
    // User reference
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // Payment identification
    referenceCode: {
      type: String,
      required: true,
      unique: true,
      index: true,
      uppercase: true,
      // Format: ZB{M|Y}{userId_last6}{random3} => ZBMY654ABC
    },

    // Payment details
    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    currency: {
      type: String,
      default: "VND",
      enum: ["VND"],
    },

    planType: {
      type: String,
      required: true,
      enum: ["monthly", "yearly"],
      index: true,
    },

    // QR Code and bank info
    qrCodeUrl: {
      type: String,
      required: true,
    },

    bankAccount: {
      accountNumber: {
        type: String,
        required: true,
        default: "1029036158",
      },
      bankName: {
        type: String,
        required: true,
        default: "Vietcombank",
      },
      accountName: {
        type: String,
        required: true,
      },
    },

    // Status tracking
    status: {
      type: String,
      enum: ["pending", "completed", "cancelled", "rejected"],
      default: "pending",
      index: true,
    },

    // Admin approval
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    approvedAt: {
      type: Date,
    },

    rejectedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    rejectedAt: {
      type: Date,
    },

    rejectionReason: {
      type: String,
    },

    // Notes
    notes: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for efficient queries
PaymentSchema.index({ userId: 1, createdAt: -1 });
PaymentSchema.index({ status: 1, createdAt: -1 });

// Methods
PaymentSchema.methods.isPending = function () {
  return this.status === "pending";
};

PaymentSchema.methods.isCompleted = function () {
  return this.status === "completed";
};

PaymentSchema.methods.canCancel = function () {
  return this.status === "pending";
};

// Statics
PaymentSchema.statics.getPendingPayments = async function () {
  return this.find({ status: "pending" })
    .populate("userId", "email profile subscription")
    .sort({ createdAt: -1 });
};

PaymentSchema.statics.getPaymentsByUser = async function (userId) {
  return this.find({ userId })
    .sort({ createdAt: -1 })
    .limit(20);
};

PaymentSchema.statics.getPaymentStats = async function () {
  const stats = await this.aggregate([
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
        totalAmount: { $sum: "$amount" },
      },
    },
  ]);

  return stats;
};

const Payment = mongoose.model("Payment", PaymentSchema);

export default Payment;
