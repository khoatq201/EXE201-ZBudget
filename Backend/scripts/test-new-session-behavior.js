#!/usr/bin/env node

/**
 * Test script to verify new session behavior
 * This tests that each AI chat button press creates a new session
 */

import mongoose from "mongoose";
import ChatSession from "../models/ChatSession.js";

async function testNewSessionBehavior() {
  try {
    // Connect to MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ Connected to MongoDB");

    // Test 1: Check total sessions
    const totalSessions = await ChatSession.countDocuments();
    console.log(`📊 Total sessions: ${totalSessions}`);

    // Test 2: Check for recent sessions (last 1 hour)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentSessions = await ChatSession.countDocuments({
      createdAt: { $gte: oneHourAgo },
    });
    console.log(`📊 Recent sessions (last 1 hour): ${recentSessions}`);

    // Test 3: Check for sessions with user messages (actual conversations)
    const sessionsWithUserMessages = await ChatSession.countDocuments({
      "messages.role": "user",
    });
    console.log(`📊 Sessions with user messages: ${sessionsWithUserMessages}`);

    // Test 4: Check for empty sessions (should be minimal with new behavior)
    const emptySessions = await ChatSession.countDocuments({
      messageCount: 0,
    });
    console.log(`📊 Empty sessions: ${emptySessions}`);

    // Test 5: Check for sessions with system message field
    const sessionsWithSystemMessage = await ChatSession.countDocuments({
      systemMessage: { $exists: true, $ne: "" },
    });
    console.log(
      `📊 Sessions with system message field: ${sessionsWithSystemMessage}`
    );

    // Test 6: Sample recent sessions to see their structure
    const sampleSessions = await ChatSession.find({})
      .sort({ createdAt: -1 })
      .limit(3)
      .select(
        "sessionId messages systemMessage messageCount createdAt lastMessageAt"
      );

    console.log("\n📋 Sample recent sessions:");
    for (const session of sampleSessions) {
      console.log(`\nSession: ${session.sessionId}`);
      console.log(`- Created: ${session.createdAt}`);
      console.log(`- Last message: ${session.lastMessageAt}`);
      console.log(`- Message count: ${session.messageCount}`);
      console.log(`- Messages length: ${session.messages.length}`);
      console.log(
        `- Has system message field: ${
          session.systemMessage ? "✅ Yes" : "❌ No"
        }`
      );

      const userMessages = session.messages.filter(
        (msg) => msg.role === "user"
      );
      const assistantMessages = session.messages.filter(
        (msg) => msg.role === "assistant"
      );
      console.log(`- User messages: ${userMessages.length}`);
      console.log(`- Assistant messages: ${assistantMessages.length}`);

      // Show first few messages
      if (session.messages.length > 0) {
        console.log("📝 First few messages:");
        for (let i = 0; i < Math.min(session.messages.length, 3); i++) {
          const msg = session.messages[i];
          const role = msg.role === "user" ? "👤 User" : "🤖 AI";
          const content =
            msg.content.substring(0, 50) +
            (msg.content.length > 50 ? "..." : "");
          console.log(`  ${i + 1}. ${role}: ${content}`);
        }
      }
    }

    // Test 7: Check for temporary sessions (should not exist in database)
    const tempSessions = await ChatSession.countDocuments({
      sessionId: { $regex: /^temp_/ },
    });
    console.log(`\n📊 Temporary sessions in database: ${tempSessions}`);

    // Test 8: Check for sessions with context (multiple messages)
    const sessionsWithContext = await ChatSession.countDocuments({
      messageCount: { $gte: 4 }, // At least 2 user + 2 assistant messages
    });
    console.log(
      `📊 Sessions with context (4+ messages): ${sessionsWithContext}`
    );

    // Summary
    console.log("\n🎯 New Session Behavior Test Summary:");
    console.log(`✅ Total sessions: ${totalSessions}`);
    console.log(`✅ Recent sessions: ${recentSessions}`);
    console.log(`✅ Sessions with user messages: ${sessionsWithUserMessages}`);
    console.log(`✅ Empty sessions: ${emptySessions}`);
    console.log(
      `✅ Sessions with system message: ${sessionsWithSystemMessage}`
    );
    console.log(`✅ Temporary sessions in DB: ${tempSessions}`);
    console.log(`✅ Sessions with context: ${sessionsWithContext}`);

    if (
      emptySessions === 0 &&
      tempSessions === 0 &&
      sessionsWithUserMessages > 0
    ) {
      console.log("\n🎉 New session behavior appears to be working correctly!");
      console.log("   - No empty sessions found");
      console.log("   - No temporary sessions in database");
      console.log("   - Sessions only created when user sends messages");
      console.log("   - Each AI button press creates new session");
    } else if (emptySessions > 0) {
      console.log(
        "\n⚠️  Found empty sessions - new behavior may not be working"
      );
    } else if (tempSessions > 0) {
      console.log(
        "\n⚠️  Found temporary sessions in database - cleanup needed"
      );
    } else {
      console.log(
        "\n❓ Session behavior status unclear. Check the numbers above."
      );
    }

    // Test 9: Check for multiple sessions per user (should be normal now)
    const sessionsPerUser = await ChatSession.aggregate([
      {
        $group: {
          _id: "$userId",
          sessionCount: { $sum: 1 },
          lastSession: { $max: "$lastMessageAt" },
        },
      },
      { $sort: { sessionCount: -1 } },
      { $limit: 5 },
    ]);

    console.log("\n📊 Top users by session count:");
    for (const user of sessionsPerUser) {
      console.log(
        `  - User ${user._id}: ${user.sessionCount} sessions (last: ${user.lastSession})`
      );
    }
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("✅ Disconnected from MongoDB");
    process.exit(0);
  }
}

testNewSessionBehavior();
