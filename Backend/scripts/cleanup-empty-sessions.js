#!/usr/bin/env node

/**
 * Cleanup script to remove empty sessions
 * This removes sessions that were created but never used (no user messages)
 */

import mongoose from "mongoose";
import ChatSession from "../models/ChatSession.js";

async function cleanupEmptySessions() {
  try {
    // Connect to MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ Connected to MongoDB");

    // Find empty sessions (no user messages)
    const emptySessions = await ChatSession.find({
      $or: [
        { messageCount: 0 },
        {
          $expr: {
            $eq: [
              {
                $size: {
                  $filter: {
                    input: "$messages",
                    cond: { $eq: ["$$this.role", "user"] },
                  },
                },
              },
              0,
            ],
          },
        },
      ],
    });

    console.log(`📊 Found ${emptySessions.length} empty sessions to cleanup`);

    if (emptySessions.length === 0) {
      console.log("🎉 No empty sessions found! Database is clean.");
      return;
    }

    // Show details of sessions to be deleted
    console.log("\n📋 Sessions to be deleted:");
    for (const session of emptySessions.slice(0, 5)) {
      // Show first 5
      console.log(
        `- ${session.sessionId} (created: ${session.createdAt}, messages: ${session.messageCount})`
      );
    }
    if (emptySessions.length > 5) {
      console.log(`- ... and ${emptySessions.length - 5} more`);
    }

    // Ask for confirmation (in production, you might want to add a confirmation prompt)
    console.log("\n⚠️  This will permanently delete empty sessions.");
    console.log("   In production, add confirmation prompt here.");

    // Delete empty sessions
    const deleteResult = await ChatSession.deleteMany({
      $or: [
        { messageCount: 0 },
        {
          $expr: {
            $eq: [
              {
                $size: {
                  $filter: {
                    input: "$messages",
                    cond: { $eq: ["$$this.role", "user"] },
                  },
                },
              },
              0,
            ],
          },
        },
      ],
    });

    console.log(`\n🗑️  Deleted ${deleteResult.deletedCount} empty sessions`);

    // Verify cleanup
    const remainingEmptySessions = await ChatSession.countDocuments({
      $or: [
        { messageCount: 0 },
        {
          $expr: {
            $eq: [
              {
                $size: {
                  $filter: {
                    input: "$messages",
                    cond: { $eq: ["$$this.role", "user"] },
                  },
                },
              },
              0,
            ],
          },
        },
      ],
    });

    console.log(`📊 Remaining empty sessions: ${remainingEmptySessions}`);

    if (remainingEmptySessions === 0) {
      console.log("🎉 Cleanup completed successfully!");
    } else {
      console.log("⚠️  Some empty sessions may still exist");
    }
  } catch (error) {
    console.error("❌ Cleanup failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("✅ Disconnected from MongoDB");
    process.exit(0);
  }
}

cleanupEmptySessions();
