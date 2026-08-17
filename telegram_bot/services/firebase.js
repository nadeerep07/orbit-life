const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");
require("dotenv").config();

let db = null;

function initializeFirebase() {
  if (admin.apps.length > 0) {
    db = admin.firestore();
    return db;
  }

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      const servicePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./serviceAccountKey.json";
      const resolvedPath = path.isAbsolute(servicePath)
        ? servicePath
        : path.resolve(__dirname, "..", servicePath);

      if (fs.existsSync(resolvedPath)) {
        const serviceAccount = require(resolvedPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      } else {
        console.warn("⚠️ No serviceAccountKey.json found. Initializing with default application credentials.");
        admin.initializeApp();
      }
    }

    db = admin.firestore();
    console.log("✅ Firebase Firestore initialized successfully");
    return db;
  } catch (err) {
    console.error("❌ Firebase initialization error:", err.message);
    throw err;
  }
}

// Get Firestore instance
function getDb() {
  if (!db) {
    return initializeFirebase();
  }
  return db;
}

/**
 * Find user ID linked to Telegram Chat ID
 */
async function getUserIdByChatId(chatId) {
  const firestore = getDb();
  const strChatId = String(chatId);

  // 1. Check if user document contains telegramChatId field
  const snapshot = await firestore
    .collection("users")
    .where("telegramChatId", "==", strChatId)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return snapshot.docs[0].id;
  }

  // 2. Check fallback single user from environment variable
  if (process.env.DEFAULT_USER_ID) {
    return process.env.DEFAULT_USER_ID;
  }

  return null;
}

/**
 * Link Telegram Chat ID to a Firestore User Document
 */
async function linkUserChatId(userId, chatId) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const doc = await userRef.get();

  if (!doc.exists) {
    await userRef.set(
      {
        telegramChatId: String(chatId),
        linkedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } else {
    await userRef.update({
      telegramChatId: String(chatId),
      linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return true;
}

/**
 * Fetch user data snapshot
 */
async function getUserData(userId) {
  const firestore = getDb();
  const doc = await firestore.collection("users").doc(userId).get();
  if (!doc.exists) return null;
  return doc.data();
}

/**
 * Helper to match or create category and account IDs
 */
function resolveCategoryAndAccount(userData, categoryName, accountName) {
  const categories = (userData && userData.categories) || [];
  const accounts = (userData && userData.accounts) || [];

  let categoryId = "general";
  if (categoryName && categories.length > 0) {
    const matched = categories.find(
      (c) => c.name && c.name.toLowerCase().includes(categoryName.toLowerCase())
    );
    if (matched) categoryId = matched.id || matched.name;
  }

  let accountId = "default";
  if (accountName && accounts.length > 0) {
    const matched = accounts.find(
      (a) => a.name && a.name.toLowerCase().includes(accountName.toLowerCase())
    );
    if (matched) accountId = matched.id || matched.name;
  } else if (accounts.length > 0) {
    accountId = accounts[0].id || accounts[0].name;
  }

  return { categoryId, accountId };
}

/**
 * Log an Expense
 */
async function logExpense(userId, { amount, description, category, account, date, source }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);

  const { categoryId, accountId } = resolveCategoryAndAccount(userData, category, account);
  const expenseId = uuidv4();
  const transactionId = uuidv4();
  const entryDate = date ? new Date(date) : new Date();

  const expenseItem = {
    id: expenseId,
    categoryId: categoryId,
    amount: Number(amount),
    description: description || category || "Expense",
    date: entryDate.toISOString(),
    accountId: accountId,
    isFromSavings: false,
    source: source || "telegram_bot",
  };

  const transactionItem = {
    id: transactionId,
    title: description || category || "Expense",
    amount: Number(amount),
    date: entryDate.toISOString(),
    type: "expense",
    categoryId: categoryId,
    accountId: accountId,
    notes: `Logged via Telegram Bot (${source || "manual"})`,
  };

  await userRef.set(
    {
      expenses: admin.firestore.FieldValue.arrayUnion(expenseItem),
      transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return expenseItem;
}

/**
 * Log an Income
 */
async function logIncome(userId, { amount, source, account, date }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);

  const { accountId } = resolveCategoryAndAccount(userData, null, account);
  const incomeId = uuidv4();
  const transactionId = uuidv4();
  const entryDate = date ? new Date(date) : new Date();

  const incomeItem = {
    id: incomeId,
    source: source || "Income",
    amount: Number(amount),
    date: entryDate.toISOString(),
    accountId: accountId,
  };

  const transactionItem = {
    id: transactionId,
    title: source || "Income",
    amount: Number(amount),
    date: entryDate.toISOString(),
    type: "income",
    accountId: accountId,
    notes: "Logged via Telegram Bot",
  };

  await userRef.set(
    {
      incomes: admin.firestore.FieldValue.arrayUnion(incomeItem),
      transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return incomeItem;
}

/**
 * Log Meal & Nutritional Macros
 */
async function logMeal(userId, { name, calories, protein, carbs, fat, mealType, date }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const entryDate = date ? new Date(date) : new Date();

  const mealItem = {
    id: uuidv4(),
    name: name || "Meal",
    calories: Math.round(Number(calories) || 0),
    protein: Number(protein || 0),
    carbs: Number(carbs || 0),
    fat: Number(fat || 0),
    date: entryDate.toISOString(),
    mealType: mealType || "Snack",
  };

  await userRef.set(
    {
      mealEntries: admin.firestore.FieldValue.arrayUnion(mealItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return mealItem;
}

/**
 * Log Mileage / Fuel
 */
async function logMileage(userId, { odometer, liters, totalCost, pricePerLiter, notes, date }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const entryDate = date ? new Date(date) : new Date();

  const mileageItem = {
    id: uuidv4(),
    date: entryDate.toISOString(),
    odometer: Number(odometer || 0),
    liters: Number(liters || 0),
    totalCost: Number(totalCost || 0),
    pricePerLiter: pricePerLiter ? Number(pricePerLiter) : totalCost && liters ? Number((totalCost / liters).toFixed(2)) : 0,
    notes: notes || "Logged via Telegram Bot",
  };

  await userRef.set(
    {
      mileages: admin.firestore.FieldValue.arrayUnion(mileageItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return mileageItem;
}

/**
 * Save Full Onboarding Data
 */
async function saveOnboardingProfile(userId, { accounts = [], incomes = [], recurringExpenses = [], emis = [], goals = [], creditCards = [], savingsTarget = null }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const now = new Date().toISOString();

  // Formatted accounts
  const formattedAccounts = accounts.map((a) => ({
    id: a.id || uuidv4(),
    name: a.name || "Main Account",
    openingBalance: Number(a.balance || 0),
    initialBalance: Number(a.balance || 0),
  }));

  // Formatted Incomes
  const primaryAccountId = formattedAccounts.length > 0 ? formattedAccounts[0].id : "default";
  const formattedIncomes = incomes.map((i) => ({
    id: uuidv4(),
    source: i.source || "Salary",
    amount: Number(i.amount || 0),
    date: now,
    accountId: primaryAccountId,
  }));

  // Formatted Expenses
  const formattedExpenses = recurringExpenses.map((e) => ({
    id: uuidv4(),
    categoryId: e.category || "Bills",
    amount: Number(e.amount || 0),
    description: e.name || e.category || "Recurring Expense",
    date: now,
    accountId: primaryAccountId,
    isFromSavings: false,
    source: "onboarding",
  }));

  // Formatted EMIs
  const formattedEmis = emis.map((emi) => ({
    id: uuidv4(),
    loanName: emi.name || "Loan",
    monthlyEmi: Number(emi.monthlyAmount || 0),
    totalAmount: Number(emi.totalAmount || (emi.monthlyAmount * (emi.months || 12))),
    remainingMonths: Number(emi.months || 12),
    interestRate: Number(emi.interestRate || 0),
    startDate: now,
  }));

  // Formatted Goals
  const formattedGoals = goals.map((g) => ({
    id: uuidv4(),
    name: g.name || "Financial Goal",
    targetAmount: Number(g.targetAmount || 0),
    currentSavings: Number(g.currentSavings || 0),
    targetDate: g.targetDate || now,
    isCompleted: false,
  }));

  // Formatted Credit Card
  const primaryCc = creditCards && creditCards.length > 0 ? {
    id: uuidv4(),
    cardName: creditCards[0].name || "Credit Card",
    totalLimit: Number(creditCards[0].limit || 50000),
    statementDate: Number(creditCards[0].statementDate || 1),
    dueDate: Number(creditCards[0].dueDate || 20),
    usedLimit: Number(creditCards[0].usedLimit || 0),
  } : null;

  const updatePayload = {
    accounts: formattedAccounts,
    incomes: formattedIncomes,
    expenses: formattedExpenses,
    emis: formattedEmis,
    goals: formattedGoals,
    lastBackup: admin.firestore.FieldValue.serverTimestamp(),
    isOnboarded: true,
  };

  if (primaryCc) {
    updatePayload.creditCardAccount = primaryCc;
  }

  if (savingsTarget) {
    updatePayload.savings = {
      targetPercentage: Number(savingsTarget.percentage || 20),
      monthlyTarget: Number(savingsTarget.monthlyTarget || 0),
    };
  }

  await userRef.set(updatePayload, { merge: true });

  return {
    accountsCount: formattedAccounts.length,
    incomesCount: formattedIncomes.length,
    expensesCount: formattedExpenses.length,
    emisCount: formattedEmis.length,
    goalsCount: formattedGoals.length,
    hasCreditCard: !!primaryCc,
  };
}

/**
 * Calculate Summary for Today & Month
 */
async function getSummary(userId) {
  const userData = await getUserData(userId);
  if (!userData) return null;

  const todayStr = new Date().toISOString().split("T")[0];
  const currentMonthStr = todayStr.substring(0, 7); // YYYY-MM

  const expenses = userData.expenses || [];
  const incomes = userData.incomes || [];
  const mealEntries = userData.mealEntries || [];
  const dietProfile = userData.dietProfile || {};

  // Today's expenses
  const todayExpenses = expenses.filter((e) => e.date && e.date.startsWith(todayStr));
  const todaySpent = todayExpenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);

  // Month's expenses & incomes
  const monthExpenses = expenses.filter((e) => e.date && e.date.startsWith(currentMonthStr));
  const monthSpent = monthExpenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);

  const monthIncomes = incomes.filter((i) => i.date && i.date.startsWith(currentMonthStr));
  const monthEarned = monthIncomes.reduce((sum, i) => sum + (Number(i.amount) || 0), 0);

  // Today's meals
  const todayMeals = mealEntries.filter((m) => m.date && m.date.startsWith(todayStr));
  const todayCalories = todayMeals.reduce((sum, m) => sum + (Number(m.calories) || 0), 0);
  const todayProtein = todayMeals.reduce((sum, m) => sum + (Number(m.protein) || 0), 0);
  const todayCarbs = todayMeals.reduce((sum, m) => sum + (Number(m.carbs) || 0), 0);
  const todayFat = todayMeals.reduce((sum, m) => sum + (Number(m.fat) || 0), 0);

  return {
    todaySpent,
    todayExpensesCount: todayExpenses.length,
    monthSpent,
    monthEarned,
    monthNet: monthEarned - monthSpent,
    todayCalories,
    calorieTarget: dietProfile.dailyCalorieTarget || 2000,
    todayProtein,
    todayCarbs,
    todayFat,
    todayMealsCount: todayMeals.length,
  };
}

module.exports = {
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
};
