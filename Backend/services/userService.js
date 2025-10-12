import { User } from "../models/index.js";
import { NotFoundError, ForbiddenError } from "../middleware/errorHandler.js";

/**
 * User Service - Centralized user operations
 */
export class UserService {
  /**
   * Find user by ID or throw error
   * @param {string} userId - User ID
   * @param {Object} options - Options { select, checkActive, populat }
   * @returns {Promise<User>} - User document
   * @throws {NotFoundError} - If user not found
   * @throws {ForbiddenError} - If user is inactive (when checkActive=true)
   */
  static async findByIdOrFail(userId, options = {}) {
    const { select, checkActive = false, populate } = options;

    let query = User.findById(userId);

    if (select) {
      query = query.select(select);
    }

    if (populate) {
      query = query.populate(populate);
    }

    const user = await query;

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    if (checkActive && !user.isActive) {
      throw new ForbiddenError("Tài khoản đã bị vô hiệu hóa");
    }

    return user;
  }

  /**
   * Find user by email or throw error
   * @param {string} email - User email
   * @param {Object} options - Options { select, checkActive }
   * @returns {Promise<User>} - User document
   * @throws {NotFoundError} - If user not found
   * @throws {ForbiddenError} - If user is inactive (when checkActive=true)
   */
  static async findByEmailOrFail(email, options = {}) {
    const { select, checkActive = false } = options;

    let query = User.findOne({ email: email.toLowerCase() });

    if (select) {
      query = query.select(select);
    }

    const user = await query;

    if (!user) {
      throw new NotFoundError("Email không tồn tại trong hệ thống");
    }

    if (checkActive && !user.isActive) {
      throw new ForbiddenError("Tài khoản đã bị vô hiệu hóa");
    }

    return user;
  }

  /**
   * Find user by ID (nullable - does not throw)
   * @param {string} userId - User ID
   * @param {Object} options - Options { select }
   * @returns {Promise<User|null>} - User document or null
   */
  static async findById(userId, options = {}) {
    const { select } = options;

    let query = User.findById(userId);

    if (select) {
      query = query.select(select);
    }

    return await query;
  }

  /**
   * Find user by email (nullable - does not throw)
   * @param {string} email - User email
   * @param {Object} options - Options { select }
   * @returns {Promise<User|null>} - User document or null
   */
  static async findByEmail(email, options = {}) {
    const { select } = options;

    let query = User.findOne({ email: email.toLowerCase() });

    if (select) {
      query = query.select(select);
    }

    return await query;
  }

  /**
   * Check if user exists by email
   * @param {string} email - Email to check
   * @param {string} excludeUserId - User ID to exclude from check (optional)
   * @returns {Promise<boolean>} - True if user exists
   */
  static async existsByEmail(email, excludeUserId = null) {
    const query = { email: email.toLowerCase() };

    if (excludeUserId) {
      query._id = { $ne: excludeUserId };
    }

    const count = await User.countDocuments(query);
    return count > 0;
  }

  /**
   * Check if user exists by phone number
   * @param {string} phoneNumber - Phone number to check
   * @param {string} excludeUserId - User ID to exclude from check (optional)
   * @returns {Promise<boolean>} - True if user exists
   */
  static async existsByPhone(phoneNumber, excludeUserId = null) {
    const query = { 'profile.phone': phoneNumber };

    if (excludeUserId) {
      query._id = { $ne: excludeUserId };
    }

    const count = await User.countDocuments(query);
    return count > 0;
  }

  /**
   * Update user by ID
   * @param {string} userId - User ID
   * @param {Object} updateData - Data to update
   * @param {Object} options - Mongoose options
   * @returns {Promise<User>} - Updated user document
   */
  static async updateById(userId, updateData, options = {}) {
    const defaultOptions = { new: true, runValidators: false };
    const mergedOptions = { ...defaultOptions, ...options };

    const user = await User.findByIdAndUpdate(userId, updateData, mergedOptions);

    if (!user) {
      throw new NotFoundError("Không tìm thấy người dùng");
    }

    return user;
  }

  /**
   * Increment user field
   * @param {string} userId - User ID
   * @param {Object} incrementFields - Fields to increment { field: amount }
   * @returns {Promise<User>} - Updated user document
   */
  static async incrementFields(userId, incrementFields) {
    return await this.updateById(userId, {
      $inc: incrementFields
    });
  }

  /**
   * Remove sensitive fields from user object
   * @param {User} user - User document or object
   * @returns {Object} - User object without sensitive fields
   */
  static removeSensitiveFields(user) {
    const userObj = user.toObject ? user.toObject() : { ...user };

    delete userObj.passwordHash;
    delete userObj.refreshTokens;
    delete userObj.emailVerificationToken;
    delete userObj.emailVerificationOTP;
    delete userObj.passwordResetToken;
    delete userObj.passwordResetOTP;
    delete userObj.loginAttempts;
    delete userObj.lockUntil;

    return userObj;
  }
}

export default UserService;
