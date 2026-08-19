/**
 * OrbitLife AI Personal CFO Suite — Comprehensive Automated Tests
 */

const assert = require("assert");
const { calculateSafeToSpend, canIAfford, simulateScenario } = require("../services/decision_engine");
const { generate30DayForecast, detectRecurringPatterns } = require("../services/forecasting");
const { generateDailyBriefing, generateWeeklyReview, calculateFinancialHealthScore } = require("../services/insights");
const { evaluateAlerts } = require("../services/alerts");
const { acquireIdempotencyLock } = require("../services/idempotency");

console.log("🧪 Running OrbitLife AI Personal CFO Engine Tests...\n");

// Mock User Financial Data
const mockUserData = {
  accounts: [
    { id: "sbi_1", name: "SBI Savings", openingBalance: 12500 },
    { id: "hdfc_1", name: "HDFC Savings", openingBalance: 3500 },
    { id: "cash_1", name: "Cash in Hand", openingBalance: 1000 },
  ],
  emis: [
    { id: "emi_1", title: "College Loan", monthlyEmi: 3750, remainingMonths: 10, isPaid: false },
  ],
  creditCardAccount: {
    name: "Supermoney Card",
    creditLimit: 26713.8,
    usedCredit: 2920,
    dueDateDay: 15,
  },
  borrowLends: [
    {
      id: "bl_1",
      personName: "Shamveel",
      type: "lent",
      amount: 10000,
      isSettled: false,
      status: "pending",
      transactions: [{ amount: 7500, type: "repayment" }],
    },
  ],
  financialPreferences: {
    salaryDayOfMonth: 1,
    expectedMonthlySalary: 29600,
    emergencyBufferTarget: 2000,
    minimumMonthlySavings: 3000,
    categoryBudgets: {
      food: 5000,
      shopping: 3000,
    },
  },
  fdLots: [
    { id: "fd_1", principalAmount: 29682 },
  ],
  expenses: [
    { id: "e_1", amount: 450, categoryId: "food", date: new Date().toISOString() },
    { id: "e_2", amount: 1200, categoryId: "shopping", date: new Date(Date.now() - 2 * 86400000).toISOString() },
    { id: "e_3", amount: 3750, description: "College Loan EMI", categoryId: "bills", date: new Date(Date.now() - 30 * 86400000).toISOString() },
    { id: "e_4", amount: 3750, description: "College Loan EMI", categoryId: "bills", date: new Date(Date.now() - 60 * 86400000).toISOString() },
  ],
  goals: [
    { id: "g_1", name: "Lakshadweep Trip", targetAmount: 30000, currentAmount: 12000, monthlyContribution: 2500, isCompleted: false },
  ],
};

// 1. Safe-To-Spend Tests
console.log("🔹 1. Testing calculateSafeToSpend...");
const safe = calculateSafeToSpend(mockUserData, new Date("2026-08-19"));
assert.strictEqual(safe.liquidMoney, 17000, "Total Liquid cash should be 17,000");
assert.ok(safe.safeToSpendToday > 0, "Safe to spend today should be > 0");
assert.ok(safe.discretionaryBalance > 0, "Discretionary balance should be positive");
assert.strictEqual(safe.financialRiskLevel, "SAFE", "Risk level should be SAFE");
console.log(`   ✅ Liquid: ₹${safe.liquidMoney}, Safe/Day: ₹${safe.safeToSpendToday}, Discretionary: ₹${safe.discretionaryBalance}`);

// 2. Affordability Tests
console.log("🔹 2. Testing canIAfford...");
// A: Small purchase (Daily allowance)
const aff1 = canIAfford(mockUserData, { amount: 200, itemName: "Lunch" });
assert.strictEqual(aff1.verdict, "RECOMMENDED", "Small purchase should be RECOMMENDED");
console.log(`   ✅ 200 Lunch: ${aff1.verdictTitle}`);

// B: Large purchase exceeding liquid money
const aff2 = canIAfford(mockUserData, { amount: 25000, itemName: "New Laptop" });
assert.strictEqual(aff2.verdict, "NOT_RECOMMENDED", "Purchase exceeding liquid should be NOT_RECOMMENDED");
console.log(`   ✅ 25k Laptop: ${aff2.verdictTitle}`);

// C: Mid purchase consuming discretionary budget
const aff3 = canIAfford(mockUserData, { amount: 2000, itemName: "Shoes" });
assert.ok(aff3.verdict === "PROCEED_WITH_CAUTION" || aff3.verdict === "WAIT_FOR_SALARY", "Mid purchase evaluated properly");
console.log(`   ✅ 2k Shoes: ${aff3.verdictTitle}`);

// 3. What-If Simulation Tests
console.log("🔹 3. Testing simulateScenario...");
const sim = simulateScenario(mockUserData, { type: "SPEND", amount: 5000, name: "Weekend Trip" });
assert.strictEqual(sim.isSimulation, true, "Should be tagged as simulation");
assert.strictEqual(sim.current.liquidMoney, 17000, "Original data untouched");
assert.strictEqual(sim.simulated.liquidMoney, 12000, "Simulated liquid should be reduced by 5000");
console.log(`   ✅ What-If Spend ₹5,000: Diff = ₹${sim.impact.dailyDiff}/day`);

// 3B: Critical Low-Balance Simulation (This Month)
const lowBalanceUserData = {
  ...mockUserData,
  accounts: [{ id: "sbi", name: "SBI Savings", openingBalance: 1663.36 }],
};
const simCritical = simulateScenario(lowBalanceUserData, { type: "SPEND", amount: 1299, name: "Earphones", timing: "CURRENT_MONTH" });
assert.ok(simCritical.recommendation.includes("NOT RECOMMENDED") || simCritical.recommendation.includes("CRITICAL"), "Low balance spend this month must NOT return safe to proceed!");
console.log(`   ✅ Critical Low Balance (This Month): ${simCritical.recommendation}`);

// 3C: Next Month Simulation (User's Exact Scenario — Earphones next month)
const simNextMonth = simulateScenario(lowBalanceUserData, { type: "SPEND", amount: 1299, name: "Bluetooth Earphones", timing: "NEXT_MONTH" });
assert.ok(simNextMonth.recommendation.includes("RECOMMENDED"), "Next month spend with expected salary must be RECOMMENDED!");
assert.ok(simNextMonth.simulated.discretionary > 5000, "Next month discretionary surplus should be > 5,000");
console.log(`   ✅ Next Month Earphones Simulation: ${simNextMonth.recommendation}`);

// 3D: Next Month Can I Afford Test
const affNextMonth = canIAfford(lowBalanceUserData, { amount: 1299, itemName: "Bluetooth Earphones", timing: "NEXT_MONTH" });
assert.strictEqual(affNextMonth.isAffordable, true, "Next month earphones must be affordable");
assert.ok(affNextMonth.verdict.includes("RECOMMENDED"), "Next month verdict must be RECOMMENDED");
console.log(`   ✅ Next Month Can I Afford: ${affNextMonth.verdictTitle} — ${affNextMonth.recommendation}`);

// 4. Cash Flow Forecast Tests
console.log("🔹 4. Testing generate30DayForecast...");
const forecast = generate30DayForecast(mockUserData, new Date("2026-08-19"));
assert.strictEqual(forecast.timeline.length, 31, "Should project 31 days (0 to 30)");
assert.ok(forecast.lowestProjectedBalance > 0, "Lowest projected balance should be positive");
assert.ok(forecast.majorEvents.length > 0, "Should detect salary and EMI events");
console.log(`   ✅ 30-Day Forecast: Lowest = ₹${forecast.lowestProjectedBalance} on ${forecast.lowestBalanceDate}`);

// 5. Recurring Pattern Detection Tests
console.log("🔹 5. Testing detectRecurringPatterns...");
const recurring = detectRecurringPatterns(mockUserData);
assert.ok(recurring.length > 0, "Should detect College Loan EMI recurring pattern");
console.log(`   ✅ Detected recurring: ${recurring.map((r) => r.name).join(", ")}`);

// 6. Daily Briefing Tests
console.log("🔹 6. Testing generateDailyBriefing...");
const brief = generateDailyBriefing(mockUserData);
assert.ok(brief.cfoTip.length > 0, "Should include actionable CFO tip");
assert.strictEqual(brief.liquidMoney, 17000);
console.log(`   ✅ Daily Briefing: Safe Today ₹${brief.safeToSpendToday}, Tip: "${brief.cfoTip}"`);

// 7. Weekly Review Tests
console.log("🔹 7. Testing generateWeeklyReview...");
const review = generateWeeklyReview(mockUserData);
assert.ok(review.thisWeekSpent >= 0);
assert.ok(review.verdict.length > 0);
console.log(`   ✅ Weekly Review: Top Category = ${review.topCategory}, Spent = ₹${review.thisWeekSpent}`);

// 8. Financial Health Score Tests
console.log("🔹 8. Testing calculateFinancialHealthScore...");
const health = calculateFinancialHealthScore(mockUserData);
assert.ok(health.score >= 0 && health.score <= 100, "Health score must be between 0 and 100");
assert.ok(health.pillars.savingsAndNetWorth.score > 0);
assert.ok(health.topImprovement.length > 0);
console.log(`   ✅ Financial Health: ${health.score}/100 (${health.rating}) — Top: "${health.topImprovement}"`);

// 9. Alert Evaluation Tests
console.log("🔹 9. Testing evaluateAlerts...");
const alerts = evaluateAlerts(mockUserData);
assert.ok(Array.isArray(alerts), "Alerts should return an array");
console.log(`   ✅ Evaluated Alerts: ${alerts.length} active alerts found`);

// 10. Idempotency Lock Tests
console.log("🔹 10. Testing acquireIdempotencyLock...");
const lockKey = "msg_test_12345";
const lock1 = acquireIdempotencyLock(lockKey, 5000);
const lock2 = acquireIdempotencyLock(lockKey, 5000);
assert.strictEqual(lock1, true, "First request acquires lock");
assert.strictEqual(lock2, false, "Duplicate request within TTL must be blocked");
console.log(`   ✅ Idempotency Guard successfully blocked duplicate request!`);

// 11. Bank SMS & UPI Auto-Parsing Tests
const { parseBankSms } = require("../services/sms_parser");
console.log("🔹 11. Testing parseBankSms...");
const sms1 = parseBankSms("Dear SBI User, your A/c ending 1234 is debited by Rs.450.00 on 19-AUG-26 at SWIGGY. Avail Bal: Rs 3,420.50");
assert.strictEqual(sms1.isBankSms, true);
assert.strictEqual(sms1.amount, 450);
assert.strictEqual(sms1.account, "SBI");
assert.strictEqual(sms1.category, "Food");
assert.strictEqual(sms1.balanceAfter, 3420.5);
console.log(`   ✅ SMS Auto-Parsed: ₹${sms1.amount} at ${sms1.merchant} (${sms1.account}) — Category: ${sms1.category}`);

// 12. Smart Money Leak & Impulse Detector Tests
const { detectMoneyLeaks } = require("../services/leak_detector");
console.log("🔹 12. Testing detectMoneyLeaks...");
const leaks = detectMoneyLeaks(mockUserData);
assert.ok(leaks.overallLeakScore >= 0);
console.log(`   ✅ Leak Detector: ${leaks.leakCount} leaks found, Status: ${leaks.status}`);

// 13. Net Worth Trajectory & Wealth Milestones Tests
const { calculateWealthTrajectory } = require("../services/wealth_engine");
console.log("🔹 13. Testing calculateWealthTrajectory...");
const wealth = calculateWealthTrajectory(mockUserData);
assert.ok(wealth.currentNetWorth > 0);
assert.ok(wealth.projections.in1Year > wealth.currentNetWorth, "1 Year net worth should compound higher");
assert.strictEqual(wealth.milestones.length, 5, "Should evaluate 5 wealth milestones");
console.log(`   ✅ Wealth Engine: Net Worth ₹${wealth.currentNetWorth} ➔ 1-Yr ₹${wealth.projections.in1Year}, 1-Lakh Target: ${wealth.milestones[1].estimatedDate}`);

// 14. Smart Payment Method Advisor Tests
const { recommendPaymentMethod } = require("../services/payment_advisor");
console.log("🔹 14. Testing recommendPaymentMethod...");
const paymentRec = recommendPaymentMethod(mockUserData, 3500, "Electronics");
assert.ok(paymentRec.recommendedMode.length > 0);
console.log(`   ✅ Payment Advisor: ₹3,500 ➔ ${paymentRec.recommendedMode} (${paymentRec.reason})`);

// 15. Financial Statement & Export Tests
const { generateMonthlyStatement } = require("../services/export_engine");
console.log("🔹 15. Testing generateMonthlyStatement...");
const statement = generateMonthlyStatement(mockUserData, new Date().toISOString().substring(0, 7));
assert.ok(statement.reportText.includes("ORBITLIFE MONTHLY FINANCIAL STATEMENT"));
assert.ok(statement.totalSpent >= 0);
console.log(`   ✅ Export Engine: Generated statement for ${statement.period} (${statement.reportText.length} chars)`);

console.log("\n🎉 ALL 15 ORBITLIFE PERSONAL CFO ADVANCED SUITE TESTS PASSED WITH 100% SUCCESS!\n");
