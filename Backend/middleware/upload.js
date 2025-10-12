import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import { v2 as cloudinary } from "cloudinary";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { ValidationError } from "./errorHandler.js";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Configure Cloudinary - moved to function to ensure env vars are loaded
let cloudinaryConfigured = false;
const configureCloudinary = () => {
  if (!cloudinaryConfigured) {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME || "zbudget",
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
      secure: true,
    });
    cloudinaryConfigured = true;
  }
};
// Local storage configuration (fallback)
const localStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, "../../uploads");
    // Create upload directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    // Create subdirectories based on file type
    let subDir = "";
    if (file.fieldname === "avatar") {
      subDir = "avatars";
    } else if (file.fieldname === "receipt") {
      subDir = "receipts";
    } else if (file.fieldname === "groupAvatar") {
      subDir = "groups";
    } else {
      subDir = "misc";
    }
    const finalDir = path.join(uploadDir, subDir);
    if (!fs.existsSync(finalDir)) {
      fs.mkdirSync(finalDir, { recursive: true });
    }
    cb(null, finalDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    const name = file.fieldname + "-" + uniqueSuffix + ext;
    cb(null, name);
  },
});
// Cloudinary storage configuration
const getCloudinaryStorage = () => {
  configureCloudinary(); // Ensure cloudinary is configured first
  return new CloudinaryStorage({
    cloudinary: cloudinary,
    params: async (req, file) => {
      let folder = "zbudget";
      let allowedFormats = ["jpeg", "jpg", "png", "webp"];
      // Configure based on file type
      if (file.fieldname === "avatar") {
        folder = "zbudget/avatars";
        allowedFormats = ["jpeg", "jpg", "png", "webp"];
      } else if (file.fieldname === "receipt") {
        folder = "zbudget/receipts";
        allowedFormats = ["jpeg", "jpg", "png", "webp", "pdf"];
      } else if (file.fieldname === "groupAvatar") {
        folder = "zbudget/groups";
        allowedFormats = ["jpeg", "jpg", "png", "webp"];
      }
      return {
        folder: folder,
        allowed_formats: allowedFormats,
        public_id: `${file.fieldname}-${Date.now()}-${Math.round(Math.random() * 1e9)}`,
        resource_type: "auto", // Automatically detect file type
        transformation: [
          {
            width: file.fieldname === "avatar" ? 300 : 800,
            height: file.fieldname === "avatar" ? 300 : 800,
            crop: file.fieldname === "avatar" ? "fill" : "limit",
            quality: "auto:good",
            fetch_format: "auto",
          },
        ],
      };
    },
  });
};
// File filter function
const fileFilter = (req, file, cb) => {
  // Debug: Log the actual MIME type received
  // Allowed mime types
  const allowedMimes = {
    "image/jpeg": true,
    "image/jpg": true,
    "image/png": true,
    "image/webp": true,
    "image/gif": true, // Add GIF support
    "image/bmp": true, // Add BMP support
    "application/pdf": true,
  };
  // Check if file type is allowed
  if (allowedMimes[file.mimetype]) {
    cb(null, true);
  } else {
    cb(
      new ValidationError(
        `Loại file không được hỗ trợ. Chỉ chấp nhận: ${Object.keys(allowedMimes).join(", ")}`
      ),
      false
    );
  }
};
// Size limits for different file types
const limits = {
  fileSize: 10 * 1024 * 1024, // 10MB default
  files: 5, // Maximum 5 files per request
  fields: 10, // Maximum 10 non-file fields
};
// Create multer instance with appropriate storage
const getStorage = () => {
  configureCloudinary(); // Ensure env vars are loaded
  return process.env.USE_CLOUDINARY === "true"
    ? getCloudinaryStorage()
    : localStorage;
};
const upload = multer({
  storage: getStorage(),
  fileFilter: fileFilter,
  limits: limits,
  onError: function (err, next) {
    console.error("Multer error:", err);
    next(new ValidationError("Lỗi tải file: " + err.message));
  },
});
// Middleware for different file upload scenarios
export const uploadMiddleware = {
  // Single avatar upload
  avatar: upload.single("avatar"),
  // Single receipt upload
  receipt: upload.single("receipt"),
  // Single group avatar upload
  groupAvatar: upload.single("groupAvatar"),
  // Multiple receipts (max 5)
  receipts: upload.array("receipts", 5),
  // Mixed upload (avatar + receipts)
  mixed: upload.fields([
    { name: "avatar", maxCount: 1 },
    { name: "receipts", maxCount: 5 },
  ]),
  // Any single file
  any: upload.any(),
  // No file upload (just form data)
  none: upload.none(),
};
// Custom file size limits for specific use cases
export const createUploadMiddleware = (options = {}) => {
  const customLimits = {
    ...limits,
    ...options.limits,
  };
  const customStorage =
    options.useCloudinary !== false && process.env.USE_CLOUDINARY === "true"
      ? cloudinaryStorage
      : localStorage;
  return multer({
    storage: customStorage,
    fileFilter: options.fileFilter || fileFilter,
    limits: customLimits,
    onError:
      options.onError ||
      function (err, next) {
        console.error("Upload error:", err);
        next(new ValidationError("Lỗi tải file: " + err.message));
      },
  });
};
// Image processing middleware (if not using Cloudinary)
export const processImage = async (req, res, next) => {
  if (!req.file || process.env.USE_CLOUDINARY === "true") {
    return next();
  }
  try {
    // Only process images, not PDFs
    if (!req.file.mimetype.startsWith("image/")) {
      return next();
    }
    // Here you could add image processing logic using sharp or similar
    // For now, we'll just pass through
    next();
  } catch (error) {
    next(new ValidationError("Lỗi xử lý ảnh: " + error.message));
  }
};
// Clean up temporary files (for local storage)
export const cleanupTempFiles = (req, res, next) => {
  const cleanup = () => {
    if (req.file && !process.env.USE_CLOUDINARY) {
      fs.unlink(req.file.path, (err) => {
        if (err) console.error("Error cleaning up temp file:", err);
      });
    }
    if (req.files && !process.env.USE_CLOUDINARY) {
      const files = Array.isArray(req.files)
        ? req.files
        : Object.values(req.files).flat();
      files.forEach((file) => {
        fs.unlink(file.path, (err) => {
          if (err) console.error("Error cleaning up temp file:", err);
        });
      });
    }
  };
  // Cleanup on response finish (success or error)
  res.on("finish", cleanup);
  res.on("close", cleanup);
  next();
};
// Delete file from storage (both local and cloudinary)
export const deleteFile = async (fileUrl) => {
  try {
    if (
      process.env.USE_CLOUDINARY === "true" &&
      fileUrl.includes("cloudinary.com")
    ) {
      // Extract public_id from Cloudinary URL
      const urlParts = fileUrl.split("/");
      const filename = urlParts[urlParts.length - 1];
      const publicId = filename.split(".")[0];
      await cloudinary.uploader.destroy(publicId);
    } else if (!fileUrl.includes("cloudinary.com")) {
      // Local file deletion
      const filename = path.basename(fileUrl);
      const filePath = path.join(__dirname, "../../uploads", filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }
  } catch (error) {
    console.error("Error deleting file:", error);
  }
};
// Get file URL (local or cloudinary)
export const getFileUrl = (file) => {
  if (process.env.USE_CLOUDINARY === "true") {
    return file.path; // Cloudinary returns full URL in path
  } else {
    // For local files, construct URL
    const baseUrl = process.env.BASE_URL || "http://localhost:3000";
    return `${baseUrl}/uploads/${file.filename}`;
  }
};
// Validate file size before upload
export const validateFileSize = (maxSize) => (req, res, next) => {
  if (req.file && req.file.size > maxSize) {
    throw new ValidationError(
      `File quá lớn. Kích thước tối đa: ${maxSize / (1024 * 1024)}MB`
    );
  }
  if (req.files) {
    const files = Array.isArray(req.files)
      ? req.files
      : Object.values(req.files).flat();
    for (const file of files) {
      if (file.size > maxSize) {
        throw new ValidationError(
          `File quá lớn. Kích thước tối đa: ${maxSize / (1024 * 1024)}MB`
        );
      }
    }
  }
  next();
};
// Validate image dimensions (requires sharp for local files)
export const validateImageDimensions =
  (maxWidth, maxHeight) => async (req, res, next) => {
    if (!req.file || !req.file.mimetype.startsWith("image/")) {
      return next();
    }
    // Skip validation for Cloudinary as it handles transformation
    if (process.env.USE_CLOUDINARY === "true") {
      return next();
    }
    try {
      // Here you would use sharp or similar to get image dimensions
      // For now, we'll skip this validation
      next();
    } catch (error) {
      next(
        new ValidationError("Lỗi kiểm tra kích thước ảnh: " + error.message)
      );
    }
  };
// Export default upload instance
export default uploadMiddleware;