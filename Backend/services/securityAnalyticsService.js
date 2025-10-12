import DeviceTrackingService from "./deviceTrackingService.js";
/**
 * Security Analytics and Monitoring Service
 * Provides comprehensive security event tracking and analysis
 */
class SecurityAnalyticsService {
  /**
   * Log security event
   * @param {string} userId - User ID
   * @param {string} eventType - Type of security event
   * @param {Object} details - Event details
   * @param {Object} req - Express request object
   * @returns {Object} Security event log entry
   */
  static logSecurityEvent(userId, eventType, details = {}, req = null) {
    const timestamp = new Date();
    const ipAddress = req ? DeviceTrackingService.getClientIP(req) : "unknown";
    const userAgent = req ? req.get("User-Agent") || "" : "";
    const location = req
      ? DeviceTrackingService.getLocationFromIP(ipAddress)
      : null;
    const securityEvent = {
      type: eventType,
      timestamp: timestamp,
      details: {
        ...details,
        success: details.success !== undefined ? details.success : true,
      },
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location
        ? DeviceTrackingService.formatLocationString(location)
        : "Unknown",
      detailedLocation: location,
      eventId: this.generateEventId(),
    };
    return securityEvent;
  }
  /**
   * Analyze security events for patterns
   * @param {Array} securityEvents - Array of security events
   * @param {number} timeWindowHours - Time window for analysis (default: 24 hours)
   * @returns {Object} Security analysis report
   */
  static analyzeSecurityEvents(securityEvents, timeWindowHours = 24) {
    const now = new Date();
    const timeWindow = new Date(
      now.getTime() - timeWindowHours * 60 * 60 * 1000
    );
    // Filter events within time window
    const recentEvents = securityEvents.filter(
      (event) => new Date(event.timestamp) >= timeWindow
    );
    const analysis = {
      timeWindow: `${timeWindowHours} hours`,
      totalEvents: recentEvents.length,
      eventsByType: this.groupEventsByType(recentEvents),
      locationAnalysis: this.analyzeLocations(recentEvents),
      deviceAnalysis: this.analyzeDevices(recentEvents),
      riskAssessment: this.assessRisk(recentEvents),
      recommendations: [],
    };
    // Generate recommendations based on analysis
    analysis.recommendations = this.generateRecommendations(analysis);
    return analysis;
  }
  /**
   * Group events by type
   * @param {Array} events - Security events
   * @returns {Object} Events grouped by type
   */
  static groupEventsByType(events) {
    const groupedEvents = {};
    events.forEach((event) => {
      const type = event.type;
      if (!groupedEvents[type]) {
        groupedEvents[type] = { count: 0, failed: 0, locations: new Set() };
      }
      groupedEvents[type].count++;
      if (!event.details.success) {
        groupedEvents[type].failed++;
      }
      if (event.location) {
        groupedEvents[type].locations.add(event.location);
      }
    });
    // Convert Sets to Arrays for JSON serialization
    Object.keys(groupedEvents).forEach((type) => {
      groupedEvents[type].locations = Array.from(groupedEvents[type].locations);
      groupedEvents[type].successRate =
        groupedEvents[type].count > 0
          ? (
              ((groupedEvents[type].count - groupedEvents[type].failed) /
                groupedEvents[type].count) *
              100
            ).toFixed(1)
          : 0;
    });
    return groupedEvents;
  }
  /**
   * Analyze location patterns
   * @param {Array} events - Security events
   * @returns {Object} Location analysis
   */
  static analyzeLocations(events) {
    const locations = {};
    const ipAddresses = new Set();
    events.forEach((event) => {
      if (event.location && event.location !== "Unknown") {
        if (!locations[event.location]) {
          locations[event.location] = {
            count: 0,
            ipAddresses: new Set(),
            firstSeen: event.timestamp,
          };
        }
        locations[event.location].count++;
        if (event.ipAddress) {
          locations[event.location].ipAddresses.add(event.ipAddress);
          ipAddresses.add(event.ipAddress);
        }
      }
    });
    // Convert Sets to Arrays and calculate metrics
    const locationStats = Object.keys(locations).map((location) => ({
      location: location,
      count: locations[location].count,
      uniqueIPs: locations[location].ipAddresses.size,
      firstSeen: locations[location].firstSeen,
      ipAddresses: Array.from(locations[location].ipAddresses),
    }));
    return {
      uniqueLocations: locationStats.length,
      uniqueIPs: ipAddresses.size,
      locationBreakdown: locationStats.sort((a, b) => b.count - a.count),
      suspiciousActivity: locationStats.length > 5 || ipAddresses.size > 10,
    };
  }
  /**
   * Analyze device patterns
   * @param {Array} events - Security events
   * @returns {Object} Device analysis
   */
  static analyzeDevices(events) {
    const userAgents = new Set();
    const browsers = {};
    const operatingSystems = {};
    events.forEach((event) => {
      if (event.userAgent) {
        userAgents.add(event.userAgent);
        // Simple browser detection
        const browserMatch = event.userAgent.match(
          /(Chrome|Firefox|Safari|Edge|Opera)\/[\d.]+/
        );
        if (browserMatch) {
          const browser = browserMatch[1];
          browsers[browser] = (browsers[browser] || 0) + 1;
        }
        // Simple OS detection
        const osPatterns = {
          Windows: /Windows/,
          macOS: /Mac OS/,
          Linux: /Linux/,
          iOS: /iPhone|iPad/,
          Android: /Android/,
        };
        for (const [os, pattern] of Object.entries(osPatterns)) {
          if (pattern.test(event.userAgent)) {
            operatingSystems[os] = (operatingSystems[os] || 0) + 1;
            break;
          }
        }
      }
    });
    return {
      uniqueUserAgents: userAgents.size,
      browserBreakdown: browsers,
      osBreakdown: operatingSystems,
      suspiciousActivity: userAgents.size > 10,
    };
  }
  /**
   * Assess overall security risk
   * @param {Array} events - Security events
   * @returns {Object} Risk assessment
   */
  static assessRisk(events) {
    let riskScore = 0;
    const riskFactors = [];
    // Calculate failed login rate
    const loginEvents = events.filter((e) => e.type === "login");
    const failedLogins = loginEvents.filter((e) => !e.details.success);
    const failureRate =
      loginEvents.length > 0 ? failedLogins.length / loginEvents.length : 0;
    if (failureRate > 0.3) {
      riskScore += 30;
      riskFactors.push("High login failure rate");
    } else if (failureRate > 0.1) {
      riskScore += 15;
      riskFactors.push("Moderate login failure rate");
    }
    // Check for geographic anomalies
    const locations = new Set(
      events.map((e) => e.location).filter((l) => l && l !== "Unknown")
    );
    if (locations.size > 5) {
      riskScore += 25;
      riskFactors.push("Multiple geographic locations");
    } else if (locations.size > 3) {
      riskScore += 10;
      riskFactors.push("Several different locations");
    }
    // Check for high event frequency
    if (events.length > 100) {
      riskScore += 20;
      riskFactors.push("High activity volume");
    } else if (events.length > 50) {
      riskScore += 10;
      riskFactors.push("Moderate activity volume");
    }
    // Check for unusual event patterns
    const eventTypes = new Set(events.map((e) => e.type));
    if (eventTypes.has("2fa_disabled") || eventTypes.has("password_change")) {
      riskScore += 15;
      riskFactors.push("Security settings changes");
    }
    // Determine risk level
    let riskLevel = "low";
    if (riskScore >= 50) {
      riskLevel = "high";
    } else if (riskScore >= 25) {
      riskLevel = "medium";
    }
    return {
      riskScore: Math.min(riskScore, 100),
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      loginFailureRate: (failureRate * 100).toFixed(1),
    };
  }
  /**
   * Generate security recommendations
   * @param {Object} analysis - Security analysis data
   * @returns {Array} Array of recommendations
   */
  static generateRecommendations(analysis) {
    const recommendations = [];
    // Risk-based recommendations
    if (analysis.riskAssessment.riskLevel === "high") {
      recommendations.push({
        priority: "high",
        category: "authentication",
        title: "Kích hoạt xác thực 2 yếu tố",
        description:
          "Mức độ rủi ro cao được phát hiện. Hãy kích hoạt 2FA để tăng cường bảo mật.",
      });
      recommendations.push({
        priority: "high",
        category: "monitoring",
        title: "Kiểm tra hoạt động đăng nhập",
        description:
          "Xem lại tất cả hoạt động đăng nhập gần đây và kết thúc các phiên đáng ngờ.",
      });
    }
    // Location-based recommendations
    if (analysis.locationAnalysis.suspiciousActivity) {
      recommendations.push({
        priority: "medium",
        category: "location",
        title: "Hoạt động từ nhiều vị trí",
        description:
          "Phát hiện đăng nhập từ nhiều vị trí khác nhau. Hãy xác minh các đăng nhập này.",
      });
    }
    // Failed login recommendations
    const failureRate = parseFloat(analysis.riskAssessment.loginFailureRate);
    if (failureRate > 20) {
      recommendations.push({
        priority: "medium",
        category: "authentication",
        title: "Tỷ lệ đăng nhập thất bại cao",
        description:
          "Có nhiều lần đăng nhập thất bại. Hãy đổi mật khẩu nếu cần thiết.",
      });
    }
    // General security recommendations
    if (!analysis.eventsByType["2fa_enabled"]) {
      recommendations.push({
        priority: "low",
        category: "security",
        title: "Cải thiện bảo mật tài khoản",
        description:
          "Hãy kích hoạt 2FA và cập nhật mật khẩu định kỳ để đảm bảo an toàn.",
      });
    }
    return recommendations;
  }
  /**
   * Generate event ID
   * @returns {string} Unique event ID
   */
  static generateEventId() {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  /**
   * Get security metrics summary
   * @param {Array} securityEvents - Security events
   * @returns {Object} Security metrics
   */
  static getSecurityMetrics(securityEvents) {
    const now = new Date();
    const last24h = securityEvents.filter(
      (e) =>
        new Date(e.timestamp) >= new Date(now.getTime() - 24 * 60 * 60 * 1000)
    );
    const last7d = securityEvents.filter(
      (e) =>
        new Date(e.timestamp) >=
        new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    );
    return {
      totalEvents: securityEvents.length,
      last24Hours: last24h.length,
      last7Days: last7d.length,
      uniqueLocations: new Set(
        securityEvents.map((e) => e.location).filter(Boolean)
      ).size,
      uniqueIPs: new Set(securityEvents.map((e) => e.ipAddress).filter(Boolean))
        .size,
      eventTypes: this.groupEventsByType(securityEvents),
      lastActivity:
        securityEvents.length > 0
          ? securityEvents[securityEvents.length - 1].timestamp
          : null,
    };
  }
}
export default SecurityAnalyticsService;