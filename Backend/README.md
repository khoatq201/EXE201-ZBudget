# ZBudget Backend - Mongoose Models

## 📋 Tổng quan

Backend Node.js với Mongoose models cho ứng dụng ZBudget - Personal Finance Management App. Được thiết kế dựa trên MongoDB schema design chi tiết và Flutter codebase hiện có.

## 🏗️ Kiến trúc Models

### Core Models

1. **User Model** (`src/models/User.js`)

   - Quản lý thông tin người dùng, profile, settings
   - Gamification stats (level, points, streaks)
   - Authentication & security features

2. **Expense Model** (`src/models/Expense.js`)

   - Chi tiêu với đầy đủ thông tin (amount, category, location)
   - Receipt & OCR support
   - Group sharing & budget integration

3. **Budget Model** (`src/models/Budget.js`)

   - Ngân sách theo kỳ (monthly, weekly, yearly)
   - Category allocations & tracking
   - Alert system & goals

4. **Challenge Model** (`src/models/Challenge.js`)

   - Thách thức gamification
   - Milestones & rewards system
   - Statistics & leaderboards

5. **UserChallenge Model** (`src/models/UserChallenge.js`)

   - Tiến độ thách thức của từng user
   - Daily progress tracking
   - Social features & completion status

6. **Group Model** (`src/models/Group.js`)

   - Nhóm chia sẻ chi tiêu
   - Member management & permissions
   - Invite system

7. **Notification Model** (`src/models/Notification.js`)
   - Hệ thống thông báo đa dạng
   - Scheduled & priority notifications
   - Action buttons & rich content

## 🚀 Cài đặt & Sử dụng

### Yêu cầu

- Node.js 18+
- MongoDB 6.0+
- npm hoặc yarn

### Cài đặt dependencies

```bash
cd backend
npm install
```

### Cấu hình môi trường

```bash
# Copy file cấu hình mẫu
cp .env.example .env

# Chỉnh sửa .env với thông tin của bạn
nano .env
```

### Khởi tạo database

```bash
# Setup database và tạo indexes
npm run setup

# Setup + seed data mẫu
npm run setup:seed
```

### Chạy development server

```bash
npm run dev
```

## 📊 MongoDB Schema Features

### Advanced Features

#### 1. Decimal128 cho Financial Data

```javascript
amount: {
  type: mongoose.Schema.Types.Decimal128,
  required: true
}
```

#### 2. Compound Indexes cho Performance

```javascript
ExpenseSchema.index({ userId: 1, date: -1 });
ExpenseSchema.index({ userId: 1, category: 1, date: -1 });
```

#### 3. Transaction Support

```javascript
const result = await transactions.withTransaction(async (session) => {
  // Multiple operations in transaction
  await Expense.create([expenseData], { session });
  await Budget.updateOne(query, update, { session });
});
```

#### 4. Validation & Middleware

```javascript
// Pre-save middleware
ExpenseSchema.pre("save", function (next) {
  // Auto-calculate budget impact
  this.updateBudgetImpact();
  next();
});
```

#### 5. Instance & Static Methods

```javascript
// Instance method
UserSchema.methods.addPoints = function (points) {
  this.stats.points += points;
  // Update level & rank logic
};

// Static method
ExpenseSchema.statics.findByUser = function (userId, options) {
  return this.find({ userId, ...options });
};
```

## 🔧 Utility Functions

### Database Operations

```javascript
import { connectDB, dbUtils, transactions } from "./models/index.js";

// Connect to database
await connectDB();

// Get database statistics
const stats = await dbUtils.getStats();

// Health check
const health = await dbUtils.healthCheck();

// Execute in transaction
const result = await transactions.addExpenseWithBudgetUpdate(expenseData);
```

### Model Validation

```javascript
import { validateModels } from "./models/index.js";

// Validate before saving
const validUser = await validateModels.validateUserData(userData);
const validExpense = await validateModels.validateExpenseData(expenseData);
```

## 📈 Performance Optimizations

### 1. Strategic Indexing

- Compound indexes cho query patterns phổ biến
- Sparse indexes cho optional fields
- TTL indexes cho temporary data

### 2. Denormalization

- Category display info trong Expense
- User email trong Expense cho performance
- Stats caching trong models

### 3. Aggregation Pipelines

```javascript
// Monthly expense summary
const monthlyStats = await Expense.aggregate([
  { $match: { userId, date: { $gte: startDate, $lte: endDate } } },
  { $group: { _id: "$category", total: { $sum: "$amount" } } },
]);
```

## 🛡️ Security Features

### 1. Data Validation

- Comprehensive field validation
- Custom validators cho business logic
- Sanitization & format checking

### 2. Password Security

```javascript
// Auto-hash passwords
UserSchema.pre("save", async function (next) {
  if (!this.isModified("passwordHash")) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
});
```

### 3. Audit Trail

- CreatedAt/UpdatedAt timestamps
- Version tracking
- Soft delete support

## 🎯 Business Logic Examples

### Challenge System

```javascript
// Start a challenge
const userChallenge = new UserChallenge({ userId, challengeId });
await userChallenge.startChallenge(challenge);

// Update daily progress
await userChallenge.updateDailyProgress(date, savedAmount, expenses, notes);

// Complete milestone
const milestone = await transactions.completeChallengeMilestone(
  userId,
  challengeId,
  milestoneIndex,
  pointsEarned
);
```

### Budget Management

```javascript
// Add expense to budget
const budget = await Budget.findCurrentBudget(userId);
budget.addExpense(amount, category);

// Check alerts
const alerts = budget.checkAlertThresholds();
if (alerts.length > 0) {
  // Send notifications
}
```

### Group Expenses

```javascript
// Add member to group
const group = await Group.findById(groupId);
await group.addMember(userId, "member");

// Track group expense
await group.addExpense(amount);
```

## 📚 API Integration

Models được thiết kế để dễ dàng integrate với REST API:

```javascript
// Express route example
app.post("/api/expenses", async (req, res) => {
  try {
    const expense = await transactions.addExpenseWithBudgetUpdate(req.body);
    res.json(expense);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

## 🧪 Testing Support

```javascript
// Test helpers
import { dbUtils } from "./models/index.js";

// Setup test database
await connectDB(process.env.MONGODB_TEST_URI);

// Clean up after tests
await dbUtils.dropAllCollections(); // Development only!
```

## 📋 Scripts Available

```json
{
  "dev": "nodemon src/setup.js --no-cleanup",
  "setup": "node src/setup.js",
  "setup:seed": "node src/setup.js --seed",
  "test": "jest",
  "lint": "eslint src/",
  "format": "prettier --write src/"
}
```

## 🔄 Migration & Versioning

Models support versioning để handle schema changes:

```javascript
// Version tracking
version: {
  type: Number,
  default: 1
}

// Migration helper
UserSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  next();
});
```

## 🌐 Localization Support

Built-in Vietnamese/English support:

```javascript
// Category display
categoryDisplay: {
  nameVi: 'Ăn uống',
  nameEn: 'Food',
  icon: '🍜',
  color: '#FF6B6B'
}
```

## 🤝 Contributing

1. Follow existing code style and patterns
2. Add validation for new fields
3. Include appropriate indexes
4. Add JSDoc comments
5. Update this README for new features

## 📄 License

MIT License - See Flutter project for full details.
