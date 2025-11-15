import express from "express";
import OCRController from "../controllers/ocrController.js";
import { uploadMiddleware } from "../middleware/upload.js";
import { authenticate } from "../middleware/auth.js";
import { checkOCRLimit, trackOCRUsage } from "../middleware/premium.js";
import rateLimit from "express-rate-limit";

const router = express.Router();

// Rate limiting for OCR endpoints
const ocrRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    success: false,
    message: "Quá nhiều yêu cầu OCR. Vui lòng thử lại sau 15 phút.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// OCR Routes
router.post(
  "/process-receipt",
  authenticate,
  checkOCRLimit, // Check if user has quota remaining
  ocrRateLimit,
  uploadMiddleware.ocr,
  OCRController.processReceipt // Tracking happens inside controller now
);

router.post(
  "/process-receipt-url",
  authenticate,
  ocrRateLimit,
  OCRController.processReceiptFromUrl
);

router.get("/status", authenticate, OCRController.getStatus);
router.get("/test", OCRController.getStatus);

export default router;
