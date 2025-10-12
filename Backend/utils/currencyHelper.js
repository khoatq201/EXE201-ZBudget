import mongoose from 'mongoose';

/**
 * Convert Mongoose Decimal128 to JavaScript Number
 * @param {mongoose.Types.Decimal128} decimal128Value - Decimal128 value from MongoDB
 * @returns {number} - JavaScript number
 */
export const toNumber = (decimal128Value) => {
  if (!decimal128Value) return 0;
  if (typeof decimal128Value === 'number') return decimal128Value;
  if (decimal128Value.toString) {
    return parseFloat(decimal128Value.toString());
  }
  return 0;
};

/**
 * Convert JavaScript Number to Mongoose Decimal128
 * @param {number|string} numberValue - Number or string to convert
 * @returns {mongoose.Types.Decimal128} - Decimal128 value for MongoDB
 */
export const toDecimal128 = (numberValue) => {
  if (!numberValue && numberValue !== 0) return mongoose.Types.Decimal128.fromString('0');
  return mongoose.Types.Decimal128.fromString(numberValue.toString());
};

/**
 * Format currency amount for display
 * @param {number|mongoose.Types.Decimal128} amount - Amount to format
 * @param {string} currency - Currency code (default: VND)
 * @param {string} locale - Locale for formatting (default: vi-VN)
 * @returns {string} - Formatted currency string
 */
export const formatCurrency = (amount, currency = 'VND', locale = 'vi-VN') => {
  const num = typeof amount === 'object' ? toNumber(amount) : amount;

  if (currency === 'VND') {
    // Vietnamese Dong - no decimals
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: 'VND',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(num);
  }

  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: currency
  }).format(num);
};

/**
 * Safely add two Decimal128 values
 * @param {mongoose.Types.Decimal128} a - First value
 * @param {mongoose.Types.Decimal128} b - Second value
 * @returns {number} - Sum as JavaScript number
 */
export const addDecimal128 = (a, b) => {
  return toNumber(a) + toNumber(b);
};

/**
 * Safely subtract two Decimal128 values
 * @param {mongoose.Types.Decimal128} a - First value
 * @param {mongoose.Types.Decimal128} b - Second value
 * @returns {number} - Difference as JavaScript number
 */
export const subtractDecimal128 = (a, b) => {
  return toNumber(a) - toNumber(b);
};

/**
 * Calculate percentage
 * @param {number|mongoose.Types.Decimal128} part - Part value
 * @param {number|mongoose.Types.Decimal128} total - Total value
 * @returns {number} - Percentage (0-100)
 */
export const calculatePercentage = (part, total) => {
  const partNum = typeof part === 'object' ? toNumber(part) : part;
  const totalNum = typeof total === 'object' ? toNumber(total) : total;

  if (totalNum === 0) return 0;
  return (partNum / totalNum) * 100;
};

/**
 * Check if amount is valid (non-negative)
 * @param {number|mongoose.Types.Decimal128} amount - Amount to validate
 * @returns {boolean} - True if valid
 */
export const isValidAmount = (amount) => {
  const num = typeof amount === 'object' ? toNumber(amount) : amount;
  return num >= 0 && !isNaN(num) && isFinite(num);
};

export default {
  toNumber,
  toDecimal128,
  formatCurrency,
  addDecimal128,
  subtractDecimal128,
  calculatePercentage,
  isValidAmount
};
