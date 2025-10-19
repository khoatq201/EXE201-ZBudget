# 🔐 Hướng dẫn sửa lỗi Permissions cho OCR

## 🐛 **Vấn đề đã được sửa:**

### **1. AndroidManifest.xml thiếu permissions:**

- ❌ **Lỗi**: App không có quyền truy cập camera và storage
- ✅ **Đã sửa**: Thêm đầy đủ permissions vào AndroidManifest.xml

### **2. Permission handling không đúng:**

- ❌ **Lỗi**: Không tự động hỏi quyền khi cần
- ✅ **Đã sửa**: Thêm logic xử lý permissions thông minh

---

## 📱 **Permissions đã thêm vào AndroidManifest.xml:**

```xml
<!-- Permissions for OCR and Camera -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Camera feature -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### **📋 Giải thích từng permission:**

- **`CAMERA`**: Quyền chụp ảnh
- **`READ_EXTERNAL_STORAGE`**: Đọc file từ storage (Android < 13)
- **`WRITE_EXTERNAL_STORAGE`**: Ghi file vào storage (Android < 13)
- **`READ_MEDIA_IMAGES`**: Đọc ảnh từ thư viện (Android 13+)
- **`android.hardware.camera`**: Camera hardware (không bắt buộc)
- **`android.hardware.camera.autofocus`**: Autofocus (không bắt buộc)

---

## 🔧 **Logic xử lý permissions:**

### **1. Pre-check permissions:**

```dart
Future<void> _checkPermissions() async {
  final cameraStatus = await Permission.camera.status;
  final storageStatus = await Permission.storage.status;
  final photosStatus = await Permission.photos.status;

  if (cameraStatus.isDenied || storageStatus.isDenied || photosStatus.isDenied) {
    setState(() {
      _errorMessage = 'App cần quyền truy cập camera và thư viện ảnh để quét hóa đơn';
    });
  }
}
```

### **2. Request permissions thông minh:**

```dart
Future<void> _requestPermissions() async {
  // Request camera permission
  final cameraStatus = await Permission.camera.request();

  // Request storage/photos permission based on Android version
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;

  PermissionStatus storageStatus;
  if (androidInfo.version.sdkInt >= 33) {
    // Android 13+ (API 33+)
    storageStatus = await Permission.photos.request();
  } else {
    // Android 12 and below
    storageStatus = await Permission.storage.request();
  }
}
```

### **3. Handle permission results:**

```dart
if (cameraStatus.isGranted && storageStatus.isGranted) {
  // Success - hide error message
  setState(() {
    _errorMessage = null;
  });
} else {
  // Show error message
  setState(() {
    _errorMessage = 'Vui lòng cấp quyền để sử dụng tính năng quét hóa đơn';
  });
}
```

---

## 🎯 **Cách hoạt động:**

### **1. Khi mở Scanner:**

- ✅ **Pre-check**: Kiểm tra permissions trước
- ✅ **Show UI**: Hiển thị nút "Cấp quyền" nếu cần
- ✅ **Error Message**: Thông báo rõ ràng về quyền cần thiết

### **2. Khi tap "Cấp quyền":**

- ✅ **Request Camera**: Yêu cầu quyền camera
- ✅ **Request Storage**: Yêu cầu quyền storage/photos (tùy Android version)
- ✅ **Handle Results**: Xử lý kết quả và cập nhật UI

### **3. Khi chụp/chọn ảnh:**

- ✅ **Check Again**: Kiểm tra lại permissions
- ✅ **Handle Denied**: Xử lý trường hợp bị từ chối
- ✅ **Show Settings**: Hướng dẫn mở Settings nếu cần

---

## 📱 **UI/UX Improvements:**

### **1. Error Message với nút "Cấp quyền":**

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.red),
  ),
  child: Column(
    children: [
      Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: _requestPermissions,
        icon: const Icon(Icons.security, size: 16),
        label: const Text('Cấp quyền'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    ],
  ),
)
```

### **2. Success Message:**

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Đã cấp quyền thành công!'),
    backgroundColor: Colors.green,
  ),
);
```

---

## 🧪 **Test Permissions:**

### **1. Test Camera Permission:**

- ✅ **Grant**: App có thể chụp ảnh
- ❌ **Deny**: Hiển thị error message
- 🔄 **Retry**: Tap "Cấp quyền" để thử lại

### **2. Test Storage Permission:**

- ✅ **Grant**: App có thể chọn ảnh từ thư viện
- ❌ **Deny**: Hiển thị error message
- 🔄 **Retry**: Tap "Cấp quyền" để thử lại

### **3. Test Permanently Denied:**

- ❌ **Permanently Denied**: Hướng dẫn mở Settings
- 📱 **Settings**: "Cài đặt > Ứng dụng > ZBudget > Quyền"

---

## 🚀 **Cách test:**

### **1. Clean install:**

```bash
# Uninstall app
adb uninstall com.example.zbudget

# Reinstall
flutter install
```

### **2. Test flow:**

1. **Mở app** → **Group Budget** → **Thêm chi tiêu**
2. **Tap "Quét hóa đơn"** → **Kiểm tra permissions**
3. **Nếu cần**: Tap "Cấp quyền"
4. **Test chụp ảnh** và **chọn từ thư viện**

### **3. Test edge cases:**

- **Deny permissions**: Kiểm tra error handling
- **Grant permissions**: Kiểm tra success flow
- **Permanently deny**: Kiểm tra Settings redirect

---

## ✅ **Kết quả:**

### **🎯 Permissions hoạt động đúng:**

- ✅ **AndroidManifest.xml**: Đầy đủ permissions
- ✅ **Permission handling**: Thông minh và user-friendly
- ✅ **UI/UX**: Rõ ràng và dễ hiểu
- ✅ **Error handling**: Xử lý tất cả trường hợp

### **📱 User Experience:**

- ✅ **Auto-request**: Tự động hỏi quyền khi cần
- ✅ **Clear messages**: Thông báo rõ ràng
- ✅ **Easy fix**: Nút "Cấp quyền" dễ sử dụng
- ✅ **Settings redirect**: Hướng dẫn mở Settings nếu cần

**🚀 Permissions đã được sửa hoàn toàn!** 🎉
