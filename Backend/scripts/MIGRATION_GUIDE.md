# Database Migration Guide - Subscription System

## 📌 Overview

This guide explains how to safely add subscription fields to existing users in your ZBudget database.

## ⚠️ Important Safety Notes

- ✅ **SAFE**: Migration **ONLY ADDS** new fields to existing users
- ✅ **NON-DESTRUCTIVE**: Does NOT delete or modify any existing data
- ✅ **REVERSIBLE**: Can be rolled back if needed
- ✅ **IDEMPOTENT**: Safe to run multiple times (only updates users missing fields)

## 📦 What Gets Added

### New Fields Added to User Schema:

1. **subscription** object:
   ```json
   {
     "tier": "free",
     "status": "active",
     "startDate": "2025-01-15T00:00:00.000Z",
     "expiryDate": null,
     "features": {
       "maxBudgets": 2,
       "maxSavingsGoals": 2,
       "ocrScansPerDay": 10,
       "aiAnalysisEnabled": false,
       "prioritySupport": false
     }
   }
   ```

2. **usageLimits** object:
   ```json
   {
     "ocr": {
       "count": 0,
       "lastResetDate": "2025-01-15T00:00:00.000Z"
     }
   }
   ```

3. **Database Indexes**:
   - `subscription.tier` (for filtering by free/premium)
   - `subscription.status` (for filtering active/inactive)
   - `subscription.expiryDate` (for expiry checks)

## 🚀 Migration Steps

### Step 1: Test Migration (Dry Run)

**ALWAYS run test first** to see what will happen:

```bash
cd Backend
npm run migrate:subscription:test
```

This will show:
- How many users will be affected
- Sample users before migration
- What changes will be made
- ⚠️ Any potential issues

### Step 2: Backup Database (Recommended)

Before running migration, backup your database:

```bash
# For MongoDB Atlas
# Use MongoDB Compass or Atlas UI to create a snapshot

# For local MongoDB
mongodump --uri="your-mongodb-uri" --out=backup-before-subscription
```

### Step 3: Run Migration

Once you've reviewed the dry run output:

```bash
npm run migrate:subscription
```

**Expected output:**
```
✅ Connected to MongoDB
🚀 Starting subscription migration...

📊 Found 15 users to migrate

🔍 Users without subscription: 15
🔍 Users without usageLimits: 15

📝 Adding subscription field to users...
✅ Updated 15 users with subscription

📝 Adding usageLimits field to users...
✅ Updated 15 users with usageLimits

🔎 Verifying migration...
✅ 15/15 users now have subscription fields

📋 Sample user after migration:
{
  "_id": "...",
  "email": "user@example.com",
  "displayName": "John Doe",
  "subscription": { ... },
  "usageLimits": { ... }
}

🔧 Creating indexes...
✅ Indexes created

✨ Migration completed successfully!
```

### Step 4: Verify Migration

Check your database to confirm:

```bash
# Using MongoDB shell/Compass
db.users.findOne({}, { subscription: 1, usageLimits: 1 })

# Or run test again to see updated status
npm run migrate:subscription:test
```

## 🔄 Rollback (If Needed)

If you need to undo the migration:

```bash
npm run migrate:subscription:rollback
```

⚠️ **Warning**: This will remove `subscription` and `usageLimits` fields from ALL users.

You will be asked for confirmation:
```
Are you sure you want to rollback? This will remove subscription fields. (yes/no):
```

Type `yes` to proceed with rollback.

## 📊 Migration Scenarios

### Scenario 1: Fresh Database (No Existing Users)

```bash
$ npm run migrate:subscription:test
📊 Found 0 users to migrate
ℹ️  No users found. Migration not needed.
```

**Action**: No migration needed. New users will get subscription fields automatically.

---

### Scenario 2: Existing Users Without Subscription

```bash
$ npm run migrate:subscription:test
📊 Found 25 users to migrate
🔍 Users without subscription: 25
🔍 Users without usageLimits: 25
```

**Action**: Run migration to add fields to all 25 users.

---

### Scenario 3: Some Users Already Migrated

```bash
$ npm run migrate:subscription:test
📊 Found 30 users to migrate
🔍 Users without subscription: 10
🔍 Users without usageLimits: 10
```

**Action**: Safe to run migration. Only the 10 users without fields will be updated.

---

### Scenario 4: All Users Already Have Subscription

```bash
$ npm run migrate:subscription:test
📊 Found 30 users to migrate
🔍 Users without subscription: 0
🔍 Users without usageLimits: 0
✨ All users already have subscription fields!
```

**Action**: No migration needed.

## 🛠️ Troubleshooting

### Issue: Migration fails with "Cannot connect to MongoDB"

**Solution:**
1. Check your `.env` file has correct `MONGODB_URI`
2. Ensure MongoDB is running (Atlas or local)
3. Check network/firewall settings

---

### Issue: Some users not updated

**Cause**: Migration only updates users where field doesn't exist

**Solution**: This is expected behavior. If a user already has the field, it won't be overwritten.

---

### Issue: Need to change default values

**Solution**:
1. Edit `DEFAULT_SUBSCRIPTION` and `DEFAULT_USAGE_LIMITS` in [migrate-add-subscription.js](./migrate-add-subscription.js)
2. Run migration again (only users without fields will get new defaults)

---

### Issue: Want to update existing subscription values

This migration script **does not** update existing values. For that, you need a different script.

**Manual update example**:
```javascript
// In MongoDB shell
db.users.updateMany(
  { 'subscription.tier': 'free' },
  { $set: { 'subscription.features.maxBudgets': 3 } }
)
```

## 📝 Post-Migration Checklist

After successful migration:

- [ ] Verify all users have `subscription` field
- [ ] Verify all users have `usageLimits` field
- [ ] Check indexes were created
- [ ] Test app login/signup flow
- [ ] Test premium features enforcement
- [ ] Test OCR quota tracking
- [ ] Test subscription settings screen
- [ ] Remove backup (if everything works)

## 🆘 Need Help?

If you encounter issues:

1. Run the test script and share output
2. Check MongoDB logs
3. Verify User model schema in `Backend/models/User.js`
4. Ensure all backend subscription routes are working

## 📚 Related Files

- Migration script: [`migrate-add-subscription.js`](./migrate-add-subscription.js)
- Test script: [`test-subscription-migration.js`](./test-subscription-migration.js)
- User model: [`../models/User.js`](../models/User.js)
- Subscription routes: [`../routes/subscriptionRoutes.js`](../routes/subscriptionRoutes.js)
- Premium middleware: [`../middleware/premium.js`](../middleware/premium.js)

---

**Last Updated**: January 2025
**Migration Version**: 1.0
**Compatible with**: ZBudget Backend v1.0+
