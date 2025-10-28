import fetch from "node-fetch";

const API_BASE = "http://localhost:3000/api";
const TEST_USER_TOKEN = "your-test-token-here"; // Cần token thực tế

async function testAPIExpenseError() {
  try {
    console.log("🧪 Testing API expense creation with large amount...");

    // Test tạo expense với số tiền lớn
    const expenseData = {
      title: "Test Large Expense",
      description: "Testing API error handling",
      amount: 5000000, // 5 triệu
      category: "shopping",
      date: new Date().toISOString(),
      paymentMethod: "cash",
    };

    console.log("📤 Sending request to create expense...");

    const response = await fetch(`${API_BASE}/expenses`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${TEST_USER_TOKEN}`,
      },
      body: JSON.stringify(expenseData),
    });

    const result = await response.json();

    console.log(`📊 Response status: ${response.status}`);
    console.log(`📊 Response:`, JSON.stringify(result, null, 2));

    if (response.status === 400 && result.error?.includes("Ready to Assign")) {
      console.log(
        "✅ Error handling working correctly - Ready to Assign validation caught"
      );
    } else if (response.status === 200) {
      console.log("⚠️ Expense created successfully - no validation error");
    } else {
      console.log("❌ Unexpected response");
    }
  } catch (error) {
    console.error("❌ Test failed:", error.message);
  }
}

testAPIExpenseError();
