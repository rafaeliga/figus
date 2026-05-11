import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import 'widgets/sticker_card.dart';

/// Page dedicated to ONE nation — mimics the layout of the printed Panini
/// album page (header info + 20 stickers grid with #13 as team-photo landscape).
class NationDetailPage extends ConsumerWidget {
  final String code;
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
          if (section == null || section.totalCount == 0) {
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
        SliverToBoxAdapter(child: _DecorativeHeader(section: section)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
          sliver: SliverToBoxAdapter(
            child: StaggeredGrid.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final st in ordered)
                  StaggeredGridTile.count(
                    crossAxisCellCount: _isTeamPhoto(st) ? 2 : 1,
                    mainAxisCellCount: _isTeamPhoto(st) ? 1 : (4 / 3),
                    child: StickerCard(
                      key: ValueKey('detail-${st.id}'),
                      sticker: st,
                      onTap: () => onTap(st),
                      onLongPress: () => onLongPress(st),
                      aspectRatio: _isTeamPhoto(st) ? 2 / 1 : 3 / 4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Position 12 (= sticker #13) is the team photo for every nation in the
  /// 2026 Panini album. We infer it from position rather than type so the
  /// layout is correct even for collections seeded before the type fix.
  bool _isTeamPhoto(StickerView st) => st.positionInPage == 12 || st.type == 'team_photo';
}

class _DecorativeHeader extends StatelessWidget {
  final AlbumSection section;
  const _DecorativeHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final name = _nameFromTitle(section.title);
    final progress = section.totalCount == 0
        ? 0.0
        : section.ownedCount / section.totalCount;
    final iso = paniniToIso2[section.key];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.seed, AppTheme.seed.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WE ARE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (iso != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CountryFlag.fromCountryCode(iso, width: 44, height: 30),
                  )
                else
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _confederation(section.key, name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _nameFromTitle(String title) {
    final idx = title.indexOf('-');
    if (idx < 0) return title;
    return title.substring(idx + 1).trim();
  }

  static String _confederation(String code, String name) {
    // Short non-licensed descriptor. Free to replace by the real federation
    // name once Panini publishes it for every nation.
    if (code == 'FWC') return 'FIFA · Especiais';
    return 'Confederação de Futebol · $name';
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
