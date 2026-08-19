/**
 * Automated Proactive Scheduler — OrbitLife Personal CFO
 * Manages Morning 8:00 AM Briefings, Evening 9:30 PM Wrap-ups, and 3-Day Bill Due Alerts.
 */

const { getDb, getUserData } = require("./firebase");
const { generateDailyBriefing } = require("./insights");
const { calculateSafeToSpend } = require("./decision_engine");
const { evaluateAlerts } = require("./alerts");

/**
 * Generate Morning 8:00 AM Briefing Message
 * 
 * @param {string} userId 
 * @returns {Promise<string>} Formatted morning brief markdown
 */
async function getMorningDigest(userId) {
  const userData = await getUserData(userId);
  if (!userData) return null;

  const brief = generateDailyBriefing(userData);

  return (
    `🌅 *Good Morning! Orbit Daily Briefing*\n\n` +
    `💰 *Liquid Cash:* ₹${brief.liquidMoney.toLocaleString("en-IN")}\n` +
    `💸 *Safe to Spend Today:* *₹${brief.safeToSpendToday.toLocaleString("en-IN")}*\n` +
    `📅 *Salary In:* ${brief.daysUntilSalary} days\n` +
    `📌 *Next Bill:* ${brief.nextBill}\n\n` +
    `💳 *Card Utilization:* ${brief.creditCard.utilPercent}%\n` +
    `🎯 *Top Goal:* ${brief.goalProgress}\n\n` +
    `🧠 *Orbit's Tip for Today:*\n_${brief.cfoTip}_`
  );
}

/**
 * Generate Evening 9:30 PM Wrap-up Message
 * 
 * @param {string} userId 
 * @returns {Promise<string>} Formatted evening wrap-up markdown
 */
async function getEveningWrapUp(userId) {
  const userData = await getUserData(userId);
  if (!userData) return null;

  const safe = calculateSafeToSpend(userData);
  const expenses = userData.expenses || [];
  const todayStr = new Date().toISOString().split("T")[0];

  const todayExpenses = expenses.filter((e) => e.date && e.date.startsWith(todayStr));
  const todaySpent = todayExpenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);

  const safeDaily = safe.safeToSpendToday;
  const savedDifference = safeDaily - todaySpent;

  let performanceEmoji = "🟢";
  let performanceSummary = "";

  if (savedDifference >= 0) {
    performanceEmoji = "🟢";
    performanceSummary = `Great discipline! You spent ₹${todaySpent.toLocaleString("en-IN")} against your ₹${safeDaily.toLocaleString("en-IN")} allowance, saving *₹${savedDifference.toLocaleString("en-IN")}* today.`;
  } else {
    performanceEmoji = "🟠";
    performanceSummary = `You exceeded today's safe allowance by ₹${Math.abs(savedDifference).toLocaleString("en-IN")}. Tomorrow's allowance will recalibrate automatically.`;
  }

  return (
    `🌙 *Orbit Evening Daily Wrap-up*\n\n` +
    `💸 *Spent Today:* ₹${todaySpent.toLocaleString("en-IN")} (${todayExpenses.length} transactions)\n` +
    `🎯 *Daily Safe Target:* ₹${safeDaily.toLocaleString("en-IN")}\n` +
    `${performanceEmoji} *Result:* ${performanceSummary}\n\n` +
    `💰 *Remaining Discretionary Pool:* ₹${safe.discretionaryBalance.toLocaleString("en-IN")}\n` +
    `_Rest well! Orbit will recalibrate your limits at 8:00 AM tomorrow._`
  );
}

/**
 * Check and Generate Proactive 3-Day Bill Due Alerts
 * 
 * @param {string} userId 
 * @returns {Promise<Array<string>>} List of urgent alert messages
 */
async function getUpcomingBillReminders(userId) {
  const userData = await getUserData(userId);
  if (!userData) return [];

  const reminders = [];
  const creditCard = userData.creditCardAccount || {};
  const emis = userData.emis || [];

  const now = new Date();
  const currentDay = now.getDate();

  // Credit Card Due Check (e.g. 3 days before due day)
  const ccDueDay = Number(creditCard.dueDateDay || 15);
  const ccUsed = Number(creditCard.usedCredit || 0);
  const daysToCcDue = ccDueDay - currentDay;

  if (ccUsed > 0 && daysToCcDue >= 0 && daysToCcDue <= 3) {
    reminders.push(
      `💳 *Credit Card Bill Due Soon!*\n\n` +
      `Your ${creditCard.name || "Supermoney Card"} bill of *₹${ccUsed.toLocaleString("en-IN")}* is due in *${daysToCcDue === 0 ? "TODAY" : `${daysToCcDue} days`}*.\n` +
      `_Pay anytime by sending:_ "Paid ₹${ccUsed.toFixed(0)} credit card bill from SBI"`
    );
  }

  // Active EMIs Due Check
  emis.forEach((emi) => {
    if (!emi.isPaid) {
      let emiDay = 5;
      if (emi.dueDate) emiDay = new Date(emi.dueDate).getDate();
      const daysToEmi = emiDay - currentDay;

      if (daysToEmi >= 0 && daysToEmi <= 3) {
        reminders.push(
          `📑 *EMI Due Reminder!*\n\n` +
          `Your installment for *${emi.title}* (*₹${Number(emi.monthlyEmi || 0).toLocaleString("en-IN")}*) is due in *${daysToEmi === 0 ? "TODAY" : `${daysToEmi} days`}*.\n` +
          `_Mark payment by sending:_ "Paid ${emi.title} from SBI"`
        );
      }
    }
  });

  return reminders;
}

module.exports = {
  getMorningDigest,
  getEveningWrapUp,
  getUpcomingBillReminders,
};
