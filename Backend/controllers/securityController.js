import { User } from "../models/index.js";
import bcrypt from "bcryptjs";
import { successResponse, errorResponse } from "../middleware/errorHandler.js";
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

// Change password
export const changePassword = async (req, res) => {
  try {
    const userId = req.userId; // Use req.userId instead of req.user.userId
    const { currentPassword, newPassword } = req.body;

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
    return errorResponse(res, "Lỗi server", 500);
  }
};

// Terminate specific session
export const terminateSession = async (req, res) => {
  try {
    const userId = req.userId;
    const { sessionId } = req.params;

    console.log(`Terminating session ${sessionId} for user ${userId}`);

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

    console.log(
      `Terminating all sessions for user ${userId} except ${currentSessionId}`
    );

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
    return errorResponse(res, "Lỗi server", 500);
  }
};
