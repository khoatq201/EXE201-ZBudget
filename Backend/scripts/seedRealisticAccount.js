import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import {
  User,
  Expense,
  Income,
  Budget,
  Challenge,
  UserChallenge,
  SavingsGoal,
  connectDB,
} from "../models/index.js";

/**
 * ============================================================================
 * SEED REALISTIC ACCOUNT - TẠO TÀI KHOẢN VỚI DATA THỰC TẾ CHI TIẾT
 * ============================================================================
 *
 * Script này tạo một tài khoản với:
 * - Profile chi tiết và thực tế
 * - Thu nhập ổn định (lương, bonus, part-time)
 * - Chi tiêu đa dạng qua 3 tháng
 * - Ngân sách cho tháng hiện tại
 * - Mục tiêu tiết kiệm
 * - Tham gia challenges
 * - Stats và gamification đầy đủ
 */

// ============================================================================
// CẤU HÌNH TÀI KHOẢN
// ============================================================================
const ACCOUNT_CONFIG = {
  // Thông tin cơ bản
  email: "minhkhoi.dev98@gmail.com",
  password: "zbudget2024",
  name: "Nguyễn Minh Khôi",
  profession: "Software Engineer",
  city: "Hồ Chí Minh",
  phone: "0901234567",
  dateOfBirth: new Date(1998, 5, 15), // June 15, 1998
  gender: "male",
  bio: "Dev yêu công nghệ | Coffee lover ☕ | Minimalist lifestyle 🌱",

  // Thu nhập hàng tháng
  monthlyIncome: {
    salary: 18000000, // 18M VND
    bonus: 2000000, // 2M bonus/quarter
    parttime: 3000000, // 3M freelance
  },

  // Ngân sách tháng
  monthlyBudget: 15000000, // 15M VND

  // Mục tiêu tiết kiệm
  savingsGoal: {
    target: 50000000, // 50M VND
    purpose: "Mua Macbook M3 Pro",
    deadline: new Date(2026, 5, 1), // June 1, 2026
  },
};

// ============================================================================
// DỮ LIỆU THU NHẬP - 3 THÁNG GẦN ĐÂY
// ============================================================================
const INCOME_DATA = [
  // Tháng 10/2025
  {
    date: new Date(2025, 9, 1), // Oct 1
    title: "Lương tháng 10",
    amount: 18000000,
    category: "salary",
    description: "Lương chính thức tháng 10/2025",
    paymentMethod: "banking",
  },
  {
    date: new Date(2025, 9, 15), // Oct 15
    title: "Freelance project - Landing page",
    amount: 3000000,
    category: "freelance",
    description: "Làm landing page cho startup X",
    paymentMethod: "banking",
  },

  // Tháng 11/2025
  {
    date: new Date(2025, 10, 1), // Nov 1
    title: "Lương tháng 11",
    amount: 18000000,
    category: "salary",
    description: "Lương chính thức tháng 11/2025",
    paymentMethod: "banking",
  },
  {
    date: new Date(2025, 10, 10), // Nov 10
    title: "Bonus Q3",
    amount: 2000000,
    category: "bonus",
    description: "Thưởng quý 3/2025",
    paymentMethod: "banking",
  },
  {
    date: new Date(2025, 10, 20), // Nov 20
    title: "Freelance - API Development",
    amount: 3000000,
    category: "freelance",
    description: "Phát triển REST API cho client",
    paymentMethod: "momo",
  },

  // Tháng 12/2025 (hiện tại)
  {
    date: new Date(2025, 11, 1), // Dec 1
    title: "Lương tháng 12",
    amount: 18000000,
    category: "salary",
    description: "Lương chính thức tháng 12/2025",
    paymentMethod: "banking",
  },
  {
    date: new Date(2025, 11, 8), // Dec 8
    title: "Freelance - Mobile App UI",
    amount: 3500000,
    category: "freelance",
    description: "Thiết kế UI cho app di động",
    paymentMethod: "banking",
  },
];

// ============================================================================
// DỮ LIỆU CHI TIÊU - 3 THÁNG THỰC TẾ
// ============================================================================
const EXPENSE_CATEGORIES = {
  food: {
    weight: 35,
    descriptions: [
      "Ăn sáng bánh mì",
      "Cơm trưa văn phòng",
      "Ăn tối phở",
      "Cafe sáng Highlands",
      "Trà sữa Gongcha",
      "Ăn vặt 7-Eleven",
      "Cơm gà ThaiExpress",
      "Lẩu hải sản cuối tuần",
      "Pizza với bạn bè",
      "Buffet BBQ",
      "Mua đồ ăn siêu thị",
      "Cafe làm việc The Coffee House",
    ],
    minAmount: 20000,
    maxAmount: 300000,
  },
  transport: {
    weight: 15,
    descriptions: [
      "Grab đi làm",
      "Grab về nhà",
      "Đổ xăng xe",
      "Grab đi meeting",
      "Xe buýt",
      "Gửi xe mall",
      "Taxi sân bay",
      "Grab Food delivery",
    ],
    minAmount: 15000,
    maxAmount: 150000,
  },
  shopping: {
    weight: 20,
    descriptions: [
      "Mua áo thun Uniqlo",
      "Giày sneaker Nike",
      "Quần jean",
      "Đồ công sở",
      "Phụ kiện điện thoại",
      "Tai nghe Bluetooth",
      "Đồ dùng văn phòng",
      "Sách kỹ thuật",
      "Decor bàn làm việc",
      "Mua đồ online Shopee",
    ],
    minAmount: 50000,
    maxAmount: 1500000,
  },
  entertainment: {
    weight: 12,
    descriptions: [
      "Xem phim CGV",
      "Karaoke với team",
      "Game Steam",
      "Netflix subscription",
      "Spotify Premium",
      "Đi bar cuối tuần",
      "Bowling",
      "Đi du lịch Đà Lạt",
      "Vé concert",
    ],
    minAmount: 50000,
    maxAmount: 500000,
  },
  healthcare: {
    weight: 8,
    descriptions: [
      "Khám nha khoa",
      "Mua thuốc",
      "Vitamin tổng hợp",
      "Khám sức khỏe định kỳ",
      "Phí phòng gym",
      "Protein shake",
    ],
    minAmount: 50000,
    maxAmount: 800000,
  },
  education: {
    weight: 6,
    descriptions: [
      "Khóa học Udemy",
      "Sách lập trình",
      "Course Coursera",
      "Workshop công nghệ",
      "Hội thảo kỹ thuật",
    ],
    minAmount: 100000,
    maxAmount: 2000000,
  },
  utilities: {
    weight: 4,
    descriptions: [
      "Tiền điện",
      "Tiền nước",
      "Internet FPT",
      "Tiền điện thoại",
      "Phí dịch vụ nhà",
    ],
    minAmount: 100000,
    maxAmount: 500000,
  },
};

const PAYMENT_METHODS = ["cash", "card", "momo", "banking"];

// Helper functions
const randomInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (array) => array[randomInt(0, array.length - 1)];
const randomBoolean = (probability = 0.5) => Math.random() < probability;

const getRandomDateInMonth = (year, month) => {
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const randomDay = randomInt(1, daysInMonth);
  const randomHour = randomInt(6, 22);
  return new Date(year, month, randomDay, randomHour, randomInt(0, 59));
};

const generateExpensesForMonth = (userId, year, month, totalExpenses = 60) => {
  const expenses = [];
  const categories = Object.keys(EXPENSE_CATEGORIES);
  const totalWeight = Object.values(EXPENSE_CATEGORIES).reduce(
    (sum, cat) => sum + cat.weight,
    0
  );

  for (let i = 0; i < totalExpenses; i++) {
    // Chọn category theo trọng số
    let random = Math.random() * totalWeight;
    let selectedCategory = categories[0];

    for (const category of categories) {
      random -= EXPENSE_CATEGORIES[category].weight;
      if (random <= 0) {
        selectedCategory = category;
        break;
      }
    }

    const catData = EXPENSE_CATEGORIES[selectedCategory];
    const amount = randomInt(catData.minAmount, catData.maxAmount);
    const description = randomElement(catData.descriptions);
    const date = getRandomDateInMonth(year, month);

    expenses.push({
      userId,
      amount: mongoose.Types.Decimal128.fromString(amount.toString()),
      category: selectedCategory,
      title: description,
      description,
      paymentMethod: randomElement(PAYMENT_METHODS),
      date,
      createdAt: date,
      updatedAt: date,
    });
  }

  return expenses.sort((a, b) => a.date - b.date);
};

// ============================================================================
// TẠO USER VỚI PROFILE ĐẦY ĐỦ
// ============================================================================
async function createRealisticUser() {
  console.log("\n👤 Đang tạo user với profile thực tế...");

  // Kiểm tra user đã tồn tại
  const existingUser = await User.findOne({ email: ACCOUNT_CONFIG.email });
  if (existingUser) {
    console.log(`   ⚠️  User ${ACCOUNT_CONFIG.email} đã tồn tại!`);
    console.log(`   🗑️  Đang xóa dữ liệu cũ...`);

    // Xóa tất cả dữ liệu liên quan
    await Expense.deleteMany({ userId: existingUser._id });
    await Income.deleteMany({ userId: existingUser._id });
    await Budget.deleteMany({ userId: existingUser._id });
    await UserChallenge.deleteMany({ userId: existingUser._id });
    await SavingsGoal.deleteMany({ userId: existingUser._id });
    await User.deleteOne({ _id: existingUser._id });

    console.log(`   ✅ Đã xóa user cũ và dữ liệu liên quan`);
  }

  const password = await bcrypt.hash(ACCOUNT_CONFIG.password, 10);

  const user = await User.create({
    email: ACCOUNT_CONFIG.email,
    passwordHash: password,
    authProvider: "local",
    isEmailVerified: true,
    profile: {
      name: ACCOUNT_CONFIG.name,
      avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(
        ACCOUNT_CONFIG.name
      )}&background=4A90E2&color=fff&size=200`,
      phone: ACCOUNT_CONFIG.phone,
      dateOfBirth: ACCOUNT_CONFIG.dateOfBirth,
      gender: ACCOUNT_CONFIG.gender,
      location: {
        city: ACCOUNT_CONFIG.city,
        country: "Vietnam",
      },
      bio: ACCOUNT_CONFIG.bio,
      occupation: ACCOUNT_CONFIG.profession,
    },
    settings: {
      currency: { primary: "VND", displayFormat: "đ", decimalPlaces: 0 },
      language: "vi",
      theme: "light",
      notifications: {
        challenges: true,
        budgetAlerts: true,
        groupActivities: true,
        weeklyReports: true,
        pushEnabled: true,
      },
    },
    stats: {
      level: 1,
      points: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalSaved: mongoose.Types.Decimal128.fromString("0"),
      challengesCompleted: 0,
      rank: "Bronze",
    },
    financialSummary: {
      monthlyAllowance: mongoose.Types.Decimal128.fromString(
        ACCOUNT_CONFIG.monthlyBudget.toString()
      ),
      currentBalance: mongoose.Types.Decimal128.fromString("0"),
      totalIncome: mongoose.Types.Decimal128.fromString("0"),
      totalExpenses: mongoose.Types.Decimal128.fromString("0"),
    },
    createdAt: new Date(2025, 8, 1), // Sept 1, 2025
    updatedAt: new Date(),
  });

  console.log(`✅ Đã tạo user: ${user.email} (ID: ${user._id})`);
  return user;
}

// ============================================================================
// TẠO THU NHẬP
// ============================================================================
async function createIncomes(userId) {
  console.log("\n💵 Đang tạo dữ liệu thu nhập...");

  const incomes = INCOME_DATA.map((inc) => ({
    userId,
    amount: mongoose.Types.Decimal128.fromString(inc.amount.toString()),
    title: inc.title,
    description: inc.description,
    category: inc.category,
    paymentMethod: inc.paymentMethod,
    date: inc.date,
    isConfirmed: true,
    createdAt: inc.date,
    updatedAt: inc.date,
  }));

  const inserted = await Income.insertMany(incomes);
  const totalIncome = incomes.reduce(
    (sum, inc) => sum + parseFloat(inc.amount.toString()),
    0
  );

  console.log(`✅ Đã tạo ${inserted.length} thu nhập`);
  console.log(`💰 Tổng thu nhập: ${totalIncome.toLocaleString()} VND`);

  return inserted;
}

// ============================================================================
// TẠO CHI TIÊU 3 THÁNG
// ============================================================================
async function createExpenses(userId) {
  console.log("\n💸 Đang tạo dữ liệu chi tiêu 3 tháng...");

  const allExpenses = [];

  // Tháng 10/2025 - 50 expenses
  const oct2025 = generateExpensesForMonth(userId, 2025, 9, 50);
  allExpenses.push(...oct2025);

  // Tháng 11/2025 - 55 expenses
  const nov2025 = generateExpensesForMonth(userId, 2025, 10, 55);
  allExpenses.push(...nov2025);

  // Tháng 12/2025 (hiện tại) - 40 expenses cho đến nay
  const dec2025 = generateExpensesForMonth(userId, 2025, 11, 40);
  allExpenses.push(...dec2025);

  const inserted = await Expense.insertMany(allExpenses);

  // Thống kê theo tháng
  const statsByMonth = {};
  for (const exp of allExpenses) {
    const month = exp.date.getMonth();
    const year = exp.date.getFullYear();
    const key = `${year}-${month + 1}`;

    if (!statsByMonth[key]) {
      statsByMonth[key] = { count: 0, total: 0 };
    }

    statsByMonth[key].count++;
    statsByMonth[key].total += parseFloat(exp.amount.toString());
  }

  console.log(`✅ Đã tạo ${inserted.length} chi tiêu`);
  console.log("\n📊 Chi tiêu theo tháng:");
  Object.entries(statsByMonth).forEach(([month, stats]) => {
    console.log(
      `   ${month}: ${
        stats.count
      } giao dịch - ${stats.total.toLocaleString()} VND`
    );
  });

  return inserted;
}

// ============================================================================
// TẠO NGÂN SÁCH THÁNG HIỆN TẠI
// ============================================================================
async function createBudget(userId, expenses) {
  console.log("\n📊 Đang tạo ngân sách tháng 12/2025...");

  // Lấy expenses tháng 12
  const dec2025Expenses = expenses.filter((exp) => {
    const month = exp.date.getMonth();
    const year = exp.date.getFullYear();
    return year === 2025 && month === 11;
  });

  // Tính toán theo category
  const categoryTotals = {};
  for (const exp of dec2025Expenses) {
    const cat = exp.category;
    if (!categoryTotals[cat]) categoryTotals[cat] = 0;
    categoryTotals[cat] += parseFloat(exp.amount.toString());
  }

  const totalBudget = ACCOUNT_CONFIG.monthlyBudget;
  const totalSpent = Object.values(categoryTotals).reduce(
    (sum, val) => sum + val,
    0
  );

  // Tạo category allocations
  const categoryAllocations = [];
  const categories = [
    "food",
    "transport",
    "shopping",
    "entertainment",
    "healthcare",
    "education",
    "utilities",
  ];
  const allocations = {
    food: 0.35,
    transport: 0.15,
    shopping: 0.2,
    entertainment: 0.12,
    healthcare: 0.08,
    education: 0.06,
    utilities: 0.04,
  };

  for (const cat of categories) {
    const allocated = Math.round(totalBudget * allocations[cat]);
    const spent = categoryTotals[cat] || 0;
    const remaining = allocated - spent;

    categoryAllocations.push({
      category: cat,
      allocated: mongoose.Types.Decimal128.fromString(allocated.toString()),
      funded: mongoose.Types.Decimal128.fromString(allocated.toString()),
      spent: mongoose.Types.Decimal128.fromString(spent.toString()),
      available: mongoose.Types.Decimal128.fromString(remaining.toString()),
      remaining: mongoose.Types.Decimal128.fromString(remaining.toString()),
      percentage: (allocated / totalBudget) * 100,
      lastUpdated: new Date(),
    });
  }

  const budget = await Budget.create({
    userId,
    name: "Ngân sách tháng 12/2025",
    period: {
      startDate: new Date(2025, 11, 1),
      endDate: new Date(2025, 11, 31),
      type: "monthly",
    },
    startDate: new Date(2025, 11, 1),
    endDate: new Date(2025, 11, 31),
    totalAmount: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
    totalAllocated: mongoose.Types.Decimal128.fromString(
      totalBudget.toString()
    ),
    totalFunded: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
    categoryAllocations,
    fundingStatus: {
      totalFunded: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
      fundingPercentage: 100,
      underfunded: false,
      overfunded: false,
    },
    status: {
      totalSpent: mongoose.Types.Decimal128.fromString(totalSpent.toString()),
      totalRemaining: mongoose.Types.Decimal128.fromString(
        (totalBudget - totalSpent).toString()
      ),
      spentPercentage: Math.round((totalSpent / totalBudget) * 100 * 100) / 100,
      isOverBudget: totalSpent > totalBudget,
      daysRemaining: 31 - new Date().getDate(),
      dailyAverageSpent: mongoose.Types.Decimal128.fromString(
        (totalSpent / new Date().getDate()).toString()
      ),
      projectedTotal: mongoose.Types.Decimal128.fromString(
        ((totalSpent / new Date().getDate()) * 31).toString()
      ),
    },
    alerts: {
      thresholds: [50, 75, 90],
      alertsSent: [],
    },
    alertThreshold: 80,
    notificationsEnabled: true,
    isActive: true,
  });

  console.log(`✅ Đã tạo ngân sách: ${budget.name}`);
  console.log(`   - Tổng: ${totalBudget.toLocaleString()} VND`);
  console.log(
    `   - Đã chi: ${totalSpent.toLocaleString()} VND (${
      budget.status.spentPercentage
    }%)`
  );
  console.log(
    `   - Còn lại: ${(totalBudget - totalSpent).toLocaleString()} VND`
  );

  return budget;
}

// ============================================================================
// TẠO MỤC TIÊU TIẾT KIỆM
// ============================================================================
async function createSavingsGoal(userId) {
  console.log("\n🎯 Đang tạo mục tiêu tiết kiệm...");

  const goal = await SavingsGoal.create({
    userId,
    name: ACCOUNT_CONFIG.savingsGoal.purpose,
    targetAmount: mongoose.Types.Decimal128.fromString(
      ACCOUNT_CONFIG.savingsGoal.target.toString()
    ),
    currentAmount: mongoose.Types.Decimal128.fromString("15000000"), // Đã tiết kiệm được 15M
    currency: "VND",
    targetDate: ACCOUNT_CONFIG.savingsGoal.deadline,
    category: "gadget",
    priority: "high",
    status: "active",
    autoSave: {
      enabled: true,
      amount: mongoose.Types.Decimal128.fromString("5000000"),
      frequency: "monthly",
    },
    contributions: [
      {
        amount: mongoose.Types.Decimal128.fromString("5000000"),
        date: new Date(2025, 9, 5),
        source: "transfer",
        note: "Tiết kiệm từ lương tháng 10",
      },
      {
        amount: mongoose.Types.Decimal128.fromString("5000000"),
        date: new Date(2025, 10, 5),
        source: "transfer",
        note: "Tiết kiệm từ lương tháng 11",
      },
      {
        amount: mongoose.Types.Decimal128.fromString("5000000"),
        date: new Date(2025, 11, 5),
        source: "transfer",
        note: "Tiết kiệm từ lương tháng 12",
      },
    ],
    milestones: [
      {
        amount: mongoose.Types.Decimal128.fromString("10000000"),
        description: "20% mục tiêu",
        achieved: true,
        achievedAt: new Date(2025, 10, 5),
      },
      {
        amount: mongoose.Types.Decimal128.fromString("25000000"),
        description: "50% mục tiêu",
        achieved: false,
      },
      {
        amount: mongoose.Types.Decimal128.fromString("50000000"),
        description: "Hoàn thành mục tiêu",
        achieved: false,
      },
    ],
  });

  const progress = (15000000 / ACCOUNT_CONFIG.savingsGoal.target) * 100;
  console.log(`✅ Đã tạo mục tiêu: ${goal.name}`);
  console.log(
    `   - Mục tiêu: ${ACCOUNT_CONFIG.savingsGoal.target.toLocaleString()} VND`
  );
  console.log(`   - Đã tiết kiệm: 15,000,000 VND (${progress.toFixed(1)}%)`);

  return goal;
}

// ============================================================================
// CẬP NHẬT STATS VÀ FINANCIAL SUMMARY
// ============================================================================
async function updateUserStats(userId, incomes, expenses) {
  console.log("\n📈 Đang cập nhật stats và financial summary...");

  const totalIncome = incomes.reduce(
    (sum, inc) => sum + parseFloat(inc.amount.toString()),
    0
  );
  const totalExpenses = expenses.reduce(
    (sum, exp) => sum + parseFloat(exp.amount.toString()),
    0
  );
  const currentBalance = totalIncome - totalExpenses;

  const totalTransactions = incomes.length + expenses.length;
  const points = totalTransactions * 10 + 500; // Bonus 500 points
  const level = Math.floor(points / 1000) + 1;

  await User.findByIdAndUpdate(userId, {
    $set: {
      "stats.level": level,
      "stats.points": points,
      "stats.currentStreak": 12,
      "stats.longestStreak": 15,
      "stats.totalSaved": mongoose.Types.Decimal128.fromString("15000000"),
      "stats.challengesCompleted": 2,
      "stats.rank": level >= 5 ? "Gold" : level >= 3 ? "Silver" : "Bronze",
      "financialSummary.currentBalance": mongoose.Types.Decimal128.fromString(
        currentBalance.toString()
      ),
      "financialSummary.totalIncome": mongoose.Types.Decimal128.fromString(
        totalIncome.toString()
      ),
      "financialSummary.totalExpenses": mongoose.Types.Decimal128.fromString(
        totalExpenses.toString()
      ),
      "financialSummary.lastUpdated": new Date(),
    },
  });

  console.log(`✅ Đã cập nhật stats:`);
  console.log(`   - Level: ${level}`);
  console.log(`   - Points: ${points}`);
  console.log(`   - Current Balance: ${currentBalance.toLocaleString()} VND`);
  console.log(`   - Total Income: ${totalIncome.toLocaleString()} VND`);
  console.log(`   - Total Expenses: ${totalExpenses.toLocaleString()} VND`);
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================
async function main() {
  try {
    console.log("\n" + "=".repeat(70));
    console.log("🌱 SEED REALISTIC ACCOUNT - TẠO TÀI KHOẢN VỚI DATA THỰC TẾ");
    console.log("=".repeat(70));

    await connectDB();
    console.log("✅ Đã kết nối MongoDB");

    // Tạo user
    const user = await createRealisticUser();

    // Tạo incomes
    const incomes = await createIncomes(user._id);

    // Tạo expenses
    const expenses = await createExpenses(user._id);

    // Tạo budget
    await createBudget(user._id, expenses);

    // Tạo savings goal
    await createSavingsGoal(user._id);

    // Cập nhật stats
    await updateUserStats(user._id, incomes, expenses);

    console.log("\n" + "=".repeat(70));
    console.log("🎉 HOÀN TẤT! TÀI KHOẢN ĐÃ ĐƯỢC TẠO THÀNH CÔNG");
    console.log("=".repeat(70));
    console.log("\n🔑 THÔNG TIN ĐĂNG NHẬP:");
    console.log("   📧 Email: " + ACCOUNT_CONFIG.email);
    console.log("   🔐 Password: " + ACCOUNT_CONFIG.password);
    console.log("   👤 Tên: " + ACCOUNT_CONFIG.name);
    console.log("\n📊 TỔNG QUAN DỮ LIỆU:");
    console.log(`   - Thu nhập: ${incomes.length} giao dịch`);
    console.log(`   - Chi tiêu: ${expenses.length} giao dịch (3 tháng)`);
    console.log(`   - Ngân sách: Tháng 12/2025`);
    console.log(
      `   - Mục tiêu tiết kiệm: ${ACCOUNT_CONFIG.savingsGoal.purpose}`
    );
    console.log("=".repeat(70));
    console.log("\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
