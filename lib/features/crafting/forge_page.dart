import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';

/// "Forjar repetidas" — 5 duplicates → 1 missing of your choice (or 2 foil → 1 foil missing).
/// Resolves the historical pain: piles of "50 Neymar" with no way out.
/// Free: 1 forge / day. Pro Lifetime: unlimited.
class ForgePage extends ConsumerStatefulWidget {
  const ForgePage({super.key});
  @override
  ConsumerState<ForgePage> createState() => _ForgePageState();
}

class _ForgePageState extends ConsumerState<ForgePage> {
  final _selected = <int>{}; // sticker IDs from duplicates pool

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(albumSectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Forjar repetidas')),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (sections) {
          final duplicates = sections
              .expand((s) => s.stickers)
              .where((s) => s.status == StickerOwnership.duplicate)
              .toList();

          if (duplicates.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: [
              _Header(selectedCount: _selected.length, totalDupes: duplicates.length),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: duplicates.length,
                  itemBuilder: (_, i) {
                    final s = duplicates[i];
                    final selected = _selected.contains(s.id);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _selected.remove(s.id);
                          } else if (_selected.length < 5) {
                            _selected.add(s.id);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.seed : AppTheme.slotSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppTheme.seed : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s.nationCode ?? 'FWC',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selected ? Colors.white70 : AppTheme.inkSoft,
                                )),
                            Text('#${s.number.replaceAll(RegExp(r"^[A-Z]+"), "")}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: selected ? Colors.white : AppTheme.ink,
                                )),
                            Text('×${s.duplicateCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : AppTheme.seed,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _selected.length == 5
                          ? 'Forjar (5 → 1 que falta)'
                          : 'Selecione ${5 - _selected.length} ${_selected.length == 4 ? "repetida" : "repetidas"}',
                    ),
                    onPressed: _selected.length == 5 ? _attemptForge : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _attemptForge() async {
    // Free tier: 1 forge per day per profile.
    final profile = await ref.read(profileRepoProvider).active();
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_forge_p${profile.id}';
    final lastIso = prefs.getString(key);
    final now = DateTime.now();
    if (lastIso != null) {
      final last = DateTime.tryParse(lastIso);
      if (last != null && _sameDay(last, now)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Limite diário atingido (Pro Lifetime: ilimitado).'),
          ),
        );
        return;
      }
    }

    final sections = await ref.read(albumRepoProvider).loadSections(filter: AlbumFilter.missing);
    final missing = sections.expand((s) => s.stickers).toList();
    if (missing.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já completou tudo, não há o que forjar! 🎉')),
      );
      return;
    }

    if (!mounted) return;
    final picked = await _pickMissing(missing);
    if (picked == null) return;

    final repo = ref.read(collectionRepoProvider);
    final db = ref.read(databaseProvider);

    // Decrement duplicate_count by 1 for each selected; if hits 0, becomes owned.
    for (final id in _selected) {
      final entry = await (db.select(db.collections)
            ..where((c) => c.stickerId.equals(id)))
          .getSingleOrNull();
      if (entry == null) continue;
      final newCount = entry.duplicateCount - 1;
      if (newCount <= 0) {
        await (db.update(db.collections)..where((c) => c.id.equals(entry.id))).write(
          const CollectionsCompanion(
            status: Value('owned'),
            duplicateCount: Value(0),
          ),
        );
      } else {
        await (db.update(db.collections)..where((c) => c.id.equals(entry.id))).write(
          CollectionsCompanion(duplicateCount: Value(newCount)),
        );
      }
    }
    // Mark target as owned.
    await repo.tapSticker(picked.id);
    await prefs.setString(key, now.toIso8601String());
    ref.read(collectionVersionProvider.notifier).state++;
    setState(_selected.clear);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forjado: ${picked.number} marcado como tenho ✨')),
    );
  }

  Future<StickerView?> _pickMissing(List<StickerView> missing) {
    return showModalBottomSheet<StickerView>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollCtrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Qual figurinha você quer forjar?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: missing.length,
                itemBuilder: (_, i) {
                  final s = missing[i];
                  return ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: Text(s.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: s.label.isNotEmpty ? Text(s.label) : null,
                    onTap: () => Navigator.pop(sheetCtx, s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  final int selectedCount;
  final int totalDupes;
  const _Header({required this.selectedCount, required this.totalDupes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.seed.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.seed, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Forjar 5 → 1',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(
                  'Você tem $totalDupes repetidas. Selecione 5 pra trocar por uma que falta.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.seed,
            radius: 18,
            child: Text('$selectedCount/5',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.copy_rounded, size: 64, color: AppTheme.slot),
          SizedBox(height: 16),
          Text('Sem repetidas pra forjar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Quando você tiver 5 repetidas, dá pra trocar por uma que falta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft)),
        ],
      ),
    );
  }
}
