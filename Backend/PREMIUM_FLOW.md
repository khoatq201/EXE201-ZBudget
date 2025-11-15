# Premium Subscription Flow - Complete Documentation

## 🎯 Overview

Premium users có **UNLIMITED** OCR scans và các features nâng cao. Hệ thống tự động quản lý lifecycle từ upgrade → active → expiry.

---

## 📊 Premium vs Free Comparison

| Feature              | Free        | Premium                         |
| -------------------- | ----------- | ------------------------------- |
| **OCR Scans**        | 10/day      | **Unlimited (-1)**              |
| **AI Analysis**      | ❌ Disabled | ✅ Enabled                      |
| **Budgets**          | 2 max       | 20 max                          |
| **Savings Goals**    | 2 max       | 10 max                          |
| **Priority Support** | ❌          | ✅                              |
| **Price**            | Free        | 25,000đ/tháng hoặc 250,000đ/năm |

---

## 🔄 Premium Lifecycle

### 1️⃣ Upgrade to Premium

#### API Endpoint

```http
POST /api/subscription/upgrade
Authorization: Bearer <token>

{
  "duration": "monthly" // or "yearly"
}
```

#### Backend Flow

```javascript
// Controller: subscriptionController.js
export const upgradeToPremium = async (req, res) => {
  const userId = req.userId;
  const { duration = "monthly" } = req.body;

  // Validate duration
  if (!["monthly", "yearly"].includes(duration)) {
    return res.status(400).json({
      success: false,
      message: "Invalid duration",
    });
  }

  // Call service
  const result = await SubscriptionService.upgradeToPremium(
    userId,
    duration,
    "user" // performedBy
  );

  return res.json(result);
};
```

#### Service Logic

```javascript
// services/subscriptionService.js
static async upgradeToPremium(userId, duration, performedBy) {
  const user = await User.findById(userId);

  if (user.isPremium()) {
    throw new Error("User is already premium");
  }

  // 1. Update user subscription
  user.upgradeToPremium(duration);
  await user.save();

  // 2. Update usage limits to unlimited
  await UsageLimit.updateUserLimits(userId, "premium");

  return {
    success: true,
    subscription: {
      tier: "premium",
      expiryDate: user.subscription.expiryDate,
      price: user.subscription.price
    }
  };
}
```

#### User Model Method

```javascript
// models/User.js
UserSchema.methods.upgradeToPremium = function (duration) {
  const now = new Date();
  const pricing = {
    monthly: { amount: 25000, duration: 30 },
    yearly: { amount: 250000, duration: 365 },
  };

  const plan = pricing[duration];
  const expiryDate = new Date(now);
  expiryDate.setDate(expiryDate.getDate() + plan.duration);

  // Update subscription fields
  this.subscription.tier = "premium";
  this.subscription.status = "active";
  this.subscription.startDate = now;
  this.subscription.expiryDate = expiryDate;
  this.subscription.features = {
    maxBudgets: 20,
    maxSavingsGoals: 10,
    ocrScansPerDay: -1, // ← UNLIMITED
    aiAnalysisEnabled: true, // ← ENABLED
  };

  // Add to history
  this.subscriptionHistory.push({
    tier: "premium",
    action: "upgrade",
    startDate: now,
    endDate: expiryDate,
    price: { amount: plan.amount, currency: "VND" },
  });
};
```

#### Usage Limit Update

```javascript
// models/UsageLimit.js
UsageLimitSchema.statics.updateUserLimits = async function (userId, newTier) {
  const today = this.getCurrentDateVN();
  const newOCRLimit = newTier === "premium" ? -1 : 10; // ← -1 = unlimited

  await this.findOneAndUpdate(
    { userId, date: today },
    {
      $set: {
        "ocrScans.limit": newOCRLimit,
        "aiAnalysis.limit": -1,
      },
    },
    { upsert: true }
  );
};
```

---

### 2️⃣ Premium Active State

#### OCR Check Logic

```javascript
// models/UsageLimit.js
UsageLimitSchema.statics.checkOCRLimit = async function (userId, userTier) {
  const usage = await this.getOrCreateToday(userId, userTier);

  // Premium users ALWAYS allowed
  if (userTier === "premium" || usage.ocrScans.limit === -1) {
    return {
      allowed: true,
      count: usage.ocrScans.count,
      limit: -1, // ← Unlimited indicator
      remaining: -1, // ← Unlimited
      tier: userTier,
    };
  }

  // Free user logic...
  const allowed = usage.ocrScans.count < usage.ocrScans.limit;
  return {
    allowed,
    count: usage.ocrScans.count,
    limit: usage.ocrScans.limit,
    remaining: Math.max(0, usage.ocrScans.limit - usage.ocrScans.count),
  };
};
```

#### Usage Tracking

```javascript
// Premium users still get tracked (for analytics)
UsageLimitSchema.statics.incrementOCRCount = async function (userId, userTier) {
  const today = this.getCurrentDateVN();
  const ocrLimit = userTier === "premium" ? -1 : 10;

  await this.findOneAndUpdate(
    { userId, date: today },
    {
      $inc: { "ocrScans.count": 1 }, // ← Count still increments
      $set: { "ocrScans.lastUsedAt": new Date() },
      $setOnInsert: { "ocrScans.limit": ocrLimit },
    },
    { upsert: true }
  );
};
```

**Note:** Premium users' count vẫn tăng (cho analytics) nhưng KHÔNG bị block bởi limit check.

---

### 3️⃣ Subscription Expiry

#### Auto-Expiry Cron Job

```javascript
// jobs/subscriptionJobs.js

// Runs every hour at minute 0
cron.schedule(
  "0 * * * *",
  async () => {
    const result = await SubscriptionService.autoExpireSubscriptions();
    console.log(`Expired ${result.expiredCount} subscriptions`);
  },
  {
    timezone: "Asia/Ho_Chi_Minh",
  }
);
```

#### Expiry Service Logic

```javascript
// services/subscriptionService.js
static async autoExpireSubscriptions() {
  const now = new Date();

  // Find expired premium users
  const expiredUsers = await User.find({
    "subscription.tier": "premium",
    "subscription.status": "active",
    "subscription.expiryDate": { $lte: now }
  });

  let expiredCount = 0;

  for (const user of expiredUsers) {
    // Downgrade to free
    user.downgradeToFree("Subscription expired");
    await user.save();

    // Update usage limits to free tier
    await UsageLimit.updateUserLimits(user._id, "free");

    expiredCount++;
  }

  return { expiredCount };
}
```

#### Downgrade Logic

```javascript
// models/User.js
UserSchema.methods.downgradeToFree = function (reason) {
  const now = new Date();

  // Add to history
  this.subscriptionHistory.push({
    tier: "free",
    action: "downgrade",
    startDate: now,
    reason: reason,
    performedBy: "system",
  });

  // Reset subscription to free
  this.subscription.tier = "free";
  this.subscription.status = "inactive";
  this.subscription.expiryDate = undefined;
  this.subscription.features = {
    maxBudgets: 2,
    maxSavingsGoals: 2,
    ocrScansPerDay: 10, // ← Back to 10/day
    aiAnalysisEnabled: false, // ← Disabled
  };
};
```

---

## 📱 Frontend Integration

### Check Premium Status

```dart
// Flutter
final subscriptionService = context.read<SubscriptionService>();
final isPremium = subscriptionService.isPremium;

if (isPremium) {
  // Show unlimited badge
  Text('Unlimited - Premium ⭐');
} else {
  // Show quota
  Text('Free: ${usage.count}/${usage.limit}');
}
```

### Display Usage Banner

```dart
Widget _buildOCRUsageBanner() {
  return Consumer<SubscriptionService>(
    builder: (context, subscriptionService, child) {
      final usageStats = subscriptionService.usageStats;
      final isPremium = subscriptionService.isPremium;

      if (usageStats == null) {
        return Text('Đang tải...');
      }

      if (isPremium) {
        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            Text('Unlimited - Premium'),
          ],
        );
      }

      // Free user - show progress
      return Column(
        children: [
          Text('Free: ${usageStats.ocr.count}/${usageStats.ocr.limit}'),
          CompactUsageProgress(
            current: usageStats.ocr.count,
            limit: usageStats.ocr.limit,
          ),
        ],
      );
    },
  );
}
```

### Upgrade Flow

```dart
// When user hits quota limit
if (!canUseOCR && !isPremium) {
  showUpgradeDialog(
    context,
    feature: 'Quét hóa đơn',
    reason: 'Bạn đã hết quota. Nâng cấp Premium để quét không giới hạn!',
    onUpgrade: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PremiumPaywallScreen(),
        ),
      );
    },
  );
}
```

---

## 🔍 Usage Data Structure

### Free User

```json
{
  "tier": "free",
  "isPremium": false,
  "usage": {
    "ocr": {
      "count": 8,
      "limit": 10,
      "remaining": 2,
      "percentage": 80
    }
  }
}
```

### Premium User

```json
{
  "tier": "premium",
  "isPremium": true,
  "usage": {
    "ocr": {
      "count": 156, // ← Still tracked for analytics
      "limit": -1, // ← Unlimited indicator
      "remaining": -1, // ← Unlimited
      "percentage": 0 // ← No limit = no percentage
    },
    "aiAnalysis": {
      "count": 23,
      "enabled": true // ← Premium feature
    }
  }
}
```

---

## 🧪 Testing Premium Flow

### Test Script

```bash
cd Backend
node scripts/test-premium-flow.js
```

### Manual Testing Steps

1. **Start as Free User**

   ```bash
   GET /api/subscription/status
   # tier: "free", ocrScansPerDay: 10
   ```

2. **Upgrade to Premium**

   ```bash
   POST /api/subscription/upgrade
   { "duration": "monthly" }
   # tier: "premium", ocrScansPerDay: -1, expiryDate: +30 days
   ```

3. **Test Unlimited Scans**

   ```bash
   # Scan 100+ times - should all succeed
   for i in {1..100}; do
     POST /api/ocr/process-receipt
   done
   ```

4. **Check Usage**

   ```bash
   GET /api/subscription/usage
   # count: 100+, limit: -1, remaining: -1
   ```

5. **Simulate Expiry** (change expiryDate in DB)

   ```javascript
   await User.updateOne(
     { email: "test@example.com" },
     { $set: { "subscription.expiryDate": new Date() } }
   );

   // Wait for hourly cron or trigger manually
   await subscriptionJobs.manualExpiryCheck();
   ```

6. **Verify Downgrade**
   ```bash
   GET /api/subscription/status
   # tier: "free", ocrScansPerDay: 10
   ```

---

## ⚙️ Configuration

### Pricing Plans

```javascript
// services/subscriptionService.js
const PRICING = {
  monthly: {
    displayName: "Tháng",
    amount: 25000,
    currency: "VND",
    duration: 30,
    features: [
      "Unlimited OCR",
      "AI Analysis",
      "20 Budgets",
      "10 Savings Goals",
    ],
  },
  yearly: {
    displayName: "Năm",
    amount: 250000,
    currency: "VND",
    duration: 365,
    savings: 50000, // Save 50k vs monthly
    features: ["All Monthly features", "Priority Support", "Early Access"],
  },
};
```

### Feature Limits

```javascript
// models/User.js
const FEATURE_LIMITS = {
  free: {
    maxBudgets: 2,
    maxSavingsGoals: 2,
    ocrScansPerDay: 10,
    aiAnalysisEnabled: false,
  },
  premium: {
    maxBudgets: 20,
    maxSavingsGoals: 10,
    ocrScansPerDay: -1, // Unlimited
    aiAnalysisEnabled: true,
  },
};
```

---

## 🚨 Edge Cases & Handling

### 1. Upgrade While Having Usage Today

```javascript
// When upgrading mid-day with usage count = 8/10
// → After upgrade: count = 8/-1 (still tracked, but unlimited)
// → User can continue scanning without limit
```

### 2. Expiry at Midnight

```javascript
// If premium expires at 00:00
// → Cron runs hourly, may take up to 1 hour to detect
// → User might get 1 extra hour of premium access
// Solution: Check expiry on each request (middleware)
```

### 3. Downgrade While Exceeding Free Limits

```javascript
// User has 15 budgets (premium allows 20)
// → Downgrade to free (limit: 2)
// → Existing budgets NOT deleted
// → User can view all 15, but cannot create new ones
```

### 4. Re-upgrade After Expiry

```javascript
// Premium expired → Downgraded to free
// → Usage history preserved
// → Can upgrade again anytime
// → Previous usage counts remain for analytics
```

---

## 📈 Analytics & Monitoring

### Track Premium Conversions

```javascript
const stats = await SubscriptionService.getSubscriptionStats();
// {
//   totalUsers: 1000,
//   freeUsers: 850,
//   premiumUsers: 150,
//   conversionRate: 15%,
//   totalRevenue: 3750000 VND
// }
```

### Monitor Usage Patterns

```javascript
const usageStats = await UsageService.getTotalUsageStats();
// {
//   date: "2025-11-15",
//   totalOCRScans: 2500,
//   averagePerUser: 25,
//   premiumUsage: 1800,  // 72% from premium users
//   freeUsage: 700       // 28% from free users
// }
```

---

## 🎯 Summary

### Premium Flow Checklist

- ✅ **Upgrade:** User → Premium tier, ocrScansPerDay = -1
- ✅ **Usage:** Count tracked, limit = -1 (unlimited)
- ✅ **Check:** `userTier === "premium"` → always allowed
- ✅ **Expiry:** Cron hourly check → auto-downgrade
- ✅ **Downgrade:** Premium → Free, ocrScansPerDay = 10
- ✅ **Frontend:** Show "Unlimited - Premium ⭐" badge
- ✅ **History:** All changes logged in subscriptionHistory

### Key Differences: Premium vs Free

| Aspect            | Free                                  | Premium                        |
| ----------------- | ------------------------------------- | ------------------------------ |
| `ocrScansPerDay`  | `10`                                  | `-1` (unlimited)               |
| Daily Reset       | Yes, new record per date              | Yes, but no quota limit        |
| `checkOCRLimit()` | Returns `allowed: false` when exceeds | Always returns `allowed: true` |
| Usage Tracking    | Count tracked, blocked at limit       | Count tracked, never blocked   |
| Frontend Display  | "X/10 scans" + progress bar           | "Unlimited - Premium ⭐"       |

**Bottom Line:** Premium users enjoy truly unlimited OCR scanning with no daily quota restrictions! 🎉
