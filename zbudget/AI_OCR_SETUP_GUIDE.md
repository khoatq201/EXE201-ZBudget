# 🤖 **AI OCR Setup Guide**

## 🎯 **Tổng quan**

Thay thế OCR truyền thống bằng AI mạnh hơn để xử lý hóa đơn Việt Nam phức tạp.

## 🚀 **Các lựa chọn AI:**

### **1. Google Cloud Vision API** ⭐ (Khuyến nghị)

- ✅ **Hỗ trợ tiếng Việt tốt nhất**
- ✅ **OCR chính xác cao**
- ✅ **Có thể train custom model**
- ✅ **Pricing hợp lý ($1.50/1000 requests)**

### **2. OpenAI GPT-4 Vision** 🧠

- ✅ **AI mạnh nhất**
- ✅ **Hiểu context tốt**
- ✅ **Có thể parse structured data**
- ✅ **Pricing cao ($0.01/1K tokens)**

### **3. Azure Computer Vision** 💼

- ✅ **Microsoft AI mạnh**
- ✅ **Hỗ trợ đa ngôn ngữ**
- ✅ **API dễ sử dụng**
- ✅ **Pricing trung bình**

## 🔧 **Setup Google Cloud Vision API:**

### **Bước 1: Tạo Google Cloud Project**

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Enable Vision API:
   - Vào "APIs & Services" > "Library"
   - Tìm "Cloud Vision API"
   - Click "Enable"

### **Bước 2: Tạo API Key**

1. Vào "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy API key
4. (Optional) Restrict API key cho security

### **Bước 3: Setup Billing**

1. Vào "Billing" trong Google Cloud Console
2. Link credit card (có $300 free credit)
3. Set budget alerts

### **Bước 4: Test API**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {
        "image": {
          "source": {
            "imageUri": "https://example.com/image.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION"
          }
        ]
      }
    ]
  }' \
  "https://vision.googleapis.com/v1/images:annotate?key=YOUR_API_KEY"
```

## 🧠 **Setup OpenAI GPT-4 Vision:**

### **Bước 1: Tạo OpenAI Account**

1. Truy cập [OpenAI Platform](https://platform.openai.com/)
2. Đăng ký account
3. Add payment method

### **Bước 2: Tạo API Key**

1. Vào "API Keys" trong dashboard
2. Click "Create new secret key"
3. Copy API key
4. Set usage limits

### **Bước 3: Test API**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-4-vision-preview",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Analyze this image"
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,BASE64_IMAGE"
            }
          }
        ]
      }
    ]
  }' \
  "https://api.openai.com/v1/chat/completions"
```

## 💼 **Setup Azure Computer Vision:**

### **Bước 1: Tạo Azure Account**

1. Truy cập [Azure Portal](https://portal.azure.com/)
2. Tạo free account
3. Tạo resource group

### **Bước 2: Tạo Computer Vision Resource**

1. Vào "Create a resource"
2. Tìm "Computer Vision"
3. Tạo resource
4. Copy endpoint và API key

### **Bước 3: Test API**

```bash
curl -X POST \
  -H "Ocp-Apim-Subscription-Key: YOUR_API_KEY" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @image.jpg \
  "YOUR_ENDPOINT/vision/v3.2/read/analyze"
```

## 📱 **Setup trong Flutter App:**

### **Bước 1: Add Dependencies**

```yaml
dependencies:
  http: ^1.1.0
  google_mlkit_text_recognition: ^0.13.1
```

### **Bước 2: Add API Keys**

```dart
// lib/services/ai_ocr_service.dart
static const String _googleVisionApiKey = 'YOUR_GOOGLE_VISION_API_KEY';
static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY';
static const String _azureEndpoint = 'YOUR_AZURE_ENDPOINT';
static const String _azureApiKey = 'YOUR_AZURE_API_KEY';
```

### **Bước 3: Update Receipt Scanner**

```dart
// lib/widgets/receipt_scanner_widget.dart
import '../services/ai_ocr_service.dart';

// Replace OCRService with AIOCRService
final result = await AIOCRService.smartExtract(imagePath);
```

## 🎯 **Smart OCR Strategy:**

### **1. Fallback Chain:**

```
Google Vision → OpenAI → Azure → Local OCR
```

### **2. Provider Selection:**

- **Vietnamese receipts**: Google Vision (best)
- **Complex receipts**: OpenAI (smartest)
- **Simple receipts**: Azure (fastest)
- **Offline**: Local OCR (backup)

### **3. Confidence Scoring:**

- **> 0.9**: High confidence
- **0.7 - 0.9**: Medium confidence
- **< 0.7**: Low confidence (try another provider)

## 💰 **Pricing Comparison:**

| Provider      | Cost                  | Best For        |
| ------------- | --------------------- | --------------- |
| Google Vision | $1.50/1K requests     | Vietnamese text |
| OpenAI GPT-4V | $0.01/1K tokens       | Complex parsing |
| Azure OCR     | $1.00/1K transactions | General OCR     |
| Local OCR     | Free                  | Offline backup  |

## 🔒 **Security Best Practices:**

### **1. API Key Management:**

```dart
// Use environment variables
const String apiKey = String.fromEnvironment('GOOGLE_VISION_API_KEY');
```

### **2. Rate Limiting:**

```dart
// Implement rate limiting
class RateLimiter {
  static final Map<String, DateTime> _lastRequest = {};

  static bool canMakeRequest(String provider) {
    final lastRequest = _lastRequest[provider];
    if (lastRequest == null) return true;

    return DateTime.now().difference(lastRequest).inSeconds > 1;
  }
}
```

### **3. Error Handling:**

```dart
try {
  final result = await AIOCRService.smartExtract(imagePath);
  return result;
} catch (e) {
  // Fallback to local OCR
  return await OCRService.extractTextFromImage(imagePath);
}
```

## 🧪 **Testing Strategy:**

### **1. Test với hóa đơn thật:**

- Bách Hóa Xanh
- Coopmart
- Big C
- Lotte
- Vincom

### **2. Test cases:**

- Hóa đơn cong
- Hóa đơn mờ
- Hóa đơn có ngón tay che
- Hóa đơn góc nghiêng

### **3. Performance metrics:**

- Accuracy rate
- Processing time
- Cost per request
- User satisfaction

## 🚀 **Implementation Steps:**

1. **Setup Google Cloud Vision** (khuyến nghị)
2. **Test với hóa đơn thật**
3. **Implement fallback chain**
4. **Add error handling**
5. **Monitor performance**
6. **Optimize costs**

## 📊 **Expected Results:**

- ✅ **Accuracy**: 95%+ cho hóa đơn Việt Nam
- ✅ **Speed**: 2-5 giây per request
- ✅ **Cost**: $0.01-0.05 per receipt
- ✅ **User Experience**: Tự động, không cần manual input

## 🎉 **Kết luận:**

AI OCR sẽ giải quyết hoàn toàn vấn đề nhận diện hóa đơn phức tạp như Bách Hóa Xanh!
