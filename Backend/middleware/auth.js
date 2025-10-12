import jwt from "jsonwebtoken";
import { User } from "../models/index.js";
import rateLimit from "express-rate-limit";
import SessionService from "../services/SessionService.js";
import crypto from "crypto";
import { sendUnauthorized, sendBadRequest, sendRateLimitExceeded, sendServerError } from "../utils/responseHelper.js";
// JWT Secret
const JWT_SECRET =
  process.env.JWT_SECRET || "your_jwt_secret_change_in_production";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";
const JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || "your_refresh_secret";
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || "30d";
// Generate JWT tokens with session tracking
export const generateTokens = async (userId, req, loginMethod = "password") => {
  // Generate unique token ID for session tracking
  const jwtTokenId = crypto.randomBytes(16).toString("hex");
  const accessToken = jwt.sign(
    {
      userId,
      type: "access",
      jti: jwtTokenId,
    },
    JWT_SECRET,
    {
      expiresIn: JWT_EXPIRES_IN,
      issuer: "zbudget-api",
      audience: "zbudget-app",
    }
  );
  const refreshToken = jwt.sign(
    {
      userId,
      type: "refresh",
      jti: jwtTokenId,
    },
    JWT_REFRESH_SECRET,
    {
      expiresIn: JWT_REFRESH_EXPIRES_IN,
      issuer: "zbudget-api",
      audience: "zbudget-app",
    }
  );
  // Calculate expiration date
  const expiresAt = new Date();
  const expiresInMs = jwt.decode(accessToken).exp * 1000;
  expiresAt.setTime(expiresInMs);
  // Create session synchronously to ensure it's ready
  if (req) {
    try {
      await SessionService.createSession(
        userId,
        jwtTokenId,
        req,
        expiresAt,
        loginMethod
      );
    } catch (error) {
      console.error("Failed to create session:", error.message);
    }
  }
  return { accessToken, refreshToken, jwtTokenId };
};
// Verify JWT token
export const verifyToken = (token, secret = JWT_SECRET) => {
  try {
    return jwt.verify(token, secret, {
      issuer: "zbudget-api",
      audience: "zbudget-app",
    });
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      throw new Error("Token đã hết hạn");
    } else if (error.name === "JsonWebTokenError") {
      throw new Error("Token không hợp lệ");
    } else {
      throw new Error("Lỗi xác thực token");
    }
  }
};
export const verifyRefreshToken = (token) => {
  return verifyToken(token, JWT_REFRESH_SECRET);
};
// Authentication middleware
export const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({
        success: false,
        error: "Thiếu authorization header",
        code: "MISSING_AUTH_HEADER",
      });
    }
    // Check format: Bearer <token>
    const tokenParts = authHeader.split(" ");
    if (tokenParts.length !== 2 || tokenParts[0] !== "Bearer") {
      return res.status(401).json({
        success: false,
        error:
          "Format authorization header không hợp lệ. Sử dụng: Bearer <token>",
        code: "INVALID_AUTH_FORMAT",
      });
    }
    const token = tokenParts[1];
    // Check if token is blacklisted
    if (isTokenBlacklisted(token)) {
      return res.status(401).json({
        success: false,
        error: "Token đã bị thu hồi",
        code: "TOKEN_BLACKLISTED",
      });
    }
    // Verify token
    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (error) {
      return res.status(401).json({
        success: false,
        error: error.message,
        code: "INVALID_TOKEN",
      });
    }
    // Check token type
    if (decoded.type !== "access") {
      return res.status(401).json({
        success: false,
        error: "Token type không hợp lệ",
        code: "INVALID_TOKEN_TYPE",
      });
    }
    // Get user from database
    const user = await User.findById(decoded.userId).select("-passwordHash");
    if (!user) {
      return res.status(401).json({
        success: false,
        error: "Người dùng không tồn tại",
        code: "USER_NOT_FOUND",
      });
    }
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        error: "Tài khoản đã bị vô hiệu hóa",
        code: "ACCOUNT_DISABLED",
      });
    }
    // Add user to request
    req.user = user;
    req.userId = user._id.toString();
    req.sessionId = decoded.jti; // JWT token ID used as session ID
    // Update session activity in background
    if (decoded.jti) {
      SessionService.updateActivity(decoded.jti).catch((error) => {
        console.error("Failed to update session activity:", error.message);
      });
    }
    next();
  } catch (error) {
    console.error("❌ Authentication error:", error);
    return res.status(500).json({
      success: false,
      error: "Lỗi server trong quá trình xác thực",
      code: "AUTH_SERVER_ERROR",
    });
  }
};
// Optional authentication middleware (doesn't fail if no token)
export const optionalAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    req.user = null;
    req.userId = null;
    return next();
  }
  try {
    // Use the authenticate middleware logic
    await authenticate(req, res, next);
  } catch (error) {
    // If authentication fails, continue without user
    req.user = null;
    req.userId = null;
    next();
  }
};
// Alias for optionalAuth
export const optionalAuthenticate = optionalAuth;
// Admin middleware
export const requireAdmin = async (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      error: "Yêu cầu xác thực",
      code: "AUTHENTICATION_REQUIRED",
    });
  }
  // Check if user has admin privileges
  // This could be a role field in User model or special admin users
  const adminEmails = (process.env.ADMIN_EMAILS || "").split(",");
  const isAdmin =
    adminEmails.includes(req.user.email) || req.user.role === "admin";
  if (!isAdmin) {
    return res.status(403).json({
      success: false,
      error: "Yêu cầu quyền quản trị viên",
      code: "ADMIN_REQUIRED",
    });
  }
  next();
};
// Refresh token middleware
export const refreshTokenMiddleware = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: "Thiếu refresh token",
        code: "MISSING_REFRESH_TOKEN",
      });
    }
    // Verify refresh token
    let decoded;
    try {
      decoded = verifyToken(refreshToken, JWT_REFRESH_SECRET);
    } catch (error) {
      return res.status(401).json({
        success: false,
        error: "Refresh token không hợp lệ",
        code: "INVALID_REFRESH_TOKEN",
      });
    }
    // Check token type
    if (decoded.type !== "refresh") {
      return res.status(401).json({
        success: false,
        error: "Token type không hợp lệ",
        code: "INVALID_TOKEN_TYPE",
      });
    }
    // Get user
    const user = await User.findById(decoded.userId);
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        error: "Người dùng không hợp lệ",
        code: "INVALID_USER",
      });
    }
    req.user = user;
    req.userId = user._id.toString();
    next();
  } catch (error) {
    console.error("Refresh token error:", error);
    return res.status(500).json({
      success: false,
      error: "Lỗi server trong quá trình làm mới token",
      code: "REFRESH_SERVER_ERROR",
    });
  }
};
// Rate limit for sensitive operations
export const sensitiveRateLimit = (windowMs = 5 * 60 * 1000, max = 5) => {
  const attempts = new Map();
  return (req, res, next) => {
    const key = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    // Clean old attempts
    for (const [ip, data] of attempts.entries()) {
      if (now - data.resetTime > windowMs) {
        attempts.delete(ip);
      }
    }
    // Check current attempts
    const userAttempts = attempts.get(key);
    if (!userAttempts) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (now - userAttempts.resetTime > windowMs) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (userAttempts.count >= max) {
      const resetIn = Math.ceil(
        (windowMs - (now - userAttempts.resetTime)) / 1000
      );
      return res.status(429).json({
        success: false,
        error: "Quá nhiều attempts. Vui lòng thử lại sau.",
        retryAfter: resetIn,
        code: "RATE_LIMIT_EXCEEDED",
      });
    }
    userAttempts.count++;
    next();
  };
};
// Simple token blacklist (in production, use Redis)
const blacklistedTokens = new Set();
export const blacklistToken = (token) => {
  if (token) {
    blacklistedTokens.add(token);
  }
  return Promise.resolve();
};
export const isTokenBlacklisted = (token) => {
  return blacklistedTokens.has(token);
};
// Rate limiting for authentication routes
export const rateLimitAuth = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_AUTH_MAX_REQUESTS) || 5, // Use separate limit for auth routes
  message: {
    success: false,
    error: "Quá nhiều yêu cầu đăng nhập. Vui lòng thử lại sau.",
  },
  standardHeaders: true,
  legacyHeaders: false,
  // ✅ FIXED: Use handler instead of deprecated onLimitReached
  handler: (req, res, next, options) => {
    res.status(429).json({
      success: false,
      error: "Quá nhiều yêu cầu đăng nhập. Vui lòng thử lại sau.",
      code: "RATE_LIMIT_EXCEEDED",
    });
  },
  // Enhanced skip function with detailed logging
  skip: (req, res) => {
    return false; // Don't skip, apply rate limiting
  },
  // Add handler for successful requests
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: "Quá nhiều yêu cầu đăng nhập. Vui lòng thử lại sau.",
      retryAfter:
        Math.ceil(parseInt(process.env.RATE_LIMIT_WINDOW_MS) / 1000) || 900,
    });
  },
  // Add keyGenerator for debugging
  keyGenerator: (req) => {
    const key = req.ip;
    return key;
  },
});
// Create a wrapper middleware to add more debugging
export const debugRateLimitAuth = (req, res, next) => {
  // Apply the actual rate limiting
  rateLimitAuth(req, res, (err) => {
    if (err) {
      return next(err);
    }
    next();
  });
};
// Rate limiting for password-related routes
export const rateLimitPassword = (windowMs = 5 * 60 * 1000, max = 3) => {
  const attempts = new Map();
  return (req, res, next) => {
    const key = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    // Clean old attempts
    for (const [ip, data] of attempts.entries()) {
      if (now - data.resetTime > windowMs) {
        attempts.delete(ip);
      }
    }
    // Check current attempts
    const userAttempts = attempts.get(key);
    if (!userAttempts) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (now - userAttempts.resetTime > windowMs) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (userAttempts.count >= max) {
      const resetIn = Math.ceil(
        (windowMs - (now - userAttempts.resetTime)) / 1000
      );
      return res.status(429).json({
        success: false,
        error: "Quá nhiều yêu cầu đổi mật khẩu, vui lòng thử lại sau 5 phút",
        retryAfter: resetIn,
        code: "PASSWORD_RATE_LIMIT_EXCEEDED",
      });
    }
    userAttempts.count++;
    next();
  };
};
// General rate limiting for API routes
export const rateLimitGeneral = (windowMs = 15 * 60 * 1000, max = 100) => {
  const attempts = new Map();
  return (req, res, next) => {
    const key = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    // Clean old attempts
    for (const [ip, data] of attempts.entries()) {
      if (now - data.resetTime > windowMs) {
        attempts.delete(ip);
      }
    }
    // Check current attempts
    const userAttempts = attempts.get(key);
    if (!userAttempts) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (now - userAttempts.resetTime > windowMs) {
      attempts.set(key, { count: 1, resetTime: now });
      return next();
    }
    if (userAttempts.count >= max) {
      const resetIn = Math.ceil(
        (windowMs - (now - userAttempts.resetTime)) / 1000
      );
      return res.status(429).json({
        success: false,
        error: "Quá nhiều yêu cầu API, vui lòng thử lại sau",
        retryAfter: resetIn,
        code: "API_RATE_LIMIT_EXCEEDED",
      });
    }
    userAttempts.count++;
    next();
  };
};
export default {
  generateTokens,
  verifyToken,
  authenticate,
  optionalAuth,
  optionalAuthenticate,
  requireAdmin,
  refreshTokenMiddleware,
  sensitiveRateLimit,
  blacklistToken,
  isTokenBlacklisted,
  rateLimitAuth,
  rateLimitPassword,
  rateLimitGeneral,
};