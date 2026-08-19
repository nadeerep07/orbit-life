const { GoogleGenerativeAI } = require("@google/generative-ai");
const Groq = require("groq-sdk");
require("dotenv").config();

function getGeminiModel() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || !apiKey.startsWith("AIzaSy")) return null;
  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    return genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
  } catch (e) {
    console.warn("⚠️ Failed to initialize Gemini SDK:", e.message);
    return null;
  }
}

function getGroqClient() {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return null;
  try {
    return new Groq({ apiKey });
  } catch (e) {
    console.warn("⚠️ Failed to initialize Groq SDK:", e.message);
    return null;
  }
}

const SYSTEM_PARSER_PROMPT = `
You are the AI engine for "OrbitLife" / "MyBudgetPro", a personal finance & health dashboard.
Default Currency: Indian Rupee (INR / ₹). All numbers represent INR unless specified otherwise.

Analyze the user's message and categorize it into one of the following intents:

1. "EXPENSE": The user spent money on something (e.g. "Spent 350 on lunch with UPI", "Bought groceries 1200 on Supermoney card").
   Extract:
   - amount: number (required)
   - description: string (merchant or item name)
   - category: string ("Food", "Groceries", "Transport", "Shopping", "Entertainment", "Bills", "Health", "Other")
   - account: string (optional, e.g. "Cash", "HDFC", "SBI", "GPay", "Supermoney Card", "Credit Card")
   - date: "YYYY-MM-DD"

2. "INCOME": The user received money (e.g. "Received 29600 salary", "Freelance payout 5000").
   Extract:
   - amount: number (required)
   - source: string (e.g. "Salary", "Freelance", "Bonus", "Gift")
   - account: string (optional)
   - date: "YYYY-MM-DD"

3. "PAY_EMI": The user paid their loan/EMI (e.g. "Paid college emi 3750", "Mark iPhone EMI as paid", "Paid my car EMI").
   Extract:
   - emiName: string (e.g. "College EMI", "iPhone EMI")
   - amount: number (optional)
   - account: string (optional)

4. "DEBT_UPDATE": The user lent/borrowed money or received/paid back a debt (e.g. "Friend paid 2500", "Friend paid remaining 2500 to SBI", "Friend repaid 2500", "Shamveel paid back 5000", "Lent 2000 to Rahul", "Settled debt with Friend", "Borrowed 3000 from Dad", "He paid 2500 back to SBI").
   Extract:
   - action: "settle" (for repayments/paybacks/received back) | "new" (for new lend/borrow)
   - type: "lend" (when someone is paying you back money they owed you, or you lent money) | "borrow" (when you borrowed or are repaying money you borrowed)
   - personName: string (e.g. "Friend", "Rahul", "Shamveel")
   - amount: number
   - account: string (optional bank account where money was received or paid from, e.g. "SBI", "HDFC", "Cash")
   - contact: string (optional phone number)

5. "PAY_CARD_BILL": The user paid their credit card bill (e.g. "Paid 10000 credit card bill", "Cleared Supermoney bill 5000 from HDFC").
   Extract:
   - amount: number (required)
   - account: string (optional bank used to pay)

6. "MEAL": The user ate something or logged food (e.g. "Ate 2 chapatis with paneer and curd").
   Extract:
   - name: string
   - calories: number (estimated kcal)
   - protein: number (estimated grams)
   - carbs: number (estimated grams)
   - fat: number (estimated grams)
   - mealType: "Breakfast" | "Lunch" | "Dinner" | "Snack"

7. "MILEAGE": Fuel / odometer logging (e.g. "Fuel 25L for 2600 at 45000 km").
   Extract:
   - odometer: number
   - liters: number
   - totalCost: number
   - notes: string

8. "TRANSFER": The user moved money between bank accounts, wallets, or cash (e.g. "Transferred 5000 from SBI to HDFC", "Transfer 2000 from HDFC to Cash", "Withdrew 5000 from SBI to Cash in Hand", "Moved 1500 from GPay to SBI").
   Extract:
   - amount: number (required)
   - fromAccount: string (source bank/wallet, e.g. "SBI", "HDFC", "Cash")
   - toAccount: string (destination bank/wallet/cash, e.g. "Cash in Hand", "HDFC", "Cash")
   - date: "YYYY-MM-DD"
   - notes: string (optional)

9. "ADD_ACCOUNT": The user wants to create/add a bank account or cash wallet (e.g. "Add Cash in Hand account with 2000 balance", "Create Cash account with 500", "Add HDFC bank account 25000").
   Extract:
   - name: string (e.g. "Cash in Hand", "HDFC Bank")
   - balance: number (opening balance, default 0)

10. "ONBOARDING": Setup entire profile with accounts, salary, EMIs, credit cards, FDs, debts.
   Extract:
   - accounts: array of { name: string, balance: number }
   - incomes: array of { source: string, amount: number }
   - recurringExpenses: array of { name: string, amount: number, category: string }
   - emis: array of { name: string, amount: number, remainingMonths: number }
   - creditCards: array of { name: string, totalLimit: number, used: number, statementDate: number, dueDate: number }
   - fixedDeposits: array of { issuer: string, amount: number, interestRate: number }
   - borrowLends: array of { to: string, contact: string, amount: number, date: string, type: "lent" | "borrowed" }
   - goals: array of { name: string, targetAmount: number }

11. "SET_BALANCE": The user wants to adjust, set, or correct an account's live balance (e.g. "Set SBI balance to 3312", "Update HDFC balance to 1500", "My SBI balance is actually 500", "Change Cash balance to 350", "Fix SBI balance to 391.67").
   Extract:
   - accountName: string (e.g. "SBI", "HDFC", "Cash")
   - balance: number (the actual correct balance)

12. "UNDO": The user wants to cancel, undo, or delete the last logged transaction, expense, income, or payment (e.g. "Undo last transaction", "Undo last expense", "Delete last payment", "Remove last entry", "Cancel that").
   Extract:
   - target: "last" | "expense" | "income" | "transfer"

13. "EDIT_TRANSACTION": The user wants to modify details of the last transaction or an expense (e.g. "Change last expense amount to 250", "Change last transaction to HDFC", "Change last category to Food", "It was 350 not 500").
   Extract:
   - amount: number (optional)
   - account: string (optional)
   - category: string (optional)
   - description: string (optional)

14. "QUERY": User asking for balances, stats, analytics, or questions (e.g. "Show balance", "How much did I spend?", "Show my EMIs", "Analytics").
   Extract:
   - queryType: "balance" | "emis" | "debts" | "card" | "analytics" | "general"

15. "UNKNOWN": Cannot determine intent.

Respond STRICTLY with valid JSON matching this schema:
{
  "intent": "EXPENSE" | "INCOME" | "PAY_EMI" | "DEBT_UPDATE" | "PAY_CARD_BILL" | "TRANSFER" | "ADD_ACCOUNT" | "SET_BALANCE" | "UNDO" | "EDIT_TRANSACTION" | "MEAL" | "MILEAGE" | "ONBOARDING" | "QUERY" | "UNKNOWN",
  "confidence": number,
  "data": { ... },
  "explanation": "Short friendly summary of what was understood"
}
`;

/**
 * Parse Natural Language Text using Gemini (or Groq fallback)
 */
async function parseTextMessage(text) {
  const currentDate = new Date().toISOString().split("T")[0];
  const userContent = `Today's Date: ${currentDate}\nDefault Currency: Indian Rupee (INR / ₹)\nUser Input: "${text}"`;

  const geminiModel = getGeminiModel();
  const groq = getGroqClient();

  // 1. Try Gemini if valid key exists
  if (geminiModel) {
    try {
      const result = await geminiModel.generateContent({
        contents: [
          {
            role: "user",
            parts: [{ text: `${SYSTEM_PARSER_PROMPT}\n\n${userContent}` }],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.1,
        },
      });

      const response = await result.response;
      const parsed = JSON.parse(response.text());
      return parsed;
    } catch (err) {
      console.warn("⚠️ Gemini text parsing error, attempting Groq fallback:", err.message);
    }
  }

  // 2. Fallback to Groq
  if (groq) {
    try {
      const completion = await groq.chat.completions.create({
        messages: [
          { role: "system", content: SYSTEM_PARSER_PROMPT },
          { role: "user", content: userContent },
        ],
        model: "openai/gpt-oss-120b",
        response_format: { type: "json_object" },
        temperature: 0.1,
      });

      const parsed = JSON.parse(completion.choices[0]?.message?.content || "{}");
      return parsed;
    } catch (err) {
      console.warn("⚠️ Primary Groq model error, trying secondary:", err.message);
      try {
        const completion = await groq.chat.completions.create({
          messages: [
            { role: "system", content: SYSTEM_PARSER_PROMPT },
            { role: "user", content: userContent },
          ],
          model: "openai/gpt-oss-20b",
          response_format: { type: "json_object" },
          temperature: 0.1,
        });

        const parsed = JSON.parse(completion.choices[0]?.message?.content || "{}");
        return parsed;
      } catch (e2) {
        console.error("❌ Groq text parsing error:", e2.message);
      }
    }
  }

  throw new Error("No available AI service configured. Please check GROQ_API_KEY.");
}

/**
 * Analyze an Image (Receipt OCR or Food Macros) using Gemini Vision
 */
async function analyzeImage(imageBuffer, mimeType = "image/jpeg", caption = "") {
  const geminiModel = getGeminiModel();
  if (!geminiModel) {
    throw new Error("A Google Gemini API Key (starts with AIzaSy) is required for receipt photo OCR & meal photo analysis.");
  }

  const prompt = `
Analyze this image. Default currency is Indian Rupee (INR / ₹).
It is either:
1. A RECEIPT / INVOICE / BILL:
   Extract merchant name, total amount in INR, date, line items, and category.
   Set "type": "RECEIPT".
   "data": {
     "merchant": string,
     "amount": number,
     "currency": "INR",
     "date": "YYYY-MM-DD",
     "category": "Groceries" | "Food" | "Shopping" | "Bills" | "Health" | "Other",
     "items": [{"name": string, "price": number}],
     "tax": number
   }

2. A FOOD / MEAL PHOTO:
   Estimate nutritional facts: calories (kcal), protein (g), carbs (g), fat (g).
   Set "type": "MEAL".
   "data": {
     "name": string (dish title),
     "calories": number,
     "protein": number,
     "carbs": number,
     "fat": number,
     "mealType": "Breakfast" | "Lunch" | "Dinner" | "Snack"
   }

3. OTHER: Not a receipt or meal. Set "type": "OTHER".

User caption (if provided): "${caption}"

Respond STRICTLY with valid JSON:
{
  "type": "RECEIPT" | "MEAL" | "OTHER",
  "summary": "Short readable summary of what was found",
  "data": { ... }
}
`;

  try {
    const result = await geminiModel.generateContent({
      contents: [
        {
          role: "user",
          parts: [
            { text: prompt },
            {
              inlineData: {
                data: imageBuffer.toString("base64"),
                mimeType: mimeType,
              },
            },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.2,
      },
    });

    const response = await result.response;
    const parsed = JSON.parse(response.text());
    return parsed;
  } catch (err) {
    console.error("❌ Gemini image analysis error:", err.message);
    throw err;
  }
}

module.exports = {
  parseTextMessage,
  analyzeImage,
};
