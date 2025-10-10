/**
 * Script to fix corrupted budget spent amounts
 * Recalculates spent amounts for each category based on actual expenses
 */

import mongoose from 'mongoose';
import { Budget, Expense } from '../models/index.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/zbudget';

async function fixBudgetSpentAmounts() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all budgets (active and inactive)
    const budgets = await Budget.find({});
    console.log(`\n📊 Found ${budgets.length} budgets to check\n`);

    let fixedCount = 0;
    let skippedCount = 0;

    for (const budget of budgets) {
      console.log(`\n📋 Checking budget: "${budget.name}" (ID: ${budget._id})`);
      console.log(`   Period: ${budget.period.startDate.toDateString()} - ${budget.period.endDate.toDateString()}`);

      let needsUpdate = false;

      // Check each category allocation
      for (const catAlloc of budget.categoryAllocations) {
        const currentSpent = parseFloat(catAlloc.spent?.toString() || '0');

        // Query actual expenses for this category in this budget
        const expenseStats = await Expense.aggregate([
          {
            $match: {
              budgetId: budget._id,
              category: catAlloc.category,
            },
          },
          {
            $group: {
              _id: null,
              actualSpent: { $sum: { $toDouble: '$amount' } },
              count: { $sum: 1 },
            },
          },
        ]);

        const actualSpent = expenseStats[0]?.actualSpent || 0;
        const expenseCount = expenseStats[0]?.count || 0;

        // Check if there's a discrepancy
        const diff = Math.abs(currentSpent - actualSpent);
        const threshold = 0.01; // 1 cent tolerance for rounding

        if (diff > threshold) {
          console.log(`   ⚠️  ${catAlloc.category}: Current=${currentSpent.toLocaleString()}, Actual=${actualSpent.toLocaleString()} (${expenseCount} expenses)`);

          // Update the category spent amount
          catAlloc.spent = mongoose.Types.Decimal128.fromString(actualSpent.toFixed(2));

          // Recalculate available (funded - spent)
          const funded = parseFloat(catAlloc.funded?.toString() || '0');
          catAlloc.available = mongoose.Types.Decimal128.fromString(
            (funded - actualSpent).toFixed(2)
          );

          catAlloc.lastUpdated = new Date();
          needsUpdate = true;
        } else {
          console.log(`   ✅ ${catAlloc.category}: Correct (${actualSpent.toLocaleString()}, ${expenseCount} expenses)`);
        }
      }

      if (needsUpdate) {
        // Recalculate budget status
        budget.updateStatus();

        // Save the budget
        await budget.save();

        console.log(`   💾 Updated budget status:`);
        console.log(`      Total Spent: ${parseFloat(budget.status.totalSpent.toString()).toLocaleString()}`);
        console.log(`      Spent %: ${budget.status.spentPercentage.toFixed(2)}%`);

        fixedCount++;
      } else {
        console.log(`   ✅ Budget is correct, no update needed`);
        skippedCount++;
      }
    }

    console.log(`\n\n📊 Summary:`);
    console.log(`   ✅ Fixed: ${fixedCount} budgets`);
    console.log(`   ⏭️  Skipped: ${skippedCount} budgets (already correct)`);
    console.log(`   📝 Total: ${budgets.length} budgets checked`);

  } catch (error) {
    console.error('❌ Error fixing budgets:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('\n👋 Disconnected from MongoDB');
  }
}

// Run the script
fixBudgetSpentAmounts();
