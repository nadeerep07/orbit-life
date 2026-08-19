/**
 * Smart Payment Method Advisor — OrbitLife Personal CFO
 * Evaluates whether to pay via UPI / Bank, Supermoney Credit Card, or Cash.
 */

/**
 * Recommend the smartest payment method for a transaction
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @param {number} amount Purchase amount
 * @param {string} [merchant=""] Merchant or category
 * @returns {Object} Recommended payment mode and explanation
 */
function recommendPaymentMethod(userData, amount, merchant = "") {
  const numAmount = Number(amount || 0);
  if (!userData || numAmount <= 0) {
    return {
      recommendedMode: "UPI",
      emoji: "📱",
      reason: "Standard UPI / Bank payment.",
    };
  }

  const accounts = userData.accounts || [];
  const creditCard = userData.creditCardAccount || {};

  const liquidAccounts = accounts.filter(
    (a) => a.id !== "supermoney" && a.id !== "credit_card" && (a.name || "").toLowerCase() !== "credit card"
  );
  const liquidMoney = liquidAccounts.reduce((sum, a) => sum + (Number(a.openingBalance) || 0), 0);

  const ccLimit = Number(creditCard.creditLimit || 26713.8);
  const ccUsed = Number(creditCard.usedCredit || 0);
  const ccAvailable = Number(creditCard.availableCredit || (ccLimit - ccUsed));
  const statementDay = Number(creditCard.statementDateDay || 1);
  const dueDay = Number(creditCard.dueDateDay || 15);

  const now = new Date();
  const currentDay = now.getDate();

  // 1. If purchase exceeds available credit, must use Bank/UPI
  if (numAmount > ccAvailable) {
    return {
      recommendedMode: "UPI / Bank Transfer",
      emoji: "📱",
      reason: `Purchase (₹${numAmount.toLocaleString("en-IN")}) exceeds your available credit card limit (₹${ccAvailable.toLocaleString("en-IN")}). Pay directly from your bank.`,
      utilizationImpact: "No impact on credit score.",
    };
  }

  // 2. Check Credit Utilization impact
  const resultingUsed = ccUsed + numAmount;
  const resultingUtilPct = Math.round((resultingUsed / ccLimit) * 100);

  // If purchase is just small tea/snacks under ₹100, recommend UPI/Cash
  if (numAmount <= 100) {
    return {
      recommendedMode: "UPI / Cash",
      emoji: "💵",
      reason: `Small daily transaction (₹${numAmount.toLocaleString("en-IN")}). Best paid via UPI or Cash to avoid small card dues.`,
      utilizationImpact: "Zero credit card overhead.",
    };
  }

  // 3. Billing Cycle Advantage Calculation
  // If we are just after statement date, card gives maximum interest-free days (30 to 45 days)
  let interestFreeDays = 30;
  if (currentDay > statementDay) {
    interestFreeDays = (30 - currentDay) + dueDay;
  } else {
    interestFreeDays = (statementDay - currentDay) + 15;
  }

  // 4. Recommendation Decision
  if (resultingUtilPct <= 30) {
    return {
      recommendedMode: "💳 Supermoney Card",
      emoji: "💳",
      reason: `Swiping your credit card gives you ~${interestFreeDays} days of interest-free credit while keeping your bank cash liquid.`,
      utilizationImpact: `Utilization remains healthy at ${resultingUtilPct}% (< 30% optimal).`,
      tip: `Ensure statement is paid before Day ${dueDay} to avoid interest.`,
    };
  } else if (liquidMoney >= numAmount && resultingUtilPct > 50) {
    return {
      recommendedMode: "📱 UPI / Direct Bank (SBI)",
      emoji: "📱",
      reason: `Swiping would push credit card utilization to ${resultingUtilPct}% (which can negatively impact your credit score). Pay via UPI to keep credit utilization low.`,
      utilizationImpact: `Keeps credit card utilization healthy at ${Math.round((ccUsed / ccLimit) * 100)}%.`,
    };
  } else {
    return {
      recommendedMode: "💳 Supermoney Card (with Planned Payoff)",
      emoji: "💳",
      reason: `Pay via Supermoney Card to preserve liquid cash until salary day, and pay down the bill on salary day.`,
      utilizationImpact: `Will temporarily raise utilization to ${resultingUtilPct}%.`,
    };
  }
}

module.exports = {
  recommendPaymentMethod,
};
