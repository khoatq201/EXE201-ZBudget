# 📚 YNAB-Style Budget API Documentation

## 🎯 Overview

ZBudget đã implement YNAB-style income allocation system. Hệ thống cho phép user:
1. **Tạo income** với allocations (phân bổ) vào budgets/savings
2. **Assign từ "Ready to Assign"** pool vào budgets/savings sau
3. **Track funding status** của budgets (bao nhiêu tiền đã funded vs allocated)

---

## 🔑 Key Concepts

### Ready to Assign
- Số tiền thu nhập **chưa được phân bổ** vào budget/savings
- Tương đương "To Be Budgeted" trong YNAB
- Field: `user.financialSummary.readyToAssign`

### Budget Funding
- **Allocated**: Số tiền user **dự định** chi cho category (kế hoạch)
- **Funded**: Số tiền **thực tế đã assign** từ income vào category
- **Available**: Số tiền còn lại để chi = `funded - spent`
- **Spent**: Số tiền đã chi tiêu

### Workflow
```
Thu nhập 10M
  ├─ Phân bổ ngay: 3M vào budget
  │   ├─ Food: 2M
  │   └─ Transport: 1M
  └─ Chưa phân bổ: 7M → Ready to Assign

Sau đó có thể:
  - Assign thêm từ Ready to Assign vào budget/savings
  - Hoặc để dành cho tương lai
```

---

## 📡 API Endpoints

### 1. Create Income with Allocations

**Endpoint:** `POST /api/income`

**Auth:** Required (Bearer token)

**Request Body:**
```json
{
  "title": "Lương tháng 10",
  "description": "Lương chính thức tháng 10/2025",
  "amount": 10000000,
  "category": "salary",
  "date": "2025-10-01T00:00:00.000Z",
  "paymentMethod": "banking",
  "allocations": [
    {
      "type": "budget",
      "targetId": "68df84b7d47388d34ee86f88",
      "targetModel": "Budget",
      "amount": 2000000,
      "categoryAllocationId": "food",
      "note": "Phân bổ cho ăn uống tháng 10"
    },
    {
      "type": "budget",
      "targetId": "68df84b7d47388d34ee86f88",
      "targetModel": "Budget",
      "amount": 1000000,
      "categoryAllocationId": "transport",
      "note": "Phân bổ cho đi lại"
    }
  ]
}
```

**Allocation Object:**
- `type`: "budget" hoặc "savings"
- `targetId`: ID của Budget hoặc SavingsGoal
- `targetModel`: "Budget" hoặc "SavingsGoal"
- `amount`: Số tiền phân bổ
- `categoryAllocationId`: Category trong budget (food, transport, etc.) - chỉ cần khi type="budget"
- `note`: Ghi chú (optional)

**Response:**
```json
{
  "success": true,
  "message": "Income created successfully",
  "data": {
    "_id": "...",
    "title": "Lương tháng 10",
    "amount": 10000000,
    "category": "salary",
    "allocations": [...],
    "totalAllocated": 3000000,
    "unallocated": 7000000,
    "isFullyAllocated": false,
    "date": "2025-10-01T00:00:00.000Z"
  }
}
```

**Key Fields:**
- `totalAllocated`: Tổng số tiền đã phân bổ
- `unallocated`: Số tiền chưa phân bổ (sẽ vào Ready to Assign)
- `isFullyAllocated`: Có phân bổ hết chưa

---

### 2. Get Ready to Assign

**Endpoint:** `GET /api/income/ready-to-assign`

**Auth:** Required

**Response:**
```json
{
  "success": true,
  "message": "Ready to Assign retrieved successfully",
  "data": {
    "readyToAssign": 7000000,
    "totalAssigned": 3000000,
    "totalSaved": 0,
    "lastAssignmentDate": "2025-10-09T04:30:46.874Z"
  }
}
```

**Fields:**
- `readyToAssign`: Số tiền chưa phân bổ (có thể assign)
- `totalAssigned`: Tổng đã assign vào budgets
- `totalSaved`: Tổng đã gửi vào savings
- `lastAssignmentDate`: Lần cuối assign

---

### 3. Assign from Ready to Assign

**Endpoint:** `POST /api/income/assign`

**Auth:** Required

**Request Body:**
```json
{
  "assignments": [
    {
      "type": "budget",
      "targetId": "68df84b7d47388d34ee86f88",
      "amount": 1000000,
      "categoryAllocationId": "entertainment",
      "note": "Phân bổ cho giải trí từ Ready to Assign"
    },
    {
      "type": "budget",
      "targetId": "68df84b7d47388d34ee86f88",
      "amount": 500000,
      "categoryAllocationId": "shopping",
      "note": "Phân bổ cho mua sắm"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Assignments processed successfully",
  "data": {
    "assigned": 1500000,
    "remainingReadyToAssign": 5500000
  }
}
```

**Validation:**
- Tổng `amount` trong assignments không được vượt quá `readyToAssign`
- Budget phải tồn tại và active
- Category phải tồn tại trong budget

---

### 4. Get Budget with Funding Status

**Endpoint:** `GET /api/budgets/:id`

**Auth:** Required

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "68df84b7d47388d34ee86f88",
    "name": "Ngân sách tháng 10",
    "totalAmount": 5000000,
    "categoryAllocations": [
      {
        "category": "food",
        "allocated": 2000000,
        "funded": 2000000,
        "spent": 725316,
        "available": 1274684,
        "percentage": 40
      },
      {
        "category": "transport",
        "allocated": 1000000,
        "funded": 1000000,
        "spent": 146065,
        "available": 853935,
        "percentage": 20
      }
    ],
    "fundingStatus": {
      "totalFunded": 3000000,
      "overfunded": false,
      "underfunded": true,
      "fundingPercentage": 60
    }
  }
}
```

**Category Allocation Fields:**
- `allocated`: Số tiền kế hoạch chi (user định trước)
- `funded`: Số tiền đã được fund từ income
- `spent`: Số tiền đã chi thực tế
- `available`: Còn lại để chi = `funded - spent`
- `percentage`: % trong tổng budget

**Funding Status:**
- `totalFunded`: Tổng tiền đã fund vào budget
- `fundingPercentage`: % funded so với totalAmount
- `underfunded`: true nếu funded < totalAmount
- `overfunded`: true nếu funded > totalAmount

---

## 🧪 Testing Examples

### Example 1: Create Income Without Allocations

```bash
POST /api/income
{
  "title": "Freelance project",
  "amount": 3000000,
  "category": "freelance",
  "date": "2025-10-05T00:00:00.000Z",
  "paymentMethod": "banking"
}
```

Result:
- Income: 3,000,000đ
- totalAllocated: 0đ
- unallocated: 3,000,000đ
- **Ready to Assign tăng thêm 3,000,000đ**

### Example 2: Create Income with Full Allocation

```bash
POST /api/income
{
  "title": "Thưởng dự án",
  "amount": 5000000,
  "category": "bonus",
  "allocations": [
    {
      "type": "budget",
      "targetId": "budgetId",
      "amount": 5000000,
      "categoryAllocationId": "food"
    }
  ]
}
```

Result:
- Income: 5,000,000đ
- totalAllocated: 5,000,000đ
- unallocated: 0đ
- isFullyAllocated: true
- **Budget food category funded tăng 5,000,000đ**
- **Ready to Assign không thay đổi**

### Example 3: Assign from Ready to Assign

Step 1: Check Ready to Assign
```bash
GET /api/income/ready-to-assign

Response: { readyToAssign: 3000000 }
```

Step 2: Assign 2M vào budget
```bash
POST /api/income/assign
{
  "assignments": [
    {
      "type": "budget",
      "targetId": "budgetId",
      "amount": 2000000,
      "categoryAllocationId": "transport"
    }
  ]
}

Response: {
  assigned: 2000000,
  remainingReadyToAssign: 1000000
}
```

Result:
- **Ready to Assign giảm 2M** (từ 3M → 1M)
- **Budget transport funded tăng 2M**
- **totalAssigned tăng 2M**

---

## 🔍 Common Use Cases

### Use Case 1: Lương về, phân bổ ngay

```javascript
// 1. Tạo income với allocations
const response = await createIncome({
  title: "Lương tháng 10",
  amount: 10000000,
  allocations: [
    { type: "budget", targetId: budgetId, amount: 3000000, categoryAllocationId: "food" },
    { type: "budget", targetId: budgetId, amount: 2000000, categoryAllocationId: "transport" },
  ]
});

// Result:
// - Income: 10M
// - Allocated: 5M
// - Ready to Assign: 5M
```

### Use Case 2: Có tiền rảnh, assign sau

```javascript
// 1. Check Ready to Assign
const { readyToAssign } = await getReadyToAssign();
console.log("Available:", readyToAssign); // 5,000,000đ

// 2. Decide to assign 3M vào shopping
await assignReadyToAssign({
  assignments: [
    { type: "budget", targetId: budgetId, amount: 3000000, categoryAllocationId: "shopping" }
  ]
});

// Result:
// - Ready to Assign: 2M (giảm từ 5M)
// - Shopping funded: tăng 3M
```

### Use Case 3: Over-budget Scenario

```javascript
// Budget allocated: 5M
// Income funded: 7M (overfunded!)

const budget = await getBudget(budgetId);
console.log(budget.fundingStatus);
// {
//   totalFunded: 7000000,
//   fundingPercentage: 140,
//   overfunded: true,
//   underfunded: false
// }
```

---

## ⚠️ Important Notes

### Database Transactions
Tất cả operations đều sử dụng MongoDB transactions:
- Create income + update user + fund budgets: atomic
- Assign từ Ready to Assign: atomic
- Nếu 1 bước fail → rollback toàn bộ

### Validation Rules
1. **Amount > 0**: Tất cả amounts phải > 0
2. **Sufficient funds**: Khi assign, tổng amount ≤ readyToAssign
3. **Budget exists**: targetId phải tồn tại và active
4. **Category exists**: categoryAllocationId phải có trong budget.categoryAllocations

### Known Limitations
- ⚠️ **SavingsGoal model chưa implement** → allocations với `type: "savings"` sẽ bị skip (tạm thời track vào totalSaved)
- Cần implement SavingsGoal model trong tương lai

---

## 🚀 Next Steps

### For Frontend Integration:
1. **Add Income Screen**: Thêm UI để chọn allocations khi tạo income
2. **Ready to Assign Card**: Hiển thị Ready to Assign prominently trên dashboard
3. **Budget Funding Progress**: Show funded vs allocated cho mỗi category
4. **Assign Modal**: Bottom sheet để assign từ Ready to Assign

### For Backend Enhancement:
1. **Implement SavingsGoal Model** với contribution tracking
2. **Add Budget Templates** với pre-funded amounts
3. **Income Rollover**: Tự động rollover unspent funds sang tháng sau
4. **Reports**: Funding history, allocation trends

---

## 📞 Support

Nếu có issues:
1. Check server logs: `npm run dev` output
2. Test migration: `node scripts/updateYNABFields.js`
3. Test features: `node scripts/testYNAB.js`

**Test Data:**
- User: phuonganh160268@gmail.com
- Password: Duy123@@
- Current Ready to Assign: 7,000,000đ
- Current Total Assigned: 3,000,000đ
