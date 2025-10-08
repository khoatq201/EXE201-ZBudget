import crypto from "crypto";
import Session from "../models/Session.js";
import logger from "../middleware/logger.js";

class SessionService {
  // Enhanced device detection với custom device info từ header
  static parseUserAgent(userAgent, customDeviceInfo = null) {
    // Nếu có custom device info từ Flutter app, sử dụng nó
    if (customDeviceInfo) {
      try {
        const deviceData =
          typeof customDeviceInfo === "string"
            ? JSON.parse(customDeviceInfo)
            : customDeviceInfo;

        console.log("📱 Using custom device info:", deviceData);

        return {
          userAgent,
          platform: deviceData.platform || "Unknown",
          browser: deviceData.browser || "Unknown",
          deviceType: deviceData.deviceType || "desktop",
          deviceName:
            deviceData.deviceName ||
            `${deviceData.platform || "Unknown"} Device`,
          deviceFingerprint: this.generateDeviceFingerprint(deviceData),
        };
      } catch (error) {
        console.log("❌ Error parsing custom device info:", error);
        // Fall back to User-Agent parsing
      }
    }

    // Fallback: Simple device detection from User-Agent
    const deviceInfo = {
      userAgent,
      platform: "Unknown",
      browser: "Unknown",
      deviceType: "desktop",
      deviceName: "Unknown Device",
      deviceFingerprint: crypto
        .createHash("md5")
        .update(userAgent)
        .digest("hex")
        .substring(0, 16),
    };

    // Simple detection từ User-Agent
    if (/Mobile|Android|iPhone|iPad/.test(userAgent)) {
      deviceInfo.deviceType = "mobile";
      deviceInfo.platform = "Mobile";
      deviceInfo.deviceName = "Mobile Device";
    } else {
      deviceInfo.deviceType = "desktop";
      deviceInfo.platform = "Desktop";
      deviceInfo.deviceName = "Desktop Browser";
    }

    if (/Chrome/.test(userAgent)) {
      deviceInfo.browser = "Chrome";
      deviceInfo.deviceName = `${deviceInfo.platform} - Chrome`;
    } else if (/Firefox/.test(userAgent)) {
      deviceInfo.browser = "Firefox";
      deviceInfo.deviceName = `${deviceInfo.platform} - Firefox`;
    } else if (/Safari/.test(userAgent)) {
      deviceInfo.browser = "Safari";
      deviceInfo.deviceName = `${deviceInfo.platform} - Safari`;
    } else if (/Flutter/.test(userAgent)) {
      deviceInfo.browser = "Flutter";
      deviceInfo.deviceName = `${deviceInfo.platform} - Flutter`;
    }

    return deviceInfo;
  }

  // Generate device fingerprint từ device data
  static generateDeviceFingerprint(deviceData) {
    try {
      const platform = deviceData.platform || "Unknown";
      const model = deviceData.model || "Unknown";
      const manufacturer = deviceData.manufacturer || "Unknown";
      const version = deviceData.version || "Unknown";

      const fingerprint = `${platform}-${manufacturer}-${model}-${version}`;
      return crypto
        .createHash("md5")
        .update(fingerprint)
        .digest("hex")
        .substring(0, 16);
    } catch (error) {
      console.log("❌ Error generating fingerprint:", error);
      return crypto.randomBytes(8).toString("hex");
    }
  }

  // Get real IP address
  static getRealIP(req) {
    return (
      req.headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
      req.headers["x-real-ip"] ||
      req.connection?.remoteAddress ||
      req.socket?.remoteAddress ||
      req.ip ||
      "Unknown"
    );
  }

  // Get location from IP (simplified)
  static async getLocationFromIP(ip) {
    try {
      // For localhost/development, return default
      if (
        ip === "127.0.0.1" ||
        ip === "::1" ||
        ip === "localhost" ||
        ip.includes("127.0.0.1")
      ) {
        return {
          ip,
          country: "Vietnam",
          countryCode: "VN",
          region: "Ho Chi Minh",
          city: "Ho Chi Minh City",
          timezone: "Asia/Ho_Chi_Minh",
          coordinates: {
            lat: 10.8231,
            lng: 106.6297,
          },
        };
      }

      // For real IPs, return unknown for now
      return {
        ip,
        country: "Unknown",
        countryCode: "XX",
        region: "Unknown",
        city: "Unknown",
        timezone: "UTC",
        coordinates: {
          lat: 0,
          lng: 0,
        },
      };
    } catch (error) {
      return {
        ip,
        country: "Unknown",
        countryCode: "XX",
        region: "Unknown",
        city: "Unknown",
        timezone: "UTC",
        coordinates: {
          lat: 0,
          lng: 0,
        },
      };
    }
  }

  // Generate unique session ID
  static generateSessionId() {
    return crypto.randomBytes(32).toString("hex");
  }

  // Create new session với enhanced device detection

  static async createSession(
    userId,
    jwtTokenId,
    req,
    expiresAt,
    loginMethod = "password"
  ) {
    try {
      const userAgent = req.headers["user-agent"] || "Unknown";
      const ip = this.getRealIP(req);

      // ✅ DEVICE TRACKING: Extract custom device info từ header
      const customDeviceInfo = req.headers["x-device-info"];

      // Enhanced device detection với custom info
      const deviceInfo = this.parseUserAgent(userAgent, customDeviceInfo);
      const location = await this.getLocationFromIP(ip);

      // Use jwtTokenId as sessionId for easy comparison
      const sessionId = jwtTokenId;

      // ✅ CHECK EXISTING DEVICE: Check if session already exists with same device fingerprint
      const deviceFingerprint = deviceInfo.deviceFingerprint;
      const existingSession = await Session.findOne({
        userId,
        "deviceInfo.deviceFingerprint": deviceFingerprint,
        isActive: true,
      });

      if (existingSession) {
        // Update existing session instead of creating new one
        existingSession.sessionId = sessionId;
        existingSession.jwtTokenId = jwtTokenId;
        existingSession.lastActiveTime = new Date();
        existingSession.expiresAt = expiresAt;
        existingSession.location = location; // Update location in case IP changed
        existingSession.loginTime = new Date(); // Update login time

        await existingSession.save();

        logger.info("Session updated for existing device", {
          userId,
          sessionId,
          deviceName: deviceInfo.deviceName,
          location: `${location.city}, ${location.country}`,
        });

        return existingSession;
      }

      // Create session object (only if no existing device found)
      const sessionData = {
        userId,
        sessionId,
        jwtTokenId,
        deviceInfo,
        location,
        isActive: true,
        expiresAt: expiresAt || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        metadata: {
          loginMethod,
          securityLevel: "medium",
          riskScore: 20,
        },
        loginTime: new Date(),
        lastActiveTime: new Date(),
      };

      // Save to database
      const session = new Session(sessionData);
      await session.save();

      return session;
    } catch (error) {
      console.error("❌ Session creation failed:", error);
      logger.error("Failed to create session:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Get active sessions for user
  static async getActiveSessions(userId) {
    try {
      const sessions = await Session.findActiveByUserId(userId);

      return sessions.map((session) => ({
        sessionId: session.sessionId,
        deviceName: session.deviceInfo.deviceName,
        platform: session.deviceInfo.platform,
        browser: session.deviceInfo.browser,
        deviceType: session.deviceInfo.deviceType,
        location: `${session.location.city}, ${session.location.country}`,
        lastActiveTime: session.lastActiveTime,
        loginTime: session.loginTime,
        isCurrentSession: false,
        securityLevel: session.metadata.securityLevel,
        ip: session.location.ip,
      }));
    } catch (error) {
      logger.error("Failed to get active sessions:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Update session activity
  static async updateActivity(sessionId) {
    try {
      await Session.updateOne(
        { sessionId, isActive: true },
        {
          lastActiveTime: new Date(),
        }
      );
    } catch (error) {
      logger.error("Failed to update session activity:", {
        sessionId,
        error: error.message,
      });
    }
  }

  // Terminate session
  static async terminateSession(sessionId) {
    try {
      const result = await Session.updateOne(
        { sessionId, isActive: true },
        {
          isActive: false,
          terminatedAt: new Date(),
        }
      );

      return result.modifiedCount > 0;
    } catch (error) {
      logger.error("Failed to terminate session:", {
        sessionId,
        error: error.message,
      });
      throw error;
    }
  }

  // Terminate all user sessions
  static async terminateAllUserSessions(userId, excludeSessionId = null) {
    try {
      const filter = {
        userId,
        isActive: true,
      };

      if (excludeSessionId) {
        filter.sessionId = { $ne: excludeSessionId };
      }

      const result = await Session.updateMany(filter, {
        isActive: false,
        terminatedAt: new Date(),
      });

      return result.modifiedCount;
    } catch (error) {
      logger.error("Failed to terminate all user sessions:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Cleanup old sessions
  static async cleanupOldSessions(userId, keepLatest = 5) {
    try {
      const sessions = await Session.find({ userId, isActive: true })
        .sort({ lastActiveTime: -1 })
        .skip(keepLatest);

      const sessionIds = sessions.map((s) => s.sessionId);

      if (sessionIds.length > 0) {
        await Session.updateMany(
          { sessionId: { $in: sessionIds } },
          {
            isActive: false,
            terminatedAt: new Date(),
          }
        );
      }

      return sessionIds.length;
    } catch (error) {
      logger.error("Failed to cleanup old sessions:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Find session by ID
  static async findBySessionId(sessionId) {
    try {
      return await Session.findBySessionId(sessionId);
    } catch (error) {
      logger.error("Failed to find session:", {
        sessionId,
        error: error.message,
      });
      return null;
    }
  }
  static async cleanupExpiredSessions() {
    try {
      const now = new Date();

      // Find and deactivate expired sessions
      const result = await Session.updateMany(
        {
          isActive: true,
          expiresAt: { $lt: now },
        },
        {
          isActive: false,
          terminatedAt: new Date(),
          terminatedReason: "expired",
        }
      );

      logger.info("Expired sessions cleaned up", {
        cleanedCount: result.modifiedCount,
        timestamp: now,
      });

      return result.modifiedCount;
    } catch (error) {
      logger.error("Failed to cleanup expired sessions:", {
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }
}

export default SessionService;
