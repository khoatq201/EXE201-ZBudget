import { User } from "../models/index.js";
import bcrypt from "bcryptjs";
import speakeasy from "speakeasy";
import QRCode from "qrcode";
import SessionService from "../services/SessionService.js";
import { successResponse, errorResponse } from "../middleware/errorHandler.js";

/**
 * @desc    Setup Tw  } catch (error) {
    return errorResponse(res, "Lỗi server khi kết thúc phiên", 500);
  }
};tor Authentication
 * @route   POST /api/security/setup-2fa
 * @access  Private
 */
export const setup2FA = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // Khởi tạo settings và security object nếu chưa có
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }

    if (user.settings.security.isTwoFactorEnabled) {
      return errorResponse(res, "2FA đã được kích hoạt", 400);
    }

    const secret = speakeasy.generateSecret({
      name: `ZBudget (${user.profile?.email || user.auth?.email || "User"})`,
      issuer: "ZBudget",
    });

    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

    user.settings.security.twoFactorSecret = secret.base32;
    await user.save();

    return successResponse(res, "Thiết lập 2FA thành công", {
      qrCode: qrCodeUrl,
      secret: secret.base32,
    });
  } catch (error) {
    return errorResponse(res, "Lỗi server khi thiết lập 2FA", 500);
  }
};

/**
 * @desc    Enable Two-Factor Authentication
 * @route   POST /api/security/enable-2fa
 * @access  Private
 */
export const enable2FA = async (req, res) => {
  try {
    const userId = req.userId;
    const { otp } = req.body; // Đổi từ token thành otp để phù hợp với request

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // Khởi tạo settings và security object nếu chưa có
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }

    // Kiểm tra xem secret đã được tạo chưa
    if (!user.settings.security.twoFactorSecret) {
      return errorResponse(
        res,
        "Chưa thiết lập 2FA. Vui lòng gọi setup2FA trước",
        400
      );
    }

    const verified = speakeasy.totp.verify({
      secret: user.settings.security.twoFactorSecret,
      encoding: "base32",
      token: otp,
      window: 2,
    });

    if (!verified) {
      return errorResponse(res, "Mã xác thực không hợp lệ", 400);
    }

    user.settings.security.isTwoFactorEnabled = true;
    user.settings.security.twoFactorEnabled = true; // Update cả hai trường để đồng bộ
    await user.save();

    return successResponse(res, "Kích hoạt 2FA thành công");
  } catch (error) {
    return errorResponse(res, "Lỗi server khi kích hoạt 2FA", 500);
  }
};

/**
 * @desc    Disable Two-Factor Authentication
 * @route   POST /api/security/disable-2fa
 * @access  Private
 */
export const disable2FA = async (req, res) => {
  try {
    const userId = req.userId;
    const { password } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // Khởi tạo settings và security object nếu chưa có
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }

    const isValidPassword = await bcrypt.compare(password, user.auth.password);
    if (!isValidPassword) {
      return errorResponse(res, "Mật khẩu không chính xác", 400);
    }

    user.settings.security.isTwoFactorEnabled = false;
    user.settings.security.twoFactorEnabled = false; // Update cả hai trường để đồng bộ
    user.settings.security.twoFactorSecret = null;
    await user.save();

    return successResponse(res, "Tắt 2FA thành công");
  } catch (error) {
    return errorResponse(res, "Lỗi server khi tắt 2FA", 500);
  }
};

/**
 * @desc    Change password
 * @route   PUT /api/security/change-password
 * @access  Private
 */
export const changePassword = async (req, res) => {
  try {
    const userId = req.userId;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return errorResponse(res, "Vui lòng cung cấp đầy đủ thông tin", 400);
    }

    // ✅ Fix: Get user with passwordHash field (normally excluded)
    const user = await User.findById(userId).select("+passwordHash");
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // ✅ Fix: Compare with passwordHash field, not auth.password
    const isValidPassword = await bcrypt.compare(
      currentPassword,
      user.passwordHash
    );
    if (!isValidPassword) {
      return errorResponse(res, "Mật khẩu hiện tại không chính xác", 400);
    }

    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // ✅ Fix: Update passwordHash field directly
    user.passwordHash = hashedPassword;
    user.profile.lastPasswordChange = new Date();
    await user.save();

    return successResponse(res, "Đổi mật khẩu thành công");
  } catch (error) {
    console.error("❌ Change password error:", error);
    return errorResponse(res, "Lỗi server khi đổi mật khẩu", 500);
  }
};

/**
 * @desc    Get security settings
 * @route   GET /api/security/settings
 * @access  Private
 */
export const getSecuritySettings = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // Khởi tạo settings và security object nếu chưa có
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }

    const security = user.settings.security;

    // Helper function to get boolean values properly (not using || for false values)
    const getBooleanValue = (primary, fallback, defaultValue) => {
      if (primary !== undefined) return primary;
      if (fallback !== undefined) return fallback;
      return defaultValue;
    };

    return successResponse(res, "Lấy cài đặt bảo mật thành công", {
      // Security settings từ settings.security
      twoFactorEnabled: getBooleanValue(
        security.isTwoFactorEnabled,
        security.twoFactorEnabled,
        false
      ),
      biometricEnabled: getBooleanValue(security.biometricEnabled, null, false),
      pinEnabled: getBooleanValue(security.pinEnabled, null, false),
      autoLockEnabled: getBooleanValue(
        security.isAutoLockEnabled,
        security.autoLockEnabled,
        true
      ),
      sessionTimeout: security.sessionTimeout || 30,
      loginNotificationEnabled: getBooleanValue(
        security.loginNotificationEnabled,
        null,
        true
      ),
      dataEncryptionEnabled: getBooleanValue(
        security.dataEncryptionEnabled,
        null,
        true
      ),
      maxFailedAttempts: security.maxFailedAttempts || 5,
      screenshotBlocked: getBooleanValue(
        security.screenshotBlocked,
        null,
        false
      ),
      appPinEnabled: getBooleanValue(security.appPinEnabled, null, false),
      primaryAuthMethod: security.primaryAuthMethod || "password",
      // Auth info
      lastPasswordChange: user.auth?.lastPasswordChange || null,
    });
  } catch (error) {
    return errorResponse(res, "Lỗi server khi lấy cài đặt bảo mật", 500);
  }
};

/**
 * @desc    Get active sessions
 * @route   GET /api/security/sessions
 * @access  Private
 */
export const getActiveSessions = async (req, res) => {
  try {
    // ✅ DEVICE TRACKING: Get real active sessions từ SessionService
    const userId = req.userId; // Fix: use req.userId instead of req.user.id
    const currentSessionId = req.sessionId; // From auth middleware

    // Get active sessions from SessionService
    const sessions = await SessionService.getActiveSessions(userId);

    // Mark current session
    const formattedSessions = sessions.map((session) => ({
      ...session,
      isCurrentSession: session.sessionId === currentSessionId,
    }));

    return successResponse(res, "Lấy danh sách phiên đăng nhập thành công", {
      sessions: formattedSessions,
    });
  } catch (error) {
    console.error("❌ Get active sessions error:", error);
    return errorResponse(
      res,
      "Lỗi server khi lấy danh sách phiên đăng nhập",
      500
    );
  }
};

/**
 * @desc    Terminate session
 * @route   DELETE /api/security/sessions/:sessionId
 * @access  Private
 */
export const terminateSession = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const currentSessionId = req.sessionId;

    // console.log('🔄 Terminating session:', sessionId);

    // Prevent terminating current session
    if (sessionId === currentSessionId) {
      return errorResponse(
        res,
        "Không thể kết thúc phiên đăng nhập hiện tại",
        400
      );
    }

    // Terminate the session
    const terminated = await SessionService.terminateSession(sessionId);

    if (terminated) {
      return successResponse(res, "Kết thúc phiên đăng nhập thành công");
    } else {
      return errorResponse(res, "Không tìm thấy phiên đăng nhập", 404);
    }
  } catch (error) {
    console.error("❌ Terminate session error:", error);
    return errorResponse(res, "Lỗi server khi kết thúc phiên đăng nhập", 500);
  }
};

/**
 * @desc    Terminate all other sessions
 * @route   DELETE /api/security/sessions
 * @access  Private
 */
export const terminateAllSessions = async (req, res) => {
  try {
    const userId = req.user.id;
    const currentSessionId = req.sessionId;

    // console.log('🔄 Terminating all sessions except current for user:', userId);

    // Terminate all sessions except current
    const terminatedCount = await SessionService.terminateAllUserSessions(
      userId,
      currentSessionId
    );

    // console.log('✅ Terminated sessions count:', terminatedCount);

    return successResponse(
      res,
      `Đã kết thúc ${terminatedCount} phiên đăng nhập khác`
    );
  } catch (error) {
    console.error("❌ Terminate all sessions error:", error);
    return errorResponse(
      res,
      "Lỗi server khi kết thúc tất cả phiên đăng nhập",
      500
    );
  }
};

/**
 * @desc    Update security settings
 * @route   PUT /api/security/settings
 * @access  Private
 */
export const updateSecuritySettings = async (req, res) => {
  try {
    const userId = req.userId;
    const updateData = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return errorResponse(res, "Người dùng không tồn tại", 404);
    }

    // Khởi tạo settings và security object nếu chưa có
    if (!user.settings) {
      user.settings = {};
    }
    if (!user.settings.security) {
      user.settings.security = {};
    }

    // Danh sách các field có thể cập nhật
    const allowedFields = [
      "biometricEnabled",
      "pinEnabled",
      "autoLockEnabled",
      "isAutoLockEnabled",
      "sessionTimeout",
      "loginNotificationEnabled",
      "loginNotifications", // alias
      "dataEncryptionEnabled",
      "maxFailedAttempts",
      "screenshotBlocked",
      "appPinEnabled",
      "primaryAuthMethod",
      "sessionPersistence",
      "keepSessionsAcrossDevices",
      "enablePrivacyMode",
      "enhancedProtection",
      "biometricAuth",
    ];

    // Cập nhật từng field nếu có trong request
    let hasUpdates = false;
    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        hasUpdates = true;

        // Handle aliases and main fields
        if (field === "loginNotifications") {
          user.settings.security.loginNotificationEnabled = updateData[field];
        } else if (field === "autoLockEnabled") {
          // Map autoLockEnabled to both fields for consistency
          user.settings.security.isAutoLockEnabled = updateData[field];
          user.settings.security.autoLockEnabled = updateData[field];
        } else if (field === "isAutoLockEnabled") {
          // Map isAutoLockEnabled to both fields for consistency
          user.settings.security.isAutoLockEnabled = updateData[field];
          user.settings.security.autoLockEnabled = updateData[field];
        } else if (field === "biometricAuth") {
          user.settings.security.biometricEnabled = updateData[field];
        } else {
          user.settings.security[field] = updateData[field];
        }
      }
    }

    if (hasUpdates) {
      await user.save();
    }

    return successResponse(res, "Cập nhật cài đặt bảo mật thành công", {
      updated: hasUpdates,
      settings: user.settings.security,
    });
  } catch (error) {
    return errorResponse(res, "Lỗi server khi cập nhật cài đặt bảo mật", 500);
  }
};
