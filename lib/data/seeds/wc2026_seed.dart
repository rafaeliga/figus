/// Seed data for the FIFA World Cup 2026 album (Panini).
///
/// 980 stickers total: FWC00 (logo Panini foil) + FWC1–FWC8 (intro) +
/// FWC9–FWC19 (Legends) + 48 nations × 20 stickers.
///
/// Player names are placeholders ("Jogador BRA 1") because Panini hasn't
/// published rosters yet. Replace via remote JSON update when available.
library;

class SeedNation {
  final String code;
  final String name;
  final String flag;
  final String? group; // null until FIFA draw (Dec 2025)
  final int orderInAlbum;
  const SeedNation({
    required this.code,
    required this.name,
    required this.flag,
    required this.orderInAlbum,
    this.group,
  });
}

class SeedSticker {
  final String number; // BRA1, FWC9, etc.
  final String? nationCode;
  final String type; // crest | team_photo | player | intro | legend | logo
  final bool isFoil;
  final int pageNumber;
  final int positionInPage;
  final String label;
  const SeedSticker({
    required this.number,
    required this.nationCode,
    required this.type,
    required this.isFoil,
    required this.pageNumber,
    required this.positionInPage,
    required this.label,
  });
}

class WC2026Seed {
  static const albumCode = 'WC2026';
  static const albumName = 'Copa do Mundo FIFA 2026';
  static const albumYear = 2026;

  /// 48 confirmed nations (Panini codes), alphabetical until draw.
  static final List<SeedNation> nations = _buildNations();

  /// 980 stickers: FWC00 + FWC1-8 (intro) + FWC9-19 (legends) + 48*20.
  static final List<SeedSticker> stickers = _buildStickers();

  static List<SeedNation> _buildNations() {
    final raw = <List<String>>[
      ['ARG', 'Argentina', '🇦🇷'],
      ['ALG', 'Argélia', '🇩🇿'],
      ['AUS', 'Austrália', '🇦🇺'],
      ['AUT', 'Áustria', '🇦🇹'],
      ['BEL', 'Bélgica', '🇧🇪'],
      ['BIH', 'Bósnia e Herzegovina', '🇧🇦'],
      ['BRA', 'Brasil', '🇧🇷'],
      ['CAN', 'Canadá', '🇨🇦'],
      ['CIV', 'Costa do Marfim', '🇨🇮'],
      ['COD', 'RD Congo', '🇨🇩'],
      ['COL', 'Colômbia', '🇨🇴'],
      ['CPV', 'Cabo Verde', '🇨🇻'],
      ['CRO', 'Croácia', '🇭🇷'],
      ['CUW', 'Curaçao', '🇨🇼'],
      ['CZE', 'Tchéquia', '🇨🇿'],
      ['ECU', 'Equador', '🇪🇨'],
      ['EGY', 'Egito', '🇪🇬'],
      ['ENG', 'Inglaterra', '🏴󠁧󠁢󠁥󠁮󠁧󠁿'],
      ['ESP', 'Espanha', '🇪🇸'],
      ['FRA', 'França', '🇫🇷'],
      ['GER', 'Alemanha', '🇩🇪'],
      ['GHA', 'Gana', '🇬🇭'],
      ['HAI', 'Haiti', '🇭🇹'],
      ['IRN', 'Irã', '🇮🇷'],
      ['IRQ', 'Iraque', '🇮🇶'],
      ['JOR', 'Jordânia', '🇯🇴'],
      ['JPN', 'Japão', '🇯🇵'],
      ['KOR', 'Coreia do Sul', '🇰🇷'],
      ['KSA', 'Arábia Saudita', '🇸🇦'],
      ['MAR', 'Marrocos', '🇲🇦'],
      ['MEX', 'México', '🇲🇽'],
      ['NED', 'Holanda', '🇳🇱'],
      ['NOR', 'Noruega', '🇳🇴'],
      ['NZL', 'Nova Zelândia', '🇳🇿'],
      ['PAN', 'Panamá', '🇵🇦'],
      ['PAR', 'Paraguai', '🇵🇾'],
      ['POR', 'Portugal', '🇵🇹'],
      ['QAT', 'Catar', '🇶🇦'],
      ['RSA', 'África do Sul', '🇿🇦'],
      ['SCO', 'Escócia', '🏴󠁧󠁢󠁳󠁣󠁴󠁿'],
      ['SEN', 'Senegal', '🇸🇳'],
      ['SUI', 'Suíça', '🇨🇭'],
      ['SWE', 'Suécia', '🇸🇪'],
      ['TUN', 'Tunísia', '🇹🇳'],
      ['TUR', 'Turquia', '🇹🇷'],
      ['URU', 'Uruguai', '🇺🇾'],
      ['USA', 'Estados Unidos', '🇺🇸'],
      ['UZB', 'Uzbequistão', '🇺🇿'],
    ];
    raw.sort((a, b) => a[0].compareTo(b[0]));
    return [
      for (var i = 0; i < raw.length; i++)
        SeedNation(
          code: raw[i][0],
          name: raw[i][1],
          flag: raw[i][2],
          orderInAlbum: i,
        ),
    ];
  }

  static List<SeedSticker> _buildStickers() {
    final list = <SeedSticker>[];

    // FWC00: Panini logo (foil)
    list.add(const SeedSticker(
      number: 'FWC00',
      nationCode: null,
      type: 'logo',
      isFoil: true,
      pageNumber: 0,
      positionInPage: 0,
      label: 'Logo Panini',
    ));

    // FWC1–FWC8: Intro
    const intro = [
      'Emblema FIFA WC 2026',
      'Mascote Maple',
      'Mascote Zayu',
      'Mascote Clutch',
      'Slogan oficial',
      'Bola oficial',
      'Cidades-sede CAN',
      'Cidades-sede MEX/USA',
    ];
    for (var i = 0; i < 8; i++) {
      list.add(SeedSticker(
        number: 'FWC${i + 1}',
        nationCode: null,
        type: 'intro',
        isFoil: false,
        pageNumber: 0,
        positionInPage: i + 1,
        label: intro[i],
      ));
    }

    // FWC9–FWC19: Legends
    const legends = [
      'Itália 1934',
      'Itália 1938',
      'Uruguai 1950',
      'Alemanha 1954',
      'Brasil 1958',
      'Brasil 1962',
      'Inglaterra 1966',
      'Brasil 1970',
      'Alemanha 1974',
      'Argentina 1978',
      'Argentina 2022',
    ];
    for (var i = 0; i < 11; i++) {
      list.add(SeedSticker(
        number: 'FWC${9 + i}',
        nationCode: null,
        type: 'legend',
        isFoil: true,
        pageNumber: 1,
        positionInPage: i,
        label: legends[i],
      ));
    }

    // 48 nations × 20 stickers
    for (final nation in nations) {
      final pageNum = nation.orderInAlbum + 2;
      for (var i = 1; i <= 20; i++) {
        String type;
        bool isFoil = false;
        String label;
        if (i == 1) {
          type = 'crest';
          isFoil = true;
          label = 'Escudo';
        } else if (i == 2) {
          type = 'team_photo';
          label = 'Equipe';
        } else {
          type = 'player';
          label = ''; // sigla + número já são suficientes na UI
        }
        list.add(SeedSticker(
          number: '${nation.code}$i',
          nationCode: nation.code,
          type: type,
          isFoil: isFoil,
          pageNumber: pageNum,
          positionInPage: i - 1,
          label: label,
        ));
      }
    }

    return list;
  }
}
