import cron from "node-cron";
import SubscriptionService from "../services/subscriptionService.js";
import UsageLimit from "../models/UsageLimit.js";

/**
 * Subscription Cron Jobs
 *
 * Handles automated tasks for subscription management:
 * 1. Daily reset of usage limits (midnight VN time)
 * 2. Hourly check for expired subscriptions
 * 3. Daily cleanup of old usage records
 */

class SubscriptionJobs {
  constructor() {
    this.jobs = [];
  }

  /**
   * Initialize all subscription jobs
   */
  init() {
    console.log("🔧 Initializing subscription cron jobs...");

    // Job 1: Daily usage reset at midnight Vietnam time (UTC+7)
    // Runs at 00:00 VN time = 17:00 UTC (previous day)
    const dailyResetJob = cron.schedule(
      "0 17 * * *", // 00:00 VN time
      async () => {
        console.log("\n⏰ [Subscription Jobs] Running daily usage reset...");
        try {
          const result = await UsageLimit.resetDailyLimits();
          console.log(
            `✅ [Subscription Jobs] Daily usage reset complete:`,
            result
          );
        } catch (error) {
          console.error(
            "❌ [Subscription Jobs] Daily usage reset failed:",
            error
          );
        }
      },
      {
        scheduled: true,
        timezone: "Asia/Ho_Chi_Minh",
      }
    );

    // Job 2: Hourly subscription expiry check
    const expiryCheckJob = cron.schedule(
      "0 * * * *", // Every hour at minute 0
      async () => {
        console.log(
          "\n⏰ [Subscription Jobs] Running subscription expiry check..."
        );
        try {
          const result = await SubscriptionService.autoExpireSubscriptions();
          if (result.expiredCount > 0) {
            console.log(
              `✅ [Subscription Jobs] Expired ${result.expiredCount} subscription(s)`
            );
          } else {
            console.log(
              "✅ [Subscription Jobs] No expired subscriptions found"
            );
          }
        } catch (error) {
          console.error(
            "❌ [Subscription Jobs] Subscription expiry check failed:",
            error
          );
        }
      },
      {
        scheduled: true,
        timezone: "Asia/Ho_Chi_Minh",
      }
    );

    // Job 3: Daily cleanup of old usage records (runs at 2 AM VN time)
    const cleanupJob = cron.schedule(
      "0 19 * * *", // 02:00 VN time = 19:00 UTC
      async () => {
        console.log(
          "\n⏰ [Subscription Jobs] Running old usage records cleanup..."
        );
        try {
          // Delete records older than 30 days
          const thirtyDaysAgo = new Date();
          thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

          const cutoffDate = UsageLimit.getCurrentDateVN.call(
            {},
            thirtyDaysAgo
          );
          const result = await UsageLimit.deleteMany({
            date: { $lt: cutoffDate },
          });

          console.log(
            `✅ [Subscription Jobs] Cleanup complete: Deleted ${result.deletedCount} old records (before ${cutoffDate})`
          );
        } catch (error) {
          console.error(
            "❌ [Subscription Jobs] Cleanup failed:",
            error
          );
        }
      },
      {
        scheduled: true,
        timezone: "Asia/Ho_Chi_Minh",
      }
    );

    // Job 4: Weekly subscription reminder (every Monday at 9 AM VN time)
    const weeklyReminderJob = cron.schedule(
      "0 2 * * 1", // Monday 09:00 VN time = 02:00 UTC
      async () => {
        console.log(
          "\n⏰ [Subscription Jobs] Running weekly subscription reminder..."
        );
        try {
          // Find premium users expiring within 7 days
          const sevenDaysLater = new Date();
          sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);

          const User = (await import("../models/User.js")).default;
          const expiringUsers = await User.find({
            "subscription.tier": "premium",
            "subscription.status": "active",
            "subscription.expiryDate": {
              $gte: new Date(),
              $lte: sevenDaysLater,
            },
          }).select("email profile.name subscription.expiryDate");

          console.log(
            `📧 [Subscription Jobs] Found ${expiringUsers.length} user(s) with subscriptions expiring within 7 days`
          );

          // TODO: Send email notifications (implement when email service is ready)
          // For now, just log
          for (const user of expiringUsers) {
            const daysLeft = Math.ceil(
              (user.subscription.expiryDate - new Date()) /
                (1000 * 60 * 60 * 24)
            );
            console.log(
              `  - ${user.email}: ${daysLeft} days until expiry`
            );
          }
        } catch (error) {
          console.error(
            "❌ [Subscription Jobs] Weekly reminder failed:",
            error
          );
        }
      },
      {
        scheduled: true,
        timezone: "Asia/Ho_Chi_Minh",
      }
    );

    // Store jobs for graceful shutdown
    this.jobs.push({
      name: "Daily Usage Reset",
      cron: dailyResetJob,
      schedule: "0 17 * * * (00:00 VN time)",
    });

    this.jobs.push({
      name: "Hourly Expiry Check",
      cron: expiryCheckJob,
      schedule: "0 * * * * (every hour)",
    });

    this.jobs.push({
      name: "Daily Cleanup",
      cron: cleanupJob,
      schedule: "0 19 * * * (02:00 VN time)",
    });

    this.jobs.push({
      name: "Weekly Reminder",
      cron: weeklyReminderJob,
      schedule: "0 2 * * 1 (Monday 09:00 VN time)",
    });

    console.log(
      `✅ Subscription cron jobs initialized (${this.jobs.length} jobs):`
    );
    this.jobs.forEach((job) => {
      console.log(`   - ${job.name}: ${job.schedule}`);
    });
  }

  /**
   * Stop all jobs (for graceful shutdown)
   */
  stopAll() {
    console.log("\n🛑 Stopping subscription cron jobs...");
    this.jobs.forEach((job) => {
      job.cron.stop();
      console.log(`   - Stopped: ${job.name}`);
    });
  }

  /**
   * Get job status
   */
  getStatus() {
    return this.jobs.map((job) => ({
      name: job.name,
      schedule: job.schedule,
      running: job.cron.running,
    }));
  }

  /**
   * Manually trigger daily reset (for testing)
   */
  async manualDailyReset() {
    console.log("🔧 [Manual Trigger] Running daily usage reset...");
    try {
      const result = await UsageLimit.resetDailyLimits();
      console.log("✅ [Manual Trigger] Daily usage reset complete:", result);
      return result;
    } catch (error) {
      console.error("❌ [Manual Trigger] Daily usage reset failed:", error);
      throw error;
    }
  }

  /**
   * Manually trigger expiry check (for testing)
   */
  async manualExpiryCheck() {
    console.log("🔧 [Manual Trigger] Running subscription expiry check...");
    try {
      const result = await SubscriptionService.autoExpireSubscriptions();
      console.log(
        "✅ [Manual Trigger] Subscription expiry check complete:",
        result
      );
      return result;
    } catch (error) {
      console.error(
        "❌ [Manual Trigger] Subscription expiry check failed:",
        error
      );
      throw error;
    }
  }
}

// Export singleton instance
const subscriptionJobs = new SubscriptionJobs();

export default subscriptionJobs;
