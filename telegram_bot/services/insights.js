/**
 * Financial Insights, Daily Briefing & Health Score — OrbitLife Personal CFO
 */

const { calculateSafeToSpend } = require("./decision_engine");

/**
 * Generate Morning 🌅 Orbit Briefing
 * 
 * @param {Object} userData 
 * @returns {Object} Briefing details and formatted message
 */
function generateDailyBriefing(userData) {
  if (!userData) throw new Error("User profile not found.");

  const safeMetrics = calculateSafeToSpend(userData);
  const creditCard = userData.creditCardAccount || {};
  const goals = userData.goals || [];
  const preferences = userData.financialPreferences || {};
  const expenses = userData.expenses || [];

  const todayStr = new Date().toISOString().split("T")[0];
  const todayExpenses = expenses.filter((e) => e.date && e.date.startsWith(todayStr));
  const todaySpent = todayExpenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);

  // Credit Card Utilization
  const limit = Number(creditCard.creditLimit || 26713.8);
  const used = Number(creditCard.usedCredit || 0);
  const utilPercent = limit > 0 ? Math.round((used / limit) * 100) : 0;

  // Primary Goal Progress
  const primaryGoal = goals.find((g) => !g.isCompleted) || goals[0] || null;
  let goalProgressStr = "None set";
  if (primaryGoal) {
    const cur = Number(primaryGoal.currentAmount || 0);
    const tgt = Number(primaryGoal.targetAmount || 1);
    const pct = Math.round((cur / tgt) * 100);
    goalProgressStr = `${primaryGoal.name || "Goal"}: ₹${cur.toLocaleString("en-IN")} / ₹${tgt.toLocaleString("en-IN")} (${pct}%)`;
  }

  // Next Upcoming Bill
  const emis = userData.emis || [];
  let nextBillStr = "No immediate dues";
  const activeEmi = emis.find((e) => !e.isPaid);
  if (activeEmi) {
    nextBillStr = `${activeEmi.title || "EMI"} (₹${Number(activeEmi.monthlyEmi || 0).toLocaleString("en-IN")})`;
  } else if (used > 0) {
    nextBillStr = `Supermoney Card Due (₹${used.toLocaleString("en-IN")})`;
  }

  // CFO Actionable Tip
  let cfoTip = "";
  if (safeMetrics.safeToSpendToday <= 0) {
    cfoTip = "🛑 Discretionary budget exhausted for this cycle. Keep today's spends strictly to essentials.";
  } else if (safeMetrics.financialRiskLevel === "CRITICAL" || safeMetrics.financialRiskLevel === "TIGHT") {
    cfoTip = `⚠️ Finances are tight before salary day (${safeMetrics.daysUntilSalary} days left). Stick under ₹${safeMetrics.safeToSpendToday.toLocaleString("en-IN")} today.`;
  } else if (utilPercent > 50) {
    cfoTip = `💳 Credit card utilization is high (${utilPercent}%). Prioritize bill repayment to safeguard your credit score.`;
  } else {
    cfoTip = `🎯 You are in a healthy position. Staying under ₹${safeMetrics.safeToSpendToday.toLocaleString("en-IN")} today protects your monthly savings.`;
  }

  return {
    liquidMoney: safeMetrics.liquidMoney,
    safeToSpendToday: safeMetrics.safeToSpendToday,
    safeToSpendThisWeek: safeMetrics.safeToSpendThisWeek,
    daysUntilSalary: safeMetrics.daysUntilSalary,
    nextBill: nextBillStr,
    creditCard: {
      used,
      limit,
      utilPercent,
    },
    goalProgress: goalProgressStr,
    todaySpent,
    cfoTip,
    riskLevel: safeMetrics.financialRiskLevel,
  };
}

/**
 * Generate Weekly 📊 CFO Performance Review
 * 
 * @param {Object} userData 
 * @returns {Object} Weekly review metrics and recommendations
 */
function generateWeeklyReview(userData) {
  if (!userData) throw new Error("User profile not found.");

  const expenses = userData.expenses || [];
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

  let thisWeekSpent = 0;
  let lastWeekSpent = 0;
  const categoryMap = {};

  expenses.forEach((e) => {
    const eDate = e.date ? new Date(e.date) : null;
    const amt = Number(e.amount || 0);
    if (!eDate || isNaN(eDate.getTime()) || amt <= 0) return;

    if (eDate >= sevenDaysAgo && eDate <= now) {
      thisWeekSpent += amt;
      const cat = e.categoryId || "general";
      categoryMap[cat] = (categoryMap[cat] || 0) + amt;
    } else if (eDate >= fourteenDaysAgo && eDate < sevenDaysAgo) {
      lastWeekSpent += amt;
    }
  });

  // Calculate percentage change
  let spendDeltaPct = 0;
  if (lastWeekSpent > 0) {
    spendDeltaPct = Math.round(((thisWeekSpent - lastWeekSpent) / lastWeekSpent) * 100);
  }

  // Top spending category
  let topCategory = "General";
  let topCategoryAmount = 0;
  for (const cat in categoryMap) {
    if (categoryMap[cat] > topCategoryAmount) {
      topCategoryAmount = categoryMap[cat];
      topCategory = cat;
    }
  }

  const safeMetrics = calculateSafeToSpend(userData);
  const nextWeekCap = Math.max(1000, safeMetrics.safeToSpendThisWeek);

  let verdict = "";
  if (spendDeltaPct < 0) {
    verdict = `🟢 Excellent week! You spent ${Math.abs(spendDeltaPct)}% less than the previous week.`;
  } else if (spendDeltaPct > 20) {
    verdict = `🟠 Spending spiked by ${spendDeltaPct}% this week, primarily driven by ${topCategory} (₹${topCategoryAmount.toLocaleString("en-IN")}).`;
  } else {
    verdict = `🟡 Stable spending week. Total outflows: ₹${thisWeekSpent.toLocaleString("en-IN")}.`;
  }

  return {
    thisWeekSpent,
    lastWeekSpent,
    spendDeltaPct,
    topCategory,
    topCategoryAmount,
    nextWeekCap,
    verdict,
    categoryBreakdown: categoryMap,
  };
}

/**
 * Calculate Explainable 0–100 Financial Health Score across 5 Core Pillars
 * 
 * @param {Object} userData 
 * @returns {Object} Score (0-100), pillars breakdown, strengths, and priority improvement
 */
function calculateFinancialHealthScore(userData) {
  if (!userData) {
    return {
      score: 50,
      rating: "MODERATE",
      pillars: {},
      positives: [],
      warnings: [],
      topImprovement: "Link your accounts to calculate your financial score.",
    };
  }

  const accounts = userData.accounts || [];
  const emis = userData.emis || [];
  const creditCard = userData.creditCardAccount || {};
  const preferences = userData.financialPreferences || {};
  const fds = userData.fdLots || [];

  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const liquidMoney = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);
  const totalFdValue = fds.reduce((sum, f) => sum + (Number(f.principalAmount || f.amount || 0)), 0);

  const monthlyIncome = Number(preferences.expectedMonthlySalary || 29600);
  const emergencyTarget = Number(preferences.emergencyBufferTarget || 2000);

  // 1. Savings & Net Worth Pillar (25 pts)
  let savingsScore = 0;
  const netWorth = liquidMoney + totalFdValue - Number(creditCard.usedCredit || 0);
  if (netWorth >= monthlyIncome * 1.5) savingsScore = 25;
  else if (netWorth >= monthlyIncome * 0.5) savingsScore = 18;
  else if (netWorth > 0) savingsScore = 12;
  else savingsScore = 5;

  // 2. Debt & EMI Burden Pillar (25 pts)
  let totalMonthlyEmis = 0;
  emis.forEach((e) => {
    if (!e.isPaid) totalMonthlyEmis += Number(e.monthlyEmi || 0);
  });
  const debtToIncomeRatio = monthlyIncome > 0 ? (totalMonthlyEmis / monthlyIncome) : 0;
  let debtScore = 0;
  if (debtToIncomeRatio === 0) debtScore = 25;
  else if (debtToIncomeRatio <= 0.20) debtScore = 22;
  else if (debtToIncomeRatio <= 0.35) debtScore = 15;
  else if (debtToIncomeRatio <= 0.50) debtScore = 10;
  else debtScore = 5;

  // 3. Credit Card Utilization Pillar (20 pts - Optimal < 30%)
  const ccLimit = Number(creditCard.creditLimit || 26713.8);
  const ccUsed = Number(creditCard.usedCredit || 0);
  const ccUtil = ccLimit > 0 ? (ccUsed / ccLimit) : 0;
  let ccScore = 0;
  if (ccUtil <= 0.20) ccScore = 20;
  else if (ccUtil <= 0.30) ccScore = 17;
  else if (ccUtil <= 0.50) ccScore = 12;
  else if (ccUtil <= 0.70) ccScore = 7;
  else ccScore = 2;

  // 4. Emergency Fund Buffer Pillar (15 pts)
  let emergencyScore = 0;
  if (liquidMoney >= emergencyTarget * 2) emergencyScore = 15;
  else if (liquidMoney >= emergencyTarget) emergencyScore = 12;
  else if (liquidMoney >= emergencyTarget * 0.5) emergencyScore = 7;
  else emergencyScore = 2;

  // 5. Cash Flow Stability & Budget Adherence (15 pts)
  const safeMetrics = calculateSafeToSpend(userData);
  let stabilityScore = 0;
  if (safeMetrics.financialRiskLevel === "SAFE") stabilityScore = 15;
  else if (safeMetrics.financialRiskLevel === "MODERATE") stabilityScore = 10;
  else if (safeMetrics.financialRiskLevel === "TIGHT") stabilityScore = 6;
  else stabilityScore = 2;

  const totalScore = Math.round(savingsScore + debtScore + ccScore + emergencyScore + stabilityScore);

  const positives = [];
  const warnings = [];
  let topImprovement = "";

  if (ccUtil <= 0.30) positives.push(`🟢 Credit card utilization is healthy (${Math.round(ccUtil * 100)}%).`);
  else warnings.push(`🟠 High credit utilization (${Math.round(ccUtil * 100)}%) is lowering your score.`);

  if (debtToIncomeRatio <= 0.25) positives.push(`🟢 Low debt-to-income ratio (${Math.round(debtToIncomeRatio * 100)}%).`);
  else warnings.push(`🔴 EMI burden is ${Math.round(debtToIncomeRatio * 100)}% of your monthly earnings.`);

  if (liquidMoney >= emergencyTarget) positives.push(`🟢 Emergency reserve (₹${liquidMoney.toLocaleString("en-IN")}) is funded.`);
  else warnings.push(`🟠 Emergency buffer is under-funded (₹${liquidMoney.toLocaleString("en-IN")} vs target ₹${emergencyTarget.toLocaleString("en-IN")}).`);

  // Determine top actionable improvement
  if (ccUtil > 0.50) {
    topImprovement = "Pay down credit card outstanding to reduce utilization below 30%.";
  } else if (debtToIncomeRatio > 0.35) {
    topImprovement = "Avoid taking on new EMIs until existing loans decrease.";
  } else if (liquidMoney < emergencyTarget) {
    topImprovement = `Build liquid cash buffer by ₹${(emergencyTarget - liquidMoney).toLocaleString("en-IN")} to meet emergency target.`;
  } else {
    topImprovement = "Maintain current daily spending discipline and allocate surplus to investments/FDs.";
  }

  let rating = "EXCELLENT";
  if (totalScore < 50) rating = "CRITICAL";
  else if (totalScore < 70) rating = "MODERATE";
  else if (totalScore < 85) rating = "GOOD";

  return {
    score: totalScore,
    rating,
    pillars: {
      savingsAndNetWorth: { score: savingsScore, max: 25 },
      debtBurden: { score: debtScore, max: 25 },
      creditUtilization: { score: ccScore, max: 20 },
      emergencyCoverage: { score: emergencyScore, max: 15 },
      cashFlowStability: { score: stabilityScore, max: 15 },
    },
    positives,
    warnings,
    topImprovement,
  };
}

module.exports = {
  generateDailyBriefing,
  generateWeeklyReview,
  calculateFinancialHealthScore,
};
