import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
    final ordered = [...s.stickers]
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));

    if (s.key == 'FWC') {
      // Specials: simple uniform grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ordered.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 3 / 4,
        ),
        itemBuilder: (_, i) => _card(ordered[i]),
      );
    }

    // Nation page mimicking the physical Panini album:
    //   - sticker #1 (crest)      → 2×2 (top-left)
    //   - sticker #2 (team photo) → 2×2 (top-right)
    //   - stickers #3..#20         → 1×1 each, filling the grid in sequence
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final st in ordered)
          StaggeredGridTile.count(
            crossAxisCellCount: _cellSpan(st),
            mainAxisCellCount: _cellSpan(st),
            child: _card(st, isBig: _cellSpan(st) > 1),
          ),
      ],
    );
  }

  int _cellSpan(StickerView st) {
    // crest and team_photo span 2x2; everything else 1x1.
    if (st.type == 'crest' || st.type == 'team_photo') return 2;
    return 1;
  }

  Widget _card(StickerView st, {bool isBig = false}) {
    return StickerCard(
      key: ValueKey('sticker-${st.id}'),
      sticker: st,
      onTap: () => widget.onTap(st),
      onLongPress: () => widget.onLongPress(st),
      // For 2x2 tiles inside a staggered grid, the height/width = 2*cell + spacing,
      // so the natural aspect is closer to 1:1 than 3:4.
      aspectRatio: isBig ? 1.0 : 3 / 4,
    );
  }
}
