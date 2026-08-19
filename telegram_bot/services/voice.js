/**
 * Voice-First Financial Assistant — OrbitLife Personal CFO
 * Transcribes voice notes via Groq Whisper API and Gemini Multimodal Audio
 */

const axios = require("axios");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const Groq = require("groq-sdk");
const fs = require("fs");
const path = require("path");
const os = require("os");

function getGeminiModel() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  const genAI = new GoogleGenerativeAI(apiKey);
  return genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
}

function getGroqClient() {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return null;
  return new Groq({ apiKey });
}

/**
 * Transcribe Telegram Voice Note Buffer into text
 * 
 * @param {Buffer} audioBuffer Audio buffer (.oga / .ogg / .mp3)
 * @param {string} [mimeType="audio/ogg"] 
 * @returns {Promise<string>} Transcribed text string
 */
async function transcribeAudio(audioBuffer, mimeType = "audio/ogg") {
  const groq = getGroqClient();
  const gemini = getGeminiModel();

  // 1. Try Groq Whisper (Ultra-fast Speech-To-Text)
  if (groq) {
    let tempFilePath = null;
    try {
      const tempDir = os.tmpdir();
      tempFilePath = path.join(tempDir, `voice_${Date.now()}.ogg`);
      fs.writeFileSync(tempFilePath, audioBuffer);

      const transcription = await groq.audio.transcriptions.create({
        file: fs.createReadStream(tempFilePath),
        model: "whisper-large-v3",
        prompt: "OrbitLife personal finance, expenses, UPI, SBI, HDFC, EMIs, salary, cash in Indian Rupees (INR)",
        temperature: 0.0,
      });

      if (tempFilePath && fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);

      if (transcription && transcription.text) {
        return transcription.text.trim();
      }
    } catch (err) {
      console.warn("⚠️ Groq Whisper transcription fallback:", err.message);
      if (tempFilePath && fs.existsSync(tempFilePath)) {
        try { fs.unlinkSync(tempFilePath); } catch (_) {}
      }
    }
  }

  // 2. Fallback to Gemini 2.5 Multimodal Audio
  if (gemini) {
    try {
      const result = await gemini.generateContent([
        {
          inlineData: {
            mimeType: mimeType,
            data: audioBuffer.toString("base64"),
          },
        },
        {
          text: "You are an audio transcription engine for a personal finance app. Transcribe the spoken audio verbatim in English or Hinglish. Output ONLY the raw transcribed text without commentary.",
        },
      ]);

      const text = result.response.text();
      return text ? text.trim() : "";
    } catch (err) {
      console.error("❌ Gemini Audio transcription error:", err.message);
      throw new Error(`Failed to process voice note: ${err.message}`);
    }
  }

  throw new Error("No Speech-To-Text API key (GROQ_API_KEY or GEMINI_API_KEY) configured.");
}

module.exports = {
  transcribeAudio,
};
