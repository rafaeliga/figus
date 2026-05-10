import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// One detected sticker code with confidence + raw text + bounding box.
class StickerDetection {
  final String code; // BRA10, FWC9, ...
  final double confidence; // 0..1
  final String rawText;

  const StickerDetection({
    required this.code,
    required this.confidence,
    required this.rawText,
  });
}

/// On-device OCR service. Mobile only — calling on web throws.
///
/// Designed for two flows:
///   1. **Page scan** (album-lock): pass the expected nation code; matches are
///      filtered to that range, killing the digit-confusion mix-ups (6/9, B/8)
///      that plague competitor apps.
///   2. **Figuritas import**: pass null nation; extracts every code-like token
///      across the whole image (e.g. screenshot of competitor app).
class OcrService {
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Sticker code = country sigla (3 caps) OR "FWC" + digits.
  static final _codeRegex = RegExp(r'\b([A-Z]{3})\s*[-–]?\s*(\d{1,3})\b');

  static Future<List<StickerDetection>> recognize(
    String imagePath, {
    String? expectedNationCode,
    Set<String>? validCodes,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('OCR só está disponível no celular (iOS/Android).');
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return _extractCodes(result, expectedNationCode, validCodes);
    } finally {
      await recognizer.close();
    }
  }

  static List<StickerDetection> _extractCodes(
    RecognizedText result,
    String? expectedNationCode,
    Set<String>? validCodes,
  ) {
    final detections = <StickerDetection>[];
    final seen = <String>{};

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.toUpperCase().replaceAll('O', '0').trim();
        for (final match in _codeRegex.allMatches(text)) {
          final sigla = match.group(1)!;
          final number = int.tryParse(match.group(2)!);
          if (number == null) continue;

          // Album-lock: when expecting a specific nation, drop other codes.
          if (expectedNationCode != null && sigla != expectedNationCode) continue;
          // Validate range (1-20 for nations, 0-19 for FWC).
          if (sigla == 'FWC') {
            if (number > 19) continue;
          } else {
            if (number < 1 || number > 20) continue;
          }

          // If caller provided a whitelist of known codes, reject unknown ones.
          final code = sigla == 'FWC' && number == 0 ? 'FWC00' : '$sigla$number';
          if (validCodes != null && !validCodes.contains(code)) continue;

          if (seen.add(code)) {
            // Confidence proxy: line confidence not exposed by ML Kit; use 1.0
            // when the regex matched cleanly. Replace by per-line conf when
            // ML Kit exposes it.
            detections.add(StickerDetection(code: code, confidence: 1.0, rawText: line.text));
          }
        }
      }
    }
    return detections;
  }
}
