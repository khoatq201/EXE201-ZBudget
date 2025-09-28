import { AccessibilityInfo } from 'react-native';

export interface AccessibilityProps {
  accessibilityLabel?: string;
  accessibilityHint?: string;
  accessibilityRole?:
    | 'button'
    | 'text'
    | 'image'
    | 'header'
    | 'link'
    | 'menu'
    | 'menuitem'
    | 'summary'
    | 'switch'
    | 'tab'
    | 'tablist'
    | 'timer'
    | 'toolbar'
    | 'none';
  accessible?: boolean;
  accessibilityState?: {
    disabled?: boolean;
    selected?: boolean;
    checked?: boolean | 'mixed';
    busy?: boolean;
    expanded?: boolean;
  };
  accessibilityValue?: {
    min?: number;
    max?: number;
    now?: number;
    text?: string;
  };
}

export class AccessibilityHelper {
  private static instance: AccessibilityHelper;
  private isScreenReaderEnabled: boolean = false;
  private announceTimer: NodeJS.Timeout | null = null;

  private constructor() {
    this.initializeAccessibility();
  }

  public static getInstance(): AccessibilityHelper {
    if (!AccessibilityHelper.instance) {
      AccessibilityHelper.instance = new AccessibilityHelper();
    }
    return AccessibilityHelper.instance;
  }

  private async initializeAccessibility(): Promise<void> {
    try {
      this.isScreenReaderEnabled = await AccessibilityInfo.isScreenReaderEnabled();

      // Listen for screen reader state changes
      AccessibilityInfo.addEventListener('screenReaderChanged', (enabled: boolean) => {
        this.isScreenReaderEnabled = enabled;
      });
    } catch (error) {
      console.error('Error initializing accessibility:', error);
    }
  }

  public getScreenReaderStatus(): boolean {
    return this.isScreenReaderEnabled;
  }

  public announce(message: string, priority: 'polite' | 'assertive' = 'polite'): void {
    if (this.announceTimer) {
      clearTimeout(this.announceTimer);
    }

    this.announceTimer = setTimeout(
      () => {
        AccessibilityInfo.announceForAccessibility(message);
      },
      priority === 'assertive' ? 0 : 100
    );
  }

  public createButtonProps(label: string, hint?: string, disabled?: boolean): AccessibilityProps {
    return {
      accessibilityLabel: label,
      accessibilityHint: hint,
      accessibilityRole: 'button',
      accessible: true,
      accessibilityState: {
        disabled: disabled || false,
      },
    };
  }

  public createTextProps(text: string, isHeading?: boolean): AccessibilityProps {
    return {
      accessibilityLabel: text,
      accessibilityRole: isHeading ? 'header' : 'text',
      accessible: true,
    };
  }

  public createProgressProps(
    current: number,
    total: number,
    description?: string
  ): AccessibilityProps {
    return {
      accessibilityLabel: description || 'Progress',
      accessibilityRole: 'none',
      accessible: true,
      accessibilityValue: {
        min: 0,
        max: total,
        now: current,
        text: `${current} của ${total}`,
      },
    };
  }

  public createFormFieldProps(
    label: string,
    value: string,
    placeholder?: string,
    error?: string
  ): AccessibilityProps {
    let hint = placeholder;
    if (error) {
      hint = error;
    }

    return {
      accessibilityLabel: label,
      accessibilityHint: hint,
      accessibilityRole: 'none',
      accessible: true,
      accessibilityValue: {
        text: value || placeholder || '',
      },
    };
  }

  public createSwitchProps(label: string, isEnabled: boolean, hint?: string): AccessibilityProps {
    return {
      accessibilityLabel: label,
      accessibilityHint: hint,
      accessibilityRole: 'switch',
      accessible: true,
      accessibilityState: {
        checked: isEnabled,
      },
    };
  }

  public createTabProps(label: string, isSelected: boolean, hint?: string): AccessibilityProps {
    return {
      accessibilityLabel: label,
      accessibilityHint: hint,
      accessibilityRole: 'tab',
      accessible: true,
      accessibilityState: {
        selected: isSelected,
      },
    };
  }

  public createMenuItemProps(label: string, hint?: string, disabled?: boolean): AccessibilityProps {
    return {
      accessibilityLabel: label,
      accessibilityHint: hint,
      accessibilityRole: 'menuitem',
      accessible: true,
      accessibilityState: {
        disabled: disabled || false,
      },
    };
  }

  public createImageProps(description: string, decorative?: boolean): AccessibilityProps {
    if (decorative) {
      return {
        accessible: false,
      };
    }

    return {
      accessibilityLabel: description,
      accessibilityRole: 'image',
      accessible: true,
    };
  }

  public createListItemProps(
    label: string,
    position?: { current: number; total: number },
    hint?: string
  ): AccessibilityProps {
    let accessibilityLabel = label;
    if (position) {
      accessibilityLabel = `${label}, ${position.current} của ${position.total}`;
    }

    return {
      accessibilityLabel,
      accessibilityHint: hint,
      accessibilityRole: 'none',
      accessible: true,
    };
  }

  public formatCurrency(amount: number, currency: string = 'VND'): string {
    const formatted = new Intl.NumberFormat('vi-VN').format(amount);
    return `${formatted} ${currency}`;
  }

  public formatDate(date: Date): string {
    return new Intl.DateTimeFormat('vi-VN', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(date);
  }

  public formatPercentage(value: number): string {
    return `${value.toFixed(1)} phần trăm`;
  }

  public createScreenTitle(title: string): string {
    return `Màn hình ${title}`;
  }

  public createNavigationHint(destination: string): string {
    return `Chuyển đến ${destination}`;
  }

  public createActionHint(action: string): string {
    return `Nhấn để ${action}`;
  }

  public createLoadingMessage(context?: string): string {
    return context ? `Đang tải ${context}...` : 'Đang tải...';
  }

  public createErrorMessage(error: string): string {
    return `Lỗi: ${error}`;
  }

  public createSuccessMessage(message: string): string {
    return `Thành công: ${message}`;
  }

  public createConfirmationMessage(action: string): string {
    return `Bạn có chắc chắn muốn ${action}?`;
  }

  public createValidationMessage(field: string, error: string): string {
    return `${field}: ${error}`;
  }

  public createListHeader(title: string, count: number): string {
    return `${title}, ${count} mục`;
  }

  public createEmptyStateMessage(context: string): string {
    return `Không có ${context} nào`;
  }

  public createFilterMessage(filter: string, count: number): string {
    return `Lọc theo ${filter}, ${count} kết quả`;
  }

  public createSortMessage(sortBy: string, order: 'asc' | 'desc'): string {
    const orderText = order === 'asc' ? 'tăng dần' : 'giảm dần';
    return `Sắp xếp theo ${sortBy}, ${orderText}`;
  }

  public createPaginationMessage(current: number, total: number): string {
    return `Trang ${current} của ${total}`;
  }

  public createModalTitle(title: string): string {
    return `Hộp thoại ${title}`;
  }

  public createCloseButtonLabel(context?: string): string {
    return context ? `Đóng ${context}` : 'Đóng';
  }

  public createEditButtonLabel(item: string): string {
    return `Chỉnh sửa ${item}`;
  }

  public createDeleteButtonLabel(item: string): string {
    return `Xóa ${item}`;
  }

  public createAddButtonLabel(item: string): string {
    return `Thêm ${item}`;
  }

  public createViewButtonLabel(item: string): string {
    return `Xem ${item}`;
  }

  public createShareButtonLabel(item: string): string {
    return `Chia sẻ ${item}`;
  }

  public createSaveButtonLabel(): string {
    return 'Lưu';
  }

  public createCancelButtonLabel(): string {
    return 'Hủy';
  }

  public createBackButtonLabel(): string {
    return 'Quay lại';
  }

  public createMenuButtonLabel(): string {
    return 'Mở menu';
  }

  public createSearchButtonLabel(): string {
    return 'Tìm kiếm';
  }

  public createRefreshButtonLabel(): string {
    return 'Làm mới';
  }

  public createSettingsButtonLabel(): string {
    return 'Cài đặt';
  }

  public createHelpButtonLabel(): string {
    return 'Trợ giúp';
  }

  public createProfileButtonLabel(): string {
    return 'Hồ sơ';
  }

  public createLogoutButtonLabel(): string {
    return 'Đăng xuất';
  }

  public createLoginButtonLabel(): string {
    return 'Đăng nhập';
  }

  public createSignUpButtonLabel(): string {
    return 'Đăng ký';
  }

  public createForgotPasswordButtonLabel(): string {
    return 'Quên mật khẩu';
  }

  public createShowPasswordButtonLabel(): string {
    return 'Hiện mật khẩu';
  }

  public createHidePasswordButtonLabel(): string {
    return 'Ẩn mật khẩu';
  }
}

// Export singleton instance
export const accessibilityHelper = AccessibilityHelper.getInstance();

// Common accessibility constants
export const ACCESSIBILITY_LABELS = {
  BACK_BUTTON: 'Quay lại',
  CLOSE_BUTTON: 'Đóng',
  MENU_BUTTON: 'Mở menu',
  SEARCH_BUTTON: 'Tìm kiếm',
  SAVE_BUTTON: 'Lưu',
  CANCEL_BUTTON: 'Hủy',
  EDIT_BUTTON: 'Chỉnh sửa',
  DELETE_BUTTON: 'Xóa',
  ADD_BUTTON: 'Thêm',
  REFRESH_BUTTON: 'Làm mới',
  LOADING: 'Đang tải',
  ERROR: 'Lỗi',
  SUCCESS: 'Thành công',
  WARNING: 'Cảnh báo',
  INFO: 'Thông tin',
} as const;

export const ACCESSIBILITY_HINTS = {
  TAP_TO_OPEN: 'Nhấn để mở',
  TAP_TO_CLOSE: 'Nhấn để đóng',
  TAP_TO_EDIT: 'Nhấn để chỉnh sửa',
  TAP_TO_DELETE: 'Nhấn để xóa',
  TAP_TO_ADD: 'Nhấn để thêm',
  TAP_TO_SAVE: 'Nhấn để lưu',
  TAP_TO_CANCEL: 'Nhấn để hủy',
  TAP_TO_SEARCH: 'Nhấn để tìm kiếm',
  TAP_TO_NAVIGATE: 'Nhấn để điều hướng',
  SWIPE_TO_REFRESH: 'Vuốt để làm mới',
  DOUBLE_TAP_TO_LIKE: 'Nhấn đúp để thích',
  LONG_PRESS_FOR_OPTIONS: 'Nhấn giữ để xem tùy chọn',
} as const;
