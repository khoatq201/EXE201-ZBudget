import express from "express";
import * as aiAnalysisController from "../controllers/aiAnalysisController.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// AI Analysis Routes
router.post("/deep", aiAnalysisController.getDeepAnalysis);
router.post("/forecast", aiAnalysisController.getAIForecast);
router.get("/anomalies", aiAnalysisController.getAnomalies);
router.post("/recommendations", aiAnalysisController.getRecommendations);
router.get("/insights", aiAnalysisController.getQuickInsights);
router.get("/patterns", aiAnalysisController.getSpendingPatterns);
router.delete("/cache", aiAnalysisController.clearCache);

export default router;
