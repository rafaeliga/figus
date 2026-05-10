import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/album_view_models.dart';
import 'sticker_card.dart';

class NationSectionWidget extends StatefulWidget {
  final AlbumSection section;
  final void Function(StickerView) onTap;
  final void Function(StickerView) onLongPress;
  final bool initiallyExpanded;

  const NationSectionWidget({
    super.key,
    required this.section,
    required this.onTap,
    required this.onLongPress,
    this.initiallyExpanded = true,
  });

  @override
  State<NationSectionWidget> createState() => _NationSectionWidgetState();
}

class _NationSectionWidgetState extends State<NationSectionWidget> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  if (s.flag != null) Text(s.flag!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.slotSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${s.ownedCount}/${s.totalCount}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: _buildLayout(),
            ),
        ],
      ),
    );
  }

  Widget _buildLayout() {
    final s = widget.section;
    if (s.key == 'FWC') {
      return _grid(s.stickers, columns: 4);
    }

    final crest = s.stickers.where((x) => x.type == 'crest').toList();
    final teamPhoto = s.stickers.where((x) => x.type == 'team_photo').toList();
    final players = s.stickers.where((x) => x.type == 'player').toList();
    final extras = s.stickers
        .where((x) => x.type != 'crest' && x.type != 'team_photo' && x.type != 'player')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final st in crest)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StickerBanner(
              sticker: st,
              onTap: () => widget.onTap(st),
              onLongPress: () => widget.onLongPress(st),
              icon: Icons.shield_rounded,
              displayLabel: 'Escudo da seleção',
            ),
          ),
        for (final st in teamPhoto)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StickerBanner(
              sticker: st,
              onTap: () => widget.onTap(st),
              onLongPress: () => widget.onLongPress(st),
              icon: Icons.groups_rounded,
              displayLabel: 'Foto da equipe',
            ),
          ),
        if (players.isNotEmpty) _grid(players, columns: 4),
        if (extras.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _grid(extras, columns: 4),
          ),
      ],
    );
  }

  Widget _grid(List<StickerView> items, {required int columns}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (_, i) {
        final st = items[i];
        return StickerCard(
          key: ValueKey('sticker-${st.id}'),
          sticker: st,
          onTap: () => widget.onTap(st),
          onLongPress: () => widget.onLongPress(st),
        );
      },
    );
  }
}
