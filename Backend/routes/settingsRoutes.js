import express from "express";
import {
  getSettings,
  updateSettings,
  updateCurrencySettings,
  getNotificationSettings,
  updateNotificationSettings,
  updateNotificationTypeSettings,
  toggleAllNotifications,
  updateSecuritySettings,
  updateThemeSettings,
  updateLanguageSettings,
  resetSettings,
  getProfile,
  updateProfile,
  updateAvatar,
  getStats,
  updateStats,
  calculateStats,
} from "../controllers/settingsController.js";
import { authenticate } from "../middleware/auth.js";
import { catchAsync } from "../middleware/errorHandler.js";
import { validate } from "../middleware/validation.js";
import { settingsSchemas } from "../middleware/validation.js";

const router = express.Router();

// All settings routes require authentication
router.use(authenticate);

// Settings routes
router.get("/", catchAsync(getSettings));
router.put(
  "/",
  validate(settingsSchemas.updateSettings),
  catchAsync(updateSettings)
);

// Specific settings routes
router.put(
  "/currency",
  validate(settingsSchemas.updateCurrency),
  catchAsync(updateCurrencySettings)
);
// Notification settings routes
router.get("/notifications", catchAsync(getNotificationSettings));
router.put(
  "/notifications",
  validate(settingsSchemas.updateNotifications),
  catchAsync(updateNotificationSettings)
);
router.put("/notifications/:type", catchAsync(updateNotificationTypeSettings));
router.put("/notifications/toggle-all", catchAsync(toggleAllNotifications));
router.put(
  "/security",
  validate(settingsSchemas.updateSecurity),
  catchAsync(updateSecuritySettings)
);
router.put(
  "/theme",
  validate(settingsSchemas.updateTheme),
  catchAsync(updateThemeSettings)
);
router.put(
  "/language",
  validate(settingsSchemas.updateLanguage),
  catchAsync(updateLanguageSettings)
);

// Reset settings
router.post("/reset", catchAsync(resetSettings));

// Profile routes
router.get("/profile", catchAsync(getProfile));
router.put(
  "/profile",
  validate(settingsSchemas.updateProfile),
  catchAsync(updateProfile)
);
router.put(
  "/profile/avatar",
  validate(settingsSchemas.updateAvatar),
  catchAsync(updateAvatar)
);

// Stats routes
router.get("/profile/stats", catchAsync(getStats));
router.put(
  "/profile/stats",
  validate(settingsSchemas.updateStats),
  catchAsync(updateStats)
);
router.post("/profile/calculate-stats", catchAsync(calculateStats));

export default router;
