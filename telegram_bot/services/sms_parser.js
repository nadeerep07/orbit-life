/**
 * Bank SMS & UPI Notification Auto-Parsing Engine — OrbitLife Personal CFO
 * Extracts amounts, merchants, accounts, and transaction types from Indian Bank SMS alerts.
 */

/**
 * Parse raw Bank SMS text
 * 
 * @param {string} smsText Raw SMS message text
 * @returns {Object|null} Extracted transaction details or null if not a bank SMS
 */
function parseBankSms(smsText) {
  if (!smsText || typeof smsText !== "string") return null;

  const text = smsText.trim();
  const lower = text.toLowerCase();

  // Check if text looks like a bank transaction SMS
  const isTransactionSms =
    (lower.includes("debited") ||
      lower.includes("credited") ||
      lower.includes("spent") ||
      lower.includes("paid rs") ||
      lower.includes("inr") ||
      lower.includes("vpa") ||
      lower.includes("upi") ||
      lower.includes("a/c") ||
      lower.includes("acct")) &&
    (lower.includes("rs") || lower.includes("inr") || lower.includes("₹"));

  if (!isTransactionSms) return null;

  // 1. Extract Amount
  // Matches: Rs. 450.00, INR 1200, Rs 350, ₹1500, Rs.450.50
  const amountRegex = /(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)/i;
  const amountMatch = text.match(amountRegex);
  let amount = 0;
  if (amountMatch && amountMatch[1]) {
    amount = parseFloat(amountMatch[1].replace(/,/g, ""));
  }

  if (amount <= 0) return null;

  // 2. Extract Transaction Type (Debit vs Credit)
  let type = "EXPENSE";
  if (lower.includes("credited") || lower.includes("received") || lower.includes("refund")) {
    type = "INCOME";
  }

  // 3. Extract Bank Account
  let account = "SBI";
  if (lower.includes("hdfc")) account = "HDFC";
  else if (lower.includes("sbi") || lower.includes("state bank")) account = "SBI";
  else if (lower.includes("icici")) account = "ICICI";
  else if (lower.includes("axis")) account = "Axis Bank";
  else if (lower.includes("kotak")) account = "Kotak Bank";
  else if (lower.includes("supermoney") || lower.includes("credit card") || lower.includes("card ending")) account = "Supermoney";

  // 4. Extract Merchant / Beneficiary / VPA
  let merchant = "Bank Transaction";
  let category = "General";

  // Match patterns like: "at SWIGGY", "to ZOMATO", "info/SWIGGY/123", "VPA rahul@upi"
  const merchantAtMatch = text.match(/(?:at|to|info\/|vpa\s+)\s*([A-Za-z0-9\s._@-]+?)(?:\s+on|\s+ref|\s+upi|\s+avl|\s+bal|\.|$)/i);
  if (merchantAtMatch && merchantAtMatch[1]) {
    merchant = merchantAtMatch[1].trim();
  }

  const mLower = merchant.toLowerCase();
  if (mLower.includes("swiggy") || mLower.includes("zomato") || mLower.includes("mcdonald") || mLower.includes("kfc") || mLower.includes("food") || mLower.includes("hotel") || mLower.includes("restaurant") || mLower.includes("cafe")) {
    category = "Food";
  } else if (mLower.includes("amazon") || mLower.includes("flipkart") || mLower.includes("myntra") || mLower.includes("blinkit") || mLower.includes("zepto") || mLower.includes("instamart") || mLower.includes("supermarket") || mLower.includes("mart")) {
    category = "Shopping & Groceries";
  } else if (mLower.includes("uber") || mLower.includes("ola") || mLower.includes("rapido") || mLower.includes("petrol") || mLower.includes("fuel") || mLower.includes("indianoil") || mLower.includes("hpcl") || mLower.includes("bpcl")) {
    category = "Transport & Fuel";
  } else if (mLower.includes("airtel") || mLower.includes("jio") || mLower.includes("vi ") || mLower.includes("bescom") || mLower.includes("electricity") || mLower.includes("wifi") || mLower.includes("netflix") || mLower.includes("spotify")) {
    category = "Bills & Utilities";
  }

  // 5. Extract Balance After Transaction (if present)
  let balanceAfter = null;
  const balMatch = text.match(/(?:bal|balance|avl\s*bal|avail\s*bal|available\s*balance)[:\s]*(?:is)?[:\s]*(?:rs\.?|inr|₹)?[:\s]*([\d,]+(?:\.\d{1,2})?)/i);
  if (balMatch && balMatch[1]) {
    balanceAfter = parseFloat(balMatch[1].replace(/,/g, ""));
  }

  return {
    isBankSms: true,
    type,
    amount,
    account,
    merchant,
    category,
    balanceAfter,
    rawText: text,
  };
}

module.exports = {
  parseBankSms,
};
