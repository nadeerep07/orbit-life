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
  saveOnboardingProfile,
  getSummary,
} = require("../services/firebase");

const { parseTextMessage, analyzeImage } = require("../services/ai");

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
initializeFirebase();

const bot = new Telegraf(BOT_TOKEN);

// Handlers
bot.start(async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  let message = `👋 *Welcome to OrbitLife Automation Bot!*\n\n` +
    `I am your personal AI financial and health manager (Default: ₹ INR). You can talk to me naturally, send receipt photos, or log meals on the go.\n\n`;

  if (userId) {
    message += `✅ *Status:* Connected to User \`${userId.substring(0, 8)}...\`\n\n` +
      `Try sending:\n` +
      `• _"Spent ₹450 on dinner with UPI"_\n` +
      `• _"Got ₹75,000 salary from employer"_\n` +
      `• _"Ate 2 dosas with sambar and filter coffee"_\n` +
      `• _"Fuel 25L cost ₹2,600 at 45,000 km"_\n` +
      `• _Send /onboard to set up your entire financial profile at once!_\n` +
      `• Or *snap a photo* of a receipt or your meal! 📸`;
  } else {
    message += `⚠️ *Account Not Linked Yet!*\n\n` +
      `To connect your account, send:\n` +
      `\`/link YOUR_FIREBASE_USER_ID\``;
  }

  await ctx.reply(message, { parse_mode: "Markdown" });
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
    await ctx.reply(`🎉 *Success! Your Telegram is now linked to OrbitLife.*\n\nUser ID: \`${userId}\`\n\nYou can now log expenses, meals, or send your full profile details to set up everything! 🚀`, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ *Failed to link account:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

bot.command("onboard", async (ctx) => {
  const msg = `🚀 *OrbitLife Fast Onboarding Setup (in ₹ INR)*\n\n` +
    `You can set up your entire financial profile in one message! Just send a text or voice note with your details:\n\n` +
    `*Example:*\n` +
    `_"My monthly salary is ₹85,000 on the 1st. Bank accounts: HDFC Bank with ₹45,000 balance, SBI with ₹15,000, and Cash ₹5,000. Credit Card: ICICI with ₹1,50,000 limit. Recurring bills: Rent ₹18,000, Electricity ₹2,500, Wi-Fi ₹999, Gym ₹2,000. Active EMI: Car loan ₹12,500/month (24 months left). Goals: Emergency Fund ₹3,00,000."_\n\n` +
    `👉 *Send your financial details now and AI will set up your entire profile!*`;

  await ctx.reply(msg, { parse_mode: "Markdown" });
});

bot.command("today", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your account first with `/link <USER_ID>`.");

  try {
    const summary = await getSummary(userId);
    if (!summary) return ctx.reply("ℹ️ No data found for today.");

    const caloriePercent = Math.round((summary.todayCalories / (summary.calorieTarget || 2000)) * 100);
    const msg = `📅 *Today's OrbitLife Summary*\n\n` +
      `💸 *Expenses Today:* ₹${summary.todaySpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })} (${summary.todayExpensesCount} entries)\n` +
      `💰 *Month Spend:* ₹${summary.monthSpent.toLocaleString("en-IN", { minimumFractionDigits: 2 })} | *Earned:* ₹${summary.monthEarned.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n` +
      `📈 *Month Net Flow:* ₹${summary.monthNet.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n\n` +
      `🥗 *Nutrition Today:*\n` +
      `• Calories: *${summary.todayCalories}* / ${summary.calorieTarget} kcal (${caloriePercent}%)\n` +
      `• Protein: *${summary.todayProtein.toFixed(1)}g* | Carbs: *${summary.todayCarbs.toFixed(1)}g* | Fat: *${summary.todayFat.toFixed(1)}g*`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply("❌ Error fetching summary.");
  }
});

bot.on("photo", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your account first with `/link <USER_ID>`.");

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

bot.on("text", async (ctx) => {
  const text = ctx.message.text.trim();
  if (text.startsWith("/")) return;

  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please connect with `/link YOUR_USER_ID` first.", { parse_mode: "Markdown" });

  await ctx.sendChatAction("typing");

  try {
    const parsed = await parseTextMessage(text);

    if (parsed.intent === "ONBOARDING") {
      const stats = await saveOnboardingProfile(userId, parsed.data);
      let reply = `🎉 *Financial Profile Setup Completed!*\n\n` +
        `🏦 *Bank/Cash Accounts Created:* ${stats.accountsCount}\n` +
        `💵 *Incomes Logged:* ${stats.incomesCount}\n` +
        `🔄 *Recurring Bills Configured:* ${stats.expensesCount}\n` +
        `📑 *Active EMIs Tracked:* ${stats.emisCount}\n` +
        `🎯 *Financial Goals Set:* ${stats.goalsCount}\n` +
        `💳 *Credit Card Linked:* ${stats.hasCreditCard ? "Yes ✅" : "None"}\n\n` +
        `✨ *All data has been synced to your OrbitLife App!* Open your app to see your live dashboard.`;

      return ctx.reply(reply, { parse_mode: "Markdown" });
    }

    if (parsed.intent === "EXPENSE") {
      const exp = await logExpense(userId, {
        amount: parsed.data.amount,
        description: parsed.data.description || "Expense",
        category: parsed.data.category || "General",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
        source: "telegram_text",
      });
      return ctx.reply(`💸 *Expense Logged!*\n\n📝 *Item:* ${exp.description}\n💰 *Amount:* ₹${exp.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}\n📁 *Category:* ${exp.categoryId}`, { parse_mode: "Markdown" });
    }

    if (parsed.intent === "INCOME") {
      const inc = await logIncome(userId, {
        amount: parsed.data.amount,
        source: parsed.data.source || "Income",
        account: parsed.data.account || "Default",
        date: parsed.data.date,
      });
      return ctx.reply(`🟢 *Income Logged!*\n\n💵 *Source:* ${inc.source}\n💰 *Amount:* ₹${inc.amount.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown" });
    }

    if (parsed.intent === "MEAL") {
      const meal = await logMeal(userId, parsed.data);
      return ctx.reply(`🥗 *Meal Logged!*\n\n🍽️ *Food:* ${meal.name}\n🔥 *Calories:* ${meal.calories} kcal\n🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g`, { parse_mode: "Markdown" });
    }

    if (parsed.intent === "MILEAGE") {
      const entry = await logMileage(userId, parsed.data);
      return ctx.reply(`⛽ *Mileage Logged!*\n\n🚗 *Odometer:* ${entry.odometer} km\n🛢️ *Fuel:* ${entry.liters} L\n💰 *Cost:* ₹${entry.totalCost.toLocaleString("en-IN", { minimumFractionDigits: 2 })}`, { parse_mode: "Markdown" });
    }

    return ctx.reply("🤖 I received your message. Send `/onboard` to set up your profile or `/help` for examples!", { parse_mode: "Markdown" });
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
  return res.status(200).send("OrbitLife Telegram Bot Webhook is ACTIVE 🚀");
};
