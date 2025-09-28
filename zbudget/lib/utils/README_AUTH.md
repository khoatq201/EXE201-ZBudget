# ZBudget Authentication System

## Overview

Enhanced authentication system với route guards, API interceptors và protected routes.

## Architecture

### Core Components

- **AuthGuard**: Route protection utility
- **AuthInterceptor**: API authentication handling
- **ProtectedRoute**: Widget-level protection
- **RouteGuards**: Configuration management

### Files Structure

```
lib/
├── utils/
│   ├── auth_guard.dart          # Route protection logic
│   ├── auth_interceptor.dart    # API authentication
│   └── auth_helper.dart         # Helper utilities
├── widgets/
│   └── protected_route.dart     # Protected route widgets
└── config/
    └── route_guards.dart        # Route configuration
```

## Usage

### 1. Route Protection (Automatic)

Routes are automatically protected via `app_router.dart`:

```dart
GoRoute(
  path: '/home',
  builder: (context, state) => NewDashboardScreen(),
  redirect: AuthGuard.checkAuthentication, // ✅ Auto-protection
),
```

### 2. API Calls with Authentication

```dart
// Instead of manual http calls
final response = await AuthInterceptor.authenticatedGet(
  'https://api.example.com/data',
  context.read<AuthService>(),
);
```

### 3. Widget-Level Protection

```dart
// Wrap sensitive widgets
ProtectedRoute(
  child: SensitiveDataWidget(),
  redirectTo: '/login',
)

// Conditional rendering
AuthCheck(
  authenticatedChild: UserMenu(),
  unauthenticatedChild: LoginButton(),
)
```

### 4. Authentication Helpers

```dart
// Quick checks
if (AuthHelper.isAuthenticated(context)) {
  // User is logged in
}

// Safe operations
await AuthHelper.safeLogout(context);
```

## Features

### ✅ Implemented

- **Route Guards**: Automatic redirect for unauthenticated users
- **API Interceptors**: Automatic token injection
- **Token Management**: Access/refresh token handling
- **401 Handling**: Automatic logout on token expiry
- **Deep Link Protection**: URLs require authentication
- **Loading States**: Loading indicators during auth checks

### 🔄 Enhanced

- **Debugging**: Comprehensive logging for auth flow
- **Error Handling**: Graceful error recovery
- **Performance**: Minimal impact on existing code
- **Flexibility**: Multiple protection levels

## Configuration

### Protected Routes

See `AuthGuard.protectedRoutes` for complete list:

- `/home`, `/budget`, `/groups`, `/challenges`, `/reports`
- `/settings`, `/profile`, `/add-expense`, etc.

### Public Routes

See `AuthGuard.publicRoutes` for complete list:

- `/`, `/login`, `/signup`, `/verify-otp`, `/forgot-password`

## Security

### Protection Levels

1. **Level 1**: InitializationWrapper (existing)
2. **Level 2**: Route Guards (new)
3. **Level 3**: Widget Protection (optional)
4. **Level 4**: API Authentication (automatic)

### Benefits

- **Defense in Depth**: Multiple protection layers
- **Automatic**: No manual checks required
- **Consistent**: Same protection across all routes
- **Maintainable**: Centralized configuration

## Backward Compatibility

### ✅ Preserved

- All existing authentication flows work unchanged
- InitializationWrapper continues to function
- No breaking changes to existing code
- Existing services remain untouched

### ➕ Enhanced

- Additional protection for direct URL access
- Better API authentication handling
- Improved user experience with loading states
- Enhanced debugging capabilities

## Troubleshooting

### Common Issues

1. **Import Errors**: Make sure all imports are correct
2. **Context Issues**: Use within Provider scope
3. **Route Conflicts**: Check route configuration

### Debug Mode

Enable detailed logging by checking console for:

- `🔐 AuthGuard:` messages
- `🌐 AuthInterceptor:` messages
- `🛣️ ROUTE ACCESS:` messages

## Future Enhancements

- Role-based access control
- Permission system
- Advanced session management
- Biometric authentication
- Multi-factor authentication

## Testing

Run authentication tests:

```bash
flutter test test/auth/
```

## Integration

This system integrates seamlessly with existing:

- AppProvider authentication state
- AuthService JWT handling
- InitializationWrapper flow
- GoRouter navigation

All enhancements are additive and non-breaking.
