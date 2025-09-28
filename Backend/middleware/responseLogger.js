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

  console.log("\n" + "=".repeat(80));
  console.log(`📥 INCOMING REQUEST - ${requestLog.timestamp}`);
  console.log("=".repeat(80));
  console.log(`Method: ${req.method}`);
  console.log(`URL: ${req.originalUrl}`);
  console.log(`IP: ${req.ip}`);
  console.log(`User-Agent: ${req.get("User-Agent")}`);
  console.log("Headers:", JSON.stringify(req.headers, null, 2));
  console.log("Query Params:", JSON.stringify(req.query, null, 2));
  console.log("Body:", JSON.stringify(req.body, null, 2));

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
  console.log("\n" + "=".repeat(80));
  console.log(`📤 OUTGOING RESPONSE - ${timestamp}`);
  console.log("=".repeat(80));
  console.log(`Method: ${req.method}`);
  console.log(`URL: ${req.originalUrl}`);
  console.log(`Status: ${res.statusCode}`);
  console.log(`Duration: ${duration}ms`);
  console.log("Response Headers:", JSON.stringify(res.getHeaders(), null, 2));
  console.log(
    "Response Body:",
    JSON.stringify(typeof data === "string" ? JSON.parse(data) : data, null, 2)
  );
  console.log("=".repeat(80) + "\n");

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
