import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/db/database.dart' show CollectionsCompanion;
import '../../data/providers.dart';
import 'pdf_image_extractor.dart';

/// Bulk import: user picks many image files at once from the device and the
/// app maps them onto sticker slots by *file order* (alphabetical) — they
/// land on slot #1, #2, ... in the seeded sequence.
///
/// Designed for the typical workflow of running `pdfimages -j album.pdf img`
/// once on the user's machine and feeding the resulting JPEGs into the app
/// in a single pick. Nothing copyrighted ships with the app itself.
class BulkImagesImportPage extends ConsumerStatefulWidget {
  const BulkImagesImportPage({super.key});
  @override
  ConsumerState<BulkImagesImportPage> createState() => _BulkImagesImportPageState();
}

class _BulkImagesImportPageState extends ConsumerState<BulkImagesImportPage> {
  bool _busy = false;
  String? _lastSummary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar imagens')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            const SizedBox(height: 20),
            const _HowItWorks(),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(_busy ? 'Processando...' : 'Selecionar PDF'),
              onPressed: _busy ? null : _pickAndImportPdf,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_busy ? 'Importando...' : 'Selecionar imagens soltas'),
              onPressed: _busy ? null : _pickAndImport,
            ),
            if (_lastSummary != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.seed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.seed),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_lastSummary!)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Apagar todas as imagens'),
              onPressed: _busy ? null : _confirmClearAll,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImportPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _busy = true;
      _lastSummary = 'Extraindo imagens do PDF...';
    });
    try {
      final pdfBytes = result.files.single.bytes!;
      final jpegs = await Future(() => PdfImageExtractor.extractJpegs(pdfBytes));
      if (jpegs.isEmpty) {
        setState(() => _lastSummary = 'Nenhuma imagem JPEG extraível neste PDF.');
        return;
      }

      final db = ref.read(databaseProvider);
      final repo = ref.read(collectionRepoProvider);
      final stickers = await (db.select(db.stickers)
            ..orderBy([
              (s) => OrderingTerm.asc(s.pageNumber),
              (s) => OrderingTerm.asc(s.positionInPage),
            ]))
          .get();

      // Sequential mapping: imagem N → slot N (na ordem do álbum).
      final n = jpegs.length < stickers.length ? jpegs.length : stickers.length;
      for (var i = 0; i < n; i++) {
        await repo.setCustomImage(stickers[i].id, jpegs[i]);
      }
      ref.read(collectionVersionProvider.notifier).state++;

      setState(() {
        _lastSummary = 'PDF processado: ${jpegs.length} imagens extraídas, '
            '$n mapeadas em sequência.';
      });
    } catch (e) {
      setState(() => _lastSummary = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final files = [...result.files]
        ..sort((a, b) => a.name.compareTo(b.name));

      final db = ref.read(databaseProvider);
      final repo = ref.read(collectionRepoProvider);

      // Stickers ordered by physical-album sequence (page + position).
      final stickers = await (db.select(db.stickers)
            ..orderBy([
              (s) => OrderingTerm.asc(s.pageNumber),
              (s) => OrderingTerm.asc(s.positionInPage),
            ]))
          .get();

      // Try name-based mapping first: a file called "BRA10.jpg" → sticker BRA10.
      final byNumber = {for (final s in stickers) s.number.toUpperCase(): s.id};
      final assignments = <int, Uint8List>{}; // stickerId -> bytes
      final unmatched = <PlatformFile>[];

      for (final f in files) {
        final bytes = f.bytes;
        if (bytes == null) continue;
        final base = f.name.split('.').first.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (byNumber.containsKey(base)) {
          assignments[byNumber[base]!] = bytes;
        } else {
          unmatched.add(f);
        }
      }

      // Fallback: any remaining files go to the next free slot in album order.
      if (unmatched.isNotEmpty) {
        var idx = 0;
        for (final f in unmatched) {
          while (idx < stickers.length && assignments.containsKey(stickers[idx].id)) {
            idx++;
          }
          if (idx >= stickers.length) break;
          if (f.bytes != null) {
            assignments[stickers[idx].id] = f.bytes!;
            idx++;
          }
        }
      }

      var done = 0;
      for (final entry in assignments.entries) {
        await repo.setCustomImage(entry.key, entry.value);
        done++;
      }
      ref.read(collectionVersionProvider.notifier).state++;

      setState(() {
        _lastSummary = '$done imagens importadas '
            '${files.length - done > 0 ? '· ${files.length - done} ignoradas' : ''}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmClearAll() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Apagar imagens?'),
        content: const Text(
          'Isso remove TODAS as imagens importadas. Sua coleção de marcações '
          '(tem/falta/repetida) continua intacta.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      await db.update(db.collections).write(const CollectionsCompanion(customImage: Value(null)));
      ref.read(collectionVersionProvider.notifier).state++;
      setState(() => _lastSummary = 'Imagens apagadas');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.seed, Color(0xFF7A5BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text('Imagens das figurinhas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Importe as imagens do seu álbum digital uma única vez. Faltantes ficam '
            'em cinza, as que você tem ficam coloridas.',
            style: TextStyle(color: Colors.white, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slotSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como funciona',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          _Step('PDF',
              'Selecione o arquivo do álbum. O app extrai as imagens JPEG '
              'embebidas e mapeia em ordem (1ª imagem → 1ª figurinha do '
              'álbum, 2ª → 2ª, e assim por diante).'),
          _Step('Imagens',
              'Como alternativa, selecione arquivos soltos (BRA1.jpg, BRA2.jpg…). '
              'O app casa por nome quando puder; senão por ordem alfabética.'),
          SizedBox(height: 8),
          Text(
            'Tudo é processado localmente no seu device. Nada é enviado pra '
            'servidor.',
            style: TextStyle(fontSize: 12, color: AppTheme.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step(this.n, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 18, child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(text, style: const TextStyle(height: 1.3))),
        ],
      ),
    );
  }
}

