const { GoogleGenerativeAI } = require("@google/generative-ai");
const Groq = require("groq-sdk");
require("dotenv").config();

function getGeminiModel() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
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

1. "EXPENSE": The user spent money on something.
   Extract:
   - amount: number (required)
   - description: string (merchant or item name, e.g. "Chai and snacks", "Starbucks Coffee")
   - category: string (e.g., "Food", "Groceries", "Transport", "Shopping", "Entertainment", "Bills", "Health", "Other")
   - account: string (optional, e.g. "Cash", "HDFC Bank", "SBI", "GPay", "Credit Card")
   - date: "YYYY-MM-DD" (defaults to current date if not mentioned)

2. "INCOME": The user received money.
   Extract:
   - amount: number (required)
   - source: string (e.g. "Salary", "Freelance", "Gift", "Dividends")
   - account: string (optional)
   - date: "YYYY-MM-DD"

3. "MEAL": The user ate something or logged food.
   Extract:
   - name: string (e.g. "2 Rotis with Dal and Paneer")
   - calories: number (estimated total kcal)
   - protein: number (estimated grams)
   - carbs: number (estimated grams)
   - fat: number (estimated grams)
   - mealType: "Breakfast" | "Lunch" | "Dinner" | "Snack"

4. "MILEAGE": The user fueled up their vehicle or logged odometer.
   Extract:
   - odometer: number (km reading)
   - liters: number (fuel amount)
   - totalCost: number (cost of fuel in INR)
   - pricePerLiter: number (optional)
   - notes: string (e.g. "Petrol full tank")

5. "ONBOARDING": The user is describing multiple accounts, salary, EMIs, credit cards, fixed deposits, or goals to set up their entire financial profile.
   Extract:
   - accounts: array of { name: string, balance: number }
   - incomes: array of { source: string, amount: number }
   - recurringExpenses: array of { name: string, amount: number, category: string }
   - emis: array of { name: string, amount: number, remainingMonths: number }
   - creditCards: array of { name: string, totalLimit: number, used: number, statementDate: number, dueDate: number }
   - fixedDeposits: array of { issuer: string, amount: number, interestRate: number }
   - borrowLends: array of { to: string, contact: string, amount: number, date: string, type: "lent" | "borrowed" }
   - goals: array of { name: string, targetAmount: number }

6. "QUERY": The user is asking a question about their finances, spending, or app status.
   Extract:
   - query: string

7. "UNKNOWN": Cannot determine intent.

Respond STRICTLY with valid JSON matching this schema:
{
  "intent": "EXPENSE" | "INCOME" | "MEAL" | "MILEAGE" | "ONBOARDING" | "QUERY" | "UNKNOWN",
  "confidence": number,
  "data": { ... },
  "explanation": "Short friendly summary of what was understood"
}
`;

/**
 * Parse Natural Language Text using Gemini (or fallback to Groq)
 */
async function parseTextMessage(text) {
  const currentDate = new Date().toISOString().split("T")[0];
  const userContent = `Today's Date: ${currentDate}\nDefault Currency: Indian Rupee (INR / ₹)\nUser Input: "${text}"`;

  const geminiModel = getGeminiModel();
  const groq = getGroqClient();

  // 1. Try Gemini
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

  throw new Error("No available AI service configured. Please check GEMINI_API_KEY or GROQ_API_KEY.");
}

/**
 * Analyze an Image (Receipt OCR or Food Macros) using Gemini Vision
 */
async function analyzeImage(imageBuffer, mimeType = "image/jpeg", caption = "") {
  const geminiModel = getGeminiModel();
  if (!geminiModel) {
    throw new Error("GEMINI_API_KEY is required for image analysis (receipt OCR & meal detection).");
  }

  const prompt = `
Analyze this image. Default currency is Indian Rupee (INR / ₹).
It is either:
1. A RECEIPT / INVOICE / BILL:
   Extract the merchant/store name, total amount paid in INR, currency, transaction date, line items, taxes, and suggested category.
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
   Identify the dish/food items visible. Estimate accurate nutritional facts: calories (kcal), protein (g), carbs (g), fat (g).
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
