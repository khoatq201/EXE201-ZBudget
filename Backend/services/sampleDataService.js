import User from "../models/User.js";
import Expense from "../models/Expense.js";
import Income from "../models/Income.js";
import Budget from "../models/Budget.js";
import bcrypt from "bcryptjs";

/**
 * Sample users with realistic Vietnamese financial data
 */
export const sampleUsers = [
  {
    name: "Nguyễn Văn A (Sample)",
    email: "sample1@test.com",
    password: "sample123",
    income: 15000000, // 15M VND/month
    expenses: [
      { category: "food", amount: 3000000, description: "Ăn uống hàng ngày" },
      { category: "transport", amount: 1500000, description: "Xăng xe, grab" },
      {
        category: "entertainment",
        amount: 2000000,
        description: "Xem phim, cafe",
      },
      {
        category: "bills",
        amount: 2500000,
        description: "Điện, nước, internet",
      },
      {
        category: "shopping",
        amount: 3000000,
        description: "Quần áo, đồ dùng",
      },
      { category: "health", amount: 1000000, description: "Khám sức khỏe" },
    ],
    budgets: [
      { category: "food", totalAmount: 4000000, spentAmount: 3000000 },
      { category: "transport", totalAmount: 2000000, spentAmount: 1500000 },
      { category: "entertainment", totalAmount: 3000000, spentAmount: 2000000 },
    ],
  },
  {
    name: "Trần Thị B (Sample)",
    email: "sample2@test.com",
    password: "sample123",
    income: 25000000, // 25M VND/month
    expenses: [
      { category: "food", amount: 4000000, description: "Ăn uống cao cấp" },
      {
        category: "transport",
        amount: 2000000,
        description: "Taxi, grab premium",
      },
      { category: "health", amount: 3000000, description: "Phòng gym, spa" },
      {
        category: "education",
        amount: 5000000,
        description: "Khóa học online",
      },
      {
        category: "shopping",
        amount: 4000000,
        description: "Thời trang, mỹ phẩm",
      },
      { category: "bills", amount: 3000000, description: "Nhà thuê, tiện ích" },
    ],
    budgets: [
      { category: "food", totalAmount: 5000000, spentAmount: 4000000 },
      { category: "education", totalAmount: 6000000, spentAmount: 5000000 },
      { category: "health", totalAmount: 4000000, spentAmount: 3000000 },
    ],
  },
  {
    name: "Lê Văn C (Sample)",
    email: "sample3@test.com",
    password: "sample123",
    income: 8000000, // 8M VND/month (student/entry level)
    expenses: [
      { category: "food", amount: 2000000, description: "Cơm bình dân" },
      { category: "transport", amount: 800000, description: "Xe bus, xe máy" },
      { category: "education", amount: 2000000, description: "Học phí, sách" },
      {
        category: "bills",
        amount: 1500000,
        description: "Phòng trọ, điện nước",
      },
      {
        category: "entertainment",
        amount: 1000000,
        description: "Giải trí ít",
      },
    ],
    budgets: [
      { category: "food", totalAmount: 2500000, spentAmount: 2000000 },
      { category: "education", totalAmount: 2500000, spentAmount: 2000000 },
      { category: "transport", totalAmount: 1000000, spentAmount: 800000 },
    ],
  },
];

/**
 * Create sample financial data for testing
 */
export async function createSampleData() {
  try {
    console.log("🚀 Creating sample financial data...");

    // Clear existing sample users
    await User.deleteMany({ email: { $regex: /sample.*@test\.com/ } });
    console.log("✅ Cleared existing sample users");

    for (const sample of sampleUsers) {
      console.log(`📝 Creating user: ${sample.name}`);

      // Hash password
      const hashedPassword = await bcrypt.hash(sample.password, 10);

      // Create user
      const user = await User.create({
        email: sample.email,
        passwordHash: hashedPassword,
        authProvider: "local",
        isEmailVerified: true,
        profile: {
          name: sample.name,
        },
        financialSummary: {
          totalIncome: sample.income,
          totalExpenses: sample.expenses.reduce(
            (sum, exp) => sum + exp.amount,
            0
          ),
          currentBalance:
            sample.income -
            sample.expenses.reduce((sum, exp) => sum + exp.amount, 0),
        },
      });

      console.log(`✅ User created: ${user._id}`);

      // Create income records
      await Income.create({
        userId: user._id,
        amount: sample.income,
        title: "Lương chính",
        description: "Thu nhập hàng tháng",
        date: new Date(),
        category: "salary",
        source: {
          name: "Công ty ABC",
          contactInfo: "HR Department",
        },
      });

      // Create expense records
      for (const exp of sample.expenses) {
        await Expense.create({
          userId: user._id,
          amount: exp.amount,
          title: exp.description,
          category: exp.category,
          description: exp.description,
          date: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000), // Random date in last 30 days
          paymentMethod: "cash",
        });
      }

      // Create budget records
      if (sample.budgets) {
        for (const budget of sample.budgets) {
          await Budget.create({
            userId: user._id,
            category: budget.category,
            totalAmount: budget.totalAmount,
            spentAmount: budget.spentAmount,
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
          });
        }
      }

      console.log(`✅ Financial data created for ${sample.name}`);
    }

    console.log("🎉 Sample data creation completed!");
    console.log("\n📊 Sample Users Created:");
    sampleUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name} (${user.email})`);
      console.log(
        `   - Thu nhập: ${user.income.toLocaleString("vi-VN")} VND/tháng`
      );
      console.log(
        `   - Chi tiêu: ${user.expenses
          .reduce((sum, exp) => sum + exp.amount, 0)
          .toLocaleString("vi-VN")} VND`
      );
      console.log(
        `   - Số dư: ${(
          user.income - user.expenses.reduce((sum, exp) => sum + exp.amount, 0)
        ).toLocaleString("vi-VN")} VND`
      );
      console.log("");
    });

    return true;
  } catch (error) {
    console.error("❌ Error creating sample data:", error);
    throw error;
  }
}

/**
 * Get sample user credentials for testing
 */
export function getSampleUserCredentials() {
  return sampleUsers.map((user) => ({
    email: user.email,
    password: user.password,
    name: user.name,
  }));
}

/**
 * Create additional sample transactions for a user
 */
export async function createAdditionalSampleTransactions(userId, count = 10) {
  try {
    const categories = [
      "food",
      "transport",
      "entertainment",
      "bills",
      "shopping",
      "health",
      "education",
    ];
    const descriptions = {
      food: ["Ăn trưa", "Cafe", "Ăn tối", "Mua đồ ăn"],
      transport: ["Xăng xe", "Grab", "Taxi", "Xe bus"],
      entertainment: ["Xem phim", "Karaoke", "Game", "Du lịch"],
      bills: ["Điện", "Nước", "Internet", "Điện thoại"],
      shopping: ["Quần áo", "Mỹ phẩm", "Đồ điện tử", "Sách"],
      health: ["Khám bệnh", "Thuốc", "Gym", "Spa"],
      education: ["Học phí", "Sách vở", "Khóa học", "Thi cử"],
    };

    const transactions = [];

    for (let i = 0; i < count; i++) {
      const category =
        categories[Math.floor(Math.random() * categories.length)];
      const categoryDescriptions = descriptions[category];
      const description =
        categoryDescriptions[
          Math.floor(Math.random() * categoryDescriptions.length)
        ];
      const amount = Math.floor(Math.random() * 1000000) + 50000; // 50k - 1M VND
      const date = new Date(
        Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000
      ); // Last 90 days

      transactions.push({
        userId,
        amount,
        category,
        description,
        date,
        paymentMethod: Math.random() > 0.5 ? "cash" : "card",
      });
    }

    await Expense.insertMany(transactions);
    console.log(
      `✅ Created ${count} additional transactions for user ${userId}`
    );

    return transactions;
  } catch (error) {
    console.error("❌ Error creating additional transactions:", error);
    throw error;
  }
}
