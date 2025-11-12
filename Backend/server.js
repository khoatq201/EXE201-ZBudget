// MUST BE FIRST - Import config to load environment variables
import config from "./config/env.js";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import mongoose from "mongoose";
import { connectDB } from "./models/index.js";
import logger from "morgan";
import sessionCleanupJob from "./services/SessionCleanupJob.js";
import notificationSchedulerJob from "./services/NotificationSchedulerJob.js";
// Import routes
import authRoutes from "./routes/authRoutes.js";
import expenseRoutes from "./routes/expenseRoutes.js";
import dashboardRoutes from "./routes/dashboardRoutes.js";
import incomeRoutes from "./routes/incomeRoutes.js";
import settingsRoutes from "./routes/settingsRoutes.js";
import uploadRoutes from "./routes/uploadRoutes.js";
import securityRoutes from "./routes/securityRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
import savingsRoutes from "./routes/savingsRoutes.js";
import budgetRoutes from "./routes/budgetRoutes.js";
import groupBudgetRoutes from "./routes/groupBudgetRoutes.js";
import ocrRoutes from "./routes/ocrRoutes.js";
import aiRoutes from "./routes/aiRoutes.js";
import aiAnalysisRoutes from "./routes/aiAnalysisRoutes.js";
// import userRoutes from './routes/users.js';
// import challengeRoutes from './routes/challenges.js';
// import groupRoutes from './routes/groups.js';
import notificationRoutes from "./routes/notificationRoutes.js";
// import healthRoutes from './routes/health.js';
// Middleware
import { errorHandler } from "./middleware/errorHandler.js";
import { requestLogger } from "./middleware/logger.js";
import { responseLogger } from "./middleware/responseLogger.js";
import { authenticate } from "./middleware/auth.js";
const app = express();
const PORT = process.env.PORT || 3000;
// Global server reference for graceful shutdown
let server = null;
// Trust proxy (for rate limiting behind reverse proxy)
app.set("trust proxy", 1);
app.use((req, res, next) => {
  req.startTime = Date.now();
  // Log when response finishes
  res.on("finish", () => {
    const duration = Date.now() - req.startTime;
  });
  next();
});
// Security middleware
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  })
);
// CORS configuration - more permissive for development
const corsOptions = {
  origin: true, // Allow all origins for development
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: [
    "Origin",
    "X-Requested-With",
    "Content-Type",
    "Accept",
    "Authorization",
    "X-API-Key",
  ],
  credentials: true,
  maxAge: 86400, // 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204,
};
app.use(cors(corsOptions));
app.use(logger("dev"));
// Add manual CORS headers for extra compatibility
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", req.get("origin") || "*");
  res.header("Access-Control-Allow-Credentials", "true");
  res.header(
    "Access-Control-Allow-Methods",
    "GET,PUT,POST,DELETE,OPTIONS,PATCH"
  );
  res.header(
    "Access-Control-Allow-Headers",
    "Origin,X-Requested-With,Content-Type,Accept,Authorization,X-API-Key"
  );
  if (req.method === "OPTIONS") {
    return res.status(204).send();
  }
  next();
});
// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: "Quá nhiều requests từ IP này, vui lòng thử lại sau.",
    retryAfter: "15 phút",
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for health checks
  skip: (req) => req.path === "/api/health",
});
app.use("/api/", limiter);
// Body parsing middleware
app.use(
  express.json({
    limit: process.env.MAX_JSON_SIZE || "10mb",
    strict: true,
  })
);
app.use(
  express.urlencoded({
    extended: true,
    limit: process.env.MAX_URLENCODED_SIZE || "10mb",
  })
);
// Simple console logging for every request (works better on Render)
app.use((req, res, next) => {
  const startTime = Date.now();
  const timestamp = new Date().toISOString();
  console.log(
    `[${timestamp}] 📥 ${req.method} ${req.originalUrl} - IP: ${
      req.ip || req.connection.remoteAddress
    }`
  );

  if (req.method !== "GET" && req.body && Object.keys(req.body).length > 0) {
    // Sanitize sensitive data for logging
    const body = { ...req.body };
    if (body.password) body.password = "***REDACTED***";
    if (body.token) body.token = "***REDACTED***";
    console.log(`Request body:`, JSON.stringify(body));
  }

  // Log response when it finishes
  res.on("finish", () => {
    const duration = Date.now() - startTime;
    const statusEmoji =
      res.statusCode >= 500 ? "❌" : res.statusCode >= 400 ? "⚠️" : "✅";
    console.log(
      `[${new Date().toISOString()}] 📤 ${statusEmoji} ${req.method} ${
        req.originalUrl
      } - Status: ${res.statusCode} - Time: ${duration}ms`
    );
  });

  next();
});

// Request and response logging middleware
app.use(requestLogger);
app.use(responseLogger);
// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "ZBudget API is running",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: "1.0.0",
  });
});
// API routes
app.use("/api/auth", authRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/income", incomeRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/security", securityRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/savings", savingsRoutes);
app.use("/api/budgets", budgetRoutes);
app.use("/api/group-budgets", groupBudgetRoutes);
app.use("/api/ocr", ocrRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/ai/analysis", aiAnalysisRoutes);
// Protected routes (will be added later)
// app.use('/api/users', authenticate, userRoutes);
// app.use('/api/challenges', authenticate, challengeRoutes);
// app.use('/api/groups', authenticate, groupRoutes);
app.use("/api/notifications", notificationRoutes);
// API documentation
app.get("/api", (req, res) => {
  res.json({
    name: "ZBudget API",
    version: "1.0.0",
    description: "Personal Finance Management API",
    endpoints: {
      auth: "/api/auth",
      expenses: "/api/expenses",
      dashboard: "/api/dashboard",
      income: "/api/income",
      reports: "/api/reports",
      savings: "/api/savings",
      ai: "/api/ai",
      aiAnalysis: "/api/ai/analysis",
      health: "/api/health",
    },
    todo_endpoints: {
      users: "/api/users",
      budgets: "/api/budgets",
      challenges: "/api/challenges",
      groups: "/api/groups",
      notifications: "/api/notifications",
    },
    documentation: "/api/docs",
    timestamp: new Date().toISOString(),
  });
});
// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    error: "Endpoint không tồn tại",
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString(),
  });
});
// Global error handler
app.use(errorHandler);
// Graceful shutdown flag to prevent multiple shutdowns
let isShuttingDown = false;
// Graceful shutdown
const gracefulShutdown = (signal) => {
  if (isShuttingDown) {
    return;
  }
  isShuttingDown = true;
  // Force close after 5 seconds to prevent hanging
  const forceShutdown = setTimeout(() => {
    console.error("⏰ Force shutdown sau 5 giây");
    process.exit(1);
  }, 5000);
  // Close HTTP server first
  if (server && server.listening) {
    server.close(async () => {
      // Close database connections
      try {
        if (mongoose.connection.readyState !== 0) {
          await mongoose.connection.close();
        }
        clearTimeout(forceShutdown);
        process.exit(0);
      } catch (error) {
        console.error("❌ Lỗi khi đóng database connection:", error);
        clearTimeout(forceShutdown);
        process.exit(1);
      }
    });
  } else {
    clearTimeout(forceShutdown);
    process.exit(0);
  }
};
// Signal handlers
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
// Unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  console.error("❌ Unhandled Rejection at:", promise, "reason:", reason);
  // Only shutdown if it's not already shutting down and not a connection close error
  if (
    !isShuttingDown &&
    !reason.message?.includes("Connection.prototype.close")
  ) {
    gracefulShutdown("Unhandled Rejection");
  }
});
// Uncaught exceptions
process.on("uncaughtException", (error) => {
  console.error("💥 Uncaught Exception thrown:", error);
  // Only shutdown if it's not already shutting down
  if (!isShuttingDown) {
    gracefulShutdown("Uncaught Exception");
  }
});
// Start server
async function startServer() {
  try {
    console.log("🌍 Environment:", process.env.NODE_ENV || "development");
    console.log("🔌 Connecting to database...");
    // Connect to database
    await connectDB();
    console.log("✅ Database connected successfully");

    // Start HTTP server
    server = app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
      console.log(
        `📍 Server URL: ${
          process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`
        }`
      );
      console.log(
        `🏥 Health check: ${
          process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`
        }/api/health`
      );
      // Start session cleanup job
      sessionCleanupJob.start();
      // Start notification scheduler job
      notificationSchedulerJob.start();
      console.log("✅ Background jobs started");

      if (process.env.NODE_ENV === "development") {
        console.log(`📝 API Documentation: http://localhost:${PORT}/api`);
      }

      console.log("🎉 Server is ready to accept requests!");
    });
    return server;
  } catch (error) {
    console.error("💥 Failed to start server:", error);
    process.exit(1);
  }
}
// Export app for testing
export default app;
// Start server if this file is run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  startServer();
} else {
  startServer();
}
