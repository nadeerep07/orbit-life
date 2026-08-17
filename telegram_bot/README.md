# 🤖 OrbitLife (MyBudgetPro) Telegram Automation Bot

An intelligent AI-powered Telegram Bot that connects directly to your **Firebase Firestore** backend. Track expenses, scan receipts with OCR, log meals with macro estimations, track vehicle fuel/mileage, and receive daily financial health reports directly from Telegram.

---

## ⚡ Key Capabilities

- 💸 **Natural Language Expense & Income Logging**: *"Spent 45 AED on groceries at Carrefour with Card"*, *"Got 8000 salary"*.
- 🧾 **Receipt & Bill Photo OCR**: Snap a picture of any invoice/receipt; Gemini Vision extracts items, amounts, and dates automatically.
- 🥗 **Meal Photo Macro Estimator**: Send a photo of your meal (or type *"2 eggs and avocado toast"*); the bot calculates calories, protein, carbs, and fats into your diet tracker.
- ⛽ **Mileage & Fuel Tracker**: *"Fuel 40L cost 110 at 64,500 km"*.
- 📊 **Instant Reports**: `/today` and `/month` overviews synced live with your mobile app.

---

## 🚀 Quick Setup Guide (5 Minutes)

### 1. Prerequisites & API Keys

1. **Telegram Bot Token**:
   - Open Telegram and message [@BotFather](https://t.me/BotFather).
   - Send `/newbot`, name your bot (e.g., `OrbitLifeAssistBot`), and copy the **Bot Token**.

2. **Firebase Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/) -> Select your project.
   - Click **Project Settings (⚙️)** -> **Service Accounts**.
   - Click **Generate new private key** and download the `.json` file.
   - Rename and place it at `telegram_bot/serviceAccountKey.json`.

3. **Gemini API Key**:
   - Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey).

---

### 2. Configure Environment

In the `telegram_bot/` directory:

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in your keys:
   ```env
   TELEGRAM_BOT_TOKEN=your_telegram_bot_token
   GEMINI_API_KEY=your_gemini_api_key
   FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
   ```

---

### 3. Install & Start

```bash
cd telegram_bot
npm install
npm start
```

You will see:
```
✅ Firebase Firestore initialized successfully
🚀 OrbitLife Telegram Automation Bot is RUNNING!
👉 Open Telegram and message your bot to start automating.
```

---

### 4. Link Your Account in Telegram

1. Open your bot on Telegram and send `/start`.
2. Link your account by sending:
   ```
   /link YOUR_FIREBASE_USER_ID
   ```
   *(Find your User ID inside the mobile app: Settings -> Profile / Backup -> Copy ID)*.

---

## 💬 Usage Examples

| Intent | What to Send in Telegram | What the Bot Does |
|---|---|---|
| **Expense** | `Spent 35 on Starbucks with credit card` | Saves expense to Firestore `expenses` & `transactions` |
| **Receipt OCR** | 📸 *(Send photo of receipt)* | Extracts total, merchant, date & line items |
| **Income** | `Received 8000 salary from employer` | Saves to Firestore `incomes` |
| **Diet / Meal** | 📸 *(Send photo of food)* OR `Ate 200g chicken breast and rice` | Estimates calories & macros, saves to `mealEntries` |
| **Fuel / Odo** | `Fuel 45L cost 120 at 72000 km` | Saves to `mileages` |
| **Daily Report** | `/today` or click `📊 Today's Summary` | Shows daily spending & remaining budget |

---

## ☁️ Free 24/7 Cloud Deployment Options

### Option A: Railway / Render (Zero Config Polling)
1. Push this folder to a GitHub repository.
2. Connect the repo on [Railway.app](https://railway.app) or [Render.com](https://render.com).
3. Set environment variables (`TELEGRAM_BOT_TOKEN`, `GEMINI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON`).
4. Railway will automatically keep the bot online 24/7!

### Option B: PM2 on VPS / Mac Background
```bash
npm install -g pm2
pm2 start index.js --name orbitlife-bot
pm2 save
```
