import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, "../../logs");
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Log levels
const LOG_LEVELS = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3,
};

const currentLogLevel =
  LOG_LEVELS[process.env.LOG_LEVEL?.toUpperCase()] || LOG_LEVELS.INFO;

// Colors for console output
const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  white: "\x1b[37m",
};

// Get client IP address
const getClientIP = (req) => {
  return (
    req.ip ||
    req.connection.remoteAddress ||
    req.socket.remoteAddress ||
    (req.connection.socket ? req.connection.socket.remoteAddress : null) ||
    "unknown"
  );
};

// Get user agent info
const getUserAgent = (req) => {
  const userAgent = req.headers["user-agent"] || "Unknown";

  // Simple device detection
  let device = "desktop";
  if (/Mobile|Android|iPhone|iPad/.test(userAgent)) {
    device = "mobile";
  } else if (/iPad|Tablet/.test(userAgent)) {
    device = "tablet";
  }

  return { userAgent, device };
};

// Format log message
const formatLogMessage = (level, message, meta = {}) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...meta,
  };

  return JSON.stringify(logEntry);
};

// Write log to file
const writeToFile = (level, message, meta = {}) => {
  if (process.env.NODE_ENV === "test") return;

  const logFile = path.join(logsDir, `${level.toLowerCase()}.log`);
  const logMessage = formatLogMessage(level, message, meta) + "\n";

  fs.appendFile(logFile, logMessage, (err) => {
    if (err) {
      console.error("Failed to write to log file:", err);
    }
  });

  // Also write to general log file
  const generalLogFile = path.join(logsDir, "app.log");
  fs.appendFile(generalLogFile, logMessage, (err) => {
    if (err && level === "ERROR") {
      console.error("Failed to write to general log file:", err);
    }
  });
};

// Console log with colors
const consoleLog = (level, message, meta = {}) => {
  const timestamp = new Date().toLocaleString("vi-VN");
  const colorMap = {
    ERROR: colors.red,
    WARN: colors.yellow,
    INFO: colors.cyan,
    DEBUG: colors.dim,
  };

  const color = colorMap[level] || colors.white;
  const resetColor = colors.reset;

  let logOutput = `${color}[${timestamp}] ${level}:${resetColor} ${message}`;

  if (Object.keys(meta).length > 0) {
    logOutput += `\n${colors.dim}${JSON.stringify(meta, null, 2)}${resetColor}`;
  }

  console.log(logOutput);
};

// Main logger class
class Logger {
  log(level, message, meta = {}) {
    const levelValue = LOG_LEVELS[level];

    if (levelValue <= currentLogLevel) {
      consoleLog(level, message, meta);
      writeToFile(level, message, meta);
    }
  }

  error(message, meta = {}) {
    this.log("ERROR", message, meta);
  }

  warn(message, meta = {}) {
    this.log("WARN", message, meta);
  }

  info(message, meta = {}) {
    this.log("INFO", message, meta);
  }

  debug(message, meta = {}) {
    this.log("DEBUG", message, meta);
  }
}

const logger = new Logger();

// Request logging middleware
export const requestLogger = (req, res, next) => {
  const startTime = Date.now();
  const clientIP = getClientIP(req);
  const { userAgent, device } = getUserAgent(req);

  // Skip logging for health checks and static files
  if (req.path === "/api/health" || req.path.startsWith("/static/")) {
    return next();
  }

  // Log request
  const requestMeta = {
    method: req.method,
    url: req.originalUrl,
    ip: clientIP,
    userAgent: userAgent.substring(0, 200), // Truncate long user agents
    device,
    userId: req.userId || null,
    body: req.method !== "GET" ? sanitizeBody(req.body) : undefined,
    query: Object.keys(req.query).length > 0 ? req.query : undefined,
  };

  logger.info(`${req.method} ${req.originalUrl}`, requestMeta);

  // Override res.json to log response
  const originalJson = res.json;
  res.json = function (data) {
    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;

    const responseMeta = {
      method: req.method,
      url: req.originalUrl,
      statusCode,
      duration: `${duration}ms`,
      ip: clientIP,
      userId: req.userId || null,
      responseSize: JSON.stringify(data).length,
    };

    // Log based on status code
    if (statusCode >= 500) {
      logger.error(`${req.method} ${req.originalUrl} - ${statusCode}`, {
        ...responseMeta,
        error: data.error || "Server Error",
      });
    } else if (statusCode >= 400) {
      logger.warn(`${req.method} ${req.originalUrl} - ${statusCode}`, {
        ...responseMeta,
        error: data.error || "Client Error",
      });
    } else {
      logger.info(
        `${req.method} ${req.originalUrl} - ${statusCode}`,
        responseMeta
      );
    }

    return originalJson.call(this, data);
  };

  next();
};

// Sanitize request body for logging (remove sensitive data)
const sanitizeBody = (body) => {
  if (!body || typeof body !== "object") return body;

  const sanitized = { ...body };
  const sensitiveFields = [
    "password",
    "passwordHash",
    "token",
    "refreshToken",
    "accessToken",
    "pin",
    "cvv",
    "cardNumber",
  ];

  sensitiveFields.forEach((field) => {
    if (sanitized[field]) {
      sanitized[field] = "***REDACTED***";
    }
  });

  return sanitized;
};

// Security logging middleware
export const securityLogger = (event, req, meta = {}) => {
  const clientIP = getClientIP(req);
  const { userAgent } = getUserAgent(req);

  const securityMeta = {
    event,
    ip: clientIP,
    userAgent: userAgent.substring(0, 200),
    userId: req.userId || null,
    timestamp: new Date().toISOString(),
    ...meta,
  };

  logger.warn(`Security Event: ${event}`, securityMeta);

  // Write to security log file
  const securityLogFile = path.join(logsDir, "security.log");
  const logMessage =
    formatLogMessage("SECURITY", `Security Event: ${event}`, securityMeta) +
    "\n";

  fs.appendFile(securityLogFile, logMessage, (err) => {
    if (err) {
      console.error("Failed to write to security log file:", err);
    }
  });
};

// Database operation logging
export const dbLogger = (operation, collection, meta = {}) => {
  const dbMeta = {
    operation,
    collection,
    timestamp: new Date().toISOString(),
    ...meta,
  };

  logger.debug(`DB Operation: ${operation} on ${collection}`, dbMeta);
};

// Performance logging
export const performanceLogger = (operation, duration, meta = {}) => {
  const perfMeta = {
    operation,
    duration: `${duration}ms`,
    timestamp: new Date().toISOString(),
    ...meta,
  };

  if (duration > 1000) {
    logger.warn(`Slow Operation: ${operation}`, perfMeta);
  } else {
    logger.debug(`Operation: ${operation}`, perfMeta);
  }
};

// Error logging with stack trace
export const errorLogger = (error, req = null, meta = {}) => {
  const errorMeta = {
    message: error.message,
    stack: error.stack,
    name: error.name,
    code: error.code,
    timestamp: new Date().toISOString(),
    ...meta,
  };

  if (req) {
    errorMeta.request = {
      method: req.method,
      url: req.originalUrl,
      ip: getClientIP(req),
      userId: req.userId || null,
    };
  }

  logger.error(`Error: ${error.message}`, errorMeta);
};

// Audit logging for sensitive operations
export const auditLogger = (action, req, data = {}) => {
  const auditMeta = {
    action,
    userId: req.userId || null,
    ip: getClientIP(req),
    userAgent: req.headers["user-agent"] || "Unknown",
    timestamp: new Date().toISOString(),
    data: sanitizeBody(data),
  };

  logger.info(`Audit: ${action}`, auditMeta);

  // Write to audit log file
  const auditLogFile = path.join(logsDir, "audit.log");
  const logMessage =
    formatLogMessage("AUDIT", `Audit: ${action}`, auditMeta) + "\n";

  fs.appendFile(auditLogFile, logMessage, (err) => {
    if (err) {
      console.error("Failed to write to audit log file:", err);
    }
  });
};

// Log rotation (basic implementation)
export const rotateLogsDaily = () => {
  const today = new Date().toISOString().split("T")[0];
  const logFiles = ["app.log", "error.log", "security.log", "audit.log"];

  logFiles.forEach((file) => {
    const currentLogPath = path.join(logsDir, file);
    const rotatedLogPath = path.join(logsDir, `${file}.${today}`);

    if (fs.existsSync(currentLogPath)) {
      fs.copyFile(currentLogPath, rotatedLogPath, (err) => {
        if (!err) {
          fs.truncate(currentLogPath, 0, () => {});
        }
      });
    }
  });
};

// Clean old logs (keep last 30 days)
export const cleanOldLogs = () => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  fs.readdir(logsDir, (err, files) => {
    if (err) return;

    files.forEach((file) => {
      const filePath = path.join(logsDir, file);

      fs.stat(filePath, (err, stats) => {
        if (!err && stats.mtime < thirtyDaysAgo) {
          fs.unlink(filePath, () => {});
        }
      });
    });
  });
};

// Schedule daily log rotation (if running as main process)
if (process.env.NODE_ENV === "production") {
  setInterval(() => {
    const now = new Date();
    if (now.getHours() === 0 && now.getMinutes() === 0) {
      rotateLogsDaily();
      cleanOldLogs();
    }
  }, 60000); // Check every minute
}

export default logger;
