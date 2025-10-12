import cron from "node-cron";
import SessionService from "../services/SessionService.js";
import logger from "../middleware/logger.js";
class SessionCleanupJob {
  constructor() {
    this.isRunning = false;
    this.lastRun = null;
    this.stats = {
      totalRuns: 0,
      totalCleaned: 0,
      lastCleanedCount: 0,
      errors: 0,
    };
  }
  // Start the cleanup job
  start() {
    // Run every 30 minutes
    cron.schedule("*/30 * * * *", async () => {
      await this.runCleanup();
    });
    // Also run every hour as backup
    cron.schedule("0 * * * *", async () => {
      if (!this.isRunning) {
        await this.runCleanup();
      }
    });
    // Run once on startup after 1 minute
    setTimeout(() => {
      this.runCleanup();
    }, 60000);
    logger.info("Session cleanup job scheduled", {
      schedule: "Every 30 minutes",
      nextRun: "30 minutes from now",
    });
  }
  // Run the cleanup process
  async runCleanup() {
    if (this.isRunning) {
      logger.warn("Session cleanup already running, skipping");
      return;
    }
    this.isRunning = true;
    const startTime = new Date();
    try {
      logger.info("Starting session cleanup", {
        runNumber: this.stats.totalRuns + 1,
        lastRun: this.lastRun,
      });
      const cleanedCount = await SessionService.cleanupExpiredSessions();
      this.stats.totalRuns++;
      this.stats.lastCleanedCount = cleanedCount;
      this.stats.totalCleaned += cleanedCount;
      this.lastRun = startTime;
      const duration = new Date() - startTime;
      logger.info("Session cleanup completed", {
        cleanedCount,
        duration: `${duration}ms`,
        totalCleaned: this.stats.totalCleaned,
        totalRuns: this.stats.totalRuns,
      });
      // Log warning if cleanup took too long
      if (duration > 5000) {
        logger.warn("Session cleanup took longer than expected", {
          duration: `${duration}ms`,
          cleanedCount,
        });
      }
    } catch (error) {
      this.stats.errors++;
      logger.error("Session cleanup failed", {
        error: error.message,
        stack: error.stack,
        runNumber: this.stats.totalRuns + 1,
        totalErrors: this.stats.errors,
      });
      // If cleanup fails repeatedly, log critical error
      if (this.stats.errors >= 5 && this.stats.errors % 5 === 0) {
        logger.error("Multiple session cleanup failures detected", {
          totalErrors: this.stats.errors,
          totalRuns: this.stats.totalRuns,
          errorRate:
            ((this.stats.errors / (this.stats.totalRuns + 1)) * 100).toFixed(
              2
            ) + "%",
        });
      }
    } finally {
      this.isRunning = false;
    }
  }
  // Get cleanup statistics
  getStats() {
    return {
      ...this.stats,
      isRunning: this.isRunning,
      lastRun: this.lastRun,
      uptime: this.lastRun ? new Date() - this.lastRun : null,
    };
  }
  // Manual cleanup trigger (for testing/admin)
  async manualCleanup() {
    logger.info("Manual session cleanup triggered");
    await this.runCleanup();
    return this.getStats();
  }
  // Stop the cleanup job (for graceful shutdown)
  stop() {
    logger.info("Stopping session cleanup job");
    this.isRunning = false;
    // Note: node-cron doesn't provide easy way to stop specific jobs
    // But setting isRunning = false will prevent execution
  }
}
// Create singleton instance
const sessionCleanupJob = new SessionCleanupJob();
export default sessionCleanupJob;