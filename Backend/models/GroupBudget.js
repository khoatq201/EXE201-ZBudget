import mongoose from 'mongoose';

const { Schema } = mongoose;

/**
 * GroupBudget Model - Shared budget for groups with contribution tracking
 *
 * Use case: "Du lịch Đà Lạt" - 10 triệu VNĐ
 * - Members: An (40%), Bình (35%), Chi (25%)
 * - Track: Contribution, spending, balance, debts
 * - Auto-split expenses by contribution % or custom
 * - Debt simplification for settlement
 *
 * Option B: Creates personal Expense records with isGroupExpense flag
 */

// Sub-schemas
const DebtSchema = new Schema({
  toUserId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  amount: {
    type: Schema.Types.Decimal128,
    required: true,
  },
}, { _id: false });

const GroupBudgetMemberSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID là bắt buộc'],
  },
  name: {
    type: String,
    required: [true, 'Tên thành viên là bắt buộc'],
  },

  // Contribution setup
  contributionPercentage: {
    type: Number,
    required: [true, 'Phần trăm đóng góp là bắt buộc'],
    min: [0, 'Phần trăm đóng góp phải >= 0'],
    max: [100, 'Phần trăm đóng góp phải <= 100'],
  },
  contributionAmount: {
    type: Schema.Types.Decimal128,
    required: true,
    default: mongoose.Types.Decimal128.fromString('0'),
  },

  // Money flow tracking
  amountFunded: {
    type: Schema.Types.Decimal128,
    required: true,
    default: mongoose.Types.Decimal128.fromString('0'),
    comment: 'Số tiền đã góp vào quỹ chung',
  },
  amountPaidOut: {
    type: Schema.Types.Decimal128,
    required: true,
    default: mongoose.Types.Decimal128.fromString('0'),
    comment: 'Số tiền đã trả thực tế cho expenses',
  },
  shareSpent: {
    type: Schema.Types.Decimal128,
    required: true,
    default: mongoose.Types.Decimal128.fromString('0'),
    comment: 'Tổng chi phí thuộc phần của mình (theo split)',
  },

  // Balance calculation: amountFunded + amountPaidOut - shareSpent
  balance: {
    type: Schema.Types.Decimal128,
    required: true,
    default: mongoose.Types.Decimal128.fromString('0'),
    comment: 'Balance > 0: người khác nợ, Balance < 0: đang nợ người khác',
  },

  // Debt tracking (calculated on-demand)
  debts: [DebtSchema],

  isPaid: {
    type: Boolean,
    default: false,
    comment: 'balance >= 0',
  },
  lastUpdated: {
    type: Date,
    default: Date.now,
  },
}, { _id: false });

const ExpenseSplitSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  percentage: {
    type: Number,
    required: true,
    min: 0,
    max: 100,
  },
  amount: {
    type: Schema.Types.Decimal128,
    required: true,
  },
}, { _id: false });

const GroupBudgetExpenseSchema = new Schema({
  expenseId: {
    type: Schema.Types.ObjectId,
    ref: 'Expense',
    comment: 'Reference to personal Expense record (Option B)',
  },
  description: {
    type: String,
    required: [true, 'Mô tả chi tiêu là bắt buộc'],
    trim: true,
  },
  amount: {
    type: Schema.Types.Decimal128,
    required: [true, 'Số tiền là bắt buộc'],
  },
  paidBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Người trả là bắt buộc'],
  },
  paidByName: {
    type: String,
    required: true,
  },

  splitType: {
    type: String,
    enum: ['auto', 'equal', 'custom'],
    default: 'auto',
    comment: 'auto: dùng contribution %, equal: chia đều, custom: tự set',
  },
  participants: [{
    type: Schema.Types.ObjectId,
    ref: 'User',
  }],
  splits: [ExpenseSplitSchema],

  category: {
    type: String,
    enum: ['food', 'transport', 'shopping', 'entertainment', 'healthcare', 'education', 'utilities', 'accommodation', 'other'],
    default: 'other',
  },
  receiptUrl: {
    type: String,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  notes: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
}, { _id: true });

// Main GroupBudget Schema
const GroupBudgetSchema = new Schema({
  createdBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Creator ID là bắt buộc'],
  },

  // Invite system
  inviteCode: {
    type: String,
    unique: true,
    index: true,
    sparse: true,
    comment: 'Unique invite code for joining (6-8 characters)',
  },
  inviteLink: {
    type: String,
    comment: 'Full invite link to share',
  },

  // Budget info
  name: {
    type: String,
    required: [true, 'Tên ngân sách là bắt buộc'],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
  },

  // Budget amounts
  totalBudget: {
    type: Schema.Types.Decimal128,
    required: [true, 'Tổng ngân sách là bắt buộc'],
  },
  totalSpent: {
    type: Schema.Types.Decimal128,
    default: mongoose.Types.Decimal128.fromString('0'),
  },
  totalFunded: {
    type: Schema.Types.Decimal128,
    default: mongoose.Types.Decimal128.fromString('0'),
    comment: 'Tổng số tiền đã góp vào quỹ',
  },
  remaining: {
    type: Schema.Types.Decimal128,
    default: function() {
      return this.totalBudget;
    },
    comment: 'totalBudget - totalSpent',
  },

  currency: {
    type: String,
    default: 'VND',
  },

  // Period
  startDate: {
    type: Date,
    required: true,
    default: Date.now,
  },
  endDate: {
    type: Date,
  },

  // Members with contribution tracking
  members: {
    type: [GroupBudgetMemberSchema],
    validate: {
      validator: function(v) {
        return v && v.length >= 1;
      },
      message: 'Phải có ít nhất 1 thành viên',
    },
  },

  // Expenses
  expenses: [GroupBudgetExpenseSchema],

  // Settings
  autoSplitByContribution: {
    type: Boolean,
    default: true,
    comment: 'Mặc định split theo contribution %',
  },
  allowPartialTag: {
    type: Boolean,
    default: true,
    comment: 'Cho phép tag subset members',
  },

  // Status
  isActive: {
    type: Boolean,
    default: true,
    index: true,
  },
  isSettled: {
    type: Boolean,
    default: false,
  },
  settledAt: {
    type: Date,
  },

  version: {
    type: Number,
    default: 1,
  },
}, {
  timestamps: true,
  versionKey: false,
});

// Indexes
GroupBudgetSchema.index({ groupId: 1, isActive: 1, createdAt: -1 });
GroupBudgetSchema.index({ createdBy: 1 });
GroupBudgetSchema.index({ 'members.userId': 1 });
GroupBudgetSchema.index({ isSettled: 1 });

// Virtual for JSON transformation
GroupBudgetSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;

    // Convert Decimal128 to float
    if (ret.totalBudget) ret.totalBudget = parseFloat(ret.totalBudget.toString());
    if (ret.totalSpent) ret.totalSpent = parseFloat(ret.totalSpent.toString());
    if (ret.totalFunded) ret.totalFunded = parseFloat(ret.totalFunded.toString());
    if (ret.remaining) ret.remaining = parseFloat(ret.remaining.toString());

    // Convert member amounts
    if (ret.members) {
      ret.members = ret.members.map(member => ({
        ...member,
        contributionAmount: parseFloat(member.contributionAmount.toString()),
        amountFunded: parseFloat(member.amountFunded.toString()),
        amountPaidOut: parseFloat(member.amountPaidOut.toString()),
        shareSpent: parseFloat(member.shareSpent.toString()),
        balance: parseFloat(member.balance.toString()),
        debts: member.debts?.map(debt => ({
          toUserId: debt.toUserId,
          amount: parseFloat(debt.amount.toString()),
        })) || [],
      }));
    }

    // Convert expense amounts
    if (ret.expenses) {
      ret.expenses = ret.expenses.map(expense => ({
        ...expense,
        id: expense._id,
        amount: parseFloat(expense.amount.toString()),
        splits: expense.splits?.map(split => ({
          ...split,
          amount: parseFloat(split.amount.toString()),
        })) || [],
      }));
    }

    return ret;
  },
});

/**
 * Calculate contribution amounts for all members based on totalBudget
 */
GroupBudgetSchema.methods.calculateContributions = function() {
  const totalBudget = parseFloat(this.totalBudget.toString());

  this.members.forEach(member => {
    const amount = (totalBudget * member.contributionPercentage) / 100;
    member.contributionAmount = mongoose.Types.Decimal128.fromString(amount.toFixed(2));
  });
};

/**
 * Add expense to GroupBudget and update member balances
 * @param {Object} expenseData - { description, amount, paidBy, splitType, participants, customSplits, category, receiptUrl, notes }
 * @param {ObjectId} personalExpenseId - Optional reference to personal Expense record
 */
GroupBudgetSchema.methods.addExpense = function(expenseData, personalExpenseId = null) {
  const { description, amount, paidBy, splitType = 'auto', participants, customSplits, category, receiptUrl, notes } = expenseData;

  // Find paidBy member
  const paidByMember = this.members.find(m => m.userId.toString() === paidBy.toString());
  if (!paidByMember) {
    throw new Error('Người trả không phải thành viên của ngân sách này');
  }

  // Determine participants (default: all members)
  const participantIds = participants && participants.length > 0
    ? participants.map(p => p.toString())
    : this.members.map(m => m.userId.toString());

  const participantMembers = this.members.filter(m =>
    participantIds.includes(m.userId.toString())
  );

  if (participantMembers.length === 0) {
    throw new Error('Phải có ít nhất 1 người tham gia chi tiêu');
  }

  // Calculate splits
  const splits = this._calculateSplits(parseFloat(amount), splitType, participantMembers, customSplits);

  // Validate total split = amount
  const totalSplit = splits.reduce((sum, s) => sum + parseFloat(s.amount.toString()), 0);
  if (Math.abs(totalSplit - parseFloat(amount)) > 0.01) {
    throw new Error(`Tổng chia tiền (${totalSplit}) phải bằng số tiền chi (${parseFloat(amount)})`);
  }

  // Create expense record
  const expense = {
    expenseId: personalExpenseId,
    description,
    amount: mongoose.Types.Decimal128.fromString(parseFloat(amount).toFixed(2)),
    paidBy,
    paidByName: paidByMember.name,
    splitType,
    participants: participantIds.map(id => new mongoose.Types.ObjectId(id)),
    splits,
    category: category || 'other',
    receiptUrl,
    notes,
    date: new Date(),
  };

  this.expenses.push(expense);

  // Update budget totals
  const amountNum = parseFloat(amount);
  const currentSpent = parseFloat(this.totalSpent.toString());
  this.totalSpent = mongoose.Types.Decimal128.fromString((currentSpent + amountNum).toFixed(2));
  this.remaining = mongoose.Types.Decimal128.fromString(
    (parseFloat(this.totalBudget.toString()) - currentSpent - amountNum).toFixed(2)
  );

  // Update member balances
  this._updateMemberBalancesAfterExpense(paidBy, splits);

  return expense;
};

/**
 * Calculate expense splits based on split type
 * @private
 */
GroupBudgetSchema.methods._calculateSplits = function(amount, splitType, participantMembers, customSplits) {
  const splits = [];

  if (splitType === 'auto') {
    // Auto: Use contribution % (proportional to participants only)
    const totalContributionPercentage = participantMembers.reduce((sum, m) => sum + m.contributionPercentage, 0);

    participantMembers.forEach((member, index) => {
      const percentage = (member.contributionPercentage / totalContributionPercentage) * 100;
      let splitAmount = (amount * percentage) / 100;

      // Handle rounding: last person gets remainder
      if (index === participantMembers.length - 1) {
        const currentTotal = splits.reduce((sum, s) => sum + parseFloat(s.amount.toString()), 0);
        splitAmount = amount - currentTotal;
      }

      splits.push({
        userId: member.userId,
        name: member.name,
        percentage: parseFloat(percentage.toFixed(2)),
        amount: mongoose.Types.Decimal128.fromString(splitAmount.toFixed(2)),
      });
    });
  } else if (splitType === 'equal') {
    // Equal: Chia đều
    const splitAmount = amount / participantMembers.length;

    participantMembers.forEach((member, index) => {
      let finalAmount = splitAmount;

      // Handle rounding: last person gets remainder
      if (index === participantMembers.length - 1) {
        const currentTotal = splits.reduce((sum, s) => sum + parseFloat(s.amount.toString()), 0);
        finalAmount = amount - currentTotal;
      }

      splits.push({
        userId: member.userId,
        name: member.name,
        percentage: parseFloat((100 / participantMembers.length).toFixed(2)),
        amount: mongoose.Types.Decimal128.fromString(finalAmount.toFixed(2)),
      });
    });
  } else if (splitType === 'custom') {
    // Custom: Use provided splits
    if (!customSplits || customSplits.length === 0) {
      throw new Error('Custom split requires customSplits data');
    }

    customSplits.forEach(split => {
      const member = participantMembers.find(m => m.userId.toString() === split.userId.toString());
      if (!member) {
        throw new Error(`User ${split.userId} not in participants`);
      }

      splits.push({
        userId: member.userId,
        name: member.name,
        percentage: split.percentage || parseFloat(((split.amount / amount) * 100).toFixed(2)),
        amount: mongoose.Types.Decimal128.fromString(parseFloat(split.amount).toFixed(2)),
      });
    });
  }

  return splits;
};

/**
 * Update member balances after adding expense
 * @private
 */
GroupBudgetSchema.methods._updateMemberBalancesAfterExpense = function(paidBy, splits) {
  // Update paidBy member: amountPaidOut increases
  const paidByMember = this.members.find(m => m.userId.toString() === paidBy.toString());
  const totalAmount = splits.reduce((sum, s) => sum + parseFloat(s.amount.toString()), 0);
  const currentPaidOut = parseFloat(paidByMember.amountPaidOut.toString());
  paidByMember.amountPaidOut = mongoose.Types.Decimal128.fromString((currentPaidOut + totalAmount).toFixed(2));

  // Update all participants: shareSpent increases
  splits.forEach(split => {
    const member = this.members.find(m => m.userId.toString() === split.userId.toString());
    if (member) {
      const currentShareSpent = parseFloat(member.shareSpent.toString());
      const splitAmount = parseFloat(split.amount.toString());
      member.shareSpent = mongoose.Types.Decimal128.fromString((currentShareSpent + splitAmount).toFixed(2));
    }
  });

  // Recalculate all balances
  this.updateBalances();
};

/**
 * Record funding (member góp tiền vào quỹ)
 * @param {ObjectId} userId - Member user ID
 * @param {Number} amount - Amount funded
 */
GroupBudgetSchema.methods.recordFunding = function(userId, amount) {
  const member = this.members.find(m => m.userId.toString() === userId.toString());
  if (!member) {
    throw new Error('Không tìm thấy thành viên trong ngân sách');
  }

  const currentFunded = parseFloat(member.amountFunded.toString());
  member.amountFunded = mongoose.Types.Decimal128.fromString((currentFunded + amount).toFixed(2));

  // Update budget totalFunded
  const currentTotalFunded = parseFloat(this.totalFunded.toString());
  this.totalFunded = mongoose.Types.Decimal128.fromString((currentTotalFunded + amount).toFixed(2));

  // Recalculate balance
  this.updateBalances();
};

/**
 * Record payment (debt settlement between members)
 * @param {ObjectId} fromUserId - Debtor (người nợ, âm)
 * @param {ObjectId} toUserId - Creditor (người được nợ, dương)
 * @param {Number} amount - Payment amount
 *
 * Logic: Đây là chuyển tiền nội bộ, KHÔNG ảnh hưởng tổng quỹ
 * - fromMember.amountFunded tăng (đã trả nợ) → balance tăng
 * - toMember.amountPaidOut giảm (đã nhận tiền) → balance giảm
 */
GroupBudgetSchema.methods.recordPayment = function(fromUserId, toUserId, amount) {
  const fromMember = this.members.find(m => m.userId.toString() === fromUserId.toString());
  const toMember = this.members.find(m => m.userId.toString() === toUserId.toString());

  if (!fromMember || !toMember) {
    throw new Error('Không tìm thấy thành viên trong ngân sách');
  }

  // fromMember trả nợ: amountFunded tăng
  // Balance = amountFunded + amountPaidOut - shareSpent
  // Balance tăng (nợ ít đi)
  const fromCurrentFunded = parseFloat(fromMember.amountFunded.toString());
  fromMember.amountFunded = mongoose.Types.Decimal128.fromString((fromCurrentFunded + amount).toFixed(2));

  // toMember nhận tiền: amountPaidOut giảm (vì đã thu hồi tiền đã trả)
  // Balance = amountFunded + amountPaidOut - shareSpent
  // Balance giảm (đã thu hồi được tiền)
  const toCurrentPaidOut = parseFloat(toMember.amountPaidOut.toString());
  toMember.amountPaidOut = mongoose.Types.Decimal128.fromString((toCurrentPaidOut - amount).toFixed(2));

  // KHÔNG update totalFunded vì đây là chuyển tiền nội bộ
  // Tổng quỹ không đổi

  // Recalculate balances
  this.updateBalances();
};

/**
 * Update all member balances
 * Balance = amountFunded + amountPaidOut - shareSpent
 */
GroupBudgetSchema.methods.updateBalances = function() {
  this.members.forEach(member => {
    const amountFunded = parseFloat(member.amountFunded.toString());
    const amountPaidOut = parseFloat(member.amountPaidOut.toString());
    const shareSpent = parseFloat(member.shareSpent.toString());

    const balance = amountFunded + amountPaidOut - shareSpent;
    member.balance = mongoose.Types.Decimal128.fromString(balance.toFixed(2));
    member.isPaid = balance >= -0.01; // Allow small rounding errors
    member.lastUpdated = new Date();
  });

  // Calculate debts
  this.calculateDebts();
};

/**
 * Calculate simplified debts using greedy algorithm
 * Updates each member's debts array
 */
GroupBudgetSchema.methods.calculateDebts = function() {
  const balances = this.members.map(m => ({
    userId: m.userId,
    name: m.name,
    balance: parseFloat(m.balance.toString()),
  }));

  // Separate creditors (balance > 0) and debtors (balance < 0)
  const creditors = balances
    .filter(b => b.balance > 0.01)
    .sort((a, b) => b.balance - a.balance);

  const debtors = balances
    .filter(b => b.balance < -0.01)
    .sort((a, b) => a.balance - b.balance);

  // Reset all debts
  this.members.forEach(m => m.debts = []);

  // Greedy matching
  let i = 0, j = 0;
  while (i < creditors.length && j < debtors.length) {
    const creditor = creditors[i];
    const debtor = debtors[j];
    const amount = Math.min(creditor.balance, Math.abs(debtor.balance));

    if (amount > 0.01) {
      // Debtor owes creditor
      const debtorMember = this.members.find(m => m.userId.toString() === debtor.userId.toString());
      debtorMember.debts.push({
        toUserId: creditor.userId,
        amount: mongoose.Types.Decimal128.fromString(amount.toFixed(2)),
      });
    }

    creditor.balance -= amount;
    debtor.balance += amount;

    if (creditor.balance < 0.01) i++;
    if (debtor.balance > -0.01) j++;
  }
};

/**
 * Get settlement plan (simplified debt transactions)
 * @returns {Array} Array of {from, to, amount}
 */
GroupBudgetSchema.methods.getSettlementPlan = function() {
  const plan = [];

  this.members.forEach(member => {
    if (member.debts && member.debts.length > 0) {
      const balance = parseFloat(member.balance.toString());
      if (balance < -0.01) {
        // This member owes money
        member.debts.forEach(debt => {
          const toMember = this.members.find(m => m.userId.toString() === debt.toUserId.toString());
          plan.push({
            from: member.userId,
            fromName: member.name,
            to: debt.toUserId,
            toName: toMember?.name,
            amount: parseFloat(debt.amount.toString()),
          });
        });
      }
    }
  });

  return plan;
};

/**
 * Mark budget as settled
 */
GroupBudgetSchema.methods.settle = function() {
  // Check if all balances are near zero
  const allSettled = this.members.every(m => {
    const balance = parseFloat(m.balance.toString());
    return Math.abs(balance) < 0.01;
  });

  if (!allSettled) {
    throw new Error('Không thể settle: Vẫn còn số dư chưa thanh toán');
  }

  this.isSettled = true;
  this.settledAt = new Date();
  this.isActive = false;
};

/**
 * Generate unique invite code (6 characters)
 */
GroupBudgetSchema.methods.generateInviteCode = function() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars (0,O,1,I)
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

/**
 * Add member to budget (for invite/join)
 */
GroupBudgetSchema.methods.addMember = function(userId, name, contributionPercentage = 0) {
  // Check if user already exists
  const existingMember = this.members.find(m => m.userId.toString() === userId.toString());
  if (existingMember) {
    throw new Error('User đã là thành viên của budget này');
  }

  // Add new member
  this.members.push({
    userId,
    name,
    contributionPercentage: contributionPercentage || 0,
    contributionAmount: mongoose.Types.Decimal128.fromString('0'),
    amountFunded: mongoose.Types.Decimal128.fromString('0'),
    amountPaidOut: mongoose.Types.Decimal128.fromString('0'),
    shareSpent: mongoose.Types.Decimal128.fromString('0'),
    balance: mongoose.Types.Decimal128.fromString('0'),
    debts: [],
    isPaid: true,
    lastUpdated: new Date(),
  });

  // Recalculate contributions if percentages are set
  if (contributionPercentage > 0) {
    this.calculateContributions();
  }
};

// Pre-save middleware
GroupBudgetSchema.pre('save', async function(next) {
  // Generate invite code if new document
  if (this.isNew && !this.inviteCode) {
    let code = this.generateInviteCode();
    let attempts = 0;
    const maxAttempts = 10;

    // Ensure uniqueness
    while (attempts < maxAttempts) {
      const existing = await mongoose.model('GroupBudget').findOne({ inviteCode: code });
      if (!existing) {
        this.inviteCode = code;
        // Generate invite link (adjust domain as needed)
        this.inviteLink = `zbudget://join/${code}`;
        break;
      }
      code = this.generateInviteCode();
      attempts++;
    }

    if (!this.inviteCode) {
      return next(new Error('Không thể tạo invite code duy nhất'));
    }
  }

  // Calculate contributions if not set
  const needsContributionCalc = this.members.some(m => {
    const amount = parseFloat(m.contributionAmount.toString());
    return amount === 0;
  });

  if (needsContributionCalc) {
    this.calculateContributions();
  }

  // Validate total contribution percentage
  const totalPercentage = this.members.reduce((sum, m) => sum + m.contributionPercentage, 0);
  if (Math.abs(totalPercentage - 100) > 0.01) {
    return next(new Error(`Tổng phần trăm đóng góp phải bằng 100%. Hiện tại: ${totalPercentage}%`));
  }

  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }

  next();
});

const GroupBudget = mongoose.model('GroupBudget', GroupBudgetSchema);

export default GroupBudget;
