import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import 'package:country_flags/country_flags.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import 'widgets/sticker_card.dart';

/// Page dedicated to ONE nation — mimics the layout of the printed Panini
/// album page, all 20 stickers in their physical position.
class NationDetailPage extends ConsumerWidget {
  final String code; // e.g. "BRA"
  const NationDetailPage({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSection = ref.watch(_nationSectionProvider(code));
    return Scaffold(
      appBar: AppBar(
        title: Text(code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncSection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (section) {
          if (section == null) {
            return const Center(child: Text('Seleção não encontrada'));
          }
          return _NationDetailBody(
            section: section,
            onTap: (st) async {
              HapticFeedback.lightImpact();
              await ref.read(collectionRepoProvider).tapSticker(st.id);
              ref.read(collectionVersionProvider.notifier).state++;
            },
            onLongPress: (st) async {
              HapticFeedback.mediumImpact();
              await ref.read(collectionRepoProvider).removeSticker(st.id);
              ref.read(collectionVersionProvider.notifier).state++;
            },
          );
        },
      ),
    );
  }
}

class _NationDetailBody extends StatelessWidget {
  final AlbumSection section;
  final void Function(StickerView) onTap;
  final void Function(StickerView) onLongPress;

  const _NationDetailBody({
    required this.section,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = [...section.stickers]
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(section: section)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          sliver: SliverToBoxAdapter(
            child: StaggeredGrid.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final st in ordered)
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    // Team photo is landscape (shorter height), the rest are portrait.
                    mainAxisCellCount: st.type == 'team_photo' ? 0.75 : (4 / 3),
                    child: StickerCard(
                      key: ValueKey('detail-${st.id}'),
                      sticker: st,
                      onTap: () => onTap(st),
                      onLongPress: () => onLongPress(st),
                      aspectRatio: st.type == 'team_photo' ? 4 / 3 : 3 / 4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AlbumSection section;
  const _Header({required this.section});

  @override
  Widget build(BuildContext context) {
    final progress = section.totalCount == 0
        ? 0.0
        : section.ownedCount / section.totalCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.seed, AppTheme.seed.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (paniniToIso2[section.key] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CountryFlag.fromCountryCode(
                    paniniToIso2[section.key]!,
                    width: 56,
                    height: 40,
                  ),
                )
              else
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WE ARE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _nameFromTitle(section.title).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${section.ownedCount}/${section.totalCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  static String _nameFromTitle(String title) {
    // "BRA - Brasil" → "Brasil"
    final idx = title.indexOf('-');
    if (idx < 0) return title;
    return title.substring(idx + 1).trim();
  }
}

final _nationSectionProvider =
    FutureProvider.autoDispose.family<AlbumSection?, String>((ref, code) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final sections = await repo.loadSections();
  return sections.firstWhere(
    (s) => s.key == code,
    orElse: () => const AlbumSection(
      key: '',
      title: '',
      flag: null,
      ownedCount: 0,
      totalCount: 0,
      stickers: [],
    ),
  );
});
