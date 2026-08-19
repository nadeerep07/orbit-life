/**
 * Financial Decision Engine — OrbitLife Personal CFO
 * Evaluates safe-to-spend, purchase affordability, and what-if financial simulations.
 * Supports both Current Month and Next Month / Future Cycle forecasting.
 */

/**
 * Calculate dynamic Safe-To-Spend with salary cycle awareness
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {Date} [currentDate=new Date()]
 * @param {string} [timing="CURRENT_MONTH"] "CURRENT_MONTH" | "NEXT_MONTH" | "AFTER_SALARY"
 * @param {Object} [customPlan=null] Optional custom breakdown { salary, emis, savings, bills, ccDue }
 * @returns {Object} Safe-To-Spend metrics and risk assessment
 */
function calculateSafeToSpend(userData, currentDate = new Date(), timing = "CURRENT_MONTH", customPlan = null) {
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
      isNextMonth: false,
      breakdown: {},
    };
  }

  const accounts = userData.accounts || [];
  const emis = userData.emis || [];
  const creditCard = userData.creditCardAccount || {};
  const borrowLends = userData.borrowLends || [];
  const preferences = userData.financialPreferences || {};
  const goals = userData.goals || [];

  // 1. Total Current Liquid Cash (Excluding credit card liability pseudo-account)
  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const currentLiquid = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);

  const isNextCycle = timing === "NEXT_MONTH" || timing === "AFTER_SALARY";

  // 2. Cycle Inflows and Starting Base
  const salaryDay = Number(preferences.salaryDayOfMonth || 1);
  const expectedSalary = customPlan?.salary !== undefined
    ? Number(customPlan.salary)
    : Number(preferences.expectedMonthlySalary || 29600);

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
  const currentDaysUntilSalary = Math.max(1, Math.ceil((nextSalaryDate - now) / msPerDay));

  const daysUntilSalary = isNextCycle ? 30 : currentDaysUntilSalary;
  const liquidMoney = isNextCycle
    ? (Math.max(0, currentLiquid) + expectedSalary)
    : currentLiquid;

  // 3. Upcoming Mandatory Commitments
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

  let totalMandatory = 0;
  if (isNextCycle) {
    const plannedEmis = customPlan?.emis !== undefined ? Number(customPlan.emis) : upcomingEmis;
    const plannedBills = customPlan?.bills !== undefined ? Number(customPlan.bills) : 0;
    const plannedCc = customPlan?.ccDue !== undefined ? Number(customPlan.ccDue) : 0;
    totalMandatory = plannedEmis + plannedBills + plannedCc;
  } else {
    totalMandatory = upcomingEmis + creditCardDue + upcomingDebtsPayable;
  }

  // 4. Protected Buffer (Emergency Reserve + Minimum Savings + Goal Allocations)
  const emergencyBuffer = Number(preferences.emergencyBufferTarget || 1500);
  const minimumSavings = customPlan?.savings !== undefined
    ? Number(customPlan.savings)
    : Number(preferences.minimumMonthlySavings || (userData.savingsTarget?.targetAmount) || 3000);

  let goalContributions = 0;
  goals.forEach((g) => {
    if (!g.isCompleted && g.targetAmount && g.targetAmount > (g.currentAmount || 0)) {
      const remaining = g.targetAmount - (g.currentAmount || 0);
      goalContributions += Number(g.monthlyContribution || (remaining / 6) || 0);
    }
  });

  const protectedBuffer = emergencyBuffer + minimumSavings + goalContributions;

  // 5. Discretionary Safe Balance
  const rawDiscretionary = liquidMoney - totalMandatory - protectedBuffer;
  const discretionaryBalance = Math.max(0, rawDiscretionary);

  // 6. Safe Daily and Weekly Allocations
  const safeToSpendToday = Math.floor(discretionaryBalance / daysUntilSalary);
  const safeToSpendThisWeek = Math.min(discretionaryBalance, safeToSpendToday * Math.min(7, daysUntilSalary));
  const safeToSpendUntilSalary = discretionaryBalance;

  // 7. Risk Level Assessment
  let financialRiskLevel = "SAFE";
  if (liquidMoney <= (totalMandatory + emergencyBuffer * 0.5)) {
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
    upcomingCommitments: totalMandatory,
    protectedBuffer,
    financialRiskLevel,
    isNextMonth: isNextCycle,
    breakdown: {
      liquidMoney,
      expectedSalary: isNextCycle ? expectedSalary : 0,
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
 * @param {Object} purchase { amount, itemName, category, paymentMethod, timing, customPlan }
 * @returns {Object} Verdict, score, impact analysis, and actionable advice
 */
function canIAfford(userData, purchase) {
  const amount = Number(purchase.amount || 0);
  const itemName = purchase.itemName || "this item";
  const timing = purchase.timing || "CURRENT_MONTH";
  const customPlan = purchase.customPlan || null;

  const safeMetrics = calculateSafeToSpend(userData, new Date(), timing, customPlan);

  if (amount <= 0) {
    return {
      verdict: "INVALID_AMOUNT",
      verdictEmoji: "⚠️",
      verdictTitle: "Invalid Amount",
      explanation: "Please specify a valid purchase amount greater than ₹0.",
      isAffordable: false,
    };
  }

  const { liquidMoney, safeToSpendToday, safeToSpendThisWeek, discretionaryBalance, daysUntilSalary, breakdown, isNextMonth } = safeMetrics;
  const cycleName = isNextMonth ? "Next Month (Post-Salary)" : "Current Month";

  // Case 1: Insufficient Total Liquid Cash in Target Cycle
  if (amount > liquidMoney) {
    return {
      verdict: "NOT_RECOMMENDED",
      verdictEmoji: "🔴",
      verdictTitle: `NOT RECOMMENDED (${cycleName})`,
      purchaseAmount: amount,
      itemName,
      timing,
      isAffordable: false,
      discretionaryBalance,
      liquidMoney,
      daysUntilSalary,
      shortfall: amount - liquidMoney,
      impact: [
        `Exceeds your ${isNextMonth ? "projected" : "current"} liquid balance of ₹${liquidMoney.toLocaleString("en-IN")}.`,
        `Would require borrowing or increasing credit card debt by ₹${(amount - liquidMoney).toLocaleString("en-IN")}.`,
      ],
      recommendation: `This purchase exceeds your total funds for ${cycleName}. Consider a lower-cost option or saving over multiple months.`,
    };
  }

  // Case 2: Easily Affordable (Within Safe Daily Spend or Healthy Discretionary)
  if (amount <= safeToSpendToday || (isNextMonth && amount <= discretionaryBalance * 0.5)) {
    const newDiscretionary = discretionaryBalance - amount;
    const newDaily = Math.max(0, Math.floor(newDiscretionary / daysUntilSalary));
    return {
      verdict: "RECOMMENDED",
      verdictEmoji: "🟢",
      verdictTitle: `RECOMMENDED (${cycleName})`,
      purchaseAmount: amount,
      itemName,
      timing,
      isAffordable: true,
      discretionaryBalance,
      safeToSpendToday,
      daysUntilSalary,
      impact: [
        isNextMonth
          ? `Your next month's salary (₹${breakdown.expectedSalary.toLocaleString("en-IN")}) covers this spend easily.`
          : `Fits comfortably within today's safe allowance (₹${safeToSpendToday.toLocaleString("en-IN")}).`,
        `Your protected savings (₹${breakdown.minimumSavings.toLocaleString("en-IN")}) and emergency buffer (₹${breakdown.emergencyBuffer.toLocaleString("en-IN")}) remain 100% intact.`,
        `Remaining discretionary budget: ₹${newDiscretionary.toLocaleString("en-IN")} (safe daily spend: ₹${newDaily.toLocaleString("en-IN")}/day).`,
      ],
      recommendation: isNextMonth
        ? `Buying ${itemName} in next month's budget is 100% safe and recommended!`
        : `You can proceed with this purchase without compromising upcoming obligations.`,
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
      verdictTitle: `PROCEED WITH CAUTION (${cycleName})`,
      purchaseAmount: amount,
      itemName,
      timing,
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

  // Case 4: Breaches Protected Buffer / Commitments
  const deficit = amount - discretionaryBalance;
  return {
    verdict: "WAIT_FOR_SALARY",
    verdictEmoji: "🟠",
    verdictTitle: `NOT RECOMMENDED (${cycleName})`,
    purchaseAmount: amount,
    itemName,
    timing,
    isAffordable: false,
    discretionaryBalance,
    deficit,
    daysUntilSalary,
    impact: [
      `Exceeds discretionary buffer by ₹${deficit.toLocaleString("en-IN")}.`,
      `Would cut directly into your emergency reserve (₹${breakdown.emergencyBuffer.toLocaleString("en-IN")}) or upcoming commitments (₹${breakdown.upcomingEmis.toLocaleString("en-IN")}).`,
      `Safe-to-spend for the next ${daysUntilSalary} days would drop to ₹0.`,
    ],
    recommendation: isNextMonth
      ? `Even with next month's salary, this purchase cuts into your ₹${breakdown.minimumSavings.toLocaleString("en-IN")} savings target.`
      : `Hold off on purchasing ${itemName}. Wait ${daysUntilSalary} days until your salary arrives on ${breakdown.nextSalaryDate}.`,
  };
}

/**
 * What-If Financial Scenario Simulator (Pure In-Memory Sandbox)
 * Does NOT mutate Firestore or any real account records.
 * 
 * @param {Object} userData 
 * @param {Object} scenario { type: 'SPEND' | 'SALARY_CHANGE' | 'NEW_EMI' | 'SAVE_GOAL', amount, tenure, name, timing, customPlan }
 * @returns {Object} Simulation analysis and comparison
 */
function simulateScenario(userData, scenario) {
  const timing = scenario.timing || "CURRENT_MONTH";
  const customPlan = scenario.customPlan || null;
  const isNextCycle = timing === "NEXT_MONTH" || timing === "AFTER_SALARY";

  const currentSafe = calculateSafeToSpend(userData, new Date(), timing, customPlan);
  const type = (scenario.type || "SPEND").toUpperCase();
  const amount = Number(scenario.amount || 0);

  let simulatedSafe;
  let summaryText = "";

  if (type === "SPEND") {
    const clonedUser = JSON.parse(JSON.stringify(userData));
    if (isNextCycle) {
      // In next cycle, salary is credited and planned commitments are deducted
      simulatedSafe = calculateSafeToSpend(clonedUser, new Date(), "NEXT_MONTH", customPlan);
      // Reduce the discretionary surplus by the simulated spend amount
      const newDiscretionary = Math.max(0, simulatedSafe.discretionaryBalance - amount);
      simulatedSafe.discretionaryBalance = newDiscretionary;
      simulatedSafe.safeToSpendToday = Math.floor(newDiscretionary / 30);
      simulatedSafe.liquidMoney = Math.max(0, simulatedSafe.liquidMoney - amount);
      summaryText = `Simulating a spend of ₹${amount.toLocaleString("en-IN")} in Next Month's budget (post-salary)`;
    } else {
      if (clonedUser.accounts && clonedUser.accounts.length > 0) {
        clonedUser.accounts[0].openingBalance = (Number(clonedUser.accounts[0].openingBalance) || 0) - amount;
      }
      simulatedSafe = calculateSafeToSpend(clonedUser, new Date(), "CURRENT_MONTH");
      summaryText = `Simulating a one-time spend of ₹${amount.toLocaleString("en-IN")} in Current Month`;
    }
  } else if (type === "SALARY_CHANGE") {
    const clonedUser = JSON.parse(JSON.stringify(userData));
    if (!clonedUser.financialPreferences) clonedUser.financialPreferences = {};
    clonedUser.financialPreferences.expectedMonthlySalary = amount;
    simulatedSafe = calculateSafeToSpend(clonedUser, new Date(), timing);
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
    simulatedSafe = calculateSafeToSpend(clonedUser, new Date(), timing);
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
    if (isNextCycle) {
      if (simulatedSafe.discretionaryBalance > 3000) {
        recommendation = `🟢 100% RECOMMENDED FOR NEXT MONTH: Your next month's salary (₹${currentSafe.breakdown.expectedSalary.toLocaleString("en-IN")}) easily covers your ₹${currentSafe.breakdown.minimumSavings.toLocaleString("en-IN")} savings target and commitments, leaving ₹${simulatedSafe.discretionaryBalance.toLocaleString("en-IN")} free discretionary cash. Buying ${scenario.name || "this"} for ₹${amount.toLocaleString("en-IN")} is completely safe!`;
      } else if (simulatedSafe.discretionaryBalance > 0) {
        recommendation = `🟡 PROCEED WITH CAUTION: In next month's budget, this leaves ₹${simulatedSafe.discretionaryBalance.toLocaleString("en-IN")} free discretionary cash (~₹${simulatedSafe.safeToSpendToday.toLocaleString("en-IN")}/day).`;
      } else {
        recommendation = `🔴 NOT RECOMMENDED: Even with next month's salary, this spend exceeds your planned commitments and ₹${currentSafe.breakdown.minimumSavings.toLocaleString("en-IN")} savings goal.`;
      }
    } else {
      if (simulatedSafe.liquidMoney <= 0) {
        recommendation = `🔴 CRITICAL: This spend completely exhausts your current liquid cash (leaves ₹${simulatedSafe.liquidMoney.toLocaleString("en-IN")}). Strictly not recommended for this month.`;
      } else if (simulatedSafe.financialRiskLevel === "CRITICAL" || simulatedSafe.financialRiskLevel === "TIGHT") {
        recommendation = `🔴 NOT RECOMMENDED FOR THIS MONTH: Your current finances are in a ${simulatedSafe.financialRiskLevel} state. Spending ₹${amount.toLocaleString("en-IN")} leaves only ₹${simulatedSafe.liquidMoney.toLocaleString("en-IN")} liquid cash before salary day. Wait for next month's salary.`;
      } else if (simulatedSafe.safeToSpendToday <= 0) {
        recommendation = `🟠 NOT RECOMMENDED: Exhausts your current discretionary budget (safe daily spend drops to ₹0/day). Wait until next month's salary.`;
      } else {
        recommendation = `🟢 Manageable impact: Safe daily allowance adjusts from ₹${currentSafe.safeToSpendToday.toLocaleString("en-IN")} to ₹${simulatedSafe.safeToSpendToday.toLocaleString("en-IN")}/day.`;
      }
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
    timing,
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
