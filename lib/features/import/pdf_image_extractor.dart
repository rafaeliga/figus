import 'dart:typed_data';

/// Minimal PDF parser that pulls out JPEG (`/DCTDecode`) image streams.
///
/// Operates on raw bytes (no giant `String.fromCharCodes` that would blow
/// memory on an 80MB+ PDF). Periodically yields to the event loop via the
/// optional [onProgress] callback so the UI can render a progress bar.
class PdfImageExtractor {
  /// "/DCTDecode" as ASCII bytes.
  static final _dct = Uint8List.fromList('/DCTDecode'.codeUnits);
  static final _stream = Uint8List.fromList('stream'.codeUnits);
  static final _endStream = Uint8List.fromList('endstream'.codeUnits);

  static Future<List<Uint8List>> extractJpegs(
    Uint8List bytes, {
    void Function(double pct, String message)? onProgress,
  }) async {
    final out = <Uint8List>[];
    final total = bytes.length;
    var cursor = 0;
    var lastYield = 0;

    while (cursor < total) {
      final dctAt = _indexOf(bytes, _dct, cursor);
      if (dctAt < 0) break;

      final streamAt = _indexOf(bytes, _stream, dctAt + _dct.length);
      if (streamAt < 0) break;
      if (streamAt - dctAt > 4000) {
        cursor = dctAt + _dct.length;
        continue;
      }
      var dataStart = streamAt + _stream.length;
      // strip the optional CR/LF after "stream"
      if (dataStart < total && bytes[dataStart] == 0x0D) dataStart++;
      if (dataStart < total && bytes[dataStart] == 0x0A) dataStart++;

      final endAt = _indexOf(bytes, _endStream, dataStart);
      if (endAt < 0) break;
      var dataEnd = endAt;
      while (dataEnd > dataStart && (bytes[dataEnd - 1] == 0x0A || bytes[dataEnd - 1] == 0x0D)) {
        dataEnd--;
      }

      cursor = endAt + _endStream.length;

      // Validate JPEG envelope.
      if (dataEnd - dataStart < 2048) continue;
      if (bytes[dataStart] != 0xFF || bytes[dataStart + 1] != 0xD8) continue;
      var eoi = dataEnd - 2;
      while (eoi > dataStart) {
        if (bytes[eoi] == 0xFF && bytes[eoi + 1] == 0xD9) break;
        eoi--;
      }
      if (eoi <= dataStart) continue;

      out.add(Uint8List.sublistView(bytes, dataStart, eoi + 2));

      // Yield to the event loop every ~5MB so the UI can repaint.
      if (cursor - lastYield > 5 * 1024 * 1024) {
        lastYield = cursor;
        onProgress?.call(cursor / total, 'Lendo PDF… ${out.length} imagens encontradas');
        await Future<void>.delayed(Duration.zero);
      }
    }
    onProgress?.call(1.0, 'Lidas ${out.length} imagens');
    return out;
  }

  /// Boyer-Moore-Horspool would be faster, but a plain forward scan over
  /// 80MB takes a few hundred ms in JS — good enough.
  static int _indexOf(Uint8List haystack, Uint8List needle, int from) {
    final n = needle.length;
    final last = haystack.length - n;
    if (from > last) return -1;
    final first = needle[0];
    for (var i = from; i <= last; i++) {
      if (haystack[i] != first) continue;
      var match = true;
      for (var j = 1; j < n; j++) {
        if (haystack[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }
}
