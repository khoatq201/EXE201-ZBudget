import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import {
  User,
  Expense,
  Income,
  Budget,
  Challenge,
  UserChallenge,
  Group,
  SavingsGoal,
  connectDB,
} from "../models/index.js";

// ============================================================================
// REALISTIC VIETNAMESE USERS - CHỈ THÊM MỚI, KHÔNG XÓA
// ============================================================================
const REALISTIC_USERS = [
  {
    name: "Nguyễn Minh Quân",
    email: "minhtquan.dev@gmail.com",
    profession: "Software Engineer",
    city: "Hồ Chí Minh",
    bio: "Dev yêu công nghệ, thích du lịch và cafe",
  },
  {
    name: "Trần Thùy Linh",
    email: "thuylinhh.2k1@gmail.com",
    profession: "Marketing Manager",
    city: "Hà Nội",
    bio: "Marketing enthusiast, foodie, travel lover 🌏",
  },
  {
    name: "Lê Hoàng Anh",
    email: "hoanganh.le95@outlook.com",
    profession: "Business Analyst",
    city: "Đà Nẵng",
    bio: "Data analyst | Coffee addict ☕",
  },
  {
    name: "Phạm Thu Hà",
    email: "phamthuha.work@yahoo.com",
    profession: "UX/UI Designer",
    city: "Hồ Chí Minh",
    bio: "Design thinking | Minimalist lifestyle",
  },
  {
    name: "Võ Minh Tuấn",
    email: "vm.tuan2198@gmail.com",
    profession: "Financial Advisor",
    city: "Hà Nội",
    bio: "Tư vấn tài chính cá nhân | Đầu tư chứng khoán",
  },
  {
    name: "Đặng Khánh Linh",
    email: "klinh.dang@gmail.com",
    profession: "Content Creator",
    city: "Đà Lạt",
    bio: "Blogger | Photography | Lifestyle",
  },
  {
    name: "Ngô Đức Thắng",
    email: "ducthang.ngo@outlook.com",
    profession: "Product Manager",
    city: "Hồ Chí Minh",
    bio: "Tech PM | Startup enthusiast 🚀",
  },
  {
    name: "Bùi Thanh Tâm",
    email: "tamthanh.bui94@gmail.com",
    profession: "HR Manager",
    city: "Hà Nội",
    bio: "People & Culture | Mental health advocate",
  },
  {
    name: "Hoàng Quốc Việt",
    email: "quocviet.hoang@yahoo.com",
    profession: "Sales Director",
    city: "Cần Thơ",
    bio: "Sales leader | Golf player ⛳",
  },
  {
    name: "Đinh Thu Trang",
    email: "thutrangdinh@gmail.com",
    profession: "Teacher",
    city: "Hải Phòng",
    bio: "Giáo viên tiếng Anh | Book lover 📚",
  },
];

// Helper functions
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randomElement = (array) => array[randomInt(0, array.length - 1)];
const randomBoolean = () => Math.random() > 0.5;

const getRandomDate = (daysAgo) => {
  const now = new Date();
  const past = new Date(now);
  past.setDate(now.getDate() - daysAgo);
  const randomTime = past.getTime() + Math.random() * (now.getTime() - past.getTime());
  return new Date(randomTime);
};

// ============================================================================
// ADD USERS - CHỈ THÊM MỚI NẾU CHƯA TỒN TẠI
// ============================================================================
async function addUsers() {
  console.log("\n👥 Đang thêm users mới...");

  const password = await bcrypt.hash("zbudget2024", 10);
  const newUsers = [];
  let skipped = 0;

  for (const userData of REALISTIC_USERS) {
    // Kiểm tra xem email đã tồn tại chưa
    const existingUser = await User.findOne({ email: userData.email });

    if (existingUser) {
      console.log(`   ⏭️  Skip: ${userData.email} (đã tồn tại)`);
      skipped++;
      continue;
    }

    // Tạo user mới
    const user = new User({
      email: userData.email,
      passwordHash: password,
      authProvider: "local",
      isEmailVerified: true,
      profile: {
        name: userData.name,
        avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.name)}&background=${randomElement(['FF6B6B', '4ECDC4', '45B7D1', 'FFA07A'])}&color=fff`,
        phone: `0${randomElement(['90', '91', '93', '94', '96', '97', '98'])}${randomInt(1000000, 9999999)}`,
        dateOfBirth: new Date(randomInt(1990, 2003), randomInt(0, 11), randomInt(1, 28)),
        gender: randomElement(['male', 'female']),
        location: {
          city: userData.city,
          country: "Vietnam",
        },
        bio: userData.bio,
        occupation: userData.profession,
      },
      settings: {
        currency: { primary: "VND", displayFormat: "đ", decimalPlaces: 0 },
        language: "vi",
        theme: randomElement(['light', 'dark', 'auto']),
        notifications: {
          challenges: true,
          budgetAlerts: true,
          groupActivities: true,
          weeklyReports: true,
          pushEnabled: randomBoolean(),
        },
      },
      stats: {
        level: randomInt(1, 10),
        points: randomInt(500, 5000),
        currentStreak: randomInt(1, 30),
        longestStreak: randomInt(10, 60),
        totalSaved: mongoose.Types.Decimal128.fromString(randomInt(1000000, 10000000).toString()),
        challengesCompleted: randomInt(0, 15),
        rank: randomElement(['Bronze', 'Silver', 'Gold', 'Platinum']),
      },
      financialSummary: {
        monthlyAllowance: mongoose.Types.Decimal128.fromString(randomInt(8000000, 30000000).toString()),
        currentBalance: mongoose.Types.Decimal128.fromString("0"),
        totalIncome: mongoose.Types.Decimal128.fromString("0"),
        totalExpenses: mongoose.Types.Decimal128.fromString("0"),
      },
      createdAt: getRandomDate(randomInt(90, 365)),
      updatedAt: new Date(),
    });

    newUsers.push(user);
  }

  if (newUsers.length > 0) {
    await User.insertMany(newUsers);
    console.log(`✅ Đã thêm ${newUsers.length} users mới`);
  }

  if (skipped > 0) {
    console.log(`ℹ️  Đã bỏ qua ${skipped} users (đã tồn tại)`);
  }

  return newUsers;
}

// ============================================================================
// ADD EXPENSES FOR NEW USERS
// ============================================================================
async function addExpensesForUsers(users) {
  if (users.length === 0) return;

  console.log("\n💸 Đang thêm expenses cho users mới...");

  const categories = ['food', 'transport', 'shopping', 'entertainment', 'healthcare', 'education', 'utilities'];
  const descriptions = {
    food: ['Ăn trưa', 'Cafe sáng', 'Ăn tối', 'Mua đồ ăn', 'Trà sữa'],
    transport: ['Grab đi làm', 'Xe bus', 'Đổ xăng', 'Taxi'],
    shopping: ['Mua quần áo', 'Mua giày', 'Mỹ phẩm', 'Đồ dùng'],
    entertainment: ['Xem phim', 'Karaoke', 'Game', 'Du lịch'],
    healthcare: ['Mua thuốc', 'Khám bệnh', 'Vitamin', 'Gym'],
    education: ['Học phí', 'Sách', 'Khóa học', 'In tài liệu'],
    utilities: ['Tiền điện', 'Tiền nước', 'Internet', 'Điện thoại'],
  };

  const allExpenses = [];

  for (const user of users) {
    const expenseCount = randomInt(30, 50);

    for (let i = 0; i < expenseCount; i++) {
      const category = randomElement(categories);
      const expense = new Expense({
        userId: user._id,
        amount: mongoose.Types.Decimal128.fromString(randomInt(15000, 500000).toString()),
        category,
        title: randomElement(descriptions[category]),
        description: randomElement(descriptions[category]),
        paymentMethod: randomElement(['cash', 'card', 'momo', 'banking']),
        date: getRandomDate(60),
        createdAt: getRandomDate(60),
        updatedAt: new Date(),
      });
      allExpenses.push(expense);
    }
  }

  if (allExpenses.length > 0) {
    await Expense.insertMany(allExpenses);
    console.log(`✅ Đã thêm ${allExpenses.length} expenses`);
  }
}

// ============================================================================
// ADD INCOMES FOR NEW USERS
// ============================================================================
async function addIncomesForUsers(users) {
  if (users.length === 0) return;

  console.log("\n💵 Đang thêm incomes cho users mới...");

  const incomeCategories = ['salary', 'bonus', 'freelance', 'investment'];
  const allIncomes = [];

  for (const user of users) {
    for (let i = 0; i < 4; i++) {
      const category = randomElement(incomeCategories);
      const income = new Income({
        userId: user._id,
        amount: mongoose.Types.Decimal128.fromString(randomInt(2000000, 15000000).toString()),
        title: category === 'salary' ? 'Lương tháng' : category === 'bonus' ? 'Thưởng' : `Thu nhập ${category}`,
        description: `Thu nhập từ ${category}`,
        category,
        paymentMethod: randomElement(['banking', 'cash', 'momo']),
        date: getRandomDate(90),
        isConfirmed: true,
        createdAt: getRandomDate(90),
        updatedAt: new Date(),
      });
      allIncomes.push(income);
    }
  }

  if (allIncomes.length > 0) {
    await Income.insertMany(allIncomes);
    console.log(`✅ Đã thêm ${allIncomes.length} incomes`);
  }
}

// ============================================================================
// ADD BUDGETS FOR NEW USERS
// ============================================================================
async function addBudgetsForUsers(users) {
  if (users.length === 0) return;

  console.log("\n📊 Đang thêm budgets cho users mới...");

  const allBudgets = [];

  for (const user of users) {
    const totalBudget = randomInt(5000000, 15000000);

    const budget = new Budget({
      userId: user._id,
      name: "Ngân sách tháng này",
      period: {
        startDate: new Date(2025, 10, 1),
        endDate: new Date(2025, 10, 30),
        type: "monthly",
      },
      startDate: new Date(2025, 10, 1),
      endDate: new Date(2025, 10, 30),
      totalAmount: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
      totalAllocated: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
      totalFunded: mongoose.Types.Decimal128.fromString(totalBudget.toString()),
      categoryAllocations: [
        {
          category: 'food',
          allocated: mongoose.Types.Decimal128.fromString((totalBudget * 0.4).toString()),
          funded: mongoose.Types.Decimal128.fromString((totalBudget * 0.4).toString()),
          spent: mongoose.Types.Decimal128.fromString("0"),
          available: mongoose.Types.Decimal128.fromString((totalBudget * 0.4).toString()),
          remaining: mongoose.Types.Decimal128.fromString((totalBudget * 0.4).toString()),
          percentage: 40,
        },
        {
          category: 'transport',
          allocated: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          funded: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          spent: mongoose.Types.Decimal128.fromString("0"),
          available: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          remaining: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          percentage: 30,
        },
        {
          category: 'entertainment',
          allocated: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          funded: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          spent: mongoose.Types.Decimal128.fromString("0"),
          available: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          remaining: mongoose.Types.Decimal128.fromString((totalBudget * 0.3).toString()),
          percentage: 30,
        },
      ],
      isActive: true,
      createdAt: new Date(2025, 10, 1),
      updatedAt: new Date(),
    });

    allBudgets.push(budget);
  }

  if (allBudgets.length > 0) {
    await Budget.insertMany(allBudgets);
    console.log(`✅ Đã thêm ${allBudgets.length} budgets`);
  }
}

// ============================================================================
// UPDATE USER FINANCIAL SUMMARY
// ============================================================================
async function updateUserFinancialSummary(users) {
  if (users.length === 0) return;

  console.log("\n💰 Đang cập nhật financial summary...");

  for (const user of users) {
    const userIncomes = await Income.find({ userId: user._id });
    const userExpenses = await Expense.find({ userId: user._id });

    const totalIncome = userIncomes.reduce((sum, inc) => sum + parseFloat(inc.amount.toString()), 0);
    const totalExpenses = userExpenses.reduce((sum, exp) => sum + parseFloat(exp.amount.toString()), 0);
    const currentBalance = totalIncome - totalExpenses;

    await User.findByIdAndUpdate(user._id, {
      $set: {
        'financialSummary.totalIncome': mongoose.Types.Decimal128.fromString(totalIncome.toString()),
        'financialSummary.totalExpenses': mongoose.Types.Decimal128.fromString(totalExpenses.toString()),
        'financialSummary.currentBalance': mongoose.Types.Decimal128.fromString(currentBalance.toString()),
        'financialSummary.lastUpdated': new Date(),
      },
    });
  }

  console.log(`✅ Đã cập nhật financial summary cho ${users.length} users`);
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================
async function main() {
  try {
    console.log("\n🌱 BẮT ĐẦU THÊM DATA MỚI (KHÔNG XÓA DATA CŨ)");
    console.log("=".repeat(60));

    await connectDB();
    console.log("✅ Đã kết nối MongoDB");

    // Show current stats
    const currentUsers = await User.countDocuments();
    const currentExpenses = await Expense.countDocuments();
    const currentIncomes = await Income.countDocuments();

    console.log("\n📊 Database hiện tại:");
    console.log(`   - Users: ${currentUsers}`);
    console.log(`   - Expenses: ${currentExpenses}`);
    console.log(`   - Incomes: ${currentIncomes}`);

    // Add data
    const newUsers = await addUsers();
    await addExpensesForUsers(newUsers);
    await addIncomesForUsers(newUsers);
    await addBudgetsForUsers(newUsers);
    await updateUserFinancialSummary(newUsers);

    // Show final stats
    const finalUsers = await User.countDocuments();
    const finalExpenses = await Expense.countDocuments();
    const finalIncomes = await Income.countDocuments();

    console.log("\n📊 Database sau khi thêm:");
    console.log(`   - Users: ${finalUsers} (+${finalUsers - currentUsers})`);
    console.log(`   - Expenses: ${finalExpenses} (+${finalExpenses - currentExpenses})`);
    console.log(`   - Incomes: ${finalIncomes} (+${finalIncomes - currentIncomes})`);

    // Show credentials
    if (newUsers.length > 0) {
      console.log("\n" + "=".repeat(60));
      console.log("🔑 CREDENTIALS - USERS MỚI");
      console.log("=".repeat(60));
      newUsers.forEach((user, i) => {
        const userData = REALISTIC_USERS.find(u => u.email === user.email);
        console.log(`${i + 1}. ${user.email}`);
        console.log(`   Tên: ${user.profile.name}`);
        console.log(`   Nghề: ${userData?.profession}`);
      });
      console.log("-".repeat(60));
      console.log("🔐 Password: zbudget2024");
      console.log("=".repeat(60));
    }

    console.log("\n✅ HOÀN TẤT! Data cũ vẫn còn nguyên.\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error);
    process.exit(1);
  }
}

main();
