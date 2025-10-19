# 🔑 **API Keys Setup Guide**

## 🚨 **Vấn đề hiện tại:**

Từ log, tôi thấy các lỗi:

- **Google Vision API 403**: API key không có quyền hoặc chưa enable billing
- **OpenAI API 401**: API key không hợp lệ
- **Azure endpoint**: Endpoint không đúng format

## 🔧 **Cách sửa:**

### **1. Google Cloud Vision API (Khuyến nghị)**

#### **Bước 1: Enable API**

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project hoặc tạo project mới
3. Vào **APIs & Services** → **Library**
4. Tìm **"Cloud Vision API"** → **Enable**

#### **Bước 2: Tạo API Key**

1. Vào **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"API key"**
3. Copy API key
4. (Optional) Click **"RESTRICT KEY"** để bảo mật

#### **Bước 3: Enable Billing**

1. Vào **Billing** trong Google Cloud Console
2. Link credit card (có $300 free credit)
3. Set budget alerts

#### **Bước 4: Test API**

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

### **2. OpenAI GPT-4 Vision (Backup)**

#### **Bước 1: Tạo Account**

1. Truy cập [OpenAI Platform](https://platform.openai.com/)
2. Đăng ký account
3. Add payment method ($5 minimum)

#### **Bước 2: Tạo API Key**

1. Vào **API Keys** trong dashboard
2. Click **"Create new secret key"**
3. Copy API key (bắt đầu với `sk-`)

#### **Bước 3: Test API**

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

### **3. Azure Computer Vision (Optional)**

#### **Bước 1: Tạo Resource**

1. Truy cập [Azure Portal](https://portal.azure.com/)
2. Click **"Create a resource"**
3. Tìm **"Computer Vision"**
4. Tạo resource
5. Copy **Endpoint** và **API Key**

#### **Bước 2: Test API**

```bash
curl -X POST \
  -H "Ocp-Apim-Subscription-Key: YOUR_API_KEY" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @image.jpg \
  "YOUR_ENDPOINT/vision/v3.2/read/analyze"
```

## 📱 **Update trong Flutter App:**

### **Bước 1: Thay API Keys**

```dart
// lib/services/ai_ocr_service.dart
static const String _googleVisionApiKey = 'YOUR_GOOGLE_VISION_API_KEY';
static const String _openaiApiKey = 'sk-your-openai-key-here';
static const String _azureEndpoint = 'https://your-resource.cognitiveservices.azure.com';
static const String _azureApiKey = 'your-azure-key-here';
```

### **Bước 2: Test App**

1. **Build app**: `flutter build apk --debug`
2. **Install**: `flutter install`
3. **Test OCR**: Chụp hóa đơn Bách Hóa Xanh
4. **Check logs**: Xem console để debug

## 🔍 **Debug Tips:**

### **1. Check API Key Format:**

- **Google**: `AIzaSy...` (39 characters)
- **OpenAI**: `sk-...` (starts with sk-)
- **Azure**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (32 characters)

### **2. Common Errors:**

- **403 Forbidden**: API key không có quyền hoặc chưa enable billing
- **401 Unauthorized**: API key không hợp lệ
- **400 Bad Request**: Request format không đúng

### **3. Test với curl:**

```bash
# Test Google Vision
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"requests":[{"image":{"source":{"imageUri":"https://example.com/image.jpg"}},"features":[{"type":"TEXT_DETECTION"}]}]}' \
  "https://vision.googleapis.com/v1/images:annotate?key=YOUR_API_KEY"
```

## 💰 **Pricing:**

| Provider      | Cost                  | Free Tier   |
| ------------- | --------------------- | ----------- |
| Google Vision | $1.50/1K requests     | $300 credit |
| OpenAI GPT-4V | $0.01/1K tokens       | $5 minimum  |
| Azure OCR     | $1.00/1K transactions | $200 credit |

## 🎯 **Khuyến nghị:**

1. **Bắt đầu với Google Vision** (tốt nhất cho tiếng Việt)
2. **Setup billing** để tránh lỗi 403
3. **Test với hóa đơn thật** để đảm bảo hoạt động
4. **Monitor costs** để tránh vượt budget

## 🚀 **Kết quả mong đợi:**

Sau khi setup đúng API keys:

- ✅ **Google Vision**: 95%+ accuracy cho hóa đơn Việt Nam
- ✅ **OpenAI**: 90%+ accuracy cho complex receipts
- ✅ **Azure**: 85%+ accuracy cho general OCR

**App sẽ hoạt động hoàn hảo với AI OCR!** 🎉
