import { GoogleGenerativeAI } from "@google/generative-ai";
import fs from "fs";
import path from "path";

// Test Gemini AI connection
const genAI = new GoogleGenerativeAI("AIzaSyCKmDwUjGxdtVE6vRUT41oh5CeDK9PBHAA");

async function testGemini() {
  try {
    console.log("🧪 Testing Gemini AI connection...");

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

    const result = await model.generateContent([
      "Hello, can you respond with 'Gemini AI is working'?",
    ]);

    const response = await result.response;
    const text = response.text();

    console.log("✅ Gemini AI Response:", text);
    console.log("🎉 Gemini AI is working correctly!");
  } catch (error) {
    console.error("❌ Gemini AI Error:", error);
  }
}

testGemini();
