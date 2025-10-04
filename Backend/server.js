import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import dotenv from "dotenv";
import mongoose from "mongoose";
import { connectDB } from "./models/index.js";
import logger from "morgan";

// Routes
import authRoutes from "./routes/authRoutes.js";
import expenseRoutes from "./routes/expenseRoutes.js";
import dashboardRoutes from "./routes/dashboardRoutes.js";
import incomeRoutes from "./routes/incomeRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
// import userRoutes from './routes/users.js';
// import budgetRoutes from './routes/budgets.js';
// import challengeRoutes from './routes/challenges.js';
// import groupRoutes from './routes/groups.js';
// import notificationRoutes from './routes/notifications.js';
// import healthRoutes from './routes/health.js';

// Middleware
import { errorHandler } from "./middleware/errorHandler.js";
import { requestLogger } from "./middleware/logger.js";
import { responseLogger } from "./middleware/responseLogger.js";
import { authenticate } from "./middleware/auth.js";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Global server reference for graceful shutdown
let server = null;

// Trust proxy (for rate limiting behind reverse proxy)
app.set("trust proxy", 1);
app.use((req, res, next) => {
  req.startTime = Date.now();
  console.log(
    `🌐 DEBUG: Request started - ${req.method} ${req.path} at ${new Date().toISOString()}`
  );

  // Log when response finishes
  res.on("finish", () => {
    const duration = Date.now() - req.startTime;
    console.log(
      `🌐 DEBUG: Request completed - ${req.method} ${req.path} - ${res.statusCode} in ${duration}ms`
    );
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
  console.log(
    `📥 ${req.method} ${req.url} from origin: ${req.get("origin") || "no-origin"}`
  );

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
    console.log("🚀 Handling preflight OPTIONS request");
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
app.use("/api/reports", reportRoutes);

// Protected routes (will be added later)
// app.use('/api/users', authenticate, userRoutes);
// app.use('/api/budgets', authenticate, budgetRoutes);
// app.use('/api/challenges', authenticate, challengeRoutes);
// app.use('/api/groups', authenticate, groupRoutes);
// app.use('/api/notifications', authenticate, notificationRoutes);

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
    console.log(`⚠️ Shutdown already in progress, ignoring ${signal}`);
    return;
  }

  isShuttingDown = true;
  console.log(`\n📴 Nhận signal ${signal}. Đang shutdown gracefully...`);

  // Force close after 5 seconds to prevent hanging
  const forceShutdown = setTimeout(() => {
    console.error("⏰ Force shutdown sau 5 giây");
    process.exit(1);
  }, 5000);

  // Close HTTP server first
  if (server && server.listening) {
    server.close(async () => {
      console.log("🔌 HTTP server đã đóng");

      // Close database connections
      try {
        if (mongoose.connection.readyState !== 0) {
          await mongoose.connection.close();
          console.log("📊 MongoDB connection đã đóng");
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
    console.log("🔌 HTTP server không đang chạy");
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
    // Connect to database
    await connectDB();
    console.log("✅ Database connected successfully");

    // Start HTTP server
    server = app.listen(PORT, () => {
      console.log(`🚀 ZBudget API Server running on port ${PORT}`);
      console.log(`📍 API Base URL: http://localhost:${PORT}/api`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`📖 API Docs: http://localhost:${PORT}/api`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || "development"}`);

      if (process.env.NODE_ENV === "development") {
        console.log("\n🛠️  Development URLs:");
        console.log(`   Frontend: http://localhost:3001`);
        console.log(`   Flutter Web: http://localhost:8080`);
        console.log(`   Database Stats: npm run db:stats`);
        console.log(`   Database Health: npm run db:health\n`);
      }
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
console.log("🔧 Debug: import.meta.url:", import.meta.url);
console.log("🔧 Debug: process.argv[1]:", process.argv[1]);
console.log("🔧 Debug: file URL:", `file://${process.argv[1]}`);

if (import.meta.url === `file://${process.argv[1]}`) {
  console.log("✅ Starting server via import check...");
  startServer();
} else {
  console.log("⚠️ Import check failed, starting server anyway...");
  startServer();
}
