import 'package:figus/data/seeds/wc2026_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeds 980 stickers', () {
    expect(WC2026Seed.stickers.length, 980);
  });

  test('seeds 48 nations', () {
    expect(WC2026Seed.nations.length, 48);
  });

  test('every nation has 20 stickers', () {
    for (final n in WC2026Seed.nations) {
      final count = WC2026Seed.stickers.where((s) => s.nationCode == n.code).length;
      expect(count, 20, reason: '${n.code} should have 20 stickers');
    }
  });

  test('FWC specials: 1 logo + 8 intro + 11 legends', () {
    final specials = WC2026Seed.stickers.where((s) => s.nationCode == null).toList();
    expect(specials.length, 20);
    expect(specials.where((s) => s.type == 'logo').length, 1);
    expect(specials.where((s) => s.type == 'intro').length, 8);
    expect(specials.where((s) => s.type == 'legend').length, 11);
  });

  test('foil count = 49 base (48 crests + FWC00) + 11 legends shiny = 60', () {
    final foils = WC2026Seed.stickers.where((s) => s.isFoil).toList();
    expect(foils.length, greaterThanOrEqualTo(49));
  });

  test('all sticker numbers are unique', () {
    final numbers = WC2026Seed.stickers.map((s) => s.number).toList();
    expect(numbers.toSet().length, numbers.length);
  });
}
