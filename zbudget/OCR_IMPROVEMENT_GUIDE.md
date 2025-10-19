# 🚀 Hướng dẫn cải thiện OCR cho hóa đơn

## 📋 **Tổng quan**

OCR (Optical Character Recognition) đã được cải thiện để xử lý tốt hơn các hóa đơn Việt Nam, đặc biệt là hóa đơn Bách Hóa Xanh.

## 🔧 **Cải thiện đã thực hiện:**

### **1. Image Preprocessing Service**

- **Grayscale conversion**: Chuyển ảnh sang đen trắng để tăng độ tương phản
- **Contrast enhancement**: Tăng độ tương phản để text rõ ràng hơn
- **Noise reduction**: Giảm nhiễu trong ảnh
- **Sharpening**: Làm sắc nét text

### **2. Enhanced OCR Service**

- **Preprocessing check**: Tự động kiểm tra chất lượng ảnh
- **Smart preprocessing**: Chỉ xử lý ảnh khi cần thiết
- **Better text cleaning**: Cải thiện việc làm sạch text

### **3. Improved Receipt Parser**

- **Vietnamese patterns**: Thêm patterns cho hóa đơn Việt Nam
- **Bách Hóa Xanh specific**: Patterns đặc biệt cho Bách Hóa Xanh
- **Store recognition**: Nhận diện tên cửa hàng tốt hơn

## 📱 **Cách sử dụng:**

### **1. Chụp ảnh tốt hơn:**

- ✅ **Đặt hóa đơn phẳng**, không cong
- ✅ **Chụp thẳng góc**, không nghiêng
- ✅ **Đảm bảo ánh sáng đủ**, không bị che khuất
- ✅ **Giữ ổn định**, tránh bị mờ

### **2. Tips cho hóa đơn Bách Hóa Xanh:**

- ✅ **Tránh che QR code** bằng ngón tay
- ✅ **Chụp toàn bộ hóa đơn** trong khung hình
- ✅ **Đảm bảo text rõ ràng** không bị mờ

## 🎯 **Patterns được cải thiện:**

### **Amount Extraction:**

```dart
// Patterns mới cho Bách Hóa Xanh
'Phải thanh toán: 40.100'
'Tiền chuyển khoản: 40.100'
'Total: 1.000.000'
'Amount: 1.000.000'
```

### **Store Recognition:**

```dart
// Stores được nhận diện
'BÁCH HÓA XANH'
'COOPMART'
'BIG C'
'LOTTE'
'VINCOM'
'AEON'
```

## 🔍 **Debugging OCR:**

### **1. Kiểm tra chất lượng ảnh:**

```dart
final qualityScore = await ImagePreprocessingService.getImageQualityScore(imagePath);
print('Image quality: ${(qualityScore * 100).toStringAsFixed(1)}%');
```

### **2. Kiểm tra preprocessing:**

```dart
final needsPreprocessing = await ImagePreprocessingService.needsPreprocessing(imagePath);
print('Needs preprocessing: $needsPreprocessing');
```

### **3. Kiểm tra confidence:**

```dart
final result = await OCRService.extractTextWithConfidence(imagePath);
print('OCR confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
```

## 🚨 **Troubleshooting:**

### **1. OCR không nhận diện được:**

- ✅ Kiểm tra chất lượng ảnh
- ✅ Thử chụp lại với góc tốt hơn
- ✅ Đảm bảo ánh sáng đủ

### **2. Amount không đúng:**

- ✅ Kiểm tra patterns trong receipt parser
- ✅ Thêm patterns mới nếu cần
- ✅ Debug với confidence score

### **3. Store name không đúng:**

- ✅ Kiểm tra store keywords
- ✅ Thêm store mới vào danh sách
- ✅ Debug với raw OCR text

## 📊 **Performance:**

### **Image Quality Score:**

- **> 0.8**: Excellent (không cần preprocessing)
- **0.6 - 0.8**: Good (có thể cần preprocessing)
- **< 0.6**: Poor (cần preprocessing)

### **OCR Confidence:**

- **> 0.8**: High confidence
- **0.5 - 0.8**: Medium confidence
- **< 0.5**: Low confidence

## 🔄 **Workflow:**

1. **User chụp/chọn ảnh**
2. **Check image quality**
3. **Preprocess nếu cần**
4. **OCR với Google ML Kit**
5. **Parse receipt data**
6. **Show preview cho user**
7. **User confirm/edit**
8. **Save expense**

## 📝 **Notes:**

- **Preprocessing** chỉ chạy khi cần thiết để tối ưu performance
- **Confidence score** giúp đánh giá độ tin cậy của OCR
- **Patterns** có thể được mở rộng cho các loại hóa đơn khác
- **Store recognition** có thể được cải thiện thêm

## 🎉 **Kết quả:**

- ✅ **Tăng độ chính xác** OCR cho hóa đơn Việt Nam
- ✅ **Xử lý tốt hơn** các trường hợp khó như hóa đơn cong, mờ
- ✅ **User experience** tốt hơn với tips chụp ảnh
- ✅ **Performance** tối ưu với smart preprocessing
