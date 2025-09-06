export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  avatar?: string;
  isPremium: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Expense {
  id: string;
  userId: string;
  amount: number;
  currency: Currency;
  category: ExpenseCategory;
  description?: string;
  date: Date;
  receiptImage?: string;
  location?: string;
  paymentMethod?: PaymentMethod;
  groupId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Budget {
  id: string;
  userId: string;
  name: string;
  totalAmount: number;
  currency: Currency;
  categories: BudgetCategory[];
  period: BudgetPeriod;
  startDate: Date;
  endDate: Date;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface BudgetCategory {
  category: ExpenseCategory;
  allocatedAmount: number;
  spentAmount: number;
  percentage: number;
}

export interface Group {
  id: string;
  name: string;
  description?: string;
  members: GroupMember[];
  budget: GroupBudget;
  expenses: Expense[];
  inviteCode: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface GroupMember {
  userId: string;
  name: string;
  email: string;
  avatar?: string;
  role: GroupRole;
  joinedAt: Date;
}

export interface GroupBudget {
  totalAmount: number;
  currency: Currency;
  splitMethod: SplitMethod;
  categories: BudgetCategory[];
  period: BudgetPeriod;
}

export interface Challenge {
  id: string;
  title: string;
  description: string;
  targetAmount: number;
  duration: number; // in days
  difficulty: ChallengeDifficulty;
  reward: string; // emoji or badge
  participants: ChallengeParticipant[];
  startDate: Date;
  endDate: Date;
  isActive: boolean;
}

export interface ChallengeParticipant {
  userId: string;
  name: string;
  avatar?: string;
  currentAmount: number;
  progress: number; // percentage
  isCompleted: boolean;
  completedAt?: Date;
}

export interface ChatMessage {
  id: string;
  userId: string;
  message: string;
  type: MessageType;
  timestamp: Date;
  metadata?: {
    expense?: Partial<Expense>;
    budget?: Partial<Budget>;
    suggestion?: string;
  };
}

export interface OCRResult {
  amount?: number;
  currency?: Currency;
  merchant?: string;
  date?: Date;
  items?: OCRItem[];
  confidence: number;
  rawText: string;
}

export interface OCRItem {
  name: string;
  quantity: number;
  price: number;
  category?: ExpenseCategory;
}

export interface Analytics {
  totalExpenses: number;
  totalBudget: number;
  budgetUtilization: number;
  topCategories: CategoryAnalytics[];
  monthlyTrend: MonthlyTrend[];
  savingsGoal: SavingsGoal;
}

export interface CategoryAnalytics {
  category: ExpenseCategory;
  amount: number;
  percentage: number;
  trend: 'up' | 'down' | 'stable';
}

export interface MonthlyTrend {
  month: string;
  expenses: number;
  budget: number;
  savings: number;
}

export interface SavingsGoal {
  id: string;
  userId: string;
  name: string;
  description?: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: Date;
  category: SavingsCategory;
  priority: SavingsPriority;
  autoSaveEnabled: boolean;
  weeklyTarget: number;
  monthlyTarget: number;
  icon: string;
  color: string;
  reminder: SavingsReminder;
  createdAt: Date;
  updatedAt: Date;
  isCompleted: boolean;
  completedAt?: Date;
}

export interface SavingsReminder {
  enabled: boolean;
  frequency: 'daily' | 'weekly' | 'monthly';
  amount: number;
  time: string; // HH:mm format
  lastNotified?: Date;
}

export interface SavingsPrediction {
  goalId: string;
  estimatedCompletionDate: Date;
  probability: number; // 0-100
  confidence: number; // 0-100
  riskFactors: RiskFactor[];
  opportunities: Opportunity[];
  adjustedWeeklyTarget: number;
  adjustedMonthlyTarget: number;
}

export interface RiskFactor {
  type: 'spending_increase' | 'income_decrease' | 'seasonal_expense' | 'emergency_fund';
  severity: 'low' | 'medium' | 'high';
  impact: number; // Amount in VND
  description: string;
  probability: number; // 0-100
  mitigation: string[];
}

export interface Opportunity {
  type: 'expense_reduction' | 'income_increase' | 'investment_return' | 'bonus_expected';
  potential: number; // Amount in VND
  description: string;
  difficulty: 'easy' | 'medium' | 'hard';
  timeframe: string;
  actionSteps: string[];
}

export interface SavingsSuggestion {
  id: string;
  goalId: string;
  type: 'reduce_expense' | 'increase_income' | 'rebalance_budget' | 'investment_strategy';
  category?: ExpenseCategory;
  title: string;
  description: string;
  currentAmount: number;
  suggestedAmount: number;
  impact: number; // Monthly savings amount
  annualImpact: number;
  difficulty: 'easy' | 'medium' | 'hard';
  confidence: number; // 0-100
  priority: number; // 1-10
  actionable: boolean;
  steps: ActionStep[];
  estimatedTimeToImplement: string;
  potentialRisks: string[];
}

export interface ActionStep {
  order: number;
  description: string;
  estimated_time: string;
  required_tools?: string[];
  success_criteria: string;
}

export interface SpendingPattern {
  userId: string;
  category: ExpenseCategory;
  monthlyAverage: number;
  trend: 'increasing' | 'decreasing' | 'stable';
  seasonality: SeasonalPattern[];
  weeklyDistribution: WeeklySpending[];
  variability: number; // Standard deviation
  predictability: number; // 0-100
}

export interface SeasonalPattern {
  month: number; // 1-12
  multiplier: number; // 1.0 = average, 1.5 = 50% above average
  reason: string;
}

export interface WeeklySpending {
  dayOfWeek: number; // 0-6, 0 = Sunday
  averageAmount: number;
  frequency: number; // How often spending occurs on this day
}

export interface BehavioralInsight {
  userId: string;
  type: 'spending_trigger' | 'saving_habit' | 'budget_behavior' | 'goal_commitment';
  title: string;
  description: string;
  confidence: number; // 0-100
  impact: 'positive' | 'negative' | 'neutral';
  actionable: boolean;
  recommendations: string[];
  evidenceCount: number; // Number of data points supporting this insight
  lastUpdated: Date;
}

export interface GoalOptimization {
  goalId: string;
  currentStrategy: SavingsStrategy;
  optimizedStrategy: SavingsStrategy;
  improvement: {
    timeSaved: number; // Days
    effortReduction: number; // Percentage
    probabilityIncrease: number; // Percentage points
  };
  reasoning: string[];
}

export interface SavingsStrategy {
  weeklyAmount: number;
  monthlyAmount: number;
  categoryAdjustments: CategoryAdjustment[];
  milestones: SavingsMilestone[];
  bufferAmount: number; // Emergency buffer
}

export interface CategoryAdjustment {
  category: ExpenseCategory;
  currentSpending: number;
  targetSpending: number;
  reduction: number;
  difficulty: 'easy' | 'medium' | 'hard';
  methods: string[];
}

export interface SavingsMilestone {
  percentage: number; // 25%, 50%, 75%, 100%
  amount: number;
  estimatedDate: Date;
  reward?: string;
  celebration?: string;
}

export enum SavingsCategory {
  EMERGENCY = 'emergency',
  PURCHASE = 'purchase',
  TRAVEL = 'travel',
  EDUCATION = 'education',
  INVESTMENT = 'investment',
  HOME = 'home',
  VEHICLE = 'vehicle',
  HEALTH = 'health',
  RETIREMENT = 'retirement',
  OTHER = 'other',
}

export enum SavingsPriority {
  CRITICAL = 'critical',
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low',
}

// Enums
export enum Currency {
  VND = 'VND',
  USD = 'USD',
  EUR = 'EUR',
}

export enum ExpenseCategory {
  FOOD = 'food',
  TRANSPORT = 'transport',
  SHOPPING = 'shopping',
  ENTERTAINMENT = 'entertainment',
  HEALTHCARE = 'healthcare',
  EDUCATION = 'education',
  UTILITIES = 'utilities',
  OTHER = 'other',
}

export enum PaymentMethod {
  CASH = 'cash',
  CARD = 'card',
  MOMO = 'momo',
  BANKING = 'banking',
  OTHER = 'other',
}

export enum BudgetPeriod {
  WEEKLY = 'weekly',
  MONTHLY = 'monthly',
  QUARTERLY = 'quarterly',
  YEARLY = 'yearly',
}

export enum GroupRole {
  ADMIN = 'admin',
  MEMBER = 'member',
}

export enum SplitMethod {
  EQUAL = 'equal',
  PERCENTAGE = 'percentage',
  CUSTOM = 'custom',
}

export enum ChallengeDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

export enum MessageType {
  USER = 'user',
  BOT = 'bot',
  SYSTEM = 'system',
}

export enum Theme {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system',
}

// Navigation Types
export type RootStackParamList = {
  Onboarding: undefined;
  Auth: undefined;
  Main: undefined;
};

export type AuthStackParamList = {
  Login: undefined;
  SignUp: undefined;
  ForgotPassword: undefined;
};

export type ReportsStackParamList = {
  ReportsMain: undefined;
  TransactionHistory:
    | {
        period?: string;
        category?: string;
        type?: 'expense' | 'income';
      }
    | undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Budget: undefined;
  Group: undefined;
  Challenge: undefined;
  Reports: undefined;
  Settings: undefined;
};

export type HomeStackParamList = {
  // Home screens
  Dashboard: undefined;
  AddExpense: undefined;
  AddIncome: undefined;
  ScanReceipt: undefined;
  ExpenseDetail: { expenseId: string };
  Chat: undefined;
  SavingsGoals: undefined;
  TransactionHistory:
    | {
        period?: string;
        category?: string;
        type?: 'expense' | 'income';
      }
    | undefined;

  // Budget screens
  BudgetList: undefined;
  BudgetOverview: undefined;
  CreateBudget: undefined;
  EditBudget: { budgetId: string };
  BudgetDetail: { budgetId: string };

  // Group screens
  GroupList: undefined;
  CreateGroup: undefined;
  GroupDetail: { groupId: string };
  InviteMembers: { groupId: string };

  // Other screens
  Reports: undefined;
  Challenge: undefined;
  Settings: undefined;
  Profile: undefined;
  Premium: undefined;
  AIChat: undefined;
  Onboarding: undefined;
};

export type BudgetStackParamList = {
  BudgetList: undefined;
  BudgetOverview: undefined;
  CreateBudget: undefined;
  EditBudget: { budgetId: string };
  BudgetDetail: { budgetId: string };
};

export type GroupStackParamList = {
  GroupList: undefined;
  CreateGroup: undefined;
  GroupDetail: { groupId: string };
  InviteMembers: { groupId: string };
};
