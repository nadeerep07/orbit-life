const { Telegraf } = require("telegraf");
const axios = require("axios");
const dotenv = require("dotenv");
dotenv.config();

const {
  initializeFirebase,
  getUserIdByChatId,
  linkUserChatId,
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
} = require("../services/firebase");

const { parseTextMessage, analyzeImage } = require("../services/ai");

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
initializeFirebase();

const bot = new Telegraf(BOT_TOKEN);

// ─── COMMANDS ───────────────────────────────────────────────────────────────

bot.start(async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  let msg = `👋 *Welcome to OrbitLife Full Automation Bot!*\n\n` +
    `Every feature of your financial dashboard can now be automated directly from Telegram (₹ INR):\n\n`;

  if (userId) {
    msg += `✅ *Connected to App:* \`${userId.substring(0, 8)}...\`\n\n` +
      `⚡ *Try Any of These Commands / Natural Texts:*\n` +
      `• *Log Expenses:* _"Spent ₹350 on lunch with UPI"_\n` +
      `• *Credit Card Spends:* _"Spent ₹1,200 on Supermoney card"_\n` +
      `• *Log Salary:* _"Received ₹29,600 salary"_\n` +
      `• *Mark EMI Paid:* _"Paid College EMI ₹3,750"_ or _/emis_\n` +
      `• *Debt Repayment:* _"Shamveel paid back ₹5,000"_ or _/debts_\n` +
      `• *Pay Card Bill:* _"Paid ₹10,000 credit card bill"_\n` +
      `• *Check Balances:* _/balance_\n` +
      `• *Card & FD Limits:* _/card_\n` +
      `• *Daily Analytics:* _/today_ or _/stats_\n` +
      `• *Log Food:* _"Ate 2 chapatis & dal"_ (or snap a photo! 📸)`;
  } else {
    msg += `⚠️ *Account Not Linked!*\n\nSend: \`/link YOUR_FIREBASE_USER_ID\``;
  }

  await ctx.reply(msg, { parse_mode: "Markdown" });
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
    await ctx.reply(`🎉 *Success! Linked to OrbitLife.*\n\nUser ID: \`${userId}\`\n\nYou can now manage expenses, EMIs, debts, and balances directly! 🚀`, { parse_mode: "Markdown" });
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
    await ctx.reply(`👤 *Current Connected Account:*\n\nUser ID: \`${userId}\`\n\nTo switch accounts, send:\n\`/link <NEW_USER_ID>\`\nOr to disconnect, send:\n\`/unlink\``, { parse_mode: "Markdown" });
  } else {
    await ctx.reply("⚠️ No account is currently linked.\n\nSend `/link <USER_ID>` to connect.", { parse_mode: "Markdown" });
  }
});

// ─── COMMAND: /balance ───────────────────────────────────────────────────────
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
      reply += `💳 *Credit Card Debt:* -₹${data.creditCard.used.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n`;
    }

    reply += `\n🌟 *Net Liquid Worth:* ₹${data.netWorth.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("balance", handleBalanceQuery);

// ─── COMMAND: /card ─────────────────────────────────────────────────────────
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

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("card", handleCardQuery);

// ─── COMMAND: /emis ─────────────────────────────────────────────────────────
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
    let reply = `📑 *Active EMIs & Loans*\n\n`;

    for (const emi of data.emis) {
      totalMonthly += emi.monthlyEmi;
      reply += `📌 *${emi.title}*\n` +
        `• Monthly EMI: ₹${emi.monthlyEmi.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
        `• Remaining Months: ${emi.remainingMonths}\n\n`;
    }

    reply += `💸 *Total Monthly EMI Burden:* ₹${totalMonthly.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `💡 _To mark an EMI paid, send:_ "Paid ${data.emis[0]?.title || "EMI"}"`;

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("emis", handleEmisQuery);

// ─── COMMAND: /debts ────────────────────────────────────────────────────────
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

    await ctx.reply(reply, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("debts", handleDebtsQuery);

// ─── COMMAND: /today & /stats ───────────────────────────────────────────────
async function handleStatsQuery(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Link account first.");

  try {
    const summary = await getSummary(userId);
    if (!summary) return ctx.reply("ℹ️ No data available.");

    const caloriePercent = Math.round((summary.todayCalories / (summary.calorieTarget || 2000)) * 100);
    const msg = `📊 *OrbitLife Monthly & Daily Analytics*\n\n` +
      `💸 *Spent Today:* ₹${summary.todaySpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })} (${summary.todayExpensesCount} entries)\n` +
      `📈 *Month Inflow:* ₹${summary.monthEarned.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📉 *Month Outflow:* ₹${summary.monthSpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `💼 *Net Monthly Surplus:* ₹${summary.monthNet.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `🥗 *Nutrition Today:*\n` +
      `• Calories: *${summary.todayCalories}* / ${summary.calorieTarget} kcal (${caloriePercent}%)\n` +
      `• Protein: *${summary.todayProtein.toFixed(1)}g* | Carbs: *${summary.todayCarbs.toFixed(1)}g* | Fat: *${summary.todayFat.toFixed(1)}g*`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Error: ${err.message}`);
  }
}
bot.command("today", handleStatsQuery);
bot.command("stats", handleStatsQuery);
bot.command("analytics", handleStatsQuery);

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

      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, reply, { parse_mode: "Markdown" });
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

      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, reply, { parse_mode: "Markdown" });
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

      return ctx.reply(reply, { parse_mode: "Markdown" });
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
      return ctx.reply(reply, { parse_mode: "Markdown" });
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
        return ctx.reply(reply, { parse_mode: "Markdown" });
      } else {
        const reply = `🤝 *New ${res.type === "borrow" ? "Borrow" : "Lend"} Record Added!*\n\n` +
          `👤 *Person:* ${res.personName}\n` +
          `💰 *Amount:* ₹${res.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
          `📌 *Type:* ${res.type === "borrow" ? "You Borrowed" : "You Lent"}`;
        return ctx.reply(reply, { parse_mode: "Markdown" });
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
      return ctx.reply(reply, { parse_mode: "Markdown" });
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
      return ctx.reply(`💸 *Expense Logged!*\n\n📝 *Item:* ${exp.description}\n💰 *Amount:* ₹${exp.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n📁 *Category:* ${exp.categoryId}\n💳 *Account:* ${exp.accountId}`, { parse_mode: "Markdown" });
    }

    // 6. INCOME
    if (parsed.intent === "INCOME") {
      const inc = await logIncome(userId, {
        amount: parsed.data.amount,
        source: parsed.data.source || "Income",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
      });
      return ctx.reply(`🟢 *Income Logged!*\n\n💵 *Source:* ${inc.source}\n💰 *Amount:* ₹${inc.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown" });
    }

    // 7. MEAL
    if (parsed.intent === "MEAL") {
      const meal = await logMeal(userId, parsed.data);
      return ctx.reply(`🥗 *Meal Logged!*\n\n🍽️ *Food:* ${meal.name}\n🔥 *Calories:* ${meal.calories} kcal\n🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`, { parse_mode: "Markdown" });
    }

    // 8. MILEAGE
    if (parsed.intent === "MILEAGE") {
      const entry = await logMileage(userId, parsed.data);
      return ctx.reply(`⛽ *Mileage Logged!*\n\n🚗 *Odometer:* ${entry.odometer} km\n🛢️ *Fuel:* ${entry.liters} L\n💰 *Cost:* ₹${entry.totalCost.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown" });
    }

    // 9. QUERY ROUTING
    if (parsed.intent === "QUERY") {
      const type = parsed.data?.queryType;
      if (type === "balance") return handleBalanceQuery(ctx);
      if (type === "card") return handleCardQuery(ctx);
      if (type === "emis") return handleEmisQuery(ctx);
      if (type === "debts") return handleDebtsQuery(ctx);
      return handleStatsQuery(ctx);
    }

    return ctx.reply("🤖 I received your message. Send `/help` for examples or check `/balance`!", { parse_mode: "Markdown" });
  } catch (err) {
    return ctx.reply(`❌ *Error:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

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
  return res.status(200).send("OrbitLife Full Automation Bot Webhook is ACTIVE 🚀");
};
