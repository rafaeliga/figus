import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/album_view_models.dart';

/// Visual card (1080×1080) used for WhatsApp / social sharing.
/// Rendered off-screen, captured to PNG by ShareService.
class ShareCard extends StatelessWidget {
  final AlbumStats stats;
  final String albumName;
  final String profileName;

  const ShareCard({
    super.key,
    required this.stats,
    required this.albumName,
    required this.profileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F66FF), Color(0xFF7A5BFF)],
        ),
      ),
      padding: const EdgeInsets.all(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('F',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.seed,
                      )),
                ),
              ),
              const SizedBox(width: 24),
              const Text('Figus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  )),
            ],
          ),
          const SizedBox(height: 60),
          Text(albumName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                height: 1.1,
              )),
          const SizedBox(height: 8),
          Text('por $profileName',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 28,
              )),
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Text('${(stats.percentComplete * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    )),
                const SizedBox(width: 24),
                const Expanded(
                  child: Text('completo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatChip(label: 'Tenho', value: '${stats.owned}'),
              _StatChip(label: 'Faltam', value: '${stats.missing}'),
              _StatChip(label: 'Repetidas', value: '${stats.duplicates}'),
              _StatChip(label: 'Brilhantes', value: '${stats.foilOwned}/${stats.foilTotal}'),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_rounded, color: AppTheme.seed),
                SizedBox(width: 8),
                Text('Vamos trocar?',
                    style: TextStyle(
                      color: AppTheme.seed,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 24,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
