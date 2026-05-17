import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/db/database_backup.dart';
import '../../data/providers.dart';

/// "Você" — replaces the Figuritas-style chapadão de itens by grouping things
/// in cards (Pro pitch + Coleção + Família + Ferramentas + Sobre).
class YouPage extends ConsumerWidget {
  const YouPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profilesListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Você')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            profileName: profileAsync.maybeWhen(
              data: (list) => list.firstWhere((p) => p.isActive, orElse: () => list.first).name,
              orElse: () => 'Você',
            ),
            onProfilesTap: () => context.push('/profiles'),
          ),
          const SizedBox(height: 16),
          _ProBanner(onTap: () => context.push('/upgrade')),
          const SizedBox(height: 24),
          _GroupCard(
            title: 'Sua coleção',
            tiles: [
              _Tile(
                icon: Icons.photo_library_rounded,
                title: 'Importar imagens do álbum',
                subtitle: 'Em lote (do PDF ou pasta de imagens)',
                onTap: () => context.push('/import-images'),
              ),
              _Tile(
                icon: Icons.file_upload_rounded,
                title: 'Importar do Figuritas',
                subtitle: 'Foto, screenshot ou lista colada',
                onTap: () => context.push('/import'),
              ),
              const _Tile(
                icon: Icons.share_rounded,
                title: 'Exportar coleção',
                subtitle: 'Em breve — PDF/CSV',
                onTap: null,
              ),
              if (isNativeSqliteFileBackupSupported) ...[
                _Tile(
                  icon: Icons.folder_zip_rounded,
                  title: 'Exportar backup do banco',
                  subtitle: 'Arquivo .sqlite para salvar nos Arquivos ou na nuvem',
                  onTap: () => _exportSqliteBackup(context, ref),
                ),
                _Tile(
                  icon: Icons.restore_rounded,
                  title: 'Restaurar backup do banco',
                  subtitle: 'Substitui toda a coleção pelo arquivo .sqlite',
                  onTap: () => _restoreSqliteBackup(context, ref),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _GroupCard(
            title: 'Comunidade',
            tiles: [
              _Tile(
                icon: Icons.bluetooth_rounded,
                title: 'Trocar por aproximação',
                subtitle: 'Em breve — diferencial nº 1',
                onTap: null,
              ),
              _Tile(
                icon: Icons.qr_code_rounded,
                title: 'QR de troca',
                subtitle: 'Em breve',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GroupCard(
            title: 'Sobre',
            tiles: [
              _Tile(
                icon: Icons.help_outline_rounded,
                title: 'Como funciona',
                onTap: () => _showHowItWorks(context),
              ),
              const _Tile(
                icon: Icons.coffee_rounded,
                title: 'Apoie o Figus',
                subtitle: 'Cafezinho via Pix (em breve)',
                onTap: null,
              ),
              const _Tile(
                icon: Icons.code_rounded,
                title: 'Versão',
                subtitle: '0.1.0 alpha · open source',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportSqliteBackup(BuildContext context, WidgetRef ref) async {
    try {
      await exportSqliteDatabase(ref.read(databaseProvider));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use “Salvar em Arquivos” ou envie para a nuvem. Guarde este arquivo para restaurar depois.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar: $e')),
      );
    }
  }

  Future<void> _restoreSqliteBackup(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (!context.mounted) return;
    if (pick == null || pick.files.isEmpty) return;

    final path = await resolveBackupPickPath(pick.files.first);
    if (!context.mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível ler o arquivo (comum com iCloud). '
            'Copie o backup para “Arquivos no iPhone” ou outra pasta local e tente de novo.',
          ),
        ),
      );
      return;
    }

    final valid = await fileLooksLikeSqliteDatabase(path);
    if (!context.mounted) return;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo inválido. Escolha um backup .sqlite gerado pelo Figus.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Toda a coleção e perfis neste aparelho serão substituídos pelo backup. '
          'O app será reiniciado em seguida.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await replaceSqliteDatabaseFromBackup(ref.read(databaseProvider), path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restauração falhou: $e')),
      );
    }
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text('Como funciona',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            _HowRow(text: 'Toque numa figurinha → marca como tenho'),
            _HowRow(text: 'Toque de novo → conta como repetida (+1)'),
            _HowRow(text: 'Pressione e segure → tira UMA repetida por vez'),
            _HowRow(text: 'Use a aba Forjar pra trocar 5 repetidas por 1 que falta'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String profileName;
  final VoidCallback onProfilesTap;
  const _ProfileHeader({required this.profileName, required this.onProfilesTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfilesTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slotSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.seed,
              child: Text(
                profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profileName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text('toque pra trocar de perfil ou criar novo',
                      style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.seed, Color(0xFF7A5BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Figus Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      )),
                  SizedBox(height: 2),
                  Text('R\$ 9,90 uma vez · sem assinatura',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _GroupCard({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkSoft.withValues(alpha: 0.8),
              )),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return ListTile(
      leading: Icon(icon, color: disabled ? AppTheme.slot : AppTheme.seed),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: disabled ? AppTheme.inkSoft : null,
          )),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: disabled ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _HowRow extends StatelessWidget {
  final String text;
  const _HowRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.seed, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
