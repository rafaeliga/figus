import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/album_view_models.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(albumStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (s) => _StatsBody(stats: s),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final AlbumStats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AlbumHeader(),
          const SizedBox(height: 24),
          const Text('Resumo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _StatCard(
                icon: Icons.donut_large_rounded,
                label: 'Completado',
                value: '${(stats.percentComplete * 100).toStringAsFixed(0)}%',
              ),
              _StatCard(icon: Icons.collections_rounded, label: 'Total', value: '${stats.total}'),
              _StatCard(icon: Icons.cancel_rounded, label: 'Me faltam', value: '${stats.missing}'),
              _StatCard(icon: Icons.check_circle_rounded, label: 'Tenho', value: '${stats.owned}'),
              _StatCard(icon: Icons.copy_rounded, label: 'Repetidas', value: '${stats.duplicates}'),
              _StatCard(
                icon: Icons.star_rounded,
                label: 'Brilhantes',
                value: '${stats.foilOwned}/${stats.foilTotal}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProgressBar(value: stats.percentComplete),
        ],
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppTheme.seed, Color(0xFF7A5BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text('F', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Copa do Mundo FIFA 2026',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('EUA · México · Canadá', style: TextStyle(color: AppTheme.inkSoft)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.seed.withValues(alpha: 0.12),
              child: Icon(icon, color: AppTheme.seed, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progresso geral',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: AppTheme.slotSoft,
                color: AppTheme.seed,
              ),
            ),
            const SizedBox(height: 8),
            Text('${(value * 100).toStringAsFixed(1)}% completo'),
          ],
        ),
      ),
    );
  }
}
