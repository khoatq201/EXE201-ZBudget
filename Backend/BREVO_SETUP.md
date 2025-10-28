# Hướng dẫn Setup Brevo Email Service

## ✅ Đã hoàn thành

Email service đã được refactor để sử dụng Brevo API thay vì Resend.

## 📝 Environment Variables cần thiCTIONENTS

Trên Render Dashboard, thêm các biến sau vào Environment:

### **Bắt buộc:**

```bash
BREVO_API_KEY=xxxxxxxxxxxxx
```

### **Tùy chọn:**

```bash
BREVO_FROM_EMAIL=noreply@brevo.com
```

## 🚀 Cách lấy Brevo API Key

1. Đăng ký tài khoản tại: https://www.brevo.com
2. Đăng nhập vào dashboard
3. Vào **SMTP & API** → **API Keys**
4. Tạo API key mới (hoặc dùng default key)
5. Copy API key

## ✅ Brevo Free Tier Benefits

✅ **300 emails/ngày (9,000 emails/tháng)** - QUOTA CAO NHẤT!
✅ **KHÔNG GIỚI HẠN địa chỉ nhận** - Gửi đến bất kỳ email nào
✅ **KHÔNG CẦN verify domain** - Works out of the box
✅ **Free mãi mãi** - Không credit card required
✅ **API đơn giản** - Dễ integrate
✅ **Không bị Render block ports**

## 📧 Setup

### **Option 1: Dùng email mặc định (Nhanh nhất)**

- Default: `noreply@brevo.com`
- Không cần setup gì thêm
- Gửi được đến BẤT KỲ email nào

### **Option 2: Thêm domain riêng (Tùy chọn)**

1. Vào Brevo Dashboard → **Senders & IP**
2. Click "Add a sender"
3. Verify domain của bạn
4. Set `BREVO_FROM_EMAIL=noreply@yourdomain.com`

## ✅ Test Email Service

Sau khi deploy, test bằng cách:

1. Đăng ký user mới → nhận OTP email
2. Reset password → nhận OTP email
3. Check logs trên Render

## 📊 Brevo vs Resend

| Tính năng           | Brevo               | Resend               |
| ------------------- | ------------------- | -------------------- |
| Free Tier           | 300/ngày (9K/tháng) | 100/ngày (3K/tháng)  |
| Giới hạn email test | **KHÔNG**           | **CÓ** (chỉ 1 email) |
| Domain verification | **KHÔNG**           | **CÓ**               |
| Free mãi mãi        | ✅                  | ✅                   |
| Branding            | Có footer           | Không                |

## 🎉 Kết luận

**Brevo là lựa chọn tốt nhất cho ứng dụng của bạn!**

- ✅ Không giới hạn địa chỉ email nhận
- ✅ Quota cao nhất (300 emails/ngày)
- ✅ Không cần verify domain
- ✅ Works ngay lập tức
