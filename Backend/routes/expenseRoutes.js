import express from "express";
import {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
  getExpenseStats,
  getExpensesByCategory,
  getExpensesByDateRange,
  exportExpenses,
  bulkDeleteExpenses,
  duplicateExpense,
} from "../controllers/expenseController.js";
import { authenticate, rateLimitGeneral } from "../middleware/auth.js";
import {
  validate,
  validateObjectId,
  expenseSchemas,
  businessRuleValidation,
  validateFile,
  uploadSchemas,
} from "../middleware/validation.js";
import { auditLogger } from "../middleware/logger.js";
import { uploadMiddleware } from "../middleware/upload.js";
import Joi from "joi";

const router = express.Router();

// Apply authentication to all expense routes
router.use(authenticate);

// Apply general rate limiting (with default 15min window, 100 requests max)
router.use(rateLimitGeneral());

// Audit logging for expense operations
const auditExpenseOperation = (operation) => (req, res, next) => {
  res.on("finish", () => {
    if (res.statusCode < 400) {
      auditLogger(operation, req, {
        expenseId: req.params.id || res.locals.expenseId,
        success: true,
        statusCode: res.statusCode,
      });
    }
  });
  next();
};

/**
 * @route   POST /api/expenses
 * @desc    Tạo chi tiêu mới
 * @access  Private
 * @body    { title, description?, amount, category, subcategory?, date, paymentMethod, location?, tags?, receipt?, groupId?, budgetId? }
 */
router.post(
  "/",
  validate(expenseSchemas.create),
  businessRuleValidation.expenseDate,
  auditExpenseOperation("EXPENSE_CREATE"),
  createExpense
);

/**
 * @route   POST /api/expenses/with-receipt
 * @desc    Tạo chi tiêu mới kèm hóa đơn
 * @access  Private
 * @form    title, amount, category, date, paymentMethod, receipt (file)
 */
router.post(
  "/with-receipt",
  uploadMiddleware.receipt,
  validateFile(uploadSchemas.receipt),
  validate(expenseSchemas.create),
  businessRuleValidation.expenseDate,
  auditExpenseOperation("EXPENSE_CREATE_WITH_RECEIPT"),
  createExpense
);

/**
 * @route   GET /api/expenses
 * @desc    Lấy danh sách chi tiêu (có phân trang và filter)
 * @access  Private
 * @query   page?, limit?, sort?, startDate?, endDate?, category?, subcategory?, minAmount?, maxAmount?, paymentMethod?, tags?, groupId?, budgetId?, search?
 */
router.get("/", validate(expenseSchemas.query, "query"), getExpenses);

/**
 * @route   GET /api/expenses/stats
 * @desc    Lấy thống kê chi tiêu
 * @access  Private
 * @query   startDate?, endDate?, groupBy?, category?
 */
router.get(
  "/stats",
  validate(
    Joi.object({
      startDate: Joi.date().iso().optional().label("Ngày bắt đầu"),
      endDate: Joi.date()
        .iso()
        .min(Joi.ref("startDate"))
        .optional()
        .label("Ngày kết thúc"),
      groupBy: Joi.string()
        .valid("day", "week", "month", "year", "category", "paymentMethod")
        .optional()
        .label("Nhóm theo"),
      category: Joi.string().optional().label("Danh mục"),
    }),
    "query"
  ),
  getExpenseStats
);

/**
 * @route   GET /api/expenses/by-category
 * @desc    Lấy chi tiêu theo danh mục
 * @access  Private
 * @query   startDate?, endDate?, includeSubcategories?
 */
router.get(
  "/by-category",
  validate(
    Joi.object({
      startDate: Joi.date().iso().optional().label("Ngày bắt đầu"),
      endDate: Joi.date()
        .iso()
        .min(Joi.ref("startDate"))
        .optional()
        .label("Ngày kết thúc"),
      includeSubcategories: Joi.boolean()
        .optional()
        .label("Bao gồm danh mục phụ"),
    }),
    "query"
  ),
  getExpensesByCategory
);

/**
 * @route   GET /api/expenses/by-date-range
 * @desc    Lấy chi tiêu theo khoảng thời gian
 * @access  Private
 * @query   startDate, endDate, groupBy?
 */
router.get(
  "/by-date-range",
  validate(
    Joi.object({
      startDate: Joi.date().iso().required().label("Ngày bắt đầu"),
      endDate: Joi.date()
        .iso()
        .min(Joi.ref("startDate"))
        .required()
        .label("Ngày kết thúc"),
      groupBy: Joi.string()
        .valid("day", "week", "month")
        .default("day")
        .label("Nhóm theo"),
    }),
    "query"
  ),
  getExpensesByDateRange
);

/**
 * @route   GET /api/expenses/export
 * @desc    Xuất dữ liệu chi tiêu (CSV/Excel)
 * @access  Private
 * @query   format?, startDate?, endDate?, category?, includeReceipts?
 */
router.get(
  "/export",
  validate(
    Joi.object({
      format: Joi.string()
        .valid("csv", "excel")
        .default("csv")
        .label("Định dạng"),
      startDate: Joi.date().iso().optional().label("Ngày bắt đầu"),
      endDate: Joi.date()
        .iso()
        .min(Joi.ref("startDate"))
        .optional()
        .label("Ngày kết thúc"),
      category: Joi.string().optional().label("Danh mục"),
      includeReceipts: Joi.boolean().default(false).label("Bao gồm hóa đơn"),
    }),
    "query"
  ),
  auditExpenseOperation("EXPENSE_EXPORT"),
  exportExpenses
);

/**
 * @route   GET /api/expenses/:id
 * @desc    Lấy chi tiết một chi tiêu
 * @access  Private
 * @params  id - Expense ID
 */
router.get("/:id", validateObjectId("id"), getExpenseById);

/**
 * @route   PUT /api/expenses/:id
 * @desc    Cập nhật chi tiêu
 * @access  Private
 * @params  id - Expense ID
 * @body    { title?, description?, amount?, category?, subcategory?, date?, paymentMethod?, location?, tags? }
 */
router.put(
  "/:id",
  validateObjectId("id"),
  validate(expenseSchemas.update),
  businessRuleValidation.expenseDate,
  auditExpenseOperation("EXPENSE_UPDATE"),
  updateExpense
);

/**
 * @route   PUT /api/expenses/:id/receipt
 * @desc    Cập nhật hóa đơn cho chi tiêu
 * @access  Private
 * @params  id - Expense ID
 * @form    receipt (file)
 */
router.put(
  "/:id/receipt",
  validateObjectId("id"),
  uploadMiddleware.receipt,
  validateFile(uploadSchemas.receipt),
  auditExpenseOperation("EXPENSE_RECEIPT_UPDATE"),
  async (req, res, next) => {
    // Add receipt file info to request for controller
    req.body.receiptFile = req.file;
    next();
  },
  updateExpense
);

/**
 * @route   DELETE /api/expenses/:id/receipt
 * @desc    Xóa hóa đơn của chi tiêu
 * @access  Private
 * @params  id - Expense ID
 */
router.delete(
  "/:id/receipt",
  validateObjectId("id"),
  auditExpenseOperation("EXPENSE_RECEIPT_DELETE"),
  async (req, res, next) => {
    req.body.removeReceipt = true;
    next();
  },
  updateExpense
);

/**
 * @route   POST /api/expenses/:id/duplicate
 * @desc    Nhân bản chi tiêu
 * @access  Private
 * @params  id - Expense ID
 * @body    { date?, title?, amount? }
 */
router.post(
  "/:id/duplicate",
  validateObjectId("id"),
  validate(
    Joi.object({
      date: Joi.date().iso().max("now").optional().label("Ngày"),
      title: Joi.string().max(100).optional().label("Tiêu đề"),
      amount: Joi.number().integer().min(0).optional().label("Số tiền"),
    })
  ),
  auditExpenseOperation("EXPENSE_DUPLICATE"),
  duplicateExpense
);

/**
 * @route   DELETE /api/expenses/:id
 * @desc    Xóa một chi tiêu
 * @access  Private
 * @params  id - Expense ID
 */
router.delete(
  "/:id",
  validateObjectId("id"),
  auditExpenseOperation("EXPENSE_DELETE"),
  deleteExpense
);

/**
 * @route   DELETE /api/expenses
 * @desc    Xóa nhiều chi tiêu
 * @access  Private
 * @body    { expenseIds: [string] }
 */
router.delete(
  "/",
  validate(
    Joi.object({
      expenseIds: Joi.array()
        .items(
          Joi.string()
            .pattern(/^[0-9a-fA-F]{24}$/)
            .message("ID không hợp lệ")
        )
        .min(1)
        .max(50)
        .required()
        .label("Danh sách ID chi tiêu"),
    })
  ),
  auditExpenseOperation("EXPENSE_BULK_DELETE"),
  bulkDeleteExpenses
);

/**
 * @route   POST /api/expenses/bulk-import
 * @desc    Nhập khẩu chi tiêu từ file CSV/Excel
 * @access  Private
 * @form    file (csv/excel)
 */
router.post(
  "/bulk-import",
  uploadMiddleware.any,
  validate(
    Joi.object({
      file: Joi.object({
        mimetype: Joi.string()
          .valid(
            "text/csv",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          )
          .required()
          .label("Loại file")
          .messages({
            "any.only": "Chỉ chấp nhận file CSV hoặc Excel",
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
    })
  ),
  auditExpenseOperation("EXPENSE_BULK_IMPORT"),
  async (req, res, next) => {
    // Implementation will be added in controller
    req.body.importFile = req.files[0];
    next();
  }
  // bulkImportExpenses // Will be implemented
);

export default router;
