/**
 * Proactive Financial Alerts Engine — OrbitLife Personal CFO
 * Evaluates priority alerts across Cash Flow, Credit Utilization, Budget Limits, and Goals.
 */

const { calculateSafeToSpend } = require("./decision_engine");
const { generate30DayForecast } = require("./forecasting");

/**
 * Evaluate all active financial alerts for a user
 * 
 * @param {Object} userData 
 * @returns {Array<Object>} List of prioritized alerts { priority: 'CRITICAL'|'HIGH'|'MEDIUM'|'LOW', title, message, icon, action }
 */
function evaluateAlerts(userData) {
  if (!userData) return [];

  const alerts = [];
  const safeMetrics = calculateSafeToSpend(userData);
  const forecast = generate30DayForecast(userData);
  const creditCard = userData.creditCardAccount || {};
  const preferences = userData.financialPreferences || {};
  const expenses = userData.expenses || [];
  const goals = userData.goals || [];

  // 1. CRITICAL: Negative balance projected within 30 days
  if (forecast.lowestProjectedBalance <= 0) {
    alerts.push({
      priority: "CRITICAL",
      icon: "🚨",
      title: "Negative Balance Projection",
      message: `Your balance is projected to fall to ₹${forecast.lowestProjectedBalance.toLocaleString("en-IN")} on ${forecast.lowestBalanceDate}. Avoid discretionary purchases.`,
      action: "REVIEW_FORECAST",
    });
  }

  // 2. HIGH: Credit Card Utilization > 60%
  const ccLimit = Number(creditCard.creditLimit || 26713.8);
  const ccUsed = Number(creditCard.usedCredit || 0);
  const ccUtil = ccLimit > 0 ? Math.round((ccUsed / ccLimit) * 100) : 0;
  if (ccUtil >= 60) {
    alerts.push({
      priority: "HIGH",
      icon: "💳",
      title: "High Credit Utilization",
      message: `Credit card utilization is at ${ccUtil}% (₹${ccUsed.toLocaleString("en-IN")} / ₹${ccLimit.toLocaleString("en-IN")}). High utilization harms your credit score.`,
      action: "PAY_CARD",
    });
  }

  // 3. HIGH: Liquid Cash below Emergency Buffer
  const emergencyTarget = Number(preferences.emergencyBufferTarget || 1500);
  if (safeMetrics.liquidMoney < emergencyTarget) {
    alerts.push({
      priority: "HIGH",
      icon: "🛡️",
      title: "Emergency Buffer Low",
      message: `Liquid balance (₹${safeMetrics.liquidMoney.toLocaleString("en-IN")}) is below your ₹${emergencyTarget.toLocaleString("en-IN")} emergency target.`,
      action: "SAVE_BUFFER",
    });
  }

  // 4. MEDIUM: Category Budget Overspending (> 80%)
  const categoryBudgets = preferences.categoryBudgets || {};
  const currentMonthStr = new Date().toISOString().substring(0, 7);
  const monthExpenses = expenses.filter((e) => e.date && e.date.startsWith(currentMonthStr));
  const categorySpent = {};
  monthExpenses.forEach((e) => {
    const cat = (e.categoryId || "general").toLowerCase();
    categorySpent[cat] = (categorySpent[cat] || 0) + (Number(e.amount) || 0);
  });

  for (const cat in categoryBudgets) {
    const limit = categoryBudgets[cat];
    const spent = categorySpent[cat] || 0;
    if (limit > 0 && spent >= limit * 0.8) {
      const pct = Math.round((spent / limit) * 100);
      alerts.push({
        priority: "MEDIUM",
        icon: "⚠️",
        title: `${cat.toUpperCase()} Budget Alert`,
        message: `You have used ${pct}% (₹${spent.toLocaleString("en-IN")} / ₹${limit.toLocaleString("en-IN")}) of your monthly ${cat} budget.`,
        action: "CHECK_BUDGET",
      });
    }
  }

  // 5. LOW: Goal Progress Milestone
  goals.forEach((g) => {
    if (!g.isCompleted && g.targetAmount > 0) {
      const pct = Math.round(((g.currentAmount || 0) / g.targetAmount) * 100);
      if (pct >= 50 && pct < 60) {
        alerts.push({
          priority: "LOW",
          icon: "🎯",
          title: "Goal Milestone: 50% Reached",
          message: `Halfway there! You have saved ₹${(g.currentAmount || 0).toLocaleString("en-IN")} towards ${g.name}.`,
          action: "VIEW_GOALS",
        });
      }
    }
  });

  // Sort by priority (CRITICAL -> HIGH -> MEDIUM -> LOW)
  const priorityOrder = { CRITICAL: 1, HIGH: 2, MEDIUM: 3, LOW: 4 };
  alerts.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

  return alerts;
}

module.exports = {
  evaluateAlerts,
};
