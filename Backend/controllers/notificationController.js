import Notification from "../models/Notification.js";
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  successResponse,
} from "../middleware/errorHandler.js";
import {
  performanceLogger,
  dbLogger,
  errorLogger,
} from "../middleware/logger.js";
import mongoose from "mongoose";
import { authenticate } from "../middleware/auth.js";

/**
 * @desc    Lấy danh sách thông báo của user
 * @route   GET /api/notifications
 * @access  Private
 */
export const getNotifications = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const {
    page = 1,
    limit = 20,
    category,
    isRead,
    priority,
    type,
    sort = "-createdAt",
  } = req.query;

  try {
    // Build query
    const query = { userId: new mongoose.Types.ObjectId(userId) };

    if (category) query.category = category;
    if (isRead !== undefined) query.isRead = isRead === "true";
    if (priority) query.priority = priority;
    if (type) query.type = type;

    // Pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const limitNum = parseInt(limit);

    // Get notifications with pagination
    const notifications = await Notification.find(query)
      .sort(sort)
      .skip(skip)
      .limit(limitNum)
      .populate("data.challengeId", "name description")
      .populate("data.budgetId", "name category amount spentAmount")
      .populate("data.expenseId", "amount category description")
      .populate("data.groupId", "name")
      .lean();

    // Get total count for pagination
    const totalCount = await Notification.countDocuments(query);
    const totalPages = Math.ceil(totalCount / limitNum);

    const duration = Date.now() - startTime;
    performanceLogger("Get notifications completed", duration, {
      userId,
      count: notifications.length,
      page,
      totalPages,
    });

    return successResponse(res, "Notifications retrieved successfully", {
      notifications,
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalCount,
        hasNextPage: parseInt(page) < totalPages,
        hasPrevPage: parseInt(page) > 1,
      },
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      duration: `${duration}ms`,
      context: "Get notifications failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to retrieve notifications",
    });
  }
};

/**
 * @desc    Lấy số thông báo chưa đọc
 * @route   GET /api/notifications/unread-count
 * @access  Private
 */
export const getUnreadCount = async (req, res) => {
  const startTime = Date.now();

  // Debug log
  console.log("🔍 getUnreadCount - req.userId:", req.userId);
  console.log("🔍 getUnreadCount - req.user:", req.user);

  if (!req.userId) {
    return res.status(400).json({
      success: false,
      error: "User ID not found in request",
    });
  }

  const userId = new mongoose.Types.ObjectId(req.userId);

  try {
    console.log("🔍 Calling Notification.getUnreadCount with userId:", userId);
    const unreadCount = await Notification.getUnreadCount(userId);
    console.log("🔍 getUnreadCount result:", unreadCount);

    const duration = Date.now() - startTime;
    performanceLogger("Get unread count completed", duration, {
      userId,
      unreadCount,
    });

    return successResponse(res, "Unread count retrieved successfully", {
      unreadCount,
    });
  } catch (error) {
    console.log("🔍 Error in getUnreadCount:", error.message);
    console.log("🔍 Error stack:", error.stack);
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      duration: `${duration}ms`,
      context: "Get unread count failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to get unread count",
    });
  }
};

/**
 * @desc    Lấy thông báo theo category
 * @route   GET /api/notifications/by-category/:category
 * @access  Private
 */
export const getNotificationsByCategory = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const { category } = req.params;
  const { limit = 20 } = req.query;

  try {
    const notifications = await Notification.findByCategory(
      userId,
      category,
      parseInt(limit)
    );

    const duration = Date.now() - startTime;
    performanceLogger("Get notifications by category completed", duration, {
      userId,
      category,
      count: notifications.length,
    });

    return successResponse(
      res,
      "Notifications by category retrieved successfully",
      {
        notifications,
      }
    );
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      category,
      duration: `${duration}ms`,
      context: "Get notifications by category failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to get notifications by category",
    });
  }
};

/**
 * @desc    Đánh dấu thông báo đã đọc
 * @route   PUT /api/notifications/:id/read
 * @access  Private
 */
export const markAsRead = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const { id } = req.params;

  try {
    const notification = await Notification.findById(id);

    if (!notification) {
      throw new NotFoundError("Notification not found");
    }

    // Check ownership
    if (!notification.userId.equals(userId)) {
      throw new ForbiddenError("Access denied");
    }

    notification.markAsRead();
    await notification.save();

    const duration = Date.now() - startTime;
    performanceLogger("Mark notification as read completed", duration, {
      userId,
      notificationId: id,
    });

    return successResponse(res, "Notification marked as read", {
      message: "Notification marked as read",
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      notificationId: id,
      duration: `${duration}ms`,
      context: "Mark notification as read failed",
    });

    if (error instanceof NotFoundError || error instanceof ForbiddenError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
      });
    }

    res.status(500).json({
      success: false,
      error: "Failed to mark notification as read",
    });
  }
};

/**
 * @desc    Đánh dấu tất cả thông báo đã đọc
 * @route   PUT /api/notifications/mark-all-read
 * @access  Private
 */
export const markAllAsRead = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const { category } = req.body;

  try {
    const result = await Notification.markAllAsReadForUser(userId, category);

    const duration = Date.now() - startTime;
    performanceLogger("Mark all notifications as read completed", duration, {
      userId,
      category,
      modifiedCount: result.modifiedCount,
    });

    return successResponse(res, "All notifications marked as read", {
      message: "All notifications marked as read",
      modifiedCount: result.modifiedCount,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      category,
      duration: `${duration}ms`,
      context: "Mark all notifications as read failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to mark all notifications as read",
    });
  }
};

/**
 * @desc    Xóa thông báo
 * @route   DELETE /api/notifications/:id
 * @access  Private
 */
export const deleteNotification = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const { id } = req.params;

  try {
    const notification = await Notification.findById(id);

    if (!notification) {
      throw new NotFoundError("Notification not found");
    }

    // Check ownership
    if (!notification.userId.equals(userId)) {
      throw new ForbiddenError("Access denied");
    }

    await Notification.findByIdAndDelete(id);

    const duration = Date.now() - startTime;
    performanceLogger("Delete notification completed", duration, {
      userId,
      notificationId: id,
    });

    return successResponse(res, "Notification deleted", {
      message: "Notification deleted",
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      notificationId: id,
      duration: `${duration}ms`,
      context: "Delete notification failed",
    });

    if (error instanceof NotFoundError || error instanceof ForbiddenError) {
      return res.status(error.statusCode).json({
        success: false,
        error: error.message,
      });
    }

    res.status(500).json({
      success: false,
      error: "Failed to delete notification",
    });
  }
};

/**
 * @desc    Tạo notification test (dev only)
 * @route   POST /api/notifications/test
 * @access  Private
 */
export const createTestNotification = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);
  const { type, title, message, category = "system" } = req.body;

  // Only allow in development
  if (process.env.NODE_ENV === "production") {
    return res.status(403).json({
      success: false,
      error: "Test notifications not allowed in production",
    });
  }

  try {
    const notification = new Notification({
      userId,
      type: type || "system",
      category,
      title: title || "Test Notification",
      message: message || "This is a test notification",
      priority: "normal",
      deliveryMethod: "in_app",
    });

    await notification.save();

    const duration = Date.now() - startTime;
    performanceLogger("Create test notification completed", duration, {
      userId,
      notificationId: notification._id,
    });

    return successResponse(res, "Test notification created", {
      message: "Test notification created",
      notification,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      duration: `${duration}ms`,
      context: "Create test notification failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to create test notification",
    });
  }
};

/**
 * @desc    Lấy thống kê thông báo
 * @route   GET /api/notifications/stats
 * @access  Private
 */
export const getNotificationStats = async (req, res) => {
  const startTime = Date.now();
  const userId = new mongoose.Types.ObjectId(req.userId);

  try {
    const [unreadCount, categoryStats] = await Promise.all([
      Notification.getUnreadCount(userId),
      Notification.getUnreadCountByCategory(userId),
    ]);

    const duration = Date.now() - startTime;
    performanceLogger("Get notification stats completed", duration, {
      userId,
      unreadCount,
      categoryStats,
    });

    return successResponse(res, "Notification stats retrieved successfully", {
      unreadCount,
      categoryStats,
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    errorLogger(error, null, {
      userId,
      duration: `${duration}ms`,
      context: "Get notification stats failed",
    });
    res.status(500).json({
      success: false,
      error: "Failed to get notification stats",
    });
  }
};

export default {
  getNotifications,
  getUnreadCount,
  getNotificationsByCategory,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  createTestNotification,
  getNotificationStats,
};
