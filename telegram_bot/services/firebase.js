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

  // 1. Check dedicated telegram_links collection (indestructible)
  try {
    const linkDoc = await firestore.collection("telegram_links").doc(strChatId).get();
    if (linkDoc.exists && linkDoc.data()?.userId) {
      return linkDoc.data().userId;
    }
  } catch (e) {
    console.warn("⚠️ telegram_links lookup warning:", e.message);
  }

  // 2. Check users collection
  try {
    const snapshot = await firestore
      .collection("users")
      .where("telegramChatId", "==", strChatId)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      const foundUserId = snapshot.docs[0].id;
      // Self-heal into telegram_links
      await firestore.collection("telegram_links").doc(strChatId).set({
        userId: foundUserId,
        linkedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return foundUserId;
    }
  } catch (e) {
    console.warn("⚠️ users lookup warning:", e.message);
  }

  if (process.env.DEFAULT_USER_ID) {
    return process.env.DEFAULT_USER_ID;
  }

  return null;
}

/**
 * Link Telegram Chat ID to a Firestore User Document permanently
 */
async function linkUserChatId(userId, chatId) {
  const firestore = getDb();
  const strChatId = String(chatId);

  // 1. Save to dedicated telegram_links collection
  await firestore.collection("telegram_links").doc(strChatId).set(
    {
      userId: userId,
      chatId: strChatId,
      linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // 2. Also save to users document
  const userRef = firestore.collection("users").doc(userId);
  await userRef.set(
    {
      telegramChatId: strChatId,
      linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return true;
}

/**
 * Unlink Telegram Chat ID
 */
async function unlinkUserChatId(chatId) {
  const firestore = getDb();
  const strChatId = String(chatId);

  await firestore.collection("telegram_links").doc(strChatId).delete();
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

  // If paid via Credit Card, also update Credit Card used limit
  let updatePayload = {
    expenses: admin.firestore.FieldValue.arrayUnion(expenseItem),
    transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (account && (account.toLowerCase().includes("card") || account.toLowerCase().includes("supermoney"))) {
    const cc = userData?.creditCardAccount;
    if (cc) {
      const currentUsed = Number(cc.usedCredit || 0);
      const currentLimit = Number(cc.creditLimit || 26713.8);
      const newUsed = currentUsed + Number(amount);
      updatePayload.creditCardAccount = {
        ...cc,
        usedCredit: newUsed,
        availableCredit: Math.max(0, currentLimit - newUsed),
        lastUpdated: new Date().toISOString(),
      };
    }
  }

  await userRef.set(updatePayload, { merge: true });

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
 * Mark EMI as Paid
 */
async function payEmi(userId, { emiName, amount, accountName }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);
  const emis = (userData && userData.emis) || [];

  if (emis.length === 0) {
    throw new Error("No active EMIs found in your profile.");
  }

  // Fuzzy find EMI by name
  let targetEmi = emis.find(
    (e) => (e.title && e.title.toLowerCase().includes(emiName.toLowerCase())) ||
           (e.loanName && e.loanName.toLowerCase().includes(emiName.toLowerCase()))
  );

  if (!targetEmi) {
    targetEmi = emis[0]; // fallback to first EMI
  }

  const emiAmount = Number(amount || targetEmi.monthlyEmi || targetEmi.amount || 0);
  const updatedPaidMonths = (targetEmi.paidMonths || 0) + 1;
  const updatedRemainingMonths = Math.max(0, (targetEmi.totalMonths || targetEmi.remainingMonths || 12) - updatedPaidMonths);

  const updatedEmis = emis.map((e) => {
    if (e.id === targetEmi.id) {
      return {
        ...e,
        paidMonths: updatedPaidMonths,
        remainingMonths: updatedRemainingMonths,
        isPaid: updatedRemainingMonths === 0,
        lastPaidDate: new Date().toISOString(),
      };
    }
    return e;
  });

  // Log as Expense
  const expenseItem = {
    id: uuidv4(),
    categoryId: "emi",
    amount: emiAmount,
    description: `Paid EMI: ${targetEmi.title || targetEmi.loanName}`,
    date: new Date().toISOString(),
    accountId: accountName || targetEmi.accountId || "bank",
    isFromSavings: false,
    source: "emi_paid_bot",
  };

  const transactionItem = {
    id: uuidv4(),
    title: `EMI Payment: ${targetEmi.title || targetEmi.loanName}`,
    amount: emiAmount,
    date: new Date().toISOString(),
    type: "expense",
    categoryId: "emi",
    accountId: accountName || targetEmi.accountId || "bank",
    notes: `Marked paid via Telegram Bot (${updatedRemainingMonths} months remaining)`,
  };

  await userRef.set(
    {
      emis: updatedEmis,
      expenses: admin.firestore.FieldValue.arrayUnion(expenseItem),
      transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    emiTitle: targetEmi.title || targetEmi.loanName,
    amountPaid: emiAmount,
    paidMonths: updatedPaidMonths,
    remainingMonths: updatedRemainingMonths,
  };
}

/**
 * Handle Borrow / Lend update (Repayment or new debt)
 */
async function handleDebtUpdate(userId, { personName, amount, type, action, contact }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);
  const borrowLends = (userData && userData.borrowLends) || [];
  const now = new Date().toISOString();

  // If action is repayment/settlement
  if (action === "settle" || action === "repay") {
    let target = borrowLends.find(
      (b) => b.personName && b.personName.toLowerCase().includes((personName || "").toLowerCase())
    );

    if (!target) {
      throw new Error(`Could not find an active debt record for "${personName}".`);
    }

    const payAmount = Number(amount || target.amount || 0);
    const newAmount = Math.max(0, Number(target.amount || 0) - payAmount);
    const isSettled = newAmount === 0;

    const updatedBorrowLends = borrowLends.map((b) => {
      if (b.id === target.id) {
        return {
          ...b,
          amount: newAmount,
          status: isSettled ? "settled" : "pending",
          isSettled: isSettled,
          lastUpdated: now,
        };
      }
      return b;
    });

    // Log transaction
    const isLend = target.type === "lend";
    const transactionItem = {
      id: uuidv4(),
      title: isLend ? `Repayment from ${target.personName}` : `Debt Repayment to ${target.personName}`,
      amount: payAmount,
      date: now,
      type: isLend ? "income" : "expense",
      accountId: "cash",
      notes: `Debt settlement recorded via Telegram (${isSettled ? "Fully Settled" : `₹${newAmount} remaining`})`,
    };

    const updatePayload = {
      borrowLends: updatedBorrowLends,
      transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (isLend) {
      updatePayload.incomes = admin.firestore.FieldValue.arrayUnion({
        id: uuidv4(),
        source: `Repayment from ${target.personName}`,
        amount: payAmount,
        date: now,
        accountId: "cash",
      });
    } else {
      updatePayload.expenses = admin.firestore.FieldValue.arrayUnion({
        id: uuidv4(),
        categoryId: "debts",
        amount: payAmount,
        description: `Repaid ${target.personName}`,
        date: now,
        accountId: "cash",
        isFromSavings: false,
        source: "debt_settle",
      });
    }

    await userRef.set(updatePayload, { merge: true });

    return {
      personName: target.personName,
      amountSettled: payAmount,
      remainingDebt: newAmount,
      isSettled,
      type: target.type,
    };
  }

  // Otherwise, add a new borrow/lend record
  const debtItem = {
    id: uuidv4(),
    personName: personName || "Friend",
    phoneNumber: contact || "",
    amount: Number(amount || 0),
    type: type === "borrow" || type === "borrowed" ? "borrow" : "lend",
    date: now,
    note: `Added via Telegram Bot`,
    status: "pending",
    accountId: "cash",
    transactions: [],
  };

  await userRef.set(
    {
      borrowLends: admin.firestore.FieldValue.arrayUnion(debtItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    personName: debtItem.personName,
    amount: debtItem.amount,
    type: debtItem.type,
  };
}

/**
 * Pay Credit Card Bill
 */
async function payCreditCardBill(userId, { amount, accountName }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);
  const cc = userData?.creditCardAccount;

  if (!cc) {
    throw new Error("No Credit Card found in your profile.");
  }

  const payAmount = Number(amount || cc.usedCredit || 0);
  const currentUsed = Number(cc.usedCredit || 0);
  const currentLimit = Number(cc.creditLimit || 26713.8);
  const newUsed = Math.max(0, currentUsed - payAmount);
  const newAvailable = Math.min(currentLimit, currentLimit - newUsed);

  const updatedCc = {
    ...cc,
    usedCredit: newUsed,
    availableCredit: newAvailable,
    lastUpdated: new Date().toISOString(),
  };

  // Log as Expense from Bank account
  const expenseItem = {
    id: uuidv4(),
    categoryId: "credit_card_bill",
    amount: payAmount,
    description: `Credit Card Bill Payment (${cc.name || "Supermoney"})`,
    date: new Date().toISOString(),
    accountId: accountName || "bank",
    isFromSavings: false,
    source: "cc_bill_pay",
  };

  const transactionItem = {
    id: uuidv4(),
    title: `Credit Card Bill Paid`,
    amount: payAmount,
    date: new Date().toISOString(),
    type: "expense",
    categoryId: "credit_card_bill",
    accountId: accountName || "bank",
    notes: `Credit card bill paid via Telegram. Available Limit restored to ₹${newAvailable.toLocaleString("en-IN")}`,
  };

  await userRef.set(
    {
      creditCardAccount: updatedCc,
      expenses: admin.firestore.FieldValue.arrayUnion(expenseItem),
      transactions: admin.firestore.FieldValue.arrayUnion(transactionItem),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    amountPaid: payAmount,
    newUsedCredit: newUsed,
    newAvailableCredit: newAvailable,
    totalLimit: currentLimit,
  };
}

/**
 * Create or add a new account (e.g. Cash in Hand)
 */
async function addAccount(userId, { name, balance = 0 }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);

  const accounts = (userData && userData.accounts) || [];
  const existing = accounts.find(
    (a) => a.name && a.name.toLowerCase() === name.toLowerCase().trim()
  );

  if (existing) {
    const updatedAccounts = accounts.map((a) =>
      a.id === existing.id ? { ...a, openingBalance: Number(balance) } : a
    );
    await userRef.set(
      {
        accounts: updatedAccounts,
        lastBackup: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return { id: existing.id, name: existing.name, balance: Number(balance), isNew: false };
  }

  const newAccount = {
    id: uuidv4(),
    name: name.trim(),
    openingBalance: Number(balance) || 0,
  };

  await userRef.set(
    {
      accounts: [...accounts, newAccount],
      lastBackup: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { id: newAccount.id, name: newAccount.name, balance: newAccount.openingBalance, isNew: true };
}

/**
 * Transfer funds between accounts (e.g. SBI -> HDFC, or SBI -> Cash in Hand)
 */
async function logTransfer(userId, { amount, fromAccount, toAccount, date, notes }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);

  if (!userData) throw new Error("User profile not found. Please link your account.");

  let accounts = [...(userData.accounts || [])];
  const transferAmount = Number(amount);
  if (!transferAmount || transferAmount <= 0) {
    throw new Error("Please specify a valid transfer amount greater than 0.");
  }

  // Resolve source account
  let fromAcc = accounts.find(
    (a) => a.name && a.name.toLowerCase().includes(fromAccount.toLowerCase().trim())
  );
  if (!fromAcc && accounts.length > 0) {
    fromAcc = accounts.find(
      (a) => fromAccount.toLowerCase().includes(a.name.toLowerCase())
    );
  }

  if (!fromAcc) {
    const existingNames = accounts.map((a) => a.name).join(", ");
    throw new Error(`Source account "${fromAccount}" not found. Available accounts: ${existingNames || "None"}`);
  }

  // Resolve target account
  let toAcc = accounts.find(
    (a) => a.name && a.name.toLowerCase().includes(toAccount.toLowerCase().trim())
  );
  if (!toAcc && accounts.length > 0) {
    toAcc = accounts.find(
      (a) => toAccount.toLowerCase().includes(a.name.toLowerCase())
    );
  }

  // Auto-create target if it's Cash / Cash in Hand and not found
  if (!toAcc) {
    const isCash = /cash/i.test(toAccount);
    const targetName = isCash ? "Cash in Hand" : toAccount.trim();
    const created = {
      id: uuidv4(),
      name: targetName,
      openingBalance: 0,
    };
    accounts.push(created);
    toAcc = created;
  }

  if (fromAcc.id === toAcc.id) {
    throw new Error("Source and destination accounts cannot be the same.");
  }

  const fromNewBalance = (Number(fromAcc.openingBalance) || 0) - transferAmount;
  const toNewBalance = (Number(toAcc.openingBalance) || 0) + transferAmount;

  const updatedAccounts = accounts.map((a) => {
    if (a.id === fromAcc.id) return { ...a, openingBalance: fromNewBalance };
    if (a.id === toAcc.id) return { ...a, openingBalance: toNewBalance };
    return a;
  });

  const entryDate = date ? new Date(date) : new Date();
  const txId = uuidv4();

  const newTx = {
    id: txId,
    amount: transferAmount,
    type: "transfer",
    accountId: fromAcc.id,
    targetAccountId: toAcc.id,
    categoryOrSource: "Account Transfer",
    date: entryDate.toISOString(),
    description: notes || `Transfer from ${fromAcc.name} to ${toAcc.name}`,
    referenceId: "telegram_transfer",
  };

  const newTransfer = {
    id: uuidv4(),
    amount: transferAmount,
    fromAccount: fromAcc.name,
    toAccount: toAcc.name,
    date: entryDate.toISOString(),
    notes: notes || `Transfer from ${fromAcc.name} to ${toAcc.name}`,
  };

  await userRef.set(
    {
      accounts: updatedAccounts,
      transactions: [...(userData.transactions || []), newTx],
      transfers: [...(userData.transfers || []), newTransfer],
      lastBackup: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return {
    fromAccountName: fromAcc.name,
    toAccountName: toAcc.name,
    fromNewBalance,
    toNewBalance,
    amount: transferAmount,
  };
}

/**
 * Get Balances & Net Worth
 */
async function getBalances(userId) {
  const userData = await getUserData(userId);
  if (!userData) return null;

  const rawAccounts = userData.accounts || [];
  const expenses = userData.expenses || [];
  const incomes = userData.incomes || [];
  const cc = userData.creditCardAccount;
  const fds = userData.fdLots || [];

  // Filter out credit card accounts from liquid bank/cash accounts
  const liquidAccounts = rawAccounts.filter((a) => {
    const nameLower = (a.name || "").toLowerCase();
    const idLower = (a.id || "").toLowerCase();
    return (
      idLower !== "supermoney" &&
      !nameLower.includes("credit card") &&
      !nameLower.includes("super money") &&
      !nameLower.includes("supermoney") &&
      a.type !== "credit_card"
    );
  });

  // Calculate live balances for liquid accounts only
  const detailedAccounts = liquidAccounts.map((a) => {
    const accIncomes = incomes
      .filter((i) => i.accountId === a.id)
      .reduce((sum, i) => sum + (Number(i.amount) || 0), 0);
    const accExpenses = expenses
      .filter((e) => e.accountId === a.id)
      .reduce((sum, e) => sum + (Number(e.amount) || 0), 0);
    const balance = Number(a.openingBalance || 0) + accIncomes - accExpenses;
    return {
      name: a.name,
      balance: balance,
    };
  });

  const totalLiquidCash = detailedAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalFdValue = fds.reduce((sum, fd) => sum + (Number(fd.currentValue || fd.principal) || 0), 0);

  return {
    accounts: detailedAccounts,
    totalLiquidCash,
    creditCard: cc ? {
      name: cc.name || "Supermoney Secured Credit Card",
      limit: Number(cc.creditLimit || 0),
      used: Number(cc.usedCredit || 0),
      available: Number(cc.availableCredit || 0),
      dueDateDay: cc.dueDateDay || 15,
    } : null,
    totalFdValue,
    netWorth: totalLiquidCash + totalFdValue - (cc ? Number(cc.usedCredit || 0) : 0),
  };
}

/**
 * Get EMIs and Debts List
 */
async function getEmisAndDebts(userId) {
  const userData = await getUserData(userId);
  if (!userData) return null;

  const emis = (userData.emis || []).map((e) => {
    const monthlyEmi = Number(e.monthlyEmi || e.amount || 0);
    const paidMonths = Number(e.paidMonths || 0);
    const totalMonths = Number(e.totalMonths || e.remainingMonths || 12);
    const remainingMonths = e.remainingMonths !== undefined ? Number(e.remainingMonths) : Math.max(0, totalMonths - paidMonths);
    const totalAmount = Number(e.totalAmount || (monthlyEmi * totalMonths));
    const pendingAmount = monthlyEmi * remainingMonths;
    const paidAmount = Math.max(0, totalAmount - pendingAmount);

    return {
      id: e.id,
      title: e.title || e.loanName || "Loan",
      monthlyEmi,
      paidMonths,
      totalMonths,
      remainingMonths,
      totalAmount,
      pendingAmount,
      paidAmount,
      isPaid: remainingMonths === 0,
    };
  });

  const borrowLends = (userData.borrowLends || []).filter((b) => !b.isSettled && b.status !== "settled").map((b) => ({
    personName: b.personName || "Person",
    amount: Number(b.amount || 0),
    type: b.type === "borrow" ? "You Owe" : "Owed to You",
    phoneNumber: b.phoneNumber || "",
  }));

  return { emis, borrowLends };
}

/**
 * Save Full Onboarding Data
 */
async function saveOnboardingProfile(userId, { accounts = [], incomes = [], recurringExpenses = [], emis = [], goals = [], creditCards = [], fixedDeposits = [], borrowLends = [], savingsTarget = null }) {
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
    title: emi.name || emi.title || "Loan",
    loanName: emi.name || emi.title || "Loan",
    provider: emi.provider || "Bank",
    monthlyEmi: Number(emi.amount || emi.monthlyAmount || emi.monthlyEmi || 0),
    totalAmount: Number(emi.totalAmount || ((emi.amount || emi.monthlyAmount || 0) * (emi.remainingMonths || emi.months || 12))),
    totalMonths: Number(emi.remainingMonths || emi.months || 12),
    paidMonths: 0,
    remainingMonths: Number(emi.remainingMonths || emi.months || 12),
    interestRate: Number(emi.interestRate || 0),
    startDate: now,
    notes: "",
    isPayLater: false,
    isPaid: false,
    isReminderEnabled: true,
    accountId: primaryAccountId,
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

  // Formatted Borrow / Lends
  const formattedBorrowLends = (borrowLends || []).map((b) => ({
    id: uuidv4(),
    personName: b.to || b.personName || "Person",
    phoneNumber: b.contact || b.phoneNumber || "",
    amount: Number(b.amount || 0),
    type: b.type === "borrowed" ? "borrow" : "lend",
    date: b.date || now,
    note: b.notes || "Recorded via Telegram Onboarding",
    status: "pending",
    accountId: primaryAccountId,
    transactions: [],
  }));

  // Formatted Credit Card
  let primaryCc = null;
  if (creditCards && creditCards.length > 0) {
    const cc = creditCards[0];
    const limit = Number(cc.totalLimit || cc.limit || cc.creditLimit || 26713.8);
    const used = Number(cc.used || cc.usedLimit || cc.usedCredit || 10000.0);
    const available = Number(cc.availableCredit || (limit - used));
    primaryCc = {
      id: "supermoney_account",
      name: cc.name || "Supermoney Secured Credit Card",
      creditLimit: limit,
      availableCredit: available,
      usedCredit: used,
      statementDateDay: Number(cc.statementDate || cc.statementDateDay || 1),
      dueDateDay: Number(cc.dueDate || cc.dueDateDay || 15),
      initialCreditMigrated: false,
      lastUpdated: now,
      cashbackPending: 0.0,
      cashbackAvailable: 0.0,
      lifetimeCashback: 0.0,
      cashbackRedeemed: 0.0,
    };
  }

  // Formatted Fixed Deposits (FD Lots)
  const formattedFds = (fixedDeposits || []).map((fd) => ({
    id: uuidv4(),
    principal: Number(fd.amount || fd.principal || 29682),
    currentValue: Number(fd.amount || fd.currentValue || 29682),
    depositDate: now,
    maturityDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
    lockUntil: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
    interestRate: Number(fd.interestRate || 6.0),
    status: "active",
    autoRenew: true,
    renewHistory: [],
    remarks: fd.issuer || "Supermoney Utkarsh Bank FD",
  }));

  if (formattedFds.length === 0 && primaryCc) {
    formattedFds.push({
      id: uuidv4(),
      principal: 29682.0,
      currentValue: 29682.0,
      depositDate: now,
      maturityDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      lockUntil: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
      interestRate: 6.0,
      status: "active",
      autoRenew: true,
      renewHistory: [],
      remarks: "Supermoney Utkarsh Bank FD",
    });
  }

  const updatePayload = {
    accounts: formattedAccounts,
    incomes: formattedIncomes,
    expenses: formattedExpenses,
    emis: formattedEmis,
    goals: formattedGoals,
    borrowLends: formattedBorrowLends,
    fdLots: formattedFds,
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
    borrowLendsCount: formattedBorrowLends.length,
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

  // Category breakdown
  const categoryMap = {};
  for (const exp of monthExpenses) {
    const cat = exp.categoryId || "general";
    categoryMap[cat] = (categoryMap[cat] || 0) + (Number(exp.amount) || 0);
  }

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
    categoryBreakdown: categoryMap,
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
}
