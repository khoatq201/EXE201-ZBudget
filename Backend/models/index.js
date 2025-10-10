import mongoose from "mongoose";

// Import all models
import User from "./User.js";
import Expense from "./Expense.js";
import Income from "./Income.js";
import Budget from "./Budget.js";
import Challenge from "./Challenge.js";
import UserChallenge from "./UserChallenge.js";
import Group from "./Group.js";
import Notification from "./Notification.js";
import Session from "./Session.js";
import SavingsGoal from "./SavingsGoal.js";

// Database connection configuration
const connectDB = async () => {
  try {
    const mongoURI =
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget";

    const options = {
      // Connection pool options
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,

      // Other options
      family: 4, // Use IPv4, skip trying IPv6
    };

    const conn = await mongoose.connect(mongoURI, options);

    console.log(
      `✅ MongoDB Connected: ${conn.connection.host}:${conn.connection.port}/${conn.connection.name}`
    );

    // Connection event listeners
    mongoose.connection.on("error", (err) => {
      console.error("❌ MongoDB connection error:", err);
    });

    mongoose.connection.on("disconnected", () => {
      console.warn("⚠️ MongoDB disconnected");
    });

    mongoose.connection.on("reconnected", () => {
      console.log("✅ MongoDB reconnected");
    });

    // Graceful shutdown
    process.on("SIGINT", async () => {
      try {
        await mongoose.connection.close();
        console.log("📴 MongoDB connection closed through app termination");
        process.exit(0);
      } catch (err) {
        console.error("❌ Error closing MongoDB connection:", err);
        process.exit(1);
      }
    });

    return conn;
  } catch (error) {
    console.error("❌ MongoDB connection failed:", error.message);
    process.exit(1);
  }
};

// Database utilities
const dbUtils = {
  // Drop all collections (use with caution - for development only)
  async dropAllCollections() {
    if (process.env.NODE_ENV === "production") {
      throw new Error("Cannot drop collections in production environment");
    }

    const collections = await mongoose.connection.db.collections();

    for (const collection of collections) {
      await collection.drop();
    }

    console.log("🗑️ All collections dropped");
  },

  // Create indexes for all models
  async createIndexes() {
    console.log("📊 Creating database indexes...");

    const models = [
      User,
      Expense,
      Income,
      Budget,
      Challenge,
      UserChallenge,
      Group,
      Notification,
      SavingsGoal,
    ];

    for (const model of models) {
      try {
        await model.createIndexes();
        console.log(`✅ Indexes created for ${model.modelName}`);
      } catch (error) {
        console.error(
          `❌ Error creating indexes for ${model.modelName}:`,
          error.message
        );
      }
    }

    console.log("📊 Database indexes creation completed");
  },

  // Get database statistics
  async getStats() {
    const stats = await mongoose.connection.db.stats();
    const collections = await mongoose.connection.db.collections();

    const collectionStats = {};
    for (const collection of collections) {
      try {
        const collectionStat = await collection.stats();
        collectionStats[collection.collectionName] = {
          documents: collectionStat.count,
          size: collectionStat.size,
          avgObjSize: collectionStat.avgObjSize,
          indexes: collectionStat.nindexes,
        };
      } catch (error) {
        // Collection might be empty
        collectionStats[collection.collectionName] = {
          documents: 0,
          size: 0,
          avgObjSize: 0,
          indexes: 0,
        };
      }
    }

    return {
      database: {
        name: mongoose.connection.name,
        collections: stats.collections,
        dataSize: stats.dataSize,
        indexSize: stats.indexSize,
        totalSize: stats.dataSize + stats.indexSize,
      },
      collections: collectionStats,
    };
  },

  // Health check
  async healthCheck() {
    try {
      const state = mongoose.connection.readyState;
      const stateNames = {
        0: "disconnected",
        1: "connected",
        2: "connecting",
        3: "disconnecting",
      };

      const ping = await mongoose.connection.db.admin().ping();

      return {
        status: stateNames[state],
        connected: state === 1,
        ping: ping.ok === 1,
        host: mongoose.connection.host,
        port: mongoose.connection.port,
        database: mongoose.connection.name,
        timestamp: new Date(),
      };
    } catch (error) {
      return {
        status: "error",
        connected: false,
        ping: false,
        error: error.message,
        timestamp: new Date(),
      };
    }
  },
};

// Model validation utilities
const validateModels = {
  // Validate User data
  async validateUserData(userData) {
    const user = new User(userData);
    await user.validate();
    return user;
  },

  // Validate Expense data
  async validateExpenseData(expenseData) {
    const expense = new Expense(expenseData);
    await expense.validate();
    return expense;
  },

  // Validate Budget data
  async validateBudgetData(budgetData) {
    const budget = new Budget(budgetData);
    await budget.validate();
    return budget;
  },

  // Validate Challenge data
  async validateChallengeData(challengeData) {
    const challenge = new Challenge(challengeData);
    await challenge.validate();
    return challenge;
  },
};

// Transaction helpers
const transactions = {
  // Execute operations in transaction
  async withTransaction(operations) {
    const session = await mongoose.startSession();

    try {
      const result = await session.withTransaction(async () => {
        return await operations(session);
      });

      return result;
    } catch (error) {
      throw error;
    } finally {
      await session.endSession();
    }
  },

  // Add expense with budget update
  async addExpenseWithBudgetUpdate(expenseData, session = null) {
    const executeOperation = async (session) => {
      // Create expense
      const [expense] = await Expense.create([expenseData], { session });

      // Update budget if exists
      if (expenseData.budgetId) {
        const budget = await Budget.findById(expenseData.budgetId, null, {
          session,
        });
        if (budget) {
          budget.addExpense(
            parseFloat(expenseData.amount.toString()),
            expenseData.category
          );
          await budget.save({ session });

          // Check for budget alerts
          const alerts = budget.checkAlertThresholds();
          if (alerts.length > 0) {
            // Create notifications for alerts
            const notifications = alerts.map((alert) => ({
              userId: expenseData.userId,
              type: "budget_alert",
              category: "budget",
              title: "⚠️ Cảnh báo ngân sách",
              message: alert.message,
              priority: alert.threshold >= 90 ? "high" : "normal",
              data: {
                budgetId: budget._id,
                budgetName: budget.name,
                category: expenseData.category,
                spentPercentage: alert.threshold,
              },
            }));

            await Notification.create(notifications, { session });
          }
        }
      }

      return expense;
    };

    if (session) {
      return await executeOperation(session);
    } else {
      return await this.withTransaction(executeOperation);
    }
  },

  // Complete challenge milestone
  async completeChallengeMilestone(
    userId,
    challengeId,
    milestoneIndex,
    pointsEarned
  ) {
    return await this.withTransaction(async (session) => {
      // Update user challenge progress
      const userChallenge = await UserChallenge.findOne(
        { userId, challengeId },
        null,
        { session }
      );

      if (!userChallenge) {
        throw new Error("User challenge not found");
      }

      userChallenge.achieveMilestone(milestoneIndex, pointsEarned);
      await userChallenge.save({ session });

      // Update user points
      const user = await User.findById(userId, null, { session });
      if (user) {
        user.addPoints(pointsEarned);
        await user.save({ session });
      }

      // Create notification
      await Notification.create(
        [
          {
            userId,
            type: "milestone_achieved",
            category: "challenge",
            title: "⭐ Đạt mốc quan trọng!",
            message: `Bạn vừa kiếm được ${pointsEarned} điểm!`,
            priority: "high",
            data: {
              challengeId,
              milestoneIndex,
              pointsEarned,
            },
          },
        ],
        { session }
      );

      return userChallenge;
    });
  },
};

// Export all models and utilities
export {
  // Models
  User,
  Expense,
  Income,
  Budget,
  Challenge,
  UserChallenge,
  Group,
  Notification,
  Session,
  SavingsGoal,

  // Database utilities
  connectDB,
  dbUtils,
  validateModels,
  transactions,

  // Mongoose instance
  mongoose,
};

// Default export for convenience
export default {
  User,
  Expense,
  Income,
  Budget,
  Challenge,
  UserChallenge,
  Group,
  Notification,
  Session,
  SavingsGoal,
  connectDB,
  dbUtils,
  validateModels,
  transactions,
  mongoose,
};
