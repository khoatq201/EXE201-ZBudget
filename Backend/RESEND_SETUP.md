# Hướng dẫn Setup Resend Email Service

## ✅ Đã hoàn thành

Email service đã được refactor để sử dụng Resend API thay vì Gmail SMTP.

## 📝 Environment Variables cần thiết

Trên Render Dashboard, thêm các biến sau vào Environment:

### **Bắt buộc:**

```bash
RESEND_API_KEY=re_xxxxxxxxxxxxx
```

### **Tùy chọn (khuyến nghị):**

```bash
RESEND_FROM_EMAIL=ZBudget <noreply@yourdomain.com>
```

## 🚀 Cách lấy Resend API Key

1. Đăng ký tài khoản tại: https://resend.com
2. Đăng nhập vào dashboard
3. Vào **API Keys** section
4. Tạo API key mới (hoặc dùng default key)
5. Copy API key

## 📧 Setup Domain (Tùy chọn)

### **Option 1: Dùng domain tạm (Nhanh)**

- Default: `onboarding@resend.dev`
- Không cần setup gì thêm
- ⚠️ Email đi từ Resend domain (không professional lắm)

### **Option 2: Thêm domain riêng (Professional)**

1. Vào Resend Dashboard → Domains
2. Click "Add Domain"
3. Thêm domain của bạn (ví dụ: `yourdomain.com`)
4. Follow hướng dẫn để add DNS records:
   - SPF record
   - DKIM records
   - DMARC record
5. Wait for verification (usually 24-48h)
6. Set `RESEND_FROM_EMAIL` = `ZBudget <noreply@yourdomain.com>`

## ✅ Test Email Service

Sau khi deploy, test bằng cách:

1. Đăng ký user mới → sẽ nhận OTP email
2. Reset password → sẽ nhận OTP email
3. Check logs trên Render để xem email được gửi thành công

## 📊 Benefits so với Gmail SMTP

✅ **Không bị block bởi cloud providers**
✅ **API đơn giản, không cần config phức tạp**
✅ **Free tier: 3,000 emails/month**
✅ **Deliverability cao hơn**
✅ **Webhooks & analytics tích hợp sẵn**
✅ **Rate limit tốt hơn Gmail**

## 🔄 Rollback (nếu cần)

Nếu muốn quay lại Gmail SMTP:

1. Revert file `Backend/services/emailService.js` về version cũ
2. Set lại `EMAIL_USER` và `EMAIL_PASS`
3. Uninstall Resend: `npm uninstall resend`
