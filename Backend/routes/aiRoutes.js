import express from "express";
import { authenticate } from "../middleware/auth.js";
import * as aiChatController from "../controllers/aiChatController.js";

const router = express.Router();

// All routes require authentication (NO Premium check - open to all users)
router.use(authenticate);

// Health check endpoint (no auth required for basic health check)
router.get("/health", aiChatController.aiHealthCheck);

// Chat session management
router.post("/chat/start", aiChatController.startChatSession);
router.get("/chat/sessions", aiChatController.getUserSessions);
router.get("/chat/session/:sessionId", aiChatController.getSessionDetails);

// Chat messaging with SSE streaming
router.post("/chat/message", aiChatController.sendChatMessage);

// Chat history and session management
router.get("/chat/history/:sessionId", aiChatController.getChatHistory);
router.post("/chat/end/:sessionId", aiChatController.endChatSession);

export default router;
