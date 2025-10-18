#!/usr/bin/env node

/**
 * Test script to verify system message migration
 * Usage: node test-migration.js
 */

import mongoose from "mongoose";
import ChatSession from "../models/ChatSession.js";

async function testMigration() {
  try {
    // Connect to MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ Connected to MongoDB");

    // Test 1: Check for sessions with system messages in messages array
    const sessionsWithSystemInMessages = await ChatSession.countDocuments({
      "messages.role": "system",
    });
    console.log(
      `📊 Sessions with system messages in messages array: ${sessionsWithSystemInMessages}`
    );

    // Test 2: Check for sessions with systemMessage field
    const sessionsWithSystemField = await ChatSession.countDocuments({
      systemMessage: { $exists: true, $ne: "" },
    });
    console.log(
      `📊 Sessions with systemMessage field: ${sessionsWithSystemField}`
    );

    // Test 3: Check for sessions without systemMessage field
    const sessionsWithoutSystemField = await ChatSession.countDocuments({
      $or: [{ systemMessage: { $exists: false } }, { systemMessage: "" }],
    });
    console.log(
      `📊 Sessions without systemMessage field: ${sessionsWithoutSystemField}`
    );

    // Test 4: Sample a few sessions to verify structure
    const sampleSessions = await ChatSession.find({})
      .limit(3)
      .select("sessionId messages systemMessage messageCount");

    console.log("\n📋 Sample sessions:");
    for (const session of sampleSessions) {
      console.log(`\nSession: ${session.sessionId}`);
      console.log(
        `- System message field: ${
          session.systemMessage ? "✅ Present" : "❌ Missing"
        }`
      );
      console.log(`- Messages count: ${session.messages.length}`);
      console.log(`- Message count field: ${session.messageCount}`);

      const hasSystemInMessages = session.messages.some(
        (msg) => msg.role === "system"
      );
      console.log(
        `- System message in messages: ${
          hasSystemInMessages ? "❌ Found" : "✅ Clean"
        }`
      );
    }

    // Test 5: Check message count consistency
    const inconsistentSessions = await ChatSession.find({
      $expr: { $ne: ["$messageCount", { $size: "$messages" }] },
    });
    console.log(
      `\n📊 Sessions with inconsistent message count: ${inconsistentSessions.length}`
    );

    if (inconsistentSessions.length > 0) {
      console.log("⚠️  Found sessions with inconsistent message count:");
      for (const session of inconsistentSessions.slice(0, 3)) {
        console.log(
          `  - ${session.sessionId}: count=${session.messageCount}, actual=${session.messages.length}`
        );
      }
    }

    // Summary
    console.log("\n🎯 Migration Test Summary:");
    console.log(
      `✅ Sessions with system messages in messages: ${sessionsWithSystemInMessages}`
    );
    console.log(
      `✅ Sessions with systemMessage field: ${sessionsWithSystemField}`
    );
    console.log(
      `✅ Sessions without systemMessage field: ${sessionsWithoutSystemField}`
    );
    console.log(
      `✅ Sessions with inconsistent message count: ${inconsistentSessions.length}`
    );

    if (sessionsWithSystemInMessages === 0 && sessionsWithSystemField > 0) {
      console.log("\n🎉 Migration appears to be successful!");
    } else if (sessionsWithSystemInMessages > 0) {
      console.log(
        "\n⚠️  Migration may not be complete. Some sessions still have system messages in messages array."
      );
    } else {
      console.log("\n❓ Migration status unclear. Check the numbers above.");
    }
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("✅ Disconnected from MongoDB");
    process.exit(0);
  }
}

testMigration();
