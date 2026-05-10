import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/sticker_gradients.dart';
import '../../../domain/models/album_view_models.dart';

/// Vertical card matching the user's reference screenshots:
/// - missing: neutral grey
/// - owned:   vibrant gradient
/// - duplicate: vibrant gradient + blue badge with count
/// - foil: holographic shimmer overlay
class StickerCard extends StatelessWidget {
  final StickerView sticker;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const StickerCard({
    super.key,
    required this.sticker,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final owned = sticker.status != StickerOwnership.missing;
    final foil = sticker.isFoil;

    final gradient = owned
        ? (foil
            ? StickerGradients.foilShimmer
            : StickerGradients.owned('${sticker.nationCode ?? 'FWC'}-${sticker.positionInPage}'))
        : null;

    final headerText = sticker.nationCode != null
        ? '${sticker.nationCode}'
        : sticker.type.toUpperCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: owned ? null : AppTheme.slotSoft,
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                border: owned
                    ? null
                    : Border.all(color: AppTheme.slot.withValues(alpha: 0.4), width: 1),
                boxShadow: owned
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headerText,
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color: owned
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.inkSoft,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '#${sticker.positionInPage > 0 || sticker.nationCode != null ? sticker.positionInPage + (sticker.nationCode != null ? 1 : 0) : 0}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: owned ? Colors.white : AppTheme.ink,
                          shadows: owned
                              ? [const Shadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sticker.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.15,
                        color: owned
                            ? Colors.white.withValues(alpha: 0.95)
                            : AppTheme.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sticker.status == StickerOwnership.duplicate)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.seed,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 26),
                  child: Text(
                    '${sticker.duplicateCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
