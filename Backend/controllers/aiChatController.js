import * as aiService from "../services/aiChatbotService.js";
import ChatSession from "../models/ChatSession.js";

/**
 * Start new chat session (lazy initialization)
 * POST /api/ai/chat/start
 * This doesn't create a session immediately, just returns a temporary session ID
 * Session will be created when user sends first message
 */
export async function startChatSession(req, res, next) {
  try {
    // Generate a temporary session ID for frontend
    const tempSessionId = `temp_${Date.now()}_${Math.random()
      .toString(36)
      .substr(2, 9)}`;

    res.json({
      success: true,
      session: {
        sessionId: tempSessionId,
        isTemporary: true,
        message: "Session will be created when you send your first message",
      },
    });
  } catch (error) {
    console.error("Error starting chat session:", error);
    next(error);
  }
}

/**
 * Send message with SSE streaming
 * POST /api/ai/chat/message
 */
export async function sendChatMessage(req, res, next) {
  try {
    const { sessionId, message } = req.body;

    if (!sessionId || !message) {
      return res.status(400).json({
        success: false,
        error: "SessionId and message are required",
      });
    }

    // Check if this is a temporary session (starts with 'temp_')
    let actualSessionId = sessionId;
    let isNewSession = false;

    if (sessionId.startsWith("temp_")) {
      // Create a real session for the first message
      const session = await aiService.createChatSession(req.userId);
      actualSessionId = session.sessionId;
      isNewSession = true;
      console.log(
        `🆕 Created new session ${actualSessionId} for first message`
      );
    } else {
      // Check if session exists
      const existingSession = await ChatSession.findOne({
        sessionId: actualSessionId,
        userId: req.userId,
      });

      if (!existingSession) {
        return res.status(404).json({
          success: false,
          error: "Session not found",
        });
      }
    }

    // Set SSE headers
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Cache-Control");

    // Send initial connection message
    res.write(
      'data: {"type":"connected","message":"Connected to AI chat"}\n\n'
    );

    // Send session info if it's a new session
    if (isNewSession) {
      res.write(
        `data: ${JSON.stringify({
          type: "session_created",
          sessionId: actualSessionId,
          message: "Chat session created successfully",
        })}\n\n`
      );
    }

    try {
      // Get streaming response
      const stream = aiService.sendMessageStream(
        actualSessionId,
        message,
        req.userId
      );

      let fullResponse = "";

      for await (const chunk of stream) {
        if (chunk) {
          fullResponse += chunk;
          // Send chunk to client
          res.write(
            `data: ${JSON.stringify({
              type: "chunk",
              content: chunk,
              fullResponse: fullResponse,
            })}\n\n`
          );
        }
      }

      // Send completion message
      res.write('data: {"type":"complete","message":"Response completed"}\n\n');
    } catch (streamError) {
      console.error("Streaming error:", streamError);
      res.write(
        `data: ${JSON.stringify({
          type: "error",
          message: streamError.message,
        })}\n\n`
      );
    }

    // End the stream
    res.write("data: [DONE]\n\n");
    res.end();
  } catch (error) {
    console.error("Error in sendChatMessage:", error);

    // If headers not sent yet, send error response
    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    } else {
      // If streaming already started, send error via SSE
      res.write(
        `data: ${JSON.stringify({
          type: "error",
          message: error.message,
        })}\n\n`
      );
      res.end();
    }
  }
}

/**
 * Get chat history
 * GET /api/ai/chat/history/:sessionId
 */
export async function getChatHistory(req, res, next) {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "SessionId is required",
      });
    }

    const messages = await aiService.getChatHistory(sessionId, req.userId);

    res.json({
      success: true,
      messages: messages,
      sessionId: sessionId,
    });
  } catch (error) {
    console.error("Error getting chat history:", error);
    next(error);
  }
}

/**
 * End chat session
 * POST /api/ai/chat/end/:sessionId
 */
export async function endChatSession(req, res, next) {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "SessionId is required",
      });
    }

    await aiService.endChatSession(sessionId, req.userId);

    res.json({
      success: true,
      message: "Chat session ended successfully",
    });
  } catch (error) {
    console.error("Error ending chat session:", error);
    next(error);
  }
}

/**
 * Get user's active sessions
 * GET /api/ai/chat/sessions
 */
export async function getUserSessions(req, res, next) {
  try {
    const sessions = await aiService.getUserActiveSessions(req.userId);

    res.json({
      success: true,
      sessions: sessions.map((session) => ({
        sessionId: session.sessionId,
        createdAt: session.createdAt,
        lastMessageAt: session.lastMessageAt,
        messageCount: session.messageCount,
        totalTokensUsed: session.totalTokensUsed,
        isActive: session.isActive,
      })),
    });
  } catch (error) {
    console.error("Error getting user sessions:", error);
    next(error);
  }
}

/**
 * Get session details
 * GET /api/ai/chat/session/:sessionId
 */
export async function getSessionDetails(req, res, next) {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "SessionId is required",
      });
    }

    const session = await ChatSession.findOne({
      sessionId,
      userId: req.userId,
    });

    if (!session) {
      return res.status(404).json({
        success: false,
        error: "Session not found",
      });
    }

    res.json({
      success: true,
      session: {
        sessionId: session.sessionId,
        createdAt: session.createdAt,
        lastMessageAt: session.lastMessageAt,
        messageCount: session.messageCount,
        totalTokensUsed: session.totalTokensUsed,
        isActive: session.isActive,
        messages: session.messages,
      },
    });
  } catch (error) {
    console.error("Error getting session details:", error);
    next(error);
  }
}

/**
 * Health check for AI service
 * GET /api/ai/health
 */
export async function aiHealthCheck(req, res, next) {
  try {
    // Check if AI features are enabled
    const aiEnabled = process.env.AI_FEATURES_ENABLED === "true";

    res.json({
      success: true,
      aiEnabled: aiEnabled,
      timestamp: new Date().toISOString(),
      message: aiEnabled
        ? "AI features are enabled"
        : "AI features are disabled",
    });
  } catch (error) {
    console.error("Error in AI health check:", error);
    next(error);
  }
}
