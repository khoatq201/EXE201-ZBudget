/**
 * Rate Limiter Helper - Create custom rate limiters
 * Replacement for duplicate rate limiting code
 */

/**
 * Create a simple in-memory rate limiter
 * @param {Object} options - Configuration options
 * @returns {Function} - Express middleware function
 */
export const createRateLimiter = (options = {}) => {
  const {
    windowMs = 15 * 60 * 1000, // 15 minutes default
    max = 100, // Max requests per window
    errorMessage = "Quá nhiều requests. Vui lòng thử lại sau.",
    errorCode = "RATE_LIMIT_EXCEEDED",
    skipSuccessfulRequests = false,
    keyGenerator = (req) => req.ip || req.connection.remoteAddress,
  } = options;

  // In-memory store for attempts
  const attempts = new Map();

  // Cleanup interval - run every minute
  const cleanupInterval = setInterval(() => {
    const now = Date.now();
    for (const [key, data] of attempts.entries()) {
      if (now - data.resetTime > windowMs) {
        attempts.delete(key);
      }
    }
  }, 60 * 1000); // Clean up every 60 seconds

  // Ensure cleanup on process exit
  if (typeof process !== 'undefined') {
    process.on('exit', () => clearInterval(cleanupInterval));
  }

  return (req, res, next) => {
    const key = keyGenerator(req);
    const now = Date.now();

    // Clean old attempts for this key
    const userAttempts = attempts.get(key);

    // First request or window expired
    if (!userAttempts || now - userAttempts.resetTime > windowMs) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }

    // Check if limit exceeded
    if (userAttempts.count >= max) {
      const resetIn = Math.ceil((windowMs - (now - userAttempts.resetTime)) / 1000);

      return res.status(429).json({
        success: false,
        error: errorMessage,
        retryAfter: resetIn,
        code: errorCode,
      });
    }

    // Increment count
    userAttempts.count++;

    // Skip incrementing on successful requests if configured
    if (skipSuccessfulRequests) {
      res.on('finish', () => {
        if (res.statusCode < 400) {
          userAttempts.count--;
        }
      });
    }

    next();
  };
};

/**
 * Preset: Rate limiter for authentication routes
 * @param {Object} customOptions - Override default options
 * @returns {Function} - Express middleware
 */
export const createAuthRateLimiter = (customOptions = {}) => {
  return createRateLimiter({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 attempts
    errorMessage: "Quá nhiều yêu cầu đăng nhập. Vui lòng thử lại sau.",
    errorCode: "AUTH_RATE_LIMIT_EXCEEDED",
    skipSuccessfulRequests: true, // Only count failed attempts
    ...customOptions,
  });
};

/**
 * Preset: Rate limiter for password-related routes
 * @param {Object} customOptions - Override default options
 * @returns {Function} - Express middleware
 */
export const createPasswordRateLimiter = (customOptions = {}) => {
  return createRateLimiter({
    windowMs: 5 * 60 * 1000, // 5 minutes
    max: 3, // 3 attempts
    errorMessage: "Quá nhiều yêu cầu đổi mật khẩu. Vui lòng thử lại sau 5 phút.",
    errorCode: "PASSWORD_RATE_LIMIT_EXCEEDED",
    ...customOptions,
  });
};

/**
 * Preset: General API rate limiter
 * @param {Object} customOptions - Override default options
 * @returns {Function} - Express middleware
 */
export const createGeneralRateLimiter = (customOptions = {}) => {
  return createRateLimiter({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requests
    errorMessage: "Quá nhiều yêu cầu API. Vui lòng thử lại sau.",
    errorCode: "API_RATE_LIMIT_EXCEEDED",
    ...customOptions,
  });
};

/**
 * Preset: Sensitive operations rate limiter (OTP, verification, etc.)
 * @param {Object} customOptions - Override default options
 * @returns {Function} - Express middleware
 */
export const createSensitiveRateLimiter = (customOptions = {}) => {
  return createRateLimiter({
    windowMs: 5 * 60 * 1000, // 5 minutes
    max: 5, // 5 attempts
    errorMessage: "Quá nhiều attempts. Vui lòng thử lại sau.",
    errorCode: "SENSITIVE_RATE_LIMIT_EXCEEDED",
    ...customOptions,
  });
};

/**
 * Rate limiter with IP + User ID combo (for authenticated routes)
 * @param {Object} options - Configuration options
 * @returns {Function} - Express middleware
 */
export const createUserBasedRateLimiter = (options = {}) => {
  return createRateLimiter({
    ...options,
    keyGenerator: (req) => {
      const ip = req.ip || req.connection.remoteAddress;
      const userId = req.userId || req.user?.id || req.user?._id;
      return userId ? `${ip}:${userId}` : ip;
    },
  });
};

export default {
  createRateLimiter,
  createAuthRateLimiter,
  createPasswordRateLimiter,
  createGeneralRateLimiter,
  createSensitiveRateLimiter,
  createUserBasedRateLimiter,
};
