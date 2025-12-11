import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import User from "../models/User.js";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Users to add
const usersToAdd = [
  {
    email: "Khangky9910@gmail.com",
    name: "Khang (A Khang)",
    password: "ZBudget2024!",
  },
  {
    email: "khanglop96qt@gmail.com",
    name: "Khang",
    password: "ZBudget2024!",
  },
  {
    email: "dohuuhoangkha@gmail.com",
    name: "Kha",
    password: "ZBudget2024!",
  },
  {
    email: "Mrjason170802@gmail.com",
    name: "Kiệt",
    password: "ZBudget2024!",
  },
  {
    email: "20530201057@uah.edu.vn",
    name: "Bạn Khang",
    password: "ZBudget2024!",
  },
  {
    email: "thinhndse162000@fpt.edu.vn",
    name: "Thịnh",
    password: "ZBudget2024!",
  },
  {
    email: "nganltcss181096@fpt.edu.vn",
    name: "Ngân",
    password: "ZBudget2024!",
  },
  {
    email: "hoangntss181069@fpt.edu.vn",
    name: "Hoàng",
    password: "ZBudget2024!",
  },
  {
    email: "thihnass181027@fpt.edu.vn",
    name: "Thi",
    password: "ZBudget2024!",
  },
  {
    email: "ngoclvkss181275@fpt.edu.vn",
    name: "Ngọc",
    password: "ZBudget2024!",
  },
  {
    email: "chungpss181258@fpt.edu.vn",
    name: "Chung",
    password: "ZBudget2024!",
  },
  {
    email: "duykhuongzxc@gmail.com",
    name: "Khương",
    password: "ZBudget2024!",
  },
  {
    email: "hiepvvss170481@fpt.edu.vn",
    name: "Hiệp",
    password: "ZBudget2024!",
  },
  {
    email: "danhtruong.19732018@gmail.com",
    name: "Cát Trần",
    password: "ZBudget2024!",
  },
  {
    email: "nguyendat20250504@gmail.com",
    name: "Đạt",
    password: "ZBudget2024!",
  },
  {
    email: "datnguyen01062025@gmail.com",
    name: "Đat",
    password: "ZBudget2024!",
  },
  {
    email: "trandat1172025@gmail.com",
    name: "Đạt Trần",
    password: "ZBudget2024!",
  },
  {
    email: "dattran05102025@gmail.com",
    name: "đạt trần",
    password: "ZBudget2024!",
  },
  {
    email: "khoaloz31.m@gmail.com",
    name: "Khoa",
    password: "ZBudget2024!",
  },
];

async function addUsers() {
  try {
    // Connect to MongoDB
    console.log("Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB successfully\n");

    // Hash password
    const hashedPassword = await bcrypt.hash("ZBudget2024!", 12);

    let addedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    console.log("Starting to add users...\n");

    for (const userData of usersToAdd) {
      try {
        // Check if user already exists
        const existingUser = await User.findOne({ email: userData.email });

        if (existingUser) {
          console.log(`⚠️  User ${userData.email} already exists - SKIPPED`);
          skippedCount++;
          continue;
        }

        // Create new user
        const newUser = new User({
          email: userData.email,
          passwordHash: hashedPassword,
          profile: {
            name: userData.name,
            gender: "other",
            location: {
              country: "Vietnam",
            },
          },
          settings: {
            currency: {
              primary: "VND",
              displayFormat: "đ",
              decimalPlaces: 0,
            },
            language: "vi",
            theme: "light",
            notifications: {
              // Default notification types with settings
              types: [
                {
                  type: "budget",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "expense",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "income",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "challenge",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "reminder",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: false,
                  frequency: "daily",
                },
                {
                  type: "achievement",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "security",
                  isEnabled: true,
                  showBadge: true,
                  playSound: true,
                  vibrate: true,
                  frequency: "immediately",
                },
                {
                  type: "system",
                  isEnabled: true,
                  showBadge: true,
                  playSound: false,
                  vibrate: false,
                  frequency: "immediately",
                },
                {
                  type: "marketing",
                  isEnabled: false,
                  showBadge: false,
                  playSound: false,
                  vibrate: false,
                  frequency: "never",
                },
              ],
              pushEnabled: true,
              emailEnabled: true,
            },
            security: {
              biometricEnabled: false,
              pinEnabled: false,
              sessionTimeout: 30,
            },
          },
          stats: {
            level: 1,
            points: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalSaved: 0,
            challengesCompleted: 0,
            rank: "Bronze",
          },
          emailVerified: true, // Set to true for easier testing
          isActive: true,
        });

        await newUser.save();
        console.log(`✅ Added user: ${userData.email} (${userData.name})`);
        addedCount++;
      } catch (error) {
        console.error(`❌ Error adding ${userData.email}:`, error.message);
        errorCount++;
      }
    }

    console.log("\n" + "=".repeat(60));
    console.log("SUMMARY");
    console.log("=".repeat(60));
    console.log(`✅ Added: ${addedCount} users`);
    console.log(`⚠️  Skipped: ${skippedCount} users (already exist)`);
    console.log(`❌ Errors: ${errorCount} users`);
    console.log(`📊 Total: ${usersToAdd.length} users processed`);
    console.log("=".repeat(60));

    // Display default password
    console.log("\n📝 Default password for all users: ZBudget2024!");
    console.log("⚠️  Users should change this password after first login\n");
  } catch (error) {
    console.error("❌ Fatal error:", error);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log("Database connection closed");
  }
}

// Run the script
addUsers();
