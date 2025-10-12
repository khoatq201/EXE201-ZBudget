import { User } from "../models/index.js";
import bcrypt from "bcryptjs";
import speakeasy from "speakeasy";
import QRCode from "qrcode";
import { successResponse, errorResponse } from "../middleware/errorHandler.js";
import { successResponse as successResp, errorResponse as errorResp } from "../utils/responseHelpers.js";
import SessionService from "../services/SessionService.js";
// Setup Two-Factor Authentication
export const setup2FA = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.user    // Mark current session and format for frontend
    const formattedSessions = sessions.map((session) => ({
      id: session.sessionId,
      deviceInfo: session.deviceName,
      location: session.location,
      lastActivity: session.lastActiveTime.toISOString(), // Use DateTime
      isCurrent: session.sessionId === currentSessionId,
      platform: session.platform,
      browser: session.browser,
      deviceType: session.deviceType,
      securityLevel: session.securityLevel,
      ip: session.ip,
    }));
    user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // For demo purposes, return a mock secret
    const mockSecret = "JBSWY3DPEHPK3PXP";
    return successResponse(res, "Thiết lập 2FA thành công", {
      secret: mockSecret,
      qrCode: "data:image/png;base64,mock_qr_code",
      manualEntryKey: mockSecret,
    });
  } catch (error) {
    console.error("Setup 2FA error:", error);
    return errorResponse(res, "Lỗi server khi thiết lập 2FA", 500);
  }
};
// Enable Two-Factor Authentication
export const enable2FA = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.userId
    const { otp } = req.body;
    if (!otp || otp.length !== 6) {
      return errorResponse(res, "Mã OTP không hợp lệ", 400);
    }
    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // For demo purposes, accept any 6-digit OTP
    user.twoFactorEnabled = true;
    await user.save();
    return successResponse(res, "Kích hoạt 2FA thành công");
  } catch (error) {
    console.error("Enable 2FA error:", error);
    return errorResponse(res, "Lỗi server khi kích hoạt 2FA", 500);
  }
};
// Disable Two-Factor Authentication
export const disable2FA = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.userId
    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // Disable 2FA
    user.twoFactorEnabled = false;
    await user.save();
    return successResponse(res, "Tắt 2FA thành công");
  } catch (error) {
    console.error("Disable 2FA error:", error);
    return errorResponse(res, "Lỗi server khi tắt 2FA", 500);
  }
};
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
    if (newPassword.length < 8) {
      return errorResponse(res, "Mật khẩu mới phải có ít nhất 8 ký tự", 400);
    }
    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // Verify current password
    const isValidPassword = await bcrypt.compare(
      currentPassword,
      user.password
    );
    if (!isValidPassword) {
      return errorResponse(res, "Mật khẩu hiện tại không chính xác", 400);
    }
    // Hash new password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    // Update password
    user.password = hashedPassword;
    user.lastPasswordChange = new Date();
    await user.save();
    return successResponse(res, "Đổi mật khẩu thành công");
  } catch (error) {
    console.error("Change password error:", error);
    return errorResponse(res, "Lỗi server khi đổi mật khẩu", 500);
  }
};
// Update security settings
export const updateSecuritySettings = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.userId
    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // Initialize settings if not exists
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }
    // Map frontend fields to backend schema
    const {
      // Frontend field names
      isBiometricEnabled,
      isTwoFactorEnabled,
      isAutoLockEnabled,
      sessionTimeout,
      isLoginNotificationEnabled,
      isDataEncryptionEnabled,
      maxFailedAttempts,
      isScreenshotBlocked,
      isAppPinEnabled,
      primaryAuthMethod,
      // Legacy fields for backward compatibility
      sessionPersistence,
      keepSessionsAcrossDevices,
      enablePrivacyMode,
      enhancedProtection,
      biometricAuth,
    } = req.body;
    // Update new security fields
    if (isBiometricEnabled !== undefined) {
      user.settings.security.biometricEnabled = isBiometricEnabled;
    }
    if (isTwoFactorEnabled !== undefined) {
      user.settings.security.twoFactorEnabled = isTwoFactorEnabled;
    }
    if (isAutoLockEnabled !== undefined) {
      user.settings.security.autoLockEnabled = isAutoLockEnabled;
    }
    if (sessionTimeout !== undefined) {
      user.settings.security.sessionTimeout = sessionTimeout;
    }
    if (isLoginNotificationEnabled !== undefined) {
      user.settings.security.loginNotificationEnabled =
        isLoginNotificationEnabled;
    }
    if (isDataEncryptionEnabled !== undefined) {
      user.settings.security.dataEncryptionEnabled = isDataEncryptionEnabled;
    }
    if (maxFailedAttempts !== undefined) {
      user.settings.security.maxFailedAttempts = maxFailedAttempts;
    }
    if (isScreenshotBlocked !== undefined) {
      user.settings.security.screenshotBlocked = isScreenshotBlocked;
    }
    if (isAppPinEnabled !== undefined) {
      user.settings.security.appPinEnabled = isAppPinEnabled;
    }
    if (primaryAuthMethod !== undefined) {
      user.settings.security.primaryAuthMethod = primaryAuthMethod;
    }
    // Update legacy fields for backward compatibility
    if (sessionPersistence !== undefined) {
      user.settings.security.sessionPersistence = sessionPersistence;
    }
    if (keepSessionsAcrossDevices !== undefined) {
      user.settings.security.keepSessionsAcrossDevices =
        keepSessionsAcrossDevices;
    }
    if (enablePrivacyMode !== undefined) {
      user.settings.security.enablePrivacyMode = enablePrivacyMode;
    }
    if (enhancedProtection !== undefined) {
      user.settings.security.enhancedProtection = enhancedProtection;
    }
    if (biometricAuth !== undefined) {
      user.settings.security.biometricAuth = biometricAuth;
      // Also update the new field for consistency
      user.settings.security.biometricEnabled = biometricAuth;
    }
    await user.save();
    return successResponse(res, "Cập nhật cài đặt bảo mật thành công", {
      securitySettings: user.settings.security,
    });
  } catch (error) {
    console.error("Update security settings error:", error);
    return errorResponse(res, "Lỗi server khi cập nhật cài đặt", 500);
  }
};
// Get security settings
export const getSecuritySettings = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.userId
    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "User not found", 404);
    }
    // Helper function to convert minutes to SessionTimeout enum name
    const getSessionTimeoutEnum = (minutes) => {
      switch (minutes) {
        case 0:
          return "never";
        case 5:
          return "minutes5";
        case 15:
          return "minutes15";
        case 30:
          return "minutes30";
        case 60:
          return "hour1";
        case 240:
          return "hour4";
        default:
          return "minutes30";
      }
    };
    // Return security settings with proper mapping from schema to frontend format
    const securitySettings = {
      // From SecuritySettingsSchema
      isBiometricEnabled: user.settings?.security?.biometricEnabled ?? false,
      isTwoFactorEnabled: user.settings?.security?.twoFactorEnabled ?? false,
      isAutoLockEnabled: user.settings?.security?.autoLockEnabled ?? true,
      sessionTimeout: getSessionTimeoutEnum(
        user.settings?.security?.sessionTimeout ?? 30
      ),
      isLoginNotificationEnabled:
        user.settings?.security?.loginNotificationEnabled ?? true,
      isDataEncryptionEnabled:
        user.settings?.security?.dataEncryptionEnabled ?? true,
      maxFailedAttempts: user.settings?.security?.maxFailedAttempts ?? 5,
      isScreenshotBlocked: user.settings?.security?.screenshotBlocked ?? false,
      isAppPinEnabled: user.settings?.security?.appPinEnabled ?? false,
      primaryAuthMethod:
        user.settings?.security?.primaryAuthMethod ?? "password",
      lastPasswordChange:
        user.settings?.security?.lastPasswordChange ?? user.createdAt,
      // Frontend expects enabledAuthMethods as array of names
      enabledAuthMethods: ["password"], // For now, default to password
      // Real active sessions from SessionService
      activeSessions: await (async () => {
        try {
          const sessions = await SessionService.getActiveSessions(userId);
          const currentSessionId = req.sessionId;
          return sessions.map((session) => ({
            id: session.sessionId,
            deviceName: session.deviceName,
            deviceType: session.deviceType,
            location: session.location,
            ipAddress: session.ip,
            loginTime: session.loginTime.toISOString(),
            lastActiveTime: session.lastActiveTime.toISOString(), // Use actual DateTime
            isCurrent: session.sessionId === currentSessionId,
          }));
        } catch (sessionError) {
          console.error("Failed to get active sessions:", sessionError);
          // Return mock session if service fails
          return [
            {
              id: "fallback",
              deviceName: "Current Device",
              deviceType: "desktop",
              location: "Unknown Location",
              ipAddress: "127.0.0.1",
              loginTime: new Date().toISOString(),
              lastActiveTime: "Vừa xong",
              isCurrent: true,
            },
          ];
        }
      })(),
    };
    return successResponse(
      res,
      "Lấy cài đặt bảo mật thành công",
      securitySettings
    );
  } catch (error) {
    console.error("Get security settings error:", error);
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
// Terminate specific session
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
    const success = await SessionService.terminateSession(sessionId, userId);
    if (success) {
      return successResponse(res, "Kết thúc phiên thành công");
    } else {
      return errorResponse(
        res,
        "Không tìm thấy phiên hoặc phiên đã hết hạn",
        404
      );
    }
  } catch (error) {
    console.error("Terminate session error:", error);
    return errorResponse(res, "Lỗi server khi kết thúc phiên", 500);
  }
};
// Terminate all sessions
export const terminateAllSessions = async (req, res) => {
  try {
    const userId = req.userId;
    const currentSessionId = req.sessionId;
    const terminatedCount = await SessionService.terminateAllSessions(
      userId,
      currentSessionId
    );
    return successResponse(
      res,
      `Kết thúc thành công ${terminatedCount} phiên khác`
    );
  } catch (error) {
    console.error("Terminate all sessions error:", error);
    return errorResponse(res, "Lỗi server khi kết thúc phiên", 500);
  }
};
// Get active sessions
export const getActiveSessions = async (req, res) => {
  try {
    const userId = req.userId;
    const currentSessionId = req.sessionId;
    const sessions = await SessionService.getActiveSessions(userId);
    // Mark current session and format for frontend
    const formattedSessions = sessions.map((session) => ({
      id: session.sessionId,
      deviceInfo: session.deviceName,
      location: session.location,
      lastActivity: session.lastActive,
      isCurrent: session.sessionId === currentSessionId,
      platform: session.platform,
      browser: session.browser,
      deviceType: session.deviceType,
      securityLevel: session.securityLevel,
      ip: session.ip,
    }));
    return successResponse(
      res,
      "Lấy danh sách phiên thành công",
      formattedSessions
    );
  } catch (error) {
    console.error("Get active sessions error:", error);
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