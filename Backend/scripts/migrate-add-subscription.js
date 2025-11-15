/**
 * Migration Script: Add Subscription Fields to User Schema
 *
 * Purpose: Safely add subscription-related fields to existing users
 * Safety: Does NOT modify or delete existing data, only adds new fields with defaults
 *
 * Features added:
 * - subscription.tier (default: 'free')
 * - subscription.status (default: 'active')
 * - subscription.startDate (default: current date)
 * - subscription.expiryDate (default: null for free users)
 * - subscription.features (default: free tier limits)
 * - usageLimits.ocr (default: 0 scans used today)
 *
 * Usage:
 *   npm run migrate:subscription
 *   OR
 *   node scripts/migrate-add-subscription.js
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import readline from 'readline';

dotenv.config();

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Define default subscription for free users
const DEFAULT_SUBSCRIPTION = {
  tier: 'free',
  status: 'active',
  startDate: new Date(),
  expiryDate: null,
  features: {
    maxBudgets: 2,
    maxSavingsGoals: 2,
    ocrScansPerDay: 10,
    aiAnalysisEnabled: false,
    prioritySupport: false,
  },
};

// Define default usage limits
const DEFAULT_USAGE_LIMITS = {
  ocr: {
    count: 0,
    lastResetDate: new Date(),
  },
};

// Migration function
const migrateSubscriptionFields = async () => {
  try {
    console.log('🚀 Starting subscription migration...\n');

    // Get User model (use native MongoDB collection to avoid schema conflicts)
    const User = mongoose.connection.collection('users');

    // Count total users
    const totalUsers = await User.countDocuments();
    console.log(`📊 Found ${totalUsers} users to migrate\n`);

    if (totalUsers === 0) {
      console.log('ℹ️  No users found. Migration not needed.');
      return;
    }

    // Find users without subscription field
    const usersWithoutSubscription = await User.countDocuments({
      subscription: { $exists: false },
    });
    console.log(`🔍 Users without subscription: ${usersWithoutSubscription}`);

    // Find users without usageLimits field
    const usersWithoutUsageLimits = await User.countDocuments({
      usageLimits: { $exists: false },
    });
    console.log(`🔍 Users without usageLimits: ${usersWithoutUsageLimits}\n`);

    // Update users without subscription field
    if (usersWithoutSubscription > 0) {
      console.log('📝 Adding subscription field to users...');
      const subscriptionResult = await User.updateMany(
        { subscription: { $exists: false } },
        {
          $set: { subscription: DEFAULT_SUBSCRIPTION },
        }
      );
      console.log(`✅ Updated ${subscriptionResult.modifiedCount} users with subscription\n`);
    }

    // Update users without usageLimits field
    if (usersWithoutUsageLimits > 0) {
      console.log('📝 Adding usageLimits field to users...');
      const usageLimitsResult = await User.updateMany(
        { usageLimits: { $exists: false } },
        {
          $set: { usageLimits: DEFAULT_USAGE_LIMITS },
        }
      );
      console.log(`✅ Updated ${usageLimitsResult.modifiedCount} users with usageLimits\n`);
    }

    // Verify migration
    console.log('🔎 Verifying migration...');
    const usersAfterMigration = await User.countDocuments({
      subscription: { $exists: true },
      usageLimits: { $exists: true },
    });
    console.log(`✅ ${usersAfterMigration}/${totalUsers} users now have subscription fields\n`);

    // Show sample user (first user with subscription)
    const sampleUser = await User.findOne({
      subscription: { $exists: true },
    }, {
      projection: {
        email: 1,
        displayName: 1,
        subscription: 1,
        usageLimits: 1,
      },
    });

    if (sampleUser) {
      console.log('📋 Sample user after migration:');
      console.log(JSON.stringify(sampleUser, null, 2));
      console.log('');
    }

    // Create indexes for performance
    console.log('🔧 Creating indexes...');
    await User.createIndex({ 'subscription.tier': 1 });
    await User.createIndex({ 'subscription.status': 1 });
    await User.createIndex({ 'subscription.expiryDate': 1 });
    console.log('✅ Indexes created\n');

    console.log('✨ Migration completed successfully!\n');
    console.log('📌 Summary:');
    console.log(`   - Total users: ${totalUsers}`);
    console.log(`   - Users migrated: ${Math.max(usersWithoutSubscription, usersWithoutUsageLimits)}`);
    console.log(`   - Default tier: free`);
    console.log(`   - Default limits: 2 budgets, 2 savings goals, 10 OCR scans/day`);
    console.log('');

  } catch (error) {
    console.error('❌ Migration error:', error);
    throw error;
  }
};

// Rollback function (optional - if you need to undo migration)
const rollbackMigration = async () => {
  try {
    console.log('⚠️  Starting rollback...\n');

    const User = mongoose.connection.collection('users');

    // Remove subscription and usageLimits fields
    const result = await User.updateMany(
      {},
      {
        $unset: {
          subscription: '',
          usageLimits: '',
        },
      }
    );

    console.log(`✅ Rolled back ${result.modifiedCount} users\n`);
    console.log('✨ Rollback completed!\n');

  } catch (error) {
    console.error('❌ Rollback error:', error);
    throw error;
  }
};

// Main execution
const main = async () => {
  await connectDB();

  // Check command line arguments
  const args = process.argv.slice(2);
  const command = args[0];

  if (command === 'rollback') {
    console.log('\n⚠️  ===== ROLLBACK MODE =====\n');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question('Are you sure you want to rollback? This will remove subscription fields. (yes/no): ', async (answer) => {
      if (answer.toLowerCase() === 'yes') {
        await rollbackMigration();
      } else {
        console.log('Rollback cancelled.');
      }
      rl.close();
      await mongoose.connection.close();
      process.exit(0);
    });
  } else {
    // Normal migration
    await migrateSubscriptionFields();
    await mongoose.connection.close();
    console.log('🔒 Database connection closed');
    process.exit(0);
  }
};

// Run migration
main();
