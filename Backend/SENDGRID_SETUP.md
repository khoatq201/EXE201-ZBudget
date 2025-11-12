# Hướng dẫn Setup SendGrid Email Service

## ✅ Đã hoàn thành

Email service đã được refactor để sử dụng SendGrid API.

## 📝 Environment Variables

Trên Render Dashboard, thêm các biến sau vào Environment:

### **Bắt buộc:**

```bash
SENDGRID_API_KEY=SG.xxxxxxxxxxxxx
```

### **Tùy chọn:**

```bash
SENDGRID_FROM_EMAIL=your-verified-email@yourdomain.com
```

## 🚀 Cách lấy SendGrid API Key

1. Đăng ký tài khoản tại: https://sendgrid.com
2. Đăng nhập vào dashboard
3. Vào **Settings** → **API Keys**
4. Click **"Create API Key"**
5. Chọn **"Full Access"** hoặc **"Restricted Access"** (chỉ cần Mail Send permission)
6. Copy API key (bắt đầu bằng `SG.`)

## ⚠️ Lưu ý về Sender Verification

SendGrid **yêu cầu verify sender email** trước khi gửi. Có 2 cách:

### **Option 1: Single Sender Verification (Khuyến nghị - FREE)**

1. Vào **Settings** → **Sender Authentication** → **Single Sender Verification**
2. Click **"Create New Sender"**
3. Điền thông tin:
   - From Email: `your-email@example.com` (email cá nhân của bạn)
   - From Name: `ZBudget`
   - Reply To: `noreply@yourdomain.com`
4. Verify email qua email confirmation
5. Sau khi verify thành công, set `SENDGRID_FROM_EMAIL=your-verified-email@example.com`

**Ưu điểm:**

- ✅ FREE
- ✅ Không cần domain
- ✅ 100 emails/ngày
- ✅ Gửi được đến bất kỳ email nào

### **Option 2: Domain Authentication (Professional)**

1. Vào **Settings** → **Sender Authentication** → **Domain Authentication**
2. Click **"Authenticate Your Domain"**
3. Chọn DNS provider của bạn
4. Add DNS records theo hướng dẫn
5. Verify domain (wait 24-48h)
6. Set `SENDGRID_FROM_EMAIL=noreply@yourdomain.com`

## ✅ SendGrid Free Tier Benefits

- ✅ **100 emails/ngày** (3,000 emails/tháng)
- ✅ **FREE mãi mãi**
- ✅ **Không giới hạn địa chỉ nhận**
- ✅ **High deliverability**
- ✅ **Analytics & tracking**
- ⚠️ **Cần verify sender** (dễ dàng với Single Sender)

## 📊 So sánh services

| Service  | Free Limit | Domain Required     | Recommend             |
| -------- | ---------- | ------------------- | --------------------- |
| SendGrid | 100/ngày   | Sender verification | ✅                    |
| Brevo    | 300/ngày   | Không               | ❌ (lỗi 403)          |
| Resend   | 3K/tháng   | Có                  | ❌ (limit test email) |

## ✅ Test Email Service

Sau khi deploy, test bằng cách:

1. Đăng ký user mới → nhận OTP email
2. Reset password → nhận OTP email
3. Check logs trên Render

## 🎯 Kết luận

**SendGrid là lựa chọn tốt nhất!**

- ✅ Easy sender verification
- ✅ Reliable & professional
- ✅ Free tier đủ dùng
- ✅ Works perfectly với Render
