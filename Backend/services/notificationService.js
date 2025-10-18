import Notification from "../models/Notification.js";
import { User, Expense, Budget, Income } from "../models/index.js";
import logger from "../middleware/logger.js";
import mongoose from "mongoose";

/**
 * Notification Service - Xử lý logic tạo và quản lý thông báo
 */
class NotificationService {
  /**
   * Tạo notification mới
   * @param {string} userId - ID của user
   * @param {string} type - Loại notification
   * @param {Object} data - Dữ liệu notification
   * @param {Object} options - Tùy chọn bổ sung
   */
  static async createNotification(userId, type, data = {}, options = {}) {
    try {
      const {
        title,
        message,
        category,
        priority = "normal",
        deliveryMethod = "in_app",
        scheduledFor,
        expiresAt,
        actionButtons = [],
        requiresAction = false,
      } = options;

      const notification = new Notification({
        userId,
        type,
        category: category || this.getCategoryFromType(type),
        title: title || this.getDefaultTitle(type),
        message: message || this.getDefaultMessage(type, data),
        priority,
        deliveryMethod,
        scheduledFor,
        expiresAt,
        data,
        actionButtons,
        requiresAction,
      });

      await notification.save();

      logger.info("Notification created", {
        userId,
        type,
        category: notification.category,
        notificationId: notification._id,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to create notification", {
        userId,
        type,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Lấy notifications của user với filters
   * @param {string} userId - ID của user
   * @param {Object} filters - Bộ lọc
   */
  static async getUserNotifications(userId, filters = {}) {
    try {
      const {
        page = 1,
        limit = 20,
        category,
        isRead,
        priority,
        type,
        sort = "-createdAt",
      } = filters;

      const query = { userId: new mongoose.Types.ObjectId(userId) };

      if (category) query.category = category;
      if (isRead !== undefined) query.isRead = isRead;
      if (priority) query.priority = priority;
      if (type) query.type = type;

      const skip = (parseInt(page) - 1) * parseInt(limit);

      const [notifications, totalCount] = await Promise.all([
        Notification.find(query)
          .sort(sort)
          .skip(skip)
          .limit(parseInt(limit))
          .populate("data.challengeId", "name description")
          .populate("data.budgetId", "name category amount spentAmount")
          .populate("data.expenseId", "amount category description")
          .populate("data.groupId", "name")
          .lean(),
        Notification.countDocuments(query),
      ]);

      return {
        notifications,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalCount,
          hasNextPage: parseInt(page) < Math.ceil(totalCount / parseInt(limit)),
          hasPrevPage: parseInt(page) > 1,
        },
      };
    } catch (error) {
      logger.error("Failed to get user notifications", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Đánh dấu notification đã đọc
   * @param {string} notificationId - ID của notification
   */
  static async markAsRead(notificationId) {
    try {
      const notification = await Notification.findById(notificationId);
      if (!notification) {
        throw new Error("Notification not found");
      }

      notification.markAsRead();
      await notification.save();

      logger.info("Notification marked as read", {
        notificationId,
        userId: notification.userId,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to mark notification as read", {
        notificationId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Đánh dấu tất cả notifications đã đọc
   * @param {string} userId - ID của user
   * @param {string} category - Category cụ thể (optional)
   */
  static async markAllAsRead(userId, category = null) {
    try {
      const result = await Notification.markAllAsReadForUser(userId, category);

      logger.info("All notifications marked as read", {
        userId,
        category,
        modifiedCount: result.modifiedCount,
      });

      return result;
    } catch (error) {
      logger.error("Failed to mark all notifications as read", {
        userId,
        category,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Xóa notification
   * @param {string} notificationId - ID của notification
   */
  static async deleteNotification(notificationId) {
    try {
      const notification = await Notification.findByIdAndDelete(notificationId);
      if (!notification) {
        throw new Error("Notification not found");
      }

      logger.info("Notification deleted", {
        notificationId,
        userId: notification.userId,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to delete notification", {
        notificationId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Lấy số notifications chưa đọc
   * @param {string} userId - ID của user
   */
  static async getUnreadCount(userId) {
    try {
      const count = await Notification.getUnreadCount(userId);
      return count;
    } catch (error) {
      logger.error("Failed to get unread count", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger budget alert khi vượt ngân sách
   * @param {string} userId - ID của user
   * @param {Object} budgetData - Dữ liệu budget
   */
  static async triggerBudgetAlert(userId, budgetData) {
    try {
      const {
        budgetId,
        budgetName,
        category,
        spentPercentage,
        remainingAmount,
      } = budgetData;

      // Kiểm tra xem đã gửi alert cho ngưỡng này chưa
      const existingAlert = await Notification.findOne({
        userId,
        type: "budget_alert",
        "data.budgetId": budgetId,
        "data.spentPercentage": { $gte: Math.floor(spentPercentage / 10) * 10 }, // Làm tròn xuống 10%
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }, // Trong 24h qua
      });

      if (existingAlert) {
        logger.info("Budget alert already sent for this threshold", {
          userId,
          budgetId,
          spentPercentage,
        });
        return;
      }

      let priority = "normal";
      let title = "⚠️ Cảnh báo ngân sách";
      let message = `Bạn đã chi ${spentPercentage.toFixed(
        1
      )}% ngân sách ${category} trong "${budgetName}"`;

      if (spentPercentage >= 100) {
        priority = "urgent";
        title = "🚨 Vượt ngân sách!";
        message = `Bạn đã vượt ngân sách ${category} trong "${budgetName}"! Cần điều chỉnh ngay.`;
      } else if (spentPercentage >= 90) {
        priority = "high";
        title = "⚠️ Ngân sách sắp hết!";
        message = `Bạn đã chi ${spentPercentage.toFixed(
          1
        )}% ngân sách ${category}. Còn lại ${remainingAmount.toLocaleString()}đ.`;
      }

      const notification = await this.createNotification(
        userId,
        "budget_alert",
        {
          budgetId,
          budgetName,
          category,
          spentPercentage,
          remainingAmount,
        },
        {
          title,
          message,
          category: "budget",
          priority,
          requiresAction: spentPercentage >= 100,
          actionButtons:
            spentPercentage >= 100
              ? [
                  {
                    text: "Xem ngân sách",
                    action: "view_budget",
                    actionData: { budgetId },
                  },
                  {
                    text: "Điều chỉnh",
                    action: "dismiss",
                    actionData: {},
                  },
                ]
              : [],
        }
      );

      logger.info("Budget alert triggered", {
        userId,
        budgetId,
        spentPercentage,
        priority,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger budget alert", {
        userId,
        budgetData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger anomaly alert cho chi tiêu bất thường
   * @param {string} userId - ID của user
   * @param {Object} expenseData - Dữ liệu expense
   */
  static async triggerAnomalyAlert(userId, expenseData) {
    try {
      const { expenseId, expenseAmount, category, description } = expenseData;

      // Kiểm tra xem đã gửi alert cho expense này chưa
      const existingAlert = await Notification.findOne({
        userId,
        type: "large_expense_alert",
        "data.expenseId": expenseId,
        createdAt: { $gte: new Date(Date.now() - 2 * 60 * 60 * 1000) }, // Trong 2h qua
      });

      if (existingAlert) {
        logger.info("Anomaly alert already sent for this expense", {
          userId,
          expenseId,
        });
        return;
      }

      const notification = await this.createNotification(
        userId,
        "large_expense_alert",
        {
          expenseId,
          expenseAmount,
          category,
          description,
        },
        {
          title: "🔍 Chi tiêu bất thường",
          message: `Bạn vừa chi ${expenseAmount.toLocaleString()}đ cho ${category}. Đây là giao dịch lớn bất thường.`,
          category: "expense",
          priority: "high",
          requiresAction: true,
          actionButtons: [
            {
              text: "Xem chi tiết",
              action: "view_expense",
              actionData: { expenseId },
            },
            {
              text: "Đã xem",
              action: "mark_read",
              actionData: {},
            },
          ],
        }
      );

      logger.info("Anomaly alert triggered", {
        userId,
        expenseId,
        expenseAmount,
        category,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger anomaly alert", {
        userId,
        expenseData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger expense notification cho chi tiêu thông thường
   * @param {string} userId - ID của user
   * @param {Object} expenseData - Dữ liệu expense
   */
  static async triggerExpenseNotification(userId, expenseData) {
    try {
      const { expenseId, expenseAmount, category, description } = expenseData;

      const notification = await this.createNotification(
        userId,
        "expense_added",
        {
          expenseId,
          expenseAmount,
          expenseCategory: category,
          expenseDescription: description,
        },
        {
          title: "💸 Chi tiêu mới",
          message: `Bạn đã thêm chi tiêu ${
            expenseAmount?.toLocaleString() || 0
          }đ cho ${category}`,
          category: "expense",
          priority: "normal",
          requiresAction: false,
          actionButtons: [
            {
              text: "Xem chi tiết",
              action: "view_expense",
              actionData: { expenseId },
            },
          ],
        }
      );

      logger.info("Expense notification triggered", {
        userId,
        expenseId,
        expenseAmount,
        category,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger expense notification", {
        userId,
        expenseData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger bill reminder
   * @param {string} userId - ID của user
   * @param {Object} billData - Dữ liệu hóa đơn
   */
  static async triggerBillReminder(userId, billData) {
    try {
      const { billName, dueDate, amount, daysUntilDue } = billData;

      let title,
        message,
        priority = "normal";

      if (daysUntilDue <= 0) {
        title = "🚨 Hóa đơn quá hạn!";
        message = `Hóa đơn ${billName} đã quá hạn ${Math.abs(
          daysUntilDue
        )} ngày. Số tiền: ${amount.toLocaleString()}đ`;
        priority = "urgent";
      } else if (daysUntilDue === 1) {
        title = "⚠️ Hóa đơn đến hạn ngày mai";
        message = `Hóa đơn ${billName} đến hạn ngày mai. Số tiền: ${amount.toLocaleString()}đ`;
        priority = "high";
      } else {
        title = "📅 Nhắc nhở hóa đơn";
        message = `Hóa đơn ${billName} đến hạn trong ${daysUntilDue} ngày. Số tiền: ${amount.toLocaleString()}đ`;
      }

      const notification = await this.createNotification(
        userId,
        "bill_reminder",
        {
          billName,
          dueDate,
          amount,
          daysUntilDue,
        },
        {
          title,
          message,
          category: "expense",
          priority,
          requiresAction: daysUntilDue <= 1,
          actionButtons:
            daysUntilDue <= 1
              ? [
                  {
                    text: "Đã trả",
                    action: "mark_bill_paid",
                    actionData: { billName },
                  },
                  {
                    text: "Xem chi tiết",
                    action: "view_bill",
                    actionData: { billName },
                  },
                ]
              : [],
        }
      );

      logger.info("Bill reminder triggered", {
        userId,
        billName,
        daysUntilDue,
        priority,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger bill reminder", {
        userId,
        billData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger daily expense reminder
   * @param {string} userId - ID của user
   */
  static async triggerDailyExpenseReminder(userId) {
    try {
      // Kiểm tra xem user đã ghi expense hôm nay chưa
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todayExpenses = await Expense.countDocuments({
        userId,
        date: { $gte: today, $lt: tomorrow },
      });

      if (todayExpenses > 0) {
        logger.info("User already has expenses today, skipping reminder", {
          userId,
          todayExpenses,
        });
        return;
      }

      // Kiểm tra xem đã gửi reminder hôm nay chưa
      const existingReminder = await Notification.findOne({
        userId,
        type: "daily_expense_reminder",
        createdAt: { $gte: today },
      });

      if (existingReminder) {
        logger.info("Daily expense reminder already sent today", {
          userId,
        });
        return;
      }

      const notification = await this.createNotification(
        userId,
        "daily_expense_reminder",
        {},
        {
          title: "📝 Nhắc ghi chi tiêu",
          message:
            "Bạn chưa ghi chi tiêu hôm nay. Hãy cập nhật để theo dõi tài chính tốt hơn!",
          category: "reminder",
          priority: "normal",
          requiresAction: true,
          actionButtons: [
            {
              text: "Thêm chi tiêu",
              action: "add_expense",
              actionData: {},
            },
            {
              text: "Hoãn",
              action: "snooze",
              actionData: { hours: 2 },
            },
          ],
        }
      );

      logger.info("Daily expense reminder triggered", {
        userId,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger daily expense reminder", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger weekly report
   * @param {string} userId - ID của user
   */
  static async triggerWeeklyReport(userId) {
    try {
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      // Lấy thống kê tuần
      const [expenses, incomes] = await Promise.all([
        Expense.find({
          userId,
          date: { $gte: oneWeekAgo },
        }).select("amount category"),
        Income.find({
          userId,
          date: { $gte: oneWeekAgo },
        }).select("amount"),
      ]);

      const totalExpenses = expenses.reduce((sum, exp) => sum + exp.amount, 0);
      const totalIncomes = incomes.reduce((sum, inc) => sum + inc.amount, 0);
      const netAmount = totalIncomes - totalExpenses;

      // Phân tích category chi tiêu
      const categoryStats = expenses.reduce((acc, exp) => {
        acc[exp.category] = (acc[exp.category] || 0) + exp.amount;
        return acc;
      }, {});

      const topCategory = Object.entries(categoryStats).sort(
        ([, a], [, b]) => b - a
      )[0];

      let message = `Tuần này bạn chi ${totalExpenses.toLocaleString()}đ, thu ${totalIncomes.toLocaleString()}đ. `;
      if (netAmount > 0) {
        message += `Tiết kiệm được ${netAmount.toLocaleString()}đ. `;
      } else {
        message += `Chi vượt thu ${Math.abs(netAmount).toLocaleString()}đ. `;
      }
      if (topCategory) {
        message += `Chi nhiều nhất cho ${
          topCategory[0]
        }: ${topCategory[1].toLocaleString()}đ.`;
      }

      const notification = await this.createNotification(
        userId,
        "weekly_report",
        {
          totalExpenses,
          totalIncomes,
          netAmount,
          categoryStats,
          topCategory: topCategory
            ? { category: topCategory[0], amount: topCategory[1] }
            : null,
        },
        {
          title: "📊 Báo cáo tuần",
          message,
          category: "insights",
          priority: "normal",
          requiresAction: false,
        }
      );

      logger.info("Weekly report triggered", {
        userId,
        totalExpenses,
        totalIncomes,
        netAmount,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger weekly report", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger income notification
   * @param {string} userId - ID của user
   * @param {Object} incomeData - Dữ liệu thu nhập
   */
  static async triggerIncomeNotification(userId, incomeData) {
    try {
      const { incomeId, incomeAmount, category, source, isRecurring } =
        incomeData;

      // ✅ FIX: Extract source name properly from object or string
      const sourceName = source?.name || source || "Nguồn không xác định";

      let title = "💰 Thu nhập mới";
      let message = `Bạn đã thêm thu nhập ${incomeAmount.toLocaleString()}đ từ ${sourceName}`;
      let priority = "normal";

      // Check for large income
      if (incomeAmount > 10000000) {
        // 10 triệu
        title = "💎 Thu nhập lớn!";
        message = `Chúc mừng! Bạn vừa có thu nhập lớn ${incomeAmount.toLocaleString()}đ từ ${sourceName}`;
        priority = "high";
      }

      // Check for recurring income
      if (isRecurring) {
        title = "🔄 Thu nhập định kỳ";
        message = `Thu nhập định kỳ ${incomeAmount.toLocaleString()}đ từ ${sourceName} đã được ghi nhận`;
      }

      const notification = await this.createNotification(
        userId,
        "income_added",
        {
          incomeId,
          incomeAmount,
          incomeSource: sourceName, // ✅ FIX: Store source name as string
          incomeCategory: category,
          isRecurring,
        },
        {
          title,
          message,
          category: "income",
          priority,
          requiresAction: false,
        }
      );

      logger.info("Income notification triggered", {
        userId,
        incomeId,
        incomeAmount,
        source,
        priority,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger income notification", {
        userId,
        incomeData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger savings goal notification
   * @param {string} userId - ID của user
   * @param {Object} savingsData - Dữ liệu mục tiêu tiết kiệm
   */
  static async triggerSavingsGoalNotification(userId, savingsData) {
    try {
      const {
        goalId,
        goalName,
        targetAmount,
        targetDate,
        currentAmount,
        progressPercentage,
      } = savingsData;

      let title = "🎯 Mục tiêu tiết kiệm mới";
      let message = `Bạn đã tạo mục tiêu "${goalName}" với số tiền ${targetAmount.toLocaleString()}đ`;
      let priority = "normal";

      const notification = await this.createNotification(
        userId,
        "savings_goal_created",
        {
          savingsGoalId: goalId,
          savingsGoalName: goalName,
          targetAmount,
          targetDate,
          currentAmount,
          progressPercentage,
        },
        {
          title,
          message,
          category: "savings",
          priority,
          requiresAction: false,
        }
      );

      logger.info("Savings goal notification triggered", {
        userId,
        goalId,
        goalName,
        targetAmount,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger savings goal notification", {
        userId,
        savingsData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger savings contribution notification
   * @param {string} userId - ID của user
   * @param {Object} contributionData - Dữ liệu đóng góp
   */
  static async triggerSavingsContributionNotification(
    userId,
    contributionData
  ) {
    try {
      const {
        goalId,
        goalName,
        contributionAmount,
        currentAmount,
        targetAmount,
        progressPercentage,
      } = contributionData;

      let title = "💳 Đóng góp mục tiêu";
      let message = `Bạn đã đóng góp ${contributionAmount.toLocaleString()}đ vào mục tiêu "${goalName}"`;
      let priority = "normal";

      // Check for milestone achievements
      if (progressPercentage >= 50 && progressPercentage < 75) {
        title = "🎉 Đạt 50% mục tiêu!";
        message = `Chúc mừng! Bạn đã đạt 50% mục tiêu "${goalName}" (${progressPercentage.toFixed(
          1
        )}%)`;
        priority = "high";
      } else if (progressPercentage >= 75 && progressPercentage < 100) {
        title = "🏆 Gần hoàn thành!";
        message = `Tuyệt vời! Bạn đã đạt ${progressPercentage.toFixed(
          1
        )}% mục tiêu "${goalName}"`;
        priority = "high";
      } else if (progressPercentage >= 100) {
        title = "🎊 Hoàn thành mục tiêu!";
        message = `Chúc mừng! Bạn đã hoàn thành mục tiêu "${goalName}"!`;
        priority = "urgent";
      }

      const notification = await this.createNotification(
        userId,
        "savings_contribution",
        {
          savingsGoalId: goalId,
          savingsGoalName: goalName,
          contributionAmount,
          currentAmount,
          targetAmount,
          progressPercentage,
        },
        {
          title,
          message,
          category: "savings",
          priority,
          requiresAction: progressPercentage >= 100,
          actionButtons:
            progressPercentage >= 100
              ? [
                  {
                    text: "Xem mục tiêu",
                    action: "view_savings_goal",
                    actionData: { savingsGoalId: goalId },
                  },
                  {
                    text: "Tạo mục tiêu mới",
                    action: "create_savings_goal",
                    actionData: {},
                  },
                ]
              : [],
        }
      );

      logger.info("Savings contribution notification triggered", {
        userId,
        goalId,
        goalName,
        contributionAmount,
        progressPercentage,
        priority,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger savings contribution notification", {
        userId,
        contributionData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Trigger budget update notification
   * @param {string} userId - ID của user
   * @param {Object} budgetData - Dữ liệu ngân sách
   */
  static async triggerBudgetUpdateNotification(userId, budgetData) {
    try {
      const { budgetId, budgetName, oldAmount, newAmount, changeType } =
        budgetData;

      let title = "📝 Cập nhật ngân sách";
      let message = `Ngân sách "${budgetName}" đã được cập nhật`;
      let priority = "normal";

      if (changeType === "amount_increase") {
        title = "📈 Tăng ngân sách";
        message = `Ngân sách "${budgetName}" đã tăng từ ${oldAmount.toLocaleString()}đ lên ${newAmount.toLocaleString()}đ`;
        priority = "normal";
      } else if (changeType === "amount_decrease") {
        title = "📉 Giảm ngân sách";
        message = `Ngân sách "${budgetName}" đã giảm từ ${oldAmount.toLocaleString()}đ xuống ${newAmount.toLocaleString()}đ`;
        priority = "high";
      }

      const notification = await this.createNotification(
        userId,
        "budget_updated",
        {
          budgetId,
          budgetName,
          oldAmount,
          newAmount,
          changeType,
        },
        {
          title,
          message,
          category: "budget",
          priority,
          requiresAction: changeType === "amount_decrease",
          actionButtons:
            changeType === "amount_decrease"
              ? [
                  {
                    text: "Xem ngân sách",
                    action: "view_budget",
                    actionData: { budgetId },
                  },
                  {
                    text: "Đã xem",
                    action: "mark_read",
                    actionData: {},
                  },
                ]
              : [],
        }
      );

      logger.info("Budget update notification triggered", {
        userId,
        budgetId,
        budgetName,
        changeType,
        priority,
      });

      return notification;
    } catch (error) {
      logger.error("Failed to trigger budget update notification", {
        userId,
        budgetData,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Helper methods
   */
  static getCategoryFromType(type) {
    const categoryMap = {
      challenge_started: "challenge",
      challenge_completed: "challenge",
      challenge_failed: "challenge",
      milestone_achieved: "challenge",
      challenge_reminder: "challenge",
      challenge_invitation: "challenge",
      budget_alert: "budget",
      budget_exceeded: "budget",
      budget_low_funds: "budget",
      budget_category_exceeded: "budget",
      monthly_budget_summary: "budget",
      expense_added: "expense",
      expense_approved: "expense",
      expense_rejected: "expense",
      receipt_processed: "expense",
      large_expense_alert: "expense",
      group_invitation: "group",
      group_expense_added: "group",
      member_joined: "group",
      member_left: "group",
      group_challenge_started: "group",
      encouragement_received: "social",
      achievement_shared: "social",
      friend_request: "social",
      leaderboard_position: "social",
      streak_milestone: "social",
      app_update: "system",
      maintenance_notice: "system",
      security_alert: "system",
      backup_completed: "system",
      sync_failed: "system",
      daily_expense_reminder: "reminder",
      weekly_report: "insights",
      monthly_report: "insights",
      bill_reminder: "expense",
      income_added: "income",
      savings_goal_created: "savings",
      savings_contribution: "savings",
      budget_updated: "budget",
    };

    return categoryMap[type] || "system";
  }

  static getDefaultTitle(type) {
    const titleMap = {
      budget_alert: "⚠️ Cảnh báo ngân sách",
      large_expense_alert: "🔍 Chi tiêu bất thường",
      daily_expense_reminder: "📝 Nhắc ghi chi tiêu",
      weekly_report: "📊 Báo cáo tuần",
      bill_reminder: "📅 Nhắc nhở hóa đơn",
      income_added: "💰 Thu nhập mới",
      savings_goal_created: "🎯 Mục tiêu tiết kiệm mới",
      savings_contribution: "💳 Đóng góp mục tiêu",
      budget_updated: "📝 Cập nhật ngân sách",
    };

    return titleMap[type] || "🔔 Thông báo mới";
  }

  static getDefaultMessage(type, data) {
    const messageMap = {
      budget_alert: `Bạn đã chi ${data.spentPercentage || 0}% ngân sách ${
        data.category || ""
      }`,
      large_expense_alert: `Bạn vừa chi ${
        data.expenseAmount?.toLocaleString() || 0
      }đ cho ${data.category || ""}`,
      daily_expense_reminder:
        "Bạn chưa ghi chi tiêu hôm nay. Hãy cập nhật để theo dõi tài chính tốt hơn!",
      weekly_report: "Báo cáo tài chính tuần này đã sẵn sàng.",
      bill_reminder: `Hóa đơn ${data.billName || ""} sắp đến hạn.`,
      income_added: `Bạn đã thêm thu nhập ${
        data.incomeAmount?.toLocaleString() || 0
      }đ từ ${data.incomeSource || ""}`,
      savings_goal_created: `Bạn đã tạo mục tiêu "${
        data.savingsGoalName || ""
      }" với số tiền ${data.targetAmount?.toLocaleString() || 0}đ`,
      savings_contribution: `Bạn đã đóng góp ${
        data.contributionAmount?.toLocaleString() || 0
      }đ vào mục tiêu "${data.savingsGoalName || ""}"`,
      budget_updated: `Ngân sách "${data.budgetName || ""}" đã được cập nhật`,
    };

    return messageMap[type] || "Bạn có thông báo mới từ ZBudget.";
  }
}

export default NotificationService;
