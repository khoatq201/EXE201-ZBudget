import mongoose from "mongoose";
// Sub-schemas
const GroupMemberSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID là bắt buộc"],
    },
    role: {
      type: String,
      enum: ["owner", "admin", "member"],
      default: "member",
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    permissions: {
      canInviteMembers: { type: Boolean, default: false },
      canManageExpenses: { type: Boolean, default: false },
      canViewReports: { type: Boolean, default: true },
    },
  },
  { _id: false }
);
const GroupSettingsSchema = new mongoose.Schema(
  {
    privacy: {
      type: String,
      enum: ["public", "private", "invite-only"],
      default: "private",
    },
    expenseApproval: {
      type: String,
      enum: ["none", "admin", "majority"],
      default: "none",
    },
    currency: {
      type: String,
      enum: ["VND", "USD", "EUR"],
      default: "VND",
    },
    maxMembers: {
      type: Number,
      min: 2,
      max: 100,
      default: 20,
    },
    allowMemberInvites: {
      type: Boolean,
      default: true,
    },
    defaultSplitMethod: {
      type: String,
      enum: ["equal", "percentage", "exact-amounts", "shares"],
      default: "equal",
    },
  },
  { _id: false }
);
const GroupStatsSchema = new mongoose.Schema(
  {
    totalExpenses: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    totalTransactions: {
      type: Number,
      default: 0,
    },
    averageExpensePerMember: {
      type: mongoose.Schema.Types.Decimal128,
      default: 0,
    },
    mostActiveCategory: {
      type: String,
    },
    lastActivity: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);
// Main Group Schema
const GroupSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Tên nhóm là bắt buộc"],
      trim: true,
      maxlength: [100, "Tên nhóm không được vượt quá 100 ký tự"],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, "Mô tả không được vượt quá 500 ký tự"],
    },
    avatar: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^https?:\/\/.+/.test(v);
        },
        message: "Avatar phải là URL hợp lệ",
      },
    },
    // Group Members
    members: {
      type: [GroupMemberSchema],
      validate: {
        validator: function (v) {
          return v.length >= 1 && v.length <= this.settings.maxMembers;
        },
        message: function () {
          return `Nhóm phải có từ 1 đến ${this.settings.maxMembers} thành viên`;
        },
      },
    },
    // Group Settings
    settings: {
      type: GroupSettingsSchema,
      default: () => ({}),
    },
    // Group Statistics
    stats: {
      type: GroupStatsSchema,
      default: () => ({}),
    },
    // Invite System
    inviteCode: {
      type: String,
      unique: true,
      sparse: true,
      validate: {
        validator: function (v) {
          return !v || /^[A-Z0-9]{8}$/.test(v);
        },
        message: "Mã mời phải là 8 ký tự chữ hoa và số",
      },
    },
    inviteExpiresAt: {
      type: Date,
      index: true,
    },
    // Status
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    archivedAt: {
      type: Date,
    },
    version: {
      type: Number,
      default: 1,
    },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      transform: function (doc, ret) {
        // Convert Decimal128 to number for JSON
        if (ret.stats) {
          if (ret.stats.totalExpenses)
            ret.stats.totalExpenses = parseFloat(
              ret.stats.totalExpenses.toString()
            );
          if (ret.stats.averageExpensePerMember)
            ret.stats.averageExpensePerMember = parseFloat(
              ret.stats.averageExpensePerMember.toString()
            );
        }
        return ret;
      },
    },
  }
);
// Indexes
GroupSchema.index({ "members.userId": 1 });
// GroupSchema.index({ inviteCode: 1 }, { sparse: true }); // Removed duplicate - already has unique: true
GroupSchema.index({ isActive: 1, createdAt: -1 });
// Instance Methods
GroupSchema.methods.addMember = function (userId, role = "member") {
  // Check if user is already a member
  const existingMember = this.members.find(
    (member) => member.userId.toString() === userId.toString()
  );
  if (existingMember) {
    if (existingMember.isActive) {
      throw new Error("Người dùng đã là thành viên của nhóm");
    } else {
      // Reactivate existing member
      existingMember.isActive = true;
      existingMember.joinedAt = new Date();
      return existingMember;
    }
  }
  // Check member limit
  const activeMembers = this.members.filter((member) => member.isActive);
  if (activeMembers.length >= this.settings.maxMembers) {
    throw new Error(
      `Nhóm đã đạt giới hạn ${this.settings.maxMembers} thành viên`
    );
  }
  // Add new member
  const newMember = {
    userId,
    role,
    joinedAt: new Date(),
    isActive: true,
    permissions: this.getDefaultPermissions(role),
  };
  this.members.push(newMember);
  return newMember;
};
GroupSchema.methods.removeMember = function (userId) {
  const member = this.members.find(
    (member) => member.userId.toString() === userId.toString()
  );
  if (!member) {
    throw new Error("Người dùng không phải thành viên của nhóm");
  }
  if (member.role === "owner") {
    throw new Error("Không thể xóa chủ sở hữu nhóm");
  }
  member.isActive = false;
  return member;
};
GroupSchema.methods.updateMemberRole = function (userId, newRole) {
  const member = this.members.find(
    (member) =>
      member.userId.toString() === userId.toString() && member.isActive
  );
  if (!member) {
    throw new Error("Không tìm thấy thành viên");
  }
  // Don't allow changing owner role
  if (member.role === "owner" || newRole === "owner") {
    throw new Error("Không thể thay đổi quyền chủ sở hữu");
  }
  member.role = newRole;
  member.permissions = this.getDefaultPermissions(newRole);
  return member;
};
GroupSchema.methods.getDefaultPermissions = function (role) {
  const permissionSets = {
    owner: {
      canInviteMembers: true,
      canManageExpenses: true,
      canViewReports: true,
    },
    admin: {
      canInviteMembers: true,
      canManageExpenses: true,
      canViewReports: true,
    },
    member: {
      canInviteMembers: false,
      canManageExpenses: false,
      canViewReports: true,
    },
  };
  return permissionSets[role] || permissionSets.member;
};
GroupSchema.methods.generateInviteCode = function (expiryHours = 24) {
  // Generate random 8-character code
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  this.inviteCode = code;
  this.inviteExpiresAt = new Date(Date.now() + expiryHours * 60 * 60 * 1000);
  return code;
};
GroupSchema.methods.isInviteCodeValid = function () {
  return (
    this.inviteCode && this.inviteExpiresAt && new Date() < this.inviteExpiresAt
  );
};
GroupSchema.methods.addExpense = function (amount) {
  const currentTotal = parseFloat(this.stats.totalExpenses.toString()) || 0;
  this.stats.totalExpenses = mongoose.Types.Decimal128.fromString(
    (currentTotal + amount).toFixed(2)
  );
  this.stats.totalTransactions += 1;
  this.stats.lastActivity = new Date();
  // Update average expense per member
  const activeMembers = this.members.filter((member) => member.isActive);
  if (activeMembers.length > 0) {
    const newTotal = currentTotal + amount;
    this.stats.averageExpensePerMember = mongoose.Types.Decimal128.fromString(
      (newTotal / activeMembers.length).toFixed(2)
    );
  }
};
GroupSchema.methods.getActiveMembersCount = function () {
  return this.members.filter((member) => member.isActive).length;
};
GroupSchema.methods.getMemberRole = function (userId) {
  const member = this.members.find(
    (member) =>
      member.userId.toString() === userId.toString() && member.isActive
  );
  return member ? member.role : null;
};
GroupSchema.methods.canUserInvite = function (userId) {
  const member = this.members.find(
    (member) =>
      member.userId.toString() === userId.toString() && member.isActive
  );
  return member && member.permissions.canInviteMembers;
};
GroupSchema.methods.canUserManageExpenses = function (userId) {
  const member = this.members.find(
    (member) =>
      member.userId.toString() === userId.toString() && member.isActive
  );
  return member && member.permissions.canManageExpenses;
};
GroupSchema.methods.archive = function () {
  this.isActive = false;
  this.archivedAt = new Date();
};
// Pre-save middleware
GroupSchema.pre("save", function (next) {
  // Update version
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  next();
});
// Static Methods
GroupSchema.statics.findUserGroups = function (userId) {
  return this.find({
    "members.userId": userId,
    "members.isActive": true,
    isActive: true,
  }).sort({ "stats.lastActivity": -1 });
};
GroupSchema.statics.findByInviteCode = function (inviteCode) {
  return this.findOne({
    inviteCode,
    isActive: true,
    inviteExpiresAt: { $gt: new Date() },
  });
};
GroupSchema.statics.findGroupsByOwner = function (userId) {
  return this.find({
    "members.userId": userId,
    "members.role": "owner",
    "members.isActive": true,
    isActive: true,
  }).sort({ createdAt: -1 });
};
GroupSchema.statics.getGroupStats = function (groupId) {
  return this.aggregate([
    {
      $match: { _id: new mongoose.Types.ObjectId(groupId) },
    },
    {
      $lookup: {
        from: "expenses",
        localField: "_id",
        foreignField: "groupId",
        as: "expenses",
      },
    },
    {
      $project: {
        name: 1,
        memberCount: { $size: "$members" },
        totalExpenses: { $sum: "$expenses.amount" },
        expenseCount: { $size: "$expenses" },
        categories: {
          $setUnion: ["$expenses.category"],
        },
        lastActivity: "$stats.lastActivity",
      },
    },
  ]);
};
const Group = mongoose.model("Group", GroupSchema);
export default Group;