import Feedback from "../models/Feedback.js";
import { AppError } from "../middleware/errorHandler.js";

/**
 * @desc    Create new feedback
 * @route   POST /api/feedback
 * @access  Public (with optional authentication)
 */
export const createFeedback = async (req, res, next) => {
  try {
    const { name, email, type, rating, content, deviceInfo } = req.body;

    // Validate required fields
    if (!name || !email || !type || !rating || !content) {
      throw new AppError("Vui lòng điền đầy đủ thông tin", 400);
    }

    // Create feedback object
    const feedbackData = {
      name,
      email,
      type,
      rating,
      content,
      deviceInfo: deviceInfo || {},
    };

    // Add userId if user is authenticated
    if (req.user) {
      feedbackData.userId = req.user._id;
    }

    const feedback = await Feedback.create(feedbackData);

    res.status(201).json({
      success: true,
      message: "Phản hồi đã được gửi thành công",
      data: feedback,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get all feedbacks (Admin only)
 * @route   GET /api/feedback
 * @access  Private/Admin
 */
export const getAllFeedbacks = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 10,
      type,
      status,
      sortBy = "createdAt",
      order = "desc",
    } = req.query;

    // Build filter query
    const filter = {};
    if (type) filter.type = type;
    if (status) filter.status = status;

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOrder = order === "asc" ? 1 : -1;

    // Get feedbacks with pagination
    const feedbacks = await Feedback.find(filter)
      .sort({ [sortBy]: sortOrder })
      .skip(skip)
      .limit(parseInt(limit))
      .populate("userId", "profile.name email")
      .populate("adminResponse.respondedBy", "profile.name email");

    const total = await Feedback.countDocuments(filter);

    res.json({
      success: true,
      data: feedbacks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get feedback by ID
 * @route   GET /api/feedback/:id
 * @access  Private
 */
export const getFeedbackById = async (req, res, next) => {
  try {
    const feedback = await Feedback.findById(req.params.id)
      .populate("userId", "profile.name email")
      .populate("adminResponse.respondedBy", "profile.name email");

    if (!feedback) {
      throw new AppError("Không tìm thấy phản hồi", 404);
    }

    // Check if user has permission to view this feedback
    if (
      req.user &&
      req.user.role !== "admin" &&
      feedback.userId &&
      feedback.userId.toString() !== req.user._id.toString()
    ) {
      throw new AppError("Bạn không có quyền xem phản hồi này", 403);
    }

    res.json({
      success: true,
      data: feedback,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get user's feedbacks
 * @route   GET /api/feedback/my-feedbacks
 * @access  Private
 */
export const getMyFeedbacks = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 10,
      type,
      status,
      sortBy = "createdAt",
      order = "desc",
    } = req.query;

    // Build filter query
    const filter = { userId: req.user._id };
    if (type) filter.type = type;
    if (status) filter.status = status;

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOrder = order === "asc" ? 1 : -1;

    // Get feedbacks with pagination
    const feedbacks = await Feedback.find(filter)
      .sort({ [sortBy]: sortOrder })
      .skip(skip)
      .limit(parseInt(limit))
      .populate("adminResponse.respondedBy", "profile.name");

    const total = await Feedback.countDocuments(filter);

    res.json({
      success: true,
      data: feedbacks,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update feedback status (Admin only)
 * @route   PATCH /api/feedback/:id/status
 * @access  Private/Admin
 */
export const updateFeedbackStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    if (!["pending", "reviewed", "resolved", "archived"].includes(status)) {
      throw new AppError("Trạng thái không hợp lệ", 400);
    }

    const feedback = await Feedback.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );

    if (!feedback) {
      throw new AppError("Không tìm thấy phản hồi", 404);
    }

    res.json({
      success: true,
      message: "Cập nhật trạng thái thành công",
      data: feedback,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Add admin response to feedback (Admin only)
 * @route   PATCH /api/feedback/:id/respond
 * @access  Private/Admin
 */
export const addAdminResponse = async (req, res, next) => {
  try {
    const { message } = req.body;

    if (!message || message.trim().length === 0) {
      throw new AppError("Vui lòng nhập nội dung phản hồi", 400);
    }

    const feedback = await Feedback.findByIdAndUpdate(
      req.params.id,
      {
        adminResponse: {
          message,
          respondedBy: req.user._id,
          respondedAt: new Date(),
        },
        status: "reviewed",
      },
      { new: true, runValidators: true }
    ).populate("adminResponse.respondedBy", "profile.name email");

    if (!feedback) {
      throw new AppError("Không tìm thấy phản hồi", 404);
    }

    res.json({
      success: true,
      message: "Phản hồi đã được gửi thành công",
      data: feedback,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete feedback (Admin only)
 * @route   DELETE /api/feedback/:id
 * @access  Private/Admin
 */
export const deleteFeedback = async (req, res, next) => {
  try {
    const feedback = await Feedback.findByIdAndDelete(req.params.id);

    if (!feedback) {
      throw new AppError("Không tìm thấy phản hồi", 404);
    }

    res.json({
      success: true,
      message: "Xóa phản hồi thành công",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get feedback statistics (Admin only)
 * @route   GET /api/feedback/stats
 * @access  Private/Admin
 */
export const getFeedbackStatistics = async (req, res, next) => {
  try {
    const stats = await Feedback.getStatistics();

    res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    next(error);
  }
};
