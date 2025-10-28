import express from "express";
import {
  getNotifications,
  getUnreadCount,
  getNotificationsByCategory,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  createTestNotification,
  getNotificationStats,
} from "../controllers/notificationController.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/notifications
 * @desc    Lấy danh sách thông báo của user
 * @access  Private
 * @query   page, limit, category, isRead, priority, type, sort
 */
router.get("/", getNotifications);

/**
 * @route   GET /api/notifications/unread-count
 * @desc    Lấy số thông báo chưa đọc
 * @access  Private
 */
router.get("/unread-count", getUnreadCount);

/**
 * @route   GET /api/notifications/stats
 * @desc    Lấy thống kê thông báo
 * @access  Private
 */
router.get("/stats", getNotificationStats);

/**
 * @route   GET /api/notifications/by-category/:category
 * @desc    Lấy thông báo theo category
 * @access  Private
 * @param   category - budget, expense, challenge, group, social, system
 */
router.get("/by-category/:category", getNotificationsByCategory);

/**
 * @route   PUT /api/notifications/:id/read
 * @desc    Đánh dấu thông báo đã đọc
 * @access  Private
 * @param   id - Notification ID
 */
router.put("/:id/read", markAsRead);

/**
 * @route   PUT /api/notifications/mark-all-read
 * @desc    Đánh dấu tất cả thông báo đã đọc
 * @access  Private
 * @body    category (optional) - Chỉ đánh dấu category cụ thể
 */
router.put("/mark-all-read", markAllAsRead);

/**
 * @route   DELETE /api/notifications/:id
 * @desc    Xóa thông báo
 * @access  Private
 * @param   id - Notification ID
 */
router.delete("/:id", deleteNotification);

/**
 * @route   POST /api/notifications/test
 * @desc    Tạo notification test (dev only)
 * @access  Private
 * @body    type, title, message, category
 */
router.post("/test", createTestNotification);

export default router;
