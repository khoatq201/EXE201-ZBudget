import express from "express";
import { authenticate } from "../middleware/auth.js";
import {
  setup2FA,
  enable2FA,
  disable2FA,
  updateSecuritySettings,
  getSecuritySettings,
  changePassword,
  terminateSession,
  terminateAllSessions,
  getActiveSessions,
} from "../controllers/securityController.js";

const router = express.Router();

// All security routes require authentication
router.use(authenticate);

// Two-Factor Authentication routes
router.post("/2fa/setup", setup2FA);
router.post("/2fa/enable", enable2FA);
router.post("/2fa/disable", disable2FA);

// Password management
router.post("/change-password", changePassword);

// Security settings
router.get("/settings", getSecuritySettings);
router.put("/settings", updateSecuritySettings);

// Session management
router.get("/sessions", getActiveSessions);
router.delete("/sessions/:sessionId", terminateSession);
router.delete("/sessions", terminateAllSessions);

export default router;
