/**
 * Net Worth Trajectory & Milestone Simulator — OrbitLife Personal CFO
 * Simulates wealth compounding, FD interest returns, and milestone achievement dates.
 */

/**
 * Calculate Net Worth Trajectory and Wealth Milestones
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {number} [customMonthlySavings=null] Optional custom monthly savings rate
 * @returns {Object} Net worth trajectory and milestone timelines
 */
function calculateWealthTrajectory(userData, customMonthlySavings = null) {
  if (!userData) return null;

  const accounts = userData.accounts || [];
  const creditCard = userData.creditCardAccount || {};
  const fds = userData.fdLots || [];
  const borrowLends = userData.borrowLends || [];
  const preferences = userData.financialPreferences || {};

  // 1. Current Live Assets & Liabilities
  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const liquidMoney = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);
  const totalFdPrincipal = fds.reduce((sum, f) => sum + (Number(f.principalAmount || f.amount || 0)), 0);

  let totalReceivables = 0;
  borrowLends.forEach((b) => {
    if (!b.isSettled && (b.type === "lend" || b.type === "lent")) {
      const totalP = Number(b.amount || 0);
      const paid = (b.transactions || []).reduce((s, t) => s + (Number(t.amount) || 0), 0);
      totalReceivables += Math.max(0, totalP - paid);
    }
  });

  const ccDue = Number(creditCard.usedCredit || 0);
  const currentNetWorth = liquidMoney + totalFdPrincipal + totalReceivables - ccDue;

  // 2. Compounding Rate & Monthly Savings
  const monthlySavings = customMonthlySavings !== null
    ? Number(customMonthlySavings)
    : Number(preferences.minimumMonthlySavings || (userData.savingsTarget?.targetAmount) || 6000);

  const fdInterestRate = 0.0825; // 8.25% p.a. compounding quarterly
  const fdCompoundingMultiplier = (months) => Math.pow(1 + fdInterestRate / 4, (4 * (months / 12)));

  // 3. Project Future Net Worth Points
  const projectAt = (months) => {
    const compoundedFd = totalFdPrincipal * fdCompoundingMultiplier(months);
    const accumulatedSavings = monthlySavings * months;
    return Math.round(liquidMoney + compoundedFd + totalReceivables + accumulatedSavings - Math.max(0, ccDue - accumulatedSavings * 0.2));
  };

  const netWorth6Months = projectAt(6);
  const netWorth1Year = projectAt(12);
  const netWorth3Years = projectAt(36);
  const netWorth5Years = projectAt(60);

  // 4. Milestone Timeline Calculations (e.g. ₹50k, ₹1 Lakh, ₹5 Lakhs, ₹10 Lakhs)
  const targets = [50000, 100000, 250000, 500000, 1000000];
  const milestones = [];

  const now = new Date();

  targets.forEach((tgt) => {
    if (tgt <= currentNetWorth) {
      milestones.push({
        targetAmount: tgt,
        title: `₹${(tgt / 1000).toFixed(0)}k Milestone`,
        status: "ACHIEVED_🎉",
        estimatedDate: "Achieved",
        monthsRemaining: 0,
      });
    } else {
      const gap = tgt - currentNetWorth;
      const effectiveMonthlyGrowth = monthlySavings + (totalFdPrincipal * (fdInterestRate / 12));
      const monthsNeeded = Math.max(1, Math.ceil(gap / Math.max(1000, effectiveMonthlyGrowth)));

      const targetDate = new Date(now.getFullYear(), now.getMonth() + monthsNeeded, 1);
      const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      const dateStr = `${monthNames[targetDate.getMonth()]} ${targetDate.getFullYear()}`;

      milestones.push({
        targetAmount: tgt,
        title: `₹${tgt >= 100000 ? `${(tgt / 100000).toFixed(0)} Lakh` : `${(tgt / 1000).toFixed(0)}k`} Milestone`,
        status: "IN_PROGRESS",
        estimatedDate: dateStr,
        monthsRemaining: monthsNeeded,
      });
    }
  });

  return {
    currentNetWorth,
    liquidMoney,
    totalFdPrincipal,
    totalReceivables,
    ccDue,
    monthlySavings,
    projections: {
      in6Months: netWorth6Months,
      in1Year: netWorth1Year,
      in3Years: netWorth3Years,
      in5Years: netWorth5Years,
    },
    milestones,
  };
}

module.exports = {
  calculateWealthTrajectory,
};
