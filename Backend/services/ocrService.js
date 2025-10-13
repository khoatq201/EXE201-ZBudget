import { GoogleGenerativeAI } from "@google/generative-ai";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { config } from "../config/env.js";
import fetch from "node-fetch";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const genAI = new GoogleGenerativeAI(
  config.GEMINI_API_KEY || "AIzaSyCKmDwUjGxdtVE6vRUT41oh5CeDK9PBHAA"
);

class OCRService {
  constructor() {
    this.model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });
  }

  async extractTextFromImage(imagePath) {
    try {
      let imageBuffer;
      let mimeType;

      // Check if it's a Cloudinary URL or local file path
      if (imagePath.startsWith("http")) {
        // It's a Cloudinary URL, download the image
        const response = await fetch(imagePath);
        if (!response.ok) {
          throw new Error(`Failed to download image: ${response.statusText}`);
        }
        imageBuffer = Buffer.from(await response.arrayBuffer());
        mimeType = "image/jpeg"; // Cloudinary URLs are typically JPEG
      } else {
        // It's a local file path
        imageBuffer = fs.readFileSync(imagePath);
        mimeType = this.getMimeType(imagePath);
      }

      // Create prompt for Vietnamese receipt processing
      const prompt = `
        Phân tích hóa đơn tiếng Việt và trích xuất thông tin sau:
        1. Số tiền (amount) - chỉ số tiền cuối cùng phải thanh toán
        2. Tên cửa hàng (storeName) 
        3. Mô tả sản phẩm (description) - tóm tắt các món đã mua
        4. Danh mục (category) - chọn từ: food, shopping, transport, entertainment, health, education, other
        5. Ngày tháng (date) - định dạng YYYY-MM-DD
        6. Danh sách sản phẩm (items) - array các sản phẩm đã mua
        
        Trả về kết quả dưới dạng JSON với format:
        {
          "amount": số_tiền,
          "storeName": "tên_cửa_hàng",
          "description": "mô_tả_ngắn_gọn",
          "category": "danh_mục",
          "date": "YYYY-MM-DD",
          "items": ["sản_phẩm_1", "sản_phẩm_2"],
          "rawText": "toàn_bộ_text_gốc"
        }
        
        Chỉ trả về JSON, không có text khác.
      `;

      // Generate content with image
      const result = await this.model.generateContent([
        prompt,
        {
          inlineData: {
            data: imageBuffer.toString("base64"),
            mimeType: mimeType,
          },
        },
      ]);

      const response = await result.response;
      const text = response.text();

      // Parse JSON response
      try {
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const jsonData = JSON.parse(jsonMatch[0]);
          return {
            success: true,
            data: jsonData,
            confidence: 0.9, // Gemini AI has high confidence
            provider: "Gemini AI",
          };
        } else {
          throw new Error("Không tìm thấy JSON trong response");
        }
      } catch (parseError) {
        return {
          success: false,
          error: "Không thể parse kết quả từ AI",
          rawText: text,
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message || "Lỗi xử lý ảnh",
      };
    }
  }

  processReceiptData(ocrData) {
    try {
      const data = ocrData.data;

      // If data is already parsed JSON object, use it directly
      if (typeof data === "object" && data.amount) {
        return {
          amount: data.amount,
          description: data.description || "",
          storeName: data.storeName || "",
          category: data.category || "other",
          date: data.date ? new Date(data.date) : new Date(),
          rawText: JSON.stringify(data),
          confidence: ocrData.confidence || 0.9,
          provider: ocrData.provider || "Gemini AI",
        };
      }

      // Extract amount with Vietnamese patterns
      const amount = this.extractAmount(data.amount || data.rawText || "");

      // Extract store name
      const storeName = this.extractStoreName(
        data.storeName || data.rawText || ""
      );

      // Determine category
      const category = this.determineCategory(
        storeName,
        data.description || ""
      );

      // Parse date
      const date = this.parseDate(data.date || new Date().toISOString());

      return {
        amount: amount,
        description: data.description || "Chi tiêu từ hóa đơn",
        storeName: storeName,
        category: category,
        date: date,
        items: data.items || [],
        rawText: data.rawText || "",
      };
    } catch (error) {
      return {
        amount: 0,
        description: "Không thể phân tích hóa đơn",
        storeName: "",
        category: "other",
        date: new Date(),
        items: [],
        rawText: "",
      };
    }
  }

  getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const mimeTypes = {
      ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg",
      ".png": "image/png",
      ".gif": "image/gif",
      ".webp": "image/webp",
    };
    return mimeTypes[ext] || "image/jpeg";
  }

  extractAmount(text) {
    // Vietnamese amount patterns
    const patterns = [
      // Pattern: Phải thanh toán: 40.100
      /(?:Phải thanh toán|Phai thanh toan|PHẢI THANH TOÁN)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)/i,
      // Pattern: Tiền chuyển khoản: 40.100
      /(?:Tiền chuyển khoản|Tien chuyen khoan|TIỀN CHUYỂN KHOẢN)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)/i,
      // Pattern: Tổng cộng: 40.100
      /(?:Tổng cộng|Tong cong|TỔNG CỘNG)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)/i,
      // Pattern: Thành tiền: 40.100
      /(?:Thành tiền|Thanh tien|THÀNH TIỀN)\s*:?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)/i,
      // General pattern for large numbers
      /(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:VND|đ|dong)/i,
    ];

    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) {
        const amountStr = match[1].replace(/[.,]/g, "");
        const amount = parseInt(amountStr);
        if (amount > 0) {
          return amount;
        }
      }
    }

    return 0;
  }

  extractStoreName(text) {
    const lines = text.split("\n").filter((line) => line.trim().length > 0);
    if (lines.length === 0) return "";

    // Vietnamese store keywords
    const storeKeywords = [
      "BÁCH HÓA XANH",
      "Bach Hoa Xanh",
      "COOPMART",
      "Big C",
      "LOTTE",
      "VINCOM",
      "AEON",
      "CIRCLE K",
      "7-ELEVEN",
      "FAMILYMART",
      "MINISTOP",
    ];

    // Look for store names in first few lines
    for (let i = 0; i < Math.min(3, lines.length); i++) {
      const line = lines[i].trim().toUpperCase();
      for (const keyword of storeKeywords) {
        if (line.includes(keyword.toUpperCase())) {
          return lines[i].trim();
        }
      }
    }

    // Fallback to first non-empty line
    return lines[0] || "";
  }

  determineCategory(storeName, description) {
    const storeLower = storeName.toLowerCase();
    const descLower = description.toLowerCase();

    const categoryKeywords = {
      food: ["nhà hàng", "quán", "cafe", "restaurant", "food", "ăn", "uống"],
      shopping: ["siêu thị", "cửa hàng", "shop", "mall", "shopping"],
      transport: ["xe", "taxi", "grab", "uber", "xăng", "fuel"],
      health: ["bệnh viện", "phòng khám", "thuốc", "medical", "health"],
      education: ["trường", "học", "education", "school"],
      entertainment: ["cinema", "game", "giải trí", "entertainment"],
    };

    for (const [category, keywords] of Object.entries(categoryKeywords)) {
      for (const keyword of keywords) {
        if (storeLower.includes(keyword) || descLower.includes(keyword)) {
          return category;
        }
      }
    }

    return "other";
  }

  parseDate(dateStr) {
    try {
      if (dateStr) {
        return new Date(dateStr);
      }
    } catch (error) {
      return new Date();
    }
    return new Date();
  }
}

export default new OCRService();
