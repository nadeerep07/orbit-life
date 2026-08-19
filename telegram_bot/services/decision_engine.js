/**
 * Financial Decision Engine — OrbitLife Personal CFO
 * Evaluates safe-to-spend, purchase affordability, and what-if financial simulations.
 */

/**
 * Calculate dynamic Safe-To-Spend with salary cycle awareness
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {Date} [currentDate=new Date()]
 * @returns {Object} Safe-To-Spend metrics and risk assessment
 */
function calculateSafeToSpend(userData, currentDate = new Date()) {
  if (!userData) {
    return {
      liquidMoney: 0,
      safeToSpendToday: 0,
      safeToSpendThisWeek: 0,
      safeToSpendUntilSalary: 0,
      discretionaryBalance: 0,
      daysUntilSalary: 1,
      upcomingCommitments: 0,
      protectedBuffer: 0,
      financialRiskLevel: "CRITICAL",
      breakdown: {},
    };
  }

  const accounts = userData.accounts || [];
  const emis = userData.emis || [];
  const creditCard = userData.creditCardAccount || {};
  const borrowLends = userData.borrowLends || [];
  const preferences = userData.financialPreferences || {};
  const goals = userData.goals || [];

  // 1. Total Liquid Cash (Excluding credit card liability pseudo-account)
  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const liquidMoney = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);

  // 2. Days Until Next Salary
  const salaryDay = Number(preferences.salaryDayOfMonth || 1);
  const now = new Date(currentDate);
  const currentDay = now.getDate();
  const currentMonth = now.getMonth();
  const currentYear = now.getFullYear();

  let nextSalaryDate;
  if (currentDay < salaryDay) {
    nextSalaryDate = new Date(currentYear, currentMonth, salaryDay);
  } else {
    nextSalaryDate = new Date(currentYear, currentMonth + 1, salaryDay);
  }
  const msPerDay = 1000 * 60 * 60 * 24;
  const daysUntilSalary = Math.max(1, Math.ceil((nextSalaryDate - now) / msPerDay));

  // 3. Upcoming Mandatory Commitments before next salary
  let upcomingEmis = 0;
  emis.forEach((e) => {
    if (!e.isPaid && (e.remainingMonths === undefined || Number(e.remainingMonths) > 0)) {
      upcomingEmis += Number(e.monthlyEmi || 0);
    }
  });

  const creditCardDue = Number(creditCard.usedCredit || 0);

  let upcomingDebtsPayable = 0;
  borrowLends.forEach((b) => {
    if (!b.isSettled && b.status !== "settled" && b.status !== "completed") {
      if (b.type === "borrow" || b.type === "borrowed") {
        const totalP = Number(b.amount || 0);
        const paid = (b.transactions || []).reduce((s, t) => s + (Number(t.amount) || 0), 0);
        upcomingDebtsPayable += Math.max(0, totalP - paid);
      }
    }
  });

  const upcomingCommitments = upcomingEmis + creditCardDue + upcomingDebtsPayable;

  // 4. Protected Buffer (Emergency Reserve + Minimum Savings + Goal Allocations)
  const emergencyBuffer = Number(preferences.emergencyBufferTarget || 1500);
  const minimumSavings = Number(preferences.minimumMonthlySavings || (userData.savingsTarget?.targetAmount) || 2000);
  
  // Monthly goal contributions
  let goalContributions = 0;
  goals.forEach((g) => {
    if (!g.isCompleted && g.targetAmount && g.targetAmount > (g.currentAmount || 0)) {
      const remaining = g.targetAmount - (g.currentAmount || 0);
      goalContributions += Number(g.monthlyContribution || (remaining / 6) || 0);
    }
  });

  const protectedBuffer = emergencyBuffer + minimumSavings + goalContributions;

  // 5. Discretionary Safe Balance
  const rawDiscretionary = liquidMoney - upcomingCommitments - protectedBuffer;
  const discretionaryBalance = Math.max(0, rawDiscretionary);

  // 6. Safe Daily and Weekly Allocations
  const safeToSpendToday = Math.floor(discretionaryBalance / daysUntilSalary);
  const safeToSpendThisWeek = Math.min(discretionaryBalance, safeToSpendToday * Math.min(7, daysUntilSalary));
  const safeToSpendUntilSalary = discretionaryBalance;

  // 7. Risk Level Assessment
  let financialRiskLevel = "SAFE";
  if (liquidMoney <= (upcomingCommitments + emergencyBuffer * 0.5)) {
    financialRiskLevel = "CRITICAL";
  } else if (rawDiscretionary < 0) {
    financialRiskLevel = "TIGHT";
  } else if (safeToSpendToday < 200) {
    financialRiskLevel = "MODERATE";
  } else {
    financialRiskLevel = "SAFE";
  }

  return {
    liquidMoney,
    safeToSpendToday,
    safeToSpendThisWeek,
    safeToSpendUntilSalary,
    discretionaryBalance,
    daysUntilSalary,
    upcomingCommitments,
    protectedBuffer,
    financialRiskLevel,
    breakdown: {
      liquidMoney,
      upcomingEmis,
      creditCardDue,
      upcomingDebtsPayable,
      emergencyBuffer,
      minimumSavings,
      goalContributions,
      salaryDay,
      nextSalaryDate: nextSalaryDate.toISOString().split("T")[0],
    },
  };
}

/**
 * 'Can I Afford This?' — Multi-Factor Financial Purchase Analysis
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {Object} purchase { amount, itemName, category, paymentMethod }
 * @returns {Object} Verdict, score, impact analysis, and actionable advice
 */
function canIAfford(userData, purchase) {
  const amount = Number(purchase.amount || 0);
  const itemName = purchase.itemName || "this item";
  const safeMetrics = calculateSafeToSpend(userData);

  if (amount <= 0) {
    return {
      verdict: "INVALID_AMOUNT",
      verdictEmoji: "⚠️",
      verdictTitle: "Invalid Amount",
      explanation: "Please specify a valid purchase amount greater than ₹0.",
      isAffordable: false,
    };
  }

  const { liquidMoney, safeToSpendToday, safeToSpendThisWeek, discretionaryBalance, daysUntilSalary, breakdown } = safeMetrics;

  // Case 1: Insufficient Total Liquid Cash
  if (amount > liquidMoney) {
    return {
      verdict: "NOT_RECOMMENDED",
      verdictEmoji: "🔴",
      verdictTitle: "NOT RECOMMENDED (Insufficient Funds)",
      purchaseAmount: amount,
      itemName,
      isAffordable: false,
      discretionaryBalance,
      liquidMoney,
      daysUntilSalary,
      shortfall: amount - liquidMoney,
      impact: [
        `Exceeds your total liquid balance of ₹${liquidMoney.toLocaleString("en-IN")}.`,
        `Would require borrowing or increasing credit card debt by ₹${(amount - liquidMoney).toLocaleString("en-IN")}.`,
      ],
      recommendation: `Wait until your next salary in ${daysUntilSalary} days before considering this purchase.`,
    };
  }

  // Case 2: Easily Affordable (Within Daily or 3-Day Safe Spend)
  if (amount <= safeToSpendToday) {
    const newDaily = Math.max(0, Math.floor((discretionaryBalance - amount) / daysUntilSalary));
    return {
      verdict: "RECOMMENDED",
      verdictEmoji: "🟢",
      verdictTitle: "RECOMMENDED (Safely Affordable)",
      purchaseAmount: amount,
      itemName,
      isAffordable: true,
      discretionaryBalance,
      safeToSpendToday,
      daysUntilSalary,
      impact: [
        `Fits comfortably within today's safe allowance (₹${safeToSpendToday.toLocaleString("en-IN")}).`,
        `Your protected savings (₹${breakdown.minimumSavings.toLocaleString("en-IN")}) and emergency buffer remain untouched.`,
        `New safe daily allowance will be ₹${newDaily.toLocaleString("en-IN")}.`,
      ],
      recommendation: `You can proceed with this purchase without compromising upcoming obligations.`,
    };
  }

  // Case 3: Within Total Discretionary Allowance, but consumes multiple days
  if (amount <= discretionaryBalance) {
    const daysConsumed = Math.ceil(amount / Math.max(1, safeToSpendToday));
    const newDiscretionary = discretionaryBalance - amount;
    const newDaily = Math.floor(newDiscretionary / daysUntilSalary);

    return {
      verdict: "PROCEED_WITH_CAUTION",
      verdictEmoji: "🟡",
      verdictTitle: "PROCEED WITH CAUTION",
      purchaseAmount: amount,
      itemName,
      isAffordable: true,
      discretionaryBalance,
      daysUntilSalary,
      daysConsumed,
      newDaily,
      impact: [
        `Consumes ₹${amount.toLocaleString("en-IN")} of your remaining ₹${discretionaryBalance.toLocaleString("en-IN")} discretionary budget.`,
        `Equates to roughly ${daysConsumed} days of your daily spending allowance.`,
        `Safe daily spend for the remaining ${daysUntilSalary} days will reduce to ₹${newDaily.toLocaleString("en-IN")}/day.`,
      ],
      recommendation: `Affordable, but keep discretionary spending minimal for the next ${daysConsumed} days to stay on track.`,
    };
  }

  // Case 4: Breaches Protected Buffer / Upcoming Commitments
  const deficit = amount - discretionaryBalance;
  return {
    verdict: "WAIT_FOR_SALARY",
    verdictEmoji: "🟠",
    verdictTitle: "NOT RECOMMENDED (Breaches Protected Savings)",
    purchaseAmount: amount,
    itemName,
    isAffordable: false,
    discretionaryBalance,
    deficit,
    daysUntilSalary,
    impact: [
      `Exceeds discretionary buffer by ₹${deficit.toLocaleString("en-IN")}.`,
      `Would cut directly into your emergency reserve (₹${breakdown.emergencyBuffer.toLocaleString("en-IN")}) or upcoming EMI commitments (₹${breakdown.upcomingEmis.toLocaleString("en-IN")}).`,
      `Safe-to-spend for the next ${daysUntilSalary} days would drop to ₹0.`,
    ],
    recommendation: `Hold off on purchasing ${itemName}. Wait ${daysUntilSalary} days until your salary arrives on ${breakdown.nextSalaryDate}.`,
  };
}

/**
 * What-If Financial Scenario Simulator (Pure In-Memory Sandbox)
 * Does NOT mutate Firestore or any real account records.
 * 
 * @param {Object} userData 
 * @param {Object} scenario { type: 'SPEND' | 'SALARY_CHANGE' | 'NEW_EMI' | 'SAVE_GOAL', amount, tenure, name }
 * @returns {Object} Simulation analysis and comparison
 */
function simulateScenario(userData, scenario) {
  const currentSafe = calculateSafeToSpend(userData);
  const type = (scenario.type || "SPEND").toUpperCase();
  const amount = Number(scenario.amount || 0);

  let simulatedSafe;
  let summaryText = "";

  if (type === "SPEND") {
    // Clone and deduct amount from first available liquid account
    const clonedUser = JSON.parse(JSON.stringify(userData));
    if (clonedUser.accounts && clonedUser.accounts.length > 0) {
      clonedUser.accounts[0].openingBalance = (Number(clonedUser.accounts[0].openingBalance) || 0) - amount;
    }
    simulatedSafe = calculateSafeToSpend(clonedUser);
    summaryText = `Simulating a one-time spend of ₹${amount.toLocaleString("en-IN")}`;
  } else if (type === "SALARY_CHANGE") {
    const clonedUser = JSON.parse(JSON.stringify(userData));
    if (!clonedUser.financialPreferences) clonedUser.financialPreferences = {};
    clonedUser.financialPreferences.expectedMonthlySalary = amount;
    simulatedSafe = calculateSafeToSpend(clonedUser);
    summaryText = `Simulating monthly salary changing to ₹${amount.toLocaleString("en-IN")}`;
  } else if (type === "NEW_EMI") {
    const clonedUser = JSON.parse(JSON.stringify(userData));
    const monthlyEmi = Number(scenario.monthlyEmi || (amount / (scenario.tenure || 12)));
    if (!clonedUser.emis) clonedUser.emis = [];
    clonedUser.emis.push({
      title: scenario.name || "New EMI",
      monthlyEmi: monthlyEmi,
      remainingMonths: scenario.tenure || 12,
      totalAmount: amount,
      isPaid: false,
    });
    simulatedSafe = calculateSafeToSpend(clonedUser);
    summaryText = `Simulating a new EMI of ₹${monthlyEmi.toLocaleString("en-IN")}/mo for ${scenario.tenure || 12} months`;
  } else {
    simulatedSafe = currentSafe;
    summaryText = `Simulation of ${scenario.name || "scenario"}`;
  }

  const dailyDiff = simulatedSafe.safeToSpendToday - currentSafe.safeToSpendToday;
  const discretionaryDiff = simulatedSafe.discretionaryBalance - currentSafe.discretionaryBalance;

  // Intelligent, risk-aware CFO recommendation
  let recommendation = "";
  if (type === "SPEND") {
    if (simulatedSafe.liquidMoney <= 0) {
      recommendation = `🔴 CRITICAL: This spend completely exhausts your liquid cash (leaves ₹${simulatedSafe.liquidMoney.toLocaleString("en-IN")}). Strictly not recommended.`;
    } else if (simulatedSafe.financialRiskLevel === "CRITICAL" || simulatedSafe.financialRiskLevel === "TIGHT") {
      recommendation = `🔴 NOT RECOMMENDED: Your finances are in a ${simulatedSafe.financialRiskLevel} state. Spending ₹${amount.toLocaleString("en-IN")} leaves only ₹${simulatedSafe.liquidMoney.toLocaleString("en-IN")} liquid cash before salary day.`;
    } else if (simulatedSafe.safeToSpendToday <= 0) {
      recommendation = `🟠 NOT RECOMMENDED: Exhausts your discretionary budget (safe daily spend drops to ₹0/day). Wait until salary day.`;
    } else {
      recommendation = `🟢 Manageable impact: Safe daily allowance adjusts from ₹${currentSafe.safeToSpendToday.toLocaleString("en-IN")} to ₹${simulatedSafe.safeToSpendToday.toLocaleString("en-IN")}/day.`;
    }
  } else if (type === "NEW_EMI") {
    if (simulatedSafe.financialRiskLevel === "CRITICAL" || simulatedSafe.financialRiskLevel === "TIGHT") {
      recommendation = `🔴 NOT RECOMMENDED: Adding this recurring EMI severely tightens your cash flow into a ${simulatedSafe.financialRiskLevel} state.`;
    } else {
      recommendation = `🟡 Manageable EMI: Safe daily allowance adjusts to ₹${simulatedSafe.safeToSpendToday.toLocaleString("en-IN")}/day.`;
    }
  } else if (type === "SALARY_CHANGE") {
    if (dailyDiff > 0) {
      recommendation = `🟢 Positive financial impact: Increases safe daily allowance by +₹${dailyDiff.toLocaleString("en-IN")}/day.`;
    } else {
      recommendation = `🟠 Reduces safe daily allowance by -₹${Math.abs(dailyDiff).toLocaleString("en-IN")}/day.`;
    }
  } else {
    recommendation = simulatedSafe.financialRiskLevel === "CRITICAL" || simulatedSafe.financialRiskLevel === "TIGHT"
      ? `🔴 NOT RECOMMENDED: Scenario puts finances in a ${simulatedSafe.financialRiskLevel} state.`
      : `🟢 Safe scenario: Financial risk level remains ${simulatedSafe.financialRiskLevel}.`;
  }

  return {
    isSimulation: true,
    scenarioType: type,
    summaryText,
    current: {
      liquidMoney: currentSafe.liquidMoney,
      safeDaily: currentSafe.safeToSpendToday,
      discretionary: currentSafe.discretionaryBalance,
      risk: currentSafe.financialRiskLevel,
    },
    simulated: {
      liquidMoney: simulatedSafe.liquidMoney,
      safeDaily: simulatedSafe.safeToSpendToday,
      discretionary: simulatedSafe.discretionaryBalance,
      risk: simulatedSafe.financialRiskLevel,
    },
    impact: {
      dailyDiff,
      discretionaryDiff,
      riskChange: `${currentSafe.financialRiskLevel} ➔ ${simulatedSafe.financialRiskLevel}`,
    },
    recommendation,
  };
}

module.exports = {
  calculateSafeToSpend,
  canIAfford,
  simulateScenario,
};
