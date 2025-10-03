import mongoose from "mongoose";
import { User, Expense, Income, Budget, connectDB } from "../models/index.js";

// User ID from registration
const USER_ID = "68ddedbf11688a48e6fad12d";
const USER_EMAIL = "phuonganh160268@gmail.com";

// Seed data configuration
const SEED_CONFIG = {
  expenseCount: 25,
  incomeCount: 3, // 3 income transactions
  monthlyBudget: 3000000, // 3M VND
  monthlyAllowance: 5000000, // 5M VND monthly allowance
  currentMonth: new Date(2025, 9, 1), // October 2025
};

// Category distribution and amount ranges
const EXPENSE_TEMPLATES = [
  // Food (~40%)
  { category: "food", weight: 10, minAmount: 15000, maxAmount: 80000 },
  { category: "food", weight: 10, minAmount: 20000, maxAmount: 50000 },
  { category: "food", weight: 10, minAmount: 25000, maxAmount: 100000 },
  { category: "food", weight: 10, minAmount: 30000, maxAmount: 70000 },

  // Transport (~20%)
  { category: "transport", weight: 5, minAmount: 10000, maxAmount: 50000 },
  { category: "transport", weight: 5, minAmount: 15000, maxAmount: 40000 },
  { category: "transport", weight: 5, minAmount: 8000, maxAmount: 30000 },
  { category: "transport", weight: 5, minAmount: 20000, maxAmount: 60000 },

  // Education (~15%)
  { category: "education", weight: 4, minAmount: 50000, maxAmount: 200000 },
  { category: "education", weight: 4, minAmount: 30000, maxAmount: 150000 },
  { category: "education", weight: 4, minAmount: 100000, maxAmount: 300000 },

  // Entertainment (~10%)
  { category: "entertainment", weight: 3, minAmount: 50000, maxAmount: 150000 },
  { category: "entertainment", weight: 3, minAmount: 30000, maxAmount: 100000 },

  // Shopping (~8%)
  { category: "shopping", weight: 2, minAmount: 50000, maxAmount: 200000 },
  { category: "shopping", weight: 2, minAmount: 100000, maxAmount: 300000 },

  // Utilities (~5%)
  { category: "utilities", weight: 1, minAmount: 50000, maxAmount: 200000 },

  // Healthcare (~2%)
  { category: "healthcare", weight: 1, minAmount: 30000, maxAmount: 150000 },
];

const PAYMENT_METHODS = ["cash", "card", "momo", "banking"];

// Income templates - using relative dates from today
const getIncomeTemplates = () => {
  const today = new Date();

  // Income 1: 5 days ago
  const date1 = new Date(today);
  date1.setDate(today.getDate() - 5);

  // Income 2: 15 days ago
  const date2 = new Date(today);
  date2.setDate(today.getDate() - 15);

  // Income 3: 10 days ago
  const date3 = new Date(today);
  date3.setDate(today.getDate() - 10);

  return [
    {
      category: "salary",
      title: "Lương tháng 10",
      amount: 8000000,
      paymentMethod: "banking",
      date: date1,
    },
    {
      category: "parttime",
      title: "Thu nhập part-time",
      amount: 2000000,
      paymentMethod: "cash",
      date: date2,
    },
    {
      category: "scholarship",
      title: "Học bổng học kỳ 1",
      amount: 3000000,
      paymentMethod: "banking",
      date: date3,
    },
  ];
};

const DESCRIPTIONS = {
  food: [
    "Ăn trưa quán cơm",
    "Cafe sáng",
    "Ăn tối",
    "Mua đồ ăn siêu thị",
    "Trà sữa",
    "Ăn vặt",
    "Mua hoa quả",
    "Cơm văn phòng",
  ],
  transport: [
    "Grab đi học",
    "Xe bus",
    "Đổ xăng",
    "Grab về nhà",
    "Gửi xe",
    "Taxi",
    "Xe ôm",
  ],
  education: [
    "Mua sách giáo trình",
    "In tài liệu",
    "Đóng học phí",
    "Khóa học online",
    "Mua văn phòng phẩm",
    "Photocopy",
  ],
  entertainment: [
    "Xem phim",
    "Đi chơi cuối tuần",
    "Game online",
    "Karaoke",
    "Du lịch ngắn ngày",
  ],
  shopping: [
    "Mua quần áo",
    "Mua giày",
    "Mua phụ kiện",
    "Đồ dùng cá nhân",
    "Mỹ phẩm",
  ],
  utilities: ["Tiền điện", "Tiền nước", "Tiền internet", "Tiền điện thoại"],
  healthcare: ["Mua thuốc", "Khám bệnh", "Vitamin"],
};

// Helper functions
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const randomElement = (array) => array[randomInt(0, array.length - 1)];

const getRandomExpenseTemplate = () => {
  const totalWeight = EXPENSE_TEMPLATES.reduce((sum, t) => sum + t.weight, 0);
  let random = Math.random() * totalWeight;

  for (const template of EXPENSE_TEMPLATES) {
    random -= template.weight;
    if (random <= 0) return template;
  }

  return EXPENSE_TEMPLATES[0];
};

const getRandomDate = () => {
  // Last 30 days from today
  const endDate = new Date(); // Today
  const startDate = new Date();
  startDate.setDate(endDate.getDate() - 30); // 30 days ago
  const randomTime = startDate.getTime() + Math.random() * (endDate.getTime() - startDate.getTime());
  return new Date(randomTime);
};

const generateIncomes = (userId) => {
  const templates = getIncomeTemplates(); // Use function to get current dates
  const incomes = templates.map((template) => ({
    userId,
    amount: mongoose.Types.Decimal128.fromString(template.amount.toString()),
    category: template.category,
    title: template.title,
    description: template.title,
    paymentMethod: template.paymentMethod,
    date: template.date,
    isConfirmed: true,
    createdAt: template.date,
    updatedAt: template.date,
  }));

  // Sort by date
  incomes.sort((a, b) => a.date - b.date);

  return incomes;
};

const generateExpenses = (userId) => {
  const expenses = [];

  for (let i = 0; i < SEED_CONFIG.expenseCount; i++) {
    const template = getRandomExpenseTemplate();
    const amount = randomInt(template.minAmount, template.maxAmount);
    const category = template.category;
    const description = randomElement(DESCRIPTIONS[category]);
    const paymentMethod = randomElement(PAYMENT_METHODS);
    const date = getRandomDate();

    expenses.push({
      userId,
      amount: mongoose.Types.Decimal128.fromString(amount.toString()),
      category,
      title: description, // Add title field
      description,
      paymentMethod,
      date,
      createdAt: date,
      updatedAt: date,
    });
  }

  // Sort by date
  expenses.sort((a, b) => a.date - b.date);

  return expenses;
};

const calculateCategoryTotals = (expenses) => {
  const totals = {};

  for (const expense of expenses) {
    const category = expense.category;
    const amount = parseFloat(expense.amount.toString());
    totals[category] = (totals[category] || 0) + amount;
  }

  return totals;
};

const generateBudget = (userId, expenses) => {
  const categoryTotals = calculateCategoryTotals(expenses);
  const totalSpent = Object.values(categoryTotals).reduce((sum, val) => sum + val, 0);
  const totalBudget = SEED_CONFIG.monthlyBudget;

  // Create category allocations based on actual spending + buffer
  const categoryAllocations = Object.entries(categoryTotals).map(([category, spent]) => {
    const allocated = Math.ceil(spent * 1.2); // 20% buffer
    const percentage = (allocated / totalBudget) * 100;

    return {
      category,
      allocated: mongoose.Types.Decimal128.fromString(allocated.toString()),
      spent: mongoose.Types.Decimal128.fromString(spent.toString()),
      remaining: mongoose.Types.Decimal128.fromString((allocated - spent).toString()),
      percentage: Math.min(percentage, 100), // Cap at 100%
    };
  });

  const budget = {
    userId,
    name: "Ngân sách tháng 10",
    period: {
      startDate: new Date(2025, 9, 1), // Oct 1, 2025
      endDate: new Date(2025, 9, 31), // Oct 31, 2025
      type: "monthly",
    },
    startDate: new Date(2025, 9, 1),
    endDate: new Date(2025, 9, 31),
    totalAmount: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
    categoryAllocations,
    status: {
      totalSpent: mongoose.Types.Decimal128.fromString(totalSpent.toString()),
      spentPercentage: (totalSpent / totalBudget) * 100,
      isOverBudget: totalSpent > totalBudget,
    },
    alertThreshold: 80,
    notificationsEnabled: true,
    isActive: true,
  };

  return budget;
};

const updateUserStats = async (userId, expenses, incomes) => {
  const totalTransactions = expenses.length + incomes.length;
  const points = totalTransactions * 10; // 10 points per transaction
  const level = Math.floor(points / 100) + 1;

  const totalIncome = incomes.reduce((sum, inc) => sum + parseFloat(inc.amount.toString()), 0);
  const totalExpenses = expenses.reduce((sum, exp) => sum + parseFloat(exp.amount.toString()), 0);
  const currentBalance = totalIncome - totalExpenses;

  await User.findByIdAndUpdate(userId, {
    $set: {
      "stats.level": level,
      "stats.points": points,
      "stats.totalTransactions": totalTransactions,
      "stats.currentStreak": 7, // 7 days streak
      "stats.longestStreak": 10,
      "financialSummary.monthlyAllowance": mongoose.Types.Decimal128.fromString(SEED_CONFIG.monthlyAllowance.toString()),
      "financialSummary.currentBalance": mongoose.Types.Decimal128.fromString(currentBalance.toString()),
      "financialSummary.totalIncome": mongoose.Types.Decimal128.fromString(totalIncome.toString()),
      "financialSummary.totalExpenses": mongoose.Types.Decimal128.fromString(totalExpenses.toString()),
      "financialSummary.lastUpdated": new Date(),
    },
  });
};

// Main seed function
const seedUserData = async () => {
  try {
    console.log("🌱 Starting seed process...");

    // Connect to database
    await connectDB();
    console.log("✅ Connected to database");

    // Verify user exists
    const user = await User.findById(USER_ID);
    if (!user) {
      console.error(`❌ User ${USER_EMAIL} not found!`);
      process.exit(1);
    }
    console.log(`✅ Found user: ${user.email}`);

    // Clear existing data for this user
    await Expense.deleteMany({ userId: USER_ID });
    await Income.deleteMany({ userId: USER_ID });
    await Budget.deleteMany({ userId: USER_ID });
    console.log("🗑️  Cleared existing expenses, incomes, and budgets");

    // Generate and insert incomes
    const incomes = generateIncomes(USER_ID);
    const insertedIncomes = await Income.insertMany(incomes);
    console.log(`✅ Created ${insertedIncomes.length} income transactions`);

    const totalIncome = incomes.reduce((sum, inc) => sum + parseFloat(inc.amount.toString()), 0);
    console.log(`💵 Total income: ${totalIncome.toLocaleString()} VND`);

    // Generate and insert expenses
    const expenses = generateExpenses(USER_ID);
    const insertedExpenses = await Expense.insertMany(expenses);
    console.log(`✅ Created ${insertedExpenses.length} expenses`);

    // Calculate totals
    const categoryTotals = calculateCategoryTotals(expenses);
    console.log("📊 Category spending:");
    Object.entries(categoryTotals).forEach(([category, total]) => {
      console.log(`   - ${category}: ${total.toLocaleString()} VND`);
    });

    const totalSpent = Object.values(categoryTotals).reduce((sum, val) => sum + val, 0);
    console.log(`💰 Total spent: ${totalSpent.toLocaleString()} VND`);

    // Generate and insert budget
    const budget = generateBudget(USER_ID, expenses);
    const insertedBudget = await Budget.create(budget);
    console.log(`✅ Created budget: ${insertedBudget.name}`);
    console.log(`   - Total: ${SEED_CONFIG.monthlyBudget.toLocaleString()} VND`);
    console.log(`   - Spent: ${totalSpent.toLocaleString()} VND (${budget.status.spentPercentage.toFixed(1)}%)`);
    console.log(`   - Remaining: ${(SEED_CONFIG.monthlyBudget - totalSpent).toLocaleString()} VND`);
    console.log(`   - Status: ${budget.status.isOverBudget ? "⚠️  Over budget" : "✅ Within budget"}`);

    // Update user stats and financial summary
    await updateUserStats(USER_ID, expenses, incomes);
    console.log("✅ Updated user stats and financial summary");

    const currentBalance = totalIncome - totalSpent;

    console.log("\n🎉 Seed completed successfully!");
    console.log("\n📝 Summary:");
    console.log(`   - Incomes: ${insertedIncomes.length} (Total: ${totalIncome.toLocaleString()} VND)`);
    console.log(`   - Expenses: ${insertedExpenses.length} (Total: ${totalSpent.toLocaleString()} VND)`);
    console.log(`   - Current Balance: ${currentBalance.toLocaleString()} VND`);
    console.log(`   - Budget: ${SEED_CONFIG.monthlyBudget.toLocaleString()} VND`);
    console.log(`   - Monthly Allowance: ${SEED_CONFIG.monthlyAllowance.toLocaleString()} VND`);
    console.log(`   - User level: ${Math.floor((expenses.length + incomes.length) * 10 / 100) + 1}`);
    console.log(`   - User points: ${(expenses.length + incomes.length) * 10}`);

  } catch (error) {
    console.error("❌ Error seeding data:", error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log("\n👋 Database connection closed");
  }
};

// Run seed
seedUserData();
