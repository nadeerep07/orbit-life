const { Telegraf, Markup } = require("telegraf");
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
  getSummary,
} = require("./services/firebase");

const { parseTextMessage, analyzeImage } = require("./services/ai");

// Check token
const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
if (!BOT_TOKEN) {
  console.error("❌ TELEGRAM_BOT_TOKEN is missing in environment variables or .env file!");
  process.exit(1);
}

// Initialize Firebase
initializeFirebase();

// Initialize Telegraf Bot
const bot = new Telegraf(BOT_TOKEN);

// Main Keyboard Menu
const mainMenu = Markup.keyboard([
  ["📊 Today's Summary", "📈 Month Overview"],
  ["🍽️ Log Quick Meal", "⛽ Log Fuel/Mileage"],
  ["❓ Help & Cheatsheet", "⚙️ Account Status"],
]).resize();

// ─── COMMAND: /start ────────────────────────────────────────────────────────
bot.start(async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  let message = `👋 *Welcome to OrbitLife Automation Bot!*\n\n` +
    `I am your personal AI financial and health manager. You can talk to me naturally, send receipt photos, or log meals on the go.\n\n`;

  if (userId) {
    message += `✅ *Status:* Connected to User \`${userId.substring(0, 8)}...\`\n\n` +
      `Try sending:\n` +
      `• _"Spent 45 AED on lunch with card"_\n` +
      `• _"Got 5000 salary"_\n` +
      `• _"Ate 2 eggs, avocado toast & black coffee"_\n` +
      `• _"Fuel 40L cost 110 at 58,000 km"_\n` +
      `• Or *snap a photo* of a receipt or your meal! 📸`;
  } else {
    message += `⚠️ *Account Not Linked Yet!*\n\n` +
      `To connect your OrbitLife / MyBudgetPro account, use:\n` +
      `\`/link YOUR_FIREBASE_USER_ID\`\n\n` +
      `💡 *Where to find your User ID:*\n` +
      `Open your app -> Settings -> Account / Backup -> Copy User ID.`;
  }

  await ctx.reply(message, {
    parse_mode: "Markdown",
    ...mainMenu,
  });
});

// ─── COMMAND: /link <userId> ────────────────────────────────────────────────
bot.command("link", async (ctx) => {
  const chatId = ctx.chat.id;
  const args = ctx.message.text.split(" ").slice(1);
  const userId = args[0]?.trim();

  if (!userId) {
    return ctx.reply(
      "❌ *Please provide your Firebase User ID.*\n\nExample:\n`/link abc123XYZ456`\n\nYou can find your ID in the app's Settings screen.",
      { parse_mode: "Markdown" }
    );
  }

  try {
    await linkUserChatId(userId, chatId);
    await ctx.reply(
      `🎉 *Success! Your Telegram is now linked to OrbitLife.*\n\nUser ID: \`${userId}\`\n\nAll your messages, receipts, and meal photos will automatically sync to your app! 🚀`,
      { parse_mode: "Markdown", ...mainMenu }
    );
  } catch (err) {
    console.error("Link error:", err);
    await ctx.reply(`❌ *Failed to link account:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// ─── COMMAND: /status ───────────────────────────────────────────────────────
bot.command("status", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  if (!userId) {
    return ctx.reply("⚠️ No OrbitLife account is linked to this Telegram chat. Use `/link <USER_ID>`.", {
      parse_mode: "Markdown",
    });
  }

  const userData = await getUserData(userId);
  const expenseCount = (userData?.expenses || []).length;
  const incomeCount = (userData?.incomes || []).length;
  const mealCount = (userData?.mealEntries || []).length;

  const msg = `📱 *OrbitLife Connection Status*\n\n` +
    `👤 *User ID:* \`${userId}\`\n` +
    `💬 *Telegram Chat ID:* \`${chatId}\`\n` +
    `📊 *Synced Records:*\n` +
    `• Expenses: ${expenseCount}\n` +
    `• Incomes: ${incomeCount}\n` +
    `• Meal Logs: ${mealCount}\n` +
    `☁️ *Firestore Sync:* Active 🟢`;

  await ctx.reply(msg, { parse_mode: "Markdown" });
});

// ─── COMMAND: /today & Button Handler ───────────────────────────────────────
async function handleTodaySummary(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  if (!userId) {
    return ctx.reply("⚠️ Please link your account first with `/link <USER_ID>`.");
  }

  await ctx.sendChatAction("typing");
  try {
    const summary = await getSummary(userId);
    if (!summary) {
      return ctx.reply("ℹ️ No data found for your account yet.");
    }

    const caloriePercent = Math.round((summary.todayCalories / (summary.calorieTarget || 2000)) * 100);

    const msg = `📅 *Today's OrbitLife Summary*\n\n` +
      `💸 *Expenses Today:* AED ${summary.todaySpent.toFixed(2)} (${summary.todayExpensesCount} entries)\n` +
      `💰 *Month Spend:* AED ${summary.monthSpent.toFixed(2)} | *Earned:* AED ${summary.monthEarned.toFixed(2)}\n` +
      `📈 *Month Net Cash Flow:* AED ${summary.monthNet.toFixed(2)}\n\n` +
      `🥗 *Nutrition Today:*\n` +
      `• Calories: *${summary.todayCalories}* / ${summary.calorieTarget} kcal (${caloriePercent}%)\n` +
      `• Protein: *${summary.todayProtein.toFixed(1)}g* | Carbs: *${summary.todayCarbs.toFixed(1)}g* | Fat: *${summary.todayFat.toFixed(1)}g*\n` +
      `• Meals Logged: *${summary.todayMealsCount}*`;

    await ctx.reply(msg, { parse_mode: "Markdown" });
  } catch (err) {
    console.error("Summary error:", err);
    await ctx.reply("❌ Error fetching summary. Please try again.");
  }
}

bot.command("today", handleTodaySummary);
bot.hears("📊 Today's Summary", handleTodaySummary);

// ─── COMMAND: /month & Button Handler ───────────────────────────────────────
async function handleMonthOverview(ctx) {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);
  if (!userId) return ctx.reply("⚠️ Please link your account first with `/link <USER_ID>`.");

  const summary = await getSummary(userId);
  if (!summary) return ctx.reply("ℹ️ No data available.");

  const msg = `📈 *Month Financial Overview*\n\n` +
    `🟢 Total Inflow: *AED ${summary.monthEarned.toFixed(2)}*\n` +
    `🔴 Total Outflow: *AED ${summary.monthSpent.toFixed(2)}*\n` +
    `💼 Net Balance: *AED ${summary.monthNet.toFixed(2)}*\n\n` +
    `_Keep tracking your expenses to stay within your monthly targets!_`;

  await ctx.reply(msg, { parse_mode: "Markdown" });
}

bot.command("month", handleMonthOverview);
bot.hears("📈 Month Overview", handleMonthOverview);

// ─── COMMAND: /help & Button Handler ────────────────────────────────────────
bot.command("help", async (ctx) => {
  const msg = `💡 *OrbitLife Telegram Bot Cheatsheet*\n\n` +
    `*1. Log Expenses Naturally:*\n` +
    `• _"Spent 25 on coffee at Starbucks with card"_\n` +
    `• _"50 groceries cash"_\n` +
    `• _"Paid 120 DEWA electricity bill"_\n\n` +
    `*2. Log Incomes:*\n` +
    `• _"Received 8500 salary"_\n` +
    `• _"Freelance project payment 1200"_\n\n` +
    `*3. Log Meals & Nutrition:*\n` +
    `• _"Ate 200g chicken breast, brown rice and avocado"_\n` +
    `• _"Breakfast: 2 boiled eggs and black coffee"_\n` +
    `• *Or send a photo of your food!* 🥗\n\n` +
    `*4. Log Fuel / Vehicle Mileage:*\n` +
    `• _"Fuel 45L for 115 AED at 65400 km"_\n\n` +
    `*5. Scan Receipts:*\n` +
    `• Send any receipt or invoice photo. The AI will extract the items and amount automatically! 🧾\n\n` +
    `*Commands:*\n` +
    `/today - View today's spending & calories\n` +
    `/month - View monthly financial overview\n` +
    `/status - Check account connection\n` +
    `/link <id> - Link your Firebase User ID`;

  await ctx.reply(msg, { parse_mode: "Markdown" });
});

bot.hears("❓ Help & Cheatsheet", (ctx) => ctx.replyWithMarkdown("💡 Check `/help` for detailed examples!"));
bot.hears("⚙️ Account Status", (ctx) => ctx.telegram.sendMessage(ctx.chat.id, "/status"));
bot.hears("🍽️ Log Quick Meal", (ctx) => ctx.reply("📸 *Snap a food picture* or type what you ate (e.g., _'Grilled salmon with quinoa'_).", { parse_mode: "Markdown" }));
bot.hears("⛽ Log Fuel/Mileage", (ctx) => ctx.reply("⛽ Type your fuel details (e.g., _'Fuel 40L cost 100 at 45000 km'_).", { parse_mode: "Markdown" }));

// ─── PHOTO HANDLER (RECEIPT OCR & MEAL RECOGNITION) ─────────────────────────
bot.on("photo", async (ctx) => {
  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  if (!userId) {
    return ctx.reply("⚠️ Please link your OrbitLife account first using `/link <USER_ID>`.");
  }

  await ctx.sendChatAction("upload_photo");
  const statusMsg = await ctx.reply("🔍 *Analyzing photo with Gemini Vision AI...*", { parse_mode: "Markdown" });

  try {
    // Get highest resolution photo URL
    const photos = ctx.message.photo;
    const bestPhoto = photos[photos.length - 1];
    const fileLink = await ctx.telegram.getFileLink(bestPhoto.file_id);
    const caption = ctx.message.caption || "";

    // Download image buffer
    const response = await axios.get(fileLink.href, { responseType: "arraybuffer" });
    const imageBuffer = Buffer.from(response.data);

    // Run Vision AI
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
        `💰 *Total Amount:* AED ${expense.amount.toFixed(2)}\n` +
        `📁 *Category:* ${expense.categoryId}\n` +
        `📅 *Date:* ${expense.date.substring(0, 10)}\n`;

      if (items && items.length > 0) {
        reply += `\n*Items Found:*\n` + items.slice(0, 5).map((i) => `• ${i.name} (${i.price || ""})`).join("\n");
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
        `🥩 *Protein:* ${meal.protein}g\n` +
        `🍚 *Carbs:* ${meal.carbs}g\n` +
        `🥑 *Fat:* ${meal.fat}g\n` +
        `🕒 *Type:* ${meal.mealType}`;

      await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, reply, { parse_mode: "Markdown" });
    } else {
      await ctx.telegram.editMessageText(
        chatId,
        statusMsg.message_id,
        null,
        `📸 *Image Received*\n\n${analysis.summary || "Could not detect a receipt or meal. Please provide a clearer photo."}`,
        { parse_mode: "Markdown" }
      );
    }
  } catch (err) {
    console.error("Photo processing error:", err);
    await ctx.telegram.editMessageText(chatId, statusMsg.message_id, null, `❌ *Error analyzing image:* ${err.message}`, {
      parse_mode: "Markdown",
    });
  }
});

// ─── NATURAL LANGUAGE TEXT MESSAGE HANDLER ──────────────────────────────────
bot.on("text", async (ctx) => {
  const text = ctx.message.text.trim();
  if (text.startsWith("/")) return; // Ignore unhandled slash commands

  const chatId = ctx.chat.id;
  const userId = await getUserIdByChatId(chatId);

  if (!userId) {
    return ctx.reply(
      "⚠️ *Account Not Linked!*\n\nPlease connect your account first using:\n`/link YOUR_USER_ID`",
      { parse_mode: "Markdown" }
    );
  }

  await ctx.sendChatAction("typing");

  try {
    const parsed = await parseTextMessage(text);

    switch (parsed.intent) {
      case "EXPENSE": {
        const { amount, description, category, account, date } = parsed.data;
        if (!amount) {
          return ctx.reply("⚠️ Could not detect the expense amount. Please mention a number (e.g. *'Spent 45 on food'*).", { parse_mode: "Markdown" });
        }

        const exp = await logExpense(userId, {
          amount,
          description: description || "Expense",
          category: category || "General",
          account: account || "Default",
          date: date || new Date().toISOString().split("T")[0],
          source: "telegram_text",
        });

        const reply = `💸 *Expense Logged!*\n\n` +
          `📝 *Item:* ${exp.description}\n` +
          `💰 *Amount:* AED ${exp.amount.toFixed(2)}\n` +
          `📁 *Category:* ${exp.categoryId}\n` +
          `💳 *Account:* ${exp.accountId}\n` +
          `📅 *Date:* ${exp.date.substring(0, 10)}`;

        return ctx.reply(reply, { parse_mode: "Markdown" });
      }

      case "INCOME": {
        const { amount, source, account, date } = parsed.data;
        if (!amount) {
          return ctx.reply("⚠️ Could not detect income amount. Example: *'Received 5000 salary'*.", { parse_mode: "Markdown" });
        }

        const inc = await logIncome(userId, {
          amount,
          source: source || "Income",
          account: account || "Default",
          date: date || new Date().toISOString().split("T")[0],
        });

        const reply = `🟢 *Income Logged!*\n\n` +
          `💵 *Source:* ${inc.source}\n` +
          `💰 *Amount:* AED ${inc.amount.toFixed(2)}\n` +
          `💳 *Account:* ${inc.accountId}\n` +
          `📅 *Date:* ${inc.date.substring(0, 10)}`;

        return ctx.reply(reply, { parse_mode: "Markdown" });
      }

      case "MEAL": {
        const { name, calories, protein, carbs, fat, mealType } = parsed.data;
        const meal = await logMeal(userId, {
          name: name || "Meal",
          calories: calories || 0,
          protein: protein || 0,
          carbs: carbs || 0,
          fat: fat || 0,
          mealType: mealType || "Meal",
        });

        const reply = `🥗 *Meal Logged!*\n\n` +
          `🍽️ *Food:* ${meal.name}\n` +
          `🔥 *Calories:* ${meal.calories} kcal\n` +
          `🥩 *Protein:* ${meal.protein}g | 🍚 *Carbs:* ${meal.carbs}g | 🥑 *Fat:* ${meal.fat}g\n` +
          `🕒 *Type:* ${meal.mealType}`;

        return ctx.reply(reply, { parse_mode: "Markdown" });
      }

      case "MILEAGE": {
        const { odometer, liters, totalCost, pricePerLiter, notes } = parsed.data;
        const entry = await logMileage(userId, {
          odometer,
          liters,
          totalCost,
          pricePerLiter,
          notes,
        });

        const reply = `⛽ *Mileage / Fuel Logged!*\n\n` +
          `🚗 *Odometer:* ${entry.odometer} km\n` +
          `🛢️ *Fuel:* ${entry.liters} L\n` +
          `💰 *Cost:* AED ${entry.totalCost.toFixed(2)}`;

        return ctx.reply(reply, { parse_mode: "Markdown" });
      }

      case "QUERY": {
        // Run summary or handle query
        return handleTodaySummary(ctx);
      }

      default: {
        return ctx.reply(
          `🤖 *I couldn't quite understand that.*\n\n` +
          `Try sending something like:\n` +
          `• _"Spent 50 on dinner"_ (Expense)\n` +
          `• _"Salary 7000"_ (Income)\n` +
          `• _"Ate grilled chicken salad"_ (Meal)\n` +
          `• _"Fuel 35L for 95 AED at 65000 km"_ (Mileage)\n` +
          `• Or send a photo of a receipt or food dish!`,
          { parse_mode: "Markdown" }
        );
      }
    }
  } catch (err) {
    console.error("NLP message error:", err);
    return ctx.reply(`❌ *Error processing message:* ${err.message}`, { parse_mode: "Markdown" });
  }
});

// Launch Bot
bot.launch().then(() => {
  console.log("🚀 OrbitLife Telegram Automation Bot is RUNNING!");
  console.log("👉 Open Telegram and message your bot to start automating.");
}).catch((err) => {
  console.error("❌ Failed to launch bot:", err.message);
});

// Enable graceful stop
process.once("SIGINT", () => bot.stop("SIGINT"));
process.once("SIGTERM", () => bot.stop("SIGTERM"));
