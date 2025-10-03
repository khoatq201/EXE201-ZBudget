# Date Formatting Guide for ZBudget

## 📅 Overview

This guide explains the standardized approach to date formatting across the ZBudget application. **All financial features (Expense, Income, Budget, Reports, Group Budget) must use the `DateFormatter` utility class** to ensure consistency and avoid timezone issues.

## 🎯 Why Standardization Matters

### The Timezone Problem

When dealing with dates between frontend (Flutter) and backend (Node.js + MongoDB), timezone conversion can cause **date shifting issues**:

**Example Problem:**
- User selects: **October 4, 2025** at 9:30 PM (21:30 local time in Vietnam, UTC+7)
- Flutter sends: `2025-10-04T21:30:00.000` (without timezone indicator)
- Backend interprets as UTC: `2025-10-04T21:30:00.000Z`
- MongoDB stores: `2025-10-04T14:30:00.000Z` (UTC, which is 9:30 PM in Vietnam minus 7 hours)
- **Result**: Date shows as **October 3** instead of October 4 ❌

### The Solution: Date-Only Format

By using `YYYY-MM-DD` format (e.g., `2025-10-04`), we ensure:
- Backend interprets the date **without time component**
- No timezone conversion occurs
- Date integrity is maintained across client and server
- User sees the **exact date they selected** ✅

## 🛠️ How to Use DateFormatter

### Import the Utility

```dart
import '../utils/date_formatter.dart';
```

### Basic Usage

#### 1. Sending Dates to API

**✅ CORRECT:**
```dart
// When creating/updating expense, income, budget, etc.
final body = {
  'date': DateFormatter.toApiFormat(selectedDate),
  // ... other fields
};
```

**❌ WRONG:**
```dart
// Don't use these:
'date': selectedDate.toIso8601String(),  // ❌ Causes timezone issues
'date': selectedDate.toString(),          // ❌ Wrong format
'date': '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}', // ❌ Not zero-padded
```

#### 2. Parsing Dates from API Response

```dart
// Backend returns: "2025-10-04T14:30:00.000Z" or "2025-10-04"
final date = DateFormatter.parseApiDate(responseJson['date']);

// With null safety
final date = DateFormatter.parseApiDateNullable(responseJson['date']);
```

#### 3. Displaying Dates to Users

```dart
// Full date format: "4 Thg 10, 2025"
final displayDate = DateFormatter.toDisplayFormat(date);

// Short format: "04/10/2025"
final shortDate = DateFormatter.toShortDisplay(date);

// With time: "04/10/2025 21:30"
final dateTime = DateFormatter.toDisplayWithTime(date);

// Month/Year: "Thg 10, 2025"
final monthYear = DateFormatter.toMonthYearDisplay(date);

// Relative: "Hôm nay", "Hôm qua", or "04/10/2025"
final relativeDate = DateFormatter.toRelativeDisplay(date);
```

#### 4. Date Range Formatting

```dart
// Format date range for budget periods, reports, etc.
final range = DateFormatter.formatDateRange(startDate, endDate);
// Output: "1 - 31 Thg 10, 2025" (same month)
// Output: "01/10/2025 - 30/11/2025" (different months)
```

#### 5. Date Calculations

```dart
// Get start/end of periods
final startOfDay = DateFormatter.startOfDay(date);
final endOfDay = DateFormatter.endOfDay(date);
final startOfMonth = DateFormatter.startOfMonth(date);
final endOfMonth = DateFormatter.endOfMonth(date);
final startOfYear = DateFormatter.startOfYear(date);
final endOfYear = DateFormatter.endOfYear(date);

// Date comparisons
final isSame = DateFormatter.isSameDay(date1, date2);
final isToday = DateFormatter.isToday(date);
final isYesterday = DateFormatter.isYesterday(date);

// Date arithmetic
final daysDiff = DateFormatter.daysBetween(startDate, endDate);
final daysInMonth = DateFormatter.daysInMonth(2025, 10);
```

## 📋 Implementation Checklist

When implementing any feature that involves dates:

- [ ] Import `DateFormatter` utility
- [ ] Use `DateFormatter.toApiFormat()` for all API requests
- [ ] Use `DateFormatter.parseApiDate()` for API responses
- [ ] Use appropriate display methods for UI
- [ ] Test with different timezones (especially UTC+7 Vietnam)
- [ ] Verify dates don't shift by ±1 day

## 🔍 Where to Apply

### Current Features (Already Implemented)
- ✅ Expense Service (`expense_service.dart`)
- ✅ Income Service (`income_service.dart`)
- ✅ Dashboard Service (`dashboard_service.dart`)

### Features to Update
- [ ] Budget Service - `startDate`, `endDate`, `createdAt`
- [ ] Group Budget Service - All date fields
- [ ] Reports Service - Date range filters
- [ ] Savings Goals Service - Target dates
- [ ] Challenge Service - Start/end dates
- [ ] Recurring Transactions - Next occurrence dates

## 🧪 Testing Date Formatting

### Manual Testing

1. **Create Transaction on Current Date**
   - Select today's date
   - Create expense/income
   - Verify it shows as **today**, not yesterday

2. **Create Transaction on Future Date**
   - Select tomorrow's date
   - Create expense/income
   - Verify it shows as **tomorrow**, not today

3. **Budget Period Boundaries**
   - Create monthly budget for current month
   - Create expense on first day
   - Create expense on last day
   - Verify both are **within budget period**

4. **Timezone Edge Cases**
   - Test at 11:59 PM (23:59) local time
   - Test at 12:00 AM (00:00) local time
   - Verify dates don't shift

### Automated Testing

```dart
void main() {
  group('DateFormatter', () {
    test('toApiFormat returns YYYY-MM-DD', () {
      final date = DateTime(2025, 10, 4);
      expect(DateFormatter.toApiFormat(date), '2025-10-04');
    });

    test('toApiFormat pads single digits', () {
      final date = DateTime(2025, 1, 5);
      expect(DateFormatter.toApiFormat(date), '2025-01-05');
    });

    test('parseApiDate handles ISO format', () {
      final date = DateFormatter.parseApiDate('2025-10-04T14:30:00.000Z');
      expect(date.year, 2025);
      expect(date.month, 10);
      expect(date.day, 4);
    });

    test('parseApiDate handles date-only format', () {
      final date = DateFormatter.parseApiDate('2025-10-04');
      expect(date.year, 2025);
      expect(date.month, 10);
      expect(date.day, 4);
    });
  });
}
```

## 🚨 Common Pitfalls

### ❌ Don't Do This

```dart
// 1. Don't use toIso8601String() for dates
body['date'] = date.toIso8601String();

// 2. Don't manually format dates
body['startDate'] = '${start.year}-${start.month}-${start.day}';

// 3. Don't use toString()
body['date'] = date.toString();

// 4. Don't mix formats
body['date'] = DateFormatter.toApiFormat(date);
body['endDate'] = endDate.toIso8601String(); // ❌ Inconsistent!
```

### ✅ Do This Instead

```dart
// Always use DateFormatter consistently
body['date'] = DateFormatter.toApiFormat(date);
body['startDate'] = DateFormatter.toApiFormat(startDate);
body['endDate'] = DateFormatter.toApiFormat(endDate);
```

## 📚 API Contract

### Frontend to Backend

**Format**: `YYYY-MM-DD` (date only, no time)

**Examples**:
- `2025-10-04`
- `2025-01-15`
- `2025-12-31`

### Backend to Frontend

**Format**: ISO 8601 with UTC timezone

**Examples**:
- `2025-10-04T14:30:00.000Z`
- `2025-01-15T08:45:30.123Z`

**Note**: Frontend should parse these using `DateFormatter.parseApiDate()`, which handles both formats.

## 🔗 Related Files

- **Utility**: `zbudget/lib/utils/date_formatter.dart`
- **Implementation Examples**:
  - `zbudget/lib/services/expense_service.dart`
  - `zbudget/lib/services/income_service.dart`
  - `zbudget/lib/services/dashboard_service.dart`
- **Backend Validation**: `Backend/middleware/validation.js`

## 📞 Support

If you encounter date-related issues:

1. Check if `DateFormatter.toApiFormat()` is being used
2. Verify backend logs to see the exact date string received
3. Test with different timezones using device settings
4. Review this guide for correct usage patterns

---

**Last Updated**: October 4, 2025
**Maintained By**: ZBudget Development Team
