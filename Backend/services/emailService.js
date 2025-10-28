import nodemailer from "nodemailer";
// Tạo transporter với cấu hình cho Gmail trên Render
const createTransporter = () => {
  // Try port 465 first (SSL), fallback to 587 (TLS) if needed
  // Many cloud providers block port 587
  const useSSL = process.env.EMAIL_USE_SSL !== "false"; // Default to SSL

  return nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: useSSL ? 465 : 587,
    secure: useSSL, // true for 465, false for 587
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS, // Sử dụng App Password
    },
    // Thêm timeout và security options cho Render
    connectionTimeout: 60000, // 60s timeout
    greetingTimeout: 30000, // 30s greeting timeout
    socketTimeout: 60000, // ützen socket timeout
    requireTLS: !useSSL, // Only require TLS for non-SSL connections
    tls: {
      rejectUnauthorized: false, // Cho phép self-signed certificates
      ciphers: "SSLv3",
    },
    debug: false, // Set true để debug
    logger: false, // Set true để log
  });
};
// Email templates
const emailTemplates = {
  verification: (name, token) => ({
    subject: "Xác thực tài khoản ZBudget",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">ZBudget</h1>
          <p style="color: white; margin: 5px 0 0 0;">Quản lý tài chính thông minh</p>
        </div>
        <div style="padding: 30px; background-color: #f8f9fa;">
          <h2 style="color: #333; margin-bottom: 20px;">Chào mừng ${name}!</h2>
          <p style="color: #555; line-height: 1.6; margin-bottom: 25px;">
            Cảm ơn bạn đã đăng ký tài khoản ZBudget. Để hoàn tất quá trình đăng ký,
            vui lòng xác thực địa chỉ email của bạn bằng cách nhấp vào nút bên dưới:
          </p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/verify-email/${token}"
               style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                      padding: 12px 30px;
                      text-decoration: none;
                      border-radius: 6px;
                      display: inline-block;
                      font-weight: bold;">
              Xác thực email
            </a>
          </div>
          <p style="color: #666; font-size: 14px; line-height: 1.6;">
            Nếu bạn không thể nhấp vào nút trên, hãy sao chép và dán liên kết sau vào trình duyệt:
          </p>
          <p style="background-color: #e9ecef; padding: 10px; border-radius: 4px; word-break: break-all; font-size: 14px;">
            ${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/verify-email/${token}
          </p>
          <div style="border-top: 1px solid #dee2e6; margin-top: 30px; padding-top: 20px;">
            <p style="color: #666; font-size: 14px; margin-bottom: 10px;">
              <strong>Lưu ý:</strong> Liên kết này sẽ hết hạn sau 24 giờ.
            </p>
            <p style="color: #666; font-size: 14px;">
              Nếu bạn không tạo tài khoản này, vui lòng bỏ qua email này.
            </p>
          </div>
        </div>
        <div style="background-color: #343a40; padding: 20px; text-align: center;">
          <p style="color: #adb5bd; margin: 0; font-size: 14px;">
            © 2024 ZBudget. Tất cả quyền được bảo lưu.
          </p>
        </div>
      </div>
    `,
  }),
  passwordReset: (name, token) => ({
    subject: "Đặt lại mật khẩu ZBudget",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">ZBudget</h1>
          <p style="color: white; margin: 5px 0 0 0;">Đặt lại mật khẩu</p>
        </div>
        <div style="padding: 30px; background-color: #f8f9fa;">
          <h2 style="color: #333; margin-bottom: 20px;">Xin chào ${name},</h2>
          <p style="color: #555; line-height: 1.6; margin-bottom: 25px;">
            Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản ZBudget của bạn.
            Nhấp vào nút bên dưới để tạo mật khẩu mới:
          </p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/reset-password/${token}"
               style="background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
                      color: white;
                      padding: 12px 30px;
                      text-decoration: none;
                      border-radius: 6px;
                      display: inline-block;
                      font-weight: bold;">
              Đặt lại mật khẩu
            </a>
          </div>
          <p style="color: #666; font-size: 14px; line-height: 1.6;">
            Hoặc sao chép và dán liên kết sau vào trình duyệt:
          </p>
          <p style="background-color: #e9ecef; padding: 10px; border-radius: 4px; word-break: break-all; font-size: 14px;">
            ${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/reset-password/${token}
          </p>
          <div style="border-top: 1px solid #dee2e6; margin-top: 30px; padding-top: 20px;">
            <p style="color: #dc3545; font-size: 14px; margin-bottom: 10px;">
              <strong>Quan trọng:</strong> Liên kết này chỉ có hiệu lực trong 10 phút.
            </p>
            <p style="color: #666; font-size: 14px;">
              Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
              Mật khẩu của bạn sẽ không thay đổi.
            </p>
          </div>
        </div>
        <div style="background-color: #343a40; padding: 20px; text-align: center;">
          <p style="color: #adb5bd; margin: 0; font-size: 14px;">
            © 2024 ZBudget. Email này được gửi tự động, vui lòng không trả lời.
          </p>
        </div>
      </div>
    `,
  }),
  welcome: (name) => ({
    subject: "Chào mừng đến với ZBudget!",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">🎉 Chào mừng đến với ZBudget!</h1>
        </div>
        <div style="padding: 30px; background-color: #f8f9fa;">
          <h2 style="color: #333; margin-bottom: 20px;">Xin chào ${name}!</h2>
          <p style="color: #555; line-height: 1.6; margin-bottom: 25px;">
            Chúc mừng bạn đã xác thực email thành công! Tài khoản ZBudget của bạn đã sẵn sàng để sử dụng.
          </p>
          <div style="background-color: white; border-left: 4px solid #667eea; padding: 20px; margin: 25px 0;">
            <h3 style="color: #333; margin-top: 0;">Bắt đầu với ZBudget:</h3>
            <ul style="color: #555; line-height: 1.8;">
              <li>📊 Theo dõi chi tiêu hàng ngày</li>
              <li>💰 Tạo ngân sách và mục tiêu tiết kiệm</li>
              <li>🎯 Tham gia các thử thách tài chính</li>
              <li>👥 Quản lý chi tiêu nhóm</li>
              <li>📱 Sử dụng trên mọi thiết bị</li>
            </ul>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/dashboard"
               style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                      padding: 12px 30px;
                      text-decoration: none;
                      border-radius: 6px;
                      display: inline-block;
                      font-weight: bold;">
              Bắt đầu ngay
            </a>
          </div>
          <div style="border-top: 1px solid #dee2e6; margin-top: 30px; padding-top: 20px;">
            <p style="color: #666; font-size: 14px;">
              Cần hỗ trợ? Liên hệ chúng tôi qua email:
              <a href="mailto:support@zbudget.com" style="color: #667eea;">support@zbudget.com</a>
            </p>
          </div>
        </div>
        <div style="background-color: #343a40; padding: 20px; text-align: center;">
          <p style="color: #adb5bd; margin: 0; font-size: 14px;">
            © 2024 ZBudget. Cảm ơn bạn đã tin tưởng sử dụng dịch vụ của chúng tôi.
          </p>
        </div>
      </div>
    `,
  }),
  budgetAlert: (name, budgetName, spent, total, percentage) => ({
    subject: `🚨 Cảnh báo ngân sách: ${budgetName}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #ffa500 0%, #ff6347 100%); padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">⚠️ Cảnh báo ngân sách</h1>
        </div>
        <div style="padding: 30px; background-color: #f8f9fa;">
          <h2 style="color: #333; margin-bottom: 20px;">Xin chào ${name},</h2>
          <p style="color: #555; line-height: 1.6; margin-bottom: 25px;">
            Ngân sách "<strong>${budgetName}</strong>" của bạn đã sử dụng <strong>${percentage}%</strong>
            so với mục tiêu đã đề ra.
          </p>
          <div style="background-color: white; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; margin: 25px 0;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
              <span style="color: #666;">Đã chi tiêu:</span>
              <span style="color: #dc3545; font-weight: bold; font-size: 18px;">${spent.toLocaleString(
                "vi-VN"
              )} ₫</span>
            </div>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
              <span style="color: #666;">Tổng ngân sách:</span>
              <span style="color: #333; font-weight: bold; font-size: 18px;">${total.toLocaleString(
                "vi-VN"
              )} ₫</span>
            </div>
            <div style="background-color: #e9ecef; border-radius: 10px; height: 20px; margin: 15px 0;">
              <div style="background: linear-gradient(90deg, #ffa500 0%, #ff6347 100%);
                          height: 20px;
                          border-radius: 10px;
                          width: ${percentage}%;
                          transition: width 0.3s ease;"></div>
            </div>
            <p style="text-align: center; color: #666; margin: 0; font-size: 14px;">
              ${percentage}% đã sử dụng
            </p>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${
              process.env.FRONTEND_URL || "http://localhost:3000"
            }/budgets"
               style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                      padding: 12px 30px;
                      text-decoration: none;
                      border-radius: 6px;
                      display: inline-block;
                      font-weight: bold;">
              Xem chi tiết ngân sách
            </a>
          </div>
        </div>
        <div style="background-color: #343a40; padding: 20px; text-align: center;">
          <p style="color: #adb5bd; margin: 0; font-size: 14px;">
            © 2024 ZBudget. Thông báo tự động từ hệ thống.
          </p>
        </div>
      </div>
    `,
  }),
};
// Send email function với debug logging tốt hơn
const sendEmail = async (to, template) => {
  try {
    // Log environment check đầu tiên
    console.log("🔍 Checking email environment variables...");
    console.log("EMAIL_USER exists:", !!process.env.EMAIL_USER);
    console.log("EMAIL_PASS exists:", !!process.env.EMAIL_PASS);

    // Kiểm tra email credentials
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.warn("⚠️ Email credentials not configured");
      console.warn("EMAIL_USER:", process.env.EMAIL_USER ? "SET" : "NOT SET");
      console.warn("EMAIL_PASS:", process.env.EMAIL_PASS ? "SET" : "NOT SET");
      return { success: false, error: "Email not configured" };
    }

    console.log(`📧 Attempting to send email to: ${to}`);

    // Test connection first
    const transporter = createTransporter();
    console.log("🔌 Verifying email connection...");

    try {
      await transporter.verify();
      console.log("✅ Email server ready");
    } catch (verifyError) {
      console.error("❌ Email verification failed:", verifyError.message);
      return {
        success: false,
        error: `Connection failed: ${verifyError.message}`,
      };
    }

    const mailOptions = {
      from: `"ZBudget" <${process.env.EMAIL_USER}>`,
      to,
      subject: template.subject,
      html: template.html,
    };

    console.log("📤 Sending email...");
    const result = await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent successfully. Message ID: ${result.messageId}`);

    return { success: true, messageId: result.messageId };
  } catch (error) {
    console.error("❌ Email send error:", error.message);
    console.error("📋 Error details:", {
      code: error.code,
      command: error.command,
      response: error.response,
      responseCode: error.responseCode,
      stack: error.stack,
    });
    return { success: false, error: error.message };
  }
};
// Exported email functions - đơn giản và dễ sử dụng
export const sendVerificationEmail = async (email, name, otp) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
      <div style="background: linear-gradient(135deg, #3DA13D 0%, #42D8C5 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">ZBudget</h1>
        <p style="color: white; margin: 10px 0 0 0; font-size: 16px;">Xác thực tài khoản</p>
      </div>
      <div style="background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
        <h2 style="color: #333; margin-bottom: 20px; text-align: center;">Chào mừng ${name}!</h2>
        <p style="color: #555; line-height: 1.6; margin-bottom: 30px; text-align: center;">
          Cảm ơn bạn đã đăng ký tài khoản ZBudget. Vui lòng nhập mã OTP bên dưới để xác thực tài khoản:
        </p>
                <div style="background: linear-gradient(135deg, #3DA13D 0%, #42D8C5 100%); margin: 30px auto; padding: 20px; border-radius: 15px; text-align: center; max-width: 300px;">
                  <p style="color: white; margin: 0 0 10px 0; font-size: 16px; font-weight: bold;">Mã xác thực OTP:</p>
                  <div style="background: rgba(255,255,255,0.2); padding: 15px; border-radius: 10px; margin-top: 10px;">
                    <span style="color: white; font-size: 32px; font-weight: bold; letter-spacing: 5px; font-family: 'Courier New', monospace;">${otp}</span>
                  </div>
                </div>        <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 15px; margin: 25px 0;">
          <p style="color: #856404; margin: 0; font-size: 14px; text-align: center;">
            <strong>⏰ Lưu ý:</strong> Mã OTP này sẽ hết hạn sau <strong>10 phút</strong>
          </p>
        </div>
        <div style="text-align: center; margin-top: 30px;">
          <p style="color: #666; font-size: 14px; margin: 0;">
            Nếu bạn không tạo tài khoản này, vui lòng bỏ qua email này.
          </p>
        </div>
      </div>
      <div style="text-align: center; margin-top: 20px;">
        <p style="color: #666; font-size: 12px; margin: 0;">
          © 2024 ZBudget. Tất cả quyền được bảo lưu.
        </p>
      </div>
    </div>
  `;
  const textContent = `
    ZBudget - Xác thực tài khoản
    Chào mừng ${name}!
    Cảm ơn bạn đã đăng ký tài khoản ZBudget.
    Mã OTP xác thực của bạn là: ${otp}
    Mã này sẽ hết hạn sau 10 phút.
    Nếu bạn không tạo tài khoản này, vui lòng bỏ qua email này.
    © 2024 ZBudget
  `;
  const template = {
    subject: "Mã OTP xác thực tài khoản ZBudget",
    html: htmlContent,
    text: textContent,
  };
  return await sendEmail(email, template);
};
export const sendPasswordResetEmail = async (email, name, token) => {
  const template = emailTemplates.passwordReset(name, token);
  return await sendEmail(email, template);
};
export const sendPasswordResetOTP = async (email, name, otp) => {
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f8f9fa; padding: 20px;">
      <div style="background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">ZBudget</h1>
        <p style="color: white; margin: 10px 0 0 0; font-size: 16px;">Đặt lại mật khẩu</p>
      </div>
      <div style="background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
        <h2 style="color: #333; margin-bottom: 20px; text-align: center;">Xin chào ${name}!</h2>
        <p style="color: #555; line-height: 1.6; margin-bottom: 30px; text-align: center;">
          Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản ZBudget của bạn.
          Vui lòng nhập mã OTP bên dưới để tiếp tục:
        </p>
        <div style="background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); margin: 30px auto; padding: 20px; border-radius: 15px; text-align: center; max-width: 300px;">
          <p style="color: white; margin: 0 0 10px 0; font-size: 16px; font-weight: bold;">Mã OTP đặt lại mật khẩu:</p>
          <div style="background: rgba(255,255,255,0.2); padding: 15px; border-radius: 10px; margin-top: 10px;">
            <span style="color: white; font-size: 32px; font-weight: bold; letter-spacing: 5px; font-family: 'Courier New', monospace;">${otp}</span>
          </div>
        </div>
        <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 15px; margin: 25px 0;">
          <p style="color: #856404; margin: 0; font-size: 14px; text-align: center;">
            <strong>⏰ Lưu ý:</strong> Mã OTP này sẽ hết hạn sau <strong>10 phút</strong>
          </p>
        </div>
        <div style="text-align: center; margin-top: 30px;">
          <p style="color: #666; font-size: 14px; margin: 0;">
            Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
            Mật khẩu của bạn sẽ không thay đổi.
          </p>
        </div>
      </div>
      <div style="text-align: center; margin-top: 20px;">
        <p style="color: #666; font-size: 12px; margin: 0;">
          © 2024 ZBudget. Tất cả quyền được bảo lưu.
        </p>
      </div>
    </div>
  `;
  const textContent = `
    ZBudget - Đặt lại mật khẩu
    Xin chào ${name}!
    Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản ZBudget của bạn.
    Mã OTP đặt lại mật khẩu của bạn là: ${otp}
    Mã này sẽ hết hạn sau 10 phút.
    Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
    © 2024 ZBudget
  `;
  const template = {
    subject: "Mã OTP đặt lại mật khẩu ZBudget",
    html: htmlContent,
    text: textContent,
  };
  return await sendEmail(email, template);
};
export const sendWelcomeEmail = async (email, name) => {
  const template = emailTemplates.welcome(name);
  return await sendEmail(email, template);
};
export const sendBudgetAlertEmail = async (
  email,
  name,
  budgetName,
  spent,
  total
) => {
  const percentage = Math.round((spent / total) * 100);
  const template = emailTemplates.budgetAlert(
    name,
    budgetName,
    spent,
    total,
    percentage
  );
  return await sendEmail(email, template);
};
// Send bulk emails (for notifications)
export const sendBulkEmail = async (recipients, template, data = {}) => {
  const results = [];
  for (const recipient of recipients) {
    try {
      const result = await sendEmail(recipient.email, template, {
        ...data,
        name: recipient.name,
      });
      results.push({
        email: recipient.email,
        success: result.success,
        error: result.error || null,
      });
      // Add delay between emails to avoid rate limits
      await new Promise((resolve) => setTimeout(resolve, 100));
    } catch (error) {
      results.push({
        email: recipient.email,
        success: false,
        error: error.message,
      });
    }
  }
  return results;
};
// Test email configuration - đơn giản
export const testEmailService = async () => {
  try {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      return { success: false, error: "Email credentials not configured" };
    }
    const transporter = createTransporter();
    await transporter.verify();
    return { success: true, message: "Email service ready" };
  } catch (error) {
    return { success: false, error: error.message };
  }
};
export default {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendPasswordResetOTP,
  sendWelcomeEmail,
  sendBudgetAlertEmail,
  sendBulkEmail,
  testEmailService,
};
