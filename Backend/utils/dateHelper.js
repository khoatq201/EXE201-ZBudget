/**
 * Time constants in milliseconds
 */
export const TimeConstants = {
  SECOND: 1000,
  MINUTE: 60 * 1000,
  HOUR: 60 * 60 * 1000,
  DAY: 24 * 60 * 60 * 1000,
  WEEK: 7 * 24 * 60 * 60 * 1000,
};

/**
 * Add minutes to current time
 * @param {number} minutes - Number of minutes to add
 * @returns {Date} - New date object
 */
export const addMinutes = (minutes) => {
  return new Date(Date.now() + minutes * TimeConstants.MINUTE);
};

/**
 * Add hours to current time
 * @param {number} hours - Number of hours to add
 * @returns {Date} - New date object
 */
export const addHours = (hours) => {
  return new Date(Date.now() + hours * TimeConstants.HOUR);
};

/**
 * Add days to current time
 * @param {number} days - Number of days to add
 * @returns {Date} - New date object
 */
export const addDays = (days) => {
  return new Date(Date.now() + days * TimeConstants.DAY);
};

/**
 * Add weeks to current time
 * @param {number} weeks - Number of weeks to add
 * @returns {Date} - New date object
 */
export const addWeeks = (weeks) => {
  return new Date(Date.now() + weeks * TimeConstants.WEEK);
};

/**
 * Add time to a specific date
 * @param {Date} date - Base date
 * @param {number} amount - Amount to add
 * @param {string} unit - Unit: 'minutes', 'hours', 'days', 'weeks'
 * @returns {Date} - New date object
 */
export const addTime = (date, amount, unit = 'minutes') => {
  const baseTime = date ? date.getTime() : Date.now();

  const multipliers = {
    seconds: TimeConstants.SECOND,
    minutes: TimeConstants.MINUTE,
    hours: TimeConstants.HOUR,
    days: TimeConstants.DAY,
    weeks: TimeConstants.WEEK,
  };

  const multiplier = multipliers[unit] || TimeConstants.MINUTE;
  return new Date(baseTime + amount * multiplier);
};

/**
 * Get start of day
 * @param {Date} date - Date to process (default: today)
 * @returns {Date} - Start of day (00:00:00.000)
 */
export const startOfDay = (date = new Date()) => {
  const newDate = new Date(date);
  newDate.setHours(0, 0, 0, 0);
  return newDate;
};

/**
 * Get end of day
 * @param {Date} date - Date to process (default: today)
 * @returns {Date} - End of day (23:59:59.999)
 */
export const endOfDay = (date = new Date()) => {
  const newDate = new Date(date);
  newDate.setHours(23, 59, 59, 999);
  return newDate;
};

/**
 * Get start of month
 * @param {Date} date - Date to process (default: this month)
 * @returns {Date} - Start of month
 */
export const startOfMonth = (date = new Date()) => {
  return new Date(date.getFullYear(), date.getMonth(), 1, 0, 0, 0, 0);
};

/**
 * Get end of month
 * @param {Date} date - Date to process (default: this month)
 * @returns {Date} - End of month
 */
export const endOfMonth = (date = new Date()) => {
  return new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);
};

/**
 * Get date range for period
 * @param {string} period - Period: 'daily', 'weekly', 'monthly', 'yearly'
 * @param {Date} referenceDate - Reference date (default: today)
 * @returns {Object} - { startDate, endDate }
 */
export const getDateRangeForPeriod = (period = 'monthly', referenceDate = new Date()) => {
  const today = new Date(referenceDate);

  switch (period) {
    case 'daily':
      return {
        startDate: startOfDay(today),
        endDate: endOfDay(today)
      };

    case 'weekly':
      const startOfWeek = new Date(today);
      startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday
      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(startOfWeek.getDate() + 6); // Saturday
      return {
        startDate: startOfDay(startOfWeek),
        endDate: endOfDay(endOfWeek)
      };

    case 'monthly':
      return {
        startDate: startOfMonth(today),
        endDate: endOfMonth(today)
      };

    case 'yearly':
      return {
        startDate: new Date(today.getFullYear(), 0, 1, 0, 0, 0, 0),
        endDate: new Date(today.getFullYear(), 11, 31, 23, 59, 59, 999)
      };

    default:
      return {
        startDate: startOfMonth(today),
        endDate: endOfMonth(today)
      };
  }
};

/**
 * Check if date is expired
 * @param {Date} expiryDate - Expiry date to check
 * @returns {boolean} - True if expired
 */
export const isExpired = (expiryDate) => {
  if (!expiryDate) return true;
  return new Date(expiryDate) < new Date();
};

/**
 * Format date for display
 * @param {Date} date - Date to format
 * @param {string} locale - Locale (default: vi-VN)
 * @returns {string} - Formatted date string
 */
export const formatDate = (date, locale = 'vi-VN') => {
  if (!date) return '';
  return new Date(date).toLocaleDateString(locale);
};

/**
 * Format date and time for display
 * @param {Date} date - Date to format
 * @param {string} locale - Locale (default: vi-VN)
 * @returns {string} - Formatted datetime string
 */
export const formatDateTime = (date, locale = 'vi-VN') => {
  if (!date) return '';
  return new Date(date).toLocaleString(locale);
};

export default {
  TimeConstants,
  addMinutes,
  addHours,
  addDays,
  addWeeks,
  addTime,
  startOfDay,
  endOfDay,
  startOfMonth,
  endOfMonth,
  getDateRangeForPeriod,
  isExpired,
  formatDate,
  formatDateTime
};
