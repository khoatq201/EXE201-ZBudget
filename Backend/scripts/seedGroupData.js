import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import {
  User,
  Group,
  GroupBudget,
  Expense,
  connectDB,
} from "../models/index.js";

/**
 * ============================================================================
 * SEED GROUP DATA - TẠO NHÓM VỚI 2 THÀNH VIÊN
 * ============================================================================
 *
 * Script này tạo:
 * - User mới: khoatqse184056@fpt.edu.vn (nếu chưa tồn tại)
 * - Nhóm "Du lịch Đà Lạt" với 2 members
 * - GroupBudget cho nhóm với phân bổ đóng góp
 * - Một số expenses mẫu cho nhóm
 *
 * KHÔNG làm ảnh hưởng đến dữ liệu users và groups khác
 */

// ============================================================================
// CẤU HÌNH
// ============================================================================
const CONFIG = {
  // User 1 - Owner của nhóm (user mới)
  ownerUser: {
    email: "khoatqse184056@fpt.edu.vn",
    password: "zbudget2024",
    name: "Trần Quang Khoa",
    profession: "Student",
    city: "Hà Nội",
    phone: "0987654321",
    dateOfBirth: new Date(2002, 4, 20), // May 20, 2002
    gender: "male",
    bio: "Student FPT | Tech enthusiast 💻",
  },

  // User 2 - Member của nhóm (user đã tồn tại)
  memberUser: {
    email: "minhkhoi.dev98@gmail.com",
  },

  // Thông tin nhóm
  group: {
    name: "Du lịch Đà Lạt 2025",
    description: "Nhóm chi tiêu chung cho chuyến du lịch Đà Lạt 3 ngày 2 đêm",
    avatar:
      "https://ui-avatars.com/api/?name=Du+Lich+Da+Lat&background=FF6B6B&color=fff&size=200",
    settings: {
      privacy: "private",
      currency: "VND",
      maxMembers: 10,
      allowMemberInvites: true,
      defaultSplitMethod: "percentage",
    },
  },

  // Ngân sách nhóm
  groupBudget: {
    name: "Ngân sách Du lịch Đà Lạt",
    totalAmount: 10000000, // 10M VND
    description: "Chi phí cho chuyến đi: xe, khách sạn, ăn uống, vui chơi",
    // Phân bổ đóng góp (%)
    contributions: {
      owner: 60, // Khoa đóng 60%
      member: 40, // Khôi đóng 40%
    },
  },
};

// Dữ liệu chi tiêu nhóm mẫu
const GROUP_EXPENSES = [
  {
    title: "Đặt khách sạn Đà Lạt",
    amount: 2400000,
    category: "other", // accommodation -> other
    subCategory: "accommodation",
    description: "Khách sạn 3* trung tâm Đà Lạt, 2 đêm",
    date: new Date(2025, 11, 20), // Dec 20
    splitMethod: "percentage",
  },
  {
    title: "Thuê xe đi Đà Lạt",
    amount: 1500000,
    category: "transport",
    description: "Thuê xe 7 chỗ đi về HCM - Đà Lạt",
    date: new Date(2025, 11, 20),
    splitMethod: "percentage",
  },
  {
    title: "Ăn tối BBQ",
    amount: 800000,
    category: "food",
    description: "Buffet BBQ tối đầu tiên",
    date: new Date(2025, 11, 20),
    splitMethod: "equal",
  },
  {
    title: "Vé tham quan Crazy House",
    amount: 200000,
    category: "entertainment",
    description: "Vé vào cửa Crazy House",
    date: new Date(2025, 11, 21),
    splitMethod: "equal",
  },
  {
    title: "Cafe view đồi",
    amount: 150000,
    category: "food",
    description: "Cafe ở đồi Mộng Mơ",
    date: new Date(2025, 11, 21),
    splitMethod: "equal",
  },
];

// Helper functions
const randomInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

// ============================================================================
// TẠO OWNER USER
// ============================================================================
async function createOrGetOwnerUser() {
  console.log("\n👤 Đang kiểm tra/tạo owner user...");

  let user = await User.findOne({ email: CONFIG.ownerUser.email });

  if (user) {
    console.log(`   ✅ User ${CONFIG.ownerUser.email} đã tồn tại`);
    return user;
  }

  // Tạo user mới
  const password = await bcrypt.hash(CONFIG.ownerUser.password, 10);

  user = await User.create({
    email: CONFIG.ownerUser.email,
    passwordHash: password,
    authProvider: "local",
    isEmailVerified: true,
    profile: {
      name: CONFIG.ownerUser.name,
      avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(
        CONFIG.ownerUser.name
      )}&background=E91E63&color=fff&size=200`,
      phone: CONFIG.ownerUser.phone,
      dateOfBirth: CONFIG.ownerUser.dateOfBirth,
      gender: CONFIG.ownerUser.gender,
      location: {
        city: CONFIG.ownerUser.city,
        country: "Vietnam",
      },
      bio: CONFIG.ownerUser.bio,
      occupation: CONFIG.ownerUser.profession,
    },
    settings: {
      currency: { primary: "VND", displayFormat: "đ", decimalPlaces: 0 },
      language: "vi",
      theme: "light",
      notifications: {
        challenges: true,
        budgetAlerts: true,
        groupActivities: true,
        weeklyReports: true,
        pushEnabled: true,
      },
    },
    stats: {
      level: 1,
      points: 100,
      currentStreak: 1,
      longestStreak: 1,
      totalSaved: mongoose.Types.Decimal128.fromString("0"),
      challengesCompleted: 0,
      rank: "Bronze",
    },
    financialSummary: {
      monthlyAllowance: mongoose.Types.Decimal128.fromString("5000000"),
      currentBalance: mongoose.Types.Decimal128.fromString("0"),
      totalIncome: mongoose.Types.Decimal128.fromString("0"),
      totalExpenses: mongoose.Types.Decimal128.fromString("0"),
    },
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  console.log(`✅ Đã tạo owner user: ${user.email} (ID: ${user._id})`);
  return user;
}

// ============================================================================
// LẤY MEMBER USER
// ============================================================================
async function getMemberUser() {
  console.log("\n👤 Đang tìm member user...");

  const user = await User.findOne({ email: CONFIG.memberUser.email });

  if (!user) {
    throw new Error(
      `❌ Không tìm thấy user ${CONFIG.memberUser.email}. Vui lòng chạy seedRealisticAccount.js trước!`
    );
  }

  console.log(`✅ Đã tìm thấy member user: ${user.email} (ID: ${user._id})`);
  return user;
}

// ============================================================================
// TẠO NHÓM
// ============================================================================
async function createGroup(ownerUser, memberUser) {
  console.log("\n👥 Đang tạo nhóm...");

  // Kiểm tra xem nhóm với tên này đã tồn tại chưa
  const existingGroup = await Group.findOne({
    name: CONFIG.group.name,
    "members.userId": ownerUser._id,
  });

  if (existingGroup) {
    console.log(`   ⚠️  Nhóm "${CONFIG.group.name}" đã tồn tại!`);
    console.log(`   🗑️  Đang xóa nhóm cũ và dữ liệu liên quan...`);

    // Xóa dữ liệu liên quan
    await GroupBudget.deleteMany({ groupId: existingGroup._id });
    await Expense.deleteMany({ groupId: existingGroup._id });
    await Group.deleteOne({ _id: existingGroup._id });

    console.log(`   ✅ Đã xóa nhóm cũ`);
  }

  // Tạo invite code
  const inviteCode = generateInviteCode();

  const group = await Group.create({
    name: CONFIG.group.name,
    description: CONFIG.group.description,
    avatar: CONFIG.group.avatar,
    members: [
      {
        userId: ownerUser._id,
        role: "owner",
        joinedAt: new Date(),
        isActive: true,
        permissions: {
          canInviteMembers: true,
          canManageExpenses: true,
          canViewReports: true,
        },
      },
      {
        userId: memberUser._id,
        role: "member",
        joinedAt: new Date(),
        isActive: true,
        permissions: {
          canInviteMembers: false,
          canManageExpenses: true,
          canViewReports: true,
        },
      },
    ],
    settings: CONFIG.group.settings,
    stats: {
      totalExpenses: mongoose.Types.Decimal128.fromString("0"),
      totalTransactions: 0,
      averageExpensePerMember: mongoose.Types.Decimal128.fromString("0"),
      lastActivity: new Date(),
    },
    inviteCode,
    inviteExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    isActive: true,
    version: 1,
  });

  console.log(`✅ Đã tạo nhóm: ${group.name} (ID: ${group._id})`);
  console.log(`   - Owner: ${ownerUser.profile.name}`);
  console.log(`   - Member: ${memberUser.profile.name}`);
  console.log(`   - Invite Code: ${inviteCode}`);

  return group;
}

// ============================================================================
// TẠO NGÂN SÁCH NHÓM
// ============================================================================
async function createGroupBudget(group, ownerUser, memberUser) {
  console.log("\n💰 Đang tạo ngân sách nhóm...");

  const totalAmount = CONFIG.groupBudget.totalAmount;
  const ownerContribution = Math.round(
    totalAmount * (CONFIG.groupBudget.contributions.owner / 100)
  );
  const memberContribution = totalAmount - ownerContribution;

  const groupBudget = await GroupBudget.create({
    groupId: group._id,
    createdBy: ownerUser._id,
    name: CONFIG.groupBudget.name,
    description: CONFIG.groupBudget.description,
    totalBudget: mongoose.Types.Decimal128.fromString(totalAmount.toString()),
    currency: "VND",
    startDate: new Date(2025, 11, 20),
    endDate: new Date(2025, 11, 23),
    members: [
      {
        userId: ownerUser._id,
        name: ownerUser.profile.name,
        contributionPercentage: CONFIG.groupBudget.contributions.owner,
        contributionAmount: mongoose.Types.Decimal128.fromString(
          ownerContribution.toString()
        ),
        amountFunded: mongoose.Types.Decimal128.fromString(
          ownerContribution.toString()
        ),
        amountPaidOut: mongoose.Types.Decimal128.fromString("0"),
        shareSpent: mongoose.Types.Decimal128.fromString("0"),
        balance: mongoose.Types.Decimal128.fromString(
          ownerContribution.toString()
        ),
        debts: [],
        isPaid: true,
        lastUpdated: new Date(),
      },
      {
        userId: memberUser._id,
        name: memberUser.profile.name,
        contributionPercentage: CONFIG.groupBudget.contributions.member,
        contributionAmount: mongoose.Types.Decimal128.fromString(
          memberContribution.toString()
        ),
        amountFunded: mongoose.Types.Decimal128.fromString(
          memberContribution.toString()
        ),
        amountPaidOut: mongoose.Types.Decimal128.fromString("0"),
        shareSpent: mongoose.Types.Decimal128.fromString("0"),
        balance: mongoose.Types.Decimal128.fromString(
          memberContribution.toString()
        ),
        debts: [],
        isPaid: true,
        lastUpdated: new Date(),
      },
    ],
    totalFunded: mongoose.Types.Decimal128.fromString(totalAmount.toString()),
    totalSpent: mongoose.Types.Decimal128.fromString("0"),
    remaining: mongoose.Types.Decimal128.fromString(totalAmount.toString()),
    autoSplitByContribution: true,
    allowPartialTag: true,
    isActive: true,
    isSettled: false,
  });

  console.log(`✅ Đã tạo ngân sách nhóm: ${groupBudget.name}`);
  console.log(`   - Tổng: ${totalAmount.toLocaleString()} VND`);
  console.log(
    `   - ${
      ownerUser.profile.name
    }: ${ownerContribution.toLocaleString()} VND (${
      CONFIG.groupBudget.contributions.owner
    }%)`
  );
  console.log(
    `   - ${
      memberUser.profile.name
    }: ${memberContribution.toLocaleString()} VND (${
      CONFIG.groupBudget.contributions.member
    }%)`
  );

  return groupBudget;
}

// ============================================================================
// TẠO CHI TIÊU NHÓM MẪU
// ============================================================================
async function createGroupExpenses(group, groupBudget, ownerUser, memberUser) {
  console.log("\n💸 Đang tạo chi tiêu nhóm mẫu...");

  const expenses = [];

  for (const expenseData of GROUP_EXPENSES) {
    // Người trả tiền (random giữa owner và member)
    const paidBy = Math.random() > 0.5 ? ownerUser : memberUser;

    // Tính split amounts dựa trên splitMethod
    let splits = [];
    if (expenseData.splitMethod === "percentage") {
      const ownerShare = Math.round(
        expenseData.amount * (CONFIG.groupBudget.contributions.owner / 100)
      );
      const memberShare = expenseData.amount - ownerShare;

      splits = [
        {
          userId: ownerUser._id,
          userName: ownerUser.profile.name,
          percentage: CONFIG.groupBudget.contributions.owner,
          amount: mongoose.Types.Decimal128.fromString(ownerShare.toString()),
        },
        {
          userId: memberUser._id,
          userName: memberUser.profile.name,
          percentage: CONFIG.groupBudget.contributions.member,
          amount: mongoose.Types.Decimal128.fromString(memberShare.toString()),
        },
      ];
    } else {
      // Equal split
      const shareAmount = Math.round(expenseData.amount / 2);
      splits = [
        {
          userId: ownerUser._id,
          userName: ownerUser.profile.name,
          percentage: 50,
          amount: mongoose.Types.Decimal128.fromString(shareAmount.toString()),
        },
        {
          userId: memberUser._id,
          userName: memberUser.profile.name,
          percentage: 50,
          amount: mongoose.Types.Decimal128.fromString(shareAmount.toString()),
        },
      ];
    }

    const expense = {
      userId: paidBy._id,
      groupId: group._id,
      groupBudgetId: groupBudget._id,
      amount: mongoose.Types.Decimal128.fromString(
        expenseData.amount.toString()
      ),
      category: expenseData.category,
      subCategory: expenseData.subCategory || "",
      title: expenseData.title,
      description: expenseData.description,
      paymentMethod: "banking",
      date: expenseData.date,
      isGroupExpense: true,
      groupDetails: {
        groupId: group._id,
        groupName: group.name,
        paidBy: {
          userId: paidBy._id,
          name: paidBy.profile.name,
        },
        splitMethod: expenseData.splitMethod,
        splits,
      },
      createdAt: expenseData.date,
      updatedAt: expenseData.date,
    };

    expenses.push(expense);
  }

  const inserted = await Expense.insertMany(expenses);

  const totalExpenses = expenses.reduce(
    (sum, exp) => sum + parseFloat(exp.amount.toString()),
    0
  );

  console.log(`✅ Đã tạo ${inserted.length} chi tiêu nhóm`);
  console.log(`💰 Tổng chi tiêu: ${totalExpenses.toLocaleString()} VND`);

  // Cập nhật group stats
  await Group.findByIdAndUpdate(group._id, {
    $set: {
      "stats.totalExpenses": mongoose.Types.Decimal128.fromString(
        totalExpenses.toString()
      ),
      "stats.totalTransactions": inserted.length,
      "stats.lastActivity": new Date(),
    },
  });

  console.log(`✅ Đã cập nhật stats cho nhóm`);

  return inserted;
}

// ============================================================================
// HELPER: GENERATE INVITE CODE
// ============================================================================
function generateInviteCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================
async function main() {
  try {
    console.log("\n" + "=".repeat(70));
    console.log("🌱 SEED GROUP DATA - TẠO NHÓM VÀ NGÂN SÁCH NHÓM");
    console.log("=".repeat(70));

    await connectDB();
    console.log("✅ Đã kết nối MongoDB");

    // Tạo/lấy users
    const ownerUser = await createOrGetOwnerUser();
    const memberUser = await getMemberUser();

    // Tạo nhóm
    const group = await createGroup(ownerUser, memberUser);

    // Tạo ngân sách nhóm
    const groupBudget = await createGroupBudget(group, ownerUser, memberUser);

    // Tạo chi tiêu mẫu
    await createGroupExpenses(group, groupBudget, ownerUser, memberUser);

    console.log("\n" + "=".repeat(70));
    console.log("🎉 HOÀN TẤT! NHÓM VÀ DỮ LIỆU ĐÃ ĐƯỢC TẠO THÀNH CÔNG");
    console.log("=".repeat(70));
    console.log("\n📋 THÔNG TIN NHÓM:");
    console.log(`   👥 Tên nhóm: ${group.name}`);
    console.log(`   🔑 Invite Code: ${group.inviteCode}`);
    console.log(
      `   💰 Ngân sách: ${CONFIG.groupBudget.totalAmount.toLocaleString()} VND`
    );
    console.log("\n👥 THÀNH VIÊN:");
    console.log(`   1. ${ownerUser.profile.name} (Owner) - ${ownerUser.email}`);
    console.log(`      Password: ${CONFIG.ownerUser.password}`);
    console.log(`      Đóng góp: ${CONFIG.groupBudget.contributions.owner}%`);
    console.log(
      `   2. ${memberUser.profile.name} (Member) - ${memberUser.email}`
    );
    console.log(`      Đóng góp: ${CONFIG.groupBudget.contributions.member}%`);
    console.log("\n💸 CHI TIÊU NHÓM:");
    console.log(`   - Số giao dịch: ${GROUP_EXPENSES.length}`);
    const totalExpenses = GROUP_EXPENSES.reduce(
      (sum, exp) => sum + exp.amount,
      0
    );
    console.log(`   - Tổng chi: ${totalExpenses.toLocaleString()} VND`);
    console.log("=".repeat(70));
    console.log("\n");

    process.exit(0);
  } catch (error) {
    console.error("❌ Lỗi:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

main();
