import 'package:flutter/material.dart';

/// Vibrant gradient palette assigned per (nationCode, position).
/// Inspired by the user's reference screenshots — yellow / red / blue / purple
/// vibrant cards when owned, neutral grey when missing.
class StickerGradients {
  static const _palettes = <List<Color>>[
    [Color(0xFFFFC83D), Color(0xFFFF8A00)], // amber
    [Color(0xFFFF5F6D), Color(0xFFFF7B5A)], // coral
    [Color(0xFF4A6CF7), Color(0xFF7A5BFF)], // indigo→violet
    [Color(0xFF8E5CFF), Color(0xFFC36BFF)], // purple
    [Color(0xFF22C1F0), Color(0xFF3577FF)], // sky→blue
    [Color(0xFF1ABC9C), Color(0xFF24D6B5)], // teal
    [Color(0xFFF45D89), Color(0xFFFF7AB6)], // pink
    [Color(0xFFFFB347), Color(0xFFFF6F61)], // sunset
  ];

  /// Stable-but-varied gradient based on a seed string.
  static LinearGradient owned(String seedKey) {
    final hash = _stableHash(seedKey);
    final palette = _palettes[hash % _palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palette,
    );
  }

  /// Foil/holographic shimmer for special stickers.
  static const LinearGradient foilShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD27E),
      Color(0xFFFF93C9),
      Color(0xFF8FB8FF),
      Color(0xFFA0F0CF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static int _stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}
