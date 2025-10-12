// Temporarily commented out due to ES module import issues
// import geoipPkg from 'geoip-lite';
// import UAParserPkg from 'ua-parser-js';
import crypto from "crypto";
// Fallback implementations
const lookup = (ip) => {
  // Simple fallback - in production would use actual geoip
  if (ip === "127.0.0.1" || ip === "::1") {
    return { country: "VN", city: "Ho Chi Minh City", region: "Ho Chi Minh" };
  }
  return { country: "Unknown", city: "Unknown", region: "Unknown" };
};
const UAParser = (userAgent) => {
  // Simple fallback parser
  return {
    getBrowser: () => ({ name: "Unknown", version: "1.0" }),
    getOS: () => ({ name: "Unknown", version: "1.0" }),
    getDevice: () => ({ type: "desktop", vendor: "Unknown", model: "Unknown" }),
  };
};
/**
 * Advanced Device and Location Tracking Service
 * Provides comprehensive device fingerprinting and geographic location detection
 */
class DeviceTrackingService {
  /**
   * Generate comprehensive device fingerprint
   * @param {Object} req - Express request object
   * @returns {Object} Device fingerprint data
   */
  static generateDeviceFingerprint(req) {
    const userAgent = req.get("User-Agent") || "";
    const parser = new UAParser(userAgent);
    const deviceInfo = parser.getResult();
    // Enhanced device identification
    const deviceFingerprint = {
      // Basic device info
      browser: {
        name: deviceInfo.browser.name || "Unknown",
        version: deviceInfo.browser.version || "Unknown",
        major: deviceInfo.browser.major || "Unknown",
      },
      os: {
        name: deviceInfo.os.name || "Unknown",
        version: deviceInfo.os.version || "Unknown",
      },
      device: {
        type: deviceInfo.device.type || "desktop",
        model: deviceInfo.device.model || "Unknown",
        vendor: deviceInfo.device.vendor || "Unknown",
      },
      engine: {
        name: deviceInfo.engine.name || "Unknown",
        version: deviceInfo.engine.version || "Unknown",
      },
      // Network & Request info
      userAgent: userAgent,
      acceptLanguage: req.get("Accept-Language") || "",
      acceptEncoding: req.get("Accept-Encoding") || "",
      connection: req.get("Connection") || "",
      // Generate unique fingerprint hash
      fingerprintHash: this.generateFingerprintHash({
        userAgent,
        acceptLanguage: req.get("Accept-Language"),
        acceptEncoding: req.get("Accept-Encoding"),
        os: deviceInfo.os.name,
        browser: deviceInfo.browser.name,
      }),
    };
    return deviceFingerprint;
  }
  /**
   * Get geographic location from IP address
   * @param {string} ipAddress - Client IP address
   * @returns {Object} Location data
   */
  static getLocationFromIP(ipAddress) {
    try {
      // Handle localhost and private IPs
      if (this.isPrivateIP(ipAddress)) {
        return {
          country: "VN",
          countryName: "Vietnam",
          city: "Ho Chi Minh City",
          region: "79",
          regionName: "Ho Chi Minh",
          timezone: "Asia/Ho_Chi_Minh",
          latitude: 10.8231,
          longitude: 106.6297,
          isPrivateIP: true,
        };
      }
      const geo = lookup(ipAddress);
      if (!geo) {
        return {
          country: "Unknown",
          countryName: "Unknown",
          city: "Unknown",
          region: "Unknown",
          regionName: "Unknown",
          timezone: "Unknown",
          latitude: null,
          longitude: null,
          isPrivateIP: false,
        };
      }
      return {
        country: geo.country,
        countryName: this.getCountryName(geo.country),
        city: geo.city,
        region: geo.region,
        regionName: geo.region,
        timezone: geo.timezone,
        latitude: geo.ll ? geo.ll[0] : null,
        longitude: geo.ll ? geo.ll[1] : null,
        isPrivateIP: false,
      };
    } catch (error) {
      console.error("Error getting location from IP:", error);
      return {
        country: "Unknown",
        countryName: "Unknown",
        city: "Unknown",
        region: "Unknown",
        regionName: "Unknown",
        timezone: "Unknown",
        latitude: null,
        longitude: null,
        isPrivateIP: false,
        error: error.message,
      };
    }
  }
  /**
   * Check if IP is private/local
   * @param {string} ip - IP address
   * @returns {boolean}
   */
  static isPrivateIP(ip) {
    if (!ip) return true;
    // Common local/private IP patterns
    const privatePatterns = [
      /^127\./, // 127.x.x.x (localhost)
      /^192\.168\./, // 192.168.x.x (private)
      /^10\./, // 10.x.x.x (private)
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./, // 172.16.x.x to 172.31.x.x (private)
      /^::1$/, // IPv6 localhost
      /^fe80:/, // IPv6 link-local
    ];
    return (
      privatePatterns.some((pattern) => pattern.test(ip)) ||
      ip === "localhost" ||
      ip === "::1"
    );
  }
  /**
   * Generate device fingerprint hash
   * @param {Object} data - Fingerprint data
   * @returns {string} SHA-256 hash
   */
  static generateFingerprintHash(data) {
    const fingerprint = JSON.stringify(data);
    return crypto.createHash("sha256").update(fingerprint).digest("hex");
  }
  /**
   * Get friendly device name
   * @param {Object} deviceInfo - Device information
   * @returns {string} Friendly device name
   */
  static getFriendlyDeviceName(deviceInfo) {
    const { browser, os, device } = deviceInfo;
    // Mobile devices
    if (device.type === "mobile") {
      if (device.vendor && device.model) {
        return `${device.vendor} ${device.model}`;
      }
      if (os.name) {
        return `${os.name} Mobile`;
      }
      return "Mobile Device";
    }
    // Tablets
    if (device.type === "tablet") {
      if (device.vendor && device.model) {
        return `${device.vendor} ${device.model}`;
      }
      return "Tablet";
    }
    // Desktop/laptop
    if (browser.name && os.name) {
      return `${browser.name} - ${os.name}`;
    }
    if (browser.name) {
      return browser.name;
    }
    return "Unknown Device";
  }
  /**
   * Generate comprehensive session info
   * @param {Object} req - Express request object
   * @returns {Object} Complete session information
   */
  static generateSessionInfo(req) {
    const ipAddress = this.getClientIP(req);
    const deviceFingerprint = this.generateDeviceFingerprint(req);
    const location = this.getLocationFromIP(ipAddress);
    return {
      sessionId: this.generateSessionId(),
      deviceName: this.getFriendlyDeviceName(deviceFingerprint),
      deviceType: deviceFingerprint.device.type || "desktop",
      location: this.formatLocationString(location),
      detailedLocation: location,
      ipAddress: ipAddress,
      userAgent: deviceFingerprint.userAgent,
      deviceFingerprint: deviceFingerprint,
      loginTime: new Date(),
      lastActiveTime: new Date(),
      isCurrent: true,
      isRevoked: false,
    };
  }
  /**
   * Get client IP address from request
   * @param {Object} req - Express request object
   * @returns {string} Client IP address
   */
  static getClientIP(req) {
    return (
      req.ip ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      (req.connection.socket ? req.connection.socket.remoteAddress : null) ||
      req.get("X-Forwarded-For") ||
      req.get("X-Real-IP") ||
      "127.0.0.1"
    );
  }
  /**
   * Generate unique session ID
   * @returns {string} Session ID
   */
  static generateSessionId() {
    return crypto.randomBytes(32).toString("hex");
  }
  /**
   * Format location string for display
   * @param {Object} location - Location data
   * @returns {string} Formatted location string
   */
  static formatLocationString(location) {
    if (location.isPrivateIP) {
      return "Hồ Chí Minh, Việt Nam";
    }
    if (location.city && location.countryName) {
      return `${location.city}, ${location.countryName}`;
    }
    if (location.countryName) {
      return location.countryName;
    }
    return "Unknown Location";
  }
  /**
   * Get country name from country code
   * @param {string} countryCode - ISO country code
   * @returns {string} Country name
   */
  static getCountryName(countryCode) {
    const countries = {
      VN: "Vietnam",
      US: "United States",
      UK: "United Kingdom",
      JP: "Japan",
      KR: "South Korea",
      CN: "China",
      SG: "Singapore",
      TH: "Thailand",
      MY: "Malaysia",
      ID: "Indonesia",
      PH: "Philippines",
    };
    return countries[countryCode] || countryCode;
  }
  /**
   * Detect suspicious login patterns
   * @param {Array} sessions - User's active sessions
   * @param {Object} newSession - New login session
   * @returns {Object} Security analysis
   */
  static analyzeSecurity(sessions, newSession) {
    const analysis = {
      isSuspicious: false,
      riskLevel: "low",
      reasons: [],
      recommendations: [],
    };
    // Check for multiple locations
    const locations = sessions.map((s) => s.location);
    const uniqueLocations = [...new Set(locations)];
    if (uniqueLocations.length > 3) {
      analysis.isSuspicious = true;
      analysis.riskLevel = "medium";
      analysis.reasons.push("Multiple geographic locations detected");
      analysis.recommendations.push("Review recent login activity");
    }
    // Check for rapid location changes
    const recentSessions = sessions.filter(
      (s) => new Date(s.loginTime) > new Date(Date.now() - 24 * 60 * 60 * 1000)
    );
    if (recentSessions.length > 5) {
      analysis.isSuspicious = true;
      analysis.riskLevel = "high";
      analysis.reasons.push("Unusually high login frequency");
      analysis.recommendations.push("Consider enabling 2FA");
    }
    // Check for new device
    const deviceHashes = sessions.map(
      (s) => s.deviceFingerprint?.fingerprintHash
    );
    if (!deviceHashes.includes(newSession.deviceFingerprint?.fingerprintHash)) {
      analysis.reasons.push("New device detected");
      analysis.recommendations.push("Verify this login attempt");
    }
    return analysis;
  }
}
export default DeviceTrackingService;