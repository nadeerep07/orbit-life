import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_parser_service.dart';

/// Singleton OCR service.
/// - Lazily initialises the TextRecognizer once and keeps it alive.
/// - OCR image processing runs in a background isolate via [compute].
/// - The text parsing also runs in the same isolate so the main thread
///   is never blocked.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  // The recognizer is expensive to create – keep it alive for the app's lifetime.
  TextRecognizer? _recognizer;
  bool _disposed = false;

  TextRecognizer get _getRecognizer {
    if (_disposed || _recognizer == null) {
      _disposed = false;
      _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
    return _recognizer!;
  }

  /// Runs OCR + parsing on a background isolate, returns a [ParsedReceipt].
  /// Never throws – errors are captured and returned as an empty receipt.
  Future<ParsedReceipt> processImage(String imagePath) async {
    try {
      // ML Kit's InputImage and TextRecognizer MUST be called on the platform /
      // main thread (they use platform channels internally), but we can offload
      // the heavy synchronous parsing work to a separate isolate.
      final inputImage = InputImage.fromFilePath(imagePath);

      // processImage itself is async and non-blocking on the main thread –
      // it marshals work through the platform channel to a native thread.
      final recognizedText = await _getRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;

      // Offload the CPU-heavy regex parsing to a background isolate so
      // the main thread (UI) is not blocked during text analysis.
      final parsed = await compute(_parseInIsolate, rawText);

      return parsed;
    } catch (e, stack) {
      dev.log('OcrService: processImage failed', error: e, stackTrace: stack);
      return ParsedReceipt(
        amount: 0.0,
        merchant: 'Unknown Merchant',
        date: DateTime.now(),
        rawText: '',
      );
    }
  }

  /// Releases native ML Kit resources. Call when the feature is no longer needed.
  Future<void> dispose() async {
    _disposed = true;
    await _recognizer?.close();
    _recognizer = null;
  }
}

// Top-level function required by [compute] – must be outside class.
ParsedReceipt _parseInIsolate(String rawText) {
  return OcrParserService.parse(rawText);
}
