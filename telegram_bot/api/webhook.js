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
} = require("../services/firebase");

const { parseTextMessage, analyzeImage } = require("../services/ai");

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
initializeFirebase();

const bot = new Telegraf(BOT_TOKEN);

const WEB_APP_URL = "https://orbit-life-zeta.vercel.app/";

// ─── CUSTOM PERSISTENT REPLY KEYBOARD ───────────────────────────────────────
const mainMenu = Markup.keyboard([
  ["📊 Today's Stats", "🎯 Daily Scorecard"],
  ["🏦 Live Balances", "💳 Supermoney Card"],
  ["📑 Active EMIs", "🤝 Borrow & Lend"],

]).resize();

// Inline Action Chips
const postActionChips = Markup.inlineKeyboard([
  [
    Markup.button.callback("🏦 View Balance", "quick_balance"),
    Markup.button.callback("🎯 Scorecard", "quick_scorecard"),
  ],
  [
    Markup.button.callback("💳 Supermoney Card", "quick_card"),
    Markup.button.callback("📑 My EMIs", "quick_emis"),
  ],
]);

// ─── COMMAND: /start ────────────────────────────────────────────────────────
bot.start(async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  let msg = `👋 *Welcome to OrbitLife Full Financial Coach!*\n\n` +
    `Automate your personal finances, track Supermoney card limits, EMIs, and daily safe limits in Indian Rupees (₹ INR):\n\n`;

  if (userId) {
    msg += `✅ *Connected to App:* \`${userId.substring(0, 8)}...\`\n\n` +
      `⚡ *Tap Any Quick Action Below or Send Text/Voice:*\n` +
      `• *Log Spends:* _"Spent ₹350 on lunch with UPI"_\n` +
      `• *Card Spends:* _"Spent ₹1,200 on Supermoney card"_\n` +
      `• *Log Salary:* _"Received ₹29,600 salary"_\n` +
      `• *Mark EMI Paid:* _"Paid College EMI ₹3,750"_\n` +
      `• *Debt Repayment:* _"Shamveel paid back ₹5,000"_\n` +
      `• *Pay Card Bill:* _"Paid ₹10,000 credit card bill"_\n` +
      `• *Daily Scorecard:* Tap *🎯 Daily Scorecard*\n` +
      `• *Snap Receipt or Food Photo:* Send any picture! 📸`;
  } else {
    msg += `⚠️ *Account Not Linked!*\n\nSend: \`/link YOUR_FIREBASE_USER_ID\``;
  }

  await ctx.reply(msg, { parse_mode: "Markdown", ...mainMenu });
});

bot.command("link", async (ctx) => {
  const chatId = ctx.chat.id;
  const args = ctx.message.text.split(" ").slice(1);
  const userId = args[0]?.trim();

  if (!userId) {
    return ctx.reply("❌ Please provide your Firebase User ID.\nExample: `/link abc123XYZ456`", { parse_mode: "Markdown" });
  }

  try {
    await linkUserChatId(userId, chatId);
    await ctx.reply(`🎉 *Success! Linked to OrbitLife.*\n\nUser ID: \`${userId}\`\n\nYou can now manage expenses, EMIs, debts, and balances directly! 🚀`, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ *Failed to link account:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

bot.command("unlink", async (ctx) => {
  const chatId = ctx.chat.id;
  try {
    await unlinkUserChatId(chatId);
    await ctx.reply("🔌 *Account Unlinked!*\n\nYou can link a new account anytime with:\n`/link <NEW_USER_ID>`", { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Error:* ${err.message}`);
  }
});

bot.command("whoami", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (userId) {
    await ctx.reply(`👤 *Current Connected Account:*\n\nUser ID: \`${userId}\`\n\nTo switch accounts, send:\n\`/link <NEW_USER_ID>\`\nOr to disconnect, send:\n\`/unlink\``, { parse_mode: "Markdown", ...mainMenu });
  } else {
    await ctx.reply("⚠️ No account is currently linked.\n\nSend `/link <USER_ID>` to connect.", { parse_mode: "Markdown" });
  }
});

// ─── ACTION: 🎯 DAILY SCORECARD ────────────────────────────────────────────
async function handleDailyScorecard(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your account first using `/link <USER_ID>`.");

  try {
    const summary = await getSummary(userId);
    const balanceData = await getBalances(userId);
    const debtData = await getEmisAndDebts(userId);
    const userData = await getUserData(userId);

    const todayStr = new Date().toISOString().split("T")[0];

    // Calculate Daily Safe Limit
    const monthlyIncome = Number(summary?.monthEarned || 29600);
    const fixedOutflows = (userData?.emis || []).reduce((sum, e) => sum + (Number(e.monthlyEmi || e.amount) || 0), 0) + 1059; // EMIs + Fixed Bills
    const monthlySurplus = Math.max(0, monthlyIncome - fixedOutflows);
    const dailySafeLimit = Math.round(monthlySurplus / 30) || 700;
    const spentToday = Math.round(summary?.todaySpent || 0);

    const isSpendUnderLimit = spentToday <= dailySafeLimit;
    const spendStatusEmoji = isSpendUnderLimit ? "✅" : "⚠️";

    // Credit Card Utilization
    const cc = balanceData?.creditCard;
    const ccLimit = cc?.limit || 26713.8;
    const ccUsed = cc?.used || 0;
    const ccRatio = Math.round((ccUsed / ccLimit) * 100);
    const ccStatusEmoji = ccRatio <= 30 ? "✅" : ccRatio <= 50 ? "🟡" : "🔴";

    // EMIs
    const totalEmis = debtData?.emis?.length || 0;
    const totalMonthlyEmi = debtData?.emis?.reduce((sum, e) => sum + e.monthlyEmi, 0) || 0;

    // Nutrition
    const calories = summary?.todayCalories || 0;
    const calTarget = summary?.calorieTarget || 2000;
    const calEmoji = calories > 0 ? "✅" : "⏳";

    let msg = `🎯 *ORBITLIFE DAILY SCORECARD*\n` +
      `📅 (${todayStr})\n` +
      `━━━━━━━━━━━━━━━━━━━━\n\n` +
      `💸 *Daily Spend Cap:* ${spendStatusEmoji} *₹${spentToday.toLocaleString("en-IN")}* / ₹${dailySafeLimit.toLocaleString("en-IN")}\n` +
      `💳 *Card Utilization:* ${ccStatusEmoji} *${ccRatio}%* (₹${ccUsed.toLocaleString("en-IN")} / ₹${Math.round(ccLimit).toLocaleString("en-IN")})\n` +
      `🏦 *Liquid Cash:* 💰 *₹${Math.round(balanceData?.totalLiquidCash || 0).toLocaleString("en-IN")}*\n` +
      `📑 *Active EMIs:* ⏳ *${totalEmis} Active* (₹${totalMonthlyEmi.toLocaleString("en-IN")}/mo)\n` +
      `🥗 *Daily Calories:* ${calEmoji} *${calories}* / ${calTarget} kcal\n`;

    if (debtData?.borrowLends?.length > 0) {
      const topDebt = debtData.borrowLends[0];
      msg += `🤝 *Receivables:* ⏳ *₹${topDebt.amount.toLocaleString("en-IN")}* (${topDebt.personName})\n`;
    }

    msg += `\n━━━━━━━━━━━━━━━━━━━━\n` +
      `🔥 *Consistency is King. Win the Day!*`;

    await ctx.reply(msg, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ Error generating scorecard: ${err.message}`);
  }
}
bot.command("scorecard", handleDailyScorecard);
bot.hears("🎯 Daily Scorecard", handleDailyScorecard);

// ─── ACTION: 📊 TODAY'S STATS ──────────────────────────────────────────────
async function handleStatsQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const summary = await getSummary(userId);
    if (!summary) return ctx.reply("ℹ️ No data available.");

    const caloriePercent = Math.round((summary.todayCalories / (summary.calorieTarget || 2000)) * 100);
    const msg = `📊 *OrbitLife Analytics & Today's Stats*\n\n` +
      `💸 *Spent Today:* ₹${summary.todaySpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })} (${summary.todayExpensesCount} entries)\n` +
      `📈 *Month Inflow:* ₹${summary.monthEarned.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📉 *Month Outflow:* ₹${summary.monthSpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `💼 *Net Monthly Surplus:* ₹${summary.monthNet.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `🥗 *Nutrition Today:*\n` +
      `• Calories: *${summary.todayCalories}* / ${summary.calorieTarget} kcal (${caloriePercent}%)\n` +
      `• Protein: *${summary.todayProtein.toFixed(1)}g* | Carbs: *${summary.todayCarbs.toFixed(1)}g* | Fat: *${summary.todayFat.toFixed(1)}g*`;

    await ctx.reply(msg, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("today", handleStatsQuery);
bot.command("stats", handleStatsQuery);
bot.hears("📊 Today's Stats", handleStatsQuery);

// ─── ACTION: 🏦 LIVE BALANCES ──────────────────────────────────────────────
async function handleBalanceQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account with `/link <USER_ID>` first.");

  try {
    const data = await getBalances(userId);
    if (!data) return ctx.reply("ℹ️ No account data found.");

    let reply = `🏦 *Your Live Balances (OrbitLife)*\n\n`;
    for (const a of data.accounts) {
      reply += `• *${a.name}:* ₹${a.balance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;
    }
    reply += `\n💰 *Total Liquid Cash:* ₹${data.totalLiquidCash.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;

    if (data.totalFdValue > 0) {
      reply += `🔒 *Fixed Deposits (FDs):* ₹${data.totalFdValue.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;
    }

    if (data.creditCard) {
      reply += `💳 *Credit Card Outstanding Due:* -₹${data.creditCard.used.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;
      reply += `   _(Available Credit: ₹${data.creditCard.available.toLocaleString("en-IN", { minimumFractionDigits: 2 })} / Limit: ₹${data.creditCard.limit.toLocaleString("en-IN", { minimumFractionDigits: 2 })})_\n`;
    }

    reply += `\n🌟 *Net Liquid Worth:* ₹${data.netWorth.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;

    await ctx.reply(reply, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("balance", handleBalanceQuery);
bot.hears("🏦 Live Balances", handleBalanceQuery);

// ─── ACTION: 🔄 TRANSFER BETWEEN ACCOUNTS ─────────────────────────────────
bot.command("transfer", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  const text = ctx.message.text.replace("/transfer", "").trim();
  const parts = text.split(/\s+/);
  if (parts.length < 3) {
    return ctx.reply(
      "💡 *Usage:* `/transfer <amount> <from_account> <to_account>`\n\n" +
      "• Example: `/transfer 5000 SBI HDFC`\n" +
      "• Example: `/transfer 2000 SBI Cash`\n" +
      "• Or just type in natural language: _'Transferred ₹2,000 from SBI to Cash in Hand'_",
      { parse_mode: "Markdown", ...mainMenu }
    );
  }

  const amount = Number(parts[0]);
  const fromAccount = parts[1];
  const toAccount = parts.slice(2).join(" ");

  try {
    const res = await logTransfer(userId, { amount, fromAccount, toAccount });
    const reply = `🔄 *Transfer Recorded!*\n\n` +
      `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📤 *From:* 🏦 ${res.fromAccountName} (Bal: ₹${res.fromNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n` +
      `📥 *To:* 🏦 ${res.toAccountName} (Bal: ₹${res.toNewBalance.toLocaleString("en-IN", { minimumFractionDigits: 2 })})\n\n` +
      `_Synced across your OrbitLife App in real time!_`;
    return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
  } catch (err) {
    return ctx.reply(`❌ *Transfer Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── ACTION: 🏦 ADD ACCOUNT (e.g. Cash in Hand) ────────────────────────────
bot.command("addaccount", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first using `/link YOUR_USER_ID`.");

  const text = ctx.message.text.replace("/addaccount", "").trim();
  const parts = text.split(/\s+/);
  if (parts.length < 1 || !text) {
    return ctx.reply(
      "💡 *Usage:* `/addaccount <Account Name> <Initial Balance>`\n\n" +
      "• Example: `/addaccount Cash in Hand 2000`\n" +
      "• Example: `/addaccount HDFC Bank 25000`",
      { parse_mode: "Markdown", ...mainMenu }
    );
  }

  const lastPart = parts[parts.length - 1];
  let balance = 0;
  let name = text;
  if (!isNaN(Number(lastPart))) {
    balance = Number(lastPart);
    name = parts.slice(0, -1).join(" ");
  }

  try {
    const res = await addAccount(userId, { name, balance });
    const reply = `🏦 *Account ${res.isNew ? "Created" : "Updated"}!*\n\n` +
      `📌 *Name:* ${res.name}\n` +
      `💰 *Balance:* ₹${res.balance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `_Available for spends and bank transfers!_`;
    return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── ACTION: 💳 SUPERMONEY CARD ────────────────────────────────────────────
async function handleCardQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const userData = await getUserData(userId);
    const cc = userData?.creditCardAccount;
    const fds = userData?.fdLots || [];

    if (!cc) {
      return ctx.reply("ℹ️ No Credit Card found in your profile.");
    }

    const totalFd = fds.reduce((sum, f) => sum + (Number(f.currentValue || f.principal) || 0), 0);

    const reply = `💳 *${cc.name || "Supermoney Secured Credit Card"}*\n\n` +
      `• *Total Credit Limit:* ₹${Number(cc.creditLimit || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `• *Available Credit:* ₹${Number(cc.availableCredit || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `• *Current Used:* ₹${Number(cc.usedCredit || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `📅 *Bill Cycle:* Statement on *${cc.statementDateDay || 1}st*, Due on *${cc.dueDateDay || 15}th*\n` +
      `🔒 *Backed by FD:* ₹${totalFd.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `💡 _To log a spend:_ "Spent ₹500 on card"\n` +
      `💡 _To pay bill:_ "Paid ₹5000 credit card bill"`;

    await ctx.reply(reply, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("card", handleCardQuery);
bot.hears("💳 Supermoney Card", handleCardQuery);

// ─── ACTION: 📑 ACTIVE EMIS ────────────────────────────────────────────────
async function handleEmisQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const data = await getEmisAndDebts(userId);
    if (!data || data.emis.length === 0) {
      return ctx.reply("🎉 *No active EMIs!* You are completely EMI-free.");
    }

    let totalMonthly = 0;
    let totalPendingDebt = 0;
    let totalPaidDebt = 0;
    let reply = `📑 *ORBITLIFE ACTIVE EMIs & LOAN TRACKER*\n` +
      `━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n`;

    const emiButtons = [];

    for (const emi of data.emis) {
      totalMonthly += emi.monthlyEmi;
      totalPendingDebt += emi.pendingAmount;
      totalPaidDebt += emi.paidAmount;

      const progressPercent = emi.totalAmount > 0 ? Math.round((emi.paidAmount / emi.totalAmount) * 100) : 0;

      reply += `📌 *${emi.title}*\n` +
        `• 💵 *Monthly EMI:* ₹${emi.monthlyEmi.toLocaleString("en-IN", { minimumFractionDigits: 2 })} / month\n` +
        `• ⏳ *Tenure Left:* *${emi.remainingMonths} months* (out of ${emi.totalMonths})\n` +
        `• 💰 *Total Pending:* ₹${emi.pendingAmount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `• 📊 *Progress:* ${progressPercent}% paid (₹${emi.paidAmount.toLocaleString("en-IN")} / ₹${emi.totalAmount.toLocaleString("en-IN")})\n\n`;

      if (!emi.isPaid) {
        emiButtons.push([
          Markup.button.callback(`✅ Pay ${emi.title} (₹${emi.monthlyEmi.toLocaleString("en-IN")})`, `pay_emi_${emi.title}`),
        ]);
      }
    }

    reply += `━━━━━━━━━━━━━━━━━━━━━━━━━━\n` +
      `💸 *Total Monthly EMI Burden:* *₹${totalMonthly.toLocaleString("en-IN", { minimumFractionDigits: 2 })} / month*\n` +
      `🏦 *Total Outstanding Debt:* *₹${totalPendingDebt.toLocaleString("en-IN", { minimumFractionDigits: 2 })}*\n\n` +
      `💡 _Tap any button below to record this month's payment:_`;

    emiButtons.push([
      Markup.button.callback("🏦 View Balance", "quick_balance"),
      Markup.button.callback("🎯 Scorecard", "quick_scorecard"),
    ]);

    await ctx.reply(reply, { parse_mode: "Markdown", ...Markup.inlineKeyboard(emiButtons) });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("emis", handleEmisQuery);
bot.hears("📑 Active EMIs", handleEmisQuery);

// ─── ACTION: 🤝 BORROW & LEND ──────────────────────────────────────────────
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
    }

    reply += `\n💡 _When someone repays, send:_ "${data.borrowLends[0]?.personName || "Person"} paid back ₹5,000"`;

    await ctx.reply(reply, { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("debts", handleDebtsQuery);
bot.hears("🤝 Borrow & Lend", handleDebtsQuery);

// ─── INLINE BUTTON CALLBACKS ────────────────────────────────────────────────
bot.action("quick_balance", async (ctx) => {
  await ctx.answerCbQuery();
  return handleBalanceQuery(ctx);
});

bot.action("quick_scorecard", async (ctx) => {
  await ctx.answerCbQuery();
  return handleDailyScorecard(ctx);
});

bot.action("quick_card", async (ctx) => {
  await ctx.answerCbQuery();
  return handleCardQuery(ctx);
});

bot.action("quick_emis", async (ctx) => {
  await ctx.answerCbQuery();
  return handleEmisQuery(ctx);
});

bot.action(/^pay_emi_(.+)$/, async (ctx) => {
  await ctx.answerCbQuery();
  const emiName = ctx.match[1];
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const res = await payEmi(userId, { emiName });
    const reply = `✅ *EMI Payment Recorded!*\n\n` +
      `📌 *Loan:* ${res.emiTitle}\n` +
      `💰 *Amount Deducted:* ₹${res.amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📅 *Tenure Progress:* ${res.paidMonths} months paid\n` +
      `⏳ *Remaining:* *${res.remainingMonths} months left*\n\n` +
      `_Deduction synced to your OrbitLife App in real time!_`;
    return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
  } catch (err) {
    return ctx.reply(`❌ *Payment Error:* ${err.message}`);
  }
});

// ─── PHOTO HANDLER ──────────────────────────────────────────────────────────
bot.on("photo", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your OrbitLife account first using `/link <USER_ID>`.");

  const statusMsg = await ctx.reply("🔍 *Analyzing photo with Gemini Vision AI...*", { parse_mode: "Markdown" });

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
        `🏪 *Store:* ${merchant || "Unknown"}\n` +
        `💰 *Total Amount:* ₹${expense.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `📁 *Category:* ${expense.categoryId}\n`;

      if (items && items.length > 0) {
        reply += `\n*Items Found:*\n` + items.slice(0, 5).map((i) => `• ${i.name} (₹${i.price || ""})`).join("\n");
      }

      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, reply, { parse_mode: "Markdown", ...postActionChips });
    } else if (analysis.type === "MEAL") {
      const { name, calories, protein, carbs, fat, mealType } = analysis.data;
      const meal = await logMeal(userId, {
        name: name || "Meal",
        calories: calories || 0,
        protein: protein || 0,
        carbs: carbs || 0,
        fat: fat || 0,
        mealType: mealType || "Meal",
      });

      const reply = `🥗 *Meal Analyzed & Logged!*\n\n` +
        `🍽️ *Dish:* ${meal.name}\n` +
        `🔥 *Calories:* ${meal.calories} kcal\n` +
        `🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`;

      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, reply, { parse_mode: "Markdown", ...postActionChips });
    } else {
      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, "📸 Image received, but could not detect a receipt or meal.", { parse_mode: "Markdown" });
    }
  } catch (err) {
    await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, `❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── NATURAL LANGUAGE TEXT MESSAGE HANDLER ──────────────────────────────────
bot.on("text", async (ctx) => {
  const text = ctx.message.text.trim();
  if (text.startsWith("/")) return;

  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please connect with `/link YOUR_USER_ID` first.", { parse_mode: "Markdown" });

  await ctx.sendChatAction("typing");

  try {
    const parsed = await parseTextMessage(text);

    // 1. ONBOARDING
    if (parsed.intent === "ONBOARDING") {
      const stats = await saveOnboardingProfile(userId, parsed.data);
      const reply = `🎉 *Financial Profile Setup Completed!*\n\n` +
        `🏦 *Bank/Cash Accounts Created:* ${stats.accountsCount}\n` +
        `💵 *Incomes Logged:* ${stats.incomesCount}\n` +
        `🔄 *Recurring Bills Configured:* ${stats.expensesCount}\n` +
        `📑 *Active EMIs Tracked:* ${stats.emisCount}\n` +
        `🤝 *Borrow/Lend Records:* ${stats.borrowLendsCount}\n` +
        `🎯 *Financial Goals Set:* ${stats.goalsCount}\n` +
        `💳 *Credit Card Linked:* ${stats.hasCreditCard ? "Yes ✅ (Supermoney)" : "None"}\n\n` +
        `✨ *All data is live in your OrbitLife App!*`;

      return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
    }

    // 2. MARK EMI PAID
    if (parsed.intent === "PAY_EMI") {
      const { emiName, amount, account } = parsed.data;
      const res = await payEmi(userId, { emiName: emiName || "EMI", amount, accountName: account });
      const reply = `✅ *EMI Payment Recorded!*\n\n` +
        `📌 *Loan:* ${res.emiTitle}\n` +
        `💰 *Amount Paid:* ₹${res.amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `📅 *Payments Made:* ${res.paidMonths} months\n` +
        `⏳ *Remaining Tenure:* ${res.remainingMonths} months left\n\n` +
        `_Deduction logged and synced to your app!_`;
      return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
    }

    // 3. DEBT REPAYMENT / SETTLEMENT OR NEW DEBT
    if (parsed.intent === "DEBT_UPDATE") {
      const res = await handleDebtUpdate(userId, parsed.data);
      if (res.isSettled !== undefined) {
        const reply = `🤝 *Debt Settlement Recorded!*\n\n` +
          `👤 *Person:* ${res.personName}\n` +
          `💰 *Amount Received/Paid:* ₹${res.amountSettled.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `📊 *Remaining Balance:* ₹${res.remainingDebt.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `✨ *Status:* ${res.isSettled ? "Fully Settled 🎉" : "Partially Paid"}`;
        return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
      } else {
        const reply = `🤝 *New ${res.type === "borrow" ? "Borrow" : "Lend"} Record Added!*\n\n` +
          `👤 *Person:* ${res.personName}\n` +
          `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `📌 *Type:* ${res.type === "borrow" ? "You Borrowed" : "You Lent"}`;
        return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
      }
    }

    // 4. PAY CREDIT CARD BILL
    if (parsed.intent === "PAY_CARD_BILL") {
      const { amount, account } = parsed.data;
      const res = await payCreditCardBill(userId, { amount, accountName: account });
      const reply = `💳 *Credit Card Bill Paid!*\n\n` +
        `💰 *Amount Paid:* ₹${res.amountPaid.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `🟢 *Available Credit Restored:* ₹${res.newAvailableCredit.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `🔴 *Remaining Used Credit:* ₹${res.newUsedCredit.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;
      return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
    }

    // 5. TRANSFER (Bank to Bank, ATM withdrawal, Cash in Hand)
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
      return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
    }

    // 6. ADD_ACCOUNT (e.g. Cash in Hand)
    if (parsed.intent === "ADD_ACCOUNT") {
      const { name, balance } = parsed.data;
      const res = await addAccount(userId, { name: name || "Cash in Hand", balance: balance || 0 });
      const reply = `🏦 *Account ${res.isNew ? "Created" : "Updated"}!*\n\n` +
        `📌 *Name:* ${res.name}\n` +
        `💰 *Balance:* ₹${res.balance.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
        `_Available for spends and bank transfers!_`;
      return ctx.reply(reply, { parse_mode: "Markdown", ...postActionChips });
    }

    // 5. EXPENSE
    if (parsed.intent === "EXPENSE") {
      const exp = await logExpense(userId, {
        amount: parsed.data.amount,
        description: parsed.data.description || "Expense",
        category: parsed.data.category || "General",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
        source: "telegram_text",
      });
      return ctx.reply(`💸 *Expense Logged!*\n\n📝 *Item:* ${exp.description}\n💰 *Amount:* ₹${exp.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n📁 *Category:* ${exp.categoryId}\n💳 *Account:* ${exp.accountId}`, { parse_mode: "Markdown", ...postActionChips });
    }

    // 6. INCOME
    if (parsed.intent === "INCOME") {
      const inc = await logIncome(userId, {
        amount: parsed.data.amount,
        source: parsed.data.source || "Income",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
      });
      return ctx.reply(`🟢 *Income Logged!*\n\n💵 *Source:* ${inc.source}\n💰 *Amount:* ₹${inc.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown", ...postActionChips });
    }

    // 7. MEAL
    if (parsed.intent === "MEAL") {
      const meal = await logMeal(userId, parsed.data);
      return ctx.reply(`🥗 *Meal Logged!*\n\n🍽️ *Food:* ${meal.name}\n🔥 *Calories:* ${meal.calories} kcal\n🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`, { parse_mode: "Markdown", ...postActionChips });
    }

    // 8. MILEAGE
    if (parsed.intent === "MILEAGE") {
      const entry = await logMileage(userId, parsed.data);
      return ctx.reply(`⛽ *Mileage Logged!*\n\n🚗 *Odometer:* ${entry.odometer} km\n🛢️ *Fuel:* ${entry.liters} L\n💰 *Cost:* ₹${entry.totalCost.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown", ...postActionChips });
    }

    // 9. QUERY ROUTING
    if (parsed.intent === "QUERY") {
      const type = parsed.data?.queryType;
      if (type === "balance") return handleBalanceQuery(ctx);
      if (type === "card") return handleCardQuery(ctx);
      if (type === "emis") return handleEmisQuery(ctx);
      if (type === "debts") return handleDebtsQuery(ctx);
      return handleDailyScorecard(ctx);
    }

    return ctx.reply("🤖 I received your message. Tap *🎯 Daily Scorecard* or *🏦 Live Balances* below!", { parse_mode: "Markdown", ...mainMenu });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown", ...mainMenu });
  }
});

// ─── MINI APP WEB DASHBOARD (HTML RESPONSE) ─────────────────────────────────
const WEB_DASHBOARD_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>OrbitLife Live Dashboard</title>
  <script src="https://telegram.org/js/telegram-web-app.js"></script>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0b0f19;
      --card-bg: rgba(255, 255, 255, 0.04);
      --card-border: rgba(255, 255, 255, 0.08);
      --primary: #3b82f6;
      --accent: #10b981;
      --warning: #f59e0b;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
    body { background: var(--bg); color: var(--text); padding: 16px; min-height: 100vh; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    .logo { font-size: 22px; font-weight: 800; background: linear-gradient(135deg, #60a5fa, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .badge { background: rgba(16, 185, 129, 0.15); color: #10b981; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; border: 1px solid rgba(16, 185, 129, 0.3); }
    .card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 20px; padding: 18px; margin-bottom: 16px; backdrop-filter: blur(16px); }
    .title { font-size: 13px; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; font-weight: 600; }
    .amount { font-size: 28px; font-weight: 800; color: #fff; margin-bottom: 12px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
    .metric { background: rgba(255, 255, 255, 0.02); padding: 12px; border-radius: 14px; border: 1px solid rgba(255, 255, 255, 0.05); }
    .metric-val { font-size: 18px; font-weight: 700; color: #fff; margin-top: 4px; }
    .progress-bg { height: 8px; background: rgba(255, 255, 255, 0.1); border-radius: 10px; overflow: hidden; margin-top: 10px; }
    .progress-fill { height: 100%; border-radius: 10px; transition: width 0.5s ease; }
    .btn { display: block; width: 100%; background: linear-gradient(135deg, #2563eb, #1d4ed8); color: #fff; text-align: center; padding: 14px; border-radius: 16px; text-decoration: none; font-weight: 700; border: none; font-size: 15px; cursor: pointer; margin-top: 10px; box-shadow: 0 4px 20px rgba(37, 99, 235, 0.3); }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">⚡ OrbitLife</div>
    <div class="badge">● LIVE SYNC</div>
  </div>

  <div class="card" style="background: linear-gradient(135deg, rgba(30, 58, 138, 0.3), rgba(15, 23, 42, 0.6)); border-color: rgba(96, 165, 250, 0.2);">
    <div class="title">Safe Daily Spending Limit</div>
    <div class="amount" id="dailyLimit">₹700<span style="font-size: 14px; color: var(--text-muted); font-weight: 500;"> / day</span></div>
    <div class="progress-bg"><div class="progress-fill" style="width: 15%; background: #10b981;"></div></div>
    <div style="display: flex; justify-content: space-between; font-size: 12px; color: var(--text-muted); margin-top: 6px;">
      <span>Spent Today: ₹0</span>
      <span>Safe Left: ₹700</span>
    </div>
  </div>

  <div class="card">
    <div class="title">💳 Supermoney Secured Credit Card</div>
    <div class="amount" id="cardAvail">₹16,713.80<span style="font-size: 14px; color: #10b981; font-weight: 600;"> Available</span></div>
    <div class="grid">
      <div class="metric">
        <div class="title">Used Credit</div>
        <div class="metric-val" style="color: #f59e0b;">₹10,000</div>
      </div>
      <div class="metric">
        <div class="title">Total Limit</div>
        <div class="metric-val">₹26,713.80</div>
      </div>
    </div>
    <div class="progress-bg"><div class="progress-fill" style="width: 37.4%; background: #f59e0b;"></div></div>
    <div style="font-size: 12px; color: var(--text-muted); margin-top: 8px; text-align: right;">37.4% Utilization • Statement on 1st</div>
  </div>

  <div class="card">
    <div class="title">🏦 Liquid Balances</div>
    <div class="grid">
      <div class="metric"><div class="title">HDFC Bank</div><div class="metric-val">₹1,044.69</div></div>
      <div class="metric"><div class="title">SBI Bank</div><div class="metric-val">₹16.31</div></div>
    </div>
  </div>

  <button class="btn" onclick="window.Telegram.WebApp.close()">Done & Return to Chat</button>

  <script>
    if (window.Telegram && window.Telegram.WebApp) {
      window.Telegram.WebApp.ready();
      window.Telegram.WebApp.expand();
    }
  </script>
</body>
</html>`;

// Vercel Serverless Function Handler
module.exports = async (req, res) => {
  if (req.method === "POST") {
    try {
      await bot.handleUpdate(req.body);
      return res.status(200).send("OK");
    } catch (err) {
      console.error("Webhook processing error:", err);
      return res.status(500).send("Error");
    }
  }
  // If user opens the Web App in browser/Telegram Mini App:
  res.setHeader("Content-Type", "text/html");
  return res.status(200).send(WEB_DASHBOARD_HTML);
};
