import crypto from "crypto";
import Session from "../models/Session.js";
import logger from "../middleware/logger.js";

class SessionService {
  // Parse User-Agent string to extract device info
  static parseUserAgent(userAgent) {
    console.log("🔍 DEBUG: Parsing User-Agent:", userAgent);

    const deviceInfo = {
      userAgent,
      platform: "Unknown",
      browser: "Unknown",
      deviceType: "desktop",
    };

    // Special handling for Flutter/Dart
    if (/Dart\/[\d.]+/.test(userAgent)) {
      deviceInfo.platform = "Flutter";
      deviceInfo.browser = "Dart";
      deviceInfo.deviceType = "mobile"; // Assume Flutter is mobile
    }
    // Detect platform
    else if (/Windows NT/.test(userAgent)) deviceInfo.platform = "Windows";
    else if (/Mac OS X/.test(userAgent)) deviceInfo.platform = "macOS";
    else if (/Linux/.test(userAgent) && !/Android/.test(userAgent))
      deviceInfo.platform = "Linux";
    else if (/Android/.test(userAgent)) {
      deviceInfo.platform = "Android";
      deviceInfo.deviceType = "mobile";
    } else if (/iPhone|iPad/.test(userAgent)) {
      deviceInfo.platform = "iOS";
      deviceInfo.deviceType = /iPad/.test(userAgent) ? "tablet" : "mobile";
    }

    // Detect browser
    if (/Chrome/.test(userAgent) && !/Edge/.test(userAgent)) {
      deviceInfo.browser = "Chrome";
    } else if (/Safari/.test(userAgent) && !/Chrome/.test(userAgent)) {
      deviceInfo.browser = "Safari";
    } else if (/Firefox/.test(userAgent)) {
      deviceInfo.browser = "Firefox";
    } else if (/Edge/.test(userAgent)) {
      deviceInfo.browser = "Edge";
    } else if (/Opera/.test(userAgent)) {
      deviceInfo.browser = "Opera";
    }

    console.log("🔍 DEBUG: Parsed device info:", deviceInfo);
    return deviceInfo;
  }

  // Get location info from IP address
  static async getLocationFromIP(ip) {
    try {
      // For localhost/development, return default
      if (ip === "127.0.0.1" || ip === "::1" || ip === "localhost") {
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

      // Use free IP geolocation service (ipapi.co)
      const response = await fetch(`http://ipapi.co/${ip}/json/`);
      const data = await response.json();

      return {
        ip,
        country: data.country_name || "Unknown",
        countryCode: data.country_code || "XX",
        region: data.region || "Unknown",
        city: data.city || "Unknown",
        timezone: data.timezone || "UTC",
        coordinates: {
          lat: data.latitude || 0,
          lng: data.longitude || 0,
        },
      };
    } catch (error) {
      logger.error("Failed to get location from IP:", {
        ip,
        error: error.message,
      });
      return {
        ip,
        country: "Unknown",
        countryCode: "XX",
        region: "Unknown",
        city: "Unknown",
        timezone: "UTC",
        coordinates: { lat: 0, lng: 0 },
      };
    }
  }

  // Extract real IP address from request
  static getRealIP(req) {
    return (
      req.headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
      req.headers["x-real-ip"] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      req.ip ||
      "127.0.0.1"
    );
  }

  // Generate unique session ID
  static generateSessionId() {
    return crypto.randomBytes(32).toString("hex");
  }

  // Create new session
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

      const deviceInfo = this.parseUserAgent(userAgent);
      const location = await this.getLocationFromIP(ip);

      const sessionId = this.generateSessionId();

      // Calculate security level based on device and location
      const securityLevel = this.calculateSecurityLevel(
        deviceInfo,
        location,
        ip
      );

      const session = new Session({
        userId,
        sessionId,
        jwtTokenId,
        deviceInfo,
        location,
        expiresAt,
        metadata: {
          loginMethod,
          securityLevel,
          riskScore: this.calculateRiskScore(deviceInfo, location),
        },
      });

      await session.save();

      logger.info("Session created successfully", {
        userId,
        sessionId,
        deviceName: deviceInfo.deviceName,
        location: `${location.city}, ${location.country}`,
      });

      return session;
    } catch (error) {
      logger.error("Failed to create session:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Calculate security level
  static calculateSecurityLevel(deviceInfo, location, ip) {
    let score = 0;

    // Platform scoring
    if (deviceInfo.platform === "iOS" || deviceInfo.platform === "macOS")
      score += 2;
    else if (deviceInfo.platform === "Android") score += 1;

    // Browser scoring
    if (deviceInfo.browser === "Chrome" || deviceInfo.browser === "Safari")
      score += 1;

    // IP scoring (localhost = high security for development)
    if (ip === "127.0.0.1" || ip === "::1") score += 3;

    return score >= 4 ? "high" : score >= 2 ? "medium" : "low";
  }

  // Calculate risk score
  static calculateRiskScore(deviceInfo, location) {
    let risk = 0;

    // Unknown platform/browser increases risk
    if (deviceInfo.platform === "Unknown") risk += 20;
    if (deviceInfo.browser === "Unknown") risk += 20;

    // Mobile devices have higher risk
    if (deviceInfo.deviceType === "mobile") risk += 10;

    // Unknown location increases risk
    if (location.country === "Unknown") risk += 30;

    return Math.min(risk, 100);
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
        lastActiveTime: session.lastActiveTime, // Return actual DateTime
        loginTime: session.loginTime,
        isCurrentSession: false, // Will be set by controller
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
      const session = await Session.findBySessionId(sessionId);
      if (session) {
        await session.updateActivity();
      }
    } catch (error) {
      logger.error("Failed to update session activity:", {
        sessionId,
        error: error.message,
      });
    }
  }

  // Terminate session
  static async terminateSession(sessionId, userId) {
    try {
      const session = await Session.findOne({
        sessionId,
        userId,
        isActive: true,
      });

      if (session) {
        await session.terminate();
        logger.info("Session terminated", { sessionId, userId });
        return true;
      }

      return false;
    } catch (error) {
      logger.error("Failed to terminate session:", {
        sessionId,
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Terminate all user sessions except current
  static async terminateAllSessions(userId, excludeSessionId = null) {
    try {
      const result = await Session.terminateAllUserSessions(
        userId,
        excludeSessionId
      );

      logger.info("All user sessions terminated", {
        userId,
        excludeSessionId,
        modifiedCount: result.modifiedCount,
      });

      return result.modifiedCount;
    } catch (error) {
      logger.error("Failed to terminate all sessions:", {
        userId,
        error: error.message,
      });
      throw error;
    }
  }

  // Cleanup expired sessions (should be run periodically)
  static async cleanupExpiredSessions() {
    try {
      const result = await Session.cleanupExpiredSessions();
      logger.info("Cleanup expired sessions", {
        deletedCount: result.deletedCount,
      });
      return result.deletedCount;
    } catch (error) {
      logger.error("Failed to cleanup expired sessions:", {
        error: error.message,
      });
      throw error;
    }
  }

  // Validate session
  static async validateSession(sessionId, userId) {
    try {
      const session = await Session.findOne({
        sessionId,
        userId,
        isActive: true,
        expiresAt: { $gt: new Date() },
      });

      return !!session;
    } catch (error) {
      logger.error("Failed to validate session:", {
        sessionId,
        userId,
        error: error.message,
      });
      return false;
    }
  }
}

export default SessionService;
