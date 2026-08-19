/**
 * Smart Money Leak & Impulse Spending Detector — OrbitLife Personal CFO
 * Identifies micro-spending drains, food delivery spikes, and weekend spending surges.
 */

/**
 * Analyze transactions and detect financial leaks
 * 
 * @param {Object} userData Complete user profile from Firestore
 * @returns {Object} Detected leaks, severity, and actionable micro-budget recommendations
 */
function detectMoneyLeaks(userData) {
  if (!userData) return { leaks: [], overallLeakScore: 0, recommendations: [] };

  const expenses = userData.expenses || [];
  const now = new Date();
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  const leaks = [];
  const recommendations = [];

  // Filter last 7 days and last 30 days expenses
  const weekExpenses = expenses.filter((e) => {
    const d = e.date ? new Date(e.date) : null;
    return d && d >= sevenDaysAgo && d <= now && (Number(e.amount) || 0) > 0;
  });

  const monthExpenses = expenses.filter((e) => {
    const d = e.date ? new Date(e.date) : null;
    return d && d >= thirtyDaysAgo && d <= now && (Number(e.amount) || 0) > 0;
  });

  // 1. Food Delivery & Dining Out Leak
  const foodKeywords = ["swiggy", "zomato", "kfc", "mcdonald", "burger", "pizza", "cafe", "restaurant", "dining", "snack"];
  const weekFoodDeliveries = weekExpenses.filter((e) => {
    const desc = (e.description || e.title || "").toLowerCase();
    const cat = (e.categoryId || "").toLowerCase();
    return foodKeywords.some((k) => desc.includes(k)) || cat.includes("dining") || cat.includes("food delivery");
  });

  const weekFoodCount = weekFoodDeliveries.length;
  const weekFoodSpent = weekFoodDeliveries.reduce((sum, e) => sum + Number(e.amount || 0), 0);

  if (weekFoodCount >= 4 || weekFoodSpent >= 1500) {
    leaks.push({
      type: "FOOD_DELIVERY_SPIKE",
      title: "🍔 Food Delivery & Dining Surge",
      severity: weekFoodSpent >= 2500 ? "HIGH" : "MEDIUM",
      detail: `You made ${weekFoodCount} food delivery/dining orders totaling ₹${weekFoodSpent.toLocaleString("en-IN")} in the last 7 days.`,
      actionPrompt: `Set a ₹1,000 weekly dining cap to save ~₹${(weekFoodSpent - 1000).toLocaleString("en-IN")}/week.`,
    });
    recommendations.push(`Set a weekly food delivery cap of ₹1,000.`);
  }

  // 2. Frequent Micro-Transactions Drain (< ₹150)
  const microSpends = weekExpenses.filter((e) => Number(e.amount || 0) > 0 && Number(e.amount || 0) <= 150);
  const microTotal = microSpends.reduce((sum, e) => sum + Number(e.amount || 0), 0);

  if (microSpends.length >= 6) {
    leaks.push({
      type: "MICRO_SPENDING_DRAIN",
      title: "☕ Micro-Transaction Drain (Small UPI Spends)",
      severity: "MEDIUM",
      detail: `${microSpends.length} small transactions (under ₹150) added up to ₹${microTotal.toLocaleString("en-IN")} this week.`,
      actionPrompt: "Small daily UPI taps add up quickly. Batch small purchases or track them with a daily cash wallet.",
    });
    recommendations.push(`Be mindful of frequent small UPI taps under ₹150.`);
  }

  // 3. Weekend Spending Velocity Check
  let weekendSpent = 0;
  let weekdaySpent = 0;
  let weekendDays = 0;
  let weekdayDays = 0;

  weekExpenses.forEach((e) => {
    const d = new Date(e.date);
    const day = d.getDay(); // 0 = Sun, 6 = Sat
    if (day === 0 || day === 6) {
      weekendSpent += Number(e.amount || 0);
      weekendDays++;
    } else {
      weekdaySpent += Number(e.amount || 0);
      weekdayDays++;
    }
  });

  const avgWeekendDaily = weekendDays > 0 ? weekendSpent / 2 : 0;
  const avgWeekdayDaily = weekdayDays > 0 ? weekdaySpent / 5 : 0;

  if (avgWeekdayDaily > 0 && avgWeekendDaily >= avgWeekdayDaily * 1.6 && weekendSpent > 1000) {
    leaks.push({
      type: "WEEKEND_SURGE",
      title: "🎉 Weekend Spending Surge",
      severity: "MEDIUM",
      detail: `Your weekend daily spending (avg ₹${Math.round(avgWeekendDaily).toLocaleString("en-IN")}/day) is 60%+ higher than your weekday average.`,
      actionPrompt: "Plan your weekend entertainment budget in advance before Friday night.",
    });
  }

  // Overall Financial Leak Score (0 = No leaks, 100 = Severe leaks)
  const leakScore = leaks.length === 0 ? 0 : leaks.length === 1 ? 30 : leaks.length === 2 ? 65 : 90;

  return {
    leaks,
    leakCount: leaks.length,
    overallLeakScore: leakScore,
    status: leakScore === 0 ? "EXCELLENT" : leakScore <= 40 ? "MODERATE" : "HIGH_LEAKAGE",
    recommendations,
  };
}

module.exports = {
  detectMoneyLeaks,
};
