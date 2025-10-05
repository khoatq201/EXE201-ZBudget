// config/env.js - Load environment variables FIRST
import dotenv from "dotenv";

// Load .env file immediately
const result = dotenv.config();

if (result.error) {
  console.error("❌ Error loading .env file:", result.error);
} else {
  console.log("✅ Environment variables loaded successfully");
}

// Export all env vars for easy access
export const config = {
  // Database
  MONGODB_URI: process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget",

  // Server
  PORT: process.env.PORT || 3000,
  NODE_ENV: process.env.NODE_ENV || "development",

  // JWT
  JWT_SECRET: process.env.JWT_SECRET,
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || "7d",

  // Cloudinary - THIS IS THE KEY PART
  CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME,
  CLOUDINARY_API_KEY: process.env.CLOUDINARY_API_KEY,
  CLOUDINARY_API_SECRET: process.env.CLOUDINARY_API_SECRET,
  USE_CLOUDINARY: process.env.USE_CLOUDINARY === "true",

  // Other configs
  CORS_ORIGINS: process.env.CORS_ORIGINS,
  EMAIL_USER: process.env.EMAIL_USER,
  EMAIL_PASS: process.env.EMAIL_PASS,
};

// Debug Cloudinary config
console.log("🔧 Cloudinary Config Loaded:", {
  cloud_name: config.CLOUDINARY_CLOUD_NAME,
  api_key: config.CLOUDINARY_API_KEY ? "***exists***" : "missing",
  api_secret: config.CLOUDINARY_API_SECRET ? "***exists***" : "missing",
  use_cloudinary: config.USE_CLOUDINARY,
});

export default config;
