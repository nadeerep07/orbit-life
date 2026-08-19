/**
 * Personal Financial Memory & User Preferences — OrbitLife Personal CFO
 * Manages user financial preferences, salary cycles, emergency buffer rules, and goals.
 */

const { getDb, getUserData } = require("./firebase");
const admin = require("firebase-admin");
const { v4: uuidv4 } = require("uuid");

const DEFAULT_PREFERENCES = {
  salaryDayOfMonth: 1,
  expectedMonthlySalary: 29600,
  emergencyBufferTarget: 2000,
  minimumMonthlySavings: 3000,
  defaultSalaryAccount: "SBI",
  defaultSpendAccount: "SBI",
  categoryBudgets: {
    food: 4000,
    shopping: 2500,
    bills: 5000,
    transport: 1500,
  },
  quietHours: {
    enabled: true,
    startHour: 23,
    endHour: 7,
  },
};

/**
 * Retrieve User Financial Preferences with fallback defaults
 * 
 * @param {string} userId 
 * @returns {Promise<Object>} Preferences object
 */
async function getPreferences(userId) {
  const userData = await getUserData(userId);
  if (!userData) return DEFAULT_PREFERENCES;

  return {
    ...DEFAULT_PREFERENCES,
    ...(userData.financialPreferences || {}),
  };
}

/**
 * Update User Financial Preferences
 * 
 * @param {string} userId 
 * @param {Object} partialPrefs 
 * @returns {Promise<Object>} Updated preferences
 */
async function updatePreferences(userId, partialPrefs) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const current = await getPreferences(userId);

  const updated = {
    ...current,
    ...partialPrefs,
    lastUpdated: new Date().toISOString(),
  };

  await userRef.set(
    {
      financialPreferences: updated,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      lastBackup: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return updated;
}

/**
 * Add or Update a Category Budget
 */
async function setCategoryBudget(userId, { category, budget }) {
  const current = await getPreferences(userId);
  const currentBudgets = current.categoryBudgets || {};
  const catKey = (category || "general").toLowerCase().trim();

  currentBudgets[catKey] = Number(budget);

  return await updatePreferences(userId, {
    categoryBudgets: currentBudgets,
  });
}

/**
 * Create or Update a Financial Goal
 */
async function setGoal(userId, { name, targetAmount, deadline, monthlyContribution, priority }) {
  const firestore = getDb();
  const userRef = firestore.collection("users").doc(userId);
  const userData = await getUserData(userId);
  if (!userData) throw new Error("User profile not found.");

  const goals = userData.goals || [];
  const goalId = uuidv4();
  const now = new Date().toISOString();

  const newGoal = {
    id: goalId,
    name: name || "Savings Goal",
    targetAmount: Number(targetAmount || 0),
    currentAmount: 0,
    deadline: deadline || null,
    monthlyContribution: Number(monthlyContribution || (targetAmount / 6) || 0),
    priority: priority || "MEDIUM",
    isCompleted: false,
    createdAt: now,
    lastUpdated: now,
  };

  // Replace if exists with same name, else add
  const filtered = goals.filter((g) => (g.name || "").toLowerCase() !== (name || "").toLowerCase());
  const updatedGoals = [...filtered, newGoal];

  await userRef.set(
    {
      goals: updatedGoals,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      lastBackup: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return newGoal;
}

module.exports = {
  DEFAULT_PREFERENCES,
  getPreferences,
  updatePreferences,
  setCategoryBudget,
  setGoal,
};
