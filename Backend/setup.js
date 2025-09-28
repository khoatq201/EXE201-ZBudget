import dotenv from "dotenv";
import { connectDB, dbUtils, User, Challenge, Budget } from "./models/index.js";
import { fileURLToPath } from "url";
import path from "path";

// Load environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, "../.env") });

// Sample data for seeding
const sampleUsers = [
  {
    email: "admin@zbudget.com",
    passwordHash: "admin123456", // Will be hashed automatically
    profile: {
      name: "Admin User",
      gender: "other",
      location: {
        city: "Ho Chi Minh City",
        country: "Vietnam",
      },
    },
    settings: {
      currency: { primary: "VND", displayFormat: "đ" },
      language: "vi",
      theme: "light",
    },
    stats: {
      level: 10,
      points: 5000,
      rank: "Gold",
    },
    emailVerified: true,
  },
  {
    email: "user@zbudget.com",
    passwordHash: "user123456",
    profile: {
      name: "Test User",
      gender: "male",
      location: {
        city: "Ha Noi",
        country: "Vietnam",
      },
    },
    emailVerified: true,
  },
];

const sampleChallenges = [
  {
    challengeId: "coffee-reduction-7days",
    title: "7 ngày không mua cà phê ngoài",
    description:
      "Thử thách bản thân pha cà phê tại nhà thay vì mua ngoài trong 7 ngày",
    emoji: "☕",
    color: "#8B4513",
    type: "reduction",
    category: "drinks",
    difficulty: "easy",
    duration: {
      days: 7,
      displayText: "7 ngày",
    },
    targets: {
      estimatedSaving: 175000,
      dailySavingTarget: 25000,
      maxBudget: 0,
      comparisonPeriod: "previous_week",
    },
    milestones: [
      {
        day: 1,
        title: "Ngày đầu tiên",
        description: "Hoàn thành ngày đầu tiên không mua cà phê",
        points: 50,
        badge: "🥇",
        reward: "Unlock: Cà phê tại nhà recipes",
      },
      {
        day: 3,
        title: "Nửa chặng đường",
        description: "3 ngày liên tiếp thành công",
        points: 100,
        badge: "🔥",
        reward: "Extra 25.000đ saving bonus",
      },
      {
        day: 7,
        title: "Hoàn thành thách thức",
        description: "Thành công 7 ngày không mua cà phê ngoài",
        points: 200,
        badge: "🏆",
        reward: "Special badge + Level up",
      },
    ],
    rules: {
      forbiddenCategories: ["drinks"],
      substitutionSuggestions: [
        "Pha cà phê tại nhà",
        "Mua cà phê bột về pha",
        "Thử trà thay cà phê",
      ],
      trackingMethod: "expense_category",
    },
    isActive: true,
    featured: true,
    endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
  },
  {
    challengeId: "transport-savings-30days",
    title: "30 ngày tiết kiệm chi phí đi lại",
    description:
      "Sử dụng phương tiện công cộng hoặc đi bộ thay vì xe grab/taxi trong 30 ngày",
    emoji: "🚌",
    color: "#32CD32",
    type: "reduction",
    category: "transport",
    difficulty: "medium",
    duration: {
      days: 30,
      displayText: "30 ngày",
    },
    targets: {
      estimatedSaving: 500000,
      dailySavingTarget: 16667,
      maxBudget: 200000,
      comparisonPeriod: "previous_month",
    },
    milestones: [
      {
        day: 7,
        title: "Tuần đầu thành công",
        description: "Hoàn thành tuần đầu tiết kiệm đi lại",
        points: 100,
        badge: "🚶",
        reward: "Bonus: Discount bus card",
      },
      {
        day: 15,
        title: "Nửa chặng đường",
        description: "15 ngày kiên trì",
        points: 200,
        badge: "🏃",
        reward: "Health bonus points",
      },
      {
        day: 30,
        title: "Chuyên gia tiết kiệm",
        description: "Hoàn thành 30 ngày tiết kiệm giao thông",
        points: 500,
        badge: "🏆",
        reward: "Transport Master Badge",
      },
    ],
    rules: {
      forbiddenCategories: ["transport"],
      substitutionSuggestions: [
        "Sử dụng xe bus",
        "Đi bộ khoảng cách ngắn",
        "Đi xe đạp",
        "Chia sẻ xe với bạn bè",
      ],
      trackingMethod: "expense_category",
    },
    isActive: true,
    featured: true,
    endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
  },
];

// Setup functions
async function setupDatabase() {
  try {
    console.log("🚀 Starting ZBudget database setup...");

    // Connect to database
    await connectDB();

    // Create indexes
    await dbUtils.createIndexes();

    console.log("✅ Database setup completed successfully");
    return true;
  } catch (error) {
    console.error("❌ Database setup failed:", error);
    return false;
  }
}

async function seedDatabase() {
  try {
    console.log("🌱 Seeding database with sample data...");

    // Check if data already exists
    const userCount = await User.countDocuments();
    const challengeCount = await Challenge.countDocuments();

    if (userCount > 0) {
      console.log("📝 Database already contains users, skipping seeding");
      return true;
    }

    // Seed users
    console.log("👥 Creating sample users...");
    for (const userData of sampleUsers) {
      try {
        const user = new User(userData);
        await user.save();
        console.log(`✅ Created user: ${userData.email}`);
      } catch (error) {
        console.error(
          `❌ Failed to create user ${userData.email}:`,
          error.message
        );
      }
    }

    // Seed challenges
    console.log("🎯 Creating sample challenges...");
    for (const challengeData of sampleChallenges) {
      try {
        const challenge = new Challenge(challengeData);
        await challenge.save();
        console.log(`✅ Created challenge: ${challengeData.title}`);
      } catch (error) {
        console.error(
          `❌ Failed to create challenge ${challengeData.title}:`,
          error.message
        );
      }
    }

    console.log("✅ Database seeding completed successfully");
    return true;
  } catch (error) {
    console.error("❌ Database seeding failed:", error);
    return false;
  }
}

async function validateSetup() {
  try {
    console.log("🔍 Validating database setup...");

    // Check database health
    const health = await dbUtils.healthCheck();
    if (!health.connected) {
      throw new Error("Database not connected");
    }

    // Check collections
    const stats = await dbUtils.getStats();
    console.log("📊 Database statistics:");
    console.log(`  Database: ${stats.database.name}`);
    console.log(`  Collections: ${stats.database.collections}`);
    console.log(
      `  Total size: ${(stats.database.totalSize / 1024 / 1024).toFixed(2)} MB`
    );

    // Check models
    const userCount = await User.countDocuments();
    const challengeCount = await Challenge.countDocuments();

    console.log("📈 Data counts:");
    console.log(`  Users: ${userCount}`);
    console.log(`  Challenges: ${challengeCount}`);

    console.log("✅ Database validation completed successfully");
    return true;
  } catch (error) {
    console.error("❌ Database validation failed:", error);
    return false;
  }
}

async function cleanup() {
  try {
    console.log("🧹 Cleaning up...");

    // Close database connection
    await mongoose.connection.close();
    console.log("📴 Database connection closed");

    return true;
  } catch (error) {
    console.error("❌ Cleanup failed:", error);
    return false;
  }
}

// Main setup function
async function main() {
  console.log("🎉 ZBudget Backend Setup");
  console.log("========================");

  const args = process.argv.slice(2);
  const shouldSeed = args.includes("--seed");
  const shouldCleanup = args.includes("--cleanup");

  try {
    // Setup database
    const setupSuccess = await setupDatabase();
    if (!setupSuccess) {
      process.exit(1);
    }

    // Seed data if requested
    if (shouldSeed) {
      const seedSuccess = await seedDatabase();
      if (!seedSuccess) {
        console.warn("⚠️ Seeding failed, but continuing...");
      }
    }

    // Validate setup
    const validateSuccess = await validateSetup();
    if (!validateSuccess) {
      console.warn("⚠️ Validation failed, but continuing...");
    }

    console.log("");
    console.log("🎉 Setup completed successfully!");
    console.log("");
    console.log("Next steps:");
    console.log("1. Copy .env.example to .env and configure your settings");
    console.log('2. Run "npm run dev" to start the development server');
    console.log(
      "3. Visit http://localhost:3000/api/health to check API status"
    );
    console.log("");

    // Auto cleanup unless explicitly running server
    if (shouldCleanup || !args.includes("--no-cleanup")) {
      await cleanup();
    }
  } catch (error) {
    console.error("💥 Setup failed:", error);
    await cleanup();
    process.exit(1);
  }
}

// Run setup if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export {
  setupDatabase,
  seedDatabase,
  validateSetup,
  cleanup,
  sampleUsers,
  sampleChallenges,
};
