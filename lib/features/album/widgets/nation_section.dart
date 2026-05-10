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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _expanded
                ? Padding(
                    key: const ValueKey('expanded'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: s.stickers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3 / 4,
                      ),
                      itemBuilder: (context, i) {
                        final st = s.stickers[i];
                        return StickerCard(
                          sticker: st,
                          onTap: () => widget.onTap(st),
                          onLongPress: () => widget.onLongPress(st),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
          ),
        ],
      ),
    );
  }
}
