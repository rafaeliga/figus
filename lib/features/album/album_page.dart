import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:country_flags/country_flags.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import '../share/share_service.dart';

/// Coleção — index of nations. Tap a nation → opens its dedicated page
/// laid out like the physical album.
class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({super.key});
  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(albumSectionsProvider);
    final filter = ref.watch(albumFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear página',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Progresso',
            onPressed: () => context.push('/progress'),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Compartilhar',
            onPressed: _showShareSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            current: filter,
            onChanged: (f) => ref.read(albumFilterProvider.notifier).state = f,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(albumSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Buscar seleção ou figurinha',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(albumSearchProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: AppTheme.slotSoft.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: sectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (sections) {
                if (sections.isEmpty) {
                  return const Center(child: Text('Nenhuma seleção encontrada'));
                }
                return ListView.builder(
                  key: const PageStorageKey('nations-list'),
                  itemCount: sections.length,
                  itemBuilder: (_, i) => _NationCard(section: sections[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.percent_rounded, color: AppTheme.seed),
              title: const Text('Meu progresso (cartão visual)'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final stats = await ref.read(albumRepoProvider).loadStats();
                final profile = await ref.read(profileRepoProvider).active();
                if (!mounted) return;
                await ShareService.shareProgressCard(
                  context,
                  stats: stats,
                  albumName: 'Copa do Mundo FIFA 2026',
                  profileName: profile.name,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: AppTheme.seed),
              title: const Text('Lista das que me faltam'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.missing, 'Me faltam essas figurinhas:');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppTheme.seed),
              title: const Text('Lista das repetidas'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.duplicates, 'Tenho essas repetidas pra trocar:');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _shareList(AlbumFilter filter, String title) async {
    final sections = await ref.read(albumRepoProvider).loadSections(filter: filter);
    final flat = sections.expand((s) => s.stickers).toList();
    if (flat.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma figurinha nessa categoria')),
      );
      return;
    }
    await ShareService.shareTextList(title: title, stickers: flat);
  }
}

class _FilterChips extends StatelessWidget {
  final AlbumFilter current;
  final ValueChanged<AlbumFilter> onChanged;
  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = <(AlbumFilter, String, IconData)>[
      (AlbumFilter.all, 'Todas', Icons.apps_rounded),
      (AlbumFilter.missing, 'Me faltam', Icons.radar_rounded),
      (AlbumFilter.duplicates, 'Repetidas', Icons.copy_all_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          for (final (f, label, icon) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: current == f,
                onSelected: (_) => onChanged(f),
                avatar: Icon(icon,
                    size: 16,
                    color: current == f ? Colors.white : AppTheme.inkSoft),
                label: Text(label),
                labelStyle: TextStyle(
                  color: current == f ? Colors.white : AppTheme.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: AppTheme.seed,
                backgroundColor: AppTheme.slotSoft,
                showCheckmark: false,
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }
}

class _FlagThumb extends StatelessWidget {
  final String code;
  const _FlagThumb({required this.code});

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[code];
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.slotSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: iso == null
          ? Text(
              code == 'FWC' ? '🏆' : code,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            )
          : CountryFlag.fromCountryCode(
              iso,
              theme: const ImageTheme(
                width: 36,
                height: 26,
                shape: RoundedRectangle(6),
              ),
            ),
    );
  }
}

class _NationCard extends StatelessWidget {
  final AlbumSection section;
  const _NationCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final progress = section.totalCount == 0
        ? 0.0
        : section.ownedCount / section.totalCount;
    final complete = section.ownedCount == section.totalCount && section.totalCount > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/nation/${section.key}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              _FlagThumb(code: section.key),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (complete)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check_circle_rounded,
                                color: Color(0xFF22C58A), size: 18),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${section.ownedCount}/${section.totalCount}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.slotSoft,
                        color: complete ? const Color(0xFF22C58A) : AppTheme.seed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
