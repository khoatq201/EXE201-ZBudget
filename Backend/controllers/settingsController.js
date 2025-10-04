import User from "../models/User.js";
import { successResponse } from "../utils/responseHelpers.js";
import { NotFoundError, BadRequestError } from "../middleware/errorHandler.js";
import { catchAsync } from "../middleware/errorHandler.js";

/**
 * @desc    Lấy cài đặt người dùng
 * @route   GET /api/settings
 * @access  Private
 */
export const getSettings = async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId).select("settings");

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  return successResponse(
    res,
    { settings: user.settings },
    "Lấy cài đặt thành công"
  );
};

/**
 * @desc    Cập nhật tất cả settings
 * @route   PUT /api/settings
 * @access  Private
 */
export const updateSettings = async (req, res) => {
  const userId = req.userId;
  const { settings } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Update settings with merge to preserve existing data
  user.settings = {
    ...user.settings,
    ...settings,
  };

  await user.save();

  return successResponse(
    res,
    { settings: user.settings },
    "Cập nhật cài đặt thành công"
  );
};

/**
 * @desc    Cập nhật cài đặt tiền tệ
 * @route   PUT /api/settings/currency
 * @access  Private
 */
export const updateCurrencySettings = async (req, res) => {
  const userId = req.userId;
  const { currency } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  user.settings.currency = {
    ...user.settings.currency,
    ...currency,
  };

  await user.save();

  res.json(
    successResponse("Cập nhật cài đặt tiền tệ thành công", {
      currency: user.settings.currency,
    })
  );
};

/**
 * @desc    Lấy cài đặt thông báo chi tiết
 * @route   GET /api/settings/notifications
 * @access  Private
 */
export const getNotificationSettings = async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId).select("settings.notifications");

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Ensure default notification settings exist
  const defaultNotificationTypes = [
    "budget",
    "expense",
    "income",
    "challenge",
    "reminder",
    "achievement",
    "security",
    "system",
    "marketing",
  ];

  if (
    !user.settings.notifications.notificationSettings ||
    user.settings.notifications.notificationSettings.length === 0
  ) {
    user.settings.notifications.notificationSettings =
      defaultNotificationTypes.map((type) => ({
        type,
        isEnabled: true,
        showBadge: true,
        playSound: type !== "expense", // Expense notifications don't play sound by default
        vibrate: type === "expense" || type === "income", // Only expense and income vibrate
        frequency: ["budget", "challenge"].includes(type)
          ? "daily"
          : "immediately",
        scheduledTime: ["budget", "challenge"].includes(type)
          ? type === "budget"
            ? "20:00"
            : "09:00"
          : null,
      }));
    await user.save();
  }

  return successResponse(
    res,
    { notificationSettings: user.settings.notifications },
    "Lấy cài đặt thông báo thành công"
  );
};

/**
 * @desc    Cập nhật cài đặt thông báo
 * @route   PUT /api/settings/notifications
 * @access  Private
 */
export const updateNotificationSettings = async (req, res) => {
  const userId = req.userId;
  const { notifications } = req.body;

  console.log("🔧 DEBUG: updateNotificationSettings called");
  console.log("🔧 DEBUG: userId:", userId);
  console.log("🔧 DEBUG: req.body:", JSON.stringify(req.body, null, 2));
  console.log(
    "🔧 DEBUG: notifications:",
    JSON.stringify(notifications, null, 2)
  );

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Deep merge notification settings
  user.settings.notifications = {
    ...user.settings.notifications,
    ...notifications,
  };

  console.log(
    "🔧 DEBUG: Final notifications to save:",
    JSON.stringify(user.settings.notifications, null, 2)
  );

  await user.save();

  return successResponse(
    res,
    { notifications: user.settings.notifications },
    "Cập nhật cài đặt thông báo thành công"
  );
};

/**
 * @desc    Cập nhật cài đặt cho một loại thông báo cụ thể
 * @route   PUT /api/settings/notifications/:type
 * @access  Private
 */
export const updateNotificationTypeSettings = async (req, res) => {
  const userId = req.userId;
  const { type } = req.params;
  const updateData = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  const validTypes = [
    "budget",
    "expense",
    "income",
    "challenge",
    "reminder",
    "achievement",
    "security",
    "system",
    "marketing",
  ];
  if (!validTypes.includes(type)) {
    throw new BadRequestError("Loại thông báo không hợp lệ");
  }

  // Find and update the specific notification type
  const notificationSettings =
    user.settings.notifications.notificationSettings || [];
  const existingIndex = notificationSettings.findIndex(
    (setting) => setting.type === type
  );

  if (existingIndex >= 0) {
    // Update existing setting
    notificationSettings[existingIndex] = {
      ...notificationSettings[existingIndex],
      ...updateData,
      type, // Ensure type doesn't change
    };
  } else {
    // Add new setting
    notificationSettings.push({
      type,
      isEnabled: true,
      showBadge: true,
      playSound: true,
      vibrate: true,
      frequency: "immediately",
      scheduledTime: null,
      ...updateData,
    });
  }

  user.settings.notifications.notificationSettings = notificationSettings;
  await user.save();

  return successResponse(
    res,
    {
      updatedSetting: notificationSettings.find((s) => s.type === type),
      allSettings: user.settings.notifications,
    },
    `Cập nhật cài đặt thông báo ${type} thành công`
  );
};

/**
 * @desc    Toggle bật/tắt tất cả thông báo
 * @route   PUT /api/settings/notifications/toggle-all
 * @access  Private
 */
export const toggleAllNotifications = async (req, res) => {
  const userId = req.userId;
  const { enabled } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Update global enabled flag
  user.settings.notifications.isGlobalEnabled = enabled;

  // Update all individual notification types
  if (user.settings.notifications.notificationSettings) {
    user.settings.notifications.notificationSettings.forEach((setting) => {
      setting.isEnabled = enabled;
    });
  }

  await user.save();

  return successResponse(
    res,
    { notifications: user.settings.notifications },
    enabled ? "Đã bật tất cả thông báo" : "Đã tắt tất cả thông báo"
  );
};

/**
 * @desc    Cập nhật cài đặt bảo mật
 * @route   PUT /api/settings/security
 * @access  Private
 */
export const updateSecuritySettings = async (req, res) => {
  const userId = req.userId;
  const { security } = req.body;

  console.log("🔧 DEBUG: updateSecuritySettings called");
  console.log("🔧 DEBUG: userId:", userId);
  console.log(
    "🔧 DEBUG: security settings:",
    JSON.stringify(security, null, 2)
  );

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Deep merge security settings
  user.settings.security = {
    ...user.settings.security,
    ...security,
  };

  // Log security event
  user.settings.security.securityEvents.push({
    type: "security_settings_updated",
    timestamp: new Date(),
    details: { updatedFields: Object.keys(security) },
    ipAddress: req.ip || "unknown",
    userAgent: req.get("User-Agent") || "unknown",
  });

  await user.save();

  console.log(
    "🔧 DEBUG: Final security settings:",
    JSON.stringify(user.settings.security, null, 2)
  );

  return successResponse(
    res,
    { security: user.settings.security },
    "Cập nhật cài đặt bảo mật thành công"
  );
};

/**
 * @desc    Cập nhật cài đặt giao diện
 * @route   PUT /api/settings/theme
 * @access  Private
 */
export const updateThemeSettings = async (req, res) => {
  const userId = req.userId;
  const { theme } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  user.settings.theme = theme;

  await user.save();

  res.json(
    successResponse("Cập nhật cài đặt giao diện thành công", {
      theme: user.settings.theme,
    })
  );
};

/**
 * @desc    Cập nhật cài đặt ngôn ngữ
 * @route   PUT /api/settings/language
 * @access  Private
 */
export const updateLanguageSettings = async (req, res) => {
  const userId = req.userId;
  const { language } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  user.settings.language = language;

  await user.save();

  res.json(
    successResponse("Cập nhật cài đặt ngôn ngữ thành công", {
      language: user.settings.language,
    })
  );
};

/**
 * @desc    Đặt lại cài đặt về mặc định
 * @route   POST /api/settings/reset
 * @access  Private
 */
export const resetSettings = async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Reset to default settings from User schema
  user.settings = {
    language: "vi",
    theme: "light",
    currency: {
      primary: "VND",
      displayFormat: "đ",
      decimalPlaces: 0,
    },
    notifications: {
      challenges: true,
      budgetAlerts: true,
      groupActivities: true,
      weeklyReports: true,
      pushEnabled: true,
    },
    security: {
      biometricEnabled: false,
      pinEnabled: false,
      sessionTimeout: 30,
    },
  };

  await user.save();

  res.json(
    successResponse("Đặt lại cài đặt thành công", { settings: user.settings })
  );
};

// ========================================
// PROFILE MANAGEMENT ENDPOINTS
// ========================================

/**
 * @desc    Lấy thông tin profile người dùng
 * @route   GET /api/settings/profile
 * @access  Private
 */
export const getProfile = catchAsync(async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId).select("email profile stats");

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  return successResponse(
    res,
    {
      _id: user._id,
      email: user.email,
      profile: user.profile,
      stats: user.stats,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    },
    "Lấy thông tin profile thành công"
  );
});

/**
 * @desc    Cập nhật thông tin profile
 * @route   PUT /api/settings/profile
 * @access  Private
 */
export const updateProfile = catchAsync(async (req, res) => {
  const userId = req.userId;
  const { name, phone, dateOfBirth, gender, location } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Update profile fields
  if (name !== undefined) user.profile.name = name;
  if (phone !== undefined) user.profile.phone = phone;
  if (dateOfBirth !== undefined) user.profile.dateOfBirth = dateOfBirth;
  if (gender !== undefined) user.profile.gender = gender;
  if (location !== undefined) {
    user.profile.location = {
      ...user.profile.location,
      ...location,
    };
  }

  await user.save();

  return successResponse(
    res,
    {
      profile: user.profile,
    },
    "Cập nhật profile thành công"
  );
});

/**
 * @desc    Cập nhật avatar
 * @route   PUT /api/settings/profile/avatar
 * @access  Private
 */
export const updateAvatar = catchAsync(async (req, res) => {
  const userId = req.userId;
  const { avatar } = req.body;

  if (!avatar) {
    throw new BadRequestError("URL avatar là bắt buộc");
  }

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  user.profile.avatar = avatar;
  await user.save();

  res.json(
    successResponse("Cập nhật avatar thành công", {
      avatar: user.profile.avatar,
    })
  );
});

/**
 * @desc    Lấy thống kê của người dùng
 * @route   GET /api/settings/profile/stats
 * @access  Private
 */
export const getStats = catchAsync(async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId).select("stats");

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  res.json(
    successResponse("Lấy thống kê thành công", {
      stats: user.stats,
    })
  );
});

/**
 * @desc    Cập nhật thống kê người dùng
 * @route   PUT /api/settings/profile/stats
 * @access  Private
 */
export const updateStats = catchAsync(async (req, res) => {
  const userId = req.userId;
  const {
    level,
    points,
    currentStreak,
    longestStreak,
    totalSaved,
    challengesCompleted,
    rank,
  } = req.body;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Update stats fields
  if (level !== undefined) user.stats.level = level;
  if (points !== undefined) user.stats.points = points;
  if (currentStreak !== undefined) user.stats.currentStreak = currentStreak;
  if (longestStreak !== undefined) user.stats.longestStreak = longestStreak;
  if (totalSaved !== undefined) user.stats.totalSaved = totalSaved;
  if (challengesCompleted !== undefined)
    user.stats.challengesCompleted = challengesCompleted;
  if (rank !== undefined) user.stats.rank = rank;

  await user.save();

  res.json(
    successResponse("Cập nhật thống kê thành công", {
      stats: user.stats,
    })
  );
});

/**
 * @desc    Tính toán và cập nhật thống kê tự động từ dữ liệu thực
 * @route   POST /api/settings/profile/calculate-stats
 * @access  Private
 */
export const calculateStats = catchAsync(async (req, res) => {
  const userId = req.userId;

  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError("Không tìm thấy người dùng");
  }

  // Import Income and Expense models để tính toán
  const { default: Income } = await import("../models/Income.js");
  const { default: Expense } = await import("../models/Expense.js");

  // Calculate total income
  const totalIncomeResult = await Income.aggregate([
    { $match: { userId: user._id } },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);
  const totalIncome = totalIncomeResult[0]?.total || 0;

  // Calculate total expenses
  const totalExpenseResult = await Expense.aggregate([
    { $match: { userId: user._id } },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);
  const totalExpenses = totalExpenseResult[0]?.total || 0;

  // Calculate total saved
  const totalSaved = totalIncome - totalExpenses;

  // Calculate level based on total saved
  let level = 1;
  if (totalSaved >= 50000000)
    level = 10; // 50M+
  else if (totalSaved >= 20000000)
    level = 8; // 20M+
  else if (totalSaved >= 10000000)
    level = 6; // 10M+
  else if (totalSaved >= 5000000)
    level = 4; // 5M+
  else if (totalSaved >= 1000000) level = 2; // 1M+

  // Calculate rank based on level
  let rank = "Bronze";
  if (level >= 8) rank = "Platinum";
  else if (level >= 6) rank = "Gold";
  else if (level >= 4) rank = "Silver";

  // Calculate points (level * 100 + additional bonuses)
  const points = level * 100 + user.stats.challengesCompleted * 50;

  // Update stats
  user.stats.level = level;
  user.stats.points = points;
  user.stats.totalSaved = totalSaved;
  user.stats.rank = rank;

  await user.save();

  res.json(
    successResponse("Tính toán thống kê thành công", {
      stats: user.stats,
      calculated: {
        totalIncome,
        totalExpenses,
        totalSaved,
      },
    })
  );
});
