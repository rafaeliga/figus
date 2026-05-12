import 'dart:typed_data';

/// Minimal PDF parser that pulls out JPEG (`/DCTDecode`) image streams in the
/// order they appear in the file.
///
/// Works for PDFs where the embedded images are stored as raw JPEG streams
/// (the common case for editorial PDFs). It does NOT handle encrypted PDFs,
/// FlateDecode-compressed image streams, or non-JPEG image filters.
///
/// All processing is in-memory and happens on the user's own device.
class PdfImageExtractor {
  static List<Uint8List> extractJpegs(Uint8List pdfBytes) {
    final out = <Uint8List>[];
    // Treat the PDF as latin1 so byte offsets align 1:1 with string indices.
    final view = String.fromCharCodes(pdfBytes);

    // Match /Filter /DCTDecode in any of its common forms:
    //   /Filter /DCTDecode
    //   /Filter[/DCTDecode]
    //   /Filter /DCTDecode/...
    final pattern = RegExp(
      r'/Filter\s*\[?\s*(?:/DCTDecode|/DCT)\b',
      caseSensitive: true,
    );

    for (final match in pattern.allMatches(view)) {
      final streamWord = view.indexOf('stream', match.end);
      if (streamWord < 0 || streamWord - match.end > 4000) continue;
      var dataStart = streamWord + 'stream'.length;
      if (dataStart < view.length && view.codeUnitAt(dataStart) == 0x0D) dataStart++;
      if (dataStart < view.length && view.codeUnitAt(dataStart) == 0x0A) dataStart++;

      final endStream = view.indexOf('endstream', dataStart);
      if (endStream < 0) continue;
      var dataEnd = endStream;
      while (dataEnd > dataStart &&
          (view.codeUnitAt(dataEnd - 1) == 0x0A ||
              view.codeUnitAt(dataEnd - 1) == 0x0D)) {
        dataEnd--;
      }

      // Validate JPEG markers: SOI (0xFF 0xD8) at start, EOI (0xFF 0xD9) at end.
      if (dataEnd - dataStart < 4) continue;
      if (pdfBytes[dataStart] != 0xFF || pdfBytes[dataStart + 1] != 0xD8) continue;
      // Find the last 0xFF 0xD9 inside the slice (some streams have trailing
      // padding before endstream).
      var eoi = dataEnd - 2;
      while (eoi > dataStart) {
        if (pdfBytes[eoi] == 0xFF && pdfBytes[eoi + 1] == 0xD9) break;
        eoi--;
      }
      if (eoi <= dataStart) continue;

      final jpeg = Uint8List.sublistView(pdfBytes, dataStart, eoi + 2);
      // Skip thumbnails / tiny masks — usually under 2KB.
      if (jpeg.length < 2048) continue;
      out.add(jpeg);
    }
    return out;
  }
}
