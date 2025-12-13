import OCRService from "../services/ocrService.js";
import { uploadMiddleware } from "../middleware/upload.js";
import UsageLimit from "../models/UsageLimit.js";
import User from "../models/User.js";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class OCRController {
  async processReceipt(req, res) {
    try {
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({
          success: false,
          message: "Không có file ảnh được upload",
          debug: {
            hasFiles: !!req.files,
            filesLength: req.files ? req.files.length : 0,
            contentType: req.headers["content-type"],
          },
        });
      }

      const file = req.files[0];
      console.log(
        `[OCR] Processing file: ${file.originalname}, size: ${
          file.buffer?.length || file.size
        } bytes`
      );

      // Use buffer directly from memory storage (no Cloudinary fetch needed)
      const ocrResult = await OCRService.extractTextFromImage(
        file.buffer,
        file.mimetype,
        file.originalname
      );

      if (!ocrResult.success) {
        return res.status(500).json({
          success: false,
          message: "Lỗi khi xử lý ảnh: " + ocrResult.error,
        });
      }

      const receiptData = OCRService.processReceiptData(ocrResult);
      // No file cleanup needed - using memory storage

      // Track OCR usage AFTER successful scan
      console.log(`[OCR] Starting usage tracking for user ${req.userId}...`);
      try {
        const userId = req.userId;
        console.log(`[OCR] Finding user ${userId}...`);
        const user = await User.findById(userId).select("subscription");

        if (!user) {
          console.error(`[OCR] User ${userId} not found!`);
        } else {
          console.log(`[OCR] User found, tier: ${user.subscription.tier}`);
          const tier = user.subscription.tier;

          console.log(`[OCR] Incrementing OCR count...`);
          await UsageLimit.incrementOCRCount(userId, tier);
          console.log(`[OCR] OCR count incremented successfully`);

          // Get updated usage for response
          console.log(`[OCR] Getting updated usage stats...`);
          const updatedUsage = await UsageLimit.getUserUsageStats(userId, tier);

          console.log(
            `[OCR] ✅ Tracked usage for user ${userId}: ${updatedUsage.usage.ocr.count}/${updatedUsage.usage.ocr.limit}`
          );

          // Include usage info in response
          const response = {
            success: true,
            data: receiptData,
            confidence: ocrResult.confidence,
            provider: ocrResult.provider,
            usage: {
              ocr: updatedUsage.usage.ocr,
              tier: updatedUsage.tier,
              message:
                updatedUsage.tier === "free"
                  ? `Còn ${updatedUsage.usage.ocr.remaining} lượt quét hôm nay`
                  : "Quét không giới hạn (Premium)",
            },
          };

          return res.json(response);
        }
      } catch (trackError) {
        console.error("[OCR] ❌ Error tracking usage:", trackError);
        console.error("[OCR] Error stack:", trackError.stack);
        // Continue with response even if tracking fails
      }

      // Fallback response without usage info
      const response = {
        success: true,
        data: receiptData,
        confidence: ocrResult.confidence,
        provider: ocrResult.provider,
      };

      res.json(response);
    } catch (error) {
      console.error("[OCR] Error processing receipt:", error);

      res.status(500).json({
        success: false,
        message: "Lỗi server khi xử lý OCR",
        error: error.message,
      });
    }
  }

  async processReceiptFromUrl(req, res) {
    try {
      const { imageUrl } = req.body;

      if (!imageUrl) {
        return res.status(400).json({
          success: false,
          message: "Không có URL ảnh được cung cấp",
        });
      }

      // For URL processing, we would need to download the image first
      // This is a simplified version - in production you'd want to download and process
      res.status(501).json({
        success: false,
        message: "Xử lý ảnh từ URL chưa được implement",
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Lỗi server khi xử lý OCR từ URL",
        error: error.message,
      });
    }
  }

  async getStatus(req, res) {
    try {
      res.json({
        success: true,
        message: "OCR service đang hoạt động",
        provider: "Gemini AI",
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "Lỗi khi kiểm tra trạng thái OCR",
        error: error.message,
      });
    }
  }
}

export default new OCRController();
