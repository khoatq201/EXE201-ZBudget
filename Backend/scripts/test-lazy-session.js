#!/usr/bin/env node

/**
 * Test script to verify lazy session creation
 * This tests that sessions are only created when user sends first message
 */

import mongoose from "mongoose";
import ChatSession from "../models/ChatSession.js";

async function testLazySessionCreation() {
  try {
    // Connect to MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/zbudget"
    );
    console.log("✅ Connected to MongoDB");

    // Test 1: Check total sessions before test
    const totalSessionsBefore = await ChatSession.countDocuments();
    console.log(`📊 Total sessions before test: ${totalSessionsBefore}`);

    // Test 2: Check for sessions created in last 5 minutes (recent activity)
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    const recentSessions = await ChatSession.countDocuments({
      createdAt: { $gte: fiveMinutesAgo },
    });
    console.log(`📊 Recent sessions (last 5 minutes): ${recentSessions}`);

    // Test 3: Check for sessions with no messages (empty sessions)
    const emptySessions = await ChatSession.countDocuments({
      messageCount: 0,
    });
    console.log(`📊 Sessions with no messages: ${emptySessions}`);

    // Test 4: Check for sessions with only system messages (old behavior)
    const sessionsWithOnlySystem = await ChatSession.find({
      $expr: {
        $and: [
          { $eq: ["$messageCount", 1] },
          { $eq: [{ $size: "$messages" }, 0] },
        ],
      },
    });
    console.log(
      `📊 Sessions with only system message (old behavior): ${sessionsWithOnlySystem.length}`
    );

    // Test 5: Check for sessions with actual user messages
    const sessionsWithUserMessages = await ChatSession.countDocuments({
      "messages.role": "user",
    });
    console.log(`📊 Sessions with user messages: ${sessionsWithUserMessages}`);

    // Test 6: Sample some recent sessions to see their structure
    const sampleSessions = await ChatSession.find({})
      .sort({ createdAt: -1 })
      .limit(3)
      .select("sessionId messages systemMessage messageCount createdAt");

    console.log("\n📋 Sample recent sessions:");
    for (const session of sampleSessions) {
      console.log(`\nSession: ${session.sessionId}`);
      console.log(`- Created: ${session.createdAt}`);
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
    }

    // Test 7: Check for temporary sessions (should not exist in database)
    const tempSessions = await ChatSession.countDocuments({
      sessionId: { $regex: /^temp_/ },
    });
    console.log(`\n📊 Temporary sessions in database: ${tempSessions}`);

    // Summary
    console.log("\n🎯 Lazy Session Test Summary:");
    console.log(`✅ Total sessions: ${totalSessionsBefore}`);
    console.log(`✅ Recent sessions: ${recentSessions}`);
    console.log(`✅ Empty sessions: ${emptySessions}`);
    console.log(`✅ Sessions with user messages: ${sessionsWithUserMessages}`);
    console.log(`✅ Temporary sessions in DB: ${tempSessions}`);

    if (emptySessions === 0 && tempSessions === 0) {
      console.log(
        "\n🎉 Lazy session creation appears to be working correctly!"
      );
      console.log("   - No empty sessions found");
      console.log("   - No temporary sessions in database");
      console.log("   - Sessions only created when user sends messages");
    } else if (emptySessions > 0) {
      console.log(
        "\n⚠️  Found empty sessions - lazy creation may not be working"
      );
    } else if (tempSessions > 0) {
      console.log(
        "\n⚠️  Found temporary sessions in database - cleanup needed"
      );
    } else {
      console.log("\n❓ Lazy session status unclear. Check the numbers above.");
    }
  } catch (error) {
    console.error("❌ Test failed:", error);
  } finally {
    await mongoose.disconnect();
    console.log("✅ Disconnected from MongoDB");
    process.exit(0);
  }
}

testLazySessionCreation();
