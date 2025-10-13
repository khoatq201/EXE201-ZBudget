import OCRService from "../services/ocrService.js";
import { uploadMiddleware } from "../middleware/upload.js";
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

      const imagePath = req.files[0].path;
      const ocrResult = await OCRService.extractTextFromImage(imagePath);

      if (!ocrResult.success) {
        // Clean up uploaded file (only if it's a local file)
        if (
          req.files &&
          req.files[0] &&
          !req.files[0].path.startsWith("http")
        ) {
          try {
            fs.unlinkSync(req.files[0].path);
          } catch (cleanupError) {
            // Silent cleanup
          }
        }
        return res.status(500).json({
          success: false,
          message: "Lỗi khi xử lý ảnh: " + ocrResult.error,
        });
      }

      const receiptData = OCRService.processReceiptData(ocrResult);

      // Clean up uploaded file (only if it's a local file)
      if (req.files && req.files[0] && !req.files[0].path.startsWith("http")) {
        try {
          fs.unlinkSync(req.files[0].path);
        } catch (cleanupError) {
          console.error("File cleanup error:", cleanupError);
        }
      }

      res.json({
        success: true,
        data: receiptData,
        confidence: ocrResult.confidence,
        provider: ocrResult.provider,
      });
    } catch (error) {
      // Clean up uploaded file on error (only if it's a local file)
      if (req.files && req.files[0] && !req.files[0].path.startsWith("http")) {
        try {
          fs.unlinkSync(req.files[0].path);
        } catch (cleanupError) {
          console.error("File cleanup error:", cleanupError);
        }
      }

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
