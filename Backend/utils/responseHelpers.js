/**
 * Response Helper Utilities
 * Provides standardized response formats for API endpoints
 */

/**
 * Sends a successful response with data
 * @param {Object} res - Express response object
 * @param {any} data - The data to send in response
 * @param {string} message - Success message
 * @param {number} statusCode - HTTP status code (default: 200)
 */
export const successResponse = (
  res,
  data = null,
  message = "Success",
  statusCode = 200
) => {
  const response = {
    success: true,
    message,
    ...(data && { data }),
  };

  return res.status(statusCode).json(response);
};

/**
 * Sends an error response
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code (default: 400)
 * @param {any} error - Additional error details
 */
export const errorResponse = (
  res,
  message = "Error occurred",
  statusCode = 400,
  error = null
) => {
  const response = {
    success: false,
    message,
    ...(error && { error }),
  };

  return res.status(statusCode).json(response);
};

/**
 * Sends a validation error response
 * @param {Object} res - Express response object
 * @param {Array|string} errors - Validation errors
 */
export const validationErrorResponse = (res, errors) => {
  return res.status(422).json({
    success: false,
    message: "Validation failed",
    errors: Array.isArray(errors) ? errors : [errors],
  });
};

/**
 * Sends a not found response
 * @param {Object} res - Express response object
 * @param {string} message - Not found message
 */
export const notFoundResponse = (res, message = "Resource not found") => {
  return res.status(404).json({
    success: false,
    message,
  });
};

/**
 * Sends an unauthorized response
 * @param {Object} res - Express response object
 * @param {string} message - Unauthorized message
 */
export const unauthorizedResponse = (res, message = "Unauthorized") => {
  return res.status(401).json({
    success: false,
    message,
  });
};

/**
 * Sends a forbidden response
 * @param {Object} res - Express response object
 * @param {string} message - Forbidden message
 */
export const forbiddenResponse = (res, message = "Forbidden") => {
  return res.status(403).json({
    success: false,
    message,
  });
};

/**
 * Sends a paginated response
 * @param {Object} res - Express response object
 * @param {Array} data - The paginated data
 * @param {Object} pagination - Pagination metadata
 * @param {string} message - Success message
 */
export const paginatedResponse = (
  res,
  data,
  pagination,
  message = "Data retrieved successfully"
) => {
  return res.status(200).json({
    success: true,
    message,
    data,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      pages: Math.ceil(pagination.total / pagination.limit),
      hasNext: pagination.page < Math.ceil(pagination.total / pagination.limit),
      hasPrev: pagination.page > 1,
    },
  });
};

export default {
  successResponse,
  errorResponse,
  validationErrorResponse,
  notFoundResponse,
  unauthorizedResponse,
  forbiddenResponse,
  paginatedResponse,
};
