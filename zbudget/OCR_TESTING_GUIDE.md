# 🧪 Hướng dẫn Test OCR cho Group Expense

## ✅ **Bug đã được sửa:**

### **1. Duplicate mapping key trong pubspec.yaml:**

- ❌ **Lỗi**: `camera: ^0.10.5+5` và `camera: ^0.11.0+2` duplicate
- ❌ **Lỗi**: `google_mlkit_text_recognition: ^0.10.0` và `google_mlkit_text_recognition: ^0.13.1` duplicate
- ✅ **Đã sửa**: Loại bỏ duplicate keys, giữ version mới nhất

### **2. Dependencies đã được cài đặt thành công:**

```bash
flutter pub get
# ✅ Got dependencies! (34 packages có version mới hơn)
```

---

## 🧪 **Hướng dẫn Test OCR:**

### **1. Test cơ bản:**

1. **Mở app** và đi đến màn hình Group Budget
2. **Tap "Thêm chi tiêu"**
3. **Tap nút "Quét hóa đơn"** (icon camera)
4. **Chọn ảnh** từ thư viện hoặc chụp mới
5. **Kiểm tra kết quả** OCR

### **2. Test với các loại hóa đơn:**

#### **🍽️ Hóa đơn nhà hàng:**

- **Mô tả**: "Cơm tấm bình dân"
- **Số tiền**: "45.000 ₫"
- **Danh mục**: `food` (tự động)
- **Cửa hàng**: "Quán cơm ABC"

#### **🛍️ Hóa đơn siêu thị:**

- **Mô tả**: "Big C Thăng Long"
- **Số tiền**: "125.000 VND"
- **Danh mục**: `shopping` (tự động)
- **Cửa hàng**: "Big C"

#### **⛽ Hóa đơn xăng:**

- **Mô tả**: "Xăng A95"
- **Số tiền**: "200.000 ₫"
- **Danh mục**: `transport` (tự động)
- **Cửa hàng**: "Petrolimex"

#### **💊 Hóa đơn thuốc:**

- **Mô tả**: "Thuốc cảm cúm"
- **Số tiền**: "75.000 VND"
- **Danh mục**: `healthcare` (tự động)
- **Cửa hàng**: "Nhà thuốc XYZ"

### **3. Test Edge Cases:**

#### **❌ Hóa đơn mờ/nhòe:**

- **Kết quả mong đợi**: Hiển thị lỗi "Không thể đọc được văn bản"
- **Fallback**: Cho phép chọn ảnh khác

#### **❌ Hóa đơn không có số tiền:**

- **Kết quả mong đợi**: Hiển thị lỗi "Không thể nhận diện số tiền"
- **Fallback**: Cho phép nhập thủ công

#### **✅ Hóa đơn rõ nét:**

- **Kết quả mong đợi**: Tự động điền form
- **Confidence**: >80% (màu xanh)

### **4. Test UI/UX:**

#### **📱 Scanner Interface:**

- ✅ **Camera preview** với corner guides
- ✅ **Action buttons**: "Chụp ảnh" và "Thư viện"
- ✅ **Tips section**: Hướng dẫn quét tốt
- ✅ **Error handling**: Thông báo lỗi rõ ràng

#### **👁️ Result Preview:**

- ✅ **Confidence indicator**: Hiển thị độ tin cậy
- ✅ **Editable fields**: Số tiền, mô tả, danh mục
- ✅ **Store info**: Thông tin cửa hàng
- ✅ **Items list**: Danh sách món đã mua

#### **🔄 Auto-fill Form:**

- ✅ **Description**: Tự động điền mô tả
- ✅ **Amount**: Tự động điền số tiền (format VND)
- ✅ **Category**: Tự động chọn danh mục
- ✅ **Notes**: Tự động điền tên cửa hàng

---

## 🎯 **Test Cases chi tiết:**

### **1. Test Pattern Recognition:**

#### **Số tiền (Amount):**

```dart
// Test cases
"1.000.000 ₫" → 1000000
"1,000,000 VND" → 1000000
"Total: 500.000" → 500000
"Tổng: 750.000" → 750000
"Amount: 1.250.000" → 1250000
```

#### **Danh mục (Category):**

```dart
// Test cases
"ăn", "food", "restaurant" → "food"
"xăng", "taxi", "uber" → "transport"
"shop", "siêu thị", "big c" → "shopping"
"thuốc", "pharmacy" → "healthcare"
"cinema", "movie" → "entertainment"
```

### **2. Test Performance:**

#### **⏱️ Timing:**

- **OCR Processing**: <3 giây
- **Result Preview**: <1 giây
- **Auto-fill**: <0.5 giây

#### **📱 Memory:**

- **Image Size**: <5MB (compressed)
- **OCR Memory**: <50MB
- **Total Memory**: <100MB

### **3. Test Error Handling:**

#### **🚨 Error Scenarios:**

```dart
// No text detected
"Không thể đọc được văn bản từ ảnh"

// No amount found
"Không thể nhận diện số tiền từ hóa đơn"

// Permission denied
"Cần quyền truy cập camera để chụp ảnh"

// Low confidence
"Độ tin cậy thấp - vui lòng kiểm tra lại"
```

---

## 🚀 **Cách chạy test:**

### **1. Development Testing:**

```bash
# Chạy app
flutter run

# Test trên device thật (khuyến nghị)
flutter run --release
```

### **2. Debug Testing:**

```bash
# Xem logs OCR
flutter logs

# Debug mode
flutter run --debug
```

### **3. Performance Testing:**

```bash
# Profile mode
flutter run --profile

# Release mode
flutter run --release
```

---

## 📊 **Kết quả mong đợi:**

### **✅ Success Metrics:**

- **OCR Accuracy**: >85% cho hóa đơn rõ nét
- **Processing Time**: <3 giây
- **User Satisfaction**: >4.5/5
- **Time Saving**: >70% so với nhập thủ công

### **❌ Failure Cases:**

- **Hóa đơn quá mờ**: <50% accuracy
- **Text không rõ**: Cần retry
- **Pattern không match**: Fallback manual input

---

## 🎉 **Kết luận:**

**✅ OCR functionality đã sẵn sàng test!**

- **Dependencies**: ✅ Đã cài đặt
- **Code**: ✅ Không có lỗi linting
- **UI**: ✅ Hoàn chỉnh
- **Integration**: ✅ Tích hợp thành công

**🚀 Bạn có thể bắt đầu test ngay bây giờ!** 🎯
