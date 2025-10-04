import express from "express";
import { validate } from "../middleware/validation.js";
import { settingsSchemas } from "../middleware/validation.js";
import { authenticate } from "../middleware/auth.js";
import { catchAsync } from "../middleware/errorHandler.js";
import {
  changePassword,
  getActiveSessions,
  terminateSession,
  terminateAllOtherSessions,
  setup2FA,
  enable2FA,
  disable2FA,
  verify2FA,
  getSecurityStats,
  getSecuritySettings,
} from "../controllers/securityController.js";

const router = express.Router();

// Apply authentication middleware to all routes
router.use(authenticate);

// Password management
router.put(
  "/change-password",
  validate(settingsSchemas.changePassword),
  catchAsync(changePassword)
);

// Session management
router.get("/sessions", catchAsync(getActiveSessions));
router.delete(
  "/sessions/:sessionId",
  validate(settingsSchemas.terminateSession),
  catchAsync(terminateSession)
);
router.delete("/sessions", catchAsync(terminateAllOtherSessions));

// Two-Factor Authentication
router.post("/setup-2fa", catchAsync(setup2FA));
router.post(
  "/enable-2fa",
  validate(settingsSchemas.verify2FA),
  catchAsync(enable2FA)
);
router.post(
  "/disable-2fa",
  validate(settingsSchemas.verify2FA),
  catchAsync(disable2FA)
);
router.post(
  "/verify-2fa",
  validate(settingsSchemas.verify2FA),
  catchAsync(verify2FA)
);

// Security settings and statistics
router.get("/settings", catchAsync(getSecuritySettings));
router.get("/stats", catchAsync(getSecurityStats));

export default router;
