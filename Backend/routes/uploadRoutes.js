import express from "express";
import { authenticate } from "../middleware/auth.js";
import { uploadAvatar } from "../middleware/uploadSimple.js";
import { catchAsync } from "../middleware/errorHandler.js";
import { successResponse, errorResponse } from "../utils/responseHelpers.js";
import User from "../models/User.js";

const router = express.Router();

// Upload avatar endpoint
router.post(
  "/avatar",
  authenticate,
  uploadAvatar,
  catchAsync(async (req, res) => {
    const userId = req.user.id;

    // Check if file was uploaded
    if (!req.file) {
      return errorResponse(res, "Vui lòng chọn file ảnh để tải lên", 400);
    }

    try {
      // Get uploaded file URL (Cloudinary returns full URL in req.file.path)
      const avatarUrl = req.file.path;

      // Update user's avatar in database
      const updatedUser = await User.findByIdAndUpdate(
        userId,
        {
          $set: {
            "profile.avatar": avatarUrl,
          },
        },
        { new: true, runValidators: true }
      ).select("profile.avatar profile.displayName email");

      if (!updatedUser) {
        return errorResponse(res, "Không tìm thấy người dùng", 404);
      }

      console.log(
        `✅ Avatar uploaded successfully for user ${userId}:`,
        avatarUrl
      );

      return successResponse(
        res,
        {
          avatar: updatedUser.profile.avatar,
          user: {
            displayName: updatedUser.profile.displayName,
            email: updatedUser.email,
            avatar: updatedUser.profile.avatar,
          },
        },
        "Tải ảnh đại diện thành công"
      );
    } catch (error) {
      console.error("❌ Error uploading avatar:", error);
      return errorResponse(
        res,
        "Lỗi tải ảnh lên server: " + error.message,
        500
      );
    }
  })
);

// TODO: Upload receipt endpoint (for expense tracking) - temporarily disabled
/*
router.post(
  "/receipt",
  authenticate,
  uploadMiddleware.receipt,
  catchAsync(async (req, res) => {
    // Check if file was uploaded
    if (!req.file) {
      return errorResponse(res, "Vui lòng chọn file ảnh hóa đơn để tải lên", 400);
    }

    try {
      // Get uploaded file URL
      const receiptUrl = req.file.path;

      console.log(`✅ Receipt uploaded successfully:`, receiptUrl);

      return successResponse(
        res,
        "Tải ảnh hóa đơn thành công",
        {
          receiptUrl: receiptUrl,
          filename: req.file.originalname,
          size: req.file.size
        }
      );

    } catch (error) {
      console.error("❌ Error uploading receipt:", error);
      return errorResponse(res, "Lỗi tải ảnh hóa đơn lên server: " + error.message, 500);
    }
  })
);

// Get user's current avatar
router.get(
  "/avatar",
  authenticate,
  catchAsync(async (req, res) => {
    const userId = req.user.id;

    try {
      const user = await User.findById(userId).select("profile.avatar profile.displayName email");
      
      if (!user) {
        return errorResponse(res, "Không tìm thấy người dùng", 404);
      }

      return successResponse(
        res,
        "Lấy thông tin ảnh đại diện thành công",
        {
          avatar: user.profile.avatar,
          user: {
            displayName: user.profile.displayName,
            email: user.email,
            avatar: user.profile.avatar
          }
        }
      );

    } catch (error) {
      console.error("❌ Error getting avatar:", error);
      return errorResponse(res, "Lỗi lấy thông tin ảnh đại diện: " + error.message, 500);
    }
  })
);

// Delete avatar endpoint
router.delete(
  "/avatar",
  authenticate,
  catchAsync(async (req, res) => {
    const userId = req.user.id;

    try {
      // Get current user to check if avatar exists
      const user = await User.findById(userId);
      if (!user) {
        return errorResponse(res, "Không tìm thấy người dùng", 404);
      }

        // Delete avatar from cloudinary if exists
        if (user.profile.avatar && user.profile.avatar.includes("cloudinary.com")) {
          try {
            await deleteFile(user.profile.avatar);
          } catch (deleteError) {
            console.error("❌ Error deleting avatar from Cloudinary:", deleteError);
            // Continue with database update even if Cloudinary delete fails
          }
        }      // Remove avatar from database
      const updatedUser = await User.findByIdAndUpdate(
        userId,
        { 
          $unset: { 
            "profile.avatar": "" 
          }
        },
        { new: true, runValidators: true }
      ).select("profile.displayName email");

      console.log(`✅ Avatar deleted successfully for user ${userId}`);

      return successResponse(
        res,
        "Xóa ảnh đại diện thành công",
        {
          user: {
            displayName: updatedUser.profile.displayName,
            email: updatedUser.email,
            avatar: null
          }
        }
      );

    } catch (error) {
      console.error("❌ Error deleting avatar:", error);
      return errorResponse(res, "Lỗi xóa ảnh đại diện: " + error.message, 500);
    }
  })
);
*/

export default router;
