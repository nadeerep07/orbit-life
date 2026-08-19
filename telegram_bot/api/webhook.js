const { Telegraf, Markup } = require("telegraf");
const axios = require("axios");
const dotenv = require("dotenv");
dotenv.config();

const {
  initializeFirebase,
  getUserIdByChatId,
  linkUserChatId,
  unlinkUserChatId,
  getUserData,
  logExpense,
  logIncome,
  logMeal,
  logMileage,
  payEmi,
  handleDebtUpdate,
  payCreditCardBill,
  getBalances,
  getEmisAndDebts,
  saveOnboardingProfile,
  getSummary,
  addAccount,
  logTransfer,
  setAccountBalance,
  undoLastTransaction,
  deleteTransactionById,
  editLastTransaction,
  getRecentTransactions,
} = require("../services/firebase");

const { parseTextMessage, analyzeImage } = require("../services/ai");
const { calculateSafeToSpend, canIAfford, simulateScenario } = require("../services/decision_engine");
const { generate30DayForecast, detectRecurringPatterns } = require("../services/forecasting");
const { generateDailyBriefing, generateWeeklyReview, calculateFinancialHealthScore } = require("../services/insights");
const { getPreferences, updatePreferences, setCategoryBudget, setGoal } = require("../services/memory");
const { evaluateAlerts } = require("../services/alerts");
const { transcribeAudio } = require("../services/voice");
const { acquireIdempotencyLock } = require("../services/idempotency");

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
initializeFirebase();

const bot = new Telegraf(BOT_TOKEN);

// ─── FINANCIAL COMMAND CENTER KEYBOARD ───────────────────────────────────────
const commandCenterMenu = Markup.keyboard([
  ["🏦 Money & Balances", "💸 Safe To Spend"],
  ["💳 Supermoney Card", "🎯 Goals & Budgets"],
  ["📊 Daily Briefing", "📈 Weekly Review"],
  ["🧠 Financial Health", "🔮 What If? Simulator"],
  ["📸 Scan Receipt", "❓ Help & Commands"],
]).resize();

// ─── COMMAND: /start ────────────────────────────────────────────────────────
bot.start(async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  let msg = `👋 *Welcome to OrbitLife — Your 24/7 AI Personal CFO!*\n\n` +
    `OrbitLife is your intelligent financial command center. You can talk naturally, send voice notes, scan receipts, or ask for financial advice:\n\n`;

  if (userId) {
    msg += `✅ *Linked Account:* \`${userId.substring(0, 8)}...\`\n\n` +
      `⚡ *Try asking Orbit right now:*\n` +
      `• _"How much can I safely spend today?"_\n` +
      `• _"Can I afford ₹4,999 headphones?"_\n` +
      `• _"What if I spend ₹5,000 this weekend?"_\n` +
      `• _"Give me my morning briefing"_\n` +
      `• _"Check my financial health score"_\n` +
      `• _"Spent ₹350 on lunch with UPI"_\n` +
      `• _"Shamveel paid remaining ₹2,500 to SBI"_`;
  } else {
    msg += `⚠️ *Account Not Linked Yet*\n` +
      `Use \`/link YOUR_FIREBASE_USER_ID\` from your OrbitLife App settings to connect in seconds.`;
  }

  await ctx.reply(msg, { parse_mode: "Markdown", ...commandCenterMenu });
});

// ─── COMMAND: /link & /unlink ───────────────────────────────────────────────
bot.command("link", async (ctx) => {
  const chatId = ctx.chat.id;
  const parts = ctx.message.text.split(/\s+/);
  if (parts.length < 2) {
    return ctx.reply("💡 *Usage:* `/link <YOUR_USER_ID>`", { parse_mode: "Markdown" });
  }

  const userId = parts[1].trim();
  try {
    await linkUserChatId(chatId, userId);
    return ctx.reply(`🎉 *Successfully Connected to OrbitLife!*`, { parse_mode: "Markdown", ...commandCenterMenu });
  } catch (err) {
    return ctx.reply(`❌ *Link Error:* ${err.message}`);
  }
});

bot.command("unlink", async (ctx) => {
  const chatId = ctx.chat.id;
  try {
    await unlinkUserChatId(chatId);
    return ctx.reply("🔌 *Account Unlinked Successfully.*", { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`);
  }
});

// ─── ACTION: 💸 SAFE TO SPEND ───────────────────────────────────────────────
async function handleSafeToSpendQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  try {
    const userData = await getUserData(userId);
    const safe = calculateSafeToSpend(userData);

    const riskEmoji = safe.financialRiskLevel === "SAFE" ? "🟢" : safe.financialRiskLevel === "MODERATE" ? "🟡" : safe.financialRiskLevel === "TIGHT" ? "🟠" : "🔴";

    const msg = `💸 *OrbitLife Dynamic Safe-To-Spend*\n\n` +
      `💰 *Safe to Spend Today:* *₹${safe.safeToSpendToday.toLocaleString("en-IN")}*\n` +
      `📅 *Safe for This Week:* ₹${safe.safeToSpendThisWeek.toLocaleString("en-IN")}\n` +
      `💼 *Discretionary Surplus:* ₹${safe.discretionaryBalance.toLocaleString("en-IN")}\n` +
      `⏳ *Days to Salary:* ${safe.daysUntilSalary} days (Due ${safe.breakdown.nextSalaryDate})\n\n` +
      `🛡️ *Protected Funds:* ₹${safe.protectedBuffer.toLocaleString("en-IN")} (Emergency Buffer + Savings)\n` +
      `📑 *Upcoming Commitments:* ₹${safe.upcomingCommitments.toLocaleString("en-IN")} (EMIs + CC Dues)\n` +
      `${riskEmoji} *Financial State:* *${safe.financialRiskLevel}*\n\n` +
      `_Orbit protects your bills and savings before calculating spending capacity._`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
}
bot.command("safetospend", handleSafeToSpendQuery);
bot.hears("💸 Safe To Spend", handleSafeToSpendQuery);

// ─── ACTION: 🌅 DAILY BRIEFING ──────────────────────────────────────────────
async function handleBriefingQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const brief = generateDailyBriefing(userData);

    const msg = `🌅 *Orbit Daily Morning Briefing*\n\n` +
      `💰 *Liquid Cash:* ₹${brief.liquidMoney.toLocaleString("en-IN")}\n` +
      `💸 *Safe to Spend Today:* *₹${brief.safeToSpendToday.toLocaleString("en-IN")}*\n` +
      `📅 *Salary In:* ${brief.daysUntilSalary} days\n` +
      `📌 *Next Bill:* ${brief.nextBill}\n\n` +
      `💳 *Credit Card:* ₹${brief.creditCard.used.toLocaleString("en-IN")} / ₹${brief.creditCard.limit.toLocaleString("en-IN")} (${brief.creditCard.utilPercent}% Util)\n` +
      `🎯 *Top Goal:* ${brief.goalProgress}\n` +
      `💸 *Spent Today:* ₹${brief.todaySpent.toLocaleString("en-IN")}\n\n` +
      `🧠 *Orbit's CFO Advice:*\n_${brief.cfoTip}_`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
}
bot.command("briefing", handleBriefingQuery);
bot.hears("📊 Daily Briefing", handleBriefingQuery);

// ─── ACTION: 📈 WEEKLY REVIEW ───────────────────────────────────────────────
async function handleWeeklyReviewQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const rev = generateWeeklyReview(userData);

    const deltaSign = rev.spendDeltaPct > 0 ? "+" : "";
    const msg = `📈 *OrbitLife Weekly CFO Review*\n\n` +
      `💸 *Spent Last 7 Days:* ₹${rev.thisWeekSpent.toLocaleString("en-IN")}\n` +
      `📊 *Velocity vs Prior Week:* ${deltaSign}${rev.spendDeltaPct}%\n` +
      `🛍️ *Top Category:* ${rev.topCategory.toUpperCase()} (₹${rev.topCategoryAmount.toLocaleString("en-IN")})\n` +
      `🎯 *Target Cap Next Week:* ₹${rev.nextWeekCap.toLocaleString("en-IN")}\n\n` +
      `🧠 *Analysis:*\n${rev.verdict}`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
}
bot.command("review", handleWeeklyReviewQuery);
bot.hears("📈 Weekly Review", handleWeeklyReviewQuery);

// ─── ACTION: 🧠 FINANCIAL HEALTH SCORE ──────────────────────────────────────
async function handleHealthScoreQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const health = calculateFinancialHealthScore(userData);

    let scoreEmoji = health.score >= 80 ? "🟢" : health.score >= 60 ? "🟡" : "🔴";

    let msg = `🧠 *Orbit Financial Health Score*\n\n` +
      `${scoreEmoji} *Overall Score:* *${health.score} / 100* (${health.rating})\n\n` +
      `📊 *Pillar Breakdown:*\n` +
      `• Savings & Net Worth: *${health.pillars.savingsAndNetWorth.score} / 25*\n` +
      `• Debt & Loan Burden: *${health.pillars.debtBurden.score} / 25*\n` +
      `• Credit Card Health: *${health.pillars.creditUtilization.score} / 20*\n` +
      `• Emergency Reserve: *${health.pillars.emergencyCoverage.score} / 15*\n` +
      `• Cash Flow Stability: *${health.pillars.cashFlowStability.score} / 15*\n\n`;

    if (health.positives.length > 0) {
      msg += `✨ *Strengths:*\n` + health.positives.map((p) => `• ${p}`).join("\n") + "\n\n";
    }
    if (health.warnings.length > 0) {
      msg += `⚠️ *Watchouts:*\n` + health.warnings.map((w) => `• ${w}`).join("\n") + "\n\n";
    }

    msg += `🎯 *Top Recommendation:*\n_${health.topImprovement}_`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
}
bot.command("health", handleHealthScoreQuery);
bot.hears("🧠 Financial Health", handleHealthScoreQuery);

// ─── ACTION: 🔮 WHAT-IF SIMULATOR ───────────────────────────────────────────
async function handleWhatIfSimulation(ctx, text) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const parsed = await parseTextMessage(text || "What if I spend 5000 today?");
    const scenario = parsed.data || { type: "SPEND", amount: 5000 };

    const sim = simulateScenario(userData, scenario);

    const msg = `🔮 *OrbitLife Scenario Simulation*\n\n` +
      `📝 *Scenario:* _${sim.summaryText}_\n\n` +
      `📊 *Before vs After Simulation:*\n` +
      `• Liquid Cash: ₹${sim.current.liquidMoney.toLocaleString("en-IN")} ➔ *₹${sim.simulated.liquidMoney.toLocaleString("en-IN")}*\n` +
      `• Safe Daily Spend: ₹${sim.current.safeDaily.toLocaleString("en-IN")} ➔ *₹${sim.simulated.safeDaily.toLocaleString("en-IN")}/day*\n` +
      `• Risk Level: ${sim.impact.riskChange}\n\n` +
      `💡 *CFO Verdict:*\n${sim.recommendation}\n\n` +
      `🔒 _This is a zero-risk simulation. No actual account data was modified._`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Simulation Error:* ${err.message}`);
  }
}
bot.command("whatif", (ctx) => handleWhatIfSimulation(ctx, ctx.message.text));
bot.hears("🔮 What If? Simulator", (ctx) => ctx.reply("🔮 *What would you like to simulate?*\n\n• _'What if I spend ₹5,000 today?'_\n• _'What if my salary is ₹35,000 next month?'_\n• _'What if I buy a laptop for ₹60,000 on 12 months EMI?'_", { parse_mode: "Markdown" }));

// ─── ACTION: 30-DAY CASH FLOW FORECAST ──────────────────────────────────────
async function handleForecastQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const forecast = generate30DayForecast(userData);

    let msg = `📅 *30-Day Cash Flow Projection*\n\n` +
      `💰 *Starting Liquid Cash:* ₹${forecast.currentLiquidBalance.toLocaleString("en-IN")}\n` +
      `📉 *Lowest Projected Balance:* *₹${forecast.lowestProjectedBalance.toLocaleString("en-IN")}* (on ${forecast.lowestBalanceDate})\n` +
      `📈 *Projected Ending Balance:* ₹${forecast.projectedEndingBalance.toLocaleString("en-IN")}\n\n`;

    if (forecast.majorEvents.length > 0) {
      msg += `📌 *Upcoming Milestones:*\n`;
      forecast.majorEvents.slice(0, 5).forEach((e) => {
        msg += `• ${e.date}: ${e.title} (${e.type === "inflow" ? "+" : "-"}₹${e.amount.toLocaleString("en-IN")})\n`;
      });
      msg += "\n";
    }

    msg += `🧠 *CFO Outlook:*\n${forecast.recommendation}`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Forecast Error:* ${err.message}`);
  }
}
bot.command("forecast", handleForecastQuery);

// ─── ACTION: 🏦 LIVE BALANCES ───────────────────────────────────────────────
async function handleBalanceQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  try {
    const data = await getBalances(userId);
    if (!data) return ctx.reply("ℹ️ No account data found. Use `/onboard` to set up.");

    let reply = `🏦 *Your Live Balances (OrbitLife)*\n\n`;
    for (const acc of data.accounts) {
      reply += `• *${acc.name}:* ₹${acc.balance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;
    }
    reply += `\n💰 *Total Liquid Cash:* *₹${data.totalLiquidCash.toLocaleString("en-IN", { minimumFractionDigits: 2 })}*\n`;
    reply += `🔒 *Fixed Deposits (FDs):* ₹${data.totalFdValue.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;

    if (data.creditCard) {
      reply += `💳 *Credit Card Outstanding Due:* -₹${data.creditCard.used.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `   _(Available Credit: ₹${data.creditCard.available.toLocaleString("en-IN", { minimumFractionDigits: 2 })} / Limit: ₹${data.creditCard.limit.toLocaleString("en-IN", { minimumFractionDigits: 2 })})_\n`;
    }
    reply += `\n🌟 *Net Liquid Worth:* *₹${data.netWorth.toLocaleString("en-IN", { minimumFractionDigits: 2 })}*`;

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("balance", handleBalanceQuery);
bot.hears("🏦 Money & Balances", handleBalanceQuery);

// ─── ACTION: 💳 SUPERMONEY CARD ────────────────────────────────────────────
async function handleCardQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const data = await getBalances(userId);
    if (!data || !data.creditCard) return ctx.reply("💳 No Credit Card linked yet.");

    const card = data.creditCard;
    const utilPct = card.limit > 0 ? Math.round((card.used / card.limit) * 100) : 0;
    const reply = `💳 *${card.name}*\n\n` +
      `🔴 *Used / Due Amount:* ₹${card.used.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `🟢 *Available Limit:* ₹${card.available.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `💳 *Total Limit:* ₹${card.limit.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📊 *Utilization:* *${utilPct}%* ${utilPct > 50 ? "⚠️ (High)" : "✅ (Healthy)"}\n` +
      `📅 *Due Date:* Day ${card.dueDateDay} of every month\n\n` +
      `💡 _Pay bill anytime by typing:_ "Paid ₹${card.used.toFixed(0)} credit card bill from SBI"`;

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("card", handleCardQuery);
bot.hears("💳 Supermoney Card", handleCardQuery);

// ─── ACTION: 🎯 GOALS & BUDGETS ─────────────────────────────────────────────
async function handleGoalsAndBudgetsQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const prefs = await getPreferences(userId);
    const goals = userData?.goals || [];

    let msg = `🎯 *Your Financial Goals & Budget Limits*\n\n`;

    if (goals.length > 0) {
      msg += `🎯 *Active Goals:*\n`;
      goals.forEach((g) => {
        const cur = Number(g.currentAmount || 0);
        const tgt = Number(g.targetAmount || 1);
        const pct = Math.round((cur / tgt) * 100);
        msg += `• *${g.name}:* ₹${cur.toLocaleString("en-IN")} / ₹${tgt.toLocaleString("en-IN")} (${pct}%)\n`;
      });
      msg += "\n";
    } else {
      msg += `🎯 *Goals:* None active. (Add with: _'Save 30,000 for Goa by Dec'_)\n\n`;
    }

    msg += `📊 *Monthly Category Budgets:*\n`;
    const catBudgets = prefs.categoryBudgets || {};
    for (const cat in catBudgets) {
      msg += `• *${cat.toUpperCase()}:* ₹${Number(catBudgets[cat]).toLocaleString("en-IN")}\n`;
    }

    msg += `\n🛡️ *Emergency Buffer Target:* ₹${Number(prefs.emergencyBufferTarget || 2000).toLocaleString("en-IN")}\n` +
      `📅 *Salary Day:* Day ${prefs.salaryDayOfMonth} (Expected: ₹${Number(prefs.expectedMonthlySalary || 29600).toLocaleString("en-IN")})`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
}
bot.command("goals", handleGoalsAndBudgetsQuery);
bot.hears("🎯 Goals & Budgets", handleGoalsAndBudgetsQuery);

// ─── ACTION: 🤝 DEBTS & EMIS ────────────────────────────────────────────────
async function handleEmisQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const data = await getEmisAndDebts(userId);
    if (!data || data.emis.length === 0) {
      return ctx.reply("📑 *No active EMIs or loans!*");
    }

    let reply = `📑 *Your Active EMIs & Loans*\n\n`;
    for (const emi of data.emis) {
      reply += `• *${emi.title}:* ₹${emi.monthlyEmi.toLocaleString("en-IN")}/mo\n` +
        `  _Paid: ${emi.paidMonths}/${emi.totalMonths} months (${emi.remainingMonths} remaining)_\n` +
        `  _Pending: ₹${emi.pendingAmount.toLocaleString("en-IN")}_\n\n`;
    }
    reply += `💡 _Mark payment by typing:_ "Paid College EMI ₹3,750 from SBI"`;
    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("emis", handleEmisQuery);

async function handleDebtsQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const data = await getEmisAndDebts(userId);
    if (!data || data.borrowLends.length === 0) {
      return ctx.reply("🤝 *No active borrow/lend records!* All settled.");
    }

    let reply = `🤝 *Active Borrow & Lend Records*\n\n`;
    for (const d of data.borrowLends) {
      reply += `• *${d.personName}* (${d.type}): *₹${d.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}* ${d.phoneNumber ? `(${d.phoneNumber})` : ""}\n`;
      if (d.originalAmount && d.paidAmount) {
        reply += `  _(Lent: ₹${d.originalAmount.toLocaleString("en-IN")} | Repaid: ₹${d.paidAmount.toLocaleString("en-IN")})_\n`;
      }
    }
    reply += `\n💡 _When someone repays, send:_ "${data.borrowLends[0]?.personName || "Person"} paid 2500 to SBI"`;
    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("debts", handleDebtsQuery);

// ─── COMMAND: /setbalance ──────────────────────────────────────────────────
bot.command("setbalance", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  const text = ctx.message.text.replace("/setbalance", "").trim();
  const parts = text.split(/\s+/);
  if (parts.length < 2) {
    return ctx.reply(
      "💡 *Usage:* `/setbalance <Account Name> <New Balance>`\n\n" +
      "• Example: `/setbalance SBI 3312.60`\n" +
      "• Example: `/setbalance HDFC 1500`\n" +
      "• Example: `/setbalance Cash 500`",
      { parse_mode: "Markdown" }
    );
  }

  const newBal = parts[parts.length - 1];
  const accName = parts.slice(0, -1).join(" ");

  try {
    const res = await setAccountBalance(userId, { accountName: accName, balance: newBal });
    const reply = `🏦 *Account Balance Corrected!*\n\n` +
      `📌 *Account:* 🏦 ${res.accountName}\n` +
      `🔄 *Old Balance:* ₹${res.oldBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `✅ *New Live Balance:* ₹${res.newBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📊 *Adjustment:* ${res.difference >= 0 ? "+" : "-"}₹${Math.abs(res.difference).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `_Synced across your OrbitLife App in real time!_`;
    return ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── COMMAND: /undo ────────────────────────────────────────────────────────
bot.command("undo", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  try {
    const res = await undoLastTransaction(userId);
    const reply = `↩️ *Transaction Undone & Reverted!*\n\n` +
      `📝 *Reverted:* ${res.description}\n` +
      `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      (res.restoredBalance !== null ? `🏦 *${res.restoredAccountName} Restored Balance:* ₹${res.restoredBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` : "\n") +
      `_Synced across your OrbitLife App in real time!_`;
    return ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.reply(`❌ *Undo Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── COMMAND: /recent or /transactions ─────────────────────────────────────
async function handleRecentTransactions(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  try {
    const list = await getRecentTransactions(userId, 5);
    if (list.length === 0) {
      return ctx.reply("📝 No recent transactions found.");
    }

    let text = `📜 *Recent 5 Transactions:*\n\n`;
    const buttons = [];

    list.forEach((t, idx) => {
      const amtStr = Number(t.amount || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 });
      const desc = t.description || t.title || t.categoryOrSource || "Transaction";
      const typeIcon = t.type === "income" ? "🟢" : t.type === "transfer" ? "🔄" : "🔴";
      const dateStr = t.date ? new Date(t.date).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }) : "";
      
      text += `${idx + 1}. ${typeIcon} *${desc}* — ₹${amtStr} (${t.accountId || "Bank"}) ${dateStr}\n`;
      buttons.push([Markup.button.callback(`🗑️ Undo #${idx + 1} (₹${amtStr})`, `undo_${t.id}`)]);
    });

    text += `\n_Tap a button below to quickly delete or undo any entry._`;
    return ctx.reply(text, { parse_mode: "Markdown", ...Markup.inlineKeyboard(buttons) });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
}
bot.command("recent", handleRecentTransactions);
bot.command("transactions", handleRecentTransactions);

// ─── ACTION CALLBACK: Undo Specific Transaction ───────────────────────────
bot.action(/^undo_(.+)$/, async (ctx) => {
  const txId = ctx.match[1];
  const chatId = ctx.chat?.id || ctx.callbackQuery?.message?.chat?.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.answerCbQuery("Account not linked!");

  try {
    const res = await deleteTransactionById(userId, txId);
    await ctx.answerCbQuery("✅ Transaction undone!");
    const reply = `↩️ *Transaction Undone & Balance Restored!*\n\n` +
      `📝 *Reverted:* ${res.description}\n` +
      `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      (res.restoredBalance !== null ? `🏦 *${res.restoredAccountName} Restored Balance:* ₹${res.restoredBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` : "\n") +
      `_Synced across your OrbitLife App in real time!_`;
    return ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.answerCbQuery(`Error: ${err.message}`);
  }
});

// ─── COMMAND: /help ─────────────────────────────────────────────────────────
bot.command("help", async (ctx) => {
  const msg = `💡 *OrbitLife AI Personal CFO Cheatsheet (₹ INR)*\n\n` +
    `*1. Financial Intelligence & Decisions:*\n` +
    `• _"Can I afford ₹4,999 headphones?"_\n` +
    `• _"How much can I safely spend today?"_\n` +
    `• _"What if I spend ₹5,000 today?"_\n` +
    `• _/safetospend - Calculate safe daily limits_\n` +
    `• _/forecast - 30-day forward cash flow_\n` +
    `• _/health - Check 0-100 financial health score_\n\n` +
    `*2. Spends & Incomes:*\n` +
    `• _"Spent ₹350 on lunch with UPI"_\n` +
    `• _"Received ₹29,600 salary"_\n` +
    `• _/undo - Revert last action & restore balance_\n\n` +
    `*3. Credit Card & EMIs:*\n` +
    `• _"Paid ₹2,920 credit card bill from SBI"_\n` +
    `• _"Paid College EMI ₹3,750"_\n` +
    `• _/card - Check limit & utilization_\n` +
    `• _/emis - Check loans & tenure_\n\n` +
    `*4. Borrow & Lend:*\n` +
    `• _"Shamveel paid remaining ₹2,500 to SBI"_\n` +
    `• _"Lent ₹2,000 to Rahul"_\n` +
    `• _/debts - View active debt balances_\n\n` +
    `*5. Multimodal Vision & Voice:*\n` +
    `• 🎙️ Send any Voice Message to log or ask questions!\n` +
    `• 🧾 Snap any receipt or payment screenshot!`;

  await ctx.reply(msg, { parse_mode: "Markdown" });
});
bot.hears("❓ Help & Commands", (ctx) => ctx.telegram.sendMessage(ctx.chat.id, "/help"));
bot.hears("📸 Scan Receipt", (ctx) => ctx.reply("📸 *Snap a photo of any receipt, bill, or payment screenshot!*", { parse_mode: "Markdown" }));

// ─── PHOTO HANDLER (Receipt OCR & Food Vision) ──────────────────────────────
bot.on("photo", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your OrbitLife account first using `/link <USER_ID>`.");

  const statusMsg = await ctx.reply("🔍 *Analyzing image with Gemini Vision AI...*", { parse_mode: "Markdown" });

  try {
    const photos = ctx.message.photo;
    const bestPhoto = photos[photos.length - 1];
    const fileLink = await ctx.telegram.getFileLink(bestPhoto.file_id);
    const caption = ctx.message.caption || "";

    const response = await axios.get(fileLink.href, { responseType: "arraybuffer" });
    const imageBuffer = Buffer.from(response.data);

    const analysis = await analyzeImage(imageBuffer, "image/jpeg", caption);

    if (analysis.type === "RECEIPT") {
      const { merchant, amount, category, date, items } = analysis.data;
      const expense = await logExpense(userId, {
        amount: amount || 0,
        description: merchant || "Receipt Expense",
        category: category || "Groceries",
        date: date || new Date().toISOString().split("T")[0],
        source: "receipt_ocr",
      });

      let reply = `🧾 *Receipt Processed & Logged!*\n\n` +
        `🏪 *Merchant:* ${merchant || "Store"}\n` +
        `💰 *Total Amount:* ₹${(amount || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `📁 *Category:* ${expense.categoryId}\n` +
        `📅 *Date:* ${expense.date}\n`;

      if (items && items.length > 0) {
        reply += `\n🛒 *Items Extracted:*\n`;
        items.slice(0, 5).forEach((it) => {
          reply += `• ${it.name} — ₹${(it.price || 0).toLocaleString("en-IN")}\n`;
        });
      }

      return ctx.reply(reply, {
        parse_mode: "Markdown",
        ...Markup.inlineKeyboard([[Markup.button.callback("↩️ Undo This", `undo_${expense.id}`)]]),
      });
    }

    if (analysis.type === "MEAL") {
      const meal = await logMeal(userId, analysis.data);
      return ctx.reply(
        `🥗 *Food Picture Analyzed!*\n\n` +
        `🍽️ *Food:* ${meal.name}\n` +
        `🔥 *Calories:* ${meal.calories} kcal\n` +
        `🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`,
        { parse_mode: "Markdown" }
      );
    }

    return ctx.reply("🤖 Image processed, but couldn't detect a clear receipt or meal. Please try again with better lighting.");
  } catch (err) {
    return ctx.reply(`❌ *Image Processing Error:* ${err.message}`);
  }
});

// ─── VOICE HANDLER (Whisper Speech-To-Text & Audio AI) ──────────────────────
bot.on(["voice", "audio"], async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  const statusMsg = await ctx.reply("🎙️ *Processing voice note with Whisper AI...*", { parse_mode: "Markdown" });

  try {
    const fileId = ctx.message.voice ? ctx.message.voice.file_id : ctx.message.audio.file_id;
    const fileLink = await ctx.telegram.getFileLink(fileId);
    const response = await axios.get(fileLink.href, { responseType: "arraybuffer" });
    const audioBuffer = Buffer.from(response.data);

    const transcribedText = await transcribeAudio(audioBuffer, "audio/ogg");
    if (!transcribedText) {
      return ctx.reply("⚠️ Could not recognize speech. Please try speaking closer to the microphone.");
    }

    await ctx.reply(`🗣️ _"${transcribedText}"_`, { parse_mode: "Markdown" });
    return await handleFinancialIntent(ctx, userId, transcribedText);
  } catch (err) {
    return ctx.reply(`❌ *Voice Processing Error:* ${err.message}`);
  }
});

// ─── TEXT MESSAGE HANDLER (Natural Language Personal CFO) ───────────────────
bot.on("text", async (ctx) => {
  const chatId = ctx.chat.id;
  const text = ctx.message.text.trim();
  if (text.startsWith("/")) return;

  const lockKey = `msg_${chatId}_${ctx.message.message_id}`;
  if (!acquireIdempotencyLock(lockKey)) {
    return;
  }

  const userId = await getUserIdByChatId(chatId);
  if (!userId) {
    return ctx.reply("⚠️ Please link your account first using `/link <YOUR_USER_ID>`.");
  }

  return await handleFinancialIntent(ctx, userId, text);
});

/**
 * Central Financial Intent Handler
 */
async function handleFinancialIntent(ctx, userId, text) {
  try {
    const userData = await getUserData(userId);
    const parsed = await parseTextMessage(text);

    // 1. CAN I AFFORD THIS?
    if (parsed.intent === "CAN_I_AFFORD") {
      const { amount, itemName, category } = parsed.data;
      const res = canIAfford(userData, { amount, itemName, category });

      const msg = `${res.verdictEmoji} *${res.verdictTitle}*\n\n` +
        `🛍️ *Purchase:* ${res.itemName || "Item"} (₹${(res.purchaseAmount || 0).toLocaleString("en-IN")})\n` +
        `💰 *Discretionary Surplus:* ₹${(res.discretionaryBalance || 0).toLocaleString("en-IN")}\n` +
        `📅 *Days Until Salary:* ${res.daysUntilSalary} days\n\n` +
        `📊 *CFO Impact:*\n` + (res.impact || []).map((i) => `• ${i}`).join("\n") + "\n\n" +
        `💡 *Recommendation:*\n_${res.recommendation}_`;

      return ctx.reply(msg, { parse_mode: "Markdown" });
    }

    // 2. WHAT-IF SCENARIO SIMULATION
    if (parsed.intent === "WHAT_IF") {
      const sim = simulateScenario(userData, parsed.data);
      const msg = `🔮 *OrbitLife Scenario Simulation*\n\n` +
        `📝 *Scenario:* _${sim.summaryText}_\n\n` +
        `📊 *Before vs After Simulation:*\n` +
        `• Liquid Cash: ₹${sim.current.liquidMoney.toLocaleString("en-IN")} ➔ *₹${sim.simulated.liquidMoney.toLocaleString("en-IN")}*\n` +
        `• Safe Daily Spend: ₹${sim.current.safeDaily.toLocaleString("en-IN")} ➔ *₹${sim.simulated.safeDaily.toLocaleString("en-IN")}/day*\n` +
        `• Risk Level: ${sim.impact.riskChange}\n\n` +
        `💡 *CFO Verdict:*\n${sim.recommendation}\n\n` +
        `🔒 _Zero-risk simulation. No actual account data was modified._`;

      return ctx.reply(msg, { parse_mode: "Markdown" });
    }

    // 3. SAFE TO SPEND
    if (parsed.intent === "SAFE_TO_SPEND") {
      return handleSafeToSpendQuery(ctx);
    }

    // 4. CASH FLOW FORECAST
    if (parsed.intent === "CASH_FLOW_FORECAST") {
      return handleForecastQuery(ctx);
    }

    // 5. DAILY BRIEFING
    if (parsed.intent === "DAILY_BRIEFING") {
      return handleBriefingQuery(ctx);
    }

    // 6. WEEKLY REVIEW
    if (parsed.intent === "WEEKLY_REVIEW") {
      return handleWeeklyReviewQuery(ctx);
    }

    // 7. FINANCIAL HEALTH SCORE
    if (parsed.intent === "FINANCIAL_HEALTH") {
      return handleHealthScoreQuery(ctx);
    }

    // 8. SET PREFERENCE / GOAL
    if (parsed.intent === "SET_PREFERENCE") {
      const updated = await updatePreferences(userId, parsed.data);
      return ctx.reply(
        `⚙️ *Financial Preference Saved!*\n\n` +
        `• Expected Salary: ₹${Number(updated.expectedMonthlySalary).toLocaleString("en-IN")}\n` +
        `• Salary Day: Day ${updated.salaryDayOfMonth}\n` +
        `• Emergency Buffer: ₹${Number(updated.emergencyBufferTarget).toLocaleString("en-IN")}\n` +
        `• Minimum Savings: ₹${Number(updated.minimumMonthlySavings).toLocaleString("en-IN")}\n\n` +
        `_Orbit will calibrate all safe-to-spend calculations with these rules._`,
        { parse_mode: "Markdown" }
      );
    }

    if (parsed.intent === "SET_GOAL") {
      const goal = await setGoal(userId, parsed.data);
      return ctx.reply(
        `🎯 *New Goal Created!*\n\n` +
        `📌 *Goal:* ${goal.name}\n` +
        `💰 *Target:* ₹${goal.targetAmount.toLocaleString("en-IN")}\n` +
        `📈 *Monthly Allocation:* ₹${goal.monthlyContribution.toLocaleString("en-IN")}/mo\n\n` +
        `_Protected in your daily safe-to-spend calculations!_`,
        { parse_mode: "Markdown" }
      );
    }

    // 9. ALERTS
    if (parsed.intent === "ALERTS") {
      const alerts = evaluateAlerts(userData);
      if (alerts.length === 0) {
        return ctx.reply("🟢 *All Clear!* No financial risks or overdue obligations detected.", { parse_mode: "Markdown" });
      }
      let alertMsg = `⚠️ *Active Financial Alerts:*\n\n`;
      alerts.forEach((a) => {
        alertMsg += `${a.icon} *[${a.priority}] ${a.title}*\n${a.message}\n\n`;
      });
      return ctx.reply(alertMsg, { parse_mode: "Markdown" });
    }

    // 10. PAY EMI
    if (parsed.intent === "PAY_EMI") {
      const { emiName, amount, account } = parsed.data;
      const res = await payEmi(userId, { emiTitle: emiName, amount, accountName: account });
      const reply = `✅ *EMI Payment Recorded!*\n\n` +
        `📌 *Loan:* ${res.emiTitle}\n` +
        `💰 *Amount Paid:* ₹${res.amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        (res.fromAccountName ? `📤 *Paid From:* 🏦 ${res.fromAccountName} (Bal: ₹${res.fromNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n` : "") +
        `📅 *Payments Made:* ${res.paidMonths} months\n` +
        `⏳ *Remaining Tenure:* ${res.remainingMonths} months left\n\n` +
        `_Deduction logged and synced to your app!_`;
      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    // 11. DEBT UPDATE (Lend/Borrow Repayment)
    if (parsed.intent === "DEBT_UPDATE") {
      const res = await handleDebtUpdate(userId, {
        ...parsed.data,
        accountName: parsed.data.account,
      });
      if (res.isSettled !== undefined) {
        const isLend = res.type === "lend" || res.type === "lent";
        const reply = `🤝 *Debt ${isLend ? "Repayment Received" : "Payment Made"}!*\n\n` +
          `👤 *Person:* ${res.personName}\n` +
          `💰 *Amount:* ₹${res.amountSettled.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          (res.toAccountName ? `${isLend ? "📥 *Credited To:*" : "📤 *Paid From:*"} 🏦 ${res.toAccountName} (Bal: ₹${res.toNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n` : "") +
          `📊 *Remaining Debt:* ₹${res.remainingDebt.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `✨ *Status:* ${res.isSettled ? "Fully Settled 🎉" : "Partially Paid"}\n\n` +
          `_Synced across your OrbitLife App in real time!_`;
        return ctx.reply(reply, { parse_mode: "Markdown" });
      } else {
        const reply = `🤝 *New ${res.type === "borrow" ? "Borrow" : "Lend"} Record Added!*\n\n` +
          `👤 *Person:* ${res.personName}\n` +
          `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `📌 *Type:* ${res.type === "borrow" ? "You Borrowed" : "You Lent"}\n\n` +
          `_Synced across your OrbitLife App in real time!_`;
        return ctx.reply(reply, { parse_mode: "Markdown" });
      }
    }

    // 12. PAY CREDIT CARD BILL
    if (parsed.intent === "PAY_CARD_BILL") {
      const { amount, account } = parsed.data;
      const res = await payCreditCardBill(userId, { amount, accountName: account });
      const reply = `💳 *Credit Card Bill Paid!*\n\n` +
        `💰 *Amount Paid:* ₹${res.amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        (res.fromAccountName ? `📤 *Paid From:* 🏦 ${res.fromAccountName} (Bal: ₹${res.fromNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n` : "") +
        `🟢 *Available Credit Restored:* ₹${res.newAvailableCredit.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `🔴 *Remaining Used Credit:* ₹${res.newUsedCredit.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
        `_Synced across your OrbitLife App in real time!_`;
      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    // 13. TRANSFER
    if (parsed.intent === "TRANSFER") {
      const { amount, fromAccount, toAccount, date, notes } = parsed.data;
      const res = await logTransfer(userId, {
        amount,
        fromAccount: fromAccount || "Default",
        toAccount: toAccount || "Cash in Hand",
        date,
        notes,
      });
      const reply = `🔄 *Transfer Recorded!*\n\n` +
        `💰 *Amount Transferred:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `📤 *From:* 🏦 ${res.fromAccountName} (Bal: ₹${res.fromNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n` +
        `📥 *To:* 🏦 ${res.toAccountName} (Bal: ₹${res.toNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n\n` +
        `_Synced across your OrbitLife App in real time!_`;
      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    // 14. EXPENSE
    if (parsed.intent === "EXPENSE") {
      const exp = await logExpense(userId, {
        amount: parsed.data.amount,
        description: parsed.data.description || "Expense",
        category: parsed.data.category || "General",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
        source: "telegram_text",
      });
      const reply = `💸 *Expense Logged!*\n\n📝 *Item:* ${exp.description}\n💰 *Amount:* ₹${exp.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n📁 *Category:* ${exp.categoryId}\n💳 *Account:* ${exp.accountId}`;
      return ctx.reply(reply, {
        parse_mode: "Markdown",
        ...Markup.inlineKeyboard([[Markup.button.callback("↩️ Undo This", `undo_${exp.id}`)]]),
      });
    }

    // 15. INCOME
    if (parsed.intent === "INCOME") {
      const inc = await logIncome(userId, {
        amount: parsed.data.amount,
        source: parsed.data.source || "Income",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
      });
      const reply = `🟢 *Income Logged!*\n\n💵 *Source:* ${inc.source}\n💰 *Amount:* ₹${inc.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;
      return ctx.reply(reply, {
        parse_mode: "Markdown",
        ...Markup.inlineKeyboard([[Markup.button.callback("↩️ Undo This", `undo_${inc.id}`)]]),
      });
    }

    // 16. SET BALANCE
    if (parsed.intent === "SET_BALANCE") {
      const { accountName, balance } = parsed.data;
      const res = await setAccountBalance(userId, { accountName: accountName || "SBI", balance });
      const reply = `🏦 *Account Balance Corrected!*\n\n` +
        `📌 *Account:* 🏦 ${res.accountName}\n` +
        `🔄 *Old Balance:* ₹${res.oldBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `✅ *New Live Balance:* ₹${res.newBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `📊 *Adjustment:* ${res.difference >= 0 ? "+" : "-"}₹${Math.abs(res.difference).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
        `_Synced across your OrbitLife App in real time!_`;
      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    // 17. UNDO LAST
    if (parsed.intent === "UNDO") {
      const res = await undoLastTransaction(userId);
      const reply = `↩️ *Transaction Undone & Reverted!*\n\n` +
        `📝 *Reverted:* ${res.description}\n` +
        `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        (res.restoredBalance !== null ? `🏦 *${res.restoredAccountName} Restored Balance:* ₹${res.restoredBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` : "\n") +
        `_Synced across your OrbitLife App in real time!_`;
      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    // 18. MEAL & MILEAGE
    if (parsed.intent === "MEAL") {
      const meal = await logMeal(userId, parsed.data);
      return ctx.reply(`🥗 *Meal Logged!*\n\n🍽️ *Food:* ${meal.name}\n🔥 *Calories:* ${meal.calories} kcal\n🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`, { parse_mode: "Markdown" });
    }

    if (parsed.intent === "MILEAGE") {
      const entry = await logMileage(userId, parsed.data);
      return ctx.reply(`⛽ *Mileage Logged!*\n\n🚗 *Odometer:* ${entry.odometer} km\n🛢️ *Fuel:* ${entry.liters} L\n💰 *Cost:* ₹${entry.totalCost.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown" });
    }

    // 19. QUERY ROUTING
    if (parsed.intent === "QUERY") {
      const type = parsed.data?.queryType;
      if (type === "balance") return handleBalanceQuery(ctx);
      if (type === "card") return handleCardQuery(ctx);
      if (type === "emis") return handleEmisQuery(ctx);
      if (type === "debts") return handleDebtsQuery(ctx);
      return handleStatsQuery(ctx);
    }

    return ctx.reply("🤖 I'm here to help! Ask me anything like _'How much can I spend today?'_, _'Can I afford ₹3,000?'_, or send `/help`.", { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
}

// ─── VERCEL SERVERLESS HANDLER ──────────────────────────────────────────────
module.exports = async (req, res) => {
  if (req.method === "POST") {
    try {
      await bot.handleUpdate(req.body, res);
      if (!res.headersSent) res.status(200).send("OK");
    } catch (err) {
      console.error("Webhook processing error:", err);
      if (!res.headersSent) res.status(500).send("Internal Server Error");
    }
  } else {
    res.status(200).send("OrbitLife Personal CFO Webhook is Active.");
  }
};
