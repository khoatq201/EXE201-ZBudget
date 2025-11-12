import express from "express";
import {
  createFeedback,
  getAllFeedbacks,
  getFeedbackById,
  getMyFeedbacks,
  updateFeedbackStatus,
  addAdminResponse,
  deleteFeedback,
  getFeedbackStatistics,
} from "../controllers/feedbackController.js";
import { authenticate, authorizeRoles, optionalAuth } from "../middleware/auth.js";
import { catchAsync } from "../middleware/errorHandler.js";

const router = express.Router();

// Public routes - no authentication required
router.post("/", optionalAuth, catchAsync(createFeedback));
router.get("/all", catchAsync(getAllFeedbacks)); // Public: view all feedbacks
router.get("/stats", catchAsync(getFeedbackStatistics)); // Public: view stats

// Protected routes - require authentication
router.use(authenticate);

// User routes - get their own feedbacks
router.get("/my-feedbacks", catchAsync(getMyFeedbacks));
router.get("/:id", catchAsync(getFeedbackById));

router.patch(
  "/:id/status",
  authorizeRoles("admin"),
  catchAsync(updateFeedbackStatus)
);

router.patch(
  "/:id/respond",
  authorizeRoles("admin"),
  catchAsync(addAdminResponse)
);

router.delete(
  "/:id",
  authorizeRoles("admin"),
  catchAsync(deleteFeedback)
);

export default router;
