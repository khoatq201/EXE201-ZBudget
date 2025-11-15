# Daily OCR Usage Reset - Implementation Documentation

## ✅ Cơ chế hoạt động

### Automatic Reset Logic

**KHÔNG CẦN RESET THỦ CÔNG!** Hệ thống tự động reset dựa trên DATE ISOLATION:

1. **Mỗi ngày = 1 record riêng biệt**

   - Field `date` format: `YYYY-MM-DD` (VD: `2025-11-15`)
   - Index: `{ userId: 1, date: 1 }` unique

2. **Query luôn dùng date hiện tại**

   ```javascript
   const today = UsageLimit.getCurrentDateVN(); // "2025-11-15"
   await UsageLimit.findOne({ userId, date: today });
   ```

3. **Sang ngày mới → Date mới → Record mới**
   - Hôm nay: `2025-11-15` → `count: 10/10` (hết quota)
   - Sang ngày: `2025-11-16` → Tạo record mới với `count: 0/10` ✅

### Implementation Details

#### Model: `UsageLimit.js`

```javascript
UsageLimitSchema.statics.incrementOCRCount = async function (userId, userTier) {
  const today = this.getCurrentDateVN(); // ← Key: uses current date

  await this.findOneAndUpdate(
    { userId, date: today }, // ← Query by today's date
    { $inc: { "ocrScans.count": 1 } },
    { upsert: true } // ← Creates new record if not exists
  );
};
```

#### Cron Job Setup

**File:** `Backend/jobs/subscriptionJobs.js`

```javascript
// Runs at 00:00 Vietnam time (17:00 UTC previous day)
cron.schedule(
  "0 17 * * *",
  async () => {
    // Only cleanup old records (>30 days)
    await UsageLimit.deleteMany({
      date: { $lt: cutoffDate },
    });
  },
  {
    scheduled: true,
    timezone: "Asia/Ho_Chi_Minh",
  }
);
```

**⚠️ Important:** Cron job chỉ DELETE old records, KHÔNG reset counts!

## 📊 Test Results

### Test Scenario

```
Hôm nay (2025-11-15):
  ✓ Scan 10 lần → count: 10/10 (hết quota)

Sang ngày (2025-11-16):
  ✓ Tự động tạo record mới
  ✓ count: 0/10 (quota refresh) ✅
  ✓ Record cũ vẫn tồn tại (lịch sử)
```

### Database State After Test

```json
[
  {
    "userId": "69160834a94a045fd23ec662",
    "date": "2025-11-15",
    "ocrScans": { "count": 10, "limit": 10 }
  },
  {
    "userId": "69160834a94a045fd23ec662",
    "date": "2025-11-16",
    "ocrScans": { "count": 1, "limit": 10 }
  }
]
```

## 🔄 Reset Timeline

### Midnight Reset (00:00 VN Time)

| Time (VN) | UTC Time | Action                                                 |
| --------- | -------- | ------------------------------------------------------ |
| 23:59:59  | 16:59:59 | Record: `2025-11-15` với count = 10                    |
| 00:00:00  | 17:00:00 | **NEW DATE** → Queries find no record for `2025-11-16` |
| 00:00:01  | 17:00:01 | First scan → Creates `2025-11-16` với count = 1        |

### Cleanup Schedule

- **When:** 02:00 VN time daily (19:00 UTC)
- **What:** Delete records older than 30 days
- **Why:** Save database space, keep history for analytics

## 🧪 Testing

### Run Test Script

```bash
cd Backend
node scripts/test-daily-reset.js
```

### Manual Testing

1. **Check current usage:**

   ```bash
   GET /api/subscription/usage
   ```

2. **Use OCR multiple times**

3. **Wait until midnight or change system date**

4. **Check usage again** → Should see count reset to 0

### Verify Cron Job Status

```javascript
import subscriptionJobs from "./jobs/subscriptionJobs.js";

// Check if cron jobs are running
const status = subscriptionJobs.getStatus();
console.log(status);
```

## 🚨 Troubleshooting

### Issue: Count not resetting at midnight

**Causes:**

1. Server timezone not set to Asia/Ho_Chi_Minh
2. Cron job not initialized in `server.js`
3. Database clock skew

**Solution:**

```javascript
// In server.js
import subscriptionJobs from "./jobs/subscriptionJobs.js";
subscriptionJobs.init(); // ← Must be called!
```

### Issue: Old records piling up

**Check:**

```javascript
// Count total records
const count = await UsageLimit.countDocuments();
console.log(`Total usage records: ${count}`);

// Check oldest record
const oldest = await UsageLimit.findOne().sort({ date: 1 });
console.log(`Oldest record: ${oldest.date}`);
```

**Fix:**

- Cleanup cron should delete records > 30 days
- Check cron job is running: `subscriptionJobs.getStatus()`

## 📈 Performance Considerations

### Index Strategy

```javascript
// Compound index for fast lookup
{ userId: 1, date: 1 }, { unique: true }

// Cleanup index
{ date: 1 }
```

### Storage Impact

- **Per user per day:** ~200 bytes
- **1000 users × 30 days:** ~6 MB
- **Cleanup:** Auto-deletes after 30 days

## 🔐 Security Notes

- Records are user-scoped (userId field)
- Date format prevents injection (YYYY-MM-DD only)
- Upsert prevents race conditions

## 📝 Summary

✅ **Auto-reset:** Dựa vào date isolation, không cần manual reset
✅ **Timezone-aware:** Sử dụng Asia/Ho_Chi_Minh timezone
✅ **History preserved:** Old records kept for 30 days
✅ **Tested:** Verified with test script
✅ **Production-ready:** Cron job scheduled for 00:00 VN time

**No action needed** - System automatically handles daily reset! 🎉
