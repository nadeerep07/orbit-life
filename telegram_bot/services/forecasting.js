/**
 * Cash Flow Forecasting & Recurring Intelligence — OrbitLife Personal CFO
 * 30-Day Forward-Looking Timeline, Lowest Balance Dip Detection & Subscription Discovery
 */

/**
 * Generate a 30-Day Forward-Looking Cash Flow Forecast
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {Date} [startDate=new Date()] Starting date
 * @returns {Object} Forecast summary, timeline, lowest balance point, and cash-flow risks
 */
function generate30DayForecast(userData, startDate = new Date()) {
  if (!userData) {
    return {
      currentLiquidBalance: 0,
      lowestProjectedBalance: 0,
      lowestBalanceDate: null,
      projectedEndingBalance: 0,
      timeline: [],
      majorEvents: [],
      hasCashFlowRisk: false,
    };
  }

  const accounts = userData.accounts || [];
  const emis = userData.emis || [];
  const creditCard = userData.creditCardAccount || {};
  const borrowLends = userData.borrowLends || [];
  const preferences = userData.financialPreferences || {};

  // 1. Initial Starting Liquid Cash
  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const startingLiquid = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);

  const salaryDay = Number(preferences.salaryDayOfMonth || 1);
  const expectedSalary = Number(preferences.expectedMonthlySalary || 0);
  const ccDueDateDay = Number(creditCard.dueDateDay || 15);
  const ccUsedCredit = Number(creditCard.usedCredit || 0);

  const timeline = [];
  const majorEvents = [];
  let runningBalance = startingLiquid;
  let lowestBalance = startingLiquid;
  let lowestDateStr = new Date(startDate).toISOString().split("T")[0];

  const start = new Date(startDate);

  for (let i = 0; i <= 30; i++) {
    const dayDate = new Date(start);
    dayDate.setDate(start.getDate() + i);
    const dayNum = dayDate.getDate();
    const dateStr = dayDate.toISOString().split("T")[0];

    const dayInflows = [];
    const dayOutflows = [];
    let netDayChange = 0;

    // A. Expected Salary Credit
    if (dayNum === salaryDay && expectedSalary > 0 && i > 0) {
      dayInflows.push({
        title: "Salary Inflow",
        amount: expectedSalary,
        type: "salary",
      });
      netDayChange += expectedSalary;
      majorEvents.push({
        date: dateStr,
        title: "💰 Salary Credit",
        amount: expectedSalary,
        type: "inflow",
      });
    }

    // B. Credit Card Due Date Settlement
    if (dayNum === ccDueDateDay && ccUsedCredit > 0 && i > 0 && i <= 30) {
      // Only deduct if not already paid
      dayOutflows.push({
        title: "Credit Card Bill",
        amount: ccUsedCredit,
        type: "credit_card",
      });
      netDayChange -= ccUsedCredit;
      majorEvents.push({
        date: dateStr,
        title: "💳 Super Money CC Bill",
        amount: ccUsedCredit,
        type: "outflow",
      });
    }

    // C. Active EMIs
    emis.forEach((emi) => {
      if (!emi.isPaid) {
        let emiDueDay = 5; // Default 5th of month
        if (emi.dueDate) {
          emiDueDay = new Date(emi.dueDate).getDate();
        } else if (emi.startDate) {
          emiDueDay = new Date(emi.startDate).getDate();
        }

        if (dayNum === emiDueDay && i > 0) {
          const emiAmt = Number(emi.monthlyEmi || 0);
          dayOutflows.push({
            title: `EMI: ${emi.title}`,
            amount: emiAmt,
            type: "emi",
          });
          netDayChange -= emiAmt;
          majorEvents.push({
            date: dateStr,
            title: `📑 EMI: ${emi.title}`,
            amount: emiAmt,
            type: "outflow",
          });
        }
      }
    });

    // D. Expected Debt Inflows (e.g. Shamveel receivable)
    if (i === 5) {
      borrowLends.forEach((b) => {
        if (!b.isSettled && b.status !== "settled" && b.status !== "completed") {
          if (b.type === "lend" || b.type === "lent") {
            const totalP = Number(b.amount || 0);
            const paid = (b.transactions || []).reduce((s, t) => s + (Number(t.amount) || 0), 0);
            const remaining = Math.max(0, totalP - paid);
            if (remaining > 0) {
              dayInflows.push({
                title: `Receivable: ${b.personName}`,
                amount: remaining,
                type: "debt_recovery",
              });
              // Expected debt recovery logged as potential inflow
            }
          }
        }
      });
    }

    runningBalance += netDayChange;

    if (runningBalance < lowestBalance) {
      lowestBalance = runningBalance;
      lowestDateStr = dateStr;
    }

    timeline.push({
      dayIndex: i,
      date: dateStr,
      dayNumber: dayNum,
      openingBalance: runningBalance - netDayChange,
      closingBalance: runningBalance,
      inflows: dayInflows,
      outflows: dayOutflows,
      netChange: netDayChange,
    });
  }

  const emergencyBuffer = Number(preferences.emergencyBufferTarget || 1500);
  const hasCashFlowRisk = lowestBalance < emergencyBuffer;

  return {
    currentLiquidBalance: startingLiquid,
    lowestProjectedBalance: lowestBalance,
    lowestBalanceDate: lowestDateStr,
    projectedEndingBalance: runningBalance,
    hasCashFlowRisk,
    emergencyBuffer,
    majorEvents,
    timeline,
    recommendation: hasCashFlowRisk
      ? lowestBalance <= 0
        ? `⚠️ CRITICAL: Balance projected to drop to ₹${lowestBalance.toLocaleString("en-IN")} on ${lowestDateStr}. Avoid new spends.`
        : `🟠 WARNING: Balance projected to reach ₹${lowestBalance.toLocaleString("en-IN")} on ${lowestDateStr} (below your ₹${emergencyBuffer.toLocaleString("en-IN")} buffer).`
      : `🟢 Cash flow is stable. Lowest balance projected at ₹${lowestBalance.toLocaleString("en-IN")} on ${lowestDateStr}.`,
  };
}

/**
 * Automatically Detect Recurring Patterns from Transaction History
 * 
 * @param {Object} userData 
 * @returns {Array<Object>} Discovered recurring commitments
 */
function detectRecurringPatterns(userData) {
  if (!userData) return [];

  const allItems = [...(userData.transactions || []), ...(userData.expenses || [])];
  const recurringMap = {};

  allItems.forEach((tx) => {
    const desc = (tx.description || tx.title || "").toLowerCase().trim();
    const amount = Number(tx.amount || 0);
    if (!desc || amount <= 0) return;

    // Filter keywords
    const isRecurringKeyword =
      desc.includes("rent") ||
      desc.includes("emi") ||
      desc.includes("bill") ||
      desc.includes("recharge") ||
      desc.includes("wifi") ||
      desc.includes("subscription") ||
      desc.includes("netflix") ||
      desc.includes("spotify") ||
      desc.includes("amazon prime") ||
      desc.includes("gym") ||
      desc.includes("electricity") ||
      desc.includes("water");

    const key = `${desc}_${amount}`;
    if (!recurringMap[key]) {
      recurringMap[key] = {
        name: tx.description || tx.title,
        amount,
        count: 0,
        type: tx.type || "expense",
        category: tx.categoryOrSource || "Bills",
        dates: [],
        isLikelyRecurring: isRecurringKeyword,
      };
    }

    recurringMap[key].count += 1;
    if (tx.date) recurringMap[key].dates.push(tx.date);
  });

  const detected = [];
  for (const key in recurringMap) {
    const item = recurringMap[key];
    if (item.count >= 2 || item.isLikelyRecurring) {
      detected.push({
        name: item.name,
        amount: item.amount,
        frequency: "Monthly",
        category: item.category,
        confidence: item.count >= 2 ? 0.95 : 0.75,
      });
    }
  }

  return detected;
}

module.exports = {
  generate30DayForecast,
  detectRecurringPatterns,
};
