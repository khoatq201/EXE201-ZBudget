/**
 * Standard error response helper
 * @param {Response} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {string} message - Error message
 * @param {string} code - Error code
 * @param {Object} additionalData - Additional data to include
 */
export const sendErrorResponse = (res, statusCode, message, code, additionalData = {}) => {
  return res.status(statusCode).json({
    success: false,
    error: message,
    code: code,
    ...additionalData
  });
};

/**
 * Send 401 Unauthorized response
 * @param {Response} res - Express response object
 * @param {string} message - Error message
 * @param {string} code - Error code
 */
export const sendUnauthorized = (res, message, code) => {
  return sendErrorResponse(res, 401, message, code);
};

/**
 * Send 403 Forbidden response
 * @param {Response} res - Express response object
 * @param {string} message - Error message
 * @param {string} code - Error code
 */
export const sendForbidden = (res, message, code) => {
  return sendErrorResponse(res, 403, message, code);
};

/**
 * Send 400 Bad Request response
 * @param {Response} res - Express response object
 * @param {string} message - Error message
 * @param {string} code - Error code
 */
export const sendBadRequest = (res, message, code) => {
  return sendErrorResponse(res, 400, message, code);
};

/**
 * Send 429 Too Many Requests response
 * @param {Response} res - Express response object
 * @param {string} message - Error message
 * @param {number} retryAfter - Seconds until retry
 */
export const sendRateLimitExceeded = (res, message, retryAfter, code = 'RATE_LIMIT_EXCEEDED') => {
  return sendErrorResponse(res, 429, message, code, { retryAfter });
};

/**
 * Send 500 Internal Server Error response
 * @param {Response} res - Express response object
 * @param {string} message - Error message
 */
export const sendServerError = (res, message = 'Lỗi server') => {
  return sendErrorResponse(res, 500, message, 'SERVER_ERROR');
};

export default {
  sendErrorResponse,
  sendUnauthorized,
  sendForbidden,
  sendBadRequest,
  sendRateLimitExceeded,
  sendServerError
};
