import bcryptjs from "bcryptjs";
const bcrypt = bcryptjs;
import jwt from "jsonwebtoken";
import crypto from "crypto";
import User from "../models/User.js";
import SessionService from "../services/SessionService.js";
import {
  BadRequestError,
  UnauthorizedError,
  NotFoundError,
  ConflictError,
  successResponse,
} from "../middleware/errorHandler.js";
import {
  generateTokens,
  verifyRefreshToken,
  blacklistToken,
} from "../middleware/auth.js";
import {
  securityLogger,
  auditLogger,
  errorLogger,
} from "../middleware/logger.js";
import {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendPasswordResetOTP,
  sendWelcomeEmail,
} from "../services/emailService.js";
import { getFileUrl, deleteFile } from "../middleware/upload.js";

// ✅ NEW: Import utilities and services
import { addMinutes, addDays, addHours } from "../utils/dateHelper.js";
import UserService from "../services/userService.js";
/**
 * @desc    Đăng ký tài khoản mới
 * @route   POST /api/auth/register
 * @access  Public
 */
export const register = async (req, res) => {
  const startTime = Date.now();
  try {
    // Step 1: Extract request data
    const { fullName, email, password, phoneNumber, dateOfBirth, gender } =
      req.body;
    // Step 2: Check existing user
    const dbStartTime = Date.now();

    // Check email first
    const existingUserByEmail = await User.findOne({
      email: email.toLowerCase(),
    });
    const dbDuration = Date.now() - dbStartTime;

    if (existingUserByEmail) {
      securityLogger("REGISTRATION_ATTEMPT_DUPLICATE_EMAIL", req, {
        email: email.toLowerCase(),
      });
      throw new ConflictError(
        `Email '${email}' đã được sử dụng. Vui lòng sử dụng email khác hoặc đăng nhập.`
      );
    }

    // Check phone number if provided
    if (phoneNumber) {
      const existingUserByPhone = await User.findOne({
        "profile.phone": phoneNumber,
      });

      if (existingUserByPhone) {
        securityLogger("REGISTRATION_ATTEMPT_DUPLICATE_PHONE", req, {
          phoneNumber,
        });
        throw new ConflictError(
          `Số điện thoại '${phoneNumber}' đã được sử dụng. Vui lòng sử dụng số điện thoại khác.`
        );
      }
    }
    // Step 3: Hash password
    const saltStartTime = Date.now();
    const salt = await bcrypt.genSalt(12);
    const saltDuration = Date.now() - saltStartTime;
    const hashStartTime = Date.now();
    const passwordHash = await bcrypt.hash(password, salt);
    const hashDuration = Date.now() - hashStartTime;
    // Step 4: Generate OTP for email verification
    const emailVerificationOTP = Math.floor(
      100000 + Math.random() * 900000
    ).toString(); // 6-digit OTP
    const emailVerificationExpires = addMinutes(10); // ✅ Using dateHelper
    // Step 5: Prepare user data
    const userData = {
      email: email.toLowerCase(),
      passwordHash,
      emailVerificationOTP,
      emailVerificationExpires,
      // ✅ FIX: Map fullName to profile.name (required by User schema)
      profile: {
        name: fullName, // ✅ This was missing!
        preferences: {
          currency: "VND",
          language: "vi",
          notifications: {
            email: true,
            push: true,
            sms: false,
          },
        },
      },
    };
    // Add optional fields to profile
    if (phoneNumber) {
      userData.profile.phone = phoneNumber; // ✅ Map to profile.phone
    }
    if (dateOfBirth) {
      try {
        let parsedDate;
        if (typeof dateOfBirth === "string") {
          // Handle different date formats
          if (dateOfBirth.includes("/")) {
            // Format: DD/MM/YYYY
            const parts = dateOfBirth.split("/");
            if (parts.length === 3) {
              // Assume DD/MM/YYYY format for Vietnamese locale
              parsedDate = new Date(`${parts[2]}-${parts[1]}-${parts[0]}`);
            }
          } else {
            // ISO format or other standard format
            parsedDate = new Date(dateOfBirth);
          }
        } else {
          parsedDate = new Date(dateOfBirth);
        }
        if (isNaN(parsedDate.getTime())) {
        } else {
          userData.profile.dateOfBirth = parsedDate; // ✅ Map to profile.dateOfBirth
        }
      } catch (dateError) {}
    }
    if (gender) {
      userData.profile.gender = gender; // ✅ Map to profile.gender
    }
    // Step 6: Store temporary user data (not create user yet)
    const tempUserKey = `temp_user_${email.toLowerCase()}`;
    // Store temporary user data in memory/cache (you can use Redis in production)
    global.tempUsers = global.tempUsers || new Map();
    global.tempUsers.set(tempUserKey, {
      ...userData,
      createdAt: new Date(),
      expiresAt: addMinutes(15), // ✅ Using dateHelper
    });
    // Step 7: Skip token generation (will generate after OTP verification)
    // Step 8: Prepare response data (without user data, only confirmation)
    const responseData = {
      success: true,
      message:
        "Mã OTP đã được gửi đến email của bạn. Vui lòng xác thực để hoàn tất đăng ký.",
      data: {
        email: email.toLowerCase(),
        otpSent: true,
        expiresIn: 600, // 10 minutes in seconds
      },
    };
    // Step 9: Send verification email SYNCHRONOUSLY
    const emailStartTime = Date.now();
    try {
      const emailResult = await sendVerificationEmail(
        email.toLowerCase(),
        fullName,
        emailVerificationOTP
      );
      const emailDuration = Date.now() - emailStartTime;

      if (emailResult.success) {
        console.log(
          `✅ DEBUG: Verification email sent successfully in ${emailDuration}ms`
        );
      } else {
        console.error(
          `❌ DEBUG: Failed to send verification email in ${emailDuration}ms:`,
          emailResult.error
        );
        // Delete temp user data if email failed
        global.tempUsers.delete(tempUserKey);
        throw new BadRequestError(
          "Không thể gửi email xác thực. Vui lòng thử lại sau."
        );
      }
    } catch (emailError) {
      const emailDuration = Date.now() - emailStartTime;
      console.error(
        `❌ DEBUG: Failed to send verification email in ${emailDuration}ms:`,
        emailError
      );
      // Delete temp user data if email failed
      global.tempUsers.delete(tempUserKey);
      throw new BadRequestError(
        "Không thể gửi email xác thực. Vui lòng thử lại sau."
      );
    }

    // Step 10: Send response ONLY AFTER email is sent successfully
    const responseStartTime = Date.now();
    res.status(201).json(responseData);
    const responseDuration = Date.now() - responseStartTime;
    const totalDuration = Date.now() - startTime;
  } catch (error) {
    const errorDuration = Date.now() - startTime;
    console.error(
      `💥 DEBUG: Registration error occurred after ${errorDuration}ms:`,
      error
    );
    console.error("📋 DEBUG: Error details:", {
      name: error.name,
      message: error.message,
      stack: error.stack?.split("\n")[0], // Only first line of stack
    });
    errorLogger(error, req);
    throw error; // Re-throw để errorHandler middleware xử lý
  }
};
/**
 * @desc    Đăng nhập
 * @route   POST /api/auth/login
 * @access  Public
 */
export const login = async (req, res) => {
  const { email, password, rememberMe } = req.body;
  // ✅ FIX: Explicitly select passwordHash
  const user = await User.findOne({
    email: email.toLowerCase(),
    isActive: true,
  }).select("+passwordHash"); // ✅ Add this line!
  if (user) {
  }
  if (!user) {
    securityLogger("LOGIN_FAILED_INVALID_EMAIL", req, { email });
    throw new UnauthorizedError("Email hoặc mật khẩu không chính xác");
  }
  // ✅ Now passwordHash should exist
  if (!user.passwordHash) {
    throw new UnauthorizedError(
      "Tài khoản chưa được thiết lập hoàn chỉnh. Vui lòng đăng ký lại."
    );
  }
  // Verify password (now safe to call)
  const isValidPassword = await bcrypt.compare(password, user.passwordHash);
  if (!isValidPassword) {
    // Handle failed attempts...
    securityLogger("LOGIN_FAILED_INVALID_PASSWORD", req, {
      userId: user._id,
    });
    throw new UnauthorizedError("Email hoặc mật khẩu không chính xác");
  }
  // Success - generate tokens and return response
  const { accessToken, refreshToken, jwtTokenId } = await generateTokens(
    user._id,
    req,
    "password"
  );
  // ✅ DEVICE TRACKING: Create session với device info
  try {
    // Calculate expiry based on rememberMe - ✅ Using dateHelper
    const expiresAt = rememberMe ? addDays(30) : addDays(7);
    await SessionService.createSession(
      user._id,
      jwtTokenId, // JWT token ID
      req,
      expiresAt,
      "password"
    );
  } catch (sessionError) {
    console.error("❌ Failed to create session:", sessionError);
    // Continue với login process, session không critical
  }
  // Update user login info WITHOUT triggering validation
  await User.updateOne(
    { _id: user._id },
    {
      lastLogin: new Date(),
      $inc: { loginCount: 1 },
    },
    { runValidators: false } // ← SKIP validation to avoid sessionTimeout error
  );
  // Remove sensitive data from response
  const userResponse = user.toObject();
  delete userResponse.passwordHash;
  return successResponse(res, "Đăng nhập thành công!", {
    user: userResponse,
    tokens: {
      accessToken,
      refreshToken,
      expiresIn: "7d", // Default token expiry
    },
  });
};
/**
 * @desc    Đăng xuất
 * @route   POST /api/auth/logout
 * @access  Private
 */
export const logout = async (req, res) => {
  const userId = req.userId;
  const token = req.token;
  // Blacklist current access token
  await blacklistToken(token);
  // Cleanup session
  try {
    await SessionService.terminateSessionByToken(token);
  } catch (sessionError) {
    console.error("❌ Failed to terminate session:", sessionError);
    // Don't fail logout if session cleanup fails
  }
  // Remove refresh token from user
  const refreshToken = req.body.refreshToken || req.headers["x-refresh-token"];
  if (refreshToken) {
    await User.updateOne(
      { _id: userId },
      { $pull: { refreshTokens: { token: refreshToken } } }
    );
  }
  return successResponse(res, "Đăng xuất thành công!");
};
/**
 * @desc    Làm mới access token
 * @route   POST /api/auth/refresh-token
 * @access  Public
 */
export const refreshToken = async (req, res) => {
  const { refreshToken: token } = req.body;
  if (!token) {
    throw new BadRequestError("Refresh token là bắt buộc");
  }
  // Verify refresh token
  const decoded = verifyRefreshToken(token);
  // Find user and validate refresh token
  const user = await User.findById(decoded.userId);
  if (!user || user.isDeleted) {
    throw new UnauthorizedError("Token không hợp lệ");
  }
  // Check if refresh token exists and is valid
  const tokenRecord = user.refreshTokens.find((rt) => rt.token === token);
  if (!tokenRecord || tokenRecord.expiresAt < new Date()) {
    // Remove expired token
    await User.updateOne(
      { _id: user._id },
      { $pull: { refreshTokens: { token: token } } }
    );
    throw new UnauthorizedError("Refresh token đã hết hạn");
  }
  // Generate new tokens
  const { accessToken, refreshToken: newRefreshToken } = await generateTokens(
    user._id,
    req,
    "refresh"
  );
  // Replace old refresh token with new one
  await User.updateOne(
    { _id: user._id, "refreshTokens.token": token },
    {
      $set: {
        "refreshTokens.$.token": newRefreshToken,
        "refreshTokens.$.createdAt": new Date(),
      },
    }
  );
  return successResponse(res, "Token đã được làm mới", {
    accessToken,
    refreshToken: newRefreshToken,
    expiresIn: "15m",
  });
};
/**
 * @desc    Quên mật khẩu
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
export const forgotPassword = async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({
    email: email.toLowerCase(),
    isActive: true, // ✅ Keep as requested
  });
  if (!user) {
    // Don't reveal if email exists
    return successResponse(
      res,
      "Nếu email tồn tại, chúng tôi đã gửi mã OTP đặt lại mật khẩu."
    );
  }
  // Generate OTP instead of token
  const passwordResetOTP = Math.floor(
    100000 + Math.random() * 900000
  ).toString(); // 6-digit OTP
  const passwordResetExpires = addMinutes(10); // ✅ Using dateHelper
  // Store OTP in user record
  user.passwordResetOTP = passwordResetOTP;
  user.passwordResetExpires = passwordResetExpires;
  await user.save();
  // Send OTP email
  try {
    const userName = user.profile?.name || user.fullName || "User";
    await sendPasswordResetOTP(user.email, userName, passwordResetOTP);
  } catch (emailError) {
    user.passwordResetOTP = undefined;
    user.passwordResetExpires = undefined;
    await user.save();
    errorLogger(emailError, req, {
      userId: user._id,
      operation: "forgot_password",
    });
    throw new BadRequestError(
      "Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại sau."
    );
  }
  return successResponse(
    res,
    "Mã OTP đặt lại mật khẩu đã được gửi đến email của bạn.",
    {
      email: email.toLowerCase(),
      otpSent: true,
      expiresIn: 600, // 10 minutes in seconds
    }
  );
};
/**
 * @desc    Xác thực OTP đặt lại mật khẩu
 * @route   POST /api/auth/verify-password-reset-otp
 * @access  Public
 */
export const verifyPasswordResetOTP = async (req, res) => {
  const { email, otp } = req.body;
  const user = await User.findOne({
    email: email.toLowerCase(),
    isActive: true,
  }).select("+passwordResetOTP +passwordResetExpires");
  if (!user) {
    throw new BadRequestError("Email không tồn tại trong hệ thống");
  }
  // Check OTP
  if (!user.passwordResetOTP || user.passwordResetOTP != otp) {
    throw new BadRequestError("Mã OTP không chính xác");
  }
  // Check expiration
  if (!user.passwordResetExpires || user.passwordResetExpires < new Date()) {
    throw new BadRequestError("Mã OTP đã hết hạn");
  }
  // OTP is valid - return success but don't clear OTP yet (will clear after password reset)
  return successResponse(res, "Mã OTP hợp lệ. Bạn có thể đặt lại mật khẩu.", {
    email: email.toLowerCase(),
    otpVerified: true,
  });
};
/**
 * @desc    Đặt lại mật khẩu với OTP
 * @route   POST /api/auth/reset-password
 * @access  Public
 */
export const resetPassword = async (req, res) => {
  const { email, otp, newPassword } = req.body;
  // Find user with valid OTP
  const user = await User.findOne({
    email: email.toLowerCase(),
    isActive: true,
  }).select("+passwordResetOTP +passwordResetExpires");
  if (!user) {
    throw new BadRequestError("Email không tồn tại trong hệ thống");
  }
  // Verify OTP again for security
  if (!user.passwordResetOTP || user.passwordResetOTP != otp) {
    throw new BadRequestError("Mã OTP không chính xác");
  }
  if (!user.passwordResetExpires || user.passwordResetExpires < new Date()) {
    throw new BadRequestError("Mã OTP đã hết hạn");
  }
  // Hash new password
  const salt = await bcrypt.genSalt(12);
  user.passwordHash = await bcrypt.hash(newPassword, salt);
  // Clear reset OTP
  user.passwordResetOTP = undefined;
  user.passwordResetExpires = undefined;
  // Reset login attempts
  user.loginAttempts = 0;
  user.lockUntil = undefined;
  // Invalidate all refresh tokens
  user.refreshTokens = [];
  await user.save();
  return successResponse(res, "Mật khẩu đã được đặt lại thành công!");
};
/**
 * @desc    Xác thực OTP email
 * @route   POST /api/auth/verify-otp
 * @access  Public
 */
export const verifyOTP = async (req, res) => {
  const startTime = Date.now();
  try {
    const { email, otp } = req.body;
    // Get temporary user data
    const tempUserKey = `temp_user_${email.toLowerCase()}`;
    global.tempUsers = global.tempUsers || new Map();
    const tempUserData = global.tempUsers.get(tempUserKey);
    if (!tempUserData) {
      throw new BadRequestError(
        "Phiên đăng ký đã hết hạn. Vui lòng đăng ký lại."
      );
    }
    // Check if temporary data is expired
    if (tempUserData.expiresAt < new Date()) {
      global.tempUsers.delete(tempUserKey);
      throw new BadRequestError(
        "Phiên đăng ký đã hết hạn. Vui lòng đăng ký lại."
      );
    }
    // Verify OTP
    if (tempUserData.emailVerificationOTP !== otp) {
      throw new BadRequestError("Mã OTP không chính xác");
    }
    if (tempUserData.emailVerificationExpires < new Date()) {
      throw new BadRequestError("Mã OTP đã hết hạn");
    }
    // Check if user already exists (double check)
    const existingUser = await User.findOne({
      email: email.toLowerCase(),
    });
    if (existingUser) {
      global.tempUsers.delete(tempUserKey);
      throw new BadRequestError("Email đã được sử dụng");
    }
    // Create user with verified email
    const finalUserData = {
      ...tempUserData,
      emailVerified: true,
      emailVerificationOTP: undefined,
      emailVerificationExpires: undefined,
    };
    // Create user without triggering pre-save middleware (since password is already hashed)
    const user = new User(finalUserData);
    await user.save({ validateBeforeSave: true });
    // Remove temporary data
    global.tempUsers.delete(tempUserKey);
    // Generate JWT tokens for the new user
    const tokens = await generateTokens(user._id.toString(), req, "password");
    // Send welcome email asynchronously
    setImmediate(async () => {
      try {
        await sendWelcomeEmail(user.email, user.profile.name);
      } catch (emailError) {
        console.error(
          "⚠️ DEBUG: Failed to send welcome email (async):",
          emailError
        );
      }
    });
    const totalDuration = Date.now() - startTime;
    res.json({
      success: true,
      message: "Đăng ký tài khoản thành công!",
      data: {
        verified: true,
        user: {
          id: user._id,
          email: user.email,
          fullName: user.profile.name,
          phoneNumber: user.profile.phone,
          dateOfBirth: user.profile.dateOfBirth,
          gender: user.profile.gender,
          emailVerified: user.isEmailVerified,
          profile: user.profile,
          createdAt: user.createdAt,
        },
        tokens: tokens,
      },
    });
  } catch (error) {
    const errorDuration = Date.now() - startTime;
    console.error(
      `💥 DEBUG: OTP verification error after ${errorDuration}ms:`,
      error
    );
    throw error;
  }
};
/**
 * @desc    Xác thực email
 * @route   GET /api/auth/verify-email/:token
 * @access  Public
 */
export const verifyEmail = async (req, res) => {
  const { token } = req.params;
  const user = await User.findOne({
    emailVerificationToken: token,
    emailVerificationExpires: { $gt: new Date() },
    isDeleted: false,
  });
  if (!user) {
    throw new BadRequestError(
      "Token xác thực email không hợp lệ hoặc đã hết hạn"
    );
  }
  // Mark email as verified
  user.isEmailVerified = true;
  user.emailVerificationToken = undefined;
  user.emailVerificationExpires = undefined;
  await user.save();
  // Send welcome email
  try {
    await sendWelcomeEmail(user.email, user.fullName);
  } catch (emailError) {
    console.error("Failed to send welcome email:", emailError);
  }
  return successResponse(res, "Email đã được xác thực thành công!");
};
/**
 * @desc    Gửi lại email xác thực
 * @route   POST /api/auth/resend-verification
 * @access  Private
 */
export const resendEmailVerification = async (req, res) => {
  const userId = req.userId;
  const user = await User.findById(userId);
  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }
  if (user.isEmailVerified) {
    throw new BadRequestError("Email đã được xác thực");
  }
  // Generate new verification token
  const emailVerificationToken = crypto.randomBytes(32).toString("hex");
  user.emailVerificationToken = emailVerificationToken;
  user.emailVerificationExpires = addHours(24); // ✅ Using dateHelper
  await user.save();
  // Send verification email
  try {
    await sendVerificationEmail(
      user.email,
      user.fullName,
      emailVerificationToken
    );
  } catch (emailError) {
    errorLogger(emailError, req, { userId, operation: "resend_verification" });
    throw new BadRequestError(
      "Không thể gửi email xác thực. Vui lòng thử lại sau."
    );
  }
  return successResponse(res, "Email xác thực đã được gửi lại!");
};
/**
 * @desc    Đổi mật khẩu
 * @route   POST /api/auth/change-password
 * @access  Private
 */
export const changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.userId;
  const user = await User.findById(userId);
  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }
  // Verify current password
  const isValidPassword = await bcrypt.compare(
    currentPassword,
    user.passwordHash
  );
  if (!isValidPassword) {
    securityLogger("PASSWORD_CHANGE_FAILED_INVALID_CURRENT", req, { userId });
    throw new UnauthorizedError("Mật khẩu hiện tại không chính xác");
  }
  // Check if new password is different from current
  const isSamePassword = await bcrypt.compare(newPassword, user.passwordHash);
  if (isSamePassword) {
    throw new BadRequestError("Mật khẩu mới phải khác mật khẩu hiện tại");
  }
  // Hash new password
  const salt = await bcrypt.genSalt(12);
  user.passwordHash = await bcrypt.hash(newPassword, salt);
  // Invalidate all refresh tokens except current session
  user.refreshTokens = [];
  await user.save();
  return successResponse(res, "Mật khẩu đã được thay đổi thành công!");
};
/**
 * @desc    Lấy thông tin profile
 * @route   GET /api/auth/profile
 * @access  Private
 */
export const getProfile = async (req, res) => {
  const userId = req.userId;
  const user = await User.findById(userId).select(
    "-passwordHash -refreshTokens -emailVerificationToken -passwordResetToken -loginAttempts -lockUntil"
  );
  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }
  return successResponse(res, "Lấy thông tin profile thành công", { user });
};
/**
 * @desc    Cập nhật profile
 * @route   PUT /api/auth/profile
 * @access  Private
 */
export const updateProfile = async (req, res) => {
  const userId = req.userId;
  const {
    fullName,
    phoneNumber,
    dateOfBirth,
    gender,
    preferences,
    avatarFile,
  } = req.body;
  const user = await User.findById(userId);
  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }
  // Check if phone number is already used by another user
  if (phoneNumber && phoneNumber !== user.phoneNumber) {
    const existingUser = await User.findOne({
      phoneNumber,
      _id: { $ne: userId },
      isDeleted: false,
    });
    if (existingUser) {
      throw new ConflictError("Số điện thoại này đã được sử dụng");
    }
  }
  // Handle avatar upload
  if (avatarFile) {
    // Delete old avatar if exists
    if (user.avatar) {
      try {
        await deleteFile(user.avatar);
      } catch (error) {
        console.error("Error deleting old avatar:", error);
      }
    }
    // Set new avatar URL
    user.avatar = getFileUrl(avatarFile);
  }
  // Update user fields
  if (fullName) user.fullName = fullName;
  if (phoneNumber) user.phoneNumber = phoneNumber;
  if (dateOfBirth) user.dateOfBirth = dateOfBirth;
  if (gender) user.gender = gender;
  // Update preferences
  if (preferences) {
    if (!user.profile) user.profile = {};
    user.profile.preferences = { ...user.profile.preferences, ...preferences };
  }
  await user.save();
  // Remove sensitive data from response
  const userResponse = user.toObject();
  delete userResponse.passwordHash;
  delete userResponse.refreshTokens;
  delete userResponse.emailVerificationToken;
  delete userResponse.passwordResetToken;
  delete userResponse.loginAttempts;
  delete userResponse.lockUntil;
  return successResponse(res, "Cập nhật profile thành công!", {
    user: userResponse,
  });
};
/**
 * @desc    Xóa tài khoản
 * @route   DELETE /api/auth/account
 * @access  Private
 */
export const deleteAccount = async (req, res) => {
  const { password, reason } = req.body;
  const userId = req.userId;
  const user = await User.findById(userId);
  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }
  // Verify password
  const isValidPassword = await bcrypt.compare(password, user.passwordHash);
  if (!isValidPassword) {
    securityLogger("ACCOUNT_DELETE_FAILED_INVALID_PASSWORD", req, { userId });
    throw new UnauthorizedError("Mật khẩu không chính xác");
  }
  // Soft delete user
  user.isDeleted = true;
  user.deletedAt = new Date();
  user.deletionReason = reason;
  // Clear sensitive data
  user.refreshTokens = [];
  user.emailVerificationToken = undefined;
  user.passwordResetToken = undefined;
  // Blacklist current token
  await blacklistToken(req.token);
  await user.save();
  return successResponse(res, "Tài khoản đã được xóa thành công!");
};

/**
 * @desc    Tìm kiếm users theo tên
 * @route   GET /api/auth/search-users?q=name
 * @access  Private
 */
export const searchUsers = async (req, res) => {
  const { q } = req.query;

  console.log("🔍 Search users query:", q);

  if (!q || q.trim().length < 2) {
    throw new BadRequestError("Từ khóa tìm kiếm phải có ít nhất 2 ký tự");
  }

  // Search by name using regex (case insensitive)
  const users = await User.find({
    "profile.name": { $regex: q.trim(), $options: "i" },
    isActive: true,
    $or: [{ isDeleted: { $exists: false } }, { isDeleted: false }],
  })
    .select("_id profile.name profile.avatar email")
    .limit(20);

  console.log("📋 Found users:", users.length);

  // Format response
  const formattedUsers = users.map((user) => ({
    id: user._id,
    name: user.profile?.name || user.email,
    avatar: user.profile?.avatar,
    email: user.email,
  }));

  console.log("✅ Formatted users:", JSON.stringify(formattedUsers));

  return successResponse(res, "Tìm kiếm thành công", { users: formattedUsers });
};
