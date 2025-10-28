import cron from "node-cron";
import NotificationService from "./notificationService.js";
import { User, Expense, Income, Budget, SavingsGoal } from "../models/index.js";
import logger from "../middleware/logger.js";

/**
 * Notification Scheduler Job - Quản lý các scheduled notifications
 * Tương tự SessionCleanupJob.js nhưng cho notifications
 */
class NotificationSchedulerJob {
  constructor() {
    this.isRunning = false;
    this.lastRun = null;
    this.stats = {
      totalRuns: 0,
      notificationsSent: 0,
      lastRunNotifications: 0,
      errors: 0,
    };
  }

  /**
   * Khởi động tất cả cron jobs
   */
  start() {
    // Daily 21:00 - Nhắc ghi chi tiêu
    cron.schedule("0 21 * * *", async () => {
      await this.sendDailyExpenseReminder();
    });

    // Daily 08:00 - Morning summary
    cron.schedule("0 8 * * *", async () => {
      await this.sendMorningSummary();
    });

    // Sunday 08:00 - Weekly report
    cron.schedule("0 8 * * 0", async () => {
      await this.sendWeeklyReport();
    });

    // Monthly 1st 09:00 - Monthly budget summary
    cron.schedule("0 9 1 * *", async () => {
      await this.sendMonthlyReport();
    });

    // Every 6 hours - Check bill reminders
    cron.schedule("0 */6 * * *", async () => {
      await this.checkBillReminders();
    });

    // Daily 10:00 - Check savings goal reminders
    cron.schedule("0 10 * * *", async () => {
      await this.checkSavingsGoalReminders();
    });

    // Run once on startup after 2 minutes
    setTimeout(() => {
      this.sendDailyExpenseReminder();
    }, 120000);

    logger.info("Notification scheduler job started", {
      schedules: [
        "Daily 21:00 - Expense reminder",
        "Daily 08:00 - Morning summary",
        "Sunday 08:00 - Weekly report",
        "Monthly 1st 09:00 - Monthly report",
        "Every 6 hours - Bill reminders",
        "Daily 10:00 - Savings reminders",
      ],
    });
  }

  /**
   * Nhắc ghi chi tiêu hàng ngày
   */
  async sendDailyExpenseReminder() {
    if (this.isRunning) {
      logger.warn("Notification scheduler already running, skipping");
      return;
    }

    this.isRunning = true;
    const startTime = new Date();

    try {
      logger.info("Starting daily expense reminder", {
        runNumber: this.stats.totalRuns + 1,
        lastRun: this.lastRun,
      });

      // Lấy tất cả users active
      const users = await User.find({ isActive: true }).select("_id email");

      let notificationsSent = 0;

      for (const user of users) {
        try {
          await NotificationService.triggerDailyExpenseReminder(user._id);
          notificationsSent++;
        } catch (error) {
          logger.error("Failed to send daily reminder to user", {
            userId: user._id,
            error: error.message,
          });
        }
      }

      this.stats.totalRuns++;
      this.stats.lastRunNotifications = notificationsSent;
      this.stats.notificationsSent += notificationsSent;
      this.lastRun = startTime;

      const duration = new Date() - startTime;
      logger.info("Daily expense reminder completed", {
        usersProcessed: users.length,
        notificationsSent,
        duration: `${duration}ms`,
        totalNotifications: this.stats.notificationsSent,
      });
    } catch (error) {
      this.stats.errors++;
      logger.error("Daily expense reminder failed", {
        error: error.message,
        stack: error.stack,
        runNumber: this.stats.totalRuns + 1,
        totalErrors: this.stats.errors,
      });
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * Morning summary cho users có active budgets
   */
  async sendMorningSummary() {
    try {
      logger.info("Starting morning summary");

      // Lấy users có active budgets
      const usersWithBudgets = await User.aggregate([
        {
          $lookup: {
            from: "budgets",
            localField: "_id",
            foreignField: "userId",
            as: "budgets",
          },
        },
        {
          $match: {
            "budgets.isActive": true,
            isActive: true,
          },
        },
        {
          $project: { _id: 1, email: 1 },
        },
      ]);

      let notificationsSent = 0;

      for (const user of usersWithBudgets) {
        try {
          // Lấy thống kê ngày hôm qua
          const yesterday = new Date();
          yesterday.setDate(yesterday.getDate() - 1);
          yesterday.setHours(0, 0, 0, 0);
          const today = new Date();
          today.setHours(0, 0, 0, 0);

          const [yesterdayExpenses, yesterdayIncomes] = await Promise.all([
            Expense.find({
              userId: user._id,
              date: { $gte: yesterday, $lt: today },
            }).select("amount category"),
            Income.find({
              userId: user._id,
              date: { $gte: yesterday, $lt: today },
            }).select("amount"),
          ]);

          const totalExpenses = yesterdayExpenses.reduce(
            (sum, exp) => sum + exp.amount,
            0
          );
          const totalIncomes = yesterdayIncomes.reduce(
            (sum, inc) => sum + inc.amount,
            0
          );

          if (totalExpenses > 0 || totalIncomes > 0) {
            await NotificationService.createNotification(
              user._id,
              "morning_summary",
              {
                totalExpenses,
                totalIncomes,
                netAmount: totalIncomes - totalExpenses,
                expenseCount: yesterdayExpenses.length,
                incomeCount: yesterdayIncomes.length,
              },
              {
                title: "🌅 Tóm tắt sáng",
                message: `Hôm qua bạn chi ${totalExpenses.toLocaleString()}đ, thu ${totalIncomes.toLocaleString()}đ. ${
                  totalIncomes > totalExpenses
                    ? "Tiết kiệm được"
                    : "Chi vượt thu"
                } ${Math.abs(totalIncomes - totalExpenses).toLocaleString()}đ.`,
                category: "insights",
                priority: "normal",
              }
            );
            notificationsSent++;
          }
        } catch (error) {
          logger.error("Failed to send morning summary to user", {
            userId: user._id,
            error: error.message,
          });
        }
      }

      logger.info("Morning summary completed", {
        usersProcessed: usersWithBudgets.length,
        notificationsSent,
      });
    } catch (error) {
      logger.error("Morning summary failed", {
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * Báo cáo tuần
   */
  async sendWeeklyReport() {
    try {
      logger.info("Starting weekly report");

      const users = await User.find({ isActive: true }).select("_id email");
      let notificationsSent = 0;

      for (const user of users) {
        try {
          await NotificationService.triggerWeeklyReport(user._id);
          notificationsSent++;
        } catch (error) {
          logger.error("Failed to send weekly report to user", {
            userId: user._id,
            error: error.message,
          });
        }
      }

      logger.info("Weekly report completed", {
        usersProcessed: users.length,
        notificationsSent,
      });
    } catch (error) {
      logger.error("Weekly report failed", {
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * Báo cáo tháng
   */
  async sendMonthlyReport() {
    try {
      logger.info("Starting monthly report");

      const users = await User.find({ isActive: true }).select("_id email");
      let notificationsSent = 0;

      for (const user of users) {
        try {
          // Lấy thống kê tháng trước
          const lastMonth = new Date();
          lastMonth.setMonth(lastMonth.getMonth() - 1);
          const startOfMonth = new Date(
            lastMonth.getFullYear(),
            lastMonth.getMonth(),
            1
          );
          const endOfMonth = new Date(
            lastMonth.getFullYear(),
            lastMonth.getMonth() + 1,
            0
          );

          const [monthlyExpenses, monthlyIncomes, activeBudgets] =
            await Promise.all([
              Expense.find({
                userId: user._id,
                date: { $gte: startOfMonth, $lte: endOfMonth },
              }).select("amount category"),
              Income.find({
                userId: user._id,
                date: { $gte: startOfMonth, $lte: endOfMonth },
              }).select("amount"),
              Budget.find({
                userId: user._id,
                isActive: true,
              }).select("name totalAmount spentAmount"),
            ]);

          const totalExpenses = monthlyExpenses.reduce(
            (sum, exp) => sum + exp.amount,
            0
          );
          const totalIncomes = monthlyIncomes.reduce(
            (sum, inc) => sum + inc.amount,
            0
          );
          const netAmount = totalIncomes - totalExpenses;

          // Phân tích budget performance
          const budgetPerformance = activeBudgets.map((budget) => ({
            name: budget.name,
            totalAmount: budget.totalAmount,
            spentAmount: budget.spentAmount,
            percentage: (budget.spentAmount / budget.totalAmount) * 100,
            status:
              budget.spentAmount > budget.totalAmount
                ? "exceeded"
                : budget.spentAmount / budget.totalAmount > 0.8
                ? "warning"
                : "good",
          }));

          await NotificationService.createNotification(
            user._id,
            "monthly_report",
            {
              totalExpenses,
              totalIncomes,
              netAmount,
              budgetPerformance,
              expenseCount: monthlyExpenses.length,
              incomeCount: monthlyIncomes.length,
              budgetCount: activeBudgets.length,
            },
            {
              title: "📊 Báo cáo tháng",
              message: `Tháng trước bạn chi ${totalExpenses.toLocaleString()}đ, thu ${totalIncomes.toLocaleString()}đ. ${
                netAmount > 0 ? "Tiết kiệm được" : "Chi vượt thu"
              } ${Math.abs(netAmount).toLocaleString()}đ.`,
              category: "insights",
              priority: "normal",
            }
          );
          notificationsSent++;
        } catch (error) {
          logger.error("Failed to send monthly report to user", {
            userId: user._id,
            error: error.message,
          });
        }
      }

      logger.info("Monthly report completed", {
        usersProcessed: users.length,
        notificationsSent,
      });
    } catch (error) {
      logger.error("Monthly report failed", {
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * Kiểm tra hóa đơn sắp đến hạn
   */
  async checkBillReminders() {
    try {
      logger.info("Checking bill reminders");

      // Tìm recurring expenses (hóa đơn định kỳ)
      // Giả sử có field isRecurring và nextDueDate trong Expense model
      const upcomingBills = await Expense.find({
        isRecurring: true,
        nextDueDate: {
          $gte: new Date(),
          $lte: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // Trong 3 ngày tới
        },
      }).populate("userId", "email");

      let notificationsSent = 0;

      for (const bill of upcomingBills) {
        try {
          const daysUntilDue = Math.ceil(
            (bill.nextDueDate - new Date()) / (24 * 60 * 60 * 1000)
          );

          await NotificationService.triggerBillReminder(bill.userId._id, {
            billName: bill.title || bill.description,
            dueDate: bill.nextDueDate,
            amount: bill.amount,
            daysUntilDue,
          });
          notificationsSent++;
        } catch (error) {
          logger.error("Failed to send bill reminder", {
            billId: bill._id,
            userId: bill.userId._id,
            error: error.message,
          });
        }
      }

      logger.info("Bill reminders completed", {
        billsChecked: upcomingBills.length,
        notificationsSent,
      });
    } catch (error) {
      logger.error("Bill reminders failed", {
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * Kiểm tra nhắc nhở mục tiêu tiết kiệm
   */
  async checkSavingsGoalReminders() {
    try {
      logger.info("Checking savings goal reminders");

      const users = await User.find({ isActive: true }).select("_id email");
      let notificationsSent = 0;

      for (const user of users) {
        try {
          // Lấy savings goals active
          const savingsGoals = await SavingsGoal.find({
            userId: user._id,
            status: "active",
          });

          for (const goal of savingsGoals) {
            // Kiểm tra nếu chưa đóng góp trong tháng này
            const startOfMonth = new Date();
            startOfMonth.setDate(1);
            startOfMonth.setHours(0, 0, 0, 0);

            const contributionsThisMonth = await Expense.find({
              userId: user._id,
              category: "savings",
              description: { $regex: goal.name, $options: "i" },
              date: { $gte: startOfMonth },
            });

            if (contributionsThisMonth.length === 0) {
              // Nhắc nhở đóng góp
              await NotificationService.createNotification(
                user._id,
                "savings_reminder",
                {
                  goalId: goal._id,
                  goalName: goal.name,
                  targetAmount: goal.targetAmount,
                  currentAmount: goal.currentAmount,
                  progress: (goal.currentAmount / goal.targetAmount) * 100,
                },
                {
                  title: "💰 Nhắc tiết kiệm",
                  message: `Bạn chưa đóng góp vào mục tiêu "${
                    goal.name
                  }" tháng này. Tiến độ hiện tại: ${(
                    (goal.currentAmount / goal.targetAmount) *
                    100
                  ).toFixed(1)}%`,
                  category: "savings",
                  priority: "normal",
                  requiresAction: true,
                  actionButtons: [
                    {
                      text: "Đóng góp ngay",
                      action: "add_savings_contribution",
                      actionData: { goalId: goal._id },
                    },
                    {
                      text: "Xem chi tiết",
                      action: "view_savings_goal",
                      actionData: { goalId: goal._id },
                    },
                  ],
                }
              );
              notificationsSent++;
            }
          }
        } catch (error) {
          logger.error("Failed to check savings reminders for user", {
            userId: user._id,
            error: error.message,
          });
        }
      }

      logger.info("Savings goal reminders completed", {
        usersProcessed: users.length,
        notificationsSent,
      });
    } catch (error) {
      logger.error("Savings goal reminders failed", {
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * Lấy thống kê scheduler
   */
  getStats() {
    return {
      ...this.stats,
      isRunning: this.isRunning,
      lastRun: this.lastRun,
      uptime: this.lastRun ? new Date() - this.lastRun : null,
    };
  }

  /**
   * Trigger manual run (for testing/admin)
   */
  async manualRun(type = "daily") {
    logger.info(`Manual notification run triggered: ${type}`);

    switch (type) {
      case "daily":
        await this.sendDailyExpenseReminder();
        break;
      case "weekly":
        await this.sendWeeklyReport();
        break;
      case "monthly":
        await this.sendMonthlyReport();
        break;
      case "bills":
        await this.checkBillReminders();
        break;
      case "savings":
        await this.checkSavingsGoalReminders();
        break;
      default:
        throw new Error(`Unknown notification type: ${type}`);
    }

    return this.getStats();
  }

  /**
   * Dừng scheduler (for graceful shutdown)
   */
  stop() {
    logger.info("Stopping notification scheduler job");
    this.isRunning = false;
  }
}

// Create singleton instance
const notificationSchedulerJob = new NotificationSchedulerJob();
export default notificationSchedulerJob;
