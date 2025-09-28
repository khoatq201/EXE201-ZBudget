# Cấu hình Google Sign-In cho Android

## Bước 1: Cấu hình Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project hiện tại hoặc tạo project mới
3. Vào **APIs & Services** > **Credentials**
4. Tạo OAuth 2.0 Client ID cho Android:
   - Application type: **Android**
   - Package name: `com.example.zbudget`
   - SHA-1 certificate fingerprint: `23:F6:8B:90:51:79:8A:D5:2A:5C:92:76:BF:68:47:3A:52:5A:43:AE`

## Bước 2: Download google-services.json

1. Trong Google Cloud Console, vào **Project Settings**
2. Chọn tab **Your apps**
3. Thêm Android app với:
   - Package name: `com.example.zbudget`
   - SHA-1: `23:F6:8B:90:51:79:8A:D5:2A:5C:92:76:BF:68:47:3A:52:5A:43:AE`
4. Download file `google-services.json`
5. Đặt file vào: `android/app/google-services.json`

## Bước 3: Cấu hình đã được cập nhật

✅ `android/app/build.gradle.kts` - Đã thêm Google Services plugin
✅ `android/build.gradle.kts` - Đã thêm Google Services classpath
✅ `lib/services/auth_service.dart` - Đã cấu hình Google Sign-In

## Bước 4: Test trên Android

```bash
# Clean và rebuild
flutter clean
flutter pub get

# Chạy trên Android device/emulator
flutter run -d <device-id>

# Hoặc build APK
flutter build apk --debug
```

## Quan trọng:

1. **Phải có file `google-services.json`** từ Google Console
2. **Package name phải khớp**: `com.example.zbudget`
3. **SHA-1 fingerprint phải chính xác**: `23:F6:8B:90:51:79:8A:D5:2A:5C:92:76:BF:68:47:3A:52:5A:43:AE`
4. **Test trên thiết bị thật** để đảm bảo Google Sign-In hoạt động

## Troubleshooting:

- Nếu gặp lỗi "Developer Error", kiểm tra lại SHA-1 và package name
- Nếu Google Sign-In không hiện, kiểm tra `google-services.json`
- Đảm bảo device có Google Play Services

## Client IDs cần thiết:

- **Web Client ID**: `996746380802-c7hh05j9jqtr2jpbidajq4g8hel30p0f.apps.googleusercontent.com` (đã có)
- **Android Client ID**: Sẽ được tạo khi thêm SHA-1 fingerprint vào Google Console
