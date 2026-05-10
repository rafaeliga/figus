import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import '../share/share_service.dart';
import 'widgets/nation_section.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({super.key});
  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  // Cache of last-loaded sections so a tap doesn't show a loading spinner
  // (which would also drop the scroll position).
  List<AlbumSection>? _cachedSections;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(albumSectionsProvider);
    final filter = ref.watch(albumFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Álbum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Compartilhar',
            onPressed: _showShareSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(
            current: filter,
            onChanged: (f) => ref.read(albumFilterProvider.notifier).state = f,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(albumSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Buscar (BRA10, jogador...)',
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
            child: _buildList(sectionsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AsyncValue<List<AlbumSection>> async) {
    // Use cached data while a refresh is in flight so the user keeps the same
    // scroll position when tapping a sticker.
    final data = async.value ?? _cachedSections;
    if (async.hasValue) _cachedSections = async.value;

    if (data == null) {
      return async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Text('Erro: ${async.error}'),
            );
    }
    if (data.isEmpty) {
      return const Center(child: Text('Nenhuma figurinha encontrada'));
    }
    return ListView.builder(
      key: const PageStorageKey('album-list'),
      controller: _scrollCtrl,
      itemCount: data.length,
      itemBuilder: (context, i) {
        final section = data[i];
        return NationSectionWidget(
          key: ValueKey('section-${section.key}'),
          section: section,
          onTap: _onTapSticker,
          onLongPress: _onLongPressSticker,
        );
      },
    );
  }

  Future<void> _onTapSticker(StickerView s) async {
    await ref.read(collectionRepoProvider).tapSticker(s.id);
    ref.read(collectionVersionProvider.notifier).state++;
  }

  Future<void> _onLongPressSticker(StickerView s) async {
    await ref.read(collectionRepoProvider).removeSticker(s.id);
    ref.read(collectionVersionProvider.notifier).state++;
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
              subtitle: const Text('Imagem 1080×1080 pra status do WhatsApp'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareProgressCard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: AppTheme.seed),
              title: const Text('Lista das que me faltam'),
              subtitle: const Text('Texto agrupado por seleção'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.missing, 'Me faltam essas figurinhas:');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppTheme.seed),
              title: const Text('Lista das repetidas'),
              subtitle: const Text('Pra propor troca'),
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

  Future<void> _shareProgressCard() async {
    final stats = await ref.read(albumRepoProvider).loadStats();
    final profile = await ref.read(profileRepoProvider).active();
    if (!mounted) return;
    await ShareService.shareProgressCard(
      context,
      stats: stats,
      albumName: 'Copa do Mundo FIFA 2026',
      profileName: profile.name,
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

class _FilterTabs extends StatelessWidget {
  final AlbumFilter current;
  final ValueChanged<AlbumFilter> onChanged;
  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      (AlbumFilter.all, 'Todas'),
      (AlbumFilter.missing, 'Me faltam'),
      (AlbumFilter.duplicates, 'Repetidas'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          for (final (f, label) in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(f),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: current == f ? AppTheme.seed.withValues(alpha: 0.10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      bottom: BorderSide(
                        color: current == f ? AppTheme.seed : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: current == f ? FontWeight.w700 : FontWeight.w500,
                      color: current == f ? AppTheme.seed : AppTheme.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
