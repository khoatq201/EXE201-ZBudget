import Joi from "joi";
import { BadRequestError } from "./errorHandler.js";

// Vietnamese error messages for Joi
const vietnameseMessages = {
  "any.required": "{{#label}} là bắt buộc",
  "any.empty": "{{#label}} không được để trống",
  "any.invalid": "{{#label}} không hợp lệ",
  "string.min": "{{#label}} phải có ít nhất {{#limit}} ký tự",
  "string.max": "{{#label}} không được vượt quá {{#limit}} ký tự",
  "string.email": "{{#label}} phải là email hợp lệ",
  "string.pattern.base": "{{#label}} không đúng định dạng",
  "number.base": "{{#label}} phải là số",
  "number.integer": "{{#label}} phải là số nguyên",
  "number.positive": "{{#label}} phải là số dương",
  "number.min": "{{#label}} phải lớn hơn hoặc bằng {{#limit}}",
  "number.max": "{{#label}} phải nhỏ hơn hoặc bằng {{#limit}}",
  "date.base": "{{#label}} phải là ngày hợp lệ",
  "array.base": "{{#label}} phải là mảng",
  "array.min": "{{#label}} phải có ít nhất {{#limit}} phần tử",
  "array.max": "{{#label}} không được có quá {{#limit}} phần tử",
  "boolean.base": "{{#label}} phải là true hoặc false",
  "object.unknown": "Trường {{#label}} không được phép",
  "alternatives.match": "{{#label}} không khớp với bất kỳ kiểu nào được phép",
};

// MongoDB ObjectId validation function
const isValidObjectId = (value) => {
  return /^[0-9a-fA-F]{24}$/.test(value);
};

// Common validation schemas
const commonSchemas = {
  // MongoDB ObjectId
  mongoId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .label("ID")
    .messages({
      "string.pattern.base": "{{#label}} phải là MongoDB ObjectId hợp lệ",
    }),

  // Pagination
  pagination: {
    page: Joi.number().integer().min(1).default(1).label("Trang"),
    limit: Joi.number().integer().min(1).max(100).default(20).label("Giới hạn"),
    sort: Joi.string().valid("asc", "desc").default("desc").label("Sắp xếp"),
  },

  // Date range
  dateRange: {
    startDate: Joi.date().iso().label("Ngày bắt đầu"),
    endDate: Joi.date().iso().min(Joi.ref("startDate")).label("Ngày kết thúc"),
  },

  // Vietnamese phone number
  vietnamesePhone: Joi.string()
    .pattern(/^(\+84|84|0)[3|5|7|8|9]([0-9]{8})$/)
    .message("Số điện thoại phải là số điện thoại Việt Nam hợp lệ")
    .label("Số điện thoại"),

  // Currency amount (VND)
  vndAmount: Joi.number()
    .integer()
    .min(0)
    .max(999999999999) // 999 billion VND
    .label("Số tiền"),

  // Password strength
  strongPassword: Joi.string()
    .min(8)
    .max(128)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .message(
      "Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt"
    )
    .label("Mật khẩu"),

  // Vietnamese text
  vietnameseText: Joi.string()
    .pattern(/^[\p{L}\p{N}\s\.,!?\-()'"]+$/u)
    .message("Chỉ được chứa chữ cái, số và dấu câu cơ bản")
    .label("Văn bản"),
};

// User validation schemas
export const userSchemas = {
  register: Joi.object({
    fullName: Joi.string().min(2).max(100).required().label("Họ tên"), // ✅ Keep as fullName for API
    email: Joi.string().email().required().label("Email"),
    password: commonSchemas.strongPassword.required(),
    confirmPassword: Joi.string()
      .valid(Joi.ref("password"))
      .optional()
      .label("Xác nhận mật khẩu")
      .messages({
        "any.only": "Xác nhận mật khẩu không khớp",
      }),
    phoneNumber: commonSchemas.vietnamesePhone.optional(),
    dateOfBirth: Joi.alternatives()
      .try(
        Joi.date().max("now"),
        Joi.string().pattern(/^\d{2}\/\d{2}\/\d{4}$/) // DD/MM/YYYY format
      )
      .optional()
      .label("Ngày sinh"),
    gender: Joi.string()
      .valid("male", "female", "other")
      .optional()
      .label("Giới tính"),
  }).messages(vietnameseMessages),

  login: Joi.object({
    email: Joi.string().email().required().label("Email"),
    password: Joi.string().required().label("Mật khẩu"),
    rememberMe: Joi.boolean().optional().label("Ghi nhớ đăng nhập"),
  }).messages(vietnameseMessages),

  verifyOTP: Joi.object({
    email: Joi.string().email().required().label("Email"),
    otp: Joi.string()
      .length(6)
      .pattern(/^[0-9]+$/)
      .required()
      .label("Mã OTP")
      .messages({
        "string.length": "Mã OTP phải có đúng 6 số",
        "string.pattern.base": "Mã OTP chỉ được chứa các chữ số",
      }),
  }).messages(vietnameseMessages),

  verifyPasswordResetOTP: Joi.object({
    email: Joi.string().email().required().label("Email"),
    otp: Joi.string()
      .length(6)
      .pattern(/^[0-9]+$/)
      .required()
      .label("Mã OTP")
      .messages({
        "string.length": "Mã OTP phải có đúng 6 số",
        "string.pattern.base": "Mã OTP chỉ được chứa các chữ số",
      }),
  }).messages(vietnameseMessages),

  updateProfile: Joi.object({
    fullName: Joi.string().min(2).max(50).optional().label("Họ tên"),
    phoneNumber: commonSchemas.vietnamesePhone.optional(),
    dateOfBirth: Joi.date().max("now").optional().label("Ngày sinh"),
    gender: Joi.string()
      .valid("male", "female", "other")
      .optional()
      .label("Giới tính"),
    avatar: Joi.string().uri().optional().label("Ảnh đại diện"),
    preferences: Joi.object({
      currency: Joi.string().valid("VND", "USD").optional().label("Tiền tệ"),
      language: Joi.string().valid("vi", "en").optional().label("Ngôn ngữ"),
      notifications: Joi.object({
        email: Joi.boolean().optional().label("Thông báo email"),
        push: Joi.boolean().optional().label("Thông báo đẩy"),
        sms: Joi.boolean().optional().label("Thông báo SMS"),
      })
        .optional()
        .label("Tùy chọn thông báo"),
    })
      .optional()
      .label("Tùy chọn"),
  }).messages(vietnameseMessages),

  changePassword: Joi.object({
    currentPassword: Joi.string().required().label("Mật khẩu hiện tại"),
    newPassword: commonSchemas.strongPassword.required().label("Mật khẩu mới"),
    confirmNewPassword: Joi.string()
      .valid(Joi.ref("newPassword"))
      .required()
      .label("Xác nhận mật khẩu mới")
      .messages({
        "any.only": "Xác nhận mật khẩu mới không khớp",
      }),
  }).messages(vietnameseMessages),

  forgotPassword: Joi.object({
    email: Joi.string().email().required().label("Email"),
  }).messages(vietnameseMessages),

  resetPassword: Joi.object({
    email: Joi.string().email().required().label("Email"),
    otp: Joi.string()
      .length(6)
      .pattern(/^[0-9]+$/)
      .required()
      .label("Mã OTP")
      .messages({
        "string.length": "Mã OTP phải có đúng 6 số",
        "string.pattern.base": "Mã OTP chỉ được chứa các chữ số",
      }),
    newPassword: commonSchemas.strongPassword.required().label("Mật khẩu mới"),
    confirmNewPassword: Joi.string()
      .valid(Joi.ref("newPassword"))
      .required()
      .label("Xác nhận mật khẩu mới")
      .messages({
        "any.only": "Xác nhận mật khẩu mới không khớp",
      }),
  }).messages(vietnameseMessages),
};

// Expense validation schemas
export const expenseSchemas = {
  create: Joi.object({
    title: Joi.string().min(1).max(100).required().label("Tiêu đề"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    amount: commonSchemas.vndAmount.required(),
    category: Joi.string().required().label("Danh mục"),
    subcategory: Joi.string().optional().label("Danh mục phụ"),
    date: Joi.date().iso().max("now").required().label("Ngày"),
    paymentMethod: Joi.string()
      .valid("cash", "card", "transfer", "ewallet")
      .required()
      .label("Phương thức thanh toán"),
    location: Joi.string().max(200).optional().label("Địa điểm"),
    tags: Joi.array()
      .items(Joi.string().max(50))
      .max(10)
      .optional()
      .label("Thẻ"),
    receipt: Joi.string().uri().optional().label("Hóa đơn"),
    groupId: commonSchemas.mongoId.optional().label("ID nhóm"),
    budgetId: commonSchemas.mongoId.optional().label("ID ngân sách"),
  }).messages(vietnameseMessages),

  update: Joi.object({
    title: Joi.string().min(1).max(100).optional().label("Tiêu đề"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    amount: commonSchemas.vndAmount.optional(),
    category: Joi.string().optional().label("Danh mục"),
    subcategory: Joi.string().optional().label("Danh mục phụ"),
    date: Joi.date().iso().max("now").optional().label("Ngày"),
    paymentMethod: Joi.string()
      .valid("cash", "card", "transfer", "ewallet")
      .optional()
      .label("Phương thức thanh toán"),
    location: Joi.string().max(200).optional().label("Địa điểm"),
    tags: Joi.array()
      .items(Joi.string().max(50))
      .max(10)
      .optional()
      .label("Thẻ"),
    receipt: Joi.string().uri().optional().label("Hóa đơn"),
  }).messages(vietnameseMessages),

  query: Joi.object({
    ...commonSchemas.pagination,
    ...commonSchemas.dateRange,
    category: Joi.string().optional().label("Danh mục"),
    subcategory: Joi.string().optional().label("Danh mục phụ"),
    minAmount: commonSchemas.vndAmount.optional().label("Số tiền tối thiểu"),
    maxAmount: commonSchemas.vndAmount.optional().label("Số tiền tối đa"),
    paymentMethod: Joi.string()
      .valid("cash", "card", "transfer", "ewallet")
      .optional()
      .label("Phương thức thanh toán"),
    tags: Joi.alternatives()
      .try(Joi.string(), Joi.array().items(Joi.string()))
      .optional()
      .label("Thẻ"),
    groupId: commonSchemas.mongoId.optional().label("ID nhóm"),
    budgetId: commonSchemas.mongoId.optional().label("ID ngân sách"),
    search: Joi.string().max(100).optional().label("Tìm kiếm"),
  }).messages(vietnameseMessages),
};

// Budget validation schemas
export const budgetSchemas = {
  create: Joi.object({
    name: Joi.string().min(1).max(100).required().label("Tên ngân sách"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    totalAmount: commonSchemas.vndAmount.required().label("Tổng số tiền"),
    period: Joi.string()
      .valid("daily", "weekly", "monthly", "yearly", "custom")
      .required()
      .label("Chu kỳ"),
    startDate: Joi.date().iso().required().label("Ngày bắt đầu"),
    endDate: Joi.date()
      .iso()
      .min(Joi.ref("startDate"))
      .required()
      .label("Ngày kết thúc"),
    categories: Joi.array()
      .items(
        Joi.object({
          category: Joi.string().required().label("Danh mục"),
          amount: commonSchemas.vndAmount.required().label("Số tiền"),
          subcategories: Joi.array()
            .items(Joi.string())
            .optional()
            .label("Danh mục phụ"),
        })
      )
      .min(1)
      .required()
      .label("Danh mục ngân sách"),
    alertThreshold: Joi.number()
      .min(0)
      .max(100)
      .default(80)
      .label("Ngưỡng cảnh báo (%)"),
    isActive: Joi.boolean().default(true).label("Trạng thái hoạt động"),
    groupId: commonSchemas.mongoId.optional().label("ID nhóm"),
  }).messages(vietnameseMessages),

  update: Joi.object({
    name: Joi.string().min(1).max(100).optional().label("Tên ngân sách"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    totalAmount: commonSchemas.vndAmount.optional().label("Tổng số tiền"),
    period: Joi.string()
      .valid("daily", "weekly", "monthly", "yearly", "custom")
      .optional()
      .label("Chu kỳ"),
    startDate: Joi.date().iso().optional().label("Ngày bắt đầu"),
    endDate: Joi.date()
      .iso()
      .min(Joi.ref("startDate"))
      .optional()
      .label("Ngày kết thúc"),
    categories: Joi.array()
      .items(
        Joi.object({
          category: Joi.string().required().label("Danh mục"),
          amount: commonSchemas.vndAmount.required().label("Số tiền"),
          subcategories: Joi.array()
            .items(Joi.string())
            .optional()
            .label("Danh mục phụ"),
        })
      )
      .optional()
      .label("Danh mục ngân sách"),
    alertThreshold: Joi.number()
      .min(0)
      .max(100)
      .optional()
      .label("Ngưỡng cảnh báo (%)"),
    isActive: Joi.boolean().optional().label("Trạng thái hoạt động"),
  }).messages(vietnameseMessages),

  query: Joi.object({
    ...commonSchemas.pagination,
    ...commonSchemas.dateRange,
    period: Joi.string()
      .valid("daily", "weekly", "monthly", "yearly", "custom")
      .optional()
      .label("Chu kỳ"),
    isActive: Joi.boolean().optional().label("Trạng thái hoạt động"),
    category: Joi.string().optional().label("Danh mục"),
    groupId: commonSchemas.mongoId.optional().label("ID nhóm"),
    search: Joi.string().max(100).optional().label("Tìm kiếm"),
  }).messages(vietnameseMessages),
};

// Challenge validation schemas
export const challengeSchemas = {
  create: Joi.object({
    title: Joi.string().min(1).max(100).required().label("Tiêu đề thử thách"),
    description: commonSchemas.vietnameseText
      .max(1000)
      .required()
      .label("Mô tả"),
    type: Joi.string()
      .valid("savings", "expense_reduction", "budget_adherence", "custom")
      .required()
      .label("Loại thử thách"),
    difficulty: Joi.string()
      .valid("easy", "medium", "hard")
      .required()
      .label("Độ khó"),
    targetAmount: commonSchemas.vndAmount.optional().label("Mục tiêu số tiền"),
    targetDays: Joi.number()
      .integer()
      .min(1)
      .max(365)
      .optional()
      .label("Số ngày mục tiêu"),
    category: Joi.string().optional().label("Danh mục"),
    startDate: Joi.date().iso().default("now").label("Ngày bắt đầu"),
    endDate: Joi.date()
      .iso()
      .min(Joi.ref("startDate"))
      .required()
      .label("Ngày kết thúc"),
    rewards: Joi.object({
      points: Joi.number().integer().min(0).required().label("Điểm thưởng"),
      badge: Joi.string().optional().label("Huy hiệu"),
      description: Joi.string().max(200).optional().label("Mô tả phần thưởng"),
    })
      .required()
      .label("Phần thưởng"),
    rules: Joi.array()
      .items(
        Joi.object({
          condition: Joi.string().required().label("Điều kiện"),
          value: Joi.alternatives()
            .try(Joi.string(), Joi.number())
            .required()
            .label("Giá trị"),
          operator: Joi.string()
            .valid(">", "<", ">=", "<=", "==", "!=")
            .required()
            .label("Toán tử"),
        })
      )
      .min(1)
      .required()
      .label("Quy tắc"),
    isActive: Joi.boolean().default(true).label("Trạng thái hoạt động"),
    maxParticipants: Joi.number()
      .integer()
      .min(1)
      .optional()
      .label("Số người tham gia tối đa"),
    tags: Joi.array()
      .items(Joi.string().max(50))
      .max(10)
      .optional()
      .label("Thẻ"),
  }).messages(vietnameseMessages),

  update: Joi.object({
    title: Joi.string().min(1).max(100).optional().label("Tiêu đề thử thách"),
    description: commonSchemas.vietnameseText
      .max(1000)
      .optional()
      .label("Mô tả"),
    difficulty: Joi.string()
      .valid("easy", "medium", "hard")
      .optional()
      .label("Độ khó"),
    targetAmount: commonSchemas.vndAmount.optional().label("Mục tiêu số tiền"),
    targetDays: Joi.number()
      .integer()
      .min(1)
      .max(365)
      .optional()
      .label("Số ngày mục tiêu"),
    category: Joi.string().optional().label("Danh mục"),
    endDate: Joi.date().iso().optional().label("Ngày kết thúc"),
    rewards: Joi.object({
      points: Joi.number().integer().min(0).optional().label("Điểm thưởng"),
      badge: Joi.string().optional().label("Huy hiệu"),
      description: Joi.string().max(200).optional().label("Mô tả phần thưởng"),
    })
      .optional()
      .label("Phần thưởng"),
    isActive: Joi.boolean().optional().label("Trạng thái hoạt động"),
    maxParticipants: Joi.number()
      .integer()
      .min(1)
      .optional()
      .label("Số người tham gia tối đa"),
    tags: Joi.array()
      .items(Joi.string().max(50))
      .max(10)
      .optional()
      .label("Thẻ"),
  }).messages(vietnameseMessages),

  join: Joi.object({
    personalGoal: commonSchemas.vndAmount.optional().label("Mục tiêu cá nhân"),
  }).messages(vietnameseMessages),

  updateProgress: Joi.object({
    progressValue: Joi.number().min(0).required().label("Giá trị tiến độ"),
    notes: commonSchemas.vietnameseText.max(500).optional().label("Ghi chú"),
  }).messages(vietnameseMessages),

  query: Joi.object({
    ...commonSchemas.pagination,
    type: Joi.string()
      .valid("savings", "expense_reduction", "budget_adherence", "custom")
      .optional()
      .label("Loại thử thách"),
    difficulty: Joi.string()
      .valid("easy", "medium", "hard")
      .optional()
      .label("Độ khó"),
    status: Joi.string()
      .valid("active", "completed", "failed", "upcoming")
      .optional()
      .label("Trạng thái"),
    category: Joi.string().optional().label("Danh mục"),
    tags: Joi.alternatives()
      .try(Joi.string(), Joi.array().items(Joi.string()))
      .optional()
      .label("Thẻ"),
    search: Joi.string().max(100).optional().label("Tìm kiếm"),
  }).messages(vietnameseMessages),
};

// Group validation schemas
export const groupSchemas = {
  create: Joi.object({
    name: Joi.string().min(1).max(100).required().label("Tên nhóm"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    type: Joi.string()
      .valid("family", "friends", "colleagues", "custom")
      .required()
      .label("Loại nhóm"),
    avatar: Joi.string().uri().optional().label("Ảnh đại diện nhóm"),
    settings: Joi.object({
      isPublic: Joi.boolean().default(false).label("Công khai"),
      allowMemberInvite: Joi.boolean()
        .default(false)
        .label("Cho phép thành viên mời"),
      expenseApprovalRequired: Joi.boolean()
        .default(false)
        .label("Yêu cầu phê duyệt chi tiêu"),
      currency: Joi.string()
        .valid("VND", "USD")
        .default("VND")
        .label("Tiền tệ"),
    })
      .optional()
      .label("Cài đặt nhóm"),
  }).messages(vietnameseMessages),

  update: Joi.object({
    name: Joi.string().min(1).max(100).optional().label("Tên nhóm"),
    description: commonSchemas.vietnameseText
      .max(500)
      .optional()
      .label("Mô tả"),
    type: Joi.string()
      .valid("family", "friends", "colleagues", "custom")
      .optional()
      .label("Loại nhóm"),
    avatar: Joi.string().uri().optional().label("Ảnh đại diện nhóm"),
    settings: Joi.object({
      isPublic: Joi.boolean().optional().label("Công khai"),
      allowMemberInvite: Joi.boolean()
        .optional()
        .label("Cho phép thành viên mời"),
      expenseApprovalRequired: Joi.boolean()
        .optional()
        .label("Yêu cầu phê duyệt chi tiêu"),
      currency: Joi.string().valid("VND", "USD").optional().label("Tiền tệ"),
    })
      .optional()
      .label("Cài đặt nhóm"),
  }).messages(vietnameseMessages),

  inviteMember: Joi.object({
    email: Joi.string().email().required().label("Email"),
    role: Joi.string()
      .valid("admin", "member", "viewer")
      .default("member")
      .label("Vai trò"),
  }).messages(vietnameseMessages),

  updateMemberRole: Joi.object({
    role: Joi.string()
      .valid("admin", "member", "viewer")
      .required()
      .label("Vai trò"),
  }).messages(vietnameseMessages),

  query: Joi.object({
    ...commonSchemas.pagination,
    type: Joi.string()
      .valid("family", "friends", "colleagues", "custom")
      .optional()
      .label("Loại nhóm"),
    isPublic: Joi.boolean().optional().label("Công khai"),
    search: Joi.string().max(100).optional().label("Tìm kiếm"),
  }).messages(vietnameseMessages),
};

// Notification validation schemas
export const notificationSchemas = {
  create: Joi.object({
    title: Joi.string().min(1).max(100).required().label("Tiêu đề"),
    message: commonSchemas.vietnameseText.max(500).required().label("Nội dung"),
    type: Joi.string()
      .valid("info", "warning", "error", "success")
      .required()
      .label("Loại thông báo"),
    category: Joi.string()
      .valid("expense", "budget", "challenge", "group", "system")
      .required()
      .label("Danh mục"),
    priority: Joi.string()
      .valid("low", "medium", "high", "urgent")
      .default("medium")
      .label("Độ ưu tiên"),
    actionUrl: Joi.string().uri().optional().label("URL hành động"),
    actionText: Joi.string().max(50).optional().label("Văn bản hành động"),
    metadata: Joi.object().optional().label("Dữ liệu bổ sung"),
    recipients: Joi.array()
      .items(commonSchemas.mongoId)
      .min(1)
      .required()
      .label("Người nhận"),
    scheduledFor: Joi.date().iso().min("now").optional().label("Lên lịch gửi"),
  }).messages(vietnameseMessages),

  query: Joi.object({
    ...commonSchemas.pagination,
    type: Joi.string()
      .valid("info", "warning", "error", "success")
      .optional()
      .label("Loại thông báo"),
    category: Joi.string()
      .valid("expense", "budget", "challenge", "group", "system")
      .optional()
      .label("Danh mục"),
    priority: Joi.string()
      .valid("low", "medium", "high", "urgent")
      .optional()
      .label("Độ ưu tiên"),
    isRead: Joi.boolean().optional().label("Đã đọc"),
    ...commonSchemas.dateRange,
  }).messages(vietnameseMessages),

  markAsRead: Joi.object({
    notificationIds: Joi.array()
      .items(commonSchemas.mongoId)
      .min(1)
      .required()
      .label("ID thông báo"),
  }).messages(vietnameseMessages),
};

// File upload validation
export const uploadSchemas = {
  image: Joi.object({
    file: Joi.object({
      mimetype: Joi.string()
        .valid("image/jpeg", "image/jpg", "image/png", "image/webp")
        .required()
        .label("Loại file")
        .messages({
          "any.only": "Chỉ chấp nhận file ảnh (JPEG, PNG, WebP)",
        }),
      size: Joi.number()
        .max(5 * 1024 * 1024)
        .required() // 5MB
        .label("Kích thước file")
        .messages({
          "number.max": "File không được vượt quá 5MB",
        }),
    })
      .required()
      .label("File"),
  }).messages(vietnameseMessages),

  receipt: Joi.object({
    file: Joi.object({
      mimetype: Joi.string()
        .valid(
          "image/jpeg",
          "image/jpg",
          "image/png",
          "image/webp",
          "application/pdf"
        )
        .required()
        .label("Loại file")
        .messages({
          "any.only": "Chỉ chấp nhận file ảnh (JPEG, PNG, WebP) hoặc PDF",
        }),
      size: Joi.number()
        .max(10 * 1024 * 1024)
        .required() // 10MB
        .label("Kích thước file")
        .messages({
          "number.max": "File không được vượt quá 10MB",
        }),
    })
      .required()
      .label("File"),
  }).messages(vietnameseMessages),
};

// Generic validation middleware
export const validate = (schema, property = "body") => {
  return (req, res, next) => {
    const validationStartTime = Date.now();
    console.log("🔍 DEBUG: ===== VALIDATION MIDDLEWARE STARTED =====");
    console.log(`🔍 DEBUG: Validating ${property} data`);

    const dataToValidate =
      property === "query"
        ? req.query
        : property === "params"
          ? req.params
          : req.body;

    console.log(
      "🔍 DEBUG: Data to validate:",
      JSON.stringify(dataToValidate, null, 2)
    );

    try {
      const { error, value } = schema.validate(dataToValidate, {
        abortEarly: false,
        stripUnknown: true,
        convert: true,
      });

      const validationDuration = Date.now() - validationStartTime;

      if (error) {
        console.log(
          `❌ DEBUG: Validation failed in ${validationDuration}ms:`,
          error.message
        );
        console.log(
          "📋 DEBUG: Validation error details:",
          error.details.map((d) => ({
            field: d.path.join("."),
            message: d.message,
            value: d.context?.value,
          }))
        );

        const errorMessage = error.details
          .map((detail) => detail.message)
          .join(", ");
        console.log(`❌ DEBUG: Throwing BadRequestError: ${errorMessage}`);
        throw new BadRequestError(errorMessage);
      }

      console.log(`✅ DEBUG: Validation passed in ${validationDuration}ms`);

      // Update request with validated data
      if (property === "query") {
        req.query = value;
      } else if (property === "params") {
        req.params = value;
      } else {
        req.body = value;
      }

      console.log("🔍 DEBUG: ===== VALIDATION MIDDLEWARE COMPLETED =====");
      next();
    } catch (validationError) {
      const validationDuration = Date.now() - validationStartTime;
      console.error(
        `💥 DEBUG: Validation middleware error after ${validationDuration}ms:`,
        validationError
      );
      throw validationError;
    }
  };
};

// Validate MongoDB ObjectId parameter
export const validateObjectId = (paramName = "id") => {
  return validate(
    Joi.object({
      [paramName]: commonSchemas.mongoId,
    }),
    "params"
  );
};

// Validate pagination query
export const validatePagination = validate(
  Joi.object(commonSchemas.pagination),
  "query"
);

// Validate date range query
export const validateDateRange = validate(
  Joi.object(commonSchemas.dateRange),
  "query"
);

// Combine multiple validation schemas
export const combineValidation = (...schemas) => {
  return (req, res, next) => {
    const combinedSchema = Joi.object().concat(...schemas);
    return validate(combinedSchema)(req, res, next);
  };
};

// File validation middleware
export const validateFile = (schema) => {
  return (req, res, next) => {
    if (!req.file) {
      throw new BadRequestError("Không có file được tải lên");
    }

    const { error } = schema.validate({ file: req.file });

    if (error) {
      throw new BadRequestError(error.details[0].message);
    }

    next();
  };
};

// Custom validation for business rules
export const businessRuleValidation = {
  // Validate expense date is not in the future
  expenseDate: (req, res, next) => {
    if (req.body.date && new Date(req.body.date) > new Date()) {
      throw new BadRequestError("Ngày chi tiêu không được ở tương lai");
    }
    next();
  },

  // Validate budget dates
  budgetDates: (req, res, next) => {
    const { startDate, endDate } = req.body;

    if (startDate && endDate) {
      const start = new Date(startDate);
      const end = new Date(endDate);
      const now = new Date();

      if (start >= end) {
        throw new BadRequestError("Ngày bắt đầu phải trước ngày kết thúc");
      }

      if (end < now) {
        throw new BadRequestError("Ngày kết thúc không được ở quá khứ");
      }

      // Maximum budget period is 1 year
      const oneYear = 365 * 24 * 60 * 60 * 1000;
      if (end - start > oneYear) {
        throw new BadRequestError("Chu kỳ ngân sách không được vượt quá 1 năm");
      }
    }

    next();
  },

  // Validate challenge dates
  challengeDates: (req, res, next) => {
    const { startDate, endDate } = req.body;

    if (startDate && endDate) {
      const start = new Date(startDate);
      const end = new Date(endDate);

      if (start >= end) {
        throw new BadRequestError("Ngày bắt đầu phải trước ngày kết thúc");
      }

      // Challenge minimum duration is 1 day
      const oneDay = 24 * 60 * 60 * 1000;
      if (end - start < oneDay) {
        throw new BadRequestError("Thời gian thử thách phải ít nhất 1 ngày");
      }

      // Challenge maximum duration is 1 year
      const oneYear = 365 * 24 * 60 * 60 * 1000;
      if (end - start > oneYear) {
        throw new BadRequestError(
          "Thời gian thử thách không được vượt quá 1 năm"
        );
      }
    }

    next();
  },
};

export default {
  validate,
  validateObjectId,
  validatePagination,
  validateDateRange,
  combineValidation,
  validateFile,
  businessRuleValidation,
  userSchemas,
  expenseSchemas,
  budgetSchemas,
  challengeSchemas,
  groupSchemas,
  notificationSchemas,
  uploadSchemas,
};
