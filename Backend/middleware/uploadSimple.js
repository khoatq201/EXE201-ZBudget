import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import { v2 as cloudinary } from "cloudinary";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import config from "../config/env.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Upload middleware that uses pre-loaded config
export const uploadAvatar = (req, res, next) => {
  console.log("🔧 Upload using config:", {
    cloud_name: config.CLOUDINARY_CLOUD_NAME,
    use_cloudinary: config.USE_CLOUDINARY,
  });

  // Configure Cloudinary with loaded config
  cloudinary.config({
    cloud_name: config.CLOUDINARY_CLOUD_NAME,
    api_key: config.CLOUDINARY_API_KEY,
    api_secret: config.CLOUDINARY_API_SECRET,
    secure: true,
  });

  // Use Cloudinary if enabled, otherwise local
  const storage = config.USE_CLOUDINARY
    ? new CloudinaryStorage({
        cloudinary: cloudinary,
        params: {
          folder: "zbudget/avatars",
          allowed_formats: ["jpeg", "jpg", "png", "webp"],
          public_id: (req, file) =>
            `avatar-${Date.now()}-${Math.round(Math.random() * 1e9)}`,
          transformation: [
            {
              width: 300,
              height: 300,
              crop: "fill",
              quality: "auto:good",
            },
          ],
        },
      })
    : multer.diskStorage({
        destination: (req, file, cb) => {
          const uploadDir = path.join(__dirname, "../../uploads/avatars");
          if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
          }
          cb(null, uploadDir);
        },
        filename: (req, file, cb) => {
          const uniqueSuffix =
            Date.now() + "-" + Math.round(Math.random() * 1e9);
          const ext = path.extname(file.originalname);
          cb(null, `avatar-${uniqueSuffix}${ext}`);
        },
      });

  console.log(
    "📦 Using storage:",
    config.USE_CLOUDINARY ? "Cloudinary" : "Local"
  );

  const upload = multer({
    storage,
    fileFilter: (req, file, cb) => {
      const allowedMimes = {
        "image/jpeg": true,
        "image/jpg": true,
        "image/png": true,
        "image/webp": true,
      };

      if (allowedMimes[file.mimetype]) {
        console.log("✅ File type", file.mimetype, "is allowed");
        cb(null, true);
      } else {
        console.log("❌ File type", file.mimetype, "is not allowed");
        cb(new Error(`File type ${file.mimetype} is not allowed`), false);
      }
    },
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB
    },
  });

  // Use multer single upload
  upload.single("avatar")(req, res, next);
};
