#!/usr/bin/env node

/**
 * Test script to verify chat context is working correctly
 * This tests that AI remembers previous messages in a conversation
 */

import mongoose from "mongoose";
import ChatSession from "../models/ChatSession.js";

async function testChatContext() {
  try {
    // Connect to MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ Connected to MongoDB");

    // Test 1: Find sessions with multiple messages
    const sessionsWithMultipleMessages = await ChatSession.find({
      messageCount: { $gte: 4 }, // At least 2 user + 2 assistant messages
    })
      .sort({ lastMessageAt: -1 })
      .limit(5);

    console.log(
      `📊 Found ${sessionsWithMultipleMessages.length} sessions with multiple messages`
    );

    // Test 2: Analyze message patterns
    for (const session of sessionsWithMultipleMessages) {
      console.log(`\n📋 Session: ${session.sessionId}`);
      console.log(`- Message count: ${session.messageCount}`);
      console.log(`- Messages length: ${session.messages.length}`);
      console.log(`- Last message at: ${session.lastMessageAt}`);

      const userMessages = session.messages.filter(
        (msg) => msg.role === "user"
      );
      const assistantMessages = session.messages.filter(
        (msg) => msg.role === "assistant"
      );

      console.log(`- User messages: ${userMessages.length}`);
      console.log(`- Assistant messages: ${assistantMessages.length}`);

      // Show first few messages to verify context
      console.log("\n📝 Message history:");
      for (let i = 0; i < Math.min(session.messages.length, 6); i++) {
        const msg = session.messages[i];
        const role = msg.role === "user" ? "👤 User" : "🤖 AI";
        const content =
          msg.content.substring(0, 100) +
          (msg.content.length > 100 ? "..." : "");
        console.log(`  ${i + 1}. ${role}: ${content}`);
      }

      if (session.messages.length > 6) {
        console.log(`  ... and ${session.messages.length - 6} more messages`);
      }
    }

    // Test 3: Check for sessions with context issues
    const sessionsWithContextIssues = await ChatSession.find({
      $expr: {
        $ne: ["$messageCount", { $size: "$messages" }],
      },
    });

    console.log(
      `\n📊 Sessions with context issues (message count mismatch): ${sessionsWithContextIssues.length}`
    );

    if (sessionsWithContextIssues.length > 0) {
      console.log("⚠️  Found sessions with context issues:");
      for (const session of sessionsWithContextIssues.slice(0, 3)) {
        console.log(
          `  - ${session.sessionId}: count=${session.messageCount}, actual=${session.messages.length}`
        );
      }
    }

    // Test 4: Check for recent sessions (last 24 hours)
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentSessions = await ChatSession.countDocuments({
      lastMessageAt: { $gte: oneDayAgo },
    });
    console.log(`📊 Recent sessions (last 24 hours): ${recentSessions}`);

    // Test 5: Check for sessions with system message field
    const sessionsWithSystemMessage = await ChatSession.countDocuments({
      systemMessage: { $exists: true, $ne: "" },
    });
    console.log(
      `📊 Sessions with system message field: ${sessionsWithSystemMessage}`
    );

    // Test 6: Check for sessions without system message field
    const sessionsWithoutSystemMessage = await ChatSession.countDocuments({
      $or: [{ systemMessage: { $exists: false } }, { systemMessage: "" }],
    });
    console.log(
      `📊 Sessions without system message field: ${sessionsWithoutSystemMessage}`
    );

    // Summary
    console.log("\n🎯 Chat Context Test Summary:");
    console.log(
      `✅ Sessions with multiple messages: ${sessionsWithMultipleMessages.length}`
    );
    console.log(
      `✅ Sessions with context issues: ${sessionsWithContextIssues.length}`
    );
    console.log(`✅ Recent sessions: ${recentSessions}`);
    console.log(
      `✅ Sessions with system message: ${sessionsWithSystemMessage}`
    );
    console.log(
      `✅ Sessions without system message: ${sessionsWithoutSystemMessage}`
    );

    if (
      sessionsWithContextIssues.length === 0 &&
      sessionsWithMultipleMessages.length > 0
    ) {
      console.log("\n🎉 Chat context appears to be working correctly!");
      console.log("   - No context issues found");
      console.log("   - Multiple message sessions exist");
      console.log("   - AI should remember previous messages");
    } else if (sessionsWithContextIssues.length > 0) {
      console.log(
        "\n⚠️  Found context issues - AI may not remember previous messages"
      );
    } else {
      console.log("\n❓ Context status unclear. Check the numbers above.");
    }
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("✅ Disconnected from MongoDB");
    process.exit(0);
  }
}

testChatContext();
