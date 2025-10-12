import logger from "./logger.js";
/**
 * Enhanced request/response logging middleware
 */
export const responseLogger = (req, res, next) => {
  const startTime = Date.now();
  // Log incoming request
  const requestLog = {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.get("User-Agent") || "Unknown",
    headers: req.headers,
    query: req.query,
    body: req.body,
    timestamp: new Date().toISOString(),
  };
  // Log detailed request to file
  logger.info(`📥 REQUEST ${req.method} ${req.originalUrl}`, requestLog);
  // Capture original response methods
  const originalJson = res.json;
  const originalSend = res.send;
  // Override response methods to capture response
  res.json = function (data) {
    logResponse(req, res, data, startTime);
    return originalJson.call(this, data);
  };
  res.send = function (data) {
    logResponse(req, res, data, startTime);
    return originalSend.call(this, data);
  };
  next();
};
const logResponse = (req, res, data, startTime) => {
  const duration = Date.now() - startTime;
  const timestamp = new Date().toISOString();
  const responseLog = {
    method: req.method,
    url: req.originalUrl,
    statusCode: res.statusCode,
    duration: `${duration}ms`,
    responseHeaders: res.getHeaders(),
    responseBody: typeof data === "string" ? JSON.parse(data) : data,
    timestamp,
  };
  // Console logging with colors and formatting
  // Log to file based on status code
  if (res.statusCode >= 500) {
    logger.error(
      `📤 RESPONSE ${req.method} ${req.originalUrl} - ${res.statusCode}`,
      responseLog
    );
  } else if (res.statusCode >= 400) {
    logger.warn(
      `📤 RESPONSE ${req.method} ${req.originalUrl} - ${res.statusCode}`,
      responseLog
    );
  } else {
    logger.info(
      `📤 RESPONSE ${req.method} ${req.originalUrl} - ${res.statusCode}`,
      responseLog
    );
  }
};