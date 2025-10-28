// config/env.js - Load environment variables FIRST
import dotenv from "dotenv";
// Load .env file immediately
const result = dotenv.config();
if (result.error) {
  console.error("❌ Error loading .env file:", result.error);
} else {
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
  // Email config - Old Gmail SMTP (kept for reference)
  EMAIL_USER: process.env.EMAIL_USER,
  EMAIL_PASS: process.env.EMAIL_PASS,
  // Brevo Email Service (free tier, no domain verification required)
  BREVO_API_KEY: process.env.BREVO_API_KEY,
  BREVO_FROM_EMAIL: process.env.BREVO_FROM_EMAIL,
  // Gemini AI OCR
  GEMINI_API_KEY: process.env.GEMINI_API_KEY,
  // Groq AI Configuration
  GROQ_API_KEY: process.env.GROQ_API_KEY,
  GROQ_MODEL: process.env.GROQ_MODEL || "llama-3.3-70b-versatile",
  AI_FEATURES_ENABLED: process.env.AI_FEATURES_ENABLED === "true",
  // AI Analysis Config
  AI_ANALYSIS_CACHE_TTL: process.env.AI_ANALYSIS_CACHE_TTL || 1800, // 30 min
  PROPHET_ENABLED: process.env.PROPHET_ENABLED !== "false", // true by default
  MAX_FORECAST_MONTHS: 12,
  ANOMALY_THRESHOLD: 2.0, // 2 standard deviations
};
// Debug Cloudinary config
export default config;
