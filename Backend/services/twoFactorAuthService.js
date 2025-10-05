import speakeasy from "speakeasy";
import QRCode from "qrcode";
import crypto from "crypto";

/**
 * Enhanced 2FA Service with TOTP and QR Code generation
 * Provides comprehensive Two-Factor Authentication functionality
 */
class TwoFactorAuthService {
  /**
   * Generate TOTP secret and QR code for 2FA setup
   * @param {string} userEmail - User's email address
   * @param {string} serviceName - Service name (default: ZBudget)
   * @returns {Promise<Object>} Secret and QR code data
   */
  static async generateTOTPSecret(userEmail, serviceName = "ZBudget") {
    try {
      // Generate a secret key
      const secret = speakeasy.generateSecret({
        name: `${serviceName} (${userEmail})`,
        issuer: serviceName,
        length: 32,
      });

      // Generate QR code as data URL
      const qrCodeDataURL = await QRCode.toDataURL(secret.otpauth_url);

      // Generate backup codes
      const backupCodes = this.generateBackupCodes(8);

      return {
        secret: secret.base32,
        qrCode: qrCodeDataURL,
        otpauthUrl: secret.otpauth_url,
        backupCodes: backupCodes,
        algorithm: "SHA1",
        digits: 6,
        period: 30,
      };
    } catch (error) {
      console.error("Error generating TOTP secret:", error);
      throw new Error("Failed to generate 2FA secret");
    }
  }

  /**
   * Verify TOTP token
   * @param {string} token - 6-digit TOTP token
   * @param {string} secret - User's TOTP secret
   * @param {number} window - Time window tolerance (default: 2)
   * @returns {boolean} Verification result
   */
  static verifyTOTPToken(token, secret, window = 2) {
    try {
      if (!token || !secret) {
        return false;
      }

      // Remove any spaces or formatting from token
      const cleanToken = token.replace(/\s/g, "");

      // Verify the token
      const verified = speakeasy.totp.verify({
        secret: secret,
        encoding: "base32",
        token: cleanToken,
        window: window, // Allow 2 time steps before/after current
        algorithm: "sha1",
      });

      return verified;
    } catch (error) {
      console.error("Error verifying TOTP token:", error);
      return false;
    }
  }

  /**
   * Generate backup codes for 2FA recovery
   * @param {number} count - Number of backup codes to generate
   * @returns {Array<string>} Array of backup codes
   */
  static generateBackupCodes(count = 8) {
    const codes = [];
    for (let i = 0; i < count; i++) {
      // Generate 8-character alphanumeric code
      const code = crypto.randomBytes(4).toString("hex").toUpperCase();
      // Format as XXXX-XXXX
      const formattedCode = code.match(/.{1,4}/g).join("-");
      codes.push(formattedCode);
    }
    return codes;
  }

  /**
   * Verify backup code
   * @param {string} inputCode - User input backup code
   * @param {Array<string>} userBackupCodes - User's valid backup codes
   * @returns {Object} Verification result with remaining codes
   */
  static verifyBackupCode(inputCode, userBackupCodes) {
    try {
      if (!inputCode || !Array.isArray(userBackupCodes)) {
        return { valid: false, remainingCodes: userBackupCodes };
      }

      // Clean and format input code
      const cleanCode = inputCode.replace(/\s/g, "").toUpperCase();

      // Check if code exists in user's backup codes
      const codeIndex = userBackupCodes.indexOf(cleanCode);

      if (codeIndex === -1) {
        return { valid: false, remainingCodes: userBackupCodes };
      }

      // Remove used backup code
      const remainingCodes = userBackupCodes.filter(
        (_, index) => index !== codeIndex
      );

      return {
        valid: true,
        remainingCodes: remainingCodes,
        usedCode: cleanCode,
      };
    } catch (error) {
      console.error("Error verifying backup code:", error);
      return { valid: false, remainingCodes: userBackupCodes };
    }
  }

  /**
   * Generate QR code as PNG buffer
   * @param {string} otpauthUrl - OTPAUTH URL
   * @returns {Promise<Buffer>} QR code PNG buffer
   */
  static async generateQRCodePNG(otpauthUrl) {
    try {
      const qrCodeBuffer = await QRCode.toBuffer(otpauthUrl, {
        type: "png",
        width: 256,
        margin: 2,
        color: {
          dark: "#000000",
          light: "#FFFFFF",
        },
      });
      return qrCodeBuffer;
    } catch (error) {
      console.error("Error generating QR code PNG:", error);
      throw new Error("Failed to generate QR code");
    }
  }

  /**
   * Validate 2FA setup completion
   * @param {string} secret - TOTP secret
   * @param {string} verificationToken - Token from user's authenticator
   * @returns {boolean} Setup validation result
   */
  static validateSetupCompletion(secret, verificationToken) {
    try {
      // Verify that user can generate valid tokens with their authenticator
      const isValid = this.verifyTOTPToken(verificationToken, secret, 1);
      return isValid;
    } catch (error) {
      console.error("Error validating 2FA setup:", error);
      return false;
    }
  }

  /**
   * Generate recovery information for 2FA
   * @param {string} userEmail - User email
   * @returns {Object} Recovery information
   */
  static generateRecoveryInfo(userEmail) {
    return {
      recoveryCode: crypto.randomBytes(16).toString("hex"),
      generatedAt: new Date(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      userEmail: userEmail,
      used: false,
    };
  }

  /**
   * Check if 2FA token is rate limited
   * @param {string} userId - User ID
   * @param {Object} attempts - Recent attempts data
   * @returns {Object} Rate limit status
   */
  static checkRateLimit(userId, attempts = {}) {
    const now = Date.now();
    const userAttempts = attempts[userId] || { count: 0, resetTime: now };

    // Reset counter every 15 minutes
    if (now > userAttempts.resetTime) {
      userAttempts.count = 0;
      userAttempts.resetTime = now + 15 * 60 * 1000;
    }

    // Allow max 5 attempts per 15 minutes
    if (userAttempts.count >= 5) {
      return {
        isLimited: true,
        remainingTime: userAttempts.resetTime - now,
        maxAttempts: 5,
      };
    }

    return {
      isLimited: false,
      attemptsLeft: 5 - userAttempts.count,
    };
  }

  /**
   * Record failed 2FA attempt
   * @param {string} userId - User ID
   * @param {Object} attempts - Attempts tracking object
   * @returns {Object} Updated attempts data
   */
  static recordFailedAttempt(userId, attempts = {}) {
    const now = Date.now();

    if (!attempts[userId]) {
      attempts[userId] = { count: 0, resetTime: now + 15 * 60 * 1000 };
    }

    attempts[userId].count += 1;
    return attempts;
  }

  /**
   * Get 2FA status summary
   * @param {Object} user - User object with security settings
   * @returns {Object} 2FA status information
   */
  static getTwoFactorStatus(user) {
    const security = user.settings?.security || {};

    return {
      isEnabled: security.isTwoFactorEnabled || false,
      hasSecret: !!security.twoFactorSecret,
      backupCodesCount: security.twoFactorBackupCodes?.length || 0,
      setupDate: security.twoFactorEnabledAt || null,
      lastUsed: security.twoFactorLastUsed || null,
    };
  }

  /**
   * Generate 2FA setup instructions
   * @returns {Object} Setup instructions
   */
  static getSetupInstructions() {
    return {
      steps: [
        {
          step: 1,
          title: "Tải ứng dụng xác thực",
          description:
            "Tải Google Authenticator, Authy, hoặc ứng dụng TOTP khác",
          apps: [
            { name: "Google Authenticator", ios: true, android: true },
            { name: "Authy", ios: true, android: true, desktop: true },
            { name: "Microsoft Authenticator", ios: true, android: true },
          ],
        },
        {
          step: 2,
          title: "Quét mã QR",
          description: "Sử dụng ứng dụng xác thực để quét mã QR bên dưới",
        },
        {
          step: 3,
          title: "Nhập mã xác minh",
          description:
            "Nhập mã 6 chữ số từ ứng dụng xác thực để hoàn tất thiết lập",
        },
        {
          step: 4,
          title: "Lưu mã khôi phục",
          description:
            "Lưu trữ các mã khôi phục ở nơi an toàn để phòng trường hợp mất thiết bị",
        },
      ],
      important: [
        "Đảm bảo thời gian trên thiết bị chính xác",
        "Lưu mã khôi phục ở nơi an toàn",
        "Không chia sẻ mã QR hoặc secret key",
        "Test 2FA trước khi đăng xuất hoàn toàn",
      ],
    };
  }
}

export default TwoFactorAuthService;
