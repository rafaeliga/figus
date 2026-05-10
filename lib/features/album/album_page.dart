import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import 'widgets/nation_section.dart';

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
            child: sectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (sections) {
                if (sections.isEmpty) {
                  return const Center(child: Text('Nenhuma figurinha encontrada'));
                }
                return ListView.builder(
                  itemCount: sections.length,
                  itemBuilder: (context, i) => NationSectionWidget(
                    section: sections[i],
                    onTap: _onTapSticker,
                    onLongPress: _onLongPressSticker,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              leading: Icon(Icons.percent_rounded),
              title: Text('Meu progresso (cartão visual)'),
              subtitle: Text('Em breve — gera card e abre WhatsApp'),
            ),
            ListTile(
              leading: Icon(Icons.checklist_rounded),
              title: Text('Lista das que me faltam'),
              subtitle: Text('Em breve'),
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text('Lista das repetidas (pra trocar)'),
              subtitle: Text('Em breve'),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
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
