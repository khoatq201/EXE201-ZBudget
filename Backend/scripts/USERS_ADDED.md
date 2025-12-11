# Users Added to ZBudget Database

## Summary
Successfully added **12 new users** to the database on **2025-11-25**.

## Added Users List

| Email | Name | Status |
|-------|------|--------|
| Khangky9910@gmail.com | Khang (A Khang) | ✅ Added |
| khanglop96qt@gmail.com | Khang | ✅ Added |
| dohuuhoangkha@gmail.com | Kha | ✅ Added |
| Mrjason170802@gmail.com | Kiệt | ✅ Added |
| 20530201057@uah.edu.vn | Bạn Khang | ✅ Added |
| thinhndse162000@fpt.edu.vn | Thịnh | ✅ Added |
| nganltcss181096@fpt.edu.vn | Ngân | ✅ Added |
| hoangntss181069@fpt.edu.vn | Hoàng | ✅ Added |
| thihnass181027@fpt.edu.vn | Thi | ✅ Added |
| ngoclvkss181275@fpt.edu.vn | Ngọc | ⚠️ Already existed |
| chungpss181258@fpt.edu.vn | Chung | ✅ Added |
| duykhuongzxc@gmail.com | Khương | ✅ Added |
| hiepvvss170481@fpt.edu.vn | Hiệp | ✅ Added |

## Default Credentials

**Default Password for All Users:** `ZBudget2024!`

⚠️ **IMPORTANT:** Users should change this password after their first login for security reasons.

## User Account Details

All users have been created with the following default settings:

- **Email Verified:** ✅ Yes (set to true for easier testing)
- **Account Status:** Active
- **Auth Provider:** Local (email/password)
- **Default Currency:** VND (Vietnamese Dong)
- **Default Language:** Vietnamese (vi)
- **Default Theme:** Light mode
- **Starting Level:** 1
- **Starting Points:** 0
- **Rank:** Bronze
- **Subscription Tier:** Free

### Notification Settings
All notification types are enabled by default with these settings:
- Budget alerts: ✅ Enabled
- Expense tracking: ✅ Enabled
- Income notifications: ✅ Enabled
- Challenge updates: ✅ Enabled
- Reminders: ✅ Enabled
- Achievement notifications: ✅ Enabled
- Security alerts: ✅ Enabled
- System notifications: ✅ Enabled
- Marketing: ❌ Disabled

### Security Settings
- Biometric authentication: ❌ Disabled (users can enable)
- PIN code: ❌ Disabled (users can enable)
- Session timeout: 30 minutes

## How to Run the Script Again

To add more users in the future, use:

```bash
cd Backend
npm run add:users
```

Or directly:

```bash
cd Backend
node scripts/addUsers.js
```

## Script Features

- ✅ Automatic duplicate detection (skips existing users)
- ✅ Secure password hashing with bcrypt (12 rounds)
- ✅ Comprehensive default settings
- ✅ Vietnamese localization
- ✅ Error handling with detailed reporting
- ✅ Summary statistics after execution

## Notes

1. One user (ngoclvkss181275@fpt.edu.vn) already existed in the database and was skipped
2. All passwords are hashed using bcrypt with 12 rounds for security
3. Users can log in immediately as emailVerified is set to true
4. Users should be advised to change their password on first login

## Next Steps

1. ✅ Inform users of their login credentials
2. ⚠️ Recommend users change password on first login
3. 📧 Consider sending welcome emails to new users
4. 📱 Test login functionality with these accounts
