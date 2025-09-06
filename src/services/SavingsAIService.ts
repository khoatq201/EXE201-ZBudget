import {
  SavingsGoal,
  SavingsPrediction,
  SavingsSuggestion,
  SpendingPattern,
  BehavioralInsight,
  GoalOptimization,
  RiskFactor,
  Opportunity,
  Expense,
  ExpenseCategory,
  CategoryAdjustment,
  SavingsMilestone,
  ActionStep,
  SeasonalPattern,
  WeeklySpending,
} from '../types';

export class SavingsAIService {
  /**
   * AI Predictive Analysis - Calculates goal probability and completion prediction
   */
  async calculateGoalPrediction(
    goal: SavingsGoal,
    expenses: Expense[],
    incomes: any[]
  ): Promise<SavingsPrediction> {
    const spendingPatterns = this.analyzeSpendingPatterns(expenses);
    const monthlyAverage = this.calculateMonthlyAverageSpending(expenses);
    const monthlyIncome = this.calculateMonthlyAverageIncome(incomes);
    const currentSavingsCapacity = monthlyIncome - monthlyAverage;

    const remainingAmount = goal.targetAmount - goal.currentAmount;
    const remainingMonths = this.getMonthsBetweenDates(new Date(), goal.targetDate);
    const requiredMonthlySavings = remainingAmount / remainingMonths;

    // Calculate probability based on current capacity vs required
    const baseProbability = Math.min(95, (currentSavingsCapacity / requiredMonthlySavings) * 100);

    // Adjust for historical patterns and seasonal factors
    const historicalSuccessRate = this.calculateHistoricalSuccessRate(expenses, goal.userId);
    const seasonalAdjustment = this.calculateSeasonalAdjustment(goal.targetDate);

    const finalProbability = Math.max(
      5,
      Math.min(95, baseProbability * 0.4 + historicalSuccessRate * 0.4 + seasonalAdjustment * 0.2)
    );

    // Generate risk factors and opportunities
    const riskFactors = await this.identifyRiskFactors(goal, spendingPatterns);
    const opportunities = await this.identifyOpportunities(goal, spendingPatterns, monthlyIncome);

    // Calculate adjusted targets
    const adjustedMonthlyTarget = this.calculateOptimalMonthlyTarget(
      requiredMonthlySavings,
      currentSavingsCapacity,
      riskFactors
    );

    return {
      goalId: goal.id,
      estimatedCompletionDate: this.calculateEstimatedCompletion(goal, adjustedMonthlyTarget),
      probability: Math.round(finalProbability),
      confidence: this.calculateConfidence(expenses.length, remainingMonths),
      riskFactors,
      opportunities,
      adjustedWeeklyTarget: adjustedMonthlyTarget / 4,
      adjustedMonthlyTarget,
    };
  }

  /**
   * Smart Suggestions Engine - Generates actionable savings suggestions
   */
  async generateSavingSuggestions(
    goal: SavingsGoal,
    expenses: Expense[]
  ): Promise<SavingsSuggestion[]> {
    const spendingPatterns = this.analyzeSpendingPatterns(expenses);
    const suggestions: SavingsSuggestion[] = [];

    // Analyze each spending category for reduction opportunities
    for (const pattern of spendingPatterns) {
      if (
        pattern.trend === 'increasing' ||
        pattern.monthlyAverage > this.getCategoryBenchmark(pattern.category)
      ) {
        const suggestion = await this.createExpenseReductionSuggestion(goal, pattern, expenses);
        if (suggestion) {
          suggestions.push(suggestion);
        }
      }
    }

    // Generate income increase suggestions
    const incomeOpportunities = await this.generateIncomeIncreaseSuggestions(goal, expenses);
    suggestions.push(...incomeOpportunities);

    // Generate budget rebalancing suggestions
    const rebalancingSuggestions = await this.generateRebalancingSuggestions(
      goal,
      spendingPatterns
    );
    suggestions.push(...rebalancingSuggestions);

    // Sort by impact and confidence
    return suggestions
      .sort((a, b) => b.impact * b.confidence - a.impact * a.confidence)
      .slice(0, 10); // Top 10 suggestions
  }

  /**
   * Behavioral Insights Analyzer - Identifies spending patterns and habits
   */
  async analyzeBehavioralInsights(
    userId: string,
    expenses: Expense[]
  ): Promise<BehavioralInsight[]> {
    const insights: BehavioralInsight[] = [];

    // Spending trigger analysis
    const spendingTriggers = this.identifySpendingTriggers(expenses);
    insights.push(...spendingTriggers);

    // Saving habit analysis
    const savingHabits = this.analyzeSavingHabits(expenses);
    insights.push(...savingHabits);

    // Budget behavior patterns
    const budgetBehaviors = this.analyzeBudgetBehaviors(expenses);
    insights.push(...budgetBehaviors);

    // Goal commitment patterns
    const commitmentPatterns = this.analyzeGoalCommitment(userId, expenses);
    insights.push(...commitmentPatterns);

    return insights.filter(insight => insight.confidence > 60); // Only high-confidence insights
  }

  /**
   * Adaptive Goals System - Optimizes goals based on real performance
   */
  async optimizeGoal(
    goal: SavingsGoal,
    expenses: Expense[],
    actualPerformance: { weeksSinceStart: number; actualSaved: number }
  ): Promise<GoalOptimization> {
    const currentStrategy = this.calculateCurrentStrategy(goal);
    const performanceRatio =
      actualPerformance.actualSaved / (goal.weeklyTarget * actualPerformance.weeksSinceStart);

    let optimizedStrategy = { ...currentStrategy };

    if (performanceRatio < 0.8) {
      // Under-performing, need easier targets
      optimizedStrategy = this.createEasierStrategy(goal, expenses, performanceRatio);
    } else if (performanceRatio > 1.2) {
      // Over-performing, can increase targets
      optimizedStrategy = this.createAggressiveStrategy(goal, expenses, performanceRatio);
    }

    const improvement = this.calculateImprovement(currentStrategy, optimizedStrategy);

    return {
      goalId: goal.id,
      currentStrategy,
      optimizedStrategy,
      improvement,
      reasoning: this.generateOptimizationReasoning(goal, performanceRatio, improvement),
    };
  }

  // Private helper methods

  private analyzeSpendingPatterns(expenses: Expense[]): SpendingPattern[] {
    const categoryGroups = this.groupExpensesByCategory(expenses);
    const patterns: SpendingPattern[] = [];

    Object.entries(categoryGroups).forEach(([category, categoryExpenses]) => {
      const monthlyAmounts = this.getMonthlyAmounts(categoryExpenses);
      const trend = this.calculateTrend(monthlyAmounts);
      const seasonality = this.calculateSeasonality(categoryExpenses);
      const weeklyDistribution = this.calculateWeeklyDistribution(categoryExpenses);

      patterns.push({
        userId: categoryExpenses[0]?.userId || '',
        category: category as ExpenseCategory,
        monthlyAverage:
          monthlyAmounts.reduce((sum, amount) => sum + amount, 0) / monthlyAmounts.length,
        trend,
        seasonality,
        weeklyDistribution,
        variability: this.calculateVariability(monthlyAmounts),
        predictability: this.calculatePredictability(monthlyAmounts, trend),
      });
    });

    return patterns;
  }

  private calculateMonthlyAverageSpending(expenses: Expense[]): number {
    const monthlyTotals = this.getMonthlyTotals(expenses);
    return monthlyTotals.reduce((sum, total) => sum + total, 0) / monthlyTotals.length;
  }

  private calculateMonthlyAverageIncome(incomes: any[]): number {
    if (!incomes.length) return 0;
    const monthlyTotals = this.getMonthlyIncomeTotals(incomes);
    return monthlyTotals.reduce((sum, total) => sum + total, 0) / monthlyTotals.length;
  }

  private getMonthsBetweenDates(startDate: Date, endDate: Date): number {
    const months =
      (endDate.getFullYear() - startDate.getFullYear()) * 12 +
      (endDate.getMonth() - startDate.getMonth());
    return Math.max(1, months);
  }

  private calculateHistoricalSuccessRate(expenses: Expense[], userId: string): number {
    // Simulate historical success rate based on spending consistency
    const consistencyScore = this.calculateSpendingConsistency(expenses);
    return Math.min(90, consistencyScore * 100);
  }

  private calculateSeasonalAdjustment(targetDate: Date): number {
    const targetMonth = targetDate.getMonth() + 1;
    // Vietnamese seasonal spending patterns
    const seasonalMultipliers: Record<number, number> = {
      1: 1.3, // Tet season - higher spending
      2: 1.2, // Tet aftermath
      3: 1.0, // Normal
      4: 1.0, // Normal
      5: 1.1, // Summer activities
      6: 1.0, // Normal
      7: 1.0, // Normal
      8: 1.1, // Back to school
      9: 1.2, // Mid-autumn festival
      10: 1.0, // Normal
      11: 1.1, // Black Friday/11.11
      12: 1.2, // Christmas/New Year
    };

    return 1 / (seasonalMultipliers[targetMonth] || 1.0);
  }

  private async identifyRiskFactors(
    goal: SavingsGoal,
    patterns: SpendingPattern[]
  ): Promise<RiskFactor[]> {
    const risks: RiskFactor[] = [];

    // Increasing spending trends
    patterns.forEach(pattern => {
      if (pattern.trend === 'increasing') {
        risks.push({
          type: 'spending_increase',
          severity: pattern.monthlyAverage > 1000000 ? 'high' : 'medium',
          impact: pattern.monthlyAverage * 0.2,
          description: `${pattern.category} spending is increasing`,
          probability: 70,
          mitigation: [
            `Set strict budget for ${pattern.category}`,
            'Track daily spending in this category',
            'Find alternatives or substitutes',
          ],
        });
      }
    });

    // Seasonal expense risks
    const currentMonth = new Date().getMonth() + 1;
    if ([1, 2, 9, 12].includes(currentMonth)) {
      risks.push({
        type: 'seasonal_expense',
        severity: 'medium',
        impact: 500000,
        description: 'Holiday season may increase spending',
        probability: 80,
        mitigation: [
          'Plan holiday expenses in advance',
          'Set aside money specifically for holidays',
          'Look for discounts and deals',
        ],
      });
    }

    return risks;
  }

  private async identifyOpportunities(
    goal: SavingsGoal,
    patterns: SpendingPattern[],
    monthlyIncome: number
  ): Promise<Opportunity[]> {
    const opportunities: Opportunity[] = [];

    // High variability categories (inconsistent spending)
    patterns.forEach(pattern => {
      if (pattern.variability > pattern.monthlyAverage * 0.3) {
        opportunities.push({
          type: 'expense_reduction',
          potential: pattern.monthlyAverage * 0.2,
          description: `Reduce variability in ${pattern.category} spending`,
          difficulty: 'medium',
          timeframe: '2-4 weeks',
          actionSteps: [
            `Track ${pattern.category} expenses daily`,
            'Identify spending triggers',
            'Set weekly spending limits',
            'Find cheaper alternatives',
          ],
        });
      }
    });

    // Income increase opportunities
    if (monthlyIncome < 15000000) {
      // Below 15M VND
      opportunities.push({
        type: 'income_increase',
        potential: monthlyIncome * 0.2,
        description: 'Explore side income opportunities',
        difficulty: 'medium',
        timeframe: '1-3 months',
        actionSteps: [
          'Identify marketable skills',
          'Look for freelance opportunities',
          'Consider part-time work',
          'Explore online income sources',
        ],
      });
    }

    return opportunities;
  }

  private calculateOptimalMonthlyTarget(
    required: number,
    capacity: number,
    risks: RiskFactor[]
  ): number {
    const riskAdjustment = risks.reduce(
      (total, risk) => total + (risk.impact * risk.probability) / 100,
      0
    );

    const bufferAmount = Math.max(required * 0.1, riskAdjustment);
    return Math.min(capacity * 0.8, required + bufferAmount);
  }

  private calculateEstimatedCompletion(goal: SavingsGoal, monthlyTarget: number): Date {
    const remainingAmount = goal.targetAmount - goal.currentAmount;
    const monthsNeeded = Math.ceil(remainingAmount / monthlyTarget);

    const estimatedDate = new Date();
    estimatedDate.setMonth(estimatedDate.getMonth() + monthsNeeded);

    return estimatedDate;
  }

  private calculateConfidence(dataPoints: number, remainingMonths: number): number {
    const dataConfidence = Math.min(95, (dataPoints / 30) * 100); // More data = higher confidence
    const timeConfidence = remainingMonths > 6 ? 90 : Math.max(50, remainingMonths * 15);

    return Math.round((dataConfidence + timeConfidence) / 2);
  }

  private async createExpenseReductionSuggestion(
    goal: SavingsGoal,
    pattern: SpendingPattern,
    expenses: Expense[]
  ): Promise<SavingsSuggestion | null> {
    const reductionPotential = pattern.monthlyAverage * 0.15; // 15% reduction

    if (reductionPotential < 50000) return null; // Not worth optimizing small amounts

    const steps: ActionStep[] = [
      {
        order: 1,
        description: `Track all ${pattern.category} expenses for one week`,
        estimated_time: '10 minutes daily',
        success_criteria: 'Complete expense log for 7 days',
      },
      {
        order: 2,
        description: `Identify the top 3 highest ${pattern.category} expenses`,
        estimated_time: '30 minutes',
        success_criteria: 'List of top 3 expenses with amounts',
      },
      {
        order: 3,
        description: `Find cheaper alternatives for each identified expense`,
        estimated_time: '2 hours',
        required_tools: ['Internet research', 'Price comparison apps'],
        success_criteria: 'List of alternatives with potential savings',
      },
      {
        order: 4,
        description: `Implement changes and monitor for 2 weeks`,
        estimated_time: '5 minutes daily',
        success_criteria: `Achieve ${reductionPotential.toLocaleString('vi-VN')}đ reduction`,
      },
    ];

    return {
      id: `reduce_${pattern.category}_${Date.now()}`,
      goalId: goal.id,
      type: 'reduce_expense',
      category: pattern.category,
      title: `Optimize ${pattern.category} spending`,
      description: `Your ${pattern.category} spending is ${pattern.trend}. You can save up to ${reductionPotential.toLocaleString('vi-VN')}đ per month.`,
      currentAmount: pattern.monthlyAverage,
      suggestedAmount: pattern.monthlyAverage - reductionPotential,
      impact: reductionPotential,
      annualImpact: reductionPotential * 12,
      difficulty: reductionPotential > 500000 ? 'medium' : 'easy',
      confidence: pattern.predictability,
      priority: Math.round(reductionPotential / 100000 + pattern.predictability / 10),
      actionable: true,
      steps,
      estimatedTimeToImplement: '2-3 weeks',
      potentialRisks: [
        'May require lifestyle changes',
        'Initial effort needed to find alternatives',
        'Savings may take time to materialize',
      ],
    };
  }

  private async generateIncomeIncreaseSuggestions(
    goal: SavingsGoal,
    expenses: Expense[]
  ): Promise<SavingsSuggestion[]> {
    const suggestions: SavingsSuggestion[] = [];

    // Skill-based income opportunities
    suggestions.push({
      id: `income_skill_${Date.now()}`,
      goalId: goal.id,
      type: 'increase_income',
      title: 'Develop monetizable skills',
      description: 'Learn in-demand skills and offer services online',
      currentAmount: 0,
      suggestedAmount: 2000000, // 2M VND potential monthly
      impact: 2000000,
      annualImpact: 24000000,
      difficulty: 'medium',
      confidence: 70,
      priority: 8,
      actionable: true,
      steps: [
        {
          order: 1,
          description: 'Identify your existing skills and interests',
          estimated_time: '1 hour',
          success_criteria: 'List of 5-10 skills/interests',
        },
        {
          order: 2,
          description: 'Research market demand for these skills',
          estimated_time: '3 hours',
          required_tools: ['Internet research', 'Freelance platforms'],
          success_criteria: 'Market analysis for top 3 skills',
        },
        {
          order: 3,
          description: 'Choose one skill and create learning plan',
          estimated_time: '2 hours',
          success_criteria: 'Detailed 30-day learning plan',
        },
        {
          order: 4,
          description: 'Complete learning and start offering services',
          estimated_time: '30 days',
          required_tools: ['Online courses', 'Practice projects'],
          success_criteria: 'First paying client or project',
        },
      ],
      estimatedTimeToImplement: '1-2 months',
      potentialRisks: [
        'Time investment required',
        'Competition in market',
        'Income may be irregular initially',
      ],
    });

    return suggestions;
  }

  private async generateRebalancingSuggestions(
    goal: SavingsGoal,
    patterns: SpendingPattern[]
  ): Promise<SavingsSuggestion[]> {
    const suggestions: SavingsSuggestion[] = [];

    // Find overspending categories
    const overspendingCategories = patterns.filter(
      p => p.monthlyAverage > this.getCategoryBenchmark(p.category)
    );

    if (overspendingCategories.length >= 2) {
      const totalOverspending = overspendingCategories.reduce(
        (sum, cat) => sum + (cat.monthlyAverage - this.getCategoryBenchmark(cat.category)),
        0
      );

      suggestions.push({
        id: `rebalance_${Date.now()}`,
        goalId: goal.id,
        type: 'rebalance_budget',
        title: 'Rebalance your budget allocation',
        description: `You're overspending in ${overspendingCategories.length} categories. Reallocating could save ${totalOverspending.toLocaleString('vi-VN')}đ monthly.`,
        currentAmount: patterns.reduce((sum, p) => sum + p.monthlyAverage, 0),
        suggestedAmount: patterns.reduce((sum, p) => sum + p.monthlyAverage, 0) - totalOverspending,
        impact: totalOverspending,
        annualImpact: totalOverspending * 12,
        difficulty: 'medium',
        confidence: 80,
        priority: 7,
        actionable: true,
        steps: [
          {
            order: 1,
            description: 'Review current budget allocation',
            estimated_time: '30 minutes',
            success_criteria: 'Clear overview of current spending by category',
          },
          {
            order: 2,
            description: 'Set new limits for overspending categories',
            estimated_time: '20 minutes',
            success_criteria: 'New budget limits defined',
          },
          {
            order: 3,
            description: 'Implement changes gradually over 2 weeks',
            estimated_time: '10 minutes daily',
            success_criteria: 'Stay within new limits for 14 days',
          },
        ],
        estimatedTimeToImplement: '2 weeks',
        potentialRisks: [
          'May require significant lifestyle adjustments',
          'Initial discomfort with reduced spending',
        ],
      });
    }

    return suggestions;
  }

  // Additional helper methods...

  private getCategoryBenchmark(category: ExpenseCategory): number {
    // Average Vietnamese spending benchmarks (monthly)
    const benchmarks: Record<ExpenseCategory, number> = {
      [ExpenseCategory.FOOD]: 3000000,
      [ExpenseCategory.TRANSPORT]: 1500000,
      [ExpenseCategory.SHOPPING]: 2000000,
      [ExpenseCategory.ENTERTAINMENT]: 1000000,
      [ExpenseCategory.HEALTHCARE]: 500000,
      [ExpenseCategory.EDUCATION]: 800000,
      [ExpenseCategory.UTILITIES]: 800000,
      [ExpenseCategory.OTHER]: 500000,
    };

    return benchmarks[category] || 1000000;
  }

  private groupExpensesByCategory(expenses: Expense[]): Record<string, Expense[]> {
    return expenses.reduce(
      (groups, expense) => {
        const category = expense.category;
        if (!groups[category]) {
          groups[category] = [];
        }
        groups[category].push(expense);
        return groups;
      },
      {} as Record<string, Expense[]>
    );
  }

  private getMonthlyAmounts(expenses: Expense[]): number[] {
    const monthlyTotals: Record<string, number> = {};

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const monthKey = `${expenseDate.getFullYear()}-${expenseDate.getMonth()}`;
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] || 0) + expense.amount;
    });

    return Object.values(monthlyTotals);
  }

  private getMonthlyTotals(expenses: Expense[]): number[] {
    return this.getMonthlyAmounts(expenses);
  }

  private getMonthlyIncomeTotals(incomes: any[]): number[] {
    const monthlyTotals: Record<string, number> = {};

    incomes.forEach(income => {
      const date = new Date(income.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth()}`;
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] || 0) + income.amount;
    });

    return Object.values(monthlyTotals);
  }

  private calculateTrend(amounts: number[]): 'increasing' | 'decreasing' | 'stable' {
    if (amounts.length < 2) return 'stable';

    const firstHalf = amounts.slice(0, Math.floor(amounts.length / 2));
    const secondHalf = amounts.slice(Math.floor(amounts.length / 2));

    const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
    const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;

    const change = (secondAvg - firstAvg) / firstAvg;

    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  private calculateSeasonality(expenses: Expense[]): SeasonalPattern[] {
    const monthlyAverages: Record<number, number[]> = {};

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const month = expenseDate.getMonth() + 1;
      if (!monthlyAverages[month]) {
        monthlyAverages[month] = [];
      }
      monthlyAverages[month].push(expense.amount);
    });

    const patterns: SeasonalPattern[] = [];
    const overallAverage = expenses.reduce((sum, exp) => sum + exp.amount, 0) / expenses.length;

    Object.entries(monthlyAverages).forEach(([month, amounts]) => {
      const monthAverage = amounts.reduce((sum, amount) => sum + amount, 0) / amounts.length;
      const multiplier = monthAverage / overallAverage;

      patterns.push({
        month: parseInt(month),
        multiplier,
        reason: this.getSeasonalReason(parseInt(month), multiplier),
      });
    });

    return patterns;
  }

  private getSeasonalReason(month: number, multiplier: number): string {
    const highSpendingReasons: Record<number, string> = {
      1: 'Tet holiday shopping',
      2: 'Post-Tet activities',
      5: 'Summer vacation',
      9: 'Mid-autumn festival',
      12: 'Christmas and New Year',
    };

    const lowSpendingReasons: Record<number, string> = {
      3: 'Post-holiday budget tightening',
      6: 'Mid-year savings focus',
      10: 'Preparing for year-end',
    };

    if (multiplier > 1.2) {
      return highSpendingReasons[month] || 'Higher spending period';
    } else if (multiplier < 0.8) {
      return lowSpendingReasons[month] || 'Lower spending period';
    }

    return 'Normal spending period';
  }

  private calculateWeeklyDistribution(expenses: Expense[]): WeeklySpending[] {
    const weeklyData: Record<number, { total: number; count: number }> = {};

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const dayOfWeek = expenseDate.getDay();
      if (!weeklyData[dayOfWeek]) {
        weeklyData[dayOfWeek] = { total: 0, count: 0 };
      }
      weeklyData[dayOfWeek].total += expense.amount;
      weeklyData[dayOfWeek].count += 1;
    });

    const weeklySpending: WeeklySpending[] = [];
    for (let day = 0; day < 7; day++) {
      const data = weeklyData[day] || { total: 0, count: 0 };
      weeklySpending.push({
        dayOfWeek: day,
        averageAmount: data.count > 0 ? data.total / data.count : 0,
        frequency: data.count / (expenses.length / 7), // Relative frequency
      });
    }

    return weeklySpending;
  }

  private calculateVariability(amounts: number[]): number {
    if (amounts.length < 2) return 0;

    const mean = amounts.reduce((sum, val) => sum + val, 0) / amounts.length;
    const variance =
      amounts.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / amounts.length;

    return Math.sqrt(variance);
  }

  private calculatePredictability(amounts: number[], trend: string): number {
    const variability = this.calculateVariability(amounts);
    const mean = amounts.reduce((sum, val) => sum + val, 0) / amounts.length;
    const coefficient = variability / mean;

    let base = Math.max(0, 100 - coefficient * 100);

    // Adjust for trend consistency
    if (trend === 'stable') base += 10;

    return Math.min(100, base);
  }

  private calculateSpendingConsistency(expenses: Expense[]): number {
    const monthlyTotals = this.getMonthlyTotals(expenses);
    const variability = this.calculateVariability(monthlyTotals);
    const mean = monthlyTotals.reduce((sum, val) => sum + val, 0) / monthlyTotals.length;

    return Math.max(0.3, 1 - variability / mean);
  }

  // Behavioral analysis methods
  private identifySpendingTriggers(expenses: Expense[]): BehavioralInsight[] {
    const insights: BehavioralInsight[] = [];

    // Weekend spending analysis
    const weekendExpenses = expenses.filter(exp => {
      const expDate = new Date(exp.date);
      const day = expDate.getDay();
      return day === 0 || day === 6; // Sunday or Saturday
    });

    if (weekendExpenses.length > expenses.length * 0.4) {
      insights.push({
        userId: expenses[0]?.userId || '',
        type: 'spending_trigger',
        title: 'Weekend Spending Pattern',
        description: 'You tend to spend significantly more on weekends',
        confidence: 85,
        impact: 'negative',
        actionable: true,
        recommendations: [
          'Plan weekend activities with fixed budgets',
          'Prepare entertainment alternatives at home',
          'Set weekend spending alerts',
        ],
        evidenceCount: weekendExpenses.length,
        lastUpdated: new Date(),
      });
    }

    return insights;
  }

  private analyzeSavingHabits(expenses: Expense[]): BehavioralInsight[] {
    const insights: BehavioralInsight[] = [];

    // Early month vs late month spending
    const earlyMonthExpenses = expenses.filter(exp => new Date(exp.date).getDate() <= 10);
    const lateMonthExpenses = expenses.filter(exp => new Date(exp.date).getDate() > 20);

    const earlyAvg =
      earlyMonthExpenses.reduce((sum, exp) => sum + exp.amount, 0) / earlyMonthExpenses.length;
    const lateAvg =
      lateMonthExpenses.reduce((sum, exp) => sum + exp.amount, 0) / lateMonthExpenses.length;

    if (earlyAvg > lateAvg * 1.5) {
      insights.push({
        userId: expenses[0]?.userId || '',
        type: 'saving_habit',
        title: 'Front-loaded Spending Pattern',
        description:
          'You spend more at the beginning of the month, which shows good restraint later',
        confidence: 75,
        impact: 'positive',
        actionable: true,
        recommendations: [
          'Continue this pattern but set aside savings first',
          'Automate savings at month start',
          'Use this natural restraint to boost savings',
        ],
        evidenceCount: earlyMonthExpenses.length + lateMonthExpenses.length,
        lastUpdated: new Date(),
      });
    }

    return insights;
  }

  private analyzeBudgetBehaviors(expenses: Expense[]): BehavioralInsight[] {
    // Placeholder for budget behavior analysis
    return [];
  }

  private analyzeGoalCommitment(userId: string, expenses: Expense[]): BehavioralInsight[] {
    // Placeholder for goal commitment analysis
    return [];
  }

  // Goal optimization methods
  private calculateCurrentStrategy(goal: SavingsGoal): any {
    return {
      weeklyAmount: goal.weeklyTarget,
      monthlyAmount: goal.monthlyTarget,
      categoryAdjustments: [],
      milestones: [],
      bufferAmount: goal.monthlyTarget * 0.1,
    };
  }

  private createEasierStrategy(
    goal: SavingsGoal,
    expenses: Expense[],
    performanceRatio: number
  ): any {
    const adjustedMonthly = goal.monthlyTarget * 0.8; // Reduce by 20%
    return {
      weeklyAmount: adjustedMonthly / 4,
      monthlyAmount: adjustedMonthly,
      categoryAdjustments: [],
      milestones: [],
      bufferAmount: adjustedMonthly * 0.05,
    };
  }

  private createAggressiveStrategy(
    goal: SavingsGoal,
    expenses: Expense[],
    performanceRatio: number
  ): any {
    const adjustedMonthly = goal.monthlyTarget * 1.2; // Increase by 20%
    return {
      weeklyAmount: adjustedMonthly / 4,
      monthlyAmount: adjustedMonthly,
      categoryAdjustments: [],
      milestones: [],
      bufferAmount: adjustedMonthly * 0.15,
    };
  }

  private calculateImprovement(current: any, optimized: any): any {
    return {
      timeSaved: 0,
      effortReduction: 0,
      probabilityIncrease: 0,
    };
  }

  private generateOptimizationReasoning(
    goal: SavingsGoal,
    performanceRatio: number,
    improvement: any
  ): string[] {
    const reasoning: string[] = [];

    if (performanceRatio < 0.8) {
      reasoning.push('Current targets are too aggressive based on actual performance');
      reasoning.push('Lowering targets will improve success probability');
    } else if (performanceRatio > 1.2) {
      reasoning.push('You are exceeding targets consistently');
      reasoning.push('Higher targets could help reach goal faster');
    }

    return reasoning;
  }
}

export default new SavingsAIService();
