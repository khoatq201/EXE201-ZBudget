# Currency Formatting Guide for ZBudget

## 💰 Overview

This guide explains the standardized approach to currency formatting across the ZBudget application. **All financial displays (Expense, Income, Budget, Reports, Dashboard) must use the `CurrencyFormatter` utility class** to ensure consistency and proper localization.

## 🎯 Why Standardization Matters

### Consistency Problems Without Standards

- Different screens show amounts differently
- Some use "VND", others use "₫"
- Inconsistent thousand separators (1,000,000 vs 1.000.000)
- No standard for positive/negative amounts
- Hard to maintain and update formatting rules

### The Solution: CurrencyFormatter

A single source of truth for all currency formatting needs:
- ✅ Consistent formatting across the entire app
- ✅ Support for multiple currencies (VND, USD, EUR)
- ✅ Localized number formatting
- ✅ Easy to use extension methods
- ✅ Type-safe API

## 🛠️ How to Use CurrencyFormatter

### Import the Utility

```dart
import '../utils/currency_formatter.dart';
```

### Basic Usage

#### 1. Displaying Amounts

**VND (Vietnamese Dong) - Default:**
```dart
// Method 1: Using formatter
final formatted = CurrencyFormatter.format(1000000);
// Output: "1.000.000 ₫"

// Method 2: Using extension
final formatted = 1000000.0.toVND();
// Output: "1.000.000 ₫"

// Method 3: Explicit VND
final formatted = CurrencyFormatter.formatVND(1000000);
// Output: "1.000.000 ₫"
```

**USD (US Dollars):**
```dart
// Method 1: Using formatter
final formatted = CurrencyFormatter.formatUSD(1000.50);
// Output: "$1,000.50"

// Method 2: Using extension
final formatted = 1000.50.toUSD();
// Output: "$1,000.50"
```

**EUR (Euros):**
```dart
// Method 1: Using formatter
final formatted = CurrencyFormatter.formatEUR(1000.50);
// Output: "1.000,50 €"

// Method 2: Using extension
final formatted = 1000.50.toEUR();
// Output: "1.000,50 €"
```

**Dynamic Currency:**
```dart
// From API response with currency field
final currency = responseJson['currency']; // 'VND', 'USD', 'EUR'
final amount = responseJson['amount'];
final formatted = CurrencyFormatter.formatWithCurrency(amount, currency);

// Using extension
final formatted = amount.toCurrency(currency);
```

#### 2. Compact Format (for Charts & Cards)

```dart
// Large numbers in compact form
final compact = CurrencyFormatter.formatCompact(1500000);
// Output: "1.5M ₫"

final compact = CurrencyFormatter.formatCompact(750000);
// Output: "750K ₫"

final compact = CurrencyFormatter.formatCompact(1500000000);
// Output: "1.5B ₫"

// Using extension
final compact = 1500000.0.toCompact();
// Output: "1.5M ₫"
```

#### 3. Income vs Expense Display

```dart
// Income (positive, green)
final income = CurrencyFormatter.formatIncome(1000000);
// Output: "+1.000.000 ₫"

// Expense (negative, red)
final expense = CurrencyFormatter.formatExpense(500000);
// Output: "-500.000 ₫"

// Generic with sign
final result = CurrencyFormatter.formatWithSign(1000000);
// Output: {'text': '+1.000.000 ₫', 'isPositive': true}

// Example usage in UI:
Text(
  result['text'],
  style: TextStyle(
    color: result['isPositive'] ? Colors.green : Colors.red,
  ),
)
```

#### 4. Budget Display

```dart
// Simple ratio
final ratio = CurrencyFormatter.formatRatio(750000, 1000000);
// Output: "750.000 / 1.000.000 ₫"

// Budget with percentage
final budget = CurrencyFormatter.formatBudget(750000, 1000000);
// Output: "750.000 / 1.000.000 ₫ (75%)"

// Remaining budget with color coding
final remaining = CurrencyFormatter.formatRemaining(750000, 1000000);
// Output: {'text': '250.000 ₫', 'isOverBudget': false}

// Over budget
final remaining = CurrencyFormatter.formatRemaining(1200000, 1000000);
// Output: {'text': '200.000 ₫', 'isOverBudget': true}
```

#### 5. Input Fields

```dart
// Format user input (as they type)
TextFormField(
  onChanged: (value) {
    final formatted = CurrencyFormatter.formatInput(value);
    // Auto-format with thousand separators
  },
  keyboardType: TextInputType.number,
)

// Without currency symbol
final formatted = CurrencyFormatter.formatWithoutSymbol(1000000);
// Output: "1.000.000"
```

#### 6. Parsing User Input

```dart
// Parse formatted string back to number
final amount = CurrencyFormatter.parse("1.000.000 ₫");
// Output: 1000000.0

final amount = CurrencyFormatter.parse("\$1,000.50");
// Output: 1000.50

final amount = CurrencyFormatter.parse("1.000,50 €");
// Output: 1000.50
```

#### 7. Validation

```dart
// Check if string is valid currency
final isValid = CurrencyFormatter.isValid("1.000.000");
// Output: true

final isValid = CurrencyFormatter.isValid("abc");
// Output: false

// Check if over budget
final isOver = CurrencyFormatter.isOverBudget(1200000, 1000000);
// Output: true
```

#### 8. API Communication

```dart
// Sending to API (already a number, no formatting needed)
body['amount'] = amount; // Just pass the double value

// Receiving from API
final amount = CurrencyFormatter.fromApiFormat(responseJson['amount']);
// Handles: double, int, String, null
```

## 📋 Implementation Examples

### Dashboard Summary Card

```dart
class DashboardSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Total Balance
          Text('Số dư', style: TextStyle(fontSize: 14)),
          Text(
            balance.toVND(), // Using extension
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Income (green)
          Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.green),
              Text(
                CurrencyFormatter.formatIncome(income),
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),

          // Expense (red)
          Row(
            children: [
              Icon(Icons.arrow_downward, color: Colors.red),
              Text(
                CurrencyFormatter.formatExpense(expense),
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Budget Progress Bar

```dart
class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final percentage = (spent / limit * 100).clamp(0, 100);
    final remaining = CurrencyFormatter.formatRemaining(spent, limit);
    final isOver = remaining['isOverBudget'];

    return Column(
      children: [
        // Budget ratio
        Text(CurrencyFormatter.formatBudget(spent, limit)),

        // Progress bar
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(
            isOver ? Colors.red : Colors.green,
          ),
        ),

        // Remaining amount
        Text(
          'Còn lại: ${remaining['text']}',
          style: TextStyle(
            color: isOver ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
}
```

### Transaction List Item

```dart
class TransactionListItem extends StatelessWidget {
  final String title;
  final double amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final formatted = isIncome
        ? CurrencyFormatter.formatIncome(amount)
        : CurrencyFormatter.formatExpense(amount);

    return ListTile(
      title: Text(title),
      trailing: Text(
        formatted,
        style: TextStyle(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

### Expense Input Form

```dart
class ExpenseInputForm extends StatefulWidget {
  @override
  _ExpenseInputFormState createState() => _ExpenseInputFormState();
}

class _ExpenseInputFormState extends State<ExpenseInputForm> {
  final _amountController = TextEditingController();
  double _amount = 0;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Số tiền',
        suffixText: '₫',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // Format as user types
        final formatted = CurrencyFormatter.formatInput(value);
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );

        // Parse to actual number
        _amount = CurrencyFormatter.parse(formatted);
      },
      validator: (value) {
        if (!CurrencyFormatter.isValid(value ?? '')) {
          return 'Số tiền không hợp lệ';
        }
        return null;
      },
    );
  }
}
```

### Chart Labels

```dart
class ExpenseChart extends StatelessWidget {
  final List<ChartData> data;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      // ... chart configuration
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) {
            // Use compact format for Y-axis labels
            return CurrencyFormatter.formatCompact(value);
          },
        ),
      ),
    );
  }
}
```

## 🧪 Testing Currency Formatting

### Unit Tests

```dart
void main() {
  group('CurrencyFormatter', () {
    test('formats VND correctly', () {
      expect(CurrencyFormatter.formatVND(1000000), '1.000.000 ₫');
      expect(CurrencyFormatter.formatVND(500), '500 ₫');
    });

    test('formats USD correctly', () {
      expect(CurrencyFormatter.formatUSD(1000.50), '\$1,000.50');
      expect(CurrencyFormatter.formatUSD(0.99), '\$0.99');
    });

    test('formats compact correctly', () {
      expect(CurrencyFormatter.formatCompact(1500000), '1.5M ₫');
      expect(CurrencyFormatter.formatCompact(750000), '750K ₫');
      expect(CurrencyFormatter.formatCompact(1500), '1.500 ₫');
    });

    test('parses currency strings correctly', () {
      expect(CurrencyFormatter.parse('1.000.000 ₫'), 1000000.0);
      expect(CurrencyFormatter.parse('\$1,000.50'), 1000.50);
      expect(CurrencyFormatter.parse('1.000,50 €'), 1000.50);
    });

    test('formats income and expense correctly', () {
      expect(CurrencyFormatter.formatIncome(1000000), '+1.000.000 ₫');
      expect(CurrencyFormatter.formatExpense(500000), '-500.000 ₫');
    });

    test('calculates budget remaining correctly', () {
      final result = CurrencyFormatter.formatRemaining(750000, 1000000);
      expect(result['text'], '250.000 ₫');
      expect(result['isOverBudget'], false);

      final overBudget = CurrencyFormatter.formatRemaining(1200000, 1000000);
      expect(overBudget['isOverBudget'], true);
    });
  });
}
```

## 🚨 Common Patterns & Best Practices

### ✅ Do This

```dart
// 1. Use extension methods for simple cases
Text(amount.toVND())

// 2. Use formatters for complex cases
Text(CurrencyFormatter.formatBudget(spent, limit))

// 3. Use formatWithCurrency for dynamic currency
Text(amount.toCurrency(currency))

// 4. Use formatIncome/formatExpense for transactions
Text(
  transaction.isIncome
    ? CurrencyFormatter.formatIncome(transaction.amount)
    : CurrencyFormatter.formatExpense(transaction.amount)
)

// 5. Use compact format for charts and small spaces
Text(amount.toCompact())
```

### ❌ Don't Do This

```dart
// 1. Don't manually format currency
Text('${amount.toStringAsFixed(0)} ₫') // ❌

// 2. Don't use inconsistent symbols
Text('VND $amount') // ❌
Text('$amount đ') // ❌

// 3. Don't forget thousand separators
Text('${amount.round()} ₫') // ❌ Shows "1000000 ₫" instead of "1.000.000 ₫"

// 4. Don't mix formats
Text('${amount.toVND()}') // VND on one screen
Text('${amount.toStringAsFixed(2)}') // Raw number on another ❌
```

## 📊 Currency Format Reference

| Currency | Format | Example Input | Example Output |
|----------|--------|---------------|----------------|
| VND | `#,##0 ₫` | 1000000 | 1.000.000 ₫ |
| USD | `$#,##0.00` | 1000.50 | $1,000.50 |
| EUR | `#,##0.00 €` | 1000.50 | 1.000,50 € |
| Compact | `#.#M/K/B` | 1500000 | 1.5M ₫ |

## 🔗 Related Files

- **Utility**: `zbudget/lib/utils/currency_formatter.dart`
- **Date Utility**: `zbudget/lib/utils/date_formatter.dart`
- **Implementation Examples**:
  - Dashboard: `zbudget/lib/screens/home/dashboard_screen_api.dart`
  - Budget: `zbudget/lib/screens/budget/`
  - Expense: `zbudget/lib/services/expense_service.dart`

## 📞 Support

If you encounter currency formatting issues:

1. Check if `CurrencyFormatter` is being used
2. Verify the correct method is chosen for your use case
3. Test with different amounts (small, large, negative)
4. Check for proper localization (VN vs US formatting)

---

**Last Updated**: October 4, 2025
**Maintained By**: ZBudget Development Team
