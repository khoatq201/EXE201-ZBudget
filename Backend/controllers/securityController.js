import bcrypt from "bcryptjs";
import speakeasy from "speakeasy";
import QRCode from "qrcode";
import { User } from "../models/index.js";
import { successResponse, errorResponse } from "../utils/responseHelpers.js";

/**
 * @desc    Thay đổi mật khẩu
 * @route   PUT /api/security/change-password
 * @access  Private
 */
export const changePassword = async (req, res) => {
  try {
    const userId = req.userId;
    const { currentPassword, newPassword } = req.body;

    // Validate input
    if (!currentPassword || !newPassword) {
      return errorResponse(res, "Vui lòng nhập đầy đủ thông tin", 400);
    }

    if (newPassword.length < 6) {
      return errorResponse(res, "Mật khẩu mới phải có ít nhất 6 ký tự", 400);
    }

    // Get user with password
    const user = await User.findById(userId).select("+password");
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(
      currentPassword,
      user.password
    );
    if (!isCurrentPasswordValid) {
      return errorResponse(res, "Mật khẩu hiện tại không đúng", 400);
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 12);

    // Update password and security settings
    user.password = hashedNewPassword;
    user.settings.security.lastPasswordChange = new Date();
    user.settings.security.failedLoginAttempts = 0;
    user.settings.security.accountLockedUntil = null;

    // Log security event
    user.settings.security.securityEvents.push({
      type: "password_changed",
      timestamp: new Date(),
      details: {},
      ipAddress: req.ip || "unknown",
      userAgent: req.get("User-Agent") || "unknown",
    });

    await user.save();

    return successResponse(res, null, "Thay đổi mật khẩu thành công");
  } catch (error) {
    console.error("Error in changePassword:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Lấy danh sách phiên đăng nhập đang hoạt động
 * @route   GET /api/security/sessions
 * @access  Private
 */
export const getActiveSessions = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId).select(
      "settings.security.activeSessions"
    );

    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    const activeSessions = user.settings.security.activeSessions || [];

    return successResponse(
      res,
      {
        sessions: activeSessions,
        totalSessions: activeSessions.length,
      },
      "Lấy danh sách phiên thành công"
    );
  } catch (error) {
    console.error("Error in getActiveSessions:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Kết thúc một phiên đăng nhập cụ thể
 * @route   DELETE /api/security/sessions/:sessionId
 * @access  Private
 */
export const terminateSession = async (req, res) => {
  try {
    const userId = req.userId;
    const { sessionId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    // Remove the session
    user.settings.security.activeSessions =
      user.settings.security.activeSessions.filter(
        (session) => session.sessionId !== sessionId
      );

    // Log security event
    user.settings.security.securityEvents.push({
      type: "session_terminated",
      timestamp: new Date(),
      details: { sessionId },
      ipAddress: req.ip || "unknown",
      userAgent: req.get("User-Agent") || "unknown",
    });

    await user.save();

    return successResponse(res, null, "Kết thúc phiên đăng nhập thành công");
  } catch (error) {
    console.error("Error in terminateSession:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Kết thúc tất cả phiên đăng nhập khác
 * @route   DELETE /api/security/sessions
 * @access  Private
 */
export const terminateAllOtherSessions = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    // Keep only current session (if exists)
    const currentToken = req.headers.authorization?.replace("Bearer ", "");
    user.settings.security.activeSessions =
      user.settings.security.activeSessions.filter(
        (session) => session.token === currentToken
      );

    // Log security event
    user.settings.security.securityEvents.push({
      type: "all_sessions_terminated",
      timestamp: new Date(),
      details: {},
      ipAddress: req.ip || "unknown",
      userAgent: req.get("User-Agent") || "unknown",
    });

    await user.save();

    return successResponse(
      res,
      null,
      "Đã kết thúc tất cả phiên đăng nhập khác"
    );
  } catch (error) {
    console.error("Error in terminateAllOtherSessions:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Tạo mã QR cho xác thực 2 bước
 * @route   POST /api/security/setup-2fa
 * @access  Private
 */
export const setup2FA = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    if (user.settings.security.twoFactorEnabled) {
      return errorResponse(res, "Xác thực 2 bước đã được kích hoạt", 400);
    }

    // Generate secret
    const secret = speakeasy.generateSecret({
      name: `ZBudget (${user.email})`,
      issuer: "ZBudget",
    });

    // Generate QR Code
    const qrCode = await QRCode.toDataURL(secret.otpauth_url);

    // Store secret temporarily
    user.settings.security.twoFactorSecret = secret.base32;
    await user.save();

    return successResponse(
      res,
      {
        secret: secret.base32,
        qrCode,
        manualEntryKey: secret.base32,
      },
      "Tạo mã QR thành công"
    );
  } catch (error) {
    console.error("Error in setup2FA:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Kích hoạt xác thực 2 bước
 * @route   POST /api/security/enable-2fa
 * @access  Private
 */
export const enable2FA = async (req, res) => {
  try {
    const userId = req.userId;
    const { token } = req.body;

    if (!token) {
      return errorResponse(res, "Vui lòng nhập mã xác thực", 400);
    }

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    if (!user.settings.security.twoFactorSecret) {
      return errorResponse(res, "Vui lòng thiết lập 2FA trước", 400);
    }

    // Verify token
    const verified = speakeasy.totp.verify({
      secret: user.settings.security.twoFactorSecret,
      encoding: "base32",
      token,
      window: 2,
    });

    if (!verified) {
      return errorResponse(res, "Mã xác thực không đúng", 400);
    }

    // Enable 2FA
    user.settings.security.twoFactorEnabled = true;

    // Log security event
    user.settings.security.securityEvents.push({
      type: "two_factor_enabled",
      timestamp: new Date(),
      details: {},
      ipAddress: req.ip || "unknown",
      userAgent: req.get("User-Agent") || "unknown",
    });

    await user.save();

    return successResponse(res, null, "Kích hoạt xác thực 2 bước thành công");
  } catch (error) {
    console.error("Error in enable2FA:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Tắt xác thực 2 bước
 * @route   POST /api/security/disable-2fa
 * @access  Private
 */
export const disable2FA = async (req, res) => {
  try {
    const userId = req.userId;
    const { currentPassword } = req.body;

    if (!currentPassword) {
      return errorResponse(res, "Vui lòng nhập mật khẩu hiện tại", 400);
    }

    const user = await User.findById(userId).select("+password");
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(
      currentPassword,
      user.password
    );
    if (!isPasswordValid) {
      return errorResponse(res, "Mật khẩu không đúng", 400);
    }

    // Disable 2FA
    user.settings.security.twoFactorEnabled = false;
    user.settings.security.twoFactorSecret = null;

    // Log security event
    user.settings.security.securityEvents.push({
      type: "two_factor_disabled",
      timestamp: new Date(),
      details: {},
      ipAddress: req.ip || "unknown",
      userAgent: req.get("User-Agent") || "unknown",
    });

    await user.save();

    return successResponse(
      res,
      {
        message: "Xác thực 2 bước đã được tắt thành công",
        securityRecommendation:
          "Bạn nên bật lại xác thực 2 bước để bảo vệ tài khoản tốt hơn",
      },
      "Tắt xác thực 2 bước thành công"
    );
  } catch (error) {
    console.error("Error in disable2FA:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Xác thực mã 2FA
 * @route   POST /api/security/verify-2fa
 * @access  Private
 */
export const verify2FA = async (req, res) => {
  try {
    const userId = req.userId;
    const { token } = req.body;

    if (!token) {
      return errorResponse(res, "Vui lòng nhập mã xác thực", 400);
    }

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    if (
      !user.settings.security.twoFactorEnabled ||
      !user.settings.security.twoFactorSecret
    ) {
      return errorResponse(res, "Xác thực 2 bước chưa được kích hoạt", 400);
    }

    // Verify token
    const isValid = speakeasy.totp.verify({
      secret: user.settings.security.twoFactorSecret,
      encoding: "base32",
      token,
      window: 2,
    });

    return successResponse(
      res,
      {
        verified: isValid,
        message: isValid ? "Mã xác thực đúng" : "Mã xác thực không đúng",
      },
      "Xác thực thành công"
    );
  } catch (error) {
    console.error("Error in verify2FA:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Lấy thống kê bảo mật
 * @route   GET /api/security/stats
 * @access  Private
 */
export const getSecurityStats = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    const securitySettings = user.settings.security;

    const stats = {
      lastPasswordChange: securitySettings.lastPasswordChange,
      twoFactorEnabled: securitySettings.twoFactorEnabled,
      activeSessions: securitySettings.activeSessions?.length || 0,
      recentSecurityEvents: securitySettings.securityEvents?.slice(-5) || [],
      accountStatus: {
        isLocked:
          securitySettings.accountLockedUntil &&
          new Date(securitySettings.accountLockedUntil) > new Date(),
        failedLoginAttempts: securitySettings.failedLoginAttempts,
      },
    };

    return successResponse(res, stats, "Lấy thống kê bảo mật thành công");
  } catch (error) {
    console.error("Error in getSecurityStats:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};

/**
 * @desc    Lấy cài đặt bảo mật
 * @route   GET /api/security/settings
 * @access  Private
 */
export const getSecuritySettings = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Không tìm thấy người dùng", 404);
    }

    const settings = {
      biometricEnabled: user.settings.security.biometricEnabled || false,
      twoFactorEnabled: user.settings.security.twoFactorEnabled || false,
      sessionManagement: user.settings.security.sessionManagement || false,
      privacyProtection: user.settings.security.privacyProtection || false,
      loginDevices: user.settings.security.activeSessions || [],
    };

    return successResponse(res, settings, "Lấy cài đặt bảo mật thành công");
  } catch (error) {
    console.error("Error in getSecuritySettings:", error);
    return errorResponse(res, "Lỗi server", 500);
  }
};
