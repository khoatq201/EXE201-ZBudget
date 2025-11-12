import { connectDB } from "../models/index.js";
import {
  createSampleData,
  getSampleUserCredentials,
} from "../services/sampleDataService.js";

async function main() {
  try {
    console.log("🚀 Starting sample data creation...");

    // Connect to database
    await connectDB();
    console.log("✅ Connected to database");

    // Create sample data
    await createSampleData();

    // Display sample user credentials
    console.log("\n🔑 Sample User Credentials for Testing:");
    console.log("=====================================");
    const credentials = getSampleUserCredentials();
    credentials.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Password: ${user.password}`);
      console.log("");
    });

    console.log("🎉 Sample data creation completed successfully!");
    console.log("\n📝 Next steps:");
    console.log("1. Start the server: npm start");
    console.log("2. Login with any sample user credentials above");
    console.log("3. Test AI chat functionality");
    console.log("4. Check streaming responses");

    process.exit(0);
  } catch (error) {
    console.error("❌ Error creating sample data:", error);
    process.exit(1);
  }
}

// Handle uncaught errors
process.on("uncaughtException", (error) => {
  console.error("❌ Uncaught Exception:", error);
  process.exit(1);
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("❌ Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

main();
