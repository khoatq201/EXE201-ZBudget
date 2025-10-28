# Cách Fix Lỗi 403 với Brevo

## 🔍 Nguyên nhân lỗi 403

Lỗi `403 Forbidden` từ Brevo thường do:

1. **API Key không hợp lệ** hoặc sai format
2. **Email sender chưa được verify** trong Brevo dashboard
3. **Tài khoản chưa được activated** đầy đủ
4. **IP chưa được whitelist** (nếu có)

## ✅ Cách Fix

### **Bước 1: Verify Sender Email**

1. Login vào Brevo dashboard: https://app.brevo.com
2. Vào **Senders & IP** → **Senders**
3. Click **"Add a sender"**
4. Thêm email: `noreply@brevo.com` (hoặc email khác)
5. Verify email qua email confirmation
6. Đợi approval (thường instant)

### **Bước 2: Check API Key Format**

API key phải có format như sau:

```
xkeysib-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxx
```

### **Bước 3: Test API Key**

Có thể test API key bằng curl:

```bash
curl -X POST "https://api.brevo.com/v3/smtp/email" \
  -H "api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "sender": {"name": "Test", "email": "verified-sender@brevo.com"},
    "to": [{"email": "your-email@example.com"}],
    "subject": "Test",
    "htmlContent": "<p>Test email</p>"
  }'
```

### **Bước 4: Check Brevo Account Status**

Đảm bảo tài khoản Brevo đã:

- ✅ Verified email
- ✅ Verified phone number (nếu required)
- ✅ Completed onboarding

## { ## Hướng dẫn Debug

Code đã thêm logging chi tiết:

- ✅ Check API key exists
- ✅ Log from/to emails
- ✅ Log error response details

Xem logs trên Render để debug:

```
🔍 Brevo API Key exists: true
🔍 Sending email to: user@example.com
🔍 From: noreply@brevo.com
⚠️ Email send error: Request failed with status code 403
Error status: 403
Error body: {...}
```

## 🎯 Quick Fix

**Option 1: Verify default sender** (Khuyến nghị)

- Dùng email đã được verify trong Brevo
- Set `BREVO_FROM_EMAIL=your-verified-email@brevo.com`

**Option 2: Add sender**

- Vào Brevo Dashboard → Senders
- Add email `noreply@brevo.com`
- Verify email này
- Dùng email này trong `BREVO_FROM_EMAIL`

## 📞 Nếu vẫn lỗi

Liên hệ Brevo Support:

- Email: support@brevo.com
- Hoặc chat trong Brevo dashboard
