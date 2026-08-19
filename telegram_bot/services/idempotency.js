/**
 * Idempotency & Deduplication Guard
 * Prevents double-execution of financial mutations caused by webhook retries,
 * duplicate network packets, or rapid double-taps on inline buttons.
 */

const processedKeys = new Map();
const DEFAULT_TTL_MS = 60 * 1000; // 60 seconds TTL

// Clean up expired keys periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, expiresAt] of processedKeys.entries()) {
    if (now > expiresAt) {
      processedKeys.delete(key);
    }
  }
}, 30 * 1000);

/**
 * Check if a request/message is a duplicate.
 * If not duplicate, marks it as processed and returns true (safe to execute).
 * If duplicate, returns false (skip execution).
 * 
 * @param {string} key Unique request key (e.g. `msg_${chatId}_${messageId}` or `cb_${updateId}`)
 * @param {number} ttlMs Time to keep key locked in milliseconds
 * @returns {boolean} true if first time, false if duplicate
 */
function acquireIdempotencyLock(key, ttlMs = DEFAULT_TTL_MS) {
  if (!key) return true;

  const now = Date.now();
  const existingExpiry = processedKeys.get(key);

  if (existingExpiry && now <= existingExpiry) {
    return false; // Duplicate detected
  }

  processedKeys.set(key, now + ttlMs);
  return true;
}

/**
 * Release lock if needed (e.g. on validation error)
 */
function releaseIdempotencyLock(key) {
  if (key) {
    processedKeys.delete(key);
  }
}

module.exports = {
  acquireIdempotencyLock,
  releaseIdempotencyLock,
};
