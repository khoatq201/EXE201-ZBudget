# Mapping AppColors -> Theme Extensions

## File cần update:

1. `signup_screen.dart` ✅ (đã thêm import theme_extensions)
2. `login_screen.dart`
3. `forgot_password_screen.dart`
4. `reset_password_screen.dart`
5. `password_reset_otp_screen.dart`
6. `otp_verification_screen.dart`
7. `complete_profile_screen.dart`

## Mapping:

- `AppColors.backgroundPrimary` → `context.screenBackground`
- `AppColors.textPrimary` → `context.primaryTextColor`
- `AppColors.textSecondary` → `context.secondaryTextColor`
- `AppColors.textTertiary` → `context.tertiaryTextColor`
- `AppColors.backgroundSecondary` → `context.cardBackground`
- `AppColors.primary500` → `context.colorScheme.primary`
- `AppColors.error` → `context.errorColor`
- `AppColors.success` → `context.colorScheme.primary`

## Steps:

1. Import `'../../utils/theme_extensions.dart'`
2. Replace all AppColors usages
3. Test dark/light theme
