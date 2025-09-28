/**
 * Utility functions for formatting data
 */

/**
 * Format currency amount to Vietnamese format
 * @param amount - The amount to format
 * @param currency - Currency symbol (default: VND)
 * @param showSymbol - Whether to show currency symbol
 * @returns Formatted currency string
 */
export const formatCurrency = (
  amount: number | string,
  currency: string = 'VND',
  showSymbol: boolean = true
): string => {
  const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;

  if (isNaN(numAmount)) {
    return '0 VND';
  }

  const formatted = new Intl.NumberFormat('vi-VN', {
    style: 'decimal',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(numAmount);

  return showSymbol ? `${formatted} ${currency}` : formatted;
};

/**
 * Format currency for display with short notation
 * @param amount - The amount to format
 * @returns Formatted currency string with K/M notation
 */
export const formatCurrencyShort = (amount: number): string => {
  if (amount >= 1000000) {
    return `${(amount / 1000000).toFixed(1)}M VND`;
  } else if (amount >= 1000) {
    return `${(amount / 1000).toFixed(0)}K VND`;
  } else {
    return formatCurrency(amount);
  }
};

/**
 * Format percentage with Vietnamese locale
 * @param value - The percentage value (0-100)
 * @param decimals - Number of decimal places
 * @returns Formatted percentage string
 */
export const formatPercentage = (value: number, decimals: number = 1): string => {
  return `${value.toFixed(decimals)}%`;
};

/**
 * Format date to Vietnamese format
 * @param date - The date to format
 * @param format - Format type ('short' | 'long' | 'time')
 * @returns Formatted date string
 */
export const formatDate = (
  date: Date | string,
  format: 'short' | 'long' | 'time' = 'short'
): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date;

  if (isNaN(dateObj.getTime())) {
    return '';
  }

  const options: Intl.DateTimeFormatOptions = {
    timeZone: 'Asia/Ho_Chi_Minh',
  };

  switch (format) {
    case 'short':
      options.day = '2-digit';
      options.month = '2-digit';
      options.year = 'numeric';
      break;
    case 'long':
      options.weekday = 'long';
      options.day = 'numeric';
      options.month = 'long';
      options.year = 'numeric';
      break;
    case 'time':
      options.hour = '2-digit';
      options.minute = '2-digit';
      options.day = '2-digit';
      options.month = '2-digit';
      break;
  }

  return new Intl.DateTimeFormat('vi-VN', options).format(dateObj);
};

/**
 * Format number with Vietnamese locale
 * @param value - The number to format
 * @param decimals - Number of decimal places
 * @returns Formatted number string
 */
export const formatNumber = (value: number, decimals: number = 0): string => {
  return new Intl.NumberFormat('vi-VN', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);
};

/**
 * Parse Vietnamese formatted currency string to number
 * @param currencyString - The currency string to parse
 * @returns Parsed number value
 */
export const parseCurrency = (currencyString: string): number => {
  const cleaned = currencyString.replace(/[^\d]/g, '');
  return parseInt(cleaned, 10) || 0;
};
