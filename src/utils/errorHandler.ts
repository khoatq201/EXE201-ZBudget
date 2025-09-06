import { Alert } from 'react-native';

export enum ErrorType {
  NETWORK = 'NETWORK',
  STORAGE = 'STORAGE',
  VALIDATION = 'VALIDATION',
  AUTHENTICATION = 'AUTHENTICATION',
  UNKNOWN = 'UNKNOWN',
}

export interface AppError {
  type: ErrorType;
  message: string;
  originalError?: Error;
  timestamp: Date;
  userId?: string;
}

export class ErrorHandler {
  private static instance: ErrorHandler;
  private errorLogs: AppError[] = [];

  private constructor() {}

  public static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  public handleError(error: Error | AppError, context?: string): void {
    const appError = this.normalizeError(error);

    // Log error
    this.logError(appError, context);

    // Show user-friendly message
    this.showUserMessage(appError);

    // Report to crash analytics in production
    if (__DEV__) {
      console.error('Error caught:', appError);
    }
  }

  private normalizeError(error: Error | AppError): AppError {
    if (this.isAppError(error)) {
      return error;
    }

    // Convert regular Error to AppError
    let type = ErrorType.UNKNOWN;
    let message = 'Đã xảy ra lỗi không mong muốn';

    if (error.message.includes('Network')) {
      type = ErrorType.NETWORK;
      message = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
    } else if (error.message.includes('Storage') || error.message.includes('AsyncStorage')) {
      type = ErrorType.STORAGE;
      message = 'Lỗi lưu trữ dữ liệu. Vui lòng thử lại.';
    } else if (error.message.includes('validation') || error.message.includes('invalid')) {
      type = ErrorType.VALIDATION;
      message = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
    } else if (error.message.includes('auth') || error.message.includes('unauthorized')) {
      type = ErrorType.AUTHENTICATION;
      message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    return {
      type,
      message,
      originalError: error,
      timestamp: new Date(),
    };
  }

  private isAppError(error: any): error is AppError {
    return error && typeof error === 'object' && 'type' in error && 'message' in error;
  }

  private logError(error: AppError, context?: string): void {
    const logEntry = {
      ...error,
      context,
      timestamp: new Date(),
    };

    this.errorLogs.push(logEntry);

    // Keep only last 100 errors
    if (this.errorLogs.length > 100) {
      this.errorLogs = this.errorLogs.slice(-100);
    }
  }

  private showUserMessage(error: AppError): void {
    const title = this.getErrorTitle(error.type);

    Alert.alert(title, error.message, [
      { text: 'Đóng', style: 'cancel' },
      {
        text: 'Thử lại',
        onPress: () => {
          // This could trigger a retry mechanism
          console.log('User requested retry');
        },
      },
    ]);
  }

  private getErrorTitle(type: ErrorType): string {
    switch (type) {
      case ErrorType.NETWORK:
        return '🌐 Lỗi kết nối';
      case ErrorType.STORAGE:
        return '💾 Lỗi lưu trữ';
      case ErrorType.VALIDATION:
        return '⚠️ Dữ liệu không hợp lệ';
      case ErrorType.AUTHENTICATION:
        return '🔐 Lỗi xác thực';
      default:
        return '❌ Lỗi hệ thống';
    }
  }

  public getErrorLogs(): AppError[] {
    return [...this.errorLogs];
  }

  public clearErrorLogs(): void {
    this.errorLogs = [];
  }

  public createError(type: ErrorType, message: string, originalError?: Error): AppError {
    return {
      type,
      message,
      originalError,
      timestamp: new Date(),
    };
  }
}

// Utility functions for common error scenarios
export const handleAsyncError = async <T>(
  operation: () => Promise<T>,
  fallbackValue: T,
  errorMessage?: string
): Promise<T> => {
  try {
    return await operation();
  } catch (error) {
    const errorHandler = ErrorHandler.getInstance();
    const appError = errorHandler.createError(
      ErrorType.UNKNOWN,
      errorMessage || 'Thao tác thất bại',
      error as Error
    );
    errorHandler.handleError(appError);
    return fallbackValue;
  }
};

export const handleStorageError = async <T>(
  operation: () => Promise<T>,
  fallbackValue: T
): Promise<T> => {
  try {
    return await operation();
  } catch (error) {
    const errorHandler = ErrorHandler.getInstance();
    const appError = errorHandler.createError(
      ErrorType.STORAGE,
      'Lỗi truy cập dữ liệu',
      error as Error
    );
    errorHandler.handleError(appError);
    return fallbackValue;
  }
};

export const validateRequired = (value: any, fieldName: string): void => {
  if (!value || (typeof value === 'string' && value.trim() === '')) {
    const errorHandler = ErrorHandler.getInstance();
    const appError = errorHandler.createError(ErrorType.VALIDATION, `${fieldName} là bắt buộc`);
    throw appError;
  }
};

export const validateEmail = (email: string): void => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    const errorHandler = ErrorHandler.getInstance();
    const appError = errorHandler.createError(ErrorType.VALIDATION, 'Email không hợp lệ');
    throw appError;
  }
};

export const validateAmount = (amount: number): void => {
  if (amount <= 0) {
    const errorHandler = ErrorHandler.getInstance();
    const appError = errorHandler.createError(ErrorType.VALIDATION, 'Số tiền phải lớn hơn 0');
    throw appError;
  }
};

// Export singleton instance
export const errorHandler = ErrorHandler.getInstance();
