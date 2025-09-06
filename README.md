# ZBudget - Flutter App

Ứng dụng quản lý tài chính thông minh được xây dựng bằng Flutter, có giao diện tương tự như React Native.

## Cấu trúc Project

```
lib/
├── constants/           # Constants và theme
│   ├── colors.dart     # Màu sắc và theme colors
│   ├── spacing.dart    # Spacing constants
│   └── typography.dart # Typography styles
├── models/             # Data models
│   ├── user.dart       # User model
│   ├── expense.dart    # Expense model với categories
│   └── budget.dart     # Budget model
├── providers/          # State management
│   └── app_provider.dart # App state provider
├── services/           # Business logic services
│   └── storage_service.dart # Local storage service
├── navigation/         # Navigation
│   └── app_navigator.dart # App navigation routes
├── screens/            # UI Screens
│   ├── onboarding_screen.dart # Onboarding flow
│   ├── auth/           # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home/           # Home screens
│   │   └── dashboard_screen.dart # Main dashboard
│   ├── budget/         # Budget screens
│   │   └── budget_list_screen.dart # Budget list
│   ├── main_navigator.dart # Main app navigation
│   └── settings_screen.dart # Settings screen
└── main.dart           # App entry point
```

## Tính năng chính

### 🏠 **Dashboard**

- Hiển thị số dư hiện tại
- Thống kê chi tiêu gần đây
- Thao tác nhanh (thêm chi tiêu, thu nhập)
- Giao diện đẹp với gradient và cards

### 💰 **Quản lý Ngân sách**

- Tạo và quản lý ngân sách theo danh mục
- Theo dõi chi tiêu thực tế vs kế hoạch
- Progress bars trực quan
- Phân tích theo thời gian (tuần/tháng/quý/năm)

### 📊 **Báo cáo & Phân tích**

- Biểu đồ chi tiêu theo danh mục
- Xu hướng chi tiêu theo thời gian
- So sánh thu nhập vs chi tiêu
- Insights thông minh

### 🔐 **Xác thực & Bảo mật**

- Đăng nhập/đăng ký tài khoản
- Quản lý profile người dùng
- Cài đặt bảo mật

### 🎨 **Giao diện**

- Material Design 3
- Theme sáng/tối
- Responsive design
- Vietnamese localization

## Công nghệ sử dụng

- **Flutter**: UI framework
- **Provider**: State management
- **SharedPreferences**: Local storage
- **Material Design**: UI components
- **Custom Themes**: Light/Dark mode

## Cài đặt & Chạy

1. **Clone project**

```bash
git clone <repository-url>
cd zbudget
```

2. **Cài đặt dependencies**

```bash
flutter pub get
```

3. **Chạy app**

```bash
flutter run
```

4. **Build APK**

```bash
flutter build apk --debug
```

## Cấu trúc State Management

Project sử dụng **Provider** pattern với `AppProvider` để quản lý:

- **Authentication state**: Đăng nhập/đăng xuất
- **User data**: Thông tin người dùng
- **App settings**: Theme, language
- **Data operations**: CRUD operations cho expenses, budgets

## Models

### User

```dart
class User {
  final String id;
  final String name;
  final String email;
  final bool isPremium;
  // ... other fields
}
```

### Expense

```dart
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  // ... other fields
}
```

### Budget

```dart
class Budget {
  final String id;
  final String name;
  final double totalAmount;
  final List<BudgetCategory> categories;
  // ... other fields
}
```

## Constants

### Colors

- **Primary**: Green theme (#3DA13D)
- **Secondary**: Teal (#42C5C5)
- **Accent**: Caribbean Green (#42D8C5)
- **Supporting**: Success, Warning, Error colors

### Typography

- **H1-H6**: Heading styles
- **Body**: Body text styles
- **Button**: Button text styles
- **Caption**: Small text styles

### Spacing

- **Base unit**: 8px
- **Scale**: xs(4), sm(8), md(12), lg(16), xl(24), xl2(32), xl3(40), xl4(48), xl5(64), xl6(80)

## Screens Flow

1. **Onboarding** → Giới thiệu app
2. **Authentication** → Đăng nhập/đăng ký
3. **Main App** → Dashboard, Budget, Settings
4. **Navigation** → Bottom navigation với 3 tabs chính

## Tính năng tương lai

- [ ] AI-powered savings suggestions
- [ ] Receipt scanning (OCR)
- [ ] Group expenses & splitting
- [ ] Export reports (PDF/Excel)
- [ ] Push notifications
- [ ] Cloud sync
- [ ] Multi-currency support

## Đóng góp

1. Fork project
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## License

Project này được phát triển cho mục đích học tập và demo.

---

**ZBudget** - Quản lý tài chính thông minh cho người Việt Nam 🇻🇳
