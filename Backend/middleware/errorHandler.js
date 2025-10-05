import mongoose from "mongoose";

// Custom error classes
export class AppError extends Error {
  constructor(message, statusCode, code = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith("4") ? "fail" : "error";
    this.code = code;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message, errors = null) {
    super(message, 400, "VALIDATION_ERROR");
    this.errors = errors;
  }
}

export class NotFoundError extends AppError {
  constructor(resource = "Resource") {
    super(`${resource} không được tìm thấy`, 404, "NOT_FOUND");
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = "Không có quyền truy cập") {
    super(message, 401, "UNAUTHORIZED");
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "Không đủ quyền thực hiện hành động này") {
    super(message, 403, "FORBIDDEN");
  }
}

export class ConflictError extends AppError {
  constructor(message = "Dữ liệu xung đột") {
    super(message, 409, "CONFLICT");
  }
}

export class BadRequestError extends AppError {
  constructor(message = "Yêu cầu không hợp lệ", details = null) {
    super(message, 400, "BAD_REQUEST");
    this.details = details;
  }
}

// Handle Mongoose validation errors
const handleValidationError = (error) => {
  const errors = {};

  Object.values(error.errors).forEach(({ properties }) => {
    if (properties) {
      errors[properties.path] = properties.message;
    }
  });

  return new ValidationError("Dữ liệu đầu vào không hợp lệ", errors);
};

// Handle Mongoose duplicate key errors
const handleDuplicateKeyError = (error) => {
  const field = Object.keys(error.keyValue)[0];
  const value = error.keyValue[field];

  const fieldNames = {
    email: "Email",
    phone: "Số điện thoại",
    challengeId: "Challenge ID",
    inviteCode: "Mã mời",
  };

  const fieldName = fieldNames[field] || field;

  return new ConflictError(`${fieldName} '${value}' đã được sử dụng`);
};

// Handle Mongoose cast errors
const handleCastError = (error) => {
  const message = `ID không hợp lệ: ${error.value}`;
  return new ValidationError(message);
};

// Handle JWT errors
const handleJWTError = () => new UnauthorizedError("Token không hợp lệ");
const handleJWTExpiredError = () => new UnauthorizedError("Token đã hết hạn");

// Send error response in development
const sendErrorDev = (err, res) => {
  console.log("📤 DEBUG: Sending development error response");
  console.log("📋 DEBUG: Response payload:", {
    success: false,
    error: err.message,
    code: err.code,
    statusCode: err.statusCode,
  });

  res.status(err.statusCode).json({
    success: false,
    error: err.message,
    code: err.code,
    stack: err.stack,
    details: err.errors || null,
  });

  console.log("✅ DEBUG: Development error response sent");
};

// Send error response in production
const sendErrorProd = (err, res) => {
  console.log("📤 DEBUG: Sending production error response");
  console.log("📋 DEBUG: Error operational status:", err.isOperational);

  // Operational, trusted error: send message to client
  if (err.isOperational) {
    console.log("✅ DEBUG: Sending operational error response");
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      code: err.code,
      details: err.errors || null,
    });
  } else {
    // Programming or other unknown error: don't leak error details
    console.error("ERROR 💥", err);
    console.log(
      "🚨 DEBUG: Sending generic error response for non-operational error"
    );

    res.status(500).json({
      success: false,
      error: "Có lỗi xảy ra! Vui lòng thử lại sau.",
      code: "INTERNAL_SERVER_ERROR",
    });
  }

  console.log("✅ DEBUG: Production error response sent");
};

// Global error handling middleware
export const errorHandler = (err, req, res, next) => {
  console.log("💥 DEBUG: ===== ERROR HANDLER TRIGGERED =====");
  console.log(`💥 DEBUG: Error type: ${err.name}`);
  console.log(`💥 DEBUG: Error message: ${err.message}`);
  console.log(`💥 DEBUG: Request path: ${req.path}`);
  console.log(`💥 DEBUG: Request method: ${req.method}`);

  let error = { ...err };
  error.message = err.message;

  // Mongoose bad ObjectId
  if (err.name === "CastError") {
    console.log("💥 DEBUG: Handling CastError");
    const message = "Tài nguyên không tồn tại";
    error = new NotFoundError(message);
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    console.log("💥 DEBUG: Handling duplicate key error");
    const message = "Dữ liệu đã tồn tại";
    error = new ConflictError(message);
  }

  // Mongoose validation error
  if (err.name === "ValidationError") {
    console.log("💥 DEBUG: Handling ValidationError");
    const message = Object.values(err.errors).map((val) => val.message);
    error = new BadRequestError(message);
  }

  // JWT errors
  if (err.name === "JsonWebTokenError") {
    console.log("💥 DEBUG: Handling JWT error");
    const message = "Token không hợp lệ";
    error = new UnauthorizedError(message);
  }

  if (err.name === "TokenExpiredError") {
    console.log("💥 DEBUG: Handling expired token error");
    const message = "Token đã hết hạn";
    error = new UnauthorizedError(message);
  }

  const statusCode = error.statusCode || 500;
  const message = error.message || "Lỗi server";

  console.log(
    `💥 DEBUG: Sending error response - Status: ${statusCode}, Message: ${message}`
  );

  const errorResponse = {
    success: false,
    error: message,
    ...(process.env.NODE_ENV === "development" && {
      stack: err.stack,
      details: err,
    }),
  };

  console.log(
    "💥 DEBUG: Error response:",
    JSON.stringify(errorResponse, null, 2)
  );
  console.log("💥 DEBUG: ===== ERROR HANDLER COMPLETED =====");

  res.status(statusCode).json(errorResponse);
};

// Async error handler wrapper
export const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Validation middleware factory
export const validateSchema = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = {};
      error.details.forEach((detail) => {
        errors[detail.path.join(".")] = detail.message;
      });

      return next(new ValidationError("Dữ liệu đầu vào không hợp lệ", errors));
    }

    next();
  };
};

// MongoDB transaction wrapper with error handling
export const withTransaction = async (operations) => {
  const session = await mongoose.startSession();

  try {
    const result = await session.withTransaction(async () => {
      return await operations(session);
    });

    return result;
  } catch (error) {
    console.error("Transaction error:", error);

    // Handle specific MongoDB transaction errors
    if (
      error.errorLabels &&
      error.errorLabels.includes("TransientTransactionError")
    ) {
      throw new AppError(
        "Giao dịch bị gián đoạn, vui lòng thử lại",
        500,
        "TRANSACTION_ERROR"
      );
    }

    if (
      error.errorLabels &&
      error.errorLabels.includes("UnknownTransactionCommitResult")
    ) {
      throw new AppError(
        "Kết quả giao dịch không rõ ràng, vui lòng kiểm tra dữ liệu",
        500,
        "UNKNOWN_TRANSACTION_RESULT"
      );
    }

    throw error;
  } finally {
    await session.endSession();
  }
};

// Request validation helpers
export const validateObjectId = (id, fieldName = "ID") => {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new ValidationError(`${fieldName} không hợp lệ`);
  }
  return new mongoose.Types.ObjectId(id);
};

export const validateRequired = (value, fieldName) => {
  if (value === undefined || value === null || value === "") {
    throw new ValidationError(`${fieldName} là bắt buộc`);
  }
};

export const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new ValidationError("Email không hợp lệ");
  }
};

export const validatePassword = (password) => {
  if (password.length < 8) {
    throw new ValidationError("Mật khẩu phải có ít nhất 8 ký tự");
  }

  if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(password)) {
    throw new ValidationError(
      "Mật khẩu phải chứa ít nhất 1 chữ thường, 1 chữ hoa và 1 số"
    );
  }
};

export const validateAmount = (amount) => {
  const numAmount = parseFloat(amount);
  if (isNaN(numAmount) || numAmount < 0) {
    throw new ValidationError("Số tiền phải là số dương hợp lệ");
  }
  return numAmount;
};

export const validateDateRange = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);

  if (isNaN(start.getTime())) {
    throw new ValidationError("Ngày bắt đầu không hợp lệ");
  }

  if (isNaN(end.getTime())) {
    throw new ValidationError("Ngày kết thúc không hợp lệ");
  }

  if (start >= end) {
    throw new ValidationError("Ngày bắt đầu phải nhỏ hơn ngày kết thúc");
  }

  return { startDate: start, endDate: end };
};

// Success response helper
export const sendSuccess = (
  res,
  data = null,
  message = "Thành công",
  statusCode = 200
) => {
  res.status(statusCode).json({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
};

// Pagination helper
export const getPagination = (req) => {
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

// Sort helper
export const getSort = (req, defaultSort = { createdAt: -1 }) => {
  const { sort } = req.query;

  if (!sort) return defaultSort;

  const sortFields = {};
  const fields = sort.split(",");

  fields.forEach((field) => {
    const isDesc = field.startsWith("-");
    const fieldName = isDesc ? field.substring(1) : field;
    sortFields[fieldName] = isDesc ? -1 : 1;
  });

  return sortFields;
};

// Helper function for success responses
export const successResponse = (
  res,
  message,
  data = null,
  statusCode = 200
) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

// Helper function for error responses
export const errorResponse = (res, message, statusCode = 500, data = null) => {
  return res.status(statusCode).json({
    success: false,
    error: message,
    data,
  });
};

export default {
  AppError,
  ValidationError,
  NotFoundError,
  UnauthorizedError,
  ForbiddenError,
  ConflictError,
  BadRequestError,
  errorHandler,
  catchAsync,
  validateSchema,
  withTransaction,
  validateObjectId,
  validateRequired,
  validateEmail,
  validatePassword,
  validateAmount,
  validateDateRange,
  sendSuccess,
  getPagination,
  getSort,
  successResponse,
};
