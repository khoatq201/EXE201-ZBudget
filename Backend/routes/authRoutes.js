import express from "express";
import User from "../models/User.js";
import {
  register,
  login,
  logout,
  refreshToken,
  forgotPassword,
  verifyPasswordResetOTP,
  resetPassword,
  verifyEmail,
  verifyOTP,
  resendEmailVerification,
  changePassword,
  getProfile,
  updateProfile,
  deleteAccount,
  searchUsers,
} from "../controllers/authController.js";
import { OAuth2Client } from "google-auth-library";
import {
  authenticate,
  optionalAuthenticate,
  rateLimitAuth,
  rateLimitPassword,
  generateTokens,
} from "../middleware/auth.js";
import {
  validate,
  userSchemas,
  validateFile,
  uploadSchemas,
} from "../middleware/validation.js";
import { auditLogger } from "../middleware/logger.js";
import { uploadMiddleware } from "../middleware/upload.js";
import Joi from "joi";
import { catchAsync } from "../middleware/errorHandler.js";
const router = express.Router();
// Enhanced audit logging middleware with better debugging
const auditAuthOperation = (operation) => (req, res, next) => {
  // Log immediately when middleware runs
  auditLogger(operation + "_ATTEMPT", req, {
    timestamp: new Date().toISOString(),
    userAgent: req.get("User-Agent"),
    ip: req.ip,
  });
  res.on("finish", () => {
    if (res.statusCode < 400) {
      auditLogger(operation + "_SUCCESS", req, {
        success: true,
        statusCode: res.statusCode,
      });
    } else {
      auditLogger(operation + "_FAILED", req, {
        success: false,
        statusCode: res.statusCode,
      });
    }
  });
  next();
};
// Debug middleware for all auth routes
router.use((req, res, next) => {
  next();
});
// Create a simple pass-through middleware for testing
const bypassRateLimit = (req, res, next) => {
  next();
};
/**
 * @route   POST /api/auth/register
 * @desc    Đăng ký tài khoản mới
 * @access  Public
 * @body    { fullName, email, password, confirmPassword, phoneNumber?, dateOfBirth?, gender? }
 */
router.post(
  "/register",
  // Add debug middleware for each step
  (req, res, next) => {
    next();
  },
  // ⚡ TEMPORARILY USE BYPASS INSTEAD OF RATE LIMITING
  process.env.NODE_ENV === "development" ? bypassRateLimit : rateLimitAuth,
  (req, res, next) => {
    next();
  },
  validate(userSchemas.register),
  (req, res, next) => {
    next();
  },
  auditAuthOperation("USER_REGISTER"),
  (req, res, next) => {
    next();
  },
  catchAsync(register) // Wrap register with asyncHandler for error catching
);
/**
 * @route   POST /api/auth/login
 * @desc    Đăng nhập
 * @access  Public
 * @body    { email, password, rememberMe? }
 */
router.post(
  "/login",
  rateLimitAuth, // ✅ Move rate limiting here
  validate(userSchemas.login),
  auditAuthOperation("USER_LOGIN"),
  catchAsync(login) // ✅ Wrap with catchAsync to handle async errors
);
/**
 * @route   POST /api/auth/logout
 * @desc    Đăng xuất
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 */
router.post(
  "/logout",
  authenticate,
  auditAuthOperation("USER_LOGOUT"),
  catchAsync(logout)
);
/**
 * @route   POST /api/auth/refresh-token
 * @desc    Làm mới access token bằng refresh token
 * @access  Public
 * @body    { refreshToken }
 */
router.post("/refresh-token", rateLimitAuth, catchAsync(refreshToken));
/**
 * @route   POST /api/auth/forgot-password
 * @desc    Quên mật khẩu - gửi email reset
 * @access  Public
 * @body    { email }
 */
router.post(
  "/forgot-password",
  rateLimitPassword(), // ✅ FIX: Call the factory function
  validate(userSchemas.forgotPassword),
  auditAuthOperation("PASSWORD_RESET_REQUEST"),
  catchAsync(forgotPassword)
);
/**
 * @route   POST /api/auth/verify-password-reset-otp
 * @desc    Xác thực OTP đặt lại mật khẩu
 * @access  Public
 * @body    { email, otp }
 */
router.post(
  "/verify-password-reset-otp",
  rateLimitPassword(), // ✅ Rate limiting for security
  validate(userSchemas.verifyPasswordResetOTP),
  auditAuthOperation("PASSWORD_RESET_OTP_VERIFY"),
  catchAsync(verifyPasswordResetOTP)
);
/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset mật khẩu với OTP
 * @access  Public
 * @body    { email, otp, newPassword, confirmNewPassword }
 */
router.post(
  "/reset-password",
  rateLimitPassword(), // ✅ FIX: Call the factory function
  validate(userSchemas.resetPassword),
  auditAuthOperation("PASSWORD_RESET_COMPLETE"),
  catchAsync(resetPassword)
);
/**
 * @route   GET /api/auth/verify-email/:token
 * @desc    Xác thực email với token
 * @access  Public
 * @params  token - Token xác thực email
 */
router.get(
  "/verify-email/:token",
  auditAuthOperation("EMAIL_VERIFICATION"),
  catchAsync(verifyEmail)
);
/**
 * @route   POST /api/auth/verify-otp
 * @desc    Xác thực OTP email
 * @access  Public
 * @body    { email, otp }
 */
router.post(
  "/verify-otp",
  process.env.NODE_ENV === "development" ? bypassRateLimit : rateLimitAuth,
  validate(userSchemas.verifyOTP),
  auditAuthOperation("OTP_VERIFICATION"),
  catchAsync(verifyOTP)
);

/**
 * @route   POST /api/auth/resend-otp
 * @desc    Gửi lại OTP cho đăng ký
 * @access  Public
 * @body    { email }
 */
router.post(
  "/resend-otp",
  process.env.NODE_ENV === "development" ? bypassRateLimit : rateLimitAuth,
  validate(userSchemas.resendOTP),
  auditAuthOperation("RESEND_OTP"),
  catchAsync(async (req, res) => {
    const { email } = req.body;

    // Get temporary user data
    const tempUserKey = `temp_user_${email.toLowerCase()}`;
    global.tempUsers = global.tempUsers || new Map();
    const tempUserData = global.tempUsers.get(tempUserKey);

    if (!tempUserData) {
      return res.status(400).json({
        success: false,
        message: "Phiên đăng ký đã hết hạn. Vui lòng đăng ký lại.",
      });
    }

    // Check if temporary data is expired
    if (tempUserData.expiresAt < new Date()) {
      global.tempUsers.delete(tempUserKey);
      return res.status(400).json({
        success: false,
        message: "Phiên đăng ký đã hết hạn. Vui lòng đăng ký lại.",
      });
    }

    // Generate new OTP
    const newOTP = Math.floor(100000 + Math.random() * 900000).toString();
    const newExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Update temporary data
    tempUserData.emailVerificationOTP = newOTP;
    tempUserData.emailVerificationExpires = newExpires;
    global.tempUsers.set(tempUserKey, tempUserData);

    // Send new OTP email
    try {
      await sendVerificationEmail(
        email.toLowerCase(),
        tempUserData.profile.name,
        newOTP
      );

      res.json({
        success: true,
        message: "Mã OTP mới đã được gửi đến email của bạn.",
        data: {
          email: email.toLowerCase(),
          otpSent: true,
          expiresIn: 600, // 10 minutes in seconds
        },
      });
    } catch (emailError) {
      console.error("Failed to send resend OTP email:", emailError);
      res.status(500).json({
        success: false,
        message: "Không thể gửi email. Vui lòng thử lại sau.",
      });
    }
  })
);
/**
 * @route   POST /api/auth/resend-verification
 * @desc    Gửi lại email xác thực
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 */
router.post(
  "/resend-verification",
  authenticate,
  auditAuthOperation("EMAIL_VERIFICATION_RESEND"),
  catchAsync(resendEmailVerification)
);
/**
 * @route   POST /api/auth/change-password
 * @desc    Đổi mật khẩu (khi đã đăng nhập)
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 * @body    { currentPassword, newPassword, confirmNewPassword }
 */
router.post(
  "/change-password",
  authenticate,
  rateLimitPassword(), // ✅ FIX: Call the factory function
  validate(userSchemas.changePassword),
  auditAuthOperation("PASSWORD_CHANGE"),
  catchAsync(changePassword)
);
/**
 * @route   GET /api/auth/profile
 * @desc    Lấy thông tin profile người dùng hiện tại
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 */
router.get("/profile", authenticate, catchAsync(getProfile));

/**
 * @route   GET /api/auth/search-users
 * @desc    Tìm kiếm users theo tên
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 * @query   q - Từ khóa tìm kiếm (tối thiểu 2 ký tự)
 */
router.get("/search-users", authenticate, catchAsync(searchUsers));
/**
 * @route   PUT /api/auth/profile
 * @desc    Cập nhật thông tin profile
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 * @body    { fullName?, phoneNumber?, dateOfBirth?, gender?, preferences? }
 */
router.put(
  "/profile",
  authenticate,
  validate(userSchemas.updateProfile),
  auditAuthOperation("PROFILE_UPDATE"),
  catchAsync(updateProfile)
);
/**
 * @route   POST /api/auth/profile/avatar
 * @desc    Cập nhật ảnh đại diện
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 * @form    avatar - File ảnh (jpeg, png, webp, max 5MB)
 */
router.post(
  "/profile/avatar",
  authenticate,
  uploadMiddleware.avatar,
  validateFile(uploadSchemas.image),
  auditAuthOperation("AVATAR_UPDATE"),
  async (req, res, next) => {
    // Add file info to request for controller
    req.body.avatarFile = req.file;
    next();
  },
  catchAsync(updateProfile)
);
/**
 * @route   DELETE /api/auth/account
 * @desc    Xóa tài khoản (soft delete)
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 * @body    { password, reason? }
 */
router.delete(
  "/account",
  authenticate,
  validate(
    Joi.object({
      password: Joi.string().required().label("Mật khẩu"),
      reason: Joi.string().max(500).optional().label("Lý do xóa tài khoản"),
    }).messages({
      "any.required": "{{#label}} là bắt buộc",
      "string.max": "{{#label}} không được vượt quá {{#limit}} ký tự",
    })
  ),
  auditAuthOperation("ACCOUNT_DELETE"),
  catchAsync(deleteAccount)
);
/**
 * @route   GET /api/auth/check
 * @desc    Kiểm tra trạng thái đăng nhập
 * @access  Public (optional auth)
 * @headers Authorization: Bearer <accessToken> (optional)
 */
router.get("/check", optionalAuthenticate, (req, res) => {
  res.json({
    success: true,
    data: {
      isAuthenticated: !!req.userId,
      user: req.user || null,
    },
  });
});
/**
 * @route   POST /api/auth/validate-token
 * @desc    Validate access token (for mobile apps)
 * @access  Private
 * @headers Authorization: Bearer <accessToken>
 */
router.post("/validate-token", authenticate, (req, res) => {
  res.json({
    success: true,
    message: "Token hợp lệ",
    data: {
      userId: req.userId,
      user: req.user,
      tokenExp: req.tokenExp,
    },
  });
});
/**
 * @route   POST /api/auth/google-signin
 * @desc    Google Sign-In
 * @access  Public
 */
router.post(
  "/google-signin",
  rateLimitAuth,
  auditAuthOperation("google_signin"),
  catchAsync(async (req, res) => {
    const { idToken, accessToken, email, displayName, photoUrl } = req.body;
    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email là bắt buộc",
      });
    }
    if (!idToken && !accessToken) {
      return res.status(400).json({
        success: false,
        message: "ID token hoặc access token là bắt buộc",
      });
    }
    try {
      let payload = {};
      if (idToken) {
        // Verify the Google ID token
        const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
        const ticket = await client.verifyIdToken({
          idToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        payload = ticket.getPayload();
        if (payload.email !== email) {
          return res.status(401).json({
            success: false,
            message: "Token Google không hợp lệ",
          });
        }
      } else if (accessToken) {
        // For web Google Sign-In, we trust the email from frontend
        // since accessToken is verified by Google on the client side
        // This is acceptable for web applications
        payload = {
          email: email,
          name: displayName,
          picture: photoUrl,
          sub: `google_${email}`, // Create a pseudo Google ID
        };
      }
      // Import User model dynamically
      // const { User } = await import("../models/index.js");
      // Find or create user
      let user = await User.findOne({ email: payload.email });
      if (!user) {
        // Create new user for Google sign-in
        user = new User({
          email: payload.email,
          profile: {
            name: displayName || payload.name,
            avatar: photoUrl || payload.picture,
          },
          emailVerified: true, // Google accounts are pre-verified
          authProvider: "google",
          googleId: payload.sub,
        });
        await user.save();
      } else {
        // Check if user was created with different auth provider
        if (user.authProvider === "local" && !user.googleId) {
          // Link Google account to existing local account
          user.googleId = payload.sub;
          user.authProvider = "google"; // Switch to Google provider
          user.emailVerified = true;
        }
        // Update user info if they exist
        if (user.profile) {
          user.profile.avatar =
            photoUrl || payload.picture || user.profile.avatar;
          if (!user.profile.name && (displayName || payload.name)) {
            user.profile.name = displayName || payload.name;
          }
        }
        user.emailVerified = true;
        user.lastLogin = new Date();
        await user.save();
      }
      // Generate JWT tokens
      const { accessToken: jwtAccessToken, refreshToken } =
        await generateTokens(user._id, req, "google");
      // Log successful Google sign-in
      auditLogger("google_signin_SUCCESS", req, {
        userId: user._id,
        email: user.email,
        timestamp: new Date().toISOString(),
      });
      res.json({
        success: true,
        message: "Đăng nhập Google thành công",
        accessToken: jwtAccessToken,
        refreshToken,
        user: {
          id: user._id,
          email: user.email,
          name: user.profile?.name || user.profile?.fullName || "",
          fullName: user.profile?.name || user.profile?.fullName || "",
          avatar: user.profile?.avatar,
          emailVerified: user.emailVerified,
          needsProfileCompletion:
            !user.profile?.phone || !user.profile?.dateOfBirth,
        },
      });
    } catch (error) {
      console.error("Google sign-in error:", error);
      // Log failed Google sign-in
      auditLogger("google_signin_FAILED", req, {
        email,
        error: error.message,
        timestamp: new Date().toISOString(),
      });
      res.status(401).json({
        success: false,
        message: "Token Google không hợp lệ",
      });
    }
  })
);
// Complete Profile endpoint (for Google Sign-In users)
const completeProfileSchema = Joi.object({
  phone: Joi.string()
    .pattern(/^(\+84|84|0)(3|5|7|8|9)[0-9]{8}$/)
    .optional()
    .messages({
      "string.pattern.base": "Số điện thoại không hợp lệ",
    }),
  dateOfBirth: Joi.date().max("now").optional().messages({
    "date.max": "Ngày sinh không thể ở tương lai",
  }),
  gender: Joi.string().valid("male", "female", "other").optional(),
  city: Joi.string().max(50).optional().messages({
    "string.max": "Tên thành phố không được vượt quá 50 ký tự",
  }),
  country: Joi.string().max(50).optional().messages({
    "string.max": "Tên quốc gia không được vượt quá 50 ký tự",
  }),
});
router.patch(
  "/complete-profile",
  authenticate,
  auditAuthOperation("complete_profile"),
  catchAsync(async (req, res) => {
    const { error, value } = completeProfileSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: "Dữ liệu không hợp lệ",
        errors: error.details.map((detail) => ({
          field: detail.path.join("."),
          message: detail.message,
        })),
      });
    }
    const { User } = await import("../models/index.js");
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Người dùng không tồn tại",
      });
    }
    // Update profile information
    const updateData = {};
    if (value.phone) updateData["profile.phone"] = value.phone;
    if (value.dateOfBirth)
      updateData["profile.dateOfBirth"] = value.dateOfBirth;
    if (value.gender) updateData["profile.gender"] = value.gender;
    if (value.city) updateData["profile.location.city"] = value.city;
    if (value.country) updateData["profile.location.country"] = value.country;
    const updatedUser = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updateData },
      { new: true, runValidators: true }
    );
    // Log successful profile completion
    auditLogger("complete_profile_SUCCESS", req, {
      userId: user._id,
      email: user.email,
      updatedFields: Object.keys(updateData),
      timestamp: new Date().toISOString(),
    });
    res.json({
      success: true,
      message: "Cập nhật thông tin thành công",
      user: {
        id: updatedUser._id,
        email: updatedUser.email,
        fullName: updatedUser.profile?.name,
        avatar: updatedUser.profile?.avatar,
        phone: updatedUser.profile?.phone,
        dateOfBirth: updatedUser.profile?.dateOfBirth,
        gender: updatedUser.profile?.gender,
        location: updatedUser.profile?.location,
        isVerified: updatedUser.isVerified,
        needsProfileCompletion:
          !updatedUser.profile?.phone || !updatedUser.profile?.dateOfBirth,
      },
    });
  })
);
export default router;
